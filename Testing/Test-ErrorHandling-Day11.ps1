# Test-ErrorHandling-Day11.ps1
# Comprehensive test suite for Master Plan Day 11: Error Handling and Retry Logic
# Tests ErrorHandling.psm1 and FailureMode.psm1 modules
# Date: 2025-08-18
# IMPORTANT: ASCII only, no backticks, proper variable delimiting

#Requires -Version 5.1

param(
    [switch]$Verbose,
    [switch]$ExportResults
)

# Initialize test framework
$ErrorActionPreference = "Stop"
$testResults = @{
    ModuleName = "ErrorHandling-Day11"
    TestDate = Get-Date
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    SkippedTests = 0
    TestDetails = @()
}

# Import modules
try {
    $modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) "Modules\Unity-Claude-AutonomousAgent"
    Import-Module (Join-Path $modulePath "Execution\ErrorHandling.psm1") -Force
    Import-Module (Join-Path $modulePath "Execution\FailureMode.psm1") -Force
    Import-Module (Join-Path $modulePath "Core\AgentLogging.psm1") -Force
    
    Write-Host "[SUCCESS] Modules imported successfully" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Failed to import modules: $_" -ForegroundColor Red
    exit 1
}

#region Test Helper Functions

function Test-ModuleFunction {
    param(
        [string]$TestName,
        [ScriptBlock]$TestBlock,
        [string]$Category = "General"
    )
    
    $testResults.TotalTests++
    $result = @{
        TestName = $TestName
        Category = $Category
        StartTime = Get-Date
    }
    
    try {
        $testOutput = & $TestBlock
        $result.Status = "Passed"
        $result.Output = $testOutput
        $testResults.PassedTests++
        Write-Host "  [PASS] $TestName" -ForegroundColor Green
        if ($Verbose -and $testOutput) {
            Write-Host "    Output: $($testOutput | ConvertTo-Json -Compress)" -ForegroundColor Gray
        }
    }
    catch {
        $result.Status = "Failed"
        $result.Error = $_.Exception.Message
        $testResults.FailedTests++
        Write-Host "  [FAIL] $TestName" -ForegroundColor Red
        Write-Host "    Error: $_" -ForegroundColor Red
    }
    finally {
        $result.Duration = ((Get-Date) - $result.StartTime).TotalMilliseconds
        $testResults.TestDetails += $result
    }
}

function Test-ErrorCondition {
    param(
        [ScriptBlock]$ErrorBlock,
        [string]$ExpectedError
    )
    
    try {
        & $ErrorBlock
        throw "Expected error did not occur"
    }
    catch {
        if ($_.Exception.Message -like "*$ExpectedError*") {
            return $true
        }
        throw "Unexpected error: $_"
    }
}

#endregion

#region ErrorHandling.psm1 Tests

Write-Host "`n=== Testing ErrorHandling.psm1 ===" -ForegroundColor Cyan

# Test 1: Exponential Backoff Delay Calculation
Test-ModuleFunction -TestName "Exponential Backoff Delay Calculation" -Category "Retry Logic" -TestBlock {
    $delay1 = Get-ExponentialBackoffDelay -AttemptCount 1 -BaseDelayMs 1000 -MaxDelayMs 30000
    $delay2 = Get-ExponentialBackoffDelay -AttemptCount 2 -BaseDelayMs 1000 -MaxDelayMs 30000
    $delay3 = Get-ExponentialBackoffDelay -AttemptCount 5 -BaseDelayMs 1000 -MaxDelayMs 30000
    
    # Verify exponential growth (with jitter tolerance)
    if ($delay1 -lt 500 -or $delay1 -gt 1500) {
        throw "Delay 1 out of expected range (with jitter): $delay1"
    }
    if ($delay2 -lt 1500 -or $delay2 -gt 2500) {
        throw "Delay 2 out of expected range (with jitter): $delay2"
    }
    if ($delay3 -lt 10000 -or $delay3 -gt 30000) {
        throw "Delay 3 out of expected range (with cap): $delay3"
    }
    
    return @{
        Attempt1 = $delay1
        Attempt2 = $delay2
        Attempt5 = $delay3
    }
}

