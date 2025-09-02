#requires -Version 5.1

<#
.SYNOPSIS
Enhanced Relationship Data Structure for D3.js Network Visualization
Comprehensive data structures and export functionality for D3.js network graph visualization

.DESCRIPTION
This script provides enhanced relationship data structures optimized for D3.js visualization:
- Comprehensive node structure with module, function, and relationship metadata
- Link structure with relationship types, weights, and temporal information
- D3.js-compatible data export functionality
- Relationship categorization (direct, indirect, circular, critical path)
- Performance optimization for large-scale networks (500+ nodes)

.NOTES
Script: D3-Data-Structures.ps1
Version: 1.0.0
Date: 2025-08-30
Author: Unity-Claude-Automation System
Dependencies: Unity-Claude-AST-Enhanced module
#>

<#
.SYNOPSIS
Creates comprehensive D3.js-compatible network data from PowerShell module analysis

.DESCRIPTION
Transforms PowerShell module analysis results into rich D3.js network visualization data structures
including nodes with detailed metadata, links with relationship weights, and categorized relationships
for enhanced visualization capabilities.

.PARAMETER CallGraphData
Call graph analysis results from Get-ModuleCallGraph

.PARAMETER ImportAnalysis
Import analysis results from Get-ModuleImportAnalysis

.PARAMETER ExportAnalysis
Export analysis results from Get-ModuleExportAnalysis

.PARAMETER UsageFrequency
Usage frequency analysis results from Get-ExportUsageFrequency

.PARAMETER IncludeTemporalData
Include temporal evolution data for time-based visualization

.PARAMETER OptimizeForLargeNetworks
Apply optimizations for networks with 500+ nodes

.EXAMPLE
Export-D3NetworkData -CallGraphData $callGraph -ImportAnalysis $imports -ExportAnalysis $exports -UsageFrequency $usage -IncludeTemporalData

