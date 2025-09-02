#requires -Version 5.1

<#
.SYNOPSIS
Import/Export Relationship Analysis Functions
Extension functions for Unity-Claude-AST-Enhanced module for detailed Import-Module and Export-ModuleMember analysis

.DESCRIPTION
This script contains specialized functions for analyzing PowerShell module import/export relationships:
- Comprehensive Import-Module statement analysis across all modules
- Export-ModuleMember mapping showing function availability and dependencies
- Dependency strength metrics based on usage frequency
- Relationship matrices for visualization preparation

.NOTES
Script: Import-Export-Analysis.ps1
Version: 1.0.0
Date: 2025-08-30
Author: Unity-Claude-Automation System
Dependencies: Unity-Claude-AST-Enhanced module, DependencySearch module
#>

<#
.SYNOPSIS
Performs comprehensive Import-Module statement analysis across all specified modules

.DESCRIPTION
Analyzes all Import-Module statements within PowerShell modules, including:
- Direct module imports with full parameter analysis
- Conditional imports within if/try blocks
- Dynamic imports using variables or expressions
- Import frequency and usage patterns across the module ecosystem

.PARAMETER ModulePaths
Array of paths to PowerShell modules (.psm1 files) to analyze

.PARAMETER IncludeConditionalImports
Include Import-Module statements within conditional blocks

.PARAMETER AnalyzeParameters
Analyze Import-Module parameters (Force, Global, etc.)

.PARAMETER TrackUsageFrequency
Track and calculate usage frequency of imported modules

.EXAMPLE
Get-ModuleImportAnalysis -ModulePaths @(".\Modules\**\*.psm1") -IncludeConditionalImports -TrackUsageFrequency

