function Invoke-SemgrepAnalysis {
    <#
    .SYNOPSIS
    Executes Semgrep security analysis on multiple language files with SARIF output
    
    .DESCRIPTION
    Integrates Semgrep multi-language security scanner with subprocess execution,
    JSON output parsing, and SARIF 2.1.0 compatible result formatting
    
    .PARAMETER Path
    Path to analyze (file or directory)
    
    .PARAMETER Config
    Configuration hashtable from StaticAnalysisConfig.psd1
    
    .PARAMETER ConfigFile
    Path to Semgrep configuration file or rule set
    
    .PARAMETER RuleSet
    Predefined rule set to use (auto, security, python, javascript, etc.)
    
    .PARAMETER Languages
    Languages to analyze (auto-detected if not specified)
    
    .PARAMETER Severity
    Severity levels to include (INFO, WARNING, ERROR)
    
    .PARAMETER MaxTargetBytes
    Maximum file size to analyze in bytes
    
    .EXAMPLE
    Invoke-SemgrepAnalysis -Path "src/" -RuleSet "security"
    
    .EXAMPLE
    $config = Import-PowerShellDataFile "StaticAnalysisConfig.psd1"
    Invoke-SemgrepAnalysis -Path . -Config $config -Languages @('python', 'javascript')
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter()]
        [hashtable]$Config = @{},
        
        [Parameter()]
        [string]$ConfigFile,
        
        [Parameter()]
        [ValidateSet('auto', 'security', 'python', 'javascript', 'typescript', 'java', 'go', 'ruby', 'php', 'csharp')]
        [string]$RuleSet = 'auto',
        
        [Parameter()]
        [string[]]$Languages = @(),
        
        [Parameter()]
        [ValidateSet('INFO', 'WARNING', 'ERROR')]
        [string[]]$Severity = @('INFO', 'WARNING', 'ERROR'),
        
        [Parameter()]
        [int]$MaxTargetBytes = 1000000  # 1MB default
    )
    
    begin {
        Write-Verbose "Starting Semgrep security analysis for path: $Path"
        
        # Check if Semgrep is available
        $semgrepCommand = 'semgrep'
        $semgrepPath = Get-Command $semgrepCommand -ErrorAction SilentlyContinue
        if (-not $semgrepPath) {
            throw "Semgrep not found. Please install Semgrep: pip install semgrep"
        }
        
        # Use config from parameter
        $semgrepConfig = if ($Config.Semgrep) { $Config.Semgrep } else { @{} }
        
        # Detect configuration file if not provided
        if (-not $ConfigFile) {
            $possibleConfigs = @('.semgrep.yml', '.semgrep.yaml', 'semgrep.yml', 'semgrep.yaml')
            foreach ($configName in $possibleConfigs) {
                $configPath = Join-Path $PWD $configName
                if (Test-Path $configPath) {
                    $ConfigFile = $configPath
                    Write-Verbose "Found Semgrep config: $ConfigFile"
                    break
                }
            }
        }
        
        # Severity mapping from Semgrep to SARIF
        $severityMap = @{
            'INFO' = 'note'
            'WARNING' = 'warning'
            'ERROR' = 'error'
        }
        
        # Language extension mapping
        $languageExtensions = @{
            'python' = @('.py')
            'javascript' = @('.js', '.jsx')
            'typescript' = @('.ts', '.tsx')
            'java' = @('.java')
            'go' = @('.go')
            'ruby' = @('.rb')
            'php' = @('.php')
            'csharp' = @('.cs')
            'yaml' = @('.yml', '.yaml')
            'json' = @('.json')
        }
    }
    
    process {
        try {
            # Find target files based on languages
            $targetFiles = @()
            
            if (Test-Path $Path -PathType Container) {
                # Auto-detect or use specified languages
                if ($Languages.Count -eq 0 -or $RuleSet -eq 'auto') {
                    # Let Semgrep auto-detect files
                    $targetFiles = Get-ChildItem -Path $Path -File -Recurse |
                                   Where-Object { 
                                       $_.FullName -notmatch 'node_modules' -and 
                                       $_.FullName -notmatch '\.git' -and
                                       $_.FullName -notmatch '__pycache__' -and
                                       $_.Length -lt $MaxTargetBytes
                                   }
                } else {
                    # Find files for specific languages
                    foreach ($lang in $Languages) {
                        if ($languageExtensions[$lang]) {
                            foreach ($ext in $languageExtensions[$lang]) {
                                $pattern = "*$ext"
                                $files = Get-ChildItem -Path $Path -Filter $pattern -Recurse -File |
                                         Where-Object { 
                                             $_.FullName -notmatch 'node_modules' -and 
                                             $_.FullName -notmatch '\.git' -and
                                             $_.FullName -notmatch '__pycache__' -and
                                             $_.Length -lt $MaxTargetBytes
                                         }
                                $targetFiles += $files
                            }
                        }
                    }
                }
            } else {
                # Single file
                if (Test-Path $Path -PathType Leaf) {
                    $file = Get-Item $Path
                    if ($file.Length -lt $MaxTargetBytes) {
                        $targetFiles += $file
                    }
                }
            }
            
            # Semgrep will find files automatically, but we check for reporting
            Write-Verbose "Analyzing path with Semgrep (auto-detection enabled)"
            
            # Build Semgrep command arguments
            $semgrepArgs = [System.Collections.ArrayList]::new()
            
            # Output format
            [void]$semgrepArgs.Add('--json')
            
            # Configuration
            if ($ConfigFile -and (Test-Path $ConfigFile)) {
                [void]$semgrepArgs.Add('--config')
                [void]$semgrepArgs.Add($ConfigFile)
            } else {
                # Use rule set
                if ($RuleSet -ne 'auto') {
                    [void]$semgrepArgs.Add('--config')
                    [void]$semgrepArgs.Add("auto")  # Use auto for comprehensive analysis
                }
            }
            
            # Severity filtering (Semgrep doesn't have direct severity filtering)
            # We'll filter results after execution
            
            # Languages
            if ($Languages.Count -gt 0) {
                foreach ($lang in $Languages) {
                    [void]$semgrepArgs.Add('--lang')
                    [void]$semgrepArgs.Add($lang)
                }
            }
            
            # Disable telemetry and update checks for CI environments
            [void]$semgrepArgs.Add('--disable-version-check')
            [void]$semgrepArgs.Add('--metrics=off')
            
            # Max target bytes
            [void]$semgrepArgs.Add('--max-target-bytes')
            [void]$semgrepArgs.Add($MaxTargetBytes.ToString())
            
            # Quiet mode to reduce noise
            [void]$semgrepArgs.Add('--quiet')
            
            # Add target path
            [void]$semgrepArgs.Add($Path)
            
            Write-Verbose "Semgrep command: $semgrepCommand $($semgrepArgs -join ' ')"
            
            # Execute Semgrep
            $startTime = Get-Date
            
            # Use Start-Process with output redirection for better control
            $tempOutputFile = [System.IO.Path]::GetTempFileName()
            $tempErrorFile = [System.IO.Path]::GetTempFileName()
            
            try {
                $process = Start-Process -FilePath $semgrepCommand -ArgumentList $semgrepArgs -NoNewWindow -PassThru -Wait -RedirectStandardOutput $tempOutputFile -RedirectStandardError $tempErrorFile
                $exitCode = $process.ExitCode
                
                $stdout = if (Test-Path $tempOutputFile) { Get-Content $tempOutputFile -Raw } else { '' }
                $stderr = if (Test-Path $tempErrorFile) { Get-Content $tempErrorFile -Raw } else { '' }
                
            } finally {
                # Cleanup temp files
                if (Test-Path $tempOutputFile) { Remove-Item $tempOutputFile -Force }
                if (Test-Path $tempErrorFile) { Remove-Item $tempErrorFile -Force }
            }
            
            $endTime = Get-Date
            $executionTime = ($endTime - $startTime).TotalSeconds
            
            Write-Verbose "Semgrep completed in $executionTime seconds with exit code: $exitCode"
            
            # Parse Semgrep JSON output
            $semgrepResults = @()
            
            if ($stdout -and $stdout.Trim()) {
                try {
                    $semgrepOutput = $stdout | ConvertFrom-Json
                    if ($semgrepOutput.results) {
                        $semgrepResults = $semgrepOutput.results
                        Write-Verbose "Parsed Semgrep JSON output: $($semgrepResults.Count) security issues found"
                    }
                } catch {
                    Write-Warning "Failed to parse Semgrep JSON output: $_"
                    Write-Verbose "Raw output: $stdout"
                }
            }
            
            if ($stderr -and $stderr.Trim()) {
                Write-Verbose "Semgrep stderr: $stderr"
            }
            
            # Convert to SARIF format
            $sarifResults = @()
            $ruleIndex = @{}
            $ruleArray = @()
            
            foreach ($finding in $semgrepResults) {
                # Map Semgrep severity to SARIF level
                $semgrepSeverity = if ($finding.extra.severity) { $finding.extra.severity.ToUpper() } else { 'WARNING' }
                $sarifLevel = $severityMap[$semgrepSeverity]
                if (-not $sarifLevel) { $sarifLevel = 'warning' }
                
                # Filter by severity if specified
                if ($Severity.Count -lt 3 -and $semgrepSeverity -notin $Severity) {
                    continue
                }
                
                # Create rule if not exists
                $ruleId = $finding.check_id
                if (-not $ruleIndex.ContainsKey($ruleId)) {
                    $ruleIndex[$ruleId] = $ruleArray.Count
                    $ruleArray += [PSCustomObject]@{
                        id = $ruleId
                        name = $ruleId
                        shortDescription = [PSCustomObject]@{
                            text = $finding.extra.message
                        }
                        fullDescription = [PSCustomObject]@{
                            text = "$($ruleId): $($finding.extra.message)"
                        }
                        helpUri = if ($finding.extra.metadata.references) { $finding.extra.metadata.references[0] } else { "https://semgrep.dev/r/$ruleId" }
                        properties = [PSCustomObject]@{
                            category = if ($finding.extra.metadata.category) { $finding.extra.metadata.category } else { 'security' }
                            tags = @('security', 'semgrep') + (if ($finding.extra.metadata.owasp) { @('owasp') } else { @() })
                            confidence = if ($finding.extra.metadata.confidence) { $finding.extra.metadata.confidence } else { 'MEDIUM' }
                        }
                    }
                }
                
                # Create SARIF result
                $sarifResult = [PSCustomObject]@{
                    ruleId = $ruleId
                    ruleIndex = $ruleIndex[$ruleId]
                    level = $sarifLevel
                    message = [PSCustomObject]@{
                        text = $finding.extra.message
                    }
                    locations = @([PSCustomObject]@{
                        physicalLocation = [PSCustomObject]@{
                            artifactLocation = [PSCustomObject]@{
                                uri = $finding.path -replace '\\', '/'
                            }
                            region = [PSCustomObject]@{
                                startLine = $finding.start.line
                                startColumn = $finding.start.col
                                endLine = $finding.end.line
                                endColumn = $finding.end.col
                                snippet = [PSCustomObject]@{
                                    text = $finding.extra.lines
                                }
                            }
                        }
                    })
                }
                
                # Add Semgrep-specific properties
                $sarifResult | Add-Member -NotePropertyName 'properties' -NotePropertyValue ([PSCustomObject]@{
                    semgrepCheckId = $finding.check_id
                    semgrepSeverity = $semgrepSeverity
                    semgrepConfidence = if ($finding.extra.metadata.confidence) { $finding.extra.metadata.confidence } else { 'MEDIUM' }
                    semgrepCategory = if ($finding.extra.metadata.category) { $finding.extra.metadata.category } else { 'security' }
                    semgrepLanguage = if ($finding.extra.metadata.languages) { $finding.extra.metadata.languages -join ',' } else { 'unknown' }
                    semgrepCwe = if ($finding.extra.metadata.cwe) { $finding.extra.metadata.cwe -join ',' } else { $null }
                    semgrepOwasp = if ($finding.extra.metadata.owasp) { $finding.extra.metadata.owasp -join ',' } else { $null }
                })
                
                # Add fix suggestions if available
                if ($finding.extra.fix) {
                    $sarifResult | Add-Member -NotePropertyName 'fixes' -NotePropertyValue @([PSCustomObject]@{
                        description = [PSCustomObject]@{
                            text = "Semgrep suggested fix"
                        }
                        artifactChanges = @([PSCustomObject]@{
                            artifactLocation = [PSCustomObject]@{
                                uri = $finding.path -replace '\\', '/'
                            }
                            replacements = @([PSCustomObject]@{
                                deletedRegion = [PSCustomObject]@{
                                    startLine = $finding.start.line
                                    startColumn = $finding.start.col
                                    endLine = $finding.end.line
                                    endColumn = $finding.end.col
                                }
                                insertedContent = [PSCustomObject]@{
                                    text = $finding.extra.fix
                                }
                            })
                        })
                    })
                }
                
                $sarifResults += $sarifResult
            }
            
            # Get Semgrep version if possible
            $semgrepVersion = 'unknown'
            try {
                $versionOutput = & $semgrepCommand --version 2>&1 | Select-Object -First 1
                if ($versionOutput -match '([0-9]+\.[0-9]+\.[0-9]+)') {
                    $semgrepVersion = $Matches[1]
                }
            } catch {
                Write-Verbose "Could not determine Semgrep version"
            }
            
            # Create SARIF run object
            $sarifRun = [PSCustomObject]@{
                tool = [PSCustomObject]@{
                    driver = [PSCustomObject]@{
                        name = 'Semgrep'
                        fullName = 'Semgrep Static Analysis'
                        version = $semgrepVersion
                        informationUri = 'https://semgrep.dev/'
                        rules = $ruleArray
                    }
                }
                results = $sarifResults
                columnKind = 'unicodeCodePoints'
            }
            
            # Add execution metadata
            $sarifRun | Add-Member -NotePropertyName 'invocations' -NotePropertyValue @([PSCustomObject]@{
                executionSuccessful = ($exitCode -eq 0 -or $exitCode -eq 1)  # Semgrep returns 1 when issues found
                exitCode = $exitCode
                startTimeUtc = $startTime.ToUniversalTime().ToString('o')
                endTimeUtc = $endTime.ToUniversalTime().ToString('o')
                machine = $env:COMPUTERNAME
                commandLine = "$semgrepCommand $($semgrepArgs -join ' ')"
            })
            
            # Add analysis metrics
            $languageStats = @{}
            $categoryStats = @{}
            
            foreach ($result in $sarifResults) {
                $lang = $result.properties.semgrepLanguage
                if ($lang -and $lang -ne 'unknown') {
                    if (-not $languageStats[$lang]) { $languageStats[$lang] = 0 }
                    $languageStats[$lang]++
                }
                
                $category = $result.properties.semgrepCategory
                if ($category) {
                    if (-not $categoryStats[$category]) { $categoryStats[$category] = 0 }
                    $categoryStats[$category]++
                }
            }
            
            $sarifRun | Add-Member -NotePropertyName 'properties' -NotePropertyValue ([PSCustomObject]@{
                securityIssuesFound = $sarifResults.Count
                executionTimeSeconds = $executionTime
                languageDistribution = $languageStats
                categoryDistribution = $categoryStats
                severityDistribution = @{
                    error = ($sarifResults | Where-Object { $_.level -eq 'error' }).Count
                    warning = ($sarifResults | Where-Object { $_.level -eq 'warning' }).Count  
                    info = ($sarifResults | Where-Object { $_.level -eq 'note' }).Count
                }
            })
            
            Write-Verbose "Semgrep security analysis complete: $($sarifResults.Count) security issues found"
            
            return [PSCustomObject]@{
                runs = @($sarifRun)
            }
            
        } catch {
            Write-Error "Semgrep security analysis failed: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Semgrep security analysis completed"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCEDI4dNtp4nAaW
# /BsuaLAVKdn9H1JQi45ax1GIY8NmA6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMgj+0bVu++ColL4HSjxkgik
# h8Mnqh7m6IitxVtt+yTqMA0GCSqGSIb3DQEBAQUABIIBAJoLiRrcXgwVE9fLODy/
# 3/M/KciiIW3aXgaVHryWLlYia6bk4kqdZ9mYunJT/GG/9EjFNRjDveG50WaUlOIQ
# Kro6VLW0jEb90W2NtMMDyosEIBgQt4Y8r9OODfoAZmfLOfpML9P3Ej4SAZP486op
# KhemYCxk1sgbwJfS3+iCwp/xANqUGBA+j7ckDTfI5zwdbzJKNr2hEPJpkpFbLo2M
# IhDgtRcYdfgBuirXByqYi88CcOp+tHfPDle73Gy/t3h77WH/YwTf0r1ceWCA0gFk
# YG5DQHhvgrIPajkM03Rf9su8o4dig1KP828zt1faz9llTh9lOQ9CfJI5B8i7H4Up
# GEY=
# SIG # End signature block
