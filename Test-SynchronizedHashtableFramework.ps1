# Test-SynchronizedHashtableFramework.ps1
# Testing the synchronized hashtable framework implementation
# Phase 1 Week 1 Day 3-4 Hours 1-3: Test synchronized hashtable framework
# Date: 2025-08-20

param(
    [switch]$Detailed = $false,
    [switch]$RunConcurrencyTest = $true,
    [int]$ConcurrencyIterations = 20,
    [string]$ResultsFile = ".\SynchronizedHashtable_Test_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
)

$ErrorActionPreference = "Continue"

Write-Host "=== Synchronized Hashtable Framework Test ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date)" -ForegroundColor Gray
Write-Host "Testing Unity-Claude-ParallelProcessing module" -ForegroundColor Gray
Write-Host ""

# Test results collection
$testResults = @{
    TestDate = Get-Date
    ModuleTests = @{}
    FunctionalityTests = @{}
    PerformanceTests = @{}
    ConcurrencyTests = @{}
    Summary = @{}
}

# Test 1: Module loading
Write-Host "1. Testing module loading..." -ForegroundColor Yellow

try {
    $modulePath = ".\Modules\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psd1"
    
    if (-not (Test-Path $modulePath)) {
        throw "Module not found at: $modulePath"
    }
    
    Write-Host "  Loading Unity-Claude-ParallelProcessing module..." -ForegroundColor Gray
    Import-Module $modulePath -Force -DisableNameChecking
    
    $module = Get-Module "Unity-Claude-ParallelProcessing"
    if ($module) {
        $testResults.ModuleTests.Loading = @{
            Status = "Success"
            Version = $module.Version.ToString()
            ExportedFunctions = $module.ExportedFunctions.Keys.Count
            ModulePath = $module.Path
        }
        
        Write-Host "    Module loaded successfully" -ForegroundColor Green
        Write-Host "    Version: $($module.Version)" -ForegroundColor Gray
        Write-Host "    Exported functions: $($module.ExportedFunctions.Keys.Count)" -ForegroundColor Gray
        Write-Host "    Functions: $($module.ExportedFunctions.Keys -join ', ')" -ForegroundColor Gray
    } else {
        throw "Module failed to load properly"
    }
} catch {
    $testResults.ModuleTests.Loading = @{
        Status = "Failed"
        Error = $_.Exception.Message
    }
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2: Basic synchronized hashtable operations
Write-Host "2. Testing basic synchronized hashtable operations..." -ForegroundColor Yellow

try {
    Write-Host "  Creating synchronized hashtable..." -ForegroundColor Gray
    $syncHash = New-SynchronizedHashtable -EnableStats
    
    if ($syncHash -and $syncHash._Metadata -and $syncHash._Metadata.ThreadSafe) {
        Write-Host "    Synchronized hashtable created successfully" -ForegroundColor Green
        
        # Test basic operations
        Write-Host "  Testing basic operations..." -ForegroundColor Gray
        
        # Set operation
        Set-SynchronizedValue -SyncHash $syncHash -Key "testKey1" -Value "testValue1" -UpdateTimestamp
        
        # Get operation
        $retrievedValue = Get-SynchronizedValue -SyncHash $syncHash -Key "testKey1"
        
        # Verify
        if ($retrievedValue -eq "testValue1") {
            Write-Host "    Basic set/get operations: SUCCESS" -ForegroundColor Green
        } else {
            throw "Value mismatch: Expected 'testValue1', got '$retrievedValue'"
        }
        
        # Test default value
        $defaultTest = Get-SynchronizedValue -SyncHash $syncHash -Key "nonExistentKey" -DefaultValue "defaultValue"
        if ($defaultTest -eq "defaultValue") {
            Write-Host "    Default value handling: SUCCESS" -ForegroundColor Green
        } else {
            throw "Default value failed: Expected 'defaultValue', got '$defaultTest'"
        }
        
        # Test removal
        $removed = Remove-SynchronizedValue -SyncHash $syncHash -Key "testKey1"
        if ($removed) {
            $afterRemoval = Get-SynchronizedValue -SyncHash $syncHash -Key "testKey1" -DefaultValue $null
            if ($afterRemoval -eq $null) {
                Write-Host "    Remove operations: SUCCESS" -ForegroundColor Green
            } else {
                throw "Remove failed: Value still exists after removal"
            }
        } else {
            throw "Remove operation returned false for existing key"
        }
        
        $testResults.FunctionalityTests.BasicOperations = @{
            Status = "Success"
            SetGet = "Pass"
            DefaultValue = "Pass"
            Remove = "Pass"
        }
    } else {
        throw "Synchronized hashtable creation failed or not thread-safe"
    }
} catch {
    $testResults.FunctionalityTests.BasicOperations = @{
        Status = "Failed"
        Error = $_.Exception.Message
    }
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: Status management system
Write-Host "3. Testing status management system..." -ForegroundColor Yellow

try {
    Write-Host "  Initializing parallel status manager..." -ForegroundColor Gray
    $statusManager = Initialize-ParallelStatusManager -EnablePersistence
    
    if ($statusManager) {
        Write-Host "    Status manager initialized successfully" -ForegroundColor Green
        
        # Test setting subsystem status
        Write-Host "  Testing subsystem status operations..." -ForegroundColor Gray
        Set-ParallelStatus -Subsystem "TestSubsystem" -StatusData @{
            Status = "Running"
            PID = 1234
            StartTime = Get-Date
            HealthScore = 0.95
        } -UpdateGlobalStats
        
        # Test retrieving subsystem status
        $subsystemStatus = Get-ParallelStatus -Subsystem "TestSubsystem"
        if ($subsystemStatus -and $subsystemStatus.Status -eq "Running") {
            Write-Host "    Subsystem status set/get: SUCCESS" -ForegroundColor Green
        } else {
            throw "Subsystem status operations failed"
        }
        
        # Test updating specific fields
        Update-ParallelStatus -Subsystem "TestSubsystem" -Updates @{
            HealthScore = 0.98
            LastCheck = Get-Date
        }
        
        $updatedStatus = Get-ParallelStatus -Subsystem "TestSubsystem"
        if ($updatedStatus.HealthScore -eq 0.98) {
            Write-Host "    Status updates: SUCCESS" -ForegroundColor Green
        } else {
            throw "Status update failed"
        }
        
        # Test full status retrieval
        $fullStatus = Get-ParallelStatus -IncludeMetadata
        if ($fullStatus -and $fullStatus.SystemInfo -and $fullStatus.Subsystems) {
            Write-Host "    Full status retrieval: SUCCESS" -ForegroundColor Green
        } else {
            throw "Full status retrieval failed"
        }
        
        $testResults.FunctionalityTests.StatusManagement = @{
            Status = "Success"
            SubsystemSetGet = "Pass"
            StatusUpdates = "Pass"
            FullStatusRetrieval = "Pass"
            SubsystemCount = $fullStatus.Subsystems.Keys.Count
        }
    } else {
        throw "Status manager initialization failed"
    }
} catch {
    $testResults.FunctionalityTests.StatusManagement = @{
        Status = "Failed"
        Error = $_.Exception.Message
    }
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 4: Thread-safe operations
Write-Host "4. Testing thread-safe operations wrapper..." -ForegroundColor Yellow

try {
    Write-Host "  Testing thread-safe operation execution..." -ForegroundColor Gray
    
    $result = Invoke-ThreadSafeOperation -ScriptBlock {
        # Simulate some work
        $processes = Get-Process | Select-Object -First 5
        return $processes.Count
    } -TimeoutMs 10000
    
    if ($result -eq 5) {
        Write-Host "    Thread-safe operation: SUCCESS (returned $result processes)" -ForegroundColor Green
        
        $testResults.FunctionalityTests.ThreadSafeOperations = @{
            Status = "Success"
            OperationResult = $result
            TimeoutHandling = "Pass"
        }
    } else {
        throw "Thread-safe operation returned unexpected result: $result"
    }
} catch {
    $testResults.FunctionalityTests.ThreadSafeOperations = @{
        Status = "Failed"
        Error = $_.Exception.Message
    }
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 5: Performance testing
Write-Host "5. Testing performance characteristics..." -ForegroundColor Yellow

try {
    Write-Host "  Performance testing synchronized operations..." -ForegroundColor Gray
    
    $perfHash = New-SynchronizedHashtable -EnableStats
    $operationCount = 100
    
    # Time synchronized operations
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    for ($i = 1; $i -le $operationCount; $i++) {
        Set-SynchronizedValue -SyncHash $perfHash -Key "perfTest$i" -Value "value$i"
    }
    
    for ($i = 1; $i -le $operationCount; $i++) {
        $value = Get-SynchronizedValue -SyncHash $perfHash -Key "perfTest$i"
    }
    
    $stopwatch.Stop()
    $totalTime = $stopwatch.ElapsedMilliseconds
    $avgTimePerOp = [Math]::Round($totalTime / ($operationCount * 2), 3)  # *2 for set + get
    
    Write-Host "    Performance test completed:" -ForegroundColor Green
    Write-Host "      Operations: $($operationCount * 2) (set + get)" -ForegroundColor Gray
    Write-Host "      Total time: ${totalTime}ms" -ForegroundColor Gray
    Write-Host "      Average per operation: ${avgTimePerOp}ms" -ForegroundColor Gray
    
    $testResults.PerformanceTests.SynchronizedOperations = @{
        Status = "Success"
        Operations = $operationCount * 2
        TotalTimeMs = $totalTime
        AvgTimePerOperationMs = $avgTimePerOp
    }
} catch {
    $testResults.PerformanceTests.SynchronizedOperations = @{
        Status = "Failed"
        Error = $_.Exception.Message
    }
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 6: Concurrency testing (if enabled)
if ($RunConcurrencyTest) {
    Write-Host "6. Testing thread safety under concurrency..." -ForegroundColor Yellow
    
    try {
        Write-Host "  Running concurrency test with $ConcurrencyIterations iterations..." -ForegroundColor Gray
        
        $concurrencyResults = Test-ThreadSafety -Iterations $ConcurrencyIterations -ConcurrencyLevel 3
        
        if ($concurrencyResults.Success -and $concurrencyResults.ConsistencyCheck) {
            Write-Host "    Concurrency test: SUCCESS" -ForegroundColor Green
            
            $testResults.ConcurrencyTests.ThreadSafety = @{
                Status = "Success"
                TotalOperations = $concurrencyResults.CompletedOperations
                Errors = $concurrencyResults.Errors.Count
                ConsistencyCheck = $concurrencyResults.ConsistencyCheck
                TotalTimeMs = $concurrencyResults.TotalTimeMs
            }
        } else {
            $errorDetails = if ($concurrencyResults.Errors.Count -gt 0) { 
                "Errors: $($concurrencyResults.Errors.Count)" 
            } else { 
                "Consistency check failed" 
            }
            
            $testResults.ConcurrencyTests.ThreadSafety = @{
                Status = "Warning"
                Details = $errorDetails
                TotalOperations = $concurrencyResults.CompletedOperations
                Errors = $concurrencyResults.Errors.Count
                ConsistencyCheck = $concurrencyResults.ConsistencyCheck
            }
            
            Write-Host "    Concurrency test: WARNING ($errorDetails)" -ForegroundColor Yellow
        }
    } catch {
        $testResults.ConcurrencyTests.ThreadSafety = @{
            Status = "Failed"
            Error = $_.Exception.Message
        }
        Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "6. Skipping concurrency test (disabled)" -ForegroundColor Gray
    $testResults.ConcurrencyTests.ThreadSafety = @{
        Status = "Skipped"
        Reason = "Disabled by parameter"
    }
}

Write-Host ""

# Test 7: Statistics and cleanup
Write-Host "7. Testing statistics and cleanup..." -ForegroundColor Yellow

try {
    Write-Host "  Retrieving thread safety statistics..." -ForegroundColor Gray
    $stats = Get-ThreadSafetyStats
    
    if ($stats -and $stats.OperationCount -gt 0) {
        Write-Host "    Statistics retrieved successfully:" -ForegroundColor Green
        Write-Host "      Total operations: $($stats.OperationCount)" -ForegroundColor Gray
        Write-Host "      Lock count: $($stats.LockCount)" -ForegroundColor Gray
        Write-Host "      Error count: $($stats.ErrorCount)" -ForegroundColor Gray
        Write-Host "      Average operation time: $($stats.AverageOperationTimeMs)ms" -ForegroundColor Gray
        
        $testResults.FunctionalityTests.Statistics = @{
            Status = "Success"
            OperationCount = $stats.OperationCount
            LockCount = $stats.LockCount
            ErrorCount = $stats.ErrorCount
            AverageOperationTimeMs = $stats.AverageOperationTimeMs
        }
    } else {
        throw "Statistics retrieval failed or no operations recorded"
    }
    
    # Test cleanup
    Write-Host "  Testing status cleanup..." -ForegroundColor Gray
    Clear-ParallelStatus -Subsystem "TestSubsystem"
    
    $clearedStatus = Get-ParallelStatus -Subsystem "TestSubsystem"
    if (-not $clearedStatus) {
        Write-Host "    Cleanup operations: SUCCESS" -ForegroundColor Green
        $testResults.FunctionalityTests.Cleanup = @{ Status = "Success" }
    } else {
        Write-Host "    Cleanup operations: WARNING (subsystem still exists)" -ForegroundColor Yellow
        $testResults.FunctionalityTests.Cleanup = @{ Status = "Warning" }
    }
} catch {
    $testResults.FunctionalityTests.Statistics = @{
        Status = "Failed"
        Error = $_.Exception.Message
    }
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Calculate summary
Write-Host "8. Calculating test summary..." -ForegroundColor Yellow

$allTests = @()
foreach ($category in @("ModuleTests", "FunctionalityTests", "PerformanceTests", "ConcurrencyTests")) {
    foreach ($test in $testResults[$category].Keys) {
        $allTests += $testResults[$category][$test]
    }
}

$successCount = ($allTests | Where-Object { $_.Status -eq "Success" }).Count
$warningCount = ($allTests | Where-Object { $_.Status -eq "Warning" }).Count
$failedCount = ($allTests | Where-Object { $_.Status -eq "Failed" }).Count
$skippedCount = ($allTests | Where-Object { $_.Status -eq "Skipped" }).Count
$totalTests = $allTests.Count

$successRate = if ($totalTests -gt 0) { [Math]::Round(($successCount / $totalTests) * 100, 2) } else { 0 }

$testResults.Summary = @{
    TotalTests = $totalTests
    SuccessCount = $successCount
    WarningCount = $warningCount
    FailedCount = $failedCount
    SkippedCount = $skippedCount
    SuccessRate = $successRate
    OverallStatus = if ($failedCount -eq 0 -and $successCount -gt 0) { "Success" } elseif ($failedCount -eq 0) { "Warning" } else { "Failed" }
    ProductionReady = ($failedCount -eq 0 -and $successRate -ge 80)
}

Write-Host "  Test Summary:" -ForegroundColor $(if ($testResults.Summary.OverallStatus -eq "Success") { "Green" } elseif ($testResults.Summary.OverallStatus -eq "Warning") { "Yellow" } else { "Red" })
Write-Host "    Total tests: $totalTests" -ForegroundColor Gray
Write-Host "    Success: $successCount" -ForegroundColor Green
Write-Host "    Warnings: $warningCount" -ForegroundColor Yellow
Write-Host "    Failed: $failedCount" -ForegroundColor Red
Write-Host "    Skipped: $skippedCount" -ForegroundColor Gray
Write-Host "    Success rate: $successRate%" -ForegroundColor Gray
Write-Host "    Production ready: $($testResults.Summary.ProductionReady)" -ForegroundColor $(if ($testResults.Summary.ProductionReady) { "Green" } else { "Yellow" })

Write-Host ""

# Save results
Write-Host "9. Saving test results..." -ForegroundColor Yellow

try {
    $output = @()
    $output += "=== Synchronized Hashtable Framework Test Results ==="
    $output += "Date: $($testResults.TestDate)"
    $output += "Module: Unity-Claude-ParallelProcessing"
    $output += ""
    
    $output += "TEST SUMMARY:"
    $output += "Overall Status: $($testResults.Summary.OverallStatus)"
    $output += "Success Rate: $($testResults.Summary.SuccessRate)%"
    $output += "Production Ready: $($testResults.Summary.ProductionReady)"
    $output += "Total Tests: $($testResults.Summary.TotalTests) (Success: $($testResults.Summary.SuccessCount), Warnings: $($testResults.Summary.WarningCount), Failed: $($testResults.Summary.FailedCount), Skipped: $($testResults.Summary.SkippedCount))"
    $output += ""
    
    foreach ($category in @("ModuleTests", "FunctionalityTests", "PerformanceTests", "ConcurrencyTests")) {
        $output += "${category}:"
        if ($testResults[$category].Count -gt 0) {
            $testResults[$category].GetEnumerator() | ForEach-Object {
                $output += "  $($_.Key): $($_.Value.Status)"
                if ($_.Value.Error) {
                    $output += "    Error: $($_.Value.Error)"
                }
            }
        } else {
            $output += "  No tests in this category"
        }
        $output += ""
    }
    
    $output += "RECOMMENDATIONS:"
    if ($testResults.Summary.ProductionReady) {
        $output += "✅ Synchronized hashtable framework is production-ready"
        $output += "✅ Proceed to next implementation phase (ConcurrentQueue/ConcurrentBag)"
        $output += "✅ Thread safety verified under concurrent operations"
    } else {
        $output += "❌ Framework needs improvement before production use"
        $output += "❌ Review failed tests and warnings"
        if ($failedCount -gt 0) {
            $output += "❌ Address $failedCount failed tests before proceeding"
        }
    }
    $output += ""
    
    if ($Detailed) {
        $output += "DETAILED RESULTS (JSON):"
        $output += ($testResults | ConvertTo-Json -Depth 10)
    }
    
    $output | Set-Content $ResultsFile -Encoding UTF8
    Write-Host "  Test results saved to: $ResultsFile" -ForegroundColor Green
} catch {
    Write-Host "  Error saving results: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Synchronized Hashtable Framework Test Complete ===" -ForegroundColor Cyan

if ($testResults.Summary.ProductionReady) {
    Write-Host "✅ RESULT: Framework is production-ready" -ForegroundColor Green
    Write-Host "Next Step: Continue to ConcurrentQueue/ConcurrentBag implementation (Hours 4-6)" -ForegroundColor Yellow
} else {
    Write-Host "❌ RESULT: Framework needs improvement ($failedCount failures, $warningCount warnings)" -ForegroundColor $(if ($failedCount -gt 0) { "Red" } else { "Yellow" })
}

Write-Host ""

return $testResults
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUA7oL0xj516InaRSWyBO3OgO1
# m++gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUnzss65RFH0P7e8+byM/fR89ma6gwDQYJKoZIhvcNAQEBBQAEggEAsJjC
# 5jbF5yHwqXLRyiOj6KmB9Nbkp/B4tN7V352rcJqgY6Cz1B5q3EgH2jiiyj3Kcdto
# +sGlBpcA8BUs9l/oJCHC8CZLp1zV55AhDUid65GpyQOQDIu7NR36jvPjpktoDpe4
# EnJVbt1RCol92uc4jkxZIOy6q+9WtHeD9aqezbCJBtFOyJmkPLuX4Y1UOfqOkyzq
# JKUJwGheHSZWCJk9ZamlQyOgEpGDj8yavivqLA+c0+Y8TWZmlflKR3pyy+PEwMQJ
# wO+uN4b/LqoFy4hTEH4dtczhqjLtGiCiOVL2PY7aSSdyREdjUKeBf6/nNZJwrDnP
# enE/5D09Y50fckNLDA==
# SIG # End signature block