.EXAMPLE
Get-ModuleImportAnalysis -ModulePaths (Get-ChildItem -Path ".\Modules" -Recurse -Filter "*.psm1" | Select-Object -ExpandProperty FullName)
#>
function Get-ModuleImportAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ModulePaths,
        [switch]$IncludeConditionalImports = $true,
        [switch]$AnalyzeParameters = $true,
        [switch]$TrackUsageFrequency = $true
    )
    
    Write-Verbose "Starting comprehensive Import-Module analysis for $($ModulePaths.Count) modules..."
    $startTime = Get-Date
    
    try {
        $importAnalysis = @{
            AnalyzedModules = @()
            ImportRelationships = @()
            ImportStatistics = @{}
            ConditionalImports = @()
            ParameterUsage = @{}
            DependencyChains = @()
            GeneratedOn = Get-Date
        }
        
        foreach ($modulePath in $ModulePaths) {
            if (-not (Test-Path $modulePath)) {
                Write-Warning "Module path not found: $modulePath"
                continue
            }
            
            Write-Verbose "Analyzing imports in: $modulePath"
            
            # Read and parse module content
            $content = Get-Content -Path $modulePath -Raw -ErrorAction SilentlyContinue
            if (-not $content) {
                Write-Warning "Could not read module content: $modulePath"
                continue
            }
            
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $moduleName = (Get-Item $modulePath).BaseName
            
            # Find all Import-Module commands
            $importCommands = $ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                $args[0].CommandElements[0].Value -like "*Import-Module*"
            }, $true)
            
            $moduleImports = @()
            
            foreach ($importCmd in $importCommands) {
                $importInfo = Analyze-ImportModuleCommand -ImportCommand $importCmd -SourceModule $moduleName -AnalyzeParameters:$AnalyzeParameters
                
                # Check if this is a conditional import
                $isConditional = Test-ConditionalImport -ImportCommand $importCmd -AST $ast
                if ($isConditional -and $IncludeConditionalImports) {
                    $importInfo.IsConditional = $true
                    $importInfo.ConditionalContext = Get-ConditionalContext -ImportCommand $importCmd -AST $ast
                    $importAnalysis.ConditionalImports += $importInfo
                }
                
                $moduleImports += $importInfo
                $importAnalysis.ImportRelationships += $importInfo
            }
            
            # Calculate usage frequency if requested
            if ($TrackUsageFrequency) {
                $usageFrequency = Calculate-ImportUsageFrequency -ModuleContent $content -ImportInfo $moduleImports -AST $ast
                foreach ($import in $moduleImports) {
                    if ($usageFrequency.ContainsKey($import.ImportedModule)) {
                        $import.UsageFrequency = $usageFrequency[$import.ImportedModule]
                    }
                }
            }
            
            # Track parameter usage statistics
            if ($AnalyzeParameters) {
                foreach ($import in $moduleImports) {
                    foreach ($param in $import.Parameters.Keys) {
                        if (-not $importAnalysis.ParameterUsage.ContainsKey($param)) {
                            $importAnalysis.ParameterUsage[$param] = 0
                        }
                        $importAnalysis.ParameterUsage[$param]++
                    }
                }
            }
            
            $importAnalysis.AnalyzedModules += @{
                ModuleName = $moduleName
                ModulePath = $modulePath
                ImportCount = $moduleImports.Count
                Imports = $moduleImports
            }
        }
        
        # Calculate dependency chains
        $importAnalysis.DependencyChains = Build-DependencyChains -ImportRelationships $importAnalysis.ImportRelationships
        
        # Generate import statistics
        $importAnalysis.ImportStatistics = @{
            TotalModulesAnalyzed = $importAnalysis.AnalyzedModules.Count
            TotalImportStatements = $importAnalysis.ImportRelationships.Count
            ConditionalImports = $importAnalysis.ConditionalImports.Count
            UniqueImportedModules = ($importAnalysis.ImportRelationships | Select-Object -ExpandProperty ImportedModule -Unique).Count
            MostImportedModules = Get-MostImportedModules -ImportRelationships $importAnalysis.ImportRelationships
            AnalysisTime = (Get-Date) - $startTime
        }
        
        Write-Verbose "Import-Module analysis completed in $($importAnalysis.ImportStatistics.AnalysisTime.TotalSeconds) seconds"
        return $importAnalysis
    }
    catch {
        Write-Error "Error analyzing Import-Module statements: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
Traces dependency chains across modules to identify complex interdependencies

.DESCRIPTION
Builds comprehensive dependency chains by following Import-Module relationships
across the entire module ecosystem, identifying circular dependencies, critical paths,
and dependency depth levels.

.PARAMETER ImportRelationships
Array of import relationship objects from Get-ModuleImportAnalysis

.PARAMETER MaxDepth
Maximum depth to trace dependency chains (default: 10)

.PARAMETER DetectCircularDependencies
Detect and report circular dependency patterns

.EXAMPLE
Get-ModuleDependencyChain -ImportRelationships $importAnalysis.ImportRelationships -DetectCircularDependencies
#>
function Get-ModuleDependencyChain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$ImportRelationships,
        [int]$MaxDepth = 10,
        [switch]$DetectCircularDependencies = $true
    )
    
    Write-Verbose "Building module dependency chains with max depth: $MaxDepth"
    
    try {
        $dependencyChains = @{
            Chains = @()
            CircularDependencies = @()
            CriticalPaths = @()
            DependencyLevels = @{}
            Statistics = @{}
        }
        
        # Create dependency graph
        $dependencyGraph = @{}
        foreach ($relationship in $ImportRelationships) {
            $source = $relationship.SourceModule
            $target = $relationship.ImportedModule
            
            if (-not $dependencyGraph.ContainsKey($source)) {
                $dependencyGraph[$source] = @()
            }
            $dependencyGraph[$source] += $target
        }
        
        # Build chains for each module
        foreach ($sourceModule in $dependencyGraph.Keys) {
            $chains = Trace-DependencyChain -SourceModule $sourceModule -DependencyGraph $dependencyGraph -MaxDepth $MaxDepth -VisitedPath @()
            $dependencyChains.Chains += $chains
            
            # Calculate dependency level
            $maxDepth = ($chains | ForEach-Object { $_.Depth } | Measure-Object -Maximum).Maximum
            $dependencyChains.DependencyLevels[$sourceModule] = $maxDepth
        }
        
        # Detect circular dependencies
        if ($DetectCircularDependencies) {
            $dependencyChains.CircularDependencies = Find-CircularDependencies -DependencyGraph $dependencyGraph
        }
        
        # Identify critical paths (longest dependency chains)
        $dependencyChains.CriticalPaths = $dependencyChains.Chains | 
            Where-Object { $_.Depth -eq ($dependencyChains.Chains | ForEach-Object { $_.Depth } | Measure-Object -Maximum).Maximum } |
            Select-Object -First 5
        
        # Calculate statistics
        $dependencyChains.Statistics = @{
            TotalChains = $dependencyChains.Chains.Count
            AverageDepth = ($dependencyChains.Chains | ForEach-Object { $_.Depth } | Measure-Object -Average).Average
            MaxDepth = ($dependencyChains.Chains | ForEach-Object { $_.Depth } | Measure-Object -Maximum).Maximum
            CircularDependencies = $dependencyChains.CircularDependencies.Count
            CriticalPaths = $dependencyChains.CriticalPaths.Count
        }
        
        Write-Verbose "Dependency chain analysis completed: $($dependencyChains.Statistics.TotalChains) chains found"
        return $dependencyChains
    }
    catch {
        Write-Error "Error tracing dependency chains: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
Maps all exported functions and their availability across the module ecosystem

.DESCRIPTION
Comprehensive analysis of Export-ModuleMember statements and exported functions:
- Explicit exports via Export-ModuleMember
- Implicit exports (functions without Export-ModuleMember)
- Function visibility and availability mapping
- Cross-reference with actual function usage

.PARAMETER ModulePaths
Array of paths to PowerShell modules (.psm1 files) to analyze

.PARAMETER IncludeImplicitExports
Include functions that are exported implicitly (no Export-ModuleMember)

.PARAMETER AnalyzeFunctionUsage
Analyze actual usage of exported functions across modules

.EXAMPLE
Get-ModuleExportAnalysis -ModulePaths @(".\Modules\**\*.psm1") -IncludeImplicitExports -AnalyzeFunctionUsage
#>
function Get-ModuleExportAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string[]]$ModulePaths,
        [switch]$IncludeImplicitExports = $true,
        [switch]$AnalyzeFunctionUsage = $true
    )
    
    Write-Verbose "Starting Export-ModuleMember analysis for $($ModulePaths.Count) modules..."
    $startTime = Get-Date
    
    try {
        $exportAnalysis = @{
            AnalyzedModules = @()
            ExportedFunctions = @()
            ExplicitExports = @()
            ImplicitExports = @()
            FunctionUsage = @()
            ExportStatistics = @{}
            GeneratedOn = Get-Date
        }
        
        foreach ($modulePath in $ModulePaths) {
            if (-not (Test-Path $modulePath)) {
                Write-Warning "Module path not found: $modulePath"
                continue
            }
            
            Write-Verbose "Analyzing exports in: $modulePath"
            
            $content = Get-Content -Path $modulePath -Raw -ErrorAction SilentlyContinue
            if (-not $content) {
                Write-Warning "Could not read module content: $modulePath"
                continue
            }
            
            $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
            $moduleName = (Get-Item $modulePath).BaseName
            
            # Find all function definitions
            $functions = $ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
            }, $true)
            
            # Find explicit Export-ModuleMember commands
            $exportCommands = $ast.FindAll({
                $args[0] -is [System.Management.Automation.Language.CommandAst] -and
                $args[0].CommandElements[0].Value -like "*Export-ModuleMember*"
            }, $true)
            
            $explicitlyExported = @()
            $exportMemberInfo = @()
            
            # Analyze Export-ModuleMember statements
            foreach ($exportCmd in $exportCommands) {
                $exportInfo = Analyze-ExportModuleMemberCommand -ExportCommand $exportCmd -SourceModule $moduleName
                $exportMemberInfo += $exportInfo
                $explicitlyExported += $exportInfo.ExportedItems
            }
            
            $moduleExports = @()
            
            # Process each function
            foreach ($function in $functions) {
                $functionName = $function.Name
                $isExplicitlyExported = $explicitlyExported -contains $functionName
                
                $functionExport = @{
                    ModuleName = $moduleName
                    FunctionName = $functionName
                    IsExplicitlyExported = $isExplicitlyExported
                    IsImplicitlyExported = (-not $exportCommands.Count -or (-not $isExplicitlyExported -and $IncludeImplicitExports))
                    Parameters = @($function.Parameters | ForEach-Object { $_.Name.VariablePath.UserPath })
                    LineNumber = $function.Extent.StartLineNumber
                    Complexity = Calculate-FunctionComplexity -FunctionAST $function
                }
                
                if ($isExplicitlyExported) {
                    $exportAnalysis.ExplicitExports += $functionExport
                }
                elseif ($functionExport.IsImplicitlyExported -and $IncludeImplicitExports) {
                    $exportAnalysis.ImplicitExports += $functionExport
                }
                
                $moduleExports += $functionExport
                $exportAnalysis.ExportedFunctions += $functionExport
            }
            
            $exportAnalysis.AnalyzedModules += @{
                ModuleName = $moduleName
                ModulePath = $modulePath
                TotalFunctions = $functions.Count
                ExplicitExports = ($moduleExports | Where-Object { $_.IsExplicitlyExported }).Count
                ImplicitExports = ($moduleExports | Where-Object { $_.IsImplicitlyExported -and -not $_.IsExplicitlyExported }).Count
                ExportMemberStatements = $exportMemberInfo
                Functions = $moduleExports
            }
        }
        
        # Analyze function usage across modules
        if ($AnalyzeFunctionUsage) {
            $exportAnalysis.FunctionUsage = Analyze-CrossModuleFunctionUsage -ModulePaths $ModulePaths -ExportedFunctions $exportAnalysis.ExportedFunctions
        }
        
        # Generate export statistics
        $exportAnalysis.ExportStatistics = @{
            TotalModulesAnalyzed = $exportAnalysis.AnalyzedModules.Count
            TotalFunctions = $exportAnalysis.ExportedFunctions.Count
            ExplicitlyExported = $exportAnalysis.ExplicitExports.Count
            ImplicitlyExported = $exportAnalysis.ImplicitExports.Count
            MostUsedFunctions = Get-MostUsedFunctions -FunctionUsage $exportAnalysis.FunctionUsage
            AnalysisTime = (Get-Date) - $startTime
        }
        
        Write-Verbose "Export-ModuleMember analysis completed in $($exportAnalysis.ExportStatistics.AnalysisTime.TotalSeconds) seconds"
        return $exportAnalysis
    }
    catch {
        Write-Error "Error analyzing Export-ModuleMember statements: $($_.Exception.Message)"
        throw
    }
}

