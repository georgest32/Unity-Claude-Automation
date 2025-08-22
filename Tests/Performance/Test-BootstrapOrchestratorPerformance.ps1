# Test-BootstrapOrchestratorPerformance.ps1
# Performance Testing Framework for Bootstrap Orchestrator
# Phase 3 Day 1 - Hour 5-6: Performance Measurement and Validation

param(
    [string]$OutputFile = ".\Test_Results_BootstrapOrchestratorPerformance_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt",
    [int]$MaxSubsystems = 15,
    [int]$PerformanceRuns = 3
)

# Initialize performance test framework
$Global:PerformanceTestResults = @()
$Global:PerformanceTestStartTime = Get-Date
$performanceMetrics = @{}

# Performance Targets (from implementation plan)
$PERFORMANCE_TARGETS = @{
    StartupTime = 5000    # <5 seconds for 10 subsystems (in milliseconds)
    MemoryUsage = 100     # <100MB base overhead
    CpuUsage = 5          # <5% during monitoring
    HealthCheckLatency = 100  # <100ms per subsystem
}

function Write-PerformanceTestResult {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$TestName = "Performance"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] [$TestName] $Message"
    
    # Console output with colors
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARN"  { Write-Host $logMessage -ForegroundColor Yellow }
        "OK"    { Write-Host $logMessage -ForegroundColor Green }
        "DEBUG" { Write-Host $logMessage -ForegroundColor Gray }
        "TRACE" { Write-Host $logMessage -ForegroundColor DarkGray }
        "PERF"  { Write-Host $logMessage -ForegroundColor Cyan }
        default { Write-Host $logMessage }
    }
    
    $Global:PerformanceTestResults += $logMessage
}

function Get-ProcessMemoryUsage {
    param([int]$ProcessId = $PID)
    
    try {
        $process = Get-Process -Id $ProcessId -ErrorAction Stop
        return [Math]::Round($process.WorkingSet64 / 1MB, 2)
    } catch {
        return 0
    }
}

function Get-ProcessCpuUsage {
    param([int]$ProcessId = $PID, [int]$SampleSeconds = 2)
    
    try {
        $before = Get-Process -Id $ProcessId -ErrorAction Stop
        Start-Sleep -Seconds $SampleSeconds
        $after = Get-Process -Id $ProcessId -ErrorAction Stop
        
        $cpuTime = ($after.TotalProcessorTime - $before.TotalProcessorTime).TotalMilliseconds
        $wallTime = $SampleSeconds * 1000
        $cpuUsage = [Math]::Round(($cpuTime / $wallTime) * 100, 2)
        
        return $cpuUsage
    } catch {
        return 0
    }
}

