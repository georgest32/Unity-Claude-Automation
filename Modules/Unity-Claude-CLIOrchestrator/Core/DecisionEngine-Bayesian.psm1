# DecisionEngine-Bayesian.psm1
# Phase 7 Day 3-4 Hours 5-8: Bayesian Confidence Adjustment Enhancement
# Advanced probabilistic decision-making with adaptive learning
# Date: 2025-08-25
#
# *** MONOLITHIC VERSION - USE DecisionEngine-Bayesian-Refactored.psm1 INSTEAD ***
# This file has been refactored into 8 focused components in the DecisionEngine-Bayesian/ directory.
# The refactored version provides the same functionality with better maintainability and modularity.
# This monolithic version is kept for reference and debugging purposes only.
#
Write-DecisionLog "Loading MONOLITHIC DecisionEngine-Bayesian - consider using DecisionEngine-Bayesian-Refactored.psm1" "WARN"

#region Bayesian Configuration

# Bayesian inference configuration
$script:BayesianConfig = @{
    # Prior probabilities for each decision type (initial beliefs)
    PriorProbabilities = @{
        CONTINUE = 0.50   # Moderate prior for continuation
        TEST = 0.30       # Moderate prior for testing
        FIX = 0.15        # Lower prior for fixes
        COMPILE = 0.10    # Lower prior for compilation
        RESTART = 0.05    # Low prior for restarts
        COMPLETE = 0.08   # Low prior for completion
        ERROR = 0.02      # Very low prior for errors
    }
    
    # Historical outcome tracking
    OutcomeHistory = @{
        CONTINUE = @{ Success = 0; Failure = 0; Total = 0 }
        TEST = @{ Success = 0; Failure = 0; Total = 0 }
        FIX = @{ Success = 0; Failure = 0; Total = 0 }
        COMPILE = @{ Success = 0; Failure = 0; Total = 0 }
        RESTART = @{ Success = 0; Failure = 0; Total = 0 }
        COMPLETE = @{ Success = 0; Failure = 0; Total = 0 }
        ERROR = @{ Success = 0; Failure = 0; Total = 0 }
    }
    
    # Learning parameters
    LearningRate = 0.1          # How quickly to update beliefs
    MinimumSamples = 10          # Minimum samples before significant adjustment
    ConfidenceDecay = 0.95       # Decay factor for old observations
    
    # Confidence bands
    ConfidenceBands = @{
        VeryHigh = 0.95
        High = 0.85
        Medium = 0.70
        Low = 0.50
        VeryLow = 0.30
    }
    
    # Uncertainty metrics
    UncertaintyThreshold = 0.2   # Maximum acceptable uncertainty
    EntropyThreshold = 2.0        # Maximum decision entropy
}

# Persistent storage for Bayesian learning
$script:BayesianStoragePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Data\BayesianLearning.json"

#endregion

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

#region Confidence Band Functions

# Determine confidence band based on adjusted confidence
function Get-ConfidenceBand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$Confidence
    )
    
    $bands = $script:BayesianConfig.ConfidenceBands
    
    if ($Confidence -ge $bands.VeryHigh) {
        return "VeryHigh"
    } elseif ($Confidence -ge $bands.High) {
        return "High"
    } elseif ($Confidence -ge $bands.Medium) {
        return "Medium"
    } elseif ($Confidence -ge $bands.Low) {
        return "Low"
    } else {
        return "VeryLow"
    }
}

