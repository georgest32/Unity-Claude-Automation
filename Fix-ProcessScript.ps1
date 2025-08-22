# Fix-ProcessScript.ps1
# Removes Unicode characters from Process-UnityErrorWithLearning.ps1
# Date: 2025-08-17

$path = ".\Process-UnityErrorWithLearning.ps1"

Write-Host "Fixing Process-UnityErrorWithLearning.ps1..." -ForegroundColor Yellow

# Read the file
$content = Get-Content -Path $path -Raw

# Replace Unicode characters with ASCII using regex
# Remove all non-ASCII characters
$pattern = '[^\x00-\x7F]+'
$content = [regex]::Replace($content, $pattern, '')

# Create backup
Copy-Item -Path $path -Destination "$path.backup" -Force
Write-Host "Backup created: $path.backup" -ForegroundColor Gray

# Save the fixed version with UTF8 BOM
$content | Set-Content -Path $path -Encoding UTF8

Write-Host "Fixed! Non-ASCII characters removed." -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAT95yHPswFgysBheqPpXU6nH
# 5HagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUFJw7J/1+VrEMkYIx938+P+oKuakwDQYJKoZIhvcNAQEBBQAEggEAmnYk
# kFuziPvPjnchEDVfVI/TMJUImK/XZiBSSln6ve3A58JDO1iyDBvGfvxVTI27hdQI
# 4j0pV9U6xaPOo+v9H/QjSCBGI0W9TZkZXKOTWRAmM30ki+LYRTIveVPEakiFmm13
# W+IDxVoQmbhhdhHXOHh3netNrmdSNzyjosogEngXtsXCRnFNQpGFhu45KR64amAF
# xq8zT9vl7bzyX5fBm59Vm87PQ120GPca9eo5VI/E7Q47eYigdHZ4aLcFTIyl0cTp
# IAmIZSB+y8Jdb203/pB+lXRXPx2oZXuZ4Slw9MRCxMm/OQmj1+v6V4eZ8B3lM9PD
# dfmcnEBPYY4pJo2nSw==
# SIG # End signature block
