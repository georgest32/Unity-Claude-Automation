#Requires -Version 5.1
<#
.SYNOPSIS
    Code Property Graph (CPG) module for relationship mapping and code analysis.

.DESCRIPTION
    *** REFACTORED *** This monolithic module has been refactored into modular components.
    See Unity-Claude-CPG-Refactored.psm1 for the new architecture.
    
    Original implementation that merges AST, CFG, and PDG for comprehensive
    code analysis, relationship mapping, and obsolescence detection.
    Based on Joern architecture with PowerShell-specific optimizations.

.NOTES
    Version: 1.0.0 (Original - Now Refactored)
    Author: Unity-Claude Automation System
    Date: 2025-08-24
    Refactored: 2025-08-25
    
    REFACTORING MARKER: This 1013-line monolithic module was refactored on 2025-08-25
    New architecture: 6 focused components in Core/ subdirectory
    Use Unity-Claude-CPG-Refactored.psm1 going forward
#>

# === REFACTORING DEBUG LOG ===
Write-Warning "⚠️ LOADING MONOLITHIC VERSION: Unity-Claude-CPG.psm1 (1013 lines) - This should be using the refactored version!"
Write-Host "📍 Expected: Unity-Claude-CPG-Refactored.psm1 with Core/ components should be loaded instead." -ForegroundColor Red

# --- Module loading handled by NestedModules in manifest ---
# ASTConverter functions are loaded automatically via NestedModules
# But we also import it explicitly to ensure functions are available
$astConverterPath = Join-Path $PSScriptRoot "Unity-Claude-CPG-ASTConverter.psm1"
if (Test-Path $astConverterPath) {
    Import-Module $astConverterPath -Force -Global
}

# Module-level variables for thread-safe graph storage
$script:CPGStorage = [hashtable]::Synchronized(@{})
$script:NodeIndex = [hashtable]::Synchronized(@{})
$script:EdgeIndex = [hashtable]::Synchronized(@{})
$script:GraphMetadata = [hashtable]::Synchronized(@{})
$script:CPGLock = [System.Threading.ReaderWriterLock]::new()

# Node type enumeration
enum CPGNodeType {
    Module
    Function
    Class
    Method
    Variable
    Parameter
    File
    Property
    Field
    Namespace
    Interface
    Enum
    Constant
    Label
    Comment
    Unknown
}

# Edge type enumeration
enum CPGEdgeType {
    Calls           # Function/method calls
    Uses            # Variable usage
    Imports         # Module imports
    Extends         # Class inheritance
    Implements      # Interface implementation
    DependsOn       # General dependency
    References      # Object references
    Assigns         # Variable assignment
    Returns         # Return values
    Throws          # Exception throwing
    Catches         # Exception handling
    Contains        # Containment relationship
    Follows         # Control flow
    DataFlow        # Data flow
    Overrides       # Method overriding
}

# Edge direction enumeration
enum EdgeDirection {
    Forward
    Backward
    Bidirectional
}

class CPGNode {
    [string]$Id
    [string]$Name
    [CPGNodeType]$Type
    [hashtable]$Properties
    [string]$FilePath
    [int]$StartLine
    [int]$EndLine
    [int]$StartColumn
    [int]$EndColumn
    [string]$Language
    [datetime]$CreatedAt
    [datetime]$ModifiedAt
    [hashtable]$Metadata
    
    CPGNode() {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Properties = @{}
        $this.Metadata = @{}
        $this.CreatedAt = Get-Date
        $this.ModifiedAt = Get-Date
    }
    
    CPGNode([string]$name, [CPGNodeType]$type) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Name = $name
        $this.Type = $type
        $this.Properties = @{}
        $this.Metadata = @{}
        $this.CreatedAt = Get-Date
        $this.ModifiedAt = Get-Date
    }
    
    [string] ToString() {
        return "$($this.Type)::$($this.Name)"
    }
    
    [hashtable] ToHashtable() {
        return @{
            Id = $this.Id
            Name = $this.Name
            Type = $this.Type.ToString()
            Properties = $this.Properties
            FilePath = $this.FilePath
            StartLine = $this.StartLine
            EndLine = $this.EndLine
            StartColumn = $this.StartColumn
            EndColumn = $this.EndColumn
            Language = $this.Language
            CreatedAt = $this.CreatedAt
            ModifiedAt = $this.ModifiedAt
            Metadata = $this.Metadata
        }
    }
}

