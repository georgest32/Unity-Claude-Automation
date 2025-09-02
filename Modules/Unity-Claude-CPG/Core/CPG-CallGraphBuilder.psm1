#Requires -Version 5.1
<#
.SYNOPSIS
    Call Graph Builder for Code Property Graph (CPG) implementation.

.DESCRIPTION
    Builds function invocation graphs, tracks call hierarchies, detects recursive calls,
    and handles virtual/override resolution for comprehensive call analysis.

.NOTES
    Part of Enhanced Documentation System Second Pass Implementation
    Week 1, Day 2 - Morning Session
    Created: 2025-08-28
#>

# Define required enumerations
enum CPGNodeType {
    Unknown = 0
    Function = 1
    Method = 2
    Variable = 3
    Parameter = 4
    Property = 5
    Class = 6
    Module = 7
    Script = 8
    Command = 9
    Expression = 10
}

# Debug helper function
function Write-CPGDebug {
    param(
        [string]$Message,
        [string]$Component = "CPG"
    )
    
    if ($env:CPG_DEBUG -eq "1" -or $VerbosePreference -ne 'SilentlyContinue') {
        Write-Verbose "[$Component] $Message"
    }
}

# Call graph specific enumerations
enum CallType {
    Direct          # Direct function call
    Indirect        # Through function pointer/delegate
    Virtual         # Virtual method call
    Override        # Override method call
    Recursive       # Recursive call
    Callback        # Callback invocation
    Dynamic         # Dynamic invocation (Invoke-Expression)
    Constructor     # Constructor call
    Destructor      # Destructor/finalizer call
}

enum CallAnalysisType {
    CHA             # Class Hierarchy Analysis
    RTA             # Rapid Type Analysis
    PointsTo        # Points-to Analysis
    FieldBased      # Field-based (for dynamic languages)
    Hybrid          # Combination of techniques
}

# Call Node class representing a callable entity
class CallNode {
    [string]$Id
    [string]$Name
    [string]$FullName
    [CPGNodeType]$NodeType
    [string]$FilePath
    [int]$StartLine
    [int]$EndLine
    [string]$Signature
    [string[]]$Parameters
    [string]$ReturnType
    [bool]$IsVirtual
    [bool]$IsAbstract
    [bool]$IsOverride
    [bool]$IsStatic
    [bool]$IsConstructor
    [hashtable]$Metadata
    
    CallNode([string]$name, [CPGNodeType]$type) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Name = $name
        $this.NodeType = $type
        $this.Parameters = @()
        $this.Metadata = @{}
        Write-CPGDebug "Created CallNode: $name ($type)" -Component "CallGraph"
    }
    
    [string] GetSignature() {
        if (-not $this.Signature) {
            $params = $this.Parameters -join ", "
            $this.Signature = "$($this.Name)($params)"
            if ($this.ReturnType) {
                $this.Signature += " : $($this.ReturnType)"
            }
        }
        return $this.Signature
    }
}

# Call Edge class representing a function invocation
class CallEdge {
    [string]$Id
    [string]$CallerId
    [string]$CalleeId
    [CallType]$CallType
    [int]$CallLine
    [int]$CallColumn
    [string]$CallExpression
    [bool]$IsConditional
    [string]$Condition
    [int]$CallFrequency
    [double]$ExecutionProbability
    [hashtable]$Context
    
    CallEdge([string]$callerId, [string]$calleeId, [CallType]$type) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.CallerId = $callerId
        $this.CalleeId = $calleeId
        $this.CallType = $type
        $this.CallFrequency = 1
        $this.ExecutionProbability = 1.0
        $this.Context = @{}
        Write-CPGDebug "Created CallEdge: $callerId -> $calleeId ($type)" -Component "CallGraph"
    }
    
    [void] IncrementFrequency() {
        $this.CallFrequency++
        Write-CPGDebug "Incremented call frequency to $($this.CallFrequency) for edge $($this.Id)" -Component "CallGraph"
    }
}

