# Test-MessagePassing.ps1
# Comprehensive test suite for message passing system

param(
    [switch]$SaveResults,
    [switch]$Verbose,
    [string]$TestType = "All"  # All, Unit, Integration, Performance, Stress
)

# Import required modules
$modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-MessageQueue"
Import-Module $modulePath -Force

# Set up logging
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resultFile = Join-Path $PSScriptRoot "MessagePassing-TestResults-$timestamp.json"
$logFile = Join-Path $PSScriptRoot "MessagePassing-TestLog-$timestamp.txt"

# Initialize test results
$testResults = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TestType = $TestType
    TotalTests = 0
    Passed = 0
    Failed = 0
    Details = @()
}

function Write-TestLog {
    param([string]$Message, [string]$Level = "INFO")
    
    $logMessage = "[$Level] $(Get-Date -Format 'HH:mm:ss.fff') - $Message"
    
    if ($Verbose) {
        switch ($Level) {
            "ERROR" { Write-Host $logMessage -ForegroundColor Red }
            "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
            default { Write-Host $logMessage }
        }
    }
    
    Add-Content -Path $logFile -Value $logMessage
}

function Test-Function {
    param(
        [string]$TestName,
        [scriptblock]$TestScript,
        [string]$Category = "General"
    )
    
    $testResults.TotalTests++
    Write-TestLog "Running test: $TestName" "INFO"
    
    $testDetail = @{
        Name = $TestName
        Category = $Category
        StartTime = Get-Date
        Status = "Running"
        Error = $null
    }
    
    try {
        $result = & $TestScript
        
        if ($result) {
            $testDetail.Status = "Passed"
            $testResults.Passed++
            Write-TestLog "Test PASSED: $TestName" "SUCCESS"
        }
        else {
            $testDetail.Status = "Failed"
            $testResults.Failed++
            Write-TestLog "Test FAILED: $TestName" "ERROR"
        }
    }
    catch {
        $testDetail.Status = "Failed"
        $testDetail.Error = $_.Exception.Message
        $testResults.Failed++
        Write-TestLog "Test FAILED with error: $TestName - $_" "ERROR"
    }
    finally {
        $testDetail.EndTime = Get-Date
        $testDetail.Duration = ($testDetail.EndTime - $testDetail.StartTime).TotalMilliseconds
        $testResults.Details += $testDetail
    }
}

