# CrossLanguage-DependencyMaps.psm1
# Enhanced Documentation System - Day 5 Afternoon Implementation
# Cross-language reference resolution and dependency mapping
# Created: 2025-08-28 04:25 AM

using namespace System.Collections.Generic
using namespace System.Collections.Concurrent

# Import required modules
# Note: Using Import-Module with ErrorAction to avoid parse-time failures
Import-Module "$PSScriptRoot\CPG-Unified.psm1" -Force -ErrorAction SilentlyContinue

# Define types locally to avoid cross-module dependency issues
# Re-define required enums and classes to avoid dependency issues
enum UnifiedNodeType {
    Root
    Namespace
    ClassDefinition
    InterfaceDefinition
    StructDefinition
    FunctionDefinition
    MethodDefinition
    PropertyDefinition
    FieldDefinition
    ParameterDefinition
    VariableDeclaration
    VariableReference
    FunctionCall
    MethodCall
    ImportStatement
    ExportStatement
    TypeReference
    ModuleDefinition
    Comment
}

enum UnifiedRelationType {
    Contains
    Inherits
    Implements
    Uses
    Calls
    References
    Imports
    Exports
    DependsOn
    Overrides
    Decorates
}

# UnifiedNode class
class UnifiedNode {
    [string] $Id
    [string] $Name
    [UnifiedNodeType] $Type
    [string] $SourceLanguage
    [string] $Namespace
    [hashtable] $Properties
    
    UnifiedNode([string] $name, [UnifiedNodeType] $type, [string] $sourceLanguage) {
        $this.Id = [System.Guid]::NewGuid().ToString()
        $this.Name = $name
        $this.Type = $type
        $this.SourceLanguage = $sourceLanguage
        $this.Properties = @{}
    }
}

# UnifiedRelation class
class UnifiedRelation {
    [string] $Id
    [UnifiedRelationType] $Type
    [string] $SourceId
    [string] $TargetId
    [string] $SourceLanguage
    [hashtable] $Properties
    
    UnifiedRelation([UnifiedRelationType] $type, [string] $sourceId, [string] $targetId, [string] $sourceLanguage) {
        $this.Id = [System.Guid]::NewGuid().ToString()
        $this.Type = $type
        $this.SourceId = $sourceId
        $this.TargetId = $targetId
        $this.SourceLanguage = $sourceLanguage
        $this.Properties = @{}
    }
}

# UnifiedCPG class
class UnifiedCPG {
    [string] $Name
    [hashtable] $Nodes
    [System.Collections.Generic.List[object]] $Relations
    [hashtable] $Properties
    
    UnifiedCPG([string] $name) {
        $this.Name = $name
        $this.Nodes = @{}
        $this.Relations = [System.Collections.Generic.List[object]]::new()
        $this.Properties = @{}
    }
    
    [void] AddNode([object] $node) {
        if ($node.Id) {
            $this.Nodes[$node.Id] = $node
        }
    }
    
    [void] AddRelation([object] $relation) {
        $this.Relations.Add($relation)
    }
    
    [object[]] GetAllNodes() {
        return $this.Nodes.Values
    }
    
    [object[]] GetAllRelations() {
        return $this.Relations.ToArray()
    }
}

# Enums for dependency analysis
enum DependencyType {
    Import          # Module/namespace imports
    Inheritance     # Class inheritance
    Composition     # Object composition  
    Call            # Function/method calls
    DataFlow        # Variable/data dependencies
    Configuration   # Config file dependencies
    External        # External library dependencies
}

enum DependencyDirection {
    Incoming        # Dependencies coming into this node
    Outgoing        # Dependencies going out from this node
    Bidirectional   # Both directions
}

enum CircularityType {
    None           # No circular dependency
    Direct         # A -> B -> A
    Indirect       # A -> B -> C -> A
    Complex        # Multiple cycles involving same nodes
}

enum ReferenceType {
    Strong         # Hard dependency (import, inheritance)
    Weak           # Soft dependency (string references)
    Potential      # Inferred dependency (naming patterns)
    Configuration  # Config-based dependency
}

# Core dependency classes
class CrossLanguageReference {
    [string] $Id
    [string] $SourceLanguage
    [string] $TargetLanguage
    [string] $SourceNodeId
    [string] $TargetNodeId
    [ReferenceType] $Type
    [string] $ReferenceName
    [string] $Context
    [float] $Confidence
    [hashtable] $Properties
    [DateTime] $Timestamp

    CrossLanguageReference([string] $sourceLanguage, [string] $targetLanguage, [string] $sourceNode, [string] $targetNode, [ReferenceType] $type) {
        $this.Id = [System.Guid]::NewGuid().ToString()
        $this.SourceLanguage = $sourceLanguage
        $this.TargetLanguage = $targetLanguage
        $this.SourceNodeId = $sourceNode
        $this.TargetNodeId = $targetNode
        $this.Type = $type
        $this.Confidence = 1.0
        $this.Properties = @{}
        $this.Timestamp = Get-Date
    }

    [string] ToString() {
        return "$($this.SourceLanguage).$($this.SourceNodeId) -> $($this.TargetLanguage).$($this.TargetNodeId) [$($this.Type)]"
    }
}

class DependencyNode {
    [string] $Id
    [string] $Name
    [string] $Language
    [string] $Namespace
    [UnifiedNodeType] $Type
    [List[string]] $IncomingDependencies
    [List[string]] $OutgoingDependencies
    [hashtable] $Metrics
    [hashtable] $Properties

