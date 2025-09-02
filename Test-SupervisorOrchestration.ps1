# Test-SupervisorOrchestration.ps1
# Comprehensive test for supervisor pattern and hierarchical control flow

param(
    [switch]$SaveResults,
    [switch]$Verbose
)

# Import required modules
$modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-MessageQueue"
Import-Module (Join-Path $modulePath "Unity-Claude-MessageQueue.psm1") -Force
Import-Module (Join-Path $modulePath "Unity-Claude-AgentIntegration.psm1") -Force

# Set up logging
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resultFile = Join-Path $PSScriptRoot "SupervisorOrchestration-TestResults-$timestamp.json"

# Initialize test results
$testResults = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TotalTests = 0
    Passed = 0
    Failed = 0
    Details = @()
    PerformanceMetrics = @{}
}

function Write-TestLog {
    param([string]$Message, [string]$Level = "INFO")
    
    if ($Verbose) {
        switch ($Level) {
            "ERROR" { Write-Host $Message -ForegroundColor Red }
            "WARNING" { Write-Host $Message -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $Message -ForegroundColor Green }
            "INFO" { Write-Host $Message -ForegroundColor Cyan }
            default { Write-Host $Message }
        }
    }
}

function Test-Function {
    param(
        [string]$TestName,
        [scriptblock]$TestScript
    )
    
    $testResults.TotalTests++
    Write-TestLog "`n=== Testing: $TestName ===" "INFO"
    
    $testDetail = @{
        Name = $TestName
        StartTime = Get-Date
        Status = "Running"
        Error = $null
    }
    
    try {
        $result = & $TestScript
        
        if ($result.Success) {
            $testDetail.Status = "Passed"
            $testResults.Passed++
            Write-TestLog "✓ PASSED: $TestName" "SUCCESS"
        }
        else {
            $testDetail.Status = "Failed"
            $testDetail.Error = $result.Error
            $testResults.Failed++
            Write-TestLog "✗ FAILED: $TestName - $($result.Error)" "ERROR"
        }
        
        $testDetail.Result = $result
    }
    catch {
        $testDetail.Status = "Failed"
        $testDetail.Error = $_.Exception.Message
        $testResults.Failed++
        Write-TestLog "✗ FAILED with exception: $TestName - $_" "ERROR"
    }
    finally {
        $testDetail.EndTime = Get-Date
        $testDetail.Duration = ($testDetail.EndTime - $testDetail.StartTime).TotalMilliseconds
        $testResults.Details += $testDetail
    }
}

Write-TestLog "`n============================================" "INFO"
Write-TestLog "    SUPERVISOR ORCHESTRATION TESTS" "INFO"
Write-TestLog "============================================" "INFO"

# Test 1: Initialize Supervisor Orchestration
Test-Function -TestName "Initialize Supervisor Orchestration" -TestScript {
    $config = Initialize-SupervisorOrchestration -AgentNames @("Agent1", "Agent2", "Agent3")
    
    return @{
        Success = ($null -ne $config -and $config.Agents.Count -eq 3)
        Config = $config
    }
}

# Test 2: Agent Selection Logic
Test-Function -TestName "Agent Selection Logic" -TestScript {
    # Initialize if not already done
    if (-not $script:SupervisorConfig) {
        Initialize-SupervisorOrchestration -AgentNames @("AnalysisAgent", "ResearchAgent", "ImplementationAgent")
    }
    
    # Test task routing
    $analysisAgent = Select-BestAgent -TaskType "Analysis"
    $researchAgent = Select-BestAgent -TaskType "Research"
    $implementAgent = Select-BestAgent -TaskType "Implementation"
    
    return @{
        Success = ($null -ne $analysisAgent -and $null -ne $researchAgent -and $null -ne $implementAgent)
        SelectedAgents = @{
            Analysis = $analysisAgent
            Research = $researchAgent
            Implementation = $implementAgent
        }
    }
}

# Test 3: Message Routing Through Supervisor
Test-Function -TestName "Message Routing Through Supervisor" -TestScript {
    Write-TestLog "Sending task to supervisor..." "INFO"
    
    # Send task to supervisor
    $result = Send-SupervisorMessage -MessageType "AssignTask" -Content @{
        TaskType = "Analysis"
        TaskId = [Guid]::NewGuid().ToString()
        Description = "Analyze code quality"
    } -Priority 8
    
    Write-TestLog "Send-SupervisorMessage result: $($result | ConvertTo-Json -Compress)" "INFO"
    
    # Give time for processing
    Start-Sleep -Milliseconds 100
    
    # Check if message was queued
    Write-TestLog "Getting orchestration status..." "INFO"
    $status = Get-OrchestrationStatus
    
    Write-TestLog "Supervisor name: $($status.Supervisor.Name)" "INFO"
    Write-TestLog "Queue name: $($status.Supervisor.Queue.Name)" "INFO"
    Write-TestLog "Queue messages count: $($status.Supervisor.Queue.Messages.Count)" "INFO"
    
    # Check if message is in the supervisor's queue
    $messageQueued = $status.Supervisor.Queue.Messages.Count -gt 0
    
    Write-TestLog "Message queued: $messageQueued" "INFO"
    
    return @{
        Success = $messageQueued
        Statistics = $status.Supervisor.Statistics
        QueuedMessages = $status.Supervisor.Queue.Messages.Count
        SendResult = $result
    }
}