class CPGEdge {
    [string]$Id
    [string]$SourceId
    [string]$TargetId
    [CPGEdgeType]$Type
    [EdgeDirection]$Direction
    [hashtable]$Properties
    [double]$Weight
    [datetime]$CreatedAt
    [hashtable]$Metadata
    
    CPGEdge() {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Properties = @{}
        $this.Metadata = @{}
        $this.Weight = 1.0
        $this.Direction = [EdgeDirection]::Forward
        $this.CreatedAt = Get-Date
    }
    
    CPGEdge([string]$sourceId, [string]$targetId, [CPGEdgeType]$type) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.SourceId = $sourceId
        $this.TargetId = $targetId
        $this.Type = $type
        $this.Properties = @{}
        $this.Metadata = @{}
        $this.Weight = 1.0
        $this.Direction = [EdgeDirection]::Forward
        $this.CreatedAt = Get-Date
    }
    
    [string] ToString() {
        return "$($this.SourceId) -[$($this.Type)]-> $($this.TargetId)"
    }
    
    [hashtable] ToHashtable() {
        return @{
            Id = $this.Id
            SourceId = $this.SourceId
            TargetId = $this.TargetId
            Type = $this.Type.ToString()
            Direction = $this.Direction.ToString()
            Properties = $this.Properties
            Weight = $this.Weight
            CreatedAt = $this.CreatedAt
            Metadata = $this.Metadata
        }
    }
}

class CPGraph {
    [string]$Id
    [string]$Name
    [hashtable]$Nodes
    [hashtable]$Edges
    [hashtable]$AdjacencyList
    [hashtable]$Metadata
    [datetime]$CreatedAt
    [datetime]$ModifiedAt
    [int]$Version
    
    CPGraph() {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Nodes = [hashtable]::Synchronized(@{})
        $this.Edges = [hashtable]::Synchronized(@{})
        $this.AdjacencyList = [hashtable]::Synchronized(@{})
        $this.Metadata = @{}
        $this.CreatedAt = Get-Date
        $this.ModifiedAt = Get-Date
        $this.Version = 1
    }
    
