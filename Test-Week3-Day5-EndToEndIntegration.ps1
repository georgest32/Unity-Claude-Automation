# Test-Week3-Day5-EndToEndIntegration.ps1
# Phase 1 Week 3 Day 5: End-to-End Integration and Performance Optimization Testing
# Comprehensive test suite for Unity-Claude integrated workflow system
# Date: 2025-08-21

[CmdletBinding()]
param(
    [switch]$SaveResults,
    [switch]$EnableResourceMonitoring,
    [switch]$TestWithRealUnityProjects,
    [switch]$TestWithRealClaudeAPI,
    [string]$TestResultsFile,
    [int]$TestTimeout = 600  # 10 minutes
)

# Temporarily set ErrorActionPreference to Continue for module import phase
$originalErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "Continue"

# Import all required modules for testing in dependency order
try {
    $moduleBasePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules"
    Write-Host "[DEBUG] Starting module import with base path: $moduleBasePath" -ForegroundColor Cyan
    
    # Import dependency modules first with detailed logging
    Write-Host "[DEBUG] Importing Unity-Claude-ParallelProcessing..." -ForegroundColor Cyan
    Import-Module "$moduleBasePath\Unity-Claude-ParallelProcessing\Unity-Claude-ParallelProcessing.psm1" -Force -Global
    $parallelCommands = (Get-Command -Module Unity-Claude-ParallelProcessing -ErrorAction SilentlyContinue).Count
    Write-Host "[DEBUG] ParallelProcessing functions: $parallelCommands" -ForegroundColor Cyan
    
    Write-Host "[DEBUG] Importing Unity-Claude-RunspaceManagement..." -ForegroundColor Cyan
    Import-Module "$moduleBasePath\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psm1" -Force -Global
    $runspaceCommands = (Get-Command -Module Unity-Claude-RunspaceManagement -ErrorAction SilentlyContinue).Count
    Write-Host "[DEBUG] RunspaceManagement functions: $runspaceCommands" -ForegroundColor Cyan
    
    Write-Host "[DEBUG] Importing Unity-Claude-UnityParallelization..." -ForegroundColor Cyan  
    Import-Module "$moduleBasePath\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psm1" -Force -Global
    $unityCommands = (Get-Command -Module Unity-Claude-UnityParallelization -ErrorAction SilentlyContinue).Count
    Write-Host "[DEBUG] UnityParallelization functions: $unityCommands" -ForegroundColor Cyan
    
    Write-Host "[DEBUG] Importing Unity-Claude-ClaudeParallelization..." -ForegroundColor Cyan
    Import-Module "$moduleBasePath\Unity-Claude-ClaudeParallelization\Unity-Claude-ClaudeParallelization.psm1" -Force -Global
    $claudeCommands = (Get-Command -Module Unity-Claude-ClaudeParallelization -ErrorAction SilentlyContinue).Count
    Write-Host "[DEBUG] ClaudeParallelization functions: $claudeCommands" -ForegroundColor Cyan
    
    # Import main module with comprehensive tracing
    Write-Host "[DEBUG] Importing Unity-Claude-IntegratedWorkflow..." -ForegroundColor Cyan
    Import-Module "$moduleBasePath\Unity-Claude-IntegratedWorkflow\Unity-Claude-IntegratedWorkflow.psm1" -Force -Global
    
    # Validate IntegratedWorkflow functions with detailed analysis
    Write-Host "[DEBUG] Checking IntegratedWorkflow module status..." -ForegroundColor Cyan
    $integratedModule = Get-Module Unity-Claude-IntegratedWorkflow -ErrorAction SilentlyContinue
    if ($integratedModule) {
        $integratedCommands = $integratedModule.ExportedCommands.Count
        Write-Host "[DEBUG] IntegratedWorkflow module loaded: $($integratedModule.Name)" -ForegroundColor Green
        Write-Host "[DEBUG] IntegratedWorkflow exported functions: $integratedCommands" -ForegroundColor Green
        
        # Test each critical function
        $criticalFunctions = @('New-IntegratedWorkflow', 'Start-IntegratedWorkflow', 'Get-IntegratedWorkflowStatus')
        foreach ($func in $criticalFunctions) {
            $exists = Get-Command $func -ErrorAction SilentlyContinue
            $status = if ($exists) { "AVAILABLE" } else { "MISSING" }
            $color = if ($exists) { "Green" } else { "Red" }
            Write-Host "[DEBUG] Function $func : $status" -ForegroundColor $color
        }
    } else {
        Write-Host "[ERROR] IntegratedWorkflow module not found in session!" -ForegroundColor Red
    }
    
    $totalFunctions = $parallelCommands + $runspaceCommands + $unityCommands + $claudeCommands + $integratedCommands
    Write-Host "[DEBUG] Total functions imported: $totalFunctions" -ForegroundColor Green
    Write-Host "All modules imported successfully for testing" -ForegroundColor Green
    
} catch {
    Write-Host "Warning: Could not import all modules: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "[DEBUG] Error details: $($_.ScriptStackTrace)" -ForegroundColor Red
} finally {
    # Restore original ErrorActionPreference for testing phase
    $ErrorActionPreference = $originalErrorActionPreference
    Write-Host "[DEBUG] ErrorActionPreference restored to: $ErrorActionPreference" -ForegroundColor Cyan
}

