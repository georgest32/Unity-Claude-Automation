# Test New Refactored SystemStatus Module
# Test the Unity-Claude-SystemStatus folder that was pasted in

$ErrorActionPreference = "Stop"

Write-Host "=== Testing New Refactored SystemStatus Module ===" -ForegroundColor Cyan

# Path to the new refactored module
$newModulePath = ".\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1"

if (-not (Test-Path $newModulePath)) {
    Write-Host "[FAIL] New refactored module not found at: $newModulePath" -ForegroundColor Red
    exit 1
}

Write-Host "[INFO] Found new refactored module" -ForegroundColor Green

# Try to import the new module
try {
    Write-Host "[INFO] Importing new refactored module..." -ForegroundColor Yellow
    Import-Module $newModulePath -Force -ErrorAction Stop
    Write-Host "[PASS] Module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Failed to import module: $_" -ForegroundColor Red
    exit 1
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

$availableFunctions = Get-Command -Module "Unity-Claude-SystemStatus" | Select-Object -ExpandProperty Name
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

# Test basic function execution
Write-Host "`n=== Testing Basic Function Execution ===" -ForegroundColor Cyan

try {
    Write-SystemStatusLog -Message "Test log message" -Level "INFO"
    Write-Host "[PASS] Write-SystemStatusLog executed successfully" -ForegroundColor Green
} catch {
    Write-Host "[FAIL] Write-SystemStatusLog failed: $_" -ForegroundColor Red
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Expected Functions: $($expectedFunctions.Count)" -ForegroundColor White
Write-Host "Functions Found: $foundCount" -ForegroundColor Green
Write-Host "Functions Missing: $missingCount" -ForegroundColor Red

$successRate = [math]::Round(($foundCount / $expectedFunctions.Count) * 100, 1)
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { 'Green' } elseif ($successRate -ge 70) { 'Yellow' } else { 'Red' })

if ($missingCount -eq 0) {
    Write-Host "`nOVERALL RESULT: SUCCESS - All functions available!" -ForegroundColor Green
    Write-Host "This refactored module appears to work correctly!" -ForegroundColor Green
} else {
    Write-Host "`nOVERALL RESULT: PARTIAL SUCCESS - Some functions missing" -ForegroundColor Yellow
    Write-Host "The refactored module needs adjustment but shows promise" -ForegroundColor Yellow
}

Write-Host "`nTest completed: $(Get-Date)" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUX92cOzD0GepkR+5FhMFVnWuR
# 1ECgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUM6OkaXP8TgHaj7S2pEjBMBqXMnowDQYJKoZIhvcNAQEBBQAEggEAVRvB
# kwXzRDahSF3Pc7JMcGC3Dg1r5Z8DwRVc9I2ntKnJbZN+W0XSsH3616KQBHa96+aM
# rvqc0dry/PloXUK85EXnqg5SK+/RjEak0Iruyja6BQblck16jeVT/h/YPAnUXU9f
# FFD2n8tQPc4JArSqRJ2rnuct/ke7Y0qI/fi2JuWUtIBWPsdGVefQkYIF3IK/cHet
# pEBgjIcQoSXwBPHRu0AJGQmTs7vAs51mrENG1eQT33kWQkLYXPrWaMuCMEKME7o0
# uLPjtkB2EmlT7w073EK3Aowh8iL88BGLJJ5+36PrzDdimcO6IC54AS/wL+Rt3t0z
# 8hSyKkQAR0/JhEhmHA==
# SIG # End signature block