    CPGraph([string]$name) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Name = $name
        $this.Nodes = [hashtable]::Synchronized(@{})
        $this.Edges = [hashtable]::Synchronized(@{})
        $this.AdjacencyList = [hashtable]::Synchronized(@{})
        $this.Metadata = @{}
        $this.CreatedAt = Get-Date
        $this.ModifiedAt = Get-Date
        $this.Version = 1
    }
    
    [void] AddNode([CPGNode]$node) {
        $this.Nodes[$node.Id] = $node
        if (-not $this.AdjacencyList.ContainsKey($node.Id)) {
            $this.AdjacencyList[$node.Id] = @{
                Incoming = @()
                Outgoing = @()
            }
        }
        $this.ModifiedAt = Get-Date
    }
    
    [void] AddEdge([CPGEdge]$edge) {
        $this.Edges[$edge.Id] = $edge
        
        # Update adjacency list
        if ($this.AdjacencyList.ContainsKey($edge.SourceId)) {
            $this.AdjacencyList[$edge.SourceId].Outgoing += $edge.Id
        }
        if ($this.AdjacencyList.ContainsKey($edge.TargetId)) {
            $this.AdjacencyList[$edge.TargetId].Incoming += $edge.Id
        }
        
        # Handle bidirectional edges
        if ($edge.Direction -eq [EdgeDirection]::Bidirectional) {
            if ($this.AdjacencyList.ContainsKey($edge.TargetId)) {
                $this.AdjacencyList[$edge.TargetId].Outgoing += $edge.Id
            }
            if ($this.AdjacencyList.ContainsKey($edge.SourceId)) {
                $this.AdjacencyList[$edge.SourceId].Incoming += $edge.Id
            }
        }
        
        $this.ModifiedAt = Get-Date
    }
    
    [CPGNode] GetNode([string]$nodeId) {
        return $this.Nodes[$nodeId]
    }
    
    [CPGEdge] GetEdge([string]$edgeId) {
        return $this.Edges[$edgeId]
    }
    
    [CPGNode[]] GetNodesByType([CPGNodeType]$type) {
        return $this.Nodes.Values | Where-Object { $_.Type -eq $type }
    }
    
    [CPGEdge[]] GetEdgesByType([CPGEdgeType]$type) {
        return $this.Edges.Values | Where-Object { $_.Type -eq $type }
    }
    
    [CPGNode[]] GetNeighbors([string]$nodeId, [EdgeDirection]$direction) {
        $neighbors = @()
        
        if (-not $this.AdjacencyList.ContainsKey($nodeId)) {
            return $neighbors
        }
        
        $edgeIds = @()
        switch ($direction) {
            ([EdgeDirection]::Forward) {
                $edgeIds = $this.AdjacencyList[$nodeId].Outgoing
            }
            ([EdgeDirection]::Backward) {
                $edgeIds = $this.AdjacencyList[$nodeId].Incoming
            }
            ([EdgeDirection]::Bidirectional) {
                $edgeIds = $this.AdjacencyList[$nodeId].Outgoing + $this.AdjacencyList[$nodeId].Incoming
            }
        }
        
        foreach ($edgeId in $edgeIds) {
            $edge = $this.Edges[$edgeId]
            if ($edge.SourceId -eq $nodeId -and $this.Nodes.ContainsKey($edge.TargetId)) {
                $neighbors += $this.Nodes[$edge.TargetId]
            }
            elseif ($edge.TargetId -eq $nodeId -and $this.Nodes.ContainsKey($edge.SourceId)) {
                $neighbors += $this.Nodes[$edge.SourceId]
            }
        }
        
        return $neighbors | Select-Object -Unique
    }
    
    [hashtable] GetStatistics() {
        return @{
            NodeCount = $this.Nodes.Count
            EdgeCount = $this.Edges.Count
            NodeTypes = $this.Nodes.Values | Group-Object -Property Type | 
                        Select-Object Name, Count
            EdgeTypes = $this.Edges.Values | Group-Object -Property Type | 
                        Select-Object Name, Count
            AverageOutDegree = if ($this.Nodes.Count -gt 0) {
                ($this.AdjacencyList.Values | ForEach-Object { $_.Outgoing.Count } | 
                 Measure-Object -Average).Average
            } else { 0 }
            AverageInDegree = if ($this.Nodes.Count -gt 0) {
                ($this.AdjacencyList.Values | ForEach-Object { $_.Incoming.Count } | 
                 Measure-Object -Average).Average
            } else { 0 }
        }
    }
    
    [hashtable] ToHashtable() {
        return @{
            Id = $this.Id
            Name = $this.Name
            Nodes = $this.Nodes.Values | ForEach-Object { $_.ToHashtable() }
            Edges = $this.Edges.Values | ForEach-Object { $_.ToHashtable() }
            Metadata = $this.Metadata
            CreatedAt = $this.CreatedAt
            ModifiedAt = $this.ModifiedAt
            Version = $this.Version
            Statistics = $this.GetStatistics()
        }
    }
}

function New-CPGNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [CPGNodeType]$Type,
        
        [hashtable]$Properties = @{},
        
        [string]$FilePath,
        
        [int]$StartLine,
        
        [int]$EndLine,
        
        [string]$Language = "PowerShell",
        
        [hashtable]$Metadata = @{}
    )
    
    Write-Verbose "Creating CPG node: $Name of type $Type"
    
    $node = [CPGNode]::new($Name, $Type)
    $node.Properties = $Properties
    $node.FilePath = $FilePath
    $node.StartLine = $StartLine
    $node.EndLine = $EndLine
    $node.Language = $Language
    $node.Metadata = $Metadata
    
    # Add to global index
    $script:NodeIndex[$node.Id] = $node
    
    Write-Verbose "Created node with ID: $($node.Id)"
    return $node
}

function New-CPGEdge {
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
    
    Write-Verbose "Creating CPG edge: $SourceId -[$Type]-> $TargetId"
    
    $edge = [CPGEdge]::new($SourceId, $TargetId, $Type)
    $edge.Direction = $Direction
    $edge.Properties = $Properties
    $edge.Weight = $Weight
    $edge.Metadata = $Metadata
    
    # Add to global index
    $script:EdgeIndex[$edge.Id] = $edge
    
    Write-Verbose "Created edge with ID: $($edge.Id)"
    return $edge
}

