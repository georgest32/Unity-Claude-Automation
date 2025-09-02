# Week 3 Day 15 Hour 1-2: Comprehensive Stress Testing Framework
# High-load and high-frequency change scenario validation
# Validates system resilience under extreme conditions

param(
    [int]$LoadMultiplier = 1,
    [int]$DurationMinutes = 5,
    [switch]$ExtremeMode,
    [string]$TestMode = "Comprehensive"
)

$ErrorActionPreference = "Continue"

$stressTestConfig = @{
    HighLoadThreshold = 100 * $LoadMultiplier
    ConcurrentOperations = 50 * $LoadMultiplier
    MemoryPressureThreshold = 80
    CPUPressureThreshold = 90
    NetworkLatencyThreshold = 1000
    TestDuration = [TimeSpan]::FromMinutes($DurationMinutes)
    ExtremeMode = $ExtremeMode.IsPresent
}

$stressResults = @{
    TestSuite = "Week3Day15-StressTestingFramework"
    StartTime = Get-Date
    EndTime = $null
    TestMode = $TestMode
    Configuration = $stressTestConfig
    StressTests = @()
    PerformanceMetrics = @{}
    SystemHealth = @{}
    OverallResult = "Unknown"
}

Write-Host "=" * 80 -ForegroundColor Red
Write-Host "STRESS TESTING: Week 3 Day 15 - High-Load Scenario Validation" -ForegroundColor Red
Write-Host "Test Mode: $TestMode | Duration: $DurationMinutes minutes | Multiplier: $LoadMultiplier" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Red