<#
.SYNOPSIS
Calculates usage frequency metrics for imported modules and exported functions

.DESCRIPTION
Analyzes actual usage frequency of imported modules and exported functions
by examining function calls, command usage, and reference patterns throughout
the module ecosystem.

.PARAMETER ImportAnalysis
Import analysis results from Get-ModuleImportAnalysis

.PARAMETER ExportAnalysis
Export analysis results from Get-ModuleExportAnalysis

.PARAMETER ModulePaths
Array of paths to modules for usage frequency calculation

.EXAMPLE
Get-ExportUsageFrequency -ImportAnalysis $imports -ExportAnalysis $exports -ModulePaths $modulePaths
#>
function Get-ExportUsageFrequency {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$ImportAnalysis,
        [Parameter(Mandatory)]
        [object]$ExportAnalysis,
        [string[]]$ModulePaths
    )
    
    Write-Verbose "Calculating export usage frequency metrics..."
    
    try {
        $usageFrequency = @{
            ModuleUsage = @{}
            FunctionUsage = @{}
            CrossReferences = @()
            UsageStatistics = @{}
        }
        
        # Calculate module import frequency
        $moduleImportCounts = @{}
        foreach ($import in $ImportAnalysis.ImportRelationships) {
            $moduleName = $import.ImportedModule
            if (-not $moduleImportCounts.ContainsKey($moduleName)) {
                $moduleImportCounts[$moduleName] = 0
            }
            $moduleImportCounts[$moduleName]++
        }
        
        # Calculate function usage frequency across all modules
        $functionUsageCounts = @{}
        
        if ($ModulePaths) {
            foreach ($modulePath in $ModulePaths) {
                if (Test-Path $modulePath) {
                    $content = Get-Content -Path $modulePath -Raw -ErrorAction SilentlyContinue
                    if ($content) {
                        $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
                        
                        # Find all command calls
                        $commandCalls = $ast.FindAll({
                            $args[0] -is [System.Management.Automation.Language.CommandAst]
                        }, $true)
                        
                        foreach ($call in $commandCalls) {
                            $commandName = $call.CommandElements[0].Value
                            
                            # Check if this command is an exported function
                            $exportedFunction = $ExportAnalysis.ExportedFunctions | Where-Object { $_.FunctionName -eq $commandName }
                            if ($exportedFunction) {
                                $key = "$($exportedFunction.ModuleName)::$($exportedFunction.FunctionName)"
                                if (-not $functionUsageCounts.ContainsKey($key)) {
                                    $functionUsageCounts[$key] = 0
                                }
                                $functionUsageCounts[$key]++
                            }
                        }
                    }
                }
            }
        }
        
        # Build usage frequency data structures
        $usageFrequency.ModuleUsage = $moduleImportCounts | ForEach-Object {
            @{
                ModuleName = $_.Key
                ImportFrequency = $_.Value
                UsageScore = Calculate-UsageScore -ImportFrequency $_.Value -ModuleCount $ImportAnalysis.AnalyzedModules.Count
            }
        }
        
        $usageFrequency.FunctionUsage = $functionUsageCounts.GetEnumerator() | ForEach-Object {
            $parts = $_.Key -split "::"
            @{
                ModuleName = $parts[0]
                FunctionName = $parts[1]
                CallFrequency = $_.Value
                UsageScore = Calculate-UsageScore -ImportFrequency $_.Value -ModuleCount $ExportAnalysis.AnalyzedModules.Count
            }
        }
        
        # Generate usage statistics
        $usageFrequency.UsageStatistics = @{
            TotalModulesTracked = $moduleImportCounts.Count
            TotalFunctionsTracked = $functionUsageCounts.Count
            AverageModuleUsage = if ($moduleImportCounts.Count -gt 0) { ($moduleImportCounts.Values | Measure-Object -Average).Average } else { 0 }
            AverageFunctionUsage = if ($functionUsageCounts.Count -gt 0) { ($functionUsageCounts.Values | Measure-Object -Average).Average } else { 0 }
            TopUsedModules = $usageFrequency.ModuleUsage | Sort-Object -Property UsageScore -Descending | Select-Object -First 5
            TopUsedFunctions = $usageFrequency.FunctionUsage | Sort-Object -Property UsageScore -Descending | Select-Object -First 10
        }
        
        Write-Verbose "Usage frequency analysis completed"
        return $usageFrequency
    }
    catch {
        Write-Error "Error calculating usage frequency: $($_.Exception.Message)"
        throw
    }
}

