@{
    # Module metadata
    ModuleVersion = '1.3.0'
    GUID = 'a7d4c8e1-5f9a-4b2d-8c3e-1f6a9b4c7e2d'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude-Automation Project'
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    Description = 'Autonomous agent module for complete Claude Code CLI feedback loop automation with conversation state management, context optimization, and session persistence'
    
    # PowerShell version requirements
    PowerShellVersion = '5.1'
    
    # Root module file
    RootModule = 'Unity-Claude-AutonomousAgent.psm1'
    
    # Required modules
    RequiredModules = @()
    
    # Required assemblies
    RequiredAssemblies = @()
    
    # Functions to export
    FunctionsToExport = @(
        # Core Agent Functions
        'Initialize-AgentLogging',
        'Start-ClaudeResponseMonitoring', 
        'Stop-ClaudeResponseMonitoring',
        'Write-AgentLog',
        'Invoke-ProcessClaudeResponse',
        'Find-ClaudeRecommendations',
        'Add-RecommendationToQueue',
        'Invoke-ProcessCommandQueue',
        'Invoke-SafeRecommendedCommand',
        'New-FollowUpPrompt',
        'Submit-PromptToClaude',
        'Find-UnityExecutable',
        'Invoke-TestCommand',
        'Invoke-UnityTests',
        'Invoke-CompilationTest',
        'Invoke-PowerShellTests',
        'Invoke-BuildCommand',
        'Invoke-AnalyzeCommand',
        'Get-PatternConfidence',
        'Convert-TypeToStandard',
        'Convert-ActionToType', 
        'Normalize-RecommendationType',
        'Remove-DuplicateRecommendations',
        'Get-StringSimilarity',
        'Classify-ClaudeResponse',
        'Extract-ConversationContext',
        'Detect-ConversationState',
        'New-ConstrainedRunspace',
        'Test-CommandSafety',
        'Test-ParameterSafety',
        'Test-PathSafety',
        'Invoke-SafeConstrainedCommand',
        'Sanitize-ParameterValue',
        
        # Conversation State Manager Functions (Day 9)
        'Initialize-ConversationState',
        'Set-ConversationState',
        'Get-ConversationState',
        'Get-ValidStateTransitions',
        'Add-ConversationHistoryItem',
        'Get-ConversationHistory',
        'Get-ConversationContext',
        'Clear-ConversationHistory',
        'Get-SessionMetadata',
        'Reset-ConversationState',
        
        # Context Optimization Functions (Day 10)
        'Initialize-WorkingMemory',
        'Add-ContextItem',
        'Compress-Context',
        'Get-OptimizedContext',
        'Calculate-ContextRelevance',
        'New-SessionIdentifier',
        'Save-SessionState',
        'Restore-SessionState',
        'Get-SessionList',
        'Clear-ExpiredSessions',
        'Get-ContextSummary'
    )
    
    # Variables to export
    VariablesToExport = @()
    
    # Aliases to export
    AliasesToExport = @()
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('Unity', 'Claude', 'Automation', 'AutonomousAgent', 'AI')
            LicenseUri = ''
            ProjectUri = 'https://github.com/Unity-Claude-Automation'
            ReleaseNotes = 'v1.3.0: Phase 2 Days 9-10 - Comprehensive context management system with conversation state machine, history tracking, context optimization, and session persistence'
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUqaBxJQ8p4y3fDoGmwMKsTspr
# e4qgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUh3NciR5ieoIc7nxMsNyQlx0DeYIwDQYJKoZIhvcNAQEBBQAEggEAMXOO
# 9JDL5iqrJj39ddg3jt4yy6clop1OtniEYRUb5HIBj4s1e2+x8B8ueni3fZvX4rfq
# diDr0UrC4/D12+FjV5qWW/d171pnk1qqrw3/Ja+bZtGwo+zmosuUx/8wPuXe43VK
# kQywxKPAPLll5C656Iz+xyuPqDlPbe+UgOaOgHeYlrDegbwpvc8sJggmgugRJmVR
# L37w6kPKE2k32zrbOe7M0kVtwJXBIL12SP0KrSpNfakEet+pPm1g7lD6xnY52wXv
# gf1ZPF4zYPCQEG8PATjqLtxAlIEWII/rLRimso9ehkU3eRfdn+6sx8mlbMll6Cg9
# nBDJHkyxHZlpkZbJ/g==
# SIG # End signature block
