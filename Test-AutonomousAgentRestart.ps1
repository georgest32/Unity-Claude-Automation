# Test-AutonomousAgentRestart.ps1
# Tests if SystemStatusMonitoring automatically restarts the AutonomousAgent
# Date: 2025-08-21

param(
    [switch]$Force
)

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "AutonomousAgent Auto-Restart Test" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# First, check if the monitoring job is running (try both naming conventions)
$monitoringJob = Get-Job -Name "SystemStatusMonitoring" -ErrorAction SilentlyContinue
if (-not $monitoringJob) {
    # Try alternate name
    $monitoringJob = Get-Job | Where-Object { $_.Name -like "*SystemStatus*" -and $_.State -eq "Running" } | Select-Object -First 1
}

if (-not $monitoringJob) {
    Write-Host "ERROR: SystemStatusMonitoring job is not running!" -ForegroundColor Red
    Write-Host "Please run Start-UnifiedSystem-Complete.ps1 first" -ForegroundColor Yellow
    exit 1
}

Write-Host "SystemStatusMonitoring Job Status:" -ForegroundColor Cyan
Write-Host "  Job ID: $($monitoringJob.Id)" -ForegroundColor Gray
Write-Host "  State: $($monitoringJob.State)" -ForegroundColor Gray
Write-Host ""

# Reload the module in the job to get new functions
if ($Force) {
    Write-Host "Restarting SystemStatusMonitoring job to load new functions..." -ForegroundColor Yellow
    
    # Stop the old job
    Stop-Job -Name "SystemStatusMonitoring" -ErrorAction SilentlyContinue
    Remove-Job -Name "SystemStatusMonitoring" -Force -ErrorAction SilentlyContinue
    
    Write-Host "Starting new SystemStatusMonitoring job..." -ForegroundColor Yellow
    
    # Start new job with the updated module
    & ".\Start-UnifiedSystem-Complete.ps1" -SkipAutonomousAgent
    
    Start-Sleep -Seconds 5
    
    $monitoringJob = Get-Job -Name "SystemStatusMonitoring" -ErrorAction SilentlyContinue
    if ($monitoringJob) {
        Write-Host "New SystemStatusMonitoring job started: ID $($monitoringJob.Id)" -ForegroundColor Green
    }
}

# Check if AutonomousAgent is currently running
Write-Host "Checking current AutonomousAgent status..." -ForegroundColor Cyan

# Import the module to use the test function
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force

$agentRunning = Test-AutonomousAgentStatus

if ($agentRunning) {
    Write-Host "AutonomousAgent is currently RUNNING" -ForegroundColor Green
    
    # Get the process ID (check both naming conventions)
    $status = Read-SystemStatus
    $agentPid = $null
    if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
        $agentPid = $status.Subsystems["AutonomousAgent"].ProcessId
    }
    elseif ($status.Subsystems.ContainsKey("Unity-Claude-AutonomousAgent")) {
        $agentPid = $status.Subsystems["Unity-Claude-AutonomousAgent"].ProcessId
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
    elseif ($status.Subsystems.ContainsKey("Unity-Claude-AutonomousAgent")) {
        $newPid = $status.Subsystems["Unity-Claude-AutonomousAgent"].ProcessId
    }
    Write-Host "  New Process ID: $newPid" -ForegroundColor Green
    
    # Check the job output for restart messages
    Write-Host ""
    Write-Host "SystemStatusMonitoring Job Output:" -ForegroundColor Cyan
    $jobOutput = Receive-Job -Id $monitoringJob.Id -Keep | Select-Object -Last 20
    $jobOutput | Where-Object { $_ -match "AutonomousAgent" } | ForEach-Object {
        Write-Host "  $_" -ForegroundColor Gray
    }
}
else {
    Write-Host "FAILURE: AutonomousAgent was NOT restarted within $timeout seconds" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Check the job output:" -ForegroundColor Gray
    Write-Host "   Receive-Job -Id $($monitoringJob.Id) -Keep | Select-Object -Last 50" -ForegroundColor Gray
    Write-Host ""
    Write-Host "2. Check the log files:" -ForegroundColor Gray
    Write-Host "   Get-Content .\SystemStatusMonitoring_Job_*.log -Tail 50" -ForegroundColor Gray
    Write-Host ""
    Write-Host "3. Manually start the agent:" -ForegroundColor Gray
    Write-Host "   Start-AutonomousAgentSafe" -ForegroundColor Gray
    Write-Host ""
    Write-Host "4. Restart monitoring with -Force flag:" -ForegroundColor Gray
    Write-Host "   .\Test-AutonomousAgentRestart.ps1 -Force" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Test complete!" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUklymArNZbx2n6cYUxCaQsPNy
# M7ygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUzNUPmNzL57Mt7kW15DNw5vpEY2kwDQYJKoZIhvcNAQEBBQAEggEAS6Nb
# +lb5eCEQHsrTRfFdu2BTt9EYU+vozcTG8pcicvAyszWU47C5CrgYd3wGOOGC343y
# zzaBrkwBjBNQw+szAPz+HaDUrs5X0ObMgyr0Ns3+eS5ti5lWnzpIfbtdnU9P0sA0
# vRFooYLfVlz/DXRavAaGhNU+guioaCdbfu8qXt3VUXFcSC/oWYsDhcxX6qPxfMb3
# PlAW4KxmtJxzl3TsPDS5XYzU0C+oFFH6cI6AcTkBvWJiE/2/AvX/5zfmMXCVMFwg
# X3sDzgeL8QbZ6SZW87oeai/pkfJVaKVwf8RWnhnwnrkcj80JoZMtCa9Ko1fuSZ3y
# 7n/nxv+NVoJ4nvJK0g==
# SIG # End signature block