# Calculate pattern confidence based on historical patterns
function Calculate-PatternConfidence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Patterns,
        
        [Parameter()]
        [hashtable]$HistoricalPatterns = @{}
    )
    
    Write-DecisionLog "Calculating pattern confidence for $($Patterns.Count) patterns" "DEBUG"
    
    $totalConfidence = 0.0
    $weightSum = 0.0
    
    foreach ($pattern in $Patterns) {
        $patternKey = "$($pattern.Type)_$($pattern.Category)"
        
        # Base confidence from pattern
        $baseConfidence = $pattern.Confidence
        
        # Historical adjustment if available
        if ($HistoricalPatterns.ContainsKey($patternKey)) {
            $historical = $HistoricalPatterns[$patternKey]
            $successRate = $historical.SuccessCount / [Math]::Max(1, $historical.TotalCount)
            $adjustedConfidence = ($baseConfidence * 0.6) + ($successRate * 0.4)
        } else {
            $adjustedConfidence = $baseConfidence
        }
        
        # Weight by pattern priority
        $weight = switch ($pattern.Priority) {
            1 { 1.5 }
            2 { 1.2 }
            3 { 1.0 }
            4 { 0.8 }
            default { 0.5 }
        }
        
        $totalConfidence += $adjustedConfidence * $weight
        $weightSum += $weight
    }
    
    if ($weightSum -gt 0) {
        $averageConfidence = $totalConfidence / $weightSum
    } else {
        $averageConfidence = 0.5  # Default confidence
    }
    
    return @{
        PatternConfidence = $averageConfidence
        PatternCount = $Patterns.Count
        ConfidenceBand = Get-ConfidenceBand -Confidence $averageConfidence
        WeightedScore = $totalConfidence
    }
}

#endregion

#region Learning and Adaptation

# Update Bayesian learning based on outcome
function Update-BayesianLearning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DecisionType,
        
        [Parameter(Mandatory = $true)]
        [bool]$Success,
        
        [Parameter()]
        [double]$ObservedConfidence = 0.0,
        
        [Parameter()]
        [hashtable]$Context = @{}
    )
    
    Write-DecisionLog "Updating Bayesian learning for $DecisionType - Success: $Success" "DEBUG"
    
    try {
        # Update outcome history
        $history = $script:BayesianConfig.OutcomeHistory[$DecisionType]
        if ($history) {
            $history.Total++
            if ($Success) {
                $history.Success++
            } else {
                $history.Failure++
            }
            
            # Apply decay to old observations
            if ($history.Total -gt 100) {
                $decay = $script:BayesianConfig.ConfidenceDecay
                $history.Success = [Math]::Floor($history.Success * $decay)
                $history.Failure = [Math]::Floor($history.Failure * $decay)
                $history.Total = $history.Success + $history.Failure
            }
        }
        
        # Update prior probabilities based on new evidence
        if ($history.Total -ge $script:BayesianConfig.MinimumSamples) {
            $currentPrior = $script:BayesianConfig.PriorProbabilities[$DecisionType]
            $observedRate = $history.Success / $history.Total
            $learningRate = $script:BayesianConfig.LearningRate
            
            # Exponential moving average update
            $newPrior = ($currentPrior * (1 - $learningRate)) + ($observedRate * $learningRate)
            $script:BayesianConfig.PriorProbabilities[$DecisionType] = [Math]::Round($newPrior, 4)
            
            Write-DecisionLog "Updated prior for $DecisionType from $currentPrior to $newPrior" "INFO"
        }
        
        # Persist learning to storage
        Save-BayesianLearning
        
        return @{
            Updated = $true
            DecisionType = $DecisionType
            NewStats = $history
            UpdatedPrior = $script:BayesianConfig.PriorProbabilities[$DecisionType]
        }
        
    } catch {
        Write-DecisionLog "Failed to update Bayesian learning: $($_.Exception.Message)" "ERROR"
        return @{
            Updated = $false
            Error = $_.Exception.Message
        }
    }
}

