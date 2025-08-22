# Test-SubmitToClaude.ps1
# Quick test script for SendKeys automation

Write-Host ""
Write-Host "================================" -ForegroundColor Cyan
Write-Host " Testing Claude Submission" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

# Create a test error file
$testErrorContent = @"
Unity-Claude Automation Test Errors
Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

[ERROR] CS0246: The type or namespace name 'TestClass' could not be found
[ERROR] CS0117: 'GameObject' does not contain a definition for 'TestMethod'
[ERROR] NullReferenceException at line 42

Please analyze these test errors.
"@

$testErrorFile = Join-Path $PSScriptRoot "test_errors_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$testErrorContent | Set-Content -Path $testErrorFile

Write-Host "Created test error file: $testErrorFile" -ForegroundColor Yellow
Write-Host ""
Write-Host "Options:" -ForegroundColor Cyan
Write-Host "1. Test NextWindow script (Alt+Tab approach)" -ForegroundColor White
Write-Host "2. Test AutoType script (simpler version)" -ForegroundColor White
Write-Host "3. Test SendKeys script (opens new Claude)" -ForegroundColor White
Write-Host "4. Exit" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Select option (1-4)"

switch ($choice) {
    '1' {
        Write-Host "Running NextWindow script..." -ForegroundColor Green
        Write-Host "Make sure Claude Code is the next window!" -ForegroundColor Yellow
        & ".\Submit-ErrorsToClaude-NextWindow.ps1" -ErrorLogPath $testErrorFile -QuickMode
    }
    '2' {
        Write-Host "Running AutoType script..." -ForegroundColor Green
        Write-Host "Make sure Claude Code is the next window!" -ForegroundColor Yellow
        & ".\Submit-ErrorsToClaude-AutoType.ps1" -ErrorLogPath $testErrorFile
    }
    '3' {
        Write-Host "Running SendKeys script..." -ForegroundColor Green
        & ".\Submit-ErrorsToClaude-SendKeys.ps1" -ErrorLogPath $testErrorFile
    }
    '4' {
        Write-Host "Exiting..." -ForegroundColor Gray
        exit
    }
    default {
        Write-Host "Invalid option" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Test complete!" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUylb8HozOKfjK/LIB9rc+IIrN
# BJ+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQURgy+pxtXkGY0a1qwvzISIFch6TwwDQYJKoZIhvcNAQEBBQAEggEAscO9
# GFXPWqGa8vCgsZxkkgkKoWBGc5FXUXa/y17F8cJgnLRGCTQZmGsFBeBEOzShMJx1
# eky8Ga41P/XFBt+2mSaTbQ/gACvyB/sfp4FuL4lUgupwAGysFGyM0P/cv9xHcNsU
# AMY8Sr4ocHOKXfzG9Tb5ZiGT5RaD0YO60zXHcCiL+4EPLbuYGcjgOPzURNMEQZGM
# 4SAk6uhjOSzBPLAKvl4h+NOCbC3NSH9N7Jbft+SS6aabnGtlS78I/bPr6AIZxJJw
# 9W4BQIU/iZTu0jVewhnFcOfX0QZZKxYqOHGdFGExZ7UBPnNBXVoF8SE9COYHnhGS
# EWCTTp1J9N+JWOVBKQ==
# SIG # End signature block
