# Test-FixedDuplicatePrevention.ps1
# Tests that the fixed duplicate prevention actually works

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TESTING FIXED DUPLICATE PREVENTION" -ForegroundColor Cyan  
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

# Clean slate
Write-Host "Cleanup: Killing any existing agents..." -ForegroundColor Yellow
Get-Process | Where-Object { $_.MainWindowTitle -like "*AUTONOMOUS*" -or $_.MainWindowTitle -like "*MONITOR*" } | ForEach-Object {
    Write-Host "  Killing: $($_.ProcessName) (PID: $($_.Id))" -ForegroundColor Gray
    Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Seconds 2

# Clear registration
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force
$status = Read-SystemStatus
if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
    $status.Subsystems.Remove("AutonomousAgent")
    Write-SystemStatus -StatusData $status
    Write-Host "  Cleared existing registration" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Test: Starting two agents rapidly" -ForegroundColor Yellow

# Start first agent
Write-Host "  Starting Agent 1..." -ForegroundColor Gray
$agent1 = Start-Process -FilePath "powershell.exe" -ArgumentList @(
    "-NoExit",
    "-ExecutionPolicy", "Bypass",
    "-File", ".\Start-AutonomousMonitoring-Fixed.ps1"
) -WorkingDirectory "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation" -PassThru

Write-Host "  Agent 1 wrapper: $($agent1.Id)" -ForegroundColor Gray
Write-Host "  Waiting 5 seconds for registration..." -ForegroundColor Gray
Start-Sleep -Seconds 5

# Check registration
$status = Read-SystemStatus
if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
    $pid1 = $status.Subsystems["AutonomousAgent"].ProcessId
    Write-Host "  Agent 1 registered with PID: $pid1" -ForegroundColor Green
}

# Start second agent (should kill first)
Write-Host ""
Write-Host "  Starting Agent 2 (should kill Agent 1)..." -ForegroundColor Gray
$agent2 = Start-Process -FilePath "powershell.exe" -ArgumentList @(
    "-NoExit",
    "-ExecutionPolicy", "Bypass",
    "-File", ".\Start-AutonomousMonitoring-Fixed.ps1"
) -WorkingDirectory "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation" -PassThru

Write-Host "  Agent 2 wrapper: $($agent2.Id)" -ForegroundColor Gray
Write-Host "  Waiting 5 seconds for duplicate prevention..." -ForegroundColor Gray
Start-Sleep -Seconds 5

# Check results
Write-Host ""
Write-Host "Results:" -ForegroundColor Yellow

# Count running agents
$runningAgents = @()
Get-Process | Where-Object { $_.MainWindowTitle -like "*AUTONOMOUS MONITORING*" } | ForEach-Object {
    $runningAgents += $_
    Write-Host "  Found running agent: PID $($_.Id)" -ForegroundColor Gray
}

if ($runningAgents.Count -eq 1) {
    Write-Host "  SUCCESS: Only one agent running!" -ForegroundColor Green
    Write-Host "  DUPLICATE PREVENTION WORKING!" -ForegroundColor Green
} elseif ($runningAgents.Count -eq 0) {
    Write-Host "  WARNING: No agents running" -ForegroundColor Yellow
} else {
    Write-Host "  FAILURE: $($runningAgents.Count) agents running!" -ForegroundColor Red
    Write-Host "  DUPLICATE PREVENTION FAILED!" -ForegroundColor Red
}

# Check registration
$status = Read-SystemStatus
if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
    $currentPid = $status.Subsystems["AutonomousAgent"].ProcessId
    Write-Host "  Registered PID: $currentPid" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Cleanup:" -ForegroundColor Yellow
@($agent1, $agent2) | ForEach-Object {
    if ($_ -and (Get-Process -Id $_.Id -ErrorAction SilentlyContinue)) {
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        Write-Host "  Killed process: $($_.Id)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUesG5Uh4uZXwyODBE0BTwQOcf
# z/OgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUxFNQ68bVNrrCvWkDd6o2YTHuq2cwDQYJKoZIhvcNAQEBBQAEggEAEvBo
# BAG3iCcXLK35kEF3dhaLC/xAywA1glrMQlinMAM2tztR+55fQBN+IRfStaXh9FpU
# PmFo+ns0uV86LoQi/9D8H7nOs30qhc2Uz0L41equMILjM6ExkWESfYJLD1fNQkem
# inUiO3KTgXT4RVdsFYz/bJ/FRw/J2eXLzQTwCxq9q62VDc1ysP+kyfZL8JrCYTDV
# xYTv+CE4nYRs6WpTlr1uPX3s+3y3M+m6WM0fPfjmOwR/1E9bhVtt6/QKiBidy7Bf
# HEYbAYdmD3abrPn0RwUw3r08x7uqkKmz5yW//Pr7ubI6ztM3b/mIaVv7nFAF0FBb
# glNbslh3HqpU+YgAFg==
# SIG # End signature block
