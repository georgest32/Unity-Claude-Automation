#Requires -Version 5.1
<#
.SYNOPSIS
    Data Flow Tracker for Code Property Graph (CPG) implementation.

.DESCRIPTION
    Tracks variable dependencies, implements taint analysis, creates data propagation paths,
    and performs sensitivity analysis for comprehensive data flow understanding.

.NOTES
    Part of Enhanced Documentation System Second Pass Implementation
    Week 1, Day 2 - Afternoon Session
    Created: 2025-08-28
#>

# Import unified CPG module for base classes
. "$PSScriptRoot\CPG-Unified.psm1"

# Debug helper function (if not already defined)
if (-not (Get-Command Write-CPGDebug -ErrorAction SilentlyContinue)) {
    function Write-CPGDebug {
        param(
            [string]$Message,
            [string]$Component = "CPG"
        )
        
        if ($env:CPG_DEBUG -eq "1" -or $VerbosePreference -ne 'SilentlyContinue') {
            Write-Verbose "[$Component] $Message"
        }
    }
}

# Data flow specific enumerations
enum DataFlowDirection {
    Forward         # Forward data flow (reaching definitions)
    Backward        # Backward data flow (live variables)
    Bidirectional   # Both directions
}

enum TaintLevel {
    Untainted      # Safe data
    PotentiallyTainted  # May be tainted
    Tainted        # Definitely tainted
    Sanitized      # Was tainted but sanitized
}

enum DataSensitivity {
    Public         # Public data
    Internal       # Internal use only
    Confidential   # Confidential data
    Secret         # Secret/sensitive data
    Critical       # Critical security data
}

# Variable Definition class
class VariableDefinition {
    [string]$Id
    [string]$Name
    [string]$Scope
    [int]$Line
    [int]$Column
    [string]$Value
    [string]$Type
    [bool]$IsConstant
    [bool]$IsParameter
    [bool]$IsGlobal
    [datetime]$DefinedAt
    [hashtable]$Metadata
    
    VariableDefinition([string]$name, [int]$line) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Name = $name
        $this.Line = $line
        $this.DefinedAt = Get-Date
        $this.Metadata = @{}
        Write-CPGDebug "Created variable definition: $name at line $line" -Component "DataFlow"
    }
}

# Variable Use class
class VariableUse {
    [string]$Id
    [string]$VariableName
    [int]$Line
    [int]$Column
    [string]$Context  # Read, Write, ReadWrite
    [string]$Expression
    [datetime]$UsedAt
    
    VariableUse([string]$name, [int]$line, [string]$context) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.VariableName = $name
        $this.Line = $line
        $this.Context = $context
        $this.UsedAt = Get-Date
        Write-CPGDebug "Created variable use: $name at line $line ($context)" -Component "DataFlow"
    }
}

# Def-Use Chain class
class DefUseChain {
    [string]$DefinitionId
    [string[]]$UseIds
    [string]$VariableName
    [bool]$IsActive
    
    DefUseChain([string]$defId, [string]$varName) {
        $this.DefinitionId = $defId
        $this.VariableName = $varName
        $this.UseIds = @()
        $this.IsActive = $true
        Write-CPGDebug "Created def-use chain for: $varName" -Component "DataFlow"
    }
    
    [void] AddUse([string]$useId) {
        $this.UseIds += $useId
        Write-CPGDebug "Added use to chain: $useId for variable $($this.VariableName)" -Component "DataFlow"
    }
}

# Use-Def Chain class
class UseDefChain {
    [string]$UseId
    [string[]]$DefinitionIds
    [string]$VariableName
    
    UseDefChain([string]$useId, [string]$varName) {
        $this.UseId = $useId
        $this.VariableName = $varName
        $this.DefinitionIds = @()
        Write-CPGDebug "Created use-def chain for: $varName" -Component "DataFlow"
    }
    
    [void] AddDefinition([string]$defId) {
        $this.DefinitionIds += $defId
        Write-CPGDebug "Added definition to chain: $defId for variable $($this.VariableName)" -Component "DataFlow"
    }
}

