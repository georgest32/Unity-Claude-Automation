# Test-AutoRestartComplete.ps1
# Comprehensive test for AutonomousAgent auto-restart functionality
# Date: 2025-08-21

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "COMPLETE AUTO-RESTART TEST" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Function to display section headers
function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "--- $Title ---" -ForegroundColor Yellow
}

Write-Section "Step 1: Stop all existing monitoring jobs"
Get-Job | Where-Object { $_.Name -like "*SystemStatus*" -or $_.Name -like "*Monitoring*" } | ForEach-Object {
    Write-Host "  Stopping job $($_.Id): $($_.Name)" -ForegroundColor Gray
    Stop-Job -Id $_.Id -ErrorAction SilentlyContinue
    Remove-Job -Id $_.Id -Force -ErrorAction SilentlyContinue
}

Write-Section "Step 2: Start new monitoring job with proper execution policy"
Write-Host "  Starting SystemStatusMonitoring job..." -ForegroundColor Green

# Start job with bypass execution policy
$jobScript = {
    param($WorkingDir)
    
    Set-Location $WorkingDir
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    
    # Load script content and execute
    $scriptContent = Get-Content ".\Start-UnifiedSystem-Complete.ps1" -Raw
    $scriptBlock = [scriptblock]::Create($scriptContent)
    
    # Execute the monitoring logic from the script
    & $scriptBlock
}

# Start the monitoring job
$monitoringJob = Start-Job -Name "SystemStatusMonitoring" -ScriptBlock $jobScript -ArgumentList $PWD.Path

Write-Host "  Monitoring job started: ID $($monitoringJob.Id)" -ForegroundColor Green
Write-Host "  Waiting for initialization..." -ForegroundColor Gray
Start-Sleep -Seconds 5

Write-Section "Step 3: Check if AutonomousAgent is running"
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force

if (Test-AutonomousAgentStatus) {
    Write-Host "  AutonomousAgent is already running" -ForegroundColor Green
} else {
    Write-Host "  AutonomousAgent is not running, starting it..." -ForegroundColor Yellow
    Start-AutonomousAgentSafe
    Start-Sleep -Seconds 3
}

# Get agent PID
$status = Read-SystemStatus
$agentPid = $null
if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
    $agentPid = $status.Subsystems["AutonomousAgent"].ProcessId
}

if ($agentPid) {
    Write-Host "  AutonomousAgent PID: $agentPid" -ForegroundColor Green
} else {
    Write-Host "  WARNING: Could not get AutonomousAgent PID" -ForegroundColor Red
}

Write-Section "Step 4: Kill AutonomousAgent to test auto-restart"
if ($agentPid) {
    Write-Host "  Killing process $agentPid..." -ForegroundColor Yellow
    Stop-Process -Id $agentPid -Force -ErrorAction SilentlyContinue
    Write-Host "  Process killed" -ForegroundColor Red
} else {
    Write-Host "  No process to kill" -ForegroundColor Yellow
}

Write-Section "Step 5: Wait for auto-restart (checking every 10 seconds for 90 seconds)"
$startTime = Get-Date
$timeout = 90
$checkInterval = 10
$restartDetected = $false

while (((Get-Date) - $startTime).TotalSeconds -lt $timeout) {
    $elapsed = [int]((Get-Date) - $startTime).TotalSeconds
    Write-Host "  [$elapsed sec] Checking..." -NoNewline
    
    if (Test-AutonomousAgentStatus) {
        $restartDetected = $true
        Write-Host " AGENT RESTARTED!" -ForegroundColor Green
        break
    } else {
        Write-Host " Agent still down" -ForegroundColor Gray
    }
    
    Start-Sleep -Seconds $checkInterval
}

Write-Section "Step 6: Results"
if ($restartDetected) {
    Write-Host "  SUCCESS: AutonomousAgent was automatically restarted!" -ForegroundColor Green
    
    $status = Read-SystemStatus
    if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
        $newPid = $status.Subsystems["AutonomousAgent"].ProcessId
        Write-Host "  New PID: $newPid" -ForegroundColor Green
    }
} else {
    Write-Host "  FAILURE: AutonomousAgent was NOT restarted within $timeout seconds" -ForegroundColor Red
}

Write-Section "Step 7: Check job output"
Write-Host "  Last 30 lines of job output:" -ForegroundColor Cyan
$jobOutput = Receive-Job -Id $monitoringJob.Id -Keep | Select-Object -Last 30
$jobOutput | ForEach-Object {
    if ($_ -like "*AGENT CHECK*" -or $_ -like "*AutonomousAgent*") {
        Write-Host "    $_" -ForegroundColor Yellow
    } elseif ($_ -like "*ERROR*" -or $_ -like "*EXCEPTION*") {
        Write-Host "    $_" -ForegroundColor Red
    } elseif ($_ -like "*WARN*") {
        Write-Host "    $_" -ForegroundColor Magenta
    } else {
        Write-Host "    $_" -ForegroundColor Gray
    }
}

Write-Section "Step 8: Check log files"
$logFile = Get-ChildItem "SystemStatusMonitoring_Job_*.log" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if ($logFile) {
    Write-Host "  Latest log file: $($logFile.Name)" -ForegroundColor Cyan
    Write-Host "  Last 20 lines containing 'Agent':" -ForegroundColor Gray
    Get-Content $logFile.FullName | Where-Object { $_ -like "*Agent*" } | Select-Object -Last 20 | ForEach-Object {
        Write-Host "    $_" -ForegroundColor Gray
    }
} else {
    Write-Host "  No log files found" -ForegroundColor Yellow
}

Write-Section "Step 9: Check central log"
Write-Host "  Last 20 lines from unity_claude_automation.log containing 'AUTONOMOUS':" -ForegroundColor Cyan
Get-Content ".\unity_claude_automation.log" -ErrorAction SilentlyContinue | 
    Where-Object { $_ -like "*AUTONOMOUS*" -or $_ -like "*TEST-AUTONOMOUS*" -or $_ -like "*START-AUTONOMOUS*" } | 
    Select-Object -Last 20 | 
    ForEach-Object {
        Write-Host "    $_" -ForegroundColor Gray
    }

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To manually check job status: Get-Job -Id $($monitoringJob.Id)" -ForegroundColor Gray
Write-Host "To see more job output: Receive-Job -Id $($monitoringJob.Id) -Keep" -ForegroundColor Gray
Write-Host ""
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUifRtUhZCatDKHuY/aYbVSD7U
# toqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUv5fq7q3LQ9WNIXenisR3rMGgf4swDQYJKoZIhvcNAQEBBQAEggEAMLRr
# gn1ZYar7oA1KCSpXFl+1LvK28Mx+PxIq8tTe5o0htPB8s4SuD9sFi6tNedFKB4p8
# zM0cVWxR5MW4SOTbYFy8pKwlQOkuZy5n4hiLKHcfOym4wJ5YASaKgxOhMiSBkdQ9
# wk2R5E3aN4VZgOcwFp87wc/nv2GhTw4nocA/y4YGQqia76IfnRs+Nbi1ARgoIjI5
# Kz8eWlJnlaE9e5xaz2DV3oojaAjcoYVEbwcZk9uCJmQZimb2P591IV3jlHVJo510
# 0YBvvTa2x1bfVoE6EQWON/hT+wJib5K8gEiXs724LJziqWazMRmtKvJGTOtFKLPm
# ik8wu+zVo4JwTqylLg==
# SIG # End signature block
