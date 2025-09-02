#region Unity-Claude-PredictiveAnalysis Orchestrator Module

# Module self-registration for session visibility
if (-not $ExecutionContext.SessionState.Module) {
    $ModuleName = 'Unity-Claude-PredictiveAnalysis'
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
    Unity Claude Predictive Analysis - Main Orchestrator Module
    
.DESCRIPTION
    Refactored modular architecture for Unity-Claude-PredictiveAnalysis providing:
    
    CORE COMPONENTS:
    - PredictiveCore.psm1: Core initialization, cache management, shared utilities
    - TrendAnalysis.psm1: Code evolution trends, churn analysis, hotspot detection
    - MaintenancePrediction.psm1: Maintenance prediction scoring, technical debt calculation
    - RefactoringDetection.psm1: Refactoring opportunity identification and analysis
    - CodeSmellPrediction.psm1: Code smell detection with confidence scoring
    - ImprovementRoadmaps.psm1: Comprehensive roadmap generation and planning
    - RiskAssessment.psm1: Bug probability prediction, maintenance risk assessment
    - AnalyticsReporting.psm1: ROI analysis, historical metrics, reporting
    
    CAPABILITIES:
    - Predictive maintenance analysis with ML-based scoring
    - Code evolution and churn trend analysis 
    - Refactoring opportunity detection and prioritization
    - Code smell prediction with remediation guidance
    - Technical debt quantification and tracking
    - Risk assessment for bugs and maintenance overhead
    - ROI analysis for improvement initiatives
    - Historical metrics collection and trend analysis
    - Multi-format reporting (HTML, Markdown, JSON, CSV)
    
.VERSION
    2.0.0 - Refactored modular architecture
    
.DEPENDENCIES
    - Unity-Claude-CPG (Code Property Graph analysis)
    - Unity-Claude-Cache (Performance optimization)
    - Unity-Claude-LLM (Language model integration)
    - Git (Version control integration)
    
.AUTHOR
    Unity-Claude-Automation Framework
#>

# Import all core components
$ComponentPath = Join-Path $PSScriptRoot 'Core'

Write-Verbose "Loading Unity-Claude-PredictiveAnalysis components from $ComponentPath"

try {
    # Import core components in dependency order
    $Components = @(
        'PredictiveCore.psm1',
        'TrendAnalysis.psm1', 
        'MaintenancePrediction.psm1',
        'RefactoringDetection.psm1',
        'CodeSmellPrediction.psm1',
        'ImprovementRoadmaps.psm1',
        'RiskAssessment.psm1',
        'AnalyticsReporting.psm1'
    )
    
    foreach ($Component in $Components) {
        $ComponentFile = Join-Path $ComponentPath $Component
        if (Test-Path $ComponentFile) {
            Import-Module $ComponentFile -Force -Global
            Write-Verbose "Imported component: $Component"
        } else {
            Write-Warning "Component not found: $ComponentFile"
        }
    }
    
    Write-Verbose "All Unity-Claude-PredictiveAnalysis components loaded successfully"
}
catch {
    Write-Error "Failed to load Unity-Claude-PredictiveAnalysis components: $_"
    throw
}

#region Orchestrator Functions

function Initialize-PredictiveAnalysis {
    <#
    .SYNOPSIS
        Initializes the predictive analysis system with all components
        
    .DESCRIPTION
        Sets up the cache, initializes prediction models, and prepares the system
        for analysis operations across all components
        
    .PARAMETER CacheSize
        Maximum number of cache entries (default: 100)
        
    .PARAMETER EnableLLM
        Enable Language Model integration for advanced analysis
        
    .OUTPUTS
        System.Boolean
        True if initialization successful, False otherwise
        
    .EXAMPLE
        $initialized = Initialize-PredictiveAnalysis -CacheSize 200 -EnableLLM
        if ($initialized) { Write-Host "System ready for analysis" }
    #>
    [CmdletBinding()]
    param(
        [int]$CacheSize = 100,
        [switch]$EnableLLM
    )
    
    Write-Verbose "Initializing Unity-Claude-PredictiveAnalysis system"
    
    try {
        # Initialize core components
        Initialize-PredictiveCache -MaxSize $CacheSize
        
        # Initialize prediction models
        $script:PredictionModels = @{
            MaintenanceModel = @{
                Weights = @{
                    Complexity = 0.3
                    Churn = 0.25  
                    Size = 0.2
                    Age = 0.15
                    BugHistory = 0.1
                }
            }
            RefactoringModel = @{
                Thresholds = @{
                    MethodLength = 50
                    ClassSize = 500
                    CyclomaticComplexity = 10
                    DuplicationRatio = 0.1
                }
            }
            SmellModel = @{
                Weights = @{
                    LongMethod = 0.3
                    LargeClass = 0.25
                    DeadCode = 0.2
                    Duplication = 0.15
                    ComplexConditions = 0.1
                }
            }
        }
        
        if ($EnableLLM) {
            Write-Verbose "LLM integration enabled for advanced analysis"
            $script:LLMEnabled = $true
        }
        
        Write-Host "Unity-Claude-PredictiveAnalysis initialized successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to initialize predictive analysis system: $_"
        return $false
    }
}

function Get-ComprehensiveAnalysis {
    <#
    .SYNOPSIS
        Performs comprehensive analysis across all prediction components
        
    .DESCRIPTION
        Orchestrates analysis across trend analysis, maintenance prediction,
        refactoring detection, code smell prediction, and risk assessment
        
    .PARAMETER Path
        File system path to analyze
        
    .PARAMETER Graph
        Optional Code Property Graph for enhanced analysis
        
    .PARAMETER IncludeRoadmap
        Include improvement roadmap generation (default: true)
        
    .PARAMETER IncludeROI
        Include ROI analysis for recommendations (default: true)
        
    .OUTPUTS
        System.Collections.Hashtable
        Comprehensive analysis results from all components
        
    .EXAMPLE
        $analysis = Get-ComprehensiveAnalysis -Path "C:\Project\src" -IncludeRoadmap -IncludeROI
        Write-Host "Overall risk level: $($analysis.OverallRisk)"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        $Graph = $null,
        
        [switch]$IncludeRoadmap = $true,
        [switch]$IncludeROI = $true
    )
    
    Write-Verbose "Performing comprehensive analysis for $Path"
    
    try {
        $analysis = @{
            Path = $Path
            Timestamp = Get-Date
            Components = @{}
        }
        
        # Trend Analysis
        Write-Progress -Activity "Comprehensive Analysis" -Status "Analyzing trends" -PercentComplete 10
        $analysis.Components.TrendAnalysis = @{
            Evolution = Get-CodeEvolutionTrend -Path $Path -DaysBack 90
            Churn = Measure-CodeChurn -Path $Path -DaysBack 30  
            Hotspots = Find-CodeHotspots -Path $Path -Graph $Graph
        }
        
        # Maintenance Prediction
        Write-Progress -Activity "Comprehensive Analysis" -Status "Predicting maintenance" -PercentComplete 25
        $analysis.Components.MaintenancePrediction = Get-MaintenancePrediction -Path $Path -Graph $Graph
        
        # Refactoring Detection
        Write-Progress -Activity "Comprehensive Analysis" -Status "Detecting refactoring opportunities" -PercentComplete 40
        if ($Graph) {
            $analysis.Components.RefactoringDetection = Find-RefactoringOpportunities -Graph $Graph
        }
        
        # Code Smell Prediction
        Write-Progress -Activity "Comprehensive Analysis" -Status "Predicting code smells" -PercentComplete 55
        if ($Graph) {
            $analysis.Components.CodeSmellPrediction = Predict-CodeSmells -Graph $Graph
        }
        
        # Risk Assessment  
        Write-Progress -Activity "Comprehensive Analysis" -Status "Assessing risks" -PercentComplete 70
        $analysis.Components.RiskAssessment = @{
            BugProbability = Predict-BugProbability -Path $Path -Graph $Graph
            MaintenanceRisk = Get-MaintenanceRisk -Path $Path
        }
        
        # Improvement Roadmap
        if ($IncludeRoadmap) {
            Write-Progress -Activity "Comprehensive Analysis" -Status "Generating roadmap" -PercentComplete 85
            $analysis.Components.ImprovementRoadmap = New-ImprovementRoadmap -Path $Path -Graph $Graph
        }
        
        # ROI Analysis
        if ($IncludeROI -and $analysis.Components.ImprovementRoadmap) {
            Write-Progress -Activity "Comprehensive Analysis" -Status "Analyzing ROI" -PercentComplete 95
            $analysis.Components.ROIAnalysis = Get-ROIAnalysis -Roadmap $analysis.Components.ImprovementRoadmap
        }
        
        # Calculate overall risk and priority
        $analysis.OverallRisk = Calculate-OverallRisk -Analysis $analysis
        $analysis.TopPriorities = Get-TopPriorities -Analysis $analysis
        
        Write-Progress -Activity "Comprehensive Analysis" -Status "Complete" -PercentComplete 100
        Write-Host "Comprehensive analysis completed successfully" -ForegroundColor Green
        
        return $analysis
    }
    catch {
        Write-Error "Failed to perform comprehensive analysis: $_"
        return $null
    }
}