# Taint Information class
class TaintInfo {
    [string]$VariableId
    [TaintLevel]$Level
    [string[]]$Sources
    [string[]]$Sinks
    [string[]]$PropagationPath
    [datetime]$TaintedAt
    [string]$TaintReason
    
    TaintInfo([string]$varId, [TaintLevel]$level, [string]$reason) {
        $this.VariableId = $varId
        $this.Level = $level
        $this.TaintReason = $reason
        $this.Sources = @()
        $this.Sinks = @()
        $this.PropagationPath = @()
        $this.TaintedAt = Get-Date
        Write-CPGDebug "Created taint info: $varId with level $level - $reason" -Component "DataFlow" -Level "WARNING"
    }
    
    [void] AddPropagation([string]$nodeId) {
        $this.PropagationPath += $nodeId
        Write-CPGDebug "Added to taint propagation path: $nodeId" -Component "DataFlow"
    }
}

# Data Flow Graph class
class DataFlowGraph {
    [string]$Id
    [string]$Name
    [hashtable]$Definitions      # Id -> VariableDefinition
    [hashtable]$Uses             # Id -> VariableUse
    [hashtable]$DefUseChains     # DefId -> DefUseChain
    [hashtable]$UseDefChains     # UseId -> UseDefChain
    [hashtable]$ReachingDefs     # Line -> [DefIds]
    [hashtable]$LiveVariables    # Line -> [VarNames]
    [hashtable]$TaintAnalysis    # VarId -> TaintInfo
    [DataFlowDirection]$Direction
    [datetime]$CreatedAt
    [hashtable]$Statistics
    
    DataFlowGraph([string]$name) {
        $this.Id = [guid]::NewGuid().ToString()
        $this.Name = $name
        $this.Definitions = [hashtable]::Synchronized(@{})
        $this.Uses = [hashtable]::Synchronized(@{})
        $this.DefUseChains = [hashtable]::Synchronized(@{})
        $this.UseDefChains = [hashtable]::Synchronized(@{})
        $this.ReachingDefs = [hashtable]::Synchronized(@{})
        $this.LiveVariables = [hashtable]::Synchronized(@{})
        $this.TaintAnalysis = [hashtable]::Synchronized(@{})
        $this.Direction = [DataFlowDirection]::Bidirectional
        $this.CreatedAt = Get-Date
        $this.Statistics = @{
            TotalDefinitions = 0
            TotalUses = 0
            TaintedVariables = 0
            LiveVariableCount = 0
        }
        Write-CPGDebug "Created DataFlowGraph: $name" -Component "DataFlow" -Level "SUCCESS"
    }
    
    [void] AddDefinition([VariableDefinition]$def) {
        $this.Definitions[$def.Id] = $def
        $this.Statistics.TotalDefinitions++
        
        # Create def-use chain
        $chain = [DefUseChain]::new($def.Id, $def.Name)
        $this.DefUseChains[$def.Id] = $chain
        
        # Update reaching definitions
        if (-not $this.ReachingDefs.ContainsKey($def.Line)) {
            $this.ReachingDefs[$def.Line] = @()
        }
        $this.ReachingDefs[$def.Line] += $def.Id
        
        Write-CPGDebug "Added definition: $($def.Name) at line $($def.Line)" -Component "DataFlow"
    }
    
    [void] AddUse([VariableUse]$use) {
        $this.Uses[$use.Id] = $use
        $this.Statistics.TotalUses++
        
        # Create use-def chain
        $chain = [UseDefChain]::new($use.Id, $use.VariableName)
        $this.UseDefChains[$use.Id] = $chain
        
        # Link with reaching definitions
        $this.LinkUseWithDefinitions($use)
        
        Write-CPGDebug "Added use: $($use.VariableName) at line $($use.Line)" -Component "DataFlow"
    }
    