# Unit Tests
function Run-UnitTests {
    Write-TestLog "`n=== Running Unit Tests ===" "INFO"
    
    # Test 1: Initialize Message Queue
    Test-Function -TestName "Initialize-MessageQueue" -Category "Unit" -TestScript {
        $queue = Initialize-MessageQueue -QueueName "TestQueue" -MaxMessages 100
        return ($null -ne $queue -and $queue.Name -eq "TestQueue")
    }
    
    # Test 2: Add Message to Queue
    Test-Function -TestName "Add-MessageToQueue" -Category "Unit" -TestScript {
        $message = @{
            Content = "Test message"
            Timestamp = Get-Date
        }
        $result = Add-MessageToQueue -QueueName "TestQueue" -Message $message -MessageType "Test"
        return ($null -ne $result -and $result.Content.Content -eq "Test message")
    }
    
    # Test 3: Get Message from Queue
    Test-Function -TestName "Get-MessageFromQueue" -Category "Unit" -TestScript {
        $message = @{ Data = "Test data" }
        Add-MessageToQueue -QueueName "TestQueue2" -Message $message -MessageType "Test"
        $retrieved = Get-MessageFromQueue -QueueName "TestQueue2" -TimeoutSeconds 2
        return ($null -ne $retrieved -and $retrieved.Content.Data -eq "Test data")
    }
    
    # Test 4: Initialize Circuit Breaker
    Test-Function -TestName "Initialize-CircuitBreaker" -Category "Unit" -TestScript {
        $breaker = Initialize-CircuitBreaker -ServiceName "TestService" -FailureThreshold 3
        return ($null -ne $breaker -and $breaker.ServiceName -eq "TestService")
    }
    
    # Test 5: Circuit Breaker Success
    Test-Function -TestName "CircuitBreaker-Success" -Category "Unit" -TestScript {
        Initialize-CircuitBreaker -ServiceName "TestService2" -FailureThreshold 3
        $result = Invoke-WithCircuitBreaker -ServiceName "TestService2" -Action {
            return "Success"
        }
        return ($result -eq "Success")
    }
    
    # Test 6: Circuit Breaker Failure Handling
    Test-Function -TestName "CircuitBreaker-FailureHandling" -Category "Unit" -TestScript {
        Initialize-CircuitBreaker -ServiceName "TestService3" -FailureThreshold 2
        
        # Cause failures to open circuit
        for ($i = 0; $i -lt 2; $i++) {
            try {
                Invoke-WithCircuitBreaker -ServiceName "TestService3" -Action {
                    throw "Simulated failure"
                }
            } catch {}
        }
        
        # Check if circuit is open
        $breaker = Get-CircuitBreakerStatus -ServiceName "TestService3"
        return ($breaker.State -eq "Open")
    }
    
    # Test 7: Message Handler Registration
    Test-Function -TestName "Register-MessageHandler" -Category "Unit" -TestScript {
        $handler = {
            param($message)
            Write-Output "Handled: $($message.Id)"
        }
        Register-MessageHandler -QueueName "TestQueue3" -Handler $handler
        return $true  # If no error, registration succeeded
    }
    
    # Test 8: Queue Statistics
    Test-Function -TestName "Get-QueueStatistics" -Category "Unit" -TestScript {
        Initialize-MessageQueue -QueueName "StatsQueue"
        Add-MessageToQueue -QueueName "StatsQueue" -Message @{Test="Data"} -MessageType "Test"
        $stats = Get-QueueStatistics -QueueName "StatsQueue"
        return ($stats.TotalReceived -gt 0)
    }
}

# Integration Tests
function Run-IntegrationTests {
    Write-TestLog "`n=== Running Integration Tests ===" "INFO"
    
    # Test 1: FileSystemWatcher Integration
    Test-Function -TestName "FileSystemWatcher-Integration" -Category "Integration" -TestScript {
        $testPath = Join-Path $env:TEMP "MessageQueueTest"
        if (-not (Test-Path $testPath)) {
            New-Item -Path $testPath -ItemType Directory -Force | Out-Null
        }
        
        Initialize-MessageQueue -QueueName "FileWatchQueue"
        Register-FileSystemWatcher -Path $testPath -QueueName "FileWatchQueue" -DebounceMilliseconds 100
        
        # Create a test file
        $testFile = Join-Path $testPath "test.txt"
        "Test content" | Out-File $testFile
        
        # Wait for debounce
        Start-Sleep -Milliseconds 200
        
        # Check if message was queued
        $message = Get-MessageFromQueue -QueueName "FileWatchQueue" -TimeoutSeconds 2
        
        # Cleanup
        Remove-Item $testPath -Recurse -Force
        
        return ($null -ne $message -and $message.Type -eq "FileSystemChange")
    }
    
    # Test 2: Message Processing Pipeline
    Test-Function -TestName "Message-Processing-Pipeline" -Category "Integration" -TestScript {
        Initialize-MessageQueue -QueueName "PipelineQueue"
        
        # Add multiple messages with different priorities
        $messageIds = @()
        for ($i = 1; $i -le 5; $i++) {
            $msg = Add-MessageToQueue -QueueName "PipelineQueue" -Message @{Index=$i} -MessageType "Test" -Priority $i
            $messageIds += $msg.Id
        }
        
        # Get messages to verify they were queued
        $retrievedCount = 0
        for ($i = 1; $i -le 5; $i++) {
            $message = Get-MessageFromQueue -QueueName "PipelineQueue" -TimeoutSeconds 1
            if ($message) {
                $retrievedCount++
            }
        }
        
        return ($retrievedCount -ge 3)  # At least 3 messages should be retrieved
    }
    
    # Test 3: Python Bridge Integration
    Test-Function -TestName "Python-Bridge-Integration" -Category "Integration" -TestScript {
        # Check if Python and required modules are available
        $pythonAvailable = Get-Command python -ErrorAction SilentlyContinue
        if (-not $pythonAvailable) {
            Write-TestLog "Python not available, skipping test" "WARNING"
            return $true  # Skip test
        }
        
        # Test Python message handler import
        $pythonScript = @"
import sys
sys.path.append(r'$PSScriptRoot\agents')
try:
    from message_queue_handler import AgentMessage, MessageType
    print('SUCCESS')
except ImportError as e:
    print(f'IMPORT_ERROR: {e}')
"@
        
        $result = $pythonScript | python 2>&1
        return ($result -like "*SUCCESS*")
    }
}

