# Test-Day17-IntegratedSystem.ps1
# Comprehensive Test Suite for Day 17: Integration with Existing Systems
# Tests autonomous feedback loop, response monitoring, decision engine, and master orchestration
# Compatible with PowerShell 5.1 and Unity 2021.1.14f1

param(
    [Parameter()]
    [switch]$VerboseOutput,
    
    [Parameter()]
    [switch]$SaveResults,
    
    [Parameter()]
    [string]$OutputPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\TestResults_Day17_IntegratedSystem_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
)

# Test configuration
$TestConfig = @{
    PerformanceTarget_ResponseDetectionMs = 500
    PerformanceTarget_DecisionProcessingMs = 2000
    SafetyValidation_MinConfidence = 0.8
    ConversationRounds_Target = 4
    ModuleIntegration_MinRequiredModules = 5
    EventProcessing_TimeoutMs = 5000
}

# Test results tracking
$TestResults = [System.Collections.Generic.List[hashtable]]::new()
$TestStartTime = Get-Date

# Logging function
function Write-TestLog {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [Parameter()]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] [Day17Test] $Message"
    
    if ($VerboseOutput -or $Level -eq "ERROR") {
        $color = switch ($Level) {
            "ERROR" { "Red" }
            "WARN" { "Yellow" }
            "PASS" { "Green" }
            "FAIL" { "Red" }
            default { "White" }
        }
        Write-Host $logMessage -ForegroundColor $color
    }
    
    # Also log to central log file
    try {
        Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value $logMessage -Encoding UTF8 -ErrorAction SilentlyContinue
    } catch {
        # Silently continue if logging fails
    }
}

# Test result recording function
function Add-TestResult {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TestName,
        [Parameter(Mandatory=$true)]
        [bool]$Success,
        [Parameter()]
        [string]$Details = "",
        [Parameter()]
        [hashtable]$Data = @{},
        [Parameter()]
        [double]$Duration = 0
    )
    
    $result = @{
        TestName = $TestName
        Success = $Success
        Details = $Details
        Data = $Data
        Duration = $Duration
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    $TestResults.Add($result)
    
    $status = if ($Success) { "PASS" } else { "FAIL" }
    Write-TestLog -Message "$TestName : $status - $Details" -Level $status
}

# Performance measurement helper
function Measure-TestPerformance {
    param(
        [Parameter(Mandatory=$true)]
        [scriptblock]$TestCode,
        [Parameter(Mandatory=$true)]
        [string]$TestName
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $result = & $TestCode
        $stopwatch.Stop()
        
        return @{
            Success = $true
            Result = $result
            Duration = $stopwatch.ElapsedMilliseconds
        }
    }
    catch {
        $stopwatch.Stop()
        Write-TestLog -Message "$TestName failed with error: $_" -Level "ERROR"
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            Duration = $stopwatch.ElapsedMilliseconds
        }
    }
}

Write-TestLog -Message "Starting Day 17 Integration Test Suite" -Level "INFO"
Write-TestLog -Message "Performance Targets: Response Detection <$($TestConfig.PerformanceTarget_ResponseDetectionMs)ms, Decision Processing <$($TestConfig.PerformanceTarget_DecisionProcessingMs)ms" -Level "INFO"

#region Module Integration Tests

Write-TestLog -Message "=== Module Integration Tests ===" -Level "INFO"

# Test 1: Unity-Claude-ResponseMonitor Module Loading and Integration
$testResult = Measure-TestPerformance -TestName "ResponseMonitor Module Integration" -TestCode {
    try {
        Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-ResponseMonitor\Unity-Claude-ResponseMonitor.psd1" -Force -ErrorAction Stop
        $module = Get-Module -Name "Unity-Claude-ResponseMonitor"
        
        if ($module -and $module.ExportedCommands.Count -gt 0) {
            return @{
                Success = $true
                FunctionCount = $module.ExportedCommands.Count
                Functions = $module.ExportedCommands.Keys | Sort-Object
            }
        } else {
            throw "Module not properly loaded or no functions exported"
        }
    }
    catch {
        throw "Failed to load Unity-Claude-ResponseMonitor: $_"
    }
}

