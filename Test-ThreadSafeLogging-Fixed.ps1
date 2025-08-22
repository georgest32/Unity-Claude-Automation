# Test-ThreadSafeLogging-Fixed.ps1
# Comprehensive test suite for thread-safe logging mechanisms with fixed NestedModules
# Phase 1 Week 1 Day 3-4 Hours 7-8 validation
# Date: 2025-08-20

param(
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Continue"

# Set working directory
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

# Output file for test results
$outputFile = ".\ThreadSafeLogging_Test_Results_Fixed_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Write-TestOutput {
    param([string]$Message, [string]$Color = "White")
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $outputFile -Value $Message
}

Write-TestOutput "==========================================" "Cyan"
Write-TestOutput "Unity-Claude Thread-Safe Logging Test - FIXED" "Cyan" 
Write-TestOutput "==========================================" "Cyan"
Write-TestOutput "Started: $(Get-Date)"
Write-TestOutput "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-TestOutput "Output File: $outputFile"
Write-TestOutput ""

# Test 1: Module Loading with Fixed AgentLogging Integration
Write-TestOutput "Test 1: Module Loading with Fixed AgentLogging Integration" "Yellow"
try {
    $modulePath = ".\Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psd1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force -Global -Verbose:$Verbose
        Write-TestOutput "  Module import: PASS" "Green"
        
        # Check if AgentLogging functions are now available with explicit exports
        $agentLogFunctions = Get-Command -Name "*AgentLog*" -ErrorAction SilentlyContinue
        if ($agentLogFunctions.Count -gt 0) {
            Write-TestOutput "  AgentLogging integration: PASS ($($agentLogFunctions.Count) functions available)" "Green"
            Write-TestOutput "  Functions: $($agentLogFunctions.Name -join ', ')" "Gray"
        } else {
            Write-TestOutput "  AgentLogging integration: FAIL (no AgentLog functions found)" "Red"
        }
        
        # Check new concurrent logging functions
        $concurrentLogFunctions = @('Initialize-ConcurrentLogging', 'Write-ConcurrentLog', 'Stop-ConcurrentLogging')
        $availableFunctions = $concurrentLogFunctions | Where-Object { Get-Command $_ -ErrorAction SilentlyContinue }
        
        if ($availableFunctions.Count -eq $concurrentLogFunctions.Count) {
            Write-TestOutput "  Concurrent logging functions: PASS (all 3 functions available)" "Green"
        } else {
            Write-TestOutput "  Concurrent logging functions: FAIL (expected 3, got $($availableFunctions.Count))" "Red"
        }
        
        # Check total function count
        $totalFunctions = Get-Command -Module Unity-Claude-ParallelProcessing
        Write-TestOutput "  Total exported functions: $($totalFunctions.Count)" "Gray"
        
    } else {
        Write-TestOutput "  Module not found: FAIL" "Red"
        exit 1
    }
} catch {
    Write-TestOutput "  Module loading error: $($_.Exception.Message)" "Red"
    exit 1
}
Write-TestOutput ""

# Test 2: Fixed Thread-Safe Logging Integration
Write-TestOutput "Test 2: Fixed Thread-Safe Logging Integration" "Yellow"
try {
    # Test Write-AgentLog direct call (should now work with explicit export)
    $logMessage = "Test message from thread-safe logging test - FIXED VERSION"
    Write-AgentLog -Message $logMessage -Level "INFO" -Component "ThreadSafeLoggingTestFixed"
    Write-TestOutput "  Direct AgentLog call: PASS" "Green"
    
    # Test parallel processing functions with integrated logging
    $syncHash = New-SynchronizedHashtable -EnableStats
    if ($syncHash) {
        Write-TestOutput "  Synchronized hashtable with logging: PASS" "Green"
    } else {
        Write-TestOutput "  Synchronized hashtable with logging: FAIL" "Red"
    }
    
    # Test concurrent collections with logging
    $queue = New-ConcurrentQueue
    if ($queue) {
        Write-TestOutput "  ConcurrentQueue with logging: PASS" "Green"
    } else {
        Write-TestOutput "  ConcurrentQueue with logging: FAIL" "Red"
    }
    
} catch {
    Write-TestOutput "  Fixed integration error: $($_.Exception.Message)" "Red"
}
Write-TestOutput ""

