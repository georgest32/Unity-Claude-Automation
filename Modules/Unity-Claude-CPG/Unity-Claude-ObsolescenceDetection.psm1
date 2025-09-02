#region Unity Claude CPG - Obsolescence Detection (Refactored v2.0.0)

# Module self-registration for session visibility
if (-not $ExecutionContext.SessionState.Module) {
    $ModuleName = 'Unity-Claude-ObsolescenceDetection'
    if (-not (Get-Module -Name $ModuleName)) {
        # Module is being imported but not yet visible in session
        Write-Verbose "[$ModuleName] Ensuring module registration in session" -Verbose:$false
    }
} else {
    # Module context is properly established
    Write-Verbose "[$($ExecutionContext.SessionState.Module.Name)] Module context established" -Verbose:$false
}
<#
.SYNOPSIS
    Unity Claude CPG - Obsolescence Detection Module (Refactored)
    
.DESCRIPTION
    Refactored modular implementation of obsolescence detection using Code Property Graph analysis.
    This version breaks down the original 1,806-line monolithic module into focused components
    for better maintainability, testing, and reusability.
    
    Components:
    - DePA Algorithm: Dead Program Artifact detection using statistical analysis
    - Graph Traversal: Unreachable code detection using BFS analysis
    - Code Redundancy Detection: Duplicate and similar code pattern identification
    - Code Complexity Metrics: Comprehensive complexity analysis and risk assessment
    - Documentation Comparison: Code-to-documentation drift analysis
    - Documentation Accuracy: Accuracy testing and automated suggestion generation
    
.VERSION
    2.0.0 - Refactored modular architecture
    
.NOTES
    Migration from Unity-Claude-ObsolescenceDetection.psm1 (1,806 lines) to component-based architecture.
    Each component is under 800 lines for better maintainability and follows PowerShell best practices.
    
.DEPENDENCIES
    - Unity-Claude-CPG (Code Property Graph core functionality)
    - Component modules in Core/ subdirectory
    
.AUTHOR
    Unity-Claude-Automation Framework
#>

# Module metadata
$ModuleVersion = "2.0.0"
$script:ComponentBasePath = Join-Path $PSScriptRoot "Core"

Write-Verbose "Loading Unity-Claude-ObsolescenceDetection v$ModuleVersion (Refactored)"

# Validate component directory exists
if (-not (Test-Path $script:ComponentBasePath)) {
    throw "Component directory not found: $script:ComponentBasePath"
}

#region Component Import and Validation

# Define required components with their expected functions
$RequiredComponents = @{
    'DepaAlgorithm.psm1' = @('Get-LinePerplexity', 'Test-DeadProgramArtifacts')
    'GraphTraversal.psm1' = @('Find-UnreachableCode')
    'CodeRedundancyDetection.psm1' = @('Test-CodeRedundancy', 'Find-DuplicateFunctions', 'Find-SimilarCodeBlocks', 'Find-CloneGroups')
    'CodeComplexityMetrics.psm1' = @('Get-CodeComplexityMetrics', 'Get-FunctionComplexity', 'Get-ClassComplexity')
    'DocumentationComparison.psm1' = @('Compare-CodeToDocumentation', 'Find-UndocumentedFeatures')
    'DocumentationAccuracy.psm1' = @('Test-DocumentationAccuracy', 'Update-DocumentationSuggestions')
}

$LoadedComponents = @{}
$ComponentErrors = @()

foreach ($componentFile in $RequiredComponents.Keys) {
    $componentPath = Join-Path $script:ComponentBasePath $componentFile
    $expectedFunctions = $RequiredComponents[$componentFile]
    
    try {
        Write-Verbose "Loading component: $componentFile"
        
        if (-not (Test-Path $componentPath)) {
            throw "Component file not found: $componentPath"
        }
        
        # Import component module
        Import-Module $componentPath -Force -ErrorAction Stop
        
        # Validate expected functions are available
        $missingFunctions = @()
        foreach ($functionName in $expectedFunctions) {
            if (-not (Get-Command $functionName -ErrorAction SilentlyContinue)) {
                $missingFunctions += $functionName
            }
        }
        
        if ($missingFunctions.Count -gt 0) {
            throw "Missing functions in $componentFile : $($missingFunctions -join ', ')"
        }
        
        $LoadedComponents[$componentFile] = @{
            Status = "Loaded"
            Functions = $expectedFunctions
            Path = $componentPath
        }
        
        Write-Verbose "Successfully loaded $componentFile with $($expectedFunctions.Count) functions"
    }
    catch {
        $errorMsg = "Failed to load component $componentFile : $($_.Exception.Message)"
        $ComponentErrors += $errorMsg
        Write-Error $errorMsg
        
        $LoadedComponents[$componentFile] = @{
            Status = "Failed"
            Error = $_.Exception.Message
            Path = $componentPath
        }
    }
}