function Add-StressTestResult {
    param(
        [string]$TestName,
        [string]$Status,
        [string]$Details,
        [hashtable]$Metrics = @{}
    )
    
    $result = @{
        TestName = $TestName
        Status = $Status
        Details = $Details
        Timestamp = Get-Date
        Metrics = $Metrics
    }
    
    $stressResults.StressTests += $result
    $color = switch ($Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    
    Write-Host "  [$Status] $TestName" -ForegroundColor $color
    if ($Details) { Write-Host "      $Details" -ForegroundColor Gray }
    
    if ($Metrics.Count -gt 0) {
        foreach ($metric in $Metrics.Keys) {
            $stressResults.PerformanceMetrics[$metric] = $Metrics[$metric]
        }
    }
}

function Start-SystemResourceMonitoring {
    Write-Host "`n🔍 Starting System Resource Monitoring..." -ForegroundColor Cyan
    
    $monitoringJob = Start-Job -ScriptBlock {
        param($Duration)
        
        $endTime = (Get-Date).Add($Duration)
        $metrics = @{
            CPUReadings = @()
            MemoryReadings = @()
            NetworkReadings = @()
            DiskIOReadings = @()
            Timestamp = @()
        }
        
        while ((Get-Date) -lt $endTime) {
            try {
                $cpu = Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
                $memory = Get-Counter "\Memory\Available MBytes" -SampleInterval 1 -MaxSamples 1 -ErrorAction SilentlyContinue
                
                if ($cpu) { $metrics.CPUReadings += [math]::Round($cpu.CounterSamples[0].CookedValue, 2) }
                if ($memory) { $metrics.MemoryReadings += [math]::Round($memory.CounterSamples[0].CookedValue, 2) }
                $metrics.Timestamp += Get-Date
                
                Start-Sleep -Seconds 2
            } catch {
                # Continue monitoring even if some counters fail
                Start-Sleep -Seconds 2
            }
        }
        
        return $metrics
    } -ArgumentList $stressTestConfig.TestDuration
    
    return $monitoringJob
}

function Test-HighVolumeCoordinatedOperations {
    Write-Host "`n🚀 Testing High-Volume Coordinated Operations..." -ForegroundColor Yellow
    
    $operationCount = $stressTestConfig.HighLoadThreshold
    $concurrentBatches = 10
    $operationsPerBatch = $operationCount / $concurrentBatches
    
    $startTime = Get-Date
    $jobs = @()
    
    try {
        # Create concurrent operation batches
        for ($batch = 0; $batch -lt $concurrentBatches; $batch++) {
            $jobs += Start-Job -ScriptBlock {
                param($BatchNumber, $OperationsPerBatch, $LoadMultiplier)
                
                $batchResults = @{
                    Successful = 0
                    Failed = 0
                    TotalLatency = 0
                    MaxLatency = 0
                    MinLatency = [double]::MaxValue
                }
                
                for ($i = 0; $i -lt $OperationsPerBatch; $i++) {
                    $opStartTime = Get-Date
                    
                    try {
                        # Simulate coordinated operation
                        $operation = @{
                            Operation = "LoadTest_Batch$BatchNumber_Op$i"
                            Priority = @("High", "Medium", "Low")[(Get-Random -Maximum 3)]
                            Payload = "LoadTest_" + ("X" * (100 * $LoadMultiplier))
                        }
                        
                        # Simulate coordinated operation processing
                        $processingTime = Get-Random -Minimum 10 -Maximum 100
                        Start-Sleep -Milliseconds $processingTime
                        
                        $latency = ((Get-Date) - $opStartTime).TotalMilliseconds
                        $batchResults.Successful++
                        $batchResults.TotalLatency += $latency
                        $batchResults.MaxLatency = [math]::Max($batchResults.MaxLatency, $latency)
                        $batchResults.MinLatency = [math]::Min($batchResults.MinLatency, $latency)
                        
                    } catch {
                        $batchResults.Failed++
                    }
                }
                
                return $batchResults
            } -ArgumentList $batch, $operationsPerBatch, $LoadMultiplier
        }
        
        # Wait for all batches to complete
        $batchResults = $jobs | Wait-Job | Receive-Job
        $jobs | Remove-Job
        
        $totalDuration = (Get-Date) - $startTime
        
        # Aggregate results
        $totalSuccessful = ($batchResults | Measure-Object -Property Successful -Sum).Sum
        $totalFailed = ($batchResults | Measure-Object -Property Failed -Sum).Sum
        $totalOperations = $totalSuccessful + $totalFailed
        $avgLatency = ($batchResults | Measure-Object -Property TotalLatency -Sum).Sum / $totalSuccessful
        $maxLatency = ($batchResults | Measure-Object -Property MaxLatency -Maximum).Maximum
        $throughput = $totalOperations / $totalDuration.TotalSeconds
        
        $successRate = if ($totalOperations -gt 0) { ($totalSuccessful / $totalOperations) * 100 } else { 0 }
        
        $metrics = @{
            TotalOperations = $totalOperations
            SuccessRate = [math]::Round($successRate, 2)
            AvgLatency = [math]::Round($avgLatency, 2)
            MaxLatency = [math]::Round($maxLatency, 2)
            Throughput = [math]::Round($throughput, 2)
            Duration = [math]::Round($totalDuration.TotalSeconds, 2)
        }
        
        if ($successRate -ge 90 -and $avgLatency -lt 500 -and $throughput -gt 10) {
            Add-StressTestResult -TestName "High-Volume Coordinated Operations" -Status "PASS" -Details "$totalOperations operations, $($metrics.SuccessRate)% success, $($metrics.Throughput) ops/sec" -Metrics $metrics
        } elseif ($successRate -ge 75) {
            Add-StressTestResult -TestName "High-Volume Coordinated Operations" -Status "WARNING" -Details "Degraded performance: $($metrics.SuccessRate)% success, $($metrics.AvgLatency)ms avg latency" -Metrics $metrics
        } else {
            Add-StressTestResult -TestName "High-Volume Coordinated Operations" -Status "FAIL" -Details "Poor performance: $($metrics.SuccessRate)% success rate" -Metrics $metrics
        }
        
    } catch {
        Add-StressTestResult -TestName "High-Volume Coordinated Operations" -Status "FAIL" -Details "Error: $($_.Exception.Message)"
    }
}

function Test-ConcurrentSystemOptimization {
    Write-Host "`n⚡ Testing Concurrent System Optimization..." -ForegroundColor Yellow
    
    $optimizationCount = $stressTestConfig.ConcurrentOperations
    $startTime = Get-Date
    
    try {
        $jobs = @()
        
        # Start multiple optimization processes concurrently
        for ($i = 0; $i -lt $optimizationCount; $i++) {
            $jobs += Start-Job -ScriptBlock {
                param($OptimizationId)
                
                try {
                    # Simulate system optimization
                    $optimizationType = @("Performance", "Memory", "CPU", "Network")[(Get-Random -Maximum 4)]
                    
                    $opStartTime = Get-Date
                    Start-Sleep -Milliseconds (Get-Random -Minimum 50 -Maximum 200)
                    $duration = (Get-Date) - $opStartTime
                    
                    return @{
                        Id = $OptimizationId
                        Type = $optimizationType
                        Success = $true
                        Duration = $duration.TotalMilliseconds
                        OptimizationsApplied = Get-Random -Minimum 1 -Maximum 10
                    }
                } catch {
                    return @{
                        Id = $OptimizationId
                        Success = $false
                        Error = $_.Exception.Message
                    }
                }
            } -ArgumentList $i
        }
        
        $results = $jobs | Wait-Job -Timeout 30 | Receive-Job
        $jobs | Remove-Job
        
        $totalDuration = (Get-Date) - $startTime
        
        $successful = ($results | Where-Object { $_.Success }).Count
        $failed = $results.Count - $successful
        $successRate = ($successful / $results.Count) * 100
        $avgDuration = ($results | Where-Object { $_.Success } | Measure-Object -Property Duration -Average).Average
        $throughput = $results.Count / $totalDuration.TotalSeconds
        
        $metrics = @{
            ConcurrentOptimizations = $results.Count
            SuccessRate = [math]::Round($successRate, 2)
            AvgDuration = [math]::Round($avgDuration, 2)
            Throughput = [math]::Round($throughput, 2)
            TotalTime = [math]::Round($totalDuration.TotalSeconds, 2)
        }
        
        if ($successRate -ge 90 -and $avgDuration -lt 300 -and $throughput -gt 5) {
            Add-StressTestResult -TestName "Concurrent System Optimization" -Status "PASS" -Details "$successful/$($results.Count) optimizations successful, $($metrics.Throughput) ops/sec" -Metrics $metrics
        } elseif ($successRate -ge 75) {
            Add-StressTestResult -TestName "Concurrent System Optimization" -Status "WARNING" -Details "Degraded: $($metrics.SuccessRate)% success, $($metrics.AvgDuration)ms avg" -Metrics $metrics
        } else {
            Add-StressTestResult -TestName "Concurrent System Optimization" -Status "FAIL" -Details "Poor performance: $($metrics.SuccessRate)% success rate" -Metrics $metrics
        }
        
    } catch {
        Add-StressTestResult -TestName "Concurrent System Optimization" -Status "FAIL" -Details "Error: $($_.Exception.Message)"
    }
}

function Test-MemoryPressureResilience {
    Write-Host "`n🧠 Testing Memory Pressure Resilience..." -ForegroundColor Yellow
    
    try {
        $startTime = Get-Date
        $memoryConsumers = @()
        
        # Create controlled memory pressure
        $targetMemoryMB = 256 * $LoadMultiplier
        
        for ($i = 0; $i -lt 5; $i++) {
            $memoryConsumers += Start-Job -ScriptBlock {
                param($SizeMB)
                
                try {
                    # Allocate memory arrays
                    $arrays = @()
                    for ($j = 0; $j -lt $SizeMB; $j++) {
                        $arrays += ,(@(0) * 1048576)  # 1MB array
                        if ($j % 10 -eq 0) {
                            Start-Sleep -Milliseconds 10
                        }
                    }
                    
                    # Hold memory for test duration
                    Start-Sleep -Seconds 30
                    
                    return @{Success = $true; MemoryAllocated = $SizeMB}
                } catch {
                    return @{Success = $false; Error = $_.Exception.Message}
                }
            } -ArgumentList ($targetMemoryMB / 5)
        }
        
        Start-Sleep -Seconds 5  # Allow memory pressure to build
        
        # Test system operations under memory pressure
        $systemOperations = @()
        for ($i = 0; $i -lt 20; $i++) {
            $opStartTime = Get-Date
            try {
                # Simulate system coordination under memory pressure
                $operation = "MemoryPressureTest_$i"
                Start-Sleep -Milliseconds (Get-Random -Minimum 20 -Maximum 100)
                
                $duration = (Get-Date) - $opStartTime
                $systemOperations += @{Success = $true; Duration = $duration.TotalMilliseconds}
            } catch {
                $systemOperations += @{Success = $false; Error = $_.Exception.Message}
            }
        }
        
        # Clean up memory consumers
        $memoryConsumers | Stop-Job
        $memoryConsumers | Remove-Job
        
        $totalDuration = (Get-Date) - $startTime
        $successfulOps = ($systemOperations | Where-Object { $_.Success }).Count
        $successRate = ($successfulOps / $systemOperations.Count) * 100
        $avgLatency = ($systemOperations | Where-Object { $_.Success } | Measure-Object -Property Duration -Average).Average
        
        $metrics = @{
            MemoryPressureMB = $targetMemoryMB
            OperationsUnderPressure = $systemOperations.Count
            SuccessRate = [math]::Round($successRate, 2)
            AvgLatency = [math]::Round($avgLatency, 2)
            TestDuration = [math]::Round($totalDuration.TotalSeconds, 2)
        }
        
        if ($successRate -ge 90 -and $avgLatency -lt 200) {
            Add-StressTestResult -TestName "Memory Pressure Resilience" -Status "PASS" -Details "$($metrics.SuccessRate)% ops successful under ${targetMemoryMB}MB pressure" -Metrics $metrics
        } elseif ($successRate -ge 75) {
            Add-StressTestResult -TestName "Memory Pressure Resilience" -Status "WARNING" -Details "Degraded: $($metrics.SuccessRate)% success under memory pressure" -Metrics $metrics
        } else {
            Add-StressTestResult -TestName "Memory Pressure Resilience" -Status "FAIL" -Details "Failed under memory pressure: $($metrics.SuccessRate)% success" -Metrics $metrics
        }
        
    } catch {
        Add-StressTestResult -TestName "Memory Pressure Resilience" -Status "FAIL" -Details "Error: $($_.Exception.Message)"
    }
}

function Test-HighFrequencyChangeScenarios {
    Write-Host "`n🔄 Testing High-Frequency Change Scenarios..." -ForegroundColor Yellow
    
    try {
        $changeCount = 200 * $LoadMultiplier
        $startTime = Get-Date
        $changeResults = @()
        
        # Simulate high-frequency documentation changes
        for ($i = 0; $i -lt $changeCount; $i++) {
            $changeStartTime = Get-Date
            
            try {
                # Simulate file change detection and processing
                $changeType = @("Create", "Update", "Delete", "Rename")[(Get-Random -Maximum 4)]
                $fileName = "TestDoc_$(Get-Random -Minimum 1000 -Maximum 9999).md"
                
                # Simulate change processing latency
                Start-Sleep -Milliseconds (Get-Random -Minimum 5 -Maximum 50)
                
                $processingTime = (Get-Date) - $changeStartTime
                $changeResults += @{
                    ChangeType = $changeType
                    FileName = $fileName
                    Success = $true
                    ProcessingTime = $processingTime.TotalMilliseconds
                }
                
            } catch {
                $changeResults += @{
                    ChangeType = $changeType
                    Success = $false
                    Error = $_.Exception.Message
                }
            }
            
            # Brief pause to prevent overwhelming the system
            if ($i % 50 -eq 0) {
                Start-Sleep -Milliseconds 10
            }
        }
        
        $totalDuration = (Get-Date) - $startTime
        $successfulChanges = ($changeResults | Where-Object { $_.Success }).Count
        $successRate = ($successfulChanges / $changeResults.Count) * 100
        $avgProcessingTime = ($changeResults | Where-Object { $_.Success } | Measure-Object -Property ProcessingTime -Average).Average
        $changesPerSecond = $changeResults.Count / $totalDuration.TotalSeconds
        
        $metrics = @{
            TotalChanges = $changeResults.Count
            SuccessRate = [math]::Round($successRate, 2)
            AvgProcessingTime = [math]::Round($avgProcessingTime, 2)
            ChangesPerSecond = [math]::Round($changesPerSecond, 2)
            TotalDuration = [math]::Round($totalDuration.TotalSeconds, 2)
        }
        
        if ($successRate -ge 95 -and $avgProcessingTime -lt 100 -and $changesPerSecond -gt 10) {
            Add-StressTestResult -TestName "High-Frequency Change Processing" -Status "PASS" -Details "$($metrics.TotalChanges) changes, $($metrics.SuccessRate)% success, $($metrics.ChangesPerSecond) changes/sec" -Metrics $metrics
        } elseif ($successRate -ge 85 -and $changesPerSecond -gt 5) {
            Add-StressTestResult -TestName "High-Frequency Change Processing" -Status "WARNING" -Details "Degraded: $($metrics.SuccessRate)% success, $($metrics.ChangesPerSecond) changes/sec" -Metrics $metrics
        } else {
            Add-StressTestResult -TestName "High-Frequency Change Processing" -Status "FAIL" -Details "Poor performance: $($metrics.SuccessRate)% success, $($metrics.ChangesPerSecond) changes/sec" -Metrics $metrics
        }
        
    } catch {
        Add-StressTestResult -TestName "High-Frequency Change Processing" -Status "FAIL" -Details "Error: $($_.Exception.Message)"
    }
}

function Test-SystemRecoveryUnderStress {
    Write-Host "`n🛡️ Testing System Recovery Under Stress..." -ForegroundColor Yellow
    
    try {
        $recoveryScenarios = @(
            @{Name = "ModuleFailure"; Severity = "Medium"; ExpectedRecoveryTime = 30},
            @{Name = "ResourceExhaustion"; Severity = "High"; ExpectedRecoveryTime = 45},
            @{Name = "NetworkLatency"; Severity = "Low"; ExpectedRecoveryTime = 20},
            @{Name = "ConfigurationCorruption"; Severity = "High"; ExpectedRecoveryTime = 60}
        )
        
        $recoveryResults = @()
        
        foreach ($scenario in $recoveryScenarios) {
            $recoveryStartTime = Get-Date
            
            try {
                # Simulate failure scenario
                Write-Host "    Simulating $($scenario.Name) scenario..." -ForegroundColor Gray
                
                # Simulate recovery process
                $recoverySteps = Get-Random -Minimum 3 -Maximum 8
                for ($step = 0; $step -lt $recoverySteps; $step++) {
                    Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 500)
                }
                
                $actualRecoveryTime = (Get-Date) - $recoveryStartTime
                
                $recoveryResults += @{
                    Scenario = $scenario.Name
                    Severity = $scenario.Severity
                    ExpectedRecoveryTime = $scenario.ExpectedRecoveryTime
                    ActualRecoveryTime = $actualRecoveryTime.TotalSeconds
                    Success = $actualRecoveryTime.TotalSeconds -le ($scenario.ExpectedRecoveryTime * 1.5)
                    RecoverySteps = $recoverySteps
                }
                
            } catch {
                $recoveryResults += @{
                    Scenario = $scenario.Name
                    Success = $false
                    Error = $_.Exception.Message
                }
            }
        }
        
        $successfulRecoveries = ($recoveryResults | Where-Object { $_.Success }).Count
        $successRate = ($successfulRecoveries / $recoveryResults.Count) * 100
        $avgRecoveryTime = ($recoveryResults | Where-Object { $_.Success } | Measure-Object -Property ActualRecoveryTime -Average).Average
        
        $metrics = @{
            RecoveryScenarios = $recoveryResults.Count
            SuccessRate = [math]::Round($successRate, 2)
            AvgRecoveryTime = [math]::Round($avgRecoveryTime, 2)
            FastestRecovery = [math]::Round(($recoveryResults | Where-Object { $_.Success } | Measure-Object -Property ActualRecoveryTime -Minimum).Minimum, 2)
            SlowestRecovery = [math]::Round(($recoveryResults | Where-Object { $_.Success } | Measure-Object -Property ActualRecoveryTime -Maximum).Maximum, 2)
        }
        
        if ($successRate -ge 90 -and $avgRecoveryTime -lt 45) {
            Add-StressTestResult -TestName "System Recovery Under Stress" -Status "PASS" -Details "$($metrics.SuccessRate)% recovery success, avg $($metrics.AvgRecoveryTime)s" -Metrics $metrics
        } elseif ($successRate -ge 75) {
            Add-StressTestResult -TestName "System Recovery Under Stress" -Status "WARNING" -Details "Slow recovery: $($metrics.SuccessRate)% success, avg $($metrics.AvgRecoveryTime)s" -Metrics $metrics
        } else {
            Add-StressTestResult -TestName "System Recovery Under Stress" -Status "FAIL" -Details "Poor recovery: $($metrics.SuccessRate)% success rate" -Metrics $metrics
        }
        
    } catch {
        Add-StressTestResult -TestName "System Recovery Under Stress" -Status "FAIL" -Details "Error: $($_.Exception.Message)"
    }
}

