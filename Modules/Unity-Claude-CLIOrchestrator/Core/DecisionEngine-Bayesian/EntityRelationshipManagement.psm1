# EntityRelationshipManagement.psm1
# Phase 7 Day 3-4 Hours 5-8: Entity Relationship Graph Management
# Entity clustering and relationship analysis
# Date: 2025-08-25

#region Entity Relationship Management

# Build entity relationship graph
function Build-EntityRelationshipGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Entities,
        
        [Parameter()]
        [double]$ProximityThreshold = 50,  # Characters apart to be considered related
        
        [Parameter()]
        [switch]$IncludeMetrics
    )
    
    Write-DecisionLog "Building entity relationship graph for $($Entities.Count) entities" "DEBUG"
    
    $graph = @{
        Nodes = @{}
        Edges = @()
        Clusters = @()
    }
    
    # Create nodes for each entity
    foreach ($entity in $Entities) {
        $nodeId = "$($entity.Type)_$($entity.Value)"
        $graph.Nodes[$nodeId] = @{
            Type = $entity.Type
            Value = $entity.Value
            Position = $entity.Position
            Confidence = $entity.Confidence
            Connections = @()
        }
    }
    
    # Create edges based on proximity and type relationships
    for ($i = 0; $i -lt $Entities.Count; $i++) {
        for ($j = $i + 1; $j -lt $Entities.Count; $j++) {
            $entity1 = $Entities[$i]
            $entity2 = $Entities[$j]
            
            # Calculate proximity if positions available
            if ($entity1.Position -ge 0 -and $entity2.Position -ge 0) {
                $distance = [Math]::Abs($entity1.Position - $entity2.Position)
                
                if ($distance -le $ProximityThreshold) {
                    $edge = @{
                        Source = "$($entity1.Type)_$($entity1.Value)"
                        Target = "$($entity2.Type)_$($entity2.Value)"
                        Weight = 1 - ($distance / $ProximityThreshold)  # Closer = higher weight
                        Type = "Proximity"
                    }
                    $graph.Edges += $edge
                    
                    # Update node connections
                    $graph.Nodes[$edge.Source].Connections += $edge.Target
                    $graph.Nodes[$edge.Target].Connections += $edge.Source
                }
            }
            
            # Check for semantic relationships
            if ($entity1.Type -eq 'FilePath' -and $entity2.Type -eq 'PowerShellCommand') {
                # Commands often operate on files
                $edge = @{
                    Source = "$($entity1.Type)_$($entity1.Value)"
                    Target = "$($entity2.Type)_$($entity2.Value)"
                    Weight = 0.8
                    Type = "Semantic"
                }
                $graph.Edges += $edge
            }
        }
    }
    
    # Identify clusters (connected components)
    $visited = @{}
    foreach ($nodeId in $graph.Nodes.Keys) {
        if (-not $visited.ContainsKey($nodeId)) {
            $cluster = Find-EntityCluster -Graph $graph -StartNode $nodeId -Visited $visited
            if ($cluster.Count -gt 1) {
                $graph.Clusters += $cluster
            }
        }
    }
    
    if ($IncludeMetrics) {
        $graph.Metrics = @{
            NodeCount = $graph.Nodes.Count
            EdgeCount = $graph.Edges.Count
            ClusterCount = $graph.Clusters.Count
            AverageDegree = if ($graph.Nodes.Count -gt 0) {
                ($graph.Nodes.Values | ForEach-Object { $_.Connections.Count } | Measure-Object -Average).Average
            } else { 0 }
            Density = if ($graph.Nodes.Count -gt 1) {
                (2 * $graph.Edges.Count) / ($graph.Nodes.Count * ($graph.Nodes.Count - 1))
            } else { 0 }
        }
    }
    
    Write-DecisionLog "Entity graph built: $($graph.Nodes.Count) nodes, $($graph.Edges.Count) edges, $($graph.Clusters.Count) clusters" "INFO"
    
    return $graph
}

