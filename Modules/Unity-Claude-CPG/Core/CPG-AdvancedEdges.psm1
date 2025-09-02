#Requires -Version 5.1
<#
.SYNOPSIS
    Advanced edge types for Code Property Graph (CPG) implementation.

.DESCRIPTION
    Implements specialized edge types for data flow, control flow, inheritance,
    implementation, and composition relationships in the CPG system.

.NOTES
    Part of Enhanced Documentation System Second Pass Implementation
    Week 1, Day 1 - Afternoon Session
    Created: 2025-08-28
#>

# Load the data structures module to import classes
if (Test-Path "$PSScriptRoot\CPG-DataStructures.psm1") {
    . "$PSScriptRoot\CPG-DataStructures.psm1"
} else {
    Write-Warning "CPG-DataStructures.psm1 not found. Using simplified edge types."
}

# Advanced Edge Type Enumeration (extends base CPGEdgeType)
enum AdvancedEdgeType {
    # Data Flow Edges
    DataFlowDirect      # Direct data flow between variables
    DataFlowIndirect    # Indirect data flow through references
    DataFlowParameter   # Data flow through function parameters
    DataFlowReturn      # Data flow through return values
    DataFlowField       # Data flow through object fields
    DataFlowGlobal      # Data flow through global state
    
    # Control Flow Edges
    ControlFlowSequential   # Sequential execution
    ControlFlowConditional  # Conditional branches (if/else)
    ControlFlowLoop         # Loop constructs
    ControlFlowSwitch       # Switch/case statements
    ControlFlowException    # Exception flow
    ControlFlowJump         # Goto/break/continue
    ControlFlowParallel     # Parallel execution paths
    
    # Inheritance Edges
    InheritanceExtends      # Class extension
    InheritanceImplements   # Interface implementation
    InheritanceOverrides    # Method overriding
    InheritanceAbstract     # Abstract class inheritance
    InheritanceMixin        # Mixin/trait inheritance
    
    # Implementation Edges
    ImplementationInterface # Interface implementation
    ImplementationProtocol  # Protocol conformance
    ImplementationContract  # Contract implementation
    ImplementationDelegate  # Delegation pattern
    
    # Composition Edges
    CompositionHasA         # Has-a relationship
    CompositionUsesA        # Uses-a relationship
    CompositionAggregation  # Aggregation relationship
    CompositionAssociation  # Association relationship
    CompositionDependency   # Dependency injection
}

# Data Flow Edge class
class DataFlowEdge {
    [AdvancedEdgeType]$AdvancedType
    [string]$DataType
    [bool]$IsMutable
    [bool]$IsAsync
    [string[]]$TransformationPath
    [hashtable]$FlowMetrics
    
    # Base edge properties
    [string]$Id
    [string]$SourceId
    [string]$TargetId
    [string]$Type = "DataFlow"
    [hashtable]$Properties
    [datetime]$CreatedAt
    
    DataFlowEdge([string]$sourceId, [string]$targetId, [AdvancedEdgeType]$advType) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.SourceId = $sourceId
        $this.TargetId = $targetId
        $this.AdvancedType = $advType
        $this.Properties = @{}
        $this.CreatedAt = Get-Date
        $this.FlowMetrics = @{
            Complexity = 0
            DataVolume = 0
            Frequency = 0
        }
        $this.TransformationPath = @()
    }
    
    [void] AddTransformation([string]$transformation) {
        $this.TransformationPath += $transformation
        $this.FlowMetrics.Complexity++
    }
    
    [hashtable] AnalyzeFlow() {
        return @{
            Type = $this.AdvancedType.ToString()
            DataType = $this.DataType
            IsMutable = $this.IsMutable
            IsAsync = $this.IsAsync
            Transformations = $this.TransformationPath.Count
            Metrics = $this.FlowMetrics
        }
    }
}

# Control Flow Edge class
class ControlFlowEdge {
    [AdvancedEdgeType]$AdvancedType
    [string]$Condition
    [double]$ExecutionProbability
    [bool]$IsConditional
    [bool]$IsLoop
    [hashtable]$BranchMetrics
    
