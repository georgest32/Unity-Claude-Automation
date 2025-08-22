# Test-AgentDeduplication.ps1
# Test script to verify that only one AutonomousAgent can run at a time
# Date: 2025-08-21

param(
    [switch]$DebugMode
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "AGENT DEDUPLICATION TEST" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Set working directory
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

# Test results tracking
$testResults = @{
    FirstAgentStart = $false
    SecondAgentBlocked = $false
    SystemStatusCheck = $false
    OverallSuccess = $false
}

Write-Host "Test 1: Starting First Agent" -ForegroundColor Yellow
try {
    # Clear any existing system status
    if (Test-Path ".\system_status.json") {
        $backup = Get-Content ".\system_status.json" -Raw
        $backup | Set-Content ".\system_status_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        Remove-Item ".\system_status.json" -Force
        Write-Host "  Cleared existing system status" -ForegroundColor Gray
    }
    
    # Start first agent in background
    $agentArgs = @{
        FilePath = "pwsh.exe"
        ArgumentList = @(
            "-ExecutionPolicy", "Bypass",
            "-File", ".\Start-AutonomousMonitoring-Fixed.ps1",
            "-PollIntervalSeconds", "5"
        )
        WindowStyle = "Hidden"
        PassThru = $true
    }
    
    $firstAgent = Start-Process @agentArgs
    Start-Sleep -Seconds 3  # Give time to initialize
    
    if ($firstAgent -and -not $firstAgent.HasExited) {
        Write-Host "  [PASS] First agent started successfully (PID: $($firstAgent.Id))" -ForegroundColor Green
        $testResults.FirstAgentStart = $true
    } else {
        Write-Host "  [FAIL] First agent failed to start or exited immediately" -ForegroundColor Red
    }
    
} catch {
    Write-Host "  [FAIL] Error starting first agent: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test 2: Checking SystemStatus Registration" -ForegroundColor Yellow
Start-Sleep -Seconds 2  # Give time for registration

try {
    if (Test-Path ".\system_status.json") {
        $systemStatusContent = Get-Content ".\system_status.json" -Raw | ConvertFrom-Json
        if ($systemStatusContent.subsystems -and $systemStatusContent.subsystems.AutonomousAgent) {
            $agentInfo = $systemStatusContent.subsystems.AutonomousAgent
            Write-Host "  [PASS] AutonomousAgent registered in SystemStatus" -ForegroundColor Green
            Write-Host "    Registered PID: $($agentInfo.process_id)" -ForegroundColor Gray
            Write-Host "    Status: $($agentInfo.status)" -ForegroundColor Gray
            $testResults.SystemStatusCheck = $true
        } else {
            Write-Host "  [FAIL] AutonomousAgent not found in SystemStatus" -ForegroundColor Red
        }
    } else {
        Write-Host "  [FAIL] system_status.json not found" -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] Error checking SystemStatus: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test 3: Attempting to Start Second Agent (Should Fail)" -ForegroundColor Yellow
try {
    # Try to start second agent - this should abort
    $secondAgentArgs = @{
        FilePath = "pwsh.exe"
        ArgumentList = @(
            "-ExecutionPolicy", "Bypass", 
            "-File", ".\Start-AutonomousMonitoring-Fixed.ps1",
            "-PollIntervalSeconds", "5"
        )
        WindowStyle = "Hidden"
        PassThru = $true
        Wait = $true  # Wait for it to complete (should exit quickly)
    }
    
    $secondAgent = Start-Process @secondAgentArgs
    
    # Check exit code - should be 1 (abort)
    if ($secondAgent.ExitCode -eq 1) {
        Write-Host "  [PASS] Second agent correctly aborted (exit code: 1)" -ForegroundColor Green
        $testResults.SecondAgentBlocked = $true
    } elseif ($secondAgent.ExitCode -eq 0) {
        Write-Host "  [FAIL] Second agent started when it should have aborted" -ForegroundColor Red
    } else {
        Write-Host "  [WARN] Second agent exited with unexpected code: $($secondAgent.ExitCode)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "  [FAIL] Error testing second agent: $_" -ForegroundColor Red
}

# Clean up - stop the first agent
Write-Host ""
Write-Host "Cleanup: Stopping test agents..." -ForegroundColor Gray
try {
    if ($firstAgent -and -not $firstAgent.HasExited) {
        $firstAgent.Kill()
        Write-Host "  First agent stopped" -ForegroundColor Gray
    }
    
    # Also kill any other autonomous agents that might be running
    Get-Process | Where-Object { $_.CommandLine -like "*AutonomousMonitoring*" } | ForEach-Object {
        $_.Kill()
        Write-Host "  Stopped agent PID: $($_.Id)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Warning: Error during cleanup: $_" -ForegroundColor Yellow
}

# Calculate overall result
$testResults.OverallSuccess = $testResults.FirstAgentStart -and $testResults.SystemStatusCheck -and $testResults.SecondAgentBlocked

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "TEST RESULTS" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

foreach ($test in $testResults.Keys) {
    if ($test -ne "OverallSuccess") {
        $status = if ($testResults[$test]) { "[PASS]" } else { "[FAIL]" }
        $color = if ($testResults[$test]) { "Green" } else { "Red" }
        Write-Host "$test : $status" -ForegroundColor $color
    }
}

Write-Host ""
if ($testResults.OverallSuccess) {
    Write-Host "OVERALL RESULT: [PASS] Agent deduplication working correctly!" -ForegroundColor Green
    Write-Host "Only one AutonomousAgent can run at a time as expected." -ForegroundColor Green
} else {
    Write-Host "OVERALL RESULT: [FAIL] Agent deduplication not working properly!" -ForegroundColor Red
    Write-Host "Multiple agents may be able to start simultaneously." -ForegroundColor Red
}

Write-Host ""
return $testResults.OverallSuccess
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUz9F1s3G843rlzdXUDF6Dt+Aq
# f4ugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUYhvxc+618YXqVzMHSyfpkFU8D58wDQYJKoZIhvcNAQEBBQAEggEAX3/P
# jv/HtFI0of6AWJqpC4HZ0nDKm6kfea4HX8AUfuE+YNKIbCflxLwh5jQegtg+imrN
# QbxJd3CQaXkIVRYciLZqTwN8ongjLLQOrh9ms0w/RopelENI76kEQJ13xO06Ekdy
# Z6RUSSIb/5s2XM9pAIvgsFLS4gDM9JKnY1ELoOm2+qxfDVBifT+ibe0UmxlA2Szz
# 3h2jyG+IbUWf/6Tj0SvbWHOwIYTttFY9BK3y0pkS1bSqoL1hZhFuuiXGhENA1xM+
# TIa5M+PsC9sJPrUQJZ3LRzaLMsjh/1wGXl8vOx1SaQKtmxy53Q83S420YRYl1ng9
# PmVtwA0MRikmWpOeYA==
# SIG # End signature block