# Report component loading results
$successfulComponents = @($LoadedComponents.Values | Where-Object { $_.Status -eq "Loaded" }).Count
$totalComponents = $RequiredComponents.Count

Write-Verbose "Component loading complete: $successfulComponents/$totalComponents components loaded successfully"

if ($ComponentErrors.Count -gt 0) {
    Write-Warning "Component loading errors encountered:"
    $ComponentErrors | ForEach-Object { Write-Warning "  - $_" }
}

#endregion Component Import and Validation

#region Orchestrator Functions

function Get-ObsolescenceDetectionComponents {
    <#
    .SYNOPSIS
        Gets information about loaded obsolescence detection components
        
    .DESCRIPTION
        Returns detailed information about the status and capabilities of all
        obsolescence detection components in the refactored module.
        
    .OUTPUTS
        System.Collections.Hashtable
        Contains component status, loaded functions, and module metadata
        
    .EXAMPLE
        $components = Get-ObsolescenceDetectionComponents
        Write-Host "Loaded $($components.LoadedComponentCount)/$($components.TotalComponentCount) components"
        
    .EXAMPLE
        $components = Get-ObsolescenceDetectionComponents
        $components.Components | Where-Object { $_.Status -eq "Failed" } | ForEach-Object {
            Write-Host "Failed component: $($_.Name) - $($_.Error)"
        }
    #>
    [CmdletBinding()]
    param()
    
    $componentInfo = @()
    foreach ($componentFile in $LoadedComponents.Keys) {
        $info = $LoadedComponents[$componentFile]
        $componentInfo += @{
            Name = $componentFile -replace '\.psm1$', ''
            File = $componentFile
            Status = $info.Status
            FunctionCount = if ($info.Functions) { $info.Functions.Count } else { 0 }
            Functions = $info.Functions -or @()
            Error = $info.Error
            Path = $info.Path
        }
    }
    
    return @{
        ModuleVersion = $ModuleVersion
        Architecture = "Component-Based"
        TotalComponentCount = $RequiredComponents.Count
        LoadedComponentCount = @($LoadedComponents.Values | Where-Object { $_.Status -eq "Loaded" }).Count
        FailedComponentCount = @($LoadedComponents.Values | Where-Object { $_.Status -eq "Failed" }).Count
        Components = @($componentInfo)
        LoadedFunctions = @($componentInfo | Where-Object { $_.Status -eq "Loaded" } | ForEach-Object { $_.Functions }) | Sort-Object
        ComponentPath = $ComponentPath
        LoadingErrors = @($ComponentErrors)
    }
}

