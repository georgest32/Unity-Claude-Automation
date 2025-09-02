function Get-ActionQueueStatus {
    [CmdletBinding()]
    param()
    
    # Initialize queue if not set
    if (-not $script:ActionQueueStatus) {
        $script:ActionQueueStatus = @{
            QueueSize = 0
            MaxQueueSize = 10
            CurrentActions = @()
            NextId = 1
        }
    }
    
    $status = @{
        Timestamp = Get-Date
        QueueSize = $script:ActionQueueStatus.QueueSize
        MaxQueueSize = $script:ActionQueueStatus.MaxQueueSize
        AvailableSlots = $script:ActionQueueStatus.MaxQueueSize - $script:ActionQueueStatus.QueueSize
        UtilizationPercent = [Math]::Round(($script:ActionQueueStatus.QueueSize / $script:ActionQueueStatus.MaxQueueSize) * 100, 2)
        CurrentActions = @()
    }
    
    # Add summary of current actions
    foreach ($action in $script:ActionQueueStatus.CurrentActions) {
        $status.CurrentActions += @{
            Id = $action.Id
            Decision = $action.Decision
            Priority = $action.Priority
            Status = $action.Status
            CreatedAt = $action.CreatedAt
            Age = ((Get-Date) - $action.CreatedAt).TotalSeconds
        }
    }
    
    # Add performance metrics
    if ($script:ActionQueueStatus.CurrentActions.Count -gt 0) {
        $avgAge = ($status.CurrentActions | Measure-Object Age -Average).Average
        $status.AverageItemAge = [Math]::Round($avgAge, 2)
        
        $oldestItem = $status.CurrentActions | Sort-Object Age -Descending | Select-Object -First 1
        $status.OldestItemAge = [Math]::Round($oldestItem.Age, 2)
    } else {
        $status.AverageItemAge = 0
        $status.OldestItemAge = 0
    }
    
    Write-DecisionLog "Queue status: $($status.QueueSize)/$($status.MaxQueueSize) ($($status.UtilizationPercent)%)" "DEBUG"
    return $status
}