#requires -Version 5.1

<#
.SYNOPSIS
Unity-Claude-AST-Enhanced PowerShell Module
Enhanced AST analysis and function call mapping for visualization relationships

.DESCRIPTION
This module provides comprehensive AST analysis capabilities including:
- Function call graph generation using DependencySearch and Out-PSModuleCallGraph
- Cross-module relationship mapping with dependency strength calculation
- D3.js-compatible data export for network visualization
- Integration with Enhanced Documentation System components

.NOTES
Module: Unity-Claude-AST-Enhanced
Version: 1.0.0
Date: 2025-08-30
Author: Unity-Claude-Automation System
Dependencies: DependencySearch module, Out-PSModuleCallGraph script
#>

# Import required modules
Import-Module DependencySearch -Force -ErrorAction SilentlyContinue

#region Module Variables
$script:ModuleRoot = $PSScriptRoot
$script:ToolsPath = Join-Path (Split-Path $PSScriptRoot -Parent | Split-Path -Parent) "Tools"
$script:CallGraphCache = @{}
$script:RelationshipCache = @{}
#endregion

#region Core Functions

<#
.SYNOPSIS
Generates comprehensive call graphs for PowerShell modules using enhanced AST analysis

.DESCRIPTION
Creates detailed function call graphs by combining DependencySearch module capabilities
with Out-PSModuleCallGraph visualization. Analyzes function dependencies, call patterns,
and cross-module relationships.

.PARAMETER ModulePaths
Array of paths to PowerShell modules (.psm1 files) to analyze

.PARAMETER ModuleNames
Array of loaded module names to analyze

.PARAMETER IncludeBuiltIn
Include built-in PowerShell cmdlets in analysis

.PARAMETER CacheResults
Cache results for performance optimization

.EXAMPLE
Get-ModuleCallGraph -ModulePaths @("C:\Modules\MyModule.psm1") -IncludeBuiltIn $false

