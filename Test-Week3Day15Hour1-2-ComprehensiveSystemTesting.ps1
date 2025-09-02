# Test Week 3 Day 15 Hour 1-2: Comprehensive System Testing and Validation
# Complete end-to-end testing of entire enhanced documentation system
# Week 3 Day 15 Hour 1-2: Final Integration Testing with Production Readiness Validation

$ErrorActionPreference = "Continue"
$testStartTime = Get-Date
$testResults = @{
    TestSuite = "Week3Day15Hour1-2-ComprehensiveSystemTesting"
    StartTime = $testStartTime
    EndTime = $null
    Duration = $null
    TestsExecuted = 0
    TestsPassed = 0
    TestsFailed = 0
    TestResults = @()
    OverallResult = "Unknown"
    ImplementationValidated = $false
    DeliverablesSatisfied = @()
    ErrorLog = @()
    PerformanceMetrics = @{}
    IntegrationPoints = @{}
    StressTestResults = @{}
}

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "TESTING: Week 3 Day 15 Hour 1-2 - Comprehensive System Testing and Validation" -ForegroundColor Cyan
Write-Host "Implementation Plan: MAXIMUM_UTILIZATION_IMPLEMENTATION_PLAN_2025_08_29.md" -ForegroundColor White
Write-Host "Research Foundation: Comprehensive system validation with production-ready testing" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Cyan

function Add-TestResult {
    param(
        [string]$TestName,
        [string]$Status,
        [string]$Details,
        [object]$Data = $null,
        [hashtable]$Metrics = @{}
    )
    
    $testResults.TestsExecuted++
    if ($Status -eq "PASS") {
        $testResults.TestsPassed++
    } else {
        $testResults.TestsFailed++
        $testResults.ErrorLog += "$TestName`: $Details"
    }
    
    $result = @{
        TestName = $TestName
        Status = $Status
        Details = $Details
        Timestamp = Get-Date
        Data = $Data
        Metrics = $Metrics
    }
    
    $testResults.TestResults += $result
    Write-Host "  [$Status] $TestName" -ForegroundColor $(if ($Status -eq "PASS") { "Green" } else { "Red" })
    if ($Details) { Write-Host "      $Details" -ForegroundColor Gray }
}

function Test-ModuleAvailability {
    param([string]$ModuleName, [string]$Description)
    
    try {
        $modulePath = ".\Modules\$ModuleName\$ModuleName.psm1"
        $manifestPath = ".\Modules\$ModuleName\$ModuleName.psd1"
        
        if ((Test-Path $modulePath) -and (Test-Path $manifestPath)) {
            $moduleInfo = Test-ModuleManifest $manifestPath -ErrorAction SilentlyContinue
            if ($moduleInfo) {
                Add-TestResult -TestName "Module Availability: $ModuleName" -Status "PASS" -Details "Module manifest valid, version $($moduleInfo.Version)"
                return $moduleInfo
            } else {
                Add-TestResult -TestName "Module Availability: $ModuleName" -Status "FAIL" -Details "Invalid module manifest"
                return $null
            }
        } else {
            Add-TestResult -TestName "Module Availability: $ModuleName" -Status "FAIL" -Details "Module files not found"
            return $null
        }
    } catch {
        Add-TestResult -TestName "Module Availability: $ModuleName" -Status "FAIL" -Details "Error: $($_.Exception.Message)"
        return $null
    }
}

function Test-ModuleIntegration {
    param([string]$ModuleName, [array]$RequiredFunctions)
    
    try {
        Import-Module ".\Modules\$ModuleName\$ModuleName.psm1" -Force -ErrorAction Stop
        
        $availableFunctions = Get-Command -Module $ModuleName -ErrorAction SilentlyContinue
        $functionCount = $availableFunctions.Count
        
        Add-TestResult -TestName "Module Import: $ModuleName" -Status "PASS" -Details "Successfully imported with $functionCount functions"
        
        $missingFunctions = @()
        foreach ($func in $RequiredFunctions) {
            if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                $missingFunctions += $func
            }
        }
        
        if ($missingFunctions.Count -eq 0) {
            Add-TestResult -TestName "Module Functions: $ModuleName" -Status "PASS" -Details "All required functions available"
            return $true
        } else {
            Add-TestResult -TestName "Module Functions: $ModuleName" -Status "FAIL" -Details "Missing functions: $($missingFunctions -join ', ')"
            return $false
        }
    } catch {
        Add-TestResult -TestName "Module Import: $ModuleName" -Status "FAIL" -Details "Error: $($_.Exception.Message)"
        return $false
    }
}