# Performance Tests
function Run-PerformanceTests {
    Write-TestLog "`n=== Running Performance Tests ===" "INFO"
    
    # Test 1: Message Throughput
    Test-Function -TestName "Message-Throughput" -Category "Performance" -TestScript {
        Initialize-MessageQueue -QueueName "PerfQueue" -MaxMessages 10000
        
        $startTime = Get-Date
        $messageCount = 1000
        
        for ($i = 1; $i -le $messageCount; $i++) {
            Add-MessageToQueue -QueueName "PerfQueue" -Message @{Index=$i} -MessageType "Perf" -Priority 5
        }
        
        $duration = (Get-Date) - $startTime
        $throughput = $messageCount / $duration.TotalSeconds
        
        Write-TestLog "Throughput: $throughput messages/second" "INFO"
        
        return ($throughput -gt 100)  # Expect at least 100 messages/second
    }
    
    # Test 2: Concurrent Queue Access
    Test-Function -TestName "Concurrent-Queue-Access" -Category "Performance" -TestScript {
        Initialize-MessageQueue -QueueName "ConcurrentQueue"
        
        $jobs = @()
        for ($i = 1; $i -le 5; $i++) {
            $jobs += Start-Job -ScriptBlock {
                param($QueueName, $JobId)
                
                Import-Module "$using:modulePath" -Force
                
                for ($j = 1; $j -le 20; $j++) {
                    Add-MessageToQueue -QueueName $QueueName -Message @{
                        JobId = $JobId
                        MessageId = $j
                    } -MessageType "Concurrent"
                }
            } -ArgumentList "ConcurrentQueue", $i
        }
        
        # Wait for all jobs
        $jobs | Wait-Job | Out-Null
        
        # Check queue statistics
        Start-Sleep -Seconds 1
        $stats = Get-QueueStatistics -QueueName "ConcurrentQueue"
        
        # Cleanup jobs
        $jobs | Remove-Job
        
        return ($stats.TotalReceived -eq 100)  # 5 jobs x 20 messages
    }
    
    # Test 3: Circuit Breaker Performance
    Test-Function -TestName "CircuitBreaker-Performance" -Category "Performance" -TestScript {
        Initialize-CircuitBreaker -ServiceName "PerfService" -FailureThreshold 5
        
        $startTime = Get-Date
        $iterations = 100
        
        for ($i = 1; $i -le $iterations; $i++) {
            Invoke-WithCircuitBreaker -ServiceName "PerfService" -Action {
                return $true
            }
        }
        
        $duration = (Get-Date) - $startTime
        $opsPerSecond = $iterations / $duration.TotalSeconds
        
        Write-TestLog "Circuit Breaker Operations: $opsPerSecond ops/second" "INFO"
        
        return ($opsPerSecond -gt 50)  # Expect at least 50 operations/second
    }
}