function Calculate-OverallRisk {
    <#
    .SYNOPSIS
        Calculates overall risk level from analysis components
        
    .DESCRIPTION
        Aggregates risk indicators from all analysis components to provide
        a unified risk assessment for the analyzed codebase
        
    .PARAMETER Analysis
        Comprehensive analysis results hashtable
        
    .OUTPUTS
        System.String
        Overall risk level: Critical, High, Medium, or Low
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Analysis
    )
    
    try {
        $riskFactors = @()
        
        # Maintenance risk
        if ($Analysis.Components.MaintenancePrediction) {
            $riskFactors += $Analysis.Components.MaintenancePrediction.RiskLevel
        }
        
        # Bug probability risk
        if ($Analysis.Components.RiskAssessment -and $Analysis.Components.RiskAssessment.BugProbability) {
            $riskFactors += $Analysis.Components.RiskAssessment.BugProbability.Risk
        }
        
        # Code smell risk
        if ($Analysis.Components.CodeSmellPrediction) {
            $smellScore = $Analysis.Components.CodeSmellPrediction.Score
            $smellRisk = if ($smellScore -gt 75) { 'Critical' }
                        elseif ($smellScore -gt 50) { 'High' }
                        elseif ($smellScore -gt 25) { 'Medium' }
                        else { 'Low' }
            $riskFactors += $smellRisk
        }
        
        # Calculate overall risk
        $criticalCount = ($riskFactors | Where-Object { $_ -eq 'Critical' }).Count
        $highCount = ($riskFactors | Where-Object { $_ -eq 'High' }).Count
        
        if ($criticalCount -gt 0) { return 'Critical' }
        if ($highCount -ge 2) { return 'High' }
        if ($highCount -ge 1) { return 'Medium' }
        return 'Low'
    }
    catch {
        Write-Warning "Could not calculate overall risk: $_"
        return 'Unknown'
    }
}