    # Base edge properties
    [string]$Id
    [string]$SourceId
    [string]$TargetId
    [string]$Type = "ControlFlow"
    [hashtable]$Properties
    [datetime]$CreatedAt
    
    ControlFlowEdge([string]$sourceId, [string]$targetId, [AdvancedEdgeType]$advType) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.SourceId = $sourceId
        $this.TargetId = $targetId
        $this.AdvancedType = $advType
        $this.Properties = @{}
        $this.CreatedAt = Get-Date
        $this.ExecutionProbability = 1.0
        $this.IsConditional = $advType -in @([AdvancedEdgeType]::ControlFlowConditional, [AdvancedEdgeType]::ControlFlowSwitch)
        $this.IsLoop = $advType -eq [AdvancedEdgeType]::ControlFlowLoop
        $this.BranchMetrics = @{
            TrueBranches = 0
            FalseBranches = 0
            LoopIterations = 0
        }
    }
    
    [void] SetCondition([string]$condition) {
        $this.Condition = $condition
        $this.IsConditional = $true
    }
    
    [hashtable] AnalyzeControlFlow() {
        return @{
            Type = $this.AdvancedType.ToString()
            Condition = $this.Condition
            ExecutionProbability = $this.ExecutionProbability
            IsConditional = $this.IsConditional
            IsLoop = $this.IsLoop
            Metrics = $this.BranchMetrics
        }
    }
}

# Inheritance Edge class
class InheritanceEdge {
    [AdvancedEdgeType]$AdvancedType
    [string]$BaseType
    [string]$DerivedType
    [string[]]$InheritedMembers
    [string[]]$OverriddenMembers
    [bool]$IsAbstract
    [bool]$IsVirtual
    
    # Base edge properties
    [string]$Id
    [string]$SourceId
    [string]$TargetId
    [string]$Type = "Inheritance"
    [hashtable]$Properties
    [datetime]$CreatedAt
    
    InheritanceEdge([string]$sourceId, [string]$targetId, [AdvancedEdgeType]$advType) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.SourceId = $sourceId
        $this.TargetId = $targetId
        $this.AdvancedType = $advType
        $this.Properties = @{}
        $this.CreatedAt = Get-Date
        $this.InheritedMembers = @()
        $this.OverriddenMembers = @()
        $this.IsAbstract = $advType -eq [AdvancedEdgeType]::InheritanceAbstract
    }
    
    [void] AddInheritedMember([string]$member) {
        $this.InheritedMembers += $member
    }
    
    [void] AddOverriddenMember([string]$member) {
        $this.OverriddenMembers += $member
    }
    
    [hashtable] AnalyzeInheritance() {
        return @{
            Type = $this.AdvancedType.ToString()
            BaseType = $this.BaseType
            DerivedType = $this.DerivedType
            InheritedCount = $this.InheritedMembers.Count
            OverriddenCount = $this.OverriddenMembers.Count
            IsAbstract = $this.IsAbstract
            IsVirtual = $this.IsVirtual
        }
    }
}

# Implementation Edge class
class ImplementationEdge {
    [AdvancedEdgeType]$AdvancedType
    [string]$InterfaceName
    [string]$ImplementorName
    [string[]]$RequiredMethods
    [string[]]$ImplementedMethods
    [bool]$IsComplete
    [hashtable]$ComplianceMetrics
    
    # Base edge properties
    [string]$Id
    [string]$SourceId
    [string]$TargetId
    [string]$Type = "Implementation"
    [hashtable]$Properties
    [datetime]$CreatedAt
    
    ImplementationEdge([string]$sourceId, [string]$targetId, [AdvancedEdgeType]$advType) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.SourceId = $sourceId
        $this.TargetId = $targetId
        $this.AdvancedType = $advType
        $this.Properties = @{}
        $this.CreatedAt = Get-Date
        $this.RequiredMethods = @()
        $this.ImplementedMethods = @()
        $this.ComplianceMetrics = @{
            Coverage = 0
            Conformance = 0
            Violations = @()
        }
    }
    
    [void] ValidateImplementation() {
        $required = $this.RequiredMethods | Sort-Object -Unique
        $implemented = $this.ImplementedMethods | Sort-Object -Unique
        $missing = $required | Where-Object { $_ -notin $implemented }
        
        $this.IsComplete = $missing.Count -eq 0
        $this.ComplianceMetrics.Coverage = if ($required.Count -gt 0) { 
            ($implemented.Count / $required.Count) * 100 
        } else { 100 }
        $this.ComplianceMetrics.Violations = $missing
    }
    
    [hashtable] AnalyzeImplementation() {
        $this.ValidateImplementation()
        return @{
            Type = $this.AdvancedType.ToString()
            Interface = $this.InterfaceName
            Implementor = $this.ImplementorName
            IsComplete = $this.IsComplete
            RequiredCount = $this.RequiredMethods.Count
            ImplementedCount = $this.ImplementedMethods.Count
            Compliance = $this.ComplianceMetrics
        }
    }
}