    DependencyNode([string] $id, [string] $name, [string] $language, [UnifiedNodeType] $type) {
        $this.Id = $id
        $this.Name = $name
        $this.Language = $language
        $this.Type = $type
        $this.IncomingDependencies = [List[string]]::new()
        $this.OutgoingDependencies = [List[string]]::new()
        $this.Metrics = @{
            InDegree = 0
            OutDegree = 0
            TotalDegree = 0
            Betweenness = 0.0
            Closeness = 0.0
            PageRank = 0.0
        }
        $this.Properties = @{}
    }

    [void] UpdateMetrics() {
        $this.Metrics.InDegree = $this.IncomingDependencies.Count
        $this.Metrics.OutDegree = $this.OutgoingDependencies.Count
        $this.Metrics.TotalDegree = $this.Metrics.InDegree + $this.Metrics.OutDegree
    }
}

class DependencyGraph {
    [string] $Name
    [hashtable] $Nodes
    [List[CrossLanguageReference]] $References
    [hashtable] $LanguageStats
    [hashtable] $DependencyMatrix
    [List[object]] $CircularDependencies
    [hashtable] $Metrics

    DependencyGraph([string] $name) {
        $this.Name = $name
        $this.Nodes = @{}
        $this.References = [List[CrossLanguageReference]]::new()
        $this.LanguageStats = @{}
        $this.DependencyMatrix = @{}
        $this.CircularDependencies = [List[object]]::new()
        $this.Metrics = @{
            TotalNodes = 0
            TotalReferences = 0
            CrossLanguageReferences = 0
            CircularDependencies = 0
            AverageInDegree = 0.0
            AverageOutDegree = 0.0
            Density = 0.0
        }
    }

    [void] AddNode([DependencyNode] $node) {
        $this.Nodes[$node.Id] = $node
        $this.UpdateLanguageStats($node.Language)
        $this.Metrics.TotalNodes++
    }

    [void] AddReference([CrossLanguageReference] $reference) {
        $this.References.Add($reference)
        
        # Update node connections
        if ($this.Nodes.ContainsKey($reference.SourceNodeId)) {
            $this.Nodes[$reference.SourceNodeId].OutgoingDependencies.Add($reference.TargetNodeId)
            $this.Nodes[$reference.SourceNodeId].UpdateMetrics()
        }
        
        if ($this.Nodes.ContainsKey($reference.TargetNodeId)) {
            $this.Nodes[$reference.TargetNodeId].IncomingDependencies.Add($reference.SourceNodeId)
            $this.Nodes[$reference.TargetNodeId].UpdateMetrics()
        }
        
        # Update metrics
        $this.Metrics.TotalReferences++
        if ($reference.SourceLanguage -ne $reference.TargetLanguage) {
            $this.Metrics.CrossLanguageReferences++
        }
    }

    [void] UpdateLanguageStats([string] $language) {
        if (-not $this.LanguageStats.ContainsKey($language)) {
            $this.LanguageStats[$language] = @{
                NodeCount = 0
                IncomingReferences = 0
                OutgoingReferences = 0
                SelfReferences = 0
            }
        }
        $this.LanguageStats[$language].NodeCount++
    }

    [void] BuildDependencyMatrix() {
        Write-CPGDebug "Building dependency matrix for $($this.Nodes.Count) nodes"
        
        $nodeIds = @($this.Nodes.Keys)
        $this.DependencyMatrix = @{}
        
        # Initialize matrix
        foreach ($sourceId in $nodeIds) {
            $this.DependencyMatrix[$sourceId] = @{}
            foreach ($targetId in $nodeIds) {
                $this.DependencyMatrix[$sourceId][$targetId] = 0
            }
        }
        
        # Populate matrix from references
        foreach ($reference in $this.References) {
            if ($this.DependencyMatrix.ContainsKey($reference.SourceNodeId) -and 
                $this.DependencyMatrix[$reference.SourceNodeId].ContainsKey($reference.TargetNodeId)) {
                $this.DependencyMatrix[$reference.SourceNodeId][$reference.TargetNodeId] = 1
            }
        }
    }

    [float] CalculateGraphDensity() {
        $nodeCount = $this.Nodes.Count
        if ($nodeCount -le 1) { return 0.0 }
        
        $maxPossibleEdges = $nodeCount * ($nodeCount - 1)
        $actualEdges = $this.References.Count
        
        return $actualEdges / $maxPossibleEdges
    }

    [hashtable] GetTopologicalOrdering() {
        # Implementation of topological sort for dependency ordering
        $inDegree = @{}
        $queue = [Queue[string]]::new()
        $result = [List[string]]::new()
        
        # Calculate in-degrees
        foreach ($node in $this.Nodes.Values) {
            $inDegree[$node.Id] = $node.IncomingDependencies.Count
            if ($inDegree[$node.Id] -eq 0) {
                $queue.Enqueue($node.Id)
            }
        }
        
        # Process nodes with no dependencies first
        while ($queue.Count -gt 0) {
            $current = $queue.Dequeue()
            $result.Add($current)
            
            # Reduce in-degree for dependent nodes
            foreach ($dependent in $this.Nodes[$current].OutgoingDependencies) {
                $inDegree[$dependent]--
                if ($inDegree[$dependent] -eq 0) {
                    $queue.Enqueue($dependent)
                }
            }
        }
        
        return @{
            Order = $result.ToArray()
            HasCycles = $result.Count -ne $this.Nodes.Count
        }
    }
}

