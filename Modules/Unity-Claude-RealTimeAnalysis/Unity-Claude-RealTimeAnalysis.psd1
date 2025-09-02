# Unity-Claude-RealTimeAnalysis.psd1
# Module manifest for Unity-Claude Real-Time Analysis Pipeline

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-RealTimeAnalysis.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # ID used to uniquely identify this module
    GUID = 'c6f9e5ea-1d4a-6f8c-0e3f-7a5b9c1e4f6a'
    
    # Author of this module
    Author = 'Unity-Claude-Automation Team'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude-Automation'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Real-Time Analysis Pipeline Integration Module for Enhanced Documentation System. Provides seamless integration between FileSystemWatcher monitoring, intelligent change detection, semantic analysis, predictive analysis, and live visualization updates with streaming processing capabilities.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @('System.Collections.Concurrent', 'System.Threading')
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Initialize-RealTimeAnalysisPipeline',
        'Start-RealTimeAnalysisPipeline',
        'Stop-RealTimeAnalysisPipeline',
        'Get-RealTimeAnalysisStatistics',
        'Get-PipelineConfiguration',
        'Set-PipelineConfiguration',
        'Test-PipelineHealth',
        'Submit-TestAnalysisRequest'
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
        'Unity-Claude-RealTimeAnalysis.psm1',
        'Unity-Claude-RealTimeAnalysis.psd1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for module discovery
            Tags = @('RealTime', 'Analysis', 'Pipeline', 'Integration', 'Streaming', 'Unity-Claude')
            
            # A URL to the license for this module
            LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri = ''
            
            # A URL to an icon representing this module
            IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of Real-Time Analysis Pipeline Integration with streaming processing and multi-module coordination'
            
            # External module dependencies
            ExternalModuleDependencies = @('Unity-Claude-RealTimeMonitoring', 'Unity-Claude-ChangeIntelligence')
        }
    }
    
    # HelpInfo URI of this module
    HelpInfoURI = ''
}