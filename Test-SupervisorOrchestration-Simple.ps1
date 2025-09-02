# Test-SupervisorOrchestration-Simple.ps1
# Simplified test to verify core orchestration functionality with debug logging

param(
    [switch]$Verbose,
    [switch]$SaveLog
)

# Set up logging
$logFile = Join-Path $PSScriptRoot "SupervisorOrchestration-Debug-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"

function Write-DebugLog {
    param([string]$Message, [string]$Level = "INFO")
    
    $timestamp = Get-Date -Format "HH:mm:ss.fff"
    $logMessage = "[$Level] $timestamp - $Message"
    
    if ($Verbose) {
        switch ($Level) {
            "ERROR" { Write-Host $logMessage -ForegroundColor Red }
            "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
            "DEBUG" { Write-Host $logMessage -ForegroundColor Gray }
            default { Write-Host $logMessage -ForegroundColor Cyan }
        }
    }
    
    if ($SaveLog) {
        Add-Content -Path $logFile -Value $logMessage
    }
}

# Import required modules
Write-DebugLog "Starting test execution" "INFO"
$modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-MessageQueue"
Write-DebugLog "Module path: $modulePath" "DEBUG"

Write-DebugLog "Importing Unity-Claude-MessageQueue module" "DEBUG"
Import-Module (Join-Path $modulePath "Unity-Claude-MessageQueue.psm1") -Force

Write-DebugLog "Importing Unity-Claude-AgentIntegration module" "DEBUG"
Import-Module (Join-Path $modulePath "Unity-Claude-AgentIntegration.psm1") -Force

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "    SUPERVISOR ORCHESTRATION SIMPLE TEST" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan

$testsPassed = 0
$testsFailed = 0

# Test 1: Initialize Supervisor
Write-Host "`nTest 1: Initialize Supervisor Orchestration..." -NoNewline
Write-DebugLog "Test 1: Starting supervisor initialization" "INFO"
try {
    Write-DebugLog "Calling Initialize-SupervisorOrchestration with 3 agents" "DEBUG"
    $config = Initialize-SupervisorOrchestration -AgentNames @("Agent1", "Agent2", "Agent3")
    
    Write-DebugLog "Config returned: $($null -ne $config)" "DEBUG"
    if ($config) {
        Write-DebugLog "Agent count: $($config.Agents.Count)" "DEBUG"
        Write-DebugLog "Supervisor name: $($config.Name)" "DEBUG"
        Write-DebugLog "Queue created: $($null -ne $config.Queue)" "DEBUG"
    }
    
    if ($config -and $config.Agents.Count -eq 3) {
        Write-Host " PASSED" -ForegroundColor Green
        Write-DebugLog "Test 1: PASSED - Supervisor initialized with 3 agents" "SUCCESS"
        $testsPassed++
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        Write-DebugLog "Test 1: FAILED - Config or agent count incorrect" "ERROR"
        $testsFailed++
    }
} catch {
    Write-Host " FAILED: $_" -ForegroundColor Red
    Write-DebugLog "Test 1: FAILED with exception: $_" "ERROR"
    Write-DebugLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    $testsFailed++
}