    [void] LinkUseWithDefinitions([VariableUse]$use) {
        # Find all reaching definitions for this use
        $reachingDefIds = $this.GetReachingDefinitions($use.Line, $use.VariableName)
        
        foreach ($defId in $reachingDefIds) {
            # Update def-use chain
            if ($this.DefUseChains.ContainsKey($defId)) {
                $this.DefUseChains[$defId].AddUse($use.Id)
            }
            
            # Update use-def chain
            if ($this.UseDefChains.ContainsKey($use.Id)) {
                $this.UseDefChains[$use.Id].AddDefinition($defId)
            }
        }
        
        Write-CPGDebug "Linked use at line $($use.Line) with $($reachingDefIds.Count) definitions" -Component "DataFlow"
    }
    
    [string[]] GetReachingDefinitions([int]$line, [string]$varName) {
        $reaching = @()
        
        # Simple implementation: find all definitions before this line
        foreach ($def in $this.Definitions.Values) {
            if ($def.Name -eq $varName -and $def.Line -lt $line) {
                $reaching += $def.Id
            }
        }
        
        return $reaching
    }
    
    [void] MarkTainted([string]$varId, [TaintLevel]$level, [string]$reason) {
        $taint = [TaintInfo]::new($varId, $level, $reason)
        $this.TaintAnalysis[$varId] = $taint
        $this.Statistics.TaintedVariables++
        
        Write-CPGDebug "Marked variable as tainted: $varId - $reason" -Component "DataFlow" -Level "WARNING"
        
        # Propagate taint through data flow
        $this.PropagateTaint($varId)
    }
    
    [void] PropagateTaint([string]$varId) {
        if (-not $this.DefUseChains.ContainsKey($varId)) {
            return
        }
        
        $chain = $this.DefUseChains[$varId]
        $taintInfo = $this.TaintAnalysis[$varId]
        
        foreach ($useId in $chain.UseIds) {
            $use = $this.Uses[$useId]
            
            # If this use is a write context, propagate taint
            if ($use.Context -in @("Write", "ReadWrite")) {
                # Find definitions that this use creates
                $subsequentDefs = $this.Definitions.Values | Where-Object {
                    $_.Name -eq $use.VariableName -and $_.Line -eq $use.Line
                }
                
                foreach ($def in $subsequentDefs) {
                    if (-not $this.TaintAnalysis.ContainsKey($def.Id)) {
                        $this.MarkTainted($def.Id, [TaintLevel]::PotentiallyTainted, "Propagated from $varId")
                        $taintInfo.AddPropagation($def.Id)
                    }
                }
            }
        }
        
        Write-CPGDebug "Propagated taint from $varId through $($chain.UseIds.Count) uses" -Component "DataFlow"
    }
    
    [hashtable] GetDataFlowStatistics() {
        $this.Statistics.LiveVariableCount = ($this.LiveVariables.Values | ForEach-Object { $_ } | Select-Object -Unique).Count
        return $this.Statistics
    }
}

