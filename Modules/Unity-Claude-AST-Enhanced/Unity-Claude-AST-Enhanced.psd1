@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'Unity-Claude-AST-Enhanced.psm1'
    
    # Version number of this module.
    ModuleVersion = '1.0.0'
    
    # ID used to uniquely identify this module
    GUID = '4bf492c4-ddeb-45fa-b6ef-84d6807120ad'
    
    # Author of this module
    Author = 'Unity-Claude-Automation System'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude-Automation'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude-Automation. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Enhanced AST analysis and function call mapping for Unity-Claude-Automation Enhanced Documentation System. Provides comprehensive PowerShell module analysis, cross-module relationship mapping, and D3.js visualization data export capabilities.'
    
    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Name of the Windows PowerShell host required by this module
    # PowerShellHostName = ''
    
    # Minimum version of the Windows PowerShell host required by this module
    # PowerShellHostVersion = ''
    
    # Minimum version of Microsoft .NET Framework required by this module
    DotNetFrameworkVersion = '4.7.2'
    
    # Minimum version of the common language runtime (CLR) required by this module
    # CLRVersion = ''
    
    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @(
        @{
            ModuleName = 'DependencySearch'
            ModuleVersion = '1.0.0'
        }
    )
    
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
    
    # Functions to export from this module
    FunctionsToExport = @(
        'Get-ModuleCallGraph',
        'Get-CrossModuleRelationships', 
        'Get-FunctionCallAnalysis',
        'Export-CallGraphData'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
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
            Tags = @('AST', 'Analysis', 'Visualization', 'PowerShell', 'Unity', 'Documentation', 'CallGraph', 'Dependencies')
            
            # A URL to the license for this module.
            # LicenseUri = ''
            
            # A URL to the main website for this project.
            # ProjectUri = ''
            
            # A URL to an icon representing this module.
            # IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
Version 1.0.0 (2025-08-30)
- Initial release of Unity-Claude-AST-Enhanced module
- Comprehensive PowerShell AST analysis capabilities
- Integration with DependencySearch module for enhanced dependency detection
- Cross-module relationship mapping with dependency strength calculation
- D3.js-compatible data export for network visualization
- Support for GraphML and CSV export formats
- Function call pattern analysis with complexity metrics
- Caching support for performance optimization
- Compatible with Enhanced Documentation System v2.0.0
'@
            
            # Prerelease string of this module
            # Prerelease = ''
            
            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false
            
            # External dependent modules of this module
            ExternalModuleDependencies = @('DependencySearch')
        }
    }
    
    # HelpInfo URI of this module
    # HelpInfoURI = ''
    
    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''
}