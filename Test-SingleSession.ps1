# Test in single session

Import-Module "$PSScriptRoot\Modules\Unity-Claude-MessageQueue\Unity-Claude-MessageQueue.psm1" -Force

Write-Host "Adding messages..." -ForegroundColor Cyan
Add-MessageToQueue -QueueName 'TestSession' -Message 'Hello' -MessageType 'Test' -Priority 5 | Out-Null
Add-MessageToQueue -QueueName 'TestSession' -Message 'World' -MessageType 'Test' -Priority 5 | Out-Null

Write-Host "Retrieving messages..." -ForegroundColor Cyan
$msg1 = Get-MessageFromQueue -QueueName 'TestSession' -TimeoutSeconds 1
$msg2 = Get-MessageFromQueue -QueueName 'TestSession' -TimeoutSeconds 1

if ($msg1) {
    Write-Host "Message 1: $($msg1.Content)" -ForegroundColor Green
} else {
    Write-Host "Message 1: NOT RETRIEVED" -ForegroundColor Red
}

if ($msg2) {
    Write-Host "Message 2: $($msg2.Content)" -ForegroundColor Green
} else {
    Write-Host "Message 2: NOT RETRIEVED" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAsm/tHwSdiNxGf
# tpC+w1KzXMncwGt0LL1bGd96NC1A9KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBBaiSnBC7in8tuc0OMMuwvD
# 2BsqqLJDr1oDJNhCUEOrMA0GCSqGSIb3DQEBAQUABIIBAHhxV6fS63CTnWIcJbgP
# mBvZGF6oyXyjd1EBIttXHLwalRpb4PzvycoOOttqP7wpfqvVTKduvrDxbHEliFMN
# h6pwX1vrHTUMqOBWWK32ilAuh6aHqLUFOYMDUPNPkF2LdEhIbt7QZdirrjnEtBft
# i9tCvOEpIVcSImzw1RK9MC7qBR5///UWr/DA+kPgMGN7BZ7OSz9q3Dwm/xVEdGRw
# 8KALRLgDTpPiTex96o3nV3vlhTj+tO4s16QZ+lYtF2qg07VffUuDdaXyJ9bITd8v
# 5e+faHmZq7khkYOvGeFUfgZKP8CvTyy46nUz8GYzQMJLfuB8kSfUcvmw/7bG6i/L
# AaU=
# SIG # End signature block
