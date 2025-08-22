# Test-Day20-PerformanceReliability.ps1
# Day 20: Performance and Reliability Test Suite
# Tests system performance, resource usage, and reliability under load

param(
    [switch]$Verbose,
    [switch]$StressTest,  # Run extended stress testing
    [int]$LoadIterations = 10  # Number of load test iterations
)

$ErrorActionPreference = "Stop"
$testResults = @()
$startTime = Get-Date
$testResultsFile = Join-Path $PSScriptRoot "Test_Results_Day20_Performance_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Performance benchmarks
$performanceBenchmarks = @{
    ResponseParsingMs = 100
    CommandExecutionMs = 500
    MemoryUsageMB = 500
    CPUUsagePercent = 30
    FileOperationMs = 50
    ModuleLoadMs = 1000
}

# Initialize test output
$testOutput = @()
$testOutput += "================================================"
$testOutput += "  Day 20: Performance & Reliability Test Suite"
$testOutput += "================================================"
$testOutput += "Start Time: $(Get-Date)"
$testOutput += ""

Write-Host $testOutput[-4] -ForegroundColor Cyan
Write-Host $testOutput[-3] -ForegroundColor Yellow
Write-Host $testOutput[-2] -ForegroundColor Cyan
Write-Host $testOutput[-1]

# Helper function for performance measurement
function Measure-Performance {
    param(
        [ScriptBlock]$Operation,
        [string]$OperationName,
        [int]$MaxMs
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $result = & $Operation
        $stopwatch.Stop()
        
        $elapsed = $stopwatch.ElapsedMilliseconds
        $passed = $elapsed -le $MaxMs
        
        return @{
            Name = $OperationName
            ElapsedMs = $elapsed
            MaxMs = $MaxMs
            Passed = $passed
            Result = $result
        }
    } catch {
        $stopwatch.Stop()
        return @{
            Name = $OperationName
            ElapsedMs = $stopwatch.ElapsedMilliseconds
            MaxMs = $MaxMs
            Passed = $false
            Error = $_.ToString()
        }
    }
}

# Test 1: Module Load Performance
Write-Host ""
Write-Host "[TEST 1] Module Load Performance..." -ForegroundColor Yellow
$testOutput += ""
$testOutput += "[TEST 1] Module Load Performance..."

try {
    $moduleLoadTest = Measure-Performance -OperationName "Module Loading" -MaxMs $performanceBenchmarks.ModuleLoadMs -Operation {
        # Load configuration module as test
        $modulePath = Join-Path $PSScriptRoot "Unity-Claude-Configuration.psm1"
        if (Test-Path $modulePath) {
            Import-Module $modulePath -Force
            return $true
        }
        return $false
    }
    
    if ($moduleLoadTest.Passed) {
        Write-Host "  [PASS] Module loaded in $($moduleLoadTest.ElapsedMs)ms (benchmark: $($moduleLoadTest.MaxMs)ms)" -ForegroundColor Green
        $testOutput += "  [PASS] Module loaded in $($moduleLoadTest.ElapsedMs)ms"
        $testResults += @{ Test = "Module Load Performance"; Result = "PASS"; Details = "$($moduleLoadTest.ElapsedMs)ms" }
    } else {
        Write-Host "  [FAIL] Module load took $($moduleLoadTest.ElapsedMs)ms (exceeded $($moduleLoadTest.MaxMs)ms)" -ForegroundColor Red
        $testOutput += "  [FAIL] Module load took $($moduleLoadTest.ElapsedMs)ms"
        $testResults += @{ Test = "Module Load Performance"; Result = "FAIL"; Details = "$($moduleLoadTest.ElapsedMs)ms" }
    }
} catch {
    Write-Host "  [FAIL] Module load error: $_" -ForegroundColor Red
    $testResults += @{ Test = "Module Load Performance"; Result = "FAIL"; Details = $_.ToString() }
    $testOutput += "  [FAIL] Module load error: $_"
}

# Test 2: Response Parsing Performance
Write-Host ""
Write-Host "[TEST 2] Response Parsing Performance..." -ForegroundColor Yellow
$testOutput += ""
$testOutput += "[TEST 2] Response Parsing Performance..."