#region Helper Functions

function Analyze-ImportModuleCommand {
    param($ImportCommand, $SourceModule, [switch]$AnalyzeParameters)
    
    $importInfo = @{
        SourceModule = $SourceModule
        ImportedModule = ""
        Parameters = @{}
        LineNumber = $ImportCommand.Extent.StartLineNumber
        IsConditional = $false
        UsageFrequency = 0
    }
    
    # Extract imported module name
    if ($ImportCommand.CommandElements.Count -gt 1) {
        $importInfo.ImportedModule = $ImportCommand.CommandElements[1].Value
    }
    
    # Analyze parameters if requested
    if ($AnalyzeParameters) {
        for ($i = 2; $i -lt $ImportCommand.CommandElements.Count; $i++) {
            $element = $ImportCommand.CommandElements[$i]
            if ($element.ParameterName) {
                $paramName = $element.ParameterName
                $paramValue = if ($i + 1 -lt $ImportCommand.CommandElements.Count) { $ImportCommand.CommandElements[$i + 1].Value } else { $true }
                $importInfo.Parameters[$paramName] = $paramValue
            }
        }
    }
    
    return $importInfo
}

function Test-ConditionalImport {
    param($ImportCommand, $AST)
    
    # Check if the import is within a conditional block
    $parent = $ImportCommand.Parent
    while ($parent) {
        if ($parent -is [System.Management.Automation.Language.IfStatementAst] -or 
            $parent -is [System.Management.Automation.Language.TryStatementAst] -or
            $parent -is [System.Management.Automation.Language.CatchClauseAst]) {
            return $true
        }
        $parent = $parent.Parent
    }
    
    return $false
}