function New-CPGraph {
    [CmdletBinding()]
    param(
        [string]$Name = "Default",
        
        [hashtable]$Metadata = @{}
    )
    
    Write-Verbose "Creating new CPG graph: $Name"
    
    $graph = [CPGraph]::new($Name)
    $graph.Metadata = $Metadata
    
    # Store in global storage
    $script:CPGStorage[$graph.Id] = $graph
    $script:GraphMetadata[$graph.Id] = @{
        Name = $Name
        CreatedAt = $graph.CreatedAt
        NodeCount = 0
        EdgeCount = 0
    }
    
    Write-Verbose "Created graph with ID: $($graph.Id)"
    return $graph
}

function Add-CPGNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph,
        
        [Parameter(Mandatory)]
        [CPGNode]$Node
    )
    
    try {
        $script:CPGLock.AcquireWriterLock(1000)
        
        $Graph.AddNode($Node)
        $script:GraphMetadata[$Graph.Id].NodeCount = $Graph.Nodes.Count
        $script:GraphMetadata[$Graph.Id].ModifiedAt = Get-Date
        
        Write-Verbose "Added node $($Node.Id) to graph $($Graph.Id)"
    }
    finally {
        if ($script:CPGLock.IsWriterLockHeld) {
            $script:CPGLock.ReleaseWriterLock()
        }
    }
}

function Add-CPGEdge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph,
        
        [Parameter(Mandatory)]
        [CPGEdge]$Edge
    )
    
    try {
        $script:CPGLock.AcquireWriterLock(1000)
        
        # Verify nodes exist
        if (-not $Graph.Nodes.ContainsKey($Edge.SourceId)) {
            throw "Source node $($Edge.SourceId) not found in graph"
        }
        if (-not $Graph.Nodes.ContainsKey($Edge.TargetId)) {
            throw "Target node $($Edge.TargetId) not found in graph"
        }
        
        $Graph.AddEdge($Edge)
        $script:GraphMetadata[$Graph.Id].EdgeCount = $Graph.Edges.Count
        $script:GraphMetadata[$Graph.Id].ModifiedAt = Get-Date
        
        Write-Verbose "Added edge $($Edge.Id) to graph $($Graph.Id)"
    }
    finally {
        if ($script:CPGLock.IsWriterLockHeld) {
            $script:CPGLock.ReleaseWriterLock()
        }
    }
}

function Get-CPGNode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph,
        
        [string]$NodeId,
        
        [string]$Name,
        
        [CPGNodeType]$Type
    )
    
    try {
        $script:CPGLock.AcquireReaderLock(1000)
        
        if ($NodeId) {
            return $Graph.GetNode($NodeId)
        }
        
        $nodes = $Graph.Nodes.Values
        
        if ($Name) {
            $nodes = $nodes | Where-Object { $_.Name -eq $Name }
        }
        
        if ($Type) {
            $nodes = $nodes | Where-Object { $_.Type -eq $Type }
        }
        
        return $nodes
    }
    finally {
        if ($script:CPGLock.IsReaderLockHeld) {
            $script:CPGLock.ReleaseReaderLock()
        }
    }
}

function Get-CPGEdge {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph,
        
        [string]$EdgeId,
        
        [string]$SourceId,
        
        [string]$TargetId,
        
        [CPGEdgeType]$Type
    )
    
    try {
        $script:CPGLock.AcquireReaderLock(1000)
        
        if ($EdgeId) {
            return $Graph.GetEdge($EdgeId)
        }
        
        $edges = $Graph.Edges.Values
        
        if ($SourceId) {
            $edges = $edges | Where-Object { $_.SourceId -eq $SourceId }
        }
        
        if ($TargetId) {
            $edges = $edges | Where-Object { $_.TargetId -eq $TargetId }
        }
        
        if ($PSBoundParameters.ContainsKey('Type')) {
            Write-Verbose "Filtering edges by type: $Type"
            $edges = $edges | Where-Object { 
                $result = $_.Type -eq $Type
                Write-Verbose "  Edge $($_.Id) type $($_.Type) eq $Type = $result"
                $result
            }
        }
        
        return $edges
    }
    finally {
        if ($script:CPGLock.IsReaderLockHeld) {
            $script:CPGLock.ReleaseReaderLock()
        }
    }
}

