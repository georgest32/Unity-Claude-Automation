function Invoke-BanditAnalysis {
    <#
    .SYNOPSIS
    Executes Bandit security analysis on Python files with SARIF output
    
    .DESCRIPTION
    Integrates Bandit Python security scanner with subprocess execution,
    JSON output parsing, and SARIF 2.1.0 compatible result formatting
    
    .PARAMETER Path
    Path to analyze (file or directory)
    
    .PARAMETER Config
    Configuration hashtable from StaticAnalysisConfig.psd1
    
    .PARAMETER ConfigFile
    Path to Bandit configuration file (.bandit)
    
    .PARAMETER Severity
    Severity levels to include (LOW, MEDIUM, HIGH)
    
    .PARAMETER SkipTests
    Skip test files during analysis
    
    .PARAMETER VirtualEnv
    Path to Python virtual environment to use
    
    .EXAMPLE
    Invoke-BanditAnalysis -Path "src/" -ConfigFile ".bandit"
    
    .EXAMPLE
    $config = Import-PowerShellDataFile "StaticAnalysisConfig.psd1"
    Invoke-BanditAnalysis -Path . -Config $config -VirtualEnv ".venv"
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
        [ValidateSet('LOW', 'MEDIUM', 'HIGH')]
        [string[]]$Severity = @('LOW', 'MEDIUM', 'HIGH'),
        
        [Parameter()]
        [switch]$SkipTests,
        
        [Parameter()]
        [string]$VirtualEnv
    )
    
    begin {
        Write-Verbose "Starting Bandit security analysis for path: $Path"
        
        # Check if Bandit is available
        $banditCommand = 'bandit'
        
        # Check for virtual environment
        if ($VirtualEnv) {
            if (Test-Path $VirtualEnv) {
                # Try to use bandit from virtual environment
                $venvBandit = Join-Path $VirtualEnv "Scripts\bandit.exe"  # Windows
                if (-not (Test-Path $venvBandit)) {
                    $venvBandit = Join-Path $VirtualEnv "bin\bandit"  # Unix/Linux
                }
                
                if (Test-Path $venvBandit) {
                    $banditCommand = $venvBandit
                    Write-Verbose "Using Bandit from virtual environment: $venvBandit"
                }
            } else {
                Write-Warning "Virtual environment path not found: $VirtualEnv"
            }
        }
        
        # Check if Bandit is available
        $banditPath = Get-Command $banditCommand -ErrorAction SilentlyContinue
        if (-not $banditPath) {
            throw "Bandit not found. Please install Bandit: pip install bandit"
        }
        
        # Use config from parameter
        $banditConfig = if ($Config.Bandit) { $Config.Bandit } else { @{} }
        
        # Detect configuration file if not provided
        if (-not $ConfigFile) {
            $possibleConfigs = @('.bandit', 'bandit.yml', 'bandit.yaml', 'pyproject.toml')
            foreach ($configName in $possibleConfigs) {
                $configPath = Join-Path $PWD $configName
                if (Test-Path $configPath) {
                    $ConfigFile = $configPath
                    Write-Verbose "Found Bandit config: $ConfigFile"
                    break
                }
            }
        }
        
        # Severity mapping from Bandit to SARIF
        $severityMap = @{
            'LOW' = 'note'
            'MEDIUM' = 'warning'  
            'HIGH' = 'error'
        }
    }
    
    process {
        try {
            # Find Python files
            $targetFiles = @()
            
            if (Test-Path $Path -PathType Container) {
                # Directory - find Python files
                $files = Get-ChildItem -Path $Path -Filter "*.py" -Recurse -File |
                         Where-Object { 
                            $_.FullName -notmatch '__pycache__' -and 
                            $_.FullName -notmatch '\.venv' -and
                            $_.FullName -notmatch 'venv' -and
                            $_.FullName -notmatch 'env' -and
                            (-not $SkipTests -or $_.Name -notmatch 'test_.*\.py$')
                         }
                $targetFiles += $files
            } else {
                # Single file
                if (Test-Path $Path -PathType Leaf) {
                    $fileExt = [System.IO.Path]::GetExtension($Path)
                    if ($fileExt -eq '.py') {
                        $targetFiles += Get-Item $Path
                    }
                }
            }
            
            if ($targetFiles.Count -eq 0) {
                Write-Verbose "No Python files found for Bandit security analysis"
                return [PSCustomObject]@{
                    runs = @([PSCustomObject]@{
                        tool = [PSCustomObject]@{
                            driver = [PSCustomObject]@{
                                name = 'Bandit'
                                version = 'unknown'
                                informationUri = 'https://bandit.readthedocs.io/'
                            }
                        }
                        results = @()
                    })
                }
            }
            
            Write-Verbose "Found $($targetFiles.Count) Python files for Bandit security analysis"
            
            # Build Bandit command arguments
            $banditArgs = [System.Collections.ArrayList]::new()
            
            # Output format
            [void]$banditArgs.Add('-f')
            [void]$banditArgs.Add('json')
            
            # Configuration file
            if ($ConfigFile -and (Test-Path $ConfigFile)) {
                if ($ConfigFile -like "*.toml") {
                    # pyproject.toml support
                    [void]$banditArgs.Add('--ini')
                    [void]$banditArgs.Add($ConfigFile)
                } else {
                    [void]$banditArgs.Add('-c')
                    [void]$banditArgs.Add($ConfigFile)
                }
            }
            
            # Severity levels
            if ($Severity.Count -lt 3) {
                $severityLevels = $Severity -join ','
                [void]$banditArgs.Add('-ll')
                if ($Severity -contains 'HIGH') { [void]$banditArgs.Add('-l') }
                if ($Severity -contains 'MEDIUM') { [void]$banditArgs.Add('-i') }
                # LOW is default
            }
            
            # Skip tests
            if ($SkipTests) {
                [void]$banditArgs.Add('--skip')
                [void]$banditArgs.Add('B101')  # Skip assert_used test
            }
            
            # Recursive analysis
            [void]$banditArgs.Add('-r')
            
            # Add target path
            [void]$banditArgs.Add($Path)
            
            Write-Verbose "Bandit command: $banditCommand $($banditArgs -join ' ')"
            
            # Execute Bandit
            $startTime = Get-Date
            
            # Use Start-Process with output redirection for better control
            $tempOutputFile = [System.IO.Path]::GetTempFileName()
            $tempErrorFile = [System.IO.Path]::GetTempFileName()
            
            try {
                $process = Start-Process -FilePath $banditCommand -ArgumentList $banditArgs -NoNewWindow -PassThru -Wait -RedirectStandardOutput $tempOutputFile -RedirectStandardError $tempErrorFile
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
            
            Write-Verbose "Bandit completed in $executionTime seconds with exit code: $exitCode"
            
            # Parse Bandit JSON output
            $banditResults = @()
            
            if ($stdout -and $stdout.Trim()) {
                try {
                    $banditOutput = $stdout | ConvertFrom-Json
                    if ($banditOutput.results) {
                        $banditResults = $banditOutput.results
                        Write-Verbose "Parsed Bandit JSON output: $($banditResults.Count) security issues found"
                    }
                } catch {
                    Write-Warning "Failed to parse Bandit JSON output: $_"
                    Write-Verbose "Raw output: $stdout"
                }
            }
            
            if ($stderr -and $stderr.Trim()) {
                Write-Verbose "Bandit stderr: $stderr"
            }
            
            # Convert to SARIF format
            $sarifResults = @()
            $ruleIndex = @{}
            $ruleArray = @()
            
            foreach ($issue in $banditResults) {
                # Map Bandit severity to SARIF level
                $sarifLevel = $severityMap[$issue.issue_severity]
                if (-not $sarifLevel) { $sarifLevel = 'warning' }
                
                # Create rule if not exists
                $ruleId = $issue.test_id
                if (-not $ruleIndex.ContainsKey($ruleId)) {
                    $ruleIndex[$ruleId] = $ruleArray.Count
                    $ruleArray += [PSCustomObject]@{
                        id = $ruleId
                        name = $issue.test_name
                        shortDescription = [PSCustomObject]@{
                            text = $issue.issue_text
                        }
                        fullDescription = [PSCustomObject]@{
                            text = "$($issue.test_name): $($issue.issue_text)"
                        }
                        helpUri = "https://bandit.readthedocs.io/en/latest/plugins/$($ruleId.ToLower()).html"
                        properties = [PSCustomObject]@{
                            category = 'security'
                            tags = @('security', 'python', $issue.issue_severity.ToLower())
                            confidence = $issue.issue_confidence
                        }
                    }
                }
                
                # Create SARIF result
                $sarifResult = [PSCustomObject]@{
                    ruleId = $ruleId
                    ruleIndex = $ruleIndex[$ruleId]
                    level = $sarifLevel
                    message = [PSCustomObject]@{
                        text = $issue.issue_text
                    }
                    locations = @([PSCustomObject]@{
                        physicalLocation = [PSCustomObject]@{
                            artifactLocation = [PSCustomObject]@{
                                uri = $issue.filename -replace '\\', '/'
                            }
                            region = [PSCustomObject]@{
                                startLine = $issue.line_number
                                startColumn = if ($issue.col_offset) { $issue.col_offset } else { 1 }
                                endLine = if ($issue.end_line_number) { $issue.end_line_number } else { $issue.line_number }
                                endColumn = if ($issue.end_col_offset) { $issue.end_col_offset } else { ($issue.col_offset + 10) }
                                snippet = [PSCustomObject]@{
                                    text = $issue.code
                                }
                            }
                        }
                    })
                }
                
                # Add Bandit-specific properties
                $sarifResult | Add-Member -NotePropertyName 'properties' -NotePropertyValue ([PSCustomObject]@{
                    banditTestId = $issue.test_id
                    banditTestName = $issue.test_name
                    banditSeverity = $issue.issue_severity
                    banditConfidence = $issue.issue_confidence
                    banditMoreInfo = $issue.more_info
                })
                
                $sarifResults += $sarifResult
            }
            
            # Get Bandit version if possible
            $banditVersion = 'unknown'
            try {
                $versionOutput = & $banditCommand --version 2>&1 | Select-Object -First 1
                if ($versionOutput -match 'bandit\s+([0-9.]+)') {
                    $banditVersion = $Matches[1]
                }
            } catch {
                Write-Verbose "Could not determine Bandit version"
            }
            
            # Create SARIF run object
            $sarifRun = [PSCustomObject]@{
                tool = [PSCustomObject]@{
                    driver = [PSCustomObject]@{
                        name = 'Bandit'
                        fullName = 'Bandit Security Linter'
                        version = $banditVersion
                        informationUri = 'https://bandit.readthedocs.io/'
                        rules = $ruleArray
                    }
                }
                results = $sarifResults
                columnKind = 'unicodeCodePoints'
            }
            
            # Add execution metadata
            $sarifRun | Add-Member -NotePropertyName 'invocations' -NotePropertyValue @([PSCustomObject]@{
                executionSuccessful = ($exitCode -eq 0 -or $exitCode -eq 1)  # Bandit returns 1 when issues found
                exitCode = $exitCode
                startTimeUtc = $startTime.ToUniversalTime().ToString('o')
                endTimeUtc = $endTime.ToUniversalTime().ToString('o')
                machine = $env:COMPUTERNAME
                commandLine = "$banditCommand $($banditArgs -join ' ')"
            })
            
            # Add file metrics
            $sarifRun | Add-Member -NotePropertyName 'properties' -NotePropertyValue ([PSCustomObject]@{
                totalFiles = $targetFiles.Count
                securityIssuesFound = $sarifResults.Count
                executionTimeSeconds = $executionTime
                severityDistribution = @{
                    high = ($sarifResults | Where-Object { $_.level -eq 'error' }).Count
                    medium = ($sarifResults | Where-Object { $_.level -eq 'warning' }).Count  
                    low = ($sarifResults | Where-Object { $_.level -eq 'note' }).Count
                }
            })
            
            Write-Verbose "Bandit security analysis complete: $($sarifResults.Count) security issues found"
            
            return [PSCustomObject]@{
                runs = @($sarifRun)
            }
            
        } catch {
            Write-Error "Bandit security analysis failed: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Bandit security analysis completed"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBPJfZOGZZqnxDz
# JKa9agXDzknpjtbKeXnbte5YeEJEwqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDO9zA8bffsw2rzReurBVujR
# 5trrtZCnt2h2eotSWC2iMA0GCSqGSIb3DQEBAQUABIIBAIwW0Wcu6SKXoU+A9FGa
# iKHGOor3CyN485y8ctBkMZTK4dgZQN6BOEe76XHYoOBg6KJEb24uB0w1J+n3rnbq
# jj5dzTHTpeI/PvLjN8ucUEcUpImuRxrM7mKNYZHcISMjCL+QfhAnoN3T9c6t+JRA
# HzZvKaLZkVy0X/kki7PBDCW2oyZr9Trc5Lgnk55MuAOX6LDHesEvsHnkrwWP+leh
# K1dsrbA+zaBOXaRULCIqvM3S+S+YfXu/LgU5qzcinQghbM1z53zfCwJS+k91cZUa
# HA1NJX423RxDFrpkSyjbkMO7gNUkxgQyQi5NLZ7951y02fhIXI/iIziAbJXFsrTK
# 2TE=
# SIG # End signature block
