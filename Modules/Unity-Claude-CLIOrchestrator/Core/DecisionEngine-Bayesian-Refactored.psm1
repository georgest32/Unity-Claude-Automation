# DecisionEngine-Bayesian-Refactored.psm1
# Refactored modular version of the Bayesian Decision Engine
# This orchestrator imports all components and provides the public interface
# Date: 2025-08-26

#region Module Orchestrator

# Import all component modules
$ComponentPath = Join-Path $PSScriptRoot "DecisionEngine-Bayesian"

# Bayesian Configuration Management
Import-Module (Join-Path $ComponentPath "BayesianConfiguration.psm1") -Force -Global

# Core Bayesian Inference Engine
Import-Module (Join-Path $ComponentPath "BayesianInference.psm1") -Force -Global

# Confidence Band Classification
Import-Module (Join-Path $ComponentPath "ConfidenceBands.psm1") -Force -Global

# Learning and Adaptation System
Import-Module (Join-Path $ComponentPath "LearningAdaptation.psm1") -Force -Global

# Advanced Pattern Analysis
Import-Module (Join-Path $ComponentPath "PatternAnalysis.psm1") -Force -Global

# Entity Relationship Management
Import-Module (Join-Path $ComponentPath "EntityRelationshipManagement.psm1") -Force -Global

# Temporal Context Tracking
Import-Module (Join-Path $ComponentPath "TemporalContextTracking.psm1") -Force -Global

# Enhanced Pattern Integration
Import-Module (Join-Path $ComponentPath "EnhancedPatternIntegration.psm1") -Force -Global

Write-DecisionLog "DecisionEngine-Bayesian components loaded successfully" "INFO"

#endregion

# Export all public functions from components
Export-ModuleMember -Function @(
    # From BayesianConfiguration
    'Initialize-BayesianEngine',
    'Get-BayesianConfiguration',
    'Reset-BayesianEngine',
    
    # From BayesianInference  
    'Invoke-BayesianConfidenceAdjustment',
    'Get-BayesianPrior',
    'Calculate-BayesianLikelihood',
    'Update-BayesianOutcome',
    
    # From ConfidenceBands
    'Get-ConfidenceBand',
    'Calculate-PatternConfidence',
    
    # From LearningAdaptation
    'Update-BayesianLearning',
    'Save-BayesianLearning',
    'Load-BayesianLearning',
    
    # From PatternAnalysis
    'Build-NGramModel',
    'Calculate-PatternSimilarity',
    'Get-LevenshteinDistance',
    
    # From EntityRelationshipManagement
    'Build-EntityRelationshipGraph',
    'Find-EntityCluster',
    'Measure-EntityProximity',
    
    # From TemporalContextTracking
    'Add-TemporalContext',
    'Get-TemporalContextRelevance',
    
    # From EnhancedPatternIntegration
    'Invoke-EnhancedPatternAnalysis'
)

# Export script variables that might be needed
Export-ModuleMember -Variable BayesianConfig, TemporalContext
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAO+UQZKk0KvHPe
# pva5VKr77kmRrWE/9E2V8cg4w+7AmqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJn4CxcvcMxQh4Y1VrPv8HlH
# sVEymo0vaFEPmiO5QoekMA0GCSqGSIb3DQEBAQUABIIBAGHoQg5ycjKlHHK7olB2
# OfDxH28SSjaqeXh2YoCg3QUNP2H4/OKEW6EXnC2RiARF9ULzQOkERoAPdo7FHtmK
# CXNgCDtt9bP9f4QZ2lL8aTMNLZhc9jPzF8dkTDOuK2MVWuK0fg/BDZXgcQTLpxg7
# pbPV8xWUSXxMc7Im0fZHitroj0RYUoTzgBs+GpqrBWr5uJ5PumKd4+P0vVzBTcIN
# u4Vcgdglz+W5oOsuoeF0H2Y5pjVvByM7ggtfmhISE/eeaIyaxF+vAuoBBT+yCCTR
# yMUKOdQ7H93wGxa9f3qTcYS24l5kH4z8BjViufMuYGVD9eOgOV3sRWTVAMjAFryD
# 448=
# SIG # End signature block
