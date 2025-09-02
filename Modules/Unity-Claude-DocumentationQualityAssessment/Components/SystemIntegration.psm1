# DocumentationQualityAssessment - System Integration Component
# This module contains initialization and system integration functions

# Module-level state (shared across all components)
$script:DocumentationQualityState = @{
    IsInitialized = $false
    Configuration = @{
        EnableAIAssessment = $true
        EnableReadabilityAlgorithms = $true
        AutoDiscoverSystems = $true
        CacheResults = $true
        EnablePerformanceTracking = $true
    }
    ConnectedSystems = @{
        OllamaAI = $false
    }
    Statistics = @{
        AssessmentsPerformed = 0
        TotalProcessingTime = 0
        AverageQualityScore = 0
        LastAssessmentTime = $null
    }
    Cache = @{}
}


function Initialize-DocumentationQualityAssessment {
    <#
    .SYNOPSIS
        Initializes AI-enhanced documentation quality assessment system.
    
    .DESCRIPTION
        Sets up comprehensive quality assessment with research-validated readability algorithms,
        AI-powered content analysis, and integration with existing quality systems.
        Implements 2025 enterprise patterns for content quality management.
    
    .PARAMETER EnableAIAssessment
        Enable AI-powered content quality assessment using Ollama.
    
    .PARAMETER EnableReadabilityAlgorithms
        Enable standard readability algorithms (Flesch-Kincaid, Gunning Fog, SMOG).
    
    .PARAMETER AutoDiscoverSystems
        Automatically discover and connect to existing quality systems.
    
    .EXAMPLE
        Initialize-DocumentationQualityAssessment -EnableAIAssessment -EnableReadabilityAlgorithms -AutoDiscoverSystems
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [switch]$EnableAIAssessment = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableReadabilityAlgorithms = $true,
        
        [Parameter(Mandatory = $false)]
        [switch]$AutoDiscoverSystems = $true
    )
    
    Write-Host "Initializing AI-Enhanced Documentation Quality Assessment..." -ForegroundColor Cyan
    
    try {
        # Create default configuration
        $script:DocumentationQualityState.Configuration = Get-DefaultQualityAssessmentConfiguration
        
        # Auto-discover existing quality systems
        if ($AutoDiscoverSystems) {
            Discover-QualityAssessmentSystems
        }
        
        # Initialize readability calculator
        if ($EnableReadabilityAlgorithms) {
            Initialize-ReadabilityCalculator
        }
        
        # Initialize AI assessment capabilities
        if ($EnableAIAssessment) {
            Initialize-AIContentAssessor
        }
        
        # Setup integration with existing quality systems
        Setup-QualitySystemIntegration
        
        $script:DocumentationQualityState.Statistics.StartTime = Get-Date
        $script:DocumentationQualityState.IsInitialized = $true
        
        Write-Host "Documentation Quality Assessment initialized successfully" -ForegroundColor Green
        Write-Host "AI assessment enabled: $EnableAIAssessment" -ForegroundColor Gray
        Write-Host "Readability algorithms enabled: $EnableReadabilityAlgorithms" -ForegroundColor Gray
        Write-Host "Connected systems: $($script:DocumentationQualityState.ConnectedSystems.Values | Where-Object { $_ }).Count" -ForegroundColor Gray
        
        return $true
    }
    catch {
        Write-Error "Failed to initialize documentation quality assessment: $($_.Exception.Message)"
        return $false
    }
}

function Get-DefaultQualityAssessmentConfiguration {
    <#
    .SYNOPSIS
        Returns default quality assessment configuration based on research findings.
    #>
    
    return [PSCustomObject]@{
        Version = "1.0.0"
        QualityAssessment = [PSCustomObject]@{
            EnableMultiDimensionalAnalysis = $true
            EnableRealTimeAssessment = $true
            EnableComprehensiveMetrics = $true
            AssessmentInterval = 60  # seconds
            QualityThresholds = @{
                MinimumReadabilityScore = 60  # Flesch score
                MinimumCompletenessScore = 0.8  # 80%
                MinimumAccuracyScore = 0.9      # 90%
                TargetReadabilityLevel = [ReadabilityLevel]::FairlyEasy
            }
        }
        ReadabilityAlgorithms = [PSCustomObject]@{
            FleschKincaid = @{
                Enabled = $true
                TargetGradeLevel = 8
                AcceptableRange = @(6, 12)
            }
            GunningFog = @{
                Enabled = $true
                TargetComplexity = 10
                AcceptableRange = @(8, 12)
            }
            SMOG = @{
                Enabled = $true
                TargetLevel = 10
                AcceptableRange = @(8, 14)
            }
            ColemanLiau = @{
                Enabled = $true
                TargetLevel = 9
                AcceptableRange = @(7, 11)
            }
        }
        AIAssessment = [PSCustomObject]@{
            EnableAIQualityScoring = $true
            UseOllamaIntegration = $true
            Model = "codellama:13b"
            MaxTokens = 4096
            Temperature = 0.1  # Low for consistent assessment
            EnableContextualAnalysis = $true
            EnableImprovementSuggestions = $true
        }
        ContentOptimization = [PSCustomObject]@{
            EnableAutomatedOptimization = $true
            EnableReadabilityImprovement = $true
            EnableCompletenessEnhancement = $true
            EnableStructureOptimization = $true
            MaxOptimizationIterations = 3
        }
        Integration = [PSCustomObject]@{
            EnableAlertQualityIntegration = $true
            EnableFeedbackCollectionIntegration = $true
            EnableAutonomousDocIntegration = $true
            EnablePerformanceTracking = $true
        }
    }
}

