# Unity-Claude-FileMonitor Module
# Real-time file monitoring with debouncing and change classification

# Module-level variables - using approach that works with event handlers
$script:FileMonitors = @{}
$script:ChangeQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
$script:DebounceTimers = @{}
$script:DefaultDebounceInterval = 500  # milliseconds
$script:MonitoredPaths = @()
$script:ChangeHandlers = @()

# Global variables accessible from event handlers
$Global:FileMonitorChangeQueue = $script:ChangeQueue
$Global:FileMonitorDebounceTimers = $script:DebounceTimers
$Global:FileMonitorHandlers = $script:ChangeHandlers

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
    
    Write-Verbose "[New-FileMonitor] Creating monitor for path: $Path with identifier: $Identifier"
    
    try {
        # Validate path exists
        if (-not (Test-Path $Path)) {
            throw "Path does not exist: $Path"
        }
        
        # Create FileSystemWatcher
        $watcher = New-Object System.IO.FileSystemWatcher
        $watcher.Path = $Path
        $watcher.Filter = $Filter
        $watcher.IncludeSubdirectories = $IncludeSubdirectories
        $watcher.NotifyFilter = $NotifyFilter
        $watcher.EnableRaisingEvents = $false  # Will be enabled in Start-FileMonitor
        
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
        }
        
        $script:FileMonitors[$Identifier] = $monitorConfig
        $script:MonitoredPaths += $Path
        
        Write-Verbose "[New-FileMonitor] Successfully created monitor: $Identifier"
        return $Identifier
    }
    catch {
        Write-Error "[New-FileMonitor] Failed to create monitor: $_"
        throw
    }
}

