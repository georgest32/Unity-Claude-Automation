# Unity-Claude-GitHub.psd1
# Module manifest for Unity-Claude GitHub Integration
# Generated: 2025-08-22
# Phase 4, Week 8, Day 1

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-GitHub.psm1'
    
    # Version number of this module
    ModuleVersion = '1.1.0'
    
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
    Description = 'GitHub integration module for Unity-Claude Automation System. Provides secure PAT management, issue creation, and API interaction with rate limiting and retry logic.'
    
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
        
        # Unity Error Processing
        'Format-UnityErrorAsIssue',
        'Get-UnityErrorSignature',
        'Test-GitHubIssueDuplicate'
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