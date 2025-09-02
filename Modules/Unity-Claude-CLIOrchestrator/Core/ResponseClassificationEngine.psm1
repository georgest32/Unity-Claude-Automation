# Unity-Claude-CLIOrchestrator - Response Classification & Ensemble Engine  
# Phase 7 Day 1-2 Hours 5-8: Enhanced Response Type Classification
# Compatible with PowerShell 5.1 and Claude Code CLI 2025

#region Classification Configuration

$script:ClassificationTypes = @(
    "Instruction",
    "Question", 
    "Information",
    "Error",
    "Complete",
    "TestResult",
    "Continuation"
)

# Classification statistics tracking
$script:ClassificationStats = @{
    Classifications = @{}
    ConfidenceHistory = @()
    LastCalibration = $null
    TotalClassifications = 0
}

# Feature engineering patterns for enhanced classification
$script:FeaturePatterns = @{
    QuestionIndicators = @(
        '\?',
        '(?i)^(?:what|how|why|when|where|who|which|should|could|would|can|do|does|did|is|are|was|were)\b',
        '(?i)\b(?:help|assist|guide|recommend|suggest|advice)\b'
    )
    InstructionIndicators = @(
        '(?i)^(?:recommendation|action|execute|run|start|stop|create|delete|modify|fix|test|compile|build)\b',
        '(?i)\b(?:need to|should|must|required|necessary)\b',
        '(?i)\b(?:step\s*\d+|first|then|next|finally)\b'
    )
    ErrorIndicators = @(
        '(?i)^(?:error|exception|failure|critical|warning)\b',
        '(?i)\b(?:failed|crashed|broken|timeout|invalid|missing)\b',
        '(?i)\b(?:cannot|unable|could not|failed to)\b'
    )
    CompletionIndicators = @(
        '(?i)^(?:complete|finished|done|success|accomplished)\b',
        '(?i)\b(?:completed successfully|task finished|all done)\b'
    )
    InformationIndicators = @(
        '(?i)^(?:info|note|notice|status|report|summary)\b',
        '(?i)\b(?:found|detected|discovered|identified|located)\b'
    )
}

#endregion

#region Enhanced Feature Engineering