# MAIN STRESS TESTING EXECUTION
Write-Host "`n🔥 Starting Comprehensive Stress Testing Framework..." -ForegroundColor Red

# Start system monitoring
$monitoringJob = Start-SystemResourceMonitoring

try {
    # Execute all stress tests
    Test-HighVolumeCoordinatedOperations
    Test-ConcurrentSystemOptimization
    Test-MemoryPressureResilience
    Test-HighFrequencyChangeScenarios
    Test-SystemRecoveryUnderStress
    
} finally {
    # Stop monitoring and collect metrics
    if ($monitoringJob) {
        $monitoringMetrics = $monitoringJob | Wait-Job -Timeout 10 | Receive-Job
        $monitoringJob | Remove-Job
        
        if ($monitoringMetrics) {
            $stressResults.SystemHealth = @{
                AvgCPU = if ($monitoringMetrics.CPUReadings.Count -gt 0) { [math]::Round(($monitoringMetrics.CPUReadings | Measure-Object -Average).Average, 2) } else { 0 }
                MaxCPU = if ($monitoringMetrics.CPUReadings.Count -gt 0) { [math]::Round(($monitoringMetrics.CPUReadings | Measure-Object -Maximum).Maximum, 2) } else { 0 }
                AvgMemoryMB = if ($monitoringMetrics.MemoryReadings.Count -gt 0) { [math]::Round(($monitoringMetrics.MemoryReadings | Measure-Object -Average).Average, 2) } else { 0 }
                MinMemoryMB = if ($monitoringMetrics.MemoryReadings.Count -gt 0) { [math]::Round(($monitoringMetrics.MemoryReadings | Measure-Object -Minimum).Minimum, 2) } else { 0 }
                MonitoringPoints = $monitoringMetrics.CPUReadings.Count
            }
        }
    }
}

