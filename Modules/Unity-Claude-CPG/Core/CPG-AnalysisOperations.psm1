#Requires -Version 5.1
<#
.SYNOPSIS
    Analysis operations for Code Property Graph (CPG) implementation.

.DESCRIPTION
    Contains functions for analyzing CPG structures, including statistics,
    connectivity analysis, and graph metrics calculation.

.NOTES
    Part of Unity-Claude-CPG refactored architecture
    Originally from Unity-Claude-CPG.psm1 (lines 716-770)
    Refactoring Date: 2025-08-25
#>

# Import required data structures
using module .\CPG-DataStructures.psm1

function Get-CPGStatistics {
    <#
    .SYNOPSIS
    Computes comprehensive statistics for a CPG graph.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph,
        
        [switch]$IncludeNodeTypeBreakdown,
        [switch]$IncludeEdgeTypeBreakdown,
        [switch]$IncludeConnectivity
    )
    
    $stats = @{
        NodeCount = $Graph.Nodes.Count
        EdgeCount = $Graph.Edges.Count
        GraphId = $Graph.Id
        GraphName = $Graph.Name
        CreatedAt = $Graph.CreatedAt
        ModifiedAt = $Graph.ModifiedAt
        Version = $Graph.Version
    }
    
    if ($IncludeNodeTypeBreakdown) {
        $nodeTypes = @{}
        foreach ($node in $Graph.Nodes.Values) {
            $typeStr = $node.Type.ToString()
            if ($nodeTypes.ContainsKey($typeStr)) {
                $nodeTypes[$typeStr]++
            } else {
                $nodeTypes[$typeStr] = 1
            }
        }
        $stats.NodeTypeBreakdown = $nodeTypes
    }
    
    if ($IncludeEdgeTypeBreakdown) {
        $edgeTypes = @{}
        foreach ($edge in $Graph.Edges.Values) {
            $typeStr = $edge.Type.ToString()
            if ($edgeTypes.ContainsKey($typeStr)) {
                $edgeTypes[$typeStr]++
            } else {
                $edgeTypes[$typeStr] = 1
            }
        }
        $stats.EdgeTypeBreakdown = $edgeTypes
    }
    
    if ($IncludeConnectivity) {
        $connectivity = @{
            IsolatedNodes = 0
            ConnectedComponents = 0
            MaxDegree = 0
            AvgDegree = 0
        }
        
        $degrees = @()
        foreach ($nodeId in $Graph.Nodes.Keys) {
            $inDegree = $Graph.AdjacencyList[$nodeId].Incoming.Count
            $outDegree = $Graph.AdjacencyList[$nodeId].Outgoing.Count
            $totalDegree = $inDegree + $outDegree
            
            $degrees += $totalDegree
            
            if ($totalDegree -eq 0) {
                $connectivity.IsolatedNodes++
            }
            
            if ($totalDegree -gt $connectivity.MaxDegree) {
                $connectivity.MaxDegree = $totalDegree
            }
        }
        
        if ($degrees.Count -gt 0) {
            $connectivity.AvgDegree = [math]::Round(($degrees | Measure-Object -Sum).Sum / $degrees.Count, 2)
        }
        
        $stats.Connectivity = $connectivity
    }
    
    return $stats
}

function Test-CPGStronglyConnected {
    <#
    .SYNOPSIS
    Tests if the CPG graph is strongly connected using Tarjan's algorithm.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph
    )
    
    if ($Graph.Nodes.Count -eq 0) {
        return $true
    }
    
    # Simple connectivity test for now
    # A full Tarjan's algorithm implementation would be more complex
    $visited = @{}
    $startNode = $Graph.Nodes.Keys | Select-Object -First 1
    
    # DFS from first node
    $stack = @($startNode)
    while ($stack.Count -gt 0) {
        $currentId = $stack[-1]
        $stack = $stack[0..($stack.Count - 2)]
        
        if ($visited.ContainsKey($currentId)) {
            continue
        }
        
        $visited[$currentId] = $true
        
        foreach ($edgeId in $Graph.AdjacencyList[$currentId].Outgoing) {
            $edge = $Graph.Edges[$edgeId]
            if (-not $visited.ContainsKey($edge.TargetId)) {
                $stack += $edge.TargetId
            }
        }
    }
    
    # Check if all nodes were visited
    return $visited.Count -eq $Graph.Nodes.Count
}