class CrossLanguageReferenceResolver {
    [hashtable] $LanguageGraphs
    [DependencyGraph] $DependencyGraph
    [hashtable] $ReferencePatterns
    [hashtable] $ResolvedReferences
    [List[object]] $UnresolvedReferences

    CrossLanguageReferenceResolver([hashtable] $languageGraphs) {
        $this.LanguageGraphs = $languageGraphs
        $this.DependencyGraph = [DependencyGraph]::new("CrossLanguageDependencies")
        $this.ReferencePatterns = $this.InitializeReferencePatterns()
        $this.ResolvedReferences = @{}
        $this.UnresolvedReferences = [List[object]]::new()
    }

    [hashtable] InitializeReferencePatterns() {
        return @{
            "PowerShell" = @{
                "Import" = @("Import-Module", "using", ". ")
                "Call" = @("Invoke-", "&", ".")
                "Variable" = @('$', '@')
            }
            "Python" = @{
                "Import" = @("import", "from", "__import__")
                "Call" = @("(", ".")
                "Variable" = @()
            }
            "CSharp" = @{
                "Import" = @("using", "extern alias")
                "Call" = @(".", "(")
                "Variable" = @()
            }
            "JavaScript" = @{
                "Import" = @("import", "require", "from")
                "Call" = @(".", "(")
                "Variable" = @("var", "let", "const")
            }
        }
    }

    [DependencyGraph] ResolveAllReferences() {
        Write-CPGDebug "Resolving cross-language references for $($this.LanguageGraphs.Count) languages"
        
        try {
            # Phase 1: Build dependency nodes from all graphs
            $this.BuildDependencyNodes()
            
            # Phase 2: Resolve import/export relationships
            $this.ResolveImportExportReferences()
            
            # Phase 3: Resolve function/method calls
            $this.ResolveFunctionCallReferences()
            
            # Phase 4: Resolve inheritance relationships
            $this.ResolveInheritanceReferences()
            
            # Phase 5: Resolve data flow references
            $this.ResolveDataFlowReferences()
            
            # Phase 6: Build dependency matrix and analyze
            $this.DependencyGraph.BuildDependencyMatrix()
            $this.AnalyzeDependencyPatterns()
            
            Write-CPGDebug "Reference resolution completed: $($this.DependencyGraph.References.Count) references found"
            return $this.DependencyGraph
        }
        catch {
            Write-CPGDebug "Reference resolution failed: $($_.Exception.Message)" "Error"
            throw
        }
    }

    [void] BuildDependencyNodes() {
        Write-CPGDebug "Building dependency nodes from language graphs"
        
        foreach ($langPair in $this.LanguageGraphs.GetEnumerator()) {
            $language = $langPair.Key
            $graph = $langPair.Value
            
            if ($graph.Nodes) {
                foreach ($nodePair in $graph.Nodes.GetEnumerator()) {
                    $node = $nodePair.Value
                    
                    $depNode = [DependencyNode]::new(
                        $node.Id,
                        $node.Name,
                        $language,
                        $node.Type
                    )
                    
                    if ($node.Namespace) {
                        $depNode.Namespace = $node.Namespace
                    }
                    
                    # Copy relevant properties
                    if ($node.Properties) {
                        foreach ($prop in $node.Properties.GetEnumerator()) {
                            $depNode.Properties[$prop.Key] = $prop.Value
                        }
                    }
                    
                    $this.DependencyGraph.AddNode($depNode)
                }
            }
        }
    }

    [void] ResolveImportExportReferences() {
        Write-CPGDebug "Resolving import/export references"
        
        foreach ($langPair in $this.LanguageGraphs.GetEnumerator()) {
            $language = $langPair.Key
            $graph = $langPair.Value
            
            # Find import statements in this language
            $importNodes = $this.FindImportNodes($graph, $language)
            
            foreach ($importNode in $importNodes) {
                $targets = $this.ResolveImportTarget($importNode, $language)
                
                foreach ($target in $targets) {
                    $reference = [CrossLanguageReference]::new(
                        $language,
                        $target.Language,
                        $importNode.Id,
                        $target.Id,
                        [ReferenceType]::Strong
                    )
                    
                    $reference.ReferenceName = $importNode.Name
                    $reference.Context = "Import"
                    $reference.Confidence = $target.Confidence
                    
                    $this.DependencyGraph.AddReference($reference)
                    $this.ResolvedReferences["$($importNode.Id)->$($target.Id)"] = $reference
                }
            }
        }
    }

    [object[]] FindImportNodes([object] $graph, [string] $language) {
        $importNodes = @()
        
        if (-not $graph.Nodes) { return $importNodes }
        
        foreach ($node in $graph.Nodes.Values) {
            # Check if this is an import-related node based on language patterns
            $isImport = $false
            
            if ($this.ReferencePatterns.ContainsKey($language)) {
                $patterns = $this.ReferencePatterns[$language].Import
                
                foreach ($pattern in $patterns) {
                    if ($node.Name -like "*$pattern*" -or 
                        ($node.Properties.Code -and $node.Properties.Code -like "*$pattern*")) {
                        $isImport = $true
                        break
                    }
                }
            }
            
            if ($isImport -or $node.Type -eq [UnifiedNodeType]::ImportStatement) {
                $importNodes += $node
            }
        }
        
        return $importNodes
    }

