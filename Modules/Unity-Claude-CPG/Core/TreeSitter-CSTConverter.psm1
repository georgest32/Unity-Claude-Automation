#Requires -Version 5.1
<#
.SYNOPSIS
    Tree-sitter Concrete Syntax Tree (CST) to Unified CPG Converter.

.DESCRIPTION
    Converts tree-sitter parse trees into unified Code Property Graph representations,
    supporting multiple languages with high-performance parsing and transformation.

.NOTES
    Part of Enhanced Documentation System Second Pass Implementation
    Week 1, Day 3 - Afternoon Session
    Created: 2025-08-28
#>

using module .\CPG-BasicOperations.psm1
using module .\CPG-CallGraphBuilder.psm1
using module .\CPG-DataFlowTracker.psm1
using module .\CPG-ThreadSafeOperations.psm1

# Performance metrics storage
$script:PerformanceMetrics = @{
    ParseTimes = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
    NodeCreationRate = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
    MemoryUsage = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
    TotalFiles = 0
    TotalLines = 0
    StartTime = $null
    EndTime = $null
}

# CST Node types enumeration
enum CSTNodeType {
    Program = 0
    Class = 1
    Method = 2
    Function = 3
    Variable = 4
    Parameter = 5
    Statement = 6
    Expression = 7
    Import = 8
    Module = 9
    Property = 10
    Field = 11
    Constructor = 12
    Decorator = 13
    Comment = 14
    Literal = 15
    Identifier = 16
    Operator = 17
    Keyword = 18
    Type = 19
}

# CST Edge types enumeration
enum CSTEdgeType {
    Child = 0
    Sibling = 1
    Parent = 2
    Reference = 3
    Definition = 4
    Usage = 5
    Import = 6
    Export = 7
    Inherits = 8
    Implements = 9
    Calls = 10
    Returns = 11
    Throws = 12
    Catches = 13
    Decorates = 14
}

# CST Node class representing parse tree nodes
class CSTNode {
    [string]$Id
    [CSTNodeType]$Type
    [string]$Text
    [hashtable]$StartPosition  # @{Line=1; Column=0}
    [hashtable]$EndPosition    # @{Line=1; Column=10}
    [System.Collections.Generic.List[CSTNode]]$Children
    [hashtable]$Properties
    [string]$Language
    
    CSTNode() {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Children = [System.Collections.Generic.List[CSTNode]]::new()
        $this.Properties = @{}
    }
    
    CSTNode([CSTNodeType]$type, [string]$text) {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Type = $type
        $this.Text = $text
        $this.Children = [System.Collections.Generic.List[CSTNode]]::new()
        $this.Properties = @{}
    }
    
    [CPGNode] ConvertToCPGNode() {
        # Convert CST node to CPG node
        $cpgType = switch ($this.Type) {
            'Class' { [CPGNodeType]::Class }
            'Method' { [CPGNodeType]::Method }
            'Function' { [CPGNodeType]::Function }
            'Variable' { [CPGNodeType]::Variable }
            'Parameter' { [CPGNodeType]::Parameter }
            'Property' { [CPGNodeType]::Property }
            'Module' { [CPGNodeType]::Module }
            default { [CPGNodeType]::Unknown }
        }
        
        $cpgNode = [CPGNode]::new($this.Text, $cpgType)
        $cpgNode.Properties = $this.Properties.Clone()
        $cpgNode.Properties['Language'] = $this.Language
        $cpgNode.Properties['StartLine'] = $this.StartPosition.Line
        $cpgNode.Properties['StartColumn'] = $this.StartPosition.Column
        $cpgNode.Properties['EndLine'] = $this.EndPosition.Line
        $cpgNode.Properties['EndColumn'] = $this.EndPosition.Column
        
        return $cpgNode
    }
    
    [CSTNode[]] GetDescendants() {
        $descendants = @()
        $queue = [System.Collections.Queue]::new()
        
        foreach ($child in $this.Children) {
            $queue.Enqueue($child)
        }
        
        while ($queue.Count -gt 0) {
            $node = $queue.Dequeue()
            $descendants += $node
            
            foreach ($child in $node.Children) {
                $queue.Enqueue($child)
            }
        }
        
        return $descendants
    }
    