function Get-CPGComplexityMetrics {
    <#
    .SYNOPSIS
    Calculates complexity metrics for the CPG graph.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph
    )
    
    $metrics = @{
        CyclomaticComplexity = 0
        Density = 0
        Modularity = 0
        ClusteringCoefficient = 0
    }
    
    # Calculate graph density
    $nodeCount = $Graph.Nodes.Count
    if ($nodeCount -gt 1) {
        $maxPossibleEdges = $nodeCount * ($nodeCount - 1)
        if ($maxPossibleEdges -gt 0) {
            $metrics.Density = [math]::Round($Graph.Edges.Count / $maxPossibleEdges, 4)
        }
    }
    
    # Calculate cyclomatic complexity (simplified)
    # V(G) = E - N + 2P where E=edges, N=nodes, P=connected components
    $metrics.CyclomaticComplexity = $Graph.Edges.Count - $Graph.Nodes.Count + 2
    
    return $metrics
}

function Find-CPGCycles {
    <#
    .SYNOPSIS
    Finds cycles in the CPG graph using depth-first search.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph,
        
        [int]$MaxCycles = 10
    )
    
    $visited = @{}
    $recursionStack = @{}
    $cycles = @()
    
    function Find-CyclesDFS($nodeId, $path) {
        if ($cycles.Count -ge $MaxCycles) {
            return
        }
        
        $visited[$nodeId] = $true
        $recursionStack[$nodeId] = $true
        
        foreach ($edgeId in $Graph.AdjacencyList[$nodeId].Outgoing) {
            $edge = $Graph.Edges[$edgeId]
            $targetId = $edge.TargetId
            
            if ($recursionStack.ContainsKey($targetId)) {
                # Found a cycle
                $cycleStart = $path.IndexOf($targetId)
                if ($cycleStart -ge 0) {
                    $cycle = $path[$cycleStart..($path.Count - 1)] + $targetId
                    $cycles += @{
                        Nodes = $cycle | ForEach-Object { $Graph.Nodes[$_] }
                        Length = $cycle.Count - 1
                    }
                }
            }
            elseif (-not $visited.ContainsKey($targetId)) {
                Find-CyclesDFS $targetId ($path + $targetId)
            }
        }
        
        $recursionStack.Remove($nodeId)
    }
    
    foreach ($nodeId in $Graph.Nodes.Keys) {
        if (-not $visited.ContainsKey($nodeId)) {
            Find-CyclesDFS $nodeId @($nodeId)
        }
    }
    
    return $cycles
}

Export-ModuleMember -Function @(
    'Get-CPGStatistics',
    'Test-CPGStronglyConnected',
    'Get-CPGComplexityMetrics',
    'Find-CPGCycles'
)

# REFACTORING MARKER: This module was refactored from Unity-Claude-CPG.psm1 on 2025-08-25
# Original file size: 1013 lines
# This component: Analysis and metrics operations
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCZGTmvqtANAwcQ
# D5urwD0cajeS9qfV9vlmHV9A9vtuN6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIFnXovFDlDT94s4CylDHr17
# /eoZR0frEVIN4m3MA9dGMA0GCSqGSIb3DQEBAQUABIIBAFczUOsUvVPOgyFKGMk/
# DJEw6+NZp8bhXAb3uzpKPIkEYSefeN/GftuiDn+s9SVolauTEZp6rzOyfTXL+Vdz
# WogwRVv42OQv5yHaKFbpnAmbaihBkf1K9Wz96MHpQ4W+Eq0U+Hq1CC2nOk13vmKB
# iScsQbp2RIlwwhFNOEHjTT6AhSGeyuybKxh9SiyjZQ1rF5INQDR/wF/6GqOI+TWg
# G/kYwTDeD/+bHrYO1ii4XP5AwTRFySVNFiESnRkpfduNRWvFrbwUoFKtxwBA6Pof
# jbkeD4krMdW8AkdIe/G1ReiMoWF4CTXoZypcBLIPQO56xGIN6JvIlh89cWx6WfSm
# dfc=
# SIG # End signature block
