# Unity-Claude-MessageQueue.psm1
# Message Queue Module for Multi-Agent Communication
# Implements thread-safe message passing with FileSystemWatcher integration

using namespace System.Collections.Concurrent
using namespace System.IO
using namespace System.Threading

# Module-level variables
$script:MessageQueue = [ConcurrentDictionary[string, object]]::new()
$script:CircuitBreakers = [ConcurrentDictionary[string, object]]::new()
$script:FileWatchers = @{}
$script:DebounceTimers = @{}
$script:MessageHandlers = @{}

# Initialize module logging
$script:LogPath = Join-Path $PSScriptRoot "Logs"
if (-not (Test-Path $script:LogPath)) {
    New-Item -Path $script:LogPath -ItemType Directory -Force | Out-Null
}

function Initialize-MessageQueue {
    [CmdletBinding()]
    param(
        [string]$QueueName = "DefaultQueue",
        [int]$MaxMessages = 1000
    )
    
    Write-Debug "[MessageQueue] Initializing queue: $QueueName with max messages: $MaxMessages"
    
    $queueConfig = @{
        Name = $QueueName
        MaxMessages = $MaxMessages
        Messages = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
        Statistics = @{
            TotalReceived = 0
            TotalProcessed = 0
            TotalErrors = 0
            CreatedAt = Get-Date
        }
    }
    
    $script:MessageQueue[$QueueName] = $queueConfig
    Write-Debug "[MessageQueue] Queue initialized successfully: $QueueName"
    
    return $queueConfig
}

function Add-MessageToQueue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$QueueName,
        
        [Parameter(Mandatory)]
        [object]$Message,
        
        [string]$MessageType = "Generic",
        [int]$Priority = 5
    )
    
    Write-Verbose "[Add-MessageToQueue] Starting - Queue: $QueueName, Type: $MessageType, Priority: $Priority"
    
    if (-not $script:MessageQueue.ContainsKey($QueueName)) {
        Write-Verbose "[Add-MessageToQueue] Queue '$QueueName' doesn't exist, initializing..."
        $null = Initialize-MessageQueue -QueueName $QueueName
    } else {
        Write-Verbose "[Add-MessageToQueue] Queue '$QueueName' exists"
    }
    
    $messageWrapper = @{
        Id = [Guid]::NewGuid().ToString()
        Type = $MessageType
        Priority = $Priority
        Content = $Message
        Timestamp = Get-Date
        Status = "Queued"
        RetryCount = 0
    }
    
    $queue = $script:MessageQueue[$QueueName]
    Write-Verbose "[Add-MessageToQueue] Queue object retrieved, Messages type: $($queue.Messages.GetType().FullName)"
    Write-Verbose "[Add-MessageToQueue] Current queue length before enqueue: $($queue.Messages.Count)"
    
    $queue.Messages.Enqueue($messageWrapper)
    $queue.Statistics.TotalReceived++
    
    Write-Verbose "[Add-MessageToQueue] Message added with ID: $($messageWrapper.Id)"
    Write-Verbose "[Add-MessageToQueue] Queue length after enqueue: $($queue.Messages.Count)"
    
    # Trigger message handler if registered (commented out - handlers should be invoked by Start-MessageProcessor)
    # if ($script:MessageHandlers.ContainsKey($QueueName)) {
    #     # Handler will be invoked by Start-MessageProcessor when it processes the queue
    # }
    
    return $messageWrapper
}