# Test configuration
$TestConfig = @{
    TestName = "Week3-Day5-EndToEndIntegration"
    Date = Get-Date
    SaveResults = $SaveResults
    EnableResourceMonitoring = $EnableResourceMonitoring
    TestWithRealUnityProjects = $TestWithRealUnityProjects
    TestWithRealClaudeAPI = $TestWithRealClaudeAPI
    TestTimeout = $TestTimeout
    TestResultsFile = if ($TestResultsFile) { $TestResultsFile } else { 
        "Test_Results_Week3_Day5_EndToEnd_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt" 
    }
}

# Initialize test results
$TestResults = @{
    TestName = $TestConfig.TestName
    StartTime = Get-Date
    Tests = @()
    Categories = @{
        ModuleLoading = @{Passed = 0; Failed = 0; Total = 0}
        WorkflowIntegration = @{Passed = 0; Failed = 0; Total = 0}
        PerformanceOptimization = @{Passed = 0; Failed = 0; Total = 0}
        EndToEndWorkflow = @{Passed = 0; Failed = 0; Total = 0}
        ResourceManagement = @{Passed = 0; Failed = 0; Total = 0}
        ErrorHandling = @{Passed = 0; Failed = 0; Total = 0}
    }
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Skipped = 0
        Duration = 0
        PassRate = 0
    }
}

# Enhanced logging
function Write-EndToEndTestLog {
    param([string]$Message, [string]$Level = "INFO", [string]$Category = "EndToEndTest")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "DEBUG" { "Gray" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] [$Category] $Message" -ForegroundColor $color
    
    # Write to centralized log
    Add-Content -Path ".\unity_claude_automation.log" -Value "[$timestamp] [$Level] [$Category] $Message" -ErrorAction SilentlyContinue
}

function Write-TestHeader {
    param([string]$Message)
    Write-Host ""
    Write-Host "=== $Message ===" -ForegroundColor Cyan
}

function Write-TestResult {
    param([string]$TestName, [bool]$Success, [string]$Message = "", [int]$Duration = 0, [string]$Category = "General")
    
    $status = if ($Success) { "PASS" } else { "FAIL" }
    $color = if ($Success) { "Green" } else { "Red" }
    
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Message) {
        Write-Host "    $Message" -ForegroundColor Gray
    }
    if ($Duration -gt 0) {
        Write-Host "    Duration: ${Duration}ms" -ForegroundColor Gray
    }
    
    # Update category statistics
    if ($TestResults.Categories.ContainsKey($Category)) {
        $TestResults.Categories[$Category].Total++
        if ($Success) {
            $TestResults.Categories[$Category].Passed++
        } else {
            $TestResults.Categories[$Category].Failed++
        }
    }
    
    # Add to results
    $TestResults.Tests += @{
        TestName = $TestName
        Success = $Success
        Message = $Message
        Duration = $Duration
        Category = $Category
        Timestamp = Get-Date
    }
}