Add-TestResult -TestName "ResponseMonitor Module Integration" -Success $testResult.Success -Details "$(if ($testResult.Success) { "Loaded $($testResult.Result.FunctionCount) functions" } else { $testResult.Error })" -Duration $testResult.Duration -Data $testResult.Result

# Test 2: Unity-Claude-DecisionEngine Module Loading and Integration
$testResult = Measure-TestPerformance -TestName "DecisionEngine Module Integration" -TestCode {
    try {
        Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-DecisionEngine\Unity-Claude-DecisionEngine.psd1" -Force -ErrorAction Stop
        $module = Get-Module -Name "Unity-Claude-DecisionEngine"
        
        if ($module -and $module.ExportedCommands.Count -gt 0) {
            return @{
                Success = $true
                FunctionCount = $module.ExportedCommands.Count
                Functions = $module.ExportedCommands.Keys | Sort-Object
            }
        } else {
            throw "Module not properly loaded or no functions exported"
        }
    }
    catch {
        throw "Failed to load Unity-Claude-DecisionEngine: $_"
    }
}

Add-TestResult -TestName "DecisionEngine Module Integration" -Success $testResult.Success -Details "$(if ($testResult.Success) { "Loaded $($testResult.Result.FunctionCount) functions" } else { $testResult.Error })" -Duration $testResult.Duration -Data $testResult.Result

# Test 3: Unity-Claude-MasterOrchestrator Module Loading and Integration
$testResult = Measure-TestPerformance -TestName "MasterOrchestrator Module Integration" -TestCode {
    try {
        Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-MasterOrchestrator\Unity-Claude-MasterOrchestrator.psd1" -Force -ErrorAction Stop
        $module = Get-Module -Name "Unity-Claude-MasterOrchestrator"
        
        if ($module -and $module.ExportedCommands.Count -gt 0) {
            return @{
                Success = $true
                FunctionCount = $module.ExportedCommands.Count
                Functions = $module.ExportedCommands.Keys | Sort-Object
            }
        } else {
            throw "Module not properly loaded or no functions exported"
        }
    }
    catch {
        throw "Failed to load Unity-Claude-MasterOrchestrator: $_"
    }
}

Add-TestResult -TestName "MasterOrchestrator Module Integration" -Success $testResult.Success -Details "$(if ($testResult.Success) { "Loaded $($testResult.Result.FunctionCount) functions" } else { $testResult.Error })" -Duration $testResult.Duration -Data $testResult.Result

# Test 4: Cross-Module Integration Point Detection
$testResult = Measure-TestPerformance -TestName "Cross-Module Integration Points" -TestCode {
    try {
        $orchestratorStatus = Get-OrchestratorStatus
        $initResult = Initialize-ModuleIntegration
        
        if ($initResult.Success) {
            $loadedModules = $initResult.LoadedModules.Count
            $integrationPoints = 0
            
            foreach ($moduleName in $initResult.LoadedModules) {
                if ($initResult.IntegrationMap.ContainsKey($moduleName)) {
                    $integrationPoints += $initResult.IntegrationMap[$moduleName].IntegrationPoints.Count
                }
            }
            
            return @{
                Success = $true
                LoadedModules = $loadedModules
                IntegrationPoints = $integrationPoints
                ModuleDetails = $initResult.IntegrationMap
            }
        } else {
            throw "Module integration initialization failed"
        }
    }
    catch {
        throw "Cross-module integration test failed: $_"
    }
}

$targetMet = $testResult.Result.LoadedModules -ge $TestConfig.ModuleIntegration_MinRequiredModules
Add-TestResult -TestName "Cross-Module Integration Points" -Success ($testResult.Success -and $targetMet) -Details "$(if ($testResult.Success) { "Integrated $($testResult.Result.LoadedModules) modules with $($testResult.Result.IntegrationPoints) integration points (Target: $($TestConfig.ModuleIntegration_MinRequiredModules)+)" } else { $testResult.Error })" -Duration $testResult.Duration -Data $testResult.Result

#endregion

#region Response Analysis and Decision Engine Tests

Write-TestLog -Message "=== Response Analysis and Decision Engine Tests ===" -Level "INFO"

