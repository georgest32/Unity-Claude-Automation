#Requires -Version 5.1
<#
.SYNOPSIS
    Query operations for Code Property Graph (CPG) implementation.

.DESCRIPTION
    Contains functions for querying and traversing CPG structures.
    Provides search, path finding, and neighbor discovery operations.

.NOTES
    Part of Unity-Claude-CPG refactored architecture
    Originally from Unity-Claude-CPG.psm1 (lines 498-715)
    Refactoring Date: 2025-08-25
#>

# Import required data structures
using module .\CPG-DataStructures.psm1

function Get-CPGNode {
    <#
    .SYNOPSIS
    Retrieves nodes from a CPG graph by various criteria.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ById')]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph,
        
        [Parameter(ParameterSetName = 'ById')]
        [string]$Id,
        
        [Parameter(ParameterSetName = 'ByName')]
        [string]$Name,
        
        [Parameter(ParameterSetName = 'ByType')]
        [CPGNodeType]$Type,
        
        [Parameter(ParameterSetName = 'ByFilter')]
        [scriptblock]$Filter,
        
        [switch]$First
    )
    
    $results = @()
    
    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            if ($Id) {
                if ($Graph.Nodes.ContainsKey($Id)) {
                    $results += $Graph.Nodes[$Id]
                }
            } else {
                $results = $Graph.Nodes.Values
            }
        }
        'ByName' {
            $results = $Graph.Nodes.Values | Where-Object { $_.Name -eq $Name }
        }
        'ByType' {
            $results = $Graph.Nodes.Values | Where-Object { $_.Type -eq $Type }
        }
        'ByFilter' {
            $results = $Graph.Nodes.Values | Where-Object $Filter
        }
    }
    
    if ($First -and $results.Count -gt 0) {
        return $results[0]
    }
    
    return $results
}

function Get-CPGEdge {
    <#
    .SYNOPSIS
    Retrieves edges from a CPG graph by various criteria.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ById')]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph,
        
        [Parameter(ParameterSetName = 'ById')]
        [string]$Id,
        
        [Parameter(ParameterSetName = 'ByNodes')]
        [string]$SourceId,
        
        [Parameter(ParameterSetName = 'ByNodes')]
        [string]$TargetId,
        
        [Parameter(ParameterSetName = 'ByType')]
        [CPGEdgeType]$Type,
        
        [Parameter(ParameterSetName = 'ByFilter')]
        [scriptblock]$Filter
    )
    
    $results = @()
    
    switch ($PSCmdlet.ParameterSetName) {
        'ById' {
            if ($Id) {
                if ($Graph.Edges.ContainsKey($Id)) {
                    $results += $Graph.Edges[$Id]
                }
            } else {
                $results = $Graph.Edges.Values
            }
        }
        'ByNodes' {
            $results = $Graph.Edges.Values | Where-Object {
                ($SourceId -and $_.SourceId -eq $SourceId) -and 
                ($TargetId -and $_.TargetId -eq $TargetId)
            }
        }
        'ByType' {
            $results = $Graph.Edges.Values | Where-Object { $_.Type -eq $Type }
        }
        'ByFilter' {
            $results = $Graph.Edges.Values | Where-Object $Filter
        }
    }
    
    return $results
}

function Get-CPGNeighbors {
    <#
    .SYNOPSIS
    Gets neighboring nodes of a specified node in the CPG graph.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph,
        
        [Parameter(Mandatory)]
        [string]$NodeId,
        
        [ValidateSet('Outgoing', 'Incoming', 'Both')]
        [string]$Direction = 'Both',
        
        [CPGEdgeType[]]$EdgeTypes,
        [int]$MaxDepth = 1,
        [switch]$IncludeEdges
    )
    
    if (-not $Graph.AdjacencyList.ContainsKey($NodeId)) {
        return @()
    }
    
    $visited = @{}
    $queue = @(@{ NodeId = $NodeId; Depth = 0 })
    $results = @()
    
    while ($queue.Count -gt 0) {
        $current = $queue[0]
        $queue = $queue[1..($queue.Count - 1)]
        
        if ($visited.ContainsKey($current.NodeId) -or $current.Depth -gt $MaxDepth) {
            continue
        }
        
        $visited[$current.NodeId] = $true
        
        if ($current.Depth -gt 0) {
            $neighbor = @{
                Node = $Graph.Nodes[$current.NodeId]
                Depth = $current.Depth
            }
            
            if ($IncludeEdges) {
                $neighbor.Edges = @()
                # Find connecting edges
                foreach ($edgeId in $Graph.AdjacencyList[$current.NodeId].Incoming + $Graph.AdjacencyList[$current.NodeId].Outgoing) {
                    $edge = $Graph.Edges[$edgeId]
                    if (($edge.SourceId -eq $NodeId) -or ($edge.TargetId -eq $NodeId)) {
                        if (-not $EdgeTypes -or ($edge.Type -in $EdgeTypes)) {
                            $neighbor.Edges += $edge
                        }
                    }
                }
            }
            
            $results += $neighbor
        }
        
        if ($current.Depth -lt $MaxDepth) {
            $adjacencies = @()
            
            if ($Direction -in @('Outgoing', 'Both')) {
                $adjacencies += $Graph.AdjacencyList[$current.NodeId].Outgoing
            }
            
            if ($Direction -in @('Incoming', 'Both')) {
                $adjacencies += $Graph.AdjacencyList[$current.NodeId].Incoming
            }
            
            foreach ($edgeId in $adjacencies) {
                $edge = $Graph.Edges[$edgeId]
                if ($EdgeTypes -and ($edge.Type -notin $EdgeTypes)) {
                    continue
                }
                
                $nextNodeId = if ($edge.SourceId -eq $current.NodeId) { $edge.TargetId } else { $edge.SourceId }
                
                if (-not $visited.ContainsKey($nextNodeId)) {
                    $queue += @{ NodeId = $nextNodeId; Depth = $current.Depth + 1 }
                }
            }
        }
    }
    
    return $results
}