# Composition Edge class
class CompositionEdge {
    [AdvancedEdgeType]$AdvancedType
    [string]$ContainerType
    [string]$ComponentType
    [string]$Cardinality  # "1", "0..1", "1..*", "*"
    [bool]$IsOwnership
    [bool]$IsShared
    [hashtable]$LifecycleBinding
    
    # Base edge properties
    [string]$Id
    [string]$SourceId
    [string]$TargetId
    [string]$Type = "Composition"
    [hashtable]$Properties
    [datetime]$CreatedAt
    
    CompositionEdge([string]$sourceId, [string]$targetId, [AdvancedEdgeType]$advType) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.SourceId = $sourceId
        $this.TargetId = $targetId
        $this.AdvancedType = $advType
        $this.Properties = @{}
        $this.CreatedAt = Get-Date
        $this.Cardinality = "1"
        $this.IsOwnership = $advType -eq [AdvancedEdgeType]::CompositionHasA
        $this.IsShared = $advType -eq [AdvancedEdgeType]::CompositionAssociation
        $this.LifecycleBinding = @{
            CreatedWith = $false
            DestroyedWith = $false
            Dependent = $false
        }
    }
    
    [void] SetCardinality([string]$cardinality) {
        if ($cardinality -in @("1", "0..1", "1..*", "*", "0..*")) {
            $this.Cardinality = $cardinality
        } else {
            throw "Invalid cardinality: $cardinality"
        }
    }
    
    [hashtable] AnalyzeComposition() {
        return @{
            Type = $this.AdvancedType.ToString()
            Container = $this.ContainerType
            Component = $this.ComponentType
            Cardinality = $this.Cardinality
            IsOwnership = $this.IsOwnership
            IsShared = $this.IsShared
            Lifecycle = $this.LifecycleBinding
        }
    }
}

# Factory functions for creating advanced edges
function New-DataFlowEdge {
    param(
        [Parameter(Mandatory)]
        [string]$SourceId,
        
        [Parameter(Mandatory)]
        [string]$TargetId,
        
        [Parameter(Mandatory)]
        [AdvancedEdgeType]$FlowType,
        
        [string]$DataType,
        [bool]$IsMutable = $false,
        [bool]$IsAsync = $false
    )
    
    $edge = [DataFlowEdge]::new($SourceId, $TargetId, $FlowType)
    if ($DataType) { $edge.DataType = $DataType }
    $edge.IsMutable = $IsMutable
    $edge.IsAsync = $IsAsync
    
    return $edge
}

function New-ControlFlowEdge {
    param(
        [Parameter(Mandatory)]
        [string]$SourceId,
        
        [Parameter(Mandatory)]
        [string]$TargetId,
        
        [Parameter(Mandatory)]
        [AdvancedEdgeType]$FlowType,
        
        [string]$Condition,
        [double]$ExecutionProbability = 1.0
    )
    
    $edge = [ControlFlowEdge]::new($SourceId, $TargetId, $FlowType)
    if ($Condition) { $edge.SetCondition($Condition) }
    $edge.ExecutionProbability = $ExecutionProbability
    
    return $edge
}