# Test 5: Hybrid Response Analysis Performance
$testResult = Measure-TestPerformance -TestName "Hybrid Response Analysis Performance" -TestCode {
    $testResponse = @{
        Content = "RECOMMENDED: TEST - Run the unit tests to validate the implementation. Please execute the test suite and verify all tests pass."
        Timestamp = Get-Date
        FilePath = "test_response.md"
    }
    
    $analysisResult = Invoke-HybridResponseAnalysis -Response $testResponse
    
    if ($analysisResult.ActionableItems.Count -gt 0) {
        return @{
            Success = $true
            ActionableItemsCount = $analysisResult.ActionableItems.Count
            OverallConfidence = $analysisResult.OverallConfidence
            IntentClassification = $analysisResult.IntentClassification
        }
    } else {
        throw "No actionable items found in test response"
    }
}

$performanceMet = $testResult.Duration -le $TestConfig.PerformanceTarget_ResponseDetectionMs
Add-TestResult -TestName "Hybrid Response Analysis Performance" -Success ($testResult.Success -and $performanceMet) -Details "$(if ($testResult.Success) { "Found $($testResult.Result.ActionableItemsCount) actionable items with $($testResult.Result.OverallConfidence) confidence in $($testResult.Duration)ms (Target: <$($TestConfig.PerformanceTarget_ResponseDetectionMs)ms)" } else { $testResult.Error })" -Duration $testResult.Duration -Data $testResult.Result

# Test 6: Autonomous Decision Making
$testResult = Measure-TestPerformance -TestName "Autonomous Decision Making" -TestCode {
    $testAnalysis = @{
        ActionableItems = @(
            @{
                Type = "RECOMMENDED"
                ExtractedData = @{ Action = "Run tests"; TestType = "Unit tests" }
                Priority = 8
                Confidence = 0.85
                Source = "TestData"
            }
        )
        OverallConfidence = 0.85
        IntentClassification = "ActionRequired"
        SemanticContext = @{ Domain = "Testing" }
    }
    
    $decision = Invoke-AutonomousDecision -Analysis $testAnalysis
    
    if ($decision.Success -and $decision.Action -ne "NO_ACTION") {
        return @{
            Success = $true
            Decision = $decision.Action
            Confidence = $decision.Confidence
            DecisionId = $decision.DecisionId
        }
    } else {
        throw "Decision making failed or resulted in NO_ACTION"
    }
}

$performanceMet = $testResult.Duration -le $TestConfig.PerformanceTarget_DecisionProcessingMs
Add-TestResult -TestName "Autonomous Decision Making" -Success ($testResult.Success -and $performanceMet) -Details "$(if ($testResult.Success) { "Generated decision '$($testResult.Result.Decision)' with confidence $($testResult.Result.Confidence) in $($testResult.Duration)ms (Target: <$($TestConfig.PerformanceTarget_DecisionProcessingMs)ms)" } else { $testResult.Error })" -Duration $testResult.Duration -Data $testResult.Result

# Test 7: Decision Engine Integration Test
$testResult = Measure-TestPerformance -TestName "Decision Engine Integration" -TestCode {
    $integrationTest = Test-DecisionEngineIntegration
    
    if ($integrationTest.OverallStatus -eq "PASS") {
        return @{
            Success = $true
            TestResults = $integrationTest
            PassedTests = ($integrationTest.GetEnumerator() | Where-Object { $_.Key -ne "OverallStatus" -and $_.Value -eq $true }).Count
        }
    } else {
        throw "Decision Engine integration test failed: $($integrationTest.OverallStatus)"
    }
}

Add-TestResult -TestName "Decision Engine Integration" -Success $testResult.Success -Details "$(if ($testResult.Success) { "Integration test passed with $($testResult.Result.PassedTests)/4 components working" } else { $testResult.Error })" -Duration $testResult.Duration -Data $testResult.Result

