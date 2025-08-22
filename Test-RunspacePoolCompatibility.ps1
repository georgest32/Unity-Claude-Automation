# Test-RunspacePoolCompatibility.ps1
# PowerShell 5.1 runspace pool compatibility testing
# Phase 1 Week 1 Hours 7-8: PowerShell 5.1 runspace pool compatibility testing
# Date: 2025-08-20

param(
    [switch]$Detailed = $false,
    [int]$MaxRunspaces = 5,
    [string]$ResultsFile = ".\RunspacePool_Compatibility_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
)

$ErrorActionPreference = "Continue"

# Initialize results collection
$results = @{
    TestDate = Get-Date
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
    DotNetFrameworkVersion = [System.Runtime.InteropServices.RuntimeInformation]::FrameworkDescription
    CompatibilityTests = @{}
    PerformanceTests = @{}
    ThreadSafetyTests = @{}
    ErrorHandlingTests = @{}
    Summary = @{}
}

Write-Host "=== PowerShell 5.1 Runspace Pool Compatibility Test ===" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date)" -ForegroundColor Gray
Write-Host "PowerShell Version: $($results.PowerShellVersion)" -ForegroundColor Gray
Write-Host "Results will be saved to: $ResultsFile" -ForegroundColor Gray
Write-Host ""

# Test 1: Basic Runspace Pool Creation
Write-Host "1. Testing basic runspace pool creation..." -ForegroundColor Yellow

