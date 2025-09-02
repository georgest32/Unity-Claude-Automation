# Unity-Claude-TriggerIntegration.psm1
# Integration layer between DocumentationDrift and TriggerManager/FileMonitor
# Created: 2025-08-24
# Phase 5 - TriggerManager Integration

#Requires -Version 7.2

# Import required modules
try {
    Import-Module Unity-Claude-DocumentationDrift -Force -ErrorAction Stop
    Import-Module Unity-Claude-TriggerConditions -Force -ErrorAction Stop
    Write-Verbose "[TriggerIntegration] Core modules imported successfully"
} catch {
    Write-Error "[TriggerIntegration] Failed to import required modules: $_"
    throw
}

# Module-level variables
$script:IntegrationConfig = @{}
$script:EventHandlers = @{}
$script:MonitoringActive = $false

# Default integration configuration
$script:DefaultIntegrationConfig = @{
    FileMonitorIntegration = @{
        Enabled = $true
        MonitorPaths = @('.', '.\Modules', '.\docs', '.\scripts')
        ExcludePaths = @('.\node_modules', '.\.git', '.\bin', '.\obj')
        FileTypes = @('*.ps1', '*.psm1', '*.psd1', '*.md', '*.txt', '*.cs', '*.py', '*.js', '*.ts')
        BufferTime = 2000  # 2 seconds buffer for file operations
    }
    TriggerManagerIntegration = @{
        Enabled = $true
        PriorityMapping = @{
            'Critical' = 1
            'High' = 2  
            'Medium' = 3
            'Low' = 4
        }
        MaxConcurrentJobs = 3
        JobTimeout = 1800  # 30 minutes
    }
    AutomationSettings = @{
        AutoTrigger = $true
        RequireApproval = $false
        DryRunMode = $false
        NotificationEnabled = $true
    }
    Performance = @{
        MaxQueueSize = 100
        ProcessingInterval = 5000  # 5 seconds
        CleanupInterval = 300000   # 5 minutes
        MetricsCollection = $true
    }
}

function Initialize-TriggerIntegration {
    <#
    .SYNOPSIS
    Initializes the trigger integration system
    
    .DESCRIPTION
    Sets up integration between DocumentationDrift, TriggerManager, and FileMonitor
    components for automated documentation maintenance.
    
    .PARAMETER ConfigPath
    Path to custom integration configuration file
    
    .PARAMETER Force
    Force reinitialization of integration system
    
    .EXAMPLE
    Initialize-TriggerIntegration
    Initializes with default configuration
    
    .EXAMPLE
    Initialize-TriggerIntegration -ConfigPath ".\integration-config.json" -Force
    Initializes with custom configuration
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ConfigPath,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    Write-Verbose "[Initialize-TriggerIntegration] Initializing trigger integration system..."
    
    try {
        # Check if already initialized
        if (-not $Force -and $script:IntegrationConfig.Count -gt 0) {
            Write-Verbose "[Initialize-TriggerIntegration] Already initialized, skipping"
            return $true
        }
        
        # Load configuration
        if ($ConfigPath -and (Test-Path $ConfigPath)) {
            Write-Verbose "[Initialize-TriggerIntegration] Loading configuration from: $ConfigPath"
            $customConfig = Get-Content $ConfigPath | ConvertFrom-Json -AsHashtable
            $script:IntegrationConfig = $script:DefaultIntegrationConfig.Clone()
            
            # Merge custom configuration
            foreach ($key in $customConfig.Keys) {
                $script:IntegrationConfig[$key] = $customConfig[$key]
            }
        } else {
            Write-Verbose "[Initialize-TriggerIntegration] Using default integration configuration"
            $script:IntegrationConfig = $script:DefaultIntegrationConfig.Clone()
        }
        
        # Initialize core systems
        Initialize-DocumentationDrift -Force:$Force
        Initialize-TriggerConditions -Force:$Force
        
        # Set up event handlers
        Register-EventHandlers
        
        # Start monitoring if enabled
        if ($script:IntegrationConfig.FileMonitorIntegration.Enabled) {
            Start-FileMonitoring
        }
        
        Write-Verbose "[Initialize-TriggerIntegration] Trigger integration system initialized successfully"
        return $true
        
    } catch {
        Write-Error "[Initialize-TriggerIntegration] Failed to initialize trigger integration: $_"
        throw
    }
}

