# Unity-Claude-PredictiveAnalysis Maintenance Prediction Component
# Maintenance prediction and technical debt calculation
# Part of refactored PredictiveAnalysis module

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Import dependencies
$CorePath = Join-Path $PSScriptRoot "PredictiveCore.psm1"
$TrendPath = Join-Path $PSScriptRoot "TrendAnalysis.psm1"

Import-Module $CorePath -Force
Import-Module $TrendPath -Force

function Get-MaintenancePrediction {
    <#
    .SYNOPSIS
    Generates maintenance predictions for a codebase
    .DESCRIPTION
    Analyzes code metrics to predict maintenance needs, risk levels, and timeline recommendations
    .PARAMETER Path
    Path to analyze for maintenance prediction
    .PARAMETER Graph
    Optional CPG graph for enhanced analysis
    .PARAMETER IncludeLLMInsights
    Include LLM-generated insights if available
    .EXAMPLE
    Get-MaintenancePrediction -Path "C:\Project" -IncludeLLMInsights
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        $Graph = $null,
        
        [switch]$IncludeLLMInsights
    )
    
    Write-Verbose "Generating maintenance prediction for $Path"
    
    try {
        # Gather metrics
        $metrics = @{
            Churn = Measure-CodeChurn -Path $Path -DaysBack 30
            Hotspots = Get-HotspotAnalysis -Path $Path -TopN 5 -DaysBack 90
            Complexity = $null
            Coverage = $null
            Dependencies = $null
        }
        
        # Get complexity from CPG if available
        if ($Graph) {
            $complexityMetrics = Get-CodeComplexityMetrics -Graph $Graph
            $metrics.Complexity = $complexityMetrics
        }
        
        # Get prediction model weights
        $config = Get-PredictiveConfig
        $weights = @{
            Complexity = 0.3
            Churn = 0.25
            Coverage = 0.15
            Age = 0.1
            Dependencies = 0.2
        }
        
        # Calculate maintenance score (0-100, higher = more maintenance needed)
        $score = 0
        
        # Churn factor
        if ($metrics.Churn) {
            $churnScore = [Math]::Min($metrics.Churn.ChurnRate / 2, 50)  # Max 50 points
            $score += $churnScore * $weights.Churn
        }
        
        # Complexity factor
        if ($metrics.Complexity) {
            $complexityScore = [Math]::Min($metrics.Complexity.AverageCyclomaticComplexity * 5, 50)
            $score += $complexityScore * $weights.Complexity
        }
        
        # Hotspot factor
        if ($metrics.Hotspots) {
            $hotspotScore = $metrics.Hotspots.Summary.CriticalFiles * 10
            $score += [Math]::Min($hotspotScore, 50) * 0.2
        }
        
        # Normalize score to 0-100
        $score = [Math]::Min([Math]::Round($score, 0), 100)
        
        # Determine risk level and timeline
        $riskLevel = switch ($score) {
            {$_ -ge 75} { 'Critical'; break }
            {$_ -ge 50} { 'High'; break }
            {$_ -ge 25} { 'Medium'; break }
            default { 'Low' }
        }
        
        $maintenanceTimeline = switch ($riskLevel) {
            'Critical' { 'Immediate (within 1 week)' }
            'High' { 'Short-term (within 1 month)' }
            'Medium' { 'Medium-term (within 3 months)' }
            'Low' { 'Long-term (within 6 months)' }
        }
        
        $prediction = @{
            Path = $Path
            Score = $score
            RiskLevel = $riskLevel
            Timeline = $maintenanceTimeline
            Metrics = $metrics
            TopIssues = @()
            Recommendations = @()
        }
        
        # Identify top issues
        if ($metrics.Churn -and $metrics.Churn.Risk -in @('High', 'Critical')) {
            $prediction.TopIssues += "High code churn rate ($($metrics.Churn.ChurnRate) lines/day)"
        }
        
        if ($metrics.Complexity -and $metrics.Complexity.AverageCyclomaticComplexity -gt 10) {
            $prediction.TopIssues += "High complexity (avg: $($metrics.Complexity.AverageCyclomaticComplexity))"
        }
        
        if ($metrics.Hotspots -and $metrics.Hotspots.Summary.CriticalFiles -gt 0) {
            $prediction.TopIssues += "$($metrics.Hotspots.Summary.CriticalFiles) critical hotspot files"
        }
        
        # Generate recommendations
        if ($score -ge 75) {
            $prediction.Recommendations += "Immediate refactoring required to reduce technical debt"
            $prediction.Recommendations += "Consider breaking down complex modules"
            $prediction.Recommendations += "Implement comprehensive testing before changes"
        } elseif ($score -ge 50) {
            $prediction.Recommendations += "Plan refactoring sprint in next iteration"
            $prediction.Recommendations += "Increase test coverage for high-risk areas"
            $prediction.Recommendations += "Review and simplify complex functions"
        } elseif ($score -ge 25) {
            $prediction.Recommendations += "Monitor trends and plan gradual improvements"
            $prediction.Recommendations += "Document complex areas for future maintenance"
        } else {
            $prediction.Recommendations += "Continue regular maintenance practices"
            $prediction.Recommendations += "Monitor for increasing complexity"
        }
        
        # Add LLM insights if requested and function is available
        if ($IncludeLLMInsights) {
            $llmPrompt = @"
Based on these maintenance metrics for ${Path}:
- Maintenance Score: $score/100
- Risk Level: $riskLevel
- Code Churn Rate: $($metrics.Churn.ChurnRate) lines/day
- Critical Hotspots: $($metrics.Hotspots.Summary.CriticalFiles)

Provide 3 specific, actionable maintenance recommendations.
"@
            
            try {
                if (Get-Command Invoke-OllamaGenerate -ErrorAction SilentlyContinue) {
                    $llmResponse = Invoke-OllamaGenerate -Prompt $llmPrompt -MaxTokens 500
                    if ($llmResponse.Success) {
                        $prediction.LLMInsights = $llmResponse.Response
                    }
                }
            }
            catch {
                Write-Warning "Could not get LLM insights: $_"
            }
        }
        
        return $prediction
    }
    catch {
        Write-Error "Failed to generate maintenance prediction: $_"
        return $null
    }
}

