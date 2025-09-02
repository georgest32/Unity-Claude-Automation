# OrchestrationManager-Refactored.psm1
# Refactored orchestration manager that dot-sources component files

<#
.SYNOPSIS
    Unity-Claude CLI Orchestrator - Refactored Orchestration Management
    
.DESCRIPTION
    This is the refactored version of OrchestrationManager that breaks down
    the monolithic module into smaller, focused components for easier
    debugging and maintenance.
    
.COMPONENTS
    - OrchestrationCore: Main orchestration initialization and startup
    - MonitoringLoop: Monitoring loop and execution cycle management  
    - DecisionMaking: Autonomous decision making and analysis
    - DecisionExecution: Decision execution and action implementation
    
.NOTES
    Refactored: 2025-08-27
    Original file: OrchestrationManager.psm1 (978 lines)
    Refactored into: 4 component modules (~200-300 lines each)
    Updated to use dot-sourcing to avoid module nesting limit
#>

# Use dot-sourcing to avoid module nesting limit
$componentPath = Join-Path $PSScriptRoot "OrchestrationComponents"

# Dot-source each component file
$components = @(
    "OrchestrationCore.psm1",
    "MonitoringLoop.psm1",
    "DecisionMaking.psm1",
    "DecisionExecution.psm1"
)

foreach ($component in $components) {
    $componentFile = Join-Path $componentPath $component
    if (Test-Path $componentFile) {
        try {
            . $componentFile
            Write-Verbose "Dot-sourced component: $component"
        }
        catch {
            Write-Warning "Failed to dot-source component $component : $_"
        }
    }
    else {
        Write-Warning "Component not found: $componentFile"
    }
}

# Dot-source shared functions from other core modules if they exist
$corePath = $PSScriptRoot
$sharedFiles = @(
    "WindowManagement.psm1",
    "AutonomousOperations.psm1"
)

foreach ($file in $sharedFiles) {
    $filePath = Join-Path $corePath $file
    if (Test-Path $filePath) {
        try {
            # Check if functions are already available before dot-sourcing
            if (-not (Get-Command "Find-ClaudeWindow" -ErrorAction SilentlyContinue)) {
                . $filePath
                Write-Verbose "Dot-sourced shared file: $file"
            }
            else {
                Write-Verbose "Shared functions from $file already available"
            }
        }
        catch {
            Write-Verbose "Could not dot-source $file (may already be loaded): $_"
        }
    }
}

# Export all functions (they're now in the current scope via dot-sourcing)
Export-ModuleMember -Function @(
    # From OrchestrationCore
    'Start-CLIOrchestration',
    'Get-CLIOrchestrationStatus',
    'Initialize-OrchestrationEnvironment',
    
    # From MonitoringLoop
    'Start-MonitoringLoop',
    'Invoke-SingleExecutionCycle',
    'Process-SignalFile',
    
    # From DecisionMaking
    'Invoke-ComprehensiveResponseAnalysis',
    'Invoke-AutonomousDecisionMaking',
    'Test-DecisionSafety',
    
    # From DecisionExecution
    'Invoke-DecisionExecution',
    'Execute-TestAction',
    'Execute-ValidationAction',
    'Submit-TestResultsToClaude',
    'Execute-RecommendedAction',
    'Execute-SummaryAction'
)

Write-Verbose "OrchestrationManager-Refactored loaded successfully with dot-sourced components"