function Start-FileMonitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Identifier
    )
    
    Write-Verbose "[Start-FileMonitor] Starting monitor: $Identifier"
    
    if (-not $script:FileMonitors.ContainsKey($Identifier)) {
        throw "Monitor not found: $Identifier"
    }
    
    $monitor = $script:FileMonitors[$Identifier]
    $watcher = $monitor.Watcher
    
    try {
        # Register event handlers with debouncing
        $changeHandler = [scriptblock]::Create(@"
            try {
                `$eventArgs = `$Event.SourceEventArgs
                `$changeType = `$eventArgs.ChangeType
                `$fullPath = `$eventArgs.FullPath
                `$name = `$eventArgs.Name
                `$monitorId = `$Event.MessageData.MonitorId
                `$debounceMs = `$Event.MessageData.DebounceMs
                
                Write-Verbose "[FileMonitor] Detected `$changeType on: `$fullPath"
                
                # Get file type and priority using the classification functions from main scope
                `$fileType = 'Unknown'
                `$priority = 4
                
                `$fileName = [System.IO.Path]::GetFileName(`$fullPath)
                
                # Simple classification in event handler scope
                if (`$fileName -like '*test*.ps1' -or `$fileName -like '*test*.cs' -or `$fileName -like '*spec*.js' -or `$fileName -like '*test*.py') {
                    `$fileType = 'Test'
                    `$priority = 5
                } elseif (`$fileName -like '*.csproj' -or `$fileName -like '*.sln' -or `$fileName -eq 'package.json' -or `$fileName -eq 'requirements.txt' -or `$fileName -like '*.gradle') {
                    `$fileType = 'Build'
                    `$priority = 1
                } elseif (`$fileName -like '*.ps1' -or `$fileName -like '*.psm1' -or `$fileName -like '*.psd1' -or `$fileName -like '*.cs' -or `$fileName -like '*.js' -or `$fileName -like '*.ts' -or `$fileName -like '*.py') {
                    `$fileType = 'Code'
                    `$priority = 2
                } elseif (`$fileName -like '*.json' -or `$fileName -like '*.xml' -or `$fileName -like '*.yaml' -or `$fileName -like '*.yml' -or `$fileName -like '*.config' -or `$fileName -like '*.ini') {
                    `$fileType = 'Config'
                    `$priority = 3
                } elseif (`$fileName -like '*.md' -or `$fileName -like '*.txt' -or `$fileName -like '*.rst' -or `$fileName -like '*.adoc') {
                    `$fileType = 'Documentation'
                    `$priority = 4
                }
                
                # Create change event object
                `$changeEvent = @{
                    ChangeType = `$changeType
                    FullPath = `$fullPath
                    Name = `$name
                    Timestamp = Get-Date
                    MonitorId = `$monitorId
                    FileType = `$fileType
                    Priority = `$priority
                }
                
                # Add to change queue using global variable accessible from event handler
                if (`$null -ne `$Global:FileMonitorChangeQueue) {
                    `$Global:FileMonitorChangeQueue.Enqueue(`$changeEvent)
                    Write-Verbose "[EventHandler] Added event to queue. Queue size: `$(`$Global:FileMonitorChangeQueue.Count)"
                } else {
                    Write-Warning "[EventHandler] Global ChangeQueue is null - cannot enqueue event"
                    return
                }
                
                # Process debouncing with null checks using global variables
                if (`$null -ne `$Global:FileMonitorDebounceTimers -and `$Global:FileMonitorDebounceTimers.ContainsKey(`$monitorId)) {
                    Write-Verbose "[EventHandler] Restarting existing timer for monitor: `$monitorId"
                    `$timer = `$Global:FileMonitorDebounceTimers[`$monitorId]
                    if (`$null -ne `$timer) {
                        `$timer.Stop()
                        `$timer.Start()
                    } else {
                        Write-Warning "[EventHandler] Timer is null for monitor: `$monitorId"
                    }
                } elseif (`$null -ne `$Global:FileMonitorDebounceTimers) {
                    `$timer = New-Object System.Timers.Timer
                    `$timer.Interval = `$debounceMs
                    `$timer.AutoReset = `$false
                    
                    `$timerAction = {
                        try {
                            Write-Verbose "[Debounce] Processing changes after debounce period"
                            `$changes = @()
                            `$change = `$null
                            
                            if (`$null -ne `$Global:FileMonitorChangeQueue) {
                                Write-Verbose "[Debounce] Dequeuing changes from queue"
                                while (`$Global:FileMonitorChangeQueue.TryDequeue([ref]`$change)) {
                                    `$changes += `$change
                                }
                                Write-Verbose "[Debounce] Dequeued `$(`$changes.Count) changes"
                            } else {
                                Write-Warning "[Debounce] Global ChangeQueue is null in timer action"
                                return
                            }
                            
                            if (`$changes.Count -gt 0) {
                                Write-Verbose "[Debounce] Calling `$(`$Global:FileMonitorHandlers.Count) handlers"
                                if (`$null -ne `$Global:FileMonitorHandlers) {
                                    foreach (`$handler in `$Global:FileMonitorHandlers) {
                                        try {
                                            Write-Verbose "[Debounce] Calling handler with `$(`$changes.Count) changes"
                                            & `$handler -AggregatedChanges `$changes
                                        } catch {
                                            Write-Warning "[Debounce] Handler error: `$_"
                                        }
                                    }
                                } else {
                                    Write-Warning "[Debounce] Global ChangeHandlers is null"
                                }
                            } else {
                                Write-Verbose "[Debounce] No changes to process"
                            }
                        } catch {
                            Write-Warning "[Debounce] Timer action error: `$_"
                        }
                    }
                    
                    Register-ObjectEvent -InputObject `$timer -EventName Elapsed -Action `$timerAction | Out-Null
                    if (`$null -ne `$Global:FileMonitorDebounceTimers) {
                        `$Global:FileMonitorDebounceTimers[`$monitorId] = `$timer
                        Write-Verbose "[EventHandler] Stored timer for monitor: `$monitorId"
                    } else {
                        Write-Warning "[EventHandler] Global DebounceTimers is null - cannot store timer"
                    }
                    `$timer.Start()
                    Write-Verbose "[EventHandler] Started debounce timer (`$debounceMs ms)"
                } else {
                    Write-Warning "[EventHandler] Global DebounceTimers is null - cannot create timer"
                }
            }
            catch {
                Write-Warning "[FileMonitor] Event handler error: `$_"
            }
"@)
        
        $messageData = @{
            MonitorId = $Identifier
            DebounceMs = $monitor.DebounceMs
        }
        
        # Register events
        $createdEvent = Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $changeHandler -MessageData $messageData
        $changedEvent = Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $changeHandler -MessageData $messageData
        $deletedEvent = Register-ObjectEvent -InputObject $watcher -EventName "Deleted" -Action $changeHandler -MessageData $messageData
        $renamedEvent = Register-ObjectEvent -InputObject $watcher -EventName "Renamed" -Action $changeHandler -MessageData $messageData
        
        # Store event subscriptions for cleanup
        $monitor.EventSubscriptions = @($createdEvent, $changedEvent, $deletedEvent, $renamedEvent)
        
        # Enable the watcher
        $watcher.EnableRaisingEvents = $true
        $monitor.IsActive = $true
        
        Write-Verbose "[Start-FileMonitor] Successfully started monitor: $Identifier"
    }
    catch {
        Write-Error "[Start-FileMonitor] Failed to start monitor: $_"
        throw
    }
}

