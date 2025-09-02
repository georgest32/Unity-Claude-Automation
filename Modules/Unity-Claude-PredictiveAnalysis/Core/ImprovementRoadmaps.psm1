# Unity-Claude-PredictiveAnalysis Improvement Roadmaps Component
# Creates improvement roadmaps and exports comprehensive reports
# Part of refactored PredictiveAnalysis module

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Import dependencies
$CorePath = Join-Path $PSScriptRoot "PredictiveCore.psm1"
$TrendPath = Join-Path $PSScriptRoot "TrendAnalysis.psm1" 
$MaintenancePath = Join-Path $PSScriptRoot "MaintenancePrediction.psm1"
$RefactoringPath = Join-Path $PSScriptRoot "RefactoringDetection.psm1"
$SmellPath = Join-Path $PSScriptRoot "CodeSmellPrediction.psm1"

Import-Module $CorePath -Force
Import-Module $TrendPath -Force
Import-Module $MaintenancePath -Force
Import-Module $RefactoringPath -Force
Import-Module $SmellPath -Force

function New-ImprovementRoadmap {
    <#
    .SYNOPSIS
    Creates a comprehensive improvement roadmap for a codebase
    .DESCRIPTION
    Analyzes codebase health and creates a phased improvement plan with effort estimates,
    ROI calculations, and success metrics
    .PARAMETER Path
    Path to the codebase to analyze
    .PARAMETER Graph
    Optional CPG graph for enhanced analysis
    .PARAMETER MaxPhases
    Maximum number of improvement phases to generate
    .PARAMETER IncludeLLMRecommendations
    Include LLM-generated strategic recommendations
    .EXAMPLE
    New-ImprovementRoadmap -Path "C:\Project" -Graph $cpgGraph -IncludeLLMRecommendations
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        $Graph = $null,
        
        [ValidateRange(1, 10)]
        [int]$MaxPhases = 5,
        
        [switch]$IncludeLLMRecommendations
    )
    
    Write-Verbose "Creating improvement roadmap for $Path"
    
    try {
        # Check cache first
        $cacheKey = "roadmap_${Path}_${MaxPhases}_$($IncludeLLMRecommendations.IsPresent)"
        $cached = Get-CacheItem -Key $cacheKey
        if ($cached) {
            Write-Verbose "Returning cached improvement roadmap"
            return $cached
        }
        
        # Gather all analyses
        Write-Verbose "Gathering codebase analyses..."
        $analyses = @{
            Maintenance = Get-MaintenancePrediction -Path $Path -Graph $Graph
            TechnicalDebt = Calculate-TechnicalDebt -Path $Path -Graph $Graph
            Refactoring = if ($Graph) { Find-RefactoringOpportunities -Graph $Graph } else { $null }
            CodeSmells = if ($Graph) { Predict-CodeSmells -Graph $Graph } else { $null }
            Evolution = Get-CodeEvolutionTrend -Path $Path -DaysBack 90 -Granularity Weekly
        }
        
        # Initialize roadmap structure
        $roadmap = @{
            Path = $Path
            CreatedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Phases = @()
            TotalEffort = 0
            ExpectedROI = @{}
            Success = @{
                Metrics = @()
                Targets = @()
            }
            AnalysisInputs = @{
                MaintenanceRisk = $analyses.Maintenance.RiskLevel
                TechnicalDebtHours = $analyses.TechnicalDebt.TotalHours
                CodeSmellCount = if ($analyses.CodeSmells) { $analyses.CodeSmells.Summary.Total } else { 0 }
                RefactoringOpportunities = if ($analyses.Refactoring) { $analyses.Refactoring.Summary.Total } else { 0 }
            }
        }
        
        # Phase 1: Critical Issues Resolution
        $phase1 = Create-CriticalPhase -Analyses $analyses
        if ($phase1.Actions.Count -gt 0) {
            $roadmap.Phases += $phase1
        }
        
        # Phase 2: High-Impact Improvements
        $phase2 = Create-HighImpactPhase -Analyses $analyses
        if ($phase2.Actions.Count -gt 0) {
            $roadmap.Phases += $phase2
        }
        
        # Phase 3: Optimization and Performance
        $phase3 = Create-OptimizationPhase -Analyses $analyses
        if ($phase3.Actions.Count -gt 0) {
            $roadmap.Phases += $phase3
        }
        
        # Phase 4: Documentation and Testing
        $phase4 = Create-DocumentationPhase -Analyses $analyses
        if ($phase4.Actions.Count -gt 0) {
            $roadmap.Phases += $phase4
        }
        
        # Phase 5: Continuous Improvement (always included)
        $phase5 = Create-ContinuousImprovementPhase
        $roadmap.Phases += $phase5
        
        # Limit to max phases if requested
        if ($roadmap.Phases.Count -gt $MaxPhases) {
            $roadmap.Phases = $roadmap.Phases[0..($MaxPhases - 1)]
        }
        
        # Calculate total effort and ROI
        $roadmap.TotalEffort = ($roadmap.Phases | Measure-Object -Property TotalHours -Sum).Sum
        $roadmap.ExpectedROI = Calculate-ExpectedROI -TotalEffort $roadmap.TotalEffort -Analyses $analyses
        $roadmap.Success = Define-SuccessMetrics -Analyses $analyses
        
        # Add LLM recommendations if requested
        if ($IncludeLLMRecommendations -and (Get-Command Invoke-OllamaGenerate -ErrorAction SilentlyContinue)) {
            $roadmap.StrategicRecommendations = Get-LLMRoadmapRecommendations -Roadmap $roadmap -Analyses $analyses
        }
        
        # Cache the result
        Set-CacheItem -Key $cacheKey -Value $roadmap -TTLMinutes 120
        
        return $roadmap
    }
    catch {
        Write-Error "Failed to create improvement roadmap: $_"
        return $null
    }
}