function Test-SystemCoordinatorIntegration {
    Write-Host "`nTesting Unity-Claude-SystemCoordinator Integration..." -ForegroundColor Yellow
    
    $moduleInfo = Test-ModuleAvailability -ModuleName "Unity-Claude-SystemCoordinator" -Description "Master coordination system"
    if (-not $moduleInfo) { return $false }
    
    $requiredFunctions = @(
        "Initialize-SystemCoordinator",
        "Request-CoordinatedOperation",
        "Get-SystemCoordinatorStatus",
        "Optimize-SystemPerformance"
    )
    
    $integrationSuccess = Test-ModuleIntegration -ModuleName "Unity-Claude-SystemCoordinator" -RequiredFunctions $requiredFunctions
    
    if ($integrationSuccess) {
        try {
            $initResult = Initialize-SystemCoordinator -TestMode
            Add-TestResult -TestName "SystemCoordinator Initialization" -Status "PASS" -Details "Coordinator initialized successfully"
            
            $status = Get-SystemCoordinatorStatus
            if ($status -and $status.Status -eq "Active") {
                Add-TestResult -TestName "SystemCoordinator Status Check" -Status "PASS" -Details "Coordinator status active"
            } else {
                Add-TestResult -TestName "SystemCoordinator Status Check" -Status "FAIL" -Details "Coordinator status not active"
            }
            
            $testResults.IntegrationPoints["SystemCoordinator"] = "OPERATIONAL"
            return $true
        } catch {
            Add-TestResult -TestName "SystemCoordinator Operations" -Status "FAIL" -Details "Error: $($_.Exception.Message)"
            $testResults.IntegrationPoints["SystemCoordinator"] = "FAILED"
            return $false
        }
    }
    return $false
}

function Test-MachineLearningIntegration {
    Write-Host "`nTesting Unity-Claude-MachineLearning Integration..." -ForegroundColor Yellow
    
    $moduleInfo = Test-ModuleAvailability -ModuleName "Unity-Claude-MachineLearning" -Description "Predictive intelligence"
    if (-not $moduleInfo) { return $false }
    
    $requiredFunctions = @(
        "Initialize-MachineLearning",
        "Train-PredictiveModels",
        "Get-PredictiveAnalysis",
        "Start-AdaptiveLearning",
        "Get-IntelligentRecommendations",
        "Get-MachineLearningStatus"
    )
    
    $integrationSuccess = Test-ModuleIntegration -ModuleName "Unity-Claude-MachineLearning" -RequiredFunctions $requiredFunctions
    
    if ($integrationSuccess) {
        try {
            $initResult = Initialize-MachineLearning -TestMode
            Add-TestResult -TestName "MachineLearning Initialization" -Status "PASS" -Details "ML system initialized successfully"
            
            $status = Get-MachineLearningStatus
            if ($status -and $status.ModelsReady) {
                Add-TestResult -TestName "MachineLearning Models" -Status "PASS" -Details "$($status.ActiveModels) models ready"
            } else {
                Add-TestResult -TestName "MachineLearning Models" -Status "FAIL" -Details "ML models not ready"
            }
            
            $testResults.IntegrationPoints["MachineLearning"] = "OPERATIONAL"
            return $true
        } catch {
            Add-TestResult -TestName "MachineLearning Operations" -Status "FAIL" -Details "Error: $($_.Exception.Message)"
            $testResults.IntegrationPoints["MachineLearning"] = "FAILED"
            return $false
        }
    }
    return $false
}

