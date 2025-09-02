#Requires -Version 5.1

<#
.SYNOPSIS
Comprehensive test suite for Multi-Step Analysis Orchestration (Week 1 Day 1 Hour 5-6)

.DESCRIPTION
Tests sophisticated multi-step analysis orchestration with parallel worker coordination,
AI enhancement, result synthesis, and performance monitoring framework.

.NOTES
Author: Unity-Claude-Automation System
Version: 1.0.0
Phase: Week 1 Day 1 Hour 5-6 - Multi-Step Analysis Orchestration
Dependencies: Unity-Claude-MultiStepOrchestrator, Unity-Claude-LangGraphBridge modules
Expected Deliverables: Multi-step orchestrator workflow, worker coordination, performance framework
#>

param(
    [Parameter()]
    [switch]$SaveResults = $true,
    
    [Parameter()]
    [switch]$ParallelProcessing = $true,
    
    [Parameter()]
    [switch]$PerformanceMonitoring = $true,
    
    [Parameter()]
    [string]$ResultsPath = ".\MultiStepOrchestration-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

# Initialize test results structure
$TestResults = @{
    StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    TestSuite = "Multi-Step Analysis Orchestration (Week 1 Day 1 Hour 5-6)"
    Tests = @()
    TestCategories = @{
        ModuleLoading = @()
        WorkflowConfiguration = @()
        ParallelCoordination = @()
        AIEnhancement = @()
        ResultSynthesis = @()
        PerformanceMonitoring = @()
        EndToEndIntegration = @()
    }
}

function Add-TestResult {
    param($TestName, $Category, $Passed, $Details, $Data = $null, $Duration = $null)
    
    $result = @{
        TestName = $TestName
        Category = $Category
        Passed = $Passed
        Details = $Details
        Data = $Data
        Duration = $Duration
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    }
    
    $TestResults.Tests += $result
    $TestResults.TestCategories.$Category += $result
    
    $status = if ($Passed) { "[PASS]" } else { "[FAIL]" }
    $color = if ($Passed) { "Green" } else { "Red" }
    Write-Host "  $status $TestName - $Details" -ForegroundColor $color
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Multi-Step Analysis Orchestration Test Suite" -ForegroundColor Cyan
Write-Host "Week 1 Day 1 Hour 5-6: Multi-Step Analysis Orchestration" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

#region Module Loading Tests

Write-Host "`n[TEST CATEGORY] Module Loading..." -ForegroundColor Yellow

try {
    Write-Host "Loading Unity-Claude-MultiStepOrchestrator module..." -ForegroundColor White
    Import-Module -Name ".\Unity-Claude-MultiStepOrchestrator.psm1" -Force
    $orchestratorFunctions = (Get-Module -Name "Unity-Claude-MultiStepOrchestrator").ExportedCommands.Keys
    $expectedFunctions = @('Invoke-MultiStepAnalysisOrchestration', 'Initialize-OrchestrationContext', 'Invoke-ParallelAnalysisWorkers', 'Get-BottleneckAnalysis')
    $missingFunctions = $expectedFunctions | Where-Object { $_ -notin $orchestratorFunctions }
    
    Add-TestResult -TestName "MultiStepOrchestrator Module Loading" -Category "ModuleLoading" -Passed ($missingFunctions.Count -eq 0) -Details "Functions: $($orchestratorFunctions.Count), Expected: $($expectedFunctions.Count), Missing: $($missingFunctions.Count)" -Data @{
        ExportedFunctions = $orchestratorFunctions
        MissingFunctions = $missingFunctions
    }
}
catch {
    Add-TestResult -TestName "MultiStepOrchestrator Module Loading" -Category "ModuleLoading" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Loading prerequisite modules..." -ForegroundColor White
    Import-Module -Name ".\Unity-Claude-LangGraphBridge.psm1" -Force -ErrorAction SilentlyContinue
    Import-Module -Name ".\Modules\Unity-Claude-CPG\Core\Predictive-Maintenance.psm1" -Force -ErrorAction SilentlyContinue
    Import-Module -Name ".\Modules\Unity-Claude-CPG\Core\Predictive-Evolution.psm1" -Force -ErrorAction SilentlyContinue
    
    $prerequisiteModules = @("Unity-Claude-LangGraphBridge", "Predictive-Maintenance", "Predictive-Evolution")
    $loadedModules = $prerequisiteModules | Where-Object { Get-Module -Name $_ -ErrorAction SilentlyContinue }
    
    Add-TestResult -TestName "Prerequisite Modules Loading" -Category "ModuleLoading" -Passed ($loadedModules.Count -eq $prerequisiteModules.Count) -Details "Loaded: $($loadedModules.Count)/$($prerequisiteModules.Count) modules" -Data @{
        ExpectedModules = $prerequisiteModules
        LoadedModules = $loadedModules
    }
}
catch {
    Add-TestResult -TestName "Prerequisite Modules Loading" -Category "ModuleLoading" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Workflow Configuration Tests

Write-Host "`n[TEST CATEGORY] Workflow Configuration..." -ForegroundColor Yellow

try {
    Write-Host "Testing multi-step workflow configuration file..." -ForegroundColor White
    $configPath = ".\MultiStep-Orchestrator-Workflows.json"
    $configExists = Test-Path $configPath
    
    if ($configExists) {
        $workflowConfig = Get-Content $configPath | ConvertFrom-Json
        $workflows = $workflowConfig.workflows.PSObject.Properties.Name
        $expectedWorkflows = @('comprehensive_analysis_orchestration', 'parallel_worker_coordination')
        $missingWorkflows = $expectedWorkflows | Where-Object { $_ -notin $workflows }
        
        Add-TestResult -TestName "Multi-Step Workflow Configuration" -Category "WorkflowConfiguration" -Passed ($missingWorkflows.Count -eq 0) -Details "Workflows: $($workflows.Count), Expected: $($expectedWorkflows.Count), Missing: $($missingWorkflows.Count)" -Data @{
            ConfigurationFile = $configPath
            AvailableWorkflows = $workflows
            MissingWorkflows = $missingWorkflows
        }
    }
    else {
        Add-TestResult -TestName "Multi-Step Workflow Configuration" -Category "WorkflowConfiguration" -Passed $false -Details "Configuration file not found: $configPath"
    }
}
catch {
    Add-TestResult -TestName "Multi-Step Workflow Configuration" -Category "WorkflowConfiguration" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing orchestrator workflow structure..." -ForegroundColor White
    $workflowConfig = Get-Content ".\MultiStep-Orchestrator-Workflows.json" | ConvertFrom-Json
    $orchestratorWorkflow = $workflowConfig.workflows.comprehensive_analysis_orchestration
    $workflowValid = ($orchestratorWorkflow.workflow_steps.Count -ge 5 -and $orchestratorWorkflow.workers.Count -ge 3)
    
    Add-TestResult -TestName "Orchestrator Workflow Structure" -Category "WorkflowConfiguration" -Passed $workflowValid -Details "Steps: $($orchestratorWorkflow.workflow_steps.Count), Workers: $($orchestratorWorkflow.workers.Count), Valid: $workflowValid" -Data @{
        WorkflowSteps = $orchestratorWorkflow.workflow_steps.Count
        WorkerCount = $orchestratorWorkflow.workers.Count
        WorkflowType = $orchestratorWorkflow.workflow_type
    }
}
catch {
    Add-TestResult -TestName "Orchestrator Workflow Structure" -Category "WorkflowConfiguration" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Parallel Coordination Tests

if ($ParallelProcessing) {
    Write-Host "`n[TEST CATEGORY] Parallel Coordination..." -ForegroundColor Yellow
    
    try {
        Write-Host "Testing orchestration context initialization..." -ForegroundColor White
        $testModules = @("Predictive-Maintenance", "Predictive-Evolution")
        $startTime = Get-Date
        $context = Initialize-OrchestrationContext -OrchestrationId "test-orchestration" -TargetModules $testModules -AnalysisScope @{ depth = "test" }
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        
        $contextValid = ($context.OrchestrationId -and $context.TargetModules.Count -eq $testModules.Count)
        
        Add-TestResult -TestName "Orchestration Context Initialization" -Category "ParallelCoordination" -Passed $contextValid -Details "Context initialized in $([math]::Round($duration, 2))ms, Modules: $($context.TargetModules.Count)" -Duration $duration -Data @{
            OrchestrationId = $context.OrchestrationId
            TargetModulesCount = $context.TargetModules.Count
            HasResourceBaseline = ($context.ResourceBaseline -ne $null)
        }
    }
    catch {
        Add-TestResult -TestName "Orchestration Context Initialization" -Category "ParallelCoordination" -Passed $false -Details "Exception: $($_.Exception.Message)"
    }
    
    try {
        Write-Host "Testing parallel worker coordination..." -ForegroundColor White
        $testContext = @{
            OrchestrationId = "test-parallel"
            TargetModules = @("Test-Module-1", "Test-Module-2")
            ResourceBaseline = @{ CpuUsage = 20; MemoryAvailableMB = 2048 }
        }
        
        $startTime = Get-Date
        $parallelResults = Invoke-ParallelAnalysisWorkers -Context $testContext -EnhancementConfig @{} -ParallelProcessing $true
        $duration = ((Get-Date) - $startTime).TotalSeconds
        
        $coordinationSuccessful = ($parallelResults -ne $null -and $parallelResults.Keys.Count -gt 0)
        
        Add-TestResult -TestName "Parallel Worker Coordination" -Category "ParallelCoordination" -Passed $coordinationSuccessful -Details "Coordination completed in $([math]::Round($duration, 2))s, Results: $($parallelResults.Keys.Count)" -Duration $duration -Data @{
            ResultsCount = $parallelResults.Keys.Count
            CoordinationTime = $duration
            WorkerTypes = ($parallelResults.Values | ForEach-Object { $_.WorkerId } | Sort-Object -Unique)
        }
    }
    catch {
        Add-TestResult -TestName "Parallel Worker Coordination" -Category "ParallelCoordination" -Passed $false -Details "Exception: $($_.Exception.Message)"
    }
}
else {
    Write-Host "`n[TEST CATEGORY] Parallel Coordination - SKIPPED (ParallelProcessing disabled)" -ForegroundColor DarkYellow
}

#endregion

#region AI Enhancement Tests

Write-Host "`n[TEST CATEGORY] AI Enhancement..." -ForegroundColor Yellow

try {
    Write-Host "Testing AI enhancement worker..." -ForegroundColor White
    $testAnalysisResults = @{
        "test_analysis" = @{
            Type = "test_analysis"
            Data = @{ TestData = "Sample analysis result" }
            Status = "completed"
            WorkerId = "TestWorker"
        }
    }
    $testContext = @{ OrchestrationId = "test-ai-enhancement" }
    
    $startTime = Get-Date
    $enhancedResults = Invoke-AIEnhancementWorker -AnalysisResults $testAnalysisResults -Context $testContext
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    
    $enhancementSuccessful = ($enhancedResults -ne $null -and $enhancedResults.Keys.Count -gt 0)
    
    Add-TestResult -TestName "AI Enhancement Worker" -Category "AIEnhancement" -Passed $enhancementSuccessful -Details "Enhancement completed in $([math]::Round($duration, 2))ms, Results: $($enhancedResults.Keys.Count)" -Duration $duration -Data @{
        InputResults = $testAnalysisResults.Keys.Count
        OutputResults = $enhancedResults.Keys.Count
        EnhancementTypes = ($enhancedResults.Values | ForEach-Object { $_.Type } | Sort-Object -Unique)
    }
}
catch {
    Add-TestResult -TestName "AI Enhancement Worker" -Category "AIEnhancement" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Result Synthesis Tests

Write-Host "`n[TEST CATEGORY] Result Synthesis..." -ForegroundColor Yellow

try {
    Write-Host "Testing synthesis worker..." -ForegroundColor White
    $testEnhancedResults = @{
        "enhanced_test_1" = @{
            Type = "maintenance_analysis_enhanced"
            Data = @{ AIInsights = @{ PatternRecognition = "Test pattern"; Recommendations = @("Test rec 1"); ConfidenceScore = 0.8 } }
            Status = "ai_enhanced"
        }
        "enhanced_test_2" = @{
            Type = "evolution_analysis_enhanced"  
            Data = @{ AIInsights = @{ PatternRecognition = "Test pattern 2"; Recommendations = @("Test rec 2"); ConfidenceScore = 0.9 } }
            Status = "ai_enhanced"
        }
    }
    $testContext = @{ OrchestrationId = "test-synthesis" }
    
    $startTime = Get-Date
    $synthesisResults = Invoke-SynthesisWorker -EnhancedResults $testEnhancedResults -Context $testContext
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    
    $synthesisSuccessful = ($synthesisResults -ne $null -and $synthesisResults.CrossAnalysisInsights -and $synthesisResults.AggregatedRecommendations)
    
    Add-TestResult -TestName "Result Synthesis Worker" -Category "ResultSynthesis" -Passed $synthesisSuccessful -Details "Synthesis completed in $([math]::Round($duration, 2))ms, Insights generated: $($synthesisResults.CrossAnalysisInsights -ne $null)" -Duration $duration -Data @{
        HasCrossAnalysisInsights = ($synthesisResults.CrossAnalysisInsights -ne $null)
        AggregatedRecommendationsCount = if ($synthesisResults.AggregatedRecommendations) { $synthesisResults.AggregatedRecommendations.Count } else { 0 }
        QualityAssessment = $synthesisResults.QualityAssessment
    }
}
catch {
    Add-TestResult -TestName "Result Synthesis Worker" -Category "ResultSynthesis" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Performance Monitoring Tests

if ($PerformanceMonitoring) {
    Write-Host "`n[TEST CATEGORY] Performance Monitoring..." -ForegroundColor Yellow
    
    try {
        Write-Host "Testing resource baseline establishment..." -ForegroundColor White
        $startTime = Get-Date
        $resourceBaseline = Get-ResourceBaseline
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        
        $baselineValid = ($resourceBaseline -and $resourceBaseline.CpuUsage -ne $null -and $resourceBaseline.MemoryAvailableMB -ne $null)
        
        Add-TestResult -TestName "Resource Baseline Establishment" -Category "PerformanceMonitoring" -Passed $baselineValid -Details "Baseline established in $([math]::Round($duration, 2))ms, CPU: $($resourceBaseline.CpuUsage)%, Memory: $($resourceBaseline.MemoryAvailableMB)MB" -Duration $duration -Data $resourceBaseline
    }
    catch {
        Add-TestResult -TestName "Resource Baseline Establishment" -Category "PerformanceMonitoring" -Passed $false -Details "Exception: $($_.Exception.Message)"
    }
    
    try {
        Write-Host "Testing bottleneck detection framework..." -ForegroundColor White
        $testPerformanceData = @(
            @{ CpuUsage = 75; MemoryAvailable = 1024; Timestamp = Get-Date }
            @{ CpuUsage = 85; MemoryAvailable = 512; Timestamp = (Get-Date).AddSeconds(5) }
            @{ CpuUsage = 60; MemoryAvailable = 2048; Timestamp = (Get-Date).AddSeconds(10) }
        )
        
        $startTime = Get-Date
        $bottleneckAnalysis = Get-BottleneckAnalysis -PerformanceData $testPerformanceData
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        
        $analysisValid = ($bottleneckAnalysis -and $bottleneckAnalysis.DetectedBottlenecks -and $bottleneckAnalysis.OptimizationOpportunities)
        
        Add-TestResult -TestName "Bottleneck Detection Framework" -Category "PerformanceMonitoring" -Passed $analysisValid -Details "Analysis completed in $([math]::Round($duration, 2))ms, Bottlenecks: $($bottleneckAnalysis.DetectedBottlenecks.Count)" -Duration $duration -Data @{
            DetectedBottlenecks = $bottleneckAnalysis.DetectedBottlenecks
            OptimizationOpportunities = $bottleneckAnalysis.OptimizationOpportunities
        }
    }
    catch {
        Add-TestResult -TestName "Bottleneck Detection Framework" -Category "PerformanceMonitoring" -Passed $false -Details "Exception: $($_.Exception.Message)"
    }
}
else {
    Write-Host "`n[TEST CATEGORY] Performance Monitoring - SKIPPED (PerformanceMonitoring disabled)" -ForegroundColor DarkYellow
}

#endregion

#region End-to-End Integration Tests

Write-Host "`n[TEST CATEGORY] End-to-End Integration..." -ForegroundColor Yellow

try {
    Write-Host "Testing complete multi-step orchestration..." -ForegroundColor White
    $testModules = @("Predictive-Maintenance", "Predictive-Evolution")
    $analysisScope = @{ depth = "test_orchestration"; timeframe = "7_days" }
    $enhancementConfig = @{ ai_models = @("Test-Model"); enhancement_level = "basic" }
    
    $startTime = Get-Date
    $orchestrationResult = Invoke-MultiStepAnalysisOrchestration -AnalysisScope $analysisScope -TargetModules $testModules -EnhancementConfig $enhancementConfig -ParallelProcessing $ParallelProcessing
    $duration = ((Get-Date) - $startTime).TotalSeconds
    
    $orchestrationSuccessful = ($orchestrationResult -ne $null -and $orchestrationResult.ReportMetadata -and $orchestrationResult.ExecutiveSummary)
    
    Add-TestResult -TestName "Complete Multi-Step Orchestration" -Category "EndToEndIntegration" -Passed $orchestrationSuccessful -Details "Orchestration completed in $([math]::Round($duration, 2))s, Report generated: $($orchestrationResult.ReportMetadata -ne $null)" -Duration $duration -Data @{
        ExecutionTime = $duration
        HasReportMetadata = ($orchestrationResult.ReportMetadata -ne $null)
        HasExecutiveSummary = ($orchestrationResult.ExecutiveSummary -ne $null)
        HasRecommendations = ($orchestrationResult.Recommendations -ne $null)
        RecommendationCount = if ($orchestrationResult.Recommendations.Immediate) { $orchestrationResult.Recommendations.Immediate.Count } else { 0 }
    }
}
catch {
    Add-TestResult -TestName "Complete Multi-Step Orchestration" -Category "EndToEndIntegration" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing orchestration performance against targets..." -ForegroundColor White
    # Test against Week 1 success metrics: AI-enhanced analysis < 30 seconds response time
    $lastTest = $TestResults.Tests | Where-Object { $_.TestName -eq "Complete Multi-Step Orchestration" } | Select-Object -Last 1
    $performanceTarget = 30  # seconds
    $actualPerformance = if ($lastTest -and $lastTest.Duration) { $lastTest.Duration } else { 999 }
    
    $performanceTargetMet = ($actualPerformance -le $performanceTarget)
    
    Add-TestResult -TestName "Performance Target Validation" -Category "EndToEndIntegration" -Passed $performanceTargetMet -Details "Target: <${performanceTarget}s, Actual: $([math]::Round($actualPerformance, 2))s, Met: $performanceTargetMet" -Data @{
        PerformanceTarget = $performanceTarget
        ActualPerformance = $actualPerformance
        TargetMet = $performanceTargetMet
        PerformanceRatio = $actualPerformance / $performanceTarget
    }
}
catch {
    Add-TestResult -TestName "Performance Target Validation" -Category "EndToEndIntegration" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Results Summary and Analysis

Write-Host "`n[RESULTS SUMMARY]" -ForegroundColor Cyan

# Calculate summary statistics
$totalTests = $TestResults.Tests.Count
$passedTests = ($TestResults.Tests | Where-Object { $_.Passed }).Count
$failedTests = $totalTests - $passedTests
$passRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 1) } else { 0 }

# Category breakdown
$categoryBreakdown = @{}
foreach ($category in $TestResults.TestCategories.Keys) {
    $categoryTests = $TestResults.TestCategories.$category
    $categoryPassed = ($categoryTests | Where-Object { $_.Passed }).Count
    $categoryTotal = $categoryTests.Count
    $categoryPassRate = if ($categoryTotal -gt 0) { [math]::Round(($categoryPassed / $categoryTotal) * 100, 1) } else { 0 }
    
    $categoryBreakdown[$category] = @{
        Passed = $categoryPassed
        Total = $categoryTotal
        Failed = $categoryTotal - $categoryPassed
        PassRate = $categoryPassRate
    }
    
    Write-Host "  $category`: $categoryPassed/$categoryTotal ($categoryPassRate%)" -ForegroundColor $(if ($categoryPassRate -ge 80) { "Green" } else { "Yellow" })
}

# Add summary to results
$TestResults.Summary = @{
    TotalTests = $totalTests
    PassedTests = $passedTests
    FailedTests = $failedTests
    PassRate = "$passRate%"
    Duration = [string]((Get-Date) - [DateTime]::Parse($TestResults.StartTime))
    Categories = $categoryBreakdown
}
$TestResults.EndTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"

Write-Host "`nOVERALL RESULTS:" -ForegroundColor White
Write-Host "  Total Tests: $totalTests" -ForegroundColor White
Write-Host "  Passed: $passedTests" -ForegroundColor Green
Write-Host "  Failed: $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Green" })
Write-Host "  Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 80) { "Green" } elseif ($passRate -ge 60) { "Yellow" } else { "Red" })

# Week 1 Day 1 Hour 5-6 Success Criteria Assessment
Write-Host "`n[SUCCESS CRITERIA ASSESSMENT]" -ForegroundColor Cyan
Write-Host "Week 1 Day 1 Hour 5-6 Deliverable Validation:" -ForegroundColor White

$successCriteria = @{
    MultiStepOrchestrator = ($TestResults.Tests | Where-Object { $_.TestName -eq "Orchestrator Workflow Structure" -and $_.Passed }).Count -gt 0
    WorkerCoordination = ($TestResults.Tests | Where-Object { $_.TestName -eq "Parallel Worker Coordination" -and $_.Passed }).Count -gt 0
    PerformanceFramework = ($TestResults.Tests | Where-Object { $_.TestName -eq "Bottleneck Detection Framework" -and $_.Passed }).Count -gt 0
    EndToEndAnalysis = ($TestResults.Tests | Where-Object { $_.TestName -eq "Complete Multi-Step Orchestration" -and $_.Passed }).Count -gt 0
}

foreach ($criterion in $successCriteria.Keys) {
    $status = if ($successCriteria[$criterion]) { "[ACHIEVED]" } else { "[PENDING]" }
    $color = if ($successCriteria[$criterion]) { "Green" } else { "Yellow" }
    Write-Host "  $status $criterion" -ForegroundColor $color
}

$overallSuccess = ($successCriteria.Values | Where-Object { $_ }).Count -eq $successCriteria.Keys.Count
$successStatus = if ($overallSuccess) { "[SUCCESS]" } else { "[PARTIAL]" }
$successColor = if ($overallSuccess) { "Green" } else { "Yellow" }
Write-Host "`n$successStatus Hour 5-6 Success Criteria: $($successCriteria.Values | Where-Object { $_ }).Count/$($successCriteria.Keys.Count) achieved" -ForegroundColor $successColor

#endregion

#region Save Results

if ($SaveResults) {
    try {
        $TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $ResultsPath -Encoding UTF8
        Write-Host "`nTest results saved to: $ResultsPath" -ForegroundColor Green
        
        # Log to centralized log
        $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [MultiStepOrchestration] Hour 5-6 test completed - Pass rate: $passRate% ($passedTests/$totalTests) - Success criteria: $($successCriteria.Values | Where-Object { $_ }).Count/$($successCriteria.Keys.Count)"
        Add-Content -Path ".\unity_claude_automation.log" -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "Failed to save test results: $($_.Exception.Message)"
    }
}

#endregion

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "Multi-Step Analysis Orchestration Test Complete" -ForegroundColor Cyan
Write-Host "Pass Rate: $passRate% ($passedTests/$totalTests tests)" -ForegroundColor $(if ($passRate -ge 80) { "Green" } else { "Yellow" })
Write-Host "Hour 5-6 Implementation: $(if ($overallSuccess) { 'READY for Hour 7-8' } else { 'REQUIRES fixes before proceeding' })" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Yellow" })
Write-Host "============================================================" -ForegroundColor Cyan

# Return test results for further processing
return $TestResults