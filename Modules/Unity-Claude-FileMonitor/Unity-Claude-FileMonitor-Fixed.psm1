# Unity-Claude-FileMonitor Module - Fixed Version
# Real-time file monitoring with debouncing and change classification

# Module-level variables
$script:FileMonitors = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()
$script:ChangeHandlers = [System.Collections.ArrayList]::new()
$script:DebounceTimers = [System.Collections.Concurrent.ConcurrentDictionary[string, object]]::new()
$script:DefaultDebounceInterval = 500  # milliseconds

# File classification patterns
$script:FilePatterns = @{
    Code = @('*.ps1', '*.psm1', '*.psd1', '*.cs', '*.js', '*.ts', '*.py')
    Config = @('*.json', '*.xml', '*.yaml', '*.yml', '*.config', '*.ini')
    Documentation = @('*.md', '*.txt', '*.rst', '*.adoc')
    Test = @('*test*.ps1', '*test*.cs', '*spec*.js', '*test*.py')
    Build = @('*.csproj', '*.sln', 'package.json', 'requirements.txt', '*.gradle')
}

# Change priority levels
$script:ChangePriority = @{
    Critical = 1  # Build files, core modules
    High = 2      # Source code changes
    Medium = 3    # Configuration changes
    Low = 4       # Documentation changes
    Minimal = 5   # Test file changes
}

function Write-FileMonitorLog {
    param(
        [string]$Message,
        [string]$Level = 'Info',
        [string]$Source = 'FileMonitor'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logMessage = "[$timestamp] [$Source] [$Level] $Message"
    
    switch ($Level) {
        'Error' { 
            Write-Error $logMessage
            Write-Verbose $logMessage
        }
        'Warning' { 
            Write-Warning $logMessage
            Write-Verbose $logMessage
        }
        'Debug' { Write-Verbose $logMessage }
        default { Write-Verbose $logMessage }
    }
}

function New-FileMonitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$Filter = '*.*',
        
        [Parameter(Mandatory = $false)]
        [bool]$IncludeSubdirectories = $true,
        
        [Parameter(Mandatory = $false)]
        [System.IO.NotifyFilters]$NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor 
                                                  [System.IO.NotifyFilters]::FileName -bor 
                                                  [System.IO.NotifyFilters]::DirectoryName,
        
        [Parameter(Mandatory = $false)]
        [int]$DebounceMs = $script:DefaultDebounceInterval,
        
        [Parameter(Mandatory = $false)]
        [string]$Identifier = [guid]::NewGuid().ToString()
    )
    
    Write-FileMonitorLog "Creating monitor for path: $Path with identifier: $Identifier" 'Debug'
    
    try {
        # Validate path exists
        if (-not (Test-Path $Path)) {
            throw "Path does not exist: $Path"
        }
        
        # Create FileSystemWatcher
        Write-FileMonitorLog "Creating FileSystemWatcher object" 'Debug'
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $Path
        $watcher.Filter = $Filter
        $watcher.IncludeSubdirectories = $IncludeSubdirectories
        $watcher.NotifyFilter = $NotifyFilter
        $watcher.EnableRaisingEvents = $false  # Will be enabled in Start-FileMonitor
        
        Write-FileMonitorLog "FileSystemWatcher created successfully" 'Debug'
        
        # Store monitor configuration
        $monitorConfig = @{
            Watcher = $watcher
            Path = $Path
            Filter = $Filter
            DebounceMs = $DebounceMs
            Identifier = $Identifier
            IsActive = $false
            EventSubscriptions = @()
            CreatedAt = Get-Date
            LastEventAt = $null
            EventCount = 0
            ChangeQueue = [System.Collections.ArrayList]::new()
        }
        
        Write-FileMonitorLog "Storing monitor configuration" 'Debug'
        $script:FileMonitors.TryAdd($Identifier, $monitorConfig) | Out-Null
        
        Write-FileMonitorLog "Successfully created monitor: $Identifier" 'Info'
        return $Identifier
    }
    catch {
        Write-FileMonitorLog "Failed to create monitor: $_" 'Error'
        throw
    }
}