function Get-ConditionalContext {
    param($ImportCommand, $AST)
    
    $parent = $ImportCommand.Parent
    while ($parent) {
        if ($parent -is [System.Management.Automation.Language.IfStatementAst]) {
            return @{
                Type = "If"
                Condition = $parent.Clauses[0].Item1.ToString()
            }
        }
        elseif ($parent -is [System.Management.Automation.Language.TryStatementAst]) {
            return @{
                Type = "Try"
                Condition = "Exception handling"
            }
        }
        $parent = $parent.Parent
    }
    
    return @{ Type = "Unknown"; Condition = "Unknown" }
}

function Calculate-ImportUsageFrequency {
    param($ModuleContent, $ImportInfo, $AST)
    
    $usageFrequency = @{}
    
    foreach ($import in $ImportInfo) {
        $moduleName = $import.ImportedModule
        $frequency = 0
        
        # Count direct references to module name
        $frequency += ([regex]::Matches($ModuleContent, [regex]::Escape($moduleName))).Count
        
        # This could be enhanced to look for specific function calls from the module
        $usageFrequency[$moduleName] = $frequency
    }
    
    return $usageFrequency
}

function Build-DependencyChains {
    param($ImportRelationships)
    
    $chains = @()
    
    # Create lookup for dependencies
    $dependencies = @{}
    foreach ($rel in $ImportRelationships) {
        if (-not $dependencies.ContainsKey($rel.SourceModule)) {
            $dependencies[$rel.SourceModule] = @()
        }
        $dependencies[$rel.SourceModule] += $rel.ImportedModule
    }
    
    # Build chains for each module
    foreach ($module in $dependencies.Keys) {
        $chain = Trace-DependencyChain -SourceModule $module -DependencyGraph $dependencies -MaxDepth 10 -VisitedPath @()
        $chains += $chain
    }
    
    return $chains
}

