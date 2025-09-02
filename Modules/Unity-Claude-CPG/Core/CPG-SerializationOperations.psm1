#Requires -Version 5.1
<#
.SYNOPSIS
    Serialization operations for Code Property Graph (CPG) implementation.

.DESCRIPTION
    Contains functions for importing and exporting CPG structures to/from 
    various formats including JSON, XML, and GraphML.

.NOTES
    Part of Unity-Claude-CPG refactored architecture
    Originally from Unity-Claude-CPG.psm1 (lines 771-893)
    Refactoring Date: 2025-08-25
#>

# Import required data structures
using module .\CPG-DataStructures.psm1

function Export-CPGraph {
    <#
    .SYNOPSIS
    Exports a CPG graph to various formats.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph,
        
        [Parameter(Mandatory)]
        [string]$Path,
        
        [ValidateSet('JSON', 'XML', 'GraphML', 'DOT')]
        [string]$Format = 'JSON',
        
        [switch]$IncludeMetadata,
        [switch]$Compress
    )
    
    $exportData = @{
        GraphInfo = $Graph.ToHashtable()
        Nodes = @()
        Edges = @()
        ExportedAt = Get-Date
        Format = $Format
    }
    
    # Export nodes
    foreach ($node in $Graph.Nodes.Values) {
        $nodeData = $node.ToHashtable()
        if (-not $IncludeMetadata) {
            $nodeData.Remove('Metadata')
        }
        $exportData.Nodes += $nodeData
    }
    
    # Export edges
    foreach ($edge in $Graph.Edges.Values) {
        $edgeData = $edge.ToHashtable()
        if (-not $IncludeMetadata) {
            $edgeData.Remove('Metadata')
        }
        $exportData.Edges += $edgeData
    }
    
    # Convert to specified format
    switch ($Format) {
        'JSON' {
            $content = $exportData | ConvertTo-Json -Depth 10
        }
        'XML' {
            # Convert to XML format
            $content = Export-ToXML -Data $exportData
        }
        'GraphML' {
            # Convert to GraphML format
            $content = Export-ToGraphML -Graph $Graph -IncludeMetadata:$IncludeMetadata
        }
        'DOT' {
            # Convert to DOT format for Graphviz
            $content = Export-ToDOT -Graph $Graph
        }
    }
    
    # Write to file
    if ($Compress) {
        # TODO: Implement compression
        $content | Out-File -FilePath $Path -Encoding UTF8
    } else {
        $content | Out-File -FilePath $Path -Encoding UTF8
    }
    
    return @{
        Path = $Path
        Format = $Format
        NodeCount = $exportData.Nodes.Count
        EdgeCount = $exportData.Edges.Count
        ExportedAt = $exportData.ExportedAt
    }
}

function Import-CPGraph {
    <#
    .SYNOPSIS
    Imports a CPG graph from various formats.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [ValidateSet('JSON', 'XML', 'GraphML')]
        [string]$Format = 'JSON',
        
        [string]$GraphName
    )
    
    if (-not (Test-Path $Path)) {
        throw "File not found: $Path"
    }
    
    $content = Get-Content -Path $Path -Raw
    
    # Parse content based on format
    switch ($Format) {
        'JSON' {
            $data = $content | ConvertFrom-Json
        }
        'XML' {
            $data = Import-FromXML -Content $content
        }
        'GraphML' {
            $data = Import-FromGraphML -Content $content
        }
    }
    
    # Create new graph
    $graph = [CPGraph]::new()
    if ($GraphName) {
        $graph.Name = $GraphName
    } elseif ($data.GraphInfo -and $data.GraphInfo.Name) {
        $graph.Name = $data.GraphInfo.Name
    }
    
    # Import nodes
    foreach ($nodeData in $data.Nodes) {
        $node = [CPGNode]::new()
        $node.Id = $nodeData.Id
        $node.Name = $nodeData.Name
        $node.Type = [CPGNodeType]$nodeData.Type
        $node.Properties = $nodeData.Properties
        $node.FilePath = $nodeData.FilePath
        $node.StartLine = $nodeData.StartLine
        $node.EndLine = $nodeData.EndLine
        $node.StartColumn = $nodeData.StartColumn
        $node.EndColumn = $nodeData.EndColumn
        $node.Language = $nodeData.Language
        $node.CreatedAt = $nodeData.CreatedAt
        $node.ModifiedAt = $nodeData.ModifiedAt
        $node.Metadata = $nodeData.Metadata
        
        $graph.Nodes[$node.Id] = $node
        $graph.AdjacencyList[$node.Id] = @{
            Outgoing = @()
            Incoming = @()
        }
    }
    
    # Import edges
    foreach ($edgeData in $data.Edges) {
        $edge = [CPGEdge]::new()
        $edge.Id = $edgeData.Id
        $edge.SourceId = $edgeData.SourceId
        $edge.TargetId = $edgeData.TargetId
        $edge.Type = [CPGEdgeType]$edgeData.Type
        $edge.Direction = [EdgeDirection]$edgeData.Direction
        $edge.Properties = $edgeData.Properties
        $edge.Weight = $edgeData.Weight
        $edge.CreatedAt = $edgeData.CreatedAt
        $edge.Metadata = $edgeData.Metadata
        
        $graph.Edges[$edge.Id] = $edge
        
        # Update adjacency list
        $graph.AdjacencyList[$edge.SourceId].Outgoing += $edge.Id
        $graph.AdjacencyList[$edge.TargetId].Incoming += $edge.Id
        
        if ($edge.Direction -eq [EdgeDirection]::Bidirectional) {
            $graph.AdjacencyList[$edge.TargetId].Outgoing += $edge.Id
            $graph.AdjacencyList[$edge.SourceId].Incoming += $edge.Id
        }
    }
    
    return $graph
}

