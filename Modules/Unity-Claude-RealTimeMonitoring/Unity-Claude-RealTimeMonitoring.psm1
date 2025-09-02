# Unity-Claude-RealTimeMonitoring.psm1
# Advanced Real-Time Monitoring Framework for Enhanced Documentation System
# Part of Week 3: Real-Time Intelligence and Autonomous Operation

using namespace System.IO
using namespace System.Collections.Generic
using namespace System.Collections.Concurrent
using namespace System.Threading

# Module-level variables for monitoring state
$script:MonitoringState = @{
    Watchers = [Dictionary[string, FileSystemWatcher]]::new()
    EventQueue = [ConcurrentQueue[PSCustomObject]]::new()
    ProcessingThread = $null
    IsRunning = $false
    Configuration = $null
    Statistics = @{
        EventsReceived = 0
        EventsProcessed = 0
        ErrorCount = 0
        StartTime = $null
    }
}

# Event types for comprehensive monitoring
enum FileChangeType {
    Created
    Modified
    Deleted
    Renamed
    Error
}

# Priority levels for event processing
enum EventPriority {
    Critical = 0
    High = 1
    Medium = 2
    Low = 3
}

function Initialize-RealTimeMonitoring {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [hashtable]$Configuration = @{}
    )
    
    Write-Verbose "Initializing Real-Time Monitoring Framework..."
    
    # Default configuration
    $defaultConfig = @{
        MonitoredPaths = @(
            "$PSScriptRoot\..\",
            "$PSScriptRoot\..\..\Tests\"
        )
        FileFilters = @("*.ps1", "*.psm1", "*.psd1", "*.md", "*.json", "*.xml")
        ExcludePatterns = @("*.log", "*.tmp", "*~", "*.bak")
        EventBufferSize = 1000
        ProcessingInterval = 500  # milliseconds
        EnableRecursive = $true
        EnableAutoRecovery = $true
        MaxRetryAttempts = 3
        NotifyFilter = [NotifyFilters]::LastWrite -bor [NotifyFilters]::FileName -bor [NotifyFilters]::DirectoryName
    }
    
    # Merge with provided configuration
    $script:MonitoringState.Configuration = $defaultConfig
    foreach ($key in $Configuration.Keys) {
        $script:MonitoringState.Configuration[$key] = $Configuration[$key]
    }
    
    # Initialize statistics
    $script:MonitoringState.Statistics.StartTime = Get-Date
    
    Write-Verbose "Real-Time Monitoring Framework initialized with $($script:MonitoringState.Configuration.MonitoredPaths.Count) paths"
    
    return $true
}

