# RuleBasedDecisionTrees.psm1
# Rule-based decision processing and priority resolution
# Part of Unity-Claude-CLIOrchestrator refactored architecture
# Date: 2025-08-25

#region Rule-Based Decision Trees

# Main decision tree processor
function Invoke-RuleBasedDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$AnalysisResult,
        
        [Parameter()]
        [switch]$IncludeDetails,
        
        [Parameter()]
        [switch]$DryRun
    )
    
    Write-DecisionLog "Starting rule-based decision processing" "INFO"
    $startTime = Get-Date
    
    try {
        # Input validation
        if (-not $AnalysisResult.ContainsKey('Recommendations') -or 
            -not $AnalysisResult.ContainsKey('ConfidenceAnalysis')) {
            throw "Invalid analysis result - missing required components"
        }
        
        $recommendations = $AnalysisResult.Recommendations
        $confidence = $AnalysisResult.ConfidenceAnalysis
        
        Write-DecisionLog "Processing $($recommendations.Count) recommendations with confidence $($confidence.OverallConfidence)" "INFO"
        
        # Step 1: Safety validation
        $safetyResult = Test-SafetyValidation -AnalysisResult $AnalysisResult
        if (-not $safetyResult.IsSafe) {
            Write-DecisionLog "Safety validation failed: $($safetyResult.Reason)" "ERROR"
            return @{
                Decision = "BLOCK"
                Reason = "Safety validation failed: $($safetyResult.Reason)"
                ProcessingTimeMs = ((Get-Date) - $startTime).TotalMilliseconds
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            }
        }
        
        # Step 2: Priority-based decision resolution
        $priorityResult = Resolve-PriorityDecision -Recommendations $recommendations -ConfidenceAnalysis $confidence
        
        # Step 3: Action queue preparation
        $queueResult = New-ActionQueueItem -Decision $priorityResult -AnalysisResult $AnalysisResult -DryRun:$DryRun
        
        # Step 4: Compile final decision
        $finalDecision = @{
            # Core Decision
            Decision = $priorityResult.RecommendationType
            Action = $priorityResult.Action
            Priority = $priorityResult.Priority
            
            # Safety Assessment
            SafetyLevel = $priorityResult.SafetyLevel
            SafetyValidated = $safetyResult.IsSafe
            
            # Confidence and Quality
            ConfidenceScore = $confidence.OverallConfidence
            QualityRating = $confidence.QualityRating
            
            # Action Queue Information
            QueuePosition = $queueResult.QueuePosition
            EstimatedExecutionTime = $queueResult.EstimatedExecutionTime
            
            # Processing Metadata
            ProcessingTimeMs = ((Get-Date) - $startTime).TotalMilliseconds
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            DryRun = $DryRun.IsPresent
        }
        
        # Add detailed information if requested
        if ($IncludeDetails) {
            $finalDecision.Details = @{
                AllRecommendations = $recommendations
                SafetyDetails = $safetyResult
                PriorityAnalysis = $priorityResult
                QueueDetails = $queueResult
            }
        }
        
        $processingTime = [int]$finalDecision.ProcessingTimeMs
        Write-DecisionLog "Decision completed: $($finalDecision.Decision) (Priority: $($finalDecision.Priority), Time: ${processingTime}ms)" "SUCCESS"
        
        # Get configuration for performance check
        $decisionConfig = Get-DecisionEngineConfiguration
        
        # Performance warning
        if ($processingTime -gt $decisionConfig.PerformanceTargets.DecisionTimeMs) {
            Write-DecisionLog "Decision processing exceeded target time (${processingTime}ms > $($decisionConfig.PerformanceTargets.DecisionTimeMs)ms)" "WARN"
        }
        
        return $finalDecision
        
    } catch {
        $processingTime = ((Get-Date) - $startTime).TotalMilliseconds
        Write-DecisionLog "Decision processing failed: $($_.Exception.Message)" "ERROR"
        
        return @{
            Decision = "ERROR"
            Reason = $_.Exception.Message
            ProcessingTimeMs = $processingTime
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            Error = $_.Exception.ToString()
        }
    }
}

