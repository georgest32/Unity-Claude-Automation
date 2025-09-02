@{
    # Module manifest for Unity-Claude-DocumentationSuggestions
    
    RootModule = 'Unity-Claude-DocumentationSuggestions.psm1'
    ModuleVersion = '1.0.0'
    GUID = '92a5e7c8-4f1b-4d2e-8a3c-6e9f2a5b8d1f'
    
    Author = 'Unity-Claude Automation System'
    CompanyName = 'Sound and Shoal'
    Copyright = '(c) 2025 Unity-Claude Automation. All rights reserved.'
    
    Description = 'Week 3 Day 13 Hour 5-6: AI-Enhanced Content Suggestions
    
    Intelligent content suggestion system with semantic analysis and AI enhancement:
    - AI-powered content suggestions using Ollama integration
    - Semantic embedding generation with vector similarity search
    - Related content identification using cosine similarity algorithms
    - Missing cross-reference detection with rule-based and AI analysis
    - Content improvement suggestions with confidence scoring
    - Integration with cross-reference and quality assessment systems
    
    Research-validated implementation with performance optimization and caching.'
    
    PowerShellVersion = '5.1'
    
    # Functions to export
    FunctionsToExport = @(
        'Initialize-DocumentationSuggestions',
        'Generate-RelatedContentSuggestions',
        'Generate-ContentEmbedding',
        'Calculate-CosineSimilarity',
        'Find-MissingCrossReferences',
        'Generate-AIContentSuggestions',
        'Test-DocumentationSuggestions',
        'Get-DocumentationSuggestionStatistics'
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
            Tags = @('Unity', 'Claude', 'Documentation', 'AI', 'Suggestions', 'Semantic', 'Embedding', 'Similarity')
            LicenseUri = ''
            ProjectUri = ''
            IconUri = ''
            ReleaseNotes = 'Week 3 Day 13 Hour 5-6: AI-Enhanced Content Suggestions implementation
            
            v1.0.0 - Initial release with intelligent content suggestion capabilities:
            - AI-powered content analysis using Ollama integration
            - Semantic embedding generation with vector similarity search
            - Related content identification with configurable similarity thresholds
            - Missing cross-reference detection using AST and content analysis
            - Rule-based and AI-enhanced suggestion generation
            - Performance optimization with caching and batch processing
            - Integration with existing documentation quality systems
            
            Research foundation: Semantic similarity algorithms, sentence transformers,
            vector similarity search, and AI-enhanced content analysis patterns.'
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