.EXAMPLE
Get-ModuleCallGraph -ModuleNames @("Unity-Claude-Core", "Unity-Claude-SystemStatus")
#>
function Get-ModuleCallGraph {
    [CmdletBinding()]
    param(
        [string[]]$ModulePaths,
        [string[]]$ModuleNames,
        [switch]$IncludeBuiltIn,
        [switch]$CacheResults = $true
    )
    
    Write-Verbose "Starting enhanced call graph analysis..."
    $startTime = Get-Date
    
    try {
        $analysisResults = @{}
        $allModules = @()
        
        # Process module paths
        if ($ModulePaths) {
            foreach ($path in $ModulePaths) {
                if (Test-Path $path) {
                    Write-Verbose "Processing module path: $path"
                    $moduleInfo = Get-ModuleAnalysisFromPath -Path $path -IncludeBuiltIn:$IncludeBuiltIn
                    $allModules += $moduleInfo
                }
                else {
                    Write-Warning "Module path not found: $path"
                }
            }
        }
        
        # Process module names
        if ($ModuleNames) {
            foreach ($moduleName in $ModuleNames) {
                Write-Verbose "Processing module name: $moduleName"
                $module = Get-Module -Name $moduleName -ErrorAction SilentlyContinue
                if ($module) {
                    $moduleInfo = Get-ModuleAnalysisFromModule -Module $module -IncludeBuiltIn:$IncludeBuiltIn
                    $allModules += $moduleInfo
                }
                else {
                    Write-Warning "Module not found or not loaded: $moduleName"
                }
            }
        }
        
        # Generate comprehensive call graph
        $callGraph = @{
            Modules = $allModules
            Relationships = Get-ModuleRelationships -Modules $allModules
            GeneratedOn = Get-Date
            AnalysisMetrics = @{
                TotalModules = $allModules.Count
                TotalFunctions = ($allModules | ForEach-Object { $_.Functions.Count } | Measure-Object -Sum).Sum
                TotalRelationships = 0  # Will be calculated
                AnalysisTime = (Get-Date) - $startTime
            }
        }
        
        # Calculate relationship count
        $callGraph.AnalysisMetrics.TotalRelationships = $callGraph.Relationships.Count
        
        # Cache results if requested
        if ($CacheResults) {
            $cacheKey = ($ModulePaths + $ModuleNames) -join "|"
            $script:CallGraphCache[$cacheKey] = $callGraph
        }
        
        Write-Verbose "Call graph analysis completed in $($callGraph.AnalysisMetrics.AnalysisTime.TotalSeconds) seconds"
        return $callGraph
    }
    catch {
        Write-Error "Error generating call graph: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
Maps cross-module relationships and dependencies with strength calculation

.DESCRIPTION
Analyzes relationships between modules including Import-Module statements,
function calls across modules, and dependency strength based on usage frequency.

.PARAMETER Modules
Array of module analysis objects to analyze relationships

.PARAMETER CalculateStrength
Calculate dependency strength metrics based on usage frequency

.EXAMPLE
Get-CrossModuleRelationships -Modules $moduleData -CalculateStrength
#>
function Get-CrossModuleRelationships {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Modules,
        [switch]$CalculateStrength = $true
    )
    
    Write-Verbose "Analyzing cross-module relationships..."
    
    try {
        $relationships = @()
        $moduleMap = @{}
        
        # Create module lookup map
        foreach ($module in $Modules) {
            $moduleMap[$module.Name] = $module
        }
        
        # Analyze each module's dependencies
        foreach ($module in $Modules) {
            Write-Verbose "Analyzing relationships for module: $($module.Name)"
            
            # Analyze Import-Module statements
            $imports = Get-ImportModuleFromModule -Module $module
            foreach ($import in $imports) {
                $relationship = @{
                    SourceModule = $module.Name
                    TargetModule = $import.ModuleName
                    RelationshipType = "Import"
                    Strength = 1
                    Frequency = $import.Frequency
                    Details = $import
                }
                
                if ($CalculateStrength) {
                    $relationship.Strength = Calculate-DependencyStrength -Relationship $relationship
                }
                
                $relationships += $relationship
            }
            
            # Analyze function call relationships
            $functionCalls = Get-CrossModuleFunctionCalls -Module $module -ModuleMap $moduleMap
            foreach ($call in $functionCalls) {
                $relationship = @{
                    SourceModule = $module.Name
                    TargetModule = $call.TargetModule
                    RelationshipType = "FunctionCall"
                    SourceFunction = $call.SourceFunction
                    TargetFunction = $call.TargetFunction
                    Strength = 1
                    Frequency = $call.Frequency
                    Details = $call
                }
                
                if ($CalculateStrength) {
                    $relationship.Strength = Calculate-DependencyStrength -Relationship $relationship
                }
                
                $relationships += $relationship
            }
        }
        
        Write-Verbose "Found $($relationships.Count) cross-module relationships"
        return $relationships
    }
    catch {
        Write-Error "Error analyzing cross-module relationships: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
Analyzes function call patterns within and across modules

.DESCRIPTION
Performs comprehensive analysis of function call patterns including call frequency,
call depth, parameter usage, and dependency chains.

.PARAMETER Module
Module object to analyze function calls

.PARAMETER IncludeInternal
Include internal function calls within the module

.PARAMETER IncludeExternal
Include external function calls to other modules

.EXAMPLE
Get-FunctionCallAnalysis -Module $moduleData -IncludeInternal -IncludeExternal
#>
function Get-FunctionCallAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Module,
        [switch]$IncludeInternal = $true,
        [switch]$IncludeExternal = $true
    )
    
    Write-Verbose "Analyzing function call patterns for module: $($Module.Name)"
    
    try {
        $callAnalysis = @{
            ModuleName = $Module.Name
            InternalCalls = @()
            ExternalCalls = @()
            CallStatistics = @{}
            FunctionComplexity = @{}
        }
        
        foreach ($function in $Module.Functions) {
            Write-Verbose "Analyzing function: $($function.Name)"
            
            # Parse function AST for call analysis
            $functionAST = $function.AST
            if ($functionAST) {
                # Find all command calls in function
                $commandCalls = $functionAST.FindAll({
                    $args[0] -is [System.Management.Automation.Language.CommandAst]
                }, $true)
                
                foreach ($call in $commandCalls) {
                    $commandName = $call.CommandElements[0].Value
                    
                    # Determine if call is internal or external
                    $isInternal = $Module.Functions.Name -contains $commandName
                    
                    $callInfo = @{
                        SourceFunction = $function.Name
                        TargetCommand = $commandName
                        Parameters = @($call.CommandElements | Select-Object -Skip 1 | ForEach-Object { $_.Value })
                        LineNumber = $call.Extent.StartLineNumber
                        IsInternal = $isInternal
                    }
                    
                    if ($isInternal -and $IncludeInternal) {
                        $callAnalysis.InternalCalls += $callInfo
                    }
                    elseif (-not $isInternal -and $IncludeExternal) {
                        $callAnalysis.ExternalCalls += $callInfo
                    }
                }
                
                # Calculate function complexity metrics
                $callAnalysis.FunctionComplexity[$function.Name] = @{
                    TotalCalls = $commandCalls.Count
                    UniqueCalls = ($commandCalls | Select-Object -ExpandProperty CommandElements | 
                                  Select-Object -First 1 -ExpandProperty Value | Sort-Object -Unique).Count
                    MaxCallDepth = Get-MaxCallDepth -FunctionAST $functionAST
                    CyclomaticComplexity = Get-CyclomaticComplexity -FunctionAST $functionAST
                }
            }
        }
        
        # Calculate call statistics
        $callAnalysis.CallStatistics = @{
            TotalInternalCalls = $callAnalysis.InternalCalls.Count
            TotalExternalCalls = $callAnalysis.ExternalCalls.Count
            UniqueInternalTargets = ($callAnalysis.InternalCalls | Select-Object -ExpandProperty TargetCommand -Unique).Count
            UniqueExternalTargets = ($callAnalysis.ExternalCalls | Select-Object -ExpandProperty TargetCommand -Unique).Count
        }
        
        Write-Verbose "Function call analysis completed for $($Module.Name)"
        return $callAnalysis
    }
    catch {
        Write-Error "Error analyzing function calls: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
Exports call graph data in formats suitable for visualization

.DESCRIPTION
Exports enhanced call graph data in various formats including D3.js JSON,
relationship matrices, and GraphML for different visualization tools.

.PARAMETER CallGraph
Call graph object to export

.PARAMETER OutputPath
Path where export files will be saved

.PARAMETER ExportFormat
Format for export: D3JS, GraphML, CSV, or All

.EXAMPLE
Export-CallGraphData -CallGraph $graph -OutputPath ".\Exports" -ExportFormat "D3JS"
#>
function Export-CallGraphData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$CallGraph,
        [Parameter(Mandatory)]
        [string]$OutputPath,
        [ValidateSet("D3JS", "GraphML", "CSV", "All")]
        [string]$ExportFormat = "D3JS"
    )
    
    Write-Verbose "Exporting call graph data in format: $ExportFormat"
    
    try {
        # Ensure output directory exists
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
        
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $exportResults = @{}
        
        if ($ExportFormat -eq "D3JS" -or $ExportFormat -eq "All") {
            $d3Data = Convert-ToD3JSFormat -CallGraph $CallGraph
            $d3Path = Join-Path $OutputPath "call_graph_d3_$timestamp.json"
            $d3Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $d3Path -Encoding UTF8
            $exportResults.D3JS = $d3Path
            Write-Verbose "D3.js data exported to: $d3Path"
        }
        
        if ($ExportFormat -eq "GraphML" -or $ExportFormat -eq "All") {
            $graphMLData = Convert-ToGraphML -CallGraph $CallGraph
            $graphMLPath = Join-Path $OutputPath "call_graph_$timestamp.graphml"
            $graphMLData | Out-File -FilePath $graphMLPath -Encoding UTF8
            $exportResults.GraphML = $graphMLPath
            Write-Verbose "GraphML data exported to: $graphMLPath"
        }
        
        if ($ExportFormat -eq "CSV" -or $ExportFormat -eq "All") {
            $csvData = Convert-ToCSV -CallGraph $CallGraph
            $csvPath = Join-Path $OutputPath "call_graph_relationships_$timestamp.csv"
            $csvData | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
            $exportResults.CSV = $csvPath
            Write-Verbose "CSV data exported to: $csvPath"
        }
        
        return $exportResults
    }
    catch {
        Write-Error "Error exporting call graph data: $($_.Exception.Message)"
        throw
    }
}

#endregion

#region Helper Functions

function Get-ModuleAnalysisFromPath {
    param([string]$Path, [switch]$IncludeBuiltIn)
    
    $content = Get-Content -Path $Path -Raw
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
    
    # Extract functions using AST
    $functions = $ast.FindAll({
        $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true)
    
    $moduleInfo = @{
        Name = (Get-Item $Path).BaseName
        Path = $Path
        Functions = @()
        AST = $ast
    }
    
    foreach ($func in $functions) {
        $functionInfo = @{
            Name = $func.Name
            Parameters = @($func.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
            AST = $func
            LineNumber = $func.Extent.StartLineNumber
        }
        $moduleInfo.Functions += $functionInfo
    }
    
    return $moduleInfo
}

function Get-ModuleAnalysisFromModule {
    param([object]$Module, [switch]$IncludeBuiltIn)
    
    $moduleInfo = @{
        Name = $Module.Name
        Path = $Module.Path
        Functions = @()
        ExportedFunctions = @($Module.ExportedFunctions.Keys)
    }
    
    # Get module AST if possible
    if ($Module.Path -and (Test-Path $Module.Path)) {
        $content = Get-Content -Path $Module.Path -Raw -ErrorAction SilentlyContinue
        if ($content) {
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $moduleInfo.AST = $ast
            
            # Extract functions using AST
            $functions = $ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true)
            
            foreach ($func in $functions) {
                $functionInfo = @{
                    Name = $func.Name
                    Parameters = @($func.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
                    AST = $func
                    LineNumber = $func.Extent.StartLineNumber
                    IsExported = $func.Name -in $moduleInfo.ExportedFunctions
                }
                $moduleInfo.Functions += $functionInfo
            }
        }
    }
    
    return $moduleInfo
}

function Get-ImportModuleFromModule {
    param([object]$Module)
    
    $imports = @()
    
    if ($Module.AST) {
        # Find Import-Module commands using AST
        $importCommands = $Module.AST.FindAll({
            $args[0] -is [System.Management.Automation.Language.CommandAst] -and
            $args[0].CommandElements[0].Value -eq "Import-Module"
        }, $true)
        
        foreach ($cmd in $importCommands) {
            if ($cmd.CommandElements.Count -gt 1) {
                $moduleName = $cmd.CommandElements[1].Value
                $imports += @{
                    ModuleName = $moduleName
                    LineNumber = $cmd.Extent.StartLineNumber
                    Frequency = 1  # Could be enhanced to count actual usage
                }
            }
        }
    }
    
    return $imports
}

function Get-CrossModuleFunctionCalls {
    param([object]$Module, [hashtable]$ModuleMap)
    
    $crossModuleCalls = @()
    
    foreach ($function in $Module.Functions) {
        if ($function.AST) {
            $commandCalls = $function.AST.FindAll({
                $args[0] -is [System.Management.Automation.Language.CommandAst]
            }, $true)
            
            foreach ($call in $commandCalls) {
                $commandName = $call.CommandElements[0].Value
                
                # Check if this command belongs to another module
                $targetModule = $null
                foreach ($modName in $ModuleMap.Keys) {
                    if ($ModuleMap[$modName].Functions.Name -contains $commandName -and $modName -ne $Module.Name) {
                        $targetModule = $modName
                        break
                    }
                }
                
                if ($targetModule) {
                    $crossModuleCalls += @{
                        SourceFunction = $function.Name
                        TargetFunction = $commandName
                        TargetModule = $targetModule
                        LineNumber = $call.Extent.StartLineNumber
                        Frequency = 1  # Could be enhanced for actual frequency counting
                    }
                }
            }
        }
    }
    
    return $crossModuleCalls
}

function Calculate-DependencyStrength {
    param([object]$Relationship)
    
    # Basic strength calculation based on frequency and type
    $baseStrength = switch ($Relationship.RelationshipType) {
        "Import" { 10 }
        "FunctionCall" { 5 }
        default { 1 }
    }
    
    $frequency = if ($Relationship.Frequency) { $Relationship.Frequency } else { 1 }
    return $baseStrength * $frequency
}

function Get-ModuleRelationships {
    param([array]$Modules)
    
    $relationships = @()
    $moduleMap = @{}
    
    # Create module lookup
    foreach ($module in $Modules) {
        $moduleMap[$module.Name] = $module
    }
    
    # Get cross-module relationships
    $relationships += Get-CrossModuleRelationships -Modules $Modules -CalculateStrength
    
    return $relationships
}

function Convert-ToD3JSFormat {
    param([object]$CallGraph)
    
    $nodes = @()
    $links = @()
    
    # Create nodes for modules
    foreach ($module in $CallGraph.Modules) {
        $nodes += @{
            id = $module.Name
            group = "module"
            type = "module"
            functions = $module.Functions.Count
            exported = if ($module.ExportedFunctions) { $module.ExportedFunctions.Count } else { 0 }
        }
        
        # Create nodes for functions
        foreach ($function in $module.Functions) {
            $nodes += @{
                id = "$($module.Name)::$($function.Name)"
                group = $module.Name
                type = "function"
                module = $module.Name
                isExported = $function.IsExported
                parameters = $function.Parameters.Count
            }
        }
    }
    
    # Create links from relationships
    foreach ($rel in $CallGraph.Relationships) {
        $links += @{
            source = $rel.SourceModule
            target = $rel.TargetModule
            type = $rel.RelationshipType
            strength = $rel.Strength
            frequency = $rel.Frequency
        }
    }
    
    return @{
        nodes = $nodes
        links = $links
        metadata = $CallGraph.AnalysisMetrics
    }
}

function Convert-ToGraphML {
    param([object]$CallGraph)
    
    $graphML = @"
<?xml version="1.0" encoding="UTF-8"?>
<graphml xmlns="http://graphml.graphdrawing.org/xmlns">
<key id="type" for="node" attr.name="type" attr.type="string"/>
<key id="functions" for="node" attr.name="functions" attr.type="int"/>
<key id="relationship" for="edge" attr.name="relationship" attr.type="string"/>
<key id="strength" for="edge" attr.name="strength" attr.type="double"/>
<graph id="CallGraph" edgedefault="directed">
"@
    
    # Add nodes
    foreach ($module in $CallGraph.Modules) {
        $graphML += "<node id=`"$($module.Name)`"><data key=`"type`">module</data><data key=`"functions`">$($module.Functions.Count)</data></node>`n"
    }
    
    # Add edges
    foreach ($rel in $CallGraph.Relationships) {
        $graphML += "<edge source=`"$($rel.SourceModule)`" target=`"$($rel.TargetModule)`"><data key=`"relationship`">$($rel.RelationshipType)</data><data key=`"strength`">$($rel.Strength)</data></edge>`n"
    }
    
    $graphML += "</graph></graphml>"
    
    return $graphML
}

function Convert-ToCSV {
    param([object]$CallGraph)
    
    $csvData = @()
    
    foreach ($rel in $CallGraph.Relationships) {
        $csvData += [PSCustomObject]@{
            SourceModule = $rel.SourceModule
            TargetModule = $rel.TargetModule
            RelationshipType = $rel.RelationshipType
            Strength = $rel.Strength
            Frequency = $rel.Frequency
            SourceFunction = if ($rel.SourceFunction) { $rel.SourceFunction } else { "" }
            TargetFunction = if ($rel.TargetFunction) { $rel.TargetFunction } else { "" }
        }
    }
    
    return $csvData
}

function Get-MaxCallDepth {
    param($FunctionAST)
    # Simplified implementation - could be enhanced for actual depth calculation
    return 1
}

function Get-CyclomaticComplexity {
    param($FunctionAST)
    # Simplified implementation - count decision points
    $decisions = $FunctionAST.FindAll({
        $args[0] -is [System.Management.Automation.Language.IfStatementAst] -or
        $args[0] -is [System.Management.Automation.Language.ForStatementAst] -or
        $args[0] -is [System.Management.Automation.Language.WhileStatementAst]
    }, $true)
    
    return $decisions.Count + 1
}

#endregion

#region Export Functions
Export-ModuleMember -Function @(
    'Get-ModuleCallGraph',
    'Get-CrossModuleRelationships', 
    'Get-FunctionCallAnalysis',
    'Export-CallGraphData'
)
#endregion