function Get-MessageFromQueue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$QueueName,
        
        [int]$TimeoutSeconds = 5
    )
    
    Write-Verbose "[Get-MessageFromQueue] Starting - Queue: $QueueName, Timeout: $TimeoutSeconds seconds"
    
    if (-not $script:MessageQueue.ContainsKey($QueueName)) {
        Write-Verbose "[Get-MessageFromQueue] Queue '$QueueName' not found in script:MessageQueue"
        Write-Verbose "[Get-MessageFromQueue] Available queues: $($script:MessageQueue.Keys -join ', ')"
        Write-Warning "Queue not found: $QueueName"
        return $null
    }
    
    $queue = $script:MessageQueue[$QueueName]
    Write-Verbose "[Get-MessageFromQueue] Queue object retrieved, Messages type: $($queue.Messages.GetType().FullName)"
    Write-Verbose "[Get-MessageFromQueue] Current queue length: $($queue.Messages.Count)"
    
    $message = $null
    $endTime = (Get-Date).AddSeconds($TimeoutSeconds)
    $attempts = 0
    
    while ((Get-Date) -lt $endTime) {
        $attempts++
        Write-Verbose "[Get-MessageFromQueue] Dequeue attempt $attempts, queue count: $($queue.Messages.Count)"
        
        if ($queue.Messages.TryDequeue([ref]$message)) {
            $message.Status = "Processing"
            $queue.Statistics.TotalProcessed++
            Write-Verbose "[Get-MessageFromQueue] SUCCESS - Message retrieved: $($message.Id)"
            return $message
        }
        
        if ($attempts -eq 1) {
            Write-Verbose "[Get-MessageFromQueue] First dequeue failed, waiting..."
        }
        Start-Sleep -Milliseconds 100
    }
    
    Write-Verbose "[Get-MessageFromQueue] TIMEOUT - No messages retrieved after $attempts attempts"
    Write-Verbose "[Get-MessageFromQueue] Final queue length: $($queue.Messages.Count)"
    return $null
}