function Create-CriticalPhase {
    <#
    .SYNOPSIS
    Creates the critical issues resolution phase
    .PARAMETER Analyses
    Collection of codebase analyses
    #>
    [CmdletBinding()]
    param([hashtable]$Analyses)
    
    $actions = @()
    
    # Critical maintenance issues
    if ($Analyses.Maintenance -and $Analyses.Maintenance.RiskLevel -in @('Critical', 'High')) {
        $estimatedHours = switch ($Analyses.Maintenance.RiskLevel) {
            'Critical' { 40 }
            'High' { 20 }
            default { 10 }
        }
        
        $actions += @{
            Action = 'Address critical maintenance issues'
            Tasks = $Analyses.Maintenance.TopIssues + $Analyses.Maintenance.Recommendations
            EstimatedHours = $estimatedHours
            Priority = 'Critical'
            Impact = 'High'
            Dependencies = @()
        }
    }
    
    # High-severity code smells
    if ($Analyses.CodeSmells -and $Analyses.CodeSmells.Summary.High -gt 0) {
        $highSmells = $Analyses.CodeSmells.Smells | Where-Object { $_.Severity -eq 'High' }
        $actions += @{
            Action = 'Fix high-severity code smells'
            Tasks = $highSmells | ForEach-Object { "$($_.Type) in $($_.Target) - $($_.Fix)" }
            EstimatedHours = $highSmells.Count * 4
            Priority = 'High'
            Impact = 'High'
            Dependencies = @()
        }
    }
    
    # Critical technical debt items
    if ($Analyses.TechnicalDebt) {
        $criticalDebt = $Analyses.TechnicalDebt.Items | Where-Object { $_.Priority -eq 'High' }
        if ($criticalDebt.Count -gt 0) {
            $actions += @{
                Action = 'Address critical technical debt'
                Tasks = $criticalDebt | ForEach-Object { $_.Description }
                EstimatedHours = ($criticalDebt | Measure-Object -Property EstimatedHours -Sum).Sum
                Priority = 'High'
                Impact = 'High'
                Dependencies = @()
            }
        }
    }
    
    if ($actions.Count -eq 0) {
        return @{ Actions = @() }
    }
    
    return @{
        Number = 1
        Name = 'Critical Issue Resolution'
        Duration = '1-2 weeks'
        Description = 'Immediate stabilization of codebase by addressing critical issues and high-risk areas'
        Actions = $actions
        TotalHours = ($actions | Measure-Object -Property EstimatedHours -Sum).Sum
        ExpectedOutcome = 'Stabilize codebase, eliminate critical risks, and establish foundation for improvements'
        SuccessCriteria = @(
            'All critical maintenance issues resolved',
            'High-severity code smells eliminated',
            'Critical technical debt addressed'
        )
    }
}

