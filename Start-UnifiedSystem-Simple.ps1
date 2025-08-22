# Start-UnifiedSystem-Simple.ps1
# Simple unified system startup - monitor handles agent lifecycle
# Date: 2025-08-21

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "UNIFIED SYSTEM STARTUP (SIMPLE)" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Set working directory
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

# Kill any existing agents BEFORE starting monitor
Write-Host "Cleaning up any existing agents..." -ForegroundColor Yellow
Get-Process | Where-Object { 
    $_.MainWindowTitle -like "*AUTONOMOUS*" -or 
    $_.MainWindowTitle -like "*MONITORING*" 
} | ForEach-Object {
    Write-Host "  Killing existing process: $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Gray
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

# Clear any stale registrations
Write-Host "Clearing stale registrations..." -ForegroundColor Yellow
try {
    Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force -ErrorAction SilentlyContinue
    $status = Read-SystemStatus
    if ($status -and $status.subsystems -and $status.subsystems.ContainsKey("AutonomousAgent")) {
        Write-Host "  Removing old AutonomousAgent registration" -ForegroundColor Gray
        $status.subsystems.Remove("AutonomousAgent")
        Write-SystemStatus -StatusData $status
    }
} catch {
    Write-Host "  Could not clear registrations: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Starting SystemStatus Monitor..." -ForegroundColor Cyan
Write-Host "The monitor will:" -ForegroundColor Gray
Write-Host "  1. Detect if AutonomousAgent is running" -ForegroundColor Gray
Write-Host "  2. Automatically start it if not running" -ForegroundColor Gray
Write-Host "  3. Restart it if it crashes" -ForegroundColor Gray
Write-Host "  4. Prevent duplicate agents" -ForegroundColor Gray
Write-Host ""

# Start the SystemStatus monitor
# It will handle starting and monitoring the AutonomousAgent
$monitorScript = ".\Start-SystemStatusMonitoring-Enhanced.ps1"
if (-not (Test-Path $monitorScript)) {
    $monitorScript = ".\Start-SystemStatusMonitoring.ps1"
}

if (Test-Path $monitorScript) {
    Write-Host "Launching monitor: $monitorScript" -ForegroundColor Green
    & $monitorScript
} else {
    Write-Host "ERROR: No SystemStatus monitoring script found!" -ForegroundColor Red
    Write-Host "Expected: Start-SystemStatusMonitoring-Enhanced.ps1 or Start-SystemStatusMonitoring.ps1" -ForegroundColor Red
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "UNIFIED SYSTEM ACTIVE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU7PUnNd0ATSjxeDlgKM0a90J5
# YZagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUSPmv1Alj9RjvsrRB/QRsBBORLGIwDQYJKoZIhvcNAQEBBQAEggEAYFgM
# s1cI05ak13r6idOCZdniuzMTSlA82IuX5q0sKASQE670R/qy9fyr4LBiLF5dRtdR
# JQ6T7Wf5ghRy2AXKhgTmG9iVn0z7J5DAWCjTrQF1H9azoRZj3WCu/Io2f7uIwWld
# Csh5/zTPbCjHD+2NQ5N62lY/AX4XbdJey0gplnC5BFFJGEaPazuNoSbqMDjW0xnx
# g10X8PRkgKPP+sA126yacWiwNcZ+Cn9T6RfLvWg0D3iXOs0Ml7kPZyjM7SQaekGN
# SLocX8Hjlk791tu70YfIDa/i6KUqRviJQsK7BwaR+8C3Ln5scNz/YOVundBSB7A+
# 7IPEMj2XKKVB03FlMA==
# SIG # End signature block
