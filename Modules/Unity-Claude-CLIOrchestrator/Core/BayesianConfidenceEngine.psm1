# Unity-Claude-CLIOrchestrator - Bayesian Confidence & Learning Engine
# Phase 7 Day 1-2 Hours 5-8: Enhanced Confidence Scoring with Bayesian Learning
# Compatible with PowerShell 5.1 and Claude Code CLI 2025

#region Bayesian Configuration

# Enhanced Bayesian priors with Position Weight Matrix (PWM) approach
$script:BayesianPriors = @{
    "TEST" = @{ 
        Success = 0.85; Total = 100; LastUpdated = (Get-Date)
        PatternWeights = @{ FilePath = 0.8; LineNumber = 0.6; TestKeywords = 0.9 }
        RarityScore = 0.3  # Based on frequency analysis
        CRPS_History = @()  # Continuous Ranked Probability Score tracking
    }
    "FIX" = @{ 
        Success = 0.75; Total = 80; LastUpdated = (Get-Date)
        PatternWeights = @{ FilePath = 0.9; ErrorMessage = 0.8; LineNumber = 0.7 }
        RarityScore = 0.4
        CRPS_History = @()
    }
    "COMPILE" = @{ 
        Success = 0.80; Total = 90; LastUpdated = (Get-Date)
        PatternWeights = @{ ProjectFile = 0.9; BuildError = 0.8; Dependencies = 0.6 }
        RarityScore = 0.5
        CRPS_History = @()
    }
    "CONTINUE" = @{ 
        Success = 0.90; Total = 120; LastUpdated = (Get-Date)
        PatternWeights = @{ WorkflowStep = 0.8; ContextUpdate = 0.7; Progress = 0.6 }
        RarityScore = 0.2
        CRPS_History = @()
    }
    "RESTART" = @{ 
        Success = 0.70; Total = 60; LastUpdated = (Get-Date)
        PatternWeights = @{ ModuleName = 0.9; ServiceName = 0.8; DependencyCheck = 0.7 }
        RarityScore = 0.6
        CRPS_History = @()
    }
    "COMPLETE" = @{ 
        Success = 0.95; Total = 150; LastUpdated = (Get-Date)
        PatternWeights = @{ Finalization = 0.9; ReportGeneration = 0.8; Summary = 0.7 }
        RarityScore = 0.1
        CRPS_History = @()
    }
    "ERROR" = @{ 
        Success = 0.85; Total = 200; LastUpdated = (Get-Date)
        PatternWeights = @{ ErrorMessage = 0.9; StackTrace = 0.8; ErrorCode = 0.7 }
        RarityScore = 0.7
        CRPS_History = @()
    }
}

# Evidence accumulation for multi-pattern scenarios
$script:EvidenceAccumulation = @{
    Patterns = @()
    TotalEvidence = 0.0
    LastAccumulation = $null
}

# Confidence calibration history for learning
$script:CalibrationHistory = @{
    Entries = @()
    LastCalibration = $null
    CalibrationParameters = @{}
}

#endregion

#region Core Bayesian Functions