function Get-EnhancedFeatureEngineering {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent,
        
        [Parameter()]
        [array]$Recommendations = @(),
        
        [Parameter()]
        [array]$Entities = @()
    )
    
    $features = @{}
    
    # Basic text features
    $features.Length = $ResponseContent.Length
    $features.WordCount = ($ResponseContent -split '\s+').Count
    $features.SentenceCount = ($ResponseContent -split '[.!?]').Count
    $features.LineCount = ($ResponseContent -split '\r?\n').Count
    $features.CapitalizedWords = ([regex]::Matches($ResponseContent, '\b[A-Z][a-z]+\b')).Count
    $features.AllCapsWords = ([regex]::Matches($ResponseContent, '\b[A-Z]{2,}\b')).Count
    $features.NumberCount = ([regex]::Matches($ResponseContent, '\b\d+\b')).Count
    $features.SpecialCharCount = ([regex]::Matches($ResponseContent, '[!@#$%^&*()_+={}\[\]|\\:";''<>?,./]')).Count
    
    # Punctuation features
    $features.QuestionMarks = ([regex]::Matches($ResponseContent, '\?')).Count
    $features.ExclamationMarks = ([regex]::Matches($ResponseContent, '!')).Count
    $features.Periods = ([regex]::Matches($ResponseContent, '\.')).Count
    $features.Colons = ([regex]::Matches($ResponseContent, ':')).Count
    
    # Linguistic features
    $features.HasQuestionWords = Test-FeaturePattern -Content $ResponseContent -Patterns $script:FeaturePatterns.QuestionIndicators
    $features.HasInstructionWords = Test-FeaturePattern -Content $ResponseContent -Patterns $script:FeaturePatterns.InstructionIndicators
    $features.HasErrorWords = Test-FeaturePattern -Content $ResponseContent -Patterns $script:FeaturePatterns.ErrorIndicators
    $features.HasCompletionWords = Test-FeaturePattern -Content $ResponseContent -Patterns $script:FeaturePatterns.CompletionIndicators
    $features.HasInformationWords = Test-FeaturePattern -Content $ResponseContent -Patterns $script:FeaturePatterns.InformationIndicators
    
    # Semantic features based on content analysis
    $features.StartsWithRecommendation = $ResponseContent -match '(?i)^RECOMMENDATION:'
    $features.StartsWithError = $ResponseContent -match '(?i)^ERROR:'
    $features.StartsWithComplete = $ResponseContent -match '(?i)^(?:COMPLETE|DONE|FINISHED):'
    $features.StartsWithQuestion = $ResponseContent -match '(?i)^(?:WHAT|HOW|WHY|WHEN|WHERE|WHO|WHICH|SHOULD|COULD|WOULD|CAN|DO|DOES|DID|IS|ARE|WAS|WERE)\b'
    
    # Entity-based features
    $features.RecommendationCount = $Recommendations.Count
    $features.EntityCount = $Entities.Count
    $features.FilePathCount = ($Entities | Where-Object { $_.Type -eq "FilePath" }).Count
    $features.CommandCount = ($Entities | Where-Object { $_.Type -eq "PowerShellCommand" }).Count
    $features.ErrorEntityCount = ($Entities | Where-Object { $_.Type -eq "ErrorMessage" }).Count
    $features.UrlCount = ($Entities | Where-Object { $_.Type -eq "URL" }).Count
    
    # Advanced pattern-based features
    $features.HasCodeBlocks = $ResponseContent -match '```|`[^`]+`'
    $features.HasFilePaths = $ResponseContent -match '[A-Z]:\\[^<>:"|?*\r\n]*\.[a-zA-Z0-9]+'
    $features.HasCommandSyntax = $ResponseContent -match '[A-Z][a-zA-Z]*-[A-Z][a-zA-Z0-9]*'
    $features.HasErrorCodes = $ResponseContent -match '\b(?:CS|BC|FS|CA|AD|MSB)\d{4,}\b'
    
    # Confidence and priority features
    if ($Recommendations.Count -gt 0) {
        $features.MaxRecommendationConfidence = ($Recommendations | Measure-Object -Property Confidence -Maximum).Maximum
        $features.AvgRecommendationConfidence = ($Recommendations | Measure-Object -Property Confidence -Average).Average
        $features.HighPriorityRecommendations = ($Recommendations | Where-Object { $_.Priority -eq "High" -or $_.Priority -eq "Critical" }).Count
    }
    else {
        $features.MaxRecommendationConfidence = 0.0
        $features.AvgRecommendationConfidence = 0.0
        $features.HighPriorityRecommendations = 0
    }
    
    return $features
}

function Test-FeaturePattern {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [array]$Patterns
    )
    
    foreach ($pattern in $Patterns) {
        if ($Content -match $pattern) {
            return $true
        }
    }
    
    return $false
}

#endregion

#region Ensemble Classification System

function Classify-ResponseType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent,
        
        [Parameter()]
        [array]$Recommendations = @(),
        
        [Parameter()]
        [array]$Entities = @()
    )
    
    $classificationStart = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Enhanced feature engineering
    $features = Get-EnhancedFeatureEngineering -ResponseContent $ResponseContent -Recommendations $Recommendations -Entities $Entities
    
    # Run ensemble classifiers
    $classifiers = @(
        (Invoke-DecisionTreeClassifier -Features $features -ResponseContent $ResponseContent),
        (Invoke-FeatureBasedClassifier -Features $features),
        (Invoke-RecommendationClassifier -Recommendations $Recommendations -Features $features),
        (Invoke-EntityContextClassifier -Entities $Entities -Features $features)
    )
    
    # Ensemble voting with weighted confidence
    $ensembleResult = Invoke-EnsembleVoting -ClassifierResults $classifiers -Features $features
    
    # Apply Bayesian calibration for final confidence
    $finalResult = Invoke-BayesianClassificationCalibration -Classification $ensembleResult.Classification -Confidence $ensembleResult.Confidence -Features $features
    
    $classificationStart.Stop()
    
    # Update classification statistics
    Update-ClassificationStatistics -Classification $finalResult -ProcessingTime $classificationStart.ElapsedMilliseconds
    
    return @{
        Type = $finalResult.Type
        Confidence = $finalResult.Confidence
        Reasoning = $finalResult.Reasoning
        EnsembleDetails = @{
            ClassifierCount = $classifiers.Count
            Agreement = $ensembleResult.Agreement
            WeightedVotes = $ensembleResult.WeightedVotes
        }
        Features = $features
        ProcessingTimeMs = $classificationStart.ElapsedMilliseconds
    }
}