# Priority-based decision resolver
function Resolve-PriorityDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Recommendations,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$ConfidenceAnalysis
    )
    
    Write-DecisionLog "Resolving priority decision from $($Recommendations.Count) recommendations" "DEBUG"
    
    if ($Recommendations.Count -eq 0) {
        Write-DecisionLog "No recommendations found - defaulting to CONTINUE" "WARN"
        return @{
            RecommendationType = "CONTINUE"
            Action = "Continue processing"
            Priority = 1
            SafetyLevel = "Low"
            Reason = "No specific recommendations found"
        }
    }
    
    # Get configuration
    $decisionConfig = Get-DecisionEngineConfiguration
    
    # Step 1: Filter by confidence threshold
    $confidenceThreshold = $decisionConfig.SafetyThresholds.MinimumConfidence
    $validRecommendations = @($Recommendations | Where-Object { 
        $_.Confidence -ge $confidenceThreshold 
    })
    
    if ($validRecommendations.Count -eq 0) {
        Write-DecisionLog "No recommendations meet confidence threshold ($confidenceThreshold)" "WARN"
        return @{
            RecommendationType = "ERROR"
            Action = "Insufficient confidence in recommendations"
            Priority = 7
            SafetyLevel = "Low"
            Reason = "No recommendations meet minimum confidence threshold"
        }
    }
    
    Write-DecisionLog "Found $($validRecommendations.Count) recommendations above confidence threshold" "DEBUG"
    
    # Step 2: Sort by priority (lower number = higher priority)
    # Step 2: Add matrix properties and sort
    $prioritizedRecommendations = @()
    foreach ($rec in $validRecommendations) {
        $recType = $rec.Type
        $matrixEntry = $decisionConfig.DecisionMatrix[$recType]
        
        if ($matrixEntry) {
            $rec | Add-Member -NotePropertyName 'MatrixPriority' -NotePropertyValue $matrixEntry.Priority -Force
            $rec | Add-Member -NotePropertyName 'MatrixSafetyLevel' -NotePropertyValue $matrixEntry.SafetyLevel -Force
            $rec | Add-Member -NotePropertyName 'MatrixActionType' -NotePropertyValue $matrixEntry.ActionType -Force
        } else {
            Write-DecisionLog "Unknown recommendation type: $recType - treating as low priority" "WARN"
            $rec | Add-Member -NotePropertyName 'MatrixPriority' -NotePropertyValue 10 -Force
            $rec | Add-Member -NotePropertyName 'MatrixSafetyLevel' -NotePropertyValue "Unknown" -Force
            $rec | Add-Member -NotePropertyName 'MatrixActionType' -NotePropertyValue "Unknown" -Force
        }
        $prioritizedRecommendations += $rec
    }
    
    # Sort by priority (only if multiple recommendations)
    # Lower priority number = higher priority, so sort ascending by priority
    # Then by confidence descending (higher is better) as tiebreaker
    if ($prioritizedRecommendations.Count -gt 1) {
        $prioritizedRecommendations = @($prioritizedRecommendations | Sort-Object @{Expression='MatrixPriority'; Ascending=$true}, @{Expression='Confidence'; Ascending=$false})
    }
    
    # Step 3: Select highest priority recommendation
    if ($prioritizedRecommendations.Count -eq 0) {
        Write-DecisionLog "No prioritized recommendations available" "ERROR"
        return @{
            RecommendationType = "ERROR"
            Action = "No valid recommendations found"
            Priority = 7
            SafetyLevel = "Low"
            Reason = "No prioritized recommendations available"
        }
    }
    
    $selectedRecommendation = $prioritizedRecommendations[0]
    
    # Step 4: Handle conflicts if multiple recommendations have same priority
    $samePriority = $prioritizedRecommendations | Where-Object { $_.MatrixPriority -eq $selectedRecommendation.MatrixPriority }
    if ($samePriority.Count -gt 1) {
        Write-DecisionLog "Found $($samePriority.Count) recommendations with same priority - using confidence as tiebreaker" "DEBUG"
        # Already sorted by confidence descending, so first item is correct
    }
    
    $result = @{
        RecommendationType = $selectedRecommendation.Type
        Action = $selectedRecommendation.Action
        Priority = $selectedRecommendation.MatrixPriority
        SafetyLevel = $selectedRecommendation.MatrixSafetyLevel
        ActionType = $selectedRecommendation.MatrixActionType
        Confidence = $selectedRecommendation.Confidence
        Reason = "Selected highest priority recommendation with confidence $($selectedRecommendation.Confidence)"
    }
    
    Write-DecisionLog "Selected recommendation: $($result.RecommendationType) (Priority: $($result.Priority), Confidence: $($result.Confidence))" "INFO"
    
    return $result
}

# Export functions
Export-ModuleMember -Function @(
    'Invoke-RuleBasedDecision',
    'Resolve-PriorityDecision'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAzF9rUXW3JLNZS
# V2HNeAoninKramfb8GuPNat8QbMIwKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDoSynITz/J9RFICjUAJvQco
# x5H2c4Py1YIfpy85ByDvMA0GCSqGSIb3DQEBAQUABIIBACSSrEx3ot4EdETeUJZ1
# OaHUk00skW4n4F/IrXI3oI3qlkl1Mpr5VBD7zAgz4hQ6axQhAvO5TSkdP1Jfrb3Z
# RaKJe7NeGQ6tHu9AMUCLpV/yD0pq+OdSD2PByqap8j45YJ6fJ11ZVbK2nB0FNgg9
# PKgGYNC22fhthNpRQivZ1Py7B5nl6pgUIxBiJughSyCksLIrIX/R6ivJFWuRjbX2
# T/IdobYm978VWv1/L/zkVOjVpRAe/HKqqrbKqpOk2K9g/54EcvmGdVX9BgAu2tE1
# gbb18zSyWDIRW+kzJF0Fii+OAx88u2ClLn9R4srSNLDuuXv0ccCVZ7RxSpLpoUcM
# SF0=
# SIG # End signature block