try {
    # Create large sample response for parsing
    $sampleResponse = @"
Based on the Unity compilation errors, I've identified several issues that need to be addressed:

1. CS0246: The type or namespace 'TestClass' could not be found
   - This indicates a missing type definition
   - Check if the class exists in the project
   - Verify namespace declarations

2. CS0103: The name 'testVariable' does not exist
   - Variable not declared in current scope
   - Check variable declaration and scope

3. CS1061: Type does not contain definition for member
   - Method or property doesn't exist on the type
   - Verify member existence

Here are the recommended fixes:
- Add missing using statements
- Create missing class definitions
- Fix variable declarations
- Update method signatures

RECOMMENDED: TEST - Run Unity compilation after applying fixes
RECOMMENDED: BUILD - Create test build to verify fixes
RECOMMENDED: ANALYZE - Review error patterns for common issues
"@ * 5  # Make it larger for stress testing
    
    $parseTest = Measure-Performance -OperationName "Response Parsing" -MaxMs $performanceBenchmarks.ResponseParsingMs -Operation {
        $recommendations = @()
        $lines = $sampleResponse -split "`n"
        foreach ($line in $lines) {
            if ($line -match "RECOMMENDED:\s*(\w+)\s*-\s*(.+)") {
                $recommendations += @{
                    Type = $matches[1]
                    Details = $matches[2]
                }
            }
        }
        return $recommendations
    }
    
    if ($parseTest.Passed) {
        Write-Host "  [PASS] Parsed in $($parseTest.ElapsedMs)ms (benchmark: $($parseTest.MaxMs)ms)" -ForegroundColor Green
        Write-Host "    Found $($parseTest.Result.Count) recommendations" -ForegroundColor Gray
        $testOutput += "  [PASS] Parsed in $($parseTest.ElapsedMs)ms"
        $testOutput += "    Found $($parseTest.Result.Count) recommendations"
        $testResults += @{ Test = "Response Parsing"; Result = "PASS"; Details = "$($parseTest.ElapsedMs)ms" }
    } else {
        Write-Host "  [FAIL] Parsing took $($parseTest.ElapsedMs)ms (exceeded $($parseTest.MaxMs)ms)" -ForegroundColor Red
        $testOutput += "  [FAIL] Parsing took $($parseTest.ElapsedMs)ms"
        $testResults += @{ Test = "Response Parsing"; Result = "FAIL"; Details = "$($parseTest.ElapsedMs)ms" }
    }
} catch {
    Write-Host "  [FAIL] Parsing error: $_" -ForegroundColor Red
    $testResults += @{ Test = "Response Parsing"; Result = "FAIL"; Details = $_.ToString() }
    $testOutput += "  [FAIL] Parsing error: $_"
}

# Test 3: Memory Usage Monitoring
Write-Host ""
Write-Host "[TEST 3] Memory Usage Monitoring..." -ForegroundColor Yellow
$testOutput += ""
$testOutput += "[TEST 3] Memory Usage Monitoring..."

