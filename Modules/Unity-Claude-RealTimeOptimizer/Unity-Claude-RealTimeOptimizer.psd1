# Unity-Claude-RealTimeOptimizer.psd1
# Module manifest for Unity-Claude Real-Time System Optimizer

@{
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-RealTimeOptimizer.psm1'
    
    # Version number of this module
    ModuleVersion = '1.0.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # ID used to uniquely identify this module
    GUID = 'd7a0f6eb-2e5a-7a9d-1f4a-8b6a0d2f5a7a'
    
    # Author of this module
    Author = 'Unity-Claude-Automation Team'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude-Automation'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Real-Time System Resource Optimization Module for Enhanced Documentation System. Provides adaptive throttling, intelligent batching, memory management, and automatic performance optimization for continuous real-time monitoring and intelligence operations.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @()
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Initialize-RealTimeOptimizer',
        'Start-RealTimeOptimization',
        'Stop-RealTimeOptimizer',
        'Get-RTPerformanceStatistics',
        'Get-RTOptimalBatchSize',
        'Get-RTThrottledDelay'
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
        'Unity-Claude-RealTimeOptimizer.psm1',
        'Unity-Claude-RealTimeOptimizer.psd1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for module discovery
            Tags = @('RealTime', 'Optimization', 'Performance', 'ResourceManagement', 'Throttling', 'Unity-Claude')
            
            # A URL to the license for this module
            LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri = ''
            
            # A URL to an icon representing this module
            IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of Real-Time System Optimizer with adaptive throttling, intelligent batching, and automatic memory management for continuous operation'
            
            # External module dependencies
            ExternalModuleDependencies = @()
        }
    }
    
    # HelpInfo URI of this module
    HelpInfoURI = ''
}