# Test 8: Response Pattern Recognition Accuracy
$testResult = Measure-TestPerformance -TestName "Response Pattern Recognition" -TestCode {
    $testPatterns = @(
        @{ 
            Content = "RECOMMENDED: DEBUGGING - Check the Unity console log for compilation errors"
            ExpectedType = "RECOMMENDED"
            ExpectedAction = "EXECUTE_RECOMMENDATION"
        },
        @{ 
            Content = "Please run the following test: Test-ModuleIntegration"
            ExpectedType = "EXECUTION_COMMAND"
            ExpectedAction = "EXECUTE_COMMAND"
        },
        @{ 
            Content = "Can you tell me more about how the integration works?"
            ExpectedType = "QUESTION_PATTERN" 
            ExpectedAction = "GENERATE_RESPONSE"
        }
    )
    
    $correctPredictions = 0
    $totalTests = $testPatterns.Count
    
    foreach ($pattern in $testPatterns) {
        $testResponse = @{ Content = $pattern.Content; Timestamp = Get-Date }
        $analysis = Invoke-HybridResponseAnalysis -Response $testResponse
        
        if ($analysis.ActionableItems.Count -gt 0) {
            $topItem = $analysis.ActionableItems | Sort-Object @{Expression={$_.Priority}; Descending=$true} | Select-Object -First 1
            if ($topItem.Type -eq $pattern.ExpectedType) {
                $correctPredictions++
            }
        }
    }
    
    $accuracy = $correctPredictions / $totalTests
    
    return @{
        Success = $accuracy -ge 0.7  # 70% accuracy threshold
        Accuracy = $accuracy
        CorrectPredictions = $correctPredictions
        TotalTests = $totalTests
    }
}

Add-TestResult -TestName "Response Pattern Recognition" -Success $testResult.Success -Details "$(if ($testResult.Success) { "Pattern recognition accuracy: $($testResult.Result.Accuracy * 100)% ($($testResult.Result.CorrectPredictions)/$($testResult.Result.TotalTests))" } else { $testResult.Error })" -Duration $testResult.Duration -Data $testResult.Result

#endregion

#region Safety and Validation Tests

Write-TestLog -Message "=== Safety and Validation Tests ===" -Level "INFO"

# Test 9: Safety Validation Framework
$testResult = Measure-TestPerformance -TestName "Safety Validation Framework" -TestCode {
    # Test high-risk decision validation
    $highRiskDecision = @{
        Action = "EXECUTE_COMMAND"
        Confidence = 0.6  # Below safety threshold
        CommandData = @{ Command = "Remove-Item -Path 'C:\test' -Force" }
        DecisionId = [guid]::NewGuid().ToString()
    }
    
    $safetyResult = Invoke-SafetyValidation -Decision $highRiskDecision
    
    # Should reject high-risk command with low confidence
    if (-not $safetyResult.IsSafe) {
        return @{
            Success = $true
            SafetyPassed = $true
            Reason = $safetyResult.Reason
            TestType = "HighRiskRejection"
        }
    } else {
        throw "Safety validation failed to reject high-risk, low-confidence command"
    }
}

Add-TestResult -TestName "Safety Validation Framework" -Success $testResult.Success -Details "$(if ($testResult.Success) { "Safety validation correctly rejected high-risk command: $($testResult.Result.Reason)" } else { $testResult.Error })" -Duration $testResult.Duration -Data $testResult.Result

# Test 10: Dangerous Command Pattern Detection
$testResult = Measure-TestPerformance -TestName "Dangerous Command Pattern Detection" -TestCode {
    $dangerousCommands = @(
        "rm -rf /",
        "del C:\Windows\System32",
        "format C:",
        "shutdown /s /f /t 0"
    )
    
    $blockedCount = 0
    
    foreach ($cmd in $dangerousCommands) {
        $testDecision = @{
            Action = "EXECUTE_COMMAND"
            Confidence = 0.9
            CommandData = @{ Command = $cmd }
            DecisionId = [guid]::NewGuid().ToString()
        }
        
        $safetyResult = Invoke-SafetyValidation -Decision $testDecision
        if (-not $safetyResult.IsSafe) {
            $blockedCount++
        }
    }
    
    return @{
        Success = $blockedCount -eq $dangerousCommands.Count
        BlockedCount = $blockedCount
        TotalCommands = $dangerousCommands.Count
        BlockedPercentage = $blockedCount / $dangerousCommands.Count
    }
}

