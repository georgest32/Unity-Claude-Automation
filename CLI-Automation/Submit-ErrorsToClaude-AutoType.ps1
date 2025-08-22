# Submit-ErrorsToClaude-AutoType.ps1
# Simple auto-typing version for Watch-AndReport integration

[CmdletBinding()]
param(
    [string]$ErrorLogPath,
    [string]$ErrorMessage,
    [switch]$AutoSubmit
)

Add-Type -AssemblyName System.Windows.Forms

# Build simple prompt
if ($ErrorMessage) {
    $prompt = "Error detected: $ErrorMessage`n`nPlease analyze and provide a fix."
} elseif ($ErrorLogPath -and (Test-Path $ErrorLogPath)) {
    $errorContent = Get-Content $ErrorLogPath -Raw
    $prompt = "Unity errors detected:`n`n$errorContent`n`nPlease analyze and fix."
} else {
    $prompt = "Unity automation error detected. Please check the latest logs for details."
}

Write-Host "Switching to Claude window in 2 seconds..." -ForegroundColor Yellow
Write-Host "Make sure Claude Code is the next window!" -ForegroundColor Cyan
Start-Sleep -Seconds 2

# Switch to next window
[System.Windows.Forms.SendKeys]::SendWait("%{TAB}")
Start-Sleep -Milliseconds 300

# Clear any existing text (Ctrl+A, Delete)
[System.Windows.Forms.SendKeys]::SendWait("^a")
Start-Sleep -Milliseconds 100
[System.Windows.Forms.SendKeys]::SendWait("{DELETE}")
Start-Sleep -Milliseconds 100

# Type the prompt quickly
$lines = $prompt -split "`n"
foreach ($line in $lines) {
    $escaped = $line -replace '[+^%~(){}[\]]', '{$0}'
    [System.Windows.Forms.SendKeys]::SendWait($escaped)
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Start-Sleep -Milliseconds 20
}

if ($AutoSubmit) {
    # Auto-submit with Enter
    Start-Sleep -Milliseconds 200
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    Write-Host "Submitted to Claude!" -ForegroundColor Green
} else {
    Write-Host "Prompt typed. Press Enter in Claude to submit." -ForegroundColor Yellow
}

Write-Host "Done!" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAI59M/ZlI5+kKE7cnLl9+mxY
# G6ugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUtGHJ4XfO+YyeQ3y3XrIVdGxfUTswDQYJKoZIhvcNAQEBBQAEggEAHwYE
# Z1jyDZg2GnVFooH0kPR8gfxa9ivulE+3TN+2NbOunmYgQ2cso1MQuEJJ76KcSA5u
# T9fuCdAc8brWLjDEPszP6OA1u8Ejm44M200VkAYswfneSZDo0GFNwAycYfiq+jqa
# GmOV2VlyMekI2DHPXwIfxlKSaJDaWt1BIooG6G1k+dotNtuiEs9KVmR3TYZCV5I/
# smTqV8J5c7sFO3VqpJQasRywLXpmBopX4Q+0I3oBQ4L5Ce5VlangweBrYvfGQgrA
# knrONQWnrQXmFBionXvVJFPyMv8mbPaotJk9TO6ewpIEE1oKkMXzEkV5Ur0v8ZRT
# hzHfPfHRUdsDHa+Ssg==
# SIG # End signature block