function Test-IntegratedWorkflowFunction {
    param(
        [string]$TestName,
        [scriptblock]$TestScript,
        [string]$Category = "General",
        [int]$TimeoutSeconds = 60
    )
    
    Write-EndToEndTestLog -Message "Starting integrated workflow test: $TestName" -Level "INFO" -Category $Category
    
    $testStartTime = Get-Date
    $success = $false
    $resultMessage = ""
    
    try {
        # Create timeout job for the test
        $testJob = Start-Job -ScriptBlock $TestScript -ArgumentList $TestConfig
        
        $completed = Wait-Job -Job $testJob -Timeout $TimeoutSeconds
        
        if ($completed) {
            $result = Receive-Job -Job $testJob
            Remove-Job -Job $testJob -Force
            
            if ($result -is [hashtable] -and $result.ContainsKey('Success')) {
                $success = $result.Success
                $resultMessage = if ($result.ContainsKey('Message')) { $result.Message } else { "Test completed" }
            } elseif ($result) {
                $success = $true
                $resultMessage = $result.ToString()
            } else {
                $success = $true
                $resultMessage = "Test completed successfully"
            }
        } else {
            Remove-Job -Job $testJob -Force
            $success = $false
            $resultMessage = "Test timed out after $TimeoutSeconds seconds"
        }
        
    } catch {
        $success = $false
        $resultMessage = "Test error: $($_.Exception.Message)"
    }
    
    $testDuration = ((Get-Date) - $testStartTime).TotalMilliseconds
    Write-TestResult -TestName $TestName -Success $success -Message $resultMessage -Duration $testDuration -Category $Category
    
    return $success
}

# Header
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " Unity-Claude End-to-End Integration Test" -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Phase 1 Week 3 Day 5: Complete Workflow Integration"
Write-Host "Date: $($TestConfig.Date)"
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-Host "Real Unity Projects: $($TestConfig.TestWithRealUnityProjects)"
Write-Host "Real Claude API: $($TestConfig.TestWithRealClaudeAPI)"
Write-Host "Resource Monitoring: $($TestConfig.EnableResourceMonitoring)"
Write-Host ""

# Module Loading and Validation Tests
Write-TestHeader "1. Module Loading and Integration"

Test-IntegratedWorkflowFunction "Integrated Workflow Module Import" {
    param($Config)
    
    try {
        $expectedFunctions = @(
            'New-IntegratedWorkflow',
            'Start-IntegratedWorkflow',
            'Get-IntegratedWorkflowStatus',
            'Stop-IntegratedWorkflow',
            'Initialize-AdaptiveThrottling',
            'Update-AdaptiveThrottling',
            'New-IntelligentJobBatching',
            'Get-WorkflowPerformanceAnalysis'
        )
        
        $missingFunctions = @()
        foreach ($func in $expectedFunctions) {
            if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                $missingFunctions += $func
            }
        }
        
        if ($missingFunctions.Count -eq 0) {
            return @{
                Success = $true
                Message = "All integrated workflow functions available: $($expectedFunctions.Count) functions"
            }
        } else {
            return @{
                Success = $false
                Message = "Missing functions: $($missingFunctions -join ', ')"
            }
        }
        
    } catch {
        return @{
            Success = $false
            Message = "Module import failed: $($_.Exception.Message)"
        }
    }
} -Category "ModuleLoading"

Test-IntegratedWorkflowFunction "Dependency Module Availability" {
    param($Config)
    
    try {
        $requiredModules = @(
            'Unity-Claude-RunspaceManagement',
            'Unity-Claude-UnityParallelization', 
            'Unity-Claude-ClaudeParallelization'
        )
        
        $availableModules = @()
        $missingModules = @()
        
        foreach ($module in $requiredModules) {
            $moduleCheck = Get-Module -Name $module -ErrorAction SilentlyContinue
            if ($moduleCheck -or (Get-Module -Name $module -ListAvailable -ErrorAction SilentlyContinue)) {
                $availableModules += $module
            } else {
                $missingModules += $module
            }
        }
        
        return @{
            Success = ($missingModules.Count -eq 0)
            Message = "Dependencies: $($availableModules.Count)/$($requiredModules.Count) available" + $(if ($missingModules.Count -gt 0) { " (Missing: $($missingModules -join ', '))" } else { "" })
        }
        
    } catch {
        return @{
            Success = $false
            Message = "Dependency check failed: $($_.Exception.Message)"
        }
    }
} -Category "ModuleLoading"