function Export-ToGraphML {
    <#
    .SYNOPSIS
    Helper function to export graph to GraphML format.
    #>
    param(
        [CPGraph]$Graph,
        [switch]$IncludeMetadata
    )
    
    $xml = @"
<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns
         http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">
  
  <!-- Key definitions -->
  <key id="name" for="node" attr.name="name" attr.type="string"/>
  <key id="type" for="node" attr.name="type" attr.type="string"/>
  <key id="filepath" for="node" attr.name="filepath" attr.type="string"/>
  <key id="edgetype" for="edge" attr.name="type" attr.type="string"/>
  <key id="weight" for="edge" attr.name="weight" attr.type="double"/>

  <graph id="$($Graph.Id)" edgedefault="directed">
"@
    
    # Add nodes
    foreach ($node in $Graph.Nodes.Values) {
        $xml += "`n    <node id=`"$($node.Id)`">"
        $xml += "`n      <data key=`"name`">$($node.Name)</data>"
        $xml += "`n      <data key=`"type`">$($node.Type)</data>"
        if ($node.FilePath) {
            $xml += "`n      <data key=`"filepath`">$($node.FilePath)</data>"
        }
        $xml += "`n    </node>"
    }
    
    # Add edges
    foreach ($edge in $Graph.Edges.Values) {
        $xml += "`n    <edge id=`"$($edge.Id)`" source=`"$($edge.SourceId)`" target=`"$($edge.TargetId)`">"
        $xml += "`n      <data key=`"edgetype`">$($edge.Type)</data>"
        $xml += "`n      <data key=`"weight`">$($edge.Weight)</data>"
        $xml += "`n    </edge>"
    }
    
    $xml += "`n  </graph>`n</graphml>"
    return $xml
}

function Export-ToDOT {
    <#
    .SYNOPSIS
    Helper function to export graph to DOT format.
    #>
    param(
        [CPGraph]$Graph
    )
    
    $dot = "digraph `"$($Graph.Name)`" {`n"
    $dot += "  rankdir=TB;`n"
    $dot += "  node [shape=box];`n`n"
    
    # Add nodes
    foreach ($node in $Graph.Nodes.Values) {
        $label = "$($node.Name)\n($($node.Type))"
        $dot += "  `"$($node.Id)`" [label=`"$label`"];`n"
    }
    
    $dot += "`n"
    
    # Add edges
    foreach ($edge in $Graph.Edges.Values) {
        $dot += "  `"$($edge.SourceId)`" -> `"$($edge.TargetId)`" [label=`"$($edge.Type)`"];`n"
    }
    
    $dot += "}"
    return $dot
}

Export-ModuleMember -Function @(
    'Export-CPGraph',
    'Import-CPGraph'
)

# REFACTORING MARKER: This module was refactored from Unity-Claude-CPG.psm1 on 2025-08-25
# Original file size: 1013 lines
# This component: Graph serialization and import/export operations
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBum3mZxKpjhpc0
# 9ZsK4kadP+4KFbw49MloCndVVEDmk6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOewFl2/zwjEDahI7KRxWhm/
# GLFTEsnCqIum3LGXPB0WMA0GCSqGSIb3DQEBAQUABIIBAIFTG1R/gUNlPIl4A5c2
# JEKCfw0f6hot7xf9Sh7+9Z8zL5LIEE3cSzCv7KA1k2ZhObGzhoZF1cg5Ku/vQa8G
# 72HvXiXwDrScFUP0rVCkmLLOMHYZCR7m+0umUPcl3VVndjYhlWbG4wybBy/KdC+e
# GoZJB6eu4BI1sR0SnKpZH5ZddpDAVQDX49R6ppkqLjGZLtKg/gi+fBCujQmCkU3x
# 6rWj2eX4YKxLv+LutQWjZXbiNwMmo8oehya/xgnHRnHJCBU7vSRyWhGf0+1iCXCu
# /Oek5GOuAMCX2W9wqhQlCIrljXWo4WUx1GrGw9xkjv/8ArRVsVg64/KMbCZWrT+n
# kqw=
# SIG # End signature block
