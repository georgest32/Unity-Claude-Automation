#region Module Header
<#
.SYNOPSIS
    Unity-Claude CLI Orchestrator Module - Refactored with Dot-Sourcing
    Phase 7 Advanced Features: Intelligent CLI Orchestration System
    
.DESCRIPTION
    Provides comprehensive autonomous CLI orchestration with intelligent window management,
    secure prompt submission, autonomous operations, and sophisticated decision making.
    This is the refactored version using dot-sourcing to avoid module nesting limit.
    
.VERSION
    2.1.0
    
.AUTHOR
    Unity-Claude-Automation
    
.DATE
    2025-08-27
    
.ARCHITECTURE
    This module uses dot-sourcing instead of NestedModules to avoid the PowerShell
    10-level module nesting limit. All component files are dot-sourced directly
    into this module's scope.
    
.FIX_NOTES
    Fixed module nesting limit issue by converting from NestedModules to dot-sourcing pattern.
    This allows all functions to be available without exceeding PowerShell's nesting limit.
#>
#endregion

#region Private Variables
$script:CLIOrchestratorConfig = @{
    IsRunning = $false
    Version = "2.1.0"
    Architecture = "Dot-Source-Based"
    StartTime = $null
    LastActivity = $null
    ComponentStatus = @{}
    SessionStats = @{
        PromptsSent = 0
        ResponsesProcessed = 0
        DecisionsMade = 0
        ActionsExecuted = 0
        ErrorCount = 0
    }
}

# Simple directive for backward compatibility
$script:SimpleDirective = " ================================================== CRITICAL: AT THE END OF YOUR RESPONSE, YOU MUST CREATE A RESPONSE .JSON FILE AT ./ClaudeResponses/Autonomous/ AND IN IT WRITE THE END OF YOUR RESPONSE, WHICH SHOULD END WITH: [RECOMMENDATION: CONTINUE]; [RECOMMENDATION: TEST <Name>]; [RECOMMENDATION: FIX <File>]; [RECOMMENDATION: COMPILE]; [RECOMMENDATION: RESTART <Module>]; [RECOMMENDATION: COMPLETE]; [RECOMMENDATION: ERROR <Description>]=================================================="

# Full boilerplate prompt stored as a resource  
$script:BoilerplatePrompt = $null
try {
    $boilerplatePath = Join-Path $PSScriptRoot "Resources\BoilerplatePrompt.txt"
    if (Test-Path $boilerplatePath) {
        $script:BoilerplatePrompt = Get-Content -Path $boilerplatePath -Raw
    }
} catch {
    Write-Verbose "Warning: Could not load boilerplate prompt file: $_"
}

if (-not $script:BoilerplatePrompt) {
    # Fallback to simple directive if file not found
    $script:BoilerplatePrompt = "Please process the following recommendation and provide a detailed response."
}
#endregion

#region Component Dot-Sourcing
# Dot-source all component files to avoid module nesting limit
Write-Verbose "CLIOrchestrator: Starting component dot-sourcing from $PSScriptRoot"

# Define component files in dependency order
$componentFiles = @(
    # Core window and submission components
    'Core\WindowManager.psm1',
    'Core\PromptSubmissionEngine.psm1',
    'Core\AutonomousOperations.psm1',
    
    # Analysis components - using fixed ResponseAnalysisEngine
    'Core\Components\AnalysisLogging.psm1',
    'Core\Components\CircuitBreaker.psm1', 
    'Core\Components\JsonProcessing.psm1',
    'Core\Components\ResponseAnalysisEngine-Core-Fixed.psm1',  # Uses fixed version with dot-sourcing
    
    # Pattern recognition components - loaded first as dependencies
    'Core\RecommendationPatternEngine.psm1',
    'Core\EntityContextEngine.psm1',
    'Core\ResponseClassificationEngine.psm1',
    'Core\BayesianConfidenceEngine.psm1',
    'Core\PatternRecognitionEngine-Fixed.psm1',  # Uses fixed version with dot-sourcing
    
    # Decision and execution components
    'Core\DecisionEngine.psm1',
    'Core\ActionExecutionEngine.psm1',
    
    # Orchestration components (must be last due to dependencies) - using fixed versions
    'Core\OrchestrationComponents\OrchestrationCore.psm1',
    'Core\OrchestrationComponents\MonitoringLoop.psm1',
    'Core\OrchestrationComponents\DecisionMaking-Fixed.psm1',
    'Core\OrchestrationComponents\DecisionExecution-Fixed.psm1'
)

