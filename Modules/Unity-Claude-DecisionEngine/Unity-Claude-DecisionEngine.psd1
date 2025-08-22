#
# Module manifest for Unity-Claude-DecisionEngine
# Response Analysis and Decision Engine for Day 17 Integration
# Hybrid regex + AI parsing system with autonomous decision-making capabilities
#

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-DecisionEngine.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
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
        'Unity-Claude-DecisionEngine.psd1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('Unity', 'Claude', 'DecisionEngine', 'AI', 'AutonomousAgent', 'ResponseAnalysis', 'PowerShell')
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
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
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUuq97UnUTVwwV18gLEQuBO5oI
# +P2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU610GwrLnSlxLURgfYKlEoRN3D6EwDQYJKoZIhvcNAQEBBQAEggEAGHno
# dnUx+rDBtLc/AuCMYNl5kn6nFMJC6j3WLPGo//Uu0UHPg3SiSx+rlKdmLmaFbZXe
# F8bm9jT0qb+A0vlgZE/nwWZiCak1dGiPQE90NIPqr/rIC10iU7aBoKLh8JZhWabl
# 3qJf6ihvOPRAooo2BLZvlLDfu1wbDkjIsxyGR9CG8r0zywfA+jeWQwdUNrSl5sIa
# bvxJ3ceM9OTRP1tUHf/ZuzeUGKdNang8PcV5g7m90LQMxcsl/7Rr/eL2y9ij9lw9
# /pv+lF07JverC1E8/UGeIRTRLFSpe1ejJIr6Ig77ef2XbJSSM4vWQ/A0joijtVKB
# URtVCaX1qKGmjybKFA==
# SIG # End signature block
