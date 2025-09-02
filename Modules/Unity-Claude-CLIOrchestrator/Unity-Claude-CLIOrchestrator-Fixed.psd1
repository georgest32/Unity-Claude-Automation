#
# Module manifest for module 'Unity-Claude-CLIOrchestrator'
# Fixed version that uses dot-sourcing to avoid module nesting limit
#

@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Unity-Claude-CLIOrchestrator-Refactored-Fixed.psm1'
    
    # Version number of this module.
    ModuleVersion = '2.1.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # ID used to uniquely identify this module
    GUID = 'b9c8d7e6-5f4e-4d3c-8b7a-9e8f7d6c5b4a'
    
    # Author of this module
    Author = 'Unity-Claude-Automation'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude-Automation'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = @'
Unity-Claude CLI Orchestrator Module - Fixed with Dot-Sourcing Architecture

Provides comprehensive autonomous CLI orchestration with intelligent window management,
secure prompt submission, autonomous operations, and sophisticated decision making.
This is the fixed version using dot-sourcing to avoid PowerShell's 10-level module nesting limit.

KEY FIX: Converted from NestedModules to dot-sourcing pattern to resolve module nesting limit errors.
All components are now dot-sourced directly in the main module file, eliminating nesting depth issues
while maintaining the component-based architecture.

FEATURES:
- Intelligent Claude CLI window detection and management
- Secure prompt submission using Windows API
- Autonomous execution loops with decision making
- Comprehensive response analysis with pattern recognition
- Rule-based and Bayesian decision engines
- Safe action execution with queuing and circuit breaker
- Advanced orchestration management with health monitoring

ARCHITECTURE:
- Dot-sourced components for zero nesting depth
- Explicit function exports for security
- Component-based design maintained
- Full backward compatibility preserved
'@
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Modules that must be imported into the global environment prior to importing this module
    # Note: We intentionally have NO RequiredModules to avoid nesting issues
    RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @(
        'System.Windows.Forms',
        'System.Drawing'
    )
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # IMPORTANT: We use NO NestedModules - all components are dot-sourced in the RootModule
    NestedModules = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Orchestrator Management Functions
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
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @('ico', 'sco', 'gco', 'tco')
    
    # List of all files packaged with this module
    FileList = @(
        'Unity-Claude-CLIOrchestrator-Refactored-Fixed.psm1',
        'Unity-Claude-CLIOrchestrator-Fixed.psd1',
        'Core\WindowManager.psm1',
        'Core\PromptSubmissionEngine.psm1',
        'Core\AutonomousOperations.psm1',
        'Core\OrchestrationComponents\OrchestrationCore.psm1',
        'Core\OrchestrationComponents\MonitoringLoop.psm1',
        'Core\OrchestrationComponents\DecisionMaking.psm1',
        'Core\OrchestrationComponents\DecisionExecution.psm1',
        'Core\Components\ResponseAnalysisEngine-Core.psm1',
        'Core\Components\AnalysisLogging.psm1',
        'Core\Components\CircuitBreaker.psm1',
        'Core\Components\JsonProcessing.psm1',
        'Core\PatternRecognitionEngine.psm1',
        'Core\EntityContextEngine.psm1',
        'Core\ResponseClassificationEngine.psm1',
        'Core\BayesianConfidenceEngine.psm1',
        'Core\RecommendationPatternEngine.psm1',
        'Core\DecisionEngine.psm1',
        'Core\ActionExecutionEngine.psm1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('CLI', 'Orchestration', 'Autonomous', 'AI', 'Automation', 'WindowManagement', 'TypeKeys', 'DecisionMaking', 'Unity', 'Claude', 'Fixed', 'DotSourcing')
            
            # Release notes of this module
            ReleaseNotes = @'
Version 2.1.0 - Module Nesting Limit Fix

CRITICAL FIX:
- Resolved "module nesting limit has been exceeded" error
- Converted from NestedModules to dot-sourcing architecture
- All components now dot-sourced directly in main module file
- Zero nesting depth - no more PowerShell 10-level limit issues

TECHNICAL CHANGES:
- Removed all NestedModules from manifest
- Implemented dot-sourcing pattern in main .psm1 file
- Explicit function exports maintained
- Component file structure preserved
- Full backward compatibility maintained

BENEFITS:
- Eliminates module nesting limit errors
- Slightly improved load performance
- Maintains component-based architecture
- All functions properly accessible
- Testing workflow now functional

TESTED:
- All core functions available
- Invoke-AutonomousDecisionMaking accessible
- Invoke-DecisionExecution accessible
- Process-ResponseFile functional
- Testing prompt-type workflow operational
'@
            
            # Flag to indicate whether the module requires explicit user acceptance
            RequireLicenseAcceptance = $false
            
            # External dependent modules of this module
            ExternalModuleDependencies = @()
        }
    }
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    
    # Default prefix for commands exported from this module
    # DefaultCommandPrefix = ''
}