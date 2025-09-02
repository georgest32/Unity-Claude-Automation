# Unity-Claude-ProactiveMaintenanceEngine.psd1
# Module manifest for Unity-Claude Proactive Maintenance Engine

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-ProactiveMaintenanceEngine.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-5e6f-7a8b-9c0d-1e2f3a4b5c6d'
    
    # Author of this module
    Author = 'Unity-Claude-Automation Team'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude-Automation'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Proactive Maintenance Recommendation System for Enhanced Documentation System. Provides intelligent maintenance recommendations based on real-time analysis, trend analysis for early warning, recommendation ranking with impact assessment, and integration with existing notification and alert systems.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Initialize-ProactiveMaintenanceEngine',
        'Start-ProactiveMaintenanceEngine',
        'Stop-ProactiveMaintenanceEngine',
        'Get-ProactiveRecommendations',
        'Get-MaintenanceWarnings',
        'Get-ProactiveMaintenanceStatistics',
        'Invoke-TestAnalysisCycle'
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
        'Unity-Claude-ProactiveMaintenanceEngine.psm1',
        'Unity-Claude-ProactiveMaintenanceEngine.psd1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for module discovery
            Tags = @('Proactive', 'Maintenance', 'Recommendations', 'TrendAnalysis', 'EarlyWarning', 'Unity-Claude')
            
            # A URL to the license for this module
            LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri = ''
            
            # A URL to an icon representing this module
            IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of Proactive Maintenance Engine with real-time integration, trend analysis, early warning system, and recommendation ranking capabilities'
            
            # External module dependencies
            ExternalModuleDependencies = @('Unity-Claude-PredictiveAnalysis', 'Unity-Claude-RealTimeMonitoring', 'Unity-Claude-AIAlertClassifier')
        }
    }
    
    # HelpInfo URI of this module
    HelpInfoURI = ''
}