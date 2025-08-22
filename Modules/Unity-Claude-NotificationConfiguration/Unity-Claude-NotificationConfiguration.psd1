@{
    # Module manifest for Unity-Claude-NotificationConfiguration
    # Generated: 2025-08-22
    # Purpose: Configuration management for notification settings

    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-NotificationConfiguration.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = 'a8f3c2d5-9e7b-4f6a-8c3e-2d5a7b9c1e4f'
    
    # Author of this module
    Author = 'Unity-Claude Automation Team'
    
    # Company or vendor of this module
    CompanyName = 'Auto-m8'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Auto-m8. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Configuration management system for Unity-Claude notification settings. Provides tools for managing, validating, and testing notification configurations.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @(
        # Configuration Management
        'Get-NotificationConfig',
        'Set-NotificationConfig',
        'Test-NotificationConfig',
        'Reset-NotificationConfig',
        
        # Backup and Restore
        'Backup-NotificationConfig',
        'Restore-NotificationConfig',
        'Get-ConfigBackupHistory',
        
        # Configuration Wizard
        'Start-NotificationConfigWizard',
        'Test-EmailConfiguration',
        'Test-WebhookConfiguration',
        
        # Validation
        'Test-ConfigurationSchema',
        'Get-ConfigurationDefaults',
        'Merge-ConfigurationSources',
        
        # Utilities
        'Export-NotificationConfig',
        'Import-NotificationConfig',
        'Compare-NotificationConfig',
        'Get-ConfigurationReport'
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
            Tags = @('Unity', 'Claude', 'Automation', 'Configuration', 'Notifications')
            ProjectUri = 'https://github.com/auto-m8/unity-claude-automation'
            IconUri = ''
            ReleaseNotes = 'Initial release - Week 6 Day 5 Implementation'
        }
    }
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        'Unity-Claude-SystemStatus',
        'Unity-Claude-EmailNotifications',
        'Unity-Claude-WebhookNotifications'
    )
}