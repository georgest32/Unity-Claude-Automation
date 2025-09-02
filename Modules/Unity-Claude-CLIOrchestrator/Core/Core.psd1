#
# Module manifest for Unity-Claude-CLIOrchestrator Core Components
# Phase 7 Enhancement - Complete Response Analysis, Pattern Recognition, and Decision Engine
# PowerShell 5.1 compatible with advanced autonomous decision-making capabilities
#

@{
    # Root module to coordinate nested modules
    RootModule = 'Core.psm1'
    
    # Nested modules for complete functionality (Phase 7 Day 3-4)
    NestedModules = @(
        'ResponseAnalysisEngine.psm1',
        'PatternRecognitionEngine.psm1',
        'DecisionEngine.psm1'
    )
    
    # Version number of this module (updated for Phase 7 Day 3-4)
    ModuleVersion = '1.1.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop')
    
    # ID used to uniquely identify this module
    GUID = 'c8d4f2a6-9e1b-4f7c-a8d3-5e9b2c7f1a4e'
    
    # Author of this module
    Author = 'Unity-Claude Automation System'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude Automation'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude Automation. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Complete CLIOrchestrator Core with Response Analysis Engine, Pattern Recognition Engine, and Decision Engine for autonomous Claude Code CLI interaction and decision-making'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Minimum version of Microsoft .NET Framework required by this module
    DotNetFrameworkVersion = '4.5'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Functions to export from this module (All three engines)
    FunctionsToExport = @(
        # Response Analysis Engine Functions
        'Invoke-EnhancedResponseAnalysis',
        'Test-JsonTruncation',
        'Repair-TruncatedJson',
        'Test-CircuitBreakerState',
        'Update-CircuitBreakerState',
        
        # Pattern Recognition Engine Functions
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
        'Invoke-GracefulDegradation'
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
            Tags = @('Unity', 'Claude', 'Automation', 'JSON', 'ResponseAnalysis', 'CircuitBreaker', 'PowerShell')
            
            # Release notes of this module
            ReleaseNotes = @'
Version 1.0.0:
- Enhanced multi-parser JSON processing with ConvertFrom-JsonFast fallback
- Claude Code CLI truncation detection and repair at known positions (4k, 6k, 8k, 10k, 12k, 16k)
- Circuit breaker pattern implementation for failure resilience
- Exponential backoff retry logic with configurable limits
- Comprehensive schema validation with Anthropic response structure detection
- Performance monitoring with sub-200ms parsing targets
- PowerShell 5.1 compatibility with .NET JavaScriptSerializer fallback
- Extensive debug logging with performance metrics
- Integration with existing Unity-Claude ecosystem
'@
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBCGRXIx1QuE8Xp
# 0JjQoUdA/2mkas4DftXeKRdN2Ya2t6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEdmeotGweR4SFfNPMNGRLsr
# HbKLxXn5ZnCFGiPF3rtXMA0GCSqGSIb3DQEBAQUABIIBAGNWL1roiCkMIP2XbGM3
# 26oYBCtP72yoxQgEYs0asmV8GQ03O/54ZhAMw6juqKY6bJm0Ae93S0W+/r7YMfti
# MRXd0aL7O2XXHP5BH9mCturnCMGjTVwwAAOuCw/0m4Z0MGMARwZRsvmRmvXarzi6
# onIM9eFUlS1gfSYkJygmCiYFDSyNKBtMZAI6kntZUwfAIDN05ug1PV3ncQF81cuP
# h8QBKCqbiMn/Cs7PfYgDAZU0ZU8Fghllgrnm0bohrKrHnz3nmWKwWRp8bw9Y1cBV
# YlUHQQduD/KYdkNsPcWxQlzKPHgtoRvcKLBX07BAikCAEp2qbcwJbx32EKVktJVz
# U5g=
# SIG # End signature block