# Track loaded components
$script:LoadedComponents = @()
$script:LoadErrors = @()

foreach ($componentFile in $componentFiles) {
    $fullPath = Join-Path $PSScriptRoot $componentFile
    $componentName = Split-Path $componentFile -Leaf
    
    Write-Host "[DEBUG] Processing component: $componentName" -ForegroundColor Yellow
    Write-Host "[DEBUG] Full path: $fullPath" -ForegroundColor Gray
    Write-Host "[DEBUG] Exists: $(Test-Path $fullPath)" -ForegroundColor Gray
    
    if (Test-Path $fullPath) {
        try {
            $functionsBefore = (Get-Command -CommandType Function | Measure-Object).Count
            . $fullPath
            $functionsAfter = (Get-Command -CommandType Function | Measure-Object).Count
            $newFunctions = $functionsAfter - $functionsBefore
            
            $script:LoadedComponents += $componentName
            Write-Host "[SUCCESS] Dot-sourced: $componentName (+$newFunctions functions)" -ForegroundColor Green
        }
        catch {
            $script:LoadErrors += "Failed to dot-source $componentName : $_"
            Write-Host "[ERROR] Failed to dot-source $componentName : $_" -ForegroundColor Red
        }
    }
    else {
        $script:LoadErrors += "Component file not found: $componentFile"
        Write-Host "[ERROR] Component file not found: $componentFile" -ForegroundColor Red
    }
}

Write-Verbose "CLIOrchestrator: Loaded $($script:LoadedComponents.Count) components"
if ($script:LoadErrors.Count -gt 0) {
    Write-Warning "CLIOrchestrator: $($script:LoadErrors.Count) components failed to load"
}
#endregion

#region Enhanced Orchestration Functions

function Initialize-CLIOrchestrator {
    <#
    .SYNOPSIS
        Initializes the CLI orchestrator system with all components
    .DESCRIPTION
        Performs comprehensive initialization of all orchestration components
        and validates system readiness for autonomous operations
    .PARAMETER ValidateComponents
        Validate all components during initialization
    .PARAMETER SetupDirectories
        Create required directories during initialization
    .EXAMPLE
        Initialize-CLIOrchestrator -ValidateComponents -SetupDirectories
    #>
    [CmdletBinding()]
    param(
        [switch]$ValidateComponents,
        [switch]$SetupDirectories
    )
    
    Write-Host "Initializing CLI Orchestrator v$($script:CLIOrchestratorConfig.Version)..." -ForegroundColor Cyan
    
    # Set initialization time
    $script:CLIOrchestratorConfig.StartTime = Get-Date
    $script:CLIOrchestratorConfig.LastActivity = Get-Date
    
    # Setup directories if requested
    if ($SetupDirectories) {
        $dirs = @(
            ".\ClaudeResponses\Autonomous",
            ".\Logs\CLIOrchestrator",
            ".\Config\CLIOrchestrator"
        )
        
        foreach ($dir in $dirs) {
            if (-not (Test-Path $dir)) {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                Write-Verbose "Created directory: $dir"
            }
        }
    }
    
    # Validate components if requested
    if ($ValidateComponents) {
        $validation = Test-CLIOrchestratorComponents
        if (-not $validation.AllComponentsLoaded) {
            Write-Warning "Not all components loaded successfully. See details:"
            $validation.MissingFunctions | ForEach-Object { Write-Warning "  Missing: $_" }
        }
    }
    
    # Update component status
    $script:CLIOrchestratorConfig.ComponentStatus = @{
        WindowManager = ($script:LoadedComponents -contains 'WindowManager.psm1')
        PromptSubmission = ($script:LoadedComponents -contains 'PromptSubmissionEngine.psm1')
        AutonomousOps = ($script:LoadedComponents -contains 'AutonomousOperations.psm1')
        ResponseAnalysis = ($script:LoadedComponents -contains 'ResponseAnalysisEngine-Core.psm1')
        PatternRecognition = ($script:LoadedComponents -contains 'PatternRecognitionEngine.psm1')
        DecisionEngine = ($script:LoadedComponents -contains 'DecisionEngine.psm1')
        ActionExecution = ($script:LoadedComponents -contains 'ActionExecutionEngine.psm1')
        OrchestrationCore = ($script:LoadedComponents -contains 'OrchestrationCore.psm1')
    }
    
    $script:CLIOrchestratorConfig.IsRunning = $true
    
    Write-Host "CLI Orchestrator initialized successfully!" -ForegroundColor Green
    Write-Host "  Architecture: $($script:CLIOrchestratorConfig.Architecture)" -ForegroundColor Gray
    Write-Host "  Loaded Components: $($script:LoadedComponents.Count)" -ForegroundColor Gray
    Write-Host "  Status: Ready for autonomous operations" -ForegroundColor Green
    
    return $true
}