    [object[]] ResolveImportTarget([object] $importNode, [string] $sourceLanguage) {
        $targets = @()
        
        # Extract imported name/path
        $importName = $this.ExtractImportName($importNode, $sourceLanguage)
        
        if (-not $importName) { return $targets }
        
        # Search for matching exports/modules in other languages
        foreach ($langPair in $this.LanguageGraphs.GetEnumerator()) {
            $targetLanguage = $langPair.Key
            $targetGraph = $langPair.Value
            
            if ($targetLanguage -eq $sourceLanguage) { continue }
            
            $matches = $this.FindMatchingExports($targetGraph, $targetLanguage, $importName)
            
            foreach ($match in $matches) {
                $targets += [PSCustomObject]@{
                    Id = $match.Id
                    Language = $targetLanguage
                    Node = $match
                    Confidence = $this.CalculateImportConfidence($importNode, $match, $sourceLanguage, $targetLanguage)
                }
            }
        }
        
        return $targets
    }

    [string] ExtractImportName([object] $importNode, [string] $language) {
        # Language-specific import name extraction
        switch ($language) {
            "PowerShell" {
                if ($importNode.Properties.ModuleName) {
                    return $importNode.Properties.ModuleName
                }
                if ($importNode.Name -match "Import-Module\s+(.+)") {
                    return $matches[1].Trim('"', "'")
                }
            }
            "Python" {
                if ($importNode.Name -match "import\s+(\w+)") {
                    return $matches[1]
                }
                if ($importNode.Name -match "from\s+(\w+)\s+import") {
                    return $matches[1]
                }
            }
            "CSharp" {
                if ($importNode.Name -match "using\s+([^;]+)") {
                    return $matches[1]
                }
            }
            "JavaScript" {
                if ($importNode.Name -match "import.*from\s+[`"']([^`"']+)[`"']") {
                    return $matches[1]
                }
                if ($importNode.Name -match "require\([`"']([^`"']+)[`"']\)") {
                    return $matches[1]
                }
            }
        }
        
        return $importNode.Name
    }

    [object[]] FindMatchingExports([object] $graph, [string] $language, [string] $importName) {
        $matches = @()
        
        if (-not $graph.Nodes) { return $matches }
        
        foreach ($node in $graph.Nodes.Values) {
            # Check for exact name match
            if ($node.Name -eq $importName) {
                $matches += $node
                continue
            }
            
            # Check for module/namespace match
            if ($node.Namespace -eq $importName) {
                $matches += $node
                continue
            }
            
            # Check for fuzzy match (similar names)
            $similarity = $this.CalculateStringSimilarity($node.Name, $importName)
            if ($similarity -gt 0.8) {
                $matches += $node
            }
        }
        
        return $matches
    }

    [float] CalculateImportConfidence([object] $importNode, [object] $exportNode, [string] $sourceLang, [string] $targetLang) {
        $confidence = 0.0
        
        # Exact name match gets high confidence
        if ($importNode.Name -eq $exportNode.Name) {
            $confidence += 0.5
        }
        
        # Module/namespace match
        if ($importNode.Namespace -eq $exportNode.Namespace) {
            $confidence += 0.3
        }
        
        # Language compatibility
        $langCompatibility = $this.GetLanguageCompatibility($sourceLang, $targetLang)
        $confidence += $langCompatibility * 0.2
        
        return [Math]::Min($confidence, 1.0)
    }

    [float] GetLanguageCompatibility([string] $lang1, [string] $lang2) {
        # Compatibility matrix for cross-language references
        $compatibility = @{
            "PowerShell" = @{
                "CSharp" = 0.9     # High compatibility
                "Python" = 0.3     # Low compatibility
                "JavaScript" = 0.2 # Very low compatibility
            }
            "Python" = @{
                "PowerShell" = 0.3
                "CSharp" = 0.4
                "JavaScript" = 0.5
            }
            "CSharp" = @{
                "PowerShell" = 0.9
                "Python" = 0.4
                "JavaScript" = 0.3
            }
            "JavaScript" = @{
                "PowerShell" = 0.2
                "Python" = 0.5
                "CSharp" = 0.3
            }
        }
        
        if ($compatibility.ContainsKey($lang1) -and $compatibility[$lang1].ContainsKey($lang2)) {
            return $compatibility[$lang1][$lang2]
        }
        
        return 0.1  # Default low compatibility
    }

    [void] ResolveFunctionCallReferences() {
        Write-CPGDebug "Resolving function call references"
        
        foreach ($langPair in $this.LanguageGraphs.GetEnumerator()) {
            $language = $langPair.Key
            $graph = $langPair.Value
            
            # Find function call nodes
            $callNodes = $this.FindCallNodes($graph, $language)
            
            foreach ($callNode in $callNodes) {
                $targets = $this.ResolveFunctionTarget($callNode, $language)
                
                foreach ($target in $targets) {
                    $reference = [CrossLanguageReference]::new(
                        $language,
                        $target.Language,
                        $callNode.Id,
                        $target.Id,
                        [ReferenceType]::Strong
                    )
                    
                    $reference.ReferenceName = $callNode.Name
                    $reference.Context = "FunctionCall"
                    $reference.Confidence = $target.Confidence
                    
                    $this.DependencyGraph.AddReference($reference)
                }
            }
        }
    }

    [object[]] FindCallNodes([object] $graph, [string] $language) {
        $callNodes = @()
        
        if (-not $graph.Nodes) { return $callNodes }
        
        foreach ($node in $graph.Nodes.Values) {
            if ($node.Type -eq [UnifiedNodeType]::FunctionCall -or
                $node.Type -eq [UnifiedNodeType]::MethodCall) {
                $callNodes += $node
            }
        }
        
        return $callNodes
    }

    [object[]] ResolveFunctionTarget([object] $callNode, [string] $sourceLanguage) {
        $targets = @()
        
        # Extract function name from call
        $functionName = $this.ExtractFunctionName($callNode, $sourceLanguage)
        
        if (-not $functionName) { return $targets }
        
        # Search for matching function definitions
        foreach ($langPair in $this.LanguageGraphs.GetEnumerator()) {
            $targetLanguage = $langPair.Key
            $targetGraph = $langPair.Value
            
            $matches = $this.FindMatchingFunctions($targetGraph, $targetLanguage, $functionName)
            
            foreach ($match in $matches) {
                $targets += [PSCustomObject]@{
                    Id = $match.Id
                    Language = $targetLanguage
                    Node = $match
                    Confidence = $this.CalculateFunctionConfidence($callNode, $match, $sourceLanguage, $targetLanguage)
                }
            }
        }
        
        return $targets
    }

    [string] ExtractFunctionName([object] $callNode, [string] $language) {
        # Extract just the function name from the call
        $name = $callNode.Name
        
        # Remove common call prefixes/suffixes
        $name = $name -replace '\(.*\)$', ''  # Remove parameter list
        $name = $name -replace '^.*\.', ''    # Remove object prefix
        $name = $name -replace '^&', ''       # Remove PowerShell call operator
        
        return $name.Trim()
    }

    [object[]] FindMatchingFunctions([object] $graph, [string] $language, [string] $functionName) {
        $matches = @()
        
        if (-not $graph.Nodes) { return $matches }
        
        foreach ($node in $graph.Nodes.Values) {
            if ($node.Type -eq [UnifiedNodeType]::FunctionDefinition -or
                $node.Type -eq [UnifiedNodeType]::MethodDefinition) {
                
                if ($node.Name -eq $functionName -or $node.Name -like "*$functionName*") {
                    $matches += $node
                }
            }
        }
        
        return $matches
    }

    [float] CalculateFunctionConfidence([object] $callNode, [object] $functionNode, [string] $sourceLang, [string] $targetLang) {
        $confidence = 0.0
        
        # Exact name match
        if ($callNode.Name -eq $functionNode.Name) {
            $confidence += 0.6
        }
        elseif ($callNode.Name -like "*$($functionNode.Name)*") {
            $confidence += 0.4
        }
        
        # Parameter count match (if available)
        if ($callNode.Properties.ParameterCount -and $functionNode.Properties.ParameterCount) {
            if ($callNode.Properties.ParameterCount -eq $functionNode.Properties.ParameterCount) {
                $confidence += 0.2
            }
        }
        
        # Language compatibility
        $langCompatibility = $this.GetLanguageCompatibility($sourceLang, $targetLang)
        $confidence += $langCompatibility * 0.2
        
        return [Math]::Min($confidence, 1.0)
    }

    [void] ResolveInheritanceReferences() {
        Write-CPGDebug "Resolving inheritance references"
        # Implementation for cross-language inheritance detection
        # This would be more complex and language-specific
    }

    [void] ResolveDataFlowReferences() {
        Write-CPGDebug "Resolving data flow references"
        # Implementation for cross-language data flow detection
        # This would involve variable tracking across language boundaries
    }

    [void] AnalyzeDependencyPatterns() {
        Write-CPGDebug "Analyzing dependency patterns"
        
        # Update graph-level metrics
        $this.DependencyGraph.Metrics.Density = $this.DependencyGraph.CalculateGraphDensity()
        
        # Calculate average degrees
        $totalInDegree = 0
        $totalOutDegree = 0
        
        foreach ($node in $this.DependencyGraph.Nodes.Values) {
            $totalInDegree += $node.Metrics.InDegree
            $totalOutDegree += $node.Metrics.OutDegree
        }
        
        if ($this.DependencyGraph.Nodes.Count -gt 0) {
            $this.DependencyGraph.Metrics.AverageInDegree = $totalInDegree / $this.DependencyGraph.Nodes.Count
            $this.DependencyGraph.Metrics.AverageOutDegree = $totalOutDegree / $this.DependencyGraph.Nodes.Count
        }
        
        # Detect circular dependencies
        $this.DetectCircularDependencies()
    }

    [void] DetectCircularDependencies() {
        Write-CPGDebug "Detecting circular dependencies"
        
        $visited = @{}
        $recursionStack = @{}
        $cycles = [List[object]]::new()
        
        foreach ($nodeId in $this.DependencyGraph.Nodes.Keys) {
            if (-not $visited.ContainsKey($nodeId)) {
                $this.DFSCycleDetection($nodeId, $visited, $recursionStack, $cycles)
            }
        }
        
        $this.DependencyGraph.CircularDependencies = $cycles
        $this.DependencyGraph.Metrics.CircularDependencies = $cycles.Count
        
        Write-CPGDebug "Found $($cycles.Count) circular dependencies"
    }

    [void] DFSCycleDetection([string] $nodeId, [hashtable] $visited, [hashtable] $recursionStack, [List[object]] $cycles) {
        $visited[$nodeId] = $true
        $recursionStack[$nodeId] = $true
        
        $node = $this.DependencyGraph.Nodes[$nodeId]
        
        foreach ($dependentId in $node.OutgoingDependencies) {
            if (-not $visited.ContainsKey($dependentId)) {
                $this.DFSCycleDetection($dependentId, $visited, $recursionStack, $cycles)
            }
            elseif ($recursionStack.ContainsKey($dependentId) -and $recursionStack[$dependentId]) {
                # Found a cycle
                $cycle = [PSCustomObject]@{
                    Type = [CircularityType]::Direct
                    Nodes = @($nodeId, $dependentId)
                    Languages = @($node.Language, $this.DependencyGraph.Nodes[$dependentId].Language)
                    Severity = "High"
                }
                $cycles.Add($cycle)
            }
        }
        
        $recursionStack[$nodeId] = $false
    }

    [float] CalculateStringSimilarity([string] $str1, [string] $str2) {
        if (-not $str1 -and -not $str2) { return 1.0 }
        if (-not $str1 -or -not $str2) { return 0.0 }
        
        # Simple Levenshtein distance based similarity
        $maxLen = [Math]::Max($str1.Length, $str2.Length)
        $distance = $this.LevenshteinDistance($str1, $str2)
        
        return 1.0 - ($distance / $maxLen)
    }

    [int] LevenshteinDistance([string] $s, [string] $t) {
        $n = $s.Length
        $m = $t.Length
        
        if ($n -eq 0) { return $m }
        if ($m -eq 0) { return $n }
        
        $d = New-Object 'int[,]' ($n + 1), ($m + 1)
        
        for ($i = 0; $i -le $n; $i++) { $d[$i, 0] = $i }
        for ($j = 0; $j -le $m; $j++) { $d[0, $j] = $j }
        
        for ($i = 1; $i -le $n; $i++) {
            for ($j = 1; $j -le $m; $j++) {
                $cost = if ($s[$i-1] -eq $t[$j-1]) { 0 } else { 1 }
                $val1 = $d[($i-1), $j] + 1
                $val2 = $d[$i, ($j-1)] + 1
                $val3 = $d[($i-1), ($j-1)] + $cost
                $d[$i, $j] = [Math]::Min([Math]::Min($val1, $val2), $val3)
            }
        }
        
        return $d[$n, $m]
    }
}

