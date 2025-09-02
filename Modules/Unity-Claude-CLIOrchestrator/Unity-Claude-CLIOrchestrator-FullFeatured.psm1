#region Module Header
<#
.SYNOPSIS
    Unity-Claude CLI Orchestrator Module - Full Featured Public/Private Architecture
    Phase 7 Advanced Features: Intelligent CLI Orchestration System with Public/Private Pattern
    
.DESCRIPTION
    Provides comprehensive autonomous CLI orchestration with intelligent window management,
    secure prompt submission, autonomous operations, and sophisticated decision making.
    This version uses the PowerShell community-standard Public/Private folder architecture
    with dot-sourcing for maximum performance and zero module nesting issues.
    
.VERSION
    3.0.0 (Full-Featured)
    
.AUTHOR
    Unity-Claude-Automation
    
.DATE
    2025-08-27
    
.ARCHITECTURE
    Public/Private Folder Architecture:
    - Public/: Functions exported to users (46 functions across 6 categories)
    - Private/: Helper functions and internal utilities
    - Uses .NET optimized file reading with dot-sourcing
    - Zero module nesting - all functions loaded directly
    - Explicit FunctionsToExport list for performance
    - PowerShell 5.1 compatible
#>
#endregion

#region Performance Optimizations
# Pre-compile .NET file operations for maximum performance
$script:FileOperations = @"
using System;
using System.IO;
using System.Collections.Generic;

public static class FastFileReader {
    public static string[] GetPS1Files(string directory) {
        if (!Directory.Exists(directory)) return new string[0];
        return Directory.GetFiles(directory, "*.ps1", SearchOption.AllDirectories);
    }
    
    public static string ReadFileContent(string path) {
        if (!File.Exists(path)) return string.Empty;
        return File.ReadAllText(path);
    }
}
"@

try {
    Add-Type -TypeDefinition $script:FileOperations -ErrorAction SilentlyContinue
} catch {
    # Fallback to PowerShell methods if .NET compilation fails
    Write-Verbose "Using PowerShell fallback for file operations"
}
#endregion