# PowerShell AST-based data flow analyzer
function Build-PowerShellDataFlow {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath,
        
        [DataFlowDirection]$Direction = [DataFlowDirection]::Bidirectional
    )
    
    Write-CPGDebug "Building PowerShell data flow for: $ScriptPath" -Component "DataFlowTracker" -Level "INFO"
    
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
        
        $dataFlow = [DataFlowGraph]::new((Split-Path -Leaf $ScriptPath))
        $dataFlow.Direction = $Direction
        
        # Find all variable assignments (definitions)
        $assignmentAsts = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.AssignmentStatementAst]
        }, $true)
        
        foreach ($assignment in $assignmentAsts) {
            $varName = $null
            
            if ($assignment.Left -is [System.Management.Automation.Language.VariableExpressionAst]) {
                $varName = $assignment.Left.VariablePath.UserPath
            }
            
            if ($varName) {
                $def = [VariableDefinition]::new($varName, $assignment.Extent.StartLineNumber)
                $def.Column = $assignment.Extent.StartColumnNumber
                
                # Determine scope
                $parent = $assignment.Parent
                $scope = "Local"
                while ($parent) {
                    if ($parent -is [System.Management.Automation.Language.FunctionDefinitionAst]) {
                        $scope = "Function:$($parent.Name)"
                        break
                    }
                    $parent = $parent.Parent
                }
                if ($scope -eq "Local" -and $varName -match '^(global:|script:)') {
                    $scope = "Global"
                    $def.IsGlobal = $true
                }
                $def.Scope = $scope
                
                $dataFlow.AddDefinition($def)
                
                Write-CPGDebug "Found assignment: $varName at line $($def.Line) in scope $scope" -Component "DataFlowTracker"
            }
        }
        
        # Find all variable uses
        $variableAsts = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.VariableExpressionAst]
        }, $true)
        
        foreach ($varAst in $variableAsts) {
            $varName = $varAst.VariablePath.UserPath
            
            # Determine context (Read, Write, ReadWrite)
            $context = "Read"
            $parent = $varAst.Parent
            
            if ($parent -is [System.Management.Automation.Language.AssignmentStatementAst]) {
                if ($parent.Left -eq $varAst) {
                    $context = "Write"
                } else {
                    $context = "Read"
                }
            } elseif ($parent -is [System.Management.Automation.Language.UnaryExpressionAst] -and
                     $parent.TokenKind -in @([System.Management.Automation.Language.TokenKind]::PlusPlus,
                                            [System.Management.Automation.Language.TokenKind]::MinusMinus)) {
                $context = "ReadWrite"
            }
            
            $use = [VariableUse]::new($varName, $varAst.Extent.StartLineNumber, $context)
            $use.Column = $varAst.Extent.StartColumnNumber
            $use.Expression = $varAst.Extent.Text
            
            $dataFlow.AddUse($use)
            
            Write-CPGDebug "Found variable use: $varName at line $($use.Line) ($context)" -Component "DataFlowTracker"
        }
        
        # Perform taint analysis for dangerous patterns
        $dangerousPatterns = @(
            'Invoke-Expression',
            'Invoke-Command',
            'Start-Process',
            'New-Object System.Diagnostics.ProcessStartInfo',
            '& ',
            '. '
        )
        
        $commandAsts = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.CommandAst]
        }, $true)
        
        foreach ($cmdAst in $commandAsts) {
            $cmdText = $cmdAst.Extent.Text
            
            foreach ($pattern in $dangerousPatterns) {
                if ($cmdText -like "*$pattern*") {
                    # Find variables used in this command
                    $varsInCommand = $cmdAst.FindAll({
                        $args[0] -is [System.Management.Automation.Language.VariableExpressionAst]
                    }, $true)
                    
                    foreach ($varAst in $varsInCommand) {
                        $varName = $varAst.VariablePath.UserPath
                        
                        # Find definition for this variable
                        $defs = $dataFlow.Definitions.Values | Where-Object {
                            $_.Name -eq $varName -and $_.Line -le $cmdAst.Extent.StartLineNumber
                        } | Sort-Object Line -Descending | Select-Object -First 1
                        
                        if ($defs) {
                            $dataFlow.MarkTainted($defs.Id, [TaintLevel]::Tainted, "Used in dangerous command: $pattern")
                        }
                    }
                    
                    Write-CPGDebug "Found dangerous pattern: $pattern at line $($cmdAst.Extent.StartLineNumber)" -Component "DataFlowTracker" -Level "WARNING"
                }
            }
        }
        
        # Compute live variables (backward analysis)
        if ($Direction -in @([DataFlowDirection]::Backward, [DataFlowDirection]::Bidirectional)) {
            $dataFlow = Compute-LiveVariables -DataFlow $dataFlow
        }
        
        $stats = $dataFlow.GetDataFlowStatistics()
        Write-CPGDebug "Data flow complete: $($stats.TotalDefinitions) defs, $($stats.TotalUses) uses, $($stats.TaintedVariables) tainted" -Component "DataFlowTracker" -Level "SUCCESS"
        
        return $dataFlow
        
    } catch {
        Write-CPGDebug "Failed to build data flow: $_" -Component "DataFlowTracker" -Level "ERROR"
        throw
    }
}

