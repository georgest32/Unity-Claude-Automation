# Test template generation
$mockError = @{
    ErrorText = "Assets/Scripts/PlayerController.cs(42,10): error CS0103: The name 'playerSpeed' does not exist in the current context"
    Message = "The name 'playerSpeed' does not exist in the current context"
    Code = "CS0103"
    File = "Assets/Scripts/PlayerController.cs"
    Line = 42
    Column = 10
    Project = "TestGame"
    UnityVersion = "2022.3.10f1"
}

Import-Module ./Modules/Unity-Claude-GitHub -Force
$template = Get-GitHubIssueTemplate -UnityError $mockError

Write-Host "===== Generated Issue Template =====" -ForegroundColor Cyan
Write-Host "Title:" -ForegroundColor Yellow
Write-Host "  $($template.Title)"
Write-Host ""
Write-Host "Labels:" -ForegroundColor Yellow
Write-Host "  $($template.Labels -join ', ')"
Write-Host ""
Write-Host "Body:" -ForegroundColor Yellow
$template.Body -split "`n" | ForEach-Object { Write-Host "  $_" }
Write-Host ""

# Check for line number formatting
if ($template.Body -match "Line.*42") {
    Write-Host "Line number found in body" -ForegroundColor Green
} else {
    Write-Host "Line number NOT found in expected format" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBPT7QsyM0mLCoK
# T0SeSDfOZ+826A0VwFiHzy6e7uAuQ6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJzTztF9BCfXan0UWAj0WJ6S
# sHJroQwEqoq/SvKfrtAOMA0GCSqGSIb3DQEBAQUABIIBAK2NIiBA+EBCZ8a9x2QO
# 17GPXgv7wmooIbhirSdadzbliN4ulIjHzbJ6xyPSJcZspbNFqHnpeg+0FK6EUylj
# lTkNVm1phlSSHMGQzybc2w7PyLpNO0Kedh4ywjeL1i6XDVwXptW0N9t/oQyEIUgR
# OxePHxDr5WzosF3A2To6RnbtcEGKERtZJbqUEoPbgRbZd8VIh35mqmqa9ZJeoKi+
# g6n3LJQ5PvyuDcH66WgZzilpXj33+23XLegFv7wpo3f5hizhzwHTJU2yJSRcGG4l
# yxOo821pFms1Xxowd4+4aoErUIZ9rKf1bn+svw59yQZkQiTG5+tjVEl7vHHtcbYQ
# O+U=
# SIG # End signature block