function Create-HighImpactPhase {
    <#
    .SYNOPSIS
    Creates the high-impact improvements phase
    .PARAMETER Analyses
    Collection of codebase analyses
    #>
    [CmdletBinding()]
    param([hashtable]$Analyses)
    
    $actions = @()
    
    # High-impact refactoring opportunities
    if ($Analyses.Refactoring) {
        $highImpact = $Analyses.Refactoring.Opportunities | Where-Object { $_.Impact -eq 'High' }
        if ($highImpact.Count -gt 0) {
            $actions += @{
                Action = 'Execute high-impact refactoring'
                Tasks = $highImpact | ForEach-Object { "$($_.Type): $($_.Target) - $($_.Details)" }
                EstimatedHours = $highImpact.Count * 8
                Priority = 'High'
                Impact = 'High'
                Dependencies = @('Phase 1 completion')
            }
        }
    }
    
    # Medium-priority technical debt with high ROI
    if ($Analyses.TechnicalDebt) {
        $mediumDebt = $Analyses.TechnicalDebt.Items | Where-Object { $_.Priority -eq 'Medium' }
        if ($mediumDebt.Count -gt 0 -and $Analyses.TechnicalDebt.TotalHours -gt 20) {
            $actions += @{
                Action = 'Reduce medium-priority technical debt'
                Tasks = $mediumDebt | Select-Object -First 5 | ForEach-Object { $_.Description }
                EstimatedHours = ($mediumDebt | Select-Object -First 5 | Measure-Object -Property EstimatedHours -Sum).Sum
                Priority = 'High'
                Impact = 'Medium'
                Dependencies = @()
            }
        }
    }
    
    # Architecture improvements
    if ($Analyses.CodeSmells -and $Analyses.CodeSmells.Summary.Medium -gt 2) {
        $actions += @{
            Action = 'Implement architectural improvements'
            Tasks = @(
                'Improve module boundaries and separation of concerns',
                'Reduce coupling between components',
                'Enhance abstraction layers'
            )
            EstimatedHours = 16
            Priority = 'Medium'
            Impact = 'High'
            Dependencies = @('Phase 1 completion')
        }
    }
    
    if ($actions.Count -eq 0) {
        return @{ Actions = @() }
    }
    
    return @{
        Number = 2
        Name = 'High-Impact Improvements'
        Duration = '2-3 weeks'
        Description = 'Strategic refactoring and architectural improvements with maximum ROI'
        Actions = $actions
        TotalHours = ($actions | Measure-Object -Property EstimatedHours -Sum).Sum
        ExpectedOutcome = 'Significant improvement in code quality, maintainability, and developer productivity'
        SuccessCriteria = @(
            'Key refactoring opportunities addressed',
            'Architecture improved with better separation',
            'Technical debt reduced by 50%'
        )
    }
}

function Create-OptimizationPhase {
    <#
    .SYNOPSIS
    Creates the optimization and performance phase
    .PARAMETER Analyses
    Collection of codebase analyses
    #>
    [CmdletBinding()]
    param([hashtable]$Analyses)
    
    $actions = @()
    
    # Stabilize volatile components
    if ($Analyses.Evolution -and $Analyses.Evolution.Volatility -gt 50) {
        $actions += @{
            Action = 'Stabilize volatile components'
            Tasks = @(
                'Identify and analyze frequently changing modules',
                'Improve abstractions to reduce change impact',
                'Implement better error handling and recovery'
            )
            EstimatedHours = 16
            Priority = 'Medium'
            Impact = 'Medium'
            Dependencies = @('Phase 2 completion')
        }
    }
    
    # Performance optimization
    $actions += @{
        Action = 'Performance optimization'
        Tasks = @(
            'Profile and identify performance bottlenecks',
            'Optimize hot paths and critical algorithms',
            'Implement appropriate caching strategies',
            'Review and optimize database queries'
        )
        EstimatedHours = 20
        Priority = 'Medium'
        Impact = 'Medium'
        Dependencies = @('Phase 1 completion')
    }
    
    # Code standardization
    $actions += @{
        Action = 'Code standardization and consistency'
        Tasks = @(
            'Implement consistent coding standards',
            'Standardize error handling patterns',
            'Ensure consistent logging and monitoring'
        )
        EstimatedHours = 12
        Priority = 'Low'
        Impact = 'Medium'
        Dependencies = @()
    }
    
    return @{
        Number = 3
        Name = 'Optimization and Performance'
        Duration = '2-3 weeks'
        Description = 'Performance optimization and code standardization for long-term stability'
        Actions = $actions
        TotalHours = ($actions | Measure-Object -Property EstimatedHours -Sum).Sum
        ExpectedOutcome = 'Improved performance, stability, and consistent code quality'
        SuccessCriteria = @(
            'Performance benchmarks improved by 15-30%',
            'Code volatility reduced',
            'Consistent coding standards implemented'
        )
    }
}