# Test 2: Agent Selection
Write-Host "Test 2: Agent Selection Logic..." -NoNewline
Write-DebugLog "Test 2: Starting agent selection test" "INFO"
try {
    Write-DebugLog "Re-initializing supervisor with specialized agents" "DEBUG"
    Initialize-SupervisorOrchestration -AgentNames @("AnalysisAgent", "ResearchAgent", "ImplementationAgent")
    
    Write-DebugLog "Selecting best agent for Analysis task" "DEBUG"
    $analysisAgent = Select-BestAgent -TaskType "Analysis"
    Write-DebugLog "Selected for Analysis: $analysisAgent" "DEBUG"
    
    Write-DebugLog "Selecting best agent for Research task" "DEBUG"
    $researchAgent = Select-BestAgent -TaskType "Research"
    Write-DebugLog "Selected for Research: $researchAgent" "DEBUG"
    
    if ($analysisAgent -eq "AnalysisAgent" -and $researchAgent -eq "ResearchAgent") {
        Write-Host " PASSED" -ForegroundColor Green
        Write-DebugLog "Test 2: PASSED - Agents selected correctly" "SUCCESS"
        $testsPassed++
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        Write-DebugLog "Test 2: FAILED - Expected AnalysisAgent and ResearchAgent" "ERROR"
        Write-DebugLog "Got: Analysis=$analysisAgent, Research=$researchAgent" "ERROR"
        $testsFailed++
    }
} catch {
    Write-Host " FAILED: $_" -ForegroundColor Red
    Write-DebugLog "Test 2: FAILED with exception: $_" "ERROR"
    $testsFailed++
}