# Save Bayesian learning data to persistent storage
function Save-BayesianLearning {
    [CmdletBinding()]
    param()
    
    try {
        $data = @{
            PriorProbabilities = $script:BayesianConfig.PriorProbabilities
            OutcomeHistory = $script:BayesianConfig.OutcomeHistory
            LastUpdate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Version = "1.0"
        }
        
        # Create directory if it doesn't exist
        $directory = Split-Path -Path $script:BayesianStoragePath -Parent
        if (-not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        
        $data | ConvertTo-Json -Depth 10 | Out-File -FilePath $script:BayesianStoragePath -Encoding UTF8
        Write-DecisionLog "Bayesian learning data saved successfully" "DEBUG"
        
    } catch {
        Write-DecisionLog "Failed to save Bayesian learning data: $($_.Exception.Message)" "ERROR"
    }
}

# Load Bayesian learning data from persistent storage
function Initialize-BayesianLearning {
    [CmdletBinding()]
    param()
    
    try {
        if (Test-Path $script:BayesianStoragePath) {
            $data = Get-Content -Path $script:BayesianStoragePath -Raw | ConvertFrom-Json
            
            # Update configuration with loaded data
            if ($data.PriorProbabilities) {
                foreach ($key in $data.PriorProbabilities.PSObject.Properties.Name) {
                    $script:BayesianConfig.PriorProbabilities[$key] = $data.PriorProbabilities.$key
                }
            }
            
            if ($data.OutcomeHistory) {
                foreach ($key in $data.OutcomeHistory.PSObject.Properties.Name) {
                    $history = $data.OutcomeHistory.$key
                    $script:BayesianConfig.OutcomeHistory[$key] = @{
                        Success = $history.Success
                        Failure = $history.Failure
                        Total = $history.Total
                    }
                }
            }
            
            Write-DecisionLog "Bayesian learning data loaded from $($data.LastUpdate)" "INFO"
            return $true
        } else {
            Write-DecisionLog "No existing Bayesian learning data found - using defaults" "INFO"
            return $false
        }
        
    } catch {
        Write-DecisionLog "Failed to load Bayesian learning data: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

#endregion

#region Advanced Pattern Analysis

# Build n-gram model for pattern analysis
function Build-NGramModel {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter()]
        [int]$N = 3,
        
        [Parameter()]
        [switch]$IncludeStatistics
    )
    
    Write-DecisionLog "Building $N-gram model from text (length: $($Text.Length))" "DEBUG"
    
    $ngrams = @{}
    $words = $Text -split '\s+' | Where-Object { $_ -ne '' }
    
    if ($words.Count -lt $N) {
        Write-DecisionLog "Text too short for $N-gram analysis" "WARN"
        return @{
            NGrams = @{}
            Count = 0
            N = $N
        }
    }
    
    # Generate n-grams (PowerShell 5.1 compatible)
    for ($i = 0; $i -le ($words.Count - $N); $i++) {
        $ngramWords = @()
        for ($j = $i; $j -lt ($i + $N); $j++) {
            $ngramWords += $words[$j]
        }
        $ngram = $ngramWords -join ' '
        if ($ngrams.ContainsKey($ngram)) {
            $ngrams[$ngram]++
        } else {
            $ngrams[$ngram] = 1
        }
    }
    
    $result = @{
        NGrams = $ngrams
        Count = $ngrams.Count
        N = $N
        TotalWords = $words.Count
    }
    
    if ($IncludeStatistics) {
        # Calculate frequency statistics
        $frequencies = $ngrams.Values | Sort-Object -Descending
        $result.Statistics = @{
            MostCommon = ($ngrams.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 5)
            UniqueNGrams = $ngrams.Count
            TotalNGrams = ($frequencies | Measure-Object -Sum).Sum
            MaxFrequency = if ($frequencies.Count -gt 0) { $frequencies[0] } else { 0 }
            MeanFrequency = if ($frequencies.Count -gt 0) { ($frequencies | Measure-Object -Average).Average } else { 0 }
        }
    }
    
    return $result
}

# Calculate pattern similarity using multiple metrics
function Calculate-PatternSimilarity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern1,
        
        [Parameter(Mandatory = $true)]
        [string]$Pattern2,
        
        [Parameter()]
        [ValidateSet('Jaccard', 'Cosine', 'Levenshtein', 'All')]
        [string]$Method = 'All'
    )
    
    Write-DecisionLog "Calculating pattern similarity using method: $Method" "DEBUG"
    
    $similarities = @{}
    
    # Jaccard similarity
    if ($Method -eq 'Jaccard' -or $Method -eq 'All') {
        $set1 = $Pattern1 -split '\s+' | Where-Object { $_ -ne '' } | Sort-Object -Unique
        $set2 = $Pattern2 -split '\s+' | Where-Object { $_ -ne '' } | Sort-Object -Unique
        
        $intersection = $set1 | Where-Object { $_ -in $set2 }
        $union = $set1 + $set2 | Sort-Object -Unique
        
        if ($union.Count -gt 0) {
            $similarities.Jaccard = [Math]::Round($intersection.Count / $union.Count, 4)
        } else {
            $similarities.Jaccard = 0.0
        }
    }
    
    # Cosine similarity
    if ($Method -eq 'Cosine' -or $Method -eq 'All') {
        $words1 = $Pattern1 -split '\s+' | Where-Object { $_ -ne '' }
        $words2 = $Pattern2 -split '\s+' | Where-Object { $_ -ne '' }
        
        # Create term frequency vectors
        $allWords = $words1 + $words2 | Sort-Object -Unique
        $vector1 = @{}
        $vector2 = @{}
        
        foreach ($word in $allWords) {
            $vector1[$word] = ($words1 | Where-Object { $_ -eq $word }).Count
            $vector2[$word] = ($words2 | Where-Object { $_ -eq $word }).Count
        }
        
        # Calculate dot product and magnitudes
        $dotProduct = 0
        $magnitude1 = 0
        $magnitude2 = 0
        
        foreach ($word in $allWords) {
            $dotProduct += $vector1[$word] * $vector2[$word]
            $magnitude1 += $vector1[$word] * $vector1[$word]
            $magnitude2 += $vector2[$word] * $vector2[$word]
        }
        
        if ($magnitude1 -gt 0 -and $magnitude2 -gt 0) {
            $similarities.Cosine = [Math]::Round($dotProduct / ([Math]::Sqrt($magnitude1) * [Math]::Sqrt($magnitude2)), 4)
        } else {
            $similarities.Cosine = 0.0
        }
    }
    
    # Levenshtein distance (normalized)
    if ($Method -eq 'Levenshtein' -or $Method -eq 'All') {
        $distance = Get-LevenshteinDistance -String1 $Pattern1 -String2 $Pattern2
        $maxLength = [Math]::Max($Pattern1.Length, $Pattern2.Length)
        if ($maxLength -gt 0) {
            $similarities.Levenshtein = [Math]::Round(1 - ($distance / $maxLength), 4)
        } else {
            $similarities.Levenshtein = 1.0
        }
    }
    
    # Calculate combined similarity if all methods used
    if ($Method -eq 'All' -and $similarities.Count -gt 0) {
        $similarities.Combined = [Math]::Round(($similarities.Values | Measure-Object -Average).Average, 4)
    }
    
    return $similarities
}

