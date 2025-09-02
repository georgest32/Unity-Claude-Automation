@{
    # Module manifest for Unity-Claude-Learning
    ModuleVersion = '2.0.0'
    GUID = 'a7c4f8d9-3e2b-4f1a-9c8d-5b6e7a9f2c3d'
    Author = 'Unity-Claude Automation'
    CompanyName = 'Unity-Claude'
    Copyright = '(c) 2025 Unity-Claude. All rights reserved.'
    Description = 'Self-improvement and pattern recognition module for Unity-Claude Automation - Phase 3 (REFACTORED)'
    PowerShellVersion = '5.1'
    
    # Module components
    # REFACTORED: Now using modular architecture version
    RootModule = 'Unity-Claude-Learning-Refactored.psm1'
    
    # Functions to export (expanded for refactored version)
    FunctionsToExport = @(
        # Core configuration
        'Get-LearningConfig',
        'Set-LearningConfig',
        
        # Database management
        'Initialize-LearningDatabase',
        
        # String similarity
        'Get-StringSimilarity',
        'Get-LevenshteinDistance',
        'Get-ErrorSignature',
        
        # Pattern recognition
        'Find-SimilarPatterns',
        'Add-ErrorPattern',
        'Calculate-ConfidenceScore',
        
        # AST Analysis
        'Get-CodeAST',
        'Find-CodePattern',
        
        # Self-patching
        'Get-SuggestedFixes',
        'Apply-AutoFix',
        
        # Success tracking
        'Update-PatternSuccess',
        'Get-LearningReport',
        
        # Metrics collection
        'Record-PatternApplicationMetric',
        'Get-LearningMetrics',
        'Get-PatternUsageAnalytics'
    )
    
    # Required modules
    RequiredModules = @()
    
    # Required assemblies for SQLite - Made optional for compatibility
    # RequiredAssemblies = @(
    #     'System.Data.SQLite.dll'
    # )
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('Unity', 'Claude', 'Automation', 'Learning', 'AI', 'Pattern-Recognition')
            ProjectUri = 'https://github.com/unity-claude/automation'
            ReleaseNotes = 'Phase 3 implementation - Self-improvement mechanism with pattern recognition'
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCs7gJ/cqfSDMv1
# UF7P5IaQ3gaKx31SXyqRsodEsZD7/6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOkomQY1Z3AjooP3+1TDtaxr
# OSMXK0oXGKoUImkjWNF3MA0GCSqGSIb3DQEBAQUABIIBAAuNU0u6atGyCftANLOo
# 7uoV/gi8f5Xj0UQ4xuojpwVRgBOZ8iQCPE+ow7Q1+zyIpRfb6Wp6erFoeZdFrWea
# bixNpkGg4vUCKDC+FODnI0T2jAfn2XvWaKuMoXTESPJg1B45GFwgmY5k3qeELemD
# p7tH/XwAskaQ+dGAvINGJ7ZicsnvNamaJT+OdEgKnWjxTsAzKJyo09W4F2onwjTg
# pEsAmfeDhdrBh4c1ySJCygeow7IN53vxo14gEFUlldxDF0KdLraqzFjvr8zzRJxH
# 9SnNfvxbhHzpitRrlwrY3PnvHW+Hiix1so07rGBYT8aw8dYikXxIQbbiXxj18xC8
# J+w=
# SIG # End signature block