# Test 2: Error Classification - Transient Errors
Test-ModuleFunction -TestName "Error Classification - Transient Errors" -Category "Error Classification" -TestBlock {
    $timeoutError = [System.Exception]::new("Connection timeout occurred")
    $networkError = [System.Exception]::new("Network connection failed")
    $http503Error = [System.Exception]::new("Service returned 503 Service Unavailable")
    
    $timeoutRetryable = Test-ErrorRetryability -Error @{Exception = $timeoutError}
    $networkRetryable = Test-ErrorRetryability -Error @{Exception = $networkError}
    $http503Retryable = Test-ErrorRetryability -Error @{Exception = $http503Error}
    
    if (-not $timeoutRetryable) { throw "Timeout error should be retryable" }
    if (-not $networkRetryable) { throw "Network error should be retryable" }
    if (-not $http503Retryable) { throw "HTTP 503 error should be retryable" }
    
    return @{
        TimeoutRetryable = $timeoutRetryable
        NetworkRetryable = $networkRetryable
        Http503Retryable = $http503Retryable
    }
}

# Test 3: Error Classification - Permanent Errors
Test-ModuleFunction -TestName "Error Classification - Permanent Errors" -Category "Error Classification" -TestBlock {
    $authError = [System.Exception]::new("401 Unauthorized access")
    $notFoundError = [System.Exception]::new("404 Resource not found")
    $forbiddenError = [System.Exception]::new("403 Forbidden")
    
    $authRetryable = Test-ErrorRetryability -Error @{Exception = $authError}
    $notFoundRetryable = Test-ErrorRetryability -Error @{Exception = $notFoundError}
    $forbiddenRetryable = Test-ErrorRetryability -Error @{Exception = $forbiddenError}
    
    if ($authRetryable) { throw "Auth error should not be retryable" }
    if ($notFoundRetryable) { throw "Not found error should not be retryable" }
    if ($forbiddenRetryable) { throw "Forbidden error should not be retryable" }
    
    return @{
        AuthRetryable = $authRetryable
        NotFoundRetryable = $notFoundRetryable
        ForbiddenRetryable = $forbiddenRetryable
    }
}

# Test 4: Exponential Backoff Retry - Success on Second Attempt
Test-ModuleFunction -TestName "Exponential Backoff Retry - Success on Second Attempt" -Category "Retry Logic" -TestBlock {
    $attemptCount = 0
    $result = Invoke-ExponentialBackoffRetry -MaxRetries 3 -BaseDelayMs 100 -ScriptBlock {
        $script:attemptCount++
        if ($script:attemptCount -eq 1) {
            throw "Simulated transient error"
        }
        return "Success on attempt $script:attemptCount"
    }
    
    if (-not $result.Success) { throw "Should have succeeded" }
    if ($result.AttemptCount -ne 1) { throw "Should have succeeded on second attempt (count starts at 0)" }
    
    return $result
}

# Test 5: Exponential Backoff Retry - All Attempts Fail
Test-ModuleFunction -TestName "Exponential Backoff Retry - All Attempts Fail" -Category "Retry Logic" -TestBlock {
    $result = Invoke-ExponentialBackoffRetry -MaxRetries 2 -BaseDelayMs 50 -ScriptBlock {
        throw "Persistent error"
    }
    
    if ($result.Success) { throw "Should have failed after all retries" }
    if ($result.AttemptCount -ne 3) { throw "Should have attempted 3 times (0, 1, 2)" }
    
    return $result
}

