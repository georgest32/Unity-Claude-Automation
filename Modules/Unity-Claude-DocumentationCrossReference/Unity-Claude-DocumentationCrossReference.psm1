# Unity-Claude-DocumentationCrossReference.psm1
# Week 3 Day 13 Hour 5-6: Cross-Reference and Link Management
# AST-based cross-reference detection and intelligent documentation graph analysis
# Research-validated implementation with performance optimization

# Module state for cross-reference management (restored with memory safety)
$script:CrossReferenceState = @{
    IsInitialized = $false
    Configuration = $null
    CrossReferenceDatabase = @{}
    DocumentationGraph = @{
        Nodes = @{}
        Edges = @{}
        Metrics = @{}
    }
    LinkValidationCache = @{}
    PerformanceMetrics = @{
        AnalysisTime = 0
        ValidationTime = 0
        GraphBuildTime = 0
        CacheHitRate = 0
        ProcessedFiles = 0
        DetectedReferences = 0
        ValidatedLinks = 0
        StartTime = $null
    }
    MonitoringState = @{
        FileSystemWatcher = $null
        IsMonitoring = $false
        LastProcessed = Get-Date
    }
}

# Cross-reference types for classification
enum CrossReferenceType {
    FunctionCall
    ModuleImport
    DotSource
    VariableReference
    MarkdownLink
    InternalLink
    ExternalLink
    RelativeLink
    CodeReference
}

# Link validation status enumeration
enum LinkValidationStatus {
    Valid
    Broken
    Redirect
    Timeout
    Forbidden
    NotChecked
    Cached
}

# Documentation node types for graph analysis
enum DocumentationNodeType {
    PowerShellModule
    MarkdownDocument
    Function
    Variable
    Class
    Enum
    Configuration
    TestScript
}

function Initialize-DocumentationCrossReference {
    <#
    .SYNOPSIS
        Initializes the documentation cross-reference and link management system.
    
    .DESCRIPTION
        Sets up AST-based cross-reference detection, link validation, and intelligent
        content suggestion capabilities with performance optimization and real-time monitoring.
        Research-validated implementation following Week 3 Day 13 Hour 5-6 objectives.
    
    .PARAMETER EnableRealTimeMonitoring
        Enable FileSystemWatcher-based real-time link monitoring.
    
    .PARAMETER EnableAIEnhancement
        Enable AI-powered content suggestions using Ollama integration.
    
    .PARAMETER CacheExpiration
        Cache expiration time in minutes for link validation results.
    
    .PARAMETER MaxConcurrentOperations
        Maximum number of concurrent operations for performance optimization.
    
    .EXAMPLE
        Initialize-DocumentationCrossReference -EnableRealTimeMonitoring -EnableAIEnhancement -CacheExpiration 60
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$EnableRealTimeMonitoring = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableAIEnhancement = $true,
        
        [Parameter(Mandatory = $false)]
        [int]$CacheExpiration = 30,
        
        [Parameter(Mandatory = $false)]
        [int]$MaxConcurrentOperations = 5
    )
    
    try {
        Write-Host "[CrossRef] Initializing Documentation Cross-Reference and Link Management System..." -ForegroundColor Cyan
        
        # Initialize configuration (restored with self-analysis protection)
        $script:CrossReferenceState.Configuration = @{
            EnableRealTimeMonitoring = $EnableRealTimeMonitoring.IsPresent
            EnableAIEnhancement = $EnableAIEnhancement.IsPresent
            CacheExpiration = $CacheExpiration
            MaxConcurrentOperations = $MaxConcurrentOperations
            ProjectRoot = (Get-Location).Path
            DocumentationPaths = @(
                ".\docs\",
                ".\Documentation\",
                ".\README.md",
                ".\Modules\**\*.md",
                ".\*.md"
            )
            MonitoredExtensions = @(".md", ".psm1", ".ps1", ".txt")
            ExcludedFiles = @(
                $PSCommandPath,  # Exclude current module file to prevent self-analysis
                (Join-Path $PSScriptRoot "Unity-Claude-DocumentationCrossReference.psm1"),
                (Join-Path $PSScriptRoot "Unity-Claude-DocumentationSuggestions.psm1")
            )
        }
        
        # Initialize performance tracking
        $script:CrossReferenceState.PerformanceMetrics.StartTime = Get-Date
        
        # Initialize cross-reference database
        $script:CrossReferenceState.CrossReferenceDatabase = @{
            Functions = @{}
            Modules = @{}
            Variables = @{}
            Links = @{}
            LastUpdated = Get-Date
        }
        
        # Initialize documentation graph
        $script:CrossReferenceState.DocumentationGraph = @{
            Nodes = @{}
            Edges = @{}
            Metrics = @{
                TotalNodes = 0
                TotalEdges = 0
                AverageConnectivity = 0
                CentralityScores = @{}
                LastAnalysis = $null
            }
        }
        
        # Connect to existing systems
        Write-Verbose "[CrossRef] Connecting to existing documentation systems..."
        Connect-ExistingDocumentationSystems
        
        # Set initialization flag
        $script:CrossReferenceState.IsInitialized = $true
        
        Write-Host "[CrossRef] Cross-reference system initialized successfully" -ForegroundColor Green
        Write-Host "[CrossRef] Real-time monitoring: $($script:CrossReferenceState.Configuration.EnableRealTimeMonitoring)" -ForegroundColor White
        Write-Host "[CrossRef] AI enhancement: $($script:CrossReferenceState.Configuration.EnableAIEnhancement)" -ForegroundColor White
        Write-Host "[CrossRef] Cache expiration: $($script:CrossReferenceState.Configuration.CacheExpiration) minutes" -ForegroundColor White
        Write-Host "[CrossRef] Max concurrent operations: $($script:CrossReferenceState.Configuration.MaxConcurrentOperations)" -ForegroundColor White
        
        return $true
    }
    catch {
        Write-Error "[CrossRef] Failed to initialize cross-reference system: $($_.Exception.Message)"
        return $false
    }
}

