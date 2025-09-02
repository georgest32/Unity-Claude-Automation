# Unity-Claude-CLIOrchestrator - Entity Context & Relationship Engine
# Phase 7 Day 1-2 Hours 5-8: Enhanced Entity Context Extraction
# Compatible with PowerShell 5.1 and Claude Code CLI 2025

#region Entity Extraction Patterns

$script:EntityPatterns = @{
    "FilePath" = @{
        Pattern = '(?:[A-Z]:\\|\.{1,2}\\|\/)[^<>:"|?*\r\n]*\.(?:ps1|psm1|psd1|cs|js|ts|json|xml|yml|yaml|txt|md|cfg|conf|ini|log)'
        Priority = "High"
        ValidationRequired = $true
    }
    "PowerShellCommand" = @{
        Pattern = '(?:^|\s)([A-Z][a-zA-Z]*-[A-Z][a-zA-Z0-9]*)'
        Priority = "High"
        ValidationRequired = $true
    }
    "ErrorMessage" = @{
        Pattern = '(?i)(?:error|exception|failure|critical)[:]\s*([^.\r\n]+)'
        Priority = "Critical" 
        ValidationRequired = $false
    }
    "Variable" = @{
        Pattern = '\$(?:script:|global:|local:)?[a-zA-Z_][a-zA-Z0-9_]*'
        Priority = "Medium"
        ValidationRequired = $false
    }
    "URL" = @{
        Pattern = 'https?://[^\s<>"]{2,}'
        Priority = "Medium"
        ValidationRequired = $true
    }
    "EmailAddress" = @{
        Pattern = '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'
        Priority = "Low"
        ValidationRequired = $false
    }
    "IPAddress" = @{
        Pattern = '(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)'
        Priority = "Medium"
        ValidationRequired = $false
    }
    "Port" = @{
        Pattern = '(?:port\s*[:=]?\s*|:)(\d{1,5})(?!\d)'
        Priority = "Low"
        ValidationRequired = $true
    }
}

# Entity relationship graph structure
$script:EntityGraph = @{
    Nodes = @{}
    Edges = @{}
    NodeCounter = 0
    LastUpdated = $null
}

# Temporal context tracking for command sequences
$script:TemporalContext = @{
    CommandSequences = @()
    LastCommandTime = $null
    SequenceThreshold = 5000  # milliseconds
}

#endregion

#region Entity Extraction Functions

function Extract-ContextEntities {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent
    )
    
    $extractionStart = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Phase 1: Joint span-based entity extraction (research-based enhancement)
    $spans = Get-TextSpans -Text $ResponseContent
    $allEntities = @()
    $entityRelationships = @()
    
    # Joint extraction approach - process all spans simultaneously to reduce error propagation
    foreach ($span in $spans) {
        $spanEntities = Invoke-JointEntityClassification -Span $span -FullText $ResponseContent
        
        foreach ($entity in $spanEntities) {
            # Enhanced entity with span-based context
            $enhancedEntity = @{
                Type = $entity.Type
                Value = $entity.Value.Trim()
                Position = $entity.Position
                Length = $entity.Length
                Priority = $entity.Priority
                SpanContext = $span
                SemanticContext = Get-SemanticContext -Entity $entity -FullText $ResponseContent
                ValidationRequired = $entity.ValidationRequired
                Confidence = $entity.Confidence
                ExtractedAt = Get-Date
                SpanScore = $entity.SpanScore
                RelationshipCandidates = @()
            }
            
            # Enhanced validation with contextual analysis
            if ($entity.ValidationRequired) {
                $enhancedEntity = Add-ContextualEntityValidation -Entity $enhancedEntity
            }
            
            $allEntities += $enhancedEntity
        }
    }
    
    # Phase 2: Cross-sentence and complex relationship extraction
    $entityRelationships = Build-EntityRelationshipGraph -Entities $allEntities
    
    # Phase 3: Build enhanced entity relationship graph with semantic analysis
    if ($allEntities.Count -gt 1) {
        Build-SemanticEntityRelationshipGraph -Entities $allEntities -Relationships $entityRelationships
    }
    
    $extractionStart.Stop()
    
    # Enhanced sorting with relationship and semantic scores
    $enhancedSortedEntities = $allEntities | Sort-Object @{
        Expression = { Get-EntityPriorityScore -Entity $_ -Relationships $entityRelationships }; Descending = $true
    }, Position
    
    return $enhancedSortedEntities
}