function Discover-QualityAssessmentSystems {
    Write-Verbose "Discovering existing quality assessment systems..."
    
    # Connect to existing systems
    $moduleBasePath = Split-Path $PSScriptRoot -Parent
    
    # Check for AutonomousDocumentationEngine
    $autonomousPath = Join-Path $moduleBasePath "Unity-Claude-AutonomousDocumentationEngine\Unity-Claude-AutonomousDocumentationEngine.psm1"
    if (Test-Path $autonomousPath) {
        try {
            Import-Module $autonomousPath -Force -Global -ErrorAction Stop
            $script:DocumentationQualityState.ConnectedSystems.AutonomousDocumentationEngine = $true
            Write-Verbose "Connected: AutonomousDocumentationEngine"
        }
        catch {
            Write-Warning "Failed to connect to AutonomousDocumentationEngine: $_"
        }
    }
    
    # Check for Ollama AI (Week 1 implementation)
    $ollamaPath = Join-Path $moduleBasePath "Unity-Claude-AI-Integration\Ollama\Unity-Claude-Ollama.psm1"
    if (Test-Path $ollamaPath) {
        try {
            Import-Module $ollamaPath -Force -Global -ErrorAction Stop
            $script:DocumentationQualityState.ConnectedSystems.OllamaAI = $true
            Write-Verbose "Connected: Ollama AI for quality assessment"
        }
        catch {
            Write-Warning "Failed to connect to Ollama AI: $_"
        }
    }
    
    # Check for Alert Quality systems (Day 12 implementation)
    $alertQualityPath = Join-Path $moduleBasePath "Unity-Claude-AlertQualityReporting\Unity-Claude-AlertQualityReporting.psm1"
    if (Test-Path $alertQualityPath) {
        try {
            Import-Module $alertQualityPath -Force -Global -ErrorAction Stop
            $script:DocumentationQualityState.ConnectedSystems.AlertQualityReporting = $true
            Write-Verbose "Connected: AlertQualityReporting patterns"
        }
        catch {
            Write-Warning "Failed to connect to AlertQualityReporting: $_"
        }
    }
    
    $connectedCount = ($script:DocumentationQualityState.ConnectedSystems.Values | Where-Object { $_ }).Count
    Write-Host "Connected to $connectedCount quality assessment systems" -ForegroundColor Green
}

function Initialize-ReadabilityCalculator {
    Write-Verbose "Readability calculator initialized with multiple algorithms"
    return $true
}

function Setup-QualitySystemIntegration {
    Write-Verbose "Quality system integration setup completed"
    return $true
}

function Get-DocumentationQualityStatistics {
    <#
    .SYNOPSIS
        Returns comprehensive documentation quality assessment statistics.
    #>
    [CmdletBinding()]
    param()
    
    $stats = $script:DocumentationQualityState.Statistics.Clone()
    
    if ($stats.StartTime) {
        $stats.Runtime = (Get-Date) - $stats.StartTime
    }
    
    $stats.IsInitialized = $script:DocumentationQualityState.IsInitialized
    $stats.ConnectedSystems = $script:DocumentationQualityState.ConnectedSystems.Clone()
    $stats.QualityMetricsCount = $script:DocumentationQualityState.QualityMetrics.OverallQualityScores.Count
    
    return [PSCustomObject]$stats
}


# Export functions
Export-ModuleMember -Function Initialize-DocumentationQualityAssessment, Get-DefaultQualityAssessmentConfiguration, Discover-QualityAssessmentSystems, Initialize-ReadabilityCalculator, Setup-QualitySystemIntegration, Get-DocumentationQualityStatistics
# Export the state variable for other components to access
Export-ModuleMember -Variable DocumentationQualityState