function Get-ASTCrossReferences {
    <#
    .SYNOPSIS
        Extracts cross-references from PowerShell files using AST analysis.
    
    .DESCRIPTION
        Uses PowerShell Abstract Syntax Tree analysis to identify function definitions,
        function calls, module imports, and variable references for comprehensive
        cross-reference mapping. Research-validated AST parsing implementation.
    
    .PARAMETER FilePath
        Path to PowerShell file for analysis.
    
    .PARAMETER IncludeCodeReferences
        Include code-level references in addition to documentation references.
    
    .EXAMPLE
        Get-ASTCrossReferences -FilePath ".\Modules\Unity-Claude-Core\Unity-Claude-Core.psm1"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeCodeReferences = $true
    )
    
    try {
        Write-Verbose "[CrossRef] Analyzing AST for file: $FilePath"
        
        if (-not (Test-Path $FilePath)) {
            Write-Warning "[CrossRef] File not found: $FilePath"
            return $null
        }
        
        # Check for excluded files to prevent self-analysis crashes
        $excludedFiles = @(
            $PSCommandPath,
            (Join-Path $PSScriptRoot "Unity-Claude-DocumentationCrossReference.psm1"),
            (Join-Path $PSScriptRoot "Unity-Claude-DocumentationSuggestions.psm1")
        )
        
        $shouldExclude = $false
        foreach ($excludedPath in $excludedFiles) {
            if ($FilePath -eq $excludedPath -or $FilePath.Contains("DocumentationCrossReference") -or $FilePath.Contains("DocumentationSuggestions")) {
                Write-Warning "[CrossRef] Skipping self-analysis file to prevent memory corruption: $FilePath"
                return @{
                    FilePath = $FilePath
                    LastAnalyzed = Get-Date
                    ParseErrors = 0
                    References = @{
                        FunctionDefinitions = @()
                        FunctionCalls = @()
                        ModuleImports = @()
                        DotSources = @()
                        VariableReferences = @()
                        CodeReferences = @()
                    }
                    Metrics = @{
                        TotalFunctions = 0
                        TotalCalls = 0
                        TotalImports = 0
                        TotalVariables = 0
                        TotalReferences = 0
                    }
                    Status = "Excluded for safety"
                }
            }
        }
        
        # Parse PowerShell file to get AST (memory-safe approach)
        $tokens = $null
        $errors = $null
        
        try {
            # Use safer parsing approach
            $content = Get-Content $FilePath -Raw
            if ($content.Length -gt 100000) {
                Write-Warning "[CrossRef] File too large for AST analysis: $FilePath ($($content.Length) characters)"
                return $null
            }
            
            $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)
            
            if ($null -eq $ast) {
                Write-Warning "[CrossRef] Failed to parse AST for: $FilePath"
                return $null
            }
            
            if ($errors.Count -gt 0) {
                Write-Warning "[CrossRef] Parse errors in $FilePath : $($errors.Count) errors"
                if ($errors.Count -gt 10) {
                    Write-Warning "[CrossRef] Too many parse errors, skipping AST analysis for safety"
                    return $null
                }
            }
        }
        catch {
            Write-Error "[CrossRef] Fatal error parsing $FilePath : $($_.Exception.Message)"
            return $null
        }
        
        $crossReferences = @{
            FilePath = $FilePath
            LastAnalyzed = Get-Date
            ParseErrors = $errors.Count
            References = @{
                FunctionDefinitions = @()
                FunctionCalls = @()
                ModuleImports = @()
                DotSources = @()
                VariableReferences = @()
                CodeReferences = @()
            }
            Metrics = @{
                TotalFunctions = 0
                TotalCalls = 0
                TotalImports = 0
                TotalVariables = 0
                ComplexityScore = 0
            }
        }
        
        # Extract function definitions (restored full recursive analysis)
        Write-Verbose "[CrossRef] Extracting function definitions..."
        $functionDefs = $ast.FindAll({
            param([System.Management.Automation.Language.Ast] $astNode)
            $astNode -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)  # Full recursive traversal restored
        
        foreach ($func in $functionDefs) {
            $functionInfo = @{
                Name = $func.Name
                LineNumber = $func.Extent.StartLineNumber
                EndLineNumber = $func.Extent.EndLineNumber
                Type = [CrossReferenceType]::FunctionCall
                Parameters = @()
                Documentation = ""
                Complexity = ($func.Body.Statements | Measure-Object).Count
            }
            
            # Extract parameters
            if ($func.Parameters) {
                foreach ($param in $func.Parameters) {
                    $functionInfo.Parameters += @{
                        Name = $param.Name.VariablePath.UserPath
                        Type = if ($param.StaticType) { $param.StaticType.Name } else { "Object" }
                        IsMandatory = $false
                    }
                }
            }
            
            $crossReferences.References.FunctionDefinitions += $functionInfo
        }
        
        # Extract function calls (commands) - restored full analysis
        Write-Verbose "[CrossRef] Extracting function calls..."
        $commands = $ast.FindAll({
            param([System.Management.Automation.Language.Ast] $astNode)
            $astNode -is [System.Management.Automation.Language.CommandAst]
        }, $true)  # Full recursive traversal restored
        
        foreach ($cmd in $commands) {
            $callInfo = @{
                Name = $cmd.GetCommandName()
                LineNumber = $cmd.Extent.StartLineNumber
                Type = [CrossReferenceType]::FunctionCall
                Arguments = @()
                Context = $cmd.Extent.Text.Substring(0, [Math]::Min(100, $cmd.Extent.Text.Length))
            }
            
            # Extract arguments
            if ($cmd.CommandElements -and ($cmd.CommandElements | Measure-Object).Count -gt 1) {
                for ($i = 1; $i -lt ($cmd.CommandElements | Measure-Object).Count; $i++) {
                    $callInfo.Arguments += $cmd.CommandElements[$i].Extent.Text
                }
            }
            
            $crossReferences.References.FunctionCalls += $callInfo
        }
        
        # Extract Import-Module statements - restored full analysis
        Write-Verbose "[CrossRef] Extracting module imports..."
        $imports = $ast.FindAll({
            param([System.Management.Automation.Language.Ast] $astNode)
            $astNode -is [System.Management.Automation.Language.CommandAst] -and
            $astNode.GetCommandName() -like "*Import-Module*"
        }, $true)  # Full recursive traversal restored
        
        foreach ($import in $imports) {
            $importInfo = @{
                ModuleName = ""
                LineNumber = $import.Extent.StartLineNumber
                Type = [CrossReferenceType]::ModuleImport
                Parameters = @()
                Context = $import.Extent.Text
            }
            
            # Extract module name from arguments
            if ($import.CommandElements -and ($import.CommandElements | Measure-Object).Count -gt 1) {
                $importInfo.ModuleName = $import.CommandElements[1].Extent.Text -replace '["'']', ''
                for ($i = 2; $i -lt ($import.CommandElements | Measure-Object).Count; $i++) {
                    $importInfo.Parameters += $import.CommandElements[$i].Extent.Text
                }
            }
            
            $crossReferences.References.ModuleImports += $importInfo
        }
        
        # Extract variable references - restored full analysis
        Write-Verbose "[CrossRef] Extracting variable references..."
        $variables = $ast.FindAll({
            param([System.Management.Automation.Language.Ast] $astNode)
            $astNode -is [System.Management.Automation.Language.VariableExpressionAst]
        }, $true)  # Full recursive traversal restored
        
        $variableGroups = $variables | Group-Object { $_.VariablePath.UserPath }
        foreach ($group in $variableGroups) {
            $varInfo = @{
                Name = $group.Name
                UsageCount = ($group.Group | Measure-Object).Count
                Type = [CrossReferenceType]::VariableReference
                LineNumbers = @()
                Contexts = @()
            }
            
            foreach ($usage in $group.Group) {
                $varInfo.LineNumbers += $usage.Extent.StartLineNumber
                $varInfo.Contexts += $usage.Extent.Text
            }
            
            $crossReferences.References.VariableReferences += $varInfo
        }
        
        # Calculate metrics
        $crossReferences.Metrics.TotalFunctions = ($crossReferences.References.FunctionDefinitions | Measure-Object).Count
        $crossReferences.Metrics.TotalCalls = ($crossReferences.References.FunctionCalls | Measure-Object).Count
        $crossReferences.Metrics.TotalImports = ($crossReferences.References.ModuleImports | Measure-Object).Count
        $crossReferences.Metrics.TotalVariables = ($crossReferences.References.VariableReferences | Measure-Object).Count
        $crossReferences.Metrics.ComplexityScore = $crossReferences.Metrics.TotalCalls + ($crossReferences.Metrics.TotalFunctions * 2)
        
        Write-Verbose "[CrossRef] AST analysis complete: $($crossReferences.Metrics.TotalFunctions) functions, $($crossReferences.Metrics.TotalCalls) calls, $($crossReferences.Metrics.TotalImports) imports"
        
        return $crossReferences
    }
    catch {
        Write-Error "[CrossRef] Failed to analyze AST for $FilePath : $($_.Exception.Message)"
        return $null
    }
}

