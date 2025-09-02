#Requires -Version 5.1
<#
.SYNOPSIS
    Unified CPG module that combines data structures and advanced edges

.DESCRIPTION
    Provides all CPG classes and functions in a single module for proper class inheritance

.NOTES
    Part of Enhanced Documentation System Second Pass Implementation
    Created: 2025-08-28
#>

# Initialize debug logging
$script:CPGDebugEnabled = $true
$script:CPGDebugLog = @()

function Write-CPGDebug {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [string]$Component = "CPG",
        [string]$Level = "DEBUG"
    )
    
    if ($script:CPGDebugEnabled) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $logEntry = "[$timestamp] [$Level] [$Component] $Message"
        $script:CPGDebugLog += $logEntry
        
        # Also write to console with color coding
        $color = switch ($Level) {
            "ERROR" { "Red" }
            "WARNING" { "Yellow" }
            "SUCCESS" { "Green" }
            "INFO" { "Cyan" }
            default { "Gray" }
        }
        Write-Host $logEntry -ForegroundColor $color
    }
}

Write-CPGDebug "Loading Unified CPG Module" -Component "Module" -Level "INFO"

# Module-level variables for thread-safe graph storage
Write-CPGDebug "Initializing module-level variables" -Component "Init"
$script:CPGStorage = [hashtable]::Synchronized(@{})
$script:NodeIndex = [hashtable]::Synchronized(@{})
$script:EdgeIndex = [hashtable]::Synchronized(@{})
$script:GraphMetadata = [hashtable]::Synchronized(@{})
$script:CPGLock = [System.Threading.ReaderWriterLock]::new()
Write-CPGDebug "Module variables initialized successfully" -Component "Init" -Level "SUCCESS"

# Node type enumeration
Write-CPGDebug "Defining CPGNodeType enumeration" -Component "TypeDef"
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

# Advanced Edge Type Enumeration
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

# Base CPG Node class
Write-CPGDebug "Defining CPGNode class" -Component "TypeDef"
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
        Write-CPGDebug "Created CPGNode with Id: $($this.Id)" -Component "CPGNode"
    }
    
    CPGNode([string]$name, [CPGNodeType]$type) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Name = $name
        $this.Type = $type
        $this.Properties = @{}
        $this.Metadata = @{}
        $this.CreatedAt = Get-Date
        $this.ModifiedAt = Get-Date
        Write-CPGDebug "Created CPGNode '$name' of type '$type' with Id: $($this.Id)" -Component "CPGNode"
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

# Base CPG Edge class
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

# CPG Graph class
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
        $this.Metadata = [hashtable]::Synchronized(@{})
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
        $this.Metadata = [hashtable]::Synchronized(@{})
        $this.CreatedAt = Get-Date
        $this.ModifiedAt = Get-Date
        $this.Version = 1
    }
    
    [void] UpdateModifiedTime() {
        $this.ModifiedAt = Get-Date
        $this.Version++
    }
    
    [string] ToString() {
        return "CPGraph '$($this.Name)' (Nodes: $($this.Nodes.Count), Edges: $($this.Edges.Count))"
    }
    
    [hashtable] ToHashtable() {
        return @{
            Id = $this.Id
            Name = $this.Name
            NodesCount = $this.Nodes.Count
            EdgesCount = $this.Edges.Count
            CreatedAt = $this.CreatedAt
            ModifiedAt = $this.ModifiedAt
            Version = $this.Version
            Metadata = $this.Metadata
        }
    }
}

# Data Flow Edge class (inherits from CPGEdge)
Write-CPGDebug "Defining DataFlowEdge class (inherits from CPGEdge)" -Component "TypeDef"
class DataFlowEdge : CPGEdge {
    [AdvancedEdgeType]$AdvancedType
    [string]$DataType
    [bool]$IsMutable
    [bool]$IsAsync
    [string[]]$TransformationPath
    [hashtable]$FlowMetrics
    
    DataFlowEdge([string]$sourceId, [string]$targetId, [AdvancedEdgeType]$advType) : base($sourceId, $targetId, [CPGEdgeType]::DataFlow) {
        $this.AdvancedType = $advType
        $this.FlowMetrics = @{
            Complexity = 0
            DataVolume = 0
            Frequency = 0
        }
        $this.TransformationPath = @()
        Write-CPGDebug "Created DataFlowEdge ($advType) from $sourceId to $targetId" -Component "DataFlowEdge"
    }
    
