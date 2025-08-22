# Test-SimpleAutoRestart.ps1
# Test auto-restart with simple monitoring
# Date: 2025-08-21

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "SIMPLE AUTO-RESTART TEST" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "This test will:" -ForegroundColor Yellow
Write-Host "  1. Start the simple monitoring script" -ForegroundColor Gray
Write-Host "  2. Wait for it to detect the agent" -ForegroundColor Gray
Write-Host "  3. Kill the agent" -ForegroundColor Gray
Write-Host "  4. Watch the monitor restart it" -ForegroundColor Gray
Write-Host ""

# Import module to get agent status
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force

# First, check if agent is running
Write-Host "Checking initial agent status..." -ForegroundColor Cyan
$agentRunning = Test-AutonomousAgentStatus

if ($agentRunning) {
    $status = Read-SystemStatus
    $agentPid = $status.Subsystems["AutonomousAgent"].ProcessId
    Write-Host "  Agent is running with PID: $agentPid" -ForegroundColor Green
} else {
    Write-Host "  Agent is not running" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Starting simple monitoring in background..." -ForegroundColor Cyan

# Start monitoring in background job
$monitorJob = Start-Job -Name "SimpleMonitor" -ScriptBlock {
    param($WorkDir)
    Set-Location $WorkDir
    & ".\Start-SimpleMonitoring.ps1" -CheckIntervalSeconds 10
} -ArgumentList $PWD.Path

Write-Host "  Monitor started in job ID: $($monitorJob.Id)" -ForegroundColor Green

# Wait a moment
Write-Host "  Waiting for monitor to initialize..." -ForegroundColor Gray
Start-Sleep -Seconds 3

# Show initial monitor output
Write-Host ""
Write-Host "Initial monitor output:" -ForegroundColor Cyan
Receive-Job -Id $monitorJob.Id -Keep | Select-Object -Last 10 | ForEach-Object {
    Write-Host "  $_" -ForegroundColor Gray
}

if ($agentRunning) {
    Write-Host ""
    Write-Host "Killing agent to test auto-restart..." -ForegroundColor Yellow
    Write-Host "  Killing PID $agentPid..." -ForegroundColor Red
    Stop-Process -Id $agentPid -Force -ErrorAction SilentlyContinue
    Write-Host "  Agent killed!" -ForegroundColor Red
} else {
    Write-Host ""
    Write-Host "Agent not running, monitor should start it..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Waiting for monitor to detect and restart (checking every 5 seconds)..." -ForegroundColor Cyan

$startTime = Get-Date
$timeout = 60
$restartDetected = $false

while (((Get-Date) - $startTime).TotalSeconds -lt $timeout) {
    Start-Sleep -Seconds 5
    
    $elapsed = [int]((Get-Date) - $startTime).TotalSeconds
    Write-Host "  [$elapsed sec] Checking..." -NoNewline
    
    # Check job output for restart message
    $jobOutput = Receive-Job -Id $monitorJob.Id -Keep
    if ($jobOutput -match "Agent RESTARTED|SUCCESS.*restarted") {
        $restartDetected = $true
        Write-Host " RESTART DETECTED!" -ForegroundColor Green
        break
    }
    
    # Also check if agent is actually running
    if (Test-AutonomousAgentStatus) {
        Write-Host " Agent is running!" -ForegroundColor Green
        $restartDetected = $true
        break
    } else {
        Write-Host " Still waiting..." -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan

if ($restartDetected) {
    Write-Host "SUCCESS: Auto-restart worked!" -ForegroundColor Green
    
    $status = Read-SystemStatus
    if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
        $newPid = $status.Subsystems["AutonomousAgent"].ProcessId
        Write-Host "  New agent PID: $newPid" -ForegroundColor Green
    }
    
    # Show restart log
    if (Test-Path ".\agent_restart_log.txt") {
        Write-Host ""
        Write-Host "Restart log:" -ForegroundColor Cyan
        Get-Content ".\agent_restart_log.txt" -Tail 5 | ForEach-Object {
            Write-Host "  $_" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "FAILURE: Agent was not restarted within $timeout seconds" -ForegroundColor Red
}

Write-Host ""
Write-Host "Final monitor output:" -ForegroundColor Cyan
Receive-Job -Id $monitorJob.Id -Keep | Select-Object -Last 20 | ForEach-Object {
    if ($_ -match "SUCCESS|RESTARTED") {
        Write-Host "  $_" -ForegroundColor Green
    } elseif ($_ -match "ERROR|FAIL") {
        Write-Host "  $_" -ForegroundColor Red
    } elseif ($_ -match "WARN|ACTION") {
        Write-Host "  $_" -ForegroundColor Yellow
    } else {
        Write-Host "  $_" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Stopping monitor job..." -ForegroundColor Yellow
Stop-Job -Id $monitorJob.Id
Remove-Job -Id $monitorJob.Id -Force

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To run continuous monitoring, use:" -ForegroundColor Gray
Write-Host "  .\Start-SimpleMonitoring.ps1" -ForegroundColor White
Write-Host ""
Write-Host "To run monitoring with custom interval:" -ForegroundColor Gray  
Write-Host "  .\Start-SimpleMonitoring.ps1 -CheckIntervalSeconds 60" -ForegroundColor White
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/1Qa6GRYoSPr9i3zWwqNNGtS
# sEKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUz3kTsylp8iqAV5/T+gfe6a1dShgwDQYJKoZIhvcNAQEBBQAEggEAqY6M
# GS+dnWtNfoD9054fs/11tfR71y41MHrki6TndjihFA+ULkcFEqkgO018VtXnsq/T
# l5WyP0QB1nGTbCRh/s+D5mbfjGyJ2c3nNy3Q/RIvfTRFO+N0rPUvNi8dr1Y42l1g
# xILNtqCZ14zdJeBBIs09BhZx2nC3Mq9C0RjrAymsOBsKPnWSu1OfIs8qqDILJ8ms
# ekCuQxDdoX25ikMMnIbQjsbocSCxlfT6NzV9PnldelBa4Zo83hfNABl+kljAYPBD
# T+Lo7D25sNKlWMF0VE7VR+cE5QMZ1UoWJROx6PeZ3nUCyG/cNsq8H3jQdnsHQ15T
# 857g1SZTZT4SHPFqSg==
# SIG # End signature block