function Register-FileSystemWatcher {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        
        [Parameter(Mandatory)]
        [string]$QueueName,
        
        [string]$Filter = "*.*",
        [int]$DebounceMilliseconds = 500,
        [System.IO.NotifyFilters]$NotifyFilter = [System.IO.NotifyFilters]::LastWrite
    )
    
    Write-Debug "[FileWatcher] Registering watcher for: $Path"
    
    if ($script:FileWatchers.ContainsKey($Path)) {
        Write-Warning "Watcher already exists for path: $Path"
        return
    }
    
    # Create FileSystemWatcher
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $Path
    $watcher.Filter = $Filter
    $watcher.NotifyFilter = $NotifyFilter
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $false
    
    # Create action for file changes with debouncing
    $action = {
        param($source, $e)
        
        $watcherKey = $e.FullPath
        $queueName = $Event.MessageData.QueueName
        $debounceMs = $Event.MessageData.DebounceMs
        
        Write-Debug "[FileWatcher] Change detected: $($e.ChangeType) - $($e.FullPath)"
        
        # Implement debouncing
        if ($script:DebounceTimers.ContainsKey($watcherKey)) {
            $script:DebounceTimers[$watcherKey].Stop()
            $script:DebounceTimers[$watcherKey].Dispose()
        }
        
        $timer = New-Object System.Timers.Timer
        $timer.Interval = $debounceMs
        $timer.AutoReset = $false
        
        Register-ObjectEvent -InputObject $timer -EventName Elapsed -Action {
            $message = @{
                ChangeType = $Event.MessageData.ChangeType
                Path = $Event.MessageData.Path
                Name = $Event.MessageData.Name
                OldPath = $Event.MessageData.OldPath
                Timestamp = Get-Date
            }
            
            Add-MessageToQueue -QueueName $Event.MessageData.QueueName `
                               -Message $message `
                               -MessageType "FileSystemChange" `
                               -Priority 7
            
            $script:DebounceTimers.Remove($Event.MessageData.WatcherKey)
        } -MessageData @{
            ChangeType = $e.ChangeType
            Path = $e.FullPath
            Name = $e.Name
            OldPath = if ($e.OldFullPath) { $e.OldFullPath } else { $null }
            QueueName = $queueName
            WatcherKey = $watcherKey
        } | Out-Null
        
        $script:DebounceTimers[$watcherKey] = $timer
        $timer.Start()
    }
    
    # Register event handlers
    $messageData = @{
        QueueName = $QueueName
        DebounceMs = $DebounceMilliseconds
    }
    
    Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $action -MessageData $messageData | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action -MessageData $messageData | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName "Deleted" -Action $action -MessageData $messageData | Out-Null
    Register-ObjectEvent -InputObject $watcher -EventName "Renamed" -Action $action -MessageData $messageData | Out-Null
    
    # Start monitoring
    $watcher.EnableRaisingEvents = $true
    
    $script:FileWatchers[$Path] = @{
        Watcher = $watcher
        QueueName = $QueueName
        DebounceMs = $DebounceMilliseconds
    }
    
    Write-Debug "[FileWatcher] Watcher registered successfully for: $Path"
}

function Initialize-CircuitBreaker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,
        
        [int]$FailureThreshold = 3,
        [int]$ResetTimeoutSeconds = 60,
        [int]$HalfOpenMaxAttempts = 1
    )
    
    Write-Debug "[CircuitBreaker] Initializing for service: $ServiceName"
    
    $breaker = @{
        ServiceName = $ServiceName
        State = "Closed"  # Closed, Open, HalfOpen
        FailureCount = 0
        FailureThreshold = $FailureThreshold
        LastFailureTime = $null
        ResetTimeout = $ResetTimeoutSeconds
        HalfOpenAttempts = 0
        HalfOpenMaxAttempts = $HalfOpenMaxAttempts
        Statistics = @{
            TotalAttempts = 0
            TotalSuccesses = 0
            TotalFailures = 0
            LastStateChange = Get-Date
        }
    }
    
    $script:CircuitBreakers[$ServiceName] = $breaker
    Write-Debug "[CircuitBreaker] Initialized for service: $ServiceName"
    
    return $breaker
}

function Invoke-WithCircuitBreaker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,
        
        [Parameter(Mandatory)]
        [scriptblock]$Action,
        
        [scriptblock]$FallbackAction = { throw "Service unavailable: Circuit breaker is open" }
    )
    
    if (-not $script:CircuitBreakers.ContainsKey($ServiceName)) {
        Initialize-CircuitBreaker -ServiceName $ServiceName
    }
    
    $breaker = $script:CircuitBreakers[$ServiceName]
    $breaker.Statistics.TotalAttempts++
    
    Write-Debug "[CircuitBreaker] Current state for $ServiceName : $($breaker.State)"
    
    switch ($breaker.State) {
        "Open" {
            $timeSinceLastFailure = (Get-Date) - $breaker.LastFailureTime
            if ($timeSinceLastFailure.TotalSeconds -ge $breaker.ResetTimeout) {
                Write-Debug "[CircuitBreaker] Transitioning to HalfOpen"
                $breaker.State = "HalfOpen"
                $breaker.HalfOpenAttempts = 0
                $breaker.Statistics.LastStateChange = Get-Date
            }
            else {
                Write-Debug "[CircuitBreaker] Circuit is OPEN, using fallback"
                return & $FallbackAction
            }
        }
    }
    
    try {
        $result = & $Action
        
        # Success handling
        $breaker.Statistics.TotalSuccesses++
        
        if ($breaker.State -eq "HalfOpen") {
            Write-Debug "[CircuitBreaker] Success in HalfOpen, transitioning to Closed"
            $breaker.State = "Closed"
            $breaker.FailureCount = 0
            $breaker.Statistics.LastStateChange = Get-Date
        }
        
        return $result
    }
    catch {
        # Failure handling
        $breaker.Statistics.TotalFailures++
        $breaker.FailureCount++
        $breaker.LastFailureTime = Get-Date
        
        Write-Debug "[CircuitBreaker] Failure detected: $_"
        
        if ($breaker.State -eq "HalfOpen") {
            Write-Debug "[CircuitBreaker] Failure in HalfOpen, reopening circuit"
            $breaker.State = "Open"
            $breaker.Statistics.LastStateChange = Get-Date
        }
        elseif ($breaker.FailureCount -ge $breaker.FailureThreshold) {
            Write-Debug "[CircuitBreaker] Threshold reached, opening circuit"
            $breaker.State = "Open"
            $breaker.Statistics.LastStateChange = Get-Date
        }
        
        throw $_
    }
}

function Register-MessageHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$QueueName,
        
        [Parameter(Mandatory)]
        [scriptblock]$Handler,
        
        [int]$MaxConcurrency = 1
    )
    
    Write-Debug "[MessageHandler] Registering handler for queue: $QueueName"
    
    $script:MessageHandlers[$QueueName] = @{
        Handler = $Handler
        MaxConcurrency = $MaxConcurrency
        IsRunning = $false
    }
    
    Write-Debug "[MessageHandler] Handler registered successfully"
}

function Start-MessageProcessor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$QueueName,
        
        [switch]$Continuous
    )
    
    Write-Debug "[MessageProcessor] Starting processor for queue: $QueueName"
    
    if (-not $script:MessageHandlers.ContainsKey($QueueName)) {
        Write-Warning "No handler registered for queue: $QueueName"
        return
    }
    
    $handlerInfo = $script:MessageHandlers[$QueueName]
    $handlerInfo.IsRunning = $true
    
    try {
        do {
            $message = Get-MessageFromQueue -QueueName $QueueName -TimeoutSeconds 1
            
            if ($message) {
                try {
                    Write-Debug "[MessageProcessor] Processing message: $($message.Id)"
                    $result = & $handlerInfo.Handler $message
                    $message.Status = "Completed"
                    Write-Debug "[MessageProcessor] Message processed successfully: $($message.Id)"
                }
                catch {
                    $message.Status = "Failed"
                    $message.Error = $_.Exception.Message
                    $message.RetryCount++
                    
                    Write-Warning "[MessageProcessor] Error processing message: $_"
                    
                    if ($message.RetryCount -lt 3) {
                        Write-Debug "[MessageProcessor] Requeueing message for retry"
                        Add-MessageToQueue -QueueName $QueueName -Message $message.Content `
                                         -MessageType $message.Type -Priority ($message.Priority - 1)
                    }
                }
            }
        } while ($Continuous -and $handlerInfo.IsRunning)
    }
    finally {
        $handlerInfo.IsRunning = $false
        Write-Debug "[MessageProcessor] Processor stopped for queue: $QueueName"
    }
}

