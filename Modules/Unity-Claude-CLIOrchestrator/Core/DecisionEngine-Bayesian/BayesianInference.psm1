# BayesianInference.psm1
# Phase 7 Day 3-4 Hours 5-8: Bayesian Inference Core Functions
# Core Bayesian decision-making and probability calculations
# Date: 2025-08-25

#region Bayesian Core Functions

# Calculate Bayesian posterior probability
function Invoke-BayesianConfidenceAdjustment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DecisionType,
        
        [Parameter(Mandatory = $true)]
        [double]$ObservedConfidence,
        
        [Parameter()]
        [hashtable]$ContextualFactors = @{},
        
        [Parameter()]
        [switch]$ReturnDetails
    )
    
    Write-DecisionLog "Applying Bayesian confidence adjustment for $DecisionType" "DEBUG"
    $startTime = Get-Date
    
    try {
        # Get prior probability
        $prior = Get-BayesianPrior -DecisionType $DecisionType
        
        # Calculate likelihood based on observed confidence and historical success
        $likelihood = Calculate-BayesianLikelihood -DecisionType $DecisionType -ObservedConfidence $ObservedConfidence
        
        # Calculate evidence (normalizing constant)
        $evidence = Calculate-BayesianEvidence -DecisionType $DecisionType -ObservedConfidence $ObservedConfidence
        
        # Apply Bayes' theorem: P(H|E) = P(E|H) * P(H) / P(E)
        if ($evidence -gt 0) {
            $posterior = ($likelihood * $prior) / $evidence
        } else {
            $posterior = $prior  # Fallback to prior if no evidence
        }
        
        # Apply contextual adjustments
        if ($ContextualFactors.Count -gt 0) {
            $contextAdjustment = Calculate-ContextualAdjustment -ContextualFactors $ContextualFactors
            $posterior = [Math]::Min(1.0, [Math]::Max(0.0, $posterior * $contextAdjustment))
        }
        
        # Calculate uncertainty metrics
        $uncertainty = Calculate-BayesianUncertainty -Prior $prior -Posterior $posterior -ObservedConfidence $ObservedConfidence
        
        # Determine confidence band
        $confidenceBand = Get-ConfidenceBand -Confidence $posterior
        
        $processingTime = ((Get-Date) - $startTime).TotalMilliseconds
        
        Write-DecisionLog "Bayesian adjustment: Prior=$([Math]::Round($prior, 3)), Posterior=$([Math]::Round($posterior, 3)), Uncertainty=$([Math]::Round($uncertainty, 3)) (${processingTime}ms)" "INFO"
        
        $result = @{
            AdjustedConfidence = $posterior
            PriorConfidence = $prior
            ObservedConfidence = $ObservedConfidence
            Uncertainty = $uncertainty
            ConfidenceBand = $confidenceBand
            ProcessingTimeMs = $processingTime
        }
        
        if ($ReturnDetails) {
            $result.Details = @{
                Likelihood = $likelihood
                Evidence = $evidence
                ContextualFactors = $ContextualFactors
                HistoricalData = $script:BayesianConfig.OutcomeHistory[$DecisionType]
            }
        }
        
        return $result
        
    } catch {
        Write-DecisionLog "Bayesian adjustment failed: $($_.Exception.Message)" "ERROR"
        return @{
            AdjustedConfidence = $ObservedConfidence  # Fallback to observed
            PriorConfidence = 0.5
            ObservedConfidence = $ObservedConfidence
            Uncertainty = 1.0
            ConfidenceBand = "Unknown"
            Error = $_.Exception.Message
        }
    }
}

# Get Bayesian prior probability
function Get-BayesianPrior {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DecisionType
    )
    
    # Start with configured prior
    $basePrior = $script:BayesianConfig.PriorProbabilities[$DecisionType]
    if (-not $basePrior) {
        Write-DecisionLog "Unknown decision type for prior: $DecisionType - using 0.5" "WARN"
        return 0.5
    }
    
    # Adjust based on historical outcomes if available
    $history = $script:BayesianConfig.OutcomeHistory[$DecisionType]
    if ($history.Total -ge $script:BayesianConfig.MinimumSamples) {
        $successRate = if ($history.Total -gt 0) { $history.Success / $history.Total } else { 0.5 }
        $learningRate = $script:BayesianConfig.LearningRate
        
        # Weighted average of base prior and observed success rate
        $adjustedPrior = ($basePrior * (1 - $learningRate)) + ($successRate * $learningRate)
        
        Write-DecisionLog "Prior adjusted from $([Math]::Round($basePrior, 3)) to $([Math]::Round($adjustedPrior, 3)) based on $($history.Total) samples" "DEBUG"
        return $adjustedPrior
    }
    
    return $basePrior
}

# Calculate Bayesian likelihood
function Calculate-BayesianLikelihood {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DecisionType,
        
        [Parameter(Mandatory = $true)]
        [double]$ObservedConfidence
    )
    
    # Likelihood represents P(Evidence | Hypothesis)
    # Higher observed confidence increases likelihood
    
    $history = $script:BayesianConfig.OutcomeHistory[$DecisionType]
    
    if ($history.Total -gt 0) {
        $historicalSuccess = $history.Success / $history.Total
        # Combine observed confidence with historical success rate
        $likelihood = ($ObservedConfidence * 0.7) + ($historicalSuccess * 0.3)
    } else {
        # No history, use observed confidence directly
        $likelihood = $ObservedConfidence
    }
    
    # Apply sigmoid smoothing to prevent extreme values
    $smoothed = 1 / (1 + [Math]::Exp(-10 * ($likelihood - 0.5)))
    
    return [Math]::Min(0.999, [Math]::Max(0.001, $smoothed))
}