function Create-DocumentationPhase {
    <#
    .SYNOPSIS
    Creates the documentation and testing phase
    .PARAMETER Analyses
    Collection of codebase analyses
    #>
    [CmdletBinding()]
    param([hashtable]$Analyses)
    
    $actions = @()
    
    # Documentation improvements
    $docHours = 20
    if ($Analyses.TechnicalDebt.Categories.ContainsKey('MissingDocumentation')) {
        $docHours = $Analyses.TechnicalDebt.Categories['MissingDocumentation']
    }
    
    $actions += @{
        Action = 'Complete documentation'
        Tasks = @(
            'Document all public APIs and interfaces',
            'Add inline comments for complex business logic',
            'Create architectural decision records (ADRs)',
            'Update README and setup documentation'
        )
        EstimatedHours = $docHours
        Priority = 'Low'
        Impact = 'Medium'
        Dependencies = @('Phase 2 completion')
    }
    
    # Test coverage improvements
    $actions += @{
        Action = 'Enhance test coverage'
        Tasks = @(
            'Add unit tests for critical business logic',
            'Implement integration tests for key workflows',
            'Add regression tests for previously fixed bugs',
            'Set up automated testing in CI/CD pipeline'
        )
        EstimatedHours = 24
        Priority = 'Medium'
        Impact = 'High'
        Dependencies = @('Phase 1 completion')
    }
    
    # Knowledge transfer and training
    $actions += @{
        Action = 'Knowledge transfer and team training'
        Tasks = @(
            'Conduct code walkthroughs for new team members',
            'Create troubleshooting guides',
            'Document common patterns and anti-patterns',
            'Set up pair programming sessions'
        )
        EstimatedHours = 8
        Priority = 'Low'
        Impact = 'Medium'
        Dependencies = @()
    }
    
    return @{
        Number = 4
        Name = 'Documentation and Testing'
        Duration = '1-2 weeks'
        Description = 'Comprehensive documentation and test coverage to ensure long-term maintainability'
        Actions = $actions
        TotalHours = ($actions | Measure-Object -Property EstimatedHours -Sum).Sum
        ExpectedOutcome = 'Complete documentation coverage and robust test suite'
        SuccessCriteria = @(
            'API documentation at 100% coverage',
            'Test coverage increased to 80%+',
            'Knowledge transfer completed'
        )
    }
}

function Create-ContinuousImprovementPhase {
    <#
    .SYNOPSIS
    Creates the continuous improvement phase
    #>
    [CmdletBinding()]
    param()
    
    $actions = @(
        @{
            Action = 'Establish code quality gates'
            Tasks = @(
                'Set up automated code analysis in CI/CD',
                'Configure quality gates for pull requests',
                'Implement automated testing requirements',
                'Set up code coverage monitoring'
            )
            EstimatedHours = 8
            Priority = 'Medium'
            Impact = 'High'
            Dependencies = @()
        }
        @{
            Action = 'Implement monitoring and metrics'
            Tasks = @(
                'Track code complexity trends over time',
                'Monitor code churn and hotspot patterns',
                'Set up automated technical debt reporting',
                'Create quality dashboards for stakeholders'
            )
            EstimatedHours = 6
            Priority = 'Low'
            Impact = 'Medium'
            Dependencies = @()
        }
        @{
            Action = 'Foster continuous learning culture'
            Tasks = @(
                'Regular code review sessions and retrospectives',
                'Share knowledge through tech talks and documentation',
                'Establish coding standards and best practices',
                'Encourage experimentation and innovation'
            )
            EstimatedHours = 4
            Priority = 'Low'
            Impact = 'High'
            Dependencies = @()
        }
    )
    
    return @{
        Number = 5
        Name = 'Continuous Improvement'
        Duration = 'Ongoing'
        Description = 'Sustainable practices for maintaining and improving code quality over time'
        Actions = $actions
        TotalHours = ($actions | Measure-Object -Property EstimatedHours -Sum).Sum
        ExpectedOutcome = 'Sustainable code quality improvements and team practices'
        SuccessCriteria = @(
            'Quality gates preventing regression',
            'Regular metrics monitoring in place',
            'Team following consistent practices'
        )
    }
}