# Call Graph class
class CallGraph {
    [string]$Id
    [string]$Name
    [hashtable]$CallNodes        # Id -> CallNode
    [hashtable]$CallEdges        # Id -> CallEdge
    [hashtable]$CalleeIndex      # CalleeId -> [CallerId]
    [hashtable]$CallerIndex      # CallerId -> [CalleeId]
    [hashtable]$RecursiveCalls   # NodeId -> RecursionInfo
    [CallAnalysisType]$AnalysisType
    [datetime]$CreatedAt
    [hashtable]$Statistics
    
    CallGraph([string]$name) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Name = $name
        $this.CallNodes = [hashtable]::Synchronized(@{})
        $this.CallEdges = [hashtable]::Synchronized(@{})
        $this.CalleeIndex = [hashtable]::Synchronized(@{})
        $this.CallerIndex = [hashtable]::Synchronized(@{})
        $this.RecursiveCalls = [hashtable]::Synchronized(@{})
        $this.AnalysisType = [CallAnalysisType]::Hybrid
        $this.CreatedAt = Get-Date
        $this.Statistics = @{
            TotalNodes = 0
            TotalEdges = 0
            RecursiveFunctions = 0
            MaxCallDepth = 0
            AverageOutDegree = 0
        }
        Write-CPGDebug "Created CallGraph: $name" -Component "CallGraph" -Level "SUCCESS"
    }
    
    [void] AddCallNode([CallNode]$node) {
        if (-not $this.CallNodes.ContainsKey($node.Id)) {
            $this.CallNodes[$node.Id] = $node
            $this.Statistics.TotalNodes++
            Write-CPGDebug "Added call node: $($node.Name) (Total: $($this.Statistics.TotalNodes))" -Component "CallGraph"
        }
    }
    
    [void] AddCallEdge([CallEdge]$edge) {
        if (-not $this.CallEdges.ContainsKey($edge.Id)) {
            $this.CallEdges[$edge.Id] = $edge
            
            # Update caller index
            if (-not $this.CallerIndex.ContainsKey($edge.CallerId)) {
                $this.CallerIndex[$edge.CallerId] = @()
            }
            $this.CallerIndex[$edge.CallerId] += $edge.CalleeId
            
            # Update callee index
            if (-not $this.CalleeIndex.ContainsKey($edge.CalleeId)) {
                $this.CalleeIndex[$edge.CalleeId] = @()
            }
            $this.CalleeIndex[$edge.CalleeId] += $edge.CallerId
            
            $this.Statistics.TotalEdges++
            Write-CPGDebug "Added call edge: $($edge.CallerId) -> $($edge.CalleeId) (Total: $($this.Statistics.TotalEdges))" -Component "CallGraph"
            
            # Check for recursion
            if ($edge.CallerId -eq $edge.CalleeId -or $this.DetectRecursion($edge)) {
                $this.MarkRecursive($edge.CallerId)
            }
        }
    }
    
    [bool] DetectRecursion([CallEdge]$edge) {
        # Simple cycle detection using DFS
        $visited = @{}
        $stack = @{}
        
        function Test-Cycle {
            param($nodeId, $targetId)
            
            if ($stack.ContainsKey($nodeId)) {
                return $nodeId -eq $targetId
            }
            
            if ($visited.ContainsKey($nodeId)) {
                return $false
            }
            
            $visited[$nodeId] = $true
            $stack[$nodeId] = $true
            
            if ($this.CallerIndex.ContainsKey($nodeId)) {
                foreach ($callee in $this.CallerIndex[$nodeId]) {
                    if (Test-Cycle -nodeId $callee -targetId $targetId) {
                        return $true
                    }
                }
            }
            
            $stack.Remove($nodeId)
            return $false
        }
        
        return Test-Cycle -nodeId $edge.CalleeId -targetId $edge.CallerId
    }
    
    [void] MarkRecursive([string]$nodeId) {
        if (-not $this.RecursiveCalls.ContainsKey($nodeId)) {
            $this.RecursiveCalls[$nodeId] = @{
                NodeId = $nodeId
                IsRecursive = $true
                RecursionDepth = 0
                RecursionType = "Direct"
            }
            $this.Statistics.RecursiveFunctions++
            Write-CPGDebug "Marked node as recursive: $nodeId" -Component "CallGraph" -Level "WARNING"
        }
    }
    
    [hashtable] GetCallStatistics() {
        $this.Statistics.AverageOutDegree = if ($this.Statistics.TotalNodes -gt 0) {
            $this.Statistics.TotalEdges / $this.Statistics.TotalNodes
        } else { 0 }
        
        return $this.Statistics
    }
}