#endregion

#region Advanced Joint Extraction Functions (Research-Based)

function Get-TextSpans {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )
    
    $spans = @()
    $sentences = Split-TextIntoSentences -Text $Text
    
    foreach ($sentence in $sentences) {
        # Create overlapping spans for better context capture
        $words = $sentence.Text -split '\s+'
        
        for ($i = 0; $i -lt $words.Count; $i++) {
            # Single word spans
            $span = @{
                Text = $words[$i]
                StartPosition = $sentence.StartPosition + $sentence.Text.IndexOf($words[$i])
                EndPosition = $sentence.StartPosition + $sentence.Text.IndexOf($words[$i]) + $words[$i].Length
                Length = $words[$i].Length
                Type = "Single"
                SentenceContext = $sentence
            }
            $spans += $span
            
            # Multi-word spans (2-5 words) for better entity boundary detection
            for ($len = 2; $len -le [Math]::Min(5, $words.Count - $i); $len++) {
                $spanText = ($words[$i..($i + $len - 1)] -join ' ')
                $spanStart = $sentence.StartPosition + $sentence.Text.IndexOf($spanText)
                
                $multiSpan = @{
                    Text = $spanText
                    StartPosition = $spanStart
                    EndPosition = $spanStart + $spanText.Length
                    Length = $spanText.Length
                    Type = "Multi"
                    WordCount = $len
                    SentenceContext = $sentence
                }
                $spans += $multiSpan
            }
        }
    }
    
    return $spans
}

function Split-TextIntoSentences {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )
    
    # Enhanced sentence splitting with context preservation
    $sentencePattern = '(?<=[.!?])\s+(?=[A-Z])|(?<=\r?\n\r?\n)|(?<=:)\s+(?=[A-Z])'
    $sentences = $Text -split $sentencePattern
    
    $result = @()
    $position = 0
    
    foreach ($sentence in $sentences) {
        if (![string]::IsNullOrWhiteSpace($sentence)) {
            $cleanSentence = $sentence.Trim()
            $sentenceObj = @{
                Text = $cleanSentence
                StartPosition = $Text.IndexOf($cleanSentence, $position)
                Length = $cleanSentence.Length
                WordCount = ($cleanSentence -split '\s+').Count
            }
            $result += $sentenceObj
            $position = $sentenceObj.StartPosition + $sentenceObj.Length
        }
    }
    
    return $result
}

function Invoke-JointEntityClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Span,
        
        [Parameter(Mandatory = $true)]
        [string]$FullText
    )
    
    $entities = @()
    $spanText = $Span.Text
    
    # Joint classification - check all entity types simultaneously
    foreach ($entityType in $script:EntityPatterns.Keys) {
        $entityPattern = $script:EntityPatterns[$entityType]
        
        try {
            $regex = [regex]::new($entityPattern.Pattern, "IgnoreCase, CultureInvariant")
            $matches = $regex.Matches($spanText)
            
            foreach ($match in $matches) {
                # Calculate span-based confidence score
                $spanScore = Get-SpanConfidenceScore -Span $Span -Match $match -EntityType $entityType
                
                if ($spanScore -gt 0.3) {  # Threshold for span acceptance
                    $entity = @{
                        Type = $entityType
                        Value = $match.Value
                        Position = $Span.StartPosition + $match.Index
                        Length = $match.Length
                        Priority = $entityPattern.Priority
                        ValidationRequired = $entityPattern.ValidationRequired
                        Confidence = $spanScore
                        SpanScore = $spanScore
                        SpanType = $Span.Type
                    }
                    
                    $entities += $entity
                }
            }
        } catch {
            # Continue processing other entity types if one fails
        }
    }
    
    return $entities
}

