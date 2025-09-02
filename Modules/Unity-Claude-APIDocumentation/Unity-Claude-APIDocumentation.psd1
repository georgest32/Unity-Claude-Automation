@{
    # Module manifest for Unity-Claude-APIDocumentation
    # Generated: 2025-08-25
    # Phase 3 Day 5: Final Integration & Documentation

    RootModule = 'Unity-Claude-APIDocumentation.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'a9f2e7c6-4b8d-4e89-9f71-3c5e9d7f2b41'
    Author = 'Unity-Claude-Automation'
    CompanyName = 'Unity-Claude'
    Copyright = '(c) 2025 Unity-Claude. All rights reserved.'
    Description = 'Comprehensive API documentation generation for Enhanced Documentation System modules'
    PowerShellVersion = '5.1'
    
    # Dependencies - PlatyPS for documentation generation
    RequiredModules = @()
    
    # Functions to export
    FunctionsToExport = @(
        # Documentation Generation
        'New-ModuleDocumentation',
        'Update-ModuleDocumentation', 
        'New-ComprehensiveAPIDocs',
        'Export-ModuleReference',
        
        # PlatyPS Integration
        'Install-PlatyPS',
        'Initialize-DocumentationProject',
        'New-MarkdownHelp',
        'Update-MarkdownHelp',
        
        # Multi-Format Export
        'Export-HTMLDocumentation',
        'Export-PDFDocumentation',
        'Export-WikiDocumentation',
        'Export-OpenAPISpec',
        
        # Cross-Reference Generation
        'Build-ModuleCrossReference',
        'Generate-DependencyMap',
        'Create-FunctionIndex',
        'Build-ParameterMatrix',
        
        # User Guide Generation
        'New-UserGuide',
        'New-QuickStartGuide',
        'New-TutorialSeries',
        'Create-ExampleGallery',
        
        # Integration Documentation
        'Document-ModuleIntegration',
        'Create-WorkflowDiagrams',
        'Generate-ArchitectureDocs',
        'Build-ConfigurationGuide',
        
        # Quality and Validation
        'Test-DocumentationCompleteness',
        'Validate-DocumentationLinks',
        'Check-ExampleSyntax',
        'Measure-DocumentationCoverage',
        
        # Automation and CI/CD
        'New-DocumentationPipeline',
        'Update-CIDocumentation',
        'Deploy-DocumentationSite',
        'Schedule-DocumentationUpdates'
    )
    
    # Variables to export
    VariablesToExport = @()
    
    # Aliases to export
    AliasesToExport = @(
        'gendoc',      # New-ModuleDocumentation
        'updatedoc',   # Update-ModuleDocumentation
        'apidocs',     # New-ComprehensiveAPIDocs
        'htmldoc',     # Export-HTMLDocumentation
        'userguide',   # New-UserGuide
        'testdoc'      # Test-DocumentationCompleteness
    )
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('Documentation', 'API', 'PlatyPS', 'Markdown', 'Help', 'Reference', 'UserGuide')
            ProjectUri = 'https://github.com/unity-claude/api-documentation'
            ReleaseNotes = 'Comprehensive API documentation generation with multi-format export and automation'
        }
        Configuration = @{
            DefaultOutputPath = ".\docs\api"
            DefaultTemplate = "enhanced"
            GenerateExamples = $true
            IncludeCrossReferences = $true
            ValidateLinks = $true
            OutputFormats = @('html', 'markdown', 'pdf')
            IncludePrivateFunctions = $false
            GenerateTOC = $true
        }
        Templates = @{
            UserGuide = @{
                Sections = @('Introduction', 'Installation', 'QuickStart', 'Configuration', 'Examples', 'Troubleshooting', 'FAQ')
                IncludeScreenshots = $false
                IncludeCodeExamples = $true
            }
            APIReference = @{
                GroupByModule = $true
                IncludeParameters = $true
                IncludeExamples = $true
                CrossReferenceLinks = $true
            }
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD8ifRUsvSDLnzF
# 0CCIbg2KxN4A7MUZ5vBb445l0Tkyu6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILjdBLovRu6K7VkqRNDBqyS0
# PbbXEGkWA58Ca8WtGpiuMA0GCSqGSIb3DQEBAQUABIIBAKbOD4mUKej9v7sElhTF
# dO+asMLo2fABRhaicdwh61OQyunRPK9+ltobMK1b4uPBB3r0xVqHCkysDVi6hHPq
# X40SgQ7kToB5pgov49gQclAGRZWuA+sxIMQilxHTbUHe+MfIKZ7zW4KPJYb3wqbt
# n38+VBQ2UqOGzwR1we+Z2CcYlqpf0OreO71Qx+hyDLe8MRu+59N2VzlDPvWbwN+i
# Uvjdhz9jE0WeiIaqACGAV0osGG3g8x7HkCSAuhGGx1uYL7kXaQ2VY/obu4wdsOni
# 0OOHUQZuogqWGKaVnWGaTh3L1brQSQVeJ+OX3NRjOWit/C1EEQeyd07asR7ortJa
# qlU=
# SIG # End signature block