function Get-CPGNeighbors {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph,
        
        [Parameter(Mandatory)]
        [string]$NodeId,
        
        [EdgeDirection]$Direction = [EdgeDirection]::Forward,
        
        [CPGEdgeType]$EdgeType,
        
        [int]$MaxDepth = 1
    )
    
    try {
        $script:CPGLock.AcquireReaderLock(1000)
        
        $visited = @{}
        $queue = [System.Collections.Queue]::new()
        $queue.Enqueue(@{Id = $NodeId; Depth = 0})
        $neighbors = @()
        
        while ($queue.Count -gt 0) {
            $current = $queue.Dequeue()
            
            if ($visited.ContainsKey($current.Id) -or $current.Depth -gt $MaxDepth) {
                continue
            }
            
            $visited[$current.Id] = $true
            
            if ($current.Depth -gt 0) {
                $neighbors += $Graph.GetNode($current.Id)
            }
            
            if ($current.Depth -lt $MaxDepth) {
                $edges = $Graph.Edges.Values | Where-Object {
                    ($_.SourceId -eq $current.Id -or 
                     ($Direction -eq [EdgeDirection]::Bidirectional -and $_.TargetId -eq $current.Id)) -and
                    (-not $EdgeType -or $_.Type -eq $EdgeType)
                }
                
                foreach ($edge in $edges) {
                    $nextId = if ($edge.SourceId -eq $current.Id) { $edge.TargetId } else { $edge.SourceId }
                    if (-not $visited.ContainsKey($nextId)) {
                        $queue.Enqueue(@{Id = $nextId; Depth = $current.Depth + 1})
                    }
                }
            }
        }
        
        return $neighbors
    }
    finally {
        if ($script:CPGLock.IsReaderLockHeld) {
            $script:CPGLock.ReleaseReaderLock()
        }
    }
}

function Find-CPGPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph,
        
        [Parameter(Mandatory)]
        [string]$StartNodeId,
        
        [Parameter(Mandatory)]
        [string]$EndNodeId,
        
        [CPGEdgeType]$EdgeType,
        
        [int]$MaxDepth = 10
    )
    
    try {
        $script:CPGLock.AcquireReaderLock(1000)
        
        # BFS to find shortest path
        $queue = [System.Collections.Queue]::new()
        $visited = @{}
        $parent = @{}
        
        $queue.Enqueue($StartNodeId)
        $visited[$StartNodeId] = $true
        
        while ($queue.Count -gt 0) {
            $current = $queue.Dequeue()
            
            if ($current -eq $EndNodeId) {
                # Reconstruct path
                $path = @()
                $node = $EndNodeId
                
                while ($node) {
                    $path = @($Graph.GetNode($node)) + $path
                    $node = $parent[$node]
                }
                
                return $path
            }
            
            $edges = $Graph.Edges.Values | Where-Object {
                $_.SourceId -eq $current -and
                (-not $EdgeType -or $_.Type -eq $EdgeType)
            }
            
            foreach ($edge in $edges) {
                if (-not $visited.ContainsKey($edge.TargetId)) {
                    $visited[$edge.TargetId] = $true
                    $parent[$edge.TargetId] = $current
                    $queue.Enqueue($edge.TargetId)
                }
            }
        }
        
        return $null  # No path found
    }
    finally {
        if ($script:CPGLock.IsReaderLockHeld) {
            $script:CPGLock.ReleaseReaderLock()
        }
    }
}

function Get-CPGStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph
    )
    
    try {
        $script:CPGLock.AcquireReaderLock(1000)
        
        $stats = $Graph.GetStatistics()
        
        # Add additional metrics
        $stats.IsolatedNodes = ($Graph.Nodes.Values | Where-Object {
            $nodeId = $_.Id
            $edges = $Graph.Edges.Values | Where-Object {
                $_.SourceId -eq $nodeId -or $_.TargetId -eq $nodeId
            }
            $edges.Count -eq 0
        }).Count
        
        $stats.StronglyConnected = Test-CPGStronglyConnected -Graph $Graph
        $stats.Density = if ($Graph.Nodes.Count -gt 1) {
            $maxEdges = $Graph.Nodes.Count * ($Graph.Nodes.Count - 1)
            [Math]::Round($Graph.Edges.Count / $maxEdges, 4)
        } else { 0 }
        
        return $stats
    }
    finally {
        if ($script:CPGLock.IsReaderLockHeld) {
            $script:CPGLock.ReleaseReaderLock()
        }
    }
}