# Calculate Levenshtein distance
function Get-LevenshteinDistance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$String1,
        
        [Parameter(Mandatory = $true)]
        [string]$String2
    )
    
    $len1 = $String1.Length
    $len2 = $String2.Length
    
    # Create distance matrix
    $matrix = New-Object 'int[,]' ($len1 + 1), ($len2 + 1)
    
    # Initialize first column and row
    for ($i = 0; $i -le $len1; $i++) {
        $matrix[$i, 0] = $i
    }
    for ($j = 0; $j -le $len2; $j++) {
        $matrix[0, $j] = $j
    }
    
    # Calculate distances
    for ($i = 1; $i -le $len1; $i++) {
        for ($j = 1; $j -le $len2; $j++) {
            $cost = if ($String1[$i - 1] -eq $String2[$j - 1]) { 0 } else { 1 }
            
            $matrix[$i, $j] = [Math]::Min(
                [Math]::Min(
                    $matrix[$i - 1, $j] + 1,      # Deletion
                    $matrix[$i, $j - 1] + 1       # Insertion
                ),
                $matrix[$i - 1, $j - 1] + $cost   # Substitution
            )
        }
    }
    
    return $matrix[$len1, $len2]
}

#endregion

#region Entity Relationship Management

# Build entity relationship graph
function Build-EntityRelationshipGraph {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Entities,
        
        [Parameter()]
        [double]$ProximityThreshold = 50,  # Characters apart to be considered related
        
        [Parameter()]
        [switch]$IncludeMetrics
    )
    
    Write-DecisionLog "Building entity relationship graph for $($Entities.Count) entities" "DEBUG"
    
    $graph = @{
        Nodes = @{}
        Edges = @()
        Clusters = @()
    }
    
    # Create nodes for each entity
    foreach ($entity in $Entities) {
        $nodeId = "$($entity.Type)_$($entity.Value)"
        $graph.Nodes[$nodeId] = @{
            Type = $entity.Type
            Value = $entity.Value
            Position = $entity.Position
            Confidence = $entity.Confidence
            Connections = @()
        }
    }
    
    # Create edges based on proximity and type relationships
    for ($i = 0; $i -lt $Entities.Count; $i++) {
        for ($j = $i + 1; $j -lt $Entities.Count; $j++) {
            $entity1 = $Entities[$i]
            $entity2 = $Entities[$j]
            
            # Calculate proximity if positions available
            if ($entity1.Position -ge 0 -and $entity2.Position -ge 0) {
                $distance = [Math]::Abs($entity1.Position - $entity2.Position)
                
                if ($distance -le $ProximityThreshold) {
                    $edge = @{
                        Source = "$($entity1.Type)_$($entity1.Value)"
                        Target = "$($entity2.Type)_$($entity2.Value)"
                        Weight = 1 - ($distance / $ProximityThreshold)  # Closer = higher weight
                        Type = "Proximity"
                    }
                    $graph.Edges += $edge
                    
                    # Update node connections
                    $graph.Nodes[$edge.Source].Connections += $edge.Target
                    $graph.Nodes[$edge.Target].Connections += $edge.Source
                }
            }
            
            # Check for semantic relationships
            if ($entity1.Type -eq 'FilePath' -and $entity2.Type -eq 'PowerShellCommand') {
                # Commands often operate on files
                $edge = @{
                    Source = "$($entity1.Type)_$($entity1.Value)"
                    Target = "$($entity2.Type)_$($entity2.Value)"
                    Weight = 0.8
                    Type = "Semantic"
                }
                $graph.Edges += $edge
            }
        }
    }
    
    # Identify clusters (connected components)
    $visited = @{}
    foreach ($nodeId in $graph.Nodes.Keys) {
        if (-not $visited.ContainsKey($nodeId)) {
            $cluster = Find-EntityCluster -Graph $graph -StartNode $nodeId -Visited $visited
            if ($cluster.Count -gt 1) {
                $graph.Clusters += $cluster
            }
        }
    }
    
    if ($IncludeMetrics) {
        $graph.Metrics = @{
            NodeCount = $graph.Nodes.Count
            EdgeCount = $graph.Edges.Count
            ClusterCount = $graph.Clusters.Count
            AverageDegree = if ($graph.Nodes.Count -gt 0) {
                ($graph.Nodes.Values | ForEach-Object { $_.Connections.Count } | Measure-Object -Average).Average
            } else { 0 }
            Density = if ($graph.Nodes.Count -gt 1) {
                (2 * $graph.Edges.Count) / ($graph.Nodes.Count * ($graph.Nodes.Count - 1))
            } else { 0 }
        }
    }
    
    Write-DecisionLog "Entity graph built: $($graph.Nodes.Count) nodes, $($graph.Edges.Count) edges, $($graph.Clusters.Count) clusters" "INFO"
    
    return $graph
}

