# Core.psm1 - Root module for CLIOrchestrator Core Components
# Phase 7 Enhancement - Re-export all nested module functions
# Date: 2025-08-25

# Re-export all functions from nested modules to make them available
# This ensures that functions from DecisionEngine.psm1, ResponseAnalysisEngine.psm1, and PatternRecognitionEngine.psm1 are accessible

# Response Analysis Engine Functions
if (Get-Command 'Invoke-EnhancedResponseAnalysis' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Invoke-EnhancedResponseAnalysis'
}
if (Get-Command 'Test-JsonTruncation' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Test-JsonTruncation'
}
if (Get-Command 'Repair-TruncatedJson' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Repair-TruncatedJson'
}
if (Get-Command 'Test-CircuitBreakerState' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Test-CircuitBreakerState'
}
if (Get-Command 'Update-CircuitBreakerState' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Update-CircuitBreakerState'
}

# Pattern Recognition Engine Functions
if (Get-Command 'Invoke-PatternRecognitionAnalysis' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Invoke-PatternRecognitionAnalysis'
}
if (Get-Command 'Find-RecommendationPatterns' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Find-RecommendationPatterns'
}
if (Get-Command 'Extract-ContextEntities' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Extract-ContextEntities'
}
if (Get-Command 'Classify-ResponseType' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Classify-ResponseType'
}
if (Get-Command 'Calculate-OverallConfidence' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Calculate-OverallConfidence'
}

# Decision Engine Functions
if (Get-Command 'Invoke-RuleBasedDecision' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Invoke-RuleBasedDecision'
}
if (Get-Command 'Resolve-PriorityDecision' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Resolve-PriorityDecision'
}
if (Get-Command 'Test-SafetyValidation' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Test-SafetyValidation'
}
if (Get-Command 'Test-SafeFilePath' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Test-SafeFilePath'
}
if (Get-Command 'Test-SafeCommand' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Test-SafeCommand'
}
if (Get-Command 'Test-ActionQueueCapacity' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Test-ActionQueueCapacity'
}
if (Get-Command 'New-ActionQueueItem' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'New-ActionQueueItem'
}
if (Get-Command 'Get-ActionQueueStatus' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Get-ActionQueueStatus'
}
if (Get-Command 'Resolve-ConflictingRecommendations' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Resolve-ConflictingRecommendations'
}
if (Get-Command 'Invoke-GracefulDegradation' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Invoke-GracefulDegradation'
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCIA0acuVUXvTrV
# kDRqWinqQ+Ho0fm+oD5YJUfqLtUIAaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHwWfG5Q2d/rh2U9UA3qvm2p
# 5sY/0mnTJa48/GAVwIM2MA0GCSqGSIb3DQEBAQUABIIBAAM2mgDaykNAl2MJPqs0
# BjpCGYAPC3Ht/IV1MV5lSGnnmnT/8z/AAEqBhT/OD5A8CDLFQ5KwvkeoXu8Uadx0
# Ab9k9I5yJQDz9F9yczt4WucS5gu5zCfgBkwKislxMwrgSOYETVk2amm1N3L5yZFK
# +KfoJwM+rNVE8K5pVE1v6f1VcVw7ipNvCYdTOTE1lm8/7Xx3phFRXI3LuNgHHbp2
# MxJIvnvFNQsL+XZv6w9PbJ6k525m6PYuwT/2yXPZMMdKslnZGTgq9PZaNrAyE8hJ
# fo+Lw2Npzc40vDppygdozEDOa4rLrJBEeKMicSDxEngbAyfAWH793+auzOUwWyP+
# W+E=
# SIG # End signature block