# Test 6: Circuit Breaker - State Transitions
Test-ModuleFunction -TestName "Circuit Breaker - State Transitions" -Category "Circuit Breaker" -TestBlock {
    $circuitName = "TestCircuit_$(Get-Random)"
    
    # Initial state should be Closed
    $initialState = Get-CircuitBreakerState -CircuitName $circuitName
    if ($initialState.State -ne "Closed") { throw "Initial state should be Closed" }
    
    # Transition to Open
    Set-CircuitBreakerState -CircuitName $circuitName -NewState "Open" -Reason "Test"
    $openState = Get-CircuitBreakerState -CircuitName $circuitName
    if ($openState.State -ne "Open") { throw "State should be Open after transition" }
    
    # Transition to Half-Open
    Set-CircuitBreakerState -CircuitName $circuitName -NewState "Half-Open" -Reason "Test recovery"
    $halfOpenState = Get-CircuitBreakerState -CircuitName $circuitName
    if ($halfOpenState.State -ne "Half-Open") { throw "State should be Half-Open after transition" }
    
    # Transition back to Closed
    Set-CircuitBreakerState -CircuitName $circuitName -NewState "Closed" -Reason "Recovery complete"
    $closedState = Get-CircuitBreakerState -CircuitName $circuitName
    if ($closedState.State -ne "Closed") { throw "State should be Closed after recovery" }
    
    return @{
        InitialState = $initialState.State
        OpenState = $openState.State
        HalfOpenState = $halfOpenState.State
        FinalState = $closedState.State
    }
}

# Test 7: Circuit Breaker - Operation Blocking
Test-ModuleFunction -TestName "Circuit Breaker - Operation Blocking" -Category "Circuit Breaker" -TestBlock {
    $circuitName = "BlockTestCircuit_$(Get-Random)"
    
    # Closed state - should allow operation
    $closedAllow = Test-CircuitBreakerState -CircuitName $circuitName
    if (-not $closedAllow) { throw "Closed circuit should allow operations" }
    
    # Open state - should block operation
    Set-CircuitBreakerState -CircuitName $circuitName -NewState "Open" -Reason "Test block"
    $openAllow = Test-CircuitBreakerState -CircuitName $circuitName
    if ($openAllow) { throw "Open circuit should block operations" }
    
    # Half-Open state - should allow limited operation
    Set-CircuitBreakerState -CircuitName $circuitName -NewState "Half-Open" -Reason "Test limited"
    $halfOpenAllow = Test-CircuitBreakerState -CircuitName $circuitName
    if (-not $halfOpenAllow) { throw "Half-Open circuit should allow limited operations" }
    
    return @{
        ClosedAllows = $closedAllow
        OpenBlocks = -not $openAllow
        HalfOpenAllows = $halfOpenAllow
    }
}

# Test 8: Circuit Breaker - Metrics Update
Test-ModuleFunction -TestName "Circuit Breaker - Metrics Update" -Category "Circuit Breaker" -TestBlock {
    $circuitName = "MetricsCircuit_$(Get-Random)"
    
    # Record failures
    Update-CircuitBreakerMetrics -CircuitName $circuitName -Success $false -ResponseTime 100
    Update-CircuitBreakerMetrics -CircuitName $circuitName -Success $false -ResponseTime 200
    
    $state = Get-CircuitBreakerState -CircuitName $circuitName
    if ($state.FailureCount -ne 2) { throw "Failure count should be 2" }
    
    # Record success
    Update-CircuitBreakerMetrics -CircuitName $circuitName -Success $true -ResponseTime 50
    
    $state = Get-CircuitBreakerState -CircuitName $circuitName
    if ($state.SuccessCount -ne 1) { throw "Success count should be 1" }
    
    return @{
        FailureCount = $state.FailureCount
        SuccessCount = $state.SuccessCount
    }
}

# Test 9: Timeout Operation - Success Within Timeout
Test-ModuleFunction -TestName "Timeout Operation - Success Within Timeout" -Category "Timeout" -TestBlock {
    $result = Invoke-OperationWithTimeout -TimeoutMs 5000 -ScriptBlock {
        Start-Sleep -Milliseconds 100
        return "Quick operation completed"
    }
    
    if (-not $result.Success) { throw "Operation should have succeeded" }
    if ($result.TimedOut) { throw "Operation should not have timed out" }
    if ($result.ElapsedMs -lt 100 -or $result.ElapsedMs -gt 2000) { 
        throw "Elapsed time unexpected: $($result.ElapsedMs)ms" 
    }
    
    return $result
}

# Test 10: Timeout Operation - Timeout Exceeded
Test-ModuleFunction -TestName "Timeout Operation - Timeout Exceeded" -Category "Timeout" -TestBlock {
    $result = Invoke-OperationWithTimeout -TimeoutMs 500 -ScriptBlock {
        Start-Sleep -Seconds 2
        return "This should timeout"
    }
    
    if ($result.Success) { throw "Operation should have timed out" }
    if (-not $result.TimedOut) { throw "TimedOut flag should be true" }
    
    return $result
}