# Find entity cluster using depth-first search
function Find-EntityCluster {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory = $true)]
        [string]$StartNode,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Visited
    )
    
    $cluster = @()
    $stack = New-Object System.Collections.Stack
    $stack.Push($StartNode)
    
    while ($stack.Count -gt 0) {
        $current = $stack.Pop()
        
        if (-not $Visited.ContainsKey($current)) {
            $Visited[$current] = $true
            $cluster += $current
            
            # Add connected nodes to stack
            $node = $Graph.Nodes[$current]
            if ($node -and $node.Connections) {
                foreach ($connection in $node.Connections) {
                    if (-not $Visited.ContainsKey($connection)) {
                        $stack.Push($connection)
                    }
                }
            }
        }
    }
    
    return $cluster
}

# Measure entity proximity in graph
function Measure-EntityProximity {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Graph,
        
        [Parameter(Mandatory = $true)]
        [string]$Entity1,
        
        [Parameter(Mandatory = $true)]
        [string]$Entity2
    )
    
    # Use breadth-first search to find shortest path
    if (-not $Graph.Nodes.ContainsKey($Entity1) -or -not $Graph.Nodes.ContainsKey($Entity2)) {
        return @{
            Distance = -1
            Path = @()
            Connected = $false
        }
    }
    
    if ($Entity1 -eq $Entity2) {
        return @{
            Distance = 0
            Path = @($Entity1)
            Connected = $true
        }
    }
    
    $queue = New-Object System.Collections.Queue
    $visited = @{ $Entity1 = $true }
    $parent = @{ $Entity1 = $null }
    $queue.Enqueue($Entity1)
    
    $found = $false
    while ($queue.Count -gt 0 -and -not $found) {
        $current = $queue.Dequeue()
        
        foreach ($neighbor in $Graph.Nodes[$current].Connections) {
            if (-not $visited.ContainsKey($neighbor)) {
                $visited[$neighbor] = $true
                $parent[$neighbor] = $current
                $queue.Enqueue($neighbor)
                
                if ($neighbor -eq $Entity2) {
                    $found = $true
                    break
                }
            }
        }
    }
    
    if ($found) {
        # Reconstruct path
        $path = @()
        $current = $Entity2
        while ($current -ne $null) {
            $path = @($current) + $path
            $current = $parent[$current]
        }
        
        return @{
            Distance = $path.Count - 1
            Path = $path
            Connected = $true
        }
    } else {
        return @{
            Distance = -1
            Path = @()
            Connected = $false
        }
    }
}

