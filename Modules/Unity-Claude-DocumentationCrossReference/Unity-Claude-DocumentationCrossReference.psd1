@{
    # Module manifest for Unity-Claude-DocumentationCrossReference
    
    RootModule = 'Unity-Claude-DocumentationCrossReference.psm1'
    ModuleVersion = '1.0.0'
    GUID = '47f8c9b2-8e3d-4a5f-9c2e-1b4d6f8a9c3e'
    
    Author = 'Unity-Claude Automation System'
    CompanyName = 'Sound and Shoal'
    Copyright = '(c) 2025 Unity-Claude Automation. All rights reserved.'
    
    Description = 'Week 3 Day 13 Hour 5-6: Cross-Reference and Link Management
    
    AST-based cross-reference detection and intelligent documentation graph analysis with:
    - PowerShell AST analysis for comprehensive cross-reference mapping
    - Markdown link extraction with intelligent classification  
    - Documentation graph analysis with centrality scoring
    - Real-time link validation with performance optimization
    - Integration with existing quality assessment and orchestration systems
    
    Research-validated implementation with performance optimization patterns.'
    
    PowerShellVersion = '5.1'
    
    # Functions to export
    FunctionsToExport = @(
        'Initialize-DocumentationCrossReference',
        'Get-ASTCrossReferences',
        'Extract-MarkdownLinks',
        'Find-FunctionDefinitions',
        'Find-FunctionCalls',
        'Build-DocumentationGraph',
        'Calculate-DocumentationCentrality',
        'Invoke-LinkValidation',
        'Test-DocumentationCrossReference',
        'Get-DocumentationCrossReferenceStatistics'
    )
    
    # Cmdlets to export
    CmdletsToExport = @()
    
    # Variables to export
    VariablesToExport = @()
    
    # Aliases to export
    AliasesToExport = @()
    
    # Private data
    PrivateData = @{
        PSData = @{
            Tags = @('Unity', 'Claude', 'Documentation', 'CrossReference', 'LinkManagement', 'AST', 'Graph', 'AI')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Week 3 Day 13 Hour 5-6: Cross-Reference and Link Management implementation
            
            v1.0.0 - Initial release with comprehensive cross-reference capabilities:
            - AST-based PowerShell code analysis with function/module mapping
            - Markdown link extraction with classification and validation
            - Documentation graph construction with centrality analysis
            - Performance optimization with caching and selective processing
            - Integration with existing quality assessment systems
            - Real-time monitoring capabilities with FileSystemWatcher
            
            Research foundation: 19 comprehensive web searches covering AST analysis,
            link validation, graph algorithms, AI enhancement, and performance optimization.'
        }
    }
    
    # Module requirements
    RequiredModules = @()
    RequiredAssemblies = @()
    
    # Module compatibility
    CompatiblePSEditions = @('Desktop', 'Core')
    
    # Help info
    HelpInfoURI = ''
}