function Calculate-OverallConfidence {
    [CmdletBinding()]
    param(
        [Parameter()]
        [array]$Recommendations = @(),
        
        [Parameter()]
        [hashtable]$Classification = @{},
        
        [Parameter()]
        [array]$Entities = @()
    )
    
    $confidenceStart = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Initialize confidence components
    $confidenceComponents = @{
        RecommendationConfidence = 0.0
        ClassificationConfidence = 0.0
        EntityConfidence = 0.0
        BayesianAdjustment = 0.0
        UncertaintyQuantification = 0.0
    }
    
    # Calculate recommendation confidence with Bayesian enhancement
    if ($Recommendations.Count -gt 0) {
        $confidenceComponents.RecommendationConfidence = Get-BayesianRecommendationConfidence -Recommendations $Recommendations
    }
    
    # Calculate classification confidence
    if ($Classification.Confidence) {
        $confidenceComponents.ClassificationConfidence = $Classification.Confidence
    }
    
    # Calculate entity-based confidence
    if ($Entities.Count -gt 0) {
        $confidenceComponents.EntityConfidence = Get-EntityBasedConfidence -Entities $Entities
    }
    
    # Apply Bayesian adjustment
    $confidenceComponents.BayesianAdjustment = Get-BayesianAdjustment -Components $confidenceComponents
    
    # Calculate uncertainty quantification
    $confidenceComponents.UncertaintyQuantification = Get-UncertaintyQuantification -Components $confidenceComponents
    
    # Combine all confidence sources with weighted average
    $weights = @{
        Recommendation = 0.40
        Classification = 0.30
        Entity = 0.15
        Bayesian = 0.10
        Uncertainty = 0.05
    }
    
    $weightedConfidence = (
        ($confidenceComponents.RecommendationConfidence * $weights.Recommendation) +
        ($confidenceComponents.ClassificationConfidence * $weights.Classification) +
        ($confidenceComponents.EntityConfidence * $weights.Entity) +
        ($confidenceComponents.BayesianAdjustment * $weights.Bayesian) +
        ((1.0 - $confidenceComponents.UncertaintyQuantification) * $weights.Uncertainty)
    )
    
    # Apply final calibration
    $finalConfidence = Invoke-FinalCalibration -RawConfidence $weightedConfidence -Components $confidenceComponents
    
    $confidenceStart.Stop()
    
    # Update learning history
    Update-ConfidenceLearning -Confidence $finalConfidence -Components $confidenceComponents -ProcessingTime $confidenceStart.ElapsedMilliseconds
    
    return @{
        OverallConfidence = $finalConfidence
        Components = $confidenceComponents
        Weights = $weights
        ProcessingTimeMs = $confidenceStart.ElapsedMilliseconds
        QualityRating = Get-ConfidenceQualityRating -Confidence $finalConfidence
        UncertaintyRange = @{
            Lower = [Math]::Max(0.0, $finalConfidence - $confidenceComponents.UncertaintyQuantification)
            Upper = [Math]::Min(1.0, $finalConfidence + $confidenceComponents.UncertaintyQuantification)
        }
    }
}

function Get-BayesianRecommendationConfidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Recommendations
    )
    
    if ($Recommendations.Count -eq 0) {
        return 0.0
    }
    
    $totalBayesianConfidence = 0.0
    $validRecommendations = 0
    
    foreach ($recommendation in $Recommendations) {
        if ($recommendation.Type -and $recommendation.Confidence) {
            $bayesianConfidence = Get-BayesianConfidence -PatternType $recommendation.Type -EvidenceStrength $recommendation.Confidence
            $totalBayesianConfidence += $bayesianConfidence
            $validRecommendations++
        }
    }
    
    if ($validRecommendations -eq 0) {
        return 0.6  # Default confidence when no valid recommendations
    }
    
    # Average Bayesian confidence with diminishing returns for multiple recommendations
    $averageConfidence = $totalBayesianConfidence / $validRecommendations
    
    # Apply multi-recommendation bonus (logarithmic scaling)
    $multiRecommendationBonus = [Math]::Log($validRecommendations + 1) / [Math]::Log(10) * 0.1
    $enhancedConfidence = $averageConfidence + $multiRecommendationBonus
    
    return [Math]::Min(0.99, $enhancedConfidence)
}