# Circular dependency detection utilities
class CircularDependencyDetector {
    [DependencyGraph] $Graph
    [List[object]] $DetectedCycles
    
    CircularDependencyDetector([DependencyGraph] $graph) {
        $this.Graph = $graph
        $this.DetectedCycles = [List[object]]::new()
    }
    
    [List[object]] DetectAllCycles() {
        Write-CPGDebug "Detecting circular dependencies in graph with $($this.Graph.Nodes.Count) nodes"
        
        # Use Tarjan's algorithm for strongly connected components
        $this.TarjanSCC()
        
        # Additional cycle detection for complex patterns
        $this.DetectComplexCycles()
        
        Write-CPGDebug "Detected $($this.DetectedCycles.Count) circular dependency patterns"
        return $this.DetectedCycles
    }
    
    [void] TarjanSCC() {
        $index = 0
        $stack = [Stack[string]]::new()
        $indices = @{}
        $lowlinks = @{}
        $onStack = @{}
        
        foreach ($nodeId in $this.Graph.Nodes.Keys) {
            if (-not $indices.ContainsKey($nodeId)) {
                $this.StrongConnect($nodeId, [ref]$index, $stack, $indices, $lowlinks, $onStack)
            }
        }
    }
    
    [void] StrongConnect([string] $nodeId, [ref] $index, [Stack[string]] $stack, [hashtable] $indices, [hashtable] $lowlinks, [hashtable] $onStack) {
        # Tarjan's strongly connected components algorithm
        $indices[$nodeId] = $index.Value
        $lowlinks[$nodeId] = $index.Value
        $index.Value++
        $stack.Push($nodeId)
        $onStack[$nodeId] = $true
        
        $node = $this.Graph.Nodes[$nodeId]
        foreach ($dependentId in $node.OutgoingDependencies) {
            if (-not $indices.ContainsKey($dependentId)) {
                $this.StrongConnect($dependentId, $index, $stack, $indices, $lowlinks, $onStack)
                $lowlinks[$nodeId] = [Math]::Min($lowlinks[$nodeId], $lowlinks[$dependentId])
            }
            elseif ($onStack.ContainsKey($dependentId) -and $onStack[$dependentId]) {
                $lowlinks[$nodeId] = [Math]::Min($lowlinks[$nodeId], $indices[$dependentId])
            }
        }
        
        # If nodeId is a root node, pop the stack and create an SCC
        if ($lowlinks[$nodeId] -eq $indices[$nodeId]) {
            $component = [List[string]]::new()
            do {
                $w = $stack.Pop()
                $onStack[$w] = $false
                $component.Add($w)
            } while ($w -ne $nodeId)
            
            if ($component.Count -gt 1) {
                # Found a strongly connected component (cycle)
                $this.DetectedCycles.Add([PSCustomObject]@{
                    Type = [CircularityType]::Complex
                    Nodes = $component.ToArray()
                    Size = $component.Count
                    Languages = @($component | ForEach-Object { $this.Graph.Nodes[$_].Language } | Sort-Object -Unique)
                    Severity = if ($component.Count -gt 3) { "High" } else { "Medium" }
                })
            }
        }
    }
    
