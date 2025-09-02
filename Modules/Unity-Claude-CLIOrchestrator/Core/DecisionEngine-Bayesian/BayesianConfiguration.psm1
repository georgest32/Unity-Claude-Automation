# BayesianConfiguration.psm1
# Phase 7 Day 3-4 Hours 5-8: Bayesian Configuration Management
# Configuration and initialization for Bayesian decision engine
# Date: 2025-08-25

#region Bayesian Configuration

# Bayesian inference configuration
$script:BayesianConfig = @{
    # Prior probabilities for each decision type (initial beliefs)
    PriorProbabilities = @{
        CONTINUE = 0.50   # Moderate prior for continuation
        TEST = 0.30       # Moderate prior for testing
        FIX = 0.15        # Lower prior for fixes
        COMPILE = 0.10    # Lower prior for compilation
        RESTART = 0.05    # Low prior for restarts
        COMPLETE = 0.08   # Low prior for completion
        ERROR = 0.02      # Very low prior for errors
    }
    
    # Historical outcome tracking
    OutcomeHistory = @{
        CONTINUE = @{ Success = 0; Failure = 0; Total = 0 }
        TEST = @{ Success = 0; Failure = 0; Total = 0 }
        FIX = @{ Success = 0; Failure = 0; Total = 0 }
        COMPILE = @{ Success = 0; Failure = 0; Total = 0 }
        RESTART = @{ Success = 0; Failure = 0; Total = 0 }
        COMPLETE = @{ Success = 0; Failure = 0; Total = 0 }
        ERROR = @{ Success = 0; Failure = 0; Total = 0 }
    }
    
    # Learning parameters
    LearningRate = 0.1          # How quickly to update beliefs
    MinimumSamples = 10          # Minimum samples before significant adjustment
    ConfidenceDecay = 0.95       # Decay factor for old observations
    
    # Confidence bands
    ConfidenceBands = @{
        VeryHigh = 0.95
        High = 0.85
        Medium = 0.70
        Low = 0.50
        VeryLow = 0.30
    }
    
    # Uncertainty metrics
    UncertaintyThreshold = 0.2   # Maximum acceptable uncertainty
    EntropyThreshold = 2.0        # Maximum decision entropy
}

# Persistent storage for Bayesian learning
$script:BayesianStoragePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Data\BayesianLearning.json"

#endregion

# Export configuration accessor functions
Export-ModuleMember -Variable BayesianConfig, BayesianStoragePath
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBzzd4BPKNU7oti
# GP4Iv6oq8+5Ec9F5BbPQy7OAv5nOlaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIN1m3JG4a3uxHRg87VtEa5U4
# LOwaH5dLhGhJXgCxPkFPMA0GCSqGSIb3DQEBAQUABIIBACPl2AJ6QzikBOVIO9tQ
# AhK3uHqyl6uGxscYb/+5yqaFdnNgrYuXAGOHio2rIq9KP82/EnojMe1eALnntstM
# QqDPfL2kusPeixrSx/wmdhAhoKOAsx6EtYp1hiEzr0Do3szG6xpfRwBZOG4cB7fx
# 2Tj+jyaRBAQOziyf1QqxQRPMeImM4gOVO0RbEbgSl7aUJ6T370GVK8w4fmwEfA3S
# SKZehasytQDLVEZwSQKcogGRyDwRPcZYDegWxxHlgAhENwPvZLsC5bIv0gFQFY9Z
# aOVIvtSVaEXX3rqyir90rKgjkvM2bftD9ESKdwCBl3mJHDimEzQF6f+MXA1Va15P
# 1gY=
# SIG # End signature block
