# ContextExtraction.psm1  
# Phase 2 Day 11: Enhanced Response Processing - Advanced Context Extraction
# Provides entity recognition, relationship mapping, and context relevance scoring
# Date: 2025-08-18

#region Module Dependencies

# Import required modules
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "Core\AgentLogging.psm1") -Force
Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) "ContextOptimization.psm1") -Force

#endregion

#region Module Variables

# Entity recognition patterns  
$script:EntityPatterns = @{
    "FilePath" = @{
        Pattern = "([A-Za-z]:\\[^,\s]+\.(?:ps1|psm1|psd1|cs|txt|log|json|xml|dll|exe))"
        Type = "File"
        Relevance = 0.9
    }
    
    "Unity_ErrorCode" = @{
        Pattern = "(CS\d{4})"
        Type = "ErrorCode"
        Relevance = 0.95
    }
    
    "Unity_Component" = @{
        Pattern = "\b(GameObject|MonoBehaviour|Transform|Component|Scene|Asset|Script|Prefab|Material|Texture|Mesh|Shader)\b"
        Type = "UnityComponent"
        Relevance = 0.8
    }
    
    "Unity_Method" = @{
        Pattern = "\b(Start|Update|Awake|OnEnable|OnDisable|OnDestroy|Instantiate|Destroy|GetComponent|AddComponent)\b"
        Type = "UnityMethod"
        Relevance = 0.75
    }
    
    "Project_Reference" = @{
        Pattern = "\b(Dithering|SymbolicMemory|Sound-and-Shoal|Unity-Claude-Automation)\b"
        Type = "ProjectRef"
        Relevance = 0.85
    }
    
    "Command_Reference" = @{
        Pattern = "\b(?:(?:Import|Export|Get|Set|New|Remove|Test|Install|Uninstall|Start|Stop|Invoke)-\w+|\w+-\w+\.ps1)\b"
        Type = "PowerShellCommand"
        Relevance = 0.8
    }
    
    "Line_Number" = @{
        Pattern = "\b(?:line|Line)\s+(\d+)\b"
        Type = "LineReference"
        Relevance = 0.7
    }
    
    "Version_Number" = @{
        Pattern = "\b(?:v|version|Version)\s*(\d+\.\d+(?:\.\d+)?(?:\.\d+)?)\b"
        Type = "Version"
        Relevance = 0.6
    }
    
    "Percentage" = @{
        Pattern = "\b(\d+(?:\.\d+)?)\s*%\b"
        Type = "Percentage"
        Relevance = 0.5
    }
}

# Relationship mapping patterns
$script:RelationshipPatterns = @{
    "ErrorToSolution" = @{
        Pattern = "(?:CS\d{4}.*?)(?:fix|resolve|solution|workaround):\s*(.+)"
        Relationship = "ErrorSolution"
        Relevance = 0.9
    }
    
    "FileToError" = @{
        Pattern = "([A-Za-z]:\\[^,\s]+\.(?:cs|ps1)).*?(CS\d{4}|error|exception)"
        Relationship = "FileError"
        Relevance = 0.85
    }
    
    "CommandToResult" = @{
        Pattern = "(?:run|execute|try)\s+([^.]+).*?(?:result|output|success|failure)"
        Relationship = "CommandResult"
        Relevance = 0.8
    }
    
    "CauseToEffect" = @{
        Pattern = "(?:because|due to|caused by)\s+([^,]+),?\s*(?:results? in|leads? to|causes?)\s+(.+)"
        Relationship = "CauseEffect"
        Relevance = 0.75
    }
}

# Context relevance scoring weights
$script:RelevanceWeights = @{
    "Recency" = 0.3      # How recent the information is
    "EntityType" = 0.25  # Type of entity (errors higher priority)
    "Frequency" = 0.2    # How often mentioned
    "Relationship" = 0.15 # Connected to other entities
    "Priority" = 0.1     # Explicit priority indicators
}

#endregion

#region Context Extraction Functions