    [void] DetectComplexCycles() {
        # Additional detection for complex dependency patterns
        # Implementation would include more sophisticated cycle detection algorithms
    }
}

# Dependency visualization utilities
class DependencyVisualizer {
    [DependencyGraph] $Graph
    [hashtable] $VisualizationOptions
    
    DependencyVisualizer([DependencyGraph] $graph) {
        $this.Graph = $graph
        $this.VisualizationOptions = @{
            Format = "Mermaid"
            ShowCrossLanguageOnly = $false
            GroupByLanguage = $true
            HighlightCycles = $true
            MaxNodes = 100
        }
    }
    
    [string] GenerateVisualization([string] $format = "Mermaid") {
        switch ($format.ToLower()) {
            "mermaid" { return $this.GenerateMermaidDiagram() }
            "dot" { return $this.GenerateDotDiagram() }
            "json" { return $this.GenerateJsonGraph() }
            default { return $this.GenerateMermaidDiagram() }
        }
        # Explicit return to satisfy PowerShell compiler
        return $this.GenerateMermaidDiagram()
    }
    
    [string] GenerateMermaidDiagram() {
        $sb = [System.Text.StringBuilder]::new()
        $sb.AppendLine("graph TD") | Out-Null
        
        # Add nodes grouped by language
        $languageColors = @{
            "PowerShell" = "fill:#012456,stroke:#fff,color:#fff"
            "Python" = "fill:#3776ab,stroke:#fff,color:#fff"
            "CSharp" = "fill:#239120,stroke:#fff,color:#fff"
            "JavaScript" = "fill:#f7df1e,stroke:#333,color:#333"
        }
        
        foreach ($langPair in $this.Graph.LanguageStats.GetEnumerator()) {
            $language = $langPair.Key
            $sb.AppendLine("    subgraph $language") | Out-Null
            
            $languageNodes = $this.Graph.Nodes.Values | Where-Object { $_.Language -eq $language }
            foreach ($node in $languageNodes) {
                $nodeStyle = if ($languageColors.ContainsKey($language)) { $languageColors[$language] } else { "" }
                $sb.AppendLine("        $($node.Id)[$($node.Name)]") | Out-Null
                if ($nodeStyle) {
                    $sb.AppendLine("        style $($node.Id) $nodeStyle") | Out-Null
                }
            }
            
            $sb.AppendLine("    end") | Out-Null
        }
        
        # Add references
        foreach ($reference in $this.Graph.References) {
            $style = if ($reference.SourceLanguage -ne $reference.TargetLanguage) { "stroke:#ff6b6b,stroke-width:3px" } else { "" }
            $sb.AppendLine("    $($reference.SourceNodeId) --> $($reference.TargetNodeId)") | Out-Null
            if ($style -and $reference.SourceLanguage -ne $reference.TargetLanguage) {
                $sb.AppendLine("    linkStyle $(($this.Graph.References.IndexOf($reference))) $style") | Out-Null
            }
        }
        
        return $sb.ToString()
    }
    