    [void] AddTransformation([string]$transformation) {
        Write-CPGDebug "Adding transformation '$transformation' to edge $($this.Id)" -Component "DataFlowEdge"
        $this.TransformationPath += $transformation
        $this.FlowMetrics.Complexity++
        Write-CPGDebug "Transformation added. Current complexity: $($this.FlowMetrics.Complexity)" -Component "DataFlowEdge"
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

# Control Flow Edge class (inherits from CPGEdge)
class ControlFlowEdge : CPGEdge {
    [AdvancedEdgeType]$AdvancedType
    [string]$Condition
    [double]$ExecutionProbability
    [bool]$IsConditional
    [bool]$IsLoop
    [hashtable]$BranchMetrics
    
    ControlFlowEdge([string]$sourceId, [string]$targetId, [AdvancedEdgeType]$advType) : base($sourceId, $targetId, [CPGEdgeType]::Follows) {
        $this.AdvancedType = $advType
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

# Inheritance Edge class (inherits from CPGEdge)
class InheritanceEdge : CPGEdge {
    [AdvancedEdgeType]$AdvancedType
    [string]$BaseType
    [string]$DerivedType
    [string[]]$InheritedMembers
    [string[]]$OverriddenMembers
    [bool]$IsAbstract
    [bool]$IsVirtual
    
    InheritanceEdge([string]$sourceId, [string]$targetId, [AdvancedEdgeType]$advType) : base($sourceId, $targetId, [CPGEdgeType]::Extends) {
        $this.AdvancedType = $advType
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

# Implementation Edge class (inherits from CPGEdge)
class ImplementationEdge : CPGEdge {
    [AdvancedEdgeType]$AdvancedType
    [string]$InterfaceName
    [string]$ImplementorName
    [string[]]$RequiredMethods
    [string[]]$ImplementedMethods
    [bool]$IsComplete
    [hashtable]$ComplianceMetrics
    
    ImplementationEdge([string]$sourceId, [string]$targetId, [AdvancedEdgeType]$advType) : base($sourceId, $targetId, [CPGEdgeType]::Implements) {
        $this.AdvancedType = $advType
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

# Composition Edge class (inherits from CPGEdge)
class CompositionEdge : CPGEdge {
    [AdvancedEdgeType]$AdvancedType
    [string]$ContainerType
    [string]$ComponentType
    [string]$Cardinality  # "1", "0..1", "1..*", "*"
    [bool]$IsOwnership
    [bool]$IsShared
    [hashtable]$LifecycleBinding
    
    CompositionEdge([string]$sourceId, [string]$targetId, [AdvancedEdgeType]$advType) : base($sourceId, $targetId, [CPGEdgeType]::Contains) {
        $this.AdvancedType = $advType
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

# Factory functions for creating nodes
Write-CPGDebug "Defining factory function: New-CPGNode" -Component "Factory"
function New-CPGNode {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [CPGNodeType]$Type,
        
        [hashtable]$Properties = @{},
        [string]$FilePath,
        [int]$StartLine,
        [int]$EndLine
    )
    
    Write-CPGDebug "Creating new CPGNode: Name='$Name', Type='$Type'" -Component "Factory"
    
    try {
        $node = [CPGNode]::new($Name, $Type)
        if ($Properties) { 
            $node.Properties = $Properties
            Write-CPGDebug "Set properties on node $($node.Id)" -Component "Factory"
        }
        if ($FilePath) { 
            $node.FilePath = $FilePath
            Write-CPGDebug "Set FilePath='$FilePath' on node $($node.Id)" -Component "Factory"
        }
        if ($StartLine) { $node.StartLine = $StartLine }
        if ($EndLine) { $node.EndLine = $EndLine }
        
        Write-CPGDebug "Successfully created node $($node.Id)" -Component "Factory" -Level "SUCCESS"
        return $node
    } catch {
        Write-CPGDebug "Failed to create node: $_" -Component "Factory" -Level "ERROR"
        throw
    }
}

# Factory functions for creating basic edges
function New-CPGEdge {
    param(
        [Parameter(Mandatory)]
        [string]$SourceId,
        
        [Parameter(Mandatory)]
        [string]$TargetId,
        
        [Parameter(Mandatory)]
        [CPGEdgeType]$Type,
        
        [hashtable]$Properties = @{},
        [double]$Weight = 1.0
    )
    
    $edge = [CPGEdge]::new($SourceId, $TargetId, $Type)
    if ($Properties) { $edge.Properties = $Properties }
    $edge.Weight = $Weight
    
    return $edge
}

# Factory functions for creating advanced edges
Write-CPGDebug "Defining factory function: New-DataFlowEdge" -Component "Factory"
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
    
    Write-CPGDebug "Creating DataFlowEdge: Source='$SourceId', Target='$TargetId', Type='$FlowType'" -Component "Factory"
    
    try {
        $edge = [DataFlowEdge]::new($SourceId, $TargetId, $FlowType)
        if ($DataType) { 
            $edge.DataType = $DataType
            Write-CPGDebug "Set DataType='$DataType' on edge $($edge.Id)" -Component "Factory"
        }
        $edge.IsMutable = $IsMutable
        $edge.IsAsync = $IsAsync
        
        Write-CPGDebug "Successfully created DataFlowEdge $($edge.Id)" -Component "Factory" -Level "SUCCESS"
        return $edge
    } catch {
        Write-CPGDebug "Failed to create DataFlowEdge: $_" -Component "Factory" -Level "ERROR"
        throw
    }
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

# Graph creation function
Write-CPGDebug "Defining factory function: New-CPGraph" -Component "Factory"
function New-CPGraph {
    param(
        [string]$Name = "DefaultGraph"
    )
    
    Write-CPGDebug "Creating new CPGraph: Name='$Name'" -Component "Factory"
    
    try {
        $graph = [CPGraph]::new($Name)
        Write-CPGDebug "Successfully created CPGraph $($graph.Id) with name '$Name'" -Component "Factory" -Level "SUCCESS"
        return $graph
    } catch {
        Write-CPGDebug "Failed to create CPGraph: $_" -Component "Factory" -Level "ERROR"
        throw
    }
}

# Function to get debug log
function Get-CPGDebugLog {
    return $script:CPGDebugLog
}

# Function to clear debug log
function Clear-CPGDebugLog {
    $script:CPGDebugLog = @()
    Write-CPGDebug "Debug log cleared" -Component "Debug" -Level "INFO"
}

# Function to enable/disable debug logging
function Set-CPGDebug {
    param(
        [bool]$Enable = $true
    )
    $script:CPGDebugEnabled = $Enable
    $status = if ($Enable) { "enabled" } else { "disabled" }
    Write-CPGDebug "Debug logging $status" -Component "Debug" -Level "INFO"
}

# Export all functions, classes and enumerations
Write-CPGDebug "Exporting module members" -Component "Module" -Level "INFO"
Export-ModuleMember -Function @(
    'New-CPGNode',
    'New-CPGEdge',
    'New-DataFlowEdge',
    'New-ControlFlowEdge', 
    'New-InheritanceEdge',
    'New-ImplementationEdge',
    'New-CompositionEdge',
    'New-CPGraph',
    'Write-CPGDebug',
    'Get-CPGDebugLog',
    'Clear-CPGDebugLog',
    'Set-CPGDebug'
) -Variable @(
    'CPGStorage',
    'NodeIndex', 
    'EdgeIndex',
    'GraphMetadata',
    'CPGLock'
)

Write-CPGDebug "Unified CPG Module loaded successfully" -Component "Module" -Level "SUCCESS"
Write-CPGDebug "Total types defined: 8 classes, 4 enumerations" -Component "Module" -Level "INFO"
Write-CPGDebug "Total functions exported: 12" -Component "Module" -Level "INFO"

# IMPLEMENTATION MARKER: Unified CPG module with proper class inheritance and debug logging
# Part of Enhanced Documentation System Second Pass Implementation
# Week 1, Day 1 - Afternoon Session
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBnsFhQy9qCf/7Q
# CJqzGAD3K8tV9zLqRP7Mj+xXhXD7PKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIK2QdTzf/SXksBGXtLgz7P5u
# ZJOwcXU8zJc+rBXbdezLMA0GCSqGSIb3DQEBAQUABIIBAJHFQ9jQ8LLzRBuOKhTA
# XGQOLn2RLl1Wk1r3JiRtGZ+gKfOtcmSaJa7eQwBfP8FQoqRzOIoB8GNKwBTJlhEx
# pUUrJPZt+ztNqgqD5xnhzJCo+8aEECXoCrSmC/IZJUhBGiTb1kSJzVzqSfQv2Xnc
# FxvzLlMn+MhPSBQNtf5YQqWRZuIJh3XazXyJBxHQJLRIjEkJKjXV8AXUWihXRAsE
# KQeq/aTxpSgAazw8N6aTEQJy9DyWPqpJL9wHs3fO8Kf3Y1Vx8ZhqxHjQQRpoxwyD
# HCVL5KxCqnUNBSCqfZqJYLcVnGaNdw7tBAbZlPu/GsOmHYk3jZKQkkbC/gJTYkGF
# Vlk=
# SIG # End signature block