function Invoke-AdvancedContextExtraction {
    <#
    .SYNOPSIS
    Performs advanced context extraction from Claude responses
    
    .DESCRIPTION
    Extracts entities, relationships, and relevance-scored context from Claude responses
    
    .PARAMETER ResponseText
    The Claude response text to analyze
    
    .PARAMETER PreviousContext
    Previous conversation context for relationship analysis
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText,
        
        [hashtable]$PreviousContext = @{}
    )
    
    Write-AgentLog "Starting advanced context extraction" -Level "DEBUG" -Component "ContextExtraction"
    
    try {
        $extractionResult = @{
            ExtractedAt = Get-Date
            Entities = @()
            Relationships = @()
            ContextItems = @()
            RelevanceScores = @{}
            IntegrationReady = $false
        }
        
        # Extract entities using pattern library
        foreach ($entityTypeName in $script:EntityPatterns.Keys) {
            $entityPattern = $script:EntityPatterns[$entityTypeName]
            
            $matches = [regex]::Matches($ResponseText, $entityPattern.Pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            
            foreach ($match in $matches) {
                $entity = @{
                    Type = $entityPattern.Type
                    Value = $match.Value
                    Position = $match.Index
                    Length = $match.Length
                    BaseRelevance = $entityPattern.Relevance
                    ExtractedAt = Get-Date
                }
                
                $extractionResult.Entities += $entity
                Write-AgentLog "Extracted entity: $($entity.Type) = $($entity.Value)" -Level "DEBUG" -Component "ContextExtraction"
            }
        }
        
        # Extract relationships
        foreach ($relationshipName in $script:RelationshipPatterns.Keys) {
            $relationship = $script:RelationshipPatterns[$relationshipName]
            
            if ($ResponseText -match $relationship.Pattern) {
                $relationshipData = @{
                    Type = $relationship.Relationship
                    Relevance = $relationship.Relevance
                    MatchedText = $Matches[0]
                    Groups = @()
                    ExtractedAt = Get-Date
                }
                
                # Extract groups
                for ($i = 1; $i -lt $Matches.Count; $i++) {
                    $relationshipData.Groups += $Matches[$i]
                }
                
                $extractionResult.Relationships += $relationshipData
                Write-AgentLog "Extracted relationship: $($relationship.Relationship)" -Level "DEBUG" -Component "ContextExtraction"
            }
        }
        
        # Calculate relevance scores for context integration
        $extractionResult.RelevanceScores = Get-ContextRelevanceScores -Entities $extractionResult.Entities -Relationships $extractionResult.Relationships -PreviousContext $PreviousContext
        
        # Create context items for integration
        $extractionResult.ContextItems = New-ContextItemsFromExtraction -Entities $extractionResult.Entities -Relationships $extractionResult.Relationships -RelevanceScores $extractionResult.RelevanceScores
        
        $extractionResult.IntegrationReady = $true
        
        Write-AgentLog "Advanced context extraction completed: $($extractionResult.Entities.Count) entities, $($extractionResult.Relationships.Count) relationships" -Level "SUCCESS" -Component "ContextExtraction"
        
        return @{
            Success = $true
            Results = $extractionResult
        }
    }
    catch {
        Write-AgentLog "Advanced context extraction failed: $_" -Level "ERROR" -Component "ContextExtraction"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ContextRelevanceScores {
    <#
    .SYNOPSIS
    Calculates relevance scores for extracted context
    
    .DESCRIPTION
    Applies relevance scoring algorithm based on multiple factors
    
    .PARAMETER Entities
    Extracted entities to score
    
    .PARAMETER Relationships
    Extracted relationships for scoring context
    
    .PARAMETER PreviousContext
    Previous context for comparison
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Entities,
        
        [array]$Relationships = @(),
        
        [hashtable]$PreviousContext = @{}
    )
    
    Write-AgentLog "Calculating context relevance scores" -Level "DEBUG" -Component "ContextExtraction"
    
    try {
        $relevanceScores = @{}
        
        foreach ($entity in $Entities) {
            $score = $entity.BaseRelevance
            $factors = @{
                Base = $entity.BaseRelevance
                Recency = 0.0
                EntityType = 0.0
                Frequency = 0.0
                Relationship = 0.0
                Priority = 0.0
            }
            
            # Recency factor (newer is more relevant)
            $age = (Get-Date) - $entity.ExtractedAt
            $factors.Recency = [Math]::Max(0, 1.0 - ($age.TotalMinutes / 60))  # Decay over 1 hour
            
            # Entity type factor
            switch ($entity.Type) {
                "ErrorCode" { $factors.EntityType = 1.0 }
                "File" { $factors.EntityType = 0.9 }
                "PowerShellCommand" { $factors.EntityType = 0.8 }
                "UnityComponent" { $factors.EntityType = 0.7 }
                default { $factors.EntityType = 0.5 }
            }
            
            # Frequency factor (check if mentioned in previous context)
            if ($PreviousContext.ContainsKey($entity.Value)) {
                $factors.Frequency = 0.8
            }
            
            # Relationship factor (connected to other entities)
            $relationshipCount = ($Relationships | Where-Object { $_.MatchedText -match [regex]::Escape($entity.Value) }).Count
            $factors.Relationship = [Math]::Min(1.0, $relationshipCount * 0.3)
            
            # Priority factor (explicit priority terms)
            if ($entity.Value -match "(?:critical|important|urgent|high|priority)") {
                $factors.Priority = 1.0
            }
            
            # Calculate weighted score
            $finalScore = 0.0
            foreach ($factor in $factors.Keys) {
                if ($script:RelevanceWeights.ContainsKey($factor)) {
                    $finalScore += $factors[$factor] * $script:RelevanceWeights[$factor]
                }
            }
            
            $relevanceScores[$entity.Value] = @{
                Score = [Math]::Round($finalScore, 2)
                Factors = $factors
                Entity = $entity
            }
        }
        
        Write-AgentLog "Relevance scores calculated for $($Entities.Count) entities" -Level "DEBUG" -Component "ContextExtraction"
        
        return $relevanceScores
    }
    catch {
        Write-AgentLog "Relevance score calculation failed: $_" -Level "ERROR" -Component "ContextExtraction"
        return @{}
    }
}

function New-ContextItemsFromExtraction {
    <#
    .SYNOPSIS
    Creates context items from extraction results
    
    .DESCRIPTION
    Converts extracted entities and relationships into context items for integration
    
    .PARAMETER Entities
    Extracted entities
    
    .PARAMETER Relationships
    Extracted relationships
    
    .PARAMETER RelevanceScores
    Calculated relevance scores
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Entities,
        
        [array]$Relationships = @(),
        
        [hashtable]$RelevanceScores = @{}
    )
    
    Write-AgentLog "Creating context items from extraction results" -Level "DEBUG" -Component "ContextExtraction"
    
    try {
        $contextItems = @()
        
        # Create context items for high-relevance entities
        foreach ($entity in $Entities) {
            $relevanceData = $RelevanceScores[$entity.Value]
            
            if ($relevanceData -and $relevanceData.Score -gt 0.5) {
                $contextItem = @{
                    Type = switch ($entity.Type) {
                        "ErrorCode" { "Error" }
                        "PowerShellCommand" { "Command" }
                        default { "Insight" }
                    }
                    Content = "Entity: $($entity.Type) = $($entity.Value)"
                    Priority = if ($relevanceData.Score -gt 0.8) { "High" } 
                             elseif ($relevanceData.Score -gt 0.6) { "Medium" } 
                             else { "Low" }
                    Metadata = @{
                        EntityType = $entity.Type
                        EntityValue = $entity.Value
                        RelevanceScore = $relevanceData.Score
                        Position = $entity.Position
                    }
                }
                
                $contextItems += $contextItem
                Write-AgentLog "Created context item: $($entity.Type) with relevance $($relevanceData.Score)" -Level "DEBUG" -Component "ContextExtraction"
            }
        }
        
        # Create context items for relationships
        foreach ($relationship in $Relationships) {
            if ($relationship.Relevance -gt 0.7) {
                $contextItem = @{
                    Type = "Insight"
                    Content = "Relationship: $($relationship.Type) - $($relationship.MatchedText)"
                    Priority = "Medium"
                    Metadata = @{
                        RelationshipType = $relationship.Type
                        Relevance = $relationship.Relevance
                        Groups = $relationship.Groups
                    }
                }
                
                $contextItems += $contextItem
                Write-AgentLog "Created relationship context item: $($relationship.Type)" -Level "DEBUG" -Component "ContextExtraction"
            }
        }
        
        Write-AgentLog "Created $($contextItems.Count) context items from extraction" -Level "INFO" -Component "ContextExtraction"
        
        return $contextItems
    }
    catch {
        Write-AgentLog "Context item creation failed: $_" -Level "ERROR" -Component "ContextExtraction"
        return @()
    }
}