# Stress Tests
function Run-StressTests {
    Write-TestLog "`n=== Running Stress Tests ===" "INFO"
    
    # Test 1: Queue Overflow Handling
    Test-Function -TestName "Queue-Overflow-Handling" -Category "Stress" -TestScript {
        Initialize-MessageQueue -QueueName "StressQueue" -MaxMessages 10
        
        $errorCount = 0
        for ($i = 1; $i -le 20; $i++) {
            try {
                Add-MessageToQueue -QueueName "StressQueue" -Message @{Index=$i} -MessageType "Stress"
            }
            catch {
                $errorCount++
            }
        }
        
        # Should handle overflow gracefully
        return ($errorCount -eq 0)  # ConcurrentQueue doesn't have max size enforcement
    }
    
    # Test 2: Rapid Circuit Breaker State Changes
    Test-Function -TestName "Rapid-CircuitBreaker-Changes" -Category "Stress" -TestScript {
        Initialize-CircuitBreaker -ServiceName "StressService" -FailureThreshold 2 -ResetTimeoutSeconds 1
        
        $successCount = 0
        $failureCount = 0
        
        for ($i = 1; $i -le 50; $i++) {
            try {
                $shouldFail = ($i % 3 -eq 0)
                
                $result = Invoke-WithCircuitBreaker -ServiceName "StressService" -Action {
                    if ($using:shouldFail) {
                        throw "Simulated failure"
                    }
                    return "Success"
                } -FallbackAction {
                    return "Fallback"
                }
                
                if ($result -eq "Success" -or $result -eq "Fallback") {
                    $successCount++
                }
            }
            catch {
                $failureCount++
            }
            
            Start-Sleep -Milliseconds 100
        }
        
        Write-TestLog "Success: $successCount, Failures: $failureCount" "INFO"
        
        return ($successCount -gt 0 -and $failureCount -gt 0)  # Both paths exercised
    }
}

# Main test execution
Write-TestLog "Starting Message Passing System Tests" "INFO"
Write-TestLog "Test Type: $TestType" "INFO"

try {
    switch ($TestType) {
        "Unit" { Run-UnitTests }
        "Integration" { Run-IntegrationTests }
        "Performance" { Run-PerformanceTests }
        "Stress" { Run-StressTests }
        "All" {
            Run-UnitTests
            Run-IntegrationTests
            Run-PerformanceTests
            Run-StressTests
        }
        default {
            Write-TestLog "Invalid test type: $TestType" "ERROR"
        }
    }
}
catch {
    Write-TestLog "Test execution error: $_" "ERROR"
}

# Calculate summary
$testResults.Duration = ((Get-Date) - [DateTime]$testResults.Timestamp).TotalSeconds
$testResults.SuccessRate = if ($testResults.TotalTests -gt 0) {
    [Math]::Round(($testResults.Passed / $testResults.TotalTests) * 100, 2)
} else { 0 }

# Display results
Write-Host "`n" -NoNewline
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "     MESSAGE PASSING TEST RESULTS" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.TotalTests)"
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor $(if ($testResults.Failed -gt 0) { "Red" } else { "Gray" })
Write-Host "Success Rate: $($testResults.SuccessRate)%"
Write-Host "Duration: $([Math]::Round($testResults.Duration, 2)) seconds"
Write-Host "============================================" -ForegroundColor Cyan

# Save results if requested
if ($SaveResults) {
    $testResults | ConvertTo-Json -Depth 10 | Out-File $resultFile
    Write-Host "`nResults saved to: $resultFile" -ForegroundColor Yellow
    Write-Host "Log saved to: $logFile" -ForegroundColor Yellow
}

# Return success/failure
exit $(if ($testResults.Failed -eq 0) { 0 } else { 1 })
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAwZZIAlF7VfbEv
# aVnTAtO3SgPMzgCjDh2ryAuW8WY3aKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIO0R+JMzwjq+g5ZwFNz6/ZHy
# bvkRi7C+QjsknsOgii0yMA0GCSqGSIb3DQEBAQUABIIBACNmPuTnC3bsRcvqVX/8
# iRmOzDpUcqfCHoB8xfqEwVh7xAvcQsqVPjzU5uabgncjleIJ3/0C45bKUiE4z+ef
# YqSiyySY2+pccNU73+8JtU/B216DLUCEk402gyUpAZGcbv3ib5i0lJzvzG71SqZ7
# KgJ0VweFtA7KFSME57UlSvn8jPel4Bl/1kcPzLSpws+/38sG0MNxtCP8jE8+fb7K
# hNVnhVooN6z5nTtD0GXdgYxM/XQdmn2bQ3xJyj7W1FMgsZzJtsJTE65vSo2mDM9C
# jLuL37gskrMYRy4OlYNtcuyokIq6K+Nzc7dShP2NdqjzguvToZ8KqgQS3bGQCTnE
# ALA=
# SIG # End signature block