function Invoke-DecisionTreeClassifier {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Features,
        
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent
    )
    
    # Decision tree logic with multiple paths
    
    # Error classification (highest priority)
    if ($Features.HasErrorWords -or $Features.StartsWithError -or $Features.ErrorEntityCount -gt 0) {
        $confidence = 0.95
        if ($Features.StartsWithError) { $confidence += 0.03 }
        if ($Features.ErrorEntityCount -gt 0) { $confidence += 0.02 }
        return @{ Type = "Error"; Confidence = [Math]::Min(0.99, $confidence); Reasoning = "Decision tree detected error indicators" }
    }
    
    # Completion classification
    if ($Features.HasCompletionWords -or $Features.StartsWithComplete) {
        $confidence = 0.88
        if ($Features.StartsWithComplete) { $confidence += 0.05 }
        return @{ Type = "Complete"; Confidence = [Math]::Min(0.99, $confidence); Reasoning = "Decision tree detected completion indicators" }
    }
    
    # Instruction classification
    if ($Features.HasInstructionWords -or $Features.StartsWithRecommendation -or $Features.RecommendationCount -gt 0) {
        $confidence = 0.85
        if ($Features.StartsWithRecommendation) { $confidence += 0.08 }
        if ($Features.RecommendationCount -gt 0) { $confidence += ($Features.RecommendationCount * 0.03) }
        return @{ Type = "Instruction"; Confidence = [Math]::Min(0.99, $confidence); Reasoning = "Decision tree detected instruction indicators" }
    }
    
    # Question classification
    if ($Features.HasQuestionWords -or $Features.QuestionMarks -gt 0 -or $Features.StartsWithQuestion) {
        $confidence = 0.82
        if ($Features.StartsWithQuestion) { $confidence += 0.06 }
        if ($Features.QuestionMarks -gt 0) { $confidence += ($Features.QuestionMarks * 0.04) }
        return @{ Type = "Question"; Confidence = [Math]::Min(0.99, $confidence); Reasoning = "Decision tree detected question indicators" }
    }
    
    # Information classification (default)
    $confidence = 0.75
    if ($Features.HasInformationWords) { $confidence += 0.05 }
    return @{ Type = "Information"; Confidence = $confidence; Reasoning = "Decision tree default classification" }
}

function Invoke-FeatureBasedClassifier {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Features
    )
    
    # Feature-based probabilistic scoring
    $scores = @{}
    
    foreach ($type in $script:ClassificationTypes) {
        $scores[$type] = 0.0
    }
    
    # Error type scoring
    if ($Features.HasErrorWords) { $scores["Error"] += 0.4 }
    if ($Features.StartsWithError) { $scores["Error"] += 0.3 }
    if ($Features.ErrorEntityCount -gt 0) { $scores["Error"] += ($Features.ErrorEntityCount * 0.15) }
    if ($Features.HasErrorCodes) { $scores["Error"] += 0.2 }
    
    # Instruction type scoring
    if ($Features.HasInstructionWords) { $scores["Instruction"] += 0.35 }
    if ($Features.StartsWithRecommendation) { $scores["Instruction"] += 0.4 }
    if ($Features.RecommendationCount -gt 0) { $scores["Instruction"] += ($Features.RecommendationCount * 0.2) }
    if ($Features.CommandCount -gt 0) { $scores["Instruction"] += ($Features.CommandCount * 0.1) }
    
    # Question type scoring
    if ($Features.HasQuestionWords) { $scores["Question"] += 0.4 }
    if ($Features.QuestionMarks -gt 0) { $scores["Question"] += ($Features.QuestionMarks * 0.25) }
    if ($Features.StartsWithQuestion) { $scores["Question"] += 0.3 }
    
    # Complete type scoring
    if ($Features.HasCompletionWords) { $scores["Complete"] += 0.4 }
    if ($Features.StartsWithComplete) { $scores["Complete"] += 0.35 }
    
    # Information type scoring (baseline)
    if ($Features.HasInformationWords) { $scores["Information"] += 0.3 }
    if ($Features.EntityCount -gt 0) { $scores["Information"] += ($Features.EntityCount * 0.05) }
    
    # Find highest scoring type
    $maxScore = ($scores.Values | Measure-Object -Maximum).Maximum
    $bestType = ($scores.GetEnumerator() | Where-Object { $_.Value -eq $maxScore } | Select-Object -First 1).Key
    
    # Normalize confidence
    $confidence = [Math]::Min(0.95, [Math]::Max(0.6, $maxScore))
    
    return @{ 
        Type = $bestType
        Confidence = $confidence
        Reasoning = "Feature-based classifier scored $bestType highest ($($maxScore.ToString('F2')))"
        AllScores = $scores
    }
}