function Calculate-TechnicalDebt {
    <#
    .SYNOPSIS
    Calculates technical debt metrics for a codebase
    .DESCRIPTION
    Analyzes code to identify technical debt items and estimate remediation effort
    .PARAMETER Path
    Path to analyze for technical debt
    .PARAMETER Graph
    Optional CPG graph for enhanced analysis
    .EXAMPLE
    Calculate-TechnicalDebt -Path "C:\Project" -Graph $cpgGraph
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        $Graph = $null
    )
    
    Write-Verbose "Calculating technical debt for $Path"
    
    try {
        # Initialize debt calculation
        $debt = @{
            Path = $Path
            TotalHours = 0
            Categories = @{}
            Items = @()
            EstimatedCost = 0
        }
        
        # Get various metrics from CPG if available
        $obsolescence = if ($Graph -and (Get-Command Find-UnreachableCode -ErrorAction SilentlyContinue)) { 
            Find-UnreachableCode -Graph $Graph 
        } else { $null }
        
        $duplication = if ($Graph -and (Get-Command Test-CodeRedundancy -ErrorAction SilentlyContinue)) { 
            Test-CodeRedundancy -Graph $Graph 
        } else { $null }
        
        $complexity = if ($Graph -and (Get-Command Get-CodeComplexityMetrics -ErrorAction SilentlyContinue)) { 
            Get-CodeComplexityMetrics -Graph $Graph 
        } else { $null }
        
        # Calculate debt from obsolete code
        if ($obsolescence) {
            $obsoleteHours = $obsolescence.Count * 2  # 2 hours per obsolete item average
            $debt.Categories['ObsoleteCode'] = $obsoleteHours
            $debt.TotalHours += $obsoleteHours
            
            foreach ($item in $obsolescence) {
                $debt.Items += @{
                    Type = 'ObsoleteCode'
                    Description = "Unreachable code in $($item.Name)"
                    EstimatedHours = 2
                    Priority = 'Medium'
                }
            }
        }
        
        # Calculate debt from duplication
        if ($duplication -and $duplication.DuplicationPercentage -gt 5) {
            $dupHours = [Math]::Round($duplication.DuplicationPercentage * 10, 0)
            $debt.Categories['CodeDuplication'] = $dupHours
            $debt.TotalHours += $dupHours
            
            $debt.Items += @{
                Type = 'CodeDuplication'
                Description = "$($duplication.DuplicationPercentage)% code duplication"
                EstimatedHours = $dupHours
                Priority = 'High'
            }
        }
        
        # Calculate debt from complexity
        if ($complexity -and $complexity.AverageCyclomaticComplexity -gt 10) {
            $complexHours = [Math]::Round(($complexity.AverageCyclomaticComplexity - 10) * 5, 0)
            $debt.Categories['HighComplexity'] = $complexHours
            $debt.TotalHours += $complexHours
            
            $debt.Items += @{
                Type = 'HighComplexity'
                Description = "Average complexity of $($complexity.AverageCyclomaticComplexity)"
                EstimatedHours = $complexHours
                Priority = 'High'
            }
        }
        
        # Check for missing documentation
        if (Test-Path $Path) {
            $files = Get-ChildItem -Path $Path -Filter "*.ps*1" -Recurse -File -ErrorAction SilentlyContinue
            $undocumented = 0
            
            foreach ($file in $files) {
                try {
                    $content = Get-Content $file.FullName -Raw -ErrorAction Stop
                    if ($content -notmatch '<#[\s\S]+?#>' -and $content -notmatch '^\s*#') {
                        $undocumented++
                    }
                }
                catch {
                    Write-Verbose "Could not analyze file $($file.FullName): $_"
                }
            }
            
            if ($undocumented -gt 0) {
                $docHours = $undocumented * 0.5  # 30 minutes per file
                $debt.Categories['MissingDocumentation'] = $docHours
                $debt.TotalHours += $docHours
                
                $debt.Items += @{
                    Type = 'MissingDocumentation'
                    Description = "$undocumented files without documentation"
                    EstimatedHours = $docHours
                    Priority = 'Low'
                }
            }
        }
        
        # Calculate estimated cost (assuming $100/hour)
        $debt.EstimatedCost = $debt.TotalHours * 100
        
        # Add summary
        $debt.Summary = @{
            TotalItems = $debt.Items.Count
            HighPriority = ($debt.Items | Where-Object { $_.Priority -eq 'High' }).Count
            PaybackPeriod = if ($debt.TotalHours -gt 40) { 'Long-term' } 
                           elseif ($debt.TotalHours -gt 20) { 'Medium-term' }
                           else { 'Short-term' }
        }
        
        return $debt
    }
    catch {
        Write-Error "Failed to calculate technical debt: $_"
        return $null
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-MaintenancePrediction',
    'Calculate-TechnicalDebt'
)

Write-Verbose "MaintenancePrediction component loaded successfully"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAYXioO9Snqg1rS
# 9zDAQpIrtf9NCuqrgZaaaJ86ILdmL6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIdUUiTJjY04uU+uunvwqP9q
# EsP7rzXlmECsPu6G+E8UMA0GCSqGSIb3DQEBAQUABIIBABBh37DmQfxWPSXqUumz
# FOKdUy73pYrlDgPku0Lu6H1nURJmJsYB5dzBgcP+XOerDgGFhZJEvmF2Fije97Ut
# iIavOu0txyKl9U48XjUtLatrg6klHDU96oXxUq7EHxVgjIf9RYDsxB92kymwGdlR
# QY6q0Xe99nWa9dTHX/zEtnGYR+lN2zLJlLjOff4tE0MkcXil8VQLjF5PoKIqj3n9
# rAGrQ7xkfYBCVPURvBbPW6JDIU5TFNZvuVxtXesDRECU3Kio/2I34+tHPQM//VZK
# eKB3mu4ng/OVDaiV91D6O8z+DD54CgYgAtrDGznwtCCogHXMNRquVC5ClMr4pFnj
# T8k=
# SIG # End signature block