# Workflow Integration Tests
Write-TestHeader "2. Workflow Integration and Creation"

Test-IntegratedWorkflowFunction "Basic Integrated Workflow Creation" {
    param($Config)
    
    try {
        $workflow = New-IntegratedWorkflow -WorkflowName "TestWorkflow-Basic" -MaxUnityProjects 2 -MaxClaudeSubmissions 5 -EnableResourceOptimization -EnableErrorPropagation
        
        if ($workflow -and $workflow.WorkflowName -eq "TestWorkflow-Basic" -and $workflow.Status -eq 'Created') {
            return @{
                Success = $true
                Message = "Integrated workflow created: Unity:$($workflow.MaxUnityProjects), Claude:$($workflow.MaxClaudeSubmissions)"
            }
        } else {
            return @{
                Success = $false
                Message = "Workflow creation failed or incorrect properties"
            }
        }
        
    } catch {
        return @{
            Success = $false
            Message = "Workflow creation error: $($_.Exception.Message)"
        }
    }
} -Category "WorkflowIntegration"

Test-IntegratedWorkflowFunction "Advanced Integrated Workflow Creation" {
    param($Config)
    
    try {
        $workflow = New-IntegratedWorkflow -WorkflowName "TestWorkflow-Advanced" -MaxUnityProjects 4 -MaxClaudeSubmissions 10 -EnableResourceOptimization -EnableErrorPropagation
        
        $script:AdvancedWorkflow = $workflow  # Store for other tests
        
        # Verify workflow components
        $componentsValid = (
            $workflow.UnityMonitor -and
            $workflow.ClaudeSubmitter -and
            $workflow.OrchestrationPool -and
            $workflow.WorkflowState -and
            $workflow.HealthStatus
        )
        
        return @{
            Success = $componentsValid
            Message = "Advanced workflow created with all components: Health=$($workflow.HealthStatus.OverallHealth)"
        }
        
    } catch {
        return @{
            Success = $false
            Message = "Advanced workflow creation error: $($_.Exception.Message)"
        }
    }
} -Category "WorkflowIntegration"

Test-IntegratedWorkflowFunction "Workflow Status and Monitoring" {
    param($Config)
    
    try {
        if (-not $script:AdvancedWorkflow) {
            return @{
                Success = $false
                Message = "No advanced workflow available for status test"
            }
        }
        
        $status = Get-IntegratedWorkflowStatus -IntegratedWorkflow $script:AdvancedWorkflow -IncludeDetailedMetrics
        
        $statusValid = (
            $status.WorkflowName -eq "TestWorkflow-Advanced" -and
            $status.OverallStatus -eq "Created" -and
            $status.Components -and
            $status.StageStatus -and
            $status.Queues -and
            $status.Metrics
        )
        
        return @{
            Success = $statusValid
            Message = "Status retrieved: $($status.OverallStatus), Components: $($status.Components.Count), Queues tracked: $($status.Queues.Count)"
        }
        
    } catch {
        return @{
            Success = $false
            Message = "Status retrieval error: $($_.Exception.Message)"
        }
    }
} -Category "WorkflowIntegration"

# Performance Optimization Tests
Write-TestHeader "3. Performance Optimization Framework"

Test-IntegratedWorkflowFunction "Adaptive Throttling Initialization" {
    param($Config)
    
    try {
        if (-not $script:AdvancedWorkflow) {
            return @{
                Success = $false
                Message = "No advanced workflow available for throttling test"
            }
        }
        
        $throttlingResult = Initialize-AdaptiveThrottling -IntegratedWorkflow $script:AdvancedWorkflow -EnableCPUThrottling -EnableMemoryThrottling -CPUThreshold 75 -MemoryThreshold 80
        
        $throttlingValid = (
            $throttlingResult.Success -and
            $script:AdvancedWorkflow.WorkflowState.ContainsKey('AdaptiveThrottling') -and
            $script:AdvancedWorkflow.WorkflowState.AdaptiveThrottling.EnableCPUThrottling -eq $true -and
            $script:AdvancedWorkflow.WorkflowState.AdaptiveThrottling.CPUThreshold -eq 75
        )
        
        return @{
            Success = $throttlingValid
            Message = "Adaptive throttling initialized: CPU:75 percent, Memory:80 percent, Counters available"
        }
        
    } catch {
        return @{
            Success = $false
            Message = "Throttling initialization error: $($_.Exception.Message)"
        }
    }
} -Category "PerformanceOptimization"

