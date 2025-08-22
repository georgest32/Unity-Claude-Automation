# Test-AutonomousAgentSimple.ps1
# Simple test to kill AutonomousAgent and wait for restart
# Date: 2025-08-21

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Simple AutonomousAgent Restart Test" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check SystemStatusMonitoring job is running (user said job 251 is running)
Write-Host "Checking if SystemStatusMonitoring is running..." -ForegroundColor Yellow

# Import the module to use the test function
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force

# Check if AutonomousAgent is currently running
Write-Host "Checking current AutonomousAgent status..." -ForegroundColor Cyan

$agentRunning = Test-AutonomousAgentStatus

if ($agentRunning) {
    Write-Host "AutonomousAgent is currently RUNNING" -ForegroundColor Green
    
    # Get the process ID
    $status = Read-SystemStatus
    $agentPid = $null
    if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
        $agentPid = $status.Subsystems["AutonomousAgent"].ProcessId
    }
    
    if ($agentPid) {
        Write-Host "  Process ID: $agentPid" -ForegroundColor Gray
        
        Write-Host ""
        Write-Host "Killing AutonomousAgent to test auto-restart..." -ForegroundColor Yellow
        Stop-Process -Id $agentPid -Force -ErrorAction SilentlyContinue
        
        Write-Host "AutonomousAgent killed." -ForegroundColor Red
    }
}
else {
    Write-Host "AutonomousAgent is NOT running" -ForegroundColor Yellow
    Write-Host "Attempting to start it..." -ForegroundColor Yellow
    Start-AutonomousAgentSafe
}

Write-Host ""
Write-Host "Waiting for SystemStatusMonitoring to detect and restart..." -ForegroundColor Cyan
Write-Host "(This should happen within 60 seconds on the next heartbeat)" -ForegroundColor Gray

# Monitor for up to 90 seconds
$startTime = Get-Date
$timeout = 90
$restartDetected = $false

while (((Get-Date) - $startTime).TotalSeconds -lt $timeout) {
    Write-Host "." -NoNewline
    Start-Sleep -Seconds 5
    
    # Check if agent is running
    if (Test-AutonomousAgentStatus) {
        $restartDetected = $true
        break
    }
}

Write-Host ""
Write-Host ""

if ($restartDetected) {
    Write-Host "SUCCESS: AutonomousAgent was automatically restarted!" -ForegroundColor Green
    
    $status = Read-SystemStatus
    $newPid = $null
    if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
        $newPid = $status.Subsystems["AutonomousAgent"].ProcessId
    }
    Write-Host "  New Process ID: $newPid" -ForegroundColor Green
}
else {
    Write-Host "FAILURE: AutonomousAgent was NOT restarted within $timeout seconds" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Check that SystemStatusMonitoring job is running:" -ForegroundColor Gray
    Write-Host "   Get-Job" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Check job output for job 251:" -ForegroundColor Gray
    Write-Host "   Receive-Job -Id 251 -Keep | Select-Object -Last 50" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Test complete!" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU+JgxB1+Q4Js+EpqYahBFLRit
# jfCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUGDKwjOO5SYWbFSEz9G0T0ok0iVEwDQYJKoZIhvcNAQEBBQAEggEArDs7
# UXTnRp7/CFgVpNe5hsw62tif2mofFuRDLnAFP7/xjL4ztjnPCdGlC+ujA66A4i6L
# 12YeinoQKixTWjfIfbluSILiKrXOdYGlaUEbuDyFkzRvAqHUeY/t3qV7Cqg2uGxo
# NU5pl8TdQwgCnbBrbtXyH5TcrvhyLgv0nU6/42goCWmS3vtEhcfonQEAXKsyiiDf
# wHO4sg2QNKZOfwKULinr4kchwaXOCyBsXxwiNDiEp86oGfUKabSWktFk9yQVX/Q/
# 6zTZ9vpJgF8FM+hxlcRHd/R72YST6Kbu/GBn57KG+fPQT1lwFmJk+LDPHU0TOVBB
# lzw04l1jE+IDaIT4bg==
# SIG # End signature block
