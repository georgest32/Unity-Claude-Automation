#
# Module manifest for module 'Unity-Claude-CLIOrchestrator-Refactored'
#

@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Unity-Claude-CLIOrchestrator-Fixed-Simple.psm1'
    
    # Version number of this module.
    ModuleVersion = '2.0.0'
    
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
Unity-Claude CLI Orchestrator Module - Refactored Architecture

Provides comprehensive autonomous CLI orchestration with intelligent window management,
secure prompt submission, autonomous operations, and sophisticated decision making.
This is the refactored version featuring a component-based architecture for improved
maintainability and enhanced functionality.

ARCHITECTURE OVERVIEW:
- WindowManager: Claude CLI window detection and management using Windows APIs
- PromptSubmissionEngine: Secure TypeKeys prompt submission with safety measures and input blocking
- AutonomousOperations: Autonomous prompt generation, execution loops, and response processing
- OrchestrationManager: Main orchestration control, status monitoring, and decision coordination
- (Existing) ResponseAnalysisEngine: Advanced response analysis and JSON processing
- (Existing) PatternRecognitionEngine: Pattern recognition and confidence calculation
- (Existing) DecisionEngine: Rule-based and Bayesian decision making with safety validation
- (Existing) ActionExecutionEngine: Safe action execution with queuing and circuit breaker

REFACTORING BENEFITS:
- Improved maintainability with focused components (~402 lines average for new components)
- Enhanced testability with isolated functionality
- Better error isolation and debugging capabilities
- Easier feature development and extension
- Preserved existing Core component functionality
- Maintained full backward compatibility

ORIGINAL: 1,610 lines in single monolithic module
REFACTORED: 4 new components + 4 existing Core components for hybrid architecture

KEY FEATURES:
- Intelligent Claude CLI window detection with multiple fallback methods
- Secure prompt submission using Windows API with input blocking and cursor management
- Autonomous execution loops with decision making and response processing
- Comprehensive response analysis with pattern recognition and confidence scoring
- Rule-based and Bayesian decision engines with safety validation
- Safe action execution with queuing, circuit breaker, and rollback capabilities
- Advanced orchestration management with health monitoring and statistics tracking
- Full backward compatibility with all existing functions and workflows

SAFETY FEATURES:
- Input blocking during prompt submission to prevent interference
- Multi-level safety validation for all autonomous actions
- Circuit breaker pattern for error recovery and graceful degradation
- Comprehensive error handling and rollback mechanisms
- User abort capabilities during critical operations