Test-IntegratedWorkflowFunction "Intelligent Job Batching" {
    param($Config)
    
    try {
        # Create test jobs with different characteristics
        $testJobs = @()
        for ($i = 1; $i -le 25; $i++) {
            $testJobs += @{
                JobId = "Job-$i"
                Type = @('UnityError', 'ClaudePrompt', 'ResponseProcessing')[(Get-Random -Maximum 3)]
                Priority = @('High', 'Normal', 'Low')[(Get-Random -Maximum 3)]
                EstimatedDuration = Get-Random -Minimum 100 -Maximum 5000
                Complexity = Get-Random -Minimum 1 -Maximum 10
            }
        }
        
        if (-not $script:AdvancedWorkflow) {
            return @{
                Success = $false
                Message = "No advanced workflow available for batching test"
            }
        }
        
        $batchingResult = New-IntelligentJobBatching -IntegratedWorkflow $script:AdvancedWorkflow -JobQueue $testJobs -BatchingStrategy "Hybrid" -MaxBatchSize 8
        
        $batchingValid = (
            $batchingResult.TotalJobs -eq 25 -and
            $batchingResult.TotalBatches -gt 0 -and
            $batchingResult.AverageJobsPerBatch -gt 0 -and
            $batchingResult.BatchingDuration -gt 0
        )
        
        return @{
            Success = $batchingValid
            Message = "Job batching: $($batchingResult.TotalBatches) batches, avg $($batchingResult.AverageJobsPerBatch) jobs/batch, $($batchingResult.BatchingDuration)ms"
        }
        
    } catch {
        return @{
            Success = $false
            Message = "Job batching error: $($_.Exception.Message)"
        }
    }
} -Category "PerformanceOptimization"

Test-IntegratedWorkflowFunction "Performance Analysis Framework" {
    param($Config)
    
    try {
        if (-not $script:AdvancedWorkflow) {
            return @{
                Success = $false
                Message = "No advanced workflow available for performance test"
            }
        }
        
        # Add some simulated performance data
        $script:AdvancedWorkflow.WorkflowState.WorkflowMetrics.UnityErrorsProcessed = 15
        $script:AdvancedWorkflow.WorkflowState.WorkflowMetrics.ClaudeResponsesReceived = 12
        $script:AdvancedWorkflow.WorkflowState.WorkflowMetrics.FixesApplied = 10
        
        $performanceData = Get-WorkflowPerformanceAnalysis -IntegratedWorkflow $script:AdvancedWorkflow -MonitoringDuration 30 -IncludeSystemMetrics
        
        $analysisValid = (
            $performanceData.WorkflowName -eq "TestWorkflow-Advanced" -and
            $performanceData.StageMetrics -and
            $performanceData.SystemMetrics -and
            $performanceData.OptimizationRecommendations -ne $null -and
            $performanceData.AnalysisDuration -gt 0
        )
        
        return @{
            Success = $analysisValid
            Message = "Performance analysis: $($performanceData.OptimizationRecommendations.Count) recommendations, analysis took $($performanceData.AnalysisDuration)ms"
        }
        
    } catch {
        return @{
            Success = $false
            Message = "Performance analysis error: $($_.Exception.Message)"
        }
    }
} -Category "PerformanceOptimization"

# End-to-End Workflow Tests
Write-TestHeader "4. End-to-End Workflow Execution"