#endregion

#region FailureMode.psm1 Tests

Write-Host "`n=== Testing FailureMode.psm1 ===" -ForegroundColor Cyan

# Test 11: Escalation Trigger - SLA Violation
Test-ModuleFunction -TestName "Escalation Trigger - SLA Violation" -Category "Escalation" -TestBlock {
    $result = Test-EscalationTriggers -OperationDuration 400000 -ErrorContext @{}
    
    if (-not $result.EscalationRequired) { throw "SLA violation should trigger escalation" }
    if ($result.RecommendedLevel -lt 2) { throw "SLA violation should recommend level 2+" }
    
    $slaReason = $result.Reasons | Where-Object { $_ -like "*SLA violation*" }
    if (-not $slaReason) { throw "Should include SLA violation reason" }
    
    return $result
}

# Test 12: Escalation Trigger - Critical Failure
Test-ModuleFunction -TestName "Escalation Trigger - Critical Failure" -Category "Escalation" -TestBlock {
    $errorContext = @{
        Severity = "Critical"
        Message = "Database connection lost"
    }
    
    $result = Test-EscalationTriggers -ErrorContext $errorContext -OperationDuration 1000
    
    if (-not $result.EscalationRequired) { throw "Critical failure should trigger escalation" }
    if ($result.RecommendedLevel -ne 3) { throw "Critical failure should recommend level 3" }
    
    $criticalReason = $result.Reasons | Where-Object { $_ -like "*Critical failure*" }
    if (-not $criticalReason) { throw "Should include critical failure reason" }
    
    return $result
}

# Test 13: Escalation Trigger - Consecutive Failures
Test-ModuleFunction -TestName "Escalation Trigger - Consecutive Failures" -Category "Escalation" -TestBlock {
    $errorContext = @{
        ConsecutiveFailures = 5
    }
    
    $result = Test-EscalationTriggers -ErrorContext $errorContext -OperationDuration 1000
    
    if (-not $result.EscalationRequired) { throw "Consecutive failures should trigger escalation" }
    
    $consecutiveReason = $result.Reasons | Where-Object { $_ -like "*Consecutive failure*" }
    if (-not $consecutiveReason) { throw "Should include consecutive failure reason" }
    
    return $result
}

# Test 14: Human Escalation - Create Notification
Test-ModuleFunction -TestName "Human Escalation - Create Notification" -Category "Escalation" -TestBlock {
    $context = @{
        ErrorMessage = "Test error for escalation"
        Timestamp = Get-Date
    }
    
    $result = Invoke-HumanEscalation -EscalationLevel 2 -Context $context -Reason "Test escalation"
    
    if (-not $result.Success) { throw "Escalation should succeed" }
    if (-not $result.EscalationId) { throw "Should have escalation ID" }
    if ($result.Level -ne 2) { throw "Level should be 2" }
    
    # Clean up test file
    if ($result.EscalationFile -and (Test-Path $result.EscalationFile)) {
        Remove-Item $result.EscalationFile -Force -ErrorAction SilentlyContinue
    }
    
    return $result
}

# Test 15: Safe Mode - Enable and Disable
Test-ModuleFunction -TestName "Safe Mode - Enable and Disable" -Category "Safe Mode" -TestBlock {
    # Enable safe mode
    $enableResult = Enable-SafeMode -Reason "Test safe mode activation"
    if (-not $enableResult.Success) { throw "Safe mode enable should succeed" }
    
    # Verify safe mode is active
    $isAllowed = Test-SafeModeOperation -OperationType "Logging"
    $isBlocked = Test-SafeModeOperation -OperationType "DatabaseWrite"
    
    if (-not $isAllowed) { throw "Logging should be allowed in safe mode" }
    if ($isBlocked) { throw "Non-essential operations should be blocked in safe mode" }
    
    # Disable safe mode
    $disableResult = Disable-SafeMode -Reason "Test complete"
    if (-not $disableResult.Success) { throw "Safe mode disable should succeed" }
    if (-not $disableResult.WasActive) { throw "Safe mode should have been active" }
    
    # Verify safe mode is inactive
    $afterDisable = Test-SafeModeOperation -OperationType "DatabaseWrite"
    if (-not $afterDisable) { throw "All operations should be allowed after disabling safe mode" }
    
    return @{
        EnableSuccess = $enableResult.Success
        AllowedInSafeMode = $isAllowed
        BlockedInSafeMode = -not $isBlocked
        DisableSuccess = $disableResult.Success
        AllowedAfterDisable = $afterDisable
    }
}