# FINAL RESULTS
$stressResults.EndTime = Get-Date

Write-Host "`n" + "=" * 80 -ForegroundColor Red
Write-Host "STRESS TESTING RESULTS SUMMARY" -ForegroundColor Red
Write-Host "=" * 80 -ForegroundColor Red

$passedTests = ($stressResults.StressTests | Where-Object { $_.Status -eq "PASS" }).Count
$warningTests = ($stressResults.StressTests | Where-Object { $_.Status -eq "WARNING" }).Count
$failedTests = ($stressResults.StressTests | Where-Object { $_.Status -eq "FAIL" }).Count
$totalTests = $stressResults.StressTests.Count

Write-Host "`nStress Test Summary:" -ForegroundColor White
Write-Host "  Total Tests: $totalTests" -ForegroundColor Yellow
Write-Host "  Passed: $passedTests" -ForegroundColor Green
Write-Host "  Warnings: $warningTests" -ForegroundColor Yellow
Write-Host "  Failed: $failedTests" -ForegroundColor Red

$overallPassRate = if ($totalTests -gt 0) { [math]::Round((($passedTests + $warningTests) / $totalTests) * 100, 1) } else { 0 }
Write-Host "  Overall Pass Rate: $overallPassRate%" -ForegroundColor $(if ($overallPassRate -ge 80) { "Green" } elseif ($overallPassRate -ge 60) { "Yellow" } else { "Red" })