# Calculate Bayesian evidence (normalizing constant)
function Calculate-BayesianEvidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DecisionType,
        
        [Parameter(Mandatory = $true)]
        [double]$ObservedConfidence
    )
    
    # Evidence is the probability of observing the data across all hypotheses
    # P(E) = Sum(P(E|Hi) * P(Hi)) for all hypotheses
    
    $totalEvidence = 0.0
    
    foreach ($type in $script:BayesianConfig.PriorProbabilities.Keys) {
        $prior = $script:BayesianConfig.PriorProbabilities[$type]
        if ($type -eq $DecisionType) {
            $likelihood = Calculate-BayesianLikelihood -DecisionType $type -ObservedConfidence $ObservedConfidence
        } else {
            # For other decision types, use a discounted likelihood
            $likelihood = Calculate-BayesianLikelihood -DecisionType $type -ObservedConfidence ($ObservedConfidence * 0.5)
        }
        $totalEvidence += $likelihood * $prior
    }
    
    return [Math]::Max(0.001, $totalEvidence)  # Prevent division by zero
}

# Calculate contextual adjustment factor
function Calculate-ContextualAdjustment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ContextualFactors
    )
    
    $adjustment = 1.0
    
    # Time of day factor (some decisions more reliable at certain times)
    if ($ContextualFactors.ContainsKey('TimeOfDay')) {
        $hour = $ContextualFactors.TimeOfDay
        if ($hour -ge 9 -and $hour -le 17) {
            $adjustment *= 1.05  # Business hours boost
        } elseif ($hour -ge 22 -or $hour -le 6) {
            $adjustment *= 0.95  # Late night/early morning penalty
        }
    }
    
    # System load factor
    if ($ContextualFactors.ContainsKey('SystemLoad')) {
        $load = $ContextualFactors.SystemLoad
        if ($load -gt 0.8) {
            $adjustment *= 0.9  # High load penalty
        } elseif ($load -lt 0.3) {
            $adjustment *= 1.1  # Low load boost
        }
    }
    
    # Recent failure factor
    if ($ContextualFactors.ContainsKey('RecentFailures')) {
        $failures = $ContextualFactors.RecentFailures
        $adjustment *= [Math]::Max(0.7, 1.0 - ($failures * 0.1))
    }
    
    # User experience level
    if ($ContextualFactors.ContainsKey('UserExperience')) {
        switch ($ContextualFactors.UserExperience) {
            'Expert' { $adjustment *= 1.15 }
            'Intermediate' { $adjustment *= 1.05 }
            'Beginner' { $adjustment *= 0.90 }
        }
    }
    
    return [Math]::Min(1.5, [Math]::Max(0.5, $adjustment))
}

# Calculate uncertainty metrics
function Calculate-BayesianUncertainty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$Prior,
        
        [Parameter(Mandatory = $true)]
        [double]$Posterior,
        
        [Parameter(Mandatory = $true)]
        [double]$ObservedConfidence
    )
    
    # Calculate KL divergence between prior and posterior
    $klDivergence = 0.0
    if ($Prior -gt 0 -and $Posterior -gt 0) {
        $klDivergence = $Posterior * [Math]::Log($Posterior / $Prior)
    }
    
    # Calculate entropy of the posterior distribution
    $entropy = 0.0
    if ($Posterior -gt 0 -and $Posterior -lt 1) {
        $entropy = -($Posterior * [Math]::Log($Posterior) + (1 - $Posterior) * [Math]::Log(1 - $Posterior))
    }
    
    # Calculate variance between observed and posterior
    $variance = [Math]::Pow($ObservedConfidence - $Posterior, 2)
    
    # Combine metrics into overall uncertainty (0 = certain, 1 = uncertain)
    $uncertainty = [Math]::Min(1.0, ($klDivergence + $entropy + $variance) / 3)
    
    return $uncertainty
}

#endregion

# Export all Bayesian inference functions
Export-ModuleMember -Function Invoke-BayesianConfidenceAdjustment, Get-BayesianPrior, Calculate-BayesianLikelihood, Calculate-BayesianEvidence, Calculate-ContextualAdjustment, Calculate-BayesianUncertainty
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBFxlZ/SpHkbOWw
# O9ReFlYHAqLkT1v3Juq9+YOK5W74i6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJ3+ak/fEhP0d6ucm/K8GqWo
# AlXjZM6KUXrIEOAO/idTMA0GCSqGSIb3DQEBAQUABIIBAIM2/uh9MzV8sjlcH2LN
# yTCeij0zSfANwNKuKeiNTLtdeChiUNle3gW4DTdw61mR1reuPje7TDCMfRSFRQGl
# NCwMR0us90+WRxs634we5h6OutU6D6/6YVCSROvn3zybLOh+XknKoeZRDVOK1Zea
# QzWgmYH3n+pC5ikphKbOW6FsuWxTkHK8goilCbu8in3kBtTkvSY9886Jji+sKEVG
# Fcea6UX/iCtBFy+0faJ8CvGLT2TYM5serVLierOpBe/4byMUMPxVRbcCtJMlxYcF
# hUsd5vxC9N1wRJmOtyRAzQI+aq8wrGZBsvLITVfLZq2+6k5iRhoU3G0AAnNtLDTV
# pAE=
# SIG # End signature block