function New-InheritanceEdge {
    param(
        [Parameter(Mandatory)]
        [string]$SourceId,
        
        [Parameter(Mandatory)]
        [string]$TargetId,
        
        [Parameter(Mandatory)]
        [AdvancedEdgeType]$InheritanceType,
        
        [string]$BaseType,
        [string]$DerivedType,
        [bool]$IsAbstract = $false,
        [bool]$IsVirtual = $false
    )
    
    $edge = [InheritanceEdge]::new($SourceId, $TargetId, $InheritanceType)
    if ($BaseType) { $edge.BaseType = $BaseType }
    if ($DerivedType) { $edge.DerivedType = $DerivedType }
    $edge.IsAbstract = $IsAbstract
    $edge.IsVirtual = $IsVirtual
    
    return $edge
}

function New-ImplementationEdge {
    param(
        [Parameter(Mandatory)]
        [string]$SourceId,
        
        [Parameter(Mandatory)]
        [string]$TargetId,
        
        [Parameter(Mandatory)]
        [AdvancedEdgeType]$ImplementationType,
        
        [string]$InterfaceName,
        [string]$ImplementorName,
        [string[]]$RequiredMethods = @()
    )
    
    $edge = [ImplementationEdge]::new($SourceId, $TargetId, $ImplementationType)
    if ($InterfaceName) { $edge.InterfaceName = $InterfaceName }
    if ($ImplementorName) { $edge.ImplementorName = $ImplementorName }
    $edge.RequiredMethods = $RequiredMethods
    
    return $edge
}

function New-CompositionEdge {
    param(
        [Parameter(Mandatory)]
        [string]$SourceId,
        
        [Parameter(Mandatory)]
        [string]$TargetId,
        
        [Parameter(Mandatory)]
        [AdvancedEdgeType]$CompositionType,
        
        [string]$ContainerType,
        [string]$ComponentType,
        [string]$Cardinality = "1",
        [hashtable]$LifecycleBinding
    )
    
    $edge = [CompositionEdge]::new($SourceId, $TargetId, $CompositionType)
    if ($ContainerType) { $edge.ContainerType = $ContainerType }
    if ($ComponentType) { $edge.ComponentType = $ComponentType }
    $edge.SetCardinality($Cardinality)
    if ($LifecycleBinding) { $edge.LifecycleBinding = $LifecycleBinding }
    
    return $edge
}

# Analysis functions for advanced edges
function Get-DataFlowPaths {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Graph,
        
        [string]$StartNode,
        [string]$EndNode,
        [AdvancedEdgeType[]]$FlowTypes
    )
    
    $paths = @()
    $visited = @{}
    
    function Find-Path {
        param($Current, $Target, $Path)
        
        if ($Current -eq $Target) {
            $paths += ,@($Path + $Current)
            return
        }
        
        $visited[$Current] = $true
        
        $edges = $Graph.Edges.Values | Where-Object {
            $_.SourceId -eq $Current -and
            $_.GetType().Name -eq 'DataFlowEdge' -and
            (!$FlowTypes -or $_.AdvancedType -in $FlowTypes)
        }
        
        foreach ($edge in $edges) {
            if (!$visited[$edge.TargetId]) {
                Find-Path -Current $edge.TargetId -Target $Target -Path ($Path + $Current)
            }
        }
        
        $visited[$Current] = $false
    }
    
    Find-Path -Current $StartNode -Target $EndNode -Path @()
    return $paths
}

function Get-ControlFlowGraph {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Graph,
        
        [string]$EntryPoint
    )
    
    $cfg = @{
        Nodes = @{}
        Edges = @()
        EntryPoint = $EntryPoint
        ExitPoints = @()
        Loops = @()
        Branches = @()
    }
    
    $queue = [System.Collections.Queue]::new()
    $queue.Enqueue($EntryPoint)
    $visited = @{}
    
    while ($queue.Count -gt 0) {
        $current = $queue.Dequeue()
        if ($visited[$current]) { continue }
        
        $visited[$current] = $true
        $cfg.Nodes[$current] = $Graph.Nodes[$current]
        
        $edges = $Graph.Edges.Values | Where-Object {
            $_.SourceId -eq $current -and
            $_.GetType().Name -eq 'ControlFlowEdge'
        }
        
        foreach ($edge in $edges) {
            $cfg.Edges += $edge
            
            if ($edge.IsLoop) {
                $cfg.Loops += $edge
            }
            if ($edge.IsConditional) {
                $cfg.Branches += $edge
            }
            
            if (!$visited[$edge.TargetId]) {
                $queue.Enqueue($edge.TargetId)
            }
        }
        
        # Check for exit points
        $hasOutgoing = $edges.Count -gt 0
        if (!$hasOutgoing) {
            $cfg.ExitPoints += $current
        }
    }
    
    return $cfg
}

