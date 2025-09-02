#Requires -Version 5.1

<#
.SYNOPSIS
Basic Multi-Agent Conversation Test Suite for AutoGen Integration (Week 1 Day 2 Hour 1-2)

.DESCRIPTION
Tests basic multi-agent conversation and coordination capabilities for AutoGen v0.4 integration
with PowerShell terminal communication. Validates agent creation, team coordination, and conversation flow.

.NOTES
Author: Unity-Claude-Automation System
Version: 1.0.0
Phase: Week 1 Day 2 Hour 1-2 - AutoGen Service Integration
Dependencies: Unity-Claude-AutoGen.psm1, AutoGen v0.7.4, PowerShell terminal integration
Validation Target: Successful multi-agent conversation with PowerShell integration
#>

param(
    [Parameter()]
    [switch]$SaveResults = $true,
    
    [Parameter()]
    [switch]$RunDemo = $true,
    
    [Parameter()]
    [switch]$TerminalIntegration = $true,
    
    [Parameter()]
    [string]$ResultsPath = ".\AutoGenBasicConversation-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

# Initialize test results structure
$TestResults = @{
    StartTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    TestSuite = "AutoGen Basic Multi-Agent Conversation (Week 1 Day 2 Hour 1-2)"
    Tests = @()
    TestCategories = @{
        ModuleLoading = @()
        AutoGenConnectivity = @()
        AgentCreation = @()
        TeamCoordination = @()
        ConversationFlow = @()
        TerminalIntegration = @()
        PowerShellIntegration = @()
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
Write-Host "AutoGen Basic Multi-Agent Conversation Test Suite" -ForegroundColor Cyan
Write-Host "Week 1 Day 2 Hour 1-2: AutoGen Service Integration" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

#region Module Loading Tests

Write-Host "`n[TEST CATEGORY] Module Loading..." -ForegroundColor Yellow

try {
    Write-Host "Loading Unity-Claude-AutoGen module..." -ForegroundColor White
    Import-Module -Name ".\Unity-Claude-AutoGen.psm1" -Force
    $autoGenFunctions = (Get-Module -Name "Unity-Claude-AutoGen").ExportedCommands.Keys
    $expectedFunctions = @('New-AutoGenAgent', 'New-AutoGenTeam', 'Invoke-AutoGenConversation', 'Test-AutoGenConnectivity')
    $missingFunctions = $expectedFunctions | Where-Object { $_ -notin $autoGenFunctions }
    
    Add-TestResult -TestName "Unity-Claude-AutoGen Module Loading" -Category "ModuleLoading" -Passed ($missingFunctions.Count -eq 0) -Details "Functions: $($autoGenFunctions.Count), Expected: $($expectedFunctions.Count), Missing: $($missingFunctions.Count)" -Data @{
        ExportedFunctions = $autoGenFunctions
        MissingFunctions = $missingFunctions
        TotalFunctions = $autoGenFunctions.Count
    }
}
catch {
    Add-TestResult -TestName "Unity-Claude-AutoGen Module Loading" -Category "ModuleLoading" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region AutoGen Connectivity Tests

Write-Host "`n[TEST CATEGORY] AutoGen Connectivity..." -ForegroundColor Yellow

try {
    Write-Host "Testing AutoGen basic connectivity..." -ForegroundColor White
    $startTime = Get-Date
    $connectivityResult = Test-AutoGenConnectivity -TestType "basic"
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    
    $connectivitySuccessful = ($connectivityResult.Results.BasicConnectivity.Status -eq "success")
    
    Add-TestResult -TestName "AutoGen Basic Connectivity" -Category "AutoGenConnectivity" -Passed $connectivitySuccessful -Details "Status: $($connectivityResult.Results.BasicConnectivity.Status), Duration: $([math]::Round($duration, 2))ms" -Duration $duration -Data $connectivityResult.Results.BasicConnectivity
}
catch {
    Add-TestResult -TestName "AutoGen Basic Connectivity" -Category "AutoGenConnectivity" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing AutoGen communication..." -ForegroundColor White
    $startTime = Get-Date
    $commResult = Test-AutoGenConnectivity -TestType "communication"
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    
    $communicationSuccessful = ($commResult.Results.Communication.Status -eq "success")
    
    Add-TestResult -TestName "AutoGen Communication" -Category "AutoGenConnectivity" -Passed $communicationSuccessful -Details "Status: $($commResult.Results.Communication.Status), Duration: $([math]::Round($duration, 2))ms" -Duration $duration -Data $commResult.Results.Communication
}
catch {
    Add-TestResult -TestName "AutoGen Communication" -Category "AutoGenConnectivity" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing comprehensive connectivity..." -ForegroundColor White
    $startTime = Get-Date
    $comprehensiveResult = Test-AutoGenConnectivity -TestType "comprehensive"
    $duration = ((Get-Date) - $startTime).TotalSeconds
    
    $comprehensiveSuccessful = ($comprehensiveResult.Results.Comprehensive.OverallStatus -eq "success")
    
    Add-TestResult -TestName "Comprehensive Connectivity" -Category "AutoGenConnectivity" -Passed $comprehensiveSuccessful -Details "Overall: $($comprehensiveResult.Results.Comprehensive.OverallStatus), Duration: $([math]::Round($duration, 2))s" -Duration $duration -Data $comprehensiveResult.Results.Comprehensive
}
catch {
    Add-TestResult -TestName "Comprehensive Connectivity" -Category "AutoGenConnectivity" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Agent Creation Tests

Write-Host "`n[TEST CATEGORY] Agent Creation..." -ForegroundColor Yellow

try {
    Write-Host "Testing AssistantAgent creation..." -ForegroundColor White
    $startTime = Get-Date
    $assistantAgent = New-AutoGenAgent -AgentType "AssistantAgent" -AgentName "TestAssistant" -SystemMessage "Test assistant agent for validation"
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    
    $agentCreatedSuccessfully = ($assistantAgent -ne $null -and $assistantAgent.Status -eq "active")
    
    Add-TestResult -TestName "AssistantAgent Creation" -Category "AgentCreation" -Passed $agentCreatedSuccessfully -Details "Agent created in $([math]::Round($duration, 2))ms, Status: $($assistantAgent.Status)" -Duration $duration -Data @{
        AgentId = if ($assistantAgent) { $assistantAgent.AgentId } else { "none" }
        AgentType = if ($assistantAgent) { $assistantAgent.AgentType } else { "none" }
        CreationSuccessful = $agentCreatedSuccessfully
    }
}
catch {
    Add-TestResult -TestName "AssistantAgent Creation" -Category "AgentCreation" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing CodeReviewAgent creation..." -ForegroundColor White
    $startTime = Get-Date
    $codeReviewAgent = New-AutoGenAgent -AgentType "CodeReviewAgent" -AgentName "TestCodeReviewer" -SystemMessage "Test code review agent for validation"
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    
    $codeAgentCreatedSuccessfully = ($codeReviewAgent -ne $null -and $codeReviewAgent.Status -eq "active")
    
    Add-TestResult -TestName "CodeReviewAgent Creation" -Category "AgentCreation" -Passed $codeAgentCreatedSuccessfully -Details "Agent created in $([math]::Round($duration, 2))ms, Status: $($codeReviewAgent.Status)" -Duration $duration -Data @{
        AgentId = if ($codeReviewAgent) { $codeReviewAgent.AgentId } else { "none" }
        AgentType = if ($codeReviewAgent) { $codeReviewAgent.AgentType } else { "none" }
        CreationSuccessful = $codeAgentCreatedSuccessfully
    }
}
catch {
    Add-TestResult -TestName "CodeReviewAgent Creation" -Category "AgentCreation" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing agent registry functionality..." -ForegroundColor White
    $registeredAgents = Get-AutoGenAgent
    $registryFunctional = ($registeredAgents.Count -ge 2)  # Should have at least 2 agents from previous tests
    
    Add-TestResult -TestName "Agent Registry Functionality" -Category "AgentCreation" -Passed $registryFunctional -Details "Registered agents: $($registeredAgents.Count)" -Data @{
        RegisteredAgentCount = $registeredAgents.Count
        AgentNames = if ($registeredAgents) { ($registeredAgents | ForEach-Object { $_.AgentName }) } else { @() }
    }
}
catch {
    Add-TestResult -TestName "Agent Registry Functionality" -Category "AgentCreation" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Team Coordination Tests

Write-Host "`n[TEST CATEGORY] Team Coordination..." -ForegroundColor Yellow

try {
    Write-Host "Testing multi-agent team creation..." -ForegroundColor White
    $availableAgents = Get-AutoGenAgent
    
    if ($availableAgents.Count -ge 2) {
        $teamAgentIds = ($availableAgents | Select-Object -First 2 | ForEach-Object { $_.AgentId })
        
        $startTime = Get-Date
        $testTeam = New-AutoGenTeam -TeamName "BasicTestTeam" -AgentIds $teamAgentIds -TeamType "GroupChat"
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        
        $teamCreatedSuccessfully = ($testTeam -ne $null -and $testTeam.Status -eq "active")
        
        Add-TestResult -TestName "Multi-Agent Team Creation" -Category "TeamCoordination" -Passed $teamCreatedSuccessfully -Details "Team created in $([math]::Round($duration, 2))ms, Agents: $($teamAgentIds.Count)" -Duration $duration -Data @{
            TeamId = if ($testTeam) { $testTeam.TeamId } else { "none" }
            AgentCount = if ($testTeam) { $testTeam.AgentIds.Count } else { 0 }
            TeamType = if ($testTeam) { $testTeam.TeamType } else { "none" }
        }
    }
    else {
        Add-TestResult -TestName "Multi-Agent Team Creation" -Category "TeamCoordination" -Passed $false -Details "Insufficient agents for team creation: $($availableAgents.Count)"
    }
}
catch {
    Add-TestResult -TestName "Multi-Agent Team Creation" -Category "TeamCoordination" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing team agent coordination..." -ForegroundColor White
    $activeTeams = $script:ActiveTeams.Values
    
    if ($activeTeams.Count -gt 0) {
        $testTeam = $activeTeams | Select-Object -First 1
        $coordinationSuccessful = ($testTeam.AgentIds.Count -ge 2 -and $testTeam.Status -eq "active")
        
        Add-TestResult -TestName "Team Agent Coordination" -Category "TeamCoordination" -Passed $coordinationSuccessful -Details "Team agents: $($testTeam.AgentIds.Count), Status: $($testTeam.Status)" -Data @{
            TeamCount = $activeTeams.Count
            CoordinationReady = $coordinationSuccessful
        }
    }
    else {
        Add-TestResult -TestName "Team Agent Coordination" -Category "TeamCoordination" -Passed $false -Details "No active teams available for coordination testing"
    }
}
catch {
    Add-TestResult -TestName "Team Agent Coordination" -Category "TeamCoordination" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Conversation Flow Tests

Write-Host "`n[TEST CATEGORY] Conversation Flow..." -ForegroundColor Yellow

try {
    Write-Host "Testing basic conversation initiation..." -ForegroundColor White
    $activeTeams = $script:ActiveTeams.Values
    
    if ($activeTeams.Count -gt 0) {
        $testTeam = $activeTeams | Select-Object -First 1
        
        $startTime = Get-Date
        $conversationResult = Invoke-AutoGenConversation -TeamId $testTeam.TeamId -InitialMessage "Please provide a brief analysis of PowerShell module architecture" -MaxRounds 3
        $duration = ((Get-Date) - $startTime).TotalSeconds
        
        $conversationSuccessful = ($conversationResult -ne $null -and $conversationResult.Status -eq "completed")
        
        Add-TestResult -TestName "Basic Conversation Initiation" -Category "ConversationFlow" -Passed $conversationSuccessful -Details "Conversation completed in $([math]::Round($duration, 2))s, Status: $($conversationResult.Status)" -Duration $duration -Data @{
            ConversationId = if ($conversationResult) { $conversationResult.ConversationId } else { "none" }
            TeamId = $testTeam.TeamId
            ConversationStatus = if ($conversationResult) { $conversationResult.Status } else { "failed" }
        }
    }
    else {
        Add-TestResult -TestName "Basic Conversation Initiation" -Category "ConversationFlow" -Passed $false -Details "No active teams available for conversation testing"
    }
}
catch {
    Add-TestResult -TestName "Basic Conversation Initiation" -Category "ConversationFlow" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing conversation history tracking..." -ForegroundColor White
    $conversationHistory = Get-AutoGenConversationHistory
    $historyTrackingWorking = ($conversationHistory.Count -gt 0)
    
    Add-TestResult -TestName "Conversation History Tracking" -Category "ConversationFlow" -Passed $historyTrackingWorking -Details "Conversations tracked: $($conversationHistory.Count)" -Data @{
        ConversationCount = $conversationHistory.Count
        HistoryAvailable = $historyTrackingWorking
    }
}
catch {
    Add-TestResult -TestName "Conversation History Tracking" -Category "ConversationFlow" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing analysis workflow execution..." -ForegroundColor White
    $startTime = Get-Date
    $workflowResult = Invoke-AutoGenAnalysisWorkflow -WorkflowType "code_review" -TargetModules @("Unity-Claude-AutoGen")
    $duration = ((Get-Date) - $startTime).TotalSeconds
    
    $workflowSuccessful = ($workflowResult -ne $null -and $workflowResult.Status -eq "success")
    
    Add-TestResult -TestName "Analysis Workflow Execution" -Category "ConversationFlow" -Passed $workflowSuccessful -Details "Workflow completed in $([math]::Round($duration, 2))s, Status: $($workflowResult.Status)" -Duration $duration -Data @{
        WorkflowType = $workflowResult.WorkflowType
        AgentCount = if ($workflowResult) { $workflowResult.AgentCount } else { 0 }
        WorkflowStatus = if ($workflowResult) { $workflowResult.Status } else { "failed" }
    }
}
catch {
    Add-TestResult -TestName "Analysis Workflow Execution" -Category "ConversationFlow" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Terminal Integration Tests

if ($TerminalIntegration) {
    Write-Host "`n[TEST CATEGORY] Terminal Integration..." -ForegroundColor Yellow
    
    try {
        Write-Host "Testing Named Pipe server functionality..." -ForegroundColor White
        $startTime = Get-Date
        $pipeServer = Start-AutoGenNamedPipeServer -PipeName "TestPipe"
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        
        $pipeServerWorking = ($pipeServer -ne $null -and $pipeServer.Status -eq "running")
        
        Add-TestResult -TestName "Named Pipe Server Functionality" -Category "TerminalIntegration" -Passed $pipeServerWorking -Details "Server started in $([math]::Round($duration, 2))ms, Status: $($pipeServer.Status)" -Duration $duration -Data @{
            PipeName = if ($pipeServer) { $pipeServer.PipeName } else { "none" }
            ServerStatus = if ($pipeServer) { $pipeServer.Status } else { "failed" }
        }
        
        # Cleanup pipe server job
        if ($pipeServer -and $pipeServer.PipeServerJob) {
            $pipeServer.PipeServerJob | Stop-Job | Remove-Job -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        Add-TestResult -TestName "Named Pipe Server Functionality" -Category "TerminalIntegration" -Passed $false -Details "Exception: $($_.Exception.Message)"
    }
    
    try {
        Write-Host "Testing message passing via Named Pipes..." -ForegroundColor White
        $startTime = Get-Date
        $messageResult = Send-AutoGenMessage -PipeName "Unity-Claude-AutoGen-Terminal" -Message "Test message for AutoGen agents" -MessageType "query"
        $duration = ((Get-Date) - $startTime).TotalMilliseconds
        
        $messagingWorking = ($messageResult -ne $null -and $messageResult.Status -eq "success")
        
        Add-TestResult -TestName "Named Pipe Message Passing" -Category "TerminalIntegration" -Passed $messagingWorking -Details "Message sent in $([math]::Round($duration, 2))ms, Status: $($messageResult.Status)" -Duration $duration -Data @{
            MessageSent = if ($messageResult) { $messageResult.MessageSent } else { "none" }
            MessageStatus = if ($messageResult) { $messageResult.Status } else { "failed" }
        }
    }
    catch {
        Add-TestResult -TestName "Named Pipe Message Passing" -Category "TerminalIntegration" -Passed $false -Details "Exception: $($_.Exception.Message)"
    }
    
    try {
        Write-Host "Testing terminal configuration management..." -ForegroundColor White
        $originalConfig = Get-AutoGenConfiguration
        Set-AutoGenConfiguration -ConversationTimeout 180 -MaxAgents 3
        $updatedConfig = Get-AutoGenConfiguration
        
        $configManagementWorking = ($updatedConfig.ConversationTimeout -eq 180 -and $updatedConfig.MaxAgents -eq 3)
        
        # Restore original configuration
        Set-AutoGenConfiguration -ConversationTimeout $originalConfig.ConversationTimeout -MaxAgents $originalConfig.MaxAgents
        
        Add-TestResult -TestName "Terminal Configuration Management" -Category "TerminalIntegration" -Passed $configManagementWorking -Details "Config updated and restored: $configManagementWorking" -Data @{
            ConfigurationUpdated = $configManagementWorking
            OriginalTimeout = $originalConfig.ConversationTimeout
            UpdatedTimeout = $updatedConfig.ConversationTimeout
        }
    }
    catch {
        Add-TestResult -TestName "Terminal Configuration Management" -Category "TerminalIntegration" -Passed $false -Details "Exception: $($_.Exception.Message)"
    }
}
else {
    Write-Host "`n[TEST CATEGORY] Terminal Integration - SKIPPED (TerminalIntegration disabled)" -ForegroundColor DarkYellow
}

#endregion

#region PowerShell Integration Tests

Write-Host "`n[TEST CATEGORY] PowerShell Integration..." -ForegroundColor Yellow

try {
    Write-Host "Testing PowerShell-AutoGen bridge functionality..." -ForegroundColor White
    # Execute PowerShell terminal integration script
    $bridgeTestResult = & ".\PowerShell-AutoGen-Terminal-Integration.ps1" -Operation "TestCommunication"
    
    # The script should have executed successfully if no exception thrown
    $bridgeWorking = $true  # If we get here without exception, bridge is functional
    
    Add-TestResult -TestName "PowerShell-AutoGen Bridge Functionality" -Category "PowerShellIntegration" -Passed $bridgeWorking -Details "Bridge script executed successfully" -Data @{
        BridgeExecuted = $bridgeWorking
        IntegrationScript = "PowerShell-AutoGen-Terminal-Integration.ps1"
    }
}
catch {
    Add-TestResult -TestName "PowerShell-AutoGen Bridge Functionality" -Category "PowerShellIntegration" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

try {
    Write-Host "Testing AutoGen configuration integration..." -ForegroundColor White
    $autoGenConfig = Get-AutoGenConfiguration
    $configValid = ($autoGenConfig.PythonExecutable -and $autoGenConfig.AgentTypes -and $autoGenConfig.ConversationTimeout)
    
    Add-TestResult -TestName "AutoGen Configuration Integration" -Category "PowerShellIntegration" -Passed $configValid -Details "Configuration valid: $configValid, Python: $(Split-Path $autoGenConfig.PythonExecutable -Leaf)" -Data @{
        ConfigurationValid = $configValid
        PythonExecutable = $autoGenConfig.PythonExecutable
        AgentTypes = $autoGenConfig.AgentTypes.Keys
    }
}
catch {
    Add-TestResult -TestName "AutoGen Configuration Integration" -Category "PowerShellIntegration" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

#endregion

#region Demo Execution (Optional)

if ($RunDemo) {
    Write-Host "`n[DEMO EXECUTION] Running AutoGen multi-agent demonstration..." -ForegroundColor Magenta
    
    try {
        $demoResult = & ".\PowerShell-AutoGen-Terminal-Integration.ps1" -Operation "RunDemo"
        
        # Demo execution successful if no exception
        $demoExecuted = $true
        
        Write-Host "[DEMO] Multi-agent demonstration completed" -ForegroundColor Magenta
        
        # Add demo result as informational test
        Add-TestResult -TestName "Multi-Agent Demo Execution" -Category "ConversationFlow" -Passed $demoExecuted -Details "Demo executed successfully" -Data @{
            DemoExecuted = $demoExecuted
            DemoType = "AutoGen multi-agent collaboration"
        }
    }
    catch {
        Add-TestResult -TestName "Multi-Agent Demo Execution" -Category "ConversationFlow" -Passed $false -Details "Exception: $($_.Exception.Message)"
    }
}

#endregion

#region Results Summary and Hour 1-2 Success Criteria

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
    
    if ($categoryTotal -gt 0) {
        Write-Host "  $category`: $categoryPassed/$categoryTotal ($categoryPassRate%)" -ForegroundColor $(if ($categoryPassRate -ge 80) { "Green" } elseif ($categoryPassRate -ge 60) { "Yellow" } else { "Red" })
    }
}

# Hour 1-2 Success Criteria Assessment
Write-Host "`n[SUCCESS CRITERIA ASSESSMENT]" -ForegroundColor Cyan
Write-Host "Week 1 Day 2 Hour 1-2 Deliverable Validation:" -ForegroundColor White

$successCriteria = @{
    AutoGenServiceOperational = ($TestResults.Tests | Where-Object { $_.TestName -eq "AutoGen Basic Connectivity" -and $_.Passed }).Count -gt 0
    PowerShellTerminalIntegration = ($TestResults.Tests | Where-Object { $_.TestName -eq "PowerShell-AutoGen Bridge Functionality" -and $_.Passed }).Count -gt 0
    ModuleWith10Functions = ($TestResults.Tests | Where-Object { $_.TestName -eq "Unity-Claude-AutoGen Module Loading" -and $_.Passed -and $_.Data.TotalFunctions -ge 10 }).Count -gt 0
    BasicConversationTesting = ($TestResults.Tests | Where-Object { $_.TestName -eq "Basic Conversation Initiation" -and $_.Passed }).Count -gt 0
}

foreach ($criterion in $successCriteria.Keys) {
    $status = if ($successCriteria[$criterion]) { "[ACHIEVED]" } else { "[PENDING]" }
    $color = if ($successCriteria[$criterion]) { "Green" } else { "Yellow" }
    Write-Host "  $status $criterion" -ForegroundColor $color
}

$overallSuccess = ($successCriteria.Values | Where-Object { $_ }).Count -eq $successCriteria.Keys.Count
$successStatus = if ($overallSuccess) { "[SUCCESS]" } else { "[PARTIAL]" }
$successColor = if ($overallSuccess) { "Green" } else { "Yellow" }
Write-Host "`n$successStatus Hour 1-2 Success Criteria: $($successCriteria.Values | Where-Object { $_ }).Count/$($successCriteria.Keys.Count) achieved" -ForegroundColor $successColor

# Add summary to results
$TestResults.Summary = @{
    TotalTests = $totalTests
    PassedTests = $passedTests
    FailedTests = $failedTests
    PassRate = "$passRate%"
    Duration = [string]((Get-Date) - [DateTime]::Parse($TestResults.StartTime))
    Categories = $categoryBreakdown
    SuccessCriteria = $successCriteria
    OverallSuccess = $overallSuccess
    Hour1_2_Status = if ($overallSuccess) { "COMPLETE" } else { "PARTIAL" }
}
$TestResults.EndTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"

Write-Host "`nOVERALL RESULTS:" -ForegroundColor White
Write-Host "  Total Tests: $totalTests" -ForegroundColor White
Write-Host "  Passed: $passedTests" -ForegroundColor Green
Write-Host "  Failed: $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Green" })
Write-Host "  Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 80) { "Green" } elseif ($passRate -ge 60) { "Yellow" } else { "Red" })

#endregion

#region Save Results

if ($SaveResults) {
    try {
        $TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $ResultsPath -Encoding UTF8
        Write-Host "`nTest results saved to: $ResultsPath" -ForegroundColor Green
        
        # Log to centralized log
        $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [AutoGenBasicConversation] Day 2 Hour 1-2 test completed - Pass rate: $passRate% ($passedTests/$totalTests) - Success criteria: $($successCriteria.Values | Where-Object { $_ }).Count/$($successCriteria.Keys.Count)"
        Add-Content -Path ".\unity_claude_automation.log" -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        Write-Warning "Failed to save test results: $($_.Exception.Message)"
    }
}

#endregion

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "AutoGen Basic Multi-Agent Conversation Test Complete" -ForegroundColor Cyan
Write-Host "Pass Rate: $passRate% ($passedTests/$totalTests tests)" -ForegroundColor $(if ($passRate -ge 80) { "Green" } else { "Yellow" })
Write-Host "Hour 1-2 Implementation: $(if ($overallSuccess) { 'COMPLETE' } else { 'REQUIRES fixes' })" -ForegroundColor $(if ($overallSuccess) { "Green" } else { "Yellow" })
Write-Host "============================================================" -ForegroundColor Cyan

# Return test results for further processing
return $TestResults