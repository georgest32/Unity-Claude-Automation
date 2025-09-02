#
# Module manifest for Unity-Claude-DecisionEngine
# Response Analysis and Decision Engine for Day 17 Integration
# Hybrid regex + AI parsing system with autonomous decision-making capabilities
#

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-DecisionEngine-Refactored.psm1'
    
    # Version number of this module
    ModuleVersion = '2.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop')
    
    # ID used to uniquely identify this module
    GUID = 'b8f3d6e2-4c9a-5d7e-1b2f-8a5c6e3d9b7a'
    
    # Author of this module
    Author = 'Unity-Claude Automation System'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude Automation'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude Automation. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Response Analysis and Decision Engine with hybrid regex + AI parsing, autonomous decision-making, and conversation management integration'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Minimum version of Microsoft .NET Framework required by this module
    DotNetFrameworkVersion = '4.5'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Core Analysis Functions
        'Invoke-HybridResponseAnalysis'
        'Invoke-RegexBasedAnalysis'
        'Invoke-AIEnhancedAnalysis'
        'Merge-AnalysisResults'
        'Add-ContextualEnrichment'
        
        # Decision Making Functions
        'Invoke-AutonomousDecision'
        'Invoke-DecisionTree'
        'Apply-ContextualAdjustments'
        'Invoke-DecisionValidation'
        'Add-DecisionToHistory'
        
        # Semantic Analysis Functions
        'Get-IntentClassification'
        'Get-SemanticContext'
        'Get-SemanticActions'
        'Calculate-SemanticConfidence'
        
        # Context Management Functions
        'Get-ConversationFlowAnalysis'
        'Get-ConversationConsistency'
        'Get-LastSimilarResponse'
        
        # Integration Functions
        'Connect-IntelligentPromptEngine'
        'Connect-ConversationManager'
        
        # Configuration Functions
        'Get-DecisionEngineConfig'
        'Set-DecisionEngineConfig'
        
        # Status and Management Functions
        'Get-DecisionEngineStatus'
        'Get-DecisionHistory'
        'Clear-DecisionHistory'
        'Test-DecisionEngineIntegration'
        
        # Orchestration Functions (NEW)
        'Get-DecisionEngineComponentStatus'
        'Invoke-DecisionEngineAnalysis'
        'Reset-DecisionEngine'
        'Test-DecisionEngineDeployment'
        'Get-DecisionEngineComponents'
        'Test-DecisionEngineHealth'
        'Write-DecisionEngineLog'
        'Test-RequiredModule'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # List of all files packaged with this module
    FileList = @(
        'Unity-Claude-DecisionEngine.psm1'
        'Unity-Claude-DecisionEngine-Refactored.psm1'
        'Unity-Claude-DecisionEngine.psd1'
        'Core\DecisionEngineCore.psm1'
        'Core\ResponseAnalysis.psm1'
        'Core\DecisionMaking.psm1'
        'Core\IntegrationManagement.psm1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('Unity', 'Claude', 'DecisionEngine', 'AI', 'AutonomousAgent', 'ResponseAnalysis', 'PowerShell')
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
Version 2.0.0 (Refactored):
- Complete modularization into 4 focused components
- 78% complexity reduction per component (avg 320 lines vs 1,284)
- Preserved all functionality with enhanced orchestration
- Component architecture: DecisionEngineCore, ResponseAnalysis, DecisionMaking, IntegrationManagement
- New orchestration functions for component health monitoring
- Backward compatibility maintained with all existing functions
- Enhanced deployment testing and validation capabilities

Version 1.0.0:
- Hybrid regex + AI parsing system for Claude response analysis
- Research-validated named capture group patterns for 2025
- Autonomous decision-making with confidence-based validation
- Intent classification and semantic context extraction
- Conversation flow analysis and contextual enrichment
- Decision tree with safety validation and risk assessment
- Integration with IntelligentPromptEngine and ConversationStateManager
- Learning-enabled decision history with pattern recognition
- PowerShell 5.1 compatibility with .NET Framework 4.5 support
- Comprehensive logging with unity_claude_automation.log integration
'@
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBBwyqulo4WdkR1
# 5l0kPrL8tofJ0A5e2+3gV8ZjpvhC/aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPs6lmkEzQ2B99Oy/qoljK0O
# IMgdWTGno/M5tUl+/o/lMA0GCSqGSIb3DQEBAQUABIIBADcFseBs3W7Ng9hrh6uL
# rnWURYsNbrCmVH/hPP5Zc0mtEhET5+EEuoV/3lqop+KzC1RrWMkVYnts8EFs7+DH
# xjerd+ZX0i3M2t1lVH64S5FnjDC8CQWBdGXg70hs3434/vH/M2sHq1I7xj+zOCHS
# xoeJOhc/DV2OUNKtQ4KjVI98O2/DzlcjZKy6D+EGTVk5+505iPoLjkYv+6tJpNAS
# lgR4QutRUOXQeKkHi2u9fkiaPWnYOsxVla5RHGuA+LOY/omdFqhe75VrhrrQG0sn
# +HL1iHYwIn9h9GYrwzpFESsnBTX2Ns3jDhW9c0x6i3pX9EVk/Hh6EH5dIr1hw6gy
# yXY=
# SIG # End signature block