function Get-SpanConfidenceScore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Span,
        
        [Parameter(Mandatory = $true)]
        [System.Text.RegularExpressions.Match]$Match,
        
        [Parameter(Mandatory = $true)]
        [string]$EntityType
    )
    
    $baseScore = 0.7
    
    # Span type bonus
    $spanTypeBonus = switch ($Span.Type) {
        "Single" { 0.0 }
        "Multi" { 0.1 }
        default { 0.0 }
    }
    
    # Match coverage score
    $coverageScore = $Match.Length / [Math]::Max(1.0, $Span.Length)
    
    # Context relevance score based on surrounding text
    $contextScore = Get-ContextRelevanceScore -Span $Span -EntityType $EntityType
    
    # Position score (entities at beginning/end of spans often more important)
    $positionScore = if ($Match.Index -eq 0 -or ($Match.Index + $Match.Length) -eq $Span.Text.Length) {
        0.05
    } else {
        0.0
    }
    
    $finalScore = ($baseScore * 0.5) + ($coverageScore * 0.2) + ($contextScore * 0.2) + $spanTypeBonus + $positionScore
    
    return [Math]::Max(0.1, [Math]::Min(0.95, $finalScore))
}

function Get-ContextRelevanceScore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Span,
        
        [Parameter(Mandatory = $true)]
        [string]$EntityType
    )
    
    $contextText = $Span.SentenceContext.Text.ToLower()
    
    # Context keywords that increase relevance for specific entity types
    $relevanceKeywords = @{
        "FilePath" = @("file", "script", "path", "directory", "folder", "location", "save", "load", "import", "export")
        "PowerShellCommand" = @("command", "cmdlet", "function", "script", "execute", "run", "invoke", "call")
        "ErrorMessage" = @("error", "exception", "fail", "issue", "problem", "bug", "crash", "fault")
        "Variable" = @("variable", "value", "parameter", "argument", "property", "field", "data")
        "URL" = @("url", "link", "address", "website", "endpoint", "api", "service", "connection")
        "Port" = @("port", "connection", "network", "service", "server", "endpoint", "listen", "bind")
    }
    
    if (-not $relevanceKeywords.ContainsKey($EntityType)) {
        return 0.5  # Neutral score for unknown entity types
    }
    
    $keywords = $relevanceKeywords[$EntityType]
    $matchCount = 0
    
    foreach ($keyword in $keywords) {
        if ($contextText.Contains($keyword)) {
            $matchCount++
        }
    }
    
    # Calculate relevance score based on keyword matches
    $maxPossibleMatches = $keywords.Count
    $relevanceRatio = $matchCount / $maxPossibleMatches
    
    # Apply logarithmic scaling to prevent over-weighting
    $scaledScore = 0.5 + ([Math]::Log($relevanceRatio + 0.1) / [Math]::Log(1.1)) * 0.3
    
    return [Math]::Max(0.1, [Math]::Min(0.9, $scaledScore))
}

function Get-EntityContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent,
        
        [Parameter(Mandatory = $true)]
        [int]$Position,
        
        [Parameter(Mandatory = $true)]
        [int]$Length
    )
    
    $contextRadius = 50  # characters before and after
    $startPos = [Math]::Max(0, $Position - $contextRadius)
    $endPos = [Math]::Min($ResponseContent.Length, $Position + $Length + $contextRadius)
    
    $contextText = $ResponseContent.Substring($startPos, $endPos - $startPos)
    
    return @{
        Before = if ($startPos -lt $Position) { $ResponseContent.Substring($startPos, $Position - $startPos) } else { "" }
        After = if ($Position + $Length -lt $endPos) { $ResponseContent.Substring($Position + $Length, $endPos - ($Position + $Length)) } else { "" }
        Full = $contextText.Trim()
    }
}