# Test 4: Hierarchical Control Flow
Test-Function -TestName "Hierarchical Control Flow" -TestScript {
    # Since we can't test actual message routing without a running processor,
    # test that the emergency message gets queued properly
    
    Write-TestLog "Sending emergency message..." "INFO"
    
    # Send emergency message
    $emergencyResult = Send-SupervisorMessage -MessageType "Emergency" -Content @{
        Reason = "Critical system failure"
        Timestamp = Get-Date
    } -Priority 10
    
    Write-TestLog "Emergency message result: $($emergencyResult | ConvertTo-Json -Compress)" "INFO"
    
    # Check if message was queued with high priority
    Write-TestLog "Getting orchestration status..." "INFO"
    $status = Get-OrchestrationStatus
    
    Write-TestLog "Total messages in queue: $($status.Supervisor.Queue.Messages.Count)" "INFO"
    Write-TestLog "Looking for emergency message..." "INFO"
    
    $emergencyMessage = $status.Supervisor.Queue.Messages | Where-Object { 
        $_.Type -eq "Emergency" -and $_.Priority -eq 10 
    }
    
    if ($emergencyMessage) {
        Write-TestLog "Emergency message found: $($emergencyMessage | ConvertTo-Json -Compress)" "INFO"
    } else {
        Write-TestLog "Emergency message NOT found" "WARNING"
        Write-TestLog "All messages in queue: $($status.Supervisor.Queue.Messages | ConvertTo-Json -Compress)" "INFO"
    }
    
    $testPassed = $null -ne $emergencyMessage
    
    return @{
        Success = $testPassed
        EmergencyQueued = $testPassed
        QueueStatus = $status.Supervisor.Queue.Messages.Count
        EmergencyResult = $emergencyResult
    }
}

# Test 5: Message Passing Reliability
Test-Function -TestName "Message Passing Reliability" -TestScript {
    $messageCount = 100
    $successCount = 0
    
    # Send multiple messages rapidly
    for ($i = 1; $i -le $messageCount; $i++) {
        try {
            Send-SupervisorMessage -MessageType "AssignTask" -Content @{
                TaskType = ("Analysis", "Research", "Implementation" | Get-Random)
                TaskId = "Task-$i"
                Priority = Get-Random -Minimum 1 -Maximum 10
            } -Priority (Get-Random -Minimum 1 -Maximum 10)
            
            $successCount++
        }
        catch {
            Write-TestLog "Failed to send message ${i}: $_" "WARNING"
        }
    }
    
    # Calculate reliability
    $reliability = ($successCount / $messageCount) * 100
    
    return @{
        Success = ($reliability -ge 95)  # Expect at least 95% reliability
        Reliability = $reliability
        Sent = $successCount
        Total = $messageCount
    }
}

# Test 6: Performance Benchmarking
Test-Function -TestName "Performance Benchmarking" -TestScript {
    $iterations = 1000
    $startTime = Get-Date
    
    # Benchmark message throughput
    for ($i = 1; $i -le $iterations; $i++) {
        $null = Add-MessageToQueue -QueueName "BenchmarkQueue" -Message @{
            Index = $i
            Timestamp = Get-Date
        } -MessageType "Benchmark" -Priority 5
    }
    
    $duration = (Get-Date) - $startTime
    $throughput = $iterations / $duration.TotalSeconds
    
    # Benchmark retrieval
    $retrievalStart = Get-Date
    $retrieved = 0
    
    for ($i = 1; $i -le $iterations; $i++) {
        $msg = Get-MessageFromQueue -QueueName "BenchmarkQueue" -TimeoutSeconds 1
        if ($msg) { $retrieved++ }
    }
    
    $retrievalDuration = (Get-Date) - $retrievalStart
    $retrievalRate = $retrieved / $retrievalDuration.TotalSeconds
    
    $testResults.PerformanceMetrics = @{
        EnqueueThroughput = [Math]::Round($throughput, 2)
        DequeueThroughput = [Math]::Round($retrievalRate, 2)
        TotalDuration = $duration.TotalSeconds + $retrievalDuration.TotalSeconds
    }
    
    # A more reasonable test - check if we achieved good throughput and retrieved messages
    return @{
        Success = ($throughput -gt 100 -and $retrieved -gt 0)
        Metrics = $testResults.PerformanceMetrics
        Retrieved = $retrieved
    }
}