function Start-FileSystemMonitoring {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$Paths,
        
        [Parameter(Mandatory = $false)]
        [string[]]$Filters,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeSubdirectories
    )
    
    if ($script:MonitoringState.IsRunning) {
        Write-Warning "Monitoring is already running"
        return
    }
    
    try {
        # Use provided paths or default configuration
        $monitorPaths = if ($Paths) { $Paths } else { $script:MonitoringState.Configuration.MonitoredPaths }
        $fileFilters = if ($Filters) { $Filters } else { $script:MonitoringState.Configuration.FileFilters }
        $includeSubDirs = if ($PSBoundParameters.ContainsKey('IncludeSubdirectories')) { 
            $IncludeSubdirectories 
        } else { 
            $script:MonitoringState.Configuration.EnableRecursive 
        }
        
        # Create FileSystemWatcher for each path and filter combination
        foreach ($path in $monitorPaths) {
            if (-not (Test-Path $path)) {
                Write-Warning "Path does not exist: $path"
                continue
            }
            
            $resolvedPath = Resolve-Path $path
            
            foreach ($filter in $fileFilters) {
                $watcherKey = "$resolvedPath|$filter"
                
                if ($script:MonitoringState.Watchers.ContainsKey($watcherKey)) {
                    Write-Verbose "Watcher already exists for: $watcherKey"
                    continue
                }
                
                Write-Verbose "Creating watcher for: $watcherKey"
                
                $watcher = New-Object System.IO.FileSystemWatcher
                $watcher.Path = $resolvedPath
                $watcher.Filter = $filter
                $watcher.IncludeSubdirectories = $includeSubDirs
                $watcher.NotifyFilter = $script:MonitoringState.Configuration.NotifyFilter
                $watcher.InternalBufferSize = 65536  # Maximum buffer size
                
                # Register event handlers
                Register-FileSystemEventHandlers -Watcher $watcher -WatcherKey $watcherKey
                
                # Enable the watcher
                $watcher.EnableRaisingEvents = $true
                
                # Store the watcher
                $script:MonitoringState.Watchers[$watcherKey] = $watcher
            }
        }
        
        # Start the event processing thread
        Start-EventProcessingThread
        
        $script:MonitoringState.IsRunning = $true
        
        Write-Host "Real-Time Monitoring started with $($script:MonitoringState.Watchers.Count) watchers" -ForegroundColor Green
        
        return @{
            Success = $true
            WatcherCount = $script:MonitoringState.Watchers.Count
            MonitoredPaths = $monitorPaths
        }
    }
    catch {
        Write-Error "Failed to start monitoring: $_"
        Stop-FileSystemMonitoring
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Register-FileSystemEventHandlers {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.IO.FileSystemWatcher]$Watcher,
        
        [Parameter(Mandatory = $true)]
        [string]$WatcherKey
    )
    
    # Common event handler for all file system events
    $eventAction = {
        $event = @{
            Type = $EventArgs.ChangeType
            FullPath = $EventArgs.FullPath
            Name = $EventArgs.Name
            TimeStamp = Get-Date
            WatcherKey = $Event.MessageData
            Priority = [EventPriority]::Medium
        }
        
        # Special handling for renamed events
        if ($EventArgs.ChangeType -eq [System.IO.WatcherChangeTypes]::Renamed) {
            $event.OldFullPath = $EventArgs.OldFullPath
            $event.OldName = $EventArgs.OldName
        }
        
        # Determine priority based on file type and change
        $event.Priority = Get-EventPriority -Event $event
        
        # Add to event queue
        Add-EventToQueue -Event $event
    }
    
    # Error event handler
    $errorAction = {
        $errorEvent = @{
            Type = [FileChangeType]::Error
            Error = $EventArgs.GetException()
            TimeStamp = Get-Date
            WatcherKey = $Event.MessageData
            Priority = [EventPriority]::High
        }
        
        Add-EventToQueue -Event $errorEvent
        
        # Attempt automatic recovery if enabled
        if ($script:MonitoringState.Configuration.EnableAutoRecovery) {
            Invoke-AutoRecovery -WatcherKey $Event.MessageData
        }
    }
    
    # Register events
    Register-ObjectEvent -InputObject $Watcher -EventName "Created" -Action $eventAction -MessageData $WatcherKey | Out-Null
    Register-ObjectEvent -InputObject $Watcher -EventName "Changed" -Action $eventAction -MessageData $WatcherKey | Out-Null
    Register-ObjectEvent -InputObject $Watcher -EventName "Deleted" -Action $eventAction -MessageData $WatcherKey | Out-Null
    Register-ObjectEvent -InputObject $Watcher -EventName "Renamed" -Action $eventAction -MessageData $WatcherKey | Out-Null
    Register-ObjectEvent -InputObject $Watcher -EventName "Error" -Action $errorAction -MessageData $WatcherKey | Out-Null
}

function Add-EventToQueue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Event
    )
    
    try {
        # Check queue size limit
        if ($script:MonitoringState.EventQueue.Count -ge $script:MonitoringState.Configuration.EventBufferSize) {
            # Remove oldest event if at capacity
            $discarded = $null
            [void]$script:MonitoringState.EventQueue.TryDequeue([ref]$discarded)
            Write-Verbose "Event queue at capacity, discarded oldest event"
        }
        
        # Convert to PSCustomObject and enqueue
        $eventObject = [PSCustomObject]$Event
        $script:MonitoringState.EventQueue.Enqueue($eventObject)
        $script:MonitoringState.Statistics.EventsReceived++
        
        Write-Verbose "Event added to queue: $($Event.Type) - $($Event.FullPath)"
    }
    catch {
        Write-Error "Failed to add event to queue: $_"
        $script:MonitoringState.Statistics.ErrorCount++
    }
}