function Start-FileMonitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Identifier
    )
    
    Write-FileMonitorLog "Starting monitor: $Identifier" 'Info'
    
    $monitor = $null
    if (-not $script:FileMonitors.TryGetValue($Identifier, [ref]$monitor)) {
        throw "Monitor not found: $Identifier"
    }
    
    $watcher = $monitor.Watcher
    
    try {
        Write-FileMonitorLog "Setting up event handlers" 'Debug'
        
        # Create event handler that uses engine events (more reliable)
        $action = {
            try {
                $eventArgs = $Event.SourceEventArgs
                $changeType = $eventArgs.ChangeType
                $fullPath = $eventArgs.FullPath
                $name = $eventArgs.Name
                $sourceId = $Event.SourceIdentifier
                
                # Parse monitor ID from source identifier
                $monitorId = $sourceId.Split('_')[1]
                
                Write-Verbose "[EventHandler] Processing $changeType on: $fullPath (Monitor: $monitorId)"
                
                # Create change event object with safe property access
                $changeEvent = @{
                    ChangeType = $changeType.ToString()
                    FullPath = $fullPath
                    Name = $name
                    Timestamp = Get-Date
                    MonitorId = $monitorId
                    FileType = Get-SafeFileType -FilePath $fullPath
                    Priority = Get-SafeChangePriority -FilePath $fullPath -ChangeType $changeType.ToString()
                }
                
                Write-Verbose "[EventHandler] Change event created: $($changeEvent | ConvertTo-Json -Compress)"
                
                # Use New-Event to create a custom event that can be processed
                New-Event -SourceIdentifier "FileMonitor_Change_$monitorId" -MessageData $changeEvent
            }
            catch {
                Write-Warning "[EventHandler] Error processing file event: $_"
                Write-Verbose "[EventHandler] Stack trace: $($_.ScriptStackTrace)"
            }
        }
        
        # Register events with unique source identifiers
        $sourceIdBase = "FileMonitor_$Identifier"
        
        Write-FileMonitorLog "Registering Created event" 'Debug'
        $createdEvent = Register-ObjectEvent -InputObject $watcher -EventName "Created" -SourceIdentifier "$($sourceIdBase)_Created" -Action $action
        
        Write-FileMonitorLog "Registering Changed event" 'Debug'
        $changedEvent = Register-ObjectEvent -InputObject $watcher -EventName "Changed" -SourceIdentifier "$($sourceIdBase)_Changed" -Action $action
        
        Write-FileMonitorLog "Registering Deleted event" 'Debug'
        $deletedEvent = Register-ObjectEvent -InputObject $watcher -EventName "Deleted" -SourceIdentifier "$($sourceIdBase)_Deleted" -Action $action
        
        Write-FileMonitorLog "Registering Renamed event" 'Debug'
        $renamedEvent = Register-ObjectEvent -InputObject $watcher -EventName "Renamed" -SourceIdentifier "$($sourceIdBase)_Renamed" -Action $action
        
        # Store event subscriptions for cleanup
        $monitor.EventSubscriptions = @($createdEvent, $changedEvent, $deletedEvent, $renamedEvent)
        
        # Register for our custom events to handle debouncing
        Write-FileMonitorLog "Setting up debounce handler" 'Debug'
        $debounceHandler = Register-EngineEvent -SourceIdentifier "FileMonitor_Change_$Identifier" -Action {
            try {
                $changeEvent = $Event.MessageData
                $monitorId = $changeEvent.MonitorId
                
                Write-Verbose "[DebounceHandler] Received change for monitor: $monitorId"
                
                # Add to monitor's change queue
                $monitor = $null
                if ($script:FileMonitors.TryGetValue($monitorId, [ref]$monitor)) {
                    $monitor.ChangeQueue.Add($changeEvent)
                    $monitor.LastEventAt = Get-Date
                    $monitor.EventCount++
                    
                    Write-Verbose "[DebounceHandler] Added to queue. Queue size: $($monitor.ChangeQueue.Count)"
                    
                    # Handle debouncing
                    Start-DebounceTimer -MonitorId $monitorId -DebounceMs $monitor.DebounceMs
                } else {
                    Write-Warning "[DebounceHandler] Monitor not found: $monitorId"
                }
            }
            catch {
                Write-Warning "[DebounceHandler] Error: $_"
            }
        }
        
        $monitor.EventSubscriptions += $debounceHandler
        
        # Enable the watcher
        Write-FileMonitorLog "Enabling FileSystemWatcher" 'Debug'
        $watcher.EnableRaisingEvents = $true
        $monitor.IsActive = $true
        
        Write-FileMonitorLog "Successfully started monitor: $Identifier" 'Info'
    }
    catch {
        Write-FileMonitorLog "Failed to start monitor: $_" 'Error'
        throw
    }
}

