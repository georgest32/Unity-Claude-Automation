# Refactor DocumentationQualityAssessment into smaller, debuggable components
$moduleDir = ".\Modules\Unity-Claude-DocumentationQualityAssessment"
$componentsDir = "$moduleDir\Components"

# Create components directory
if (-not (Test-Path $componentsDir)) {
    New-Item -ItemType Directory -Path $componentsDir -Force | Out-Null
    Write-Host "Created components directory: $componentsDir" -ForegroundColor Green
}

# Read the original module
$originalPath = "$moduleDir\Unity-Claude-DocumentationQualityAssessment.psm1"
$content = Get-Content $originalPath -Raw
$lines = $content -split "`r?`n"

Write-Host "Creating component modules..." -ForegroundColor Cyan

# Component 1: Readability Algorithms
$readabilityFunctions = @(
    'Calculate-ComprehensiveReadabilityScores',
    'Analyze-TextStatistics',
    'Estimate-SyllableCount',
    'Get-ReadabilityLevel',
    'Measure-FleschKincaidScore',
    'Measure-GunningFogScore',
    'Measure-SMOGScore',
    'Generate-ReadabilityRecommendations'
)

# Component 2: AI Assessment
$aiFunctions = @(
    'Perform-AIQualityAssessment',
    'Parse-AIQualityResponse',
    'Initialize-AIContentAssessor'
)

# Component 3: Content Analysis
$contentFunctions = @(
    'Assess-ContentCompleteness',
    'Calculate-OverallQualityMetrics',
    'Generate-ImprovementSuggestions',
    'Generate-ClarityRecommendations',
    'Generate-CompletenessRecommendations',
    'Generate-StructureRecommendations',
    'Get-PriorityActions',
    'Estimate-ImprovementImpact'
)

# Component 4: System Integration
$systemFunctions = @(
    'Initialize-DocumentationQualityAssessment',
    'Get-DefaultQualityAssessmentConfiguration',
    'Discover-QualityAssessmentSystems',
    'Initialize-ReadabilityCalculator',
    'Setup-QualitySystemIntegration',
    'Get-DocumentationQualityStatistics'
)

function Extract-Function {
    param(
        [string]$FunctionName,
        [string[]]$Lines,
        [string]$Content
    )
    
    # Find the function start
    $startLine = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match "^function\s+$FunctionName\s*{") {
            $startLine = $i
            break
        }
    }
    
    if ($startLine -eq -1) {
        Write-Warning "Function $FunctionName not found"
        return $null
    }
    
    # Find the function end by counting braces
    $braceCount = 0
    $endLine = -1
    $inFunction = $false
    
    for ($i = $startLine; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match "function\s+$FunctionName") {
            $inFunction = $true
        }
        
        if ($inFunction) {
            $braceCount += ([regex]::Matches($Lines[$i], '{').Count)
            $braceCount -= ([regex]::Matches($Lines[$i], '}').Count)
            
            if ($braceCount -eq 0 -and $i -gt $startLine) {
                $endLine = $i
                break
            }
        }
    }
    
    if ($endLine -eq -1) {
        Write-Warning "Could not find end of function $FunctionName"
        return $null
    }
    
    # Extract the function content
    $functionLines = $Lines[$startLine..$endLine]
    return $functionLines -join "`n"
}

# Create Readability component
Write-Host "  Creating ReadabilityAlgorithms.psm1..." -ForegroundColor Yellow
$readabilityContent = @"
# DocumentationQualityAssessment - Readability Algorithms Component
# This module contains all readability calculation functions

# Module-level variables
`$script:ReadabilityState = @{
    IsInitialized = `$false
    AlgorithmsEnabled = @{}
}

"@

foreach ($funcName in $readabilityFunctions) {
    $funcContent = Extract-Function -FunctionName $funcName -Lines $lines -Content $content
    if ($funcContent) {
        $readabilityContent += "`n`n$funcContent"
    }
}

$readabilityContent += @"

`n`n# Export functions
Export-ModuleMember -Function $($readabilityFunctions -join ', ')
"@

Set-Content -Path "$componentsDir\ReadabilityAlgorithms.psm1" -Value $readabilityContent -Encoding UTF8

# Create AI Assessment component  
Write-Host "  Creating AIAssessment.psm1..." -ForegroundColor Yellow
$aiContent = @"
# DocumentationQualityAssessment - AI Assessment Component
# This module contains AI-powered assessment functions