function Add-EntityValidation {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Entity
    )
    
    $validatedEntity = $Entity.Clone()
    
    switch ($Entity.Type) {
        "FilePath" {
            $validatedEntity.IsValid = Test-Path $Entity.Value -IsValid
            $validatedEntity.Exists = if ($validatedEntity.IsValid) { Test-Path $Entity.Value } else { $false }
            $validatedEntity.Extension = [System.IO.Path]::GetExtension($Entity.Value)
            $validatedEntity.Directory = [System.IO.Path]::GetDirectoryName($Entity.Value)
            $validatedEntity.FileName = [System.IO.Path]::GetFileName($Entity.Value)
        }
        "PowerShellCommand" {
            $validatedEntity.IsValid = $null -ne (Get-Command $Entity.Value -ErrorAction SilentlyContinue)
            if ($validatedEntity.IsValid) {
                $cmdInfo = Get-Command $Entity.Value
                $validatedEntity.ModuleName = $cmdInfo.ModuleName
                $validatedEntity.CommandType = $cmdInfo.CommandType
            }
        }
        "URL" {
            $validatedEntity.IsValid = [System.Uri]::TryCreate($Entity.Value, "Absolute", [ref]$null)
            if ($validatedEntity.IsValid) {
                $uri = [System.Uri]::new($Entity.Value)
                $validatedEntity.Domain = $uri.Host
                $validatedEntity.Protocol = $uri.Scheme
            }
        }
        "Port" {
            $portNumber = [int]$Entity.Value
            $validatedEntity.IsValid = ($portNumber -ge 1 -and $portNumber -le 65535)
            $validatedEntity.PortNumber = $portNumber
        }
    }
    
    return $validatedEntity
}

function Build-EntityRelationshipGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Entities
    )
    
    $graphStart = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Clear existing graph
    $script:EntityGraph.Nodes.Clear()
    $script:EntityGraph.Edges.Clear()
    $script:EntityGraph.NodeCounter = 0
    
    # Create nodes for all entities
    $nodeIds = @()
    foreach ($entity in $Entities) {
        $nodeId = New-EntityNode -Entity $entity
        $nodeIds += $nodeId
    }
    
    # Establish relationships between entities
    for ($i = 0; $i -lt $nodeIds.Count; $i++) {
        for ($j = $i + 1; $j -lt $nodeIds.Count; $j++) {
            $nodeId1 = $nodeIds[$i]
            $nodeId2 = $nodeIds[$j]
            $entity1 = $Entities[$i]
            $entity2 = $Entities[$j]
            
            # Calculate semantic similarity
            $similarity = Get-EntitySimilarity -Entity1 $entity1 -Entity2 $entity2
            
            if ($similarity.OverallSimilarity -gt 0.7) {
                New-EntityRelationship -SourceNodeId $nodeId1 -TargetNodeId $nodeId2 -RelationshipType "SimilarTo" -Confidence $similarity.OverallSimilarity
            }
            
            # Check for contextual proximity
            $positionDistance = [Math]::Abs($entity1.Position - $entity2.Position)
            if ($positionDistance -le 100) {  # Within 100 characters
                $proximityConfidence = [Math]::Max(0.5, 1.0 - ($positionDistance / 200.0))
                New-EntityRelationship -SourceNodeId $nodeId1 -TargetNodeId $nodeId2 -RelationshipType "NearBy" -Confidence $proximityConfidence
            }
            
            # Type-specific relationship detection
            if ($entity1.Type -eq "FilePath" -and $entity2.Type -eq "PowerShellCommand") {
                New-EntityRelationship -SourceNodeId $nodeId2 -TargetNodeId $nodeId1 -RelationshipType "OperatesOn" -Confidence 0.8
            }
            elseif ($entity1.Type -eq "PowerShellCommand" -and $entity2.Type -eq "FilePath") {
                New-EntityRelationship -SourceNodeId $nodeId1 -TargetNodeId $nodeId2 -RelationshipType "OperatesOn" -Confidence 0.8
            }
        }
    }
    
    $script:EntityGraph.LastUpdated = Get-Date
    $graphStart.Stop()
    
    return @{
        NodesCreated = $nodeIds.Count
        RelationshipsCreated = $script:EntityGraph.Edges.Count
        BuildTimeMs = $graphStart.ElapsedMilliseconds
    }
}