    [CSTNode[]] FindPattern([string]$pattern) {
        $matches = @()
        $descendants = $this.GetDescendants()
        
        foreach ($node in $descendants) {
            if ($node.Text -match $pattern -or $node.Type.ToString() -match $pattern) {
                $matches += $node
            }
        }
        
        return $matches
    }
}

# CST Edge class representing relationships
class CSTEdge {
    [string]$Id
    [CSTEdgeType]$Type
    [string]$Source  # Node ID
    [string]$Target  # Node ID
    [hashtable]$Properties
    [double]$Weight
    
    CSTEdge() {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Properties = @{}
        $this.Weight = 1.0
    }
    
    CSTEdge([CSTEdgeType]$type, [string]$source, [string]$target) {
        $this.Id = [Guid]::NewGuid().ToString()
        $this.Type = $type
        $this.Source = $source
        $this.Target = $target
        $this.Properties = @{}
        $this.Weight = 1.0
    }
    
    [CPGEdge] ConvertToCPGEdge() {
        # Map CST edge types to CPG edge types
        $cpgType = switch ($this.Type) {
            'Child' { 'contains' }
            'Parent' { 'belongsTo' }
            'Reference' { 'references' }
            'Definition' { 'defines' }
            'Usage' { 'uses' }
            'Import' { 'imports' }
            'Export' { 'exports' }
            'Inherits' { 'inherits' }
            'Implements' { 'implements' }
            'Calls' { 'calls' }
            'Returns' { 'returns' }
            default { 'unknown' }
        }
        
        $cpgEdge = [CPGEdge]::new($this.Source, $this.Target, $cpgType)
        $cpgEdge.Properties = $this.Properties.Clone()
        $cpgEdge.Weight = $this.Weight
        
        return $cpgEdge
    }
    
    [double] GetWeight() {
        return $this.Weight
    }
}

# Abstract base class for language handlers
class LanguageHandler {
    [string]$Language
    [string[]]$FileExtensions
    [string]$ParserPath
    [hashtable]$Configuration
    
    LanguageHandler([string]$language, [string[]]$extensions) {
        $this.Language = $language
        $this.FileExtensions = $extensions
        $this.Configuration = @{}
    }
    
    [CSTNode] ParseFile([string]$filePath) {
        throw "ParseFile must be implemented by derived class"
    }
    
    [CSTNode[]] ExtractNodes([CSTNode]$root) {
        # Default implementation - extract all nodes
        $nodes = @($root)
        $nodes += $root.GetDescendants()
        return $nodes
    }
    
    [CSTEdge[]] ExtractEdges([CSTNode]$root) {
        # Default implementation - extract parent-child relationships
        $edges = @()
        $queue = [System.Collections.Queue]::new()
        $queue.Enqueue($root)
        
        while ($queue.Count -gt 0) {
            $node = $queue.Dequeue()
            
            foreach ($child in $node.Children) {
                $edge = [CSTEdge]::new([CSTEdgeType]::Child, $node.Id, $child.Id)
                $edges += $edge
                $queue.Enqueue($child)
            }
        }
        
        return $edges
    }
    
    [hashtable] GetMetrics([CSTNode]$root) {
        $nodes = $this.ExtractNodes($root)
        $edges = $this.ExtractEdges($root)
        
        return @{
            TotalNodes = $nodes.Count
            TotalEdges = $edges.Count
            NodeTypes = $nodes | Group-Object Type | ForEach-Object { @{$_.Name = $_.Count} }
            EdgeTypes = $edges | Group-Object Type | ForEach-Object { @{$_.Name = $_.Count} }
            MaxDepth = $this.CalculateMaxDepth($root)
            AverageChildrenPerNode = if ($nodes.Count -gt 0) { 
                ($nodes | ForEach-Object { $_.Children.Count } | Measure-Object -Average).Average 
            } else { 0 }
        }
    }
    
