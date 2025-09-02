@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Unity-Claude-CLIOrchestrator.psm1'
    
    # Version number of this module.
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'
    
    # Author of this module
    Author = 'Unity-Claude-Automation System'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude-Automation'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Core autonomous monitoring functionality for Unity-Claude automation system with enhanced window detection, input blocking, and TEST execution capabilities.'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Nested modules (Phase 7 Day 3-4 Enhancement)
    NestedModules = @(
        'Core\Components\ResponseAnalysisEngine-Core.psm1',
        'Core\PatternRecognitionEngine.psm1',
        'Core\DecisionEngine.psm1',
        'Core\ActionExecutionEngine.psm1',
        'Core\PerformanceOptimizer.psm1'
    )
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Original Functions
        'Start-CLIOrchestration',
        'Find-ClaudeWindow',
        'Switch-ToWindow', 
        'Submit-ToClaudeViaTypeKeys',
        'Execute-TestScript',
        'Process-ResponseFile',
        'Update-ClaudeWindowInfo',
        
        # Enhanced Response Analysis (Phase 7 Day 1-2)
        'Invoke-EnhancedResponseAnalysis',
        'Invoke-UniversalResponseParser',
        'Test-ResponseFormat',
        'Parse-MixedFormatResponse',
        'Initialize-ResponseMonitoring',
        'Test-JsonTruncation',
        'Repair-TruncatedJson',
        'Test-CircuitBreakerState',
        'Update-CircuitBreakerState',
        'Extract-ResponseEntities',
        'Analyze-ResponseSentiment',
        'Get-ResponseContext',
        
        # Pattern Recognition & Classification (Phase 7 Day 1-2)
        'Invoke-PatternRecognitionAnalysis',
        'Find-RecommendationPatterns',
        'Extract-ContextEntities',
        'Classify-ResponseType',
        'Calculate-OverallConfidence',
        
        # Decision Engine (Phase 7 Day 3-4)
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
        
        # Action Execution Framework (Phase 7 Day 5)
        'Invoke-SafeAction',
        'Add-ActionToQueue',
        'Get-NextQueuedAction',
        'Get-ActionExecutionStatus',
        'Test-ActionSafety',
        'Test-SafeFilePath',
        'Test-SafeCommand',
        
        # Performance Optimization Functions (Phase 7 Day 1-2)
        'Invoke-OptimizedEntityExtraction',
        'Invoke-CacheCleanup',
        'Get-PerformanceReport',
        'Test-PerformanceOptimization',
        'Initialize-PerformanceCache',
        
        # Integrated Processing Functions
        'Invoke-ComprehensiveResponseAnalysis',
        'Get-CLIOrchestrationStatus',
        'Invoke-AutonomousDecisionMaking'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('Unity', 'Claude', 'Automation', 'Monitoring', 'WindowDetection', 'TestExecution')
            
            # Release notes of this module
            ReleaseNotes = 'v1.0.0 - Initial release with enhanced window detection, input blocking, and TEST execution capabilities'
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCBqKxjY5u3Tpkl
# tpK+Gi0dpXAiuTz3pZ8FY/jc6RXaWqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIC6z98sdn4hazABtcatfBr9J
# ZleRC6ZJc4zlcFk3nPlTMA0GCSqGSIb3DQEBAQUABIIBAGfKlu3t2/Xl5nMyc9kw
# mR9iiC9e7+ge3z0U6y15jgIL0U15VHoH533dvx9bTiHhTToM3cYgPyXie7pLW6sh
# yRDWgMYZgSiwXe5AJrCHlN6bmKtxEvRSuw2NaWG3oKHRP6q5a6ZaLtnrYs3CUGir
# S04+0riFiOW5ca5M4ZHCrvs2MXaQ1dS2hw4VSu6y3IkCG1Wt9br/elLHpXzX6Mte
# DRP41n7jePe+LIsZyosG3AvEUGTdL2OjGsLk8gVvE/VNKEAbg5SQwDLNTYZQNQLS
# O69kqF3atbkBjXp+RyY/iJnz4NpiET+ng9PDSF9zQFXsW3DRC5l04aRwLIwQnAjd
# ef4=
# SIG # End signature block
