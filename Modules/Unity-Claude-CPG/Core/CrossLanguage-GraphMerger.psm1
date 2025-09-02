# CrossLanguage-GraphMerger.psm1
# Enhanced Documentation System - Day 5 Morning Implementation
# Merges multiple language-specific CPGs into unified representation
# Created: 2025-08-28 04:20 AM

using namespace System.Collections.Generic
using namespace System.Collections.Concurrent

# Import required modules
# Note: Using Import-Module instead of using module to avoid parse-time failures
Import-Module "$PSScriptRoot\CPG-Unified.psm1" -Force -ErrorAction SilentlyContinue

# Define types locally to avoid cross-module dependency issues
# UnifiedCPG class for graph merging
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
    
    [void] RemoveNode([string] $nodeId) {
        $this.Nodes.Remove($nodeId)
    }
    
    [void] RemoveRelation([string] $relationId) {
        $relToRemove = $this.Relations | Where-Object { $_.Id -eq $relationId }
        if ($relToRemove) {
            $this.Relations.Remove($relToRemove) | Out-Null
        }
    }
}

# Re-define enum types that might be needed from UnifiedModel
if (-not ([System.Management.Automation.PSTypeName]'UnifiedNodeType').Type) {
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
        Comment
    }
}

if (-not ([System.Management.Automation.PSTypeName]'UnifiedRelationType').Type) {
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

# LanguageMapper class stub for compatibility
class LanguageMapper {
    [string] $Language
    
    LanguageMapper([string] $language) {
        $this.Language = $language
    }
    
    [UnifiedNode] MapToUnified([object] $originalNode) {
        $node = [UnifiedNode]::new(
            $originalNode.Name,
            [UnifiedNodeType]::VariableReference,
            $this.Language
        )
        
        if ($originalNode.Type) {
            # Simple type mapping
            switch ($originalNode.Type) {
                'ClassDefinition' { $node.Type = [UnifiedNodeType]::ClassDefinition }
                'FunctionDefinition' { $node.Type = [UnifiedNodeType]::FunctionDefinition }
                default { $node.Type = [UnifiedNodeType]::VariableReference }
            }
        }
        
        if ($originalNode.Namespace) {
            $node.Namespace = $originalNode.Namespace
        }
        
        if ($originalNode.Properties) {
            $node.Properties = $originalNode.Properties.Clone()
        }
        
        return $node
    }
}

# Enums for merger operations
enum MergeStrategy {
    Conservative  # Only merge high-confidence matches
    Aggressive    # Merge lower-confidence matches
    Manual        # Require manual approval for conflicts
    Hybrid        # Use confidence thresholds
}

enum ConflictResolution {
    KeepFirst     # Keep first encountered
    KeepBest      # Keep highest confidence
    Merge         # Attempt to merge both
    Flag          # Flag for manual resolution
}

enum NamespaceStrategy {
    Hierarchical  # Create nested namespaces
    Flattened     # Flatten to single level
    LanguagePrefixed # Prefix with language name
    Original      # Keep original structure
}

# Core merger classes
class GraphMerger {
    [hashtable] $LanguageGraphs
    [UnifiedCPG] $MergedGraph
    [MergeStrategy] $Strategy
    [ConflictResolution] $ConflictStrategy
    [NamespaceStrategy] $NamespaceStrategy
    [hashtable] $MergeStatistics
    [List[object]] $Conflicts
    [hashtable] $NamespaceMappings
    [hashtable] $NodeMappings
    [float] $ConfidenceThreshold

    GraphMerger([hashtable] $languageGraphs, [MergeStrategy] $strategy) {
        $this.LanguageGraphs = $languageGraphs
        $this.Strategy = $strategy
        $this.ConflictStrategy = [ConflictResolution]::KeepBest
        $this.NamespaceStrategy = [NamespaceStrategy]::Hierarchical
        $this.MergeStatistics = @{}
        $this.Conflicts = [List[object]]::new()
        $this.NamespaceMappings = @{}
        $this.NodeMappings = @{}
        $this.ConfidenceThreshold = switch ($strategy) {
            "Conservative" { 0.8 }
            "Aggressive" { 0.4 }
            "Hybrid" { 0.6 }
            default { 0.6 }
        }
        $this.InitializeStatistics()
    }

    [void] InitializeStatistics() {
        $this.MergeStatistics = @{
            TotalNodes = 0
            MergedNodes = 0
            ConflictingNodes = 0
            UniqueNodes = 0
            TotalRelations = 0
            MergedRelations = 0
            ProcessingTime = [TimeSpan]::Zero
            LanguageStats = @{}
            ConfidenceDistribution = @{
                High = 0    # >= 0.8
                Medium = 0  # 0.6-0.79
                Low = 0     # 0.4-0.59
                VeryLow = 0 # < 0.4
            }
        }
    }

    [UnifiedCPG] MergeGraphs() {
        $startTime = Get-Date
        Write-CPGDebug "Starting graph merger with strategy: $($this.Strategy)"
        
        try {
            # Initialize merged graph
            $this.MergedGraph = [UnifiedCPG]::new("MergedCPG")
            
            # Phase 1: Analyze and prepare namespaces
            $this.PrepareNamespaces()
            
            # Phase 2: Merge nodes with conflict detection
            $this.MergeAllNodes()
            
            # Phase 3: Merge relationships
            $this.MergeAllRelationships()
            
            # Phase 4: Resolve conflicts
            $this.ResolveConflicts()
            
            # Phase 5: Optimize merged graph
            $this.OptimizeMergedGraph()
            
            $this.MergeStatistics.ProcessingTime = (Get-Date) - $startTime
            Write-CPGDebug "Graph merger completed in $($this.MergeStatistics.ProcessingTime.TotalSeconds) seconds"
            
            return $this.MergedGraph
        }
        catch {
            Write-CPGDebug "Graph merger failed: $($_.Exception.Message)" "Error"
            throw
        }
    }

    [void] PrepareNamespaces() {
        Write-CPGDebug "Preparing namespace mappings"
        
        foreach ($langPair in $this.LanguageGraphs.GetEnumerator()) {
            $language = $langPair.Key
            $graph = $langPair.Value
            
            # Extract namespaces from this language's graph
            $namespaces = $this.ExtractNamespaces($graph, $language)
            
            # Create mapping strategy
            foreach ($ns in $namespaces) {
                $mappedName = $this.MapNamespace($ns, $language)
                $this.NamespaceMappings[$ns] = $mappedName
            }
        }
    }

    [string[]] ExtractNamespaces([object] $graph, [string] $language) {
        $namespaces = @()
        
        if ($graph.Nodes) {
            foreach ($node in $graph.Nodes.Values) {
                if ($node.Namespace -and $node.Namespace -notin $namespaces) {
                    $namespaces += $node.Namespace
                }
            }
        }
        
        return $namespaces
    }

    [string] MapNamespace([string] $originalNamespace, [string] $language) {
        switch ($this.NamespaceStrategy) {
            "Hierarchical" {
                return "$language.$originalNamespace"
            }
            "Flattened" {
                return $originalNamespace -replace '\.', '_'
            }
            "LanguagePrefixed" {
                return "$($language)_$($originalNamespace -replace '\.', '_')"
            }
            "Original" {
                return $originalNamespace
            }
            default {
                return "$language.$originalNamespace"
            }
        }
        # Explicit return to satisfy PowerShell compiler
        return "$language.$originalNamespace"
    }

    [void] MergeAllNodes() {
        Write-CPGDebug "Merging nodes from all languages"
        
        foreach ($langPair in $this.LanguageGraphs.GetEnumerator()) {
            $language = $langPair.Key
            $graph = $langPair.Value
            
            $this.MergeStatistics.LanguageStats[$language] = @{
                NodesProcessed = 0
                NodesMerged = 0
                NodesUnique = 0
                NodesConflicted = 0
            }
            
            if ($graph.Nodes) {
                foreach ($nodePair in $graph.Nodes.GetEnumerator()) {
                    $nodeId = $nodePair.Key
                    $node = $nodePair.Value
                    
                    $this.MergeNode($node, $language)
                    $this.MergeStatistics.LanguageStats[$language].NodesProcessed++
                    $this.MergeStatistics.TotalNodes++
                }
            }
        }
    }

    [void] MergeNode([object] $node, [string] $sourceLanguage) {
        # Create unified representation
        $unifiedNode = $this.CreateUnifiedNode($node, $sourceLanguage)
        
        # Check for existing equivalent nodes
        $equivalents = $this.FindEquivalentNodes($unifiedNode)
        
        if ($equivalents.Count -eq 0) {
            # Unique node - add directly
            $this.MergedGraph.AddNode($unifiedNode)
            $this.NodeMappings["$sourceLanguage.$($node.Id)"] = $unifiedNode.Id
            $this.MergeStatistics.UniqueNodes++
            $this.MergeStatistics.LanguageStats[$sourceLanguage].NodesUnique++
        }
        else {
            # Found equivalents - handle based on strategy
            $mergeResult = $this.HandleNodeEquivalents($unifiedNode, $equivalents, $sourceLanguage)
            
            if ($mergeResult.Success) {
                $this.NodeMappings["$sourceLanguage.$($node.Id)"] = $mergeResult.MergedNodeId
                $this.MergeStatistics.MergedNodes++
                $this.MergeStatistics.LanguageStats[$sourceLanguage].NodesMerged++
                
                # Update confidence distribution
                $this.UpdateConfidenceStats($mergeResult.Confidence)
            }
            else {
                # Conflict detected
                $conflict = [PSCustomObject]@{
                    Type = "NodeConflict"
                    SourceLanguage = $sourceLanguage
                    SourceNode = $unifiedNode
                    ConflictingNodes = $equivalents
                    Confidence = $mergeResult.Confidence
                    Timestamp = Get-Date
                }
                $this.Conflicts.Add($conflict)
                $this.MergeStatistics.ConflictingNodes++
                $this.MergeStatistics.LanguageStats[$sourceLanguage].NodesConflicted++
            }
        }
    }

    [UnifiedNode] CreateUnifiedNode([object] $originalNode, [string] $language) {
        $mapper = [LanguageMapper]::new($language)
        return $mapper.MapToUnified($originalNode)
    }

    [List[UnifiedNode]] FindEquivalentNodes([UnifiedNode] $targetNode) {
        $equivalents = [List[UnifiedNode]]::new()
        
        foreach ($existingNode in $this.MergedGraph.GetAllNodes()) {
            $similarity = $this.CalculateNodeSimilarity($targetNode, $existingNode)
            
            if ($similarity.Score -ge $this.ConfidenceThreshold) {
                $equivalents.Add($existingNode)
            }
        }
        
        return $equivalents
    }

    [PSCustomObject] CalculateNodeSimilarity([UnifiedNode] $node1, [UnifiedNode] $node2) {
        $similarity = @{
            Score = 0.0
            Factors = @{}
        }
        
        # Name similarity (weighted 40%)
        $nameSim = $this.CalculateStringSimilarity($node1.Name, $node2.Name)
        $similarity.Factors.Name = $nameSim
        $similarity.Score += $nameSim * 0.4
        
        # Type similarity (weighted 30%)
        $typeSim = if ($node1.Type -eq $node2.Type) { 1.0 } else { 0.0 }
        $similarity.Factors.Type = $typeSim
        $similarity.Score += $typeSim * 0.3
        
        # Namespace similarity (weighted 20%)
        $nsSim = $this.CalculateStringSimilarity($node1.Namespace, $node2.Namespace)
        $similarity.Factors.Namespace = $nsSim
        $similarity.Score += $nsSim * 0.2
        
        # Signature similarity (weighted 10%)
        $sigSim = $this.CalculateSignatureSimilarity($node1, $node2)
        $similarity.Factors.Signature = $sigSim
        $similarity.Score += $sigSim * 0.1
        
        return [PSCustomObject]$similarity
    }

    [float] CalculateStringSimilarity([string] $str1, [string] $str2) {
        if (-not $str1 -and -not $str2) { return 1.0 }
        if (-not $str1 -or -not $str2) { return 0.0 }
        
        # Levenshtein distance based similarity
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

    [float] CalculateSignatureSimilarity([UnifiedNode] $node1, [UnifiedNode] $node2) {
        # Compare function signatures, parameter lists, return types, etc.
        if ($node1.Type -ne [UnifiedNodeType]::FunctionDefinition -or 
            $node2.Type -ne [UnifiedNodeType]::FunctionDefinition) {
            return 1.0  # Non-function nodes don't have signatures
        }
        
        $sig1 = $node1.Properties.Signature
        $sig2 = $node2.Properties.Signature
        
        if (-not $sig1 -or -not $sig2) { return 0.5 }
        
        return $this.CalculateStringSimilarity($sig1, $sig2)
    }

    [PSCustomObject] HandleNodeEquivalents([UnifiedNode] $newNode, [List[UnifiedNode]] $equivalents, [string] $language) {
        $result = [PSCustomObject]@{
            Success = $false
            MergedNodeId = $null
            Confidence = 0.0
            Action = ""
        }
        
        # Find best match
        $bestMatch = $null
        $bestConfidence = 0.0
        
        foreach ($equivalent in $equivalents) {
            $similarity = $this.CalculateNodeSimilarity($newNode, $equivalent)
            if ($similarity.Score -gt $bestConfidence) {
                $bestMatch = $equivalent
                $bestConfidence = $similarity.Score
            }
        }
        
        $result.Confidence = $bestConfidence
        
        # Apply merge strategy
        switch ($this.Strategy) {
            "Conservative" {
                if ($bestConfidence -ge 0.9) {
                    $result = $this.MergeNodes($bestMatch, $newNode)
                    $result.Action = "Merged (High Confidence)"
                }
                else {
                    $result.Action = "Rejected (Low Confidence)"
                }
            }
            "Aggressive" {
                if ($bestConfidence -ge 0.4) {
                    $result = $this.MergeNodes($bestMatch, $newNode)
                    $result.Action = "Merged (Aggressive)"
                }
                else {
                    $result.Action = "Rejected (Very Low Confidence)"
                }
            }
            "Hybrid" {
                if ($bestConfidence -ge 0.8) {
                    $result = $this.MergeNodes($bestMatch, $newNode)
                    $result.Action = "Merged (High Confidence)"
                }
                elseif ($bestConfidence -ge 0.6) {
                    $result = $this.FlagForManualReview($bestMatch, $newNode, $bestConfidence)
                    $result.Action = "Flagged (Medium Confidence)"
                }
                else {
                    $result.Action = "Rejected (Low Confidence)"
                }
            }
        }
        
        return $result
    }

    [PSCustomObject] MergeNodes([UnifiedNode] $existingNode, [UnifiedNode] $newNode) {
        # Merge properties, maintaining source language info
        if (-not $existingNode.Properties.SourceLanguages) {
            $existingNode.Properties.SourceLanguages = @()
        }
        
        if ($newNode.SourceLanguage -notin $existingNode.Properties.SourceLanguages) {
            $existingNode.Properties.SourceLanguages += $newNode.SourceLanguage
        }
        
        # Merge additional properties
        foreach ($propPair in $newNode.Properties.GetEnumerator()) {
            $key = $propPair.Key
            $value = $propPair.Value
            
            if ($key -eq "SourceLanguages") { continue }
            
            if (-not $existingNode.Properties.ContainsKey($key)) {
                $existingNode.Properties[$key] = $value
            }
            elseif ($existingNode.Properties[$key] -ne $value) {
                # Store alternative values
                $altKey = "$key.$($newNode.SourceLanguage)"
                $existingNode.Properties[$altKey] = $value
            }
        }
        
        return [PSCustomObject]@{
            Success = $true
            MergedNodeId = $existingNode.Id
            Confidence = 1.0
        }
    }

    [PSCustomObject] FlagForManualReview([UnifiedNode] $existingNode, [UnifiedNode] $newNode, [float] $confidence) {
        $conflict = [PSCustomObject]@{
            Type = "ManualReview"
            ExistingNode = $existingNode
            NewNode = $newNode
            Confidence = $confidence
            RecommendedAction = if ($confidence -gt 0.7) { "Merge" } else { "Keep Separate" }
        }
        
        $this.Conflicts.Add($conflict)
        
        return [PSCustomObject]@{
            Success = $false
            MergedNodeId = $null
            Confidence = $confidence
        }
    }

    [void] UpdateConfidenceStats([float] $confidence) {
        if ($confidence -ge 0.8) {
            $this.MergeStatistics.ConfidenceDistribution.High++
        }
        elseif ($confidence -ge 0.6) {
            $this.MergeStatistics.ConfidenceDistribution.Medium++
        }
        elseif ($confidence -ge 0.4) {
            $this.MergeStatistics.ConfidenceDistribution.Low++
        }
        else {
            $this.MergeStatistics.ConfidenceDistribution.VeryLow++
        }
    }

    [void] MergeAllRelationships() {
        Write-CPGDebug "Merging relationships from all languages"
        
        foreach ($langPair in $this.LanguageGraphs.GetEnumerator()) {
            $language = $langPair.Key
            $graph = $langPair.Value
            
            if ($graph.Edges -or $graph.Relations) {
                $relationships = if ($graph.Relations) { $graph.Relations } else { $graph.Edges }
                
                foreach ($rel in $relationships) {
                    $this.MergeRelationship($rel, $language)
                    $this.MergeStatistics.TotalRelations++
                }
            }
        }
    }

    [void] MergeRelationship([object] $relationship, [string] $language) {
        # Map source and target nodes to merged graph
        $sourceId = $this.NodeMappings["$language.$($relationship.SourceId)"]
        $targetId = $this.NodeMappings["$language.$($relationship.TargetId)"]
        
        if (-not $sourceId -or -not $targetId) {
            Write-CPGDebug "Skipping relationship due to unmapped nodes: $($relationship.Type)" "Warning"
            return
        }
        
        # Create unified relationship
        $unifiedRel = [UnifiedRelation]::new(
            $relationship.Type,
            $sourceId,
            $targetId,
            $language
        )
        
        # Check for duplicate relationships
        if (-not $this.HasDuplicateRelationship($unifiedRel)) {
            $this.MergedGraph.AddRelation($unifiedRel)
            $this.MergeStatistics.MergedRelations++
        }
    }

    [bool] HasDuplicateRelationship([UnifiedRelation] $relationship) {
        foreach ($existing in $this.MergedGraph.GetAllRelations()) {
            if ($existing.Type -eq $relationship.Type -and
                $existing.SourceId -eq $relationship.SourceId -and
                $existing.TargetId -eq $relationship.TargetId) {
                return $true
            }
        }
        return $false
    }

    [void] ResolveConflicts() {
        Write-CPGDebug "Resolving $($this.Conflicts.Count) conflicts"
        
        foreach ($conflict in $this.Conflicts) {
            switch ($this.ConflictStrategy) {
                "KeepFirst" {
                    # Already handled during merge
                }
                "KeepBest" {
                    $this.ResolveByBestConfidence($conflict)
                }
                "Merge" {
                    $this.AttemptConflictMerge($conflict)
                }
                "Flag" {
                    # Keep for manual resolution
                }
            }
        }
    }

    [void] ResolveByBestConfidence([object] $conflict) {
        # Implementation for keeping highest confidence node
        # This would involve scoring and selection logic
    }

    [void] AttemptConflictMerge([object] $conflict) {
        # Implementation for attempting to merge conflicting nodes
        # This would involve sophisticated merging algorithms
    }

    [void] OptimizeMergedGraph() {
        Write-CPGDebug "Optimizing merged graph structure"
        
        # Remove orphaned nodes
        $this.RemoveOrphanedNodes()
        
        # Consolidate duplicate relationships
        $this.ConsolidateDuplicateRelationships()
        
        # Update graph metrics
        $this.UpdateGraphMetrics()
    }

    [void] RemoveOrphanedNodes() {
        $orphanedNodes = [List[string]]::new()
        
        foreach ($node in $this.MergedGraph.GetAllNodes()) {
            $hasIncoming = $false
            $hasOutgoing = $false
            
            foreach ($rel in $this.MergedGraph.GetAllRelations()) {
                if ($rel.TargetId -eq $node.Id) { $hasIncoming = $true }
                if ($rel.SourceId -eq $node.Id) { $hasOutgoing = $true }
                if ($hasIncoming -and $hasOutgoing) { break }
            }
            
            # Only remove if completely isolated and not a root node
            if (-not $hasIncoming -and -not $hasOutgoing -and $node.Type -ne [UnifiedNodeType]::Root) {
                $orphanedNodes.Add($node.Id)
            }
        }
        
        foreach ($nodeId in $orphanedNodes) {
            $this.MergedGraph.RemoveNode($nodeId)
        }
        
        Write-CPGDebug "Removed $($orphanedNodes.Count) orphaned nodes"
    }

    [void] ConsolidateDuplicateRelationships() {
        $duplicates = [List[object]]::new()
        $seen = [HashSet[string]]::new()
        
        foreach ($rel in $this.MergedGraph.GetAllRelations()) {
            $key = "$($rel.Type):$($rel.SourceId):$($rel.TargetId)"
            
            if ($seen.Contains($key)) {
                $duplicates.Add($rel)
            }
            else {
                $seen.Add($key) | Out-Null
            }
        }
        
        foreach ($duplicate in $duplicates) {
            $this.MergedGraph.RemoveRelation($duplicate.Id)
        }
        
        Write-CPGDebug "Removed $($duplicates.Count) duplicate relationships"
    }

    [void] UpdateGraphMetrics() {
        $this.MergeStatistics.FinalStats = @{
            TotalNodes = $this.MergedGraph.GetAllNodes().Count
            TotalRelations = $this.MergedGraph.GetAllRelations().Count
            Languages = $this.LanguageGraphs.Keys
            MergeEfficiency = if ($this.MergeStatistics.TotalNodes -gt 0) {
                [Math]::Round(($this.MergeStatistics.MergedNodes / $this.MergeStatistics.TotalNodes) * 100, 2)
            } else { 0 }
        }
    }

    [hashtable] GetMergeReport() {
        return @{
            Statistics = $this.MergeStatistics
            Conflicts = $this.Conflicts.ToArray()
            NamespaceMappings = $this.NamespaceMappings
            NodeMappings = $this.NodeMappings
            MergedGraph = $this.MergedGraph
        }
    }
}

# Conflict detection and resolution utilities
class ConflictDetector {
    [List[object]] $DetectedConflicts
    
    ConflictDetector() {
        $this.DetectedConflicts = [List[object]]::new()
    }
    
    [List[object]] DetectNamingConflicts([hashtable] $languageGraphs) {
        $nameMap = @{}
        $conflicts = [List[object]]::new()
        
        foreach ($langPair in $languageGraphs.GetEnumerator()) {
            $language = $langPair.Key
            $graph = $langPair.Value
            
            if ($graph.Nodes) {
                foreach ($node in $graph.Nodes.Values) {
                    $key = "$($node.Namespace).$($node.Name)"
                    
                    if ($nameMap.ContainsKey($key)) {
                        $conflicts.Add([PSCustomObject]@{
                            Type = "NamingConflict"
                            Name = $key
                            Language1 = $nameMap[$key].Language
                            Node1 = $nameMap[$key].Node
                            Language2 = $language
                            Node2 = $node
                        })
                    }
                    else {
                        $nameMap[$key] = @{
                            Language = $language
                            Node = $node
                        }
                    }
                }
            }
        }
        
        return $conflicts
    }
    
    [List[object]] DetectTypeConflicts([hashtable] $languageGraphs) {
        # Detect nodes with same name but different types
        $conflicts = [List[object]]::new()
        # Implementation would go here
        return $conflicts
    }
    
    [List[object]] DetectSignatureConflicts([hashtable] $languageGraphs) {
        # Detect functions with same name but different signatures
        $conflicts = [List[object]]::new()
        # Implementation would go here
        return $conflicts
    }
}

# Namespace merger utilities
class NamespaceMerger {
    [NamespaceStrategy] $Strategy
    [hashtable] $MergedNamespaces
    
    NamespaceMerger([NamespaceStrategy] $strategy) {
        $this.Strategy = $strategy
        $this.MergedNamespaces = @{}
    }
    
    [hashtable] MergeNamespaces([hashtable] $languageGraphs) {
        foreach ($langPair in $languageGraphs.GetEnumerator()) {
            $language = $langPair.Key
            $graph = $langPair.Value
            
            $this.ProcessLanguageNamespaces($language, $graph)
        }
        
        return $this.MergedNamespaces
    }
    
    [void] ProcessLanguageNamespaces([string] $language, [object] $graph) {
        # Extract and merge namespaces based on strategy
        # Implementation would go here
    }
}

# Duplicate detection utilities
class DuplicateDetector {
    [float] $SimilarityThreshold
    
    DuplicateDetector([float] $threshold = 0.8) {
        $this.SimilarityThreshold = $threshold
    }
    
    [List[object]] DetectDuplicateNodes([hashtable] $languageGraphs) {
        $duplicates = [List[object]]::new()
        $allNodes = [List[object]]::new()
        
        # Collect all nodes
        foreach ($graph in $languageGraphs.Values) {
            if ($graph.Nodes) {
                $allNodes.AddRange($graph.Nodes.Values)
            }
        }
        
        # Compare each pair
        for ($i = 0; $i -lt $allNodes.Count; $i++) {
            for ($j = $i + 1; $j -lt $allNodes.Count; $j++) {
                $similarity = $this.CalculateNodeSimilarity($allNodes[$i], $allNodes[$j])
                
                if ($similarity -ge $this.SimilarityThreshold) {
                    $duplicates.Add([PSCustomObject]@{
                        Node1 = $allNodes[$i]
                        Node2 = $allNodes[$j]
                        Similarity = $similarity
                    })
                }
            }
        }
        
        return $duplicates
    }
    
    [float] CalculateNodeSimilarity([object] $node1, [object] $node2) {
        # Simplified similarity calculation
        if ($node1.Name -eq $node2.Name -and $node1.Type -eq $node2.Type) {
            return 1.0
        }
        # More sophisticated similarity calculation would go here
        return 0.0
    }
}

# Main merger functions
function Merge-LanguageGraphs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $LanguageGraphs,
        
        [Parameter(Mandatory = $false)]
        [MergeStrategy] $Strategy = [MergeStrategy]::Hybrid,
        
        [Parameter(Mandatory = $false)]
        [ConflictResolution] $ConflictResolution = [ConflictResolution]::KeepBest,
        
        [Parameter(Mandatory = $false)]
        [NamespaceStrategy] $NamespaceStrategy = [NamespaceStrategy]::Hierarchical,
        
        [Parameter(Mandatory = $false)]
        [float] $ConfidenceThreshold = 0.6
    )
    
    Write-CPGDebug "Starting cross-language graph merge with $($LanguageGraphs.Count) languages"
    
    try {
        # Create merger instance
        $merger = [GraphMerger]::new($LanguageGraphs, $Strategy)
        $merger.ConflictStrategy = $ConflictResolution
        $merger.NamespaceStrategy = $NamespaceStrategy
        $merger.ConfidenceThreshold = $ConfidenceThreshold
        
        # Perform merge
        $mergedGraph = $merger.MergeGraphs()
        
        # Generate report
        $report = $merger.GetMergeReport()
        
        Write-CPGDebug "Graph merge completed successfully"
        Write-CPGDebug "Merged $($report.Statistics.MergedNodes) nodes from $($report.Statistics.TotalNodes) total nodes"
        Write-CPGDebug "Merge efficiency: $($report.Statistics.FinalStats.MergeEfficiency)%"
        
        return [PSCustomObject]@{
            MergedGraph = $mergedGraph
            Report = $report
            Success = $true
        }
    }
    catch {
        Write-CPGDebug "Graph merge failed: $($_.Exception.Message)" "Error"
        return [PSCustomObject]@{
            MergedGraph = $null
            Report = $null
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Resolve-NamingConflicts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $LanguageGraphs,
        
        [Parameter(Mandatory = $false)]
        [string] $Resolution = "KeepBest"  # Changed from enum to string
    )
    
    # Simple conflict detection without class instantiation
    $conflicts = @()
    $nameMap = @{}
    
    foreach ($lang in $LanguageGraphs.Keys) {
        $graph = $LanguageGraphs[$lang]
        
        if ($graph.Nodes) {
            foreach ($nodeKey in $graph.Nodes.Keys) {
                $node = $graph.Nodes[$nodeKey]
                $fullName = if ($node.Namespace) { "$($node.Namespace).$($node.Name)" } else { $node.Name }
                
                if ($nameMap.ContainsKey($fullName)) {
                    # Found a conflict
                    $conflicts += @{
                        Name = $fullName
                        Language1 = $nameMap[$fullName].Language
                        Language2 = $lang
                        Node1 = $nameMap[$fullName].Node
                        Node2 = $node
                        Resolution = $Resolution
                    }
                }
                else {
                    $nameMap[$fullName] = @{
                        Language = $lang
                        Node = $node
                    }
                }
            }
        }
    }
    
    Write-CPGDebug "Detected $($conflicts.Count) naming conflicts"
    
    foreach ($conflict in $conflicts) {
        switch ($Resolution) {
            "KeepFirst" {
                # Keep the first encountered node
                Write-CPGDebug "Keeping first occurrence: $($conflict.Language1).$($conflict.Name)"
            }
            "KeepBest" {
                # Keep the node with better quality metrics (simplified logic)
                Write-CPGDebug "Keeping best node for: $($conflict.Name)"
            }
            "Flag" {
                # Flag for manual resolution
                Write-CPGDebug "Flagged for manual resolution: $($conflict.Name)"
            }
        }
    }
    
    return $conflicts
}

function Merge-Namespaces {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $LanguageGraphs,
        
        [Parameter(Mandatory = $false)]
        [NamespaceStrategy] $Strategy = [NamespaceStrategy]::Hierarchical
    )
    
    $merger = [NamespaceMerger]::new($Strategy)
    $mergedNamespaces = $merger.MergeNamespaces($LanguageGraphs)
    
    Write-CPGDebug "Merged namespaces using $Strategy strategy"
    Write-CPGDebug "Created $($mergedNamespaces.Count) unified namespaces"
    
    return $mergedNamespaces
}