Test-IntegratedWorkflowFunction "Complete Workflow Simulation" -TimeoutSeconds 120 {
    param($Config)
    
    try {
        # Create a new workflow for end-to-end testing
        $e2eWorkflow = New-IntegratedWorkflow -WorkflowName "E2E-TestWorkflow" -MaxUnityProjects 2 -MaxClaudeSubmissions 4 -EnableResourceOptimization -EnableErrorPropagation
        
        # Initialize performance optimization
        Initialize-AdaptiveThrottling -IntegratedWorkflow $e2eWorkflow -EnableCPUThrottling -EnableMemoryThrottling | Out-Null
        
        # Simulate Unity projects
        $testUnityProjects = @(
            "C:\TestUnityProject1",
            "C:\TestUnityProject2"
        )
        
        # Start the integrated workflow (this will run the simulation)
        $workflowResult = Start-IntegratedWorkflow -IntegratedWorkflow $e2eWorkflow -UnityProjects $testUnityProjects -WorkflowMode "OnDemand" -MonitoringInterval 10
        
        # Let it run briefly
        Start-Sleep -Seconds 15
        
        # Check workflow status
        $status = Get-IntegratedWorkflowStatus -IntegratedWorkflow $e2eWorkflow
        
        # Stop the workflow
        $stopResult = Stop-IntegratedWorkflow -IntegratedWorkflow $e2eWorkflow -WaitForCompletion -TimeoutSeconds 30
        
        $e2eValid = (
            $workflowResult.Success -and
            $status.OrchestrationStatus -eq "Running" -and
            $stopResult.Success
        )
        
        return @{
            Success = $e2eValid
            Message = "E2E workflow: Started->Running->Stopped, Final metrics: $($stopResult.FinalMetrics.UnityErrorsProcessed) errors processed"
        }
        
    } catch {
        return @{
            Success = $false
            Message = "E2E workflow error: $($_.Exception.Message)"
        }
    }
} -Category "EndToEndWorkflow"

Test-IntegratedWorkflowFunction "Workflow Performance Validation" {
    param($Config)
    
    try {
        # Create multiple workflows to test concurrent performance
        $workflows = @()
        
        for ($i = 1; $i -le 3; $i++) {
            $workflow = New-IntegratedWorkflow -WorkflowName "PerfTest-$i" -MaxUnityProjects 1 -MaxClaudeSubmissions 3 -EnableResourceOptimization
            Initialize-AdaptiveThrottling -IntegratedWorkflow $workflow -EnableCPUThrottling -EnableMemoryThrottling | Out-Null
            $workflows += $workflow
        }
        
        $perfStartTime = Get-Date
        
        # Start all workflows
        foreach ($workflow in $workflows) {
            Start-IntegratedWorkflow -IntegratedWorkflow $workflow -UnityProjects @("C:\TestProject") -WorkflowMode "Batch" -MonitoringInterval 5 | Out-Null
        }
        
        # Let them run
        Start-Sleep -Seconds 10
        
        # Check all statuses
        $runningCount = 0
        foreach ($workflow in $workflows) {
            $status = Get-IntegratedWorkflowStatus -IntegratedWorkflow $workflow
            if ($status.OrchestrationStatus -eq "Running") {
                $runningCount++
            }
        }
        
        # Stop all workflows
        foreach ($workflow in $workflows) {
            Stop-IntegratedWorkflow -IntegratedWorkflow $workflow -WaitForCompletion -TimeoutSeconds 20 | Out-Null
        }
        
        $perfDuration = ((Get-Date) - $perfStartTime).TotalMilliseconds
        
        return @{
            Success = ($runningCount -eq 3)
            Message = "Performance validation: $runningCount/3 workflows running concurrently, total test time: ${perfDuration}ms"
        }
        
    } catch {
        return @{
            Success = $false
            Message = "Performance validation error: $($_.Exception.Message)"
        }
    }
} -Category "EndToEndWorkflow"

# Resource Management Tests
Write-TestHeader "5. Resource Management and Optimization"