function Trace-DependencyChain {
    param($SourceModule, $DependencyGraph, $MaxDepth, $VisitedPath)
    
    $chains = @()
    
    if ($MaxDepth -le 0 -or $SourceModule -in $VisitedPath) {
        return @()
    }
    
    $newPath = $VisitedPath + $SourceModule
    
    if ($DependencyGraph.ContainsKey($SourceModule)) {
        foreach ($dependency in $DependencyGraph[$SourceModule]) {
            $chain = @{
                Source = $SourceModule
                Target = $dependency
                Path = $newPath + $dependency
                Depth = $newPath.Count
            }
            $chains += $chain
            
            # Recursively trace further dependencies
            $subChains = Trace-DependencyChain -SourceModule $dependency -DependencyGraph $DependencyGraph -MaxDepth ($MaxDepth - 1) -VisitedPath $newPath
            $chains += $subChains
        }
    }
    
    return $chains
}

function Find-CircularDependencies {
    param($DependencyGraph)
    
    $circularDeps = @()
    $visited = @{}
    $recursionStack = @{}
    
    foreach ($module in $DependencyGraph.Keys) {
        if (-not $visited[$module]) {
            $circular = Find-CircularDependenciesHelper -Module $module -DependencyGraph $DependencyGraph -Visited $visited -RecursionStack $recursionStack -Path @()
            $circularDeps += $circular
        }
    }
    
    return $circularDeps
}

function Find-CircularDependenciesHelper {
    param($Module, $DependencyGraph, $Visited, $RecursionStack, $Path)
    
    $Visited[$Module] = $true
    $RecursionStack[$Module] = $true
    $newPath = $Path + $Module
    
    if ($DependencyGraph.ContainsKey($Module)) {
        foreach ($dependency in $DependencyGraph[$Module]) {
            if (-not $Visited[$dependency]) {
                $result = Find-CircularDependenciesHelper -Module $dependency -DependencyGraph $DependencyGraph -Visited $Visited -RecursionStack $RecursionStack -Path $newPath
                if ($result) { return $result }
            }
            elseif ($RecursionStack[$dependency]) {
                # Found circular dependency
                $circularPath = $newPath[($newPath.IndexOf($dependency))..$newPath.Count] + $dependency
                return @{
                    CircularPath = $circularPath
                    StartModule = $dependency
                    PathLength = $circularPath.Count - 1
                }
            }
        }
    }
    
    $RecursionStack[$Module] = $false
    return $null
}

function Get-MostImportedModules {
    param($ImportRelationships)
    
    $importCounts = @{}
    foreach ($rel in $ImportRelationships) {
        $module = $rel.ImportedModule
        if (-not $importCounts.ContainsKey($module)) {
            $importCounts[$module] = 0
        }
        $importCounts[$module]++
    }
    
    return $importCounts.GetEnumerator() | 
        Sort-Object -Property Value -Descending | 
        Select-Object -First 5 | 
        ForEach-Object { @{ ModuleName = $_.Key; ImportCount = $_.Value } }
}

