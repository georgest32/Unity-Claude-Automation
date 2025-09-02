# DocumentationQualityAssessment - Content Analysis Component
# This module contains content analysis and improvement suggestion functions


function Assess-ContentCompleteness {
    param($Content, $FilePath)
    
    # Basic completeness assessment
    $hasTitle = $Content -match '^#\s+.+' -or $Content -match '<h\d>'
    $hasDescription = $Content.Length -gt 100
    $hasExamples = $Content -match '(example|Example|EXAMPLE)' -or $Content -match '```'
    $hasStructure = $Content -match '^#{1,6}\s+' -or $Content -match '<h\d>'
    
    $completenessScore = @($hasTitle, $hasDescription, $hasExamples, $hasStructure) | Where-Object { $_ }
    $score = $completenessScore.Count / 4.0
    
    return @{
        CompletenessScore = [Math]::Round($score, 2)
        HasTitle = $hasTitle
        HasDescription = $hasDescription
        HasExamples = $hasExamples
        HasStructure = $hasStructure
        RequiresImprovement = $score -lt 0.7
    }
}

function Calculate-OverallQualityMetrics {
    param($ReadabilityScores, $CompletenessAssessment, $AIAssessment)
    
    # Calculate weighted overall score
    $readabilityScore = if ($ReadabilityScores.FleschKincaidScore -ge 60) { 4 } else { 2 }
    $completenessScore = $CompletenessAssessment.CompletenessScore * 5
    $aiScore = if ($AIAssessment) { $AIAssessment.OverallScore } else { 3.5 }
    
    $overallScore = ($readabilityScore + $completenessScore + $aiScore) / 3
    
    $qualityLevel = if ($overallScore -ge 4) { "Excellent" }
                   elseif ($overallScore -ge 3) { "Good" }
                   elseif ($overallScore -ge 2) { "Fair" }
                   else { "Needs Improvement" }
    
    return @{
        OverallScore = [Math]::Round($overallScore, 2)
        QualityLevel = $qualityLevel
        RequiresImprovement = $overallScore -lt 3.0
        ComponentScores = @{
            Readability = $readabilityScore
            Completeness = $completenessScore
            AIAssessment = $aiScore
        }
    }
}

function Generate-ImprovementSuggestions {
    param($QualityMetrics, $Content, $UseAI)
    
    $suggestions = @()
    
    # Readability suggestions
    if ($QualityMetrics.ComponentScores.Readability -lt 3) {
        $suggestions += "Simplify sentence structure to improve readability"
        $suggestions += "Use shorter sentences (target: 15-20 words per sentence)"
        $suggestions += "Replace complex words with simpler alternatives where possible"
    }
    
    # Completeness suggestions
    if ($QualityMetrics.ComponentScores.Completeness -lt 3) {
        $suggestions += "Add more detailed examples and use cases"
        $suggestions += "Include comprehensive parameter descriptions"
        $suggestions += "Provide troubleshooting and common issues sections"
    }
    
    # AI-specific suggestions
    if ($UseAI -and $QualityMetrics.ComponentScores.AIAssessment -lt 3) {
        $suggestions += "Enhance technical accuracy and current information"
        $suggestions += "Improve logical flow and organization"
        $suggestions += "Add cross-references to related documentation"
    }
    
    return $suggestions
}

function Generate-ClarityRecommendations {
    param($QualityAssessment)
    return @("Add clear explanations", "Improve logical flow")
}

function Generate-CompletenessRecommendations {
    param($QualityAssessment)
    return @("Add missing examples", "Include comprehensive details")
}

function Generate-StructureRecommendations {
    param($QualityAssessment)
    return @("Improve organization", "Add clear headings")
}

function Get-PriorityActions {
    param($QualityAssessment)
    return @("Focus on readability improvement", "Enhance content completeness")
}

function Estimate-ImprovementImpact {
    param($QualityAssessment, $Recommendations)
    return @{ EstimatedImprovement = "15-25%"; ImplementationEffort = "Medium" }
}


# Export functions
Export-ModuleMember -Function Assess-ContentCompleteness, Calculate-OverallQualityMetrics, Generate-ImprovementSuggestions, Generate-ClarityRecommendations, Generate-CompletenessRecommendations, Generate-StructureRecommendations, Get-PriorityActions, Estimate-ImprovementImpact