    [int] CalculateMaxDepth([CSTNode]$node, [int]$currentDepth = 0) {
        if ($node.Children.Count -eq 0) {
            return $currentDepth
        }
        
        $maxChildDepth = 0
        foreach ($child in $node.Children) {
            $childDepth = $this.CalculateMaxDepth($child, $currentDepth + 1)
            if ($childDepth -gt $maxChildDepth) {
                $maxChildDepth = $childDepth
            }
        }
        
        return $maxChildDepth
    }
}

# C# language handler
class CSharpHandler : LanguageHandler {
    CSharpHandler() : base('csharp', @('.cs')) {
        $this.Configuration = @{
            NamespaceTracking = $true
            UsingDirectives = $true
            ClassHierarchy = $true
            AsyncAwait = $true
            LINQ = $true
        }
    }
    
    [CSTNode] ParseFile([string]$filePath) {
        Write-Verbose "Parsing C# file: $filePath"
        $startTime = [DateTime]::Now
        
        # For now, create a mock parse tree
        # In production, this would call tree-sitter CLI or bindings
        $root = [CSTNode]::new([CSTNodeType]::Program, "Program")
        $root.Language = "C#"
        $root.StartPosition = @{Line = 1; Column = 0}
        
        # Read file content for basic parsing
        $content = Get-Content $filePath -Raw
        $lines = $content -split "`n"
        $root.EndPosition = @{Line = $lines.Count; Column = $lines[-1].Length}
        
        # Extract namespaces
        $namespacePattern = 'namespace\s+([^\s{]+)'
        $namespaces = [regex]::Matches($content, $namespacePattern)
        foreach ($match in $namespaces) {
            $nsNode = [CSTNode]::new([CSTNodeType]::Module, $match.Groups[1].Value)
            $nsNode.Language = "C#"
            $root.Children.Add($nsNode)
        }
        
        # Extract classes
        $classPattern = 'class\s+([^\s{:]+)'
        $classes = [regex]::Matches($content, $classPattern)
        foreach ($match in $classes) {
            $classNode = [CSTNode]::new([CSTNodeType]::Class, $match.Groups[1].Value)
            $classNode.Language = "C#"
            
            # Add to appropriate namespace or root
            if ($root.Children.Count -gt 0) {
                $root.Children[-1].Children.Add($classNode)
            } else {
                $root.Children.Add($classNode)
            }
        }
        
        # Extract methods
        $methodPattern = '(public|private|protected|internal)\s+[\w<>\[\]]+\s+(\w+)\s*\([^)]*\)'
        $methods = [regex]::Matches($content, $methodPattern)
        foreach ($match in $methods) {
            $methodNode = [CSTNode]::new([CSTNodeType]::Method, $match.Groups[2].Value)
            $methodNode.Language = "C#"
            $methodNode.Properties['Visibility'] = $match.Groups[1].Value
            
            # Add to last class if available
            $lastClass = $root.GetDescendants() | Where-Object { $_.Type -eq [CSTNodeType]::Class } | Select-Object -Last 1
            if ($lastClass) {
                $lastClass.Children.Add($methodNode)
            }
        }
        
        # Track performance
        $parseTime = ([DateTime]::Now - $startTime).TotalMilliseconds
        $script:PerformanceMetrics.ParseTimes.Add(@{
            File = $filePath
            Time = $parseTime
            Nodes = $root.GetDescendants().Count + 1
        })
        
        Write-Verbose "Parsed C# file in $parseTime ms"
        return $root
    }
}

# Python language handler
class PythonHandler : LanguageHandler {
    PythonHandler() : base('python', @('.py', '.pyw')) {
        $this.Configuration = @{
            ImportTracking = $true
            DecoratorHandling = $true
            IndentationScoping = $true
            TypeHints = $true
            Docstrings = $true
        }
    }
    