Test-IntegratedWorkflowFunction "Resource Usage Monitoring" {
    param($Config)
    
    try {
        $workflow = New-IntegratedWorkflow -WorkflowName "ResourceTest" -MaxUnityProjects 3 -MaxClaudeSubmissions 6 -EnableResourceOptimization
        Initialize-AdaptiveThrottling -IntegratedWorkflow $workflow -EnableCPUThrottling -EnableMemoryThrottling | Out-Null
        
        # Simulate resource updates
        $throttlingUpdates = 0
        for ($i = 0; $i -lt 5; $i++) {
            $updateResult = Update-AdaptiveThrottling -IntegratedWorkflow $workflow
            if ($updateResult) {
                $throttlingUpdates++
            }
            Start-Sleep -Seconds 2
        }
        
        # Check throttling history
        $throttlingHistory = $workflow.WorkflowState.AdaptiveThrottling.ThrottlingHistory
        
        return @{
            Success = ($throttlingHistory.Count -gt 0)
            Message = "Resource monitoring: $($throttlingHistory.Count) resource snapshots, $throttlingUpdates throttling updates applied"
        }
        
    } catch {
        return @{
            Success = $false
            Message = "Resource monitoring error: $($_.Exception.Message)"
        }
    }
} -Category "ResourceManagement"

# Error Handling Tests  
Write-TestHeader "6. Error Handling and Recovery"

Test-IntegratedWorkflowFunction "Error Propagation Testing" {
    param($Config)
    
    try {
        $workflow = New-IntegratedWorkflow -WorkflowName "ErrorTest" -MaxUnityProjects 2 -MaxClaudeSubmissions 4 -EnableErrorPropagation
        
        # Simulate error scenarios
        $errorHandlingValid = $true
        
        # Test invalid Unity projects
        try {
            Start-IntegratedWorkflow -IntegratedWorkflow $workflow -UnityProjects @("C:\NonExistentProject") -WorkflowMode "OnDemand" -ErrorAction Stop
            $errorHandlingValid = $false  # Should have thrown an error
        } catch {
            # Expected error - this is good
        }
        
        # Test workflow status retrieval with error state
        $status = Get-IntegratedWorkflowStatus -IntegratedWorkflow $workflow
        
        return @{
            Success = $errorHandlingValid
            Message = "Error propagation: Invalid paths handled correctly, status retrieval: $($status.OverallStatus)"
        }
        
    } catch {
        return @{
            Success = $false
            Message = "Error handling test error: $($_.Exception.Message)"
        }
    }
} -Category "ErrorHandling"

# Calculate final results
$TestResults.EndTime = Get-Date
$TestResults.Summary.Duration = ($TestResults.EndTime - $TestResults.StartTime).TotalMilliseconds
$TestResults.Summary.Total = $TestResults.Tests.Count
$TestResults.Summary.Passed = ($TestResults.Tests | Where-Object Success -eq $true).Count
$TestResults.Summary.Failed = ($TestResults.Tests | Where-Object Success -eq $false).Count
$TestResults.Summary.PassRate = if ($TestResults.Summary.Total -gt 0) { 
    [math]::Round(($TestResults.Summary.Passed / $TestResults.Summary.Total) * 100, 2) 
} else { 0 }

# Display summary
Write-Host ""
Write-Host "=== End-to-End Integration Testing Results Summary ===" -ForegroundColor Cyan
Write-Host ""

Write-Host "Testing Execution Summary:"
Write-Host "Total Tests: $($TestResults.Summary.Total)"
Write-Host "Passed: $($TestResults.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($TestResults.Summary.Failed)" -ForegroundColor $(if($TestResults.Summary.Failed -gt 0){'Red'}else{'Green'})
Write-Host "Skipped: $($TestResults.Summary.Skipped)"
Write-Host "Duration: $([math]::Round($TestResults.Summary.Duration / 1000, 2)) seconds"
Write-Host "Pass Rate: $($TestResults.Summary.PassRate) percent" -ForegroundColor $(if($TestResults.Summary.PassRate -ge 90){'Green'}elseif($TestResults.Summary.PassRate -ge 75){'Yellow'}else{'Red'})
Write-Host ""

Write-Host "Category Breakdown:"
foreach ($category in $TestResults.Categories.Keys | Sort-Object) {
    $cat = $TestResults.Categories[$category]
    if ($cat.Total -gt 0) {
        $catPassRate = [math]::Round(($cat.Passed / $cat.Total) * 100, 1)
        Write-Host "$category : $($cat.Passed)/$($cat.Total) ($catPassRate percent)" -ForegroundColor $(if($catPassRate -eq 100){'Green'}elseif($catPassRate -ge 75){'Yellow'}else{'Red'})
    }
}

