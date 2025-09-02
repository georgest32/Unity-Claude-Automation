@{
    ModuleVersion = '1.0.0'
    GUID = '7d3f4c2a-8e1b-4a5c-9f2d-6e8c4b9a1e3f'
    Author = 'Unity-Claude-Automation'
    Description = 'Bayesian decision engine for CLI orchestration with advanced statistical analysis'
    PowerShellVersion = '5.1'
    
    RootModule = 'Unity-Claude-DecisionEngine-Bayesian.psm1'
    
    FunctionsToExport = @(
        'Invoke-BayesianDecisionAnalysis',
        'Get-BayesianConfidenceScore',
        'Update-BayesianPriors',
        'Calculate-PosteriorProbabilities',
        'Get-DecisionTreeAnalysis',
        'Invoke-MonteCarloSimulation',
        'Get-RiskAssessmentMatrix',
        'Calculate-ExpectedValue'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    RequiredModules = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('Bayesian', 'Decision', 'Analysis', 'Statistics')
            ProjectUri = 'https://github.com/georgest32/Unity-Claude-Automation'
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB84Xkw2blehcJR
# ctdOmgeRK0VFXkXIgg8qfjpZ3hQBkKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIArWoDeD7qT6waVbBDZslmJg
# PHeRLmGNq7i6cr9ftqnPMA0GCSqGSIb3DQEBAQUABIIBAEBtnn+iaXvxZWq8FTgo
# 0hRG5iCnVWGqo5eSJO5K7LlZ3ltX4tCps8QedzuCwHeuPG/9JS6tyu8zdkfMYRqe
# h4Cw04rgwfHAo4szH1wovXSBImhyxEKFnAJwymNvegkb5QWXA1SptW/SgmYpocwU
# tDqhvs+EwU2oIKSMqNfXkg9HEd8cXBQYm+E2q/Tz16EBN0ZRH8FalZxSgYQA1cnb
# 6MGYkBWFfvNEIZMtI4ztnK3sb6/F1a/aSePW8081JRhJRMY7L/+l7HbGG7AHve7M
# 93s3njTnN2AgCVT4JrymdNcuFav4qysBQ87mIePbrdW6DSrBGWIdcpS2Uz35MpL1
# XqI=
# SIG # End signature block