function Calculate-ExpectedROI {
    <#
    .SYNOPSIS
    Calculates expected return on investment for the improvement roadmap
    .PARAMETER TotalEffort
    Total effort hours for the roadmap
    .PARAMETER Analyses
    Collection of codebase analyses
    #>
    [CmdletBinding()]
    param(
        [int]$TotalEffort,
        [hashtable]$Analyses
    )
    
    $currentMaintenanceCost = if ($Analyses.Maintenance -and $Analyses.Maintenance.Score -gt 50) { 
        $Analyses.Maintenance.Score * 0.5  # Hours per month
    } else { 10 }
    
    $projectedSavings = [Math]::Round($TotalEffort * 0.25, 0)  # 25% of effort as monthly savings
    $bugReduction = switch ($Analyses.Maintenance.RiskLevel) {
        'Critical' { '50-70%' }
        'High' { '30-50%' }
        'Medium' { '20-40%' }
        default { '15-30%' }
    }
    
    $velocityImprovement = if ($TotalEffort -gt 100) { '20-35%' } 
                          elseif ($TotalEffort -gt 50) { '15-25%' } 
                          else { '10-20%' }
    
    return @{
        ReducedMaintenanceTime = "$projectedSavings hours/month saved"
        ReducedBugRate = "$bugReduction reduction expected"
        ImprovedVelocity = "$velocityImprovement increase in feature delivery"
        TeamSatisfaction = "Improved developer experience and reduced frustration"
        BreakEvenPeriod = "$([Math]::Round($TotalEffort / $projectedSavings, 1)) months"
        YearlyROI = "$([Math]::Round((($projectedSavings * 12 - $TotalEffort) / $TotalEffort) * 100, 0))%"
    }
}

function Define-SuccessMetrics {
    <#
    .SYNOPSIS
    Defines success metrics and targets for the roadmap
    .PARAMETER Analyses
    Collection of codebase analyses
    #>
    [CmdletBinding()]
    param([hashtable]$Analyses)
    
    $metrics = @(
        'Code complexity reduced by 30%',
        'Test coverage increased to 80%',
        'Critical and high-severity code smells eliminated',
        'Documentation coverage at 100% for public APIs',
        'Technical debt reduced by 60%',
        'Code review process established with 100% coverage'
    )
    
    $targets = @()
    
    # Code smell targets
    if ($Analyses.CodeSmells) {
        $targets += @{
            Metric = 'Code Smell Score'
            Current = $Analyses.CodeSmells.Score
            Target = [Math]::Round($Analyses.CodeSmells.Score * 0.3, 1)
            Unit = 'points'
        }
        
        $targets += @{
            Metric = 'High-Severity Smells'
            Current = $Analyses.CodeSmells.Summary.High
            Target = 0
            Unit = 'count'
        }
    }
    
    # Technical debt targets
    if ($Analyses.TechnicalDebt) {
        $targets += @{
            Metric = 'Technical Debt Hours'
            Current = $Analyses.TechnicalDebt.TotalHours
            Target = [Math]::Round($Analyses.TechnicalDebt.TotalHours * 0.4, 0)
            Unit = 'hours'
        }
    }
    
    # Maintenance targets
    if ($Analyses.Maintenance) {
        $targets += @{
            Metric = 'Maintenance Risk Level'
            Current = $Analyses.Maintenance.RiskLevel
            Target = if ($Analyses.Maintenance.RiskLevel -in @('Critical', 'High')) { 'Medium' } else { 'Low' }
            Unit = 'level'
        }
    }
    
    return @{
        Metrics = $metrics
        Targets = $targets
        ReviewSchedule = 'Monthly progress reviews with quarterly comprehensive assessments'
    }
}

function Get-LLMRoadmapRecommendations {
    <#
    .SYNOPSIS
    Gets LLM-generated strategic recommendations
    .PARAMETER Roadmap
    The roadmap object
    .PARAMETER Analyses
    Collection of analyses
    #>
    [CmdletBinding()]
    param(
        [hashtable]$Roadmap,
        [hashtable]$Analyses
    )
    
    $llmPrompt = @"
Based on this code improvement roadmap analysis:

Project: $($Roadmap.Path)
Total Effort: $($Roadmap.TotalEffort) hours across $($Roadmap.Phases.Count) phases

Current State:
- Maintenance Risk: $($Analyses.Maintenance.RiskLevel)
- Technical Debt: $($Analyses.TechnicalDebt.TotalHours) hours
- Code Smells: $($Analyses.CodeSmells.Summary.Total) total ($($Analyses.CodeSmells.Summary.High) high-severity)
- Refactoring Opportunities: $($Roadmap.AnalysisInputs.RefactoringOpportunities)

Expected ROI: $($Roadmap.ExpectedROI.YearlyROI) yearly return

Provide 3 strategic recommendations for maximizing the success of this improvement initiative, focusing on:
1. Risk mitigation and prioritization
2. Team adoption and change management
3. Long-term sustainability

Keep each recommendation concise (2-3 sentences) and actionable.
"@
    
    try {
        $llmResponse = Invoke-OllamaGenerate -Prompt $llmPrompt -MaxTokens 600
        if ($llmResponse -and $llmResponse.Success) {
            return $llmResponse.Response
        }
    }
    catch {
        Write-Warning "Could not get LLM recommendations: $_"
    }
    
    return "LLM recommendations not available. Consider consulting with technical leads and stakeholders for strategic guidance."
}