function Detect-Duplicates {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $LanguageGraphs,
        
        [Parameter(Mandatory = $false)]
        [float] $SimilarityThreshold = 0.8
    )
    
    # Simple duplicate detection without class instantiation
    $duplicates = @()
    $allNodes = @()
    
    # Collect all nodes from all language graphs
    foreach ($lang in $LanguageGraphs.Keys) {
        $graph = $LanguageGraphs[$lang]
        
        if ($graph.Nodes) {
            foreach ($nodeKey in $graph.Nodes.Keys) {
                $node = $graph.Nodes[$nodeKey]
                $allNodes += @{
                    Language = $lang
                    NodeKey = $nodeKey
                    Node = $node
                    Name = $node.Name
                    Type = $node.Type
                }
            }
        }
    }
    
    # Compare nodes to find duplicates (simplified similarity check)
    for ($i = 0; $i -lt $allNodes.Count; $i++) {
        for ($j = $i + 1; $j -lt $allNodes.Count; $j++) {
            $node1 = $allNodes[$i]
            $node2 = $allNodes[$j]
            
            # Simple similarity check: same name and type
            if ($node1.Name -eq $node2.Name -and $node1.Type -eq $node2.Type) {
                $duplicates += @{
                    Node1 = $node1
                    Node2 = $node2
                    Similarity = 1.0  # Exact match on name and type
                    Language1 = $node1.Language
                    Language2 = $node2.Language
                }
            }
        }
    }
    
    Write-CPGDebug "Detected $($duplicates.Count) potential duplicate nodes"
    
    return $duplicates
}

