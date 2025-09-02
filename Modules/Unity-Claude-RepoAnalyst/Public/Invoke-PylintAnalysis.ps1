function Invoke-PylintAnalysis {
    <#
    .SYNOPSIS
    Executes Pylint analysis on Python files with SARIF output
    
    .DESCRIPTION
    Integrates Pylint Python linting with subprocess execution,
    JSON output parsing, and SARIF 2.1.0 compatible result formatting
    
    .PARAMETER Path
    Path to analyze (file or directory)
    
    .PARAMETER Config
    Configuration hashtable from StaticAnalysisConfig.psd1
    
    .PARAMETER ConfigFile
    Path to Pylint configuration file (.pylintrc)
    
    .PARAMETER OutputFormat
    Pylint output format (default: json)
    
    .PARAMETER Extensions
    File extensions to analyze (default: .py)
    
    .PARAMETER VirtualEnv
    Path to Python virtual environment to use
    
    .EXAMPLE
    Invoke-PylintAnalysis -Path "src/" -ConfigFile ".pylintrc"
    
    .EXAMPLE
    $config = Import-PowerShellDataFile "StaticAnalysisConfig.psd1"
    Invoke-PylintAnalysis -Path . -Config $config -VirtualEnv ".venv"
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
        [ValidateSet('json', 'text', 'colorized')]
        [string]$OutputFormat = 'json',
        
        [Parameter()]
        [string[]]$Extensions = @('.py'),
        
        [Parameter()]
        [string]$VirtualEnv
    )
    
    begin {
        Write-Verbose "Starting Pylint analysis for path: $Path"
        
        # Check if Pylint is available
        $pylintCommand = 'pylint'
        
        # Check for virtual environment
        if ($VirtualEnv) {
            if (Test-Path $VirtualEnv) {
                # Try to use pylint from virtual environment
                $venvPylint = Join-Path $VirtualEnv "Scripts\pylint.exe"  # Windows
                if (-not (Test-Path $venvPylint)) {
                    $venvPylint = Join-Path $VirtualEnv "bin\pylint"  # Unix/Linux
                }
                
                if (Test-Path $venvPylint) {
                    $pylintCommand = $venvPylint
                    Write-Verbose "Using Pylint from virtual environment: $venvPylint"
                }
            } else {
                Write-Warning "Virtual environment path not found: $VirtualEnv"
            }
        }
        
        # Check if Pylint is available
        $pylintPath = Get-Command $pylintCommand -ErrorAction SilentlyContinue
        if (-not $pylintPath) {
            throw "Pylint not found. Please install Pylint: pip install pylint"
        }
        
        # Use config from parameter
        $pylintConfig = if ($Config.Pylint) { $Config.Pylint } else { @{} }
        
        # Detect configuration file if not provided
        if (-not $ConfigFile) {
            $possibleConfigs = @('.pylintrc', 'pyproject.toml', 'setup.cfg')
            foreach ($configName in $possibleConfigs) {
                $configPath = Join-Path $PWD $configName
                if (Test-Path $configPath) {
                    $ConfigFile = $configPath
                    Write-Verbose "Found Pylint config: $ConfigFile"
                    break
                }
            }
        }
        
        # Severity mapping from Pylint to SARIF
        $severityMap = @{
            'convention' = 'note'      # C - Convention violations
            'refactor' = 'info'        # R - Refactoring suggestions  
            'warning' = 'warning'      # W - Warning for stylistic or minor issues
            'error' = 'error'          # E - Error for important issues
            'fatal' = 'error'          # F - Fatal for errors preventing further processing
        }
    }
    
    process {
        try {
            # Find Python files
            $targetFiles = @()
            
            if (Test-Path $Path -PathType Container) {
                # Directory - find Python files
                $includeExtensions = if ($pylintConfig.Extensions) { $pylintConfig.Extensions } else { $Extensions }
                
                foreach ($ext in $includeExtensions) {
                    $pattern = "*$ext"
                    $files = Get-ChildItem -Path $Path -Filter $pattern -Recurse -File |
                             Where-Object { 
                                $_.FullName -notmatch '__pycache__' -and 
                                $_.FullName -notmatch '\.venv' -and
                                $_.FullName -notmatch 'venv' -and
                                $_.FullName -notmatch 'env'
                             }
                    $targetFiles += $files
                }
            } else {
                # Single file
                if (Test-Path $Path -PathType Leaf) {
                    $fileExt = [System.IO.Path]::GetExtension($Path)
                    if ($Extensions -contains $fileExt) {
                        $targetFiles += Get-Item $Path
                    }
                }
            }
            
            if ($targetFiles.Count -eq 0) {
                Write-Verbose "No Python files found for Pylint analysis"
                return [PSCustomObject]@{
                    runs = @([PSCustomObject]@{
                        tool = [PSCustomObject]@{
                            driver = [PSCustomObject]@{
                                name = 'Pylint'
                                version = 'unknown'
                                informationUri = 'https://pylint.org/'
                            }
                        }
                        results = @()
                    })
                }
            }
            
            Write-Verbose "Found $($targetFiles.Count) Python files for Pylint analysis"
            
            # Build Pylint command arguments
            $pylintArgs = [System.Collections.ArrayList]::new()
            
            # Output format
            [void]$pylintArgs.Add('--output-format')
            [void]$pylintArgs.Add($OutputFormat)
            
            # Configuration file
            if ($ConfigFile -and (Test-Path $ConfigFile)) {
                [void]$pylintArgs.Add('--rcfile')
                [void]$pylintArgs.Add($ConfigFile)
            }
            
            # Disable reports for JSON output
            if ($OutputFormat -eq 'json') {
                [void]$pylintArgs.Add('--reports')
                [void]$pylintArgs.Add('no')
            }
            
            # Disable score for cleaner output
            [void]$pylintArgs.Add('--score')
            [void]$pylintArgs.Add('no')
            
            # Add disabled checks from config
            if ($pylintConfig.DisabledChecks -and $pylintConfig.DisabledChecks.Count -gt 0) {
                [void]$pylintArgs.Add('--disable')
                [void]$pylintArgs.Add($pylintConfig.DisabledChecks -join ',')
            }
            
            # Add enabled checks from config  
            if ($pylintConfig.EnabledChecks -and $pylintConfig.EnabledChecks.Count -gt 0 -and $pylintConfig.EnabledChecks[0] -ne 'all') {
                [void]$pylintArgs.Add('--enable')
                [void]$pylintArgs.Add($pylintConfig.EnabledChecks -join ',')
            }
            
            # Add target path/files
            if ($targetFiles.Count -le 100) {
                # For small number of files, pass them directly
                foreach ($file in $targetFiles) {
                    [void]$pylintArgs.Add($file.FullName)
                }
            } else {
                # For large number of files, pass the directory
                [void]$pylintArgs.Add($Path)
            }
            
            Write-Verbose "Pylint command: $pylintCommand $($pylintArgs -join ' ')"
            
            # Execute Pylint
            $startTime = Get-Date
            
            # Use Start-Process with output redirection for better control
            $tempOutputFile = [System.IO.Path]::GetTempFileName()
            $tempErrorFile = [System.IO.Path]::GetTempFileName()
            
            try {
                $process = Start-Process -FilePath $pylintCommand -ArgumentList $pylintArgs -NoNewWindow -PassThru -Wait -RedirectStandardOutput $tempOutputFile -RedirectStandardError $tempErrorFile
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
            
            Write-Verbose "Pylint completed in $executionTime seconds with exit code: $exitCode"
            
            # Parse Pylint JSON output
            $pylintResults = @()
            
            if ($stdout -and $stdout.Trim()) {
                try {
                    if ($OutputFormat -eq 'json') {
                        $pylintOutput = $stdout | ConvertFrom-Json
                        $pylintResults = $pylintOutput
                        Write-Verbose "Parsed Pylint JSON output: $($pylintResults.Count) issues found"
                    } else {
                        Write-Verbose "Pylint text output received (non-JSON format)"
                    }
                } catch {
                    Write-Warning "Failed to parse Pylint JSON output: $_"
                    Write-Verbose "Raw output: $stdout"
                }
            }
            
            if ($stderr -and $stderr.Trim()) {
                Write-Verbose "Pylint stderr: $stderr"
            }
            
            # Convert to SARIF format
            $sarifResults = @()
            $ruleIndex = @{}
            $ruleArray = @()
            
            foreach ($message in $pylintResults) {
                # Map Pylint message type to severity
                $messageType = $message.type
                $sarifLevel = if ($pylintConfig.SeverityMapping -and $pylintConfig.SeverityMapping[$messageType]) {
                    switch ($pylintConfig.SeverityMapping[$messageType]) {
                        'Info' { 'note' }
                        'Warning' { 'warning' }
                        'Error' { 'error' }
                        default { $severityMap[$messageType] }
                    }
                } else {
                    $severityMap[$messageType]
                }
                
                if (-not $sarifLevel) { $sarifLevel = 'warning' }
                
                # Create rule if not exists
                $ruleId = if ($message.'message-id') { $message.'message-id' } else { $message.symbol }
                if (-not $ruleIndex.ContainsKey($ruleId)) {
                    $ruleIndex[$ruleId] = $ruleArray.Count
                    $ruleArray += [PSCustomObject]@{
                        id = $ruleId
                        name = $message.symbol
                        shortDescription = [PSCustomObject]@{
                            text = $message.message
                        }
                        fullDescription = [PSCustomObject]@{
                            text = "$($message.symbol): $($message.message)"
                        }
                        helpUri = "https://pylint.pycqa.org/en/latest/user_guide/messages/$($message.symbol.ToLower()).html"
                    }
                }
                
                # Create SARIF result
                $sarifResult = [PSCustomObject]@{
                    ruleId = $ruleId
                    ruleIndex = $ruleIndex[$ruleId]
                    level = $sarifLevel
                    message = [PSCustomObject]@{
                        text = $message.message
                    }
                    locations = @([PSCustomObject]@{
                        physicalLocation = [PSCustomObject]@{
                            artifactLocation = [PSCustomObject]@{
                                uri = $message.path -replace '\\', '/'
                            }
                            region = [PSCustomObject]@{
                                startLine = $message.line
                                startColumn = $message.column
                                endLine = if ($message.endLine) { $message.endLine } else { $message.line }
                                endColumn = if ($message.endColumn) { $message.endColumn } else { ($message.column + 1) }
                            }
                        }
                    })
                }
                
                # Add additional Pylint-specific properties
                $sarifResult | Add-Member -NotePropertyName 'properties' -NotePropertyValue ([PSCustomObject]@{
                    pylintMessageType = $messageType
                    pylintSymbol = $message.symbol
                    pylintModule = $message.module
                    pylintObj = $message.obj
                })
                
                $sarifResults += $sarifResult
            }
            
            # Get Pylint version if possible
            $pylintVersion = 'unknown'
            try {
                $versionOutput = & $pylintCommand --version 2>&1 | Select-Object -First 1
                if ($versionOutput -match 'pylint\s+([\d.]+)') {
                    $pylintVersion = $Matches[1]
                }
            } catch {
                Write-Verbose "Could not determine Pylint version"
            }
            
            # Create SARIF run object
            $sarifRun = [PSCustomObject]@{
                tool = [PSCustomObject]@{
                    driver = [PSCustomObject]@{
                        name = 'Pylint'
                        version = $pylintVersion
                        informationUri = 'https://pylint.org/'
                        rules = $ruleArray
                    }
                }
                results = $sarifResults
                columnKind = 'unicodeCodePoints'
            }
            
            # Add execution metadata
            $sarifRun | Add-Member -NotePropertyName 'invocations' -NotePropertyValue @([PSCustomObject]@{
                executionSuccessful = ($exitCode -eq 0 -or $exitCode -lt 32)  # Pylint uses exit codes for message categories
                exitCode = $exitCode
                exitCodeDescription = Get-PylintExitCodeDescription -ExitCode $exitCode
                startTimeUtc = $startTime.ToUniversalTime().ToString('o')
                endTimeUtc = $endTime.ToUniversalTime().ToString('o')
                machine = $env:COMPUTERNAME
                commandLine = "$pylintCommand $($pylintArgs -join ' ')"
            })
            
            Write-Verbose "Pylint analysis complete: $($sarifResults.Count) issues found"
            
            return [PSCustomObject]@{
                runs = @($sarifRun)
            }
            
        } catch {
            Write-Error "Pylint analysis failed: $_"
            
            # Return proper SARIF structure even on critical failure
            return [PSCustomObject]@{
                runs = @([PSCustomObject]@{
                    tool = [PSCustomObject]@{
                        driver = [PSCustomObject]@{
                            name = 'Pylint'
                            version = 'unknown'
                            informationUri = 'https://pylint.org/'
                        }
                    }
                    results = @()
                    columnKind = 'unicodeCodePoints'
                    invocations = @([PSCustomObject]@{
                        executionSuccessful = $false
                        exitCode = 1
                        machine = $env:COMPUTERNAME
                        commandLine = "Pylint analysis failed"
                    })
                })
            }
        }
    }
    
    end {
        Write-Verbose "Pylint analysis completed"
    }
}

