function New-ActionQueueItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Decision,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$AnalysisResult,
        
        [Parameter()]
        [switch]$DryRun
    )
    
    # Initialize queue if not set
    if (-not $script:ActionQueueStatus) {
        $script:ActionQueueStatus = @{
            QueueSize = 0
            MaxQueueSize = 10
            CurrentActions = @()
            NextId = 1
        }
    }
    
    try {
        # Check capacity
        $capacityCheck = Test-ActionQueueCapacity
        if (-not $capacityCheck.HasCapacity) {
            Write-DecisionLog "Cannot add to queue - at capacity" "ERROR"
            return @{
                QueuePosition = -1
                EstimatedExecutionTime = "N/A"
                Status = "Rejected - Queue Full"
                Id = $null
            }
        }
        
        # Create queue item
        $queueItem = @{
            Id = $script:ActionQueueStatus.NextId++
            Decision = $Decision.RecommendationType
            Action = $Decision.Action
            Priority = $Decision.Priority
            SafetyLevel = $Decision.SafetyLevel
            CreatedAt = Get-Date
            EstimatedDuration = 60  # Default 60 seconds
            Status = if ($DryRun) { "DryRun" } else { "Queued" }
            AnalysisResult = $AnalysisResult
        }
        
        # Add to queue (don't actually modify if dry run)
        if (-not $DryRun) {
            $script:ActionQueueStatus.CurrentActions += $queueItem
            $script:ActionQueueStatus.QueueSize++
        }
        
        # Calculate position and estimated time
        $queuePosition = $script:ActionQueueStatus.QueueSize
        $estimatedWait = ($script:ActionQueueStatus.CurrentActions | Measure-Object EstimatedDuration -Sum).Sum
        $estimatedExecutionTime = (Get-Date).AddSeconds($estimatedWait).ToString("HH:mm:ss")
        
        $result = @{
            QueuePosition = $queuePosition
            EstimatedExecutionTime = $estimatedExecutionTime
            Status = "Queued"
            Id = $queueItem.Id
        }
        
        Write-DecisionLog "Created queue item: ID=$($queueItem.Id), Position=$queuePosition, ETA=$estimatedExecutionTime" "INFO"
        return $result
        
    } catch {
        Write-DecisionLog "Error creating queue item: $($_.Exception.Message)" "ERROR"
        return @{
            QueuePosition = -1
            EstimatedExecutionTime = "Error"
            Status = "Error"
            Id = $null
        }
    }
}