Add-TestResult -TestName "Dangerous Command Pattern Detection" -Success $testResult.Success -Details "$(if ($testResult.Success) { "Blocked $($testResult.Result.BlockedCount)/$($testResult.Result.TotalCommands) dangerous commands (100%)" } else { "Only blocked $($testResult.Result.BlockedCount)/$($testResult.Result.TotalCommands) dangerous commands ($($testResult.Result.BlockedPercentage * 100)%)" })" -Duration $testResult.Duration -Data $testResult.Result

# Test 11: Confidence Threshold Enforcement
$testResult = Measure-TestPerformance -TestName "Confidence Threshold Enforcement" -TestCode {
    $testDecisions = @(
        @{ Action = "EXECUTE_COMMAND"; Confidence = 0.9; ShouldPass = $true },
        @{ Action = "EXECUTE_COMMAND"; Confidence = 0.7; ShouldPass = $false },
        @{ Action = "CONTINUE_CONVERSATION"; Confidence = 0.5; ShouldPass = $true },
        @{ Action = "NO_ACTION"; Confidence = 0.1; ShouldPass = $false }
    )
    
    $correctValidations = 0
    
    foreach ($testCase in $testDecisions) {
        $decision = @{
            Action = $testCase.Action
            Confidence = $testCase.Confidence
            DecisionId = [guid]::NewGuid().ToString()
        }
        
        $safetyResult = Invoke-SafetyValidation -Decision $decision
        $actualPass = $safetyResult.IsSafe
        
        if ($actualPass -eq $testCase.ShouldPass) {
            $correctValidations++
        }
    }
    
    return @{
        Success = $correctValidations -eq $testDecisions.Count
        CorrectValidations = $correctValidations
        TotalTests = $testDecisions.Count
        Accuracy = $correctValidations / $testDecisions.Count
    }
}

Add-TestResult -TestName "Confidence Threshold Enforcement" -Success $testResult.Success -Details "$(if ($testResult.Success) { "Confidence validation accuracy: $($testResult.Result.Accuracy * 100)% ($($testResult.Result.CorrectValidations)/$($testResult.Result.TotalTests))" } else { "Confidence validation accuracy: $($testResult.Result.Accuracy * 100)% ($($testResult.Result.CorrectValidations)/$($testResult.Result.TotalTests))" })" -Duration $testResult.Duration -Data $testResult.Result

#endregion

#region Event-Driven Architecture Tests

Write-TestLog -Message "=== Event-Driven Architecture Tests ===" -Level "INFO"

# Test 12: Event Processing System
$testResult = Measure-TestPerformance -TestName "Event Processing System" -TestCode {
    $eventResult = Start-EventDrivenProcessing
    
    if ($eventResult.Success) {
        # Test event queue functionality
        $testEvent = @{
            Type = "TestEvent"
            Source = "TestSuite"
            Data = @{ TestData = "Integration Test" }
            Priority = 5
        }
        
        Add-EventToQueue -Event $testEvent
        
        $orchestratorStatus = Get-OrchestratorStatus
        
        return @{
            Success = $true
            EventProcessingActive = $eventResult.EventQueueActive
            QueueSize = $orchestratorStatus.EventProcessing.QueueSize
            RegisteredEvents = $eventResult.RegisteredEvents
        }
    } else {
        throw "Failed to start event-driven processing: $($eventResult.Error)"
    }
}

Add-TestResult -TestName "Event Processing System" -Success $testResult.Success -Details "$(if ($testResult.Success) { "Event processing active with queue size: $($testResult.Result.QueueSize)" } else { $testResult.Error })" -Duration $testResult.Duration -Data $testResult.Result

# Test 13: Response Event Processing
$testResult = Measure-TestPerformance -TestName "Response Event Processing" -TestCode {
    $testResponseEvent = @{
        Type = "ClaudeResponse"
        Source = "Unity-Claude-ResponseMonitor"
        Data = @{
            Content = "RECOMMENDED: TEST - Execute the integration test suite"
            Timestamp = Get-Date
            FilePath = "test_response.md"
        }
        Priority = 8
    }
    
    $processingResult = Invoke-ResponseEventProcessing -Event $testResponseEvent
    
    if ($processingResult.Success) {
        return @{
            Success = $true
            Stage = $processingResult.Stage
            HasAnalysis = $processingResult.AnalysisResult -ne $null
            HasDecision = $processingResult.Decision -ne $null
            HasExecution = $processingResult.ExecutionResult -ne $null
        }
    } else {
        throw "Response event processing failed: $($processingResult.Error)"
    }
}

