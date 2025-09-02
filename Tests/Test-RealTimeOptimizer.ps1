# Test-RealTimeOptimizer.ps1
# Test script for Unity-Claude Real-Time System Optimizer
# Validates adaptive throttling, resource monitoring, and performance optimization

param(
    [switch]$Verbose,
    [switch]$LongRunning
)

# Set verbose preference
if ($Verbose) {
    $VerbosePreference = "Continue"
}

# Import the module
$realTimeOptimizerPath = Join-Path $PSScriptRoot "..\Modules\Unity-Claude-RealTimeOptimizer"
Import-Module $realTimeOptimizerPath -Force

Write-Host "`n===== Unity-Claude Real-Time System Optimizer Test =====" -ForegroundColor Cyan
Write-Host "Testing adaptive throttling, resource monitoring, and optimization" -ForegroundColor Cyan
Write-Host "============================================================`n" -ForegroundColor Cyan

# Test results collection
$testResults = @{
    TotalTests = 0
    Passed = 0
    Failed = 0
    Details = @()
}

function Test-Functionality {
    param(
        [string]$TestName,
        [scriptblock]$TestScript
    )
    
    $testResults.TotalTests++
    Write-Host "Testing: $TestName" -NoNewline
    
    try {
        $result = & $TestScript
        if ($result) {
            Write-Host " [PASSED]" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Details += @{
                Test = $TestName
                Result = "Passed"
                Details = $result
            }
        }
        else {
            Write-Host " [FAILED]" -ForegroundColor Red
            $testResults.Failed++
            $testResults.Details += @{
                Test = $TestName
                Result = "Failed"
                Details = "Test returned false"
            }
        }
    }
    catch {
        Write-Host " [ERROR]" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        $testResults.Failed++
        $testResults.Details += @{
            Test = $TestName
            Result = "Error"
            Details = $_.Exception.Message
        }
    }
}

# Test 1: Optimizer Initialization
Test-Functionality "Real-Time Optimizer Initialization" {
    $result = Initialize-RealTimeOptimizer -Mode Balanced
    
    if ($result) {
        $stats = Get-RTPerformanceStatistics
        return ($null -ne $stats)
    }
    return $false
}

# Test 2: RealTime Mode Configuration
Test-Functionality "RealTime Mode Configuration" {
    $result = Initialize-RealTimeOptimizer -Mode RealTime
    
    if ($result) {
        $stats = Get-RTPerformanceStatistics
        # RealTime mode should be initialized but not monitoring yet
        return ($stats.IsMonitoring -eq $false)
    }
    return $false
}

# Test 3: Efficiency Mode Configuration
Test-Functionality "Efficiency Mode Configuration" {
    $result = Initialize-RealTimeOptimizer -Mode Efficiency
    
    if ($result) {
        $stats = Get-RTPerformanceStatistics
        return ($null -ne $stats)
    }
    return $false
}

# Test 4: Adaptive Mode Configuration
Test-Functionality "Adaptive Mode Configuration" {
    $result = Initialize-RealTimeOptimizer -Mode Adaptive
    
    if ($result) {
        $stats = Get-RTPerformanceStatistics
        return ($null -ne $stats)
    }
    return $false
}

# Test 5: Custom Configuration
Test-Functionality "Custom Configuration Support" {
    $customConfig = @{
        CPUThresholdHigh = 85
        MemoryThresholdHigh = 90
        BaseProcessingInterval = 200
    }
    
    $result = Initialize-RealTimeOptimizer -Configuration $customConfig
    
    if ($result) {
        $stats = Get-RTPerformanceStatistics
        return ($null -ne $stats)
    }
    return $false
}

# Test 6: Start Optimization
Test-Functionality "Start Real-Time Optimization" {
    $startResult = Start-RealTimeOptimization
    
    if ($startResult) {
        # Wait a moment for threads to start
        Start-Sleep -Seconds 1
        
        $stats = Get-RTPerformanceStatistics
        return ($stats.IsMonitoring -eq $true)
    }
    return $false
}

# Test 7: Resource Statistics Tracking
Test-Functionality "Resource Statistics Tracking" {
    # Wait for at least one monitoring cycle
    Start-Sleep -Seconds 2
    
    $stats = Get-RTPerformanceStatistics
    
    # Should have some resource readings
    return ($stats.CurrentCPUUsage -ge 0 -and $stats.CurrentMemoryUsage -ge 0)
}

# Test 8: Optimal Batch Size Calculation
Test-Functionality "Optimal Batch Size Calculation" {
    # Test with different queue lengths and load levels
    $lowQueue = Get-RTOptimalBatchSize -QueueLength 5
    $highQueue = Get-RTOptimalBatchSize -QueueLength 50
    
    # High queue should result in larger batch size
    return ($highQueue -gt $lowQueue)
}