# PowerShell AST-based call graph builder
function Build-PowerShellCallGraph {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,
        
        [CallAnalysisType]$AnalysisType = [CallAnalysisType]::Hybrid
    )
    
    Write-CPGDebug "Building PowerShell call graph for: $ScriptPath" -Component "CallGraphBuilder" -Level "INFO"
    
    try {
        # Parse the script
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $ScriptPath,
            [ref]$null,
            [ref]$null
        )
        
        if (-not $ast) {
            throw "Failed to parse script: $ScriptPath"
        }
        
        $callGraph = [CallGraph]::new((Split-Path -Leaf $ScriptPath))
        $callGraph.AnalysisType = $AnalysisType
        
        # Build function inventory
        $functions = @{}
        $functionAsts = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)
        
        foreach ($funcAst in $functionAsts) {
            $node = [CallNode]::new($funcAst.Name, [CPGNodeType]::Function)
            $node.FilePath = $ScriptPath
            $node.StartLine = $funcAst.Extent.StartLineNumber
            $node.EndLine = $funcAst.Extent.EndLineNumber
            
            # Extract parameters
            if ($funcAst.Parameters) {
                $node.Parameters = $funcAst.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath }
            }
            
            $callGraph.AddCallNode($node)
            $functions[$funcAst.Name] = $node
            
            Write-CPGDebug "Found function: $($funcAst.Name) at line $($node.StartLine)" -Component "CallGraphBuilder"
        }
        
        # Find all command invocations
        $commandAsts = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.CommandAst]
        }, $true)
        
        foreach ($cmdAst in $commandAsts) {
            # Determine the calling context
            $callerFunc = $null
            $parent = $cmdAst.Parent
            while ($parent) {
                if ($parent -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
                    $callerFunc = $parent.Name
                    break
                }
                $parent = $parent.Parent
            }
            
            # Get the command name
            $commandName = $null
            if ($cmdAst.CommandElements -and $cmdAst.CommandElements.Count -gt 0) {
                $firstElement = $cmdAst.CommandElements[0]
                if ($firstElement -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                    $commandName = $firstElement.Value
                } elseif ($firstElement.GetType().Name -eq 'StringExpandableExpressionAst') {
                    $commandName = $firstElement.Value
                }
            }
            
            if ($commandName -and $functions.ContainsKey($commandName)) {
                # Create call edge
                $callerId = if ($callerFunc -and $functions.ContainsKey($callerFunc)) {
                    $functions[$callerFunc].Id
                } else {
                    # Global scope or script body
                    $globalNode = [CallNode]::new("<Script>", [CPGNodeType]::Module)
                    $callGraph.AddCallNode($globalNode)
                    $globalNode.Id
                }
                
                $calleeId = $functions[$commandName].Id
                $callType = [CallType]::Direct
                
                # Check for dynamic invocation patterns
                if ($cmdAst.InvocationOperator -eq [System.Management.Automation.Language.TokenKind]::Dot) {
                    $callType = [CallType]::Dynamic
                } elseif ($cmdAst.InvocationOperator -eq [System.Management.Automation.Language.TokenKind]::Ampersand) {
                    $callType = [CallType]::Indirect
                }
                
                $edge = [CallEdge]::new($callerId, $calleeId, $callType)
                $edge.CallLine = $cmdAst.Extent.StartLineNumber
                $edge.CallColumn = $cmdAst.Extent.StartColumnNumber
                $edge.CallExpression = $cmdAst.Extent.Text
                
                $callGraph.AddCallEdge($edge)
                
                Write-CPGDebug "Found call: $callerFunc -> $commandName at line $($edge.CallLine)" -Component "CallGraphBuilder"
            }
        }
        
        # Analyze for indirect calls (Invoke-Expression, Invoke-Command, etc.)
        $invokeAsts = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.CommandAst] -and
            $args[0].CommandElements[0].Value -match '^(Invoke-Expression|Invoke-Command|&|\.)$'
        }, $true)
        
        foreach ($invokeAst in $invokeAsts) {
            Write-CPGDebug "Found dynamic invocation at line $($invokeAst.Extent.StartLineNumber)" -Component "CallGraphBuilder" -Level "WARNING"
            
            # Add dynamic call edge with unknown target
            $dynamicNode = [CallNode]::new("<Dynamic>", [CPGNodeType]::Unknown)
            $callGraph.AddCallNode($dynamicNode)
            
            $callerFunc = $null
            $parent = $invokeAst.Parent
            while ($parent) {
                if ($parent -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
                    $callerFunc = $parent.Name
                    break
                }
                $parent = $parent.Parent
            }
            
            if ($callerFunc -and $functions.ContainsKey($callerFunc)) {
                $edge = [CallEdge]::new($functions[$callerFunc].Id, $dynamicNode.Id, [CallType]::Dynamic)
                $edge.CallLine = $invokeAst.Extent.StartLineNumber
                $callGraph.AddCallEdge($edge)
            }
        }
        
        $stats = $callGraph.GetCallStatistics()
        Write-CPGDebug "Call graph complete: $($stats.TotalNodes) nodes, $($stats.TotalEdges) edges, $($stats.RecursiveFunctions) recursive" -Component "CallGraphBuilder" -Level "SUCCESS"
        
        return $callGraph
        
    } catch {
        Write-CPGDebug "Failed to build call graph: $_" -Component "CallGraphBuilder" -Level "ERROR"
        throw
    }
}