#endregion

#region Temporal Context Tracking

# Temporal context storage
$script:TemporalContext = @{
    RecentDecisions = New-Object System.Collections.Queue
    MaxHistorySize = 50
    TimeWindows = @{
        Immediate = 60      # 1 minute
        Recent = 300        # 5 minutes
        Short = 1800        # 30 minutes
        Medium = 7200       # 2 hours
        Long = 86400        # 24 hours
    }
}

# Add temporal context to decision
function Add-TemporalContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Decision,
        
        [Parameter()]
        [int]$TimeWindowSeconds = 300
    )
    
    Write-DecisionLog "Adding temporal context with window: ${TimeWindowSeconds}s" "DEBUG"
    
    $now = Get-Date
    $decision.Timestamp = $now
    
    # Add to recent decisions queue
    $script:TemporalContext.RecentDecisions.Enqueue($decision)
    
    # Maintain queue size
    while ($script:TemporalContext.RecentDecisions.Count -gt $script:TemporalContext.MaxHistorySize) {
        $script:TemporalContext.RecentDecisions.Dequeue() | Out-Null
    }
    
    # Analyze recent patterns
    $recentDecisions = @($script:TemporalContext.RecentDecisions.ToArray() | 
        Where-Object { ($now - $_.Timestamp).TotalSeconds -le $TimeWindowSeconds })
    
    $temporalAnalysis = @{
        WindowSize = $TimeWindowSeconds
        DecisionCount = $recentDecisions.Count
        TimeRange = if ($recentDecisions.Count -gt 0) {
            @{
                Start = ($recentDecisions | Sort-Object Timestamp | Select-Object -First 1).Timestamp
                End = $now
            }
        } else { @{} }
    }
    
    # Analyze decision type frequency
    if ($recentDecisions.Count -gt 0) {
        $typeFrequency = $recentDecisions | Group-Object DecisionType | ForEach-Object {
            @{
                Type = $_.Name
                Count = $_.Count
                Percentage = [Math]::Round(($_.Count / $recentDecisions.Count) * 100, 2)
            }
        } | Sort-Object Count -Descending
        
        $temporalAnalysis.TypeFrequency = $typeFrequency
        $temporalAnalysis.DominantType = $typeFrequency[0].Type
        
        # Calculate decision velocity (decisions per minute)
        $timeSpan = ($now - $temporalAnalysis.TimeRange.Start).TotalMinutes
        if ($timeSpan -gt 0) {
            $temporalAnalysis.DecisionVelocity = [Math]::Round($recentDecisions.Count / $timeSpan, 2)
        }
        
        # Detect patterns
        $temporalAnalysis.Patterns = @{
            Repetitive = ($typeFrequency[0].Percentage -gt 60)
            HighVelocity = ($temporalAnalysis.DecisionVelocity -gt 10)
            LowVariety = ($typeFrequency.Count -le 2)
        }
    }
    
    $decision.TemporalContext = $temporalAnalysis
    
    return $decision
}