#region Private Variables and Configuration
$script:CLIOrchestratorConfig = @{
    IsRunning = $false
    Version = "3.0.0"
    Architecture = "Public/Private"
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

# Initialize decision engine configuration
$script:DecisionConfig = @{
    DecisionMatrix = @{
        "CONTINUE" = @{ Priority = 1; ActionType = "Continuation"; SafetyLevel = "Low" }
        "TEST" = @{ Priority = 2; ActionType = "TestExecution"; SafetyLevel = "Medium" }
        "FIX" = @{ Priority = 3; ActionType = "FileModification"; SafetyLevel = "High" }
        "COMPILE" = @{ Priority = 4; ActionType = "BuildOperation"; SafetyLevel = "Medium" }
        "RESTART" = @{ Priority = 5; ActionType = "ServiceRestart"; SafetyLevel = "High" }
        "COMPLETE" = @{ Priority = 6; ActionType = "TaskCompletion"; SafetyLevel = "Low" }
        "ERROR" = @{ Priority = 7; ActionType = "ErrorHandling"; SafetyLevel = "Low" }
    }
    SafetyThresholds = @{
        MinimumConfidence = 0.7
        MaxFileSize = 10MB
        AllowedFileExtensions = @('.ps1', '.psm1', '.psd1', '.json', '.txt', '.md', '.yml', '.yaml')
        BlockedPaths = @('C:\Windows', 'C:\Program Files', 'C:\Program Files (x86)')
        MaxConcurrentActions = 3
    }
    PerformanceTargets = @{ DecisionTimeMs = 100 }
}

# Initialize action queue status
$script:ActionQueueStatus = @{
    QueueSize = 0
    MaxQueueSize = 10
    CurrentActions = @()
    NextId = 1
}

# Boilerplate prompt configuration
$script:SimpleDirective = " ================================================== CRITICAL: AT THE END OF YOUR RESPONSE, YOU MUST CREATE A RESPONSE .JSON FILE AT ./ClaudeResponses/Autonomous/ AND IN IT WRITE THE END OF YOUR RESPONSE, WHICH SHOULD END WITH: [RECOMMENDATION: CONTINUE]; [RECOMMENDATION: TEST <Name>]; [RECOMMENDATION: FIX <File>]; [RECOMMENDATION: COMPILE]; [RECOMMENDATION: RESTART <Module>]; [RECOMMENDATION: COMPLETE]; [RECOMMENDATION: ERROR <Description>]=================================================="

$script:BoilerplatePrompt = $null
try {
    $boilerplatePath = Join-Path $PSScriptRoot "Resources\BoilerplatePrompt.txt"
    if (Test-Path $boilerplatePath) {
        $script:BoilerplatePrompt = Get-Content -Path $boilerplatePath -Raw
    }
} catch {
    Write-Verbose "Could not load boilerplate prompt file: $_"
}

if (-not $script:BoilerplatePrompt) {
    $script:BoilerplatePrompt = "Please process the following recommendation and provide a detailed response."
}
#endregion

#region Optimized Function Loading with Dot-Sourcing
Write-Verbose "Loading Unity-Claude-CLIOrchestrator functions using Public/Private architecture..."

# Get all PS1 files from Public and Private folders using optimized method
$publicFiles = @()
$privateFiles = @()

if ([System.Management.Automation.PSTypeName]'FastFileReader'.Type) {
    # Use compiled .NET method for maximum performance
    $publicPath = Join-Path $PSScriptRoot "Public"
    $privatePath = Join-Path $PSScriptRoot "Private"
    
    $publicFiles = [FastFileReader]::GetPS1Files($publicPath)
    $privateFiles = [FastFileReader]::GetPS1Files($privatePath)
} else {
    # Fallback to PowerShell methods
    $publicPath = Join-Path $PSScriptRoot "Public\*\*.ps1"
    $privatePath = Join-Path $PSScriptRoot "Private\*\*.ps1"
    
    if (Test-Path $publicPath) {
        $publicFiles = @(Get-ChildItem -Path $publicPath -File -ErrorAction SilentlyContinue | 
                        ForEach-Object { $_.FullName })
    }
    
    if (Test-Path $privatePath) {
        $privateFiles = @(Get-ChildItem -Path $privatePath -File -ErrorAction SilentlyContinue | 
                         ForEach-Object { $_.FullName })
    }
}

# Load Private functions first (internal utilities)
$privateCount = 0
foreach ($file in $privateFiles) {
    try {
        . $file
        $privateCount++
        Write-Verbose "Loaded private function: $(Split-Path $file -Leaf)"
    } catch {
        Write-Warning "Failed to load private function $(Split-Path $file -Leaf): $($_.Exception.Message)"
    }
}

# Load Public functions (exported functions)
$publicCount = 0
foreach ($file in $publicFiles) {
    try {
        . $file
        $publicCount++
        Write-Verbose "Loaded public function: $(Split-Path $file -Leaf)"
    } catch {
        Write-Warning "Failed to load public function $(Split-Path $file -Leaf): $($_.Exception.Message)"
    }
}

Write-Verbose "Function loading complete: $publicCount public, $privateCount private functions loaded"
#endregion

#region Fallback Core Functions
# Include essential functions inline as fallback if files don't load properly

if (-not (Get-Command Initialize-CLIOrchestrator -ErrorAction SilentlyContinue)) {
    function Initialize-CLIOrchestrator {
        param([switch]$ValidateComponents, [switch]$SetupDirectories)
        
        Write-Host "Initializing CLI Orchestrator System v3.0..." -ForegroundColor Cyan
        
        $script:CLIOrchestratorConfig.StartTime = Get-Date
        $script:CLIOrchestratorConfig.LastActivity = Get-Date
        $script:CLIOrchestratorConfig.IsRunning = $true
        
        return @{
            Version = "3.0.0"
            Initialized = $true
            Architecture = "Public/Private"
            InitializedAt = $script:CLIOrchestratorConfig.StartTime
        }
    }
}

if (-not (Get-Command Find-ClaudeWindow -ErrorAction SilentlyContinue)) {
    function Find-ClaudeWindow {
        $psProcessNames = @('pwsh', 'powershell', 'powershell_ise', 'WindowsTerminal')
        $psProcesses = Get-Process -Name $psProcessNames -ErrorAction SilentlyContinue | 
                      Where-Object { $_.MainWindowHandle -ne 0 }
        
        if ($psProcesses) {
            $fallbackProc = $psProcesses | Select-Object -First 1
            return $fallbackProc.MainWindowHandle
        }
        
        return $null
    }
}
#endregion

#region Module Initialization
# Initialize module state
if (-not $script:CLIOrchestratorConfig.StartTime) {
    $script:CLIOrchestratorConfig.StartTime = Get-Date
    $script:CLIOrchestratorConfig.LastActivity = Get-Date
}

Write-Verbose "Unity-Claude-CLIOrchestrator v3.0.0 (Public/Private Architecture) loaded successfully"
Write-Verbose "Ready for autonomous CLI orchestration with zero module nesting issues"
#endregion

#region Export All Public Functions
# Export all functions that should be available to users
# This list matches the 46 functions identified in the original implementation plan

Export-ModuleMember -Function @(
    # Core Functions (4)
    'Initialize-CLIOrchestrator',
    'Test-CLIOrchestratorComponents',
    'Get-CLIOrchestratorInfo',
    'Update-CLISessionStats',
    
    # WindowManager Functions (3)
    'Update-ClaudeWindowInfo',
    'Find-ClaudeWindow',
    'Switch-ToWindow',
    
    # AutonomousOperations Functions (4)
    'New-AutonomousPrompt',
    'Get-ActionResultSummary',
    'Process-ResponseFile',
    'Invoke-AutonomousExecutionLoop',
    
    # OrchestrationManager Functions (5)
    'Start-CLIOrchestration',
    'Get-CLIOrchestrationStatus',
    'Invoke-ComprehensiveResponseAnalysis',
    'Invoke-AutonomousDecisionMaking',
    'Invoke-DecisionExecution',
    
    # DecisionEngine Functions (10)
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
    
    # PromptSubmissionEngine Functions (2)
    'Submit-ToClaudeViaTypeKeys',
    'Execute-TestScript',
    
    # Additional Core Functions (18 - from existing Core components)
    'Invoke-EnhancedResponseAnalysis',
    'Test-JsonTruncation',
    'Repair-TruncatedJson',
    'Extract-ResponseEntities',
    'Analyze-ResponseSentiment',
    'Get-ResponseContext',
    'Invoke-PatternRecognitionAnalysis',
    'Find-RecommendationPatterns',
    'Extract-ContextEntities',
    'Classify-ResponseType',
    'Calculate-OverallConfidence',
    'Test-CircuitBreakerState',
    'Update-CircuitBreakerState',
    'Invoke-SafeAction',
    'Add-ActionToQueue',
    'Get-NextQueuedAction',
    'Get-ActionExecutionStatus',
    'Test-ActionSafety'
)
#endregion