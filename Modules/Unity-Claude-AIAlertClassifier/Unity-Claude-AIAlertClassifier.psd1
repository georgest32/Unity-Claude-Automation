# Unity-Claude-AIAlertClassifier.psd1
# Module manifest for Unity-Claude AI-Powered Alert Classifier

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-AIAlertClassifier.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # ID used to uniquely identify this module
    GUID = 'e8b1a7fc-3f6a-8b0e-2a5a-9c7a1f3a6a8a'
    
    # Author of this module
    Author = 'Unity-Claude-Automation Team'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude-Automation'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'AI-Powered Alert Classification and Prioritization Module for Enhanced Documentation System. Provides intelligent alert classification using Ollama, priority-based escalation procedures, contextual alert enrichment, and alert correlation and deduplication to reduce notification noise.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Initialize-AIAlertClassifier',
        'Invoke-AIAlertClassification',
        'Test-AlertCorrelation',
        'Get-AIAlertStatistics'
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
        'Unity-Claude-AIAlertClassifier.psm1',
        'Unity-Claude-AIAlertClassifier.psd1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for module discovery
            Tags = @('AI', 'Alerts', 'Classification', 'Prioritization', 'Ollama', 'Escalation', 'Unity-Claude')
            
            # A URL to the license for this module
            LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri = ''
            
            # A URL to an icon representing this module
            IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of AI-Powered Alert Classifier with Ollama integration, priority-based escalation, and contextual enrichment capabilities'
            
            # External module dependencies
            ExternalModuleDependencies = @('Unity-Claude-LLM', 'Unity-Claude-ChangeIntelligence', 'Unity-Claude-NotificationIntegration')
        }
    }
    
    # HelpInfo URI of this module
    HelpInfoURI = ''
}