# Get temporal context relevance
function Get-TemporalContextRelevance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DecisionType,
        
        [Parameter()]
        [string]$TimeWindow = 'Recent'
    )
    
    $windowSeconds = $script:TemporalContext.TimeWindows[$TimeWindow]
    if (-not $windowSeconds) {
        Write-DecisionLog "Unknown time window: $TimeWindow - using Recent" "WARN"
        $windowSeconds = $script:TemporalContext.TimeWindows.Recent
    }
    
    $now = Get-Date
    $relevantDecisions = @($script:TemporalContext.RecentDecisions.ToArray() | 
        Where-Object { 
            ($now - $_.Timestamp).TotalSeconds -le $windowSeconds -and
            $_.DecisionType -eq $DecisionType
        })
    
    if ($relevantDecisions.Count -eq 0) {
        return @{
            Relevance = 0.5  # Neutral relevance
            SampleSize = 0
            TimeWindow = $TimeWindow
            Message = "No recent decisions of type $DecisionType"
        }
    }
    
    # Calculate success rate
    $successCount = @($relevantDecisions | Where-Object { $_.Success -eq $true }).Count
    $successRate = $successCount / $relevantDecisions.Count
    
    # Calculate recency weight (more recent = higher weight)
    $weights = $relevantDecisions | ForEach-Object {
        $age = ($now - $_.Timestamp).TotalSeconds
        1 - ($age / $windowSeconds)  # Linear decay
    }
    $averageWeight = ($weights | Measure-Object -Average).Average
    
    # Combine success rate and recency
    $relevance = ($successRate * 0.7) + ($averageWeight * 0.3)
    
    return @{
        Relevance = [Math]::Round($relevance, 3)
        SampleSize = $relevantDecisions.Count
        TimeWindow = $TimeWindow
        SuccessRate = [Math]::Round($successRate, 3)
        RecencyFactor = [Math]::Round($averageWeight, 3)
        Message = "Based on $($relevantDecisions.Count) recent decisions"
    }
}

#endregion

#region Enhanced Pattern Analysis Integration