function Register-EventHandlers {
    <#
    .SYNOPSIS
    Registers event handlers for file change monitoring
    
    .DESCRIPTION
    Sets up event handlers to respond to file system changes and
    integrate with the documentation automation pipeline.
    #>
    [CmdletBinding()]
    param()
    
    Write-Verbose "[Register-EventHandlers] Registering event handlers..."
    
    try {
        # File change event handler
        $script:EventHandlers.FileChanged = {
            param($EventArgs)
            
            try {
                $filePath = $EventArgs.FullPath
                $changeType = $EventArgs.ChangeType.ToString()
                
                Write-Verbose "[FileChanged] Processing change: $filePath ($changeType)"
                
                # Apply buffer time to avoid processing incomplete file operations
                Start-Sleep -Milliseconds $script:IntegrationConfig.FileMonitorIntegration.BufferTime
                
                # Test trigger conditions
                $triggerResult = Test-TriggerCondition -FilePath $filePath -ChangeType $changeType
                
                if ($triggerResult.ShouldTrigger) {
                    Write-Verbose "[FileChanged] Trigger conditions met for: $filePath"
                    
                    # Add to processing queue
                    $queueResult = Add-ToProcessingQueue -TriggerResult $triggerResult
                    
                    if ($queueResult) {
                        Write-Verbose "[FileChanged] Added to processing queue: $filePath"
                        
                        # Trigger processing if auto-trigger is enabled
                        if ($script:IntegrationConfig.AutomationSettings.AutoTrigger) {
                            Start-AsynchronousProcessing
                        }
                    }
                } else {
                    Write-Verbose "[FileChanged] No trigger needed for: $filePath ($($triggerResult.Reason))"
                }
                
            } catch {
                Write-Error "[FileChanged] Error processing file change event: $_"
            }
        }
        
        # Queue processing event handler
        $script:EventHandlers.QueueProcessor = {
            try {
                Write-Verbose "[QueueProcessor] Starting queue processing cycle..."
                
                $processingResult = Start-QueueProcessing -MaxConcurrent $script:IntegrationConfig.TriggerManagerIntegration.MaxConcurrentJobs
                
                if ($processingResult.ProcessedCount -gt 0) {
                    Write-Verbose "[QueueProcessor] Processed $($processingResult.ProcessedCount) items"
                    
                    # Send notifications if enabled
                    if ($script:IntegrationConfig.AutomationSettings.NotificationEnabled) {
                        Send-ProcessingNotification -ProcessingResult $processingResult
                    }
                    
                    # Collect metrics if enabled
                    if ($script:IntegrationConfig.Performance.MetricsCollection) {
                        Collect-ProcessingMetrics -ProcessingResult $processingResult
                    }
                }
                
            } catch {
                Write-Error "[QueueProcessor] Error during queue processing: $_"
            }
        }
        
        # Cleanup event handler
        $script:EventHandlers.Cleanup = {
            try {
                Write-Verbose "[Cleanup] Running periodic cleanup..."
                
                # Clear completed items from queue
                $clearedCount = Clear-ProcessingQueue -Status 'Completed' -OlderThan 24
                
                if ($clearedCount -gt 0) {
                    Write-Verbose "[Cleanup] Cleared $clearedCount completed items from queue"
                }
                
                # Clear failed items older than 7 days
                $failedCleared = Clear-ProcessingQueue -Status 'Failed' -OlderThan 168
                
                if ($failedCleared -gt 0) {
                    Write-Verbose "[Cleanup] Cleared $failedCleared failed items from queue"
                }
                
            } catch {
                Write-Error "[Cleanup] Error during cleanup: $_"
            }
        }
        
        Write-Verbose "[Register-EventHandlers] Event handlers registered successfully"
        
    } catch {
        Write-Error "[Register-EventHandlers] Failed to register event handlers: $_"
        throw
    }
}