function New-EntityNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Entity
    )
    
    $nodeId = "node_" + $script:EntityGraph.NodeCounter++
    
    $node = @{
        Id = $nodeId
        Type = $Entity.Type
        Value = $Entity.Value
        Properties = @{
            Position = $Entity.Position
            Context = $Entity.Context
            Priority = $Entity.Priority
            ContextWeight = if ($Entity.ContextWeight) { $Entity.ContextWeight } else { 1.0 }
            CreatedAt = Get-Date
            LastAccessed = Get-Date
            AccessCount = 1
        }
        Relationships = @{}
        SemanticSimilarity = @{}
    }
    
    # Add type-specific properties
    switch ($Entity.Type) {
        "FilePath" { 
            if ($Entity.Extension) { $node.Properties.Extension = $Entity.Extension }
            if ($Entity.Directory) { $node.Properties.Directory = $Entity.Directory }
            if ($Entity.FileName) { $node.Properties.FileName = $Entity.FileName }
        }
        "ErrorMessage" {
            $node.Properties.Severity = "High"
            $node.Properties.Category = "Unknown"
        }
        "PowerShellCommand" {
            if ($Entity.ModuleName) { $node.Properties.ModuleName = $Entity.ModuleName }
            if ($Entity.CommandType) { $node.Properties.CommandType = $Entity.CommandType }
        }
        "URL" {
            if ($Entity.Domain) { $node.Properties.Domain = $Entity.Domain }
            if ($Entity.Protocol) { $node.Properties.Protocol = $Entity.Protocol }
        }
    }
    
    $script:EntityGraph.Nodes[$nodeId] = $node
    return $nodeId
}

function New-EntityRelationship {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourceNodeId,
        
        [Parameter(Mandatory = $true)]
        [string]$TargetNodeId,
        
        [Parameter(Mandatory = $true)]
        [string]$RelationshipType,
        
        [Parameter(Mandatory = $true)]
        [double]$Confidence
    )
    
    $relationshipId = "$SourceNodeId->$TargetNodeId"
    
    $relationship = @{
        Id = $relationshipId
        SourceNodeId = $SourceNodeId
        TargetNodeId = $TargetNodeId
        Type = $RelationshipType
        Confidence = $Confidence
        CreatedAt = Get-Date
        Weight = $Confidence
    }
    
    $script:EntityGraph.Edges[$relationshipId] = $relationship
    
    # Update node relationships
    if ($script:EntityGraph.Nodes.ContainsKey($SourceNodeId)) {
        $script:EntityGraph.Nodes[$SourceNodeId].Relationships[$relationshipId] = $relationship
    }
    
    return $relationshipId
}

function Get-EntitySimilarity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSObject]$Entity1,
        
        [Parameter(Mandatory = $true)]
        [PSObject]$Entity2
    )
    
    # Type similarity
    $typeSimilarity = if ($Entity1.Type -eq $Entity2.Type) { 1.0 } else { 0.0 }
    
    # Value similarity (Levenshtein distance)
    $valueSimilarity = Get-StringSimilarity -String1 $Entity1.Value -String2 $Entity2.Value
    
    # Context similarity
    $contextSimilarity = if ($Entity1.Context -and $Entity2.Context) {
        Get-StringSimilarity -String1 $Entity1.Context.Full -String2 $Entity2.Context.Full
    } else { 0.0 }
    
    # Position proximity
    $positionDistance = [Math]::Abs($Entity1.Position - $Entity2.Position)
    $positionSimilarity = [Math]::Max(0.0, 1.0 - ($positionDistance / 500.0))  # Within 500 chars = similar
    
    # Overall weighted similarity
    $overallSimilarity = ($typeSimilarity * 0.4) + ($valueSimilarity * 0.3) + ($contextSimilarity * 0.2) + ($positionSimilarity * 0.1)
    
    return @{
        TypeSimilarity = $typeSimilarity
        ValueSimilarity = $valueSimilarity
        ContextSimilarity = $contextSimilarity
        PositionSimilarity = $positionSimilarity
        OverallSimilarity = $overallSimilarity
    }
}