function Get-BayesianConfidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PatternType,
        
        [Parameter(Mandatory = $true)]
        [double]$EvidenceStrength,
        
        [Parameter()]
        [hashtable]$PatternContext = @{}
    )
    
    # Get enhanced prior knowledge with PWM scoring
    $prior = 0.5  # Default neutral prior
    $patternWeights = @{}
    $rarityAdjustment = 0.0
    
    if ($script:BayesianPriors.ContainsKey($PatternType)) {
        $priorInfo = $script:BayesianPriors[$PatternType]
        $prior = $priorInfo.Success / [Math]::Max(1.0, $priorInfo.Total)
        $patternWeights = $priorInfo.PatternWeights
        $rarityAdjustment = $priorInfo.RarityScore * 0.1  # Rarity bonus
    }
    
    # Apply Position Weight Matrix (PWM) scoring
    $pwmScore = Get-PositionWeightMatrixScore -PatternContext $PatternContext -PatternWeights $patternWeights
    
    # Enhanced evidence strength with PWM adjustment
    $enhancedEvidenceStrength = ($EvidenceStrength * 0.7) + ($pwmScore * 0.3)
    
    # Calculate likelihood with pattern weighting
    $likelihoodSuccess = $enhancedEvidenceStrength + $rarityAdjustment
    $likelihoodFailure = 1.0 - $enhancedEvidenceStrength + (0.1 - $rarityAdjustment)
    
    # Enhanced Bayesian calculation with uncertainty quantification
    $evidenceGivenSuccess = $likelihoodSuccess * $prior * $enhancedEvidenceStrength
    $evidenceGivenFailure = $likelihoodFailure * (1.0 - $prior) * (1.0 - $enhancedEvidenceStrength)
    $totalEvidence = $evidenceGivenSuccess + $evidenceGivenFailure
    
    $bayesianConfidence = if ($totalEvidence -gt 0) { 
        $evidenceGivenSuccess / $totalEvidence 
    } else { 
        $prior 
    }
    
    # Apply confidence calibration with CRPS consideration
    $calibratedConfidence = Invoke-CRPSCalibration -RawConfidence $bayesianConfidence -PatternType $PatternType -Context $PatternContext
    
    # Final smoothing with enhanced prior consideration
    $smoothedConfidence = ($calibratedConfidence * 0.85) + ($prior * 0.15)
    
    return [Math]::Max(0.1, [Math]::Min(0.99, $smoothedConfidence))
}

#endregion

#region Advanced Pattern Recognition Functions (Research-Based)

function Get-PositionWeightMatrixScore {
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$PatternContext = @{},
        
        [Parameter()]
        [hashtable]$PatternWeights = @{}
    )
    
    if ($PatternWeights.Count -eq 0 -or $PatternContext.Count -eq 0) {
        return 0.5  # Neutral score when no context or weights
    }
    
    $totalWeightedScore = 0.0
    $totalWeights = 0.0
    
    foreach ($contextKey in $PatternContext.Keys) {
        foreach ($weightKey in $PatternWeights.Keys) {
            # Calculate similarity between context and pattern weight keys
            $similarity = Get-KeySimilarityScore -Key1 $contextKey -Key2 $weightKey
            
            if ($similarity -gt 0.6) {  # Threshold for considering a match
                $contextValue = $PatternContext[$contextKey]
                $weight = $PatternWeights[$weightKey] * $similarity
                
                # Convert context value to probability if needed
                $probabilityValue = if ($contextValue -is [string]) {
                    Get-StringToProbabilityScore -Text $contextValue
                } elseif ($contextValue -is [bool]) {
                    if ($contextValue) { 0.9 } else { 0.1 }
                } else {
                    [Math]::Max(0.0, [Math]::Min(1.0, [double]$contextValue))
                }
                
                $totalWeightedScore += ($probabilityValue * $weight)
                $totalWeights += $weight
            }
        }
    }
    
    if ($totalWeights -eq 0) {
        return 0.5
    }
    
    $pwmScore = $totalWeightedScore / $totalWeights
    return [Math]::Max(0.1, [Math]::Min(0.9, $pwmScore))
}

function Get-KeySimilarityScore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Key1,
        
        [Parameter(Mandatory = $true)]
        [string]$Key2
    )
    
    # Convert to lowercase for comparison
    $k1 = $Key1.ToLower()
    $k2 = $Key2.ToLower()
    
    # Exact match
    if ($k1 -eq $k2) {
        return 1.0
    }
    
    # Contains match (either direction)
    if ($k1.Contains($k2) -or $k2.Contains($k1)) {
        return 0.8
    }
    
    # Fuzzy string similarity using longest common subsequence approach
    $lcs = Get-LongestCommonSubsequence -String1 $k1 -String2 $k2
    $maxLength = [Math]::Max($k1.Length, $k2.Length)
    
    if ($maxLength -eq 0) {
        return 0.0
    }
    
    $similarity = [double]$lcs / $maxLength
    return [Math]::Max(0.0, [Math]::Min(1.0, $similarity))
}