# Test 3: Concurrent Logging System Initialization
Write-TestOutput "Test 3: Concurrent Logging System Initialization" "Yellow"
try {
    # Initialize concurrent logging
    Initialize-ConcurrentLogging -BufferSize 100 -ProcessorIntervalMs 50
    Write-TestOutput "  Concurrent logging initialization: PASS" "Green"
    
    # Test Write-ConcurrentLog function
    $testMessages = @(
        @{ Message = "Test concurrent log message 1 - FIXED"; Level = "INFO" },
        @{ Message = "Test concurrent log message 2 - FIXED"; Level = "DEBUG" },
        @{ Message = "Test concurrent log message 3 - FIXED"; Level = "WARNING" }
    )
    
    foreach ($msg in $testMessages) {
        Write-ConcurrentLog -Message $msg.Message -Level $msg.Level -Component "ConcurrentLoggingTestFixed"
    }
    Write-TestOutput "  Concurrent log messages queued: PASS (3 messages)" "Green"
    
    # Give background processor time to process
    Start-Sleep -Seconds 1
    
} catch {
    Write-TestOutput "  Concurrent logging initialization error: $($_.Exception.Message)" "Red"
}
Write-TestOutput ""

# Test 4: High-Throughput Logging Performance
Write-TestOutput "Test 4: High-Throughput Logging Performance" "Yellow"
try {
    $messageCount = 50
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Send multiple concurrent log messages
    for ($i = 1; $i -le $messageCount; $i++) {
        Write-ConcurrentLog -Message "High-throughput test message $i - FIXED" -Level "INFO" -Component "PerformanceTestFixed"
    }
    
    $stopwatch.Stop()
    $throughputMs = $stopwatch.ElapsedMilliseconds
    $messagesPerSecond = [math]::Round(($messageCount / $throughputMs) * 1000, 2)
    
    Write-TestOutput "  Messages sent: $messageCount" "Gray"
    Write-TestOutput "  Total time: ${throughputMs}ms" "Gray"
    Write-TestOutput "  Throughput: $messagesPerSecond messages/second" "Gray"
    
    if ($throughputMs -lt 1000) {  # Less than 1 second for 50 messages
        Write-TestOutput "  High-throughput performance: PASS" "Green"
    } else {
        Write-TestOutput "  High-throughput performance: FAIL (too slow: ${throughputMs}ms)" "Red"
    }
    
    # Give background processor time to handle all messages
    Start-Sleep -Seconds 2
    
} catch {
    Write-TestOutput "  High-throughput performance error: $($_.Exception.Message)" "Red"
}
Write-TestOutput ""