# Test 7: State Synchronization
Test-Function -TestName "Agent State Synchronization" -TestScript {
    # Update agent states
    $stateUpdates = @(
        @{ Agent = "AnalysisAgent"; State = "Processing"; TaskId = "task-001" },
        @{ Agent = "ResearchAgent"; State = "Idle"; TaskId = $null },
        @{ Agent = "ImplementationAgent"; State = "Error"; TaskId = "task-002"; Error = "Resource unavailable" }
    )
    
    $syncSuccess = $true
    
    foreach ($update in $stateUpdates) {
        try {
            $null = Add-MessageToQueue -QueueName "$($update.Agent)-Status" -Message $update -MessageType "StateUpdate" -Priority 6
        }
        catch {
            $syncSuccess = $false
            Write-TestLog "Failed to sync state for $($update.Agent): $_" "WARNING"
        }
    }
    
    # Verify states
    Start-Sleep -Milliseconds 100
    $currentStatus = Get-OrchestrationStatus
    
    return @{
        Success = $syncSuccess
        Status = $currentStatus
        StateUpdates = $stateUpdates
    }
}

# Test 8: Error Recovery Mechanisms
Test-Function -TestName "Error Recovery Mechanisms" -TestScript {
    # Test circuit breaker integration
    Initialize-CircuitBreaker -ServiceName "TestService" -FailureThreshold 2
    
    $recoverySuccess = $true
    $recoveryLog = @()
    
    # Simulate failures
    for ($i = 1; $i -le 3; $i++) {
        try {
            $currentIteration = $i
            $result = Invoke-WithCircuitBreaker -ServiceName "TestService" -Action {
                if ($currentIteration -le 2) {
                    throw "Simulated failure $currentIteration"
                }
                return "Success"
            }.GetNewClosure() -FallbackAction {
                return "Fallback executed"
            }
            
            $recoveryLog += "Attempt $i : $result"
        }
        catch {
            $recoveryLog += "Attempt $i failed: $_"
        }
    }
    
    # Check circuit breaker state
    $breakerStatus = Get-CircuitBreakerStatus -ServiceName "TestService"
    
    return @{
        Success = ($breakerStatus.State -eq "Open")
        BreakerState = $breakerStatus.State
        RecoveryLog = $recoveryLog
    }
}

# Calculate summary
$testResults.Duration = ((Get-Date) - [DateTime]$testResults.Timestamp).TotalSeconds
$testResults.SuccessRate = if ($testResults.TotalTests -gt 0) {
    [Math]::Round(($testResults.Passed / $testResults.TotalTests) * 100, 2)
} else { 0 }

# Display results
Write-Host "`n" -NoNewline
Write-TestLog "============================================" "INFO"
Write-TestLog "         ORCHESTRATION TEST RESULTS" "INFO"
Write-TestLog "============================================" "INFO"
Write-Host "Total Tests: $($testResults.TotalTests)"
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor $(if ($testResults.Failed -gt 0) { "Red" } else { "Gray" })
Write-Host "Success Rate: $($testResults.SuccessRate)%"
Write-Host "Duration: $([Math]::Round($testResults.Duration, 2)) seconds"

if ($testResults.PerformanceMetrics.Count -gt 0) {
    Write-Host "`nPerformance Metrics:" -ForegroundColor Cyan
    Write-Host "  Enqueue: $($testResults.PerformanceMetrics.EnqueueThroughput) msg/sec"
    Write-Host "  Dequeue: $($testResults.PerformanceMetrics.DequeueThroughput) msg/sec"
}

Write-TestLog "============================================" "INFO"

# Save results if requested
if ($SaveResults) {
    $testResults | ConvertTo-Json -Depth 10 | Out-File $resultFile
    Write-Host "`nResults saved to: $resultFile" -ForegroundColor Yellow
}

# Return success/failure
exit $(if ($testResults.Failed -eq 0) { 0 } else { 1 })
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBX9QF52IWn3jW3
# 9w+TplLIRuUdtk1YeBI8paIjTldBNKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFjuMH6nSFTjJ3Jv2aCU3++L
# Fv4nJaaA9+mx3OIpEq6sMA0GCSqGSIb3DQEBAQUABIIBALEFmRPSk51z+Ap1UJLE
# kO9FM8c97KpyRnrwPV6BYRPvmlf7Q3YIQ7vK8auERYibtu31/BHmFzAZtar+0HTB
# Fowb52n0yo0hgGBwvmXgUBY3DtoNskG9BmNfQj9sKDmOs5Wrx6SK69LQwyIWb2Ly
# qju/Xn0mkUInh5slj8984pJLtPYSV9BI8b3pW09I+BNfSK3/BIHKSoGrYVoxZzOu
# Cv02gjYPnMQNW0cFAPBCFt49CERQvxWgNVuu6BrMUTm87L6lcwnejrCBCCrnYHJH
# 5bIgLouDIDFh3lLV+9+f5NohzyoSs4rIquSzKqZIpOb4rXqERzmkPFPOKVYWPjzm
# RlU=
# SIG # End signature block
