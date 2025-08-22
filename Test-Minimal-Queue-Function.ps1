# Test-Minimal-Queue-Function.ps1
# Minimal test to isolate the issue

# Define function directly in script (not in module)
function Test-CreateQueue {
    $queue = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
    $queue
}

Write-Host "=== Minimal Queue Function Test ===" -ForegroundColor Cyan

# Test 1: Direct function call (not from module)
Write-Host "`nTest 1: Direct function call" -ForegroundColor Yellow
$result1 = Test-CreateQueue
Write-Host "Result 1: '$result1'" -ForegroundColor Gray
Write-Host "Is null: $($null -eq $result1)" -ForegroundColor Gray
if ($result1) {
    Write-Host "Type: $($result1.GetType().FullName)" -ForegroundColor Gray
    Write-Host "SUCCESS: Direct function works" -ForegroundColor Green
} else {
    Write-Host "FAILED: Direct function returns null" -ForegroundColor Red
}

# Test 2: Direct New-Object call (for comparison)
Write-Host "`nTest 2: Direct New-Object call" -ForegroundColor Yellow
$result2 = New-Object 'System.Collections.Concurrent.ConcurrentQueue[object]'
Write-Host "Result 2: '$result2'" -ForegroundColor Gray
Write-Host "Is null: $($null -eq $result2)" -ForegroundColor Gray
if ($result2) {
    Write-Host "Type: $($result2.GetType().FullName)" -ForegroundColor Gray
    Write-Host "SUCCESS: Direct New-Object works" -ForegroundColor Green
} else {
    Write-Host "FAILED: Direct New-Object returns null" -ForegroundColor Red
}

Write-Host "`n=== End Minimal Test ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUIeP6Bxsno2KwIT1oahAHwIHg
# UmigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUmEfTUjCX39AHajoqlocMPkwN9XIwDQYJKoZIhvcNAQEBBQAEggEAVKVo
# ChzHV5V8qSwKsfeNwy5dOTCgSzZ3MP6jUylClgtU578qmT3N0uR61pNWOtQ5RxUX
# tFAgXdqtIkytZJsYvzzWLpsBQJ7/IcEcvUCyBxHf+tHBsjQVJVr7n93qBx/pTzGn
# qmCnKK79JdJYBYu3gj/ddnwp41y3Kkr6/Px4knh4A8ocH6UQH7mWz7YFQdq954Gw
# 4bSWqMl/8PxmXppRGosBdRP2HwshVolAWgr43GCJQVxbRh7R7GwvPrBC0YJG1AjA
# DlA9jUAFJP47VIVd5zBjKHlL9IPVUTW9YJrV4NfcE/EnmPfLgbZ2eBoAAeidrqw7
# 8Ic3wvaZjSOt5lkBQQ==
# SIG # End signature block