function Invoke-ContextIntegration {
    <#
    .SYNOPSIS
    Integrates extraction results with context management system
    
    .DESCRIPTION
    Automatically adds extracted context to the working memory system
    
    .PARAMETER ExtractionResults
    Results from advanced context extraction
    
    .PARAMETER AutoAdd
    Automatically add high-relevance items to context
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ExtractionResults,
        
        [switch]$AutoAdd
    )
    
    Write-AgentLog "Integrating extraction results with context management" -Level "DEBUG" -Component "ContextExtraction"
    
    try {
        $integrationResults = @{
            ItemsAdded = 0
            ItemsSkipped = 0
            AddedItems = @()
            SkippedItems = @()
        }
        
        if (-not $ExtractionResults.IntegrationReady) {
            throw "Extraction results not ready for integration"
        }
        
        foreach ($contextItem in $ExtractionResults.ContextItems) {
            if ($AutoAdd -and $contextItem.Priority -in @("High", "Medium")) {
                # Add to context management system
                $addResult = Add-ContextItem -Type $contextItem.Type -Content $contextItem.Content -Priority $contextItem.Priority
                
                if ($addResult.Success) {
                    $integrationResults.ItemsAdded++
                    $integrationResults.AddedItems += $contextItem
                    Write-AgentLog "Added context item: $($contextItem.Type) ($($contextItem.Priority) priority)" -Level "DEBUG" -Component "ContextExtraction"
                } else {
                    $integrationResults.ItemsSkipped++
                    $integrationResults.SkippedItems += $contextItem
                    Write-AgentLog "Failed to add context item: $($addResult.Error)" -Level "WARNING" -Component "ContextExtraction"
                }
            } else {
                $integrationResults.ItemsSkipped++
                $integrationResults.SkippedItems += $contextItem
                Write-AgentLog "Skipped context item: $($contextItem.Type) (Low priority or AutoAdd disabled)" -Level "DEBUG" -Component "ContextExtraction"
            }
        }
        
        Write-AgentLog "Context integration completed: $($integrationResults.ItemsAdded) added, $($integrationResults.ItemsSkipped) skipped" -Level "SUCCESS" -Component "ContextExtraction"
        
        return @{
            Success = $true
            Results = $integrationResults
        }
    }
    catch {
        Write-AgentLog "Context integration failed: $_" -Level "ERROR" -Component "ContextExtraction"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-EntityRelationshipMap {
    <#
    .SYNOPSIS
    Creates a relationship map between extracted entities
    
    .DESCRIPTION
    Analyzes entities and relationships to create a connection map
    
    .PARAMETER Entities
    Extracted entities
    
    .PARAMETER Relationships
    Extracted relationships
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Entities,
        
        [array]$Relationships = @()
    )
    
    Write-AgentLog "Creating entity relationship map" -Level "DEBUG" -Component "ContextExtraction"
    
    try {
        $relationshipMap = @{
            Nodes = @{}
            Edges = @()
            Clusters = @{}
        }
        
        # Create nodes for entities
        foreach ($entity in $Entities) {
            $nodeId = "$($entity.Type):$($entity.Value)"
            $relationshipMap.Nodes[$nodeId] = @{
                Id = $nodeId
                Type = $entity.Type
                Value = $entity.Value
                Relevance = $entity.BaseRelevance
                Connections = @()
            }
        }
        
        # Create edges for relationships
        foreach ($relationship in $Relationships) {
            # Find entities mentioned in this relationship
            $connectedEntities = @()
            foreach ($entity in $Entities) {
                if ($relationship.MatchedText -match [regex]::Escape($entity.Value)) {
                    $connectedEntities += $entity
                }
            }
            
            # Create edges between connected entities
            for ($i = 0; $i -lt $connectedEntities.Count - 1; $i++) {
                for ($j = $i + 1; $j -lt $connectedEntities.Count; $j++) {
                    $sourceId = "$($connectedEntities[$i].Type):$($connectedEntities[$i].Value)"
                    $targetId = "$($connectedEntities[$j].Type):$($connectedEntities[$j].Value)"
                    
                    $edge = @{
                        Source = $sourceId
                        Target = $targetId
                        RelationshipType = $relationship.Type
                        Strength = $relationship.Relevance
                    }
                    
                    $relationshipMap.Edges += $edge
                    
                    # Update node connections
                    if ($relationshipMap.Nodes.ContainsKey($sourceId)) {
                        $relationshipMap.Nodes[$sourceId].Connections += $targetId
                    }
                    if ($relationshipMap.Nodes.ContainsKey($targetId)) {
                        $relationshipMap.Nodes[$targetId].Connections += $sourceId
                    }
                }
            }
        }
        
        # Create clusters of related entities
        $relationshipMap.Clusters = Get-EntityClusters -Nodes $relationshipMap.Nodes -Edges $relationshipMap.Edges
        
        Write-AgentLog "Entity relationship map created: $($relationshipMap.Nodes.Count) nodes, $($relationshipMap.Edges.Count) edges" -Level "INFO" -Component "ContextExtraction"
        
        return @{
            Success = $true
            RelationshipMap = $relationshipMap
        }
    }
    catch {
        Write-AgentLog "Entity relationship mapping failed: $_" -Level "ERROR" -Component "ContextExtraction"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-EntityClusters {
    <#
    .SYNOPSIS
    Identifies clusters of related entities
    
    .DESCRIPTION
    Groups entities into clusters based on their relationships
    
    .PARAMETER Nodes
    Entity nodes
    
    .PARAMETER Edges
    Relationship edges
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Nodes,
        
        [array]$Edges = @()
    )
    
    $clusters = @{}
    $visited = @{}
    $clusterId = 0
    
    # Simple clustering using connected components
    foreach ($nodeId in $Nodes.Keys) {
        if (-not $visited.ContainsKey($nodeId)) {
            $clusterId++
            $cluster = @{
                Id = $clusterId
                Nodes = @()
                Relevance = 0.0
            }
            
            # Depth-first search to find connected components
            $stack = @($nodeId)
            $iterationCount = 0
            $maxIterations = 1000  # Prevent infinite loops
            
            Write-AgentLog "Starting DFS for cluster $clusterId with node: $nodeId" -Level "DEBUG" -Component "ContextExtraction"
            
            while ($stack.Count -gt 0 -and $iterationCount -lt $maxIterations) {
                $iterationCount++
                Write-AgentLog "DFS iteration $iterationCount, stack size: $($stack.Count)" -Level "DEBUG" -Component "ContextExtraction"
                
                $currentNode = $stack[-1]
                
                # Safe stack pop operation
                if ($stack.Count -eq 1) {
                    $stack = @()
                } else {
                    $stack = $stack[0..($stack.Count - 2)]
                }
                
                if (-not $visited.ContainsKey($currentNode)) {
                    $visited[$currentNode] = $true
                    $cluster.Nodes += $currentNode
                    $cluster.Relevance += $Nodes[$currentNode].Relevance
                    
                    # Add connected nodes to stack
                    foreach ($connection in $Nodes[$currentNode].Connections) {
                        if (-not $visited.ContainsKey($connection)) {
                            $stack += $connection
                        }
                    }
                }
            }
            
            # Check for infinite loop protection
            if ($iterationCount -ge $maxIterations) {
                Write-AgentLog "DFS reached maximum iterations ($maxIterations) for cluster $clusterId - possible infinite loop detected" -Level "WARNING" -Component "ContextExtraction"
            }
            
            Write-AgentLog "DFS completed for cluster $clusterId after $iterationCount iterations" -Level "DEBUG" -Component "ContextExtraction"
            
            if ($cluster.Nodes.Count -gt 0) {
                $cluster.Relevance = [Math]::Round($cluster.Relevance / $cluster.Nodes.Count, 2)
            } else {
                $cluster.Relevance = 0.0
            }
            $clusters["Cluster$clusterId"] = $cluster
        }
    }
    
    Write-AgentLog "Created $($clusters.Count) entity clusters" -Level "DEBUG" -Component "ContextExtraction"
    
    return $clusters
}

#endregion

# Export module functions
Export-ModuleMember -Function @(
    'Invoke-AdvancedContextExtraction',
    'Get-ContextRelevanceScores',
    'New-ContextItemsFromExtraction',
    'Invoke-ContextIntegration',
    'Get-EntityRelationshipMap',
    'Get-EntityClusters'
)

Write-AgentLog "ContextExtraction module loaded successfully" -Level "INFO" -Component "ContextExtraction"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFzT17w1ya8dcnS/NBHOYBc8s
# CHugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUFh8EKSC2KbhmYfHxi2wlLvcd0EMwDQYJKoZIhvcNAQEBBQAEggEAIfy0
# qoZFLpqNPTLcACxqXRanK6cHF+8gMsxO2lkcQcl4RdFhnyD0h99m1h33e+BVUAsr
# sU/4V9LRGdOYS/5eP5hIXEXPWFhv9p9phBnjiPbBAYYlkUxVN6edqpF59QlfB4yx
# 0+PthurpusIKdJ1s1TbosydqKJaqjLuZ9PK2LGhIHG6IIGt1ncN0JSiebn7xY7nj
# 4m1kNWA5E/eBSBMOtLYcarQf0COWMzawiAn30l8bnTI341l8zSvK+swQv8fyX79z
# XRFlUXFYjxpkpEQMcZHocSO6PP1M7HKajZX8aTkJzymh3UQNS2NGyRvYDG89dBRN
# wE7VXxNalG2dPCR2mQ==
# SIG # End signature block