function Test-CPGStronglyConnected {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph
    )
    
    # Tarjan's algorithm for strongly connected components
    # Simplified check - returns true if entire graph is strongly connected
    
    if ($Graph.Nodes.Count -eq 0) {
        return $true
    }
    
    # For now, return false for simplicity
    # Full implementation would use Tarjan's or Kosaraju's algorithm
    return $false
}

function Export-CPGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CPGraph]$Graph,
        
        [Parameter(Mandatory)]
        [string]$Path,
        
        [ValidateSet('JSON', 'DOT', 'GraphML')]
        [string]$Format = 'JSON'
    )
    
    Write-Verbose "Exporting graph $($Graph.Id) to $Path as $Format"
    
    switch ($Format) {
        'JSON' {
            $Graph.ToHashtable() | ConvertTo-Json -Depth 10 | 
                Out-File -FilePath $Path -Encoding UTF8
        }
        
        'DOT' {
            $dot = @()
            $dot += "digraph $($Graph.Name -replace '\s', '_') {"
            
            # Add nodes
            foreach ($node in $Graph.Nodes.Values) {
                $label = "$($node.Type)\\n$($node.Name)"
                $dot += "  `"$($node.Id)`" [label=`"$label`"];"
            }
            
            # Add edges
            foreach ($edge in $Graph.Edges.Values) {
                $dot += "  `"$($edge.SourceId)`" -> `"$($edge.TargetId)`" [label=`"$($edge.Type)`"];"
            }
            
            $dot += "}"
            $dot -join "`n" | Out-File -FilePath $Path -Encoding UTF8
        }
        
        'GraphML' {
            # GraphML format for compatibility with graph visualization tools
            $xml = @()
            $xml += '<?xml version="1.0" encoding="UTF-8"?>'
            $xml += '<graphml xmlns="http://graphml.graphdrawing.org/xmlns">'
            $xml += '  <graph id="G" edgedefault="directed">'
            
            # Add nodes
            foreach ($node in $Graph.Nodes.Values) {
                $xml += "    <node id=`"$($node.Id)`">"
                $xml += "      <data key=`"name`">$($node.Name)</data>"
                $xml += "      <data key=`"type`">$($node.Type)</data>"
                $xml += "    </node>"
            }
            
            # Add edges
            foreach ($edge in $Graph.Edges.Values) {
                $xml += "    <edge source=`"$($edge.SourceId)`" target=`"$($edge.TargetId)`">"
                $xml += "      <data key=`"type`">$($edge.Type)</data>"
                $xml += "    </edge>"
            }
            
            $xml += '  </graph>'
            $xml += '</graphml>'
            $xml -join "`n" | Out-File -FilePath $Path -Encoding UTF8
        }
    }
    
    Write-Verbose "Graph exported successfully to $Path"
}

function Import-CPGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        throw "File not found: $Path"
    }
    
    Write-Verbose "Importing graph from $Path"
    
    $content = Get-Content -Path $Path -Raw
    $data = $content | ConvertFrom-Json
    
    $graph = New-CPGraph -Name $data.Name
    
    # Import nodes
    foreach ($nodeData in $data.Nodes) {
        $node = [CPGNode]::new()
        $node.Id = $nodeData.Id
        $node.Name = $nodeData.Name
        $node.Type = [CPGNodeType]::($nodeData.Type)
        $node.Properties = $nodeData.Properties
        $node.FilePath = $nodeData.FilePath
        $node.StartLine = $nodeData.StartLine
        $node.EndLine = $nodeData.EndLine
        $node.Language = $nodeData.Language
        
        Add-CPGNode -Graph $graph -Node $node
    }
    
    # Import edges
    foreach ($edgeData in $data.Edges) {
        $edge = [CPGEdge]::new()
        $edge.Id = $edgeData.Id
        $edge.SourceId = $edgeData.SourceId
        $edge.TargetId = $edgeData.TargetId
        $edge.Type = [CPGEdgeType]::($edgeData.Type)
        $edge.Direction = [EdgeDirection]::($edgeData.Direction)
        $edge.Properties = $edgeData.Properties
        $edge.Weight = $edgeData.Weight
        
        Add-CPGEdge -Graph $graph -Edge $edge
    }
    
    Write-Verbose "Graph imported successfully"
    return $graph
}