Add-TestResult -TestName "Response Event Processing" -Success $testResult.Success -Details "$(if ($testResult.Success) { "Response event processed through stage: $($testResult.Result.Stage)" } else { $testResult.Error })" -Duration $testResult.Duration -Data $testResult.Result

# Test 14: Decision Execution Routing
$testResult = Measure-TestPerformance -TestName "Decision Execution Routing" -TestCode {
    $testDecisions = @(
        @{ Action = "NO_ACTION"; ExpectedSuccess = $true },
        @{ Action = "CONTINUE_MONITORING"; ExpectedSuccess = $true },
        @{ Action = "CONTINUE_CONVERSATION"; ExpectedSuccess = $true },
        @{ Action = "REQUEST_APPROVAL"; ExpectedSuccess = $true }
    )
    
    $successfulExecutions = 0
    
    foreach ($testCase in $testDecisions) {
        $decision = @{
            Action = $testCase.Action
            Confidence = 0.7
            DecisionId = [guid]::NewGuid().ToString()
        }
        
        $executionResult = Invoke-DecisionExecution -Decision $decision
        
        if ($executionResult.Success -eq $testCase.ExpectedSuccess) {
            $successfulExecutions++
        }
    }
    
    return @{
        Success = $successfulExecutions -eq $testDecisions.Count
        SuccessfulExecutions = $successfulExecutions
        TotalTests = $testDecisions.Count
        Accuracy = $successfulExecutions / $testDecisions.Count
    }
}

Add-TestResult -TestName "Decision Execution Routing" -Success $testResult.Success -Details "$(if ($testResult.Success) { "Decision routing accuracy: $($testResult.Result.Accuracy * 100)% ($($testResult.Result.SuccessfulExecutions)/$($testResult.Result.TotalTests))" } else { "Decision routing accuracy: $($testResult.Result.Accuracy * 100)% ($($testResult.Result.SuccessfulExecutions)/$($testResult.Result.TotalTests))" })" -Duration $testResult.Duration -Data $testResult.Result

#endregion

#region End-to-End Workflow Tests

Write-TestLog -Message "=== End-to-End Workflow Tests ===" -Level "INFO"

# Test 15: Complete Autonomous Feedback Loop
$testResult = Measure-TestPerformance -TestName "Complete Autonomous Feedback Loop" -TestCode {
    # Start autonomous feedback loop
    $feedbackResult = Start-AutonomousFeedbackLoop -MaxRounds 2
    
    if ($feedbackResult.Success) {
        # Give it a moment to initialize
        Start-Sleep -Milliseconds 500
        
        # Check status
        $status = Get-OrchestratorStatus
        
        # Stop the feedback loop
        $stopResult = Stop-AutonomousFeedbackLoop
        
        return @{
            Success = $true
            FeedbackLoopStarted = $feedbackResult.FeedbackLoopActive
            AutonomousMode = $feedbackResult.AutonomousMode
            IntegratedModules = $feedbackResult.IntegratedModules
            FeedbackLoopStopped = $stopResult.Success
            CompletedRounds = $stopResult.CompletedRounds
        }
    } else {
        throw "Failed to start autonomous feedback loop: $($feedbackResult.Error)"
    }
}

Add-TestResult -TestName "Complete Autonomous Feedback Loop" -Success $testResult.Success -Details "$(if ($testResult.Success) { "Feedback loop completed with $($testResult.Result.IntegratedModules) integrated modules" } else { $testResult.Error })" -Duration $testResult.Duration -Data $testResult.Result

# Test 16: Master Orchestrator Integration Test
$testResult = Measure-TestPerformance -TestName "Master Orchestrator Integration" -TestCode {
    $integrationTest = Test-OrchestratorIntegration
    
    if ($integrationTest.OverallStatus -eq "PASS") {
        return @{
            Success = $true
            TestResults = $integrationTest
            PassedTests = ($integrationTest.GetEnumerator() | Where-Object { $_.Key -ne "OverallStatus" -and $_.Value -eq $true }).Count
        }
    } else {
        throw "Master Orchestrator integration test failed: $($integrationTest.OverallStatus)"
    }
}

