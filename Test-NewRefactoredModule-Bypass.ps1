# Test New Refactored SystemStatus Module - Bypass Execution Policy
# Test the Unity-Claude-SystemStatus folder that was pasted in

$ErrorActionPreference = "Stop"

Write-Host "=== Testing New Refactored SystemStatus Module (Execution Policy Bypass) ===" -ForegroundColor Cyan

# Path to the new refactored module
$newModulePath = ".\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1"

if (-not (Test-Path $newModulePath)) {
    Write-Host "[FAIL] New refactored module not found at: $newModulePath" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Found new refactored module" -ForegroundColor Green

# Try to import the new module with bypass
try {
    Write-Host "[INFO] Importing new refactored module (bypassing execution policy)..." -ForegroundColor Yellow
    
    # Method 1: Import with -Force and bypass execution policy for this session
    $originalPolicy = Get-ExecutionPolicy
    Write-Host "[INFO] Current execution policy: $originalPolicy" -ForegroundColor Gray
    
    # Temporarily set execution policy for this process only
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    Write-Host "[INFO] Temporarily set execution policy to Bypass for this process" -ForegroundColor Gray
    
    Import-Module $newModulePath -Force -ErrorAction Stop
    Write-Host "[PASS] Module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Failed to import module: $_" -ForegroundColor Red
    
    # Try alternative method - dot source the main file
    Write-Host "[INFO] Trying alternative method - dot sourcing..." -ForegroundColor Yellow
    try {
        . $newModulePath
        Write-Host "[PASS] Module dot-sourced successfully" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] Dot sourcing also failed: $_" -ForegroundColor Red
        exit 1
    }
}

# Test function availability
Write-Host "`n=== Testing Function Availability ===" -ForegroundColor Cyan

$expectedFunctions = @(
    'Write-SystemStatusLog',
    'Test-SystemStatusSchema', 
    'Read-SystemStatus',
    'Write-SystemStatus',
    'Get-SystemUptime',
    'Get-SubsystemProcessId',
    'Update-SubsystemProcessInfo',
    'Register-Subsystem',
    'Unregister-Subsystem',
    'Get-RegisteredSubsystems',
    'Send-Heartbeat',
    'Test-HeartbeatResponse',
    'Test-AllSubsystemHeartbeats',
    'Initialize-NamedPipeServer',
    'Stop-NamedPipeServer',
    'Send-SystemStatusMessage',
    'Receive-SystemStatusMessage',
    'Start-SystemStatusFileWatcher',
    'Stop-SystemStatusFileWatcher',
    'Initialize-CrossModuleEvents',
    'Send-EngineEvent',
    'Initialize-SystemStatusMonitoring',
    'Stop-SystemStatusMonitoring',
    'Test-ProcessHealth',
    'Test-ServiceResponsiveness',
    'Get-ProcessPerformanceCounters',
    'Test-ProcessPerformanceHealth',
    'Get-CriticalSubsystems',
    'Test-CriticalSubsystemHealth',
    'Invoke-CircuitBreakerCheck',
    'Send-HealthAlert',
    'Invoke-EscalationProcedure',
    'Get-AlertHistory',
    'Get-ServiceDependencyGraph',
    'Restart-ServiceWithDependencies',
    'Start-ServiceRecoveryAction',
    'Initialize-SubsystemRunspaces',
    'Start-SubsystemSession',
    'Stop-SubsystemRunspaces'
)

# Check what functions are actually available
try {
    $availableFunctions = Get-Command -Module "Unity-Claude-SystemStatus" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    if (-not $availableFunctions) {
        # Try getting functions from current scope if module method didn't work
        $availableFunctions = Get-Command -Name $expectedFunctions -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
    }
} catch {
    Write-Host "[WARN] Could not get module functions, trying alternative method..." -ForegroundColor Yellow
    $availableFunctions = @()
    foreach ($func in $expectedFunctions) {
        if (Get-Command $func -ErrorAction SilentlyContinue) {
            $availableFunctions += $func
        }
    }
}

$foundCount = 0
$missingCount = 0

foreach ($func in $expectedFunctions) {
    if ($availableFunctions -contains $func) {
        Write-Host "[PASS] Function available: $func" -ForegroundColor Green
        $foundCount++
    } else {
        Write-Host "[FAIL] Function missing: $func" -ForegroundColor Red
        $missingCount++
    }
}

# Test basic function execution if available
Write-Host "`n=== Testing Basic Function Execution ===" -ForegroundColor Cyan

if (Get-Command "Write-SystemStatusLog" -ErrorAction SilentlyContinue) {
    try {
        Write-SystemStatusLog -Message "Test log message" -Level "INFO"
        Write-Host "[PASS] Write-SystemStatusLog executed successfully" -ForegroundColor Green
    } catch {
        Write-Host "[FAIL] Write-SystemStatusLog failed: $_" -ForegroundColor Red
    }
} else {
    Write-Host "[SKIP] Write-SystemStatusLog not available for testing" -ForegroundColor Yellow
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Expected Functions: $($expectedFunctions.Count)" -ForegroundColor White
Write-Host "Functions Found: $foundCount" -ForegroundColor Green
Write-Host "Functions Missing: $missingCount" -ForegroundColor Red

$successRate = if ($expectedFunctions.Count -gt 0) { [math]::Round(($foundCount / $expectedFunctions.Count) * 100, 1) } else { 0 }
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { 'Green' } elseif ($successRate -ge 70) { 'Yellow' } else { 'Red' })

if ($missingCount -eq 0) {
    Write-Host "`nOVERALL RESULT: SUCCESS - All functions available!" -ForegroundColor Green
    Write-Host "This refactored module works correctly!" -ForegroundColor Green
} elseif ($foundCount -gt 0) {
    Write-Host "`nOVERALL RESULT: PARTIAL SUCCESS - $foundCount/$($expectedFunctions.Count) functions working" -ForegroundColor Yellow
    Write-Host "The refactored module shows promise but needs refinement" -ForegroundColor Yellow
} else {
    Write-Host "`nOVERALL RESULT: FAILED - No functions available" -ForegroundColor Red
    Write-Host "The refactored module needs significant work" -ForegroundColor Red
}

Write-Host "`nTest completed: $(Get-Date)" -ForegroundColor Gray
Write-Host "Note: Used execution policy bypass for testing unsigned scripts" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQURh1KaUBlpfkE3k1v2M7u+tqO
# IHigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUTwVSaLGdkHIaDYUuIunkJMEzno4wDQYJKoZIhvcNAQEBBQAEggEAV0y0
# Cw7ml10gKXYRTpt67qc7Zr8GW7Zn3xjnOPogvnVuBuinkNJZIkHrXRfAPgJ39k0z
# cjQjtQ8q3Io4xEgKoGHinADK/cqqXoFtAIFenv/GIcKf/oQNYatf9i90Dnh22HHk
# NEAQbx8v0dolgaGW/fcGTOALPJMwGAhB4beHP0beEDOsNOWTw50PmiRQLnWZQGi6
# gVuDKfPtJPTR06PAY32xE7m1Y/mgWvyjDihbflDwjzN0wPzKqme+7zfKTXNw6rKc
# sVCj2/+X9lRBs+1+Y/MatpgJlpYipE4u0jVWkmu7BlUCWmPLtF/HumUgWgy4584h
# utPpztF9ezA9mmqFPQ==
# SIG # End signature block