function Get-LongestCommonSubsequence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$String1,
        
        [Parameter(Mandatory = $true)]
        [string]$String2
    )
    
    $m = $String1.Length
    $n = $String2.Length
    
    # Create DP table
    $dp = New-Object 'int[,]' ($m + 1), ($n + 1)
    
    # Fill DP table
    for ($i = 1; $i -le $m; $i++) {
        for ($j = 1; $j -le $n; $j++) {
            if ($String1[$i-1] -eq $String2[$j-1]) {
                $dp[$i,$j] = $dp[$i-1,$j-1] + 1
            } else {
                $dp[$i,$j] = [Math]::Max($dp[$i-1,$j], $dp[$i,$j-1])
            }
        }
    }
    
    return $dp[$m,$n]
}

function Get-StringToProbabilityScore {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )
    
    if ([string]::IsNullOrWhiteSpace($Text)) {
        return 0.1
    }
    
    $text = $Text.ToLower().Trim()
    
    # High confidence indicators
    if ($text -match "(success|complete|ok|pass|valid|correct|good|high)") {
        return 0.85
    }
    
    # Medium confidence indicators
    if ($text -match "(warning|partial|maybe|possible|likely|medium)") {
        return 0.6
    }
    
    # Low confidence indicators  
    if ($text -match "(error|fail|invalid|wrong|bad|low|no|none)") {
        return 0.2
    }
    
    # Neutral indicators
    if ($text -match "(info|information|neutral|unknown|unclear)") {
        return 0.5
    }
    
    # Length-based heuristic for unknown text
    $lengthScore = [Math]::Min(0.8, $text.Length / 100.0)
    return [Math]::Max(0.3, 0.5 + $lengthScore)
}

function Invoke-CRPSCalibration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$RawConfidence,
        
        [Parameter(Mandatory = $true)]
        [string]$PatternType,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    # Get CRPS history for this pattern type
    $crpsHistory = @()
    if ($script:BayesianPriors.ContainsKey($PatternType) -and $script:BayesianPriors[$PatternType].CRPS_History) {
        $crpsHistory = $script:BayesianPriors[$PatternType].CRPS_History
    }
    
    if ($crpsHistory.Count -lt 5) {
        # Not enough history for CRPS calibration, return with minimal adjustment
        return [Math]::Max(0.1, [Math]::Min(0.9, $RawConfidence * 0.95))
    }
    
    # Calculate CRPS-based calibration
    $recentCRPS = $crpsHistory | Select-Object -Last 10
    $averageCRPS = ($recentCRPS | Measure-Object -Property Score -Average).Average
    $crpsVariance = ($recentCRPS | ForEach-Object { [Math]::Pow($_.Score - $averageCRPS, 2) } | Measure-Object -Average).Average
    
    # Calibration adjustment based on CRPS performance
    $calibrationFactor = if ($averageCRPS -lt 0.3) { 
        1.1  # Good CRPS performance, boost confidence
    } elseif ($averageCRPS -gt 0.7) { 
        0.9  # Poor CRPS performance, reduce confidence
    } else { 
        1.0  # Neutral adjustment
    }
    
    # Variance-based uncertainty adjustment
    $uncertaintyAdjustment = [Math]::Min(0.1, $crpsVariance * 0.5)
    
    $calibratedConfidence = ($RawConfidence * $calibrationFactor) - $uncertaintyAdjustment
    
    return [Math]::Max(0.1, [Math]::Min(0.95, $calibratedConfidence))
}