function Start-FileMonitoring {
    <#
    .SYNOPSIS
    Starts file system monitoring for documentation automation
    
    .DESCRIPTION
    Initiates file system monitoring using FileSystemWatcher to detect
    changes that should trigger documentation automation.
    #>
    [CmdletBinding()]
    param()
    
    Write-Verbose "[Start-FileMonitoring] Starting file monitoring..."
    
    try {
        if ($script:MonitoringActive) {
            Write-Verbose "[Start-FileMonitoring] Monitoring already active"
            return $true
        }
        
        # Create file system watchers for each monitor path
        $script:FileSystemWatchers = @()
        
        foreach ($monitorPath in $script:IntegrationConfig.FileMonitorIntegration.MonitorPaths) {
            if (Test-Path $monitorPath) {
                Write-Verbose "[Start-FileMonitoring] Setting up watcher for: $monitorPath"
                
                $watcher = New-Object System.IO.FileSystemWatcher
                $watcher.Path = Resolve-Path $monitorPath
                $watcher.Filter = "*.*"
                $watcher.IncludeSubdirectories = $true
                $watcher.EnableRaisingEvents = $true
                
                # Register events
                Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $script:EventHandlers.FileChanged
                Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $script:EventHandlers.FileChanged
                Register-ObjectEvent -InputObject $watcher -EventName "Deleted" -Action $script:EventHandlers.FileChanged
                Register-ObjectEvent -InputObject $watcher -EventName "Renamed" -Action $script:EventHandlers.FileChanged
                
                $script:FileSystemWatchers += $watcher
            } else {
                Write-Warning "[Start-FileMonitoring] Monitor path does not exist: $monitorPath"
            }
        }
        
        # Start periodic processing timer
        $script:ProcessingTimer = New-Object System.Timers.Timer
        $script:ProcessingTimer.Interval = $script:IntegrationConfig.Performance.ProcessingInterval
        $script:ProcessingTimer.AutoReset = $true
        Register-ObjectEvent -InputObject $script:ProcessingTimer -EventName "Elapsed" -Action $script:EventHandlers.QueueProcessor
        $script:ProcessingTimer.Start()
        
        # Start cleanup timer
        $script:CleanupTimer = New-Object System.Timers.Timer
        $script:CleanupTimer.Interval = $script:IntegrationConfig.Performance.CleanupInterval
        $script:CleanupTimer.AutoReset = $true
        Register-ObjectEvent -InputObject $script:CleanupTimer -EventName "Elapsed" -Action $script:EventHandlers.Cleanup
        $script:CleanupTimer.Start()
        
        $script:MonitoringActive = $true
        
        Write-Verbose "[Start-FileMonitoring] File monitoring started successfully with $($script:FileSystemWatchers.Count) watchers"
        return $true
        
    } catch {
        Write-Error "[Start-FileMonitoring] Failed to start file monitoring: $_"
        throw
    }
}

function Stop-FileMonitoring {
    <#
    .SYNOPSIS
    Stops file system monitoring
    
    .DESCRIPTION
    Stops all file system watchers and associated timers.
    #>
    [CmdletBinding()]
    param()
    
    Write-Verbose "[Stop-FileMonitoring] Stopping file monitoring..."
    
    try {
        if (-not $script:MonitoringActive) {
            Write-Verbose "[Stop-FileMonitoring] Monitoring not active"
            return $true
        }
        
        # Stop and dispose file system watchers
        if ($script:FileSystemWatchers) {
            foreach ($watcher in $script:FileSystemWatchers) {
                $watcher.EnableRaisingEvents = $false
                $watcher.Dispose()
            }
            $script:FileSystemWatchers = @()
        }
        
        # Stop timers
        if ($script:ProcessingTimer) {
            $script:ProcessingTimer.Stop()
            $script:ProcessingTimer.Dispose()
            $script:ProcessingTimer = $null
        }
        
        if ($script:CleanupTimer) {
            $script:CleanupTimer.Stop()
            $script:CleanupTimer.Dispose()
            $script:CleanupTimer = $null
        }
        
        # Unregister events
        Get-EventSubscriber | Where-Object { $_.SourceObject -is [System.IO.FileSystemWatcher] -or $_.SourceObject -is [System.Timers.Timer] } | Unregister-Event
        
        $script:MonitoringActive = $false
        
        Write-Verbose "[Stop-FileMonitoring] File monitoring stopped successfully"
        return $true
        
    } catch {
        Write-Error "[Stop-FileMonitoring] Failed to stop file monitoring: $_"
        throw
    }
}