function Start-EventProcessingThread {
    [CmdletBinding()]
    param()
    
    if ($script:MonitoringState.ProcessingThread -and $script:MonitoringState.ProcessingThread.IsAlive) {
        Write-Verbose "Event processing thread is already running"
        return
    }
    
    $processingScript = {
        param($State, $Interval)
        
        while ($State.IsRunning) {
            try {
                # Process events in the queue
                $processedCount = 0
                $maxBatchSize = 10
                
                while ($processedCount -lt $maxBatchSize) {
                    $event = $null
                    if ($State.EventQueue.TryDequeue([ref]$event)) {
                        # Process the event (this will be expanded with actual processing logic)
                        Write-Host "Processing event: $($event.Type) - $($event.FullPath)" -ForegroundColor Yellow
                        $State.Statistics.EventsProcessed++
                        $processedCount++
                    }
                    else {
                        break
                    }
                }
                
                # Sleep for the configured interval
                Start-Sleep -Milliseconds $Interval
            }
            catch {
                Write-Error "Error in event processing thread: $_"
                $State.Statistics.ErrorCount++
            }
        }
    }
    
    # Create and start the processing thread
    $runspace = [runspacefactory]::CreateRunspace()
    $runspace.Open()
    $runspace.SessionStateProxy.SetVariable("State", $script:MonitoringState)
    
    $powershell = [powershell]::Create()
    $powershell.Runspace = $runspace
    [void]$powershell.AddScript($processingScript)
    [void]$powershell.AddArgument($script:MonitoringState)
    [void]$powershell.AddArgument($script:MonitoringState.Configuration.ProcessingInterval)
    
    $script:MonitoringState.ProcessingThread = $powershell.BeginInvoke()
    
    Write-Verbose "Event processing thread started"
}

function Get-EventPriority {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Event
    )
    
    # Determine priority based on file type and change type
    $priority = [EventPriority]::Medium
    
    # Critical priority for module files
    if ($Event.FullPath -match '\.psm1$|\.psd1$') {
        $priority = [EventPriority]::Critical
    }
    # High priority for PowerShell scripts
    elseif ($Event.FullPath -match '\.ps1$') {
        $priority = [EventPriority]::High
    }
    # High priority for deleted files
    elseif ($Event.Type -eq [System.IO.WatcherChangeTypes]::Deleted) {
        $priority = [EventPriority]::High
    }
    # Low priority for documentation
    elseif ($Event.FullPath -match '\.md$|\.txt$') {
        $priority = [EventPriority]::Low
    }
    
    return $priority
}

function Invoke-AutoRecovery {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WatcherKey
    )
    
    Write-Warning "Attempting auto-recovery for watcher: $WatcherKey"
    
    try {
        # Get the failed watcher
        $watcher = $script:MonitoringState.Watchers[$WatcherKey]
        
        if ($watcher) {
            # Disable the watcher
            $watcher.EnableRaisingEvents = $false
            
            # Wait briefly
            Start-Sleep -Milliseconds 500
            
            # Re-enable the watcher
            $watcher.EnableRaisingEvents = $true
            
            Write-Host "Auto-recovery successful for: $WatcherKey" -ForegroundColor Green
        }
    }
    catch {
        Write-Error "Auto-recovery failed for $WatcherKey : $_"
        $script:MonitoringState.Statistics.ErrorCount++
    }
}