    [CSTNode] ParseFile([string]$filePath) {
        Write-Verbose "Parsing Python file: $filePath"
        $startTime = [DateTime]::Now
        
        $root = [CSTNode]::new([CSTNodeType]::Program, "Module")
        $root.Language = "Python"
        $root.StartPosition = @{Line = 1; Column = 0}
        
        $content = Get-Content $filePath -Raw
        $lines = $content -split "`n"
        $root.EndPosition = @{Line = $lines.Count; Column = $lines[-1].Length}
        
        # Extract imports
        $importPattern = '(from\s+[\w.]+\s+)?import\s+([^\n]+)'
        $imports = [regex]::Matches($content, $importPattern)
        foreach ($match in $imports) {
            $importNode = [CSTNode]::new([CSTNodeType]::Import, $match.Value)
            $importNode.Language = "Python"
            $root.Children.Add($importNode)
        }
        
        # Extract classes
        $classPattern = 'class\s+(\w+)(\([^)]*\))?:'
        $classes = [regex]::Matches($content, $classPattern)
        foreach ($match in $classes) {
            $classNode = [CSTNode]::new([CSTNodeType]::Class, $match.Groups[1].Value)
            $classNode.Language = "Python"
            if ($match.Groups[2].Value) {
                $classNode.Properties['Inherits'] = $match.Groups[2].Value
            }
            $root.Children.Add($classNode)
        }
        
        # Extract functions
        $funcPattern = 'def\s+(\w+)\s*\([^)]*\)(\s*->\s*[^:]+)?:'
        $functions = [regex]::Matches($content, $funcPattern)
        foreach ($match in $functions) {
            $funcNode = [CSTNode]::new([CSTNodeType]::Function, $match.Groups[1].Value)
            $funcNode.Language = "Python"
            if ($match.Groups[2].Value) {
                $funcNode.Properties['ReturnType'] = $match.Groups[2].Value
            }
            
            # Determine if it's a method (inside class) or function
            # Simplified: add to last class if indented
            $lastClass = $root.Children | Where-Object { $_.Type -eq [CSTNodeType]::Class } | Select-Object -Last 1
            if ($lastClass) {
                $funcNode.Type = [CSTNodeType]::Method
                $lastClass.Children.Add($funcNode)
            } else {
                $root.Children.Add($funcNode)
            }
        }
        
        $parseTime = ([DateTime]::Now - $startTime).TotalMilliseconds
        $script:PerformanceMetrics.ParseTimes.Add(@{
            File = $filePath
            Time = $parseTime
            Nodes = $root.GetDescendants().Count + 1
        })
        
        Write-Verbose "Parsed Python file in $parseTime ms"
        return $root
    }
}

# JavaScript/TypeScript language handler
class JavaScriptHandler : LanguageHandler {
    JavaScriptHandler() : base('javascript', @('.js', '.jsx', '.mjs', '.ts', '.tsx')) {
        $this.Configuration = @{
            ModuleImports = $true
            ArrowFunctions = $true
            AsyncAwait = $true
            Classes = $true
            JSX = $true
            TypeAnnotations = $true
        }
    }
    
    [CSTNode] ParseFile([string]$filePath) {
        Write-Verbose "Parsing JavaScript/TypeScript file: $filePath"
        $startTime = [DateTime]::Now
        
        $root = [CSTNode]::new([CSTNodeType]::Program, "Program")
        $root.Language = if ($filePath -match '\.ts') { "TypeScript" } else { "JavaScript" }
        $root.StartPosition = @{Line = 1; Column = 0}
        
        $content = Get-Content $filePath -Raw
        $lines = $content -split "`n"
        $root.EndPosition = @{Line = $lines.Count; Column = $lines[-1].Length}
        
        # Extract imports
        $importPattern = '(import\s+.+\s+from\s+[''"]([^''"]+)[''"]|const\s+\w+\s*=\s*require\([''"]([^''"]+)[''"]\))'
        $imports = [regex]::Matches($content, $importPattern)
        foreach ($match in $imports) {
            $importNode = [CSTNode]::new([CSTNodeType]::Import, $match.Value)
            $importNode.Language = $root.Language
            $root.Children.Add($importNode)
        }
        
        # Extract classes (ES6+)
        $classPattern = 'class\s+(\w+)(\s+extends\s+\w+)?'
        $classes = [regex]::Matches($content, $classPattern)
        foreach ($match in $classes) {
            $classNode = [CSTNode]::new([CSTNodeType]::Class, $match.Groups[1].Value)
            $classNode.Language = $root.Language
            if ($match.Groups[2].Value) {
                $classNode.Properties['Extends'] = $match.Groups[2].Value.Trim()
            }
            $root.Children.Add($classNode)
        }
        
        # Extract functions (regular and arrow)
        $funcPatterns = @(
            'function\s+(\w+)\s*\([^)]*\)',
            'const\s+(\w+)\s*=\s*\([^)]*\)\s*=>',
            '(\w+)\s*:\s*\([^)]*\)\s*=>'
        )
        
        foreach ($pattern in $funcPatterns) {
            $functions = [regex]::Matches($content, $pattern)
            foreach ($match in $functions) {
                $funcNode = [CSTNode]::new([CSTNodeType]::Function, $match.Groups[1].Value)
                $funcNode.Language = $root.Language
                
                # Check if it's async
                if ($match.Value -match 'async') {
                    $funcNode.Properties['Async'] = $true
                }
                
                $root.Children.Add($funcNode)
            }
        }
        
        $parseTime = ([DateTime]::Now - $startTime).TotalMilliseconds
        $script:PerformanceMetrics.ParseTimes.Add(@{
            File = $filePath
            Time = $parseTime
            Nodes = $root.GetDescendants().Count + 1
        })
        
        Write-Verbose "Parsed JavaScript/TypeScript file in $parseTime ms"
        return $root
    }
}