function Start-AsynchronousProcessing {
    <#
    .SYNOPSIS
    Starts asynchronous processing of queued items
    
    .DESCRIPTION
    Initiates background processing of items in the processing queue
    without blocking the main thread.
    #>
    [CmdletBinding()]
    param()
    
    Write-Verbose "[Start-AsynchronousProcessing] Starting asynchronous processing..."
    
    try {
        # Check queue size limits
        $queueSize = (Get-ProcessingQueue -Status 'Queued').Count
        
        if ($queueSize -gt $script:IntegrationConfig.Performance.MaxQueueSize) {
            Write-Warning "[Start-AsynchronousProcessing] Queue size ($queueSize) exceeds maximum ($($script:IntegrationConfig.Performance.MaxQueueSize))"
            
            # Clear oldest items to make room
            $oldestItems = Get-ProcessingQueue -Status 'Queued' | Sort-Object QueuedAt | Select-Object -First ($queueSize - $script:IntegrationConfig.Performance.MaxQueueSize)
            foreach ($item in $oldestItems) {
                $item.Status = 'Skipped'
                $item.Error = 'Queue size limit exceeded'
            }
        }
        
        # Start processing job
        $processingJob = Start-Job -ScriptBlock {
            param($ConfigPath)
            
            # Import modules in job context
            Import-Module Unity-Claude-DocumentationDrift -Force
            Import-Module Unity-Claude-TriggerConditions -Force
            
            # Process the queue
            $result = Start-QueueProcessing -MaxConcurrent 2 -BatchSize 3
            return $result
            
        } -ArgumentList $null
        
        Write-Verbose "[Start-AsynchronousProcessing] Processing job started: $($processingJob.Id)"
        
        return $processingJob.Id
        
    } catch {
        Write-Error "[Start-AsynchronousProcessing] Failed to start asynchronous processing: $_"
        throw
    }
}

function Send-ProcessingNotification {
    <#
    .SYNOPSIS
    Sends notifications about processing results
    
    .DESCRIPTION
    Sends notifications via configured channels about documentation
    automation processing results.
    
    .PARAMETER ProcessingResult
    Result from Start-QueueProcessing
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ProcessingResult
    )
    
    Write-Verbose "[Send-ProcessingNotification] Sending processing notification..."
    
    try {
        $notification = @{
            Timestamp = Get-Date
            ProcessedCount = $ProcessingResult.ProcessedCount
            SuccessCount = $ProcessingResult.SuccessCount
            FailedCount = $ProcessingResult.FailedCount
            Message = "Documentation automation processed $($ProcessingResult.ProcessedCount) items ($($ProcessingResult.SuccessCount) successful, $($ProcessingResult.FailedCount) failed)"
        }
        
        # In a real implementation, this would send to configured notification channels
        # For now, we'll just log the notification
        Write-Information "[Notification] $($notification.Message)" -InformationAction Continue
        
        # Could integrate with:
        # - Email notifications
        # - Slack/Teams webhooks  
        # - Windows notifications
        # - Custom logging systems
        
        return $notification
        
    } catch {
        Write-Error "[Send-ProcessingNotification] Failed to send notification: $_"
        throw
    }
}