function Invoke-RecommendationClassifier {
    [CmdletBinding()]
    param(
        [Parameter()]
        [array]$Recommendations = @(),
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Features
    )
    
    if ($Recommendations.Count -eq 0) {
        return @{ Type = "Information"; Confidence = 0.65; Reasoning = "No recommendations found, likely informational" }
    }
    
    # High recommendation count suggests instructions
    if ($Recommendations.Count -ge 2) {
        $confidence = 0.9 + ($Recommendations.Count * 0.02)
        return @{ Type = "Instruction"; Confidence = [Math]::Min(0.99, $confidence); Reasoning = "Multiple recommendations suggest instruction type" }
    }
    
    # Single recommendation analysis
    $recommendation = $Recommendations[0]
    $confidence = 0.85
    
    # Boost confidence based on recommendation confidence
    if ($recommendation.Confidence) {
        $confidence += ($recommendation.Confidence - 0.5) * 0.2  # Scale recommendation confidence
    }
    
    return @{ 
        Type = "Instruction"
        Confidence = [Math]::Min(0.99, $confidence)
        Reasoning = "Single recommendation with $($recommendation.Type) action type"
    }
}

function Invoke-EntityContextClassifier {
    [CmdletBinding()]
    param(
        [Parameter()]
        [array]$Entities = @(),
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Features
    )
    
    if ($Entities.Count -eq 0) {
        return @{ Type = "Information"; Confidence = 0.7; Reasoning = "No entities extracted, likely general information" }
    }
    
    # Entity type analysis
    $errorEntities = $Entities | Where-Object { $_.Type -eq "ErrorMessage" }
    $fileEntities = $Entities | Where-Object { $_.Type -eq "FilePath" }
    $commandEntities = $Entities | Where-Object { $_.Type -eq "PowerShellCommand" }
    
    if ($errorEntities.Count -gt 0) {
        $confidence = 0.92 + ($errorEntities.Count * 0.02)
        return @{ Type = "Error"; Confidence = [Math]::Min(0.99, $confidence); Reasoning = "Error entities detected" }
    }
    
    if ($commandEntities.Count -ge 2 -or $fileEntities.Count -ge 2) {
        $confidence = 0.87 + (($commandEntities.Count + $fileEntities.Count) * 0.03)
        return @{ Type = "Instruction"; Confidence = [Math]::Min(0.99, $confidence); Reasoning = "Multiple actionable entities suggest instructions" }
    }
    
    if ($commandEntities.Count -eq 1 -or $fileEntities.Count -eq 1) {
        return @{ Type = "Instruction"; Confidence = 0.8; Reasoning = "Single actionable entity suggests instruction" }
    }
    
    # General entity analysis suggests information
    $confidence = 0.75 + ($Entities.Count * 0.02)
    return @{ Type = "Information"; Confidence = [Math]::Min(0.9, $confidence); Reasoning = "Entity context suggests informational content" }
}

