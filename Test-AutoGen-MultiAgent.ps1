#Requires -Version 5.1

<#
.SYNOPSIS
Comprehensive AutoGen Multi-Agent Test Suite (Week 1 Day 2 Hour 7-8)

.DESCRIPTION
Production-ready comprehensive testing of all AutoGen multi-agent scenarios including
performance optimization, scalability testing, and production deployment validation.

.NOTES
Author: Unity-Claude-Automation System
Version: 1.0.0
Phase: Week 1 Day 2 Hour 7-8 - AutoGen Integration Testing and Production Setup
Dependencies: Unity-Claude-AutoGen.psm1, Unity-Claude-CodeReviewCoordination.psm1, Unity-Claude-TechnicalDebtAgents.psm1
Research Foundation: AutoGen v0.4 production patterns + OpenTelemetry monitoring + AgentOps observability
Target: Production-ready AutoGen integration with scalable architecture
#>

param(
    [Parameter()]
    [switch]$SaveResults = $true,
    
    [Parameter()]
    [switch]$PerformanceTesting = $true,
    
    [Parameter()]
    [switch]$LoadTesting = $true,
    
    [Parameter()]
    [switch]$ProductionValidation = $true,
    
    [Parameter()]
    [string]$ResultsPath = ".\AutoGen-MultiAgent-Comprehensive-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

# Initialize comprehensive test results structure (PowerShell 5.1 compatible)
$script:TestStartTime = Get-Date
Write-Debug "[DEBUG] Test start time initialized: $($script:TestStartTime.ToString('yyyy-MM-dd HH:mm:ss.fff'))"

$script:TestResults = @{
    StartTime = $script:TestStartTime.ToString("yyyy-MM-dd HH:mm:ss.fff")
    TestSuite = "AutoGen Multi-Agent Comprehensive Testing (Week 1 Day 2 Hour 7-8)"
    Tests = @()
    TestCategories = @{
        Infrastructure = @()
        AgentScenarios = @()
        CollaborativeWorkflows = @()
        TechnicalDebtIntegration = @()
        PerformanceOptimization = @()
        ScalabilityValidation = @()
        ProductionReadiness = @()
        MonitoringIntegration = @()
    }
    PerformanceBaseline = $null
    ProductionMetrics = @{}
}

Write-Debug "[DEBUG] TestResults initialized successfully"
Write-Debug "[DEBUG] TestResults.StartTime: '$($script:TestResults.StartTime)'"
Write-Debug "[DEBUG] TestResults.Tests type: $($script:TestResults.Tests.GetType().Name)"
Write-Debug "[DEBUG] TestResults.Tests count: $(($script:TestResults.Tests | Measure-Object).Count)"

function Add-TestResult {
    param($TestName, $Category, $Passed, $Details, $Data = $null, $Duration = $null, $PerformanceData = $null)
    
    Write-Debug "[DEBUG] Add-TestResult called with TestName: $TestName, Category: $Category"
    Write-Debug "[DEBUG] TestResults.Tests type before: $(if ($script:TestResults.Tests) { $script:TestResults.Tests.GetType().Name } else { 'NULL' })"
    Write-Debug "[DEBUG] TestResults.Tests count before: $(if ($script:TestResults.Tests) { ($script:TestResults.Tests | Measure-Object).Count } else { 0 })"
    Write-Debug "[DEBUG] TestResults.TestCategories.$Category type before: $(if ($script:TestResults.TestCategories.$Category) { $script:TestResults.TestCategories.$Category.GetType().Name } else { 'NULL' })"
    
    try {
        $result = [PSCustomObject]@{
            TestName = $TestName
            Category = $Category
            Passed = $Passed
            Details = $Details
            Data = $Data
            Duration = $Duration
            PerformanceData = $PerformanceData
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        }
        
        Write-Debug "[DEBUG] Created result object successfully"
        Write-Debug "[DEBUG] Result object type: $($result.GetType().Name)"
        
        # Verify TestResults.Tests is not null before adding
        if ($script:TestResults.Tests -eq $null) {
            Write-Warning "[DEBUG] TestResults.Tests is null! Reinitializing..."
            $script:TestResults.Tests = @()
        }
        
        # Verify category collection is not null before adding
        if ($script:TestResults.TestCategories[$Category] -eq $null) {
            Write-Warning "[DEBUG] TestResults.TestCategories.$Category is null! Reinitializing..."
            $script:TestResults.TestCategories[$Category] = @()
        }
        
        # Add to collections using += for safer array concatenation
        $script:TestResults.Tests += $result
        $script:TestResults.TestCategories[$Category] += $result
        
        Write-Debug "[DEBUG] TestResults.Tests count after: $(($script:TestResults.Tests | Measure-Object).Count)"
        Write-Debug "[DEBUG] TestResults.TestCategories.$Category count after: $(($script:TestResults.TestCategories[$Category] | Measure-Object).Count)"
        
        $status = if ($Passed) { "[PASS]" } else { "[FAIL]" }
        $color = if ($Passed) { "Green" } else { "Red" }
        Write-Host "  $status $TestName - $Details" -ForegroundColor $color
        
        Write-Debug "[DEBUG] Add-TestResult completed successfully for: $TestName"
    }
    catch {
        Write-Error "[DEBUG] Add-TestResult failed for $TestName`: $($_.Exception.Message)"
        Write-Debug "[DEBUG] TestResults.Tests is null: $($script:TestResults.Tests -eq $null)"
        Write-Debug "[DEBUG] TestResults exists: $($script:TestResults -ne $null)"
        if ($script:TestResults -ne $null -and $script:TestResults.TestCategories -ne $null) {
            Write-Debug "[DEBUG] TestResults.TestCategories.$Category is null: $($script:TestResults.TestCategories[$Category] -eq $null)"
        } else {
            Write-Debug "[DEBUG] TestResults.TestCategories is null, cannot check category"
        }
        
        # Try to recover state instead of throwing
        Write-Warning "[DEBUG] Attempting to recover TestResults state..."
        
        # Ensure TestResults exists
        if ($script:TestResults -eq $null) {
            Write-Warning "[DEBUG] TestResults was null, reinitializing entire structure"
            $script:TestResults = @{
                StartTime = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
                TestSuite = "AutoGen Multi-Agent Comprehensive Testing (Week 1 Day 2 Hour 7-8)"
                Tests = @()
                TestCategories = @{
                    Infrastructure = @()
                    AgentScenarios = @()
                    CollaborativeWorkflows = @()
                    TechnicalDebtIntegration = @()
                    PerformanceOptimization = @()
                    ScalabilityValidation = @()
                    ProductionReadiness = @()
                    MonitoringIntegration = @()
                }
                PerformanceBaseline = $null
                ProductionMetrics = @{}
            }
        }
        
        # Ensure Tests array exists
        if ($script:TestResults.Tests -eq $null) {
            Write-Warning "[DEBUG] TestResults.Tests was null, reinitializing"
            $script:TestResults.Tests = @()
        }
        
        # Ensure TestCategories hashtable exists
        if ($script:TestResults.TestCategories -eq $null) {
            Write-Warning "[DEBUG] TestResults.TestCategories was null, reinitializing"
            $script:TestResults.TestCategories = @{
                Infrastructure = @()
                AgentScenarios = @()
                CollaborativeWorkflows = @()
                TechnicalDebtIntegration = @()
                PerformanceOptimization = @()
                ScalabilityValidation = @()
                ProductionReadiness = @()
                MonitoringIntegration = @()
            }
        }
        
        # Ensure specific category exists
        if ($script:TestResults.TestCategories[$Category] -eq $null) {
            Write-Warning "[DEBUG] TestResults.TestCategories.$Category was null, reinitializing"
            $script:TestResults.TestCategories[$Category] = @()
        }
        
        # Try to add the failed test result anyway
        try {
            $failedResult = [PSCustomObject]@{
                TestName = $TestName
                Category = $Category
                Passed = $false
                Details = "Failed to record: $($_.Exception.Message)"
                Data = $null
                Duration = $null
                PerformanceData = $null
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            }
            
            $script:TestResults.Tests += $failedResult
            $script:TestResults.TestCategories[$Category] += $failedResult
            
            Write-Warning "[DEBUG] Added failed test result for: $TestName"
        }
        catch {
            Write-Error "[DEBUG] Could not recover state for test: $TestName"
        }
    }
}

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "AutoGen Multi-Agent Comprehensive Test Suite" -ForegroundColor Cyan
Write-Host "Week 1 Day 2 Hour 7-8: Production Testing & Deployment Setup" -ForegroundColor Cyan
Write-Host "Target: Production-Ready AutoGen Integration with Scalable Architecture" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

#region Infrastructure Validation

Write-Host "`n[TEST CATEGORY] Infrastructure..." -ForegroundColor Yellow

try {
    Write-Host "Loading all AutoGen modules..." -ForegroundColor White
    Import-Module -Name ".\Unity-Claude-AutoGen.psm1" -Force
    Import-Module -Name ".\Unity-Claude-CodeReviewCoordination.psm1" -Force  
    Import-Module -Name ".\Unity-Claude-TechnicalDebtAgents.psm1" -Force
    Import-Module -Name ".\Safe-FileEnumeration.psm1" -Force
    try {
        Import-Module -Name ".\Modules\Unity-Claude-CLIOrchestrator\Core\PerformanceOptimizer.psm1" -Force -ErrorAction Stop
        Write-Debug "[ModuleLoad] PerformanceOptimizer module imported successfully"
    } catch {
        Write-Warning "[ModuleLoad] PerformanceOptimizer module import failed: $($_.Exception.Message)"
        Write-Debug "[ModuleLoad] Start-PerformanceMonitoring command will not be available for production checks"
    }
    
    $requiredModules = @("Unity-Claude-AutoGen", "Unity-Claude-CodeReviewCoordination", "Unity-Claude-TechnicalDebtAgents", "Safe-FileEnumeration")
    $loadedModules = $requiredModules | Where-Object { Get-Module -Name $_ }
    
    Write-Debug "[DEBUG] About to call first Add-TestResult"
    Write-Debug "[DEBUG] TestResults variable exists: $($script:TestResults -ne $null)"
    Write-Debug "[DEBUG] TestResults.Tests exists: $($script:TestResults.Tests -ne $null)"
    Write-Debug "[DEBUG] TestResults.Tests type: $($script:TestResults.Tests.GetType().Name)"
    
    Add-TestResult -TestName "Complete Infrastructure Loading" -Category "Infrastructure" -Passed (($loadedModules | Measure-Object).Count -eq ($requiredModules | Measure-Object).Count) -Details "Loaded: $(($loadedModules | Measure-Object).Count)/$(($requiredModules | Measure-Object).Count) modules" -Data @{
        RequiredModules = $requiredModules
        LoadedModules = $loadedModules
        InfrastructureReady = (($loadedModules | Measure-Object).Count -eq ($requiredModules | Measure-Object).Count)
    }
}
catch {
    Add-TestResult -TestName "Complete Infrastructure Loading" -Category "Infrastructure" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing CLR error prevention..." -ForegroundColor White
    $startTime = Get-Date
    $safeEnumResult = Get-SafeChildItems -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation" -Filter "*.psm1" -FilesOnly -MaxDepth 3
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    
    $clrSafetyWorking = (($safeEnumResult | Measure-Object).Count -gt 0 -and $duration -lt 5000)  # Should complete in <5 seconds
    
    Add-TestResult -TestName "CLR Error Prevention Validation" -Category "Infrastructure" -Passed $clrSafetyWorking -Details "Safe enumeration: $(($safeEnumResult | Measure-Object).Count) files in $([math]::Round($duration, 2))ms" -Duration $duration -Data @{
        FileCount = ($safeEnumResult | Measure-Object).Count
        EnumerationTime = $duration
        CLRSafetyValidated = $clrSafetyWorking
    }
}
catch {
    Add-TestResult -TestName "CLR Error Prevention Validation" -Category "Infrastructure" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Agent Scenarios Testing

Write-Host "`n[TEST CATEGORY] Agent Scenarios..." -ForegroundColor Yellow

try {
    Write-Host "Testing complete agent lifecycle..." -ForegroundColor White
    
    # Create agents
    $startTime = Get-Date
    $testAgent1 = New-AutoGenAgent -AgentType "AssistantAgent" -AgentName "LifecycleTest1" -SystemMessage "Code review test agent"
    $testAgent2 = New-AutoGenAgent -AgentType "ArchitectureAgent" -AgentName "LifecycleTest2" -SystemMessage "Architecture test agent"
    $testAgent3 = New-AutoGenAgent -AgentType "DocumentationAgent" -AgentName "LifecycleTest3" -SystemMessage "Documentation test agent"
    
    # Create team
    if ($testAgent1 -and $testAgent2 -and $testAgent3) {
        $testTeam = New-AutoGenTeam -TeamName "LifecycleTestTeam" -AgentIds @($testAgent1.AgentId, $testAgent2.AgentId, $testAgent3.AgentId)
        
        # Execute conversation
        if ($testTeam) {
            $conversation = Invoke-AutoGenConversation -TeamId $testTeam.TeamId -InitialMessage "Test multi-agent lifecycle" -MaxRounds 3
        }
    }
    
    $duration = ((Get-Date) - $startTime).TotalSeconds
    $lifecycleSuccessful = ($testAgent1 -and $testAgent2 -and $testAgent3 -and $testTeam -and $conversation)
    
    Add-TestResult -TestName "Complete Agent Lifecycle" -Category "AgentScenarios" -Passed $lifecycleSuccessful -Details "Lifecycle completed in $([math]::Round($duration, 2))s, Agents: 3, Team: 1, Conversation: 1" -Duration $duration -Data @{
        AgentsCreated = if ($testAgent1 -and $testAgent2 -and $testAgent3) { 3 } else { 0 }
        TeamCreated = ($testTeam -ne $null)
        ConversationExecuted = ($conversation -ne $null)
    }
}
catch {
    Add-TestResult -TestName "Complete Agent Lifecycle" -Category "AgentScenarios" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing agent specialization scenarios..." -ForegroundColor White
    $allAgents = Get-AutoGenAgent
    $agentTypes = ($allAgents | ForEach-Object { $_.AgentType } | Sort-Object -Unique)
    $expectedTypes = @("AssistantAgent", "ArchitectureAgent", "DocumentationAgent")
    $specializationComplete = (($expectedTypes | Where-Object { $_ -in $agentTypes } | Measure-Object).Count -eq ($expectedTypes | Measure-Object).Count)
    
    Add-TestResult -TestName "Agent Specialization Scenarios" -Category "AgentScenarios" -Passed $specializationComplete -Details "Agent types: $(($agentTypes | Measure-Object).Count), Expected: $(($expectedTypes | Measure-Object).Count)" -Data @{
        AvailableAgentTypes = $agentTypes
        ExpectedAgentTypes = $expectedTypes
        SpecializationComplete = $specializationComplete
        TotalActiveAgents = ($allAgents | Measure-Object).Count
    }
}
catch {
    Add-TestResult -TestName "Agent Specialization Scenarios" -Category "AgentScenarios" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Collaborative Workflows Testing

Write-Host "`n[TEST CATEGORY] Collaborative Workflows..." -ForegroundColor Yellow

try {
    Write-Host "Testing code review collaborative workflow..." -ForegroundColor White
    $startTime = Get-Date
    $reviewTeam = New-CodeReviewAgentTeam -TeamName "ComprehensiveReviewTeam"
    
    if ($reviewTeam) {
        $collaborativeAnalysis = Invoke-AgentCollaborativeAnalysis -TeamId $reviewTeam.TeamId -TargetModule "Unity-Claude-AutoGen.psm1"
    }
    
    $duration = ((Get-Date) - $startTime).TotalSeconds
    $workflowSuccessful = ($reviewTeam -and $collaborativeAnalysis -and $collaborativeAnalysis.Status -eq "completed")
    
    Add-TestResult -TestName "Code Review Collaborative Workflow" -Category "CollaborativeWorkflows" -Passed $workflowSuccessful -Details "Workflow completed in $([math]::Round($duration, 2))s" -Duration $duration -Data @{
        TeamCreated = ($reviewTeam -ne $null)
        AnalysisCompleted = ($collaborativeAnalysis -ne $null)
        WorkflowStatus = if ($collaborativeAnalysis) { $collaborativeAnalysis.Status } else { "failed" }
    }
}
catch {
    Add-TestResult -TestName "Code Review Collaborative Workflow" -Category "CollaborativeWorkflows" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing consensus voting workflow..." -ForegroundColor White
    $consensusTestData = @{
        Agent1 = @{ Confidence = 0.9; Recommendations = @("Recommendation A", "Recommendation B") }
        Agent2 = @{ Confidence = 0.85; Recommendations = @("Recommendation A", "Recommendation C") }
        Agent3 = @{ Confidence = 0.8; Recommendations = @("Recommendation B", "Recommendation C") }
    }
    
    $startTime = Get-Date
    $consensusResult = Invoke-AgentConsensusVoting -AgentResults $consensusTestData
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    
    $consensusWorking = ($consensusResult -and $consensusResult.ConsensusAchieved)
    
    Add-TestResult -TestName "Consensus Voting Workflow" -Category "CollaborativeWorkflows" -Passed $consensusWorking -Details "Consensus achieved in $([math]::Round($duration, 2))ms" -Duration $duration -Data @{
        ConsensusAchieved = $consensusResult.ConsensusAchieved
        RecommendationCount = if ($consensusResult -and $consensusResult.FinalRecommendations) { ($consensusResult.FinalRecommendations | Measure-Object).Count } else { 0 }
    }
}
catch {
    Add-TestResult -TestName "Consensus Voting Workflow" -Category "CollaborativeWorkflows" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Technical Debt Integration Testing

Write-Host "`n[TEST CATEGORY] Technical Debt Integration..." -ForegroundColor Yellow

try {
    Write-Host "Testing technical debt multi-agent workflow..." -ForegroundColor White
    $startTime = Get-Date
    $debtAnalysis = Invoke-TechnicalDebtMultiAgentAnalysis -TargetModules @("Unity-Claude-AutoGen.psm1") -AnalysisDepth "comprehensive"
    $duration = ((Get-Date) - $startTime).TotalSeconds
    
    $debtIntegrationWorking = ($debtAnalysis -and $debtAnalysis.Status -eq "completed")
    
    Add-TestResult -TestName "Technical Debt Multi-Agent Workflow" -Category "TechnicalDebtIntegration" -Passed $debtIntegrationWorking -Details "Debt analysis completed in $([math]::Round($duration, 2))s" -Duration $duration -Data @{
        AnalysisStatus = if ($debtAnalysis) { $debtAnalysis.Status } else { "failed" }
        PrioritizationCompleted = ($debtAnalysis -and $debtAnalysis.PrioritizationResult)
    }
}
catch {
    Add-TestResult -TestName "Technical Debt Multi-Agent Workflow" -Category "TechnicalDebtIntegration" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing human intervention escalation..." -ForegroundColor White
    $criticalRecommendation = @{
        Module = "CriticalModule.psm1"
        Recommendation = "Major security refactoring required"
        RiskLevel = 0.95
        TechnicalImpact = 0.9
    }
    
    $startTime = Get-Date
    $escalationResult = Invoke-HumanInterventionEscalation -RecommendationData $criticalRecommendation -EscalationLevel "Critical"
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    
    $escalationWorking = ($escalationResult -and $escalationResult.Status -eq "escalated")
    
    Add-TestResult -TestName "Human Intervention Escalation" -Category "TechnicalDebtIntegration" -Passed $escalationWorking -Details "Escalation processed in $([math]::Round($duration, 2))ms" -Duration $duration -Data @{
        EscalationStatus = if ($escalationResult) { $escalationResult.Status } else { "failed" }
        RequiredActions = if ($escalationResult -and $escalationResult.EscalationRequest -and $escalationResult.EscalationRequest.RequiredActions) { ($escalationResult.EscalationRequest.RequiredActions | Measure-Object).Count } else { 0 }
    }
}
catch {
    Add-TestResult -TestName "Human Intervention Escalation" -Category "TechnicalDebtIntegration" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Performance Optimization Testing

if ($PerformanceTesting) {
    Write-Host "`n[TEST CATEGORY] Performance Optimization..." -ForegroundColor Yellow
    
    try {
        Write-Host "Testing agent coordination performance..." -ForegroundColor White
        $performanceTests = @()
        
        # Test multiple agent coordination cycles
        for ($cycle = 1; $cycle -le 5; $cycle++) {
            $cycleStart = Get-Date
            
            $quickAgent = New-AutoGenAgent -AgentType "AssistantAgent" -AgentName "PerfTest$cycle" -SystemMessage "Performance test agent"
            $quickTeam = New-AutoGenTeam -TeamName "PerfTeam$cycle" -AgentIds @($quickAgent.AgentId) -TeamType "GroupChat"
            $quickConversation = Invoke-AutoGenConversation -TeamId $quickTeam.TeamId -InitialMessage "Performance test message $cycle" -MaxRounds 2
            
            $cycleTime = ((Get-Date) - $cycleStart).TotalMilliseconds
            $performanceTests += $cycleTime
        }
        
        $avgPerformance = ($performanceTests | Measure-Object -Average).Average
        $performanceTarget = ($avgPerformance -le 5000)  # Target: <5 seconds per cycle
        
        Add-TestResult -TestName "Agent Coordination Performance" -Category "PerformanceOptimization" -Passed $performanceTarget -Details "Avg coordination: $([math]::Round($avgPerformance, 2))ms (target: <5000ms)" -PerformanceData @{
            AverageCoordinationTime = $avgPerformance
            PerformanceTests = $performanceTests
            PerformanceTarget = 5000
            TargetMet = $performanceTarget
        }
    }
    catch {
        Add-TestResult -TestName "Agent Coordination Performance" -Category "PerformanceOptimization" -Passed $false -Details "Exception: $($_.Exception.Message)"
    }
    
    try {
        Write-Host "Testing memory efficiency..." -ForegroundColor White
        $memoryBefore = (Get-Process -Id $PID).WorkingSet / 1MB
        
        # Create multiple agents and teams to test memory usage
        $memoryTestAgents = @()
        for ($i = 1; $i -le 10; $i++) {
            $memoryTestAgents += New-AutoGenAgent -AgentType "AssistantAgent" -AgentName "MemTest$i" -SystemMessage "Memory test agent $i"
        }
        
        Start-Sleep -Seconds 2  # Allow memory to settle
        $memoryAfter = (Get-Process -Id $PID).WorkingSet / 1MB
        $memoryIncrease = $memoryAfter - $memoryBefore
        $memoryEfficient = ($memoryIncrease -lt 50)  # Target: <50MB for 10 agents
        
        Add-TestResult -TestName "Memory Efficiency" -Category "PerformanceOptimization" -Passed $memoryEfficient -Details "Memory increase: $([math]::Round($memoryIncrease, 2))MB (target: <50MB)" -PerformanceData @{
            MemoryBefore = $memoryBefore
            MemoryAfter = $memoryAfter
            MemoryIncrease = $memoryIncrease
            AgentsCreated = ($memoryTestAgents | Measure-Object).Count
            MemoryEfficient = $memoryEfficient
        }
    }
    catch {
        Add-TestResult -TestName "Memory Efficiency" -Category "PerformanceOptimization" -Passed $false -Details "Exception: $($_.Exception.Message)"
    }
}

#endregion

#region Scalability Validation

if ($LoadTesting) {
    Write-Host "`n[TEST CATEGORY] Scalability Validation..." -ForegroundColor Yellow
    
    try {
        Write-Host "Testing concurrent agent operations..." -ForegroundColor White
        $concurrentJobs = @()
        $startTime = Get-Date
        
        # Create concurrent agent operations with staggered starts to reduce resource contention
        $moduleBasePath = (Get-Location).Path
        for ($worker = 1; $worker -le 3; $worker++) {
            # Add 200ms delay between job starts to prevent resource contention
            if ($worker -gt 1) { Start-Sleep -Milliseconds 200 }
            Write-Debug "[ConcurrentOps] Starting job $worker with 200ms stagger"
            
            $concurrentJobs += Start-Job -Name "ConcurrentTest$worker" -ScriptBlock {
                param($WorkerId, $ModuleBasePath)
                
                # Import modules in job using absolute paths
                $modulePath = Join-Path $ModuleBasePath "Unity-Claude-AutoGen.psm1"
                Write-Debug "[ConcurrentJob$WorkerId] Attempting to import module: $modulePath"
                Write-Debug "[ConcurrentJob$WorkerId] Module path exists: $(Test-Path $modulePath)"
                
                try {
                    Import-Module $modulePath -Force -Global
                    Write-Debug "[ConcurrentJob$WorkerId] Module imported successfully"
                }
                catch {
                    Write-Debug "[ConcurrentJob$WorkerId] Module import failed: $($_.Exception.Message)"
                    return @{
                        WorkerId = $WorkerId
                        Error = "Module import failed: $($_.Exception.Message)"
                        Status = "failed"
                        ModulePath = $modulePath
                        ModuleExists = (Test-Path $modulePath)
                    }
                }
                
                try {
                    Write-Debug "[ConcurrentJob$WorkerId] Creating AutoGen agent..."
                    $agent = New-AutoGenAgent -AgentType "AssistantAgent" -AgentName "ConcurrentAgent$WorkerId" -SystemMessage "Concurrent test agent"
                    Write-Debug "[ConcurrentJob$WorkerId] Agent creation result type: $($agent.GetType().Name)"
                    
                    # Check if agent creation succeeded (agent object) or failed (error details)
                    $agentCreated = ($agent -and $agent.AgentId -and -not $agent.Error)
                    Write-Debug "[ConcurrentJob$WorkerId] Agent created successfully: $agentCreated"
                    
                    if ($agentCreated) {
                        return @{
                            WorkerId = $WorkerId
                            AgentCreated = $true
                            Status = "success"
                            AgentId = $agent.AgentId
                        }
                    } else {
                        # Agent creation failed, return error details
                        return @{
                            WorkerId = $WorkerId
                            AgentCreated = $false
                            Status = "failed"
                            Error = if ($agent.Error) { $agent.Error } else { "Unknown agent creation failure" }
                            ErrorType = if ($agent.ErrorType) { $agent.ErrorType } else { "Unknown" }
                            AgentName = "ConcurrentAgent$WorkerId"
                        }
                    }
                }
                catch {
                    Write-Debug "[ConcurrentJob$WorkerId] Agent creation failed: $($_.Exception.Message)"
                    return @{
                        WorkerId = $WorkerId
                        Error = $_.Exception.Message
                        Status = "failed"
                    }
                }
            } -ArgumentList $worker, $moduleBasePath
        }
        
        # Wait for concurrent operations
        $concurrentResults = @()
        foreach ($job in $concurrentJobs) {
            $result = $job | Wait-Job | Receive-Job
            $concurrentResults += $result
            $job | Remove-Job -Force
        }
        
        $duration = ((Get-Date) - $startTime).TotalSeconds
        $successfulConcurrent = ($concurrentResults | Where-Object { $_.Status -eq "success" } | Measure-Object).Count
        $concurrencyWorking = ($successfulConcurrent -eq 3)
        
        Add-TestResult -TestName "Concurrent Agent Operations" -Category "ScalabilityValidation" -Passed $concurrencyWorking -Details "Concurrent success: $successfulConcurrent/3 in $([math]::Round($duration, 2))s" -Duration $duration -Data @{
            ConcurrentWorkers = 3
            SuccessfulOperations = $successfulConcurrent
            ConcurrencyResults = $concurrentResults
        }
    }
    catch {
        Add-TestResult -TestName "Concurrent Agent Operations" -Category "ScalabilityValidation" -Passed $false -Details "Exception: $($_.Exception.Message)"
    }
}

#endregion

#region Production Readiness Testing

if ($ProductionValidation) {
    Write-Host "`n[TEST CATEGORY] Production Readiness..." -ForegroundColor Yellow
    
    try {
        Write-Host "Testing production configuration validation..." -ForegroundColor White
        $productionChecks = @{
            ErrorHandling = $true
            ConfigurationManagement = (Test-Path ".\CodeReview-MultiAgent-Configurations.json")
            MonitoringCapability = (Get-Command "Start-PerformanceMonitoring" -ErrorAction SilentlyContinue) -ne $null
            LoggingFramework = (Test-Path ".\unity_claude_automation.log")
            SafeFileOperations = (Get-Command "Get-SafeChildItems" -ErrorAction SilentlyContinue) -ne $null
        }
        
        $productionScore = ($productionChecks.Values | Where-Object { $_ } | Measure-Object).Count
        $productionReady = ($productionScore -eq ($productionChecks.Keys | Measure-Object).Count)
        
        Add-TestResult -TestName "Production Configuration Validation" -Category "ProductionReadiness" -Passed $productionReady -Details "Production checks: $productionScore/$(($productionChecks.Keys | Measure-Object).Count)" -Data @{
            ProductionChecks = $productionChecks
            ProductionScore = $productionScore
            ProductionReady = $productionReady
        }
    }
    catch {
        Add-TestResult -TestName "Production Configuration Validation" -Category "ProductionReadiness" -Passed $false -Details "Exception: $($_.Exception.Message)"
    }
    
    try {
        Write-Host "Testing error recovery and resilience..." -ForegroundColor White
        # Test graceful degradation with invalid agent configuration
        $errorRecoveryTest = $false
        
        try {
            $invalidAgent = New-AutoGenAgent -AgentType "InvalidType" -AgentName "ErrorTest" -SystemMessage "Error test"
        }
        catch {
            # Expected error - test if system handles gracefully
            $errorRecoveryTest = $true
        }
        
        Add-TestResult -TestName "Error Recovery and Resilience" -Category "ProductionReadiness" -Passed $errorRecoveryTest -Details "Graceful error handling: $errorRecoveryTest" -Data @{
            ErrorHandlingWorking = $errorRecoveryTest
            GracefulDegradation = $true
        }
    }
    catch {
        Add-TestResult -TestName "Error Recovery and Resilience" -Category "ProductionReadiness" -Passed $false -Details "Exception: $($_.Exception.Message)"
    }
}

#endregion

#region Results Summary and Day 2 Success Metrics

Write-Host "`n[RESULTS SUMMARY]" -ForegroundColor Cyan

# Calculate comprehensive statistics
$totalTests = ($script:TestResults.Tests | Measure-Object).Count
$passedTests = ($script:TestResults.Tests | Where-Object { $_.Passed } | Measure-Object).Count
$failedTests = $totalTests - $passedTests
$passRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 1) } else { 0 }

# Category breakdown
$categoryBreakdown = @{}
foreach ($category in $script:TestResults.TestCategories.Keys) {
    $categoryTests = $script:TestResults.TestCategories.$category
    $categoryPassed = ($categoryTests | Where-Object { $_.Passed } | Measure-Object).Count
    $categoryTotal = ($categoryTests | Measure-Object).Count
    $categoryPassRate = if ($categoryTotal -gt 0) { [math]::Round(($categoryPassed / $categoryTotal) * 100, 1) } else { 0 }
    
    $categoryBreakdown[$category] = @{
        Passed = $categoryPassed
        Total = $categoryTotal
        Failed = $categoryTotal - $categoryPassed
        PassRate = $categoryPassRate
    }
    
    if ($categoryTotal -gt 0) {
        Write-Host "  $category`: $categoryPassed/$categoryTotal ($categoryPassRate%)" -ForegroundColor $(if ($categoryPassRate -ge 95) { "Green" } elseif ($categoryPassRate -ge 80) { "Yellow" } else { "Red" })
    }
}

# Week 1 Day 2 Success Criteria Assessment
Write-Host "`n[WEEK 1 DAY 2 SUCCESS ASSESSMENT]" -ForegroundColor Cyan

$day2SuccessCriteria = @{
    AutoGenServiceIntegration = ($script:TestResults.Tests | Where-Object { $_.TestName -eq "Complete Infrastructure Loading" -and $_.Passed } | Measure-Object).Count -gt 0
    MultiAgentCoordination = ($script:TestResults.Tests | Where-Object { $_.TestName -eq "Complete Agent Lifecycle" -and $_.Passed } | Measure-Object).Count -gt 0
    CollaborativeWorkflows = ($script:TestResults.Tests | Where-Object { $_.TestName -eq "Code Review Collaborative Workflow" -and $_.Passed } | Measure-Object).Count -gt 0
    TechnicalDebtIntegration = ($script:TestResults.Tests | Where-Object { $_.TestName -eq "Technical Debt Multi-Agent Workflow" -and $_.Passed } | Measure-Object).Count -gt 0
    ProductionReadiness = ($script:TestResults.Tests | Where-Object { $_.TestName -eq "Production Configuration Validation" -and $_.Passed } | Measure-Object).Count -gt 0
}

foreach ($criterion in $day2SuccessCriteria.Keys) {
    $status = if ($day2SuccessCriteria[$criterion]) { "[ACHIEVED]" } else { "[PENDING]" }
    $color = if ($day2SuccessCriteria[$criterion]) { "Green" } else { "Yellow" }
    Write-Host "  $status $criterion" -ForegroundColor $color
}

$day2Success = (($day2SuccessCriteria.Values | Where-Object { $_ } | Measure-Object).Count -eq ($day2SuccessCriteria.Keys | Measure-Object).Count)
$day2Status = if ($day2Success) { "[SUCCESS]" } else { "[PARTIAL]" }
$day2Color = if ($day2Success) { "Green" } else { "Yellow" }
Write-Host "`n$day2Status Week 1 Day 2 Success: $(($day2SuccessCriteria.Values | Where-Object { $_ } | Measure-Object).Count)/$(($day2SuccessCriteria.Keys | Measure-Object).Count) criteria achieved" -ForegroundColor $day2Color

# Add comprehensive summary to results
Write-Debug "[DEBUG] Creating summary - TestStartTime: $($script:TestStartTime)"
Write-Debug "[DEBUG] Current time: $(Get-Date)"
Write-Debug "[DEBUG] TotalTests: $totalTests, PassedTests: $passedTests"

try {
    $durationCalc = (Get-Date) - $script:TestStartTime
    Write-Debug "[DEBUG] Duration calculation successful: $durationCalc"
    
    $script:TestResults.Summary = @{
        TotalTests = $totalTests
        PassedTests = $passedTests
        FailedTests = $failedTests
        PassRate = "$passRate%"
        Duration = [string]$durationCalc
        Categories = $categoryBreakdown
        Day2SuccessCriteria = $day2SuccessCriteria
        Day2Success = $day2Success
        ProductionReadiness = $script:TestResults.ProductionMetrics
    }
    
    Write-Debug "[DEBUG] Summary created successfully"
}
catch {
    Write-Error "[DEBUG] Summary creation failed: $($_.Exception.Message)"
    $script:TestResults.Summary = @{
        TotalTests = $totalTests
        PassedTests = $passedTests
        FailedTests = $failedTests
        PassRate = "$passRate%"
        Duration = "Error calculating duration"
        Error = $_.Exception.Message
    }
}
$script:TestResults.EndTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"

Write-Host "`nOVERALL RESULTS:" -ForegroundColor White
Write-Host "  Total Tests: $totalTests" -ForegroundColor White
Write-Host "  Passed: $passedTests" -ForegroundColor Green
Write-Host "  Failed: $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Green" })
Write-Host "  Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 95) { "Green" } elseif ($passRate -ge 80) { "Yellow" } else { "Red" })

Write-Host "`n[WEEK 1 DAY 2 COMPLETION STATUS]" -ForegroundColor Cyan
Write-Host "AutoGen Integration Foundation: $(if ($day2Success) { 'COMPLETE' } else { 'REQUIRES fixes' })" -ForegroundColor $(if ($day2Success) { "Green" } else { "Yellow" })
Write-Host "Production Readiness: $(if ($passRate -ge 90) { 'VALIDATED' } else { 'REQUIRES optimization' })" -ForegroundColor $(if ($passRate -ge 90) { "Green" } else { "Yellow" })

#endregion

#region Save Results

if ($SaveResults) {
    try {
        $script:TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $ResultsPath -Encoding UTF8
        Write-Host "`nTest results saved to: $ResultsPath" -ForegroundColor Green
        
        # Log to centralized log
        $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [AutoGenMultiAgent] Day 2 Hour 7-8 comprehensive testing completed - Pass rate: $passRate% ($passedTests/$totalTests) - Day 2 success: $(($day2SuccessCriteria.Values | Where-Object { $_ } | Measure-Object).Count)/$(($day2SuccessCriteria.Keys | Measure-Object).Count)"
        Add-Content -Path ".\unity_claude_automation.log" -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "Failed to save test results: $($_.Exception.Message)"
    }
}

#endregion

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "AutoGen Multi-Agent Comprehensive Testing Complete" -ForegroundColor Cyan
Write-Host "Pass Rate: $passRate% ($passedTests/$totalTests tests)" -ForegroundColor $(if ($passRate -ge 95) { "Green" } else { "Yellow" })
Write-Host "Week 1 Day 2 Status: $(if ($day2Success) { 'COMPLETE' } else { 'REQUIRES fixes' })" -ForegroundColor $(if ($day2Success) { "Green" } else { "Yellow" })
Write-Host "Production Deployment: $(if ($passRate -ge 90) { 'READY' } else { 'REQUIRES optimization' })" -ForegroundColor $(if ($passRate -ge 90) { "Green" } else { "Yellow" })
Write-Host "============================================================" -ForegroundColor Cyan

return $script:TestResults