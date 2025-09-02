@{
    # Module metadata
    ModuleVersion = '3.0.0'
    GUID = 'b8e5d9f2-6a0c-4d3e-9f8b-2c5a8e4d7f1a'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude-Automation Project'
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    Description = 'Fully refactored autonomous agent module with complete modular architecture across 12 sub-modules: Core, Monitoring, Parsing, Execution, Commands, Integration, and Intelligence systems'
    
    # PowerShell version requirements
    PowerShellVersion = '5.1'
    
    # Root module file (main loader)
    RootModule = 'Unity-Claude-AutonomousAgent-Refactored.psm1'
    
    # Nested modules - load in dependency order
    NestedModules = @(
        # Core modules (load first)
        'Core\AgentCore.psm1',
        'Core\AgentLogging.psm1',
        
        # Monitoring modules
        'Monitoring\FileSystemMonitoring.psm1',
        'Monitoring\ResponseMonitoring.psm1',
        
        # Parsing modules (Day 11 - NEW)
        'Parsing\ResponseParsing.psm1',
        'Parsing\Classification.psm1',
        'Parsing\ContextExtraction.psm1',
        
        # Execution modules
        'Execution\SafeExecution.psm1',
        
        # Command modules
        'Commands\UnityCommands.psm1',
        
        # Integration modules
        'Integration\ClaudeIntegration.psm1',
        'Integration\UnityIntegration.psm1',
        
        # Intelligence modules (Day 8-10)
        'IntelligentPromptEngine.psm1',
        'ConversationStateManager.psm1',
        'ContextOptimization.psm1'
    )
    
    # Required modules
    RequiredModules = @()
    
    # Required assemblies
    RequiredAssemblies = @()
    
    # Functions to export - ALL functions from nested modules
    FunctionsToExport = @(
        # Core Functions (AgentCore.psm1)
        'Initialize-AgentCore',
        'Get-AgentConfig',
        'Set-AgentConfig',
        'Get-AgentState',
        'Set-AgentState',
        'Reset-AgentState',
        
        # Logging Functions (AgentLogging.psm1)
        'Write-AgentLog',
        'Initialize-AgentLogging',
        'Invoke-LogRotation',
        'Remove-OldLogFiles',
        'Get-AgentLogPath',
        'Get-AgentLogStatistics',
        'Clear-AgentLog',
        
        # Monitoring Functions (FileSystemMonitoring.psm1)
        'Start-ClaudeResponseMonitoring',
        'Stop-ClaudeResponseMonitoring',
        'Get-MonitoringStatus',
        'Test-FileSystemMonitoring',
        
        # Response Monitoring Functions (ResponseMonitoring.psm1)
        'Invoke-ProcessClaudeResponse',
        'Find-ClaudeRecommendations',
        'Add-RecommendationToQueue',
        'Invoke-ProcessCommandQueue',
        'Submit-PromptToClaude',
        
        # Response Parsing Functions (ResponseParsing.psm1 - Day 11)
        'Invoke-EnhancedResponseParsing',
        'Get-ResponseQualityScore',
        'Extract-CommandsFromResponse',
        'Get-ResponseCategorization',
        'Get-ResponseEntities',
        'Test-ResponseParsingModule',
        
        # Classification Functions (Classification.psm1 - Day 11)
        'Invoke-ResponseClassification',
        'Invoke-DecisionTreeClassification',
        'Test-NodeCondition',
        'Get-ResponseIntent',
        'Get-ResponseSentiment',
        'Get-SimpleClassification',
        'Get-ClassificationMetrics',
        'Test-ClassificationEngine',
        
        # Context Extraction Functions (ContextExtraction.psm1 - Day 11)
        'Invoke-AdvancedContextExtraction',
        'Get-ContextRelevanceScores',
        'New-ContextItemsFromExtraction',
        'Invoke-ContextIntegration',
        'Get-EntityRelationshipMap',
        'Get-EntityClusters',
        
        # Intelligent Prompt Engine Functions (IntelligentPromptEngine.psm1 - Day 8)
        'Find-ResultPatterns',
        'Get-BasePromptTemplate',
        'Get-HistoricalPatterns',
        'Get-NextActionRecommendations',
        'Get-ResultClassification',
        'Get-ResultSeverity',
        'Get-TypeSpecificVariables',
        'Invoke-CommandResultAnalysis',
        'Invoke-DecisionTreeAnalysis',
        'Invoke-NodeEvaluation',
        'Invoke-PromptTypeSelection',
        'Invoke-TemplateRendering',
        'New-PromptTemplate',
        'New-PromptTypeDecisionTree',
        
        # Conversation State Manager Functions (ConversationStateManager.psm1 - Day 9)
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
        
        # Context Optimization Functions (ContextOptimization.psm1 - Day 10)
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
        'Get-ContextSummary',
        
        # Safe Execution Functions (SafeExecution.psm1)
        'New-ConstrainedRunspace',
        'Test-CommandSafety',
        'Test-ParameterSafety',
        'Test-PathSafety',
        'Invoke-SafeConstrainedCommand',
        'Invoke-SafeRecommendedCommand',
        'Sanitize-ParameterValue',
        
        # Unity Commands Functions (UnityCommands.psm1)
        'Invoke-TestCommand',
        'Invoke-UnityTests',
        'Invoke-CompilationTest',
        'Invoke-PowerShellTests',
        'Invoke-BuildCommand',
        'Invoke-AnalyzeCommand',
        'Find-UnityExecutable',
        
        # Claude Integration Functions (ClaudeIntegration.psm1)
        'Submit-PromptToClaude',
        'New-FollowUpPrompt',
        'Submit-ToClaude',
        'Get-ClaudeResponseStatus',
        
        # Unity Integration Functions (UnityIntegration.psm1)  
        'Get-PatternConfidence',
        'Convert-TypeToStandard',
        'Convert-ActionToType',
        'Normalize-RecommendationType',
        'Remove-DuplicateRecommendations',
        'Get-StringSimilarity',
        
        # Module Management Functions (from main loader)
        'Get-ModuleStatus'
    )
    
    # Variables to export
    VariablesToExport = @()
    
    # Aliases to export
    AliasesToExport = @()
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('Unity', 'Claude', 'Automation', 'AutonomousAgent', 'AI', 'Refactored', 'Modular')
            LicenseUri = ''
            ProjectUri = 'https://github.com/Unity-Claude-Automation'
            ReleaseNotes = 'v3.0.0: Complete modular refactoring - Split 2250+ line monolith into 12 focused modules across 7 categories. Total: 95+ exported functions with enhanced response processing, safe execution, Unity commands, and comprehensive integration systems.'
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUfrgcxVJwTDdDETpNXk0KTjsz
# OPKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU+zgNPwAcKwKLQ/2HBDXGoW0MaKkwDQYJKoZIhvcNAQEBBQAEggEAo+hK
# qy/bUApISVelv4oJ8LZ1S3YWXC/mIyzEaXBsegbWeOj163pSvyhy3U4ShlZ454B7
# epsWXizxANZla1/iqqK06Ue/XBKjiD1n8Vsl2iCsRuNaV4QFnJznXpLeTHUso3zK
# tNdcQ2TRSEv3wuOLJZMaoChzao43yYbeR+pabWNKu76djSKv1XCWd+LthBt/vjl7
# eaNEfVkeOFb29OLYLfyq3fBR40fa20uBHG/Q9jja6RyK48V+6U9IBnZpwT2+JTnU
# EKeOtyeDzPXPayASuagffkQoQOsH+R13nAp9QbnFK5UUja5hn7I1I0l/HPEJRgBY
# 0mt3bwuWlRSmuT1WyA==
# SIG # End signature block