# Test 3: Message Queue Creation
Write-Host "Test 3: Message Queue Creation..." -NoNewline
Write-DebugLog "Test 3: Starting message queue test" "INFO"
try {
    Write-DebugLog "Adding message to SupervisorAgent-Control queue" "DEBUG"
    $message = @{TaskType = "Test"; TaskId = "test-001"}
    Write-DebugLog "Message content: $($message | ConvertTo-Json -Compress)" "DEBUG"
    
    Add-MessageToQueue -QueueName "SupervisorAgent-Control" `
                      -Message $message `
                      -MessageType "AssignTask" `
                      -Priority 5
    
    Write-DebugLog "Getting queue statistics" "DEBUG"
    $stats = Get-QueueStatistics -QueueName "SupervisorAgent-Control"
    Write-DebugLog "Queue stats - TotalReceived: $($stats.TotalReceived)" "DEBUG"
    Write-DebugLog "Queue stats - TotalProcessed: $($stats.TotalProcessed)" "DEBUG"
    
    if ($stats.TotalReceived -gt 0) {
        Write-Host " PASSED" -ForegroundColor Green
        Write-DebugLog "Test 3: PASSED - Message queued successfully" "SUCCESS"
        $testsPassed++
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        Write-DebugLog "Test 3: FAILED - No messages in queue" "ERROR"
        $testsFailed++
    }
} catch {
    Write-Host " FAILED: $_" -ForegroundColor Red
    Write-DebugLog "Test 3: FAILED with exception: $_" "ERROR"
    $testsFailed++
}

# Test 4: Circuit Breaker Integration
Write-Host "Test 4: Circuit Breaker Integration..." -NoNewline
try {
    Initialize-CircuitBreaker -ServiceName "TestService" -FailureThreshold 2
    
    # Cause failures
    $failed = $false
    for ($i = 1; $i -le 2; $i++) {
        try {
            Invoke-WithCircuitBreaker -ServiceName "TestService" -Action {
                throw "Test failure"
            }
        } catch {
            $failed = $true
        }
    }
    
    $breaker = Get-CircuitBreakerStatus -ServiceName "TestService"
    if ($failed -and $breaker.State -eq "Open") {
        Write-Host " PASSED" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host " FAILED: $_" -ForegroundColor Red
    $testsFailed++
}

# Test 5: Message Routing
Write-Host "Test 5: Message Routing to Agents..." -NoNewline
try {
    # Add message directly to agent queue
    Add-MessageToQueue -QueueName "AnalysisAgent-Tasks" `
                      -Message @{TaskId = "analysis-001"; Command = "Analyze"} `
                      -MessageType "TaskAssignment" `
                      -Priority 8
    
    # Retrieve message
    $message = Get-MessageFromQueue -QueueName "AnalysisAgent-Tasks" -TimeoutSeconds 1
    
    if ($message -and $message.Content.TaskId -eq "analysis-001") {
        Write-Host " PASSED" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host " FAILED: $_" -ForegroundColor Red
    $testsFailed++
}

# Test 6: Orchestration Status
Write-Host "Test 6: Get Orchestration Status..." -NoNewline
try {
    $status = Get-OrchestrationStatus
    
    if ($status -and $status.Supervisor -and $status.Agents) {
        Write-Host " PASSED" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host " FAILED: $_" -ForegroundColor Red
    $testsFailed++
}

# Test 7: Emergency Coordination
Write-Host "Test 7: Emergency Coordination..." -NoNewline
try {
    # Send emergency message
    Add-MessageToQueue -QueueName "SupervisorAgent-Control" `
                      -Message @{Reason = "Emergency test"} `
                      -MessageType "Emergency" `
                      -Priority 10
    
    # Since handler isn't running, just verify message was queued
    $stats = Get-QueueStatistics -QueueName "SupervisorAgent-Control"
    if ($stats.TotalReceived -ge 2) {  # At least 2 messages (from test 3 and this one)
        Write-Host " PASSED" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host " FAILED" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host " FAILED: $_" -ForegroundColor Red
    $testsFailed++
}

# Test 8: Performance Metrics
Write-Host "Test 8: Performance Metrics..." -NoNewline
try {
    $startTime = Get-Date
    
    # Queue 100 messages rapidly
    for ($i = 1; $i -le 100; $i++) {
        Add-MessageToQueue -QueueName "PerfTestQueue" `
                          -Message @{Index = $i} `
                          -MessageType "PerfTest" `
                          -Priority 5
    }
    
    $duration = (Get-Date) - $startTime
    $throughput = 100 / $duration.TotalSeconds
    
    if ($throughput -gt 50) {  # At least 50 messages per second
        Write-Host " PASSED (Throughput: $([Math]::Round($throughput, 2)) msg/sec)" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host " FAILED (Throughput too low)" -ForegroundColor Red
        $testsFailed++
    }
} catch {
    Write-Host " FAILED: $_" -ForegroundColor Red
    $testsFailed++
}

# Summary
$total = $testsPassed + $testsFailed
$successRate = if ($total -gt 0) { [Math]::Round(($testsPassed / $total) * 100, 2) } else { 0 }

Write-DebugLog "Test execution completed" "INFO"
Write-DebugLog "Total: $total, Passed: $testsPassed, Failed: $testsFailed" "INFO"

Write-Host "`n============================================" -ForegroundColor Cyan
Write-Host "              TEST SUMMARY" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Total Tests: $total"
Write-Host "Passed: $testsPassed" -ForegroundColor Green
Write-Host "Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -gt 0) { "Red" } else { "Gray" })
Write-Host "Success Rate: $successRate%"
Write-Host "============================================" -ForegroundColor Cyan

if ($SaveLog) {
    Write-Host "`nDebug log saved to: $logFile" -ForegroundColor Yellow
}

exit $(if ($testsFailed -eq 0) { 0 } else { 1 })
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB4aMPrgyYpEZKz
# Kiko+4TVTFAqhdQSoQgtf2kuC9zDJaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHaIJ/K9n4aZ19Yn44k+vhUP
# AljNBMM2fvORWIXXcRwyMA0GCSqGSIb3DQEBAQUABIIBAEzzgPc19bYDZC6WQr1Y
# DzuJAAvk44pVG92oU1r0OQQTleibauQHVdUP8cKemFeXonOF/sMvCwMhp94LDjF5
# 8g3ATh8hXXaD245J8Zs4SbGbpNV4NxT4SDu5JQOl/uQDEQdZo0m77oCYazdTjZLY
# dAiK/94yQVwWBRxHRxz68IzljC2ZfOECWa8wJ1Xwe63kujTb0UzWC6o+gStPR0nk
# 7CgVt8WF5GP+uYlOnSR1VnVk7Lt7BzUKjO+UHzJjJj+ygeiB50DLCYQ7pOj/wNLd
# Ugh0FOkI21fO4zmgjnl5Bu7ZUHPvWTlb4WoRNwMyjWgaLt/wlL8rpl+M1rRXDqMm
# Lxs=
# SIG # End signature block