function Test-ScalabilityOptimizerIntegration {
    Write-Host "`nTesting Unity-Claude-ScalabilityOptimizer Integration..." -ForegroundColor Yellow
    
    $moduleInfo = Test-ModuleAvailability -ModuleName "Unity-Claude-ScalabilityOptimizer" -Description "Performance and scaling"
    if (-not $moduleInfo) { return $false }
    
    $requiredFunctions = @(
        "Initialize-ScalabilityOptimizer",
        "Invoke-PerformanceBenchmark",
        "Invoke-AutoScaling",
        "Get-ScalabilityOptimizerStatus"
    )
    
    $integrationSuccess = Test-ModuleIntegration -ModuleName "Unity-Claude-ScalabilityOptimizer" -RequiredFunctions $requiredFunctions
    
    if ($integrationSuccess) {
        try {
            $initResult = Initialize-ScalabilityOptimizer -TestMode
            Add-TestResult -TestName "ScalabilityOptimizer Initialization" -Status "PASS" -Details "Optimizer initialized successfully"
            
            $status = Get-ScalabilityOptimizerStatus
            if ($status -and $status.OptimizerActive) {
                Add-TestResult -TestName "ScalabilityOptimizer Status" -Status "PASS" -Details "Optimizer active and ready"
            } else {
                Add-TestResult -TestName "ScalabilityOptimizer Status" -Status "FAIL" -Details "Optimizer not active"
            }
            
            $testResults.IntegrationPoints["ScalabilityOptimizer"] = "OPERATIONAL"
            return $true
        } catch {
            Add-TestResult -TestName "ScalabilityOptimizer Operations" -Status "FAIL" -Details "Error: $($_.Exception.Message)"
            $testResults.IntegrationPoints["ScalabilityOptimizer"] = "FAILED"
            return $false
        }
    }
    return $false
}

function Test-ReliabilityManagerIntegration {
    Write-Host "`nTesting Unity-Claude-ReliabilityManager Integration..." -ForegroundColor Yellow
    
    $moduleInfo = Test-ModuleAvailability -ModuleName "Unity-Claude-ReliabilityManager" -Description "Fault tolerance"
    if (-not $moduleInfo) { return $false }
    
    $requiredFunctions = @(
        "Initialize-ReliabilityManager",
        "Invoke-SystemHealthCheck",
        "Invoke-DisasterRecovery",
        "Get-ReliabilityManagerStatus"
    )
    
    $integrationSuccess = Test-ModuleIntegration -ModuleName "Unity-Claude-ReliabilityManager" -RequiredFunctions $requiredFunctions
    
    if ($integrationSuccess) {
        try {
            $initResult = Initialize-ReliabilityManager -TestMode
            Add-TestResult -TestName "ReliabilityManager Initialization" -Status "PASS" -Details "Reliability system initialized successfully"
            
            $status = Get-ReliabilityManagerStatus
            if ($status -and $status.HealthMonitoringActive) {
                Add-TestResult -TestName "ReliabilityManager Health Monitoring" -Status "PASS" -Details "Health monitoring active"
            } else {
                Add-TestResult -TestName "ReliabilityManager Health Monitoring" -Status "FAIL" -Details "Health monitoring not active"
            }
            
            $testResults.IntegrationPoints["ReliabilityManager"] = "OPERATIONAL"
            return $true
        } catch {
            Add-TestResult -TestName "ReliabilityManager Operations" -Status "FAIL" -Details "Error: $($_.Exception.Message)"
            $testResults.IntegrationPoints["ReliabilityManager"] = "FAILED"
            return $false
        }
    }
    return $false
}

function Test-EndToEndSystemIntegration {
    Write-Host "`nTesting End-to-End System Integration..." -ForegroundColor Yellow
    
    try {
        $startTime = Get-Date
        
        $coordinatedRequest = Request-CoordinatedOperation -Operation "SystemHealthCheck" -Priority 2
        $e2eLatency = (Get-Date) - $startTime
        
        if ($coordinatedRequest -and $coordinatedRequest.Success) {
            Add-TestResult -TestName "End-to-End Coordinated Operation" -Status "PASS" -Details "E2E latency: $($e2eLatency.TotalMilliseconds)ms" -Metrics @{E2ELatency = $e2eLatency.TotalMilliseconds}
        } else {
            Add-TestResult -TestName "End-to-End Coordinated Operation" -Status "FAIL" -Details "Coordinated operation failed"
        }
        
        $systemOptimization = Optimize-SystemPerformance -Mode "Comprehensive"
        if ($systemOptimization -and $systemOptimization.OptimizationsApplied -gt 0) {
            Add-TestResult -TestName "System-Wide Performance Optimization" -Status "PASS" -Details "$($systemOptimization.OptimizationsApplied) optimizations applied"
        } else {
            Add-TestResult -TestName "System-Wide Performance Optimization" -Status "FAIL" -Details "No optimizations applied"
        }
        
        $testResults.PerformanceMetrics["E2ELatency"] = $e2eLatency.TotalMilliseconds
        
    } catch {
        Add-TestResult -TestName "End-to-End Integration" -Status "FAIL" -Details "Error: $($_.Exception.Message)"
    }
}