function Get-StringSimilarity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$String1,
        
        [Parameter(Mandatory = $true)]
        [string]$String2
    )
    
    # Simple Levenshtein distance calculation
    if ($String1 -eq $String2) { return 1.0 }
    if ($String1.Length -eq 0 -or $String2.Length -eq 0) { return 0.0 }
    
    $maxLength = [Math]::Max($String1.Length, $String2.Length)
    $distance = Get-LevenshteinDistance -String1 $String1 -String2 $String2
    
    return [Math]::Max(0.0, 1.0 - ($distance / $maxLength))
}

function Get-LevenshteinDistance {
    [CmdletBinding()]
    param(
        [string]$String1,
        [string]$String2
    )
    
    $len1 = $String1.Length
    $len2 = $String2.Length
    
    if ($len1 -eq 0) { return $len2 }
    if ($len2 -eq 0) { return $len1 }
    
    $matrix = New-Object 'int[,]' ($len1 + 1), ($len2 + 1)
    
    for ($i = 0; $i -le $len1; $i++) { $matrix[$i, 0] = $i }
    for ($j = 0; $j -le $len2; $j++) { $matrix[0, $j] = $j }
    
    for ($i = 1; $i -le $len1; $i++) {
        for ($j = 1; $j -le $len2; $j++) {
            $cost = if ($String1[$i - 1] -eq $String2[$j - 1]) { 0 } else { 1 }
            $matrix[$i, $j] = [Math]::Min(
                [Math]::Min($matrix[$i - 1, $j] + 1, $matrix[$i, $j - 1] + 1),
                $matrix[$i - 1, $j - 1] + $cost
            )
        }
    }
    
    return $matrix[$len1, $len2]
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Extract-ContextEntities',
    'Build-EntityRelationshipGraph',
    'Get-EntitySimilarity',
    'Get-TextSpans',
    'Split-TextIntoSentences', 
    'Invoke-JointEntityClassification',
    'Get-SpanConfidenceScore',
    'Get-SemanticContext'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBhq1PTpzOEgThJ
# Al0P5vNdhs0YhSJipCQPIqq+wFEz6aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPQplxafrfZ+odVHP7K3rOGM
# bvrMKrlePnuBBuda/wVqMA0GCSqGSIb3DQEBAQUABIIBAB6XMbjyj+hxKwR1rAZu
# RMuRXEJ2EDFiwXJbrD/2T4WDmiLrFFanEu5Bs4qmrtCQsZ8Uc6LIIswLx/WvEJ+g
# jb6+2cn9oOZ+pv3LfaGyv2KtCVSBV7H72XsdJ4VNcUpSfP9WmjpcOnYFU/SxOz4S
# LwwN45SIw8ZikJROM/rH5Z/HiCNKZCUgri12Dtm/cPjDn0EPkxoSVe9Gz+8loOT+
# ypzQ0A6eZZQbiCXQ2ecHhXMz7n4Ma9RxlRRgEzNiopMmJmOIZWvM1TvxGUbwdPd5
# VaLwcT8IXtWngGhp7tNX+OFGXALdygFFbi7Z3MLeOB8wlW7/2jhv2WmPJid6IPGn
# 0fQ=
# SIG # End signature block