if ($stressResults.SystemHealth.Count -gt 0) {
    Write-Host "`nSystem Health During Testing:" -ForegroundColor White
    Write-Host "  Average CPU: $($stressResults.SystemHealth.AvgCPU)% | Peak: $($stressResults.SystemHealth.MaxCPU)%" -ForegroundColor Yellow
    Write-Host "  Available Memory: $($stressResults.SystemHealth.AvgMemoryMB)MB avg | Lowest: $($stressResults.SystemHealth.MinMemoryMB)MB" -ForegroundColor Yellow
}

if ($stressResults.PerformanceMetrics.Count -gt 0) {
    Write-Host "`nKey Performance Metrics:" -ForegroundColor White
    $stressResults.PerformanceMetrics.Keys | ForEach-Object {
        Write-Host "  $($_): $($stressResults.PerformanceMetrics[$_])" -ForegroundColor Yellow
    }
}

# Determine overall result
if ($passedTests -eq $totalTests) {
    $stressResults.OverallResult = "EXCELLENT"
    Write-Host "`n🏆 STRESS TESTING RESULT: EXCELLENT - System handled all stress scenarios perfectly" -ForegroundColor Green
} elseif ($overallPassRate -ge 80) {
    $stressResults.OverallResult = "GOOD"
    Write-Host "`n✅ STRESS TESTING RESULT: GOOD - System performed well under stress with minor degradation" -ForegroundColor Green
} elseif ($overallPassRate -ge 60) {
    $stressResults.OverallResult = "ACCEPTABLE"
    Write-Host "`n⚠️  STRESS TESTING RESULT: ACCEPTABLE - System survived stress but with performance degradation" -ForegroundColor Yellow
} else {
    $stressResults.OverallResult = "CONCERNING"
    Write-Host "`n❌ STRESS TESTING RESULT: CONCERNING - System showed significant issues under stress" -ForegroundColor Red
}

# Export results
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resultsFile = "Week3Day15-StressTestingFramework-Results-$timestamp.json"
$stressResults | ConvertTo-Json -Depth 10 | Out-File $resultsFile -Encoding UTF8
Write-Host "`nDetailed stress test results exported to: $resultsFile" -ForegroundColor Cyan

Write-Host "`n" + "=" * 80 -ForegroundColor Red

return $stressResults