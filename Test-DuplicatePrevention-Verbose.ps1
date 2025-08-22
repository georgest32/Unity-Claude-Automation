# Test-DuplicatePrevention-Verbose.ps1
# Tests duplicate prevention with detailed logging

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "VERBOSE DUPLICATE PREVENTION TEST" -ForegroundColor Cyan  
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

# Clean slate - kill any existing agents first
Write-Host "Cleanup: Killing any existing agents..." -ForegroundColor Yellow
Get-Process | Where-Object { $_.MainWindowTitle -like "*AUTONOMOUS*" } | ForEach-Object {
    Write-Host "  Killing existing agent window PID: $($_.Id)" -ForegroundColor Gray
    Stop-Process -Id $_.Id -Force
}
Start-Sleep -Seconds 2

# Clear the registration
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force
$status = Read-SystemStatus
if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
    Write-Host "  Clearing existing registration" -ForegroundColor Gray
    $status.Subsystems.Remove("AutonomousAgent")
    Write-SystemStatus -StatusData $status
}

Write-Host ""
Write-Host "Test 1: Start first agent and monitor registration" -ForegroundColor Yellow

# Create a simple test script that registers and waits
$testScript1 = @'
param([int]$AgentNumber = 1)
Write-Host "AGENT $AgentNumber STARTING - PID: $PID" -ForegroundColor Cyan
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force
Write-Host "AGENT $AgentNumber REGISTERING..." -ForegroundColor Yellow
Register-Subsystem -SubsystemName "AutonomousAgent" -ModulePath ".\Modules\Unity-Claude-AutonomousAgent" -ProcessId $PID
Write-Host "AGENT $AgentNumber REGISTERED WITH PID: $PID" -ForegroundColor Green
Write-Host "AGENT $AgentNumber RUNNING - Press Ctrl+C to stop" -ForegroundColor Cyan
while ($true) { Start-Sleep -Seconds 5; Write-Host "." -NoNewline }
'@

$testScript1 | Out-File -FilePath ".\TestAgent1.ps1" -Encoding ASCII

Write-Host "  Starting Agent 1..." -ForegroundColor Gray
$agent1 = Start-Process -FilePath "powershell.exe" -ArgumentList @(
    "-NoExit",
    "-ExecutionPolicy", "Bypass",
    "-Command", "& { .\TestAgent1.ps1 -AgentNumber 1 }"
) -WorkingDirectory "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation" -PassThru

Write-Host "  Agent 1 wrapper process: $($agent1.Id)" -ForegroundColor Gray
Write-Host "  Waiting 5 seconds for registration..." -ForegroundColor Gray
Start-Sleep -Seconds 5

# Check registration
$status = Read-SystemStatus
if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
    $pid1 = $status.Subsystems["AutonomousAgent"].ProcessId
    Write-Host "  Agent 1 registered with PID: $pid1" -ForegroundColor Green
    
    # Verify process exists
    if (Get-Process -Id $pid1 -ErrorAction SilentlyContinue) {
        Write-Host "  Agent 1 process verified as running" -ForegroundColor Green
    }
} else {
    Write-Host "  ERROR: Agent 1 did not register!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test 2: Start second agent (should kill first)" -ForegroundColor Yellow

# Create second test script
$testScript2 = @'
param([int]$AgentNumber = 2)
Write-Host "AGENT $AgentNumber STARTING - PID: $PID" -ForegroundColor Magenta
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force
Write-Host "AGENT $AgentNumber ATTEMPTING REGISTRATION..." -ForegroundColor Yellow
Register-Subsystem -SubsystemName "AutonomousAgent" -ModulePath ".\Modules\Unity-Claude-AutonomousAgent" -ProcessId $PID
Write-Host "AGENT $AgentNumber REGISTERED WITH PID: $PID" -ForegroundColor Green
Write-Host "AGENT $AgentNumber RUNNING - Press Ctrl+C to stop" -ForegroundColor Magenta
while ($true) { Start-Sleep -Seconds 5; Write-Host "." -NoNewline }
'@

$testScript2 | Out-File -FilePath ".\TestAgent2.ps1" -Encoding ASCII

Write-Host "  Starting Agent 2..." -ForegroundColor Gray
$agent2 = Start-Process -FilePath "powershell.exe" -ArgumentList @(
    "-NoExit",
    "-ExecutionPolicy", "Bypass",
    "-Command", "& { .\TestAgent2.ps1 -AgentNumber 2 }"
) -WorkingDirectory "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation" -PassThru

Write-Host "  Agent 2 wrapper process: $($agent2.Id)" -ForegroundColor Gray
Write-Host "  Waiting 5 seconds for duplicate prevention..." -ForegroundColor Gray
Start-Sleep -Seconds 5

# Check what happened
Write-Host ""
Write-Host "Results:" -ForegroundColor Yellow

# Check if Agent 1 is still alive
if ($pid1) {
    if (Get-Process -Id $pid1 -ErrorAction SilentlyContinue) {
        Write-Host "  ERROR: Agent 1 ($pid1) is still running!" -ForegroundColor Red
        Write-Host "  DUPLICATE PREVENTION FAILED" -ForegroundColor Red
    } else {
        Write-Host "  SUCCESS: Agent 1 ($pid1) was killed" -ForegroundColor Green
    }
}

# Check current registration
$status = Read-SystemStatus
if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
    $pid2 = $status.Subsystems["AutonomousAgent"].ProcessId
    Write-Host "  Current registered PID: $pid2" -ForegroundColor Gray
    
    if ($pid2 -eq $agent2.Id) {
        Write-Host "  Agent 2 registered successfully" -ForegroundColor Green
        Write-Host "  DUPLICATE PREVENTION WORKING" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "Cleanup:" -ForegroundColor Yellow
# Kill test processes
@($agent1, $agent2) | ForEach-Object {
    if ($_ -and (Get-Process -Id $_.Id -ErrorAction SilentlyContinue)) {
        Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue
        Write-Host "  Killed process: $($_.Id)" -ForegroundColor Gray
    }
}

# Clean up test files
Remove-Item ".\TestAgent1.ps1" -ErrorAction SilentlyContinue
Remove-Item ".\TestAgent2.ps1" -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "VERBOSE TEST COMPLETE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUBFDlQB9XrxPOvgMNCYzV+3ou
# I9qgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUyBGykt6Zn7mVSNNUwDhQaNDhj8cwDQYJKoZIhvcNAQEBBQAEggEAFElE
# RSseAt+5WFOWButSqbr1OSNss2VZEAOcRe6Ynvckkqu4X2t517nLqzGnfy+oXGmj
# cG3FWrWCbzPR6007MxITWtCgva8IvGiStf2KZife+J5Jss1XjA4LuoeffMklYbZR
# osPWqHDEwDiwZlQoR5oUeAh8KNaF04oHyjwugTjDVhMGDVVSl2ibHvKz3eUHOq7K
# x/Wut61R5ssapg7FDndyWNRNa8PgZLDXHzRti1NjDByanFKl/fR3RWc/Gy9OSyny
# C0MfGM/zbIl/3zJXHywr3JCi8OX+HHJOyOfSPiJJeSteOS98oFN4xH5hqmETuKb+
# qeWX/9hLC9Jq1rq5wA==
# SIG # End signature block
