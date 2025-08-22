# Test-DuplicatePrevention.ps1
# Tests that only one AutonomousAgent can run at a time

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TESTING DUPLICATE PREVENTION SYSTEM" -ForegroundColor Cyan  
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Set working directory
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

# Import the SystemStatus module
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force

Write-Host "Test 1: Check current status" -ForegroundColor Yellow
$status = Read-SystemStatus
if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
    $agentInfo = $status.Subsystems["AutonomousAgent"]
    Write-Host "  Current PID registered: $($agentInfo.ProcessId)" -ForegroundColor Gray
    
    # Check if process is alive
    $process = Get-Process -Id $agentInfo.ProcessId -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "  Process is ALIVE" -ForegroundColor Green
    } else {
        Write-Host "  Process is DEAD" -ForegroundColor Red
    }
} else {
    Write-Host "  No AutonomousAgent registered" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Test 2: Start first agent" -ForegroundColor Yellow
Write-Host "  Starting agent via Start-AutonomousMonitoring-Fixed.ps1..." -ForegroundColor Gray

$process1 = Start-Process -FilePath "powershell.exe" -ArgumentList @(
    "-NoExit",
    "-ExecutionPolicy", "Bypass", 
    "-File", ".\Start-AutonomousMonitoring-Fixed.ps1"
) -WorkingDirectory "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation" -PassThru

Write-Host "  PowerShell wrapper PID: $($process1.Id)" -ForegroundColor Gray
Write-Host "  Waiting 7 seconds for agent to self-register..." -ForegroundColor Gray
Start-Sleep -Seconds 7

# Check registration
$status = Read-SystemStatus
if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
    $agentPid1 = $status.Subsystems["AutonomousAgent"].ProcessId
    Write-Host "  Agent self-registered with PID: $agentPid1" -ForegroundColor Green
    
    # Verify different from wrapper
    if ($agentPid1 -ne $process1.Id) {
        Write-Host "  GOOD: Agent PID ($agentPid1) differs from wrapper PID ($($process1.Id))" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: PIDs match - may be incorrect" -ForegroundColor Yellow
    }
} else {
    Write-Host "  ERROR: Agent did not register!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test 3: Attempt to start duplicate agent" -ForegroundColor Yellow  
Write-Host "  Starting second agent..." -ForegroundColor Gray

$process2 = Start-Process -FilePath "powershell.exe" -ArgumentList @(
    "-NoExit",
    "-ExecutionPolicy", "Bypass",
    "-File", ".\Start-AutonomousMonitoring-Fixed.ps1"
) -WorkingDirectory "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation" -PassThru

Write-Host "  Second wrapper PID: $($process2.Id)" -ForegroundColor Gray
Write-Host "  Waiting 7 seconds..." -ForegroundColor Gray
Start-Sleep -Seconds 7

# Check what happened
$status = Read-SystemStatus
if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
    $agentPid2 = $status.Subsystems["AutonomousAgent"].ProcessId
    Write-Host "  Current registered PID: $agentPid2" -ForegroundColor Gray
    
    # Check if first agent was killed
    if ($agentPid1) {
        $firstStillAlive = Get-Process -Id $agentPid1 -ErrorAction SilentlyContinue
        if ($firstStillAlive) {
            Write-Host "  ERROR: First agent ($agentPid1) still running!" -ForegroundColor Red
            Write-Host "  Duplicate prevention FAILED" -ForegroundColor Red
        } else {
            Write-Host "  GOOD: First agent ($agentPid1) was killed" -ForegroundColor Green
            
            if ($agentPid2 -ne $agentPid1) {
                Write-Host "  GOOD: New agent registered with different PID ($agentPid2)" -ForegroundColor Green
                Write-Host "  Duplicate prevention SUCCESSFUL" -ForegroundColor Green
            } else {
                Write-Host "  WARNING: Same PID registered - unexpected" -ForegroundColor Yellow
            }
        }
    }
}

Write-Host ""
Write-Host "Test 4: Cleanup" -ForegroundColor Yellow
Write-Host "  Killing all test processes..." -ForegroundColor Gray

# Kill wrapper processes
@($process1, $process2) | ForEach-Object {
    if ($_ -and (Get-Process -Id $_.Id -ErrorAction SilentlyContinue)) {
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        Write-Host "    Killed wrapper PID: $($_.Id)" -ForegroundColor Gray
    }
}

# Kill any registered agent
$status = Read-SystemStatus
if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
    $agentPid = $status.Subsystems["AutonomousAgent"].ProcessId
    if ($agentPid -and (Get-Process -Id $agentPid -ErrorAction SilentlyContinue)) {
        Stop-Process -Id $agentPid -Force -ErrorAction SilentlyContinue
        Write-Host "    Killed agent PID: $agentPid" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "DUPLICATE PREVENTION TEST COMPLETE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUCDjKaFwljES1Hjxr6YPXd9Sx
# IUugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUywZ8e87agEg4K0/xo8/EJqfoOMYwDQYJKoZIhvcNAQEBBQAEggEAQJ1c
# 1ybmTD4Ii/+fl7kt1ixUtK4zQw6bBSi4p7bLAEuWBI/JQIn1CDoKyY5Vkb09GtAX
# ThwW/K15VoCQvcvJARWaEIYJKBeSPdx/ymyV/m3s67lGKa33aPTS5I0xNXR28hDf
# EO8kACik3uOdUgPlP7G/JJxtP/RUKm+WfQO10SeUUOdIhTrwxrf3f9ypHJfaj8Wa
# t5YTxny0kYaC/HyuOsZ6k8i44lY1kniIYSnRcvgWjdVc+yCCBilDzAUdlaGos1Zk
# dKXOojRDWWuqiCWZW1Y85P3Jn5E01YQyulHeiI+q4zlzIO8HSO2zpmbQOUllH59k
# KPwxwxrSQKtNRW+wqA==
# SIG # End signature block