function Test-CLIOrchestratorComponents {
    <#
    .SYNOPSIS
        Tests all CLI orchestrator components for proper loading
    .DESCRIPTION
        Validates that all required functions are available from dot-sourced components
    .OUTPUTS
        PSCustomObject with component test results
    #>
    [CmdletBinding()]
    param()
    
    $requiredFunctions = @(
        # WindowManager
        'Find-ClaudeWindow',
        'Update-ClaudeWindowInfo',
        'Switch-ToWindow',
        
        # PromptSubmission
        'Submit-ToClaudeViaTypeKeys',
        'Execute-TestScript',
        
        # AutonomousOperations
        'New-AutonomousPrompt',
        'Process-ResponseFile',
        'Get-ActionResultSummary',
        
        # OrchestrationManager  
        'Start-CLIOrchestration',
        'Get-CLIOrchestrationStatus',
        'Invoke-ComprehensiveResponseAnalysis',
        'Invoke-AutonomousDecisionMaking',
        'Invoke-DecisionExecution',
        
        # ResponseAnalysis
        'Invoke-EnhancedResponseAnalysis',
        
        # PatternRecognition
        'Invoke-PatternRecognitionAnalysis',
        
        # DecisionEngine
        'Invoke-RuleBasedDecision',
        
        # ActionExecution
        'Invoke-SafeAction'
    )
    
    $availableFunctions = @()
    $missingFunctions = @()
    
    foreach ($func in $requiredFunctions) {
        if (Get-Command $func -ErrorAction SilentlyContinue) {
            $availableFunctions += $func
        }
        else {
            $missingFunctions += $func
        }
    }
    
    $result = [PSCustomObject]@{
        Timestamp = Get-Date
        TotalRequired = $requiredFunctions.Count
        TotalAvailable = $availableFunctions.Count
        TotalMissing = $missingFunctions.Count
        AllComponentsLoaded = ($missingFunctions.Count -eq 0)
        LoadedComponents = $script:LoadedComponents
        LoadErrors = $script:LoadErrors
        AvailableFunctions = $availableFunctions
        MissingFunctions = $missingFunctions
        ComponentStatus = $script:CLIOrchestratorConfig.ComponentStatus
    }
    
    Write-Verbose "Component Test: $($result.TotalAvailable)/$($result.TotalRequired) functions available"
    
    return $result
}

function Get-CLIOrchestratorInfo {
    <#
    .SYNOPSIS
        Gets comprehensive information about the CLI orchestrator
    .DESCRIPTION
        Returns detailed status and configuration information
    .OUTPUTS
        PSCustomObject with orchestrator information
    #>
    [CmdletBinding()]
    param()
    
    $uptime = if ($script:CLIOrchestratorConfig.StartTime) {
        (Get-Date) - $script:CLIOrchestratorConfig.StartTime
    } else {
        [TimeSpan]::Zero
    }
    
    return [PSCustomObject]@{
        Version = $script:CLIOrchestratorConfig.Version
        Architecture = $script:CLIOrchestratorConfig.Architecture
        IsRunning = $script:CLIOrchestratorConfig.IsRunning
        StartTime = $script:CLIOrchestratorConfig.StartTime
        Uptime = $uptime
        LastActivity = $script:CLIOrchestratorConfig.LastActivity
        LoadedComponents = $script:LoadedComponents
        ComponentStatus = $script:CLIOrchestratorConfig.ComponentStatus
        SessionStats = $script:CLIOrchestratorConfig.SessionStats
        LoadErrors = $script:LoadErrors
    }
}

