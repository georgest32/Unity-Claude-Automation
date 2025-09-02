# Module manifest for Unity-Claude-DocumentationDrift - Refactored Modular Version
# Created: 2025-08-25 (Refactored from large monolithic module)

@{
    RootModule = 'Unity-Claude-DocumentationDrift-Refactored.psm1'
    ModuleVersion = '2.0.0'
    GUID = '6c1b2a3d-4e5f-6a7b-8c9d-1e2f3a4b5c6d'
    Author = 'Unity-Claude Automation'
    CompanyName = 'Unity-Claude'
    Copyright = '(c) 2025 Unity-Claude Automation. All rights reserved.'
    Description = 'Refactored modular Documentation Drift Detection system - analyzes code changes and automates documentation updates'
    
    PowerShellVersion = '7.2'
    
    # Required modules (sub-modules will be loaded automatically)
    RequiredModules = @()
    
    # Nested modules loaded by this module
    NestedModules = @(
        'Core\Configuration.psd1',
        'Analysis\ImpactAnalysis.psd1'
    )
    
    FunctionsToExport = @(
        # From Core.Configuration
        'Initialize-DocumentationDrift',
        'Get-DocumentationDriftConfig', 
        'Set-DocumentationDriftConfig',
        'Reset-DocumentationDriftConfig',
        'Export-DocumentationDriftConfig',
        
        # From Analysis.ImpactAnalysis  
        'Analyze-ChangeImpact',
        'Analyze-NewFileImpact',
        'Analyze-DeletedFileImpact', 
        'Analyze-ModifiedFileImpact',
        'Analyze-RenamedFileImpact',
        'Determine-OverallImpactLevel',
        'Generate-ChangeRecommendations',
        
        # Main module functions
        'Clear-DriftCache',
        'Get-DriftDetectionResults',
        'Test-DocumentationDrift'
    )
    
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    
    PrivateData = @{
        PSData = @{
            Tags = @('DocumentationDrift', 'Automation', 'CodeAnalysis', 'Documentation', 'Refactored', 'Modular')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = @"
Version 2.0.0 - Major Refactoring Release
- Broke down large 3708-line monolithic module into smaller, focused components
- Created organized subdirectory structure: Core, Analysis, Monitoring, GitHub, Cache, Utils
- Improved maintainability and debugging capabilities
- Maintained backward compatibility with existing function exports
- Enhanced modularity for easier testing and development
"@
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBtQ3czM9gPKfdo
# NkXuFDNDnvvMhKg0xIAiU3E+wN5D9aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEDftv0UrID9wtf0+XjgXYoB
# FSGIBMjEu+6Ygy10tGvZMA0GCSqGSIb3DQEBAQUABIIBADiVL1vOR0VNfBNPnhii
# SCsZ6MDAxalUV+qhfwZ6GIL8Aazn4IuFmolR5KSZxu+fYo0SaqFdst3Jj8Z6RExi
# hXBzNNnydHBeRvwXAEVep38KGx+F/fcXKEvsmgnoAwUWxKXkfDE8dv+eimP51Kri
# X8sL0uIwqYGq/GmmnpoN8bsGDskjMFuua4BAEDFb/JBx7xVVwWQyLXQ6mD3pM3oe
# F7TPKwkftMjmHqitjJ5erqi20uFSZsfBGKykvWi2dcZWmi+hmR4l3IgnNP8KlD9G
# TusjSXLir7AUpbYMruoUQsAdsq90PYuIqJbrGf3dU4JKC5R9eHLKz1PN9FCM9ejF
# G7k=
# SIG # End signature block