function Get-TopPriorities {
    <#
    .SYNOPSIS
        Extracts top priority items from comprehensive analysis
        
    .DESCRIPTION
        Identifies the most critical issues and opportunities from all analysis
        components and ranks them by priority and impact
        
    .PARAMETER Analysis
        Comprehensive analysis results hashtable
        
    .OUTPUTS
        System.Collections.Hashtable[]
        Array of top priority items with recommendations
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Analysis
    )
    
    try {
        $priorities = @()
        
        # High-risk refactoring opportunities
        if ($Analysis.Components.RefactoringDetection) {
            $highImpact = $Analysis.Components.RefactoringDetection | Where-Object { $_.Impact -eq 'High' }
            foreach ($opportunity in $highImpact) {
                $priorities += @{
                    Type = 'Refactoring'
                    Priority = 'High'
                    Description = $opportunity.Reason
                    Target = $opportunity.Target
                    Effort = $opportunity.Effort
                }
            }
        }
        
        # Critical code smells
        if ($Analysis.Components.CodeSmellPrediction) {
            $criticalSmells = $Analysis.Components.CodeSmellPrediction.Smells | Where-Object { $_.Severity -eq 'Critical' }
            foreach ($smell in $criticalSmells) {
                $priorities += @{
                    Type = 'CodeSmell'
                    Priority = 'Critical'
                    Description = $smell.Type
                    Target = $smell.Target
                    Fix = $smell.Fix
                }
            }
        }
        
        # High bug probability areas
        if ($Analysis.Components.RiskAssessment.BugProbability -and 
            $Analysis.Components.RiskAssessment.BugProbability.Risk -eq 'High') {
            $priorities += @{
                Type = 'BugRisk'
                Priority = 'High'
                Description = 'High bug probability detected'
                Target = $Analysis.Path
                Recommendation = $Analysis.Components.RiskAssessment.BugProbability.Recommendation
            }
        }
        
        return $priorities | Sort-Object @{Expression={@{'Critical'=0;'High'=1;'Medium'=2;'Low'=3}[$_.Priority]}}
    }
    catch {
        Write-Warning "Could not extract top priorities: $_"
        return @()
    }
}