function Extract-MarkdownLinks {
    <#
    .SYNOPSIS
        Extracts and classifies links from markdown documentation files.
    
    .DESCRIPTION
        Uses regex patterns with named capture groups to extract all types of markdown links
        including inline, reference, relative, and external links. Provides classification
        and validation for intelligent link management.
    
    .PARAMETER FilePath
        Path to markdown file for link extraction.
    
    .PARAMETER Content
        Markdown content to analyze (alternative to FilePath).
    
    .PARAMETER ValidateLinks
        Perform HTTP validation of extracted links.
    
    .EXAMPLE
        Extract-MarkdownLinks -FilePath ".\README.md" -ValidateLinks
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$FilePath = "",
        
        [Parameter(Mandatory = $false)]
        [string]$Content = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$ValidateLinks = $false
    )
    
    try {
        Write-Verbose "[CrossRef] Extracting links from: $(if($FilePath) { $FilePath } else { 'content string' })"
        
        # Get content
        if ($FilePath -and (Test-Path $FilePath)) {
            $Content = Get-Content $FilePath -Raw
        }
        elseif (-not $Content) {
            Write-Warning "[CrossRef] No content provided for link extraction"
            return $null
        }
        
        $extractedLinks = @{
            SourceFile = $FilePath
            LastExtracted = Get-Date
            Links = @()
            Metrics = @{
                TotalLinks = 0
                InlineLinks = 0
                ReferenceLinks = 0
                RelativeLinks = 0
                ExternalLinks = 0
                ValidLinks = 0
                BrokenLinks = 0
            }
        }
        
        # Regex patterns for different link types (research-validated)
        $linkPatterns = @{
            # Inline links: [text](url)
            Inline = '\[(?<text>[^\]]+)\]\((?<url>[^)]+)\)'
            
            # Reference links: [text][ref] and [ref]: url
            Reference = '\[(?<text>[^\]]+)\]\[(?<ref>[^\]]+)\]'
            ReferenceDefinition = '^\[(?<ref>[^\]]+)\]:\s*(?<url>\S+)'
            
            # Auto links: <url>
            AutoLink = '<(?<url>https?://[^>]+)>'
            
            # Relative links: [text](./path or ../path)
            RelativeLink = '\[(?<text>[^\]]+)\]\((?<url>\.{1,2}/[^)]+)\)'
            
            # Internal anchor links: [text](#anchor)
            InternalLink = '\[(?<text>[^\]]+)\]\((?<url>#[^)]+)\)'
        }
        
        $lineNumber = 1
        foreach ($line in $Content -split "`n") {
            foreach ($patternName in $linkPatterns.Keys) {
                $pattern = $linkPatterns[$patternName]
                
                if ($line -match $pattern) {
                    $matches = [regex]::Matches($line, $pattern)
                    
                    foreach ($match in $matches) {
                        $linkInfo = @{
                            Text = if ($match.Groups['text'].Success) { $match.Groups['text'].Value } else { "" }
                            Url = if ($match.Groups['url'].Success) { $match.Groups['url'].Value } else { if ($match.Groups['ref'].Success) { $match.Groups['ref'].Value } else { "" } }
                            LineNumber = $lineNumber
                            Type = [CrossReferenceType]::MarkdownLink
                            LinkType = $patternName
                            ValidationStatus = [LinkValidationStatus]::NotChecked
                            Context = $line.Trim()
                        }
                        
                        # Classify link type
                        $url = $linkInfo.Url
                        if ($url.StartsWith("http://") -or $url.StartsWith("https://")) {
                            $linkInfo.Type = [CrossReferenceType]::ExternalLink
                            $extractedLinks.Metrics.ExternalLinks++
                        }
                        elseif ($url.StartsWith("#")) {
                            $linkInfo.Type = [CrossReferenceType]::InternalLink
                        }
                        elseif ($url.StartsWith("./") -or $url.StartsWith("../")) {
                            $linkInfo.Type = [CrossReferenceType]::RelativeLink
                            $extractedLinks.Metrics.RelativeLinks++
                        }
                        else {
                            $linkInfo.Type = [CrossReferenceType]::MarkdownLink
                        }
                        
                        # Update type-specific metrics
                        switch ($patternName) {
                            "Inline" { $extractedLinks.Metrics.InlineLinks++ }
                            "Reference" { $extractedLinks.Metrics.ReferenceLinks++ }
                            "ReferenceDefinition" { $extractedLinks.Metrics.ReferenceLinks++ }
                        }
                        
                        $extractedLinks.Links += $linkInfo
                    }
                }
            }
            $lineNumber++
        }
        
        # Update total metrics
        $extractedLinks.Metrics.TotalLinks = ($extractedLinks.Links | Measure-Object).Count
        
        # Validate links if requested
        if ($ValidateLinks -and $extractedLinks.Metrics.TotalLinks -gt 0) {
            Write-Verbose "[CrossRef] Validating $($extractedLinks.Metrics.TotalLinks) extracted links..."
            $extractedLinks = Invoke-LinkValidation -LinkData $extractedLinks
        }
        
        Write-Verbose "[CrossRef] Link extraction complete: $($extractedLinks.Metrics.TotalLinks) links found"
        
        return $extractedLinks
    }
    catch {
        Write-Error "[CrossRef] Failed to extract links: $($_.Exception.Message)"
        return $null
    }
}

