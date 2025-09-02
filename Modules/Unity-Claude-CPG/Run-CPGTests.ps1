#Requires -Version 7.0
<#
.SYNOPSIS
    Runs the Unity-Claude-CPG module tests with proper Pester version.

.DESCRIPTION
    This script ensures tests are run with PowerShell 7 and Pester v5.
    Run this instead of executing the test file directly.

.EXAMPLE
    .\Run-CPGTests.ps1
#>

# Ensure we're using Pester v5
Import-Module Pester -RequiredVersion 5.7.1 -ErrorAction Stop

# Run the tests
$testPath = Join-Path $PSScriptRoot "Unity-Claude-CPG.Tests.ps1"

Write-Host "Running Unity-Claude-CPG Tests with Pester v5..." -ForegroundColor Cyan
Write-Host "Test file: $testPath" -ForegroundColor Gray
Write-Host ""

# Run tests with detailed output
Invoke-Pester -Path $testPath -Output Detailed

Write-Host ""
Write-Host "To run tests in PowerShell 5.1, upgrade Pester or use:" -ForegroundColor Yellow
Write-Host "  pwsh -Command `"& '$PSCommandPath'`"" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDQFpomdZsijFlP
# qf/JSMpCzCX7LEokxVBkSqIXBvKaQaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIH3wftofVlrW84Y53Zj3EKnJ
# wzEpT77feqyi7dwzS6o6MA0GCSqGSIb3DQEBAQUABIIBAKgdWIgzwDoEHhEh+pgD
# +QkQGOkwmRFS82EIQHNEq3TIVvmIisHkdYR8dp2eOuLgsdJ+Cg9w2NWXgOoOU0qO
# AjU56ZXizjRi2xWdHQDYSZsHnXSXnPNxNQKjK52OOx9TSnsKCDNbAGcuF+UgtW7u
# 2I9kvAYm6uet3OLWh+j/J6DK9dJx05iIyS4fZFIyaNuSXf0v4aNBcl9+dtPkyRlT
# r7182ZCkwtSLbarRFey9hBnLHA8mKZgpBIfUxI1C/9FJUyTneCXMxOmhJQEtvhGt
# lh8VHTSAMEMYJLHxz1/BtwHsrmJcZe7eF/C6vleMGm9vrKWRHaKtvMcHp3npAAEd
# eDM=
# SIG # End signature block
