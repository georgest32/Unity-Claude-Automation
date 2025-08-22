# Test-SystemStatusAPICompatibility.ps1
# Tests public API compatibility for Unity-Claude-SystemStatus module
# Date: 2025-08-20
# Purpose: Ensure refactoring maintains backward compatibility

param(
    [string]$ModulePath = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1",
    [string]$ResultsPath = ".\SystemStatus_API_Test_Results.txt"
)

# Start logging
$testResults = @()
$testResults += "=== Unity-Claude-SystemStatus API Compatibility Test ==="
$testResults += "Test Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$testResults += ""

# Import the module
try {
    Write-Host "Importing module from: $ModulePath" -ForegroundColor Cyan
    Import-Module $ModulePath -Force -ErrorAction Stop
    $testResults += "Module imported successfully"
} catch {
    $testResults += "ERROR: Failed to import module: $_"
    $testResults | Out-File $ResultsPath
    Write-Error "Module import failed: $_"
    exit 1
}

# Define expected public API functions
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

# Test each function exists
$testResults += ""
$testResults += "=== Testing Function Availability ==="
$passCount = 0
$failCount = 0

foreach ($funcName in $expectedFunctions) {
    $func = Get-Command -Name $funcName -ErrorAction SilentlyContinue
    if ($func) {
        $testResults += "[PASS] Function exists: $funcName"
        $passCount++
    } else {
        $testResults += "[FAIL] Function missing: $funcName"
        $failCount++
    }
}

$testResults += ""
$testResults += "Function Availability Summary: $passCount passed, $failCount failed"

# Test function signatures (parameters)
$testResults += ""
$testResults += "=== Testing Function Signatures ==="

# Define expected parameters for key functions
$functionSignatures = @{
    'Register-Subsystem' = @('Name', 'Description', 'ProcessId', 'Priority', 'Dependencies')
    'Send-Heartbeat' = @('SubsystemName', 'Status', 'Details')
    'Test-HeartbeatResponse' = @('SubsystemName', 'TimeoutSeconds')
    'Write-SystemStatusLog' = @('Message', 'Level', 'SubsystemName')
    'Read-SystemStatus' = @('Path')
    'Write-SystemStatus' = @('Status', 'Path')
}

$sigPassCount = 0
$sigFailCount = 0

foreach ($funcName in $functionSignatures.Keys) {
    $func = Get-Command -Name $funcName -ErrorAction SilentlyContinue
    if ($func) {
        $expectedParams = $functionSignatures[$funcName]
        $actualParams = $func.Parameters.Keys | Where-Object { $_ -notmatch '^(Debug|ErrorAction|ErrorVariable|InformationAction|InformationVariable|OutBuffer|OutVariable|PipelineVariable|Verbose|WarningAction|WarningVariable|WhatIf|Confirm)$' }
        
        $missingParams = $expectedParams | Where-Object { $_ -notin $actualParams }
        
        if ($missingParams.Count -eq 0) {
            $testResults += "[PASS] $funcName has all expected parameters"
            $sigPassCount++
        } else {
            $testResults += "[FAIL] $funcName missing parameters: $($missingParams -join ', ')"
            $sigFailCount++
        }
    } else {
        $testResults += "[FAIL] Cannot test signature - function missing: $funcName"
        $sigFailCount++
    }
}

$testResults += ""
$testResults += "Signature Test Summary: $sigPassCount passed, $sigFailCount failed"

# Test basic functionality
$testResults += ""
$testResults += "=== Testing Basic Functionality ==="

# Test 1: System Status File Operations
try {
    $testPath = Join-Path $env:TEMP "test_system_status.json"
    $testStatus = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        subsystems = @{}
        test = $true
    }
    
    Write-SystemStatus -Status $testStatus -Path $testPath -ErrorAction Stop
    $readStatus = Read-SystemStatus -Path $testPath -ErrorAction Stop
    
    if ($readStatus.test -eq $true) {
        $testResults += "[PASS] System status read/write operations work"
    } else {
        $testResults += "[FAIL] System status read/write mismatch"
    }
    
    Remove-Item $testPath -Force -ErrorAction SilentlyContinue
} catch {
    $testResults += "[FAIL] System status operations failed: $_"
}

# Test 2: Logging Function
try {
    Write-SystemStatusLog -Message "API Test" -Level "INFO" -SubsystemName "TestSuite" -ErrorAction Stop
    $testResults += "[PASS] Logging function works"
} catch {
    $testResults += "[FAIL] Logging function failed: $_"
}

# Test 3: Get System Uptime
try {
    $uptime = Get-SystemUptime -ErrorAction Stop
    if ($uptime -is [TimeSpan]) {
        $testResults += "[PASS] Get-SystemUptime returns TimeSpan"
    } else {
        $testResults += "[FAIL] Get-SystemUptime returned unexpected type"
    }
} catch {
    $testResults += "[FAIL] Get-SystemUptime failed: $_"
}

# Generate summary
$testResults += ""
$testResults += "=== Test Summary ==="
$testResults += "Total Functions Expected: $($expectedFunctions.Count)"
$testResults += "Functions Found: $passCount"
$testResults += "Functions Missing: $failCount"
$testResults += "Signature Tests Passed: $sigPassCount"
$testResults += "Signature Tests Failed: $sigFailCount"
$testResults += ""
$testResults += "Overall Result: $(if ($failCount -eq 0 -and $sigFailCount -eq 0) { 'ALL TESTS PASSED' } else { 'TESTS FAILED' })"
$testResults += "Test Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Save results
$testResults | Out-File $ResultsPath
Write-Host "`nTest results saved to: $ResultsPath" -ForegroundColor Cyan

# Display summary
if ($failCount -eq 0 -and $sigFailCount -eq 0) {
    Write-Host "ALL TESTS PASSED - API is compatible" -ForegroundColor Green
} else {
    Write-Host "TESTS FAILED - API compatibility issues detected" -ForegroundColor Red
    Write-Host "  Functions missing: $failCount" -ForegroundColor Yellow
    Write-Host "  Signature issues: $sigFailCount" -ForegroundColor Yellow
}

# Return success/failure
exit $(if ($failCount -eq 0 -and $sigFailCount -eq 0) { 0 } else { 1 })
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUledlD/+IA1R4octQhvBsAYro
# DN6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU5kBhWjLhylsMv+ffQAfnlh6//zAwDQYJKoZIhvcNAQEBBQAEggEAaZaa
# X8Jl8SPCcfX7aIv7m6oxisV54hhfF6bjNZJKHH5ZC/m4I+zj9GeUztML9Fnt/wMu
# YPbSjIJUaQubdl73LzDPaXPKWcGN0O7yEbgSdHauTOrDCYEG4hQQPxwMZg+cPjLt
# QAwcZy6Qd9z5nPgU52TRvgFNUiHg8kgab+BThDKeFE0fNi67bhspGA8+B28b3sO6
# f4pVZUrCTTmUuN9jA2Zlu9JMKuBKxaeKyYtsTG8ll3ZhQs4aY6gIPU54t3BK9nCT
# 6gQ3D+4i7UpSwYvVzv4h6XJvs5hrOM+FTddNnXMZAvAaqY2vg1gU0mG733ioIrNa
# 4s/hrT0T8PayO0Q30w==
# SIG # End signature block