function Stop-FileSystemMonitoring {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Stopping Real-Time Monitoring Framework..."
    
    # Set running flag to false to stop processing thread
    $script:MonitoringState.IsRunning = $false
    
    # Stop and dispose all watchers
    foreach ($watcherKey in $script:MonitoringState.Watchers.Keys) {
        try {
            $watcher = $script:MonitoringState.Watchers[$watcherKey]
            $watcher.EnableRaisingEvents = $false
            $watcher.Dispose()
            Write-Verbose "Disposed watcher: $watcherKey"
        }
        catch {
            Write-Warning "Failed to dispose watcher $watcherKey : $_"
        }
    }
    
    # Clear the watchers dictionary
    $script:MonitoringState.Watchers.Clear()
    
    # Unregister all events
    Get-EventSubscriber | Where-Object { $_.SourceObject -is [System.IO.FileSystemWatcher] } | Unregister-Event
    
    # Clear the event queue
    while ($script:MonitoringState.EventQueue.Count -gt 0) {
        $discarded = $null
        [void]$script:MonitoringState.EventQueue.TryDequeue([ref]$discarded)
    }
    
    Write-Host "Real-Time Monitoring stopped" -ForegroundColor Yellow
    
    # Return statistics
    return Get-MonitoringStatistics
}

function Get-MonitoringStatistics {
    [CmdletBinding()]
    param()
    
    $stats = $script:MonitoringState.Statistics.Clone()
    
    if ($stats.StartTime) {
        $stats.Runtime = (Get-Date) - $stats.StartTime
    }
    
    $stats.QueueLength = $script:MonitoringState.EventQueue.Count
    $stats.WatcherCount = $script:MonitoringState.Watchers.Count
    $stats.IsRunning = $script:MonitoringState.IsRunning
    
    return [PSCustomObject]$stats
}

function Get-MonitoringConfiguration {
    [CmdletBinding()]
    param()
    
    return $script:MonitoringState.Configuration
}

function Set-MonitoringConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Configuration
    )
    
    if ($script:MonitoringState.IsRunning) {
        Write-Warning "Cannot change configuration while monitoring is running. Stop monitoring first."
        return $false
    }
    
    foreach ($key in $Configuration.Keys) {
        $script:MonitoringState.Configuration[$key] = $Configuration[$key]
    }
    
    Write-Verbose "Monitoring configuration updated"
    return $true
}

function Test-MonitoringHealth {
    [CmdletBinding()]
    param()
    
    $health = @{
        IsHealthy = $true
        Issues = @()
        Watchers = @{}
    }
    
    # Check if monitoring is running
    if (-not $script:MonitoringState.IsRunning) {
        $health.IsHealthy = $false
        $health.Issues += "Monitoring is not running"
    }
    
    # Check each watcher
    foreach ($watcherKey in $script:MonitoringState.Watchers.Keys) {
        $watcher = $script:MonitoringState.Watchers[$watcherKey]
        $watcherHealth = @{
            IsEnabled = $watcher.EnableRaisingEvents
            Path = $watcher.Path
            Filter = $watcher.Filter
        }
        
        if (-not $watcher.EnableRaisingEvents) {
            $health.IsHealthy = $false
            $health.Issues += "Watcher disabled: $watcherKey"
        }
        
        if (-not (Test-Path $watcher.Path)) {
            $health.IsHealthy = $false
            $health.Issues += "Path no longer exists: $($watcher.Path)"
        }
        
        $health.Watchers[$watcherKey] = $watcherHealth
    }
    
    # Check error rate
    $stats = Get-MonitoringStatistics
    if ($stats.EventsReceived -gt 0) {
        $errorRate = $stats.ErrorCount / $stats.EventsReceived
        if ($errorRate -gt 0.05) {  # 5% error threshold
            $health.IsHealthy = $false
            $health.Issues += "High error rate: $([math]::Round($errorRate * 100, 2))%"
        }
    }
    
    # Check event queue
    if ($stats.QueueLength -gt ($script:MonitoringState.Configuration.EventBufferSize * 0.9)) {
        $health.IsHealthy = $false
        $health.Issues += "Event queue near capacity: $($stats.QueueLength)/$($script:MonitoringState.Configuration.EventBufferSize)"
    }
    
    return [PSCustomObject]$health
}

# Export module functions
Export-ModuleMember -Function @(
    'Initialize-RealTimeMonitoring',
    'Start-FileSystemMonitoring',
    'Stop-FileSystemMonitoring',
    'Get-MonitoringStatistics',
    'Get-MonitoringConfiguration',
    'Set-MonitoringConfiguration',
    'Test-MonitoringHealth'
)