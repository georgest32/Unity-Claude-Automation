#
# Module manifest for module 'Unity-Claude-DocumentationAutomation-Refactored'
#

@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Unity-Claude-DocumentationAutomation.psm1'
    
    # Version number of this module.
    ModuleVersion = '2.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # ID used to uniquely identify this module
    GUID = 'a8b7c6d5-4e3f-4a2b-9c8d-7e6f5a4b3c2d'
    
    # Author of this module
    Author = 'Unity-Claude-Automation'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude-Automation'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = @'
Unity-Claude Documentation Automation Module - Refactored Architecture

Provides comprehensive automated documentation update system with GitHub PR automation,
intelligent synchronization, review workflows, and backup capabilities. This is the 
refactored version featuring a component-based architecture for improved maintainability.

ARCHITECTURE OVERVIEW:
- AutomationEngine: Core automation lifecycle management
- GitHubPRManager: Pull request creation and management  
- TemplateSystem: Documentation template system
- TriggerSystem: Auto-generation triggers and workflows
- BackupIntegration: Backup/recovery and system integration

REFACTORING BENEFITS:
- Improved maintainability with focused components (~326 lines average)
- Enhanced testability with isolated functionality
- Better error isolation and debugging capabilities
- Easier feature development and extension

ORIGINAL: 1,633 lines in single monolithic module
REFACTORED: 5 components + orchestration for modular architecture

Features:
- Automated documentation generation from code changes
- GitHub PR automation with intelligent branching
- Template-based content generation system
- Multi-trigger automation (file changes, Git commits, schedules)
- Comprehensive backup and recovery capabilities
- Integration with predictive analysis systems
- Review workflows with approval mechanisms
- Comprehensive reporting and metrics
'@
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''
    
    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''
    
    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''
    
    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # CLRVersion = ''
    
    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()
    
    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @(
        'Core\AutomationEngine.psm1',
        'Core\GitHubPRManager.psm1', 
        'Core\TemplateSystem.psm1',
        'Core\TriggerSystem.psm1',
        'Core\BackupIntegration.psm1'
    )
    
    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        # Orchestration functions
        'Initialize-DocumentationAutomation',
        'Test-ComponentHealth',
        'Get-DocumentationAutomationInfo',
        
        # AutomationEngine functions  
        'Start-DocumentationAutomation',
        'Stop-DocumentationAutomation',
        'Test-DocumentationSync',
        'Get-DocumentationStatus',
        
        # GitHubPRManager functions
        'New-DocumentationPR',
        'Update-DocumentationPR',
        'Get-DocumentationPRs', 
        'Merge-DocumentationPR',
        'Test-PRDocumentationChanges',
        
        # TemplateSystem functions
        'New-DocumentationTemplate',
        'Get-DocumentationTemplates',
        'Update-DocumentationTemplate',
        'Export-DocumentationTemplates',
        'Import-DocumentationTemplates',
        'Invoke-TemplateRendering',
        
        # TriggerSystem functions
        'Register-DocumentationTrigger',
        'Unregister-DocumentationTrigger', 
        'Get-DocumentationTriggers',
        'Test-TriggerConditions',
        'Invoke-DocumentationUpdate',
        'Start-DocumentationReview',
        'Get-ReviewStatus',
        'Approve-DocumentationChanges',
        'Reject-DocumentationChanges',
        'Get-ReviewMetrics',
        
        # BackupIntegration functions
        'New-DocumentationBackup',
        'Restore-DocumentationBackup',
        'Get-DocumentationHistory',
        'Test-RollbackCapability', 
        'Sync-WithPredictiveAnalysis',
        'Update-FromCodeChanges',
        'Generate-ImprovementDocs',
        'Export-DocumentationReport'
    )
    
    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @('sda', 'ndr', 'idt', 'gds', 'ndb', 'ida')
    
    # DSC resources to export from this module
    # DscResourcesToExport = @()
    
    # List of all modules packaged with this module
    # ModuleList = @()
    
    # List of all files packaged with this module
    FileList = @(
        'Unity-Claude-DocumentationAutomation-Refactored.psm1',
        'Unity-Claude-DocumentationAutomation-Refactored.psd1',
        'Core\AutomationEngine.psm1',
        'Core\GitHubPRManager.psm1',
        'Core\TemplateSystem.psm1', 
        'Core\TriggerSystem.psm1',
        'Core\BackupIntegration.psm1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Documentation', 'Automation', 'GitHub', 'PR', 'Templates', 'Backup', 'Unity', 'Claude', 'Refactored')
            
            # A URL to the license for this module.
            LicenseUri = ''
            
            # A URL to the main website for this project.
            ProjectUri = ''
            
            # A URL to an icon representing this module.
            IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
Version 2.0.0 - Refactored Architecture Release

MAJOR CHANGES:
- Complete refactoring from monolithic 1,633-line module to component-based architecture
- 5 focused components: AutomationEngine, GitHubPRManager, TemplateSystem, TriggerSystem, BackupIntegration
- Average component size: ~326 lines (down from 1,633 monolithic)
- Enhanced maintainability, testability, and modularity

NEW FEATURES:
- Component health monitoring with Test-ComponentHealth
- Comprehensive system information via Get-DocumentationAutomationInfo
- Enhanced initialization with Initialize-DocumentationAutomation
- Improved error isolation between components
- Better debugging and troubleshooting capabilities

ARCHITECTURE IMPROVEMENTS:
- Separation of concerns with focused components
- Improved code organization and readability
- Enhanced testability with isolated functionality
- Better error handling and recovery
- Easier feature development and extension

COMPONENT BREAKDOWN:
- AutomationEngine (250 lines): Core automation lifecycle management
- GitHubPRManager (270 lines): Pull request creation and management  
- TemplateSystem (320 lines): Documentation template system
- TriggerSystem (490 lines): Auto-generation triggers and workflows
- BackupIntegration (300 lines): Backup/recovery and system integration

BENEFITS:
- Reduced complexity per component
- Improved maintainability
- Enhanced debugging capabilities
- Better separation of concerns
- Easier testing and validation
- More focused development workflow

COMPATIBILITY:
- Fully backward compatible with existing functionality
- All original functions preserved and enhanced
- New orchestration functions for improved management
- Enhanced error handling and recovery mechanisms
'@
            
            # Prerelease string of this module
            # Prerelease = ''
            
            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            RequireLicenseAcceptance = $false
            
            # External dependent modules of this module
            ExternalModuleDependencies = @()
        }
    }
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    
    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAMTT1CWYx9ttOQ
# 1WLRV7WpZ0ufJNj5QwwmV1r4f+iMyKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEII45cj2gTa8YQ3XQxWzJ0/ti
# p2x7RZgG/Y7eo4AFEKfVMA0GCSqGSIb3DQEBAQUABIIBAH+ekgTnOrJOEywG3Sj1
# gvPB6hlnHpXZbjk/XqCze5vePT55a6Ja7HoKpX7k8MmZ01rWricA7h6TaBwf1wa6
# lctXrVjfgg37d5t+kGBcnLptUZogJjdPz2I/syCOo8dBjqJ37c7VvvHhdxBKCB4G
# WfK6vifROUUQZqlpBGs2ipPhJrQ/mRPqiqwqCyruejUdYOjujbZhuJwAKGq/yqHl
# dhxX2Ylq8eq6qdvCrh/6PegYsd3qRzfeNEKldF8jHTmJsx98amCRTyauC+0+APWv
# Ar6RRfK0fKidBAKWwFrdcuAmbgiDpF+MzzpbWHV3iaBqCT7awecp5xeQ4n/rjkEF
# dx8=
# SIG # End signature block