function Get-EntityBasedConfidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Entities
    )
    
    if ($Entities.Count -eq 0) {
        return 0.5
    }
    
    $totalConfidence = 0.0
    $weightedEntities = 0
    
    foreach ($entity in $Entities) {
        $entityConfidence = 0.7  # Base entity confidence
        
        # Boost confidence for validated entities
        if ($entity.IsValid) {
            $entityConfidence += 0.15
        }
        
        # Boost confidence for high-priority entities
        switch ($entity.Priority) {
            "Critical" { $entityConfidence += 0.2 }
            "High" { $entityConfidence += 0.1 }
            "Medium" { $entityConfidence += 0.05 }
        }
        
        # Weight by entity type importance
        $entityWeight = switch ($entity.Type) {
            "FilePath" { 1.2 }
            "PowerShellCommand" { 1.1 }
            "ErrorMessage" { 1.3 }
            "URL" { 0.9 }
            "Variable" { 0.8 }
            default { 1.0 }
        }
        
        $totalConfidence += ($entityConfidence * $entityWeight)
        $weightedEntities += $entityWeight
    }
    
    if ($weightedEntities -eq 0) {
        return 0.5
    }
    
    $averageConfidence = $totalConfidence / $weightedEntities
    
    # Apply entity count bonus (logarithmic)
    $entityCountBonus = [Math]::Log($Entities.Count + 1) / [Math]::Log(10) * 0.05
    $finalConfidence = $averageConfidence + $entityCountBonus
    
    return [Math]::Min(0.95, $finalConfidence)
}

function Get-BayesianAdjustment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Components
    )
    
    # Calculate agreement between different confidence sources
    $confidenceValues = @(
        $Components.RecommendationConfidence,
        $Components.ClassificationConfidence,
        $Components.EntityConfidence
    ) | Where-Object { $_ -gt 0.0 }
    
    if ($confidenceValues.Count -lt 2) {
        return 0.5  # No adjustment possible
    }
    
    # Calculate variance as a measure of agreement
    $mean = ($confidenceValues | Measure-Object -Average).Average
    $variance = 0.0
    
    foreach ($value in $confidenceValues) {
        $variance += [Math]::Pow($value - $mean, 2)
    }
    $variance = $variance / $confidenceValues.Count
    
    # Lower variance means higher agreement, higher confidence adjustment
    $maxVariance = 0.25  # Maximum expected variance
    $agreementFactor = [Math]::Max(0.0, 1.0 - ($variance / $maxVariance))
    
    # Bayesian adjustment based on agreement
    $bayesianAdjustment = $mean * (0.8 + ($agreementFactor * 0.2))
    
    return [Math]::Max(0.3, [Math]::Min(0.95, $bayesianAdjustment))
}

function Get-UncertaintyQuantification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Components
    )
    
    # Collect all confidence values
    $allConfidences = @()
    if ($Components.RecommendationConfidence -gt 0) { $allConfidences += $Components.RecommendationConfidence }
    if ($Components.ClassificationConfidence -gt 0) { $allConfidences += $Components.ClassificationConfidence }
    if ($Components.EntityConfidence -gt 0) { $allConfidences += $Components.EntityConfidence }
    
    if ($allConfidences.Count -eq 0) {
        return 0.5  # High uncertainty when no evidence
    }
    
    # Calculate standard deviation as uncertainty measure
    if ($allConfidences.Count -eq 1) {
        return 0.2  # Moderate uncertainty for single source
    }
    
    $mean = ($allConfidences | Measure-Object -Average).Average
    $variance = 0.0
    
    foreach ($confidence in $allConfidences) {
        $variance += [Math]::Pow($confidence - $mean, 2)
    }
    $variance = $variance / $allConfidences.Count
    $standardDeviation = [Math]::Sqrt($variance)
    
    # Normalize uncertainty to 0-1 range
    $maxExpectedStdDev = 0.3
    $uncertainty = [Math]::Min(1.0, $standardDeviation / $maxExpectedStdDev)
    
    return $uncertainty
}

function Invoke-FinalCalibration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$RawConfidence,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Components
    )
    
    # Apply Platt scaling for final calibration
    $plattA = 1.5  # Learned parameter
    $plattB = -0.8  # Learned parameter
    
    # Convert confidence to logit space
    $logit = [Math]::Log($RawConfidence / (1.0 - $RawConfidence))
    
    # Apply Platt scaling
    $scaledLogit = ($plattA * $logit) + $plattB
    $calibratedConfidence = 1.0 / (1.0 + [Math]::Exp(-$scaledLogit))
    
    # Apply conservative adjustment for uncertainty
    $uncertaintyPenalty = $Components.UncertaintyQuantification * 0.1
    $finalConfidence = $calibratedConfidence - $uncertaintyPenalty
    
    # Ensure reasonable bounds
    return [Math]::Max(0.05, [Math]::Min(0.99, $finalConfidence))
}