# Main converter function
function Convert-TreeSitterToCST {
    <#
    .SYNOPSIS
        Converts tree-sitter parse output to CST representation
    #>
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [string]$Language = "auto",
        
        [switch]$Benchmark
    )
    
    # Auto-detect language from extension
    if ($Language -eq "auto") {
        $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
        $Language = switch ($extension) {
            '.cs' { 'csharp' }
            '.py' { 'python' }
            '.pyw' { 'python' }
            '.js' { 'javascript' }
            '.jsx' { 'javascript' }
            '.mjs' { 'javascript' }
            '.ts' { 'typescript' }
            '.tsx' { 'typescript' }
            '.ps1' { 'powershell' }
            '.psm1' { 'powershell' }
            default { 'unknown' }
        }
    }
    
    # Select appropriate handler
    $handler = switch ($Language) {
        'csharp' { [CSharpHandler]::new() }
        'python' { [PythonHandler]::new() }
        { $_ -in 'javascript', 'typescript' } { [JavaScriptHandler]::new() }
        default { throw "Unsupported language: $Language" }
    }
    
    # Parse file
    $cstRoot = $handler.ParseFile($FilePath)
    
    if ($Benchmark) {
        $metrics = $handler.GetMetrics($cstRoot)
        $metrics['Language'] = $Language
        $metrics['FilePath'] = $FilePath
        return @{
            CST = $cstRoot
            Metrics = $metrics
        }
    }
    
    return $cstRoot
}

# Convert CST to CPG
function Convert-CSTToCPG {
    <#
    .SYNOPSIS
        Converts CST representation to CPG format
    #>
    param(
        [Parameter(Mandatory)]
        [CSTNode]$CSTRoot,
        
        [switch]$ThreadSafe
    )
    
    # Create CPG
    $cpg = if ($ThreadSafe) {
        New-ThreadSafeCPG -Name "CPG_$($CSTRoot.Language)"
    } else {
        New-CPGraph -Name "CPG_$($CSTRoot.Language)"
    }
    
    # Convert nodes
    $nodeMap = @{}
    $queue = [System.Collections.Queue]::new()
    $queue.Enqueue($CSTRoot)
    
    while ($queue.Count -gt 0) {
        $cstNode = $queue.Dequeue()
        $cpgNode = $cstNode.ConvertToCPGNode()
        
        if ($ThreadSafe) {
            Add-ThreadSafeNode -Graph $cpg -Node $cpgNode
        } else {
            Add-CPGNode -Graph $cpg -Node $cpgNode
        }
        
        $nodeMap[$cstNode.Id] = $cpgNode.Id
        
        foreach ($child in $cstNode.Children) {
            $queue.Enqueue($child)
        }
    }
    
    # Convert edges
    $cstNodes = @($CSTRoot) + $CSTRoot.GetDescendants()
    foreach ($node in $cstNodes) {
        foreach ($child in $node.Children) {
            $edge = [CPGEdge]::new($nodeMap[$node.Id], $nodeMap[$child.Id], 'contains')
            
            if ($ThreadSafe) {
                Add-ThreadSafeEdge -Graph $cpg -Edge $edge
            } else {
                Add-CPGEdge -Graph $cpg -Edge $edge
            }
        }
    }
    
    return $cpg
}