MONITORING & ANALYTICS:
- Real-time system health monitoring and component status tracking
- Comprehensive session statistics and performance metrics
- Advanced pattern recognition for response analysis
- Predictive analysis and confidence scoring
- Detailed logging and audit trails
'@
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''
    
    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''
    
    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''
    
    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''
    
    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @(
        'System.Windows.Forms',
        'System.Drawing'
    )
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules removed - all components are dot-sourced in the RootModule to avoid nesting limit
    NestedModules = @()
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        # New Orchestration Functions
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
        
        # Legacy Functions (maintained for backward compatibility)
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
        
        # Pattern Recognition Functions
        'Invoke-PatternRecognitionAnalysis',
        'Find-RecommendationPatterns',
        'Extract-ContextEntities',
        'Classify-ResponseType',
        'Calculate-OverallConfidence',
        
        # Response Analysis Functions
        'Invoke-EnhancedResponseAnalysis',
        'Test-JsonTruncation',
        'Repair-TruncatedJson',
        'Extract-ResponseEntities',
        'Analyze-ResponseSentiment',
        'Get-ResponseContext',
        
        # Action Execution Functions
        'Invoke-SafeAction',
        'Add-ActionToQueue',
        'Get-NextQueuedAction',
        'Get-ActionExecutionStatus',
        'Test-ActionSafety'
    )
    
    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @('ico', 'sco', 'fco', 'aco')
    
    # DSC resources to export from this module
    # DscResourcesToExport = @()
    
    # List of all modules packaged with this module
    # ModuleList = @()
    
    # List of all files packaged with this module
    FileList = @(
        'Unity-Claude-CLIOrchestrator-Refactored.psm1',
        'Unity-Claude-CLIOrchestrator-Refactored.psd1',
        'Core\WindowManager.psm1',
        'Core\PromptSubmissionEngine.psm1',
        'Core\AutonomousOperations.psm1',
        'Core\OrchestrationManager.psm1',
        'Core\ResponseAnalysisEngine.psm1',
        'Core\PatternRecognitionEngine.psm1',
        'Core\DecisionEngine.psm1',
        'Core\ActionExecutionEngine.psm1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('CLI', 'Orchestration', 'Autonomous', 'AI', 'Automation', 'WindowManagement', 'TypeKeys', 'DecisionMaking', 'Unity', 'Claude', 'Refactored')
            
            # A URL to the license for this module.
            LicenseUri = ''
            
            # A URL to the main website for this project.
            ProjectUri = ''
            
            # A URL to an icon representing this module.
            IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
Version 2.0.0 - Refactored Architecture Release

MAJOR CHANGES:
- Complete refactoring from monolithic 1,610-line module to component-based architecture
- 4 new focused components: WindowManager, PromptSubmissionEngine, AutonomousOperations, OrchestrationManager
- Preserved existing 4 Core components: ResponseAnalysisEngine, PatternRecognitionEngine, DecisionEngine, ActionExecutionEngine
- Average new component size: ~402 lines (down from 1,610 monolithic)
- Enhanced maintainability, testability, and modularity

NEW FEATURES:
- Component health monitoring with Test-CLIOrchestratorComponents
- Comprehensive system information via Get-CLIOrchestratorInfo
- Enhanced initialization with Initialize-CLIOrchestrator
- Session statistics tracking with Update-CLISessionStats
- Improved error isolation between components
- Better debugging and troubleshooting capabilities

ARCHITECTURE IMPROVEMENTS:
- Separation of concerns with focused components
- Improved code organization and readability
- Enhanced testability with isolated functionality
- Better error handling and recovery mechanisms
- Easier feature development and extension
- Preserved full backward compatibility

COMPONENT BREAKDOWN:
- WindowManager (272 lines): Claude CLI window detection and management using Windows APIs
- PromptSubmissionEngine (310 lines): Secure TypeKeys prompt submission with safety measures
- AutonomousOperations (490 lines): Autonomous prompt generation, execution loops, and response processing
- OrchestrationManager (536 lines): Main orchestration control, status monitoring, and decision coordination
- (Existing) ResponseAnalysisEngine: Advanced response analysis and JSON processing
- (Existing) PatternRecognitionEngine: Pattern recognition and confidence calculation
- (Existing) DecisionEngine: Rule-based and Bayesian decision making with safety validation
- (Existing) ActionExecutionEngine: Safe action execution with queuing and circuit breaker

SAFETY ENHANCEMENTS:
- Enhanced input blocking during prompt submission
- Multi-level safety validation for all autonomous actions
- Improved circuit breaker pattern implementation
- Comprehensive error handling and rollback mechanisms
- Enhanced user abort capabilities during critical operations

MONITORING IMPROVEMENTS:
- Real-time system health monitoring
- Component status tracking and reporting
- Enhanced session statistics and performance metrics
- Advanced pattern recognition capabilities
- Improved logging and audit trails

BENEFITS:
- 75% reduction in component complexity (avg 402 vs 1,610 lines)
- Improved maintainability and code organization
- Enhanced debugging capabilities with component isolation
- Better separation of concerns and single responsibility principle
- Easier testing and validation of individual components
- More focused development workflow
- Preserved all existing functionality and workflows

COMPATIBILITY:
- Fully backward compatible with existing functionality
- All original functions preserved and enhanced
- New orchestration functions for improved management
- Enhanced error handling and recovery mechanisms
- Maintained all existing APIs and interfaces
'@
            
            # Prerelease string of this module
            # Prerelease = ''
            
            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            RequireLicenseAcceptance = $false
            
            # External dependent modules of this module
            ExternalModuleDependencies = @()
        }
    }
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    
    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB40Ux/KngBXaQF
# jJzOe5nuugZwcPbyKKhckQqkaSQggKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAmAlGTdW4ZcjEpiQRcFitJD
# MaZLuEqOQfZgW1g3/Ja5MA0GCSqGSIb3DQEBAQUABIIBAGjy0vmzoQKq+6oY9OWy
# PGz2bDtVHjvvHSr9tlo5gcbmCaYMnBhVo0gqboKCXqmL9L29k5tFuVawpyAz8Nfu
# n9urzrBBkQfJK5Qp0KiQNu24PZsNpja8sxpZ5rzJ2mPyS2rfnKJoE+wVrOqEe5V1
# ruB6Qn+sA65bh5HLR6QeGnrC6cvMTFSN7yUMk/CYSCfjX328w3GIHu6VQNwafBqX
# g/k9Vnbn/EHbCgLNRhoCvQm8mKtYtmub31mZ8gmvzg4/64WCAbUYyxiVDrZaZPiC
# CvnQqQfJr6xKez7lb8NdbDX2hSShw+JFndUuVHWspMR7sv6jmaBher/ejgGMfVDf
# NME=
# SIG # End signature block