function Stop-FileMonitor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Identifier
    )
    
    Write-Verbose "[Stop-FileMonitor] Stopping monitor: $Identifier"
    
    if (-not $script:FileMonitors.ContainsKey($Identifier)) {
        throw "Monitor not found: $Identifier"
    }
    
    $monitor = $script:FileMonitors[$Identifier]
    
    try {
        # Disable the watcher
        $monitor.Watcher.EnableRaisingEvents = $false
        
        # Unregister all events
        foreach ($subscription in $monitor.EventSubscriptions) {
            if ($subscription) {
                Unregister-Event -SourceIdentifier $subscription.Name -ErrorAction SilentlyContinue
            }
        }
        
        # Clear event subscriptions
        $monitor.EventSubscriptions = @()
        $monitor.IsActive = $false
        
        # Stop any active debounce timer
        if ($script:DebounceTimers.ContainsKey($Identifier)) {
            $timer = $script:DebounceTimers[$Identifier]
            if ($timer) {
                $timer.Stop()
                $timer.Dispose()
                $script:DebounceTimers.Remove($Identifier)
            }
        }
        
        Write-Verbose "[Stop-FileMonitor] Successfully stopped monitor: $Identifier"
    }
    catch {
        Write-Error "[Stop-FileMonitor] Failed to stop monitor: $_"
        throw
    }
    finally {
        # Ensure proper disposal
        if ($monitor.Watcher) {
            $monitor.Watcher.Dispose()
        }
        $script:FileMonitors.Remove($Identifier)
    }
}


function Aggregate-Changes {
    param(
        [array]$Changes
    )
    
    # Group changes by file path
    $grouped = $Changes | Group-Object -Property FullPath
    
    $aggregated = @()
    foreach ($group in $grouped) {
        $path = $group.Name
        $fileChanges = $group.Group
        
        # Determine final change type
        $changeTypes = $fileChanges.ChangeType | Select-Object -Unique
        $finalChangeType = if ('Deleted' -in $changeTypes) { 'Deleted' }
                          elseif ('Created' -in $changeTypes) { 'Created' }
                          elseif ('Renamed' -in $changeTypes) { 'Renamed' }
                          else { 'Changed' }
        
        # Get highest priority
        $priority = ($fileChanges.Priority | Measure-Object -Minimum).Minimum
        
        $aggregated += @{
            Path = $path
            ChangeType = $finalChangeType
            FileType = $fileChanges[0].FileType
            Priority = $priority
            EventCount = $fileChanges.Count
            FirstEvent = ($fileChanges.Timestamp | Measure-Object -Minimum).Minimum
            LastEvent = ($fileChanges.Timestamp | Measure-Object -Maximum).Maximum
        }
    }
    
    # Sort by priority
    return $aggregated | Sort-Object -Property Priority
}

function Get-FileType {
    param(
        [string]$FilePath
    )
    
    $extension = [System.IO.Path]::GetExtension($FilePath)
    $fileName = [System.IO.Path]::GetFileName($FilePath)
    
    # Check Test patterns first (more specific)
    foreach ($pattern in $script:FilePatterns['Test']) {
        if ($fileName -like $pattern) {
            return 'Test'
        }
    }
    
    # Check other patterns
    foreach ($type in @('Build', 'Code', 'Config', 'Documentation')) {
        foreach ($pattern in $script:FilePatterns[$type]) {
            if ($fileName -like $pattern) {
                return $type
            }
        }
    }
    
    return 'Unknown'
}

function Get-ChangePriority {
    param(
        [string]$FilePath,
        [string]$ChangeType
    )
    
    $fileType = Get-FileType -FilePath $FilePath
    $fileName = [System.IO.Path]::GetFileName($FilePath)
    
    # Determine priority based on file type and change type
    if ($fileType -eq 'Build') {
        return $script:ChangePriority.Critical
    }
    elseif ($fileType -eq 'Code' -and $ChangeType -ne 'Deleted') {
        return $script:ChangePriority.High
    }
    elseif ($fileType -eq 'Config') {
        return $script:ChangePriority.Medium
    }
    elseif ($fileType -eq 'Documentation') {
        return $script:ChangePriority.Low
    }
    elseif ($fileType -eq 'Test') {
        return $script:ChangePriority.Minimal
    }
    else {
        return $script:ChangePriority.Low
    }
}

function Register-FileChangeHandler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$Handler
    )
    
    $script:ChangeHandlers += $Handler
    $Global:FileMonitorHandlers = $script:ChangeHandlers  # Keep global in sync
    Write-Verbose "[Register-FileChangeHandler] Registered new change handler"
}