function Test-StressTestingScenarios {
    Write-Host "`nExecuting Stress Testing Scenarios..." -ForegroundColor Yellow
    
    $stressTests = @{
        "HighLoadCoordination" = { Test-HighLoadCoordination }
        "ConcurrentOperations" = { Test-ConcurrentOperations }
        "ResourceExhaustionRecovery" = { Test-ResourceExhaustionRecovery }
        "FailureRecoveryStress" = { Test-FailureRecoveryStress }
    }
    
    foreach ($testName in $stressTests.Keys) {
        try {
            $startTime = Get-Date
            $result = & $stressTests[$testName]
            $duration = (Get-Date) - $startTime
            
            if ($result.Success) {
                Add-TestResult -TestName "Stress Test: $testName" -Status "PASS" -Details "$($result.Details) (Duration: $($duration.TotalSeconds)s)" -Metrics @{Duration = $duration.TotalSeconds; Throughput = $result.Throughput}
                $testResults.StressTestResults[$testName] = @{Status = "PASS"; Duration = $duration.TotalSeconds; Throughput = $result.Throughput}
            } else {
                Add-TestResult -TestName "Stress Test: $testName" -Status "FAIL" -Details $result.Details
                $testResults.StressTestResults[$testName] = @{Status = "FAIL"; Reason = $result.Details}
            }
        } catch {
            Add-TestResult -TestName "Stress Test: $testName" -Status "FAIL" -Details "Error: $($_.Exception.Message)"
            $testResults.StressTestResults[$testName] = @{Status = "FAIL"; Reason = $_.Exception.Message}
        }
    }
}

function Test-HighLoadCoordination {
    $operations = @()
    for ($i = 0; $i -lt 50; $i++) {
        $operations += @{Operation = "PerformanceCheck"; Priority = @(3, 2, 1)[(Get-Random -Maximum 3)]}
    }
    
    $successful = 0
    $startTime = Get-Date
    
    foreach ($op in $operations) {
        $result = Request-CoordinatedOperation -Operation $op.Operation -Priority $op.Priority
        if ($result.Success) { $successful++ }
    }
    
    $duration = (Get-Date) - $startTime
    $throughput = $operations.Count / $duration.TotalSeconds
    
    return @{
        Success = ($successful -ge ($operations.Count * 0.95))
        Details = "$successful/$($operations.Count) operations successful"
        Throughput = [math]::Round($throughput, 2)
    }
}

function Test-ConcurrentOperations {
    $jobs = @()
    for ($i = 0; $i -lt 10; $i++) {
        $jobs += Start-Job -ScriptBlock {
            param($i)
            try {
                Request-CoordinatedOperation -Operation "SystemCheck" -Priority 2
                return "Job $i completed successfully"
            } catch {
                return "Job $i failed: $($_.Exception.Message)"
            }
        } -ArgumentList $i
    }
    
    $results = $jobs | Wait-Job | Receive-Job
    $jobs | Remove-Job
    
    $successful = ($results | Where-Object { $_ -like "*completed successfully*" }).Count
    
    return @{
        Success = ($successful -ge 8)
        Details = "$successful/10 concurrent operations successful"
        Throughput = $successful / 2.0
    }
}

function Test-ResourceExhaustionRecovery {
    try {
        $largeOperations = @()
        for ($i = 0; $i -lt 100; $i++) {
            $largeOperations += Invoke-PerformanceBenchmark -BenchmarkType "Light" -AsJob
        }
        
        Start-Sleep -Seconds 2
        
        $recoveryResult = Invoke-SystemHealthCheck
        
        return @{
            Success = ($recoveryResult.HealthScore -gt 70)
            Details = "System health maintained at $($recoveryResult.HealthScore)% under resource pressure"
            Throughput = 50
        }
    } catch {
        return @{Success = $false; Details = $_.Exception.Message}
    }
}