# Virtual method resolution for object-oriented code
function Resolve-VirtualMethodCalls {
    param(
        [Parameter(Mandatory)]
        [CallGraph]$CallGraph,
        
        [hashtable]$TypeHierarchy = @{}
    )
    
    Write-CPGDebug "Resolving virtual method calls" -Component "CallGraphBuilder" -Level "INFO"
    
    $resolvedCount = 0
    
    foreach ($edge in $CallGraph.CallEdges.Values) {
        if ($edge.CallType -eq [CallType]::Virtual) {
            # Attempt to resolve based on type hierarchy
            $callerNode = $CallGraph.CallNodes[$edge.CallerId]
            $calleeNode = $CallGraph.CallNodes[$edge.CalleeId]
            
            if ($calleeNode.IsVirtual -or $calleeNode.IsAbstract) {
                # Find concrete implementations
                $implementations = @()
                
                foreach ($node in $CallGraph.CallNodes.Values) {
                    if ($node.IsOverride -and $node.Name -eq $calleeNode.Name) {
                        $implementations += $node
                    }
                }
                
                foreach ($impl in $implementations) {
                    $newEdge = [CallEdge]::new($edge.CallerId, $impl.Id, [CallType]::Override)
                    $newEdge.CallLine = $edge.CallLine
                    $newEdge.ExecutionProbability = 1.0 / $implementations.Count
                    $CallGraph.AddCallEdge($newEdge)
                    $resolvedCount++
                }
                
                Write-CPGDebug "Resolved virtual call to $($calleeNode.Name) with $($implementations.Count) implementations" -Component "CallGraphBuilder"
            }
        }
    }
    
    Write-CPGDebug "Resolved $resolvedCount virtual method calls" -Component "CallGraphBuilder" -Level "SUCCESS"
    return $resolvedCount
}

