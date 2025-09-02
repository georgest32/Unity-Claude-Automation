# Unity-Claude-RealTimeMonitoring.psd1
# Module manifest for Unity-Claude Real-Time Monitoring Framework

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-RealTimeMonitoring.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # ID used to uniquely identify this module
    GUID = 'a4e7c3d8-9b2f-4e6a-8c1d-5f3e7a9b2c4d'
    
    # Author of this module
    Author = 'Unity-Claude-Automation Team'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude-Automation'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Advanced Real-Time Monitoring Framework for Enhanced Documentation System. Provides comprehensive FileSystemWatcher infrastructure with intelligent event handling, automatic recovery, and performance optimization for monitoring code changes in real-time.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Initialize-RealTimeMonitoring',
        'Start-FileSystemMonitoring',
        'Stop-FileSystemMonitoring',
        'Get-MonitoringStatistics',
        'Get-MonitoringConfiguration',
        'Set-MonitoringConfiguration',
        'Test-MonitoringHealth'
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
        'Unity-Claude-RealTimeMonitoring.psm1',
        'Unity-Claude-RealTimeMonitoring.psd1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for module discovery
            Tags = @('RealTimeMonitoring', 'FileSystemWatcher', 'Documentation', 'Automation', 'Unity-Claude')
            
            # A URL to the license for this module
            LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri = ''
            
            # A URL to an icon representing this module
            IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of Real-Time Monitoring Framework for Week 3 implementation'
            
            # External module dependencies
            ExternalModuleDependencies = @()
        }
    }
    
    # HelpInfo URI of this module
    HelpInfoURI = ''
}