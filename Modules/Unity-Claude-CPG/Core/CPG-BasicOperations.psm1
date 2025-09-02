#Requires -Version 5.1
<#
.SYNOPSIS
    Basic graph operations for Code Property Graph (CPG) implementation.

.DESCRIPTION
    Contains functions for creating and manipulating CPG nodes, edges, and graphs.
    Provides the core CRUD operations for the CPG system.

.NOTES
    Part of Unity-Claude-CPG refactored architecture
    Originally from Unity-Claude-CPG.psm1 (lines 337-497)
    Refactoring Date: 2025-08-25
#>

# Import required data structures
using module .\CPG-DataStructures.psm1

function New-CPGNode {
    <#
    .SYNOPSIS
    Creates a new CPG node with the specified name and type.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [CPGNodeType]$Type,
        
        [hashtable]$Properties = @{},
        [string]$FilePath,
        [int]$StartLine = 0,
        [int]$EndLine = 0,
        [int]$StartColumn = 0,
        [int]$EndColumn = 0,
        [string]$Language = 'PowerShell',
        [hashtable]$Metadata = @{}
    )
    
    $node = [CPGNode]::new($Name, $Type)
    $node.Properties = $Properties
    $node.FilePath = $FilePath
    $node.StartLine = $StartLine
    $node.EndLine = $EndLine
    $node.StartColumn = $StartColumn
    $node.EndColumn = $EndColumn
    $node.Language = $Language
    $node.Metadata = $Metadata
    
    return $node
}

function New-CPGEdge {
    <#
    .SYNOPSIS
    Creates a new CPG edge between two nodes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SourceId,
        
        [Parameter(Mandatory)]
        [string]$TargetId,
        
        [Parameter(Mandatory)]
        [CPGEdgeType]$Type,
        
        [EdgeDirection]$Direction = [EdgeDirection]::Forward,
        [hashtable]$Properties = @{},
        [double]$Weight = 1.0,
        [hashtable]$Metadata = @{}
    )
    
    $edge = [CPGEdge]::new($SourceId, $TargetId, $Type)
    $edge.Direction = $Direction
    $edge.Properties = $Properties
    $edge.Weight = $Weight
    $edge.Metadata = $Metadata
    
    return $edge
}

function New-CPGraph {
    <#
    .SYNOPSIS
    Creates a new CPG graph instance.
    #>
    [CmdletBinding()]
    param(
        [string]$Name = "Graph-$([guid]::NewGuid().ToString().Substring(0,8))",
        [hashtable]$Metadata = @{}
    )
    
    $graph = [CPGraph]::new($Name)
    $graph.Metadata = $Metadata
    
    return $graph
}

function Add-CPGNode {
    <#
    .SYNOPSIS
    Adds a node to the specified CPG graph.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph,
        
        [Parameter(Mandatory)]
        [CPGNode]$Node
    )
    
    if ($Graph.Nodes.ContainsKey($Node.Id)) {
        Write-Warning "Node with ID '$($Node.Id)' already exists in graph '$($Graph.Name)'"
        return $false
    }
    
    $Graph.Nodes[$Node.Id] = $Node
    $Graph.AdjacencyList[$Node.Id] = @{
        Outgoing = @()
        Incoming = @()
    }
    $Graph.UpdateModifiedTime()
    
    return $true
}

function Add-CPGEdge {
    <#
    .SYNOPSIS
    Adds an edge to the specified CPG graph.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph,
        
        [Parameter(Mandatory)]
        [CPGEdge]$Edge
    )
    
    # Validate source and target nodes exist
    if (-not $Graph.Nodes.ContainsKey($Edge.SourceId)) {
        throw "Source node '$($Edge.SourceId)' does not exist in graph"
    }
    
    if (-not $Graph.Nodes.ContainsKey($Edge.TargetId)) {
        throw "Target node '$($Edge.TargetId)' does not exist in graph"
    }
    
    if ($Graph.Edges.ContainsKey($Edge.Id)) {
        Write-Warning "Edge with ID '$($Edge.Id)' already exists in graph '$($Graph.Name)'"
        return $false
    }
    
    $Graph.Edges[$Edge.Id] = $Edge
    
    # Update adjacency list
    $Graph.AdjacencyList[$Edge.SourceId].Outgoing += $Edge.Id
    $Graph.AdjacencyList[$Edge.TargetId].Incoming += $Edge.Id
    
    if ($Edge.Direction -eq [EdgeDirection]::Bidirectional) {
        $Graph.AdjacencyList[$Edge.TargetId].Outgoing += $Edge.Id
        $Graph.AdjacencyList[$Edge.SourceId].Incoming += $Edge.Id
    }
    
    $Graph.UpdateModifiedTime()
    return $true
}

Export-ModuleMember -Function @(
    'New-CPGNode',
    'New-CPGEdge',
    'New-CPGraph',
    'Add-CPGNode',
    'Add-CPGEdge'
)

# REFACTORING MARKER: This module was refactored from Unity-Claude-CPG.psm1 on 2025-08-25
# Original file size: 1013 lines  
# This component: Basic graph operations (node/edge/graph creation and addition)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCWDZh1HHeLZf2L
# viE2B67pyrP7vfTkgGd8jiQd1eLnK6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICym7y1XW5ao6bFuCrdbCR+V
# ALABkcMHpBFd4UB1DSxSMA0GCSqGSIb3DQEBAQUABIIBAKmW+Ac7d535XtbuN48O
# sIRQ5KBgnvPKr4EInmNnpUVs3uWDtlePC3yro05oSggNcVWvx8udQzLfnZlYKQvj
# k+edivTG/iDm+C0jEBcTuICc5CEXZUisYmr2NICcCRUewl7QFbHICJ55Jh0qxecA
# YlJ/N1oqxGyx2quHHTw8hpdBzHA3+B1IxMc3RFy53QH5OFUoQAwjI4N2eFSQOme1
# 6/4gXRQe2KQmd+D0vxPTczotmXZ4dE0pCLmYENg7tM8/cwI9ivfLKLT3bvmf7/hP
# KLdyc1cdWqfSWc8P5K8cXop3AUApWsOMoH0y/ufpb8KTEwmwZPoHSpbOR3jPLr4V
# Fmk=
# SIG # End signature block