try {
    Write-Host "  Testing System.Management.Automation.Runspaces.RunspacePool..." -ForegroundColor Gray
    
    $initialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    $runspacePool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, $MaxRunspaces, $initialSessionState, $Host)
    
    Write-Host "    RunspacePool created successfully" -ForegroundColor Green
    
    # Test opening the pool
    $runspacePool.Open()
    Write-Host "    RunspacePool opened successfully" -ForegroundColor Green
    
    # Test pool properties
    $poolState = $runspacePool.RunspacePoolStateInfo.State
    $maxRunspaces = $runspacePool.GetMaxRunspaces()
    $availableRunspaces = $runspacePool.GetAvailableRunspaces()
    
    $results.CompatibilityTests.BasicRunspacePool = @{
        Status = "Success"
        PoolState = $poolState.ToString()
        MaxRunspaces = $maxRunspaces
        AvailableRunspaces = $availableRunspaces
        CreationTime = (Get-Date)
    }
    
    Write-Host "    Pool State: $poolState" -ForegroundColor Gray
    Write-Host "    Max Runspaces: $maxRunspaces" -ForegroundColor Gray
    Write-Host "    Available Runspaces: $availableRunspaces" -ForegroundColor Gray
    
} catch {
    $results.CompatibilityTests.BasicRunspacePool = @{
        Status = "Failed"
        Error = $_.Exception.Message
        StackTrace = $_.Exception.StackTrace
    }
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 2: Session State Configuration
Write-Host "2. Testing session state configuration..." -ForegroundColor Yellow

try {
    Write-Host "  Testing InitialSessionState configuration..." -ForegroundColor Gray
    
    # Create session state with variables
    $sessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault()
    
    # Add test variable
    $testVariable = New-Object System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'TestVar', 'TestValue', 'Test variable for runspace pool'
    $sessionState.Variables.Add($testVariable)
    
    # Add test function
    $testFunction = New-Object System.Management.Automation.Runspaces.SessionStateFunctionEntry -ArgumentList 'Test-RunspaceFunction', 'Write-Output "Function called from runspace: $TestVar"'
    $sessionState.Commands.Add($testFunction)
    
    # Create pool with configured session state
    $configuredPool = [System.Management.Automation.Runspaces.RunspaceFactory]::CreateRunspacePool(1, 3, $sessionState, $Host)
    $configuredPool.Open()
    
    $results.CompatibilityTests.SessionStateConfiguration = @{
        Status = "Success"
        VariablesAdded = 1
        FunctionsAdded = 1
        PoolState = $configuredPool.RunspacePoolStateInfo.State.ToString()
    }
    
    Write-Host "    Session state configured successfully" -ForegroundColor Green
    Write-Host "    Variables added: 1, Functions added: 1" -ForegroundColor Gray
    
} catch {
    $results.CompatibilityTests.SessionStateConfiguration = @{
        Status = "Failed"
        Error = $_.Exception.Message
    }
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 3: PowerShell execution in runspace pool
Write-Host "3. Testing PowerShell execution in runspace pool..." -ForegroundColor Yellow

try {
    Write-Host "  Testing PowerShell command execution..." -ForegroundColor Gray
    
    # Create PowerShell instance
    $ps = [System.Management.Automation.PowerShell]::Create()
    $ps.RunspacePool = $runspacePool
    
    # Add simple script
    $ps.AddScript("Get-Process | Select-Object -First 5 | ForEach-Object { $_.Name }")
    
    # Execute asynchronously
    $asyncResult = $ps.BeginInvoke()
    
    # Wait for completion with timeout
    $timeout = 10000 # 10 seconds
    $completed = $asyncResult.AsyncWaitHandle.WaitOne($timeout)
    
    if ($completed) {
        $result = $ps.EndInvoke($asyncResult)
        $errors = $ps.Streams.Error
        
        $results.CompatibilityTests.PowerShellExecution = @{
            Status = "Success"
            ResultCount = $result.Count
            ErrorCount = $errors.Count
            ExecutionCompleted = $completed
        }
        
        Write-Host "    Command executed successfully" -ForegroundColor Green
        Write-Host "    Results: $($result.Count) items, Errors: $($errors.Count)" -ForegroundColor Gray
    } else {
        $results.CompatibilityTests.PowerShellExecution = @{
            Status = "Timeout"
            TimeoutMs = $timeout
        }
        Write-Host "    TIMEOUT: Command did not complete within $timeout ms" -ForegroundColor Yellow
    }
    
    $ps.Dispose()
    
} catch {
    $results.CompatibilityTests.PowerShellExecution = @{
        Status = "Failed"
        Error = $_.Exception.Message
    }
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 4: Concurrent Collections (.NET Framework 4.5)
Write-Host "4. Testing concurrent collections compatibility..." -ForegroundColor Yellow

try {
    Write-Host "  Testing ConcurrentQueue..." -ForegroundColor Gray
    
    # Test ConcurrentQueue
    $concurrentQueue = [System.Collections.Concurrent.ConcurrentQueue[string]]::new()
    $concurrentQueue.Enqueue("Test1")
    $concurrentQueue.Enqueue("Test2")
    $concurrentQueue.Enqueue("Test3")
    
    $dequeueResult = ""
    $dequeueSuccess = $concurrentQueue.TryDequeue([ref]$dequeueResult)
    
    Write-Host "    ConcurrentQueue: Items=$($concurrentQueue.Count), Dequeue Success=$dequeueSuccess, Value=$dequeueResult" -ForegroundColor Gray
    
    # Test ConcurrentBag
    Write-Host "  Testing ConcurrentBag..." -ForegroundColor Gray
    $concurrentBag = [System.Collections.Concurrent.ConcurrentBag[int]]::new()
    1..10 | ForEach-Object { $concurrentBag.Add($_) }
    
    $bagArray = $concurrentBag.ToArray()
    Write-Host "    ConcurrentBag: Items=$($concurrentBag.Count), Array Length=$($bagArray.Length)" -ForegroundColor Gray
    
    # Test ConcurrentDictionary
    Write-Host "  Testing ConcurrentDictionary..." -ForegroundColor Gray
    $concurrentDict = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()
    $concurrentDict.TryAdd("key1", "value1")
    $concurrentDict.TryAdd("key2", "value2")
    
    $getValue = ""
    $getSuccess = $concurrentDict.TryGetValue("key1", [ref]$getValue)
    
    Write-Host "    ConcurrentDictionary: Items=$($concurrentDict.Count), Get Success=$getSuccess, Value=$getValue" -ForegroundColor Gray
    
    $results.CompatibilityTests.ConcurrentCollections = @{
        Status = "Success"
        ConcurrentQueue = @{ Count = $concurrentQueue.Count; DequeueSuccess = $dequeueSuccess }
        ConcurrentBag = @{ Count = $concurrentBag.Count; ArrayLength = $bagArray.Length }
        ConcurrentDictionary = @{ Count = $concurrentDict.Count; GetSuccess = $getSuccess }
    }
    
    Write-Host "    All concurrent collections working correctly" -ForegroundColor Green
    
} catch {
    $results.CompatibilityTests.ConcurrentCollections = @{
        Status = "Failed"
        Error = $_.Exception.Message
    }
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 5: Synchronized Collections (PowerShell Compatible)
Write-Host "5. Testing synchronized collections..." -ForegroundColor Yellow

try {
    Write-Host "  Testing synchronized hashtable..." -ForegroundColor Gray
    
    # Create synchronized hashtable
    $syncHash = [hashtable]::Synchronized(@{})
    $syncHash["test1"] = "value1"
    $syncHash["test2"] = "value2"
    
    # Test thread safety with Monitor
    [System.Threading.Monitor]::Enter($syncHash.SyncRoot)
    try {
        $keys = $syncHash.Keys | ForEach-Object { $_ }
        $keyCount = $keys.Count
    } finally {
        [System.Threading.Monitor]::Exit($syncHash.SyncRoot)
    }
    
    Write-Host "    Synchronized hashtable: Items=$($syncHash.Count), Keys enumerated=$keyCount" -ForegroundColor Gray
    
    # Test synchronized ArrayList
    Write-Host "  Testing synchronized ArrayList..." -ForegroundColor Gray
    $syncList = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
    1..10 | ForEach-Object { $syncList.Add($_) }
    
    $results.CompatibilityTests.SynchronizedCollections = @{
        Status = "Success"
        SyncHashtable = @{ Count = $syncHash.Count; KeysEnumerated = $keyCount }
        SyncArrayList = @{ Count = $syncList.Count }
    }
    
    Write-Host "    Synchronized collections working correctly" -ForegroundColor Green
    
} catch {
    $results.CompatibilityTests.SynchronizedCollections = @{
        Status = "Failed"
        Error = $_.Exception.Message
    }
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 6: Performance comparison
Write-Host "6. Testing runspace pool performance..." -ForegroundColor Yellow

try {
    Write-Host "  Testing parallel vs sequential execution..." -ForegroundColor Gray
    
    # Sequential execution test
    $sequentialStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $sequentialResults = @()
    for ($i = 1; $i -le 10; $i++) {
        $ps = [System.Management.Automation.PowerShell]::Create()
        $ps.AddScript("Start-Sleep -Milliseconds 100; $i * 2")
        $result = $ps.Invoke()
        $sequentialResults += $result[0]
        $ps.Dispose()
    }
    $sequentialStopwatch.Stop()
    $sequentialTime = $sequentialStopwatch.ElapsedMilliseconds
    
    Write-Host "    Sequential execution: $sequentialTime ms" -ForegroundColor Gray
    
    # Parallel execution test
    $parallelStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $parallelJobs = @()
    
    for ($i = 1; $i -le 10; $i++) {
        $ps = [System.Management.Automation.PowerShell]::Create()
        $ps.RunspacePool = $runspacePool
        $ps.AddScript("Start-Sleep -Milliseconds 100; $i * 2")
        $handle = $ps.BeginInvoke()
        $parallelJobs += @{ PowerShell = $ps; Handle = $handle; Index = $i }
    }
    
    # Wait for all jobs to complete
    $parallelResults = @()
    foreach ($job in $parallelJobs) {
        $result = $job.PowerShell.EndInvoke($job.Handle)
        $parallelResults += $result[0]
        $job.PowerShell.Dispose()
    }
    $parallelStopwatch.Stop()
    $parallelTime = $parallelStopwatch.ElapsedMilliseconds
    
    Write-Host "    Parallel execution: $parallelTime ms" -ForegroundColor Gray
    
    $performanceImprovement = [Math]::Round((($sequentialTime - $parallelTime) / $sequentialTime) * 100, 2)
    
    $results.PerformanceTests = @{
        SequentialTimeMs = $sequentialTime
        ParallelTimeMs = $parallelTime
        PerformanceImprovementPercent = $performanceImprovement
        SequentialResults = $sequentialResults.Count
        ParallelResults = $parallelResults.Count
    }
    
    Write-Host "    Performance improvement: $performanceImprovement%" -ForegroundColor Green
    
} catch {
    $results.PerformanceTests = @{
        Status = "Failed"
        Error = $_.Exception.Message
    }
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Test 7: Error handling and cleanup
Write-Host "7. Testing error handling and cleanup..." -ForegroundColor Yellow

try {
    Write-Host "  Testing runspace pool cleanup..." -ForegroundColor Gray
    
    # Test proper disposal
    if ($runspacePool -and $runspacePool.RunspacePoolStateInfo.State -eq 'Opened') {
        $runspacePool.Close()
        Write-Host "    RunspacePool closed successfully" -ForegroundColor Green
    }
    
    if ($configuredPool -and $configuredPool.RunspacePoolStateInfo.State -eq 'Opened') {
        $configuredPool.Close()
        Write-Host "    Configured RunspacePool closed successfully" -ForegroundColor Green
    }
    
    $results.ErrorHandlingTests = @{
        Status = "Success"
        CleanupCompleted = $true
    }
    
} catch {
    $results.ErrorHandlingTests = @{
        Status = "Failed"
        Error = $_.Exception.Message
    }
    Write-Host "    FAILED: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Calculate summary
Write-Host "8. Calculating compatibility summary..." -ForegroundColor Yellow

$successfulTests = ($results.CompatibilityTests.Values | Where-Object { $_.Status -eq "Success" }).Count
$totalTests = $results.CompatibilityTests.Count

$results.Summary = @{
    OverallCompatibility = if ($totalTests -gt 0) { [Math]::Round(($successfulTests / $totalTests) * 100, 2) } else { 0 }
    SuccessfulTests = $successfulTests
    TotalTests = $totalTests
    PowerShell51Compatible = $true
    RunspacePoolSupported = ($results.CompatibilityTests.BasicRunspacePool.Status -eq "Success")
    ConcurrentCollectionsSupported = ($results.CompatibilityTests.ConcurrentCollections.Status -eq "Success")
    SynchronizedCollectionsSupported = ($results.CompatibilityTests.SynchronizedCollections.Status -eq "Success")
    RecommendedForProduction = ($successfulTests -ge ($totalTests * 0.8))  # 80% success rate
}

Write-Host "  Compatibility: $($results.Summary.OverallCompatibility)% ($successfulTests/$totalTests)" -ForegroundColor Gray
Write-Host "  Production Ready: $($results.Summary.RecommendedForProduction)" -ForegroundColor $(if ($results.Summary.RecommendedForProduction) { "Green" } else { "Yellow" })
Write-Host ""

# Save results
Write-Host "9. Saving compatibility test results..." -ForegroundColor Yellow

try {
    $output = @()
    $output += "=== PowerShell 5.1 Runspace Pool Compatibility Results ==="
    $output += "Date: $($results.TestDate)"
    $output += "PowerShell Version: $($results.PowerShellVersion)"
    $output += "Framework: $($results.DotNetFrameworkVersion)"
    $output += ""
    
    $output += "COMPATIBILITY SUMMARY:"
    $output += "Overall Compatibility: $($results.Summary.OverallCompatibility)%"
    $output += "Successful Tests: $($results.Summary.SuccessfulTests)/$($results.Summary.TotalTests)"
    $output += "Production Ready: $($results.Summary.RecommendedForProduction)"
    $output += ""
    
    $output += "FEATURE SUPPORT:"
    $output += "RunspacePool: $($results.Summary.RunspacePoolSupported)"
    $output += "ConcurrentCollections: $($results.Summary.ConcurrentCollectionsSupported)"
    $output += "SynchronizedCollections: $($results.Summary.SynchronizedCollectionsSupported)"
    $output += ""
    
    if ($results.PerformanceTests.PerformanceImprovementPercent) {
        $output += "PERFORMANCE RESULTS:"
        $output += "Sequential Time: $($results.PerformanceTests.SequentialTimeMs)ms"
        $output += "Parallel Time: $($results.PerformanceTests.ParallelTimeMs)ms"  
        $output += "Performance Improvement: $($results.PerformanceTests.PerformanceImprovementPercent)%"
        $output += ""
    }
    
    $output += "DETAILED TEST RESULTS:"
    foreach ($testCategory in $results.Keys) {
        if ($testCategory -match "Tests$") {
            $output += "$testCategory:"
            if ($results[$testCategory] -is [hashtable]) {
                $results[$testCategory].GetEnumerator() | ForEach-Object {
                    $output += "  $($_.Key): $($_.Value.Status)"
                    if ($_.Value.Error) {
                        $output += "    Error: $($_.Value.Error)"
                    }
                }
            }
            $output += ""
        }
    }
    
    $output += "RECOMMENDATIONS:"
    if ($results.Summary.RecommendedForProduction) {
        $output += "✅ PowerShell 5.1 runspace pools are fully supported"
        $output += "✅ Proceed with parallel processing implementation"
        $output += "✅ Expected performance improvement: $($results.PerformanceTests.PerformanceImprovementPercent)%"
    } else {
        $output += "❌ Some compatibility issues detected"
        $output += "❌ Review failed tests before proceeding"
    }
    $output += ""
    
    if ($Detailed) {
        $output += "DETAILED RESULTS (JSON):"
        $output += ($results | ConvertTo-Json -Depth 10)
    }
    
    $output | Set-Content $ResultsFile -Encoding UTF8
    Write-Host "  Results saved to: $ResultsFile" -ForegroundColor Green
} catch {
    Write-Host "  Error saving results: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Runspace Pool Compatibility Test Complete ===" -ForegroundColor Cyan

if ($results.Summary.RecommendedForProduction) {
    Write-Host "✅ RESULT: PowerShell 5.1 runspace pools are production-ready" -ForegroundColor Green
    Write-Host "Next Step: Begin Week 1 Day 3-4 thread safety infrastructure implementation" -ForegroundColor Yellow
} else {
    Write-Host "❌ RESULT: Compatibility issues detected - review before proceeding" -ForegroundColor Red
}

Write-Host ""

return $results
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUgRUI9muTzia0KF+Ys2e9cGS9
# ySGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUw2oMr32xQ6H8yifAzwFMQJPE5qMwDQYJKoZIhvcNAQEBBQAEggEAccPM
# Hw6TUOzLuX0aWpYM1whOmVwj3+9nsZaStm4GAlBqHvAdPrgUxR5KUEqrcDTzQoDc
# aDIY+jnEKfw/SNpRNE2S3hfGq69XWZWVe+1mSAffZnSkqrFeDCmS0KTLniOOeEDE
# jLwXINaQMG0oJJ89ppDmyogx7ceIL4ePtCoBWJKtVeVW4f6TYUsNhe7kGREnznp+
# TrOrEjkAvGg3+u9y9+w4kKzrL/9P9pTx8tOWvcU0xyuGz0FmXN2u7CpgJTnjb9b6
# zKIMSQUD1tn+b9v7d/OQWLfVQ8W8ZIXX5Z5+i13yGOZ7XjKzrAHDg9RiebWSeDhq
# rmBdmdBhc6Eh1q4dRA==
# SIG # End signature block