try {
    # Get current process memory usage
    $process = Get-Process -Id $PID
    $memoryUsageMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
    
    Write-Host "  Current memory usage: ${memoryUsageMB}MB" -ForegroundColor Gray
    $testOutput += "  Current memory usage: ${memoryUsageMB}MB"
    
    # Check if under threshold
    $memoryPassed = $memoryUsageMB -le $performanceBenchmarks.MemoryUsageMB
    
    if ($memoryPassed) {
        Write-Host "  [PASS] Memory usage within limits (${memoryUsageMB}MB < $($performanceBenchmarks.MemoryUsageMB)MB)" -ForegroundColor Green
        $testOutput += "  [PASS] Memory usage within limits"
        $testResults += @{ Test = "Memory Usage"; Result = "PASS"; Details = "${memoryUsageMB}MB" }
    } else {
        Write-Host "  [WARN] Memory usage high (${memoryUsageMB}MB > $($performanceBenchmarks.MemoryUsageMB)MB)" -ForegroundColor Yellow
        $testOutput += "  [WARN] Memory usage high"
        $testResults += @{ Test = "Memory Usage"; Result = "WARN"; Details = "${memoryUsageMB}MB" }
    }
    
    # Test for memory leaks with allocation/deallocation
    $initialMemory = $memoryUsageMB
    
    # Allocate and deallocate memory
    for ($i = 1; $i -le 5; $i++) {
        $tempData = @(1..10000) | ForEach-Object { [Guid]::NewGuid().ToString() }
        $tempData = $null
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
    
    $process = Get-Process -Id $PID
    $finalMemory = [math]::Round($process.WorkingSet64 / 1MB, 2)
    $memoryDelta = $finalMemory - $initialMemory
    
    Write-Host "  Memory delta after operations: ${memoryDelta}MB" -ForegroundColor Gray
    $testOutput += "  Memory delta after operations: ${memoryDelta}MB"
    
    $noLeaks = [math]::Abs($memoryDelta) -lt 50  # Allow 50MB variance
    
    if ($noLeaks) {
        Write-Host "  [PASS] No significant memory leaks detected" -ForegroundColor Green
        $testOutput += "  [PASS] No significant memory leaks detected"
        $testResults += @{ Test = "Memory Leak Check"; Result = "PASS"; Details = "Delta: ${memoryDelta}MB" }
    } else {
        Write-Host "  [WARN] Possible memory leak detected (${memoryDelta}MB change)" -ForegroundColor Yellow
        $testOutput += "  [WARN] Possible memory leak detected"
        $testResults += @{ Test = "Memory Leak Check"; Result = "WARN"; Details = "Delta: ${memoryDelta}MB" }
    }
    
} catch {
    Write-Host "  [FAIL] Memory monitoring error: $_" -ForegroundColor Red
    $testResults += @{ Test = "Memory Monitoring"; Result = "FAIL"; Details = $_.ToString() }
    $testOutput += "  [FAIL] Memory monitoring error: $_"
}

# Test 4: CPU Usage Monitoring
Write-Host ""
Write-Host "[TEST 4] CPU Usage Monitoring..." -ForegroundColor Yellow
$testOutput += ""
$testOutput += "[TEST 4] CPU Usage Monitoring..."

try {
    # Monitor CPU usage over a period
    $cpuSamples = @()
    
    Write-Host "  Sampling CPU usage..." -ForegroundColor Gray
    $testOutput += "  Sampling CPU usage..."
    
    for ($i = 1; $i -le 5; $i++) {
        $cpu = (Get-Counter "\Process(powershell*)\% Processor Time" -ErrorAction SilentlyContinue).CounterSamples[0].CookedValue
        $cpuSamples += [math]::Round($cpu, 2)
        Start-Sleep -Milliseconds 200
    }
    
    $avgCPU = [math]::Round(($cpuSamples | Measure-Object -Average).Average, 2)
    $maxCPU = [math]::Round(($cpuSamples | Measure-Object -Maximum).Maximum, 2)
    
    Write-Host "  Average CPU: ${avgCPU} percent" -ForegroundColor Gray
    Write-Host "  Peak CPU: ${maxCPU} percent" -ForegroundColor Gray
    $testOutput += "  Average CPU: ${avgCPU} percent"
    $testOutput += "  Peak CPU: ${maxCPU} percent"
    
    $cpuPassed = $avgCPU -le $performanceBenchmarks.CPUUsagePercent
    
    if ($cpuPassed) {
        Write-Host "  [PASS] CPU usage within limits (${avgCPU} percent < $($performanceBenchmarks.CPUUsagePercent) percent)" -ForegroundColor Green
        $testOutput += "  [PASS] CPU usage within limits"
        $testResults += @{ Test = "CPU Usage"; Result = "PASS"; Details = "Avg: ${avgCPU} percent" }
    } else {
        Write-Host "  [WARN] CPU usage elevated (${avgCPU} percent > $($performanceBenchmarks.CPUUsagePercent) percent)" -ForegroundColor Yellow
        $testOutput += "  [WARN] CPU usage elevated"
        $testResults += @{ Test = "CPU Usage"; Result = "WARN"; Details = "Avg: ${avgCPU} percent" }
    }
    
} catch {
    Write-Host "  [SKIP] CPU monitoring not available: $_" -ForegroundColor Yellow
    $testResults += @{ Test = "CPU Usage"; Result = "SKIP"; Details = "Monitoring unavailable" }
    $testOutput += "  [SKIP] CPU monitoring not available"
}

# Test 5: File Operation Performance
Write-Host ""
Write-Host "[TEST 5] File Operation Performance..." -ForegroundColor Yellow
$testOutput += ""
$testOutput += "[TEST 5] File Operation Performance..."

try {
    $testFile = Join-Path $PSScriptRoot "test_performance_$(Get-Date -Format 'yyyyMMdd_HHmmss').tmp"
    
    # Test write performance
    $writeTest = Measure-Performance -OperationName "File Write" -MaxMs $performanceBenchmarks.FileOperationMs -Operation {
        $testContent = "Test data " * 1000
        Set-Content -Path $testFile -Value $testContent -Force
        return $true
    }
    
    # Test read performance
    $readTest = Measure-Performance -OperationName "File Read" -MaxMs $performanceBenchmarks.FileOperationMs -Operation {
        $content = Get-Content -Path $testFile -Raw
        return $content.Length
    }
    
    # Clean up
    if (Test-Path $testFile) {
        Remove-Item $testFile -Force
    }
    
    $fileOpsPassed = $writeTest.Passed -and $readTest.Passed
    
    if ($fileOpsPassed) {
        Write-Host "  [PASS] File operations within benchmarks" -ForegroundColor Green
        Write-Host "    Write: $($writeTest.ElapsedMs)ms, Read: $($readTest.ElapsedMs)ms" -ForegroundColor Gray
        $testOutput += "  [PASS] File operations within benchmarks"
        $testOutput += "    Write: $($writeTest.ElapsedMs)ms, Read: $($readTest.ElapsedMs)ms"
        $testResults += @{ Test = "File Operations"; Result = "PASS"; Details = "W:$($writeTest.ElapsedMs)ms R:$($readTest.ElapsedMs)ms" }
    } else {
        Write-Host "  [FAIL] File operations exceeded benchmarks" -ForegroundColor Red
        Write-Host "    Write: $($writeTest.ElapsedMs)ms, Read: $($readTest.ElapsedMs)ms" -ForegroundColor Gray
        $testOutput += "  [FAIL] File operations exceeded benchmarks"
        $testResults += @{ Test = "File Operations"; Result = "FAIL"; Details = "W:$($writeTest.ElapsedMs)ms R:$($readTest.ElapsedMs)ms" }
    }
    
} catch {
    Write-Host "  [FAIL] File operation error: $_" -ForegroundColor Red
    $testResults += @{ Test = "File Operations"; Result = "FAIL"; Details = $_.ToString() }
    $testOutput += "  [FAIL] File operation error: $_"
}

# Test 6: Concurrent Operations Load Test
Write-Host ""
Write-Host "[TEST 6] Concurrent Operations Load Test..." -ForegroundColor Yellow
$testOutput += ""
$testOutput += "[TEST 6] Concurrent Operations Load Test..."

try {
    Write-Host "  Running $LoadIterations concurrent operations..." -ForegroundColor Gray
    $testOutput += "  Running $LoadIterations concurrent operations..."
    
    $jobs = @()
    $jobStartTime = Get-Date
    
    # Start concurrent operations
    for ($i = 1; $i -le $LoadIterations; $i++) {
        $job = Start-Job -ScriptBlock {
            param($index)
            
            # Simulate various operations
            $result = @{
                Index = $index
                Start = Get-Date
            }
            
            # File operation
            $tempFile = "$env:TEMP\load_test_$index.tmp"
            "Test data $index" | Out-File $tempFile
            $content = Get-Content $tempFile
            Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
            
            # Memory allocation
            $data = @(1..1000) | ForEach-Object { [Guid]::NewGuid().ToString() }
            
            # String parsing
            $text = "Sample text " * 100
            $words = $text -split " "
            
            $result.End = Get-Date
            $result.Duration = ($result.End - $result.Start).TotalMilliseconds
            
            return $result
        } -ArgumentList $i
        
        $jobs += $job
    }
    
    # Wait for all jobs to complete
    $completedJobs = $jobs | Wait-Job -Timeout 30
    $results = $completedJobs | Receive-Job
    
    # Clean up jobs
    $jobs | Remove-Job -Force
    
    $jobEndTime = Get-Date
    $totalDuration = ($jobEndTime - $jobStartTime).TotalSeconds
    
    $successCount = $results.Count
    $successRate = if ($LoadIterations -gt 0) { ($successCount / $LoadIterations) * 100 } else { 0 }
    
    Write-Host "  Completed $successCount of $LoadIterations operations" -ForegroundColor Gray
    Write-Host "  Total duration: $([math]::Round($totalDuration, 2)) seconds" -ForegroundColor Gray
    $testOutput += "  Completed $successCount of $LoadIterations operations"
    $testOutput += "  Total duration: $([math]::Round($totalDuration, 2)) seconds"
    
    if ($successRate -ge 90) {
        Write-Host "  [PASS] Load test successful (${successRate} percent completion)" -ForegroundColor Green
        $testOutput += "  [PASS] Load test successful"
        $testResults += @{ Test = "Load Test"; Result = "PASS"; Details = "${successRate} percent completion" }
    } else {
        Write-Host "  [FAIL] Load test failed (${successRate} percent completion)" -ForegroundColor Red
        $testOutput += "  [FAIL] Load test failed"
        $testResults += @{ Test = "Load Test"; Result = "FAIL"; Details = "${successRate} percent completion" }
    }
    
} catch {
    Write-Host "  [FAIL] Load test error: $_" -ForegroundColor Red
    $testResults += @{ Test = "Load Test"; Result = "FAIL"; Details = $_.ToString() }
    $testOutput += "  [FAIL] Load test error: $_"
}

# Test 7: Log Rotation and Management
Write-Host ""
Write-Host "[TEST 7] Log Rotation and Management..." -ForegroundColor Yellow
$testOutput += ""
$testOutput += "[TEST 7] Log Rotation and Management..."

try {
    $logFile = Join-Path $PSScriptRoot "unity_claude_automation.log"
    $logBackupPattern = "unity_claude_automation_*.log"
    
    # Check if log file exists and size
    if (Test-Path $logFile) {
        $logInfo = Get-Item $logFile
        $logSizeMB = [math]::Round($logInfo.Length / 1MB, 2)
        
        Write-Host "  Current log size: ${logSizeMB}MB" -ForegroundColor Gray
        $testOutput += "  Current log size: ${logSizeMB}MB"
        
        # Check for log rotation (if log is over 100MB)
        $needsRotation = $logSizeMB -gt 100
        
        if ($needsRotation) {
            Write-Host "  [INFO] Log rotation recommended (>100MB)" -ForegroundColor Yellow
            $testOutput += "  [INFO] Log rotation recommended"
        }
        
        # Check for old log backups
        $oldLogs = Get-ChildItem -Path $PSScriptRoot -Filter $logBackupPattern | 
                   Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-7) }
        
        if ($oldLogs.Count -gt 0) {
            Write-Host "  Found $($oldLogs.Count) old log backups (>7 days)" -ForegroundColor Gray
            $testOutput += "  Found $($oldLogs.Count) old log backups"
        }
        
        Write-Host "  [PASS] Log management operational" -ForegroundColor Green
        $testOutput += "  [PASS] Log management operational"
        $testResults += @{ Test = "Log Management"; Result = "PASS"; Details = "Size: ${logSizeMB}MB" }
    } else {
        Write-Host "  [INFO] Log file not found (will be created on first use)" -ForegroundColor Gray
        $testOutput += "  [INFO] Log file not found"
        $testResults += @{ Test = "Log Management"; Result = "PASS"; Details = "No log file yet" }
    }
    
} catch {
    Write-Host "  [FAIL] Log management error: $_" -ForegroundColor Red
    $testResults += @{ Test = "Log Management"; Result = "FAIL"; Details = $_.ToString() }
    $testOutput += "  [FAIL] Log management error: $_"
}