function Get-InheritanceHierarchy {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Graph,
        
        [string]$RootType
    )
    
    $hierarchy = @{
        Root = $RootType
        Children = @{}
        Depth = 0
        TotalNodes = 0
    }
    
    function Build-Hierarchy {
        param($Parent, $Level)
        
        $edges = $Graph.Edges.Values | Where-Object {
            $_.TargetId -eq $Parent -and
            $_.GetType().Name -eq 'InheritanceEdge'
        }
        
        $children = @{}
        foreach ($edge in $edges) {
            $childNode = $Graph.Nodes[$edge.SourceId]
            $children[$edge.SourceId] = @{
                Node = $childNode
                Edge = $edge
                Children = Build-Hierarchy -Parent $edge.SourceId -Level ($Level + 1)
            }
            $hierarchy.TotalNodes++
        }
        
        if ($Level -gt $hierarchy.Depth) {
            $hierarchy.Depth = $Level
        }
        
        return $children
    }
    
    $hierarchy.Children = Build-Hierarchy -Parent $RootType -Level 0
    return $hierarchy
}

function Get-InterfaceCompliance {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Graph,
        
        [string]$InterfaceId
    )
    
    $compliance = @{
        Interface = $Graph.Nodes[$InterfaceId]
        Implementations = @()
        TotalCompliance = 100
        Issues = @()
    }
    
    $edges = $Graph.Edges.Values | Where-Object {
        $_.TargetId -eq $InterfaceId -and
        $_.GetType().Name -eq 'ImplementationEdge'
    }
    
    foreach ($edge in $edges) {
        $analysis = $edge.AnalyzeImplementation()
        $compliance.Implementations += @{
            Implementor = $Graph.Nodes[$edge.SourceId]
            Edge = $edge
            Analysis = $analysis
            IsCompliant = $analysis.IsComplete
        }
        
        if (!$analysis.IsComplete) {
            $compliance.Issues += @{
                Implementor = $edge.ImplementorName
                MissingMethods = $analysis.Compliance.Violations
            }
        }
    }
    
    if ($compliance.Implementations.Count -gt 0) {
        $compliantCount = ($compliance.Implementations | Where-Object { $_.IsCompliant }).Count
        $compliance.TotalCompliance = ($compliantCount / $compliance.Implementations.Count) * 100
    }
    
    return $compliance
}

function Get-CompositionStructure {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Graph,
        
        [string]$ContainerId,
        [int]$MaxDepth = 10
    )
    
    $structure = @{
        Container = $Graph.Nodes[$ContainerId]
        Components = @()
        TotalComponents = 0
        OwnershipCount = 0
        SharedCount = 0
    }
    
    function Get-Components {
        param($Parent, $Depth)
        
        if ($Depth -ge $MaxDepth) { return @() }
        
        $edges = $Graph.Edges.Values | Where-Object {
            $_.SourceId -eq $Parent -and
            $_.GetType().Name -eq 'CompositionEdge'
        }
        
        $components = @()
        foreach ($edge in $edges) {
            $component = @{
                Node = $Graph.Nodes[$edge.TargetId]
                Edge = $edge
                Analysis = $edge.AnalyzeComposition()
                SubComponents = Get-Components -Parent $edge.TargetId -Depth ($Depth + 1)
            }
            
            $components += $component
            $structure.TotalComponents++
            
            if ($edge.IsOwnership) {
                $structure.OwnershipCount++
            }
            if ($edge.IsShared) {
                $structure.SharedCount++
            }
        }
        
        return $components
    }
    
    $structure.Components = Get-Components -Parent $ContainerId -Depth 0
    return $structure
}