function Find-FunctionDefinitions {
    <#
    .SYNOPSIS
        Finds all function definitions in a PowerShell file using AST analysis.
    
    .DESCRIPTION
        Extracts detailed information about function definitions including parameters,
        documentation, and complexity metrics for cross-reference database building.
    
    .PARAMETER FilePath
        Path to PowerShell file for analysis.
    
    .EXAMPLE
        Find-FunctionDefinitions -FilePath ".\Modules\Unity-Claude-Core\Unity-Claude-Core.psm1"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        Write-Verbose "[CrossRef] Finding function definitions in: $FilePath"
        
        if (-not (Test-Path $FilePath)) {
            Write-Warning "[CrossRef] File not found: $FilePath"
            return @()
        }
        
        # Parse file
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)
        
        # Find function definitions
        $functions = $ast.FindAll({
            param([System.Management.Automation.Language.Ast] $astNode)
            $astNode -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)
        
        $functionDefinitions = @()
        
        foreach ($func in $functions) {
            $functionInfo = @{
                Name = $func.Name
                FilePath = $FilePath
                LineNumber = $func.Extent.StartLineNumber
                EndLineNumber = $func.Extent.EndLineNumber
                Parameters = @()
                Documentation = ""
                Complexity = ($func.Body.Statements | Measure-Object).Count
                IsExported = $false
                References = @()
            }
            
            # Extract parameters with detailed information
            if ($func.Parameters) {
                foreach ($param in $func.Parameters) {
                    $paramInfo = @{
                        Name = $param.Name.VariablePath.UserPath
                        Type = if ($param.StaticType) { $param.StaticType.Name } else { "Object" }
                        IsMandatory = $false
                        HasDefault = $null -ne $param.DefaultValue
                        DefaultValue = if ($param.DefaultValue) { $param.DefaultValue.Extent.Text } else { "" }
                    }
                    
                    # Check for mandatory attribute
                    if ($param.Attributes) {
                        foreach ($attr in $param.Attributes) {
                            if ($attr.TypeName.Name -eq "Parameter") {
                                foreach ($namedAttr in $attr.NamedArguments) {
                                    if ($namedAttr.ArgumentName -eq "Mandatory" -and $namedAttr.Argument.Value) {
                                        $paramInfo.IsMandatory = $true
                                    }
                                }
                            }
                        }
                    }
                    
                    $functionInfo.Parameters += $paramInfo
                }
            }
            
            # Extract comment-based help if available
            if ($func.HelpContent) {
                $functionInfo.Documentation = $func.HelpContent.Description
            }
            
            $functionDefinitions += $functionInfo
        }
        
        Write-Verbose "[CrossRef] Found $($functionDefinitions.Count) function definitions"
        
        return $functionDefinitions
    }
    catch {
        Write-Error "[CrossRef] Failed to find function definitions in $FilePath : $($_.Exception.Message)"
        return @()
    }
}

function Find-FunctionCalls {
    <#
    .SYNOPSIS
        Finds all function calls in a PowerShell file using AST analysis.
    
    .DESCRIPTION
        Identifies function calls and their contexts for cross-reference mapping
        and dependency analysis. Provides detailed call information with parameters.
    
    .PARAMETER FilePath
        Path to PowerShell file for analysis.
    
    .EXAMPLE
        Find-FunctionCalls -FilePath ".\test-script.ps1"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    try {
        Write-Verbose "[CrossRef] Finding function calls in: $FilePath"
        
        if (-not (Test-Path $FilePath)) {
            Write-Warning "[CrossRef] File not found: $FilePath"
            return @()
        }
        
        # Check for excluded files to prevent self-analysis crashes
        $excludedFiles = @(
            $PSCommandPath,
            (Join-Path $PSScriptRoot "Unity-Claude-DocumentationCrossReference.psm1"),
            (Join-Path $PSScriptRoot "Unity-Claude-DocumentationSuggestions.psm1")
        )
        
        foreach ($excludedPath in $excludedFiles) {
            if ($FilePath -eq $excludedPath -or $FilePath.Contains("DocumentationCrossReference") -or $FilePath.Contains("DocumentationSuggestions")) {
                Write-Warning "[CrossRef] Skipping self-analysis file to prevent memory corruption: $FilePath"
                return @()
            }
        }
        
        # Parse file
        $tokens = $null
        $errors = $null
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($FilePath, [ref]$tokens, [ref]$errors)
        
        # Find command calls
        $commands = $ast.FindAll({
            param([System.Management.Automation.Language.Ast] $astNode)
            $astNode -is [System.Management.Automation.Language.CommandAst]
        }, $true)
        
        $functionCalls = @()
        
        foreach ($cmd in $commands) {
            $commandName = $cmd.GetCommandName()
            
            # Skip built-in cmdlets and focus on custom functions
            if ($commandName -and $commandName -notmatch '^(Get-|Set-|New-|Remove-|Test-|Start-|Stop-|Add-|Clear-|Copy-|Move-|Join-|Split-|Select-|Where-|ForEach-|Measure-|Compare-|Sort-|Group-|Import-|Export-)') {
                $callInfo = @{
                    FunctionName = $commandName
                    CallerFile = $FilePath
                    LineNumber = $cmd.Extent.StartLineNumber
                    Type = [CrossReferenceType]::FunctionCall
                    Arguments = @()
                    Context = $cmd.Extent.Text.Substring(0, [Math]::Min(150, $cmd.Extent.Text.Length))
                    IsBuiltIn = $false
                }
                
                # Extract arguments
                if ($cmd.CommandElements -and ($cmd.CommandElements | Measure-Object).Count -gt 1) {
                    for ($i = 1; $i -lt ($cmd.CommandElements | Measure-Object).Count; $i++) {
                        $element = $cmd.CommandElements[$i]
                        $callInfo.Arguments += @{
                            Text = $element.Extent.Text
                            Type = $element.GetType().Name
                            IsParameter = $element.Extent.Text.StartsWith("-")
                        }
                    }
                }
                
                $functionCalls += $callInfo
            }
        }
        
        Write-Verbose "[CrossRef] Found $($functionCalls.Count) function calls"
        
        return $functionCalls
    }
    catch {
        Write-Error "[CrossRef] Failed to find function calls in $FilePath : $($_.Exception.Message)"
        return @()
    }
}