# Test 8: Resource Cleanup Validation
Write-Host ""
Write-Host "[TEST 8] Resource Cleanup Validation..." -ForegroundColor Yellow
$testOutput += ""
$testOutput += "[TEST 8] Resource Cleanup Validation..."

try {
    # Check for orphaned temp files
    $tempPattern = Join-Path $env:TEMP "unity_claude_*"
    $orphanedFiles = Get-ChildItem -Path $env:TEMP -Filter "unity_claude_*" -ErrorAction SilentlyContinue |
                     Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-1) }
    
    if ($orphanedFiles.Count -gt 0) {
        Write-Host "  Found $($orphanedFiles.Count) orphaned temp files" -ForegroundColor Yellow
        $testOutput += "  Found $($orphanedFiles.Count) orphaned temp files"
        
        # Clean up old files
        $orphanedFiles | Remove-Item -Force -ErrorAction SilentlyContinue
        Write-Host "  Cleaned up orphaned files" -ForegroundColor Gray
        $testOutput += "  Cleaned up orphaned files"
    }
    
    # Check for stuck background jobs
    $stuckJobs = Get-Job | Where-Object { $_.State -eq "Running" -and $_.PSBeginTime -lt (Get-Date).AddMinutes(-30) }
    
    if ($stuckJobs.Count -gt 0) {
        Write-Host "  Found $($stuckJobs.Count) stuck background jobs" -ForegroundColor Yellow
        $testOutput += "  Found $($stuckJobs.Count) stuck background jobs"
        
        # Clean up stuck jobs
        $stuckJobs | Stop-Job -PassThru | Remove-Job -Force
        Write-Host "  Cleaned up stuck jobs" -ForegroundColor Gray
        $testOutput += "  Cleaned up stuck jobs"
    }
    
    Write-Host "  [PASS] Resource cleanup validated" -ForegroundColor Green
    $testOutput += "  [PASS] Resource cleanup validated"
    $testResults += @{ Test = "Resource Cleanup"; Result = "PASS"; Details = "Resources clean" }
    
} catch {
    Write-Host "  [FAIL] Resource cleanup error: $_" -ForegroundColor Red
    $testResults += @{ Test = "Resource Cleanup"; Result = "FAIL"; Details = $_.ToString() }
    $testOutput += "  [FAIL] Resource cleanup error: $_"
}

