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
        
        # Performance warning - initialize config if not set
        if (-not $script:DecisionConfig) {
            $script:DecisionConfig = @{ PerformanceTargets = @{ DecisionTimeMs = 100 } }
        }
        if ($processingTime -gt $script:DecisionConfig.PerformanceTargets.DecisionTimeMs) {
            Write-DecisionLog "Decision processing exceeded target time (${processingTime}ms > $($script:DecisionConfig.PerformanceTargets.DecisionTimeMs)ms)" "WARN"
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