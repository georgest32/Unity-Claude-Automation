# Restart-MonitoringJob.ps1
# Restarts the SystemStatusMonitoring job to pick up code changes
# Date: 2025-08-21

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Restarting SystemStatusMonitoring Job" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Stop existing jobs
Write-Host "Stopping existing monitoring jobs..." -ForegroundColor Yellow
Get-Job | Where-Object { $_.Name -like "*SystemStatus*" } | ForEach-Object {
    Write-Host "  Stopping job $($_.Id): $($_.Name)" -ForegroundColor Gray
    Stop-Job -Id $_.Id -ErrorAction SilentlyContinue
    Remove-Job -Id $_.Id -Force -ErrorAction SilentlyContinue
}

Write-Host ""
Write-Host "Starting new SystemStatusMonitoring job..." -ForegroundColor Green

# Start the unified system with bypass execution policy
powershell -ExecutionPolicy Bypass -File ".\Start-UnifiedSystem-Complete.ps1"

Write-Host ""
Write-Host "Monitoring job restarted with auto-restart functionality!" -ForegroundColor Green
Write-Host ""
Write-Host "The monitoring job will now:" -ForegroundColor Cyan
Write-Host "  - Check AutonomousAgent status every 60 seconds" -ForegroundColor Gray
Write-Host "  - Automatically restart it if it crashes or is closed" -ForegroundColor Gray
Write-Host ""
Write-Host "To test auto-restart:" -ForegroundColor Yellow
Write-Host "  1. Run: .\Test-AutonomousAgentSimple.ps1" -ForegroundColor Gray
Write-Host "  2. Or manually close the AutonomousAgent window" -ForegroundColor Gray
Write-Host "  3. Wait up to 60 seconds for auto-restart" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUHdC6SFaJ8Tp4xsVDqihChq8l
# 1EagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUo486bsMsflHQZirL+Y5WrrEOzqgwDQYJKoZIhvcNAQEBBQAEggEASK5C
# WHPe6pFawz/6xvQjKBGkbuC6qNQy4DFTAw//hRvrLEx93S6kPJWPl/XCyO/Bbam8
# DoDlJImZFyWOygYrNCrHhMAdY4lWkVsvr4nfcUghxDnDRF5acNEDTtmP3/yykvhv
# CqTVbvDe4m2sM0QOHHBwIaJ5wjFw5Y3QfxymGhmPucBk24lIUHVhjX68/UvOY/Ww
# 9xUj/1UTWGqas9ScAW7HaaAWTPa38ikFu1Ll4/s5uWxnIiyrXZmsPWOptolTXa81
# JFJu9mpkttRPC017pzyasykKhn1WcqnzpDy5uZ33jC+x+0zUI6SXwG6Di3SJp4zG
# sjx2zJVXHm/qrVP8IQ==
# SIG # End signature block