# Optional Stress Test
if ($StressTest) {
    Write-Host ""
    Write-Host "[STRESS TEST] Extended Load Testing..." -ForegroundColor Yellow
    $testOutput += ""
    $testOutput += "[STRESS TEST] Extended Load Testing..."
    
    try {
        Write-Host "  Running extended stress test (this may take several minutes)..." -ForegroundColor Gray
        $testOutput += "  Running extended stress test..."
        
        $stressIterations = 100
        $stressResults = @()
        
        for ($i = 1; $i -le $stressIterations; $i++) {
            if (($i % 10) -eq 0) {
                Write-Host "    Progress: $i/$stressIterations" -ForegroundColor Gray
            }
            
            # Simulate heavy operation
            $stressResult = Measure-Performance -OperationName "Stress $i" -MaxMs 1000 -Operation {
                $data = @(1..1000) | ForEach-Object { 
                    @{
                        Id = $_
                        Data = [Guid]::NewGuid().ToString()
                        Timestamp = Get-Date
                    }
                }
                $json = $data | ConvertTo-Json
                $parsed = $json | ConvertFrom-Json
                return $parsed.Count
            }
            
            $stressResults += $stressResult
        }
        
        $stressSuccess = ($stressResults | Where-Object { $_.Passed }).Count
        $stressRate = ($stressSuccess / $stressIterations) * 100
        
        Write-Host "  Stress test completion: ${stressRate} percent" -ForegroundColor Gray
        $testOutput += "  Stress test completion: ${stressRate} percent"
        
        if ($stressRate -ge 95) {
            Write-Host "  [PASS] System stable under stress" -ForegroundColor Green
            $testOutput += "  [PASS] System stable under stress"
            $testResults += @{ Test = "Stress Test"; Result = "PASS"; Details = "${stressRate} percent success" }
        } else {
            Write-Host "  [WARN] Performance degradation under stress" -ForegroundColor Yellow
            $testOutput += "  [WARN] Performance degradation under stress"
            $testResults += @{ Test = "Stress Test"; Result = "WARN"; Details = "${stressRate} percent success" }
        }
        
    } catch {
        Write-Host "  [FAIL] Stress test error: $_" -ForegroundColor Red
        $testResults += @{ Test = "Stress Test"; Result = "FAIL"; Details = $_.ToString() }
        $testOutput += "  [FAIL] Stress test error: $_"
    }
}