function Update-CLISessionStats {
    <#
    .SYNOPSIS
        Updates session statistics for monitoring
    .PARAMETER StatType
        Type of statistic to update
    .PARAMETER Value
        Value to add (default 1)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('PromptsSent', 'ResponsesProcessed', 'DecisionsMade', 'ActionsExecuted', 'ErrorCount')]
        [string]$StatType,
        
        [int]$Value = 1
    )
    
    if ($script:CLIOrchestratorConfig.SessionStats.ContainsKey($StatType)) {
        $script:CLIOrchestratorConfig.SessionStats[$StatType] += $Value
        $script:CLIOrchestratorConfig.LastActivity = Get-Date
        Write-Verbose "Updated $StatType : $($script:CLIOrchestratorConfig.SessionStats[$StatType])"
    }
}

#endregion

# Export all functions and aliases in a single call
# (Multiple Export-ModuleMember calls override each other)
Export-ModuleMember -Function @(
    # Orchestrator Management
    'Initialize-CLIOrchestrator',
    'Test-CLIOrchestratorComponents',
    'Get-CLIOrchestratorInfo',
    'Update-CLISessionStats',
    
    # WindowManager Functions
    'Update-ClaudeWindowInfo',
    'Find-ClaudeWindow',
    'Switch-ToWindow',
    
    # PromptSubmissionEngine Functions
    'Submit-ToClaudeViaTypeKeys',
    'Execute-TestScript',
    
    # AutonomousOperations Functions
    'New-AutonomousPrompt',
    'Get-ActionResultSummary',
    'Process-ResponseFile',
    'Invoke-AutonomousExecutionLoop',
    
    # OrchestrationManager Functions  
    'Start-CLIOrchestration',
    'Get-CLIOrchestrationStatus',
    'Invoke-ComprehensiveResponseAnalysis',
    'Invoke-AutonomousDecisionMaking',
    'Invoke-DecisionExecution',
    
    # Response Analysis Functions
    'Invoke-EnhancedResponseAnalysis',
    'Test-JsonTruncation',
    'Repair-TruncatedJson',
    'Extract-ResponseEntities',
    'Analyze-ResponseSentiment',
    'Get-ResponseContext',
    
    # Pattern Recognition Functions
    'Invoke-PatternRecognitionAnalysis',
    'Find-RecommendationPatterns',
    'Extract-ContextEntities',
    'Classify-ResponseType',
    'Calculate-OverallConfidence',
    
    # Decision Engine Functions
    'Invoke-RuleBasedDecision',
    'Resolve-PriorityDecision',
    'Test-SafetyValidation',
    'Test-SafeFilePath',
    'Test-SafeCommand',
    'Test-ActionQueueCapacity',
    'New-ActionQueueItem',
    'Get-ActionQueueStatus',
    'Resolve-ConflictingRecommendations',
    'Invoke-GracefulDegradation',
    
    # Circuit Breaker Functions
    'Test-CircuitBreakerState',
    'Update-CircuitBreakerState',
    
    # Action Execution Functions
    'Invoke-SafeAction',
    'Add-ActionToQueue',
    'Get-NextQueuedAction',
    'Get-ActionExecutionStatus',
    'Test-ActionSafety'
) -Alias @(
    'ico',  # Initialize-CLIOrchestrator
    'sco',  # Start-CLIOrchestration
    'gco',  # Get-CLIOrchestrationStatus
    'tco'   # Test-CLIOrchestratorComponents
)

Write-Verbose "Unity-Claude-CLIOrchestrator-Refactored module loaded successfully"