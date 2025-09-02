@{
    # Module manifest for Unity-Claude-CPG
    
    # Script module or binary module file associated with this manifest
    RootModule = 'Unity-Claude-CPG-Refactored.psm1'
    
    # Version number of this module
    ModuleVersion = '1.3.0'
    
    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # ID used to uniquely identify this module
    GUID = 'a7c8f9e2-3b5d-4e7f-9c1a-8d6b5f4e2a3c'
    
    # Author of this module
    Author = 'Unity-Claude Automation System'
    
    # Company or vendor of this module
    CompanyName = 'Unity-Claude'
    
    # Copyright statement for this module
    Copyright = '(c) 2025 Unity-Claude. All rights reserved.'
    
    # Description of the functionality provided by this module
    Description = 'Code Property Graph (CPG) implementation for PowerShell code analysis, relationship mapping, and obsolescence detection. Based on Joern architecture with PowerShell-specific optimizations.'
    
    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'
    
    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()
    
    # Assemblies that must be loaded prior to importing this module
    RequiredAssemblies = @()
    
    # Script files (.ps1) that are run in the caller's environment prior to importing this module
    ScriptsToProcess = @('Unity-Claude-CPG-Enums.ps1')
    
    # Type files (.ps1xml) to be loaded when importing this module
    TypesToProcess = @()
    
    # Format files (.ps1xml) to be loaded when importing this module
    FormatsToProcess = @()
    
    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # Now safe to use since circular dependency is broken
    NestedModules = @('Unity-Claude-CPG-ASTConverter.psm1')
    
    # Functions to export from this module (updated for refactored architecture)
    FunctionsToExport = @(
        # Core graph API (from BasicOperations)
        'New-CPGraph','New-CPGNode','Add-CPGNode','New-CPGEdge','Add-CPGEdge',
        
        # Query operations  
        'Get-CPGNode','Get-CPGEdge','Get-CPGNeighbors','Find-CPGPath',
        
        # Analysis operations (new in refactored version)
        'Get-CPGStatistics','Test-CPGStronglyConnected','Get-CPGComplexityMetrics','Find-CPGCycles',
        
        # Serialization operations
        'Export-CPGraph','Import-CPGraph',
        
        # AST conversion operations
        'Convert-ASTtoCPG','ConvertTo-CPGFromFile','ConvertTo-CPGFromScriptBlock'
    )
    
    # Cmdlets to export from this module
    CmdletsToExport = @()
    
    # Variables to export from this module
    VariablesToExport = @()
    
    # Aliases to export from this module
    AliasesToExport = @()
    
    # DSC resources to export from this module
    DscResourcesToExport = @()
    
    # List of all modules packaged with this module
    ModuleList = @(
        'Unity-Claude-CPG.psm1',
        'Unity-Claude-CPG-ASTConverter.psm1',
        'Unity-Claude-TreeSitter.psm1',
        'Unity-Claude-CrossLanguage.psm1',
        'Unity-Claude-ObsolescenceDetection.psm1'
    )
    
    # List of all files packaged with this module
    FileList = @(
        'Unity-Claude-CPG.psd1',
        'Unity-Claude-CPG.psm1',
        'Unity-Claude-CPG-ASTConverter.psm1',
        'Unity-Claude-CPG-Enums.ps1',
        'Unity-Claude-TreeSitter.psm1',
        'Unity-Claude-CrossLanguage.psm1',
        'Unity-Claude-ObsolescenceDetection.psm1',
        'Unity-Claude-CPG.Tests.ps1',
        'Test-TreeSitterIntegration.ps1',
        'Test-ObsolescenceDetection.ps1'
    )
    
    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module for module discovery
            Tags = @('CPG', 'CodePropertyGraph', 'AST', 'CodeAnalysis', 'PowerShell', 'Automation', 'RelationshipMapping', 'ObsolescenceDetection')
            
            # A URL to the license for this module
            LicenseUri = ''
            
            # A URL to the main website for this project
            ProjectUri = 'https://github.com/unity-claude/automation'
            
            # A URL to an icon representing this module
            IconUri = ''
            
            # ReleaseNotes of this module
            ReleaseNotes = @'
## Version 1.2.0
- Added comprehensive obsolescence detection system
- DePA algorithm implementation for line-level perplexity analysis
- Unreachable code detection using graph traversal
- Code redundancy testing with Levenshtein distance
- Code complexity metrics (cyclomatic, cognitive, Halstead)
- Documentation drift detection and accuracy testing
- Automated documentation suggestion generation
- Effort estimation for documentation updates

## Version 1.1.0
- Added Tree-sitter integration for universal parsing
- Support for JavaScript, TypeScript, Python, and C# parsing
- CST to CPG conversion capabilities
- Cross-language relationship mapping
- Unified graph merging for multi-language codebases
- Performance benchmarking tools
- Cross-language statistics and reporting

## Version 1.0.0
- Initial release of Unity-Claude-CPG module
- Core CPG data structures (nodes, edges, graphs)
- Thread-safe operations with synchronized hashtables
- AST to CPG conversion for PowerShell
- Support for multiple node types (Module, Function, Class, Variable, etc.)
- Support for multiple edge types (Calls, Uses, Imports, Extends, etc.)
- Graph traversal and path finding
- Export/Import capabilities (JSON, DOT, GraphML)
- Integration with Unity-Claude documentation pipeline
'@
            
            # Prerelease string of this module
            Prerelease = ''
            
            # Flag to indicate whether the module requires explicit user acceptance
            RequireLicenseAcceptance = $false
            
            # External dependent modules of this module
            ExternalModuleDependencies = @()
        }
    }
    
    # HelpInfo URI of this module
    HelpInfoURI = ''
    
    # Default prefix for commands exported from this module
    DefaultCommandPrefix = ''
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCByoZzGIr3AVQwu
# Q4q6azdDcgV1bo5EOn7c7IZgi1bOPqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIE4Qq6jUMrASmqWBMxFLRW17
# 4dKb5xvMt5PRQ3TdBHGHMA0GCSqGSIb3DQEBAQUABIIBAH4Rz/ihV79Tbc6f2c8C
# O5kZfcdRotGbz0hfsfmFkOfky5nAaoCKDxJzEZn5xFQ8m9z9dNfi0qQqedXbO6Kr
# tSklmE99cixSEHBgN5rvLkAB3iqVzTUTNowF45jLu0J6Yv8sYPLOnvG5kERh/Z/d
# ogj1n2Asigb4yWTmsJiOJQfAD3fqNpRes/bgYyvg2A6yf6ICSDpICrCpX5Aa63qE
# 8ubOSr6VHVMGo94iTmjRl/fA4qu46EhKn7f+Y+lzmciclOVVBXkMkHNJ9rMK0O7e
# 2iboYb26Q0rYrVYlQCzvv8Hlxa0so7+d7bg+qFP+RTNdDddm3/NPzrQLK+6LwbXi
# h98=
# SIG # End signature block
