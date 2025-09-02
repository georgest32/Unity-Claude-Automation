# Module manifest for Unity-Claude-DocumentationDrift Core Configuration
# Created: 2025-08-25 (Refactored from large monolithic module)

@{
    RootModule = 'Configuration.psm1'
    ModuleVersion = '1.0.0'
    GUID = '8f3b2c1d-5e6a-4f9b-8c7d-2e1a3f4b5c6d'
    Author = 'Unity-Claude Automation'
    CompanyName = 'Unity-Claude'
    Copyright = '(c) 2025 Unity-Claude Automation. All rights reserved.'
    Description = 'Core configuration and initialization module for Documentation Drift Detection system'
    
    PowerShellVersion = '7.2'
    
    FunctionsToExport = @(
        'Initialize-DocumentationDrift',
        'Get-DocumentationDriftConfig', 
        'Set-DocumentationDriftConfig',
        'Reset-DocumentationDriftConfig',
        'Export-DocumentationDriftConfig'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('DocumentationDrift', 'Configuration', 'Automation')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Initial refactored release - Core configuration module extracted from monolithic Unity-Claude-DocumentationDrift'
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA3uL61XUgmmN4k
# 6ExvUqQOU/OdbKG5rwcyC0Gb9xDxTaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINerlbDB1tYdr/eberfQ+6Dh
# pojX43ZrDlq/EQj5Z4dIMA0GCSqGSIb3DQEBAQUABIIBAKr1piry6UcV80Drdm8/
# MvntasHsEObG8KB9AThq5e4l/22FsMy2qS22W6s9UNuwNzyyyYjxek61efmaGL2i
# YChjWrXMkb/GDhKiYxhpfTS1YesSb6Fn9wRo5rSpmhrCmg6VXrPhLSyZf+sfVYhf
# 5m6dIqchD3G0BiHd7Ak8A47KOTISrLRExJA6wnQBky/30lYSSzBHy7JBlzkAeyc3
# wYhvkdUDg1fAxZ1tc6K0P+WuhCgitTWNVQTrcHJaWqL3Mg0a9Dvd8Il8rw6tXB6a
# 7filBEYbMIUfnZJn3dTFxMnd6Z7feUqyhyEU6JWUr50rtpQoAEaCGHcQODNFp2Qa
# e14=
# SIG # End signature block