# Main enhanced pattern analysis function
function Invoke-EnhancedPatternAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AnalysisResult,
        
        [Parameter()]
        [switch]$UseBayesian,
        
        [Parameter()]
        [switch]$IncludeNGrams,
        
        [Parameter()]
        [switch]$BuildEntityGraph,
        
        [Parameter()]
        [switch]$AddTemporalContext
    )
    
    Write-DecisionLog "Starting enhanced pattern analysis" "INFO"
    $startTime = Get-Date
    
    $enhancedResult = $AnalysisResult.Clone()
    
    try {
        # Apply Bayesian confidence adjustment
        if ($UseBayesian -and $AnalysisResult.Recommendations) {
            foreach ($rec in $AnalysisResult.Recommendations) {
                $bayesianResult = Invoke-BayesianConfidenceAdjustment `
                    -DecisionType $rec.Type `
                    -ObservedConfidence $rec.Confidence `
                    -ReturnDetails
                
                $rec | Add-Member -NotePropertyName 'BayesianConfidence' -NotePropertyValue $bayesianResult.AdjustedConfidence -Force
                $rec | Add-Member -NotePropertyName 'ConfidenceBand' -NotePropertyValue $bayesianResult.ConfidenceBand -Force
                $rec | Add-Member -NotePropertyName 'Uncertainty' -NotePropertyValue $bayesianResult.Uncertainty -Force
            }
        }
        
        # Build n-gram model for response text
        if ($IncludeNGrams -and $AnalysisResult.ResponseText) {
            $ngramModel = Build-NGramModel -Text $AnalysisResult.ResponseText -N 3 -IncludeStatistics
            $enhancedResult | Add-Member -NotePropertyName 'NGramAnalysis' -NotePropertyValue $ngramModel -Force
        }
        
        # Build entity relationship graph
        if ($BuildEntityGraph -and $AnalysisResult.Entities) {
            $allEntities = @()
            
            # Collect all entities with positions
            $position = 0
            if ($AnalysisResult.Entities.FilePaths) {
                foreach ($path in $AnalysisResult.Entities.FilePaths) {
                    $allEntities += @{
                        Type = 'FilePath'
                        Value = if ($path -is [string]) { $path } else { $path.Value }
                        Position = $position
                        Confidence = if ($path.Confidence) { $path.Confidence } else { 0.9 }
                    }
                    $position += 100
                }
            }
            
            if ($AnalysisResult.Entities.PowerShellCommands) {
                foreach ($cmd in $AnalysisResult.Entities.PowerShellCommands) {
                    $allEntities += @{
                        Type = 'PowerShellCommand'
                        Value = $cmd.Value
                        Position = $position
                        Confidence = $cmd.Confidence
                    }
                    $position += 100
                }
            }
            
            if ($allEntities.Count -gt 0) {
                $entityGraph = Build-EntityRelationshipGraph -Entities $allEntities -IncludeMetrics
                $enhancedResult | Add-Member -NotePropertyName 'EntityGraph' -NotePropertyValue $entityGraph -Force
            }
        }
        
        # Add temporal context
        if ($AddTemporalContext) {
            $primaryRecommendation = $AnalysisResult.Recommendations | Select-Object -First 1
            if ($primaryRecommendation) {
                $temporalDecision = @{
                    DecisionType = $primaryRecommendation.Type
                    Confidence = $primaryRecommendation.Confidence
                    Success = $null  # Will be updated after execution
                }
                
                $temporalDecision = Add-TemporalContext -Decision $temporalDecision
                $enhancedResult | Add-Member -NotePropertyName 'TemporalContext' -NotePropertyValue $temporalDecision.TemporalContext -Force
                
                # Get relevance for this decision type
                $relevance = Get-TemporalContextRelevance -DecisionType $primaryRecommendation.Type
                $enhancedResult | Add-Member -NotePropertyName 'TemporalRelevance' -NotePropertyValue $relevance -Force
            }
        }
        
        $processingTime = ((Get-Date) - $startTime).TotalMilliseconds
        $enhancedResult | Add-Member -NotePropertyName 'EnhancementTimeMs' -NotePropertyValue $processingTime -Force
        
        Write-DecisionLog "Enhanced pattern analysis completed in ${processingTime}ms" "SUCCESS"
        
        return $enhancedResult
        
    } catch {
        Write-DecisionLog "Enhanced pattern analysis failed: $($_.Exception.Message)" "ERROR"
        return $AnalysisResult  # Return original on failure
    }
}

#endregion

#region Module Initialization

# Initialize Bayesian learning from storage
Initialize-BayesianLearning | Out-Null

# Log module load
Write-DecisionLog "DecisionEngine-Bayesian module loaded with enhanced capabilities" "SUCCESS"

#endregion

# Export enhanced functions
Export-ModuleMember -Function @(
    # Bayesian Core
    'Invoke-BayesianConfidenceAdjustment',
    'Get-BayesianPrior',
    'Calculate-BayesianLikelihood',
    'Calculate-BayesianEvidence',
    'Calculate-ContextualAdjustment',
    'Calculate-BayesianUncertainty',
    
    # Confidence and Patterns
    'Get-ConfidenceBand',
    'Calculate-PatternConfidence',
    'Calculate-PatternSimilarity',
    
    # Learning and Adaptation
    'Update-BayesianLearning',
    'Save-BayesianLearning',
    'Initialize-BayesianLearning',
    
    # N-Gram Analysis
    'Build-NGramModel',
    'Get-LevenshteinDistance',
    
    # Entity Relationships
    'Build-EntityRelationshipGraph',
    'Find-EntityCluster',
    'Measure-EntityProximity',
    
    # Temporal Context
    'Add-TemporalContext',
    'Get-TemporalContextRelevance',
    
    # Enhanced Integration
    'Invoke-EnhancedPatternAnalysis'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBeqjhONe/HwO34
# cAANFi4a7yppxt67R0xj1HtB9F+Ie6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJIda4VEwXp1gS0i1rPO17Rn
# pzEiJQAv6IPZC2CdBDjHMA0GCSqGSIb3DQEBAQUABIIBAJsQz/IJDWUVCVfdzkJb
# v0sH2JjJkw8v7g8XaERPFV7aChlHySTS0xCxi7/WtMeBkt1ZOJXfrSrxV8wj8JFe
# StZY2AQvu7680LRV3s8JxQKkFZL23M0apDk9Rs4dTX+8wTAMh+lnMyKZr0KevII8
# 1TOJdxJyKZoVIqQuKPbB7uR3FWbSsrnDGpNFdl2GBqGTWw1iPHMEdw+CJuT0WZ3k
# ds8kGjVk0HgKk4JmTMzXIbC5Ov1LhfemL7pXUZxZjhNSsupnUnS2u+tgmM2AcZ/o
# aWU9p9aY+A6N43g+ZnSpTzhg6DwZF0bM5+K9pbB8x8IzREroV16M1hbpUYLYpLp9
# p8M=
# SIG # End signature block