function Find-CPGPath {
    <#
    .SYNOPSIS
    Finds paths between nodes in a CPG graph using breadth-first search.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph,
        
        [Parameter(Mandatory)]
        [string]$StartNodeId,
        
        [Parameter(Mandatory)]
        [string]$EndNodeId,
        
        [CPGEdgeType[]]$EdgeTypes,
        [ValidateSet('Shortest', 'All')]
        [string]$PathType = 'Shortest',
        [int]$MaxDepth = 10
    )
    
    if (-not $Graph.Nodes.ContainsKey($StartNodeId)) {
        throw "Start node '$StartNodeId' not found in graph"
    }
    
    if (-not $Graph.Nodes.ContainsKey($EndNodeId)) {
        throw "End node '$EndNodeId' not found in graph"
    }
    
    if ($StartNodeId -eq $EndNodeId) {
        return @(@{
            Nodes = @($Graph.Nodes[$StartNodeId])
            Edges = @()
            Length = 0
        })
    }
    
    $queue = @(@{
        NodeId = $StartNodeId
        Path = @($StartNodeId)
        EdgePath = @()
        Depth = 0
    })
    
    $visited = @{}
    $allPaths = @()
    
    while ($queue.Count -gt 0) {
        $current = $queue[0]
        $queue = $queue[1..($queue.Count - 1)]
        
        if ($current.Depth -gt $MaxDepth) {
            continue
        }
        
        if ($PathType -eq 'Shortest' -and $visited.ContainsKey($current.NodeId)) {
            continue
        }
        
        $visited[$current.NodeId] = $true
        
        # Get outgoing edges
        foreach ($edgeId in $Graph.AdjacencyList[$current.NodeId].Outgoing) {
            $edge = $Graph.Edges[$edgeId]
            
            if ($EdgeTypes -and ($edge.Type -notin $EdgeTypes)) {
                continue
            }
            
            $nextNodeId = $edge.TargetId
            
            if ($nextNodeId -eq $EndNodeId) {
                # Found a path
                $path = @{
                    Nodes = @()
                    Edges = @()
                    Length = $current.Path.Count
                }
                
                foreach ($nodeId in ($current.Path + $nextNodeId)) {
                    $path.Nodes += $Graph.Nodes[$nodeId]
                }
                
                foreach ($edgeId in ($current.EdgePath + $edge.Id)) {
                    $path.Edges += $Graph.Edges[$edgeId]
                }
                
                $allPaths += $path
                
                if ($PathType -eq 'Shortest') {
                    return $allPaths
                }
            }
            elseif ($nextNodeId -notin $current.Path) {
                $newPath = $current.Path + $nextNodeId
                $newEdgePath = $current.EdgePath + $edge.Id
                
                $queue += @{
                    NodeId = $nextNodeId
                    Path = $newPath
                    EdgePath = $newEdgePath
                    Depth = $current.Depth + 1
                }
            }
        }
    }
    
    return $allPaths
}

Export-ModuleMember -Function @(
    'Get-CPGNode',
    'Get-CPGEdge', 
    'Get-CPGNeighbors',
    'Find-CPGPath'
)

# REFACTORING MARKER: This module was refactored from Unity-Claude-CPG.psm1 on 2025-08-25
# Original file size: 1013 lines
# This component: Query and traversal operations
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC6pLJ/t7LEtkx9
# ym2g8iXbZWou3ih+SZgxShY0CorPFKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJvVsOCZIURBU5QZwGEcEmMC
# lzYizn0izrr63KGO7pHSMA0GCSqGSIb3DQEBAQUABIIBAAhN2BxEry/RN6K3BHXL
# RJSkEMq+a7N9yVRHFoAL2QKuZXg/RP783R9MqnmcQSY5dzROcBWdGjmiCPj8UiPt
# ZiVcHEGK0ChDvcm0jIDShoAUiomeDKtOen1S1HyQpXY1o3qsPpGULb4CKlDKhtWi
# Vc14G62baieZPsVGKECrpHs0qzwVllbtIhpcbVtLsrsvfvE3QGl14hCAe17GcprT
# UBlaH8JO5nwRgbaDUbiUlI/B6rmao3tbNrKzWexrex9k0ifcRbA/G+3MbxhdUk5+
# I00TjeDFY1CPUhITQ4rNJXiItZ4nkdRw0hjQk3uZdj8zrhCL5KM4XFtzgVv3Zy07
# tNs=
# SIG # End signature block