function Export-RoadmapReport {
    <#
    .SYNOPSIS
    Exports roadmap to various formats
    .DESCRIPTION
    Generates comprehensive reports in HTML, Markdown, or JSON formats
    .PARAMETER Roadmap
    The roadmap hashtable to export
    .PARAMETER OutputPath
    Path where to save the report
    .PARAMETER Format
    Export format (HTML, Markdown, JSON)
    .EXAMPLE
    Export-RoadmapReport -Roadmap $roadmap -OutputPath ".\roadmap.html" -Format HTML
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Roadmap,
        
        [string]$OutputPath = ".\ImprovementRoadmap.html",
        
        [ValidateSet('HTML', 'Markdown', 'JSON')]
        [string]$Format = 'HTML'
    )
    
    Write-Verbose "Exporting roadmap report to $OutputPath (Format: $Format)"
    
    try {
        switch ($Format) {
            'JSON' {
                $Roadmap | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            
            'Markdown' {
                $markdown = Generate-MarkdownReport -Roadmap $Roadmap
                $markdown | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            
            'HTML' {
                $html = Generate-HTMLReport -Roadmap $Roadmap
                $html | Out-File -FilePath $OutputPath -Encoding UTF8
            }
        }
        
        Write-Verbose "Roadmap report exported successfully to $OutputPath"
        return $OutputPath
    }
    catch {
        Write-Error "Failed to export roadmap report: $_"
        return $null
    }
}

function Generate-MarkdownReport {
    <#
    .SYNOPSIS
    Generates markdown format report
    .PARAMETER Roadmap
    The roadmap to convert to markdown
    #>
    [CmdletBinding()]
    param([hashtable]$Roadmap)
    
    $markdown = @"
# Code Improvement Roadmap

**Project**: $($Roadmap.Path)  
**Created**: $($Roadmap.CreatedDate)  
**Total Effort**: $($Roadmap.TotalEffort) hours  
**Expected ROI**: $($Roadmap.ExpectedROI.YearlyROI) yearly return

## Executive Summary

This roadmap outlines a comprehensive $($Roadmap.Phases.Count)-phase improvement plan designed to enhance code quality, reduce technical debt, and improve maintainability.

### Current State Analysis
- **Maintenance Risk**: $($Roadmap.AnalysisInputs.MaintenanceRisk)
- **Technical Debt**: $($Roadmap.AnalysisInputs.TechnicalDebtHours) hours
- **Code Smells**: $($Roadmap.AnalysisInputs.CodeSmellCount) identified
- **Refactoring Opportunities**: $($Roadmap.AnalysisInputs.RefactoringOpportunities) found

## Implementation Phases

"@
    
    foreach ($phase in $Roadmap.Phases) {
        $markdown += @"

### Phase $($phase.Number): $($phase.Name)
**Duration**: $($phase.Duration) | **Total Effort**: $($phase.TotalHours) hours

$($phase.Description)

**Expected Outcome**: $($phase.ExpectedOutcome)

#### Actions:
"@
        foreach ($action in $phase.Actions) {
            $markdown += @"

- **$($action.Action)** [$($action.Priority) Priority] - $($action.EstimatedHours) hours
"@
            foreach ($task in $action.Tasks) {
                $markdown += "  - $task`n"
            }
        }
        
        $markdown += "`n**Success Criteria:**`n"
        foreach ($criteria in $phase.SuccessCriteria) {
            $markdown += "- $criteria`n"
        }
    }
    
    $markdown += @"

## Expected Return on Investment

| Metric | Value |
|--------|-------|
| Reduced Maintenance Time | $($Roadmap.ExpectedROI.ReducedMaintenanceTime) |
| Reduced Bug Rate | $($Roadmap.ExpectedROI.ReducedBugRate) |
| Improved Velocity | $($Roadmap.ExpectedROI.ImprovedVelocity) |
| Break-Even Period | $($Roadmap.ExpectedROI.BreakEvenPeriod) |
| Yearly ROI | $($Roadmap.ExpectedROI.YearlyROI) |

## Success Metrics & Targets

| Metric | Current | Target | Unit |
|--------|---------|--------|------|
"@
    
    foreach ($target in $Roadmap.Success.Targets) {
        $markdown += "| $($target.Metric) | $($target.Current) | $($target.Target) | $($target.Unit) |`n"
    }
    
    if ($Roadmap.StrategicRecommendations) {
        $markdown += @"

## Strategic Recommendations

$($Roadmap.StrategicRecommendations)
"@
    }
    
    return $markdown
}

function Generate-HTMLReport {
    <#
    .SYNOPSIS
    Generates HTML format report
    .PARAMETER Roadmap
    The roadmap to convert to HTML
    #>
    [CmdletBinding()]
    param([hashtable]$Roadmap)
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Code Improvement Roadmap - $($Roadmap.Path)</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; line-height: 1.6; color: #333; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 10px; margin-bottom: 30px; }
        h1 { margin: 0; font-size: 2.5em; }
        h2 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; margin-top: 30px; }
        h3 { color: #34495e; margin-top: 25px; }
        .summary { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 5px solid #3498db; }
        .phase { background: #fff; padding: 20px; margin: 20px 0; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .phase-header { background: #ecf0f1; padding: 15px; margin: -20px -20px 20px -20px; border-radius: 8px 8px 0 0; }
        .priority-critical { color: #c0392b; font-weight: bold; }
        .priority-high { color: #e74c3c; font-weight: bold; }
        .priority-medium { color: #f39c12; font-weight: bold; }
        .priority-low { color: #27ae60; }
        .action { background: #f1f2f6; padding: 15px; margin: 10px 0; border-radius: 5px; border-left: 4px solid #3498db; }
        .roi-section { background: #d5f4e6; padding: 20px; border-radius: 8px; margin: 20px 0; }
        .metrics-table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        .metrics-table th { background: #3498db; color: white; padding: 12px; text-align: left; }
        .metrics-table td { padding: 12px; border: 1px solid #ddd; }
        .metrics-table tr:nth-child(even) { background: #f9f9f9; }
        .progress-indicator { display: inline-block; width: 20px; height: 20px; border-radius: 50%; margin-right: 10px; }
        .phase-1 { background: #e74c3c; }
        .phase-2 { background: #f39c12; }
        .phase-3 { background: #3498db; }
        .phase-4 { background: #9b59b6; }
        .phase-5 { background: #27ae60; }
        .recommendations { background: #fff3cd; padding: 20px; border-radius: 8px; border-left: 5px solid #ffc107; margin: 20px 0; }
        ul, ol { padding-left: 20px; }
        li { margin: 5px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Code Improvement Roadmap</h1>
        <p><strong>Project:</strong> $($Roadmap.Path)</p>
        <p><strong>Created:</strong> $($Roadmap.CreatedDate) | <strong>Total Effort:</strong> $($Roadmap.TotalEffort) hours | <strong>Expected ROI:</strong> $($Roadmap.ExpectedROI.YearlyROI)</p>
    </div>
    
    <div class="summary">
        <h2>Executive Summary</h2>
        <p>This roadmap outlines a comprehensive $($Roadmap.Phases.Count)-phase improvement plan designed to enhance code quality, reduce technical debt, and improve maintainability.</p>
        
        <h3>Current State Analysis</h3>
        <ul>
            <li><strong>Maintenance Risk:</strong> $($Roadmap.AnalysisInputs.MaintenanceRisk)</li>
            <li><strong>Technical Debt:</strong> $($Roadmap.AnalysisInputs.TechnicalDebtHours) hours</li>
            <li><strong>Code Smells:</strong> $($Roadmap.AnalysisInputs.CodeSmellCount) identified</li>
            <li><strong>Refactoring Opportunities:</strong> $($Roadmap.AnalysisInputs.RefactoringOpportunities) found</li>
        </ul>
    </div>

    <h2>Implementation Phases</h2>
"@
    
    foreach ($phase in $Roadmap.Phases) {
        $phaseClass = "phase-$($phase.Number)"
        $html += @"
    <div class="phase">
        <div class="phase-header">
            <h3><span class="progress-indicator $phaseClass"></span>Phase $($phase.Number): $($phase.Name)</h3>
            <p><strong>Duration:</strong> $($phase.Duration) | <strong>Total Effort:</strong> $($phase.TotalHours) hours</p>
        </div>
        
        <p><strong>Description:</strong> $($phase.Description)</p>
        <p><strong>Expected Outcome:</strong> $($phase.ExpectedOutcome)</p>
        
        <h4>Actions:</h4>
"@
        
        foreach ($action in $phase.Actions) {
            $priorityClass = "priority-$($action.Priority.ToLower())"
            $html += @"
        <div class="action">
            <h5><span class="$priorityClass">[$($action.Priority)]</span> $($action.Action) - $($action.EstimatedHours) hours</h5>
            <ul>
"@
            foreach ($task in $action.Tasks) {
                $html += "                <li>$task</li>`n"
            }
            $html += "            </ul>`n"
            
            if ($action.Dependencies -and $action.Dependencies.Count -gt 0) {
                $html += "            <p><strong>Dependencies:</strong> $($action.Dependencies -join ', ')</p>`n"
            }
            $html += "        </div>`n"
        }
        
        $html += @"
        <h4>Success Criteria:</h4>
        <ul>
"@
        foreach ($criteria in $phase.SuccessCriteria) {
            $html += "            <li>$criteria</li>`n"
        }
        $html += "        </ul>`n    </div>`n"
    }
    
    $html += @"
    
    <div class="roi-section">
        <h2>Expected Return on Investment</h2>
        <table class="metrics-table">
            <tr><th>Metric</th><th>Value</th></tr>
            <tr><td>Reduced Maintenance Time</td><td>$($Roadmap.ExpectedROI.ReducedMaintenanceTime)</td></tr>
            <tr><td>Reduced Bug Rate</td><td>$($Roadmap.ExpectedROI.ReducedBugRate)</td></tr>
            <tr><td>Improved Velocity</td><td>$($Roadmap.ExpectedROI.ImprovedVelocity)</td></tr>
            <tr><td>Break-Even Period</td><td>$($Roadmap.ExpectedROI.BreakEvenPeriod)</td></tr>
            <tr><td>Team Satisfaction</td><td>$($Roadmap.ExpectedROI.TeamSatisfaction)</td></tr>
        </table>
    </div>
    
    <h2>Success Metrics &amp; Targets</h2>
    <table class="metrics-table">
        <tr><th>Metric</th><th>Current</th><th>Target</th><th>Unit</th></tr>
"@
    
    foreach ($target in $Roadmap.Success.Targets) {
        $html += "        <tr><td>$($target.Metric)</td><td>$($target.Current)</td><td>$($target.Target)</td><td>$($target.Unit)</td></tr>`n"
    }
    
    $html += "    </table>`n"
    
    if ($Roadmap.StrategicRecommendations) {
        $html += @"
    <div class="recommendations">
        <h2>Strategic Recommendations</h2>
        <p>$($Roadmap.StrategicRecommendations -replace "`n", "<br>")</p>
    </div>
"@
    }
    
    $html += @"
    
    <div class="summary">
        <p><strong>Review Schedule:</strong> $($Roadmap.Success.ReviewSchedule)</p>
        <p><em>This roadmap should be reviewed and updated regularly based on progress and changing requirements.</em></p>
    </div>
</body>
</html>
"@
    
    return $html
}

# Export functions
Export-ModuleMember -Function @(
    'New-ImprovementRoadmap',
    'Export-RoadmapReport'
)

Write-Verbose "ImprovementRoadmaps component loaded successfully"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDW116O0Z8tTDlY
# wirUf3wwKk/Qbyl/Ro7BFY/89MZhVaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJzKcSj8plbxoMXnVCNOrW0U
# A1+iNWVIIJhL4xoiDdvdMA0GCSqGSIb3DQEBAQUABIIBADMnT7HqkhnTNV+/4bkJ
# YGW291dbD8HgunjRHZvMP5ypoXcqLKjWw3ZWSspjtbH+5AgZKyO5Nnl31Vp6fsoz
# omPwA8sPCFMXZrR3TtNwNqwspCuxTtG01wDdyw2NXOvzObrcdLVmX2R1zLtKg9iT
# 7BYP9qKM4IfyUdoLeyca6JVLo/qNTn/TeAokxz9aXwvsrEyHrFS/bC9NuRGx60lD
# bG21WuMG4cdQH5Q1xK4fXd+IJ+c+4aqj+j93aspS232+Iya1d4xLHVRJR+qWLeq8
# 33C6nq2SBiYMuHzcA8eBleKddphv+vmlkuVOINT4RB+ht1RRW+lsJCKUYY2AZKku
# 0iA=
# SIG # End signature block
