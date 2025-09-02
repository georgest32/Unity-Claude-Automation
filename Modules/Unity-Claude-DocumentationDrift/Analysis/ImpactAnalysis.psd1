# Module manifest for Unity-Claude-DocumentationDrift Impact Analysis
# Created: 2025-08-25 (Refactored from large monolithic module)

@{
    RootModule = 'ImpactAnalysis.psm1'
    ModuleVersion = '1.0.0'
    GUID = '7d2c3e4f-1a5b-4c6d-9e8f-3a2b4c5d6e7f'
    Author = 'Unity-Claude Automation'
    CompanyName = 'Unity-Claude'
    Copyright = '(c) 2025 Unity-Claude Automation. All rights reserved.'
    Description = 'Impact analysis module for Documentation Drift Detection system - analyzes code changes and their impact on documentation'
    
    PowerShellVersion = '7.2'
    
    FunctionsToExport = @(
        'Analyze-ChangeImpact',
        'Analyze-NewFileImpact',
        'Analyze-DeletedFileImpact', 
        'Analyze-ModifiedFileImpact',
        'Analyze-RenamedFileImpact',
        'Determine-OverallImpactLevel',
        'Generate-ChangeRecommendations'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('DocumentationDrift', 'Analysis', 'Impact', 'CodeAnalysis', 'Automation')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Initial refactored release - Impact analysis module extracted from monolithic Unity-Claude-DocumentationDrift'
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCzypduCioqNIKW
# 2t7/yi6jD+5ct7q5/aW4UkspAxNEK6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDNm04jxcGKn0ofoE9+uUF1J
# xX5fG4JV22+fJy0Qejm+MA0GCSqGSIb3DQEBAQUABIIBAIAhRQ+vuVRaemrCnNlN
# KqbCsfCrft252ZCml1jilhPFZVpqoBAaGKA7gdXWCThdLNgtMq0+sbri4ZBu2LLj
# bY1ejj2QMnSXwPpXVJPBXQLkSLLqg+iQS3/9q7JBU7cgvCu3XvCqaw1eJqIJklgZ
# 8tgwL0+u/6j43tZjwjIOGv3ljwRiI76pLUFQf9dOiZ/yx9hlrgG/RrYwcIP7yrI6
# 0bAtmeFEosQ3m96N1t+jlqADtjxcA7YsnQis3EXrtCh3Vvu8v4MqxgpJjLkxEabH
# E4eGyxqrkESlmCtsF9MnBIM5g320W7ua7d8j+wSmnKeuijz7pJv10XCSYdnO7m4L
# /aA=
# SIG # End signature block