function Start-DebounceTimer {
    param(
        [string]$MonitorId,
        [int]$DebounceMs
    )
    
    Write-Verbose "[DebounceTimer] Starting/restarting timer for monitor: $MonitorId ($DebounceMs ms)"
    
    # Stop existing timer if any
    $existingTimer = $null
    if ($script:DebounceTimers.TryGetValue($MonitorId, [ref]$existingTimer)) {
        Write-Verbose "[DebounceTimer] Stopping existing timer"
        $existingTimer.Stop()
        $existingTimer.Dispose()
    }
    
    # Create new timer
    $timer = New-Object System.Timers.Timer
    $timer.Interval = $DebounceMs
    $timer.AutoReset = $false
    
    # Timer event handler
    $timerAction = Register-ObjectEvent -InputObject $timer -EventName Elapsed -Action {
        try {
            Write-Verbose "[TimerElapsed] Processing debounced changes"
            
            # Find the monitor (we need to pass this info somehow)
            foreach ($monitorEntry in $script:FileMonitors.GetEnumerator()) {
                $monitor = $monitorEntry.Value
                if ($monitor.ChangeQueue.Count -gt 0) {
                    Write-Verbose "[TimerElapsed] Processing $($monitor.ChangeQueue.Count) changes for monitor: $($monitorEntry.Key)"
                    
                    # Get all changes and clear queue
                    $changes = @($monitor.ChangeQueue.ToArray())
                    $monitor.ChangeQueue.Clear()
                    
                    # Aggregate changes
                    $aggregated = Get-AggregatedChanges -Changes $changes
                    
                    Write-Verbose "[TimerElapsed] Aggregated to $($aggregated.Count) unique changes"
                    
                    # Call registered handlers
                    foreach ($handler in $script:ChangeHandlers) {
                        try {
                            Write-Verbose "[TimerElapsed] Calling change handler"
                            & $handler -AggregatedChanges $aggregated
                        }
                        catch {
                            Write-Warning "[TimerElapsed] Handler error: $_"
                        }
                    }
                }
            }
        }
        catch {
            Write-Warning "[TimerElapsed] Error: $_"
        }
    }
    
    # Store timer
    $script:DebounceTimers.TryAdd($MonitorId, $timer) | Out-Null
    
    # Start timer
    $timer.Start()
    Write-Verbose "[DebounceTimer] Timer started"
}