    [string] GenerateDotDiagram() {
        # DOT format for Graphviz
        $sb = [System.Text.StringBuilder]::new()
        $sb.AppendLine("digraph DependencyGraph {") | Out-Null
        $sb.AppendLine("    rankdir=TD;") | Out-Null
        
        # Add nodes
        foreach ($node in $this.Graph.Nodes.Values) {
            $color = switch ($node.Language) {
                "PowerShell" { "lightblue" }
                "Python" { "lightgreen" }
                "CSharp" { "lightyellow" }
                "JavaScript" { "lightcoral" }
                default { "lightgray" }
            }
            $sb.AppendLine("    `"$($node.Id)`" [label=`"$($node.Name)`", fillcolor=$color, style=filled];") | Out-Null
        }
        
        # Add edges
        foreach ($reference in $this.Graph.References) {
            $style = if ($reference.SourceLanguage -ne $reference.TargetLanguage) { ", color=red, penwidth=2" } else { "" }
            $sb.AppendLine("    `"$($reference.SourceNodeId)`" -> `"$($reference.TargetNodeId)`"$style;") | Out-Null
        }
        
        $sb.AppendLine("}") | Out-Null
        return $sb.ToString()
    }
    
    [string] GenerateJsonGraph() {
        $graphData = @{
            nodes = @($this.Graph.Nodes.Values | ForEach-Object {
                @{
                    id = $_.Id
                    name = $_.Name
                    language = $_.Language
                    type = $_.Type.ToString()
                    namespace = $_.Namespace
                    metrics = $_.Metrics
                }
            })
            links = @($this.Graph.References | ForEach-Object {
                @{
                    source = $_.SourceNodeId
                    target = $_.TargetNodeId
                    type = $_.Type.ToString()
                    sourceLanguage = $_.SourceLanguage
                    targetLanguage = $_.TargetLanguage
                    confidence = $_.Confidence
                }
            })
            metadata = @{
                totalNodes = $this.Graph.Metrics.TotalNodes
                totalReferences = $this.Graph.Metrics.TotalReferences
                crossLanguageReferences = $this.Graph.Metrics.CrossLanguageReferences
                languages = @($this.Graph.LanguageStats.Keys)
                generated = Get-Date
            }
        }
        
        return $graphData | ConvertTo-Json -Depth 10
    }
}

# Main dependency mapping functions
function Resolve-CrossLanguageReferences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $LanguageGraphs,
        