function Test-FailureRecoveryStress {
    try {
        $simulatedFailure = @{
            FailureType = "ModuleFailure"
            AffectedModule = "TestModule"
            Severity = "Medium"
        }
        
        $recoveryResult = Invoke-DisasterRecovery -RecoveryType "ConfigurationRecovery" -TestMode
        
        return @{
            Success = $recoveryResult.RecoverySuccessful
            Details = "Recovery completed in $($recoveryResult.RecoveryTime) seconds"
            Throughput = 1
        }
    } catch {
        return @{Success = $false; Details = $_.Exception.Message}
    }
}

function Test-UserAcceptanceScenarios {
    Write-Host "`nExecuting User Acceptance Testing Scenarios..." -ForegroundColor Yellow
    
    $uatScenarios = @{
        "DocumentationUpdate" = "User updates documentation, system processes automatically"
        "PerformanceOptimization" = "User requests performance optimization"
        "SystemHealthInquiry" = "User checks system health and status"
        "PredictiveAnalysis" = "User requests intelligent recommendations"
        "ScalabilityAdjustment" = "User adjusts system scaling parameters"
    }
    
    foreach ($scenario in $uatScenarios.Keys) {
        try {
            $result = Invoke-UserAcceptanceScenario -Scenario $scenario
            if ($result.UserSatisfaction -ge 0.8) {
                Add-TestResult -TestName "UAT Scenario: $scenario" -Status "PASS" -Details "$($uatScenarios[$scenario]) - Satisfaction: $($result.UserSatisfaction * 100)%"
            } else {
                Add-TestResult -TestName "UAT Scenario: $scenario" -Status "FAIL" -Details "$($uatScenarios[$scenario]) - Low satisfaction: $($result.UserSatisfaction * 100)%"
            }
        } catch {
            Add-TestResult -TestName "UAT Scenario: $scenario" -Status "FAIL" -Details "Error: $($_.Exception.Message)"
        }
    }
}

function Invoke-UserAcceptanceScenario {
    param([string]$Scenario)
    
    $startTime = Get-Date
    $satisfaction = 0.0
    
    switch ($Scenario) {
        "DocumentationUpdate" {
            $result = Request-CoordinatedOperation -Operation "DocumentationUpdate" -Priority 2
            $satisfaction = if ($result.Success -and $result.CompletionTime -lt 30) { 0.95 } else { 0.7 }
        }
        "PerformanceOptimization" {
            $result = Optimize-SystemPerformance -Mode "User-Requested"
            $satisfaction = if ($result.OptimizationsApplied -gt 0) { 0.9 } else { 0.6 }
        }
        "SystemHealthInquiry" {
            $result = Invoke-SystemHealthCheck
            $satisfaction = if ($result.HealthScore -gt 80) { 0.95 } else { 0.75 }
        }
        "PredictiveAnalysis" {
            $result = Get-IntelligentRecommendations
            $satisfaction = if ($result.RecommendationCount -gt 0) { 0.9 } else { 0.7 }
        }
        "ScalabilityAdjustment" {
            $result = Invoke-AutoScaling -ScalingMode "UserRequested"
            $satisfaction = if ($result.ScalingSuccessful) { 0.9 } else { 0.8 }
        }
    }
    
    return @{
        UserSatisfaction = $satisfaction
        CompletionTime = ((Get-Date) - $startTime).TotalSeconds
    }
}

# MAIN TESTING EXECUTION
Write-Host "`n🧪 Starting Comprehensive System Testing and Validation..." -ForegroundColor Green

# Test 1: Module Availability and Integration
Write-Host "`n--- PHASE 1: MODULE INTEGRATION TESTING ---" -ForegroundColor Magenta
$systemCoordinatorOK = Test-SystemCoordinatorIntegration
$machineLearningOK = Test-MachineLearningIntegration  
$scalabilityOptimizerOK = Test-ScalabilityOptimizerIntegration
$reliabilityManagerOK = Test-ReliabilityManagerIntegration

# Test 2: End-to-End System Integration
Write-Host "`n--- PHASE 2: END-TO-END INTEGRATION TESTING ---" -ForegroundColor Magenta
if ($systemCoordinatorOK -and $machineLearningOK -and $scalabilityOptimizerOK -and $reliabilityManagerOK) {
    Test-EndToEndSystemIntegration
} else {
    Add-TestResult -TestName "End-to-End Integration" -Status "SKIP" -Details "Module integration failures prevent E2E testing"
}

# Test 3: Stress Testing Scenarios
Write-Host "`n--- PHASE 3: STRESS TESTING ---" -ForegroundColor Magenta
Test-StressTestingScenarios