# Compute live variables using backward analysis
function Compute-LiveVariables {
    param(
        [Parameter(Mandatory)]
        [DataFlowGraph]$DataFlow
    )
    
    Write-CPGDebug "Computing live variables" -Component "DataFlowTracker" -Level "INFO"
    
    # Get all lines with uses or definitions
    $allLines = @()
    $allLines += $DataFlow.Definitions.Values | ForEach-Object { $_.Line }
    $allLines += $DataFlow.Uses.Values | ForEach-Object { $_.Line }
    $allLines = $allLines | Sort-Object -Unique -Descending
    
    # Initialize live variables for each line
    foreach ($line in $allLines) {
        $DataFlow.LiveVariables[$line] = @()
    }
    
    # Backward analysis
    $changed = $true
    $iterations = 0
    $maxIterations = 100
    
    while ($changed -and $iterations -lt $maxIterations) {
        $changed = $false
        $iterations++
        
        foreach ($line in $allLines) {
            $oldLive = $DataFlow.LiveVariables[$line]
            
            # Gen: variables used at this line
            $gen = $DataFlow.Uses.Values | Where-Object { $_.Line -eq $line -and $_.Context -ne "Write" } | 
                   ForEach-Object { $_.VariableName } | Select-Object -Unique
            if ($null -eq $gen) { $gen = @() }
            
            # Kill: variables defined at this line
            $kill = $DataFlow.Definitions.Values | Where-Object { $_.Line -eq $line } | 
                    ForEach-Object { $_.Name } | Select-Object -Unique
            if ($null -eq $kill) { $kill = @() }
            
            # Get live variables from successor lines
            $successorLive = @()
            $nextLine = $allLines | Where-Object { $_ -gt $line } | Select-Object -First 1
            if ($nextLine) {
                $successorLive = $DataFlow.LiveVariables[$nextLine]
                if ($null -eq $successorLive) { $successorLive = @() }
            }
            
            # Live = gen ∪ (successor_live - kill)
            $newLive = @()
            if ($gen) {
                $newLive += $gen
            }
            if ($successorLive) {
                foreach ($var in $successorLive) {
                    if ($kill -and $var -notin $kill) {
                        $newLive += $var
                    } elseif (-not $kill) {
                        $newLive += $var
                    }
                }
            }
            if ($newLive) {
                $newLive = $newLive | Select-Object -Unique
            } else {
                $newLive = @()
            }
            
            # Check if changed (with null checks)
            $hasChanged = $false
            if ($null -eq $oldLive -and $null -ne $newLive) {
                $hasChanged = $true
            } elseif ($null -ne $oldLive -and $null -eq $newLive) {
                $hasChanged = $true
            } elseif ($null -ne $oldLive -and $null -ne $newLive) {
                $diff = Compare-Object -ReferenceObject $oldLive -DifferenceObject $newLive -ErrorAction SilentlyContinue
                if ($diff) {
                    $hasChanged = $true
                }
            }
            
            if ($hasChanged) {
                $DataFlow.LiveVariables[$line] = $newLive
                $changed = $true
            }
        }
        
        Write-CPGDebug "Live variable iteration $iterations completed" -Component "DataFlowTracker"
    }
    
    Write-CPGDebug "Live variable analysis complete after $iterations iterations" -Component "DataFlowTracker" -Level "SUCCESS"
    return $DataFlow
}