function Collect-ProcessingMetrics {
    <#
    .SYNOPSIS
    Collects metrics about processing performance
    
    .DESCRIPTION
    Collects and stores metrics about documentation automation
    processing performance for analysis and reporting.
    
    .PARAMETER ProcessingResult
    Result from Start-QueueProcessing
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ProcessingResult
    )
    
    Write-Verbose "[Collect-ProcessingMetrics] Collecting processing metrics..."
    
    try {
        $metrics = @{
            Timestamp = Get-Date
            ProcessedItems = $ProcessingResult.ProcessedCount
            SuccessfulItems = $ProcessingResult.SuccessCount
            FailedItems = $ProcessingResult.FailedCount
            SuccessRate = if ($ProcessingResult.ProcessedCount -gt 0) { 
                ($ProcessingResult.SuccessCount / $ProcessingResult.ProcessedCount) * 100 
            } else { 
                0 
            }
            QueueSize = (Get-ProcessingQueue).Count
            AverageProcessingTime = if ($ProcessingResult.Results) {
                ($ProcessingResult.Results | Measure-Object -Property Duration -Average).Average
            } else {
                0
            }
        }
        
        # Store metrics (in a real implementation, this would persist to a database)
        if (-not $script:ProcessingMetrics) {
            $script:ProcessingMetrics = @()
        }
        $script:ProcessingMetrics += $metrics
        
        # Keep only last 1000 metrics entries to prevent memory issues
        if ($script:ProcessingMetrics.Count -gt 1000) {
            $script:ProcessingMetrics = $script:ProcessingMetrics | Select-Object -Last 1000
        }
        
        Write-Verbose "[Collect-ProcessingMetrics] Metrics collected: Success rate $([math]::Round($metrics.SuccessRate, 2))%"
        
        return $metrics
        
    } catch {
        Write-Error "[Collect-ProcessingMetrics] Failed to collect metrics: $_"
        throw
    }
}

function Get-IntegrationStatus {
    <#
    .SYNOPSIS
    Gets the current status of the trigger integration system
    
    .DESCRIPTION
    Returns comprehensive status information about the trigger integration
    system including monitoring status, queue status, and performance metrics.
    
    .EXAMPLE
    Get-IntegrationStatus
    Gets current integration system status
    #>
    [CmdletBinding()]
    param()
    
    try {
        $status = @{
            Timestamp = Get-Date
            MonitoringActive = $script:MonitoringActive
            Configuration = $script:IntegrationConfig
            Queue = @{
                TotalItems = (Get-ProcessingQueue).Count
                QueuedItems = (Get-ProcessingQueue -Status 'Queued').Count
                ProcessingItems = (Get-ProcessingQueue -Status 'Processing').Count
                CompletedItems = (Get-ProcessingQueue -Status 'Completed').Count
                FailedItems = (Get-ProcessingQueue -Status 'Failed').Count
            }
            FileSystemWatchers = if ($script:FileSystemWatchers) { $script:FileSystemWatchers.Count } else { 0 }
            RecentMetrics = if ($script:ProcessingMetrics) { 
                $script:ProcessingMetrics | Select-Object -Last 10 
            } else { 
                @() 
            }
        }
        
        return $status
        
    } catch {
        Write-Error "[Get-IntegrationStatus] Failed to get integration status: $_"
        throw
    }
}

# Export functions
$ExportedFunctions = @(
    'Initialize-TriggerIntegration',
    'Start-FileMonitoring',
    'Stop-FileMonitoring', 
    'Start-AsynchronousProcessing',
    'Get-IntegrationStatus'
)

Export-ModuleMember -Function $ExportedFunctions

# Auto-initialize on import
Write-Verbose "[TriggerIntegration] Module loaded. Call Initialize-TriggerIntegration to start integration."
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD+UUKR7VkAA6zt
# mpvYzHsmLArkWMTVbowFu7y2PJZau6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDKtwd3El1hb+6FmEG0QIuW0
# HXkSpRvxzS1HtNBp8b2iMA0GCSqGSIb3DQEBAQUABIIBALCCwWeL8WLeHECSThlM
# XqgUvLYeGSwi3F4i68evIJ6df2nJPw7knsQ1kvtilxGkNlK6r0yFXgcxrDwApIdS
# nBsXefVzbNBinOnSVvjJaZxmI3Iqvsd+KY8+XUml730XkMVDcUR68tD1dmIzGWUZ
# OZyHGe57PVw/ydj6iCr+jd9vHvZnrGJypjwYBvliPXFb3B5+6q42lGjO0ztX8D09
# j3YaHrRWRbl1FKASCACXyHcbMw2AZumMtW3NNAdr1JxR4+O5PtyQyR4WcP2Q53WR
# xsYDeKXxHgLVYXln2Xy4xmEnQNT1ZqG5lLVCGXnIPfpRy4/kFWv7gZqR6oMBp432
# qHI=
# SIG # End signature block
