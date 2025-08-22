# Test-SimpleRegistration.ps1
# Test simple PID registration

$ErrorActionPreference = "Continue"

Write-Host "Testing Simple Registration" -ForegroundColor Cyan

# Load the module
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force

# Register with a test PID
$testPID = $PID
Write-Host "Registering with PID: $testPID" -ForegroundColor Yellow

$result = Register-Subsystem -SubsystemName "AutonomousAgent" `
    -ModulePath ".\Modules\Unity-Claude-AutonomousMonitoring" `
    -ProcessId $testPID

Write-Host "Registration result: $result" -ForegroundColor Gray

# Check if file was created
if (Test-Path ".\system_status.json") {
    Write-Host "[PASS] system_status.json created" -ForegroundColor Green
    
    $content = Get-Content ".\system_status.json" -Raw | ConvertFrom-Json
    if ($content.subsystems.AutonomousAgent.ProcessId -eq $testPID) {
        Write-Host "[PASS] PID $testPID correctly stored" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] PID not stored correctly" -ForegroundColor Red
        Write-Host "Expected: $testPID" -ForegroundColor Red
        Write-Host "Got: $($content.subsystems.AutonomousAgent.ProcessId)" -ForegroundColor Red
    }
} else {
    Write-Host "[FAIL] system_status.json not created" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUqT7RPwqYQPIw3SYkJcyA0eQn
# 0oegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUOk128QRTd5Oxf/OxmfItrfeC7owwDQYJKoZIhvcNAQEBBQAEggEAMsIN
# 6Hy88T40AsAaLdgaNI0F9sZpBIKk4xULw4za2UHngVISaYYyO1eD2R9DQdI3msD/
# RCS/QkWWQbO3aCvwEiersab6Kwnet9cQmdLmvyHvdrf6PC9A+DvtQg0oU2jAkUrO
# O6XrLiISma5oXWgZ0cQWNYVW1IApBXYodT+xtZ0Hc2dfAnNB32RZ8lPu2zONKxUT
# MJZudFJOu/ZNPye3famFTzuqW+qYQoFi0A3bedz5RLSg1Q7jMbFYxdC2eIXxye4v
# xDCs4k0+iDazk5+1pPBSkt9sCSdPNzuwpHt9UCnArAVAFfoTvej0DHYiYJC/6jjl
# oXwbraIbaYabz6W8pQ==
# SIG # End signature block
