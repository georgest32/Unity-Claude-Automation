# Check-ClaudeParallelizationFunctions.ps1
# Checks actual function parameters for Claude Parallelization module
# Date: 2025-08-21

$env:PSModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules;" + $env:PSModulePath
Import-Module Unity-Claude-ClaudeParallelization -Force

Write-Host "=== Claude Parallelization Function Parameters ===" -ForegroundColor Cyan

# Check New-ClaudeCLIParallelManager
$func = Get-Command New-ClaudeCLIParallelManager -ErrorAction SilentlyContinue
if ($func) {
    Write-Host "`nNew-ClaudeCLIParallelManager parameters:" -ForegroundColor Yellow
    $func.Parameters.Keys | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
} else {
    Write-Host "New-ClaudeCLIParallelManager not found" -ForegroundColor Red
}

# Check Start-ConcurrentResponseMonitoring
$func = Get-Command Start-ConcurrentResponseMonitoring -ErrorAction SilentlyContinue
if ($func) {
    Write-Host "`nStart-ConcurrentResponseMonitoring parameters:" -ForegroundColor Yellow
    $func.Parameters.Keys | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
} else {
    Write-Host "Start-ConcurrentResponseMonitoring not found" -ForegroundColor Red
}

# Check Test-ClaudeParallelizationPerformance
$func = Get-Command Test-ClaudeParallelizationPerformance -ErrorAction SilentlyContinue
if ($func) {
    Write-Host "`nTest-ClaudeParallelizationPerformance parameters:" -ForegroundColor Yellow
    $func.Parameters.Keys | ForEach-Object { Write-Host "  - $_" -ForegroundColor White }
} else {
    Write-Host "Test-ClaudeParallelizationPerformance not found" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvkZMJLQUWb9CS0P3aoElbyrB
# 8iugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUhb5Fs0+J4WqcC7/dVg4MX0BO6w4wDQYJKoZIhvcNAQEBBQAEggEAl2X8
# opRh84fjBKArbjfqqYRdhLZVaLJC+3XZ8HeJiPY71MUx3/8IYdYRMAv5D7a4bRPj
# 9SX4PuA5wQfAxq9872gjJuD3Zu364dNFq+3Hdrnb7F4iTzbaOtz1SEigv/gSkg6x
# ++zuCm7qakYNFun+agKolIypKNfBtkYPDFZkTRosZuFjrz3ua1jtxNKfXTDIQmWf
# HTINzSGQEzuq0pSAgjT3bGlEfyP3/MITqjRHTVDkPwIZROA5vvGEILCDXJhAxHcB
# M8/exMGghvSQIOL/W+pQLkBnKMDLHJ6kSTc4gdsP5KYUoIsi+HOtLE/fH1B2OrY2
# v4y9a5s7KWUYfLVRwg==
# SIG # End signature block
