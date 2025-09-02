# Unity-Claude-GitHub.psd1
# Module manifest for Unity-Claude GitHub Integration
# Generated: 2025-08-22
# Phase 4, Week 8, Day 1

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-GitHub.psm1'
    
    # Version number of this module
    ModuleVersion = '2.1.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # ID used to uniquely identify this module
    GUID = 'a7f8e4d5-2b3c-4e6f-9a1b-8c5d7e3f2a4b'
    
    # Author of this module
    Author = 'Unity-Claude Automation System'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'GitHub integration module for Unity-Claude Automation System. Provides secure PAT management, issue creation, API interaction with rate limiting, retry logic, and governance features including branch protection and CODEOWNERS management.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Authentication & Security
        'Set-GitHubPAT',
        'Get-GitHubPAT',
        'Test-GitHubPAT',
        'Clear-GitHubPAT',
        
        # Rate Limiting
        'Get-GitHubRateLimit',
        'Invoke-GitHubAPIWithRetry',
        
        # Issue Management
        'New-GitHubIssue',
        'Search-GitHubIssues',
        'Update-GitHubIssue',
        'Add-GitHubIssueComment',
        
        # Issue Lifecycle Management (Week 9)
        'Get-GitHubIssueStatus',
        'Update-GitHubIssueState',
        'Test-UnityErrorResolved',
        'Close-GitHubIssueIfResolved',
        
        # Repository Management (Week 9)
        'Get-GitHubRepositories',
        'Test-GitHubRepositoryAccess',
        'Get-UnityProjectCategory',
        'Search-GitHubIssuesMultiRepo',
        
        # Performance & Analytics (Week 9)
        'Get-GitHubAPIUsageStats',
        
        # Unity Error Processing
        'Format-UnityErrorAsIssue',
        'Get-UnityErrorSignature',
        'Test-GitHubIssueDuplicate',
        
        # Configuration Management
        'Get-GitHubIntegrationConfig',
        'Set-GitHubIntegrationConfig',
        'Test-GitHubIntegrationConfig',
        
        # Template System
        'Get-GitHubIssueTemplate',
        
        # Pull Request Management
        'New-GitHubPullRequest',
        
        # Governance & Branch Protection (Phase 5)
        'Set-GitHubBranchProtection',
        'Get-GitHubBranchProtection',
        'Test-GitHubBranchProtection',
        'New-GitHubCodeOwnersFile',
        'Set-GitHubGovernanceConfiguration'
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
            Tags = @('GitHub', 'API', 'Integration', 'Unity', 'Claude', 'Automation', 'IssueTracking')
            
            # A URL to the license for this module
            LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri = 'https://github.com/Unity-Claude/Automation'
            
            # A URL to an icon representing this module
            IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
## Version 2.0.0 (2025-08-23) - Week 9 Advanced Features
### Issue Lifecycle Management
- Get-GitHubIssueStatus: Comprehensive issue status and lifecycle tracking
- Update-GitHubIssueState: State transitions with audit trail
- Test-UnityErrorResolved: Unity error resolution detection
- Close-GitHubIssueIfResolved: Automated issue closing with confidence scoring
- Reopen support for recurring errors

### Multi-Repository Support
- Get-GitHubRepositories: Configured repository management
- Test-GitHubRepositoryAccess: API access validation
- Get-UnityProjectCategory: Smart project categorization
- Search-GitHubIssuesMultiRepo: Cross-repository searching
- Project-to-repository mapping

### Performance Optimization
- Get-GitHubAPIUsageStats: Comprehensive API usage analytics
- GitHub issue caching system for reduced API calls
- Request batching and optimization
- Historical usage tracking with recommendations

## Version 1.1.0 (2025-08-22)
- Added comprehensive Issue Management System
- New functions for issue creation, search, and updates
- Unity error signature generation for deduplication
- Smart duplicate detection with similarity scoring
- Automated issue formatting from Unity errors
- Comment threading for recurring errors
- Integration with Unity-Claude error pipeline

## Version 1.0.0
- Initial release
- Secure PAT storage using DPAPI
- Rate limiting with exponential backoff
- Comprehensive error handling
- GitHub issue creation and management
- Integration with PowerShellForGitHub module
'@
            
            # Prerelease string of this module
            Prerelease = ''
            
            # Flag to indicate whether the module requires explicit user acceptance
            RequireLicenseAcceptance = $false
            
            # External dependent modules of this module
            ExternalModuleDependencies = @('PowerShellForGitHub')
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
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCWEJAVhRfvVhZu
# sStLx+KlijvTbG44eFTfK3MB5rEsmaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDNj7fXAJiVB76C31v1RdR+U
# vvseBvLwkiKjbCMMcpZpMA0GCSqGSIb3DQEBAQUABIIBAJ2noL8DhylOWkJ2b7t8
# MUwulPfmeywjatXK65kbgTvC3RH/UzUCOcUXH5C5ly2aU/512gJqQM3KbgBNRFCN
# QNyb/H9ZXUplTM816kXzwGHxUPsD2uL8l10sblzMeXUDNds+h3+gEY3uJMO1z+4j
# UogCKlU7+edz9/Jo/2Gk8ofm2908EgFTEGjEONw0APxOc2Wc/nrR2szJ7ftP+EEN
# ZGM9x3NNA7VffiOZRiEd2FT7HR8AKa394hqWcYu1aCTwyNmxOVofpwaJ7zNMkECJ
# IFSfJS0zDM7mwcIuw4FXKUpNJlXFB6rhTAWxjtGIpNrk3OD4+kJgw6wSylRA1EX8
# t6I=
# SIG # End signature block