function Invoke-EnsembleVoting {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$ClassifierResults,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Features
    )
    
    # Weighted voting system
    $classifierWeights = @(1.2, 1.0, 1.1, 0.9)  # Decision tree, feature-based, recommendation, entity
    
    $votingScores = @{}
    foreach ($type in $script:ClassificationTypes) {
        $votingScores[$type] = 0.0
    }
    
    for ($i = 0; $i -lt $ClassifierResults.Count; $i++) {
        $classifier = $ClassifierResults[$i]
        $weight = $classifierWeights[$i]
        
        if ($classifier -and $classifier.Type -and $classifier.Confidence) {
            $votingScores[$classifier.Type] += ($classifier.Confidence * $weight)
        }
    }
    
    # Find consensus result
    $maxScore = ($votingScores.Values | Measure-Object -Maximum).Maximum
    $consensusType = ($votingScores.GetEnumerator() | Where-Object { $_.Value -eq $maxScore } | Select-Object -First 1).Key
    
    # Calculate agreement level
    $sameTypeCount = ($ClassifierResults | Where-Object { $_.Type -eq $consensusType }).Count
    $agreement = $sameTypeCount / $ClassifierResults.Count
    
    # Adjust confidence based on agreement
    $baseConfidence = $maxScore / [Math]::Max(1.0, ($classifierWeights | Measure-Object -Maximum).Maximum)
    $confidenceAdjustment = ($agreement - 0.5) * 0.2  # Boost for high agreement, reduce for low agreement
    $finalConfidence = [Math]::Max(0.6, [Math]::Min(0.99, $baseConfidence + $confidenceAdjustment))
    
    return @{
        Classification = @{ Type = $consensusType; Confidence = $finalConfidence }
        Agreement = $agreement
        WeightedVotes = $votingScores
        ConsensusStrength = $maxScore
    }
}

function Invoke-BayesianClassificationCalibration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Classification,
        
        [Parameter(Mandatory = $true)]
        [double]$Confidence,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Features
    )
    
    $type = $Classification.Type
    $rawConfidence = $Confidence
    
    # Apply Platt scaling calibration (simplified version)
    $calibratedConfidence = Invoke-PlattScaling -RawConfidence $rawConfidence -ClassificationType $type
    
    # Apply Bayesian prior adjustment
    $priorAdjustment = Get-BayesianPriorAdjustment -ClassificationType $type -Features $Features
    
    # Combine calibrated confidence with prior
    $finalConfidence = ($calibratedConfidence * 0.8) + ($priorAdjustment * 0.2)
    $finalConfidence = [Math]::Max(0.5, [Math]::Min(0.99, $finalConfidence))
    
    return @{
        Type = $type
        Confidence = $finalConfidence
        Reasoning = "Ensemble classification with Bayesian calibration ($($rawConfidence.ToString('P1')) -> $($finalConfidence.ToString('P1')))"
        CalibrationDetails = @{
            RawConfidence = $rawConfidence
            CalibratedConfidence = $calibratedConfidence
            PriorAdjustment = $priorAdjustment
            FinalConfidence = $finalConfidence
        }
    }
}

function Invoke-PlattScaling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [double]$RawConfidence,
        
        [Parameter(Mandatory = $true)]
        [string]$ClassificationType
    )
    
    # Simplified Platt scaling parameters (would normally be learned from data)
    $scalingParams = @{
        "Error" = @{ A = 2.1; B = -1.2 }
        "Instruction" = @{ A = 1.8; B = -0.9 }
        "Question" = @{ A = 1.9; B = -1.0 }
        "Complete" = @{ A = 2.0; B = -1.1 }
        "Information" = @{ A = 1.5; B = -0.7 }
        "TestResult" = @{ A = 1.7; B = -0.8 }
        "Continuation" = @{ A = 1.6; B = -0.8 }
    }
    
    $params = $scalingParams[$ClassificationType]
    if (-not $params) {
        $params = @{ A = 1.0; B = 0.0 }  # Default parameters
    }
    
    # Platt scaling formula: P = 1 / (1 + exp(A * score + B))
    $logit = [Math]::Log($RawConfidence / (1.0 - $RawConfidence))
    $scaledLogit = ($params.A * $logit) + $params.B
    $calibrated = 1.0 / (1.0 + [Math]::Exp(-$scaledLogit))
    
    return [Math]::Max(0.5, [Math]::Min(0.99, $calibrated))
}