function Get-PylintExitCodeDescription {
    <#
    .SYNOPSIS
    Provides description for Pylint exit codes
    #>
    [CmdletBinding()]
    param(
        [int]$ExitCode
    )
    
    # Pylint exit codes are bit flags
    $descriptions = @()
    
    if ($ExitCode -band 1) { $descriptions += "Fatal message issued" }
    if ($ExitCode -band 2) { $descriptions += "Error message issued" }  
    if ($ExitCode -band 4) { $descriptions += "Warning message issued" }
    if ($ExitCode -band 8) { $descriptions += "Refactor message issued" }
    if ($ExitCode -band 16) { $descriptions += "Convention message issued" }
    if ($ExitCode -band 32) { $descriptions += "Usage error" }
    
    if ($descriptions.Count -eq 0) {
        return "No issues found"
    }
    
    return $descriptions -join "; "
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBSJFg7EApx9FHf
# 3mQ75cD+/9bTfGwG2uF/9h9vKan9i6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEUZmnh/J2xBDjxERedoF0mJ
# dhcpezzrWNSYat8adoSyMA0GCSqGSIb3DQEBAQUABIIBAGkPnkD43xSClVGXtNGV
# Z5OQapLW08o39IpuwDUw5WEnxc/BM8uxja7AWU/dDHsIASAkiWaxng9Ld7/nBH68
# yd4b0bg7J/6mide5Sk32fZtl67tnfQzPJwm2vavIpzjeFaeLkjcAeuoAsh6+I9ql
# 8zCC6OUO5TEkIta9oYgjWr9MHQGZEjK9gY7QIQAlG7jEH7Ez9klbxiXSv+snyF9k
# dRtQ5D87jIAjEuGyWcm3CB4yLy6rgVI/Nc+CmI7iHwEBlAEJ15zwNPIeczjBZ5S4
# 54j651Yu/+OgIgK188BYqWwzY0ZprvxUkuvqde/qRtWcWK6t3KseCVHgMba4Iwkw
# 3fQ=
# SIG # End signature block