function Get-FileMonitorStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Identifier
    )
    
    if ($Identifier) {
        if ($script:FileMonitors.ContainsKey($Identifier)) {
            return $script:FileMonitors[$Identifier]
        }
        else {
            Write-Warning "Monitor not found: $Identifier"
            return $null
        }
    }
    else {
        return $script:FileMonitors.Values
    }
}

function Get-PendingChanges {
    [CmdletBinding()]
    param()
    
    $changes = @()
    $tempQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    
    # Drain queue to array and refill
    $change = $null
    while ($script:ChangeQueue.TryDequeue([ref]$change)) {
        $changes += $change
        $tempQueue.Enqueue($change)
    }
    
    # Restore queue
    while ($tempQueue.TryDequeue([ref]$change)) {
        $script:ChangeQueue.Enqueue($change)
    }
    
    return $changes
}

function Clear-ChangeQueue {
    [CmdletBinding()]
    param()
    
    $count = 0
    $change = $null
    while ($script:ChangeQueue.TryDequeue([ref]$change)) {
        $count++
    }
    
    Write-Verbose "[Clear-ChangeQueue] Cleared $count pending changes"
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
    
    if ($script:FileMonitors.ContainsKey($Identifier)) {
        $script:FileMonitors[$Identifier].DebounceMs = $DebounceMs
        Write-Verbose "[Set-DebounceInterval] Updated debounce interval to ${DebounceMs}ms for monitor: $Identifier"
    }
    else {
        Write-Warning "Monitor not found: $Identifier"
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
    $existing = $script:FileMonitors.Values | Where-Object { $_.Path -eq $Path }
    if ($existing) {
        Write-Warning "Path already monitored: $Path"
        return $existing.Identifier
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
    
    $monitor = $script:FileMonitors.Values | Where-Object { $_.Path -eq $Path }
    if ($monitor) {
        Stop-FileMonitor -Identifier $monitor.Identifier
        Write-Verbose "[Remove-MonitorPath] Removed monitor for path: $Path"
        return $true
    }
    else {
        Write-Warning "No monitor found for path: $Path"
        return $false
    }
}

function Get-MonitoredPaths {
    [CmdletBinding()]
    param()
    
    return $script:FileMonitors.Values | Select-Object -Property Path, Filter, IsActive, EventCount, LastEventAt
}

function Test-FileChangeClassification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    return @{
        FilePath = $FilePath
        FileType = Get-FileType -FilePath $FilePath
        Priority = Get-ChangePriority -FilePath $FilePath -ChangeType 'Changed'
    }
}

# Module cleanup
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    Write-Verbose "[Unity-Claude-FileMonitor] Module cleanup - disposing all monitors"
    
    foreach ($identifier in $script:FileMonitors.Keys) {
        try {
            Stop-FileMonitor -Identifier $identifier -ErrorAction SilentlyContinue
        }
        catch {
            Write-Warning "Failed to stop monitor during cleanup: $identifier"
        }
    }
    
    # Clear all module variables
    $script:FileMonitors.Clear()
    $script:ChangeQueue = $null
    $script:DebounceTimers.Clear()
    $script:MonitoredPaths = @()
    $script:ChangeHandlers = @()
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

Write-Verbose "[Unity-Claude-FileMonitor] Module loaded successfully"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA0Hd8UTSdtSyux
# ksGQI44Lck75xQwDmmp8iFQiOHxa0aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDQyvm7Af9It1IS6Q80cUqGR
# /L1pKVKNuxf28agbdGUBMA0GCSqGSIb3DQEBAQUABIIBABQdpOcaQjI1sQOChASH
# x7qqSD5PvW7ylwsbYkUyQUBbz4efgMbUdLfgGaP/obUvFY+LPtL60VPNzR9aCRaF
# ZcgVe0U3KnKoignF9qL+xYC87MOAi5OjwoTB/WisYjEK1OqQr6D+jSk+lfBwscGo
# aZbUlTg5mG0/2ZWacHA4dVtfI/CufdQWOtsXjFlKH+wBRRMkw6LnWw+Zsn2hoSbN
# 2BWH2/0ZVwiRjSI9W7ze+onMdrh6qxUkD9iKESUIRzfM1zILuo+Fh+48FBbZsBYS
# 2Yp4aXezgVwBjBwQtK9jLdW60tSCjsYJeL80lFXcmyfjGb5QEdZNMVfOdrsrquqD
# nT8=
# SIG # End signature block