function Get-BayesianPriorAdjustment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ClassificationType,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Features
    )
    
    # Historical priors (would be updated based on actual classification history)
    $priors = @{
        "Instruction" = 0.40  # Most common in CLI environment
        "Information" = 0.25
        "Error" = 0.15
        "Question" = 0.10
        "Complete" = 0.05
        "TestResult" = 0.03
        "Continuation" = 0.02
    }
    
    $basePrior = $priors[$ClassificationType]
    if (-not $basePrior) { $basePrior = 0.1 }  # Default prior
    
    # Adjust prior based on context features
    $contextAdjustment = 1.0
    
    if ($ClassificationType -eq "Error" -and $Features.ErrorEntityCount -gt 0) {
        $contextAdjustment *= 1.3
    }
    if ($ClassificationType -eq "Instruction" -and $Features.RecommendationCount -gt 0) {
        $contextAdjustment *= 1.2
    }
    if ($ClassificationType -eq "Question" -and $Features.QuestionMarks -gt 0) {
        $contextAdjustment *= 1.25
    }
    
    $adjustedPrior = [Math]::Min(0.95, $basePrior * $contextAdjustment)
    return $adjustedPrior
}

function Update-ClassificationStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Classification,
        
        [Parameter(Mandatory = $true)]
        [int]$ProcessingTime
    )
    
    $type = $Classification.Type
    $confidence = $Classification.Confidence
    
    if (-not $script:ClassificationStats.Classifications.ContainsKey($type)) {
        $script:ClassificationStats.Classifications[$type] = @{
            Count = 0
            TotalConfidence = 0.0
            AverageConfidence = 0.0
            LastSeen = $null
        }
    }
    
    $stats = $script:ClassificationStats.Classifications[$type]
    $stats.Count++
    $stats.TotalConfidence += $confidence
    $stats.AverageConfidence = $stats.TotalConfidence / $stats.Count
    $stats.LastSeen = Get-Date
    
    # Track confidence history for calibration
    $script:ClassificationStats.ConfidenceHistory += @{
        Type = $type
        Confidence = $confidence
        Timestamp = Get-Date
        ProcessingTime = $ProcessingTime
    }
    
    # Keep only recent history (last 1000 entries)
    if ($script:ClassificationStats.ConfidenceHistory.Count -gt 1000) {
        # Keep only recent history (PowerShell 5.1 compatible)
        $historyCount = $script:ClassificationStats.ConfidenceHistory.Count
        if ($historyCount -gt 1000) {
            $keepHistory = @()
            for ($i = ($historyCount - 1000); $i -lt $historyCount; $i++) {
                $keepHistory += $script:ClassificationStats.ConfidenceHistory[$i]
            }
            $script:ClassificationStats.ConfidenceHistory = $keepHistory
        }
    }
    
    $script:ClassificationStats.TotalClassifications++
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Classify-ResponseType',
    'Get-EnhancedFeatureEngineering',
    'Invoke-EnsembleVoting'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDj/cOpJjjyZ3p4
# ncz3XoHy+xPpOfUdfTa+YuP5IN1D1KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPcAJY3pgKL5U0iovfQCo+hO
# YCp3rISMHSHylrw4NZFZMA0GCSqGSIb3DQEBAQUABIIBAG1lJI29+9OW8zL6ANcI
# xmBZDq/tLOHmqEhl3WHgBGB4vTvhoSeuTuQ1eAqTIKP/5J4vtdZ2GWxjzmNUjYb3
# +R23E8b9YFJfB0UrnpwMGUlZ4f9G1O1XSVq2buY5TyurinfVqKxrqJM5uBfD2x+L
# PIXujFuhY02+NcWeriIQiJ3fZz/Q0ZnbQDLRB7lulJnwkWSX2aABxLRh4N/Hxt79
# pXKssKqY4i7Og4N6bGVicqBxlkP5M/RqfvBJtH88Iien+CnF3tm5ckgXWvP73mZz
# HJc3Kg2Y+QmZhrYZO3riTGtTBpxVVACCNu6YURM7qR42/12STu+we9R4KzYdOWG1
# 3wI=
# SIG # End signature block
