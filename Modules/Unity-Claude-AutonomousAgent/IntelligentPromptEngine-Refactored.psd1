@{
    # Module manifest for IntelligentPromptEngine-Refactored
    # Refactored modular architecture from 1,457-line monolithic module
    # Version 2.0.0 - Component-based intelligent prompt generation system
    
    RootModule = 'IntelligentPromptEngine-Refactored.psm1'
    ModuleVersion = '2.0.0'
    GUID = '1b2c3d4e-5f6a-7b8c-9d0e-1f2a3b4c5d6e'
    
    Author = 'Unity-Claude-Automation System'
    CompanyName = 'Unity-Claude-Automation'
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    
    Description = @'
IntelligentPromptEngine-Refactored: Advanced intelligent prompt generation system with modular architecture

ARCHITECTURE OVERVIEW:
This refactored module transforms a monolithic 1,457-line system into a component-based architecture 
with specialized modules handling distinct responsibilities under the 800-line maintainability threshold.

CORE COMPONENTS:
• PromptConfiguration.psm1 (50 lines): Configuration management and thread-safe collections
• ResultAnalysisEngine.psm1 (350 lines): Command result analysis with Unity-specific pattern recognition
• PromptTypeSelection.psm1 (400 lines): Decision tree-based prompt type selection logic
• PromptTemplateSystem.psm1 (350 lines): Template management and rendering system

KEY FEATURES:
✓ Intelligent command result analysis with classification (Success/Failure/Exception)
✓ Four-tier severity assessment system (Critical/High/Medium/Low)
✓ Decision tree logic for prompt type selection (Debugging/Test Results/Continue/ARP)
✓ Template-based prompt generation with contextual rendering
✓ Unity-specific error pattern recognition (compilation, build, test failures)
✓ Thread-safe concurrent collections for performance
✓ Comprehensive fallback mechanisms and error handling
✓ Pattern recognition and historical data analysis
✓ Confidence-based automation thresholds
✓ Enhanced orchestration with component health monitoring

DECISION TREE INTELLIGENCE:
The system uses sophisticated decision trees to select appropriate prompt types:
• Exception patterns → Debugging prompts (95% confidence)
• Failure severity assessment → Routing to specialized handlers
• Success patterns → Workflow continuation logic
• Context-aware branching for complex scenarios

TEMPLATE SYSTEM:
• Debugging templates with error analysis and solution frameworks
• Test result templates with pattern recognition and interpretation
• Continuation templates for successful workflow progression
• ARP (Analyze, Research, Plan) templates for complex problem resolution
• Default fallback templates with general analysis structure

PERFORMANCE OPTIMIZATIONS:
• Modular loading reduces memory footprint
• Component-based testing and health monitoring
• Thread-safe collections for concurrent operations
• Efficient pattern matching algorithms
• Configurable confidence thresholds for automation

REFACTORING BENEFITS:
• Reduced complexity from 1,457 to ~307 orchestrator lines
• Improved maintainability with focused components
• Enhanced testability of individual modules
• Better separation of concerns and single responsibility
• Simplified debugging and troubleshooting
'@
    
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Orchestration functions
        'Invoke-IntelligentPromptGeneration',
        'Get-PromptEngineStatus',
        'Initialize-IntelligentPromptEngine',
        
        # Re-exported component functions
        'Get-PromptEngineConfig',
        'Invoke-CommandResultAnalysis',
        'Invoke-PromptTypeSelection', 
        'New-PromptTemplate'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # List of all modules packaged with this module
    ModuleList = @(
        'IntelligentPromptEngine-Refactored.psm1',
        'Core\PromptConfiguration.psm1',
        'Core\ResultAnalysisEngine.psm1',
        'Core\PromptTypeSelection.psm1',
        'Core\PromptTemplateSystem.psm1'
    )
    
    # List of all files packaged with this module  
    FileList = @(
        'IntelligentPromptEngine-Refactored.psm1',
        'IntelligentPromptEngine-Refactored.psd1',
        'Core\PromptConfiguration.psm1',
        'Core\ResultAnalysisEngine.psm1',
        'Core\PromptTypeSelection.psm1',
        'Core\PromptTemplateSystem.psm1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            Tags = @(
                'IntelligentPromptGeneration',
                'CommandResultAnalysis', 
                'DecisionTrees',
                'TemplateSystem',
                'UnityAutomation',
                'ModularArchitecture',
                'PatternRecognition',
                'AutonomousAgent'
            )
            
            # Links
            ProjectUri = 'https://github.com/Unity-Claude-Automation'
            
            # Release notes
            ReleaseNotes = @'
Version 2.0.0 - Major Refactoring Release

BREAKING CHANGES:
• Modular architecture replaces monolithic 1,457-line module
• Component-based imports may require initialization sequence changes
• Enhanced error handling may change exception patterns

NEW FEATURES:
✓ Component-based modular architecture with 4 specialized modules
✓ Enhanced orchestration with health monitoring and status reporting  
✓ Improved decision tree logic with contextual branching
✓ Advanced template system with specialized prompt types
✓ Thread-safe concurrent collections for better performance
✓ Comprehensive component availability testing
✓ Fallback mechanisms with graceful degradation

IMPROVEMENTS:
• Reduced complexity: 1,457 lines → ~307 orchestrator + focused components
• Enhanced maintainability with single responsibility components
• Better testability and debugging capabilities  
• Improved error handling and recovery mechanisms
• Performance optimizations through modular loading
• Comprehensive documentation and component descriptions

COMPONENTS REFACTORED:
• PromptConfiguration: Configuration and thread-safe collections (50 lines)
• ResultAnalysisEngine: Command result analysis system (350 lines) 
• PromptTypeSelection: Decision tree prompt selection logic (400 lines)
• PromptTemplateSystem: Template management and rendering (350 lines)

MIGRATION NOTES:
• Update import statements to use IntelligentPromptEngine-Refactored
• Component functions remain compatible with existing API
• Enhanced status and health monitoring available
• Initialization function added for component verification
'@
        }
        
        # Component metadata for tracking and health monitoring
        ComponentMetadata = @{
            TotalComponents = 4
            ComponentSizes = @{
                'PromptConfiguration' = 50
                'ResultAnalysisEngine' = 350  
                'PromptTypeSelection' = 400
                'PromptTemplateSystem' = 350
            }
            RefactoringDate = '2025-08-25'
            OriginalSize = 1457
            RefactoredSize = 307
            SizeReduction = 78.9
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAYRkwTKeN5wlac
# RvWrT294RhzRlNia6j/mxbiNgpW/IqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBAZIk2YGuoncByBGfJ2mbXZ
# Sjh7zVnQgdZZosJcI8xSMA0GCSqGSIb3DQEBAQUABIIBAFJVNNByfDfTlfvvieNU
# PdRZKDUE0T7746fu6EWwdpVQO7wWwuMpBMzq7aVdE0gUzoC5Twu07INLcRgohTMe
# /BxYr3lQOw5Pu0a/ze0QtfM+C7HgTFAX2kLyiElir0ySIae7AC9x7+2v7vf2g648
# YNHucVSYIL+ZPmUpNeSxRzzMGOqhyZTjSaMzVb68IdKq29SYd9G4b7EnLqmDeReW
# YcHrJ/d3EYSlghY6zr7dpPDbuJMdZRhyy4GfLN3Kj/Bu1NTwjUQTCY5JevRRJ1EG
# /SeBehTu+9Ay/cx3ryY3tWqcNBwyDPg2mKLQKZnQaLqrlh3oazeGVn3wNRKPUj1R
# E0E=
# SIG # End signature block
