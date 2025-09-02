# Module Manifest for Unity-Claude-HITL
# Generated on: 2025-08-24
# Human-in-the-Loop Integration Module for Unity Claude Automation

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-HITL-Refactored.psm1'

    # Version number of this module
    ModuleVersion = '2.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID = '4d2a1c9e-8b6f-4a3e-9d7c-2f5e8a1b3c4d'

    # Author of this module
    Author = 'Unity-Claude-Automation System'

    # Company or vendor of this module
    CompanyName = 'Unity-Claude-Automation'

    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Human-in-the-Loop (HITL) integration module for Unity Claude Automation system. Provides approval workflows, notification systems, and workflow interruption management with LangGraph integration.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # ClrVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @(
    #     @{
    #         ModuleName = 'Unity-Claude-GitHub'
    #         ModuleVersion = '2.0.0'
    #     }
    # )

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport = @(
        # Core Configuration Functions
        'Set-HITLConfiguration',
        'Get-HITLConfiguration',
        
        # Database Management Functions
        'Initialize-ApprovalDatabase',
        'Test-DatabaseConnection',
        
        # Security & Token Functions
        'New-ApprovalToken',
        'Test-ApprovalToken',
        'Get-TokenMetadata',
        'Revoke-ApprovalToken',
        
        # Approval Request Functions
        'New-ApprovalRequest',
        'Get-ApprovalStatus',
        'Set-ApprovalEscalation',
        'Get-PendingApprovals',
        'Update-ApprovalStatus',
        
        # Notification Functions
        'Send-ApprovalNotification',
        'Build-ApprovalEmailTemplate',
        'Send-ApprovalReminder',
        'Send-ApprovalResultNotification',
        
        # Workflow Integration Functions
        'Wait-HumanApproval',
        'Resume-WorkflowFromApproval',
        'Invoke-HumanApprovalWorkflow',
        'Invoke-ApprovalAction',
        'Export-ApprovalMetrics',
        'Test-HITLSystemHealth',
        
        # Enhanced Orchestration Functions
        'Get-HITLComponents',
        'Test-HITLSystemIntegration',
        'Invoke-ComprehensiveHITLAnalysis'
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport = @()

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('Unity', 'Claude', 'Automation', 'HITL', 'Approval', 'Workflow', 'LangGraph', 'GitHub')

            # A URL to the license for this module.
            # LicenseUri = ''

            # A URL to the main website for this project.
            # ProjectUri = ''

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = @"
Version 2.0.0 - Refactored Modular Architecture
- ✅ REFACTORED: Component-based modular architecture with 6 focused components
- ✅ Enhanced: Comprehensive orchestration functions for system management
- ✅ Core: HITLCore.psm1 (configuration & initialization)
- ✅ Database: DatabaseManagement.psm1 (SQLite operations & schema)
- ✅ Security: SecurityTokens.psm1 (token generation & validation)
- ✅ Requests: ApprovalRequests.psm1 (approval lifecycle management)
- ✅ Notifications: NotificationSystem.psm1 (email & webhook notifications)
- ✅ Workflow: WorkflowIntegration.psm1 (LangGraph integration & utilities)
- ✅ NEW: Test-HITLSystemIntegration for comprehensive system testing
- ✅ NEW: Invoke-ComprehensiveHITLAnalysis for system analysis
- ✅ Maintained: Full backward compatibility with v1.0.0 functions

Previous Version 1.0.0 Features:
- Human-in-the-Loop approval workflow system
- LangGraph interrupt integration
- Email-based approval notifications
- SQLite approval tracking database
- Escalation and timeout management
- Mobile-friendly approval interfaces
- Security token validation system
- Integration with Unity-Claude-GitHub module
- Comprehensive audit trail and metrics
"@

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()
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
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA/TaGzNWy/NDcU
# 7WXemRFGgxmPJWY5VN3iOu9kmekvj6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBk/7hvof42gCz4BuQTn/J1n
# czDCHUlVW12/F2wVVuvZMA0GCSqGSIb3DQEBAQUABIIBAIylq2J5iqEUVblUrt+s
# b2e3AmqDrAZH7nUtMSyr1+8HtV1Krj4hOcMeFBN8tCCCCO1rZkxAIyDnquaEf9wr
# 0+k6GRWHnJJY/OTVZ0lebMgxMnplMpzMTQ7YOrvjcweeoW1lRyMZKMmBSQfaf/KC
# iY+X2dnyl7CyKdo5Ke+ZEOWzN0dYGenMMeVxwheXtkMDIAaJtY7U1F7GI9f5jNyI
# KG1K0xHPPyi+oARHxMUq5emsMtOtsa10aqLlmiv7PcQMkrZCgK4Vc1KaBwMBaeVb
# tO2ATtXcFY4cSXqdOCn2ht4QW9B9IZDbYLEYGclZDOTd8H9bLrRsFK/yZcHrJ/lL
# cnA=
# SIG # End signature block
