#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Installs and configures DependencySearch module for enhanced dependency analysis
    
.DESCRIPTION
    Implements WEEK 2 Day 6 Hour 1-2 requirements:
    - Installs DependencySearch module
    - Integrates with existing AST analysis
    - Enables Out-PSModuleCallGraph functionality
#>

Write-Host "DEPENDENCY SEARCH MODULE INSTALLATION" -ForegroundColor Cyan
Write-Host "Implementing WEEK 2 Day 6 dependency analysis features" -ForegroundColor Yellow

# Check if module is already installed
$module = Get-Module -ListAvailable -Name DependencySearch
if (-not $module) {
    Write-Host "Installing DependencySearch module..." -ForegroundColor Yellow
    
    try {
        Install-Module -Name DependencySearch -Force -AllowClobber -Scope CurrentUser
        Write-Host "✅ DependencySearch module installed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ Could not install from PSGallery, implementing local alternative" -ForegroundColor Yellow
        
        # Create local implementation based on AST analysis
        $localModule = @'
#Requires -Version 5.1

function Find-ModuleDependencies {
    param(
        [string]$Path = ".",
        [switch]$Recurse
    )
    
    $dependencies = @{}
    $files = Get-ChildItem -Path $Path -Filter "*.ps*1" -Recurse:$Recurse
    
    foreach ($file in $files) {
        $ast = [System.Management.Automation.Language.Parser]::ParseFile(
            $file.FullName,
            [ref]$null,
            [ref]$null
        )
        
        # Find Import-Module statements
        $imports = $ast.FindAll({
            $args[0] -is [System.Management.Automation.Language.CommandAst] -and
            $args[0].GetCommandName() -eq 'Import-Module'
        }, $true)
        
        $dependencies[$file.Name] = @{
            Imports = $imports | ForEach-Object { 
                $_.CommandElements[1].Value 
            }
            Path = $file.FullName
        }
    }
    
    return $dependencies
}

function Out-PSModuleCallGraph {
    param(
        [string]$ModulePath,
        [string]$OutputPath = ".\call-graph.json"
    )
    
    $callGraph = @{
        nodes = @()
        edges = @()
    }
    
    # Parse module
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $ModulePath,
        [ref]$null,
        [ref]$null
    )
    
    # Get all functions
    $functions = $ast.FindAll({
        $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true)
    
    foreach ($function in $functions) {
        # Add function node
        $callGraph.nodes += @{
            id = $function.Name
            type = "function"
            module = (Get-Item $ModulePath).BaseName
        }
        
        # Find function calls
        $calls = $function.FindAll({
            $args[0] -is [System.Management.Automation.Language.CommandAst]
        }, $true)
        
        foreach ($call in $calls) {
            $callName = $call.GetCommandName()
            if ($callName -and $callName -ne $function.Name) {
                $callGraph.edges += @{
                    source = $function.Name
                    target = $callName
                    type = "calls"
                }
            }
        }
    }
    
    $callGraph | ConvertTo-Json -Depth 10 | Set-Content $OutputPath
    Write-Host "Call graph exported to: $OutputPath" -ForegroundColor Green
    return $callGraph
}

Export-ModuleMember -Function Find-ModuleDependencies, Out-PSModuleCallGraph
'@
        
        # Save local module
        $modulePath = ".\Modules\DependencySearch-Local\DependencySearch-Local.psm1"
        $moduleDir = Split-Path $modulePath -Parent
        
        if (-not (Test-Path $moduleDir)) {
            New-Item -ItemType Directory -Path $moduleDir -Force | Out-Null
        }
        
        $localModule | Set-Content $modulePath -Encoding UTF8
        Import-Module $modulePath -Force
        
        Write-Host "✅ Local DependencySearch implementation created" -ForegroundColor Green
    }
}
else {
    Write-Host "✅ DependencySearch module already installed" -ForegroundColor Green
    Import-Module DependencySearch -Force
}

# Test the module
Write-Host ""
Write-Host "Testing DependencySearch functionality..." -ForegroundColor Cyan

try {
    # Find dependencies in Modules directory
    $deps = Find-ModuleDependencies -Path ".\Modules" -Recurse | Select-Object -First 5
    
    Write-Host "Sample dependencies found:" -ForegroundColor Green
    foreach ($dep in $deps.GetEnumerator() | Select-Object -First 3) {
        Write-Host "  $($dep.Key): $($dep.Value.Imports -join ', ')" -ForegroundColor White
    }
    
    # Generate call graph for a sample module
    $sampleModule = Get-ChildItem -Path ".\Modules" -Filter "*.psm1" -Recurse | Select-Object -First 1
    if ($sampleModule) {
        Write-Host ""
        Write-Host "Generating call graph for: $($sampleModule.Name)" -ForegroundColor Cyan
        $graph = Out-PSModuleCallGraph -ModulePath $sampleModule.FullName -OutputPath ".\sample-call-graph.json"
        Write-Host "  Nodes: $($graph.nodes.Count)" -ForegroundColor White
        Write-Host "  Edges: $($graph.edges.Count)" -ForegroundColor White
    }
    
    Write-Host ""
    Write-Host "✅ DependencySearch module ready for use!" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ Error testing module: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Integration complete! Use these functions:" -ForegroundColor Cyan
Write-Host "  Find-ModuleDependencies -Path .\Modules -Recurse" -ForegroundColor White
Write-Host "  Out-PSModuleCallGraph -ModulePath <path.psm1>" -ForegroundColor White