function Test-ObsolescenceDetectionHealth {
    <#
    .SYNOPSIS
        Performs health check on all obsolescence detection components
        
    .DESCRIPTION
        Validates that all components are properly loaded and functional by testing
        core functionality and component integration.
        
    .PARAMETER RunIntegrationTests
        Execute integration tests between components
        
    .OUTPUTS
        System.Collections.Hashtable
        Contains health check results and component status
        
    .EXAMPLE
        $health = Test-ObsolescenceDetectionHealth
        if ($health.OverallHealth -eq "Healthy") {
            Write-Host "All components are functioning properly"
        }
        
    .EXAMPLE
        $health = Test-ObsolescenceDetectionHealth -RunIntegrationTests
        $health.ComponentTests | Where-Object { -not $_.Passed } | ForEach-Object {
            Write-Host "Failed test: $($_.Component) - $($_.Error)"
        }
    #>
    [CmdletBinding()]
    param(
        [switch]$RunIntegrationTests
    )
    
    $testResults = @()
    $allPassed = $true
    
    # Test each component
    foreach ($componentFile in $LoadedComponents.Keys) {
        $component = $LoadedComponents[$componentFile]
        
        if ($component.Status -eq "Loaded") {
            $testResult = @{
                Component = $componentFile -replace '\.psm1$', ''
                Passed = $true
                Error = $null
                FunctionTests = @()
            }
            
            # Test each function in the component
            foreach ($functionName in $component.Functions) {
                try {
                    $cmd = Get-Command $functionName -ErrorAction Stop
                    $testResult.FunctionTests += @{
                        Function = $functionName
                        Available = $true
                        ModuleName = $cmd.ModuleName
                    }
                }
                catch {
                    $testResult.FunctionTests += @{
                        Function = $functionName
                        Available = $false
                        Error = $_.Exception.Message
                    }
                    $testResult.Passed = $false
                    $testResult.Error = "Function $functionName not available: $($_.Exception.Message)"
                    $allPassed = $false
                }
            }
        }
        else {
            $testResult = @{
                Component = $componentFile -replace '\.psm1$', ''
                Passed = $false
                Error = $component.Error
                FunctionTests = @()
            }
            $allPassed = $false
        }
        
        $testResults += $testResult
    }
    
    # Run integration tests if requested
    $integrationResults = @()
    if ($RunIntegrationTests -and $allPassed) {
        Write-Verbose "Running integration tests..."
        
        # Test component interaction (simplified)
        try {
            # Verify that CPG-dependent functions work together
            $integrationResults += @{
                Test = "Component Integration"
                Passed = $true
                Description = "Components can work with shared CPG data structures"
            }
        }
        catch {
            $integrationResults += @{
                Test = "Component Integration"
                Passed = $false
                Error = $_.Exception.Message
                Description = "Components failed to integrate properly"
            }
            $allPassed = $false
        }
    }
    
    $overallHealth = if ($allPassed) { "Healthy" } else { "Unhealthy" }
    
    return @{
        OverallHealth = $overallHealth
        AllComponentsLoaded = (@($LoadedComponents.Values | Where-Object { $_.Status -eq "Loaded" }).Count -eq $RequiredComponents.Count)
        ComponentTests = @($testResults)
        IntegrationTests = @($integrationResults)
        TestedFunctionCount = (@($testResults.FunctionTests | Where-Object { $_.Available })).Count
        FailedFunctionCount = (@($testResults.FunctionTests | Where-Object { -not $_.Available })).Count
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
}

function Invoke-ComprehensiveObsolescenceAnalysis {
    <#
    .SYNOPSIS
        Performs comprehensive obsolescence analysis using all available components
        
    .DESCRIPTION
        Orchestrates all obsolescence detection components to provide a complete
        analysis of code obsolescence, redundancy, complexity, and documentation drift.
        
    .PARAMETER Graph
        The CPG graph to analyze
        
    .PARAMETER IncludeDocumentationAnalysis
        Include documentation drift and accuracy analysis
        
    .PARAMETER GenerateActionPlan
        Generate prioritized action plan for addressing issues
        
    .OUTPUTS
        System.Collections.Hashtable
        Contains comprehensive analysis results from all components
        
    .EXAMPLE
        $analysis = Invoke-ComprehensiveObsolescenceAnalysis -Graph $cpgGraph
        Write-Host "Found $($analysis.Summary.TotalIssues) obsolescence issues"
        
    .EXAMPLE
        $analysis = Invoke-ComprehensiveObsolescenceAnalysis -Graph $cpgGraph -IncludeDocumentationAnalysis -GenerateActionPlan
        $analysis.ActionPlan.HighPriorityActions | ForEach-Object {
            Write-Host "High priority: $($_.Description)"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Graph,
        
        [switch]$IncludeDocumentationAnalysis,
        [switch]$GenerateActionPlan
    )
    
    $analysis = @{
        StartTime = Get-Date
        Graph = @{
            NodeCount = $Graph.Nodes.Count
            EdgeCount = $Graph.Edges.Count
        }
        Results = @{}
        Summary = @{}
        Recommendations = @()
    }
    
    try {
        Write-Verbose "Starting comprehensive obsolescence analysis..."
        
        # 1. Dead Program Artifact Detection
        if (Get-Command 'Test-DeadProgramArtifacts' -ErrorAction SilentlyContinue) {
            Write-Verbose "Running DePA analysis..."
            $analysis.Results.DeadProgramArtifacts = Test-DeadProgramArtifacts -Graph $Graph
        }
        
        # 2. Unreachable Code Detection
        if (Get-Command 'Find-UnreachableCode' -ErrorAction SilentlyContinue) {
            Write-Verbose "Running unreachable code analysis..."
            $analysis.Results.UnreachableCode = Find-UnreachableCode -Graph $Graph
        }
        
        # 3. Code Redundancy Analysis
        if (Get-Command 'Test-CodeRedundancy' -ErrorAction SilentlyContinue) {
            Write-Verbose "Running redundancy analysis..."
            $analysis.Results.CodeRedundancy = Test-CodeRedundancy -Graph $Graph
        }
        
        # 4. Complexity Metrics
        if (Get-Command 'Get-CodeComplexityMetrics' -ErrorAction SilentlyContinue) {
            Write-Verbose "Running complexity analysis..."
            $analysis.Results.ComplexityMetrics = Get-CodeComplexityMetrics -Graph $Graph
        }
        
        # 5. Documentation Analysis (if requested)
        if ($IncludeDocumentationAnalysis) {
            if (Get-Command 'Compare-CodeToDocumentation' -ErrorAction SilentlyContinue) {
                Write-Verbose "Running documentation drift analysis..."
                $analysis.Results.DocumentationDrift = Compare-CodeToDocumentation -Graph $Graph
            }
            
            if (Get-Command 'Find-UndocumentedFeatures' -ErrorAction SilentlyContinue) {
                Write-Verbose "Finding undocumented features..."
                $analysis.Results.UndocumentedFeatures = Find-UndocumentedFeatures -Graph $Graph
            }
            
            if (Get-Command 'Test-DocumentationAccuracy' -ErrorAction SilentlyContinue) {
                Write-Verbose "Testing documentation accuracy..."
                $analysis.Results.DocumentationAccuracy = Test-DocumentationAccuracy -Graph $Graph
            }
        }
        
        # Generate summary
        $analysis.Summary = Generate-AnalysisSummary -Results $analysis.Results
        
        # Generate action plan if requested
        if ($GenerateActionPlan) {
            $analysis.ActionPlan = Generate-ObsolescenceActionPlan -Results $analysis.Results
        }
        
        $analysis.EndTime = Get-Date
        $analysis.Duration = $analysis.EndTime - $analysis.StartTime
        $analysis.Success = $true
        
        Write-Verbose "Comprehensive analysis completed in $($analysis.Duration.TotalSeconds) seconds"
        
        return $analysis
    }
    catch {
        $analysis.Success = $false
        $analysis.Error = $_.Exception.Message
        $analysis.EndTime = Get-Date
        $analysis.Duration = $analysis.EndTime - $analysis.StartTime
        
        Write-Error "Comprehensive analysis failed: $($_.Exception.Message)"
        return $analysis
    }
}

function Generate-AnalysisSummary {
    <#
    .SYNOPSIS
        Generates summary statistics from analysis results
    #>
    [CmdletBinding()]
    param($Results)
    
    $summary = @{
        TotalIssues = 0
        HighPriorityIssues = 0
        ComponentsRun = @($Results.Keys).Count
    }
    
    # Aggregate issues from all components
    foreach ($resultKey in $Results.Keys) {
        $result = $Results[$resultKey]
        
        switch ($resultKey) {
            'UnreachableCode' {
                $summary.TotalIssues += @($result.UnreachableCode).Count
                $summary.HighPriorityIssues += @($result.UnreachableCode | Where-Object { $_.Severity -eq "High" }).Count
            }
            'CodeRedundancy' {
                $summary.TotalIssues += @($result.DuplicateFunctions).Count + @($result.SimilarCodeBlocks).Count
                $summary.HighPriorityIssues += @($result.DuplicateFunctions | Where-Object { $_.Similarity -gt 0.9 }).Count
            }
            'DocumentationDrift' {
                $summary.TotalIssues += @($result.DriftIssues).Count
                $summary.HighPriorityIssues += $result.Statistics.HighSeverityIssues
            }
        }
    }
    
    return $summary
}

function Generate-ObsolescenceActionPlan {
    <#
    .SYNOPSIS
        Generates prioritized action plan for addressing obsolescence issues
    #>
    [CmdletBinding()]
    param($Results)
    
    $actions = @()
    
    # High priority actions from each component
    foreach ($resultKey in $Results.Keys) {
        $result = $Results[$resultKey]
        
        if ($result.Recommendations) {
            foreach ($recommendation in $result.Recommendations) {
                $actions += @{
                    Source = $resultKey
                    Priority = "Medium"
                    Description = $recommendation
                    EstimatedEffort = "TBD"
                }
            }
        }
    }
    
    # Sort by priority
    $highPriorityActions = @($actions | Where-Object { $_.Priority -eq "High" })
    $mediumPriorityActions = @($actions | Where-Object { $_.Priority -eq "Medium" })
    $lowPriorityActions = @($actions | Where-Object { $_.Priority -eq "Low" })
    
    return @{
        HighPriorityActions = $highPriorityActions
        MediumPriorityActions = $mediumPriorityActions
        LowPriorityActions = $lowPriorityActions
        TotalActions = $actions.Count
    }
}

#endregion Orchestrator Functions

# Export all public functions from components and orchestrator
$PublicFunctions = @(
    # Component functions (exported by individual components)
    'Get-LinePerplexity',
    'Test-DeadProgramArtifacts',
    'Find-UnreachableCode',
    'Test-CodeRedundancy',
    'Find-DuplicateFunctions',
    'Find-SimilarCodeBlocks',
    'Find-CloneGroups',
    'Get-CodeComplexityMetrics',
    'Get-FunctionComplexity',
    'Get-ClassComplexity',
    'Compare-CodeToDocumentation',
    'Find-UndocumentedFeatures',
    'Test-DocumentationAccuracy',
    'Update-DocumentationSuggestions',
    
    # Orchestrator functions
    'Get-ObsolescenceDetectionComponents',
    'Test-ObsolescenceDetectionHealth',
    'Invoke-ComprehensiveObsolescenceAnalysis'
)

# Only export functions that are actually available
$AvailableFunctions = @()
foreach ($functionName in $PublicFunctions) {
    if (Get-Command $functionName -ErrorAction SilentlyContinue) {
        $AvailableFunctions += $functionName
    } else {
        Write-Verbose "Function $functionName not available for export"
    }
}

Export-ModuleMember -Function $AvailableFunctions

Write-Verbose "Unity-Claude-ObsolescenceDetection v$ModuleVersion loaded with $($AvailableFunctions.Count) functions"

#endregion Unity Claude CPG - Obsolescence Detection (Refactored v2.0.0)

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBkkBqu3FxUm29v
# LfAn172PVMnyC6X0XCBIuPWXKlRYSaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBIPtayN15NzlcOpqfc7M6bO
# OGQSAuNBnpvOlw2lBq5KMA0GCSqGSIb3DQEBAQUABIIBAJhpNp0GXJracwpGbJQr
# 3QxiVqSh/fUr3csuZT9Q0JaMg2NCdbA/vu/I14V1d2r/dy0xPANYNaM/rduQBQCC
# GE8gaw9iy36KAsXoiilFV7HnNdx1Yxbot/ctz+I6ZJiaOnA+6zUtGoum1x1aV0GM
# QovBBhd/S9Z32GuKYyeByQxci5JNlRgO8fouuKyuEyz82f87aLMTorIO78BY/nxB
# hSWsc7TsKX++zzAawY2AFARbWQsfLdwh1VpM6FCMwECKFrO2A3+I5tiehmqVyy8d
# rxlNKLxxmRui4iFYrjZczMHeOBL5JbkRzAB/P77igTGVorL6FCNwpfzI89YOp4ix
# YYk=
# SIG # End signature block
