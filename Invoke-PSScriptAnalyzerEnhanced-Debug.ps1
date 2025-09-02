function Invoke-PSScriptAnalyzerEnhanced-Debug {
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
        Write-Host "[DEBUG] Starting enhanced PSScriptAnalyzer analysis for path: $Path" -ForegroundColor Cyan
        Write-Host "[DEBUG] Current PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
        Write-Host "[DEBUG] PSModulePath: $env:PSModulePath" -ForegroundColor Cyan
        
        # Check module availability in all locations
        Write-Host "[DEBUG] Checking for PSScriptAnalyzer module..." -ForegroundColor Yellow
        $availableModules = Get-Module -ListAvailable PSScriptAnalyzer -ErrorAction SilentlyContinue
        if ($availableModules) {
            Write-Host "[DEBUG] Found PSScriptAnalyzer modules:" -ForegroundColor Green
            $availableModules | ForEach-Object {
                Write-Host "  - Version: $($_.Version) at $($_.Path)" -ForegroundColor Green
            }
        } else {
            Write-Host "[DEBUG] PSScriptAnalyzer module not found in any module path" -ForegroundColor Red
            
            # Try to install for Windows PowerShell
            Write-Host "[DEBUG] Attempting to install PSScriptAnalyzer for Windows PowerShell..." -ForegroundColor Yellow
            try {
                # Save to Windows PowerShell module path
                $modulePath = "$env:USERPROFILE\Documents\WindowsPowerShell\Modules"
                if (-not (Test-Path $modulePath)) {
                    New-Item -Path $modulePath -ItemType Directory -Force | Out-Null
                }
                
                Save-Module -Name PSScriptAnalyzer -Path $modulePath -Force
                Write-Host "[DEBUG] Saved PSScriptAnalyzer to: $modulePath" -ForegroundColor Green
                
                # Add to PSModulePath if not already there
                if ($env:PSModulePath -notlike "*$modulePath*") {
                    $env:PSModulePath = "$modulePath;$env:PSModulePath"
                    Write-Host "[DEBUG] Added $modulePath to PSModulePath" -ForegroundColor Green
                }
            } catch {
                Write-Host "[DEBUG] Failed to install PSScriptAnalyzer: $_" -ForegroundColor Red
                throw "PSScriptAnalyzer not available and could not be installed: $_"
            }
        }
        
        # Try to import the module
        Write-Host "[DEBUG] Attempting to import PSScriptAnalyzer module..." -ForegroundColor Yellow
        try {
            Import-Module PSScriptAnalyzer -Force -ErrorAction Stop
            Write-Host "[DEBUG] Successfully imported PSScriptAnalyzer" -ForegroundColor Green
            
            # Verify module is loaded
            $loadedModule = Get-Module PSScriptAnalyzer
            if ($loadedModule) {
                Write-Host "[DEBUG] PSScriptAnalyzer loaded: Version $($loadedModule.Version)" -ForegroundColor Green
                
                # List available commands
                $commands = Get-Command -Module PSScriptAnalyzer
                Write-Host "[DEBUG] Available PSScriptAnalyzer commands: $($commands.Name -join ', ')" -ForegroundColor Green
            }
        } catch {
            Write-Host "[DEBUG] Failed to import PSScriptAnalyzer: $_" -ForegroundColor Red
            throw $_
        }
        
        # Test if Invoke-ScriptAnalyzer is available
        Write-Host "[DEBUG] Testing Invoke-ScriptAnalyzer availability..." -ForegroundColor Yellow
        if (Get-Command Invoke-ScriptAnalyzer -ErrorAction SilentlyContinue) {
            Write-Host "[DEBUG] Invoke-ScriptAnalyzer command is available" -ForegroundColor Green
        } else {
            Write-Host "[DEBUG] Invoke-ScriptAnalyzer command is NOT available" -ForegroundColor Red
            throw "Invoke-ScriptAnalyzer command not found after module import"
        }
        
        # Test if Get-ScriptAnalyzerRule is available
        Write-Host "[DEBUG] Testing Get-ScriptAnalyzerRule availability..." -ForegroundColor Yellow
        try {
            $rules = Get-ScriptAnalyzerRule -ErrorAction Stop
            Write-Host "[DEBUG] Found $($rules.Count) PSScriptAnalyzer rules" -ForegroundColor Green
        } catch {
            Write-Host "[DEBUG] Failed to get PSScriptAnalyzer rules: $_" -ForegroundColor Red
        }
    }
    
    process {
        Write-Host "[DEBUG] Starting analysis process..." -ForegroundColor Cyan
        
        try {
            # Build parameters for Invoke-ScriptAnalyzer
            $psaParams = @{
                Path = $Path
                Recurse = $true
                Severity = $Severity
            }
            
            if ($Settings -and (Test-Path $Settings)) {
                $psaParams['Settings'] = $Settings
                Write-Host "[DEBUG] Using settings file: $Settings" -ForegroundColor Green
            }
            
            if ($IncludeRules.Count -gt 0) {
                $psaParams['IncludeRule'] = $IncludeRules
                Write-Host "[DEBUG] Including rules: $($IncludeRules -join ', ')" -ForegroundColor Green
            }
            
            if ($ExcludeRules.Count -gt 0) {
                $psaParams['ExcludeRule'] = $ExcludeRules
                Write-Host "[DEBUG] Excluding rules: $($ExcludeRules -join ', ')" -ForegroundColor Green
            }
            
            if ($CustomRulePath -and (Test-Path $CustomRulePath)) {
                $psaParams['CustomRulePath'] = $CustomRulePath
                Write-Host "[DEBUG] Using custom rules from: $CustomRulePath" -ForegroundColor Green
            }
            
            Write-Host "[DEBUG] Running Invoke-ScriptAnalyzer with parameters:" -ForegroundColor Yellow
            $psaParams.GetEnumerator() | ForEach-Object {
                Write-Host "  $($_.Key): $($_.Value)" -ForegroundColor Yellow
            }
            
            # Run analysis
            $analysisResults = Invoke-ScriptAnalyzer @psaParams
            
            Write-Host "[DEBUG] Analysis completed. Found $($analysisResults.Count) issues" -ForegroundColor Green
            
            # Convert to SARIF format
            $sarif = @{
                version = "2.1.0"
                runs = @(
                    @{
                        tool = @{
                            driver = @{
                                name = "PSScriptAnalyzer"
                                version = (Get-Module PSScriptAnalyzer).Version.ToString()
                                informationUri = "https://github.com/PowerShell/PSScriptAnalyzer"
                            }
                        }
                        results = @()
                    }
                )
            }
            
            # Convert results to SARIF format
            foreach ($issue in $analysisResults) {
                $result = @{
                    ruleId = $issue.RuleName
                    level = switch ($issue.Severity) {
                        'Error' { 'error' }
                        'Warning' { 'warning' }
                        'Information' { 'note' }
                        default { 'note' }
                    }
                    message = @{
                        text = $issue.Message
                    }
                    locations = @(
                        @{
                            physicalLocation = @{
                                artifactLocation = @{
                                    uri = $issue.ScriptPath
                                }
                                region = @{
                                    startLine = $issue.Line
                                    startColumn = $issue.Column
                                }
                            }
                        }
                    )
                }
                
                $sarif.runs[0].results += $result
            }
            
            Write-Host "[DEBUG] Converted to SARIF format successfully" -ForegroundColor Green
            return $sarif
            
        } catch {
            Write-Host "[DEBUG] Error during analysis: $_" -ForegroundColor Red
            throw $_
        }
    }
}