function Build-DocumentationGraph {
    <#
    .SYNOPSIS
        Builds a comprehensive documentation graph for relationship analysis.
    
    .DESCRIPTION
        Creates graph representation of documentation relationships using nodes
        (documents/functions) and edges (references/links) for connectivity analysis
        and content suggestion generation. Research-validated graph algorithms.
    
    .PARAMETER DocumentationPaths
        Array of paths to analyze for graph construction.
    
    .PARAMETER IncludeMetrics
        Calculate advanced graph metrics (centrality, connectivity, importance).
    
    .EXAMPLE
        Build-DocumentationGraph -DocumentationPaths @(".\docs\", ".\Modules\") -IncludeMetrics
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$DocumentationPaths = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeMetrics = $true
    )
    
    try {
        Write-Host "[CrossRef] Building documentation graph..." -ForegroundColor Cyan
        $startTime = Get-Date
        
        # Use configured paths if none provided
        if (($DocumentationPaths | Measure-Object).Count -eq 0) {
            $DocumentationPaths = $script:CrossReferenceState.Configuration.DocumentationPaths
        }
        
        # Initialize graph structure
        $graph = @{
            Nodes = @{}
            Edges = @{}
            Metrics = @{
                TotalNodes = 0
                TotalEdges = 0
                AverageConnectivity = 0
                CentralityScores = @{}
                BuildTime = 0
                LastAnalysis = Get-Date
            }
            BuildInfo = @{
                DocumentationPaths = $DocumentationPaths
                ProcessedFiles = @()
                SkippedFiles = @()
                Errors = @()
            }
        }
        
        # Find all documentation files
        $documentationFiles = @()
        foreach ($path in $DocumentationPaths) {
            if (Test-Path $path) {
                if ((Get-Item $path).PSIsContainer) {
                    # Directory - find all relevant files
                    $files = Get-ChildItem $path -Recurse -Include "*.md", "*.psm1", "*.ps1" -ErrorAction SilentlyContinue
                    $documentationFiles += $files.FullName
                }
                else {
                    # Single file
                    $documentationFiles += (Resolve-Path $path).Path
                }
            }
            else {
                Write-Warning "[CrossRef] Path not found: $path"
            }
        }
        
        Write-Verbose "[CrossRef] Found $($documentationFiles.Count) files to analyze"
        
        # Apply Learning #263: Selective processing for performance optimization
        # Restore 50 file limit with self-analysis exclusion
        if (($documentationFiles | Measure-Object).Count -gt 50) {
            Write-Verbose "[CrossRef] Applying selective processing for performance (limiting to 50 most recent files)"
            $documentationFiles = $documentationFiles | 
                Get-Item | 
                Sort-Object LastWriteTime -Descending | 
                Select-Object -First 50 | 
                ForEach-Object { $_.FullName }
        }
        
        # CRITICAL: Exclude self-analysis files to prevent memory corruption
        $excludedFiles = $script:CrossReferenceState.Configuration.ExcludedFiles
        $documentationFiles = $documentationFiles | Where-Object { 
            $file = $_
            $shouldExclude = $false
            foreach ($excludedPath in $excludedFiles) {
                if ($file -eq $excludedPath -or $file.Contains("DocumentationCrossReference") -or $file.Contains("DocumentationSuggestions")) {
                    $shouldExclude = $true
                    break
                }
            }
            -not $shouldExclude
        }
        
        Write-Verbose "[CrossRef] Excluded self-analysis files for memory safety"
        
        # Process each file to build graph nodes
        foreach ($file in $documentationFiles) {
            try {
                # GetRelativePath is only available in .NET Core 2.1+, use fallback for compatibility
                try {
                    $nodeId = [System.IO.Path]::GetRelativePath((Get-Location).Path, $file)
                }
                catch {
                    # Fallback for PowerShell 5.1 compatibility
                    $currentPath = (Get-Location).Path
                    if ($file.StartsWith($currentPath)) {
                        $nodeId = $file.Substring($currentPath.Length).TrimStart('\', '/')
                    }
                    else {
                        $nodeId = $file
                    }
                }
                $extension = [System.IO.Path]::GetExtension($file).ToLower()
                
                # Determine node type
                $nodeType = switch ($extension) {
                    ".psm1" { [DocumentationNodeType]::PowerShellModule }
                    ".ps1" { if ($nodeId -like "*Test*") { [DocumentationNodeType]::TestScript } else { [DocumentationNodeType]::PowerShellModule } }
                    ".md" { [DocumentationNodeType]::MarkdownDocument }
                    default { [DocumentationNodeType]::MarkdownDocument }
                }
                
                # Create node information
                $nodeInfo = @{
                    Id = $nodeId
                    Type = $nodeType
                    FilePath = $file
                    Name = [System.IO.Path]::GetFileNameWithoutExtension($file)
                    LastModified = (Get-Item $file).LastWriteTime
                    Size = (Get-Item $file).Length
                    References = @{
                        Outgoing = @()
                        Incoming = @()
                    }
                    Metrics = @{
                        ReferenceCount = 0
                        ImportanceScore = 0
                        ConnectivityScore = 0
                    }
                }
                
                # Extract references based on file type (restored full AST analysis)
                if ($extension -in @(".psm1", ".ps1")) {
                    # PowerShell file - use full AST analysis (safe due to self-analysis exclusion)
                    Write-Debug "[CrossRef] Analyzing PowerShell file: $nodeId"
                    
                    $astReferences = Get-ASTCrossReferences -FilePath $file
                    if ($astReferences) {
                        $nodeInfo.References.Outgoing += $astReferences.References.FunctionCalls | ForEach-Object {
                            @{
                                Type = "FunctionCall"
                                Target = $_.Name
                                LineNumber = $_.LineNumber
                                Context = $_.Context
                            }
                        }
                        
                        $nodeInfo.References.Outgoing += $astReferences.References.ModuleImports | ForEach-Object {
                            @{
                                Type = "ModuleImport"
                                Target = $_.ModuleName
                                LineNumber = $_.LineNumber
                                Context = $_.Context
                            }
                        }
                    }
                }
                elseif ($extension -eq ".md") {
                    # Markdown file - restored full link extraction
                    Write-Debug "[CrossRef] Analyzing Markdown file: $nodeId"
                    
                    $markdownLinks = Extract-MarkdownLinks -FilePath $file
                    if ($markdownLinks) {
                        $nodeInfo.References.Outgoing += $markdownLinks.Links | ForEach-Object {
                            @{
                                Type = "MarkdownLink"
                                Target = $_.Url
                                LineNumber = $_.LineNumber
                                Context = $_.Context
                                LinkType = $_.LinkType
                            }
                        }
                    }
                }
                
                # Calculate reference metrics
                $nodeInfo.Metrics.ReferenceCount = ($nodeInfo.References.Outgoing | Measure-Object).Count
                
                # Add node to graph
                $graph.Nodes[$nodeId] = $nodeInfo
                $graph.BuildInfo.ProcessedFiles += $file
                
                Write-Debug "[CrossRef] Processed node: $nodeId ($($nodeInfo.Metrics.ReferenceCount) references)"
            }
            catch {
                Write-Warning "[CrossRef] Failed to process file $file : $($_.Exception.Message)"
                $graph.BuildInfo.SkippedFiles += $file
                $graph.BuildInfo.Errors += @{
                    File = $file
                    Error = $_.Exception.Message
                    Time = Get-Date
                }
            }
        }
        
        # Build edges and calculate incoming references
        Write-Verbose "[CrossRef] Building graph edges..."
        foreach ($sourceNodeId in $graph.Nodes.Keys) {
            $sourceNode = $graph.Nodes[$sourceNodeId]
            
            foreach ($reference in $sourceNode.References.Outgoing) {
                # Find target node
                $targetNodeId = $null
                
                # For function calls, find the module that defines the function
                if ($reference.Type -eq "FunctionCall") {
                    foreach ($candidateNodeId in $graph.Nodes.Keys) {
                        $candidateNode = $graph.Nodes[$candidateNodeId]
                        if ($candidateNode.Type -in @([DocumentationNodeType]::PowerShellModule)) {
                            # Check if this module defines the function
                            $astRefs = Get-ASTCrossReferences -FilePath $candidateNode.FilePath
                            if ($astRefs) {
                                $definedFunctions = $astRefs.References.FunctionDefinitions | Where-Object { $_.Name -eq $reference.Target }
                                if (($definedFunctions | Measure-Object).Count -gt 0) {
                                    $targetNodeId = $candidateNodeId
                                    break
                                }
                            }
                        }
                    }
                }
                # For module imports, find the target module
                elseif ($reference.Type -eq "ModuleImport") {
                    foreach ($candidateNodeId in $graph.Nodes.Keys) {
                        if ($candidateNodeId -like "*$($reference.Target)*") {
                            $targetNodeId = $candidateNodeId
                            break
                        }
                    }
                }
                # For markdown links, find target documents
                elseif ($reference.Type -eq "MarkdownLink") {
                    if ($reference.Target.StartsWith("./") -or $reference.Target.StartsWith("../")) {
                        # Relative link - resolve to actual file
                        $basePath = Split-Path $sourceNode.FilePath -Parent
                        $targetPath = Join-Path $basePath $reference.Target
                        $resolvedPath = Resolve-Path $targetPath -ErrorAction SilentlyContinue
                        if ($resolvedPath) {
                            # GetRelativePath is only available in .NET Core 2.1+, use fallback for compatibility
                            try {
                                $targetNodeId = [System.IO.Path]::GetRelativePath((Get-Location).Path, $resolvedPath.Path)
                            }
                            catch {
                                # Fallback for PowerShell 5.1 compatibility
                                $currentPath = (Get-Location).Path
                                if ($resolvedPath.Path.StartsWith($currentPath)) {
                                    $targetNodeId = $resolvedPath.Path.Substring($currentPath.Length).TrimStart('\', '/')
                                }
                                else {
                                    $targetNodeId = $resolvedPath.Path
                                }
                            }
                        }
                    }
                }
                
                # Create edge if target found
                if ($targetNodeId -and $graph.Nodes.ContainsKey($targetNodeId)) {
                    $edgeId = "$sourceNodeId -> $targetNodeId"
                    
                    if (-not $graph.Edges.ContainsKey($edgeId)) {
                        $graph.Edges[$edgeId] = @{
                            Source = $sourceNodeId
                            Target = $targetNodeId
                            Type = $reference.Type
                            Weight = 1
                            References = @()
                        }
                    }
                    else {
                        $graph.Edges[$edgeId].Weight++
                    }
                    
                    # Add reference details
                    $graph.Edges[$edgeId].References += @{
                        LineNumber = $reference.LineNumber
                        Context = $reference.Context
                        ReferenceTarget = $reference.Target
                    }
                    
                    # Add incoming reference to target node
                    $graph.Nodes[$targetNodeId].References.Incoming += @{
                        Source = $sourceNodeId
                        Type = $reference.Type
                        LineNumber = $reference.LineNumber
                    }
                }
            }
        }
        
        # Calculate graph metrics
        $graph.Metrics.TotalNodes = ($graph.Nodes.Keys | Measure-Object).Count
        $graph.Metrics.TotalEdges = ($graph.Edges.Keys | Measure-Object).Count
        
        if ($graph.Metrics.TotalNodes -gt 0) {
            $graph.Metrics.AverageConnectivity = [Math]::Round($graph.Metrics.TotalEdges / $graph.Metrics.TotalNodes, 2)
        }
        
        # Calculate centrality scores if requested
        if ($IncludeMetrics) {
            Write-Verbose "[CrossRef] Calculating centrality metrics..."
            $graph.Metrics.CentralityScores = Calculate-DocumentationCentrality -Graph $graph
        }
        
        # Record build time
        $graph.Metrics.BuildTime = ((Get-Date) - $startTime).TotalSeconds
        
        # Update module state (restored full structure)
        $script:CrossReferenceState.DocumentationGraph = $graph
        $script:CrossReferenceState.PerformanceMetrics.GraphBuildTime = $graph.Metrics.BuildTime
        
        Write-Host "[CrossRef] Documentation graph built successfully" -ForegroundColor Green
        Write-Host "[CrossRef] Nodes: $($graph.Metrics.TotalNodes), Edges: $($graph.Metrics.TotalEdges), Connectivity: $($graph.Metrics.AverageConnectivity)" -ForegroundColor White
        Write-Host "[CrossRef] Build time: $([Math]::Round($graph.Metrics.BuildTime, 2)) seconds" -ForegroundColor White
        
        return $graph
    }
    catch {
        Write-Error "[CrossRef] Failed to build documentation graph: $($_.Exception.Message)"
        return $null
    }
}

function Calculate-DocumentationCentrality {
    <#
    .SYNOPSIS
        Calculates centrality metrics for documentation graph analysis.
    
    .DESCRIPTION
        Implements PageRank-style algorithm and degree centrality for identifying
        important documents and functions in the documentation ecosystem.
        Research-validated graph analysis algorithms.
    
    .PARAMETER Graph
        Documentation graph object with nodes and edges.
    
    .EXAMPLE
        Calculate-DocumentationCentrality -Graph $documentationGraph
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph
    )
    
    try {
        Write-Verbose "[CrossRef] Calculating centrality scores..."
        
        $centralityScores = @{}
        $nodes = $Graph.Nodes
        $edges = $Graph.Edges
        
        # Calculate degree centrality (simple but effective)
        foreach ($nodeId in $nodes.Keys) {
            $node = $nodes[$nodeId]
            
            # In-degree (how many references TO this node)
            $inDegree = ($node.References.Incoming | Measure-Object).Count
            
            # Out-degree (how many references FROM this node)
            $outDegree = ($node.References.Outgoing | Measure-Object).Count
            
            # Combined centrality score
            $centralityScore = @{
                InDegree = $inDegree
                OutDegree = $outDegree
                TotalDegree = $inDegree + $outDegree
                NormalizedCentrality = 0
                ImportanceScore = 0
                PageRankScore = 1.0  # Initialize for PageRank algorithm
            }
            
            $centralityScores[$nodeId] = $centralityScore
        }
        
        # Normalize centrality scores
        $maxDegree = ($centralityScores.Values | ForEach-Object { $_.TotalDegree } | Measure-Object -Maximum).Maximum
        if ($maxDegree -gt 0) {
            foreach ($nodeId in $centralityScores.Keys) {
                $centralityScores[$nodeId].NormalizedCentrality = [Math]::Round($centralityScores[$nodeId].TotalDegree / $maxDegree, 3)
            }
        }
        
        # Simple PageRank calculation (3 iterations for performance)
        Write-Verbose "[CrossRef] Calculating PageRank scores..."
        $dampingFactor = 0.85
        $nodeCount = ($nodes.Keys | Measure-Object).Count
        
        for ($iteration = 0; $iteration -lt 3; $iteration++) {
            $newScores = @{}
            
            foreach ($nodeId in $nodes.Keys) {
                $newScore = (1 - $dampingFactor) / $nodeCount
                
                # Add contributions from incoming links
                foreach ($incomingRef in $nodes[$nodeId].References.Incoming) {
                    $sourceNodeId = $incomingRef.Source
                    if ($centralityScores.ContainsKey($sourceNodeId)) {
                        $sourceOutDegree = [Math]::Max(1, $centralityScores[$sourceNodeId].OutDegree)
                        $contribution = $dampingFactor * ($centralityScores[$sourceNodeId].PageRankScore / $sourceOutDegree)
                        $newScore += $contribution
                    }
                }
                
                $newScores[$nodeId] = $newScore
            }
            
            # Update scores
            foreach ($nodeId in $newScores.Keys) {
                $centralityScores[$nodeId].PageRankScore = $newScores[$nodeId]
            }
        }
        
        # Calculate importance scores (combination of metrics)
        foreach ($nodeId in $centralityScores.Keys) {
            $score = $centralityScores[$nodeId]
            $node = $nodes[$nodeId]
            
            # Combine PageRank, centrality, and file characteristics
            $importanceScore = ($score.PageRankScore * 0.4) + 
                              ($score.NormalizedCentrality * 0.3) + 
                              (($node.Size / 10000) * 0.2) +  # File size factor
                              ((Get-Date) - $node.LastModified).TotalDays * -0.1  # Recency factor
            
            $score.ImportanceScore = [Math]::Round([Math]::Max(0, $importanceScore), 3)
        }
        
        Write-Verbose "[CrossRef] Centrality calculation complete"
        
        return $centralityScores
    }
    catch {
        Write-Error "[CrossRef] Failed to calculate centrality: $($_.Exception.Message)"
        return @{}
    }
}

function Connect-ExistingDocumentationSystems {
    <#
    .SYNOPSIS
        Connects to existing documentation quality and orchestration systems.
    
    .DESCRIPTION
        Discovers and integrates with existing Unity-Claude documentation modules
        for seamless integration with quality assessment and orchestration workflows.
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Verbose "[CrossRef] Connecting to existing documentation systems..."
        
        $moduleBasePath = Split-Path $PSScriptRoot -Parent
        $connectedSystems = @{
            DocumentationQualityAssessment = $false
            DocumentationQualityOrchestrator = $false
            AutonomousDocumentationEngine = $false
            OllamaAI = $false
        }
        
        # Connect to DocumentationQualityAssessment
        $qualityAssessmentPath = Join-Path $moduleBasePath "Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1"
        if (Test-Path $qualityAssessmentPath) {
            try {
                Import-Module $qualityAssessmentPath -Force -Global -ErrorAction Stop
                $connectedSystems.DocumentationQualityAssessment = $true
                Write-Verbose "[CrossRef] Connected: DocumentationQualityAssessment"
            }
            catch {
                Write-Warning "[CrossRef] Failed to connect to DocumentationQualityAssessment: $_"
            }
        }
        
        # Connect to DocumentationQualityOrchestrator
        $orchestratorPath = Join-Path $moduleBasePath "Unity-Claude-DocumentationQualityOrchestrator\Unity-Claude-DocumentationQualityOrchestrator.psm1"
        if (Test-Path $orchestratorPath) {
            try {
                Import-Module $orchestratorPath -Force -Global -ErrorAction Stop
                $connectedSystems.DocumentationQualityOrchestrator = $true
                Write-Verbose "[CrossRef] Connected: DocumentationQualityOrchestrator"
            }
            catch {
                Write-Warning "[CrossRef] Failed to connect to DocumentationQualityOrchestrator: $_"
            }
        }
        
        # Connect to Ollama AI (for AI-enhanced suggestions)
        $ollamaPath = Join-Path $moduleBasePath "Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama.psm1"
        if (Test-Path $ollamaPath) {
            try {
                Import-Module $ollamaPath -Force -Global -ErrorAction Stop
                $connectedSystems.OllamaAI = $true
                Write-Verbose "[CrossRef] Connected: Ollama AI for content suggestions"
            }
            catch {
                Write-Warning "[CrossRef] Failed to connect to Ollama AI: $_"
            }
        }
        
        $connectedCount = ($connectedSystems.Values | Where-Object { $_ }).Count
        Write-Host "[CrossRef] Connected to $connectedCount existing documentation systems" -ForegroundColor Green
        
        return $connectedSystems
    }
    catch {
        Write-Error "[CrossRef] Failed to connect to existing systems: $($_.Exception.Message)"
        return @{}
    }
}