# ConvertTo-CPGFromScriptBlock helper function moved from AST Converter module
function ConvertTo-CPGFromScriptBlock {
    <#
    .SYNOPSIS
    Converts a PowerShell ScriptBlock to Code Property Graph (CPG) format.
    
    .DESCRIPTION
    Parses a PowerShell ScriptBlock into an AST and converts it to CPG format for analysis.
    Provides a synthetic file path for in-memory code snippets.
    
    .PARAMETER ScriptBlock
    The PowerShell ScriptBlock to convert
    
    .PARAMETER GraphName
    Name for the generated graph (optional)
    
    .PARAMETER IncludeDataFlow
    Include data flow edges in the graph
    
    .PARAMETER IncludeControlFlow
    Include control flow edges in the graph
    
    .PARAMETER PseudoPath
    Optional friendly pseudo path for the root file node
    
    .EXAMPLE
    $graph = ConvertTo-CPGFromScriptBlock -ScriptBlock { function Test { Write-Host "Hello" } }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock] $ScriptBlock,

        [string] $GraphName,
        [switch] $IncludeDataFlow,
        [switch] $IncludeControlFlow,

        # Optional friendly pseudo path for the root file node
        [string] $PseudoPath
    )

    # Parse the ScriptBlock to an AST
    $tokens = $null            # ✅ declare a real variable for tokens
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseInput(
        $ScriptBlock.ToString(),
        [ref]$tokens,           # ✅ pass a ref to a variable
        [ref]$parseErrors
    )

    if ($parseErrors -and $parseErrors.Count -gt 0) {
        throw ("ScriptBlock parse failed:`n" + ($parseErrors | ForEach-Object { $_.Message } | Out-String))
    }
    if (-not $ast) { throw "Parser returned null AST." }

    if (-not $PseudoPath) {
        $timestamp = (Get-Date).ToString('yyyyMMdd_HHmmss_ffff')
        $PseudoPath = "InMemory:$timestamp.ps1"
    }

    Write-Verbose "[CPG] Parsed scriptblock to AST; PseudoPath='$PseudoPath'"

    # Invoke the converter function directly (now available through nested module)
    $graph = Convert-ASTtoCPG `
        -AST $ast `
        -FilePath $PseudoPath `
        -GraphName $GraphName `
        -IncludeDataFlow:$IncludeDataFlow `
        -IncludeControlFlow:$IncludeControlFlow
    
    if (-not $graph) { throw "Convert-ASTtoCPG returned null graph." }
    return $graph
}

# Export public functions
Export-ModuleMember -Function @(
  # Core graph API (needed by ASTConverter)
  'New-CPGraph','New-CPGNode','Add-CPGNode','New-CPGEdge','Add-CPGEdge',
  'Get-CPGNode','Get-CPGEdge',

  # Optional but likely used elsewhere
  'Get-CPGNeighbors','Find-CPGPath','Get-CPGStatistics',
  'Export-CPGraph','Import-CPGraph',

  # Converter surface exposed via root
  'Convert-ASTtoCPG','ConvertTo-CPGFromFile','ConvertTo-CPGFromScriptBlock'
) -Variable @()
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAI48JsbPVTuA2n
# AVWT8mgWRl+nKRjBmG/xHf2dEIwenaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMzzf/m8ya4y/kNsddSYkzvl
# qyaBganZguy5Uv4lhLQUMA0GCSqGSIb3DQEBAQUABIIBADTHC5EAGIwPSgWVTbQq
# agOFFh1a1y1ZchGsziZBPch5qE85IsBekgWe1sSVlWeTnF7Hhs2GzKjEEUBSRQaW
# nnhDhzoR5rZsJSHtEr4F9oZYqzB7W27s2LXVb0NqPEmyX4knHLa9CJJi/QAj/vcq
# yZmMi91GtGnREOXKyxdiUUjUU/c+3OfK3+OkrJtux88erMJw3mPyojA+5DsdvSrx
# kciJw+2pTUaIjrCmbjawZYRr/+Xhbb54NWkfwvhYwIcunVsAZ38c12wIhQCIt2D7
# TI252y50ZC2uwc7Zz6RgdWBDYrL0s7is4s6B7nW3m5Ost8dQa4H7Avv1+wK7zxW7
# x6E=
# SIG # End signature block
