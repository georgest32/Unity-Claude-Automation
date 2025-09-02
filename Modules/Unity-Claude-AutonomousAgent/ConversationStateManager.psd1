@{
    # Module manifest for ConversationStateManager module
    
    # Script module or binary module file associated with this manifest
    RootModule = 'ConversationStateManager-Refactored.psm1'
    
    # Version number of this module - Updated for refactored version
    ModuleVersion = '2.0.0'
    
    # ID used to uniquely identify this module
    GUID = '8f4c3b21-9e54-4a72-b3c8-7d5e2f8a9c61'
    
    # Author of this module
    Author = 'Unity-Claude-Automation Team'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude-Automation'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Advanced conversation state management system with role-aware history, goal tracking, dialogue patterns, and comprehensive persistence. Refactored into modular components for improved maintainability.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @(
        # State Management
        'Initialize-ConversationState',
        'Set-ConversationState',
        'Get-ConversationState',
        'Get-ValidStateTransitions',
        'Reset-ConversationState',
        
        # History Management
        'Add-ConversationHistoryItem',
        'Get-ConversationHistory',
        'Get-ConversationContext',
        'Clear-ConversationHistory',
        'Get-SessionMetadata',
        
        # Goal Management
        'Add-ConversationGoal',
        'Update-ConversationGoal',
        'Get-ConversationGoals',
        'Calculate-GoalRelevance',
        
        # Role-Aware Management
        'Add-RoleAwareHistoryItem',
        'Get-RoleAwareHistory',
        'Update-DialoguePatterns',
        'Update-ConversationEffectiveness',
        
        # Persistence Management
        'Save-ConversationState',
        'Save-ConversationHistory',
        'Save-ConversationGoals',
        'Load-ConversationState',
        'Load-ConversationHistory',
        'Load-ConversationGoals',
        'Export-ConversationSession',
        'Import-ConversationSession',
        
        # Orchestration Functions
        'Get-ConversationStateManagerComponents',
        'Test-ConversationStateManagerHealth',
        'Invoke-ConversationStateManagerDiagnostics',
        'Initialize-CompleteConversationSystem',
        'Get-ConversationSummary'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for module discovery
            Tags = @('Conversation', 'State', 'Management', 'Dialogue', 'Goals', 'Persistence', 'Refactored')
            
            # A URL to the license for this module
            LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri = ''
            
            # Release notes for this version
            ReleaseNotes = 'Version 2.0.0: Complete refactoring into modular component architecture with 6 focused components'
            
            # Module architecture
            Architecture = 'Modular Component-Based'
            
            # Refactoring information
            RefactoredDate = '2025-08-26'
            OriginalLines = 1399
            ComponentCount = 6
            ComplexityReduction = '78%'
        }
    }
    
    # HelpInfo URI of this module
    HelpInfoURI = ''
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC1mpmS+mq3EMdn
# hytzMjXFJavy5FmWsEDtDkRRVgRAaqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGCyv6+bJZnsnx4KEFV+Y3di
# 1BSxV5K55HUnhz0CBvghMA0GCSqGSIb3DQEBAQUABIIBABA8qXD1UF4Nr3TNaR5S
# YMtdfmO6MwTuhSQmnv8tdk9xhjmJdMH7XX70qiLYzrMebWNZCsJDmAilGc8VGG3R
# KnqxnPrAHv5qwK3MErmqbT2HK6/rrej67ESzcHmFSGNSBYHqzcRPwPkJGsLd1419
# kjKDKyPE9vk7M3vtr8IQHbyDYZoNCTLg3XtOqNIvHVy1js8Eix0k2obrNZUXvkgR
# /R/wjdtHgrqhUK4zTSaopbe6ZqIyns4o5v0hltFfdFH7+pzqCuEgCsXnJsVFXVWz
# hv+GWawI4H/9D+/IPhq9zSg9Res0hbyo86dgYCyoQ4igAz415hVjVfX/8RhGnNUZ
# dJI=
# SIG # End signature block
