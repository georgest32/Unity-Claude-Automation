# Unity-Claude-IntelligentAlerting.psd1
# Module manifest for Unity-Claude Intelligent Alerting System

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-IntelligentAlerting.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # ID used to uniquely identify this module
    GUID = 'f9c2b8ed-4a7b-9c1f-3b6c-0d8b2c5f8b1c'
    
    # Author of this module
    Author = 'Unity-Claude-Automation Team'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude-Automation'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Intelligent Alerting System Integration Module for Enhanced Documentation System. Provides comprehensive integration between AI-powered alert classification, existing notification infrastructure, priority-based escalation procedures, alert correlation, deduplication, and contextual enrichment capabilities.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Initialize-IntelligentAlerting',
        'Start-IntelligentAlerting',
        'Stop-IntelligentAlerting',
        'Submit-Alert',
        'Get-IntelligentAlertingStatistics'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # List of all modules packaged with this module
    ModuleList = @()
    
    # List of all files packaged with this module
    FileList = @(
        'Unity-Claude-IntelligentAlerting.psm1',
        'Unity-Claude-IntelligentAlerting.psd1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for module discovery
            Tags = @('Alerting', 'AI', 'Intelligence', 'Notification', 'Escalation', 'Integration', 'Unity-Claude')
            
            # A URL to the license for this module
            LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri = ''
            
            # A URL to an icon representing this module
            IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of Intelligent Alerting System with AI classification integration, priority-based escalation, and comprehensive notification management'
            
            # External module dependencies
            ExternalModuleDependencies = @('Unity-Claude-AIAlertClassifier', 'Unity-Claude-NotificationIntegration')
        }
    }
    
    # HelpInfo URI of this module
    HelpInfoURI = ''
}