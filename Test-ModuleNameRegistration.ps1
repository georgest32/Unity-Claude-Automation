# Test Module Name Registration
Write-Host "Testing module name registration issues:" -ForegroundColor Cyan
Write-Host ""

# Test cases for problematic modules
$testCases = @(
    @{
        Name = "Unity-Claude-PredictiveAnalysis"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-PredictiveAnalysis\Unity-Claude-PredictiveAnalysis.psd1"
    },
    @{
        Name = "Unity-Claude-ObsolescenceDetection" 
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CPG\Unity-Claude-ObsolescenceDetection-Refactored.psd1"
    },
    @{
        Name = "Unity-Claude-AutonomousStateTracker-Enhanced"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousStateTracker-Enhanced\Unity-Claude-AutonomousStateTracker-Enhanced-Refactored.psd1"
    },
    @{
        Name = "IntelligentPromptEngine"
        Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent\IntelligentPromptEngine-Refactored.psd1"
    }
)

foreach ($test in $testCases) {
    Write-Host "Testing: $($test.Name)" -ForegroundColor Yellow
    
    # Remove any existing modules
    Get-Module -All | Remove-Module -Force -ErrorAction SilentlyContinue
    
    # Import the module
    try {
        Import-Module $test.Path -Force -Global 2>$null
        
        # Check what modules are actually loaded
        $loadedModules = Get-Module
        
        Write-Host "  Expected name: $($test.Name)" -ForegroundColor Cyan
        Write-Host "  Actual modules loaded:" -ForegroundColor Green
        foreach ($mod in $loadedModules) {
            Write-Host "    - $($mod.Name)" -ForegroundColor White
            if ($mod.Name -eq $test.Name) {
                Write-Host "      [MATCH]" -ForegroundColor Green
            }
        }
        
        # Try to find by expected name
        $foundByName = Get-Module $test.Name -ErrorAction SilentlyContinue
        if ($foundByName) {
            Write-Host "  Result: Module found with expected name" -ForegroundColor Green
        } else {
            Write-Host "  Result: Module NOT found with expected name" -ForegroundColor Red
            Write-Host "  This is why the test script fails!" -ForegroundColor Magenta
        }
        
    } catch {
        Write-Host "  Error importing: $_" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "ANALYSIS:" -ForegroundColor Cyan
Write-Host "The test script looks for modules by their expected names," -ForegroundColor White
Write-Host "but some modules register with different names after import." -ForegroundColor White
Write-Host ""
Write-Host "SOLUTIONS:" -ForegroundColor Cyan
Write-Host "1. Fix Test-AllRefactoredModules.ps1 to check for actual module names" -ForegroundColor White
Write-Host "2. OR update module manifests to use consistent names" -ForegroundColor White
Write-Host "3. OR add ActualModuleName property to test configuration" -ForegroundColor White
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDKBNSBdBN61QrK
# 4l9qhKjHwSe+f9ARHx/4Rj3eXiDQjKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJqhpgwaHvAYzb+09EoGkmub
# G00TDpiLpwLG8pW+fDrwMA0GCSqGSIb3DQEBAQUABIIBAEilf/5z+nbX953ekr43
# mva2xPd0boXQSibDA8HF53tTO0KsgTIijW1l2bIkMVvkBeoIjfZnA56Ak7ec9xA5
# OKFaGYloCRWUDAhI6EAFf0wBiDD7EYYbsSOFVoj9DGCZQ+Yqyg9Q1mwOthM3Iai8
# zhJVuatboLPBYVVttlV73OLzjs2W+nTCYqxty2YCrzqRFIP2g1p1hb0LGWjW+viI
# N+dSAR3Fji6uSkNsEbAY3SpuIRgmp0DYsMqBmQXOgNqPj/DgDQDQRPoTOvDNQJep
# 1KPfC2G2f5gMCmI2cPk48v6COl+Z+ONEqckxQ4OR49AOohzZNAXIVs84aQ5iIFH3
# QF8=
# SIG # End signature block