function Get-AggregatedChanges {
    param([array]$Changes)
    
    if ($Changes.Count -eq 0) { return @() }
    
    Write-Verbose "[Aggregate] Processing $($Changes.Count) changes"
    
    # Group changes by file path
    $grouped = $Changes | Group-Object -Property FullPath
    
    $aggregated = @()
    foreach ($group in $grouped) {
        $path = $group.Name
        $fileChanges = $group.Group
        
        Write-Verbose "[Aggregate] Processing $($fileChanges.Count) changes for: $path"
        
        # Determine final change type
        $changeTypes = $fileChanges.ChangeType | Select-Object -Unique
        $finalChangeType = if ('Deleted' -in $changeTypes) { 'Deleted' }
                          elseif ('Created' -in $changeTypes) { 'Created' }
                          elseif ('Renamed' -in $changeTypes) { 'Renamed' }
                          else { 'Changed' }
        
        # Get highest priority (lowest number)
        $priority = ($fileChanges.Priority | Measure-Object -Minimum).Minimum
        
        $aggregated += @{
            Path = $path
            ChangeType = $finalChangeType
            FileType = $fileChanges[0].FileType
            Priority = $priority
            EventCount = $fileChanges.Count
            FirstEvent = ($fileChanges.Timestamp | Sort-Object)[0]
            LastEvent = ($fileChanges.Timestamp | Sort-Object)[-1]
        }
    }
    
    # Sort by priority
    return $aggregated | Sort-Object -Property Priority
}

function Get-SafeFileType {
    param([string]$FilePath)
    
    try {
        if ([string]::IsNullOrEmpty($FilePath)) {
            Write-Verbose "[SafeFileType] Empty file path"
            return 'Unknown'
        }
        
        $fileName = [System.IO.Path]::GetFileName($FilePath)
        if ([string]::IsNullOrEmpty($fileName)) {
            Write-Verbose "[SafeFileType] Could not extract filename from: $FilePath"
            return 'Unknown'
        }
        
        Write-Verbose "[SafeFileType] Classifying: $fileName"
        
        # Check Test patterns first (more specific)
        foreach ($pattern in $script:FilePatterns['Test']) {
            if ($fileName -like $pattern) {
                Write-Verbose "[SafeFileType] Matched Test pattern: $pattern"
                return 'Test'
            }
        }
        
        # Check other patterns
        foreach ($type in @('Build', 'Code', 'Config', 'Documentation')) {
            foreach ($pattern in $script:FilePatterns[$type]) {
                if ($fileName -like $pattern) {
                    Write-Verbose "[SafeFileType] Matched $type pattern: $pattern"
                    return $type
                }
            }
        }
        
        Write-Verbose "[SafeFileType] No pattern matched for: $fileName"
        return 'Unknown'
    }
    catch {
        Write-Warning "[SafeFileType] Error classifying $FilePath : $_"
        return 'Unknown'
    }
}

function Get-SafeChangePriority {
    param(
        [string]$FilePath,
        [string]$ChangeType
    )
    
    try {
        $fileType = Get-SafeFileType -FilePath $FilePath
        
        Write-Verbose "[SafePriority] File: $FilePath, Type: $fileType, Change: $ChangeType"
        
        # Determine priority based on file type
        switch ($fileType) {
            'Build' { return $script:ChangePriority.Critical }
            'Code' { return $script:ChangePriority.High }
            'Config' { return $script:ChangePriority.Medium }
            'Documentation' { return $script:ChangePriority.Low }
            'Test' { return $script:ChangePriority.Minimal }
            default { return $script:ChangePriority.Low }
        }
    }
    catch {
        Write-Warning "[SafePriority] Error determining priority for $FilePath : $_"
        return $script:ChangePriority.Low
    }
}

