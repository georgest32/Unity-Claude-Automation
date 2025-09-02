@{
    RootModule = 'Unity-Claude-LLM.psm1'
    ModuleVersion = '1.0.0'
    GUID = '7b8a9c2d-3e4f-5a6b-7c8d-9e0f1a2b3c4d'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude'
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    Description = 'Local LLM integration module for Unity-Claude-Automation using Ollama for documentation generation and code analysis'
    PowerShellVersion = '5.1'
    
    FunctionsToExport = @(
        'Invoke-OllamaGenerate'
        'Get-OllamaModels'
        'Test-OllamaConnection'
        'New-DocumentationPrompt'
        'Invoke-DocumentationGeneration'
        'New-CodeAnalysisPrompt'
        'Invoke-CodeAnalysis'
        'Get-LLMConfiguration'
        'Set-LLMConfiguration'
        'Test-LLMAvailability'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    RequiredModules = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('Unity', 'Claude', 'LLM', 'Ollama', 'Documentation', 'CodeAnalysis')
            ProjectUri = 'https://github.com/georgest32/Unity-Claude-Automation'
            ReleaseNotes = 'Initial release of Unity-Claude-LLM module with Ollama integration'
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBM7Z04sQTbzfrS
# wBwxfmOKMK6Lh+k74VnMJvJOAgQPGKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKc5xjhP134L3lMLhQ/ssW78
# 8OxMIfNabMkmbv/vTTJuMA0GCSqGSIb3DQEBAQUABIIBACazTKad25xEhvNMFRG2
# +AT9eE/WYTOZAKNJ9kXrNPpFv6zV4fq+lJBkijTgG/EMtFeLX32ppE5WsqB5CBR9
# 672DRzsjwwm6L1SsvTeh6cSEgawFe9kY3JokZ8ki3Bu5Ax/ltaMYU14FEB6XRtfg
# kryZWdrA/DCAkpoaAga1tmdDZICgREpLZsIHO5x/H7dn+/ZGWzCOqeMD3iHq11uu
# 90Nm/IVCIPjJsnYjwJ273lnj40hxj5HmFrlRqUn+Hj+W2ScB0Y/xh0yCKV0lcT7X
# bY4uLxDbPm7c3ABDEHV8e6GBJRpDp/aWrR4aBeSvWRuA9Lk3Dav81TO3dTeyaZeb
# 5bs=
# SIG # End signature block