# Module-level variables
`$script:AIAssessmentState = @{
    IsInitialized = `$false
    ConnectedSystems = @{
        OllamaAI = `$false
    }
}

"@

foreach ($funcName in $aiFunctions) {
    $funcContent = Extract-Function -FunctionName $funcName -Lines $lines -Content $content
    if ($funcContent) {
        $aiContent += "`n`n$funcContent"
    }
}

$aiContent += @"

`n`n# Export functions
Export-ModuleMember -Function $($aiFunctions -join ', ')
"@

Set-Content -Path "$componentsDir\AIAssessment.psm1" -Value $aiContent -Encoding UTF8

# Create Content Analysis component
Write-Host "  Creating ContentAnalysis.psm1..." -ForegroundColor Yellow
$contentAnalysisContent = @"
# DocumentationQualityAssessment - Content Analysis Component
# This module contains content analysis and improvement suggestion functions

"@

foreach ($funcName in $contentFunctions) {
    $funcContent = Extract-Function -FunctionName $funcName -Lines $lines -Content $content
    if ($funcContent) {
        $contentAnalysisContent += "`n`n$funcContent"
    }
}

$contentAnalysisContent += @"

`n`n# Export functions
Export-ModuleMember -Function $($contentFunctions -join ', ')
"@

Set-Content -Path "$componentsDir\ContentAnalysis.psm1" -Value $contentAnalysisContent -Encoding UTF8

# Create System Integration component
Write-Host "  Creating SystemIntegration.psm1..." -ForegroundColor Yellow
$systemContent = @"
# DocumentationQualityAssessment - System Integration Component
# This module contains initialization and system integration functions

# Module-level state (shared across all components)
`$script:DocumentationQualityState = @{
    IsInitialized = `$false
    Configuration = @{
        EnableAIAssessment = `$true
        EnableReadabilityAlgorithms = `$true
        AutoDiscoverSystems = `$true
        CacheResults = `$true
        EnablePerformanceTracking = `$true
    }
    ConnectedSystems = @{
        OllamaAI = `$false
    }
    Statistics = @{
        AssessmentsPerformed = 0
        TotalProcessingTime = 0
        AverageQualityScore = 0
        LastAssessmentTime = `$null
    }
    Cache = @{}
}

"@

foreach ($funcName in $systemFunctions) {
    $funcContent = Extract-Function -FunctionName $funcName -Lines $lines -Content $content
    if ($funcContent) {
        $systemContent += "`n`n$funcContent"
    }
}

$systemContent += @"

`n`n# Export functions
Export-ModuleMember -Function $($systemFunctions -join ', ')
# Export the state variable for other components to access
Export-ModuleMember -Variable DocumentationQualityState
"@

Set-Content -Path "$componentsDir\SystemIntegration.psm1" -Value $systemContent -Encoding UTF8

Write-Host "  Creating refactored main module..." -ForegroundColor Yellow

# Create the main orchestrator module
$mainModuleContent = @"
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
        Write-Host "📊 Performing AI-enhanced documentation quality assessment..." -ForegroundColor Blue
        
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
        
        Write-Host "✅ Quality assessment complete. Overall score: `$(`$qualityMetrics.OverallScore)/100" -ForegroundColor Green
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

# Backup the original module
$backupPath = "$moduleDir\Unity-Claude-DocumentationQualityAssessment_Original_$(Get-Date -Format 'yyyyMMdd_HHmmss').psm1"
Copy-Item $originalPath $backupPath
Write-Host "Original module backed up to: $backupPath" -ForegroundColor Cyan

# Create the new main module
Set-Content -Path $originalPath -Value $mainModuleContent -Encoding UTF8

Write-Host "`nRefactoring complete!" -ForegroundColor Green
Write-Host "Components created:" -ForegroundColor Cyan
Write-Host "  - SystemIntegration.psm1 (initialization and configuration)" -ForegroundColor White
Write-Host "  - ReadabilityAlgorithms.psm1 (Flesch-Kincaid, Gunning Fog, SMOG)" -ForegroundColor White
Write-Host "  - AIAssessment.psm1 (AI-powered analysis)" -ForegroundColor White
Write-Host "  - ContentAnalysis.psm1 (content analysis and suggestions)" -ForegroundColor White
Write-Host "  - Unity-Claude-DocumentationQualityAssessment.psm1 (main orchestrator)" -ForegroundColor White