function Stop-FileMonitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Identifier
    )
    
    Write-FileMonitorLog "Stopping monitor: $Identifier" 'Info'
    
    $monitor = $null
    if (-not $script:FileMonitors.TryGetValue($Identifier, [ref]$monitor)) {
        Write-FileMonitorLog "Monitor not found: $Identifier" 'Warning'
        return
    }
    
    try {
        Write-FileMonitorLog "Disabling FileSystemWatcher" 'Debug'
        
        # Disable the watcher
        if ($monitor.Watcher) {
            $monitor.Watcher.EnableRaisingEvents = $false
        }
        
        Write-FileMonitorLog "Unregistering events" 'Debug'
        
        # Unregister all events
        foreach ($subscription in $monitor.EventSubscriptions) {
            if ($subscription -and $subscription.Name) {
                try {
                    Unregister-Event -SourceIdentifier $subscription.Name -ErrorAction SilentlyContinue
                    Write-Verbose "[Stop] Unregistered event: $($subscription.Name)"
                }
                catch {
                    Write-Verbose "[Stop] Error unregistering event $($subscription.Name): $_"
                }
            }
        }
        
        # Clear event subscriptions
        $monitor.EventSubscriptions = @()
        $monitor.IsActive = $false
        
        Write-FileMonitorLog "Stopping debounce timer" 'Debug'
        
        # Stop and dispose debounce timer
        $timer = $null
        if ($script:DebounceTimers.TryRemove($Identifier, [ref]$timer)) {
            if ($timer) {
                try {
                    $timer.Stop()
                    $timer.Dispose()
                    Write-Verbose "[Stop] Disposed timer for monitor: $Identifier"
                }
                catch {
                    Write-Verbose "[Stop] Error disposing timer: $_"
                }
            }
        }
        
        Write-FileMonitorLog "Disposing FileSystemWatcher" 'Debug'
        
        # Dispose watcher
        if ($monitor.Watcher) {
            try {
                $monitor.Watcher.Dispose()
                Write-Verbose "[Stop] Disposed FileSystemWatcher"
            }
            catch {
                Write-Verbose "[Stop] Error disposing watcher: $_"
            }
        }
        
        Write-FileMonitorLog "Removing monitor from collection" 'Debug'
        
        # Remove from collection
        $script:FileMonitors.TryRemove($Identifier, [ref]$null) | Out-Null
        
        Write-FileMonitorLog "Successfully stopped monitor: $Identifier" 'Info'
    }
    catch {
        Write-FileMonitorLog "Error stopping monitor: $_" 'Error'
        throw
    }
}

function Register-FileChangeHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Handler
    )
    
    Write-FileMonitorLog "Registering new change handler" 'Debug'
    $script:ChangeHandlers.Add($Handler) | Out-Null
    Write-FileMonitorLog "Change handler registered. Total handlers: $($script:ChangeHandlers.Count)" 'Info'
}

function Get-FileMonitorStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Identifier
    )
    
    if ($Identifier) {
        $monitor = $null
        if ($script:FileMonitors.TryGetValue($Identifier, [ref]$monitor)) {
            return $monitor
        } else {
            Write-FileMonitorLog "Monitor not found: $Identifier" 'Warning'
            return $null
        }
    } else {
        return $script:FileMonitors.Values
    }
}

function Get-PendingChanges {
    [CmdletBinding()]
    param()
    
    $allChanges = @()
    foreach ($monitor in $script:FileMonitors.Values) {
        if ($monitor.ChangeQueue.Count -gt 0) {
            $allChanges += $monitor.ChangeQueue.ToArray()
        }
    }
    
    return $allChanges
}

function Clear-ChangeQueue {
    [CmdletBinding()]
    param()
    
    $count = 0
    foreach ($monitor in $script:FileMonitors.Values) {
        $count += $monitor.ChangeQueue.Count
        $monitor.ChangeQueue.Clear()
    }
    
    Write-FileMonitorLog "Cleared $count pending changes" 'Debug'
    return $count
}

function Set-DebounceInterval {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Identifier,
        
        [Parameter(Mandatory = $true)]
        [int]$DebounceMs
    )
    
    $monitor = $null
    if ($script:FileMonitors.TryGetValue($Identifier, [ref]$monitor)) {
        $monitor.DebounceMs = $DebounceMs
        Write-FileMonitorLog "Updated debounce interval to ${DebounceMs}ms for monitor: $Identifier" 'Info'
    } else {
        Write-FileMonitorLog "Monitor not found: $Identifier" 'Warning'
    }
}

