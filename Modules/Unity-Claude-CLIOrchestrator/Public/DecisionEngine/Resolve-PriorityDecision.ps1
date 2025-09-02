function Resolve-PriorityDecision {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Recommendations,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$ConfidenceAnalysis
    )
    
    # Initialize script config if not set
    if (-not $script:DecisionConfig) {
        $script:DecisionConfig = @{
            DecisionMatrix = @{
                "CONTINUE" = @{ Priority = 1; ActionType = "Continuation"; SafetyLevel = "Low" }
                "TEST" = @{ Priority = 2; ActionType = "TestExecution"; SafetyLevel = "Medium" }
                "FIX" = @{ Priority = 3; ActionType = "FileModification"; SafetyLevel = "High" }
                "COMPILE" = @{ Priority = 4; ActionType = "BuildOperation"; SafetyLevel = "Medium" }
                "RESTART" = @{ Priority = 5; ActionType = "ServiceRestart"; SafetyLevel = "High" }
                "COMPLETE" = @{ Priority = 6; ActionType = "TaskCompletion"; SafetyLevel = "Low" }
                "ERROR" = @{ Priority = 7; ActionType = "ErrorHandling"; SafetyLevel = "Low" }
            }
            SafetyThresholds = @{ MinimumConfidence = 0.7 }
        }
    }
    
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
    
    # Step 1: Filter by confidence threshold
    $confidenceThreshold = $script:DecisionConfig.SafetyThresholds.MinimumConfidence
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
    
    # Step 2: Add matrix properties and sort
    $prioritizedRecommendations = @()
    foreach ($rec in $validRecommendations) {
        $recType = $rec.Type
        $matrixEntry = $script:DecisionConfig.DecisionMatrix[$recType]
        
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