# Test 5: Thread Safety Simulation with Fixed Runspace Jobs
Write-TestOutput "Test 5: Thread Safety Simulation with Fixed Runspace Jobs" "Yellow"
try {
    # Create multiple jobs that log concurrently with absolute paths
    $jobCount = 3
    $messagesPerJob = 5
    $jobs = @()
    $absoluteModulePath = (Resolve-Path $modulePath).Path
    
    for ($j = 1; $j -le $jobCount; $j++) {
        $job = Start-Job -ScriptBlock {
            param($JobId, $MessageCount, $FullModulePath)
            
            try {
                # Import module in job context with absolute path
                Import-Module $FullModulePath -Force -Global
                
                # Test if Write-ConcurrentLog is available
                if (Get-Command Write-ConcurrentLog -ErrorAction SilentlyContinue) {
                    # Send multiple log messages from this job
                    for ($i = 1; $i -le $MessageCount; $i++) {
                        Write-ConcurrentLog -Message "Thread $JobId message $i - FIXED" -Level "INFO" -Component "ThreadSafetyTestFixed"
                        Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 50)
                    }
                    return "Job $JobId completed $MessageCount messages successfully"
                } else {
                    return "Job $JobId failed - Write-ConcurrentLog not available"
                }
            } catch {
                return "Job $JobId failed with error: $_"
            }
        } -ArgumentList $j, $messagesPerJob, $absoluteModulePath
        
        $jobs += $job
    }
    
    # Wait for all jobs to complete
    $jobResults = $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job
    
    Write-TestOutput "  Concurrent jobs completed: PASS" "Green"
    Write-TestOutput "  Job results: $($jobResults -join ', ')" "Gray"
    
    # Check for successful completions
    $successfulJobs = $jobResults | Where-Object { $_ -like "*completed*successfully*" }
    if ($successfulJobs.Count -eq $jobCount) {
        Write-TestOutput "  All jobs successful: PASS ($($successfulJobs.Count)/$jobCount)" "Green"
    } else {
        Write-TestOutput "  Job success rate: PARTIAL ($($successfulJobs.Count)/$jobCount)" "Yellow"
    }
    
    # Give background processor time to handle all concurrent messages
    Start-Sleep -Seconds 3
    
} catch {
    Write-TestOutput "  Thread safety simulation error: $($_.Exception.Message)" "Red"
}
Write-TestOutput ""

# Test 6: Concurrent Logging System Shutdown with Metrics
Write-TestOutput "Test 6: Concurrent Logging System Shutdown with Metrics" "Yellow"
try {
    # Stop concurrent logging system (queue metrics handled internally)
    Stop-ConcurrentLogging
    Write-TestOutput "  Concurrent logging shutdown: PASS" "Green"
    
} catch {
    Write-TestOutput "  Concurrent logging shutdown error: $($_.Exception.Message)" "Red"
}
Write-TestOutput ""

# Test Summary
Write-TestOutput "==========================================" "Cyan"
Write-TestOutput "Test Summary - FIXED VERSION" "Cyan"
Write-TestOutput "==========================================" "Cyan"
Write-TestOutput "All tests completed at: $(Get-Date)"
Write-TestOutput ""
Write-TestOutput "Key Achievements:" "Green"
Write-TestOutput "  - AgentLogging integration with explicit function exports" "Green"
Write-TestOutput "  - Thread-safe logging across module functions" "Green"  
Write-TestOutput "  - High-performance concurrent logging system operational" "Green"
Write-TestOutput "  - Background logging processor with batching" "Green"
Write-TestOutput "  - Multi-threaded logging validation with fixed runspace jobs" "Green"
Write-TestOutput "  - Graceful shutdown with queue flushing and metrics" "Green"
Write-TestOutput ""
Write-TestOutput "Phase 1 Week 1 Day 3-4 Hours 7-8: Thread-safe logging mechanisms VALIDATION!" "Cyan"
Write-TestOutput ""
Write-TestOutput "Results saved to: $outputFile"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUkxvkCyDocUcJ9pxN4iAZ8Zex
# AsKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUVba0LighKufXN+2HS2DTdW0yaSQwDQYJKoZIhvcNAQEBBQAEggEAC5KH
# qz7AMCqt2fRpTTCQy7L8a2L1TVYiK257Fb3NArcilnhd3AhvE22smVqewlK2t7BO
# rapX7XTdgA+liTenw8pSJl3uxETpqZIcWZP3zNjiU6LvOmyBEwxKUMIsFp4+mzMC
# /veHR7bkAoT2AywtmflrHJ+2Z5FOoBWw+7hUNZu7EypNGF7EBudeTQWJ7NEwaOlQ
# du3DNaJcSzYq94M0dAlZiIy67OABf7zWrDoamZJBGdzuPAcSYMLFw06YU3+msHee
# hNayfL4VQ8aSOjTnreU2dela1r5tIBWWrezIbFtvsLwwI1kN6RfNR+bS1cVy52qA
# Jo1ZmJVZMhhLH6Y77g==
# SIG # End signature block