#endregion Orchestrator Functions

#region Export Configuration

# Export all public functions from components and orchestrator
$ExportedFunctions = @(
    # Core Functions
    'Initialize-PredictiveCache', 'Clear-PredictiveCache', 'Get-CacheStats',
    
    # Trend Analysis Functions  
    'Get-CodeEvolutionTrend', 'Measure-CodeChurn', 'Find-CodeHotspots',
    
    # Maintenance Prediction Functions
    'Get-MaintenancePrediction', 'Calculate-TechnicalDebt', 'Get-MaintenanceScore',
    
    # Refactoring Detection Functions
    'Find-RefactoringOpportunities', 'Find-LongMethods', 'Find-LargeClasses', 
    'Get-DuplicationCandidates', 'Find-DeadCode',
    
    # Code Smell Prediction Functions  
    'Predict-CodeSmells', 'Get-SmellDetails', 'Get-RemediationAdvice',
    
    # Improvement Roadmap Functions
    'New-ImprovementRoadmap', 'Export-RoadmapReport', 'Get-RoadmapPhases',
    
    # Risk Assessment Functions
    'Predict-BugProbability', 'Get-MaintenanceRisk', 'Find-AntiPatterns', 'Get-DesignFlaws',
    
    # Analytics & Reporting Functions  
    'Get-ROIAnalysis', 'Get-HistoricalMetrics', 'Get-ComplexityTrend',
    'Get-CommitFrequency', 'Get-AuthorContributions', 'Update-PredictionModels',
    'Estimate-RefactoringEffort', 'Get-PriorityActions', 'Get-CouplingIssues',
    
    # Orchestrator Functions
    'Initialize-PredictiveAnalysis', 'Get-ComprehensiveAnalysis'
)

# Export functions and aliases for backward compatibility
Export-ModuleMember -Function $ExportedFunctions -Alias @('gct', 'gmp', 'fro', 'pcs', 'nir')

Write-Host "Unity-Claude-PredictiveAnalysis v2.0.0 (Refactored) loaded successfully" -ForegroundColor Green
Write-Host "Components: PredictiveCore | TrendAnalysis | MaintenancePrediction | RefactoringDetection" -ForegroundColor Cyan
Write-Host "           CodeSmellPrediction | ImprovementRoadmaps | RiskAssessment | AnalyticsReporting" -ForegroundColor Cyan
Write-Host "Functions exported: $($ExportedFunctions.Count)" -ForegroundColor Yellow

#endregion Export Configuration

#endregion Unity-Claude-PredictiveAnalysis Orchestrator Module

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBzvZFi85y3tC86
# b3w/iEraiAv35kgp+7dte+UzN3uyIKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBvI55B9uMctvgMBZc1oDADb
# c8d/0xOCtj378ews48MeMA0GCSqGSIb3DQEBAQUABIIBAEc1zqbuaNVB5Ty79KP0
# bUl5jrS/r/XmwDVbNboiSVWn9uTxkC8BOm7KGM7iT0Oz1nVae/fush6HqMtYgndi
# hYuoZ+U6aUghTtJuHK4FYpimIk4AdSwgWtFwqfFD1BlhlwIPQwAvmvMILEYDZFyV
# MhaVN4lTdgkwT7G3KiMkKDj9gXX7EGZn1v3PibV44tJDSoNnpnFRTYrCJkx6W+tk
# +2jYCl2BB6QbdN7bLiZ6VntYoiXX0f7kH4REW4NnezzGPUAbKda9rpYtRItybU4B
# RVOK7a21oHyDnKnEylThLn9B0NZTp+8Xeau7bmUSoWKlIg3v0XmsnQYMTCYEO7X3
# BYc=
# SIG # End signature block