# Analyze call graph for metrics
function Get-CallGraphMetrics {
    param(
        [Parameter(Mandatory)]
        [CallGraph]$CallGraph
    )
    
    Write-CPGDebug "Calculating call graph metrics" -Component "CallGraphBuilder" -Level "INFO"
    
    $metrics = @{
        TotalFunctions = $CallGraph.Statistics.TotalNodes
        TotalCalls = $CallGraph.Statistics.TotalEdges
        RecursiveFunctions = $CallGraph.Statistics.RecursiveFunctions
        AverageCallsPerFunction = $CallGraph.Statistics.AverageOutDegree
        MaxInDegree = 0
        MaxOutDegree = 0
        MostCalledFunction = $null
        MostCallingFunction = $null
        UnreachableFunctions = @()
        LeafFunctions = @()
        EntryPoints = @()
    }
    
    # Calculate in/out degrees
    foreach ($nodeId in $CallGraph.CallNodes.Keys) {
        $inDegree = if ($CallGraph.CalleeIndex.ContainsKey($nodeId)) {
            $CallGraph.CalleeIndex[$nodeId].Count
        } else { 0 }
        
        $outDegree = if ($CallGraph.CallerIndex.ContainsKey($nodeId)) {
            $CallGraph.CallerIndex[$nodeId].Count
        } else { 0 }
        
        if ($inDegree -gt $metrics.MaxInDegree) {
            $metrics.MaxInDegree = $inDegree
            $metrics.MostCalledFunction = $CallGraph.CallNodes[$nodeId].Name
        }
        
        if ($outDegree -gt $metrics.MaxOutDegree) {
            $metrics.MaxOutDegree = $outDegree
            $metrics.MostCallingFunction = $CallGraph.CallNodes[$nodeId].Name
        }
        
        if ($inDegree -eq 0 -and $CallGraph.CallNodes[$nodeId].Name -ne "<Script>") {
            $metrics.EntryPoints += $CallGraph.CallNodes[$nodeId].Name
        }
        
        if ($outDegree -eq 0) {
            $metrics.LeafFunctions += $CallGraph.CallNodes[$nodeId].Name
        }
    }
    
    # Find unreachable functions (not called and not entry points)
    foreach ($node in $CallGraph.CallNodes.Values) {
        if (-not $CallGraph.CalleeIndex.ContainsKey($node.Id) -and 
            $node.Name -notin $metrics.EntryPoints -and
            $node.Name -ne "<Script>") {
            $metrics.UnreachableFunctions += $node.Name
        }
    }
    
    Write-CPGDebug "Metrics calculated: $($metrics.TotalFunctions) functions, $($metrics.RecursiveFunctions) recursive" -Component "CallGraphBuilder" -Level "SUCCESS"
    
    return $metrics
}