# Find entity cluster using depth-first search
function Find-EntityCluster {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory = $true)]
        [string]$StartNode,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Visited
    )
    
    $cluster = @()
    $stack = New-Object System.Collections.Stack
    $stack.Push($StartNode)
    
    while ($stack.Count -gt 0) {
        $current = $stack.Pop()
        
        if (-not $Visited.ContainsKey($current)) {
            $Visited[$current] = $true
            $cluster += $current
            
            # Add connected nodes to stack
            $node = $Graph.Nodes[$current]
            if ($node -and $node.Connections) {
                foreach ($connection in $node.Connections) {
                    if (-not $Visited.ContainsKey($connection)) {
                        $stack.Push($connection)
                    }
                }
            }
        }
    }
    
    return $cluster
}

# Measure entity proximity in graph
function Measure-EntityProximity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory = $true)]
        [string]$Entity1,
        
        [Parameter(Mandatory = $true)]
        [string]$Entity2
    )
    
    # Use breadth-first search to find shortest path
    if (-not $Graph.Nodes.ContainsKey($Entity1) -or -not $Graph.Nodes.ContainsKey($Entity2)) {
        return @{
            Distance = -1
            Path = @()
            Connected = $false
        }
    }
    
    if ($Entity1 -eq $Entity2) {
        return @{
            Distance = 0
            Path = @($Entity1)
            Connected = $true
        }
    }
    
    $queue = New-Object System.Collections.Queue
    $visited = @{ $Entity1 = $true }
    $parent = @{ $Entity1 = $null }
    $queue.Enqueue($Entity1)
    
    $found = $false
    while ($queue.Count -gt 0 -and -not $found) {
        $current = $queue.Dequeue()
        
        foreach ($neighbor in $Graph.Nodes[$current].Connections) {
            if (-not $visited.ContainsKey($neighbor)) {
                $visited[$neighbor] = $true
                $parent[$neighbor] = $current
                $queue.Enqueue($neighbor)
                
                if ($neighbor -eq $Entity2) {
                    $found = $true
                    break
                }
            }
        }
    }
    
    if ($found) {
        # Reconstruct path
        $path = @()
        $current = $Entity2
        while ($current -ne $null) {
            $path = @($current) + $path
            $current = $parent[$current]
        }
        
        return @{
            Distance = $path.Count - 1
            Path = $path
            Connected = $true
        }
    } else {
        return @{
            Distance = -1
            Path = @()
            Connected = $false
        }
    }
}

#endregion

# Export entity relationship functions
Export-ModuleMember -Function Build-EntityRelationshipGraph, Find-EntityCluster, Measure-EntityProximity
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCCZ6Efc3fqbAEs
# 5wkn6AYlYVFsFJ87KHwQ6iYCNLLAvqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEII4U4ppfDM5ngQ8ltr33MOuF
# 3bq6xjBWXtD6Ak+FNxcIMA0GCSqGSIb3DQEBAQUABIIBAKfI+A15M75l5Un83Jg7
# i8eipKwNnzsYAv1uaK+BSnB4LhN5unaFfLIkzbiXJwERKwfd/sg03/TCqYYx/cpr
# FTsaAcB0zn+wWZmNFy9q6gac324nA0WoGjlpwYP9R/MvIobDIopCPBZwPCGmlRNr
# 9SBMeEKTBNhMz9NZSfVvDxb56tZ6juzD7h2HbFofdueSFlBLoveLg7qSXgUy/+Cc
# vVDXcUFs81CaKUX/7gof2MoiQOsYz+FhSsc1JrvD76ZtWDtEX+yoskn2QDq2s4CS
# Q0czAfIjuDMFrj1H3A+tb33qXzgYvgZFJlBbRu+kW92SsI2qzbMuhWK45nqZlajo
# VIE=
# SIG # End signature block
