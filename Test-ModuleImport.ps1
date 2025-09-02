# Test Module Import Script

# Import modules
$modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-MessageQueue"
Import-Module (Join-Path $modulePath "Unity-Claude-MessageQueue.psm1") -Force
Import-Module (Join-Path $modulePath "Unity-Claude-AgentIntegration.psm1") -Force

Write-Host "Available functions from Unity-Claude-MessageQueue:" -ForegroundColor Cyan
Get-Command -Module Unity-Claude-MessageQueue | Select-Object -ExpandProperty Name

Write-Host ""
Write-Host "Available functions from Unity-Claude-AgentIntegration:" -ForegroundColor Cyan
Get-Command -Module Unity-Claude-AgentIntegration | Select-Object -ExpandProperty Name

Write-Host ""
Write-Host "Testing Add-MessageToQueue parameters:" -ForegroundColor Cyan
(Get-Command Add-MessageToQueue).Parameters.Keys

Write-Host ""
Write-Host "Testing Send-SupervisorMessage directly:" -ForegroundColor Cyan
try {
    Initialize-SupervisorOrchestration -AgentNames @("TestAgent")
    Send-SupervisorMessage -MessageType "Test" -Content @{Test="Data"} -Priority 5
    Write-Host "Success!" -ForegroundColor Green
}
catch {
    Write-Host "Error: $_" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBruDfn2+TPS9pu
# AKr84lHnIc0qqvUrPNOviXAh34CBQKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKtHOEnVdOskJBraSz48HpuK
# NP9CWgDjEikynr0DM2WtMA0GCSqGSIb3DQEBAQUABIIBAEY5F4eciXc+XF+jyxST
# l22X27s0gd++Ifm3OIIU3fgX5YDfnfimbhIvwHh6GzIclmumJmn/u2ZhYYMhEzY+
# 5uS2YmAw0boVt7CJ52DcLdUP76Hk4EG1Dp8X0sT9O8TO5lw07J3cXdOfuXSWBhS0
# vgyQkdrb2V5Sy0AwelzWeh+fwHg88BtnxDVm8vnr7OUVMvAxPnw8fVx2QCSWYru1
# smLEDbfOZdPIGhbmwbu2ZJHW4PIhSfsfYJK1dU7O1nlryhEjVTNiZ4zEstBcj1a2
# c5fZqOryDKGLxMZcApXSSRP7v12oj2dZ1cs39ihv1+BcJAA2c1hlPlS/xonpTRAl
# jUg=
# SIG # End signature block
