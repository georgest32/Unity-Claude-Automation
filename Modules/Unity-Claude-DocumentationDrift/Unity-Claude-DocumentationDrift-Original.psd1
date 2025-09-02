# Unity-Claude-DocumentationDrift.psd1
# Module manifest for Unity-Claude Documentation Drift Detection
# Generated: 2025-08-24
# Phase 5, Day 3-4: Documentation Update Automation

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-DocumentationDrift.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # ID used to uniquely identify this module
    GUID = 'b8f9e2d7-3c4f-5a6b-9e1d-7c8f4e2a3b5c'
    
    # Author of this module
    Author = 'Unity-Claude Automation System'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Documentation drift detection and automated update system for Unity-Claude Automation. Provides real-time monitoring of code-to-documentation synchronization, impact analysis, and automated PR creation for documentation updates.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '7.2'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        'Unity-Claude-RepoAnalyst',
        'Unity-Claude-FileMonitor', 
        'Unity-Claude-GitHub'
    )
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Core drift detection
        'Initialize-DocumentationDrift',
        'Build-CodeToDocMapping',
        'Update-DocumentationIndex',
        'Test-DocumentationCurrency',
        
        # Change impact analysis
        'Analyze-ChangeImpact',
        'Get-DocumentationDependencies',
        'Generate-UpdateRecommendations',
        
        # Automation pipeline
        'Invoke-DocumentationAutomation',
        'New-DocumentationBranch',
        'Generate-DocumentationCommitMessage',
        'New-DocumentationPR',
        
        # Configuration and management
        'Get-DocumentationDriftConfig',
        'Set-DocumentationDriftConfig',
        'Get-DriftDetectionResults',
        'Clear-DriftCache',
        
        # Quality and validation
        'Test-DocumentationQuality',
        'Validate-DocumentationLinks',
        'Get-DocumentationMetrics'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # Private data to pass to the module specified in RootModule
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('Documentation', 'Automation', 'Drift Detection', 'GitHub', 'Unity', 'Claude', 'AST', 'Code Analysis')
            
            # A URL to the license for this module
            LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri = 'https://github.com/Unity-Claude/Automation'
            
            # A URL to an icon representing this module
            IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
## Version 1.0.0 (2025-08-24) - Phase 5: Documentation Update Automation

### Documentation Drift Detection
- Build-CodeToDocMapping: Creates bidirectional mapping between code components and documentation
- Update-DocumentationIndex: Scans and indexes all documentation files with metadata extraction
- Test-DocumentationCurrency: Identifies stale documentation based on modification timestamps
- Analyze-ChangeImpact: Determines documentation impact from code changes using AST analysis

### Automated Update System
- Generate-UpdateRecommendations: Provides specific suggestions for documentation updates
- Get-DocumentationDependencies: Tracks cascade effects and dependency chains
- Invoke-DocumentationAutomation: Complete end-to-end automation pipeline

### GitHub Integration
- New-DocumentationBranch: Automated branch management with naming conventions
- Generate-DocumentationCommitMessage: Conventional commits compliant message generation
- New-DocumentationPR: Automated PR creation with templates and proper metadata

### Quality Assurance
- Test-DocumentationQuality: Validates documentation against style guidelines
- Validate-DocumentationLinks: Checks for broken links in documentation
- Get-DocumentationMetrics: Tracks automation success rates and drift detection accuracy

### Configuration Management
- Get/Set-DocumentationDriftConfig: Comprehensive configuration system
- JSON-based configuration with validation schema
- Configurable sensitivity levels, approval thresholds, and template selection

### Integration Features
- Full integration with Unity-Claude-FileMonitor for real-time change detection
- Unity-Claude-TriggerManager integration for priority-based processing
- Unity-Claude-GitHub v2.0.0 integration for comprehensive GitHub API operations
- Unity-Claude-RepoAnalyst integration for multi-language AST analysis
'@
            
            # Prerelease string of this module
            Prerelease = ''
            
            # Flag to indicate whether the module requires explicit user acceptance
            RequireLicenseAcceptance = $false
            
            # External dependent modules of this module
            ExternalModuleDependencies = @()
        }
    }
    
    # HelpInfo URI of this module
    HelpInfoURI = ''
    
    # Default prefix for commands exported from this module
    DefaultCommandPrefix = ''
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBMfR0zjsvZEDCE
# uYpuHPTOaL/FwMxdVQL1XD8+aViTVqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFXEb7bbwb/50fIEFEDLL3B1
# n5529fUuCjQGu11owjyDMA0GCSqGSIb3DQEBAQUABIIBAJfI54HZxDzlKu6swWgD
# QUBJ7j8O/NbwlFX1Zfq0f4jPHHr7zLYe3n2VzDQMaETfEoiyEIGBLmz1q9pCItFT
# 92o5pEB49UwpoKHPvqvSjev9hi5JayHaa0gKbYc0H0dORlCiHFEXoTyznIbfzDRz
# D7BK0TgFHSmx/ivh1SJ11oJgDADnwGbihbR4JH3E84mME8M4kXjcf5rqfebym07C
# 0gWiruxezEEzAOMmet/T2a0MnCbO+n/uDaMqNuLDPNZEVO1MTgxD+j1VqQPLxlOb
# FFCIwaMCuBgEAQZsr/HtGO6VulykOeab7Fut6sQ1sha//TelrIs6kM7wuc6Gh/yB
# 9tI=
# SIG # End signature block