# Test 16: Recovery Checkpoint - Create and Restore
Test-ModuleFunction -TestName "Recovery Checkpoint - Create and Restore" -Category "Recovery" -TestBlock {
    $checkpointName = "TestCheckpoint_$(Get-Random)"
    $stateData = @{
        TestValue = "Original Value"
        TestNumber = 42
        TestArray = @(1, 2, 3)
    }
    
    # Create checkpoint
    $createResult = New-RecoveryCheckpoint -CheckpointName $checkpointName -StateData $stateData
    if (-not $createResult.Success) { throw "Checkpoint creation should succeed" }
    
    # Restore checkpoint
    $restoreResult = Restore-RecoveryCheckpoint -CheckpointName $checkpointName
    if (-not $restoreResult.Success) { throw "Checkpoint restoration should succeed" }
    
    # Verify restored data
    $restoredData = $restoreResult.CheckpointData.StateData
    if ($restoredData.TestValue -ne "Original Value") { throw "Restored value mismatch" }
    if ($restoredData.TestNumber -ne 42) { throw "Restored number mismatch" }
    
    # Clean up test file
    if ($createResult.CheckpointFile -and (Test-Path $createResult.CheckpointFile)) {
        Remove-Item $createResult.CheckpointFile -Force -ErrorAction SilentlyContinue
    }
    
    return @{
        CreateSuccess = $createResult.Success
        RestoreSuccess = $restoreResult.Success
        DataIntegrity = ($restoredData.TestValue -eq "Original Value")
    }
}

# Test 17: Diagnostic Data Collection
Test-ModuleFunction -TestName "Diagnostic Data Collection" -Category "Diagnostics" -TestBlock {
    # Add error diagnostic data
    Add-DiagnosticData -DataType "Error" -Data @{
        ErrorCode = "TEST001"
        Message = "Test error for diagnostics"
    }
    
    # Add performance diagnostic data
    Add-DiagnosticData -DataType "Performance" -Data @{
        OperationName = "TestOperation"
        Duration = 1500
    }
    
    # Add system state
    Add-DiagnosticData -DataType "SystemState" -Data @{
        MemoryUsage = 1024
        CpuUsage = 25
    }
    
    # Get diagnostic summary
    $summary = Get-DiagnosticSummary
    
    if (-not $summary.CollectedAt) { throw "Summary should have timestamp" }
    if (-not $summary.SystemState) { throw "Summary should include system state" }
    
    return $summary
}

# Test 18: System Metrics Collection
Test-ModuleFunction -TestName "System Metrics Collection" -Category "Diagnostics" -TestBlock {
    $metrics = Get-SystemMetrics
    
    if (-not $metrics.ProcessId) { throw "Metrics should include ProcessId" }
    if (-not $metrics.WorkingSet) { throw "Metrics should include WorkingSet" }
    if (-not $metrics.Timestamp) { throw "Metrics should include Timestamp" }
    
    return $metrics
}

# Test 19: Error Classification Configuration
Test-ModuleFunction -TestName "Error Classification Configuration" -Category "Configuration" -TestBlock {
    # Get current configuration
    $currentConfig = Get-ErrorClassificationConfig
    if (-not $currentConfig) { throw "Should return current configuration" }
    
    # Create custom configuration
    $customConfig = @{
        "Custom" = @{
            Patterns = @("custom_error", "special_case")
            RetryEnabled = $true
            MaxRetries = 2
            BaseDelay = 500
        }
    }
    
    # Merge with existing
    $mergedConfig = $currentConfig + $customConfig
    
    # Update configuration
    $updateResult = Set-ErrorClassificationConfig -Classification $mergedConfig
    if (-not $updateResult) { throw "Configuration update should succeed" }
    
    # Verify update
    $newConfig = Get-ErrorClassificationConfig
    if (-not $newConfig.ContainsKey("Custom")) { throw "Custom configuration should be present" }
    
    # Restore original configuration
    Set-ErrorClassificationConfig -Classification $currentConfig
    
    return @{
        ConfigUpdated = $updateResult
        CustomAdded = $newConfig.ContainsKey("Custom")
    }
}