function Analyze-ExportModuleMemberCommand {
    param($ExportCommand, $SourceModule)
    
    $exportInfo = @{
        SourceModule = $SourceModule
        ExportedItems = @()
        ExportType = "Function"  # Default, could be enhanced to detect Alias, Variable, etc.
        LineNumber = $ExportCommand.Extent.StartLineNumber
    }
    
    # Parse Export-ModuleMember parameters
    for ($i = 1; $i -lt $ExportCommand.CommandElements.Count; $i++) {
        $element = $ExportCommand.CommandElements[$i]
        if ($element.ParameterName -eq "Function") {
            # Next element should be the function name(s)
            if ($i + 1 -lt $ExportCommand.CommandElements.Count) {
                $functionNames = $ExportCommand.CommandElements[$i + 1].Value
                if ($functionNames -like "@(*") {
                    # Array of functions
                    $exportInfo.ExportedItems += $functionNames -replace '@\(|\)|"| ', '' -split ','
                } else {
                    $exportInfo.ExportedItems += $functionNames
                }
            }
        }
    }
    
    return $exportInfo
}

function Calculate-FunctionComplexity {
    param($FunctionAST)
    
    # Basic complexity calculation based on control flow statements
    $complexity = 1  # Base complexity
    
    $controlFlowElements = $FunctionAST.FindAll({
        $args[0] -is [System.Management.Automation.Language.IfStatementAst] -or
        $args[0] -is [System.Management.Automation.Language.ForStatementAst] -or
        $args[0] -is [System.Management.Automation.Language.ForEachStatementAst] -or
        $args[0] -is [System.Management.Automation.Language.WhileStatementAst] -or
        $args[0] -is [System.Management.Automation.Language.SwitchStatementAst] -or
        $args[0] -is [System.Management.Automation.Language.TryStatementAst]
    }, $true)
    
    $complexity += $controlFlowElements.Count
    
    return $complexity
}

function Analyze-CrossModuleFunctionUsage {
    param($ModulePaths, $ExportedFunctions)
    
    $functionUsage = @()
    
    foreach ($modulePath in $ModulePaths) {
        if (Test-Path $modulePath) {
            $content = Get-Content -Path $modulePath -Raw -ErrorAction SilentlyContinue
            if ($content) {
                $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
                $sourceModule = (Get-Item $modulePath).BaseName
                
                # Find all command calls
                $commandCalls = $ast.FindAll({
                    $args[0] -is [System.Management.Automation.Language.CommandAst]
                }, $true)
                
                foreach ($call in $commandCalls) {
                    $commandName = $call.CommandElements[0].Value
                    
                    # Check if this command is an exported function from another module
                    $exportedFunction = $ExportedFunctions | Where-Object { 
                        $_.FunctionName -eq $commandName -and $_.ModuleName -ne $sourceModule 
                    }
                    
                    if ($exportedFunction) {
                        $functionUsage += @{
                            SourceModule = $sourceModule
                            TargetModule = $exportedFunction.ModuleName
                            FunctionName = $commandName
                            LineNumber = $call.Extent.StartLineNumber
                            CallCount = 1  # Could be enhanced for frequency counting
                        }
                    }
                }
            }
        }
    }
    
    return $functionUsage
}

function Get-MostUsedFunctions {
    param($FunctionUsage)
    
    if (-not $FunctionUsage -or $FunctionUsage.Count -eq 0) {
        return @()
    }
    
    $usageCounts = @{}
    foreach ($usage in $FunctionUsage) {
        $key = "$($usage.TargetModule)::$($usage.FunctionName)"
        if (-not $usageCounts.ContainsKey($key)) {
            $usageCounts[$key] = 0
        }
        $usageCounts[$key] += $usage.CallCount
    }
    
    return $usageCounts.GetEnumerator() | 
        Sort-Object -Property Value -Descending | 
        Select-Object -First 10 | 
        ForEach-Object { 
            $parts = $_.Key -split "::"
            @{ 
                ModuleName = $parts[0]
                FunctionName = $parts[1]
                UsageCount = $_.Value 
            } 
        }
}

function Calculate-UsageScore {
    param($ImportFrequency, $ModuleCount)
    
    if ($ModuleCount -eq 0) { return 0 }
    
    # Calculate score as percentage of modules that use this item
    $score = ($ImportFrequency / $ModuleCount) * 100
    return [math]::Round($score, 2)
}

#endregion

# Functions for use with Unity-Claude-AST-Enhanced module
# Note: Functions are available when this script is dot-sourced
# Export-ModuleMember -Function @(
#     'Get-ModuleImportAnalysis',
#     'Get-ModuleDependencyChain',
#     'Get-ModuleExportAnalysis',
#     'Get-ExportUsageFrequency'
# )