# Export call graph to various formats
function Export-CallGraph {
    param(
        [Parameter(Mandatory)]
        [CallGraph]$CallGraph,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [ValidateSet("JSON", "DOT", "Mermaid")]
        [string]$Format = "JSON"
    )
    
    Write-CPGDebug "Exporting call graph to $Format format" -Component "CallGraphBuilder" -Level "INFO"
    
    switch ($Format) {
        "JSON" {
            $export = @{
                Id = $CallGraph.Id
                Name = $CallGraph.Name
                AnalysisType = $CallGraph.AnalysisType.ToString()
                CreatedAt = $CallGraph.CreatedAt
                Statistics = $CallGraph.Statistics
                Nodes = @()
                Edges = @()
            }
            
            foreach ($node in $CallGraph.CallNodes.Values) {
                $export.Nodes += @{
                    Id = $node.Id
                    Name = $node.Name
                    Type = $node.NodeType.ToString()
                    Signature = $node.GetSignature()
                    FilePath = $node.FilePath
                    StartLine = $node.StartLine
                    EndLine = $node.EndLine
                    IsVirtual = $node.IsVirtual
                    IsOverride = $node.IsOverride
                }
            }
            
            foreach ($edge in $CallGraph.CallEdges.Values) {
                $export.Edges += @{
                    Id = $edge.Id
                    CallerId = $edge.CallerId
                    CalleeId = $edge.CalleeId
                    CallType = $edge.CallType.ToString()
                    CallLine = $edge.CallLine
                    CallFrequency = $edge.CallFrequency
                    ExecutionProbability = $edge.ExecutionProbability
                }
            }
            
            $export | ConvertTo-Json -Depth 10 | Set-Content $OutputPath
        }
        
        "DOT" {
            $dot = @("digraph CallGraph {")
            $dot += '    rankdir=LR;'
            $dot += '    node [shape=box];'
            
            foreach ($node in $CallGraph.CallNodes.Values) {
                $label = $node.Name
                if ($node.IsVirtual) { $label = "<<virtual>> $label" }
                if ($node.IsOverride) { $label = "<<override>> $label" }
                $dot += "    `"$($node.Id)`" [label=`"$label`"];"
            }
            
            foreach ($edge in $CallGraph.CallEdges.Values) {
                $style = switch ($edge.CallType) {
                    "Virtual" { "dashed" }
                    "Indirect" { "dotted" }
                    "Recursive" { "bold" }
                    default { "solid" }
                }
                $dot += "    `"$($edge.CallerId)`" -> `"$($edge.CalleeId)`" [style=$style];"
            }
            
            $dot += "}"
            $dot -join "`n" | Set-Content $OutputPath
        }
        
        "Mermaid" {
            $mermaid = @("graph TD")
            
            foreach ($node in $CallGraph.CallNodes.Values) {
                $shape = if ($node.NodeType -eq [CPGNodeType]::Function) { "()" } else { "[]" }
                $mermaid += "    $($node.Id)$shape$($node.Name)$shape"
            }
            
            foreach ($edge in $CallGraph.CallEdges.Values) {
                $arrow = switch ($edge.CallType) {
                    "Virtual" { "-.->>" }
                    "Indirect" { "..>" }
                    "Recursive" { "==>" }
                    default { "-->" }
                }
                $mermaid += "    $($edge.CallerId) $arrow $($edge.CalleeId)"
            }
            
            $mermaid -join "`n" | Set-Content $OutputPath
        }
    }
    
    Write-CPGDebug "Call graph exported to: $OutputPath" -Component "CallGraphBuilder" -Level "SUCCESS"
}

# Export functions
Export-ModuleMember -Function @(
    'Build-PowerShellCallGraph',
    'Resolve-VirtualMethodCalls',
    'Get-CallGraphMetrics',
    'Export-CallGraph'
)

# IMPLEMENTATION MARKER: Week 1, Day 2, Morning - Call Graph Builder
# Part of Enhanced Documentation System Second Pass Implementation
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDM+RXhMVnXA2/6
# k8tV9zLqRP7Mj+xXhXD7PKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# XGQOLn2RLl1Wk1r3JiRtGZ+gKfOtcmSaJa7eQwBfP8FQoqRzOIoB8GNKwBTJlhEx
# pUUrJPZt+ztNqgqD5xnhzJCo+8aEECXoCrSmC/IZJUhBGiTb1kSJzVzqSfQv2Xnc
# KQeq/aTxpSgAazw8N6aTEQJy9DyWPqpJL9wHs3fO8Kf3Y1Vx8ZhqxHjQQRpoxwyD
# HCVL5KxCqnUNBSCqfZqJYLcVnGaNdw7tBAbZlPu/GsOmHYk3jZKQkkbC/gJTYkGF
# Vlk=
# SIG # End signature block