# Test the function
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing PSScriptAnalyzer Debug Function" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$testPath = $PSScriptRoot
Write-Host "[INFO] Testing with path: $testPath" -ForegroundColor Yellow

try {
    $result = Invoke-PSScriptAnalyzerEnhanced-Debug -Path $testPath
    Write-Host "[SUCCESS] Analysis completed successfully!" -ForegroundColor Green
    Write-Host "[INFO] SARIF results: $($result.runs[0].results.Count) issues found" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Test failed: $_" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA0JEj1p4IKzy/v
# YOA63IjTwdrhGFD7Caoo22XMZW68YKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIB6ibCUz/uhdSQ8PPa1Cp9Z4
# UO1u3oq8hVUTC197QPq3MA0GCSqGSIb3DQEBAQUABIIBAIW/nARiVcdsntWxbRUV
# MFeznaOBLdV7OJbcAmVPxQgqyfulrxATjKldv8oCAWQ0az/wzuKRKMzhka1TrH/q
# vDrjVY/OH6aX204SbimV8XOhlIzxy6knvLDnaoG59eEUrrMXBQxepO0IqyO+xBuN
# j1jLxlx0p7QGRUV7QSf8MOD20A4yzzcTL6+5jKLbY0Axr8rgXW/fFRPqEtzxEwJz
# 4olITpwp+aqAGdxTZcHLFLJDroa95rQ322MnFHVu2cRwK5G8yrkVi3onS0V42s7y
# YhMugOthL9tN7W/+/nqVxjjqR9I9UXJikQddP8Rv76wputgvHFtGbcaK0M75l9Oh
# 6M0=
# SIG # End signature block