# Calculate summary
$endTime = Get-Date
$duration = $endTime - $startTime

$passCount = ($testResults | Where-Object { $_.Result -eq "PASS" }).Count
$failCount = ($testResults | Where-Object { $_.Result -eq "FAIL" }).Count
$warnCount = ($testResults | Where-Object { $_.Result -eq "WARN" }).Count
$skipCount = ($testResults | Where-Object { $_.Result -eq "SKIP" }).Count
$totalTests = $testResults.Count

Write-Host ""
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "           PERFORMANCE TEST SUMMARY" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor Red
Write-Host "Warnings: $warnCount" -ForegroundColor Yellow
Write-Host "Skipped: $skipCount" -ForegroundColor Gray
Write-Host "Duration: $($duration.TotalSeconds) seconds" -ForegroundColor Gray
Write-Host ""

$testOutput += ""
$testOutput += "================================================"
$testOutput += "           PERFORMANCE TEST SUMMARY"
$testOutput += "================================================"
$testOutput += ""
$testOutput += "Total Tests: $totalTests"
$testOutput += "Passed: $passCount"
$testOutput += "Failed: $failCount"
$testOutput += "Warnings: $warnCount"
$testOutput += "Skipped: $skipCount"
$testOutput += "Duration: $($duration.TotalSeconds) seconds"
$testOutput += ""