# Test 20: Integration - Retry with Circuit Breaker
Test-ModuleFunction -TestName "Integration - Retry with Circuit Breaker" -Category "Integration" -TestBlock {
    $circuitName = "IntegrationCircuit_$(Get-Random)"
    $attemptCount = 0
    
    # Test that circuit breaker blocks after failures
    $scriptBlock = {
        $script:attemptCount++
        
        # Check circuit breaker
        if (-not (Test-CircuitBreakerState -CircuitName $circuitName)) {
            throw "Circuit breaker is open"
        }
        
        # Simulate failures
        if ($script:attemptCount -le 3) {
            Update-CircuitBreakerMetrics -CircuitName $circuitName -Success $false -ResponseTime 100
            throw "Simulated failure $script:attemptCount"
        }
        
        Update-CircuitBreakerMetrics -CircuitName $circuitName -Success $true -ResponseTime 50
        return "Success"
    }
    
    # Run with retry logic
    $result = Invoke-ExponentialBackoffRetry -MaxRetries 5 -BaseDelayMs 50 -ScriptBlock $scriptBlock
    
    # Circuit should prevent all retries after threshold
    if ($result.Success) { throw "Should fail due to circuit breaker" }
    
    return @{
        Success = $result.Success
        AttemptCount = $script:attemptCount
        CircuitState = (Get-CircuitBreakerState -CircuitName $circuitName).State
    }
}

#endregion

#region Test Summary

Write-Host "`n=== Test Summary ===" -ForegroundColor Yellow
Write-Host "Total Tests: $($testResults.TotalTests)" -ForegroundColor White
Write-Host "Passed: $($testResults.PassedTests)" -ForegroundColor Green
Write-Host "Failed: $($testResults.FailedTests)" -ForegroundColor Red
Write-Host "Skipped: $($testResults.SkippedTests)" -ForegroundColor Gray

# Calculate success rate
if ($testResults.TotalTests -gt 0) {
    $successRate = [Math]::Round(($testResults.PassedTests / $testResults.TotalTests) * 100, 2)
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } else { "Yellow" })
}

# Export results if requested
if ($ExportResults) {
    $exportPath = Join-Path $PSScriptRoot "TestResults_ErrorHandling_Day11_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $testResults | ConvertTo-Json -Depth 10 | Set-Content -Path $exportPath -Force
    Write-Host "`nTest results exported to: $exportPath" -ForegroundColor Cyan
}

# Return test results
return $testResults

#endregion
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUglBRvP1FE6XxWFSwNgrHw7iz
# ABCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU0rTOrNqxd6rQO5+avaLXuWL6q6MwDQYJKoZIhvcNAQEBBQAEggEAQQFn
# lbbAlsFPesSbtmPkAYmkVtsApBMdEywAgpudPkhMKNw214zOcBTG8D8spGBH7XFD
# uFx/0nCqko/Ijh7BMxXiAYi3M0KT0XC20VXNSo6FlmkI6BZbo4NLfKs+XyoYosF6
# oRhOYZ7AfGCQ9cNCVNn7n0Wna0k9hZYDHGp0JAdi6WbNLnkkD4aVKsb5NxtQBfHR
# m5l5KRY7/ciKt3u9/WaSSKCKVRHi7Z+S7kKN0CnwXjd8fEYMSJ/wLr+etAkTxvJu
# MLXyB1wa4xg++3MrI9wzeLzRHbufV9ILJAraZQoTqdgpsiGU3UXyWES/J2H2Jw+P
# glBoAYcRjRcg4rLi5A==
# SIG # End signature block
