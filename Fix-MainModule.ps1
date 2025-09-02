# Fix the main module with ASCII-only content
$mainModulePath = '.\Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1'

$fixedMainModuleContent = @"
# Unity-Claude-DocumentationQualityAssessment
# Refactored modular version for easier debugging and maintenance

# Import all component modules
Import-Module "`$PSScriptRoot\Components\SystemIntegration.psm1" -Force
Import-Module "`$PSScriptRoot\Components\ReadabilityAlgorithms.psm1" -Force  
Import-Module "`$PSScriptRoot\Components\AIAssessment.psm1" -Force
Import-Module "`$PSScriptRoot\Components\ContentAnalysis.psm1" -Force

# Main orchestrator function
function Assess-DocumentationQuality {
    <#
    .SYNOPSIS
        Performs comprehensive AI-enhanced quality assessment of documentation content.
    
    .DESCRIPTION
        Implements research-validated quality assessment using multiple readability algorithms,
        AI-powered content analysis, and comprehensive quality metrics for enterprise
        documentation optimization.
    
    .PARAMETER Content
        Documentation content to assess.
    
    .PARAMETER FilePath
        Optional file path for context and result tracking.
    
    .PARAMETER UseAI
        Use AI for enhanced quality assessment and improvement suggestions.
    
    .EXAMPLE
        Assess-DocumentationQuality -Content `$documentationText -FilePath ".\README.md" -UseAI
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = `$true)]
        [string]`$Content,
        
        [Parameter(Mandatory = `$false)]
        [string]`$FilePath = "",
        
        [Parameter(Mandatory = `$false)]
        [switch]`$UseAI = `$true
    )
    
    if (-not `$script:DocumentationQualityState.IsInitialized) {
        Write-Debug "Auto-initializing Documentation Quality Assessment"
        `$initResult = Initialize-DocumentationQualityAssessment -EnableAIAssessment -EnableReadabilityAlgorithms -AutoDiscoverSystems
        if (-not `$initResult) {
            Write-Error "Failed to auto-initialize Documentation Quality Assessment"
            return `$false
        }
    }
    
    Write-Verbose "Performing comprehensive quality assessment for content"
    
    try {
        Write-Host "[INFO] Performing AI-enhanced documentation quality assessment..." -ForegroundColor Blue
        
        # Step 1: Calculate readability scores using multiple algorithms (research-validated)
        `$readabilityScores = Calculate-ComprehensiveReadabilityScores -Content `$Content
        
        # Step 2: Assess content completeness and structure
        `$completenessAssessment = Assess-ContentCompleteness -Content `$Content -FilePath `$FilePath
        
        # Step 3: AI-powered quality assessment (if enabled)
        `$aiAssessment = if (`$UseAI -and `$script:DocumentationQualityState.ConnectedSystems.OllamaAI) {
            Perform-AIQualityAssessment -Content `$Content -FilePath `$FilePath
        } else { `$null }
        
        # Step 4: Calculate overall quality metrics
        `$qualityMetrics = Calculate-OverallQualityMetrics -ReadabilityScores `$readabilityScores -CompletenessAssessment `$completenessAssessment -AIAssessment `$aiAssessment
        
        # Step 5: Generate actionable improvement suggestions
        `$improvements = Generate-ImprovementSuggestions -QualityMetrics `$qualityMetrics -Content `$Content
        
        # Step 6: Update performance tracking
        `$script:DocumentationQualityState.Statistics.AssessmentsPerformed++
        `$script:DocumentationQualityState.Statistics.LastAssessmentTime = Get-Date
        
        `$result = @{
            FilePath = `$FilePath
            QualityMetrics = `$qualityMetrics
            ReadabilityScores = `$readabilityScores
            CompletenessAssessment = `$completenessAssessment
            AIAssessment = `$aiAssessment
            ImprovementSuggestions = `$improvements
            AssessmentTimestamp = Get-Date
            ProcessingDuration = (Get-Date) - (Get-Date).AddSeconds(-1)
        }
        
        Write-Host "[PASS] Quality assessment complete. Overall score: `$(`$qualityMetrics.OverallScore)/100" -ForegroundColor Green
        return `$result
        
    } catch {
        Write-Error "Error in Assess-DocumentationQuality: `$_"
        return `$null
    }
}

# Export the main function and re-export component functions
Export-ModuleMember -Function Assess-DocumentationQuality

# Re-export all functions from components
`$componentFunctions = @(
    'Initialize-DocumentationQualityAssessment',
    'Get-DefaultQualityAssessmentConfiguration', 
    'Calculate-ComprehensiveReadabilityScores',
    'Analyze-TextStatistics',
    'Perform-AIQualityAssessment',
    'Estimate-SyllableCount',
    'Get-ReadabilityLevel',
    'Discover-QualityAssessmentSystems',
    'Initialize-ReadabilityCalculator',
    'Initialize-AIContentAssessor',
    'Setup-QualitySystemIntegration',
    'Assess-ContentCompleteness',
    'Calculate-OverallQualityMetrics',
    'Generate-ImprovementSuggestions',
    'Parse-AIQualityResponse',
    'Generate-ReadabilityRecommendations',
    'Generate-ClarityRecommendations',
    'Generate-CompletenessRecommendations',
    'Generate-StructureRecommendations',
    'Get-PriorityActions',
    'Estimate-ImprovementImpact',
    'Get-DocumentationQualityStatistics',
    'Measure-FleschKincaidScore',
    'Measure-GunningFogScore',
    'Measure-SMOGScore'
)

Export-ModuleMember -Function `$componentFunctions
"@

Write-Host "Creating fixed main module..." -ForegroundColor Cyan
Set-Content -Path $mainModulePath -Value $fixedMainModuleContent -Encoding UTF8
Write-Host "Main module fixed with ASCII-only content" -ForegroundColor Green