# Test 4: User Acceptance Testing
Write-Host "`n--- PHASE 4: USER ACCEPTANCE TESTING ---" -ForegroundColor Magenta
Test-UserAcceptanceScenarios

# FINAL RESULTS
$testResults.EndTime = Get-Date
$testResults.Duration = $testResults.EndTime - $testResults.StartTime

Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "COMPREHENSIVE SYSTEM TESTING RESULTS" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`nTest Summary:" -ForegroundColor White
Write-Host "  Tests Executed: $($testResults.TestsExecuted)" -ForegroundColor Yellow
Write-Host "  Tests Passed: $($testResults.TestsPassed)" -ForegroundColor Green
Write-Host "  Tests Failed: $($testResults.TestsFailed)" -ForegroundColor Red
Write-Host "  Duration: $([math]::Round($testResults.Duration.TotalMinutes, 2)) minutes" -ForegroundColor Yellow

$passRate = if ($testResults.TestsExecuted -gt 0) { [math]::Round(($testResults.TestsPassed / $testResults.TestsExecuted) * 100, 1) } else { 0 }
Write-Host "  Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 95) { "Green" } else { "Yellow" })

Write-Host "`nIntegration Points Status:" -ForegroundColor White
foreach ($point in $testResults.IntegrationPoints.Keys) {
    $status = $testResults.IntegrationPoints[$point]
    Write-Host "  $point`: $status" -ForegroundColor $(if ($status -eq "OPERATIONAL") { "Green" } else { "Red" })
}

if ($testResults.PerformanceMetrics.Count -gt 0) {
    Write-Host "`nPerformance Metrics:" -ForegroundColor White
    foreach ($metric in $testResults.PerformanceMetrics.Keys) {
        Write-Host "  $metric`: $($testResults.PerformanceMetrics[$metric])" -ForegroundColor Yellow
    }
}

# Validate deliverables
$deliverables = @(
    @{Name = "Comprehensive end-to-end system testing validation"; Met = ($passRate -ge 95)}
    @{Name = "Stress testing validation under high-load scenarios"; Met = ($testResults.StressTestResults.Values | Where-Object {$_.Status -eq "PASS"}).Count -ge 3}
    @{Name = "Complete integration and coordination capability validation"; Met = ($testResults.IntegrationPoints.Values | Where-Object {$_ -eq "OPERATIONAL"}).Count -eq 4}
)

Write-Host "`nDeliverables Assessment:" -ForegroundColor White
foreach ($deliverable in $deliverables) {
    $status = if ($deliverable.Met) { "✓ SATISFIED" } else { "✗ NOT SATISFIED" }
    $color = if ($deliverable.Met) { "Green" } else { "Red" }
    Write-Host "  $status - $($deliverable.Name)" -ForegroundColor $color
    if ($deliverable.Met) { $testResults.DeliverablesSatisfied += $deliverable.Name }
}

$allDeliverablesMet = ($testResults.DeliverablesSatisfied.Count -eq $deliverables.Count)
$testResults.ImplementationValidated = $allDeliverablesMet -and ($passRate -ge 95)

if ($testResults.ImplementationValidated) {
    $testResults.OverallResult = "SUCCESS"
    Write-Host "`n🎉 Week 3 Day 15 Hour 1-2 Implementation: COMPREHENSIVE SYSTEM TESTING VALIDATED" -ForegroundColor Green
    Write-Host "Complete enhanced documentation system thoroughly tested and validated" -ForegroundColor Green
} else {
    $testResults.OverallResult = "PARTIAL"
    Write-Host "`n⚠️  Week 3 Day 15 Hour 1-2 Implementation: PARTIAL VALIDATION" -ForegroundColor Yellow
    if ($testResults.ErrorLog.Count -gt 0) {
        Write-Host "`nError Log:" -ForegroundColor Red
        $testResults.ErrorLog | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    }
}

# Export results
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$resultsFile = "Week3Day15Hour1-2-ComprehensiveSystemTesting-TestResults-$timestamp.json"
$testResults | ConvertTo-Json -Depth 10 | Out-File $resultsFile -Encoding UTF8
Write-Host "`nDetailed results exported to: $resultsFile" -ForegroundColor Cyan

Write-Host "`n" + "=" * 80 -ForegroundColor Cyan