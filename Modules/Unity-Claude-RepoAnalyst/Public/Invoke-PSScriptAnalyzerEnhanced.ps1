function Invoke-PSScriptAnalyzerEnhanced {
    <#
    .SYNOPSIS
    Enhanced PSScriptAnalyzer integration with SARIF output and performance optimization
    
    .DESCRIPTION
    Advanced PowerShell Script Analyzer integration with SARIF 2.1.0 compatible output,
    custom rule loading, batch processing, and integration with existing module capabilities
    
    .PARAMETER Path
    Path to analyze (file or directory)
    
    .PARAMETER Config
    Configuration hashtable from StaticAnalysisConfig.psd1
    
    .PARAMETER Settings
    Path to PSScriptAnalyzer settings file (PSScriptAnalyzerSettings.psd1)
    
    .PARAMETER Severity
    Severity levels to include (Error, Warning, Information)
    
    .PARAMETER IncludeRules
    Array of specific rules to include
    
    .PARAMETER ExcludeRules
    Array of rules to exclude from analysis
    
    .PARAMETER EnableExit
    Enable exit code for CI/CD integration
    
    .PARAMETER CustomRulePath
    Path to custom PSScriptAnalyzer rules
    
    .EXAMPLE
    Invoke-PSScriptAnalyzerEnhanced -Path "src/" -Settings "PSScriptAnalyzerSettings.psd1"
    
    .EXAMPLE
    $config = Import-PowerShellDataFile "StaticAnalysisConfig.psd1"
    Invoke-PSScriptAnalyzerEnhanced -Path . -Config $config -Severity @('Error', 'Warning')
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter()]
        [hashtable]$Config = @{},
        
        [Parameter()]
        [string]$Settings,
        
        [Parameter()]
        [ValidateSet('Error', 'Warning', 'Information', 'ParseError')]
        [string[]]$Severity = @('Error', 'Warning', 'Information'),
        
        [Parameter()]
        [string[]]$IncludeRules = @(),
        
        [Parameter()]
        [string[]]$ExcludeRules = @(),
        
        [Parameter()]
        [switch]$EnableExit,
        
        [Parameter()]
        [string]$CustomRulePath
    )
    
    begin {
        Write-Verbose "Starting enhanced PSScriptAnalyzer analysis for path: $Path"
        
        # Check if PSScriptAnalyzer is available
        if (-not (Get-Module -ListAvailable PSScriptAnalyzer)) {
            try {
                Install-Module PSScriptAnalyzer -Force -Scope CurrentUser
                Write-Verbose "Installed PSScriptAnalyzer module"
            } catch {
                throw "PSScriptAnalyzer not available and could not be installed: $_"
            }
        }
        
        # Import PSScriptAnalyzer if not already loaded
        if (-not (Get-Module PSScriptAnalyzer)) {
            Import-Module PSScriptAnalyzer -Force
        }
        
        # Use config from parameter
        $psaConfig = if ($Config.PSScriptAnalyzer) { $Config.PSScriptAnalyzer } else { @{} }
        
        # Detect settings file if not provided
        if (-not $Settings) {
            $possibleSettings = @('PSScriptAnalyzerSettings.psd1', '.vscode\PSScriptAnalyzerSettings.psd1')
            foreach ($settingName in $possibleSettings) {
                $settingPath = Join-Path $PWD $settingName
                if (Test-Path $settingPath) {
                    $Settings = $settingPath
                    Write-Verbose "Found PSScriptAnalyzer settings: $Settings"
                    break
                }
            }
        }
        
        # Use configuration values if not provided as parameters
        if ($psaConfig.Severity -and $Severity.Count -eq 3) {
            $Severity = $psaConfig.Severity
        }
        
        if ($psaConfig.IncludeRules -and $IncludeRules.Count -eq 0) {
            $IncludeRules = $psaConfig.IncludeRules
        }
        
        if ($psaConfig.ExcludeRules -and $ExcludeRules.Count -eq 0) {
            $ExcludeRules = $psaConfig.ExcludeRules
        }
        
        if ($psaConfig.CustomRulePath -and -not $CustomRulePath) {
            $CustomRulePath = $psaConfig.CustomRulePath
        }
    }
    
    process {
        try {
            # Find PowerShell files
            $targetFiles = @()
            $psExtensions = @('.ps1', '.psm1', '.psd1')
            
            if ($psaConfig.Extensions) {
                $psExtensions = $psaConfig.Extensions
            }
            
            if (Test-Path $Path -PathType Container) {
                # Directory - find PowerShell files
                foreach ($ext in $psExtensions) {
                    $pattern = "*$ext"
                    $files = Get-ChildItem -Path $Path -Filter $pattern -Recurse -File |
                             Where-Object { 
                                $_.FullName -notmatch '\\bin\\' -and 
                                $_.FullName -notmatch '\\obj\\' -and
                                $_.FullName -notmatch '\\packages\\' -and
                                $_.FullName -notmatch '\\.git\\' -and
                                $_.FullName -notmatch '\\\.venv\\' -and
                                $_.FullName -notmatch '\\venv\\' -and
                                $_.FullName -notmatch '\\env\\' -and
                                $_.FullName -notmatch '\\lib64\\' -and
                                $_.FullName -notmatch '\\__pycache__\\' -and
                                $_.FullName -notmatch '\\node_modules\\' -and
                                (Test-Path $_.FullName -PathType Leaf)
                             }
                    $targetFiles += $files
                }
            } else {
                # Single file
                if (Test-Path $Path -PathType Leaf) {
                    $fileExt = [System.IO.Path]::GetExtension($Path)
                    if ($psExtensions -contains $fileExt) {
                        $targetFiles += Get-Item $Path
                    }
                }
            }
            
            if ($targetFiles.Count -eq 0) {
                Write-Verbose "No PowerShell files found for PSScriptAnalyzer analysis"
                return [PSCustomObject]@{
                    runs = @([PSCustomObject]@{
                        tool = [PSCustomObject]@{
                            driver = [PSCustomObject]@{
                                name = 'PSScriptAnalyzer'
                                version = (Get-Module PSScriptAnalyzer).Version.ToString()
                                informationUri = 'https://github.com/PowerShell/PSScriptAnalyzer'
                            }
                        }
                        results = @()
                    })
                }
            }
            
            Write-Verbose "Found $($targetFiles.Count) PowerShell files for PSScriptAnalyzer analysis"
            
            # Execute PSScriptAnalyzer on each file individually to avoid array-to-string conversion
            $startTime = Get-Date
            $allPsaResults = @()
            
            foreach ($file in $targetFiles) {
                $psaParams = @{
                    Path = $file.FullName
                    Severity = $Severity
                    Recurse = $false
                }
                
                # Add settings file if available
                if ($Settings -and (Test-Path $Settings)) {
                    $psaParams.Settings = $Settings
                }
                
                # Add include rules  
                if ($IncludeRules.Count -gt 0) {
                    $psaParams.IncludeRule = $IncludeRules
                }
                
                # Add exclude rules
                if ($ExcludeRules.Count -gt 0) {
                    $psaParams.ExcludeRule = $ExcludeRules  
                }
                
                # Add custom rule path
                if ($CustomRulePath -and (Test-Path $CustomRulePath)) {
                    $psaParams.CustomRulePath = $CustomRulePath
                }
                
                # Enable exit code if requested
                if ($EnableExit) {
                    $psaParams.EnableExit = $true
                }
                
                try {
                    $fileResults = Invoke-ScriptAnalyzer @psaParams
                    $allPsaResults += $fileResults
                    Write-Verbose "PSScriptAnalyzer completed for $($file.Name): $($fileResults.Count) issues"
                } catch {
                    Write-Warning "PSScriptAnalyzer failed for $($file.FullName): $_"
                }
            }
            
            # Set results from individual file processing
            $psaResults = $allPsaResults
            $executionSuccessful = $true
            $exitCode = 0
            
            $endTime = Get-Date
            $executionTime = ($endTime - $startTime).TotalSeconds
            
            Write-Verbose "PSScriptAnalyzer completed in $executionTime seconds with $($psaResults.Count) issues found"
            
            # Convert to SARIF format
            $sarifResults = @()
            $ruleIndex = @{}
            $ruleArray = @()
            
            # Get all available rules for reference
            $allRules = Get-ScriptAnalyzerRule
            
            foreach ($result in $psaResults) {
                # Map PSScriptAnalyzer severity to SARIF level
                $sarifLevel = switch ($result.Severity) {
                    'Error' { 'error' }
                    'Warning' { 'warning' }
                    'Information' { 'note' }
                    'ParseError' { 'error' }
                    default { 'warning' }
                }
                
                # Create rule if not exists
                $ruleId = $result.RuleName
                if (-not $ruleIndex.ContainsKey($ruleId)) {
                    $ruleIndex[$ruleId] = $ruleArray.Count
                    
                    # Find detailed rule information
                    $ruleInfo = $allRules | Where-Object { $_.RuleName -eq $ruleId } | Select-Object -First 1
                    
                    $ruleObj = [PSCustomObject]@{
                        id = $ruleId
                        name = $ruleId
                        shortDescription = [PSCustomObject]@{
                            text = if ($ruleInfo.Description) { $ruleInfo.Description } else { $result.Message }
                        }
                        fullDescription = [PSCustomObject]@{
                            text = if ($ruleInfo.Description) { $ruleInfo.Description } else { $result.Message }
                        }
                        helpUri = "https://github.com/PowerShell/PSScriptAnalyzer/blob/master/RuleDocumentation/$ruleId.md"
                        properties = [PSCustomObject]@{
                            category = if ($ruleInfo.SourceName) { $ruleInfo.SourceName } else { 'PSScriptAnalyzer' }
                            tags = @('powershell', 'style', 'best-practice')
                        }
                    }
                    
                    $ruleArray += $ruleObj
                }
                
                # Create SARIF result
                $sarifResult = [PSCustomObject]@{
                    ruleId = $ruleId
                    ruleIndex = $ruleIndex[$ruleId]
                    level = $sarifLevel
                    message = [PSCustomObject]@{
                        text = $result.Message
                    }
                    locations = @([PSCustomObject]@{
                        physicalLocation = [PSCustomObject]@{
                            artifactLocation = [PSCustomObject]@{
                                uri = ($result.ScriptName -replace '\\', '/') -replace '^.*/', ''  # Relative path
                            }
                            region = [PSCustomObject]@{
                                startLine = $result.Line
                                startColumn = $result.Column
                                endLine = if ($result.EndLine) { $result.EndLine } else { $result.Line }
                                endColumn = if ($result.EndColumn) { $result.EndColumn } else { ($result.Column + $result.Extent.Text.Length) }
                            }
                        }
                    })
                }
                
                # Add PSScriptAnalyzer-specific properties
                $sarifResult | Add-Member -NotePropertyName 'properties' -NotePropertyValue ([PSCustomObject]@{
                    psScriptAnalyzerRuleName = $result.RuleName
                    psScriptAnalyzerSeverity = $result.Severity.ToString()
                    scriptName = $result.ScriptName
                    extent = $result.Extent.Text
                })
                
                # Add suggested corrections if available
                if ($result.SuggestedCorrections -and $result.SuggestedCorrections.Count -gt 0) {
                    $fixes = @()
                    foreach ($correction in $result.SuggestedCorrections) {
                        $fixes += [PSCustomObject]@{
                            description = [PSCustomObject]@{
                                text = $correction.Description
                            }
                            artifactChanges = @([PSCustomObject]@{
                                artifactLocation = [PSCustomObject]@{
                                    uri = ($result.ScriptName -replace '\\', '/') -replace '^.*/', ''
                                }
                                replacements = @([PSCustomObject]@{
                                    deletedRegion = [PSCustomObject]@{
                                        startLine = $correction.StartLineNumber
                                        startColumn = $correction.StartColumnNumber
                                        endLine = $correction.EndLineNumber
                                        endColumn = $correction.EndColumnNumber
                                    }
                                    insertedContent = [PSCustomObject]@{
                                        text = $correction.Text
                                    }
                                })
                            })
                        }
                    }
                    $sarifResult | Add-Member -NotePropertyName 'fixes' -NotePropertyValue $fixes
                }
                
                $sarifResults += $sarifResult
            }
            
            # Get PSScriptAnalyzer version
            $psaModule = Get-Module PSScriptAnalyzer
            $psaVersion = if ($psaModule) { $psaModule.Version.ToString() } else { 'unknown' }
            
            # Create SARIF run object
            $sarifRun = [PSCustomObject]@{
                tool = [PSCustomObject]@{
                    driver = [PSCustomObject]@{
                        name = 'PSScriptAnalyzer'
                        fullName = 'PowerShell Script Analyzer'
                        version = $psaVersion
                        informationUri = 'https://github.com/PowerShell/PSScriptAnalyzer'
                        rules = $ruleArray
                    }
                }
                results = $sarifResults
                columnKind = 'unicodeCodePoints'
            }
            
            # Add execution metadata
            $sarifRun | Add-Member -NotePropertyName 'invocations' -NotePropertyValue @([PSCustomObject]@{
                executionSuccessful = $executionSuccessful
                exitCode = $exitCode
                startTimeUtc = $startTime.ToUniversalTime().ToString('o')
                endTimeUtc = $endTime.ToUniversalTime().ToString('o')
                machine = $env:COMPUTERNAME
                workingDirectory = [PSCustomObject]@{
                    uri = $PWD.Path -replace '\\', '/'
                }
                commandLine = "Invoke-ScriptAnalyzer -Path '$Path'"
            })
            
            # Add file-level metrics
            $fileMetrics = @()
            $fileGroups = $psaResults | Group-Object ScriptName
            
            foreach ($fileGroup in $fileGroups) {
                $fileMetrics += [PSCustomObject]@{
                    file = ($fileGroup.Name -replace '\\', '/') -replace '^.*/', ''
                    issueCount = $fileGroup.Count
                    errorCount = ($fileGroup.Group | Where-Object { $_.Severity -eq 'Error' }).Count
                    warningCount = ($fileGroup.Group | Where-Object { $_.Severity -eq 'Warning' }).Count
                    infoCount = ($fileGroup.Group | Where-Object { $_.Severity -eq 'Information' }).Count
                }
            }
            
            $sarifRun | Add-Member -NotePropertyName 'properties' -NotePropertyValue ([PSCustomObject]@{
                fileMetrics = $fileMetrics
                totalFiles = $targetFiles.Count
                analyzedFiles = $fileGroups.Count
                executionTimeSeconds = $executionTime
            })
            
            Write-Verbose "Enhanced PSScriptAnalyzer analysis complete: $($sarifResults.Count) issues found across $($fileGroups.Count) files"
            
            return [PSCustomObject]@{
                runs = @($sarifRun)
            }
            
        } catch {
            Write-Error "Enhanced PSScriptAnalyzer analysis failed: $_"
            
            # Return proper SARIF structure even on critical failure
            return [PSCustomObject]@{
                runs = @([PSCustomObject]@{
                    tool = [PSCustomObject]@{
                        driver = [PSCustomObject]@{
                            name = 'PSScriptAnalyzer'
                            version = 'unknown'
                            informationUri = 'https://github.com/PowerShell/PSScriptAnalyzer'
                        }
                    }
                    results = @()
                    columnKind = 'unicodeCodePoints'
                    invocations = @([PSCustomObject]@{
                        executionSuccessful = $false
                        exitCode = 1
                        machine = $env:COMPUTERNAME
                        commandLine = "PSScriptAnalyzer analysis failed"
                    })
                })
            }
        }
    }
    
    end {
        Write-Verbose "Enhanced PSScriptAnalyzer analysis completed"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC7MDSBE9r/XtLt
# lDJsAE7dDISz0vCd09cC5L/SHRBl2KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIM+XQyCNZimBiuADaOsLaAWu
# rILjtp8yghPvOLHeWyPnMA0GCSqGSIb3DQEBAQUABIIBAA/feUmfZXPUV6UR55Wq
# 8QaIjWFT/uqMZIgnLSRikugXW7i9OkmjVqNFpvMN7HTaIpuUL2Y86PYNuaCAlqtA
# jZgTJqLa0/wdpqLOBYd0qP+GwjRIjEj0eRKeb4gcILlXnQhQKqWFxHYeufhLFXWu
# wf2Tt3WLi+YAGztT/rS4lkxODsD0oR+sUyVNi+0wiPzSytlIigDeHS2HEpk0+6C5
# lTHGA4Qa9KAK7M3HvyM5S8ZCrV7EVnubV9NGag97zOr6Ja3IjEkBsiE8FWu1/mZh
# gdj/jcjjbiCQpWk3VvvKXMHEVRMwoSVwUOlcBbqzdBlCROGQBFgnfdW0ey1wfynz
# 798=
# SIG # End signature block