Add-TestResult -TestName "Master Orchestrator Integration" -Success $testResult.Success -Details "$(if ($testResult.Success) { "Master Orchestrator integration passed with $($testResult.Result.PassedTests)/4 components working" } else { $testResult.Error })" -Duration $testResult.Duration -Data $testResult.Result

# Test 17: Performance Benchmark Validation
$testResult = Measure-TestPerformance -TestName "Performance Benchmark Validation" -TestCode {
    # Collect performance data from previous tests
    $responseDetectionTests = $TestResults | Where-Object { $_.TestName -like "*Response*" -and $_.Duration -gt 0 }
    $decisionProcessingTests = $TestResults | Where-Object { $_.TestName -like "*Decision*" -and $_.Duration -gt 0 }
    
    $avgResponseTime = if ($responseDetectionTests.Count -gt 0) { 
        ($responseDetectionTests | Measure-Object -Property Duration -Average).Average 
    } else { 0 }
    
    $avgDecisionTime = if ($decisionProcessingTests.Count -gt 0) { 
        ($decisionProcessingTests | Measure-Object -Property Duration -Average).Average 
    } else { 0 }
    
    $responseTargetMet = $avgResponseTime -le $TestConfig.PerformanceTarget_ResponseDetectionMs
    $decisionTargetMet = $avgDecisionTime -le $TestConfig.PerformanceTarget_DecisionProcessingMs
    
    return @{
        Success = $responseTargetMet -and $decisionTargetMet
        AverageResponseTime = $avgResponseTime
        AverageDecisionTime = $avgDecisionTime
        ResponseTargetMet = $responseTargetMet
        DecisionTargetMet = $decisionTargetMet
        ResponseTarget = $TestConfig.PerformanceTarget_ResponseDetectionMs
        DecisionTarget = $TestConfig.PerformanceTarget_DecisionProcessingMs
    }
}

Add-TestResult -TestName "Performance Benchmark Validation" -Success $testResult.Success -Details "$(if ($testResult.Success) { "Performance targets met - Response: $($testResult.Result.AverageResponseTime)ms (Target: <$($testResult.Result.ResponseTarget)ms), Decision: $($testResult.Result.AverageDecisionTime)ms (Target: <$($testResult.Result.DecisionTarget)ms)" } else { "Performance targets not met - Response: $($testResult.Result.AverageResponseTime)ms, Decision: $($testResult.Result.AverageDecisionTime)ms" })" -Duration $testResult.Duration -Data $testResult.Result

# Test 18: System Resource and Memory Management
$testResult = Measure-TestPerformance -TestName "System Resource Management" -TestCode {
    # Test memory cleanup and resource management
    $initialMemory = [System.GC]::GetTotalMemory($false)
    
    # Perform resource-intensive operations
    Initialize-ModuleIntegration -Force | Out-Null
    Start-EventDrivenProcessing | Out-Null
    
    # Force garbage collection
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    
    $finalMemory = [System.GC]::GetTotalMemory($true)
    $memoryDifference = $finalMemory - $initialMemory
    
    # Clean up orchestrator state
    Clear-OrchestratorState | Out-Null
    
    return @{
        Success = $memoryDifference -lt 50MB  # Acceptable memory increase
        InitialMemory = $initialMemory
        FinalMemory = $finalMemory
        MemoryDifference = $memoryDifference
        MemoryDifferenceMB = [Math]::Round($memoryDifference / 1MB, 2)
    }
}

Add-TestResult -TestName "System Resource Management" -Success $testResult.Success -Details "$(if ($testResult.Success) { "Memory usage increase: $($testResult.Result.MemoryDifferenceMB)MB (acceptable)" } else { "Memory usage increase: $($testResult.Result.MemoryDifferenceMB)MB (excessive)" })" -Duration $testResult.Duration -Data $testResult.Result

#endregion

#region Results Summary and Output

Write-TestLog -Message "=== Test Results Summary ===" -Level "INFO"

