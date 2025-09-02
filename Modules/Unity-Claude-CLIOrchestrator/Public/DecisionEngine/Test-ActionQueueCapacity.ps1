function Test-ActionQueueCapacity {
    [CmdletBinding()]
    param()
    
    # Initialize queue tracking if not set
    if (-not $script:ActionQueueStatus) {
        $script:ActionQueueStatus = @{
            QueueSize = 0
            MaxQueueSize = 10
            CurrentActions = @()
        }
    }
    
    $result = @{
        HasCapacity = $true
        CurrentSize = $script:ActionQueueStatus.QueueSize
        MaxSize = $script:ActionQueueStatus.MaxQueueSize
        AvailableSlots = $script:ActionQueueStatus.MaxQueueSize - $script:ActionQueueStatus.QueueSize
        Reason = "Queue has available capacity"
    }
    
    if ($script:ActionQueueStatus.QueueSize -ge $script:ActionQueueStatus.MaxQueueSize) {
        $result.HasCapacity = $false
        $result.AvailableSlots = 0
        $result.Reason = "Queue is at maximum capacity"
        Write-DecisionLog "Action queue at capacity: $($script:ActionQueueStatus.QueueSize)/$($script:ActionQueueStatus.MaxQueueSize)" "WARN"
    } else {
        Write-DecisionLog "Action queue capacity: $($script:ActionQueueStatus.QueueSize)/$($script:ActionQueueStatus.MaxQueueSize)" "DEBUG"
    }
    
    return $result
}