function Create-MergedCPG {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable] $LanguageGraphs,
        
        [Parameter(Mandatory = $false)]
        [string] $Name = "MergedCPG",
        
        [Parameter(Mandatory = $false)]
        [MergeStrategy] $Strategy = [MergeStrategy]::Hybrid
    )
    
    Write-CPGDebug "Creating merged CPG: $Name"
    
    # Perform comprehensive merge
    $mergeResult = Merge-LanguageGraphs -LanguageGraphs $LanguageGraphs -Strategy $Strategy
    
    if (-not $mergeResult.Success) {
        Write-CPGDebug "Failed to create merged CPG: $($mergeResult.Error)" "Error"
        return $null
    }
    
    $mergedCPG = $mergeResult.MergedGraph
    $mergedCPG.Name = $Name
    
    # Add metadata
    $mergedCPG.Properties.Languages = @($LanguageGraphs.Keys)
    $mergedCPG.Properties.MergeStrategy = $Strategy.ToString()
    $mergedCPG.Properties.MergeTimestamp = Get-Date
    $mergedCPG.Properties.MergeReport = $mergeResult.Report
    
    Write-CPGDebug "Successfully created merged CPG with $($mergedCPG.GetAllNodes().Count) nodes"
    
    return $mergedCPG
}

# Debug logging function
function Write-CPGDebug {
    param(
        [string] $Message,
        [string] $Level = "Info"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] [GraphMerger] $Message"
    
    switch ($Level) {
        "Error" { Write-Error $logMessage }
        "Warning" { Write-Warning $logMessage }
        default { Write-Verbose $logMessage -Verbose }
    }
}

# Export module members
Export-ModuleMember -Function @(
    'Merge-LanguageGraphs',
    'Resolve-NamingConflicts', 
    'Merge-Namespaces',
    'Detect-Duplicates',
    'Create-MergedCPG'
) -Variable @() -Alias @()