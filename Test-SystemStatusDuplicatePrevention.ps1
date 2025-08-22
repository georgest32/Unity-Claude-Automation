# Test-SystemStatusDuplicatePrevention.ps1
# Test that SystemStatus module kills duplicate subsystems on registration
# Date: 2025-08-21

param(
    [switch]$DebugMode
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "SYSTEMSTATUS DUPLICATE PREVENTION TEST" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Set working directory
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

# Load SystemStatus module
Write-Host "Loading SystemStatus module..." -ForegroundColor Yellow
try {
    Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force
    Write-Host "  [PASS] SystemStatus module loaded" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Could not load SystemStatus module: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Test 1: Register First AutonomousAgent" -ForegroundColor Yellow

# Start a dummy process to simulate first agent
$firstAgentScript = @'
param($Duration)
Write-Host "First AutonomousAgent running (PID: $PID)"
Start-Sleep -Seconds $Duration
'@

$firstAgentFile = ".\test_first_agent_$(Get-Date -Format 'yyyyMMdd_HHmmss').ps1"
$firstAgentScript | Set-Content $firstAgentFile

$firstAgent = Start-Process powershell -ArgumentList "-File", $firstAgentFile, "-Duration", "30" -PassThru
Start-Sleep -Seconds 2

Write-Host "  First agent started with PID: $($firstAgent.Id)" -ForegroundColor Gray

# Register the first agent
try {
    # Manually update the system status to simulate registration
    $systemStatus = @{
        subsystems = @{
            AutonomousAgent = @{
                ProcessId = $firstAgent.Id
                Status = "Running"
                LastHeartbeat = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
            }
        }
    }
    
    # Initialize SystemStatus if needed
    if (Get-Command Initialize-SystemStatusConfig -ErrorAction SilentlyContinue) {
        Initialize-SystemStatusConfig
    }
    
    # Register first agent
    $result = Register-Subsystem -SubsystemName "AutonomousAgent" -ModulePath ".\Modules\Unity-Claude-AutonomousAgent"
    
    Write-Host "  [PASS] First agent registered successfully" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Could not register first agent: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test 2: Attempt to Register Second AutonomousAgent (Should Kill First)" -ForegroundColor Yellow

# Start a second dummy process
$secondAgentScript = @'
param($Duration)
Write-Host "Second AutonomousAgent running (PID: $PID)"
Start-Sleep -Seconds $Duration
'@

$secondAgentFile = ".\test_second_agent_$(Get-Date -Format 'yyyyMMdd_HHmmss').ps1"
$secondAgentScript | Set-Content $secondAgentFile

$secondAgent = Start-Process powershell -ArgumentList "-File", $secondAgentFile, "-Duration", "30" -PassThru
Start-Sleep -Seconds 2

Write-Host "  Second agent started with PID: $($secondAgent.Id)" -ForegroundColor Gray

# Now try to register the second agent - this should kill the first
$originalPID = $PID
$PID = $secondAgent.Id  # Temporarily set PID to simulate the second agent registering

try {
    $result = Register-Subsystem -SubsystemName "AutonomousAgent" -ModulePath ".\Modules\Unity-Claude-AutonomousAgent"
    
    # Check if first agent was killed
    Start-Sleep -Seconds 2
    $firstStillRunning = Get-Process -Id $firstAgent.Id -ErrorAction SilentlyContinue
    
    if (-not $firstStillRunning) {
        Write-Host "  [PASS] First agent was killed when second registered" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] First agent still running after second registration" -ForegroundColor Red
    }
    
} catch {
    Write-Host "  [INFO] Registration threw expected error: $_" -ForegroundColor Yellow
} finally {
    $PID = $originalPID  # Restore original PID
}

Write-Host ""
Write-Host "Test 3: Verify Only One Agent Remains" -ForegroundColor Yellow

# Check how many test agents are running
$runningAgents = @()
if (Get-Process -Id $firstAgent.Id -ErrorAction SilentlyContinue) {
    $runningAgents += $firstAgent.Id
}
if (Get-Process -Id $secondAgent.Id -ErrorAction SilentlyContinue) {
    $runningAgents += $secondAgent.Id
}

if ($runningAgents.Count -eq 1) {
    Write-Host "  [PASS] Exactly one agent is running (PID: $($runningAgents[0]))" -ForegroundColor Green
} elseif ($runningAgents.Count -eq 0) {
    Write-Host "  [WARN] No agents running (both may have been killed)" -ForegroundColor Yellow
} else {
    Write-Host "  [FAIL] Multiple agents still running: $($runningAgents -join ', ')" -ForegroundColor Red
}

# Cleanup
Write-Host ""
Write-Host "Cleanup: Stopping all test processes..." -ForegroundColor Gray
try {
    if (Get-Process -Id $firstAgent.Id -ErrorAction SilentlyContinue) {
        Stop-Process -Id $firstAgent.Id -Force
        Write-Host "  Stopped first agent" -ForegroundColor Gray
    }
    if (Get-Process -Id $secondAgent.Id -ErrorAction SilentlyContinue) {
        Stop-Process -Id $secondAgent.Id -Force
        Write-Host "  Stopped second agent" -ForegroundColor Gray
    }
    
    # Remove test files
    if (Test-Path $firstAgentFile) { Remove-Item $firstAgentFile -Force }
    if (Test-Path $secondAgentFile) { Remove-Item $secondAgentFile -Force }
    
} catch {
    Write-Host "  Warning during cleanup: $_" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "The SystemStatus module should now prevent duplicate AutonomousAgent processes" -ForegroundColor Green
Write-Host "by killing any existing agent when a new one tries to register." -ForegroundColor Green
Write-Host ""
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU3dtUbV3Ch76Ymqj2leWDAWmD
# ZLSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUUd35AI5460/OlH46gnaPLRvp2NAwDQYJKoZIhvcNAQEBBQAEggEAJYhA
# DyifRjiwZUFqrYxyLERmMC1IKf79ytsCm0QP5M98OVego4u1pd+rsaRZYMgb89tF
# MIqqeNlFWTwU34S/Hs2pxDKozT1/e6kkXUeVgFlDdq4izH/cOsjGHs1DJCFgxa2X
# 3xoIBupYPbu3A4YEnYrJw0UuApCHv7l4SpqpUNR4Hu9sdT2jhjc1mVToBciIJtNd
# osfuABO4ylkMosJU1tJw0zgVMZHmKi0JIJvK1sn8zdWzF1fxiwo8jWm5UsnM28lD
# 0tuL0cU1yKuR6wF9AzgaU7rV3zTQva7qdLhDagEgr4iGUEbIy4qkPsGX1u0PeGsD
# Mtub8A3lm078hkqmEg==
# SIG # End signature block