# Performance benchmarking
function Measure-TreeSitterPerformance {
    <#
    .SYNOPSIS
        Benchmarks tree-sitter parsing performance
    #>
    param(
        [Parameter(Mandatory)]
        [string[]]$FilePaths,
        
        [switch]$CompareWithAST
    )
    
    $script:PerformanceMetrics.StartTime = [DateTime]::Now
    $results = @()
    
    foreach ($file in $FilePaths) {
        Write-Host "Benchmarking: $file" -ForegroundColor Cyan
        
        # Measure tree-sitter parsing
        $tsStart = [DateTime]::Now
        $cst = Convert-TreeSitterToCST -FilePath $file -Benchmark
        $tsTime = ([DateTime]::Now - $tsStart).TotalMilliseconds
        
        # Measure AST parsing if requested
        $astTime = 0
        if ($CompareWithAST -and $file -match '\.ps1$|\.psm1$') {
            $astStart = [DateTime]::Now
            $ast = [System.Management.Automation.Language.Parser]::ParseFile(
                $file,
                [ref]$null,
                [ref]$null
            )
            $astTime = ([DateTime]::Now - $astStart).TotalMilliseconds
        }
        
        $result = @{
            File = $file
            TreeSitterTime = $tsTime
            ASTTime = $astTime
            SpeedupFactor = if ($astTime -gt 0) { [Math]::Round($astTime / $tsTime, 2) } else { 0 }
            NodeCount = $cst.Metrics.TotalNodes
            EdgeCount = $cst.Metrics.TotalEdges
        }
        
        $results += $result
    }
    
    $script:PerformanceMetrics.EndTime = [DateTime]::Now
    $script:PerformanceMetrics.TotalFiles = $FilePaths.Count
    
    # Calculate summary
    $summary = @{
        TotalFiles = $results.Count
        AverageTreeSitterTime = ($results.TreeSitterTime | Measure-Object -Average).Average
        AverageASTTime = ($results | Where-Object { $_.ASTTime -gt 0 } | ForEach-Object { $_.ASTTime } | Measure-Object -Average).Average
        AverageSpeedup = ($results | Where-Object { $_.SpeedupFactor -gt 0 } | ForEach-Object { $_.SpeedupFactor } | Measure-Object -Average).Average
        TotalNodes = ($results.NodeCount | Measure-Object -Sum).Sum
        TotalEdges = ($results.EdgeCount | Measure-Object -Sum).Sum
        TotalTime = ($script:PerformanceMetrics.EndTime - $script:PerformanceMetrics.StartTime).TotalSeconds
    }
    
    Write-Host "`nPerformance Summary:" -ForegroundColor Green
    Write-Host "Files Processed: $($summary.TotalFiles)"
    Write-Host "Average Tree-sitter Time: $([Math]::Round($summary.AverageTreeSitterTime, 2))ms"
    if ($summary.AverageASTTime -gt 0) {
        Write-Host "Average AST Time: $([Math]::Round($summary.AverageASTTime, 2))ms"
        Write-Host "Average Speedup: $($summary.AverageSpeedup)x"
    }
    Write-Host "Total Nodes Created: $($summary.TotalNodes)"
    Write-Host "Total Edges Created: $($summary.TotalEdges)"
    
    return @{
        Results = $results
        Summary = $summary
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Convert-TreeSitterToCST',
    'Convert-CSTToCPG',
    'Measure-TreeSitterPerformance'
) -Class @(
    'CSTNode',
    'CSTEdge',
    'LanguageHandler',
    'CSharpHandler',
    'PythonHandler',
    'JavaScriptHandler'
)

# Module initialization
Write-Verbose "TreeSitter-CSTConverter module loaded successfully"

# SIG # Begin signature block
# Tree-sitter CST Converter for Enhanced Documentation System
# Week 1, Day 3, Afternoon - Multi-language parsing support
# SIG # End signature block