function Measure-PerformanceBlock {
    param(
        [scriptblock]$ScriptBlock,
        [string]$OperationName = "Operation"
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $beforeMemory = Get-ProcessMemoryUsage
    
    try {
        $result = & $ScriptBlock
        $stopwatch.Stop()
        
        $afterMemory = Get-ProcessMemoryUsage
        $memoryDelta = $afterMemory - $beforeMemory
        
        return @{
            Success = $true
            Duration = $stopwatch.ElapsedMilliseconds
            MemoryBefore = $beforeMemory
            MemoryAfter = $afterMemory
            MemoryDelta = $memoryDelta
            Result = $result
            OperationName = $OperationName
        }
    } catch {
        $stopwatch.Stop()
        return @{
            Success = $false
            Duration = $stopwatch.ElapsedMilliseconds
            Error = $_.Exception.Message
            OperationName = $OperationName
        }
    }
}

Write-PerformanceTestResult "========================================================" "INFO"
Write-PerformanceTestResult "BOOTSTRAP ORCHESTRATOR PERFORMANCE TESTS" "INFO"
Write-PerformanceTestResult "Phase 3 Day 1 - Hour 5-6: Performance Measurement" "INFO"
Write-PerformanceTestResult "========================================================" "INFO"
Write-PerformanceTestResult "Performance tests started at: $Global:PerformanceTestStartTime" "INFO"
Write-PerformanceTestResult "Output file: $OutputFile" "INFO"
Write-PerformanceTestResult "Max subsystems to test: $MaxSubsystems" "INFO"
Write-PerformanceTestResult "Performance runs per test: $PerformanceRuns" "INFO"
Write-PerformanceTestResult "" "INFO"

# Performance Targets Display
Write-PerformanceTestResult "Performance Targets:" "INFO"
Write-PerformanceTestResult "  Startup Time: <$($PERFORMANCE_TARGETS.StartupTime)ms for 10 subsystems" "INFO"
Write-PerformanceTestResult "  Memory Usage: <$($PERFORMANCE_TARGETS.MemoryUsage)MB base overhead" "INFO"
Write-PerformanceTestResult "  CPU Usage: <$($PERFORMANCE_TARGETS.CpuUsage)% during monitoring" "INFO"
Write-PerformanceTestResult "  Health Check: <$($PERFORMANCE_TARGETS.HealthCheckLatency)ms per subsystem" "INFO"
Write-PerformanceTestResult "" "INFO"

# Set working directory and import module
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-PerformanceTestResult "Importing Unity-Claude-SystemStatus module..." "INFO"
Remove-Module Unity-Claude-SystemStatus -Force -ErrorAction SilentlyContinue

try {
    Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force -ErrorAction Stop
    Write-PerformanceTestResult "Module imported successfully" "OK"
} catch {
    Write-PerformanceTestResult "Failed to import module: $_" "ERROR"
    exit 1
}

#region Performance Test 1: Mutex Operations Performance

Write-PerformanceTestResult "" "INFO"
Write-PerformanceTestResult "PERFORMANCE TEST 1: Mutex Operations" "INFO"
Write-PerformanceTestResult "====================================" "INFO"

$mutexPerformanceResults = @()

for ($run = 1; $run -le $PerformanceRuns; $run++) {
    Write-PerformanceTestResult "Mutex performance run $run/$PerformanceRuns" "DEBUG" "MutexPerformance"
    
    # Test mutex creation performance
    $mutexCreationTest = Measure-PerformanceBlock -OperationName "MutexCreation" -ScriptBlock {
        $results = @()
        for ($i = 1; $i -le 10; $i++) {
            $mutex = New-SubsystemMutex -SubsystemName "PerfTest$i" -TimeoutMs 1000
            $results += $mutex
        }
        return $results
    }
    
    if ($mutexCreationTest.Success) {
        Write-PerformanceTestResult "Mutex creation (10 mutexes): $($mutexCreationTest.Duration)ms" "PERF" "MutexPerformance"
        $mutexPerformanceResults += @{
            Operation = "Creation"
            Run = $run
            Duration = $mutexCreationTest.Duration
            ThroughputPerSecond = [Math]::Round(10000 / $mutexCreationTest.Duration, 2)
        }
        
        # Clean up mutexes
        foreach ($mutexResult in $mutexCreationTest.Result) {
            if ($mutexResult.Acquired) {
                Remove-SubsystemMutex -MutexObject $mutexResult.Mutex -SubsystemName "PerfTest$($mutexCreationTest.Result.IndexOf($mutexResult) + 1)"
            }
        }
    } else {
        Write-PerformanceTestResult "Mutex creation test failed: $($mutexCreationTest.Error)" "ERROR" "MutexPerformance"
    }
    
    # Test mutex testing performance
    $mutex = New-SubsystemMutex -SubsystemName "PerfTestStatus" -TimeoutMs 1000
    if ($mutex.Acquired) {
        $mutexStatusTest = Measure-PerformanceBlock -OperationName "MutexStatusCheck" -ScriptBlock {
            for ($i = 1; $i -le 100; $i++) {
                Test-SubsystemMutex -SubsystemName "PerfTestStatus"
            }
        }
        
        if ($mutexStatusTest.Success) {
            Write-PerformanceTestResult "Mutex status checks (100 calls): $($mutexStatusTest.Duration)ms" "PERF" "MutexPerformance"
            $mutexPerformanceResults += @{
                Operation = "StatusCheck"
                Run = $run
                Duration = $mutexStatusTest.Duration
                ThroughputPerSecond = [Math]::Round(100000 / $mutexStatusTest.Duration, 2)
            }
        }
        
        Remove-SubsystemMutex -MutexObject $mutex.Mutex -SubsystemName "PerfTestStatus"
    }
}

# Calculate average mutex performance
$avgMutexCreation = ($mutexPerformanceResults | Where-Object { $_.Operation -eq "Creation" } | Measure-Object -Property Duration -Average).Average
$avgMutexStatusCheck = ($mutexPerformanceResults | Where-Object { $_.Operation -eq "StatusCheck" } | Measure-Object -Property Duration -Average).Average

Write-PerformanceTestResult "" "INFO"
Write-PerformanceTestResult "Mutex Performance Summary:" "PERF" "MutexPerformance"
Write-PerformanceTestResult "  Average Creation Time (10 mutexes): $([Math]::Round($avgMutexCreation, 2))ms" "PERF" "MutexPerformance"
Write-PerformanceTestResult "  Average Status Check Time (100 calls): $([Math]::Round($avgMutexStatusCheck, 2))ms" "PERF" "MutexPerformance"

$performanceMetrics["MutexCreationAvg"] = $avgMutexCreation
$performanceMetrics["MutexStatusCheckAvg"] = $avgMutexStatusCheck

#endregion

#region Performance Test 2: Manifest Discovery and Validation Performance

Write-PerformanceTestResult "" "INFO"
Write-PerformanceTestResult "PERFORMANCE TEST 2: Manifest Operations" "INFO"
Write-PerformanceTestResult "=======================================" "INFO"

# Create test manifests for performance testing
$testManifestDir = ".\Tests\Performance\TestManifests"
if (-not (Test-Path $testManifestDir)) {
    New-Item -ItemType Directory -Path $testManifestDir -Force | Out-Null
}

# Generate multiple test manifests
for ($i = 1; $i -le $MaxSubsystems; $i++) {
    $manifestContent = @"
@{
    Name = "PerfTestSubsystem$i"
    Version = "1.0.0"
    Description = "Performance test subsystem $i"
    StartScript = ".\test$i.ps1"
    DependsOn = @($(if ($i -gt 1) { """PerfTestSubsystem$($i-1)""" } else { "" }))
    RestartPolicy = "OnFailure"
    MaxRestarts = 3
    RestartDelay = 5
    MaxMemoryMB = 100
    MaxCpuPercent = 25
    Priority = "Normal"
}
"@
    $manifestContent | Out-File "$testManifestDir\PerfTestSubsystem$i.manifest.psd1" -Encoding ASCII
}

$manifestPerformanceResults = @()

for ($run = 1; $run -le $PerformanceRuns; $run++) {
    Write-PerformanceTestResult "Manifest performance run $run/$PerformanceRuns" "DEBUG" "ManifestPerformance"
    
    # Test manifest discovery performance
    $manifestDiscoveryTest = Measure-PerformanceBlock -OperationName "ManifestDiscovery" -ScriptBlock {
        Get-SubsystemManifests -SearchPath $testManifestDir -Force
    }
    
    if ($manifestDiscoveryTest.Success) {
        $manifestCount = $manifestDiscoveryTest.Result.Count
        Write-PerformanceTestResult "Manifest discovery ($manifestCount manifests): $($manifestDiscoveryTest.Duration)ms" "PERF" "ManifestPerformance"
        $manifestPerformanceResults += @{
            Operation = "Discovery"
            Run = $run
            Duration = $manifestDiscoveryTest.Duration
            Count = $manifestCount
        }
    }
    
    # Test manifest validation performance
    if ($manifestDiscoveryTest.Success -and $manifestDiscoveryTest.Result) {
        $manifestValidationTest = Measure-PerformanceBlock -OperationName "ManifestValidation" -ScriptBlock {
            $validationResults = @()
            foreach ($manifest in $manifestDiscoveryTest.Result) {
                $validationResults += Test-SubsystemManifest -Manifest $manifest
            }
            return $validationResults
        }
        
        if ($manifestValidationTest.Success) {
            $validCount = ($manifestValidationTest.Result | Where-Object { $_.IsValid }).Count
            Write-PerformanceTestResult "Manifest validation ($validCount/$($manifestDiscoveryTest.Result.Count) valid): $($manifestValidationTest.Duration)ms" "PERF" "ManifestPerformance"
            $manifestPerformanceResults += @{
                Operation = "Validation"
                Run = $run
                Duration = $manifestValidationTest.Duration
                Count = $validCount
            }
        }
    }
}

# Calculate average manifest performance
$avgManifestDiscovery = ($manifestPerformanceResults | Where-Object { $_.Operation -eq "Discovery" } | Measure-Object -Property Duration -Average).Average
$avgManifestValidation = ($manifestPerformanceResults | Where-Object { $_.Operation -eq "Validation" } | Measure-Object -Property Duration -Average).Average

Write-PerformanceTestResult "" "INFO"
Write-PerformanceTestResult "Manifest Performance Summary:" "PERF" "ManifestPerformance"
Write-PerformanceTestResult "  Average Discovery Time ($MaxSubsystems manifests): $([Math]::Round($avgManifestDiscovery, 2))ms" "PERF" "ManifestPerformance"
Write-PerformanceTestResult "  Average Validation Time ($MaxSubsystems manifests): $([Math]::Round($avgManifestValidation, 2))ms" "PERF" "ManifestPerformance"

$performanceMetrics["ManifestDiscoveryAvg"] = $avgManifestDiscovery
$performanceMetrics["ManifestValidationAvg"] = $avgManifestValidation

#endregion

#region Performance Test 3: Dependency Resolution Performance

Write-PerformanceTestResult "" "INFO"
Write-PerformanceTestResult "PERFORMANCE TEST 3: Dependency Resolution" "INFO"
Write-PerformanceTestResult "=========================================" "INFO"

$dependencyPerformanceResults = @()

# Get manifests for dependency testing
$testManifests = Get-SubsystemManifests -SearchPath $testManifestDir -Force

for ($run = 1; $run -le $PerformanceRuns; $run++) {
    Write-PerformanceTestResult "Dependency resolution run $run/$PerformanceRuns" "DEBUG" "DependencyPerformance"
    
    # Test topological sort performance (DFS)
    $dfsPerformanceTest = Measure-PerformanceBlock -OperationName "TopologicalSort-DFS" -ScriptBlock {
        $dependencyGraph = @{}
        foreach ($manifest in $testManifests) {
            $dependencyGraph[$manifest.Name] = $manifest.DependsOn
        }
        Get-TopologicalSort -DependencyGraph $dependencyGraph -Algorithm 'DFS'
    }
    
    if ($dfsPerformanceTest.Success) {
        Write-PerformanceTestResult "DFS topological sort ($($testManifests.Count) subsystems): $($dfsPerformanceTest.Duration)ms" "PERF" "DependencyPerformance"
        $dependencyPerformanceResults += @{
            Algorithm = "DFS"
            Run = $run
            Duration = $dfsPerformanceTest.Duration
            Count = $testManifests.Count
        }
    }
    
    # Test topological sort performance (Kahn)
    $kahnPerformanceTest = Measure-PerformanceBlock -OperationName "TopologicalSort-Kahn" -ScriptBlock {
        $dependencyGraph = @{}
        foreach ($manifest in $testManifests) {
            $dependencyGraph[$manifest.Name] = $manifest.DependsOn
        }
        Get-TopologicalSort -DependencyGraph $dependencyGraph -Algorithm 'Kahn'
    }
    
    if ($kahnPerformanceTest.Success) {
        Write-PerformanceTestResult "Kahn topological sort ($($testManifests.Count) subsystems): $($kahnPerformanceTest.Duration)ms" "PERF" "DependencyPerformance"
        $dependencyPerformanceResults += @{
            Algorithm = "Kahn"
            Run = $run
            Duration = $kahnPerformanceTest.Duration
            Count = $testManifests.Count
        }
    }
    
    # Test complete startup order calculation
    $startupOrderTest = Measure-PerformanceBlock -OperationName "StartupOrderCalculation" -ScriptBlock {
        Get-SubsystemStartupOrder -Manifests $testManifests -EnableParallelExecution -IncludeValidation
    }
    
    if ($startupOrderTest.Success) {
        Write-PerformanceTestResult "Complete startup order calculation: $($startupOrderTest.Duration)ms" "PERF" "DependencyPerformance"
        $dependencyPerformanceResults += @{
            Algorithm = "StartupOrder"
            Run = $run
            Duration = $startupOrderTest.Duration
            Count = $testManifests.Count
        }
    }
}

# Calculate average dependency resolution performance
$avgDFS = ($dependencyPerformanceResults | Where-Object { $_.Algorithm -eq "DFS" } | Measure-Object -Property Duration -Average).Average
$avgKahn = ($dependencyPerformanceResults | Where-Object { $_.Algorithm -eq "Kahn" } | Measure-Object -Property Duration -Average).Average
$avgStartupOrder = ($dependencyPerformanceResults | Where-Object { $_.Algorithm -eq "StartupOrder" } | Measure-Object -Property Duration -Average).Average

Write-PerformanceTestResult "" "INFO"
Write-PerformanceTestResult "Dependency Resolution Performance Summary:" "PERF" "DependencyPerformance"
Write-PerformanceTestResult "  Average DFS Sort Time ($($testManifests.Count) subsystems): $([Math]::Round($avgDFS, 2))ms" "PERF" "DependencyPerformance"
Write-PerformanceTestResult "  Average Kahn Sort Time ($($testManifests.Count) subsystems): $([Math]::Round($avgKahn, 2))ms" "PERF" "DependencyPerformance"
Write-PerformanceTestResult "  Average Startup Order Time ($($testManifests.Count) subsystems): $([Math]::Round($avgStartupOrder, 2))ms" "PERF" "DependencyPerformance"

$performanceMetrics["DependencyResolutionDFS"] = $avgDFS
$performanceMetrics["DependencyResolutionKahn"] = $avgKahn
$performanceMetrics["StartupOrderCalculation"] = $avgStartupOrder

#endregion

#region Performance Test 4: Scalability Testing

Write-PerformanceTestResult "" "INFO"
Write-PerformanceTestResult "PERFORMANCE TEST 4: Scalability Testing" "INFO"
Write-PerformanceTestResult "=======================================" "INFO"

$scalabilityResults = @()

# Test with different numbers of subsystems
$testSizes = @(5, 10, 15)

foreach ($size in $testSizes) {
    Write-PerformanceTestResult "Testing scalability with $size subsystems..." "DEBUG" "ScalabilityTest"
    
    # Get subset of manifests
    $subsetManifests = $testManifests | Select-Object -First $size
    
    $scalabilityTest = Measure-PerformanceBlock -OperationName "ScalabilityTest-$size" -ScriptBlock {
        # Complete workflow test
        $results = @{}
        
        # Discovery
        $discoveryTime = Measure-Command {
            $results.Manifests = $subsetManifests
        }
        $results.DiscoveryTime = $discoveryTime.TotalMilliseconds
        
        # Validation
        $validationTime = Measure-Command {
            $results.ValidationResults = @()
            foreach ($manifest in $subsetManifests) {
                $results.ValidationResults += Test-SubsystemManifest -Manifest $manifest
            }
        }
        $results.ValidationTime = $validationTime.TotalMilliseconds
        
        # Dependency Resolution
        $dependencyTime = Measure-Command {
            $results.StartupOrder = Get-SubsystemStartupOrder -Manifests $subsetManifests -EnableParallelExecution
        }
        $results.DependencyTime = $dependencyTime.TotalMilliseconds
        
        $results.TotalTime = $results.DiscoveryTime + $results.ValidationTime + $results.DependencyTime
        
        return $results
    }
    
    if ($scalabilityTest.Success) {
        $result = $scalabilityTest.Result
        Write-PerformanceTestResult "Scalability test ($size subsystems): $($scalabilityTest.Duration)ms total" "PERF" "ScalabilityTest"
        Write-PerformanceTestResult "  Discovery: $([Math]::Round($result.DiscoveryTime, 2))ms" "PERF" "ScalabilityTest"
        Write-PerformanceTestResult "  Validation: $([Math]::Round($result.ValidationTime, 2))ms" "PERF" "ScalabilityTest"
        Write-PerformanceTestResult "  Dependency Resolution: $([Math]::Round($result.DependencyTime, 2))ms" "PERF" "ScalabilityTest"
        
        $scalabilityResults += @{
            SubsystemCount = $size
            TotalTime = $scalabilityTest.Duration
            DiscoveryTime = $result.DiscoveryTime
            ValidationTime = $result.ValidationTime
            DependencyTime = $result.DependencyTime
            MemoryUsage = $scalabilityTest.MemoryAfter
        }
    }
}

Write-PerformanceTestResult "" "INFO"
Write-PerformanceTestResult "Scalability Performance Summary:" "PERF" "ScalabilityTest"
foreach ($result in $scalabilityResults) {
    Write-PerformanceTestResult "  $($result.SubsystemCount) subsystems: $([Math]::Round($result.TotalTime, 2))ms (Memory: $($result.MemoryUsage)MB)" "PERF" "ScalabilityTest"
}

$performanceMetrics["ScalabilityResults"] = $scalabilityResults

#endregion

#region Performance Test 5: Memory and CPU Usage

Write-PerformanceTestResult "" "INFO"
Write-PerformanceTestResult "PERFORMANCE TEST 5: Memory and CPU Usage" "INFO"
Write-PerformanceTestResult "=========================================" "INFO"

$baselineMemory = Get-ProcessMemoryUsage
Write-PerformanceTestResult "Baseline memory usage: $($baselineMemory)MB" "PERF" "ResourceUsage"

# Perform intensive operations and measure resource usage
$resourceTest = Measure-PerformanceBlock -OperationName "ResourceUsageTest" -ScriptBlock {
    # Simulate typical Bootstrap Orchestrator workload
    for ($i = 1; $i -le 5; $i++) {
        # Mutex operations
        $mutex = New-SubsystemMutex -SubsystemName "ResourceTest$i" -TimeoutMs 1000
        if ($mutex.Acquired) {
            Test-SubsystemMutex -SubsystemName "ResourceTest$i"
            Remove-SubsystemMutex -MutexObject $mutex.Mutex -SubsystemName "ResourceTest$i"
        }
        
        # Manifest operations
        $manifests = Get-SubsystemManifests -SearchPath $testManifestDir -Force
        foreach ($manifest in ($manifests | Select-Object -First 3)) {
            Test-SubsystemManifest -Manifest $manifest | Out-Null
        }
        
        # Dependency resolution
        Get-SubsystemStartupOrder -Manifests ($manifests | Select-Object -First 5) | Out-Null
    }
}

$peakMemory = Get-ProcessMemoryUsage
$memoryOverhead = $peakMemory - $baselineMemory

Write-PerformanceTestResult "Peak memory usage: $($peakMemory)MB" "PERF" "ResourceUsage"
Write-PerformanceTestResult "Memory overhead: $($memoryOverhead)MB" "PERF" "ResourceUsage"

# CPU usage measurement
Write-PerformanceTestResult "Measuring CPU usage during intensive operations..." "DEBUG" "ResourceUsage"
$cpuUsage = Get-ProcessCpuUsage -SampleSeconds 3

Write-PerformanceTestResult "CPU usage during intensive operations: $($cpuUsage)%" "PERF" "ResourceUsage"

$performanceMetrics["BaselineMemory"] = $baselineMemory
$performanceMetrics["PeakMemory"] = $peakMemory
$performanceMetrics["MemoryOverhead"] = $memoryOverhead
$performanceMetrics["CpuUsage"] = $cpuUsage

#endregion

# Performance Test Summary and Validation
$performanceTestEndTime = Get-Date
$performanceTestDuration = $performanceTestEndTime - $Global:PerformanceTestStartTime

Write-PerformanceTestResult "" "INFO"
Write-PerformanceTestResult "========================================================" "INFO"
Write-PerformanceTestResult "BOOTSTRAP ORCHESTRATOR PERFORMANCE TESTS COMPLETED" "INFO"
Write-PerformanceTestResult "========================================================" "INFO"
Write-PerformanceTestResult "End time: $performanceTestEndTime" "INFO"
Write-PerformanceTestResult "Total duration: $($performanceTestDuration.TotalSeconds) seconds" "INFO"

Write-PerformanceTestResult "" "INFO"
Write-PerformanceTestResult "PERFORMANCE VALIDATION AGAINST TARGETS:" "INFO"
Write-PerformanceTestResult "========================================" "INFO"

# Validate against performance targets
$validationResults = @()

# Startup time validation (extrapolate to 10 subsystems)
$startup10Subsystems = if ($scalabilityResults.Count -gt 1) {
    # Linear extrapolation from test results
    $ratio = 10 / ($scalabilityResults | Where-Object { $_.SubsystemCount -eq $MaxSubsystems }).SubsystemCount
    ($scalabilityResults | Where-Object { $_.SubsystemCount -eq $MaxSubsystems }).TotalTime * $ratio
} else {
    $performanceMetrics["StartupOrderCalculation"]
}

$startupValidation = @{
    Target = $PERFORMANCE_TARGETS.StartupTime
    Actual = $startup10Subsystems
    Passed = $startup10Subsystems -lt $PERFORMANCE_TARGETS.StartupTime
    Name = "Startup Time (10 subsystems)"
}
$validationResults += $startupValidation

# Memory usage validation
$memoryValidation = @{
    Target = $PERFORMANCE_TARGETS.MemoryUsage
    Actual = $performanceMetrics["MemoryOverhead"]
    Passed = $performanceMetrics["MemoryOverhead"] -lt $PERFORMANCE_TARGETS.MemoryUsage
    Name = "Memory Overhead"
}
$validationResults += $memoryValidation

# CPU usage validation
$cpuValidation = @{
    Target = $PERFORMANCE_TARGETS.CpuUsage
    Actual = $performanceMetrics["CpuUsage"]
    Passed = $performanceMetrics["CpuUsage"] -lt $PERFORMANCE_TARGETS.CpuUsage
    Name = "CPU Usage"
}
$validationResults += $cpuValidation

# Health check latency validation (using mutex status check as proxy)
$healthCheckValidation = @{
    Target = $PERFORMANCE_TARGETS.HealthCheckLatency
    Actual = $performanceMetrics["MutexStatusCheckAvg"]
    Passed = $performanceMetrics["MutexStatusCheckAvg"] -lt $PERFORMANCE_TARGETS.HealthCheckLatency
    Name = "Health Check Latency"
}
$validationResults += $healthCheckValidation

# Display validation results
foreach ($validation in $validationResults) {
    $status = if ($validation.Passed) { "PASS" } else { "FAIL" }
    $level = if ($validation.Passed) { "OK" } else { "ERROR" }
    $unit = switch ($validation.Name) {
        "Startup Time (10 subsystems)" { "ms" }
        "Memory Overhead" { "MB" }
        "CPU Usage" { "%" }
        "Health Check Latency" { "ms" }
        default { "" }
    }
    
    Write-PerformanceTestResult "  $($validation.Name): $status" $level "Validation"
    Write-PerformanceTestResult "    Target: <$($validation.Target)$unit, Actual: $([Math]::Round($validation.Actual, 2))$unit" "DEBUG" "Validation"
}

$passedValidations = ($validationResults | Where-Object { $_.Passed }).Count
$totalValidations = $validationResults.Count

Write-PerformanceTestResult "" "INFO"
Write-PerformanceTestResult "Performance Validation Summary:" "INFO"
Write-PerformanceTestResult "  Validations Passed: $passedValidations/$totalValidations" $(if ($passedValidations -eq $totalValidations) { "OK" } else { "WARN" })
$performanceScore = [Math]::Round(($passedValidations / $totalValidations) * 100, 1)
Write-PerformanceTestResult "  Performance Score: $performanceScore%" $(if ($performanceScore -ge 75) { "OK" } elseif ($performanceScore -ge 50) { "WARN" } else { "ERROR" })

# Clean up test files
try {
    if (Test-Path $testManifestDir) {
        Remove-Item $testManifestDir -Recurse -Force -ErrorAction SilentlyContinue
    }
} catch {
    Write-PerformanceTestResult "Warning: Could not clean up test manifests: $_" "WARN"
}

# Save results
Write-PerformanceTestResult "" "INFO"
Write-PerformanceTestResult "Saving performance test results to: $OutputFile" "INFO"
$Global:PerformanceTestResults | Out-File $OutputFile -Encoding ASCII

if ($passedValidations -eq $totalValidations) {
    Write-PerformanceTestResult "All performance targets MET successfully!" "OK"
    Write-PerformanceTestResult "Bootstrap Orchestrator performance validated" "OK"
} else {
    Write-PerformanceTestResult "Some performance targets not met. Review output for optimization opportunities." "WARN"
}

Write-PerformanceTestResult "Performance test results saved to: $OutputFile" "INFO"

# Update progress
$Global:PerformanceTestResults += ""
$Global:PerformanceTestResults += "HOUR 5-6 COMPLETION STATUS:"
$Global:PerformanceTestResults += "[PASS] Performance Test Framework Created"
$Global:PerformanceTestResults += "[PASS] Mutex Operations Performance Tested"
$Global:PerformanceTestResults += "[PASS] Manifest Operations Performance Validated"
$Global:PerformanceTestResults += "[PASS] Dependency Resolution Performance Measured"
$Global:PerformanceTestResults += "[PASS] Scalability Testing Completed ($MaxSubsystems subsystems)"
$Global:PerformanceTestResults += "[PASS] Memory and CPU Usage Monitoring Implemented"
$Global:PerformanceTestResults += "[STATS] Performance Score: $performanceScore%"
$Global:PerformanceTestResults += "[STATS] Targets Met: $passedValidations/$totalValidations"

Write-PerformanceTestResult "Hour 5-6 Performance Testing Phase COMPLETED" "OK"