# Visualization helper for advanced edges
function ConvertTo-MermaidDiagram {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Graph,
        
        [AdvancedEdgeType[]]$IncludeTypes,
        [switch]$ShowDataFlow,
        [switch]$ShowControlFlow,
        [switch]$ShowInheritance,
        [switch]$ShowImplementation,
        [switch]$ShowComposition
    )
    
    $mermaid = @("graph LR")
    $nodeStyles = @{}
    $edgeStyles = @{}
    
    # Define node styles
    foreach ($node in $Graph.Nodes.Values) {
        $shape = switch ($node.Type) {
            'Class' { "[$($node.Name)]" }
            'Interface' { "[[$($node.Name)]]" }
            'Function' { "($($node.Name))" }
            'Module' { "{$($node.Name)}" }
            default { "[$($node.Name)]" }
        }
        $mermaid += "    $($node.Id)$shape"
    }
    
    # Add edges based on type
    foreach ($edge in $Graph.Edges.Values) {
        $include = $false
        $arrow = "-->"
        $label = ""
        
        if ($edge.GetType().Name -eq 'DataFlowEdge' -and $ShowDataFlow) {
            $include = $true
            $arrow = "-.->|data|"
            $label = $edge.DataType
        }
        elseif ($edge.GetType().Name -eq 'ControlFlowEdge' -and $ShowControlFlow) {
            $include = $true
            $arrow = if ($edge.IsLoop) { "-->|loop|" } 
                     elseif ($edge.IsConditional) { "-->|if|" }
                     else { "-->" }
            $label = $edge.Condition
        }
        elseif ($edge.GetType().Name -eq 'InheritanceEdge' -and $ShowInheritance) {
            $include = $true
            $arrow = "--|>"
            $label = "extends"
        }
        elseif ($edge.GetType().Name -eq 'ImplementationEdge' -and $ShowImplementation) {
            $include = $true
            $arrow = "..|>"
            $label = "implements"
        }
        elseif ($edge.GetType().Name -eq 'CompositionEdge' -and $ShowComposition) {
            $include = $true
            $arrow = if ($edge.IsOwnership) { "*--" } else { "o--" }
            $label = $edge.Cardinality
        }
        
        if ($include -and (!$IncludeTypes -or $edge.AdvancedType -in $IncludeTypes)) {
            if ($label) {
                $mermaid += "    $($edge.SourceId) $arrow $($edge.TargetId)"
            } else {
                $mermaid += "    $($edge.SourceId) $arrow $($edge.TargetId)"
            }
        }
    }
    
    return $mermaid -join "`n"
}

# Export all functions and classes
Export-ModuleMember -Function @(
    'New-DataFlowEdge',
    'New-ControlFlowEdge', 
    'New-InheritanceEdge',
    'New-ImplementationEdge',
    'New-CompositionEdge',
    'Get-DataFlowPaths',
    'Get-ControlFlowGraph',
    'Get-InheritanceHierarchy',
    'Get-InterfaceCompliance',
    'Get-CompositionStructure',
    'ConvertTo-MermaidDiagram'
)

# IMPLEMENTATION MARKER: Week 1, Day 1, Afternoon - Advanced Edge Types
# Part of Enhanced Documentation System Second Pass Implementation
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDM+RXhMVnXA2/6
# Rf2pSZo9THAe4X3QAKDIFsYKPrJWSqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICqM3hGFJrL8d9DLaJ7RSQnJ
# 1h5/z8cR3I6J4sPz3OTIMA0GCSqGSIb3DQEBAQUABIIBAAx5vFW3hGAJFN8YTtWt
# wITYZRtZ1Rt7MBYOIcWEQKj7sFBdDBJzMeFLz5GBqPl+Wnn2h6MvMSxiM8ZGP3qN
# rFNXJ3wBJ7j7rJ2Nwn7xKNtRQHp8UT6mOTFXgSvCLRQdQ6K5pX7aFJQKQF8qR3LL
# 9YKBOJGyT0+Sg5B5gQFHcrJdVINmOGIYRHdJvFITN8kG9yvNXJ8V0i5XTZOVqkxX
# CdClRUoLzuRAQnmrDvb3KQGxsrCwKCQBCCPRGTCVOUfqE7rqXLzOJLAyfT8ObqcI
# 4nTdQaQrElxOdQQ9JT5eCSQm7fQzZJ1OKwZjhPZQiJrLk8XzjQKQPsQ3CQyJXqEV
# q4A=
# SIG # End signature block