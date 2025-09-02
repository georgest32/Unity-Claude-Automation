#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Generates AST-enhanced visualization data with function call mapping
    
.DESCRIPTION
    Implements WEEK 2 Day 6 requirements from MAXIMUM_UTILIZATION_IMPLEMENTATION_PLAN:
    - PowerShell AST analysis for function call mapping
    - Import/Export relationship analysis
    - Dependency strength calculation
    
.PARAMETER MaxNodes
    Maximum nodes to include in visualization
    
.PARAMETER OutputPath
    Output path for enhanced data
#>

param(
    [int]$MaxNodes = 500,
    [string]$OutputPath = ".\Visualization\public\static\data"
)

Write-Host "AST-ENHANCED VISUALIZATION DATA GENERATION" -ForegroundColor Cyan
Write-Host "Implementing WEEK 2 Day 6 features" -ForegroundColor Yellow

# Load AST analysis module if available
$astModule = Get-Module -ListAvailable | Where-Object { $_.Name -like "*AST*" }
if ($astModule) {
    Import-Module $astModule.Name -ErrorAction SilentlyContinue
    Write-Host "Loaded AST module: $($astModule.Name)" -ForegroundColor Green
}

# Initialize enhanced graph structure
$astGraph = @{
    metadata = @{
        title = "AST-Enhanced Function Call Graph"
        generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        features = @("AST Analysis", "Function Call Mapping", "Import/Export Analysis")
    }
    nodes = @()
    links = @()
    callGraphs = @{}
}

Write-Host "[1/4] Analyzing PowerShell modules with AST..." -ForegroundColor Cyan

# Get all PowerShell modules
$modules = Get-ChildItem -Path ".\Modules" -Filter "*.psm1" -Recurse

foreach ($module in $modules | Select-Object -First 20) {
    Write-Host "  Analyzing: $($module.Name)" -ForegroundColor White
    
    try {
        # Parse module AST
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $module.FullName,
            [ref]$null,
            [ref]$null
        )
        
        # Extract functions
        $functions = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
        }, $true)
        
        # Extract Import-Module statements
        $imports = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.CommandAst] -and
            $args[0].GetCommandName() -eq 'Import-Module'
        }, $true)
        
        # Create node for module
        $moduleNode = @{
            id = $module.BaseName
            label = $module.BaseName -replace "Unity-Claude-", ""
            type = "module"
            functionCount = $functions.Count
            importCount = $imports.Count
            size = [Math]::Min(30, 10 + $functions.Count)
            color = "#4ECDC4"
        }
        
        $astGraph.nodes += $moduleNode
        
        # Analyze function calls within module
        foreach ($function in $functions) {
            $functionCalls = $function.FindAll({
                $args[0] -is [System.Management.Automation.Language.CommandAst]
            }, $true)
            
            # Store in call graph
            $astGraph.callGraphs[$function.Name] = @{
                module = $module.BaseName
                callCount = $functionCalls.Count
                calls = $functionCalls | ForEach-Object { $_.GetCommandName() }
            }
        }
        
        # Create import relationships
        foreach ($import in $imports) {
            $importedModule = $import.CommandElements[1].Value
            if ($importedModule) {
                $link = @{
                    source = $module.BaseName
                    target = $importedModule -replace ".*\\", "" -replace "\.psm1", ""
                    type = "imports"
                    color = "#3B82F6"
                    width = 2
                }
                $astGraph.links += $link
            }
        }
    }
    catch {
        Write-Host "    Error analyzing $($module.Name): $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host "[2/4] Calculating dependency strengths..." -ForegroundColor Cyan

# Calculate dependency strengths based on call frequency
foreach ($link in $astGraph.links) {
    $callCount = 0
    foreach ($callGraph in $astGraph.callGraphs.Values) {
        if ($callGraph.module -eq $link.source) {
            $callCount += ($callGraph.calls | Where-Object { $_ -like "*$($link.target)*" }).Count
        }
    }
    $link.strength = [Math]::Min(1.0, $callCount / 10)
    $link.width = [Math]::Max(1, [Math]::Min(5, $callCount))
}

Write-Host "[3/4] Adding function-level nodes for critical modules..." -ForegroundColor Cyan

# Add function nodes for top modules
$topModules = $astGraph.nodes | Sort-Object -Property functionCount -Descending | Select-Object -First 5

foreach ($topModule in $topModules) {
    $moduleFunctions = $astGraph.callGraphs.GetEnumerator() | 
        Where-Object { $_.Value.module -eq $topModule.id } |
        Select-Object -First 5
    
    foreach ($func in $moduleFunctions) {
        $funcNode = @{
            id = "$($topModule.id)::$($func.Key)"
            label = $func.Key
            type = "function"
            parent = $topModule.id
            size = 8
            color = "#F59E0B"
        }
        
        $astGraph.nodes += $funcNode
        
        # Link function to module
        $astGraph.links += @{
            source = $topModule.id
            target = $funcNode.id
            type = "contains"
            color = "#84CC16"
            width = 1
        }
    }
}

Write-Host "[4/4] Exporting AST-enhanced visualization data..." -ForegroundColor Cyan

# Add statistics
$astGraph.metadata.nodeCount = $astGraph.nodes.Count
$astGraph.metadata.linkCount = $astGraph.links.Count
$astGraph.metadata.functionCount = $astGraph.callGraphs.Count

# Export data
$outputFile = Join-Path $OutputPath "ast-enhanced-graph.json"
$astGraph | ConvertTo-Json -Depth 10 | Set-Content $outputFile -Encoding UTF8

Write-Host ""
Write-Host "AST-ENHANCED VISUALIZATION COMPLETE!" -ForegroundColor Green
Write-Host "Nodes: $($astGraph.nodes.Count)" -ForegroundColor White
Write-Host "Links: $($astGraph.links.Count)" -ForegroundColor White
Write-Host "Functions analyzed: $($astGraph.callGraphs.Count)" -ForegroundColor White
Write-Host "Output: $outputFile" -ForegroundColor Cyan

return $astGraph