function Get-QueueStatistics {
    [CmdletBinding()]
    param(
        [string]$QueueName
    )
    
    if ($QueueName) {
        if ($script:MessageQueue.ContainsKey($QueueName)) {
            return $script:MessageQueue[$QueueName].Statistics
        }
        else {
            Write-Warning "Queue not found: $QueueName"
            return $null
        }
    }
    else {
        $stats = @{}
        foreach ($queue in $script:MessageQueue.Keys) {
            $stats[$queue] = $script:MessageQueue[$queue].Statistics
        }
        return $stats
    }
}

function Get-CircuitBreakerStatus {
    [CmdletBinding()]
    param(
        [string]$ServiceName
    )
    
    if ($ServiceName) {
        if ($script:CircuitBreakers.ContainsKey($ServiceName)) {
            return $script:CircuitBreakers[$ServiceName]
        }
        else {
            Write-Warning "Circuit breaker not found: $ServiceName"
            return $null
        }
    }
    else {
        return $script:CircuitBreakers.Values
    }
}

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-MessageQueue',
    'Add-MessageToQueue',
    'Get-MessageFromQueue',
    'Register-FileSystemWatcher',
    'Initialize-CircuitBreaker',
    'Invoke-WithCircuitBreaker',
    'Register-MessageHandler',
    'Start-MessageProcessor',
    'Get-QueueStatistics',
    'Get-CircuitBreakerStatus'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCUqBg2LXnbXIWv
# PM0jkb70G9sEYUEuiRZzPS7FnblI0KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMR6coaG24NaUSVVHnSs9r7W
# p9p6oOygFit+jq2BhjH9MA0GCSqGSIb3DQEBAQUABIIBAI9NYGW6N3gp9H0v6sqL
# GdPILN/0NWUEmXAb99BQxgt4R6d3SSTEdWkTgxT74ZqwzZSeyokobNbIdNArAPWg
# RsNd+PE3W1wfN8sjbJDSEnhnOz3TXto9chE4V+MZaGEDNVTRwpwWgLyVXvbGLMLe
# 15JjCjKk0tWhYaECUQTncM72saEoJ/yOE4cw4wCHSzJaqTmhnwjEWVHr3tz4b2MQ
# 3UW1kJLZp1soxN7tvce/WE7bXZtpQwaHsLGpui52JrHawwSMvUoG5xvfqouvzUw7
# xAqqdGn/9R+A3EQ/rn/5b9Clt4e7zjg3ResCpUDqWlBSLKOtcakARuvjN+ki1t1k
# jy4=
# SIG # End signature block
