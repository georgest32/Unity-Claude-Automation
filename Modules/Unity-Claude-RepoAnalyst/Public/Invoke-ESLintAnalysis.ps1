function Invoke-ESLintAnalysis {
    <#
    .SYNOPSIS
    Executes ESLint analysis on JavaScript/TypeScript files with SARIF output
    
    .DESCRIPTION
    Integrates ESLint JavaScript/TypeScript linting with subprocess execution,
    JSON output parsing, and SARIF 2.1.0 compatible result formatting
    
    .PARAMETER Path
    Path to analyze (file or directory)
    
    .PARAMETER Config
    Configuration hashtable from StaticAnalysisConfig.psd1
    
    .PARAMETER ConfigFile
    Path to ESLint configuration file (.eslintrc.json)
    
    .PARAMETER FixIssues
    Attempt to automatically fix issues where possible
    
    .PARAMETER Extensions
    File extensions to analyze (default: .js, .jsx, .ts, .tsx)
    
    .EXAMPLE
    Invoke-ESLintAnalysis -Path "src/" -ConfigFile ".eslintrc.json"
    
    .EXAMPLE
    $config = Import-PowerShellDataFile "StaticAnalysisConfig.psd1"
    Invoke-ESLintAnalysis -Path . -Config $config -FixIssues
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
        [switch]$FixIssues,
        
        [Parameter()]
        [string[]]$Extensions = @('.js', '.jsx', '.ts', '.tsx')
    )
    
    begin {
        Write-Verbose "Starting ESLint analysis for path: $Path"
        
        # Check if ESLint is available - prefer direct eslint over npx
        $eslintPath = Get-Command 'eslint' -ErrorAction SilentlyContinue
        if ($eslintPath) {
            # Use .cmd version for Windows compatibility
            $eslintCommand = if ($eslintPath.Source -match '\.ps1$') {
                $eslintPath.Source -replace '\.ps1$', '.cmd'
            } else {
                $eslintPath.Source
            }
            Write-Verbose "Using ESLint directly: $eslintCommand"
        } else {
            # Try npx eslint as fallback
            $npxPath = Get-Command 'npx' -ErrorAction SilentlyContinue
            if (-not $npxPath) {
                throw "ESLint not found. Please install ESLint: npm install -g eslint"
            }
            # Use .cmd version for npx as well
            $npxCmd = if ($npxPath.Source -match '\.ps1$') {
                $npxPath.Source -replace '\.ps1$', '.cmd'
            } else {
                $npxPath.Source
            }
            $eslintCommand = @($npxCmd, 'eslint')
            Write-Verbose "Using ESLint via npx: $($eslintCommand -join ' ')"
        }
        
        # Use config from parameter or detect configuration file
        $eslintConfig = if ($Config.ESLint) { $Config.ESLint } else { @{} }
        
        # Detect configuration file if not provided
        if (-not $ConfigFile) {
            $possibleConfigs = @('.eslintrc.json', '.eslintrc.js', '.eslintrc.yml', '.eslintrc.yaml', 'eslint.config.js')
            foreach ($configName in $possibleConfigs) {
                $configPath = Join-Path $PWD $configName
                if (Test-Path $configPath) {
                    $ConfigFile = $configPath
                    Write-Verbose "Found ESLint config: $ConfigFile"
                    break
                }
            }
        }
    }
    
    process {
        try {
            # Find JavaScript/TypeScript files
            $targetFiles = @()
            
            if (Test-Path $Path -PathType Container) {
                # Directory - find files with matching extensions
                $includeExtensions = if ($eslintConfig.Extensions) { $eslintConfig.Extensions } else { $Extensions }
                
                foreach ($ext in $includeExtensions) {
                    $pattern = "*$ext"
                    $files = Get-ChildItem -Path $Path -Filter $pattern -Recurse -File | 
                             Where-Object { $_.FullName -notmatch 'node_modules' -and $_.FullName -notmatch '\.min\.' }
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
                Write-Verbose "No JavaScript/TypeScript files found for ESLint analysis"
                return [PSCustomObject]@{
                    runs = @([PSCustomObject]@{
                        tool = [PSCustomObject]@{
                            driver = [PSCustomObject]@{
                                name = 'ESLint'
                                version = 'unknown'
                                informationUri = 'https://eslint.org/'
                            }
                        }
                        results = @()
                    })
                }
            }
            
            Write-Verbose "Found $($targetFiles.Count) files for ESLint analysis"
            
            # Build ESLint command arguments
            $eslintArgs = [System.Collections.ArrayList]::new()
            
            # Output format
            [void]$eslintArgs.Add('--format')
            [void]$eslintArgs.Add('json')
            
            # Configuration file
            if ($ConfigFile -and (Test-Path $ConfigFile)) {
                [void]$eslintArgs.Add('--config')
                [void]$eslintArgs.Add($ConfigFile)
            }
            
            # Fix issues if requested
            if ($FixIssues) {
                [void]$eslintArgs.Add('--fix')
            }
            
            # Add target path
            [void]$eslintArgs.Add($Path)
            
            Write-Verbose "ESLint command: $eslintCommand $($eslintArgs -join ' ')"
            
            # Execute ESLint using System.Diagnostics.Process for reliable output redirection
            $startTime = Get-Date
            
            try {
                # Determine command and arguments  
                if ($eslintCommand -is [array]) {
                    # Using npx eslint
                    $executablePath = $eslintCommand[0]
                    $argumentList = ($eslintCommand[1..($eslintCommand.Length-1)] + $eslintArgs) -join ' '
                } else {
                    # Using eslint directly
                    $executablePath = $eslintCommand
                    $argumentList = $eslintArgs -join ' '
                }
                
                Write-Verbose "ESLint execution: $executablePath $argumentList"
                
                # Use System.Diagnostics.Process for reliable redirection
                $pinfo = New-Object System.Diagnostics.ProcessStartInfo
                $pinfo.FileName = $executablePath
                $pinfo.Arguments = $argumentList
                $pinfo.RedirectStandardError = $true
                $pinfo.RedirectStandardOutput = $true
                $pinfo.UseShellExecute = $false
                $pinfo.CreateNoWindow = $true
                
                $process = New-Object System.Diagnostics.Process
                $process.StartInfo = $pinfo
                $process.Start() | Out-Null
                $process.WaitForExit()
                
                $stdout = $process.StandardOutput.ReadToEnd()
                $stderr = $process.StandardError.ReadToEnd()
                $exitCode = $process.ExitCode
                
            } catch {
                Write-Error "ESLint execution failed: $_"
                $stdout = ''
                $stderr = $_.Exception.Message
                $exitCode = 1
            }
            
            $endTime = Get-Date
            $executionTime = ($endTime - $startTime).TotalSeconds
            
            Write-Verbose "ESLint completed in $executionTime seconds with exit code: $exitCode"
            
            # Parse ESLint JSON output
            $eslintResults = @()
            
            if ($stdout) {
                try {
                    $eslintOutput = $stdout | ConvertFrom-Json
                    $eslintResults = $eslintOutput
                    Write-Verbose "Parsed ESLint JSON output: $($eslintResults.Count) files analyzed"
                } catch {
                    Write-Warning "Failed to parse ESLint JSON output: $_"
                    Write-Verbose "Raw output: $stdout"
                }
            }
            
            if ($stderr) {
                Write-Warning "ESLint stderr: $stderr"
            }
            
            # Convert to SARIF format
            $sarifResults = @()
            $ruleIndex = @{}
            $ruleArray = @()
            
            foreach ($fileResult in $eslintResults) {
                foreach ($message in $fileResult.messages) {
                    # Map ESLint severity to SARIF level
                    $sarifLevel = switch ($message.severity) {
                        1 { 'warning' }  # ESLint warning
                        2 { 'error' }    # ESLint error
                        default { 'note' }
                    }
                    
                    # Create rule if not exists
                    $ruleId = if ($message.ruleId) { $message.ruleId } else { 'no-rule' }
                    if (-not $ruleIndex.ContainsKey($ruleId)) {
                        $ruleIndex[$ruleId] = $ruleArray.Count
                        $ruleArray += [PSCustomObject]@{
                            id = $ruleId
                            name = $ruleId
                            shortDescription = [PSCustomObject]@{
                                text = $message.message
                            }
                            helpUri = if ($message.ruleId) { "https://eslint.org/docs/rules/$($message.ruleId)" } else { $null }
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
                                    uri = $fileResult.filePath -replace '\\', '/'
                                }
                                region = [PSCustomObject]@{
                                    startLine = $message.line
                                    startColumn = $message.column
                                    endLine = if ($message.endLine) { $message.endLine } else { $message.line }
                                    endColumn = if ($message.endColumn) { $message.endColumn } else { $message.column }
                                }
                            }
                        })
                    }
                    
                    # Add fix information if available
                    if ($message.fix) {
                        $sarifResult | Add-Member -NotePropertyName 'fixes' -NotePropertyValue @([PSCustomObject]@{
                            description = [PSCustomObject]@{
                                text = "ESLint auto-fix available"
                            }
                            artifactChanges = @([PSCustomObject]@{
                                artifactLocation = [PSCustomObject]@{
                                    uri = $fileResult.filePath -replace '\\', '/'
                                }
                                replacements = @([PSCustomObject]@{
                                    deletedRegion = [PSCustomObject]@{
                                        startLine = $message.line
                                        startColumn = $message.column
                                        endLine = $message.endLine
                                        endColumn = $message.endColumn
                                    }
                                    insertedContent = [PSCustomObject]@{
                                        text = $message.fix.text
                                    }
                                })
                            })
                        })
                    }
                    
                    $sarifResults += $sarifResult
                }
            }
            
            # Create SARIF run object
            $sarifRun = [PSCustomObject]@{
                tool = [PSCustomObject]@{
                    driver = [PSCustomObject]@{
                        name = 'ESLint'
                        version = 'unknown'  # Could be extracted from npm list or eslint --version
                        informationUri = 'https://eslint.org/'
                        rules = $ruleArray
                    }
                }
                results = $sarifResults
                columnKind = 'unicodeCodePoints'
            }
            
            # Add execution metadata
            $sarifRun | Add-Member -NotePropertyName 'invocations' -NotePropertyValue @([PSCustomObject]@{
                executionSuccessful = ($exitCode -eq 0 -or $exitCode -eq 1)  # ESLint returns 1 for linting errors
                exitCode = $exitCode
                startTimeUtc = $startTime.ToUniversalTime().ToString('o')
                endTimeUtc = $endTime.ToUniversalTime().ToString('o')
                machine = $env:COMPUTERNAME
                commandLine = "$eslintCommand $($eslintArgs -join ' ')"
            })
            
            Write-Verbose "ESLint analysis complete: $($sarifResults.Count) issues found"
            
            return [PSCustomObject]@{
                runs = @($sarifRun)
            }
            
        } catch {
            Write-Error "ESLint analysis failed: $_"
            
            # Return proper SARIF structure even on critical failure
            return [PSCustomObject]@{
                runs = @([PSCustomObject]@{
                    tool = [PSCustomObject]@{
                        driver = [PSCustomObject]@{
                            name = 'ESLint'
                            version = 'unknown'
                            informationUri = 'https://eslint.org/'
                        }
                    }
                    results = @()
                    columnKind = 'unicodeCodePoints'
                    invocations = @([PSCustomObject]@{
                        executionSuccessful = $false
                        exitCode = 1
                        machine = $env:COMPUTERNAME
                        commandLine = "ESLint analysis failed"
                    })
                })
            }
        }
    }
    
    end {
        Write-Verbose "ESLint analysis completed"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD1ATgG0npd4GhI
# esseBiZO5Z4HHQ7A36yvgeuBNleWR6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMH90i8Iu9E27wwH4Z4KN1Wz
# aJkrhaD6GrwkfLLVxRjqMA0GCSqGSIb3DQEBAQUABIIBABXmuQpBtqLt2qOgJYvW
# OULdEtSpDUyWUmpQ2TYs9GYfd2/NctluUyL/WnwN9swBQQICTNFFYzoHhYZeqrlA
# fwgYNySuKB32yeY8dPUzMPB8asrodXkmBubaEVZVHgeWR6KPRl9GFIJq16r0359n
# /VOPP++RHhKh3ssKIOnxkqmjhQU27zt5xB3svjZMxvqhNBnAto7jLBJFTXXbRVh/
# LAh7+Nr9v5lU3RzE7a0aVHrYlW96NYiL8LRpAMZFx5DWOTGe/yhkO0xN79Wh1jTW
# gzQbqhHCe93WYADMyC55ux1JHHm3QvOyOskSB11VtRGs3n3admq7WcYheM03iXlE
# WHo=
# SIG # End signature block