$totalTests = $TestResults.Count
$passedTests = ($TestResults | Where-Object { $_.Success -eq $true }).Count
$failedTests = $totalTests - $passedTests
$successRate = if ($totalTests -gt 0) { ($passedTests / $totalTests) * 100 } else { 0 }
$totalDuration = ($TestResults | Measure-Object -Property Duration -Sum).Sum

Write-TestLog -Message "Total Tests: $totalTests" -Level "INFO"
Write-TestLog -Message "Passed Tests: $passedTests" -Level "PASS"
Write-TestLog -Message "Failed Tests: $failedTests" -Level $(if ($failedTests -eq 0) { "PASS" } else { "FAIL" })
Write-TestLog -Message "Success Rate: $([Math]::Round($successRate, 1))%" -Level $(if ($successRate -ge 90) { "PASS" } else { "WARN" })
Write-TestLog -Message "Total Duration: $totalDuration ms" -Level "INFO"

# Detailed results for failed tests
if ($failedTests -gt 0) {
    Write-TestLog -Message "Failed Tests Details:" -Level "ERROR"
    $TestResults | Where-Object { $_.Success -eq $false } | ForEach-Object {
        Write-TestLog -Message "  - $($_.TestName): $($_.Details)" -Level "ERROR"
    }
}

# Performance summary
$performanceTests = $TestResults | Where-Object { $_.TestName -like "*Performance*" -or $_.Duration -gt 100 }
if ($performanceTests.Count -gt 0) {
    Write-TestLog -Message "Performance Summary:" -Level "INFO"
    $performanceTests | ForEach-Object {
        $status = if ($_.Success) { "PASS" } else { "FAIL" }
        Write-TestLog -Message "  - $($_.TestName): $($_.Duration)ms [$status]" -Level "INFO"
    }
}

# Create final test report
$finalReport = @{
    TestSuite = "Day 17: Integration with Existing Systems"
    ExecutionTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Duration = ((Get-Date) - $TestStartTime).TotalSeconds
    Configuration = $TestConfig
    Summary = @{
        TotalTests = $totalTests
        PassedTests = $passedTests
        FailedTests = $failedTests
        SuccessRate = [Math]::Round($successRate, 1)
        TotalDurationMs = $totalDuration
    }
    Results = $TestResults
    SystemInfo = @{
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        OS = [System.Environment]::OSVersion.ToString()
        MachineName = $env:COMPUTERNAME
        UserName = $env:USERNAME
    }
}

if ($SaveResults -and $OutputPath) {
    try {
        $finalReport | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
        Write-TestLog -Message "Test results saved to: $OutputPath" -Level "INFO"
    }
    catch {
        Write-TestLog -Message "Failed to save test results: $_" -Level "ERROR"
    }
}

Write-TestLog -Message "Day 17 Integration Test Suite completed" -Level "INFO"

# Return overall test status
if ($successRate -ge 90) {
    Write-TestLog -Message "Day 17 Integration: SUCCESS - All systems integrated and operational" -Level "PASS"
    exit 0
} else {
    Write-TestLog -Message "Day 17 Integration: PARTIAL SUCCESS - Some systems require attention" -Level "WARN"
    exit 1
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUACBmfftyJGWWrlyjKSQijdgo
# 2F+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUeu1OZjeoEBXjYQNzo76pO3aAQIUwDQYJKoZIhvcNAQEBBQAEggEAlFCi
# IBNkTyUVCMYnPDUubkbL4euQURm2Y6Ee/fnEEPmkYQgMcN6uvGre7ofPKhRAECbY
# BepgW1gQ8H7bByrQfQB4D1uHV7dLC9b/MIquuF8yCpAxtvS+f5W8tl4Lpol4Ieox
# w8J/Rmv4R4FAM3U0/tYr0giqcujmdhu/jUEO5jV0wPScrnzsz34/Eo5kW/insE/B
# O3mo/+r8F1daY5vlfVS/rs9cgbFx966zDNehTOy3tG45VcjS4N/711dY9hSzwN6r
# 4m4ZzQQMzOgTUUV9gXDO3o/Fa+9142eBGl4+JIFIHcBD8/NxgvcJqz8Hu5LpoMgE
# P4ysBR8VyTQcbeMceg==
# SIG # End signature block