# Analyze data sensitivity
function Analyze-DataSensitivity {
    param(
        [Parameter(Mandatory)]
        [DataFlowGraph]$DataFlow,
        
        [hashtable]$SensitivityRules = @{
            "password" = [DataSensitivity]::Secret
            "token" = [DataSensitivity]::Secret
            "key" = [DataSensitivity]::Secret
            "secret" = [DataSensitivity]::Secret
            "credential" = [DataSensitivity]::Critical
            "ssn" = [DataSensitivity]::Critical
            "creditcard" = [DataSensitivity]::Critical
        }
    )
    
    Write-CPGDebug "Analyzing data sensitivity" -Component "DataFlowTracker" -Level "INFO"
    
    $sensitiveVars = @{}
    
    foreach ($def in $DataFlow.Definitions.Values) {
        $sensitivity = [DataSensitivity]::Public
        
        # Check variable name against rules
        foreach ($pattern in $SensitivityRules.Keys) {
            if ($def.Name -like "*$pattern*") {
                $sensitivity = $SensitivityRules[$pattern]
                Write-CPGDebug "Found sensitive variable: $($def.Name) - $sensitivity" -Component "DataFlowTracker" -Level "WARNING"
                break
            }
        }
        
        $sensitiveVars[$def.Id] = @{
            Variable = $def
            Sensitivity = $sensitivity
            ExposureRisk = $false
        }
        
        # Check if sensitive data is exposed
        if ($sensitivity -ne [DataSensitivity]::Public) {
            # Check if used in logging or output commands
            $uses = $DataFlow.Uses.Values | Where-Object { $_.VariableName -eq $def.Name }
            foreach ($use in $uses) {
                if ($use.Expression -match '(Write-Host|Write-Output|Out-File|Export-)') {
                    $sensitiveVars[$def.Id].ExposureRisk = $true
                    Write-CPGDebug "SECURITY RISK: Sensitive variable $($def.Name) may be exposed at line $($use.Line)" -Component "DataFlowTracker" -Level "ERROR"
                }
            }
        }
    }
    
    Write-CPGDebug "Sensitivity analysis complete: Found $($sensitiveVars.Count) variables" -Component "DataFlowTracker" -Level "SUCCESS"
    return $sensitiveVars
}

# Get data flow metrics
function Get-DataFlowMetrics {
    param(
        [Parameter(Mandatory)]
        [DataFlowGraph]$DataFlow
    )
    
    Write-CPGDebug "Calculating data flow metrics" -Component "DataFlowTracker" -Level "INFO"
    
    $metrics = @{
        TotalVariables = ($DataFlow.Definitions.Values | ForEach-Object { $_.Name } | Select-Object -Unique).Count
        TotalDefinitions = $DataFlow.Statistics.TotalDefinitions
        TotalUses = $DataFlow.Statistics.TotalUses
        DefUseRatio = if ($DataFlow.Statistics.TotalUses -gt 0) { 
            $DataFlow.Statistics.TotalDefinitions / $DataFlow.Statistics.TotalUses 
        } else { 0 }
        TaintedVariables = $DataFlow.Statistics.TaintedVariables
        TaintPercentage = if ($DataFlow.Statistics.TotalDefinitions -gt 0) {
            ($DataFlow.Statistics.TaintedVariables / $DataFlow.Statistics.TotalDefinitions) * 100
        } else { 0 }
        AverageLiveVariables = 0
        MaxLiveVariables = 0
        UnusedDefinitions = @()
        UndefinedUses = @()
    }
    
    # Calculate live variable metrics
    if ($DataFlow.LiveVariables.Count -gt 0) {
        $liveCounts = $DataFlow.LiveVariables.Values | ForEach-Object { $_.Count }
        $metrics.AverageLiveVariables = ($liveCounts | Measure-Object -Average).Average
        $metrics.MaxLiveVariables = ($liveCounts | Measure-Object -Maximum).Maximum
    }
    
    # Find unused definitions
    foreach ($def in $DataFlow.Definitions.Values) {
        if (-not $DataFlow.DefUseChains.ContainsKey($def.Id) -or 
            $DataFlow.DefUseChains[$def.Id].UseIds.Count -eq 0) {
            $metrics.UnusedDefinitions += $def.Name
        }
    }
    
    # Find undefined uses
    foreach ($use in $DataFlow.Uses.Values) {
        if (-not $DataFlow.UseDefChains.ContainsKey($use.Id) -or 
            $DataFlow.UseDefChains[$use.Id].DefinitionIds.Count -eq 0) {
            $metrics.UndefinedUses += @{
                Variable = $use.VariableName
                Line = $use.Line
            }
        }
    }
    
    Write-CPGDebug "Metrics calculated: $($metrics.TotalVariables) vars, $($metrics.TaintPercentage)% tainted" -Component "DataFlowTracker" -Level "SUCCESS"
    
    return $metrics
}