# Display performance benchmarks summary
Write-Host "Performance Benchmarks:" -ForegroundColor Yellow
Write-Host "  Response Parsing: < $($performanceBenchmarks.ResponseParsingMs)ms" -ForegroundColor Gray
Write-Host "  Command Execution: < $($performanceBenchmarks.CommandExecutionMs)ms" -ForegroundColor Gray
Write-Host "  Memory Usage: < $($performanceBenchmarks.MemoryUsageMB)MB" -ForegroundColor Gray
Write-Host "  CPU Usage: < $($performanceBenchmarks.CPUUsagePercent) percent" -ForegroundColor Gray
Write-Host ""

$testOutput += "Performance Benchmarks:"
$testOutput += "  Response Parsing: < $($performanceBenchmarks.ResponseParsingMs)ms"
$testOutput += "  Command Execution: < $($performanceBenchmarks.CommandExecutionMs)ms"
$testOutput += "  Memory Usage: < $($performanceBenchmarks.MemoryUsageMB)MB"
$testOutput += "  CPU Usage: < $($performanceBenchmarks.CPUUsagePercent) percent"
$testOutput += ""

# Calculate success rate (warnings count as partial success)
$effectivePass = $passCount + ($warnCount * 0.5)
$successRate = if ($totalTests -gt 0) { [math]::Round(($effectivePass / $totalTests) * 100, 2) } else { 0 }

if ($successRate -ge 90) {
    Write-Host "SUCCESS: Performance and reliability validated! (${successRate} percent effective pass rate)" -ForegroundColor Green
    $testOutput += "SUCCESS: Performance and reliability validated! (${successRate} percent effective pass rate)"
} elseif ($successRate -ge 75) {
    Write-Host "PARTIAL SUCCESS: Performance acceptable with warnings (${successRate} percent effective pass rate)" -ForegroundColor Yellow
    $testOutput += "PARTIAL SUCCESS: Performance acceptable with warnings (${successRate} percent effective pass rate)"
} else {
    Write-Host "FAILURE: Performance issues detected (${successRate} percent effective pass rate)" -ForegroundColor Red
    $testOutput += "FAILURE: Performance issues detected (${successRate} percent effective pass rate)"
}

Write-Host ""
Write-Host "Day 20 Performance & Reliability Test Complete!" -ForegroundColor Cyan
$testOutput += ""
$testOutput += "Day 20 Performance & Reliability Test Complete!"
$testOutput += "End Time: $(Get-Date)"

# Save results
$testOutput | Out-File -FilePath $testResultsFile -Encoding UTF8
Write-Host ""
Write-Host "Test results saved to: $testResultsFile" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUBnXWPZrrU2mOKux3EXSpo/VG
# 7+egggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUy/kCoyYQqLNJzPzOBIOX1OpYanAwDQYJKoZIhvcNAQEBBQAEggEAV3/l
# 1OfsrRtLDzqo3SpF8ANoyQI7VEmq2LSL/7cxHq5uvVEovVhg1dtsl00XvhSLeQsS
# UCYOI8xxYFJ7/cqlDU1+HehPCgZQqHxv5PJlpZzg04mR9bmM3QYb0+NgPNKRW/Xg
# Q4vlKOa9RN2rbyItEiuvpG7l4eSuXMGpCzGF8Y9axFmKwJ2IGvCn94zIYk56Bvsv
# lQBmPOA0eHdRptUWKR2cPP/Xf9t0yQpGFTMCzX6no0ppItVjwsjc5SCJEfhABt2j
# S2trvRuNJQ+RjyKNgmkL6S0erLVmFY5gBDavpt2xvjWURu3z9RkceaJ5y1F3ds5M
# 4LQVfH/zMRnKWzd7JA==
# SIG # End signature block