        [Parameter(Mandatory = $false)]
        [string[]] $ReferenceTypes = @("Import", "Call", "Inheritance", "DataFlow")
    )
    
    Write-CPGDebug "Resolving cross-language references for $($LanguageGraphs.Count) languages"
    
    try {
        $resolver = [CrossLanguageReferenceResolver]::new($LanguageGraphs)
        $dependencyGraph = $resolver.ResolveAllReferences()
        
        Write-CPGDebug "Successfully resolved $($dependencyGraph.References.Count) cross-language references"
        
        return [PSCustomObject]@{
            DependencyGraph = $dependencyGraph
            UnresolvedReferences = $resolver.UnresolvedReferences
            Success = $true
        }
    }
    catch {
        Write-CPGDebug "Failed to resolve cross-language references: $($_.Exception.Message)" "Error"
        return [PSCustomObject]@{
            DependencyGraph = $null
            UnresolvedReferences = @()
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Track-ImportExport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $LanguageGraphs,
        
        [Parameter(Mandatory = $false)]
        [switch] $IncludeInternal
    )
    
    Write-CPGDebug "Tracking import/export relationships"
    
    $importExportMap = @{
        Exports = @{}
        Imports = @{}
        CrossLanguageLinks = @()
    }
    
    foreach ($langPair in $LanguageGraphs.GetEnumerator()) {
        $language = $langPair.Key
        $graph = $langPair.Value
        
        $importExportMap.Exports[$language] = @()
        $importExportMap.Imports[$language] = @()
        
        if ($graph.Nodes) {
            foreach ($node in $graph.Nodes.Values) {
                # Identify export nodes
                if ($node.Type -eq [UnifiedNodeType]::ModuleDefinition -or 
                    $node.Type -eq [UnifiedNodeType]::ClassDefinition -or
                    $node.Type -eq [UnifiedNodeType]::FunctionDefinition) {
                    $importExportMap.Exports[$language] += $node
                }
                
                # Identify import nodes
                if ($node.Type -eq [UnifiedNodeType]::ImportStatement) {
                    $importExportMap.Imports[$language] += $node
                }
            }
        }
    }
    
    Write-CPGDebug "Tracked exports: $($importExportMap.Exports.Values.Count) imports: $($importExportMap.Imports.Values.Count)"
    
    return $importExportMap
}

function Generate-DependencyGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [DependencyGraph] $DependencyGraph,
        
        [Parameter(Mandatory = $false)]
        [string] $Format = "Mermaid",
        
        [Parameter(Mandatory = $false)]
        [string] $OutputPath,
        
        [Parameter(Mandatory = $false)]
        [switch] $ShowCrossLanguageOnly
    )
    
    Write-CPGDebug "Generating dependency graph visualization in $Format format"
    
    $visualizer = [DependencyVisualizer]::new($DependencyGraph)
    $visualizer.VisualizationOptions.ShowCrossLanguageOnly = $ShowCrossLanguageOnly.IsPresent
    
    $diagram = $visualizer.GenerateVisualization($Format)
    
    if ($OutputPath) {
        $diagram | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-CPGDebug "Dependency graph saved to: $OutputPath"
    }
    
    return $diagram
}

function Detect-CircularDependencies {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [DependencyGraph] $DependencyGraph,
        
        [Parameter(Mandatory = $false)]
        [switch] $IncludeSelfReferences
    )
    
    Write-CPGDebug "Detecting circular dependencies"
    
    $detector = [CircularDependencyDetector]::new($DependencyGraph)
    $cycles = $detector.DetectAllCycles()
    
    # Filter self-references if not requested
    if (-not $IncludeSelfReferences.IsPresent) {
        $cycles = $cycles | Where-Object { $_.Nodes.Count -gt 1 }
    }
    
    Write-CPGDebug "Found $($cycles.Count) circular dependencies"
    
    return $cycles
}

function Export-DependencyReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [DependencyGraph] $DependencyGraph,
        
        [Parameter(Mandatory = $true)]
        [string] $OutputPath,
        
        [Parameter(Mandatory = $false)]
        [string] $Format = "Html"
    )
    
    Write-CPGDebug "Exporting dependency report to: $OutputPath"
    
    $report = @{
        Summary = @{
            TotalNodes = $DependencyGraph.Nodes.Count
            TotalReferences = $DependencyGraph.References.Count
            CrossLanguageReferences = $DependencyGraph.Metrics.CrossLanguageReferences
            Languages = @($DependencyGraph.LanguageStats.Keys)
            CircularDependencies = $DependencyGraph.CircularDependencies.Count
            GraphDensity = $DependencyGraph.Metrics.Density
        }
        LanguageStats = $DependencyGraph.LanguageStats
        CircularDependencies = $DependencyGraph.CircularDependencies
        TopNodes = $DependencyGraph.Nodes.Values | 
                   Sort-Object { $_.Metrics.TotalDegree } -Descending | 
                   Select-Object -First 10
        CrossLanguageReferences = $DependencyGraph.References | 
                                  Where-Object { $_.SourceLanguage -ne $_.TargetLanguage }
    }
    
    switch ($Format.ToLower()) {
        "json" {
            $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        "html" {
            $html = $this.GenerateHtmlReport($report)
            $html | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        default {
            $report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        }
    }
    
    Write-CPGDebug "Dependency report exported successfully"
    
    return $report
}

# Debug logging function
function Write-CPGDebug {
    param(
        [string] $Message,
        [string] $Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] [DependencyMaps] $Message"
    
    switch ($Level) {
        "Error" { Write-Error $logMessage }
        "Warning" { Write-Warning $logMessage }
        default { Write-Verbose $logMessage -Verbose }
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Resolve-CrossLanguageReferences',
    'Track-ImportExport',
    'Generate-DependencyGraph',
    'Detect-CircularDependencies',
    'Export-DependencyReport'
) -Variable @() -Alias @()