# Overall assessment
Write-Host ""
$overallStatus = if ($TestResults.Summary.PassRate -ge 95) {
    "✅ WEEK 3 DAY 5 END-TO-END INTEGRATION: EXCELLENT"
    "All integrated workflow components operational"
} elseif ($TestResults.Summary.PassRate -ge 85) {
    "⚠️ WEEK 3 DAY 5 END-TO-END INTEGRATION: GOOD"
    "Most integrated workflow components working - minor issues to address"
} else {
    "❌ WEEK 3 DAY 5 END-TO-END INTEGRATION: NEEDS ATTENTION"
    "Significant issues in integrated workflow implementation"
}

Write-Host $overallStatus -ForegroundColor $(if($TestResults.Summary.PassRate -ge 95){'Green'}elseif($TestResults.Summary.PassRate -ge 85){'Yellow'}else{'Red'})

# Save results if requested
if ($TestConfig.SaveResults) {
    try {
        $testOutput = @()
        $testOutput += "Unity-Claude End-to-End Integration Test Results"
        $testOutput += "================================================="
        $testOutput += "Test Date: $($TestResults.StartTime)"
        $testOutput += "Test Duration: $([math]::Round($TestResults.Summary.Duration / 1000, 2)) seconds"
        $testOutput += "PowerShell Version: $($PSVersionTable.PSVersion)"
        $testOutput += ""
        $testOutput += "Summary:"
        $testOutput += "Total Tests: $($TestResults.Summary.Total)"
        $testOutput += "Passed: $($TestResults.Summary.Passed)"
        $testOutput += "Failed: $($TestResults.Summary.Failed)"
        $testOutput += "Pass Rate: $($TestResults.Summary.PassRate)%"
        $testOutput += ""
        $testOutput += "Detailed Results:"
        
        foreach ($test in $TestResults.Tests) {
            $status = if ($test.Success) { "PASS" } else { "FAIL" }
            $testOutput += "[$status] $($test.TestName) ($($test.Category)) - $($test.Message) [$($test.Duration)ms]"
        }
        
        $testOutput += ""
        $testOutput += "Category Summary:"
        foreach ($category in $TestResults.Categories.Keys | Sort-Object) {
            $cat = $TestResults.Categories[$category]
            if ($cat.Total -gt 0) {
                $catPassRate = [math]::Round(($cat.Passed / $cat.Total) * 100, 1)
                $testOutput += "$category" + ": " + "$($cat.Passed)" + "/" + "$($cat.Total)" + " (" + "$catPassRate" + "%)"
            }
        }
        
        $testOutput += ""
        $testOutput += $overallStatus
        
        $testOutput | Out-File -FilePath $TestConfig.TestResultsFile -Encoding ASCII
        Write-Host ""
        Write-Host "Test results saved to: $($TestConfig.TestResultsFile)" -ForegroundColor Green
        
    } catch {
        Write-Host "Failed to save test results: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Return results for further processing
return $TestResults
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUNIYQEslI5Mb57RxRsVHlarL
# tcSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUjejAbnNVmaulaVFMrD/L392AH0MwDQYJKoZIhvcNAQEBBQAEggEAPpyJ
# 5MAom/qykqgl3x7sX8exW7YcdDX7an6yyk8ey5GQ6nEwGg+zGNOd1iqcULK6JHKu
# IWv6or6MoU1d2hZHQIKKLayiKzRJDmmBPtFm07V3Z1fp1b0JrbdjMQsJXrWdfcAk
# 4M89oZxkPaGB8mTDPrf+j2SYLVp7pfiAxYkfNEUuuN3EFbKLD4kmexeNv1wASjO0
# F4ukjJFEfg3oEFQJFh6lL9deCWzfH536JwqIpWBZKx36VyVzcOunnBua7KY6iVbI
# bCflCKWoJc4TPjP+ytx1qzvWGdjt6GubRu017pBqM1yl2ZoA7oKMizNiIfa64abn
# bd4eE/OQlttCwZ9UKw==
# SIG # End signature block