function Add-MonitorPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        
        [Parameter(Mandatory = $false)]
        [string]$Filter = '*.*',
        
        [Parameter(Mandatory = $false)]
        [int]$DebounceMs = $script:DefaultDebounceInterval
    )
    
    # Check if path already monitored
    foreach ($monitor in $script:FileMonitors.Values) {
        if ($monitor.Path -eq $Path) {
            Write-FileMonitorLog "Path already monitored: $Path" 'Warning'
            return $monitor.Identifier
        }
    }
    
    # Create and start new monitor
    $identifier = New-FileMonitor -Path $Path -Filter $Filter -DebounceMs $DebounceMs
    Start-FileMonitor -Identifier $identifier
    
    return $identifier
}

function Remove-MonitorPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )
    
    foreach ($monitorEntry in $script:FileMonitors.GetEnumerator()) {
        $monitor = $monitorEntry.Value
        if ($monitor.Path -eq $Path) {
            Stop-FileMonitor -Identifier $monitor.Identifier
            Write-FileMonitorLog "Removed monitor for path: $Path" 'Info'
            return $true
        }
    }
    
    Write-FileMonitorLog "No monitor found for path: $Path" 'Warning'
    return $false
}

function Get-MonitoredPaths {
    [CmdletBinding()]
    param()
    
    $paths = @()
    foreach ($monitor in $script:FileMonitors.Values) {
        $paths += [PSCustomObject]@{
            Path = $monitor.Path
            Filter = $monitor.Filter
            IsActive = $monitor.IsActive
            EventCount = $monitor.EventCount
            LastEventAt = $monitor.LastEventAt
            QueueSize = $monitor.ChangeQueue.Count
        }
    }
    
    return $paths
}

function Test-FileChangeClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    return @{
        FilePath = $FilePath
        FileType = Get-SafeFileType -FilePath $FilePath
        Priority = Get-SafeChangePriority -FilePath $FilePath -ChangeType 'Changed'
    }
}

# Module cleanup
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Write-Verbose "[Unity-Claude-FileMonitor] Module cleanup - disposing all monitors"
    
    # Stop all monitors
    foreach ($identifier in $script:FileMonitors.Keys) {
        try {
            Stop-FileMonitor -Identifier $identifier -ErrorAction SilentlyContinue
        }
        catch {
            Write-Warning "Failed to stop monitor during cleanup: $identifier"
        }
    }
    
    # Clear all collections
    $script:FileMonitors.Clear()
    $script:ChangeHandlers.Clear()
    $script:DebounceTimers.Clear()
}

# Export module members
Export-ModuleMember -Function @(
    'New-FileMonitor',
    'Start-FileMonitor',
    'Stop-FileMonitor',
    'Register-FileChangeHandler',
    'Get-FileMonitorStatus',
    'Get-PendingChanges',
    'Clear-ChangeQueue',
    'Set-DebounceInterval',
    'Add-MonitorPath',
    'Remove-MonitorPath',
    'Get-MonitoredPaths',
    'Test-FileChangeClassification'
)

Write-Verbose "[Unity-Claude-FileMonitor] Fixed module loaded successfully"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCChIQDi1NyFbfP4
# ta0NzF6ccIvk6Rs4CCVVYLkJU6wZiKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEax4cGbCShF8+cwF530flfZ
# NOXjOfnoqs9Jwcb2Rao6MA0GCSqGSIb3DQEBAQUABIIBAF6U72OMUWYubrQ2+FEG
# GoGmMBGERM5OwqKzqUDIyzowEgLrlDAuwh6kvQ2FSVgtlrMunb8Tut9ODhhebvjx
# zvwVb1f8k8RM+itTsNECw66dq8HspQlBwlcz8ohlELn+MGzSuF7b5X1UOglg2v9A
# vqkb3gUdKp8Cy+xDtyoy9jcPnYNEHrczhHb/bhS/u6Ot24JnUMWIRv4BPm+pb0X2
# 24O1fjxdjiyN6Lgxfz6u1foHWKvq4QZAwUcuZaQwGFmOrf69bQEB1XRSdNBeKl5E
# /2uaErS4c/P00R8hyZJ6HIDEHIVxd5XTwMmtFTZsKFPa7yWPfi//UX9XUanXaoIe
# QfI=
# SIG # End signature block