function Get-ConfidenceQualityRating {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$Confidence
    )
    
    if ($Confidence -ge 0.9) { return "Excellent" }
    elseif ($Confidence -ge 0.8) { return "High" }
    elseif ($Confidence -ge 0.7) { return "Good" }
    elseif ($Confidence -ge 0.6) { return "Moderate" }
    elseif ($Confidence -ge 0.5) { return "Fair" }
    else { return "Low" }
}

function Update-ConfidenceLearning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$Confidence,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Components,
        
        [Parameter(Mandatory = $true)]
        [int]$ProcessingTime
    )
    
    # Add to calibration history
    $entry = @{
        Timestamp = Get-Date
        Confidence = $Confidence
        Components = $Components.Clone()
        ProcessingTime = $ProcessingTime
        QualityRating = Get-ConfidenceQualityRating -Confidence $Confidence
    }
    
    $script:CalibrationHistory.Entries += $entry
    
    # Keep only recent history (last 500 entries)
    if ($script:CalibrationHistory.Entries.Count -gt 500) {
        # Keep only recent history (PowerShell 5.1 compatible)
        $entryCount = [int]$script:CalibrationHistory.Entries.Count
        if ($entryCount -gt 500) {
            $keepEntries = @()
            for ($i = ($entryCount - 500); $i -lt $entryCount; $i++) {
                $keepEntries += $script:CalibrationHistory.Entries[$i]
            }
            $script:CalibrationHistory.Entries = $keepEntries
        }
    }
    
    # Update calibration timestamp
    $script:CalibrationHistory.LastCalibration = Get-Date
}

function Update-BayesianPrior {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$PatternType,
        
        [Parameter(Mandatory = $true)]
        [bool]$Success
    )
    
    if (-not $script:BayesianPriors.ContainsKey($PatternType)) {
        $script:BayesianPriors[$PatternType] = @{ Success = 0; Total = 0; LastUpdated = (Get-Date) }
    }
    
    $prior = $script:BayesianPriors[$PatternType]
    
    if ($Success) {
        $prior.Success += 1
    }
    $prior.Total += 1
    $prior.LastUpdated = Get-Date
    
    # Apply exponential decay to weight recent results more heavily
    $decayFactor = 0.99
    $prior.Success = $prior.Success * $decayFactor
    $prior.Total = $prior.Total * $decayFactor
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Calculate-OverallConfidence',
    'Get-BayesianConfidence', 
    'Update-BayesianPrior',
    'Get-PositionWeightMatrixScore',
    'Get-LongestCommonSubsequence',
    'Invoke-CRPSCalibration',
    'Get-PatternRarityScore'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA+prn+DIcP6srQ
# 3bwg0iBRXeKs2JeJgjdtd2vlP120TKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEII2dIevM+8jXc3gdtzuMo61M
# 0wIhVMkR4pEi9LQ8pU22MA0GCSqGSIb3DQEBAQUABIIBAHYEpVZ7KTLxSJC3KlQR
# n0ghaGnGDRzmu1iWin5ak4XcDA9laKhRycqPnl4ShIbl1oPsxHzdUxyg4O56kOTM
# Zta2Y++24TTTphZtOMRPXMh4CsPNklWT12xFVOnu3Tv5mVE+m1VntcYNDrAWLk4L
# i8F1++5ZSpxtt0lOsuvIEpMKXriNRHkOqu726Dn+VqqRh50PMKClUkD/PRY6Gf8H
# j2srskejCyJxFW0BKHIpE/Rq/dBeFIxjYDRv86TpRDdkdi6b2Nt5DLERoeL9qG1l
# DwIFYO7lfx01f03ij9diKZ55xjAAsUkmlj3aJtWiEwnGn/CyZiCQT9BWwDYu+gdd
# HOU=
# SIG # End signature block