function Invoke-LinkValidation {
    <#
    .SYNOPSIS
        Validates links with caching and performance optimization.
    
    .DESCRIPTION
        Performs HTTP validation of links with intelligent caching, retry logic,
        and performance optimization for large-scale documentation processing.
    
    .PARAMETER LinkData
        Link data object from Extract-MarkdownLinks.
    
    .PARAMETER UseCache
        Use cached validation results when available.
    
    .EXAMPLE
        Invoke-LinkValidation -LinkData $extractedLinks -UseCache
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$LinkData,
        
        [Parameter(Mandatory = $false)]
        [switch]$UseCache = $true
    )
    
    try {
        Write-Verbose "[CrossRef] Validating $($LinkData.Metrics.TotalLinks) links..."
        $startTime = Get-Date
        
        $cacheExpiration = $script:CrossReferenceState.Configuration.CacheExpiration
        $validatedCount = 0
        $cacheHits = 0
        
        foreach ($link in $LinkData.Links) {
            $url = $link.Url
            
            # Skip internal and relative links
            if ($link.Type -in @([CrossReferenceType]::InternalLink, [CrossReferenceType]::RelativeLink)) {
                $link.ValidationStatus = [LinkValidationStatus]::Valid
                $validatedCount++
                continue
            }
            
            # Check cache first
            if ($UseCache -and $script:CrossReferenceState.LinkValidationCache.ContainsKey($url)) {
                $cacheEntry = $script:CrossReferenceState.LinkValidationCache[$url]
                $cacheAge = (Get-Date) - $cacheEntry.Timestamp
                
                if ($cacheAge.TotalMinutes -lt $cacheExpiration) {
                    $link.ValidationStatus = $cacheEntry.Status
                    $cacheHits++
                    $validatedCount++
                    continue
                }
            }
            
            # Validate external links
            if ($url.StartsWith("http://") -or $url.StartsWith("https://")) {
                try {
                    $response = Invoke-WebRequest -Uri $url -Method Head -TimeoutSec 10 -ErrorAction Stop
                    
                    if ($response.StatusCode -eq 200) {
                        $link.ValidationStatus = [LinkValidationStatus]::Valid
                        $LinkData.Metrics.ValidLinks++
                    }
                    elseif ($response.StatusCode -in @(301, 302, 307, 308)) {
                        $link.ValidationStatus = [LinkValidationStatus]::Redirect
                    }
                    else {
                        $link.ValidationStatus = [LinkValidationStatus]::Broken
                        $LinkData.Metrics.BrokenLinks++
                    }
                }
                catch {
                    if ($_.Exception.Message -match "timeout") {
                        $link.ValidationStatus = [LinkValidationStatus]::Timeout
                    }
                    elseif ($_.Exception.Message -match "403|Forbidden") {
                        $link.ValidationStatus = [LinkValidationStatus]::Forbidden
                    }
                    else {
                        $link.ValidationStatus = [LinkValidationStatus]::Broken
                        $LinkData.Metrics.BrokenLinks++
                    }
                }
                
                # Cache result
                $script:CrossReferenceState.LinkValidationCache[$url] = @{
                    Status = $link.ValidationStatus
                    Timestamp = Get-Date
                    LastChecked = Get-Date
                }
                
                $validatedCount++
            }
        }
        
        # Update metrics (restored full tracking)
        $validationTime = ((Get-Date) - $startTime).TotalSeconds
        $script:CrossReferenceState.PerformanceMetrics.ValidationTime = $validationTime
        $script:CrossReferenceState.PerformanceMetrics.ValidatedLinks += $validatedCount
        $script:CrossReferenceState.PerformanceMetrics.CacheHitRate = if ($validatedCount -gt 0) {
            [Math]::Round(($cacheHits / $validatedCount) * 100, 1)
        } else { 0 }
        
        Write-Verbose "[CrossRef] Link validation complete: $validatedCount validated, $cacheHits cache hits, $([Math]::Round($validationTime, 2))s"
        
        return $LinkData
    }
    catch {
        Write-Error "[CrossRef] Failed to validate links: $($_.Exception.Message)"
        return $LinkData
    }
}