.EXAMPLE
Export-D3NetworkData -CallGraphData $callGraph -ImportAnalysis $imports -ExportAnalysis $exports -OptimizeForLargeNetworks
#>
function Export-D3NetworkData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$CallGraphData,
        [object]$ImportAnalysis,
        [object]$ExportAnalysis,
        [object]$UsageFrequency,
        [switch]$IncludeTemporalData,
        [switch]$OptimizeForLargeNetworks
    )
    
    Write-Verbose "Creating enhanced D3.js network data structure..."
    $startTime = Get-Date
    
    try {
        $networkData = @{
            nodes = @()
            links = @()
            metadata = @{
                generatedOn = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
                version = "1.0.0"
                networkType = "PowerShell-Module-Dependencies"
                optimization = @{
                    largeNetworkOptimizations = $OptimizeForLargeNetworks.IsPresent
                    temporalDataIncluded = $IncludeTemporalData.IsPresent
                }
            }
            categories = @{}
            statistics = @{}
        }
        
        # Create comprehensive node structures
        $nodeIndex = 0
        $nodeMap = @{}
        
        Write-Verbose "Creating module nodes..."
        
        # Create module nodes
        foreach ($module in $CallGraphData.Modules) {
            $moduleNode = Create-ModuleNode -Module $module -ExportAnalysis $ExportAnalysis -UsageFrequency $UsageFrequency -NodeIndex $nodeIndex
            $networkData.nodes += $moduleNode
            $nodeMap[$module.Name] = $nodeIndex
            $nodeIndex++
            
            # Create function nodes if not optimizing for large networks
            if (-not $OptimizeForLargeNetworks -or $module.Functions.Count -le 20) {
                foreach ($function in $module.Functions) {
                    $functionNode = Create-FunctionNode -Function $function -Module $module -ExportAnalysis $ExportAnalysis -UsageFrequency $UsageFrequency -NodeIndex $nodeIndex
                    $networkData.nodes += $functionNode
                    $nodeMap["$($module.Name)::$($function.Name)"] = $nodeIndex
                    $nodeIndex++
                }
            }
        }
        
        Write-Verbose "Creating relationship links..."
        
        # Create links from call graph relationships
        if ($CallGraphData.Relationships) {
            foreach ($relationship in $CallGraphData.Relationships) {
                $link = Create-RelationshipLink -Relationship $relationship -NodeMap $nodeMap -ImportAnalysis $ImportAnalysis -UsageFrequency $UsageFrequency
                if ($link) {
                    $networkData.links += $link
                }
            }
        }
        
        # Add import/export relationship links
        if ($ImportAnalysis) {
            foreach ($importRel in $ImportAnalysis.ImportRelationships) {
                $link = Create-ImportLink -ImportRelationship $importRel -NodeMap $nodeMap -UsageFrequency $UsageFrequency
                if ($link) {
                    $networkData.links += $link
                }
            }
        }
        
        # Add function usage links
        if ($ExportAnalysis -and $ExportAnalysis.FunctionUsage) {
            foreach ($usage in $ExportAnalysis.FunctionUsage) {
                $link = Create-FunctionUsageLink -Usage $usage -NodeMap $nodeMap -UsageFrequency $UsageFrequency
                if ($link) {
                    $networkData.links += $link
                }
            }
        }
        
        Write-Verbose "Categorizing relationships..."
        
        # Categorize relationships
        $networkData.categories = Categorize-Relationships -Links $networkData.links -ImportAnalysis $ImportAnalysis
        
        # Add temporal data if requested
        if ($IncludeTemporalData) {
            Write-Verbose "Adding temporal evolution data..."
            $networkData.temporal = Create-TemporalData -Modules $CallGraphData.Modules -ImportAnalysis $ImportAnalysis
        }
        
        # Calculate network statistics
        $networkData.statistics = Calculate-NetworkStatistics -Nodes $networkData.nodes -Links $networkData.links -Categories $networkData.categories
        
        # Apply large network optimizations
        if ($OptimizeForLargeNetworks) {
            Write-Verbose "Applying large network optimizations..."
            $networkData = Apply-LargeNetworkOptimizations -NetworkData $networkData
        }
        
        $networkData.metadata.processingTime = (Get-Date) - $startTime
        
        Write-Verbose "D3.js network data structure created with $($networkData.nodes.Count) nodes and $($networkData.links.Count) links"
        return $networkData
    }
    catch {
        Write-Error "Error creating D3.js network data: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
Creates relationship matrices for comprehensive dependency analysis

.DESCRIPTION
Generates various matrix representations of module relationships including:
- Adjacency matrices for direct relationships
- Dependency strength matrices with weighted connections
- Critical path matrices highlighting important dependency chains
- Circular dependency matrices for identifying problematic patterns

.PARAMETER CallGraphData
Call graph analysis results

.PARAMETER ImportAnalysis
Import analysis results

.PARAMETER ExportAnalysis
Export analysis results

.PARAMETER MatrixFormat
Output format: JSON, CSV, or PowerShell objects

.EXAMPLE
Export-RelationshipMatrix -CallGraphData $graph -ImportAnalysis $imports -MatrixFormat "JSON"
#>
function Export-RelationshipMatrix {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$CallGraphData,
        [object]$ImportAnalysis,
        [object]$ExportAnalysis,
        [ValidateSet("JSON", "CSV", "PSObject")]
        [string]$MatrixFormat = "JSON"
    )
    
    Write-Verbose "Creating relationship matrices..."
    
    try {
        # Get all unique modules
        $allModules = @()
        if ($CallGraphData.Modules) {
            $allModules += $CallGraphData.Modules.Name
        }
        if ($ImportAnalysis -and $ImportAnalysis.ImportRelationships) {
            $allModules += $ImportAnalysis.ImportRelationships.SourceModule
            $allModules += $ImportAnalysis.ImportRelationships.ImportedModule
        }
        $allModules = $allModules | Sort-Object -Unique
        
        $matrices = @{
            adjacencyMatrix = Create-AdjacencyMatrix -Modules $allModules -ImportAnalysis $ImportAnalysis
            dependencyStrengthMatrix = Create-DependencyStrengthMatrix -Modules $allModules -CallGraphData $CallGraphData -ImportAnalysis $ImportAnalysis
            criticalPathMatrix = Create-CriticalPathMatrix -Modules $allModules -ImportAnalysis $ImportAnalysis
            circularDependencyMatrix = Create-CircularDependencyMatrix -Modules $allModules -ImportAnalysis $ImportAnalysis
            metadata = @{
                moduleCount = $allModules.Count
                matrixSize = "$($allModules.Count)x$($allModules.Count)"
                generatedOn = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
                moduleOrder = $allModules
            }
        }
        
        # Format output according to specified format
        switch ($MatrixFormat) {
            "JSON" {
                return $matrices | ConvertTo-Json -Depth 10
            }
            "CSV" {
                return Convert-MatricesToCSV -Matrices $matrices
            }
            "PSObject" {
                return $matrices
            }
        }
    }
    catch {
        Write-Error "Error creating relationship matrices: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
Analyzes and categorizes different types of relationships in the module ecosystem

.DESCRIPTION
Provides comprehensive relationship categorization including:
- Direct dependencies (explicit Import-Module statements)
- Indirect dependencies (transitive dependencies through other modules)
- Circular dependencies (modules that depend on each other)
- Critical path dependencies (essential chains for functionality)
- Weak dependencies (infrequently used connections)

.PARAMETER NetworkData
D3.js network data structure

.PARAMETER ImportAnalysis
Import analysis results for dependency chain analysis

.PARAMETER StrengthThreshold
Minimum strength threshold for strong vs weak relationship classification

.EXAMPLE
Get-RelationshipCategorization -NetworkData $d3Data -ImportAnalysis $imports -StrengthThreshold 5
#>
function Get-RelationshipCategorization {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$NetworkData,
        [object]$ImportAnalysis,
        [double]$StrengthThreshold = 3.0
    )
    
    Write-Verbose "Categorizing module relationships..."
    
    try {
        $categorization = @{
            directDependencies = @()
            indirectDependencies = @()
            circularDependencies = @()
            criticalPathDependencies = @()
            weakDependencies = @()
            strongDependencies = @()
            statistics = @{}
        }
        
        # Analyze each link for categorization
        foreach ($link in $NetworkData.links) {
            $category = Determine-LinkCategory -Link $link -ImportAnalysis $ImportAnalysis -StrengthThreshold $StrengthThreshold
            
            switch ($category.primary) {
                "direct" { $categorization.directDependencies += $link }
                "indirect" { $categorization.indirectDependencies += $link }
                "circular" { $categorization.circularDependencies += $link }
                "critical" { $categorization.criticalPathDependencies += $link }
            }
            
            if ($link.strength -ge $StrengthThreshold) {
                $categorization.strongDependencies += $link
            } else {
                $categorization.weakDependencies += $link
            }
            
            # Add category information to the link
            $link.category = $category
        }
        
        # Calculate statistics
        $categorization.statistics = @{
            totalRelationships = $NetworkData.links.Count
            directCount = $categorization.directDependencies.Count
            indirectCount = $categorization.indirectDependencies.Count
            circularCount = $categorization.circularDependencies.Count
            criticalCount = $categorization.criticalPathDependencies.Count
            strongCount = $categorization.strongDependencies.Count
            weakCount = $categorization.weakDependencies.Count
            averageStrength = ($NetworkData.links | ForEach-Object { $_.strength } | Measure-Object -Average).Average
        }
        
        Write-Verbose "Relationship categorization completed: $($categorization.statistics.totalRelationships) relationships analyzed"
        return $categorization
    }
    catch {
        Write-Error "Error categorizing relationships: $($_.Exception.Message)"
        throw
    }
}

#region Helper Functions for Node Creation

function Create-ModuleNode {
    param($Module, $ExportAnalysis, $UsageFrequency, $NodeIndex)
    
    # Get export information for this module
    $moduleExports = if ($ExportAnalysis) {
        $ExportAnalysis.AnalyzedModules | Where-Object { $_.ModuleName -eq $Module.Name }
    } else { $null }
    
    # Get usage frequency for this module
    $moduleUsage = if ($UsageFrequency -and $UsageFrequency.ModuleUsage) {
        $UsageFrequency.ModuleUsage | Where-Object { $_.ModuleName -eq $Module.Name }
    } else { $null }
    
    $node = @{
        id = $Module.Name
        index = $NodeIndex
        type = "module"
        group = "module"
        size = [math]::Log10($Module.Functions.Count + 1) * 10 + 10  # Logarithmic scaling for visualization
        
        # Module metadata
        metadata = @{
            name = $Module.Name
            path = $Module.Path
            functionCount = $Module.Functions.Count
            exportedFunctions = if ($Module.ExportedFunctions) { $Module.ExportedFunctions.Count } else { 0 }
            complexity = Calculate-ModuleComplexity -Module $Module
        }
        
        # Export information
        exports = @{
            explicitExports = if ($moduleExports) { $moduleExports.ExplicitExports } else { 0 }
            implicitExports = if ($moduleExports) { $moduleExports.ImplicitExports } else { 0 }
            totalFunctions = if ($moduleExports) { $moduleExports.TotalFunctions } else { $Module.Functions.Count }
        }
        
        # Usage metrics
        usage = @{
            importFrequency = if ($moduleUsage) { $moduleUsage.ImportFrequency } else { 0 }
            usageScore = if ($moduleUsage) { $moduleUsage.UsageScore } else { 0 }
        }
        
        # Visual properties for D3.js
        visual = @{
            color = Get-ModuleColor -Module $Module -UsageFrequency $moduleUsage
            borderWidth = if ($moduleUsage -and $moduleUsage.UsageScore -gt 50) { 3 } else { 1 }
            shape = "circle"
        }
    }
    
    return $node
}

function Create-FunctionNode {
    param($Function, $Module, $ExportAnalysis, $UsageFrequency, $NodeIndex)
    
    # Get function usage information
    $functionUsage = if ($UsageFrequency -and $UsageFrequency.FunctionUsage) {
        $UsageFrequency.FunctionUsage | Where-Object { 
            $_.ModuleName -eq $Module.Name -and $_.FunctionName -eq $Function.Name 
        }
    } else { $null }
    
    $node = @{
        id = "$($Module.Name)::$($Function.Name)"
        index = $NodeIndex
        type = "function"
        group = $Module.Name
        parentModule = $Module.Name
        size = [math]::Max(5, $Function.Parameters.Count * 2 + 5)  # Size based on parameter count
        
        # Function metadata
        metadata = @{
            name = $Function.Name
            moduleName = $Module.Name
            parameterCount = $Function.Parameters.Count
            parameters = $Function.Parameters
            lineNumber = $Function.LineNumber
            isExported = $Function.IsExported
            complexity = if ($Function.AST) { Get-CyclomaticComplexity -FunctionAST $Function.AST } else { 1 }
        }
        
        # Usage metrics
        usage = @{
            callFrequency = if ($functionUsage) { $functionUsage.CallFrequency } else { 0 }
            usageScore = if ($functionUsage) { $functionUsage.UsageScore } else { 0 }
        }
        
        # Visual properties for D3.js
        visual = @{
            color = Get-FunctionColor -Function $Function -UsageFrequency $functionUsage
            shape = if ($Function.IsExported) { "square" } else { "circle" }
            opacity = if ($Function.IsExported) { 1.0 } else { 0.7 }
        }
    }
    
    return $node
}

function Create-RelationshipLink {
    param($Relationship, $NodeMap, $ImportAnalysis, $UsageFrequency)
    
    $sourceKey = $Relationship.SourceModule
    $targetKey = $Relationship.TargetModule
    
    if (-not $NodeMap.ContainsKey($sourceKey) -or -not $NodeMap.ContainsKey($targetKey)) {
        Write-Verbose "Skipping relationship link: missing nodes for $sourceKey -> $targetKey"
        return $null
    }
    
    $link = @{
        source = $NodeMap[$sourceKey]
        target = $NodeMap[$targetKey]
        type = $Relationship.RelationshipType
        strength = [double]$Relationship.Strength
        frequency = [int]$Relationship.Frequency
        
        # Relationship metadata
        metadata = @{
            sourceModule = $Relationship.SourceModule
            targetModule = $Relationship.TargetModule
            relationshipType = $Relationship.RelationshipType
            details = $Relationship.Details
        }
        
        # Visual properties for D3.js
        visual = @{
            strokeWidth = [math]::Min([math]::Max($Relationship.Strength / 2, 1), 5)
            color = Get-RelationshipColor -RelationshipType $Relationship.RelationshipType
            opacity = [math]::Min($Relationship.Frequency / 10.0 + 0.3, 1.0)
            dashed = $Relationship.RelationshipType -eq "FunctionCall"
        }
    }
    
    return $link
}

function Create-ImportLink {
    param($ImportRelationship, $NodeMap, $UsageFrequency)
    
    $sourceKey = $ImportRelationship.SourceModule
    $targetKey = $ImportRelationship.ImportedModule
    
    if (-not $NodeMap.ContainsKey($sourceKey) -or -not $NodeMap.ContainsKey($targetKey)) {
        return $null
    }
    
    $link = @{
        source = $NodeMap[$sourceKey]
        target = $NodeMap[$targetKey]
        type = "Import"
        strength = [double]10  # High strength for import relationships
        frequency = [int]$ImportRelationship.Frequency
        
        metadata = @{
            sourceModule = $ImportRelationship.SourceModule
            targetModule = $ImportRelationship.ImportedModule
            lineNumber = $ImportRelationship.LineNumber
            isConditional = $ImportRelationship.IsConditional
            parameters = $ImportRelationship.Parameters
        }
        
        visual = @{
            strokeWidth = 3
            color = "#FF6B35"  # Orange for import relationships
            opacity = 0.8
            dashed = $ImportRelationship.IsConditional
        }
    }
    
    return $link
}

function Create-FunctionUsageLink {
    param($Usage, $NodeMap, $UsageFrequency)
    
    $sourceKey = $Usage.SourceModule
    $targetKey = "$($Usage.TargetModule)::$($Usage.FunctionName)"
    
    if (-not $NodeMap.ContainsKey($sourceKey) -or -not $NodeMap.ContainsKey($targetKey)) {
        return $null
    }
    
    $link = @{
        source = $NodeMap[$sourceKey]
        target = $NodeMap[$targetKey]
        type = "FunctionCall"
        strength = [double]$Usage.CallCount
        frequency = [int]$Usage.CallCount
        
        metadata = @{
            sourceModule = $Usage.SourceModule
            targetModule = $Usage.TargetModule
            functionName = $Usage.FunctionName
            lineNumber = $Usage.LineNumber
        }
        
        visual = @{
            strokeWidth = [math]::Min($Usage.CallCount, 4)
            color = "#4ECDC4"  # Teal for function calls
            opacity = 0.6
            dashed = $true
        }
    }
    
    return $link
}

#endregion

#region Helper Functions for Matrix Creation

function Create-AdjacencyMatrix {
    param($Modules, $ImportAnalysis)
    
    $size = $Modules.Count
    $matrix = New-Object 'int[,]' $size, $size
    
    if ($ImportAnalysis -and $ImportAnalysis.ImportRelationships) {
        foreach ($import in $ImportAnalysis.ImportRelationships) {
            $sourceIndex = $Modules.IndexOf($import.SourceModule)
            $targetIndex = $Modules.IndexOf($import.ImportedModule)
            
            if ($sourceIndex -ge 0 -and $targetIndex -ge 0) {
                $matrix[$sourceIndex, $targetIndex] = 1
            }
        }
    }
    
    return Convert-MatrixToObject -Matrix $matrix -Modules $Modules
}

function Create-DependencyStrengthMatrix {
    param($Modules, $CallGraphData, $ImportAnalysis)
    
    $size = $Modules.Count
    $matrix = New-Object 'double[,]' $size, $size
    
    # Add import relationship strengths
    if ($ImportAnalysis -and $ImportAnalysis.ImportRelationships) {
        foreach ($import in $ImportAnalysis.ImportRelationships) {
            $sourceIndex = $Modules.IndexOf($import.SourceModule)
            $targetIndex = $Modules.IndexOf($import.ImportedModule)
            
            if ($sourceIndex -ge 0 -and $targetIndex -ge 0) {
                $matrix[$sourceIndex, $targetIndex] = [double]10  # High strength for imports
            }
        }
    }
    
    # Add call graph relationship strengths
    if ($CallGraphData -and $CallGraphData.Relationships) {
        foreach ($rel in $CallGraphData.Relationships) {
            $sourceIndex = $Modules.IndexOf($rel.SourceModule)
            $targetIndex = $Modules.IndexOf($rel.TargetModule)
            
            if ($sourceIndex -ge 0 -and $targetIndex -ge 0) {
                $matrix[$sourceIndex, $targetIndex] += [double]$rel.Strength
            }
        }
    }
    
    return Convert-MatrixToObject -Matrix $matrix -Modules $Modules
}

function Create-CriticalPathMatrix {
    param($Modules, $ImportAnalysis)
    
    $size = $Modules.Count
    $matrix = New-Object 'int[,]' $size, $size
    
    if ($ImportAnalysis -and $ImportAnalysis.DependencyChains) {
        # Find critical paths (longest chains)
        $maxDepth = ($ImportAnalysis.DependencyChains | ForEach-Object { $_.Depth } | Measure-Object -Maximum).Maximum
        $criticalChains = $ImportAnalysis.DependencyChains | Where-Object { $_.Depth -eq $maxDepth }
        
        foreach ($chain in $criticalChains) {
            $sourceIndex = $Modules.IndexOf($chain.Source)
            $targetIndex = $Modules.IndexOf($chain.Target)
            
            if ($sourceIndex -ge 0 -and $targetIndex -ge 0) {
                $matrix[$sourceIndex, $targetIndex] = 1
            }
        }
    }
    
    return Convert-MatrixToObject -Matrix $matrix -Modules $Modules
}

function Create-CircularDependencyMatrix {
    param($Modules, $ImportAnalysis)
    
    $size = $Modules.Count
    $matrix = New-Object 'int[,]' $size, $size
    
    if ($ImportAnalysis -and $ImportAnalysis.DependencyChains) {
        # Detect circular dependencies
        $visited = @{}
        
        foreach ($module in $Modules) {
            $circular = Find-CircularDependenciesInChain -Module $module -ImportAnalysis $ImportAnalysis -Visited $visited
            
            foreach ($circularPair in $circular) {
                $sourceIndex = $Modules.IndexOf($circularPair.Source)
                $targetIndex = $Modules.IndexOf($circularPair.Target)
                
                if ($sourceIndex -ge 0 -and $targetIndex -ge 0) {
                    $matrix[$sourceIndex, $targetIndex] = 1
                }
            }
        }
    }
    
    return Convert-MatrixToObject -Matrix $matrix -Modules $Modules
}

#endregion

#region Helper Functions for Categorization

function Categorize-Relationships {
    param($Links, $ImportAnalysis)
    
    $categories = @{
        direct = @()
        indirect = @()
        circular = @()
        critical = @()
        strong = @()
        weak = @()
    }
    
    foreach ($link in $Links) {
        $category = Determine-LinkCategory -Link $link -ImportAnalysis $ImportAnalysis -StrengthThreshold 3.0
        
        switch ($category.primary) {
            "direct" { $categories.direct += $link }
            "indirect" { $categories.indirect += $link }
            "circular" { $categories.circular += $link }
            "critical" { $categories.critical += $link }
        }
        
        if ($link.strength -ge 3.0) {
            $categories.strong += $link
        } else {
            $categories.weak += $link
        }
    }
    
    return $categories
}

function Determine-LinkCategory {
    param($Link, $ImportAnalysis, $StrengthThreshold)
    
    $category = @{
        primary = "direct"
        secondary = @()
        confidence = 1.0
    }
    
    # Determine primary category based on relationship type
    switch ($Link.type) {
        "Import" { 
            $category.primary = "direct"
            $category.confidence = 1.0
        }
        "FunctionCall" { 
            $category.primary = "indirect"
            $category.confidence = 0.8
        }
        default { 
            $category.primary = "indirect"
            $category.confidence = 0.6
        }
    }
    
    # Check for circular dependencies
    if ($ImportAnalysis -and $ImportAnalysis.DependencyChains) {
        $isCircular = Test-CircularDependency -SourceModule $Link.metadata.sourceModule -TargetModule $Link.metadata.targetModule -ImportAnalysis $ImportAnalysis
        if ($isCircular) {
            $category.secondary += "circular"
        }
    }
    
    # Check for critical path
    if ($Link.strength -ge $StrengthThreshold * 2) {
        $category.secondary += "critical"
    }
    
    return $category
}

#endregion

#region Utility Functions

function Calculate-ModuleComplexity {
    param($Module)
    
    $complexity = 0
    
    # Base complexity from function count
    $complexity += $Module.Functions.Count
    
    # Add complexity from individual functions
    foreach ($function in $Module.Functions) {
        if ($function.AST) {
            $complexity += Get-CyclomaticComplexity -FunctionAST $function.AST
        } else {
            $complexity += 1  # Base complexity if no AST available
        }
    }
    
    return $complexity
}

function Get-ModuleColor {
    param($Module, $UsageFrequency)
    
    # Color coding based on usage frequency and function count
    $usageScore = if ($UsageFrequency) { $UsageFrequency.UsageScore } else { 0 }
    $functionCount = $Module.Functions.Count
    
    if ($usageScore -gt 75) { return "#E74C3C" }      # High usage - Red
    elseif ($usageScore -gt 50) { return "#F39C12" }   # Medium usage - Orange
    elseif ($usageScore -gt 25) { return "#F1C40F" }   # Low-medium usage - Yellow
    elseif ($functionCount -gt 10) { return "#3498DB" } # Large module - Blue
    else { return "#95A5A6" }                          # Small/unused - Gray
}

function Get-FunctionColor {
    param($Function, $UsageFrequency)
    
    $usageScore = if ($UsageFrequency) { $UsageFrequency.UsageScore } else { 0 }
    
    if ($Function.IsExported -and $usageScore -gt 50) { return "#E67E22" }  # Exported and used - Dark Orange
    elseif ($Function.IsExported) { return "#F39C12" }                     # Exported - Orange
    elseif ($usageScore -gt 25) { return "#3498DB" }                       # Internal but used - Blue
    else { return "#BDC3C7" }                                              # Internal unused - Light Gray
}

function Get-RelationshipColor {
    param($RelationshipType)
    
    switch ($RelationshipType) {
        "Import" { return "#E74C3C" }        # Red
        "FunctionCall" { return "#3498DB" }   # Blue
        "Export" { return "#2ECC71" }        # Green
        default { return "#95A5A6" }         # Gray
    }
}

function Convert-MatrixToObject {
    param($Matrix, $Modules)
    
    $matrixObject = @{
        size = @($Matrix.GetLength(0), $Matrix.GetLength(1))
        modules = $Modules
        data = @()
    }
    
    for ($i = 0; $i -lt $Matrix.GetLength(0); $i++) {
        $row = @()
        for ($j = 0; $j -lt $Matrix.GetLength(1); $j++) {
            $row += $Matrix[$i, $j]
        }
        $matrixObject.data += , $row
    }
    
    return $matrixObject
}

function Apply-LargeNetworkOptimizations {
    param($NetworkData)
    
    Write-Verbose "Applying large network optimizations..."
    
    # Remove weak links to reduce visual clutter
    $strongLinks = $NetworkData.links | Where-Object { $_.strength -ge 2.0 }
    $NetworkData.links = $strongLinks
    
    # Group small modules into clusters
    $smallModules = $NetworkData.nodes | Where-Object { $_.type -eq "module" -and $_.metadata.functionCount -lt 5 }
    if ($smallModules.Count -gt 20) {
        # Create cluster nodes for small modules
        $clusterNode = @{
            id = "SmallModulesCluster"
            type = "cluster"
            group = "cluster"
            size = 20
            metadata = @{
                clusterType = "SmallModules"
                moduleCount = $smallModules.Count
                totalFunctions = ($smallModules | ForEach-Object { $_.metadata.functionCount } | Measure-Object -Sum).Sum
            }
            visual = @{
                color = "#BDC3C7"
                shape = "diamond"
            }
        }
        
        # Remove small modules and add cluster
        $NetworkData.nodes = $NetworkData.nodes | Where-Object { $_ -notin $smallModules }
        $NetworkData.nodes += $clusterNode
    }
    
    return $NetworkData
}

function Create-TemporalData {
    param($Modules, $ImportAnalysis)
    
    $temporal = @{
        snapshots = @()
        evolutionMetrics = @{}
        changeEvents = @()
    }
    
    # This would typically analyze git history or file timestamps
    # For now, create a basic temporal structure
    $temporal.snapshots += @{
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        moduleCount = $Modules.Count
        relationshipCount = if ($ImportAnalysis) { $ImportAnalysis.ImportRelationships.Count } else { 0 }
        complexity = Calculate-SystemComplexity -Modules $Modules
    }
    
    return $temporal
}

function Calculate-SystemComplexity {
    param($Modules)
    
    $totalComplexity = 0
    foreach ($module in $Modules) {
        $totalComplexity += Calculate-ModuleComplexity -Module $module
    }
    
    return $totalComplexity
}

function Calculate-NetworkStatistics {
    param($Nodes, $Links, $Categories)
    
    $statistics = @{
        nodeCount = $Nodes.Count
        linkCount = $Links.Count
        moduleCount = ($Nodes | Where-Object { $_.type -eq "module" }).Count
        functionCount = ($Nodes | Where-Object { $_.type -eq "function" }).Count
        
        # Network density (actual links / possible links)
        density = if ($Nodes.Count -gt 1) { 
            $Links.Count / ($Nodes.Count * ($Nodes.Count - 1)) 
        } else { 0 }
        
        # Average clustering coefficient would require more complex calculation
        averageStrength = ($Links | ForEach-Object { $_.strength } | Measure-Object -Average).Average
        maxStrength = ($Links | ForEach-Object { $_.strength } | Measure-Object -Maximum).Maximum
        minStrength = ($Links | ForEach-Object { $_.strength } | Measure-Object -Minimum).Minimum
        
        categories = @{
            directCount = if ($Categories.direct) { $Categories.direct.Count } else { 0 }
            indirectCount = if ($Categories.indirect) { $Categories.indirect.Count } else { 0 }
            circularCount = if ($Categories.circular) { $Categories.circular.Count } else { 0 }
            criticalCount = if ($Categories.critical) { $Categories.critical.Count } else { 0 }
            strongCount = if ($Categories.strong) { $Categories.strong.Count } else { 0 }
            weakCount = if ($Categories.weak) { $Categories.weak.Count } else { 0 }
        }
    }
    
    return $statistics
}

#endregion

# Functions available when dot-sourced
# Export-ModuleMember -Function @(
#     'Export-D3NetworkData',
#     'Export-RelationshipMatrix',
#     'Get-RelationshipCategorization'
# )