# Export data flow to various formats
function Export-DataFlow {
    param(
        [Parameter(Mandatory)]
        [DataFlowGraph]$DataFlow,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [ValidateSet("JSON", "DOT", "CSV")]
        [string]$Format = "JSON"
    )
    
    Write-CPGDebug "Exporting data flow to $Format format" -Component "DataFlowTracker" -Level "INFO"
    
    switch ($Format) {
        "JSON" {
            $export = @{
                Id = $DataFlow.Id
                Name = $DataFlow.Name
                Direction = $DataFlow.Direction.ToString()
                CreatedAt = $DataFlow.CreatedAt
                Statistics = $DataFlow.Statistics
                Definitions = @()
                Uses = @()
                DefUseChains = @()
                TaintAnalysis = @()
            }
            
            foreach ($def in $DataFlow.Definitions.Values) {
                $export.Definitions += @{
                    Id = $def.Id
                    Name = $def.Name
                    Line = $def.Line
                    Scope = $def.Scope
                    IsGlobal = $def.IsGlobal
                    IsConstant = $def.IsConstant
                }
            }
            
            foreach ($use in $DataFlow.Uses.Values) {
                $export.Uses += @{
                    Id = $use.Id
                    Variable = $use.VariableName
                    Line = $use.Line
                    Context = $use.Context
                }
            }
            
            foreach ($chain in $DataFlow.DefUseChains.Values) {
                if ($chain.UseIds.Count -gt 0) {
                    $export.DefUseChains += @{
                        Definition = $chain.DefinitionId
                        Variable = $chain.VariableName
                        Uses = $chain.UseIds
                    }
                }
            }
            
            foreach ($taint in $DataFlow.TaintAnalysis.Values) {
                $export.TaintAnalysis += @{
                    Variable = $taint.VariableId
                    Level = $taint.Level.ToString()
                    Reason = $taint.TaintReason
                    PropagationPath = $taint.PropagationPath
                }
            }
            
            $export | ConvertTo-Json -Depth 10 | Set-Content $OutputPath
        }
        
        "DOT" {
            $dot = @("digraph DataFlow {")
            $dot += '    rankdir=TB;'
            $dot += '    node [shape=box];'
            
            # Add definition nodes
            foreach ($def in $DataFlow.Definitions.Values) {
                $color = if ($DataFlow.TaintAnalysis.ContainsKey($def.Id)) {
                    "red"
                } else {
                    "black"
                }
                $dot += "    `"def_$($def.Id)`" [label=`"$($def.Name) (L$($def.Line))`" color=$color];"
            }
            
            # Add use nodes
            foreach ($use in $DataFlow.Uses.Values) {
                $dot += "    `"use_$($use.Id)`" [label=`"USE: $($use.VariableName) (L$($use.Line))`" shape=ellipse];"
            }
            
            # Add def-use edges
            foreach ($chain in $DataFlow.DefUseChains.Values) {
                foreach ($useId in $chain.UseIds) {
                    $dot += "    `"def_$($chain.DefinitionId)`" -> `"use_$useId`";"
                }
            }
            
            $dot += "}"
            $dot -join "`n" | Set-Content $OutputPath
        }
        
        "CSV" {
            $csv = @()
            
            # Create def-use relationships
            foreach ($chain in $DataFlow.DefUseChains.Values) {
                $def = $DataFlow.Definitions[$chain.DefinitionId]
                foreach ($useId in $chain.UseIds) {
                    $use = $DataFlow.Uses[$useId]
                    $csv += [PSCustomObject]@{
                        Variable = $chain.VariableName
                        DefinitionLine = $def.Line
                        UseLine = $use.Line
                        UseContext = $use.Context
                        IsTainted = $DataFlow.TaintAnalysis.ContainsKey($chain.DefinitionId)
                    }
                }
            }
            
            $csv | Export-Csv -Path $OutputPath -NoTypeInformation
        }
    }
    
    Write-CPGDebug "Data flow exported to: $OutputPath" -Component "DataFlowTracker" -Level "SUCCESS"
}

# Export functions
Export-ModuleMember -Function @(
    'Build-PowerShellDataFlow',
    'Compute-LiveVariables',
    'Analyze-DataSensitivity',
    'Get-DataFlowMetrics',
    'Export-DataFlow'
)

# IMPLEMENTATION MARKER: Week 1, Day 2, Afternoon - Data Flow Tracker
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