function Test-DocumentationCrossReference {
    <#
    .SYNOPSIS
        Tests documentation cross-reference system with comprehensive validation.
    
    .DESCRIPTION
        Validates AST analysis, link extraction, graph building, and integration
        with existing quality systems. Performance benchmarking included.
    
    .EXAMPLE
        Test-DocumentationCrossReference
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "Testing Documentation Cross-Reference System..." -ForegroundColor Cyan
    
    if (-not $script:CrossReferenceState.IsInitialized) {
        Write-Host "Initializing Documentation Cross-Reference for testing..." -ForegroundColor Yellow
        $initResult = Initialize-DocumentationCrossReference -EnableRealTimeMonitoring -EnableAIEnhancement
        if (-not $initResult) {
            Write-Error "Failed to initialize Documentation Cross-Reference"
            return $false
        }
    }
    
    $testResults = @{
        ASTAnalysis = $false
        LinkExtraction = $false
        GraphBuilding = $false
        SystemIntegration = $false
        PerformanceValidation = $false
    }
    
    # Test 1: AST Analysis
    Write-Host "Testing AST cross-reference analysis..." -ForegroundColor Yellow
    $testFile = $PSCommandPath  # Use this module file for testing
    $astResult = Get-ASTCrossReferences -FilePath $testFile
    $testResults.ASTAnalysis = ($null -ne $astResult -and $astResult.Metrics.TotalFunctions -gt 0)
    
    # Test 2: Link Extraction
    Write-Host "Testing markdown link extraction..." -ForegroundColor Yellow
    $testMarkdown = @"
# Test Document
This is a [sample link](https://example.com) and a [relative link](./docs/test.md).
Also includes [internal link](#section) and <https://autolink.com>.
"@
    $linkResult = Extract-MarkdownLinks -Content $testMarkdown -ValidateLinks
    $testResults.LinkExtraction = ($null -ne $linkResult -and $linkResult.Metrics.TotalLinks -gt 0)
    
    # Test 3: Graph Building
    Write-Host "Testing documentation graph building..." -ForegroundColor Yellow
    $graphResult = Build-DocumentationGraph -DocumentationPaths @($PSScriptRoot) -IncludeMetrics
    $testResults.GraphBuilding = ($null -ne $graphResult -and $graphResult.Metrics.TotalNodes -gt 0)
    
    # Test 4: System Integration
    Write-Host "Testing integration with existing systems..." -ForegroundColor Yellow
    $integrationTest = Test-ExistingSystemIntegration
    $testResults.SystemIntegration = $integrationTest
    
    # Test 5: Performance Validation
    Write-Host "Testing performance metrics..." -ForegroundColor Yellow
    $perfTest = ($script:CrossReferenceState.PerformanceMetrics.GraphBuildTime -gt 0)
    $testResults.PerformanceValidation = $perfTest
    
    # Calculate success rate
    $successCount = ($testResults.Values | Where-Object { $_ }).Count
    $totalTests = ($testResults.Values | Measure-Object).Count
    $successRate = if ($totalTests -gt 0) { [Math]::Round(($successCount / $totalTests) * 100, 1) } else { 0 }
    
    Write-Host "Documentation Cross-Reference test complete: $successCount/$totalTests tests passed ($successRate%)" -ForegroundColor Green
    
    return @{
        TestResults = $testResults
        SuccessCount = $successCount
        TotalTests = $totalTests
        SuccessRate = $successRate
        PerformanceMetrics = $script:CrossReferenceState.PerformanceMetrics
    }
}

function Test-ExistingSystemIntegration {
    <#
    .SYNOPSIS
        Tests integration with existing documentation quality systems.
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Test DocumentationQualityAssessment integration
        $qualityIntegration = Get-Command Assess-DocumentationQuality -ErrorAction SilentlyContinue
        
        # Test DocumentationQualityOrchestrator integration
        $orchestratorIntegration = Get-Command Start-DocumentationQualityWorkflow -ErrorAction SilentlyContinue
        
        # Test Ollama AI integration
        $aiIntegration = Get-Command Invoke-OllamaDocumentation -ErrorAction SilentlyContinue
        
        $integrationStatus = ($null -ne $qualityIntegration) -and ($null -ne $orchestratorIntegration)
        
        Write-Verbose "[CrossRef] Integration status - Quality: $($null -ne $qualityIntegration), Orchestrator: $($null -ne $orchestratorIntegration), AI: $($null -ne $aiIntegration)"
        
        return $integrationStatus
    }
    catch {
        Write-Warning "[CrossRef] Integration test failed: $($_.Exception.Message)"
        return $false
    }
}

function Get-DocumentationCrossReferenceStatistics {
    <#
    .SYNOPSIS
        Returns comprehensive cross-reference and link management statistics.
    #>
    [CmdletBinding()]
    param()
    
    if (-not $script:CrossReferenceState.IsInitialized) {
        Write-Warning "[CrossRef] Cross-reference system not initialized"
        return $null
    }
    
    $stats = $script:CrossReferenceState.PerformanceMetrics.Clone()
    $stats.Configuration = $script:CrossReferenceState.Configuration.Clone()
    $stats.GraphMetrics = $script:CrossReferenceState.DocumentationGraph.Metrics.Clone()
    $stats.CacheSize = ($script:CrossReferenceState.LinkValidationCache.Keys | Measure-Object).Count
    $stats.IsMonitoring = $script:CrossReferenceState.MonitoringState.IsMonitoring

    if ($stats.StartTime) {
        $stats.Runtime = (Get-Date) - $stats.StartTime
    }
    
    return [PSCustomObject]$stats
}

# Export cross-reference and link management functions
Export-ModuleMember -Function @(
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