# Test 9: Throttled Delay Calculation
Test-Functionality "Throttled Delay Calculation" {
    $delay = Get-RTThrottledDelay
    
    # Should return a reasonable delay value
    return ($delay -gt 0 -and $delay -lt 10000)  # Between 0 and 10 seconds
}

# Test 10: Performance Statistics Structure
Test-Functionality "Performance Statistics Structure" {
    $stats = Get-RTPerformanceStatistics
    
    # Verify required properties exist
    $requiredProps = @('CurrentCPUUsage', 'CurrentMemoryUsage', 'CurrentThrottleMultiplier', 
                       'GCCollections', 'ThrottleAdjustments', 'IsMonitoring', 'SystemLoadLevel')
    
    $hasAllProps = $true
    foreach ($prop in $requiredProps) {
        if (-not ($stats.PSObject.Properties.Name -contains $prop)) {
            $hasAllProps = $false
            break
        }
    }
    
    return $hasAllProps
}

# Test 11: Memory Management (if long running test enabled)
if ($LongRunning) {
    Test-Functionality "Memory Management Long-Running" {
        Write-Host "`n  Running 30-second memory management test..." -ForegroundColor Yellow
        
        $startStats = Get-RTPerformanceStatistics
        $startGC = $startStats.GCCollections
        
        # Wait for memory management cycles
        Start-Sleep -Seconds 30
        
        $endStats = Get-RTPerformanceStatistics
        $endGC = $endStats.GCCollections
        
        # Should have performed at least one GC cycle
        return ($endGC -gt $startGC)
    }
}

# Test 12: System Load Level Detection
Test-Functionality "System Load Level Detection" {
    $stats = Get-RTPerformanceStatistics
    
    # Should detect and report system load level
    $validLoadLevels = @('Low', 'Normal', 'High', 'Critical', 'Emergency')
    return ($stats.SystemLoadLevel -in $validLoadLevels)
}

# Test 13: Runtime Metrics
Test-Functionality "Runtime Metrics Calculation" {
    $stats = Get-RTPerformanceStatistics
    
    # Should have runtime and other calculated metrics
    return ($null -ne $stats.Runtime -and $stats.Runtime.TotalSeconds -gt 0)
}

# Test 14: Stop Optimizer
Test-Functionality "Stop Real-Time Optimizer" {
    $stopResult = Stop-RealTimeOptimizer
    
    if ($null -ne $stopResult) {
        $stats = Get-RTPerformanceStatistics
        return ($stats.IsMonitoring -eq $false)
    }
    return $false
}

# Display test summary
Write-Host "`n===== Test Summary =====" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.TotalTests)" -ForegroundColor White
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor $(if ($testResults.Failed -eq 0) { "Green" } else { "Red" })

# Calculate success rate
if ($testResults.TotalTests -gt 0) {
    $successRate = [math]::Round(($testResults.Passed / $testResults.TotalTests) * 100, 2)
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 95) { "Green" } elseif ($successRate -ge 80) { "Yellow" } else { "Red" })
}

# Get final statistics
try {
    $finalStats = Get-RTPerformanceStatistics
    Write-Host "`n===== Real-Time Optimizer Statistics =====" -ForegroundColor Cyan
    Write-Host "Current CPU Usage: $($finalStats.CurrentCPUUsage)%" -ForegroundColor White
    Write-Host "Current Memory Usage: $($finalStats.CurrentMemoryUsage)%" -ForegroundColor White
    Write-Host "Current Throttle Multiplier: $($finalStats.CurrentThrottleMultiplier)x" -ForegroundColor White
    Write-Host "Current Batch Size: $($finalStats.CurrentBatchSize)" -ForegroundColor White
    Write-Host "GC Collections: $($finalStats.GCCollections)" -ForegroundColor White
    Write-Host "Throttle Adjustments: $($finalStats.ThrottleAdjustments)" -ForegroundColor White
    Write-Host "System Load Level: $($finalStats.SystemLoadLevel)" -ForegroundColor White
    Write-Host "Runtime: $($finalStats.Runtime)" -ForegroundColor White
}
catch {
    Write-Host "Could not retrieve final statistics: $_" -ForegroundColor Yellow
}

# Export results
$resultsFile = Join-Path $PSScriptRoot "RealTimeOptimizer-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
Write-Host "`nTest results saved to: $resultsFile" -ForegroundColor Gray

# Return success/failure for CI/CD integration
exit $(if ($testResults.Failed -eq 0) { 0 } else { 1 })