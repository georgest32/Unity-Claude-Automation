# Unity-Claude-ResourceOptimizer.psm1
# Resource usage optimization module for Day 14 final task
# Provides memory management, log rotation, cleanup, and resource alerting
# Date: 2025-08-18 | Day 14: Complete Feedback Loop Integration

#region Module Configuration and Dependencies

$ErrorActionPreference = "Stop"

Write-Host "[ResourceOptimizer] Loading resource usage optimization module..." -ForegroundColor Cyan

# Resource optimization configuration
$script:ResourceConfig = @{
    # Memory management
    MemoryMonitoringEnabled = $true
    MemoryCheckIntervalMinutes = 5
    MemoryPressureThresholdMB = 400
    CriticalMemoryThresholdMB = 800
    AutoGarbageCollectionEnabled = $true
    AggressiveGCThresholdMB = 600
    
    # Log management
    LogRotationEnabled = $true
    MaxLogFileSizeMB = 50
    MaxLogFiles = 10
    LogCompressionEnabled = $true
    LogArchiveAfterDays = 7
    
    # Session cleanup
    SessionCleanupEnabled = $true
    TempFileCleanupEnabled = $true
    SessionDataRetentionDays = 30
    CacheCleanupEnabled = $true
    
    # Resource alerting
    AlertingEnabled = $true
    AlertThresholds = @{
        MemoryUsageMB = 500
        CpuUsagePercentage = 85
        DiskUsagePercentage = 90
        OpenFileHandles = 100
    }
    
    # Cleanup scheduling
    AutoCleanupEnabled = $true
    CleanupIntervalHours = 6
    MaintenanceWindowHour = 2  # 2 AM
    
    # Paths
    DataPath = Join-Path $PSScriptRoot "..\SessionData"
    LogPath = Join-Path $PSScriptRoot "..\SessionData\Logs"
    TempPath = Join-Path $PSScriptRoot "..\SessionData\Temp"
    ArchivePath = Join-Path $PSScriptRoot "..\SessionData\Archive"
    
    # Logging
    LogFile = "resource_optimizer.log"
    VerboseLogging = $true
}

# Ensure directories exist
foreach ($path in @($script:ResourceConfig.LogPath, $script:ResourceConfig.TempPath, $script:ResourceConfig.ArchivePath)) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# Initialize resource tracking
$script:ResourceMetrics = @{
    LastMemoryCheck = Get-Date
    LastLogRotation = Get-Date
    LastCleanup = Get-Date
    LastGarbageCollection = Get-Date
    
    MemoryHistory = @()
    CpuHistory = @()
    AlertHistory = @()
    
    TotalGarbageCollections = 0
    TotalMemoryFreed = 0
    TotalFilesDeleted = 0
    TotalSpaceFreed = 0
}

# Initialize cleanup job tracking
$script:CleanupJobs = @{}

#endregion

#region Logging and Utilities

function Write-ResourceLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO",
        [string]$Component = "ResourceOptimizer"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    
    # Console output with colors
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "DEBUG" { "Gray" }
    }
    
    if ($Level -ne "DEBUG" -or $script:ResourceConfig.VerboseLogging) {
        Write-Host $logEntry -ForegroundColor $color
    }
    
    # File logging
    $logFile = Join-Path $script:ResourceConfig.LogPath $script:ResourceConfig.LogFile
    try {
        Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    } catch {
        Write-Warning "Failed to write to resource log: $($_.Exception.Message)"
    }
}

function Get-ResourceTimestamp {
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
}

function ConvertTo-HumanReadableSize {
    param([long]$Bytes)
    
    $sizes = @("B", "KB", "MB", "GB", "TB")
    $index = 0
    $size = $Bytes
    
    while ($size -gt 1024 -and $index -lt ($sizes.Length - 1)) {
        $size = $size / 1024
        $index++
    }
    
    return "$([Math]::Round($size, 2)) $($sizes[$index])"
}

#endregion

#region Memory Management

function Get-MemoryUsage {
    param([switch]$Detailed)
    
    try {
        $process = Get-Process -Id $PID
        $workingSetMB = [Math]::Round($process.WorkingSet64 / 1MB, 2)
        $privateMemoryMB = [Math]::Round($process.PrivateMemorySize64 / 1MB, 2)
        $virtualMemoryMB = [Math]::Round($process.VirtualMemorySize64 / 1MB, 2)
        
        $gcMemoryMB = [Math]::Round([GC]::GetTotalMemory($false) / 1MB, 2)
        
        $memoryInfo = @{
            WorkingSetMB = $workingSetMB
            PrivateMemoryMB = $privateMemoryMB
            VirtualMemoryMB = $virtualMemoryMB
            GCMemoryMB = $gcMemoryMB
            Timestamp = Get-ResourceTimestamp
        }
        
        if ($Detailed) {
            # Get system memory info
            $systemMemory = Get-CimInstance -ClassName Win32_ComputerSystem
            $totalMemoryMB = [Math]::Round($systemMemory.TotalPhysicalMemory / 1MB, 2)
            
            $memoryInfo.SystemTotalMemoryMB = $totalMemoryMB
            $memoryInfo.SystemMemoryUsagePercent = [Math]::Round(($workingSetMB / $totalMemoryMB) * 100, 2)
        }
        
        return @{
            Success = $true
            MemoryInfo = $memoryInfo
        }
    } catch {
        Write-ResourceLog "Failed to get memory usage: $($_.Exception.Message)" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.ToString()
        }
    }
}

function Invoke-MemoryMonitoring {
    $timeSinceLastCheck = ((Get-Date) - $script:ResourceMetrics.LastMemoryCheck).TotalMinutes
    
    if ($timeSinceLastCheck -lt $script:ResourceConfig.MemoryCheckIntervalMinutes) {
        return @{ Success = $true; Message = "Memory check not needed yet" }
    }
    
    Write-ResourceLog "Performing memory monitoring check" -Level "DEBUG"
    
    try {
        $memoryResult = Get-MemoryUsage -Detailed
        if (-not $memoryResult.Success) {
            return $memoryResult
        }
        
        $memoryInfo = $memoryResult.MemoryInfo
        $workingSetMB = $memoryInfo.WorkingSetMB
        
        # Add to history
        $script:ResourceMetrics.MemoryHistory += $memoryInfo
        
        # Keep only recent history (last 24 hours worth)
        $maxHistoryEntries = (24 * 60) / $script:ResourceConfig.MemoryCheckIntervalMinutes
        if ($script:ResourceMetrics.MemoryHistory.Count -gt $maxHistoryEntries) {
            $script:ResourceMetrics.MemoryHistory = $script:ResourceMetrics.MemoryHistory | Select-Object -Last $maxHistoryEntries
        }
        
        $script:ResourceMetrics.LastMemoryCheck = Get-Date
        
        # Check for memory pressure
        $pressureLevel = "Normal"
        $actionRequired = $false
        
        if ($workingSetMB -gt $script:ResourceConfig.CriticalMemoryThresholdMB) {
            $pressureLevel = "Critical"
            $actionRequired = $true
            Write-ResourceLog "Critical memory usage detected: ${workingSetMB}MB" -Level "ERROR"
            
            if ($script:ResourceConfig.AlertingEnabled) {
                Invoke-ResourceAlert -Type "CriticalMemory" -Value $workingSetMB -Threshold $script:ResourceConfig.CriticalMemoryThresholdMB
            }
        } elseif ($workingSetMB -gt $script:ResourceConfig.MemoryPressureThresholdMB) {
            $pressureLevel = "Warning"
            Write-ResourceLog "Memory pressure detected: ${workingSetMB}MB" -Level "WARNING"
            
            if ($script:ResourceConfig.AlertingEnabled) {
                Invoke-ResourceAlert -Type "MemoryPressure" -Value $workingSetMB -Threshold $script:ResourceConfig.MemoryPressureThresholdMB
            }
        }
        
        # Trigger automatic garbage collection if enabled and threshold exceeded
        if ($script:ResourceConfig.AutoGarbageCollectionEnabled -and 
            $workingSetMB -gt $script:ResourceConfig.AggressiveGCThresholdMB) {
            
            Write-ResourceLog "Triggering automatic garbage collection due to high memory usage" -Level "INFO"
            $gcResult = Invoke-GarbageCollection -Aggressive
            
            if ($gcResult.Success) {
                Write-ResourceLog "Garbage collection freed $([Math]::Round($gcResult.MemoryFreed / 1MB, 2))MB" -Level "INFO"
            }
        }
        
        return @{
            Success = $true
            MemoryInfo = $memoryInfo
            PressureLevel = $pressureLevel
            ActionRequired = $actionRequired
        }
        
    } catch {
        Write-ResourceLog "Memory monitoring failed: $($_.Exception.Message)" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.ToString()
        }
    }
}

function Invoke-GarbageCollection {
    param(
        [switch]$Aggressive,
        [switch]$Force
    )
    
    $timeSinceLastGC = ((Get-Date) - $script:ResourceMetrics.LastGarbageCollection).TotalMinutes
    
    # Don't run GC too frequently unless forced
    if (-not $Force -and $timeSinceLastGC -lt 1) {
        return @{ Success = $true; Message = "Garbage collection performed recently" }
    }
    
    Write-ResourceLog "Starting garbage collection$(if ($Aggressive) { ' (aggressive)' })" -Level "INFO"
    
    try {
        $memoryBefore = [GC]::GetTotalMemory($false)
        
        # Force garbage collection
        [GC]::Collect()
        
        if ($Aggressive) {
            [GC]::WaitForPendingFinalizers()
            [GC]::Collect()
            [GC]::Collect()
        }
        
        $memoryAfter = [GC]::GetTotalMemory($true)
        $memoryFreed = $memoryBefore - $memoryAfter
        
        # Update metrics
        $script:ResourceMetrics.TotalGarbageCollections++
        $script:ResourceMetrics.TotalMemoryFreed += $memoryFreed
        $script:ResourceMetrics.LastGarbageCollection = Get-Date
        
        Write-ResourceLog "Garbage collection completed: freed $(ConvertTo-HumanReadableSize $memoryFreed)" -Level "INFO"
        
        return @{
            Success = $true
            MemoryBefore = $memoryBefore
            MemoryAfter = $memoryAfter
            MemoryFreed = $memoryFreed
            Aggressive = $Aggressive.IsPresent
        }
        
    } catch {
        Write-ResourceLog "Garbage collection failed: $($_.Exception.Message)" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.ToString()
        }
    }
}

#endregion

#region Log Management

function Invoke-LogRotation {
    param(
        [string]$LogPath = $null,
        [switch]$Force
    )
    
    if (-not $LogPath) {
        $LogPath = $script:ResourceConfig.LogPath
    }
    
    $timeSinceLastRotation = ((Get-Date) - $script:ResourceMetrics.LastLogRotation).TotalHours
    
    if (-not $Force -and $timeSinceLastRotation -lt 1) {
        return @{ Success = $true; Message = "Log rotation performed recently" }
    }
    
    Write-ResourceLog "Starting log rotation for path: $LogPath" -Level "INFO"
    
    try {
        $rotatedFiles = @()
        $compressedFiles = @()
        $deletedFiles = @()
        
        # Get all log files in the directory
        $logFiles = Get-ChildItem -Path $LogPath -Filter "*.log" -ErrorAction SilentlyContinue
        
        foreach ($logFile in $logFiles) {
            $fileSizeMB = [Math]::Round($logFile.Length / 1MB, 2)
            
            # Check if file needs rotation
            if ($fileSizeMB -gt $script:ResourceConfig.MaxLogFileSizeMB) {
                Write-ResourceLog "Rotating log file: $($logFile.Name) (${fileSizeMB}MB)" -Level "INFO"
                
                # Create rotated filename with timestamp
                $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
                $rotatedName = "$($logFile.BaseName)_$timestamp.log"
                $rotatedPath = Join-Path $LogPath $rotatedName
                
                # Move current log to rotated name
                Move-Item -Path $logFile.FullName -Destination $rotatedPath
                $rotatedFiles += $rotatedPath
                
                # Create new empty log file
                New-Item -Path $logFile.FullName -ItemType File -Force | Out-Null
            }
        }
        
        # Compress old rotated files if enabled
        if ($script:ResourceConfig.LogCompressionEnabled) {
            $oldRotatedFiles = Get-ChildItem -Path $LogPath -Filter "*_*.log" -ErrorAction SilentlyContinue | 
                              Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) }
            
            foreach ($file in $oldRotatedFiles) {
                try {
                    $zipPath = "$($file.FullName).zip"
                    Compress-Archive -Path $file.FullName -DestinationPath $zipPath -Force
                    Remove-Item -Path $file.FullName -Force
                    $compressedFiles += $zipPath
                    Write-ResourceLog "Compressed log file: $($file.Name)" -Level "DEBUG"
                } catch {
                    Write-ResourceLog "Failed to compress $($file.Name): $($_.Exception.Message)" -Level "WARNING"
                }
            }
        }
        
        # Delete old log files based on retention policy
        $retentionDate = (Get-Date).AddDays(-$script:ResourceConfig.LogArchiveAfterDays)
        $oldFiles = Get-ChildItem -Path $LogPath -Filter "*.zip" -ErrorAction SilentlyContinue | 
                   Where-Object { $_.LastWriteTime -lt $retentionDate }
        
        foreach ($file in $oldFiles) {
            try {
                $script:ResourceMetrics.TotalSpaceFreed += $file.Length
                Remove-Item -Path $file.FullName -Force
                $deletedFiles += $file.Name
                $script:ResourceMetrics.TotalFilesDeleted++
                Write-ResourceLog "Deleted old log archive: $($file.Name)" -Level "DEBUG"
            } catch {
                Write-ResourceLog "Failed to delete $($file.Name): $($_.Exception.Message)" -Level "WARNING"
            }
        }
        
        # Limit number of log files
        $allLogFiles = Get-ChildItem -Path $LogPath -Filter "*.log" -ErrorAction SilentlyContinue | 
                      Sort-Object LastWriteTime -Descending
        
        if ($allLogFiles.Count -gt $script:ResourceConfig.MaxLogFiles) {
            $filesToDelete = $allLogFiles | Select-Object -Skip $script:ResourceConfig.MaxLogFiles
            foreach ($file in $filesToDelete) {
                try {
                    $script:ResourceMetrics.TotalSpaceFreed += $file.Length
                    Remove-Item -Path $file.FullName -Force
                    $deletedFiles += $file.Name
                    $script:ResourceMetrics.TotalFilesDeleted++
                    Write-ResourceLog "Deleted excess log file: $($file.Name)" -Level "DEBUG"
                } catch {
                    Write-ResourceLog "Failed to delete excess log $($file.Name): $($_.Exception.Message)" -Level "WARNING"
                }
            }
        }
        
        $script:ResourceMetrics.LastLogRotation = Get-Date
        
        Write-ResourceLog "Log rotation completed: $($rotatedFiles.Count) rotated, $($compressedFiles.Count) compressed, $($deletedFiles.Count) deleted" -Level "INFO"
        
        return @{
            Success = $true
            RotatedFiles = $rotatedFiles.Count
            CompressedFiles = $compressedFiles.Count
            DeletedFiles = $deletedFiles.Count
            SpaceFreed = $script:ResourceMetrics.TotalSpaceFreed
        }
        
    } catch {
        Write-ResourceLog "Log rotation failed: $($_.Exception.Message)" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.ToString()
        }
    }
}

#endregion

#region Session and Cache Cleanup

function Invoke-SessionCleanup {
    param(
        [switch]$Force,
        [switch]$IncludeTempFiles,
        [switch]$IncludeCaches
    )
    
    $timeSinceLastCleanup = ((Get-Date) - $script:ResourceMetrics.LastCleanup).TotalHours
    
    if (-not $Force -and $timeSinceLastCleanup -lt $script:ResourceConfig.CleanupIntervalHours) {
        return @{ Success = $true; Message = "Session cleanup performed recently" }
    }
    
    Write-ResourceLog "Starting session cleanup" -Level "INFO"
    
    try {
        $cleanupResults = @{
            SessionDataCleaned = 0
            TempFilesCleaned = 0
            CachesCleaned = 0
            SpaceFreed = 0
            ErrorCount = 0
        }
        
        # Clean up old session data
        if ($script:ResourceConfig.SessionCleanupEnabled) {
            $sessionDataPath = Join-Path $script:ResourceConfig.DataPath "Sessions"
            if (Test-Path $sessionDataPath) {
                $retentionDate = (Get-Date).AddDays(-$script:ResourceConfig.SessionDataRetentionDays)
                $oldSessionFiles = Get-ChildItem -Path $sessionDataPath -Filter "*.json" -ErrorAction SilentlyContinue | 
                                  Where-Object { $_.LastWriteTime -lt $retentionDate }
                
                foreach ($file in $oldSessionFiles) {
                    try {
                        $cleanupResults.SpaceFreed += $file.Length
                        Remove-Item -Path $file.FullName -Force
                        $cleanupResults.SessionDataCleaned++
                        $script:ResourceMetrics.TotalFilesDeleted++
                    } catch {
                        $cleanupResults.ErrorCount++
                        Write-ResourceLog "Failed to delete session file $($file.Name): $($_.Exception.Message)" -Level "WARNING"
                    }
                }
            }
        }
        
        # Clean up temporary files
        if ($IncludeTempFiles -and $script:ResourceConfig.TempFileCleanupEnabled) {
            if (Test-Path $script:ResourceConfig.TempPath) {
                $tempFiles = Get-ChildItem -Path $script:ResourceConfig.TempPath -Recurse -ErrorAction SilentlyContinue | 
                            Where-Object { $_.LastWriteTime -lt (Get-Date).AddHours(-6) }  # 6 hours old
                
                foreach ($file in $tempFiles) {
                    try {
                        $cleanupResults.SpaceFreed += $file.Length
                        Remove-Item -Path $file.FullName -Force -Recurse
                        $cleanupResults.TempFilesCleaned++
                        $script:ResourceMetrics.TotalFilesDeleted++
                    } catch {
                        $cleanupResults.ErrorCount++
                        Write-ResourceLog "Failed to delete temp file $($file.Name): $($_.Exception.Message)" -Level "WARNING"
                    }
                }
            }
        }
        
        # Clean up caches
        if ($IncludeCaches -and $script:ResourceConfig.CacheCleanupEnabled) {
            $cachePath = Join-Path $script:ResourceConfig.DataPath "Cache"
            if (Test-Path $cachePath) {
                $cacheFiles = Get-ChildItem -Path $cachePath -Recurse -ErrorAction SilentlyContinue | 
                             Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-1) }  # 1 day old
                
                foreach ($file in $cacheFiles) {
                    try {
                        $cleanupResults.SpaceFreed += $file.Length
                        Remove-Item -Path $file.FullName -Force -Recurse
                        $cleanupResults.CachesCleaned++
                        $script:ResourceMetrics.TotalFilesDeleted++
                    } catch {
                        $cleanupResults.ErrorCount++
                        Write-ResourceLog "Failed to delete cache file $($file.Name): $($_.Exception.Message)" -Level "WARNING"
                    }
                }
            }
        }
        
        $script:ResourceMetrics.LastCleanup = Get-Date
        $script:ResourceMetrics.TotalSpaceFreed += $cleanupResults.SpaceFreed
        
        $totalCleaned = $cleanupResults.SessionDataCleaned + $cleanupResults.TempFilesCleaned + $cleanupResults.CachesCleaned
        $spaceFreedMB = [Math]::Round($cleanupResults.SpaceFreed / 1MB, 2)
        
        Write-ResourceLog "Session cleanup completed: $totalCleaned files cleaned, ${spaceFreedMB}MB freed" -Level "INFO"
        
        return @{
            Success = $true
            Results = $cleanupResults
            TotalFilesCleaned = $totalCleaned
            SpaceFreedMB = $spaceFreedMB
        }
        
    } catch {
        Write-ResourceLog "Session cleanup failed: $($_.Exception.Message)" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.ToString()
        }
    }
}

function Invoke-EmergencyCleanup {
    param(
        [string]$Reason = "Emergency cleanup requested"
    )
    
    Write-ResourceLog "Starting emergency cleanup: $Reason" -Level "WARNING"
    
    try {
        $results = @{}
        
        # Aggressive garbage collection
        Write-ResourceLog "Performing aggressive garbage collection" -Level "INFO"
        $gcResult = Invoke-GarbageCollection -Aggressive -Force
        $results.GarbageCollection = $gcResult
        
        # Force session cleanup
        Write-ResourceLog "Performing comprehensive session cleanup" -Level "INFO"
        $sessionResult = Invoke-SessionCleanup -Force -IncludeTempFiles -IncludeCaches
        $results.SessionCleanup = $sessionResult
        
        # Force log rotation
        Write-ResourceLog "Performing log rotation" -Level "INFO"
        $logResult = Invoke-LogRotation -Force
        $results.LogRotation = $logResult
        
        # Clear performance caches if available
        try {
            if (Get-Command Clear-PerformanceCache -ErrorAction SilentlyContinue) {
                Clear-PerformanceCache -CacheType "All"
                Write-ResourceLog "Cleared performance caches" -Level "INFO"
            }
        } catch {
            Write-ResourceLog "Failed to clear performance caches: $($_.Exception.Message)" -Level "WARNING"
        }
        
        Write-ResourceLog "Emergency cleanup completed" -Level "INFO"
        
        return @{
            Success = $true
            Results = $results
            Reason = $Reason
        }
        
    } catch {
        Write-ResourceLog "Emergency cleanup failed: $($_.Exception.Message)" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.ToString()
            Reason = $Reason
        }
    }
}

#endregion

#region Resource Alerting

function Invoke-ResourceAlert {
    param(
        [string]$Type,
        [double]$Value,
        [double]$Threshold,
        [hashtable]$AdditionalData = @{}
    )
    
    if (-not $script:ResourceConfig.AlertingEnabled) {
        return
    }
    
    $alert = @{
        AlertId = [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
        Type = $Type
        Timestamp = Get-ResourceTimestamp
        Value = $Value
        Threshold = $Threshold
        Severity = if ($Value -gt ($Threshold * 1.5)) { "Critical" } elseif ($Value -gt ($Threshold * 1.2)) { "High" } else { "Medium" }
        AdditionalData = $AdditionalData
    }
    
    # Add to alert history
    $script:ResourceMetrics.AlertHistory += $alert
    
    # Keep only recent alerts (last 100)
    if ($script:ResourceMetrics.AlertHistory.Count -gt 100) {
        $script:ResourceMetrics.AlertHistory = $script:ResourceMetrics.AlertHistory | Select-Object -Last 100
    }
    
    $message = "Resource alert [$Type]: $Value exceeds threshold of $Threshold (Severity: $($alert.Severity))"
    Write-ResourceLog $message -Level $(if ($alert.Severity -eq "Critical") { "ERROR" } else { "WARNING" })
    
    # Save alert to file for external monitoring
    try {
        $alertFile = Join-Path $script:ResourceConfig.LogPath "resource_alerts.json"
        $alerts = @()
        
        if (Test-Path $alertFile) {
            $alertsJson = Get-Content -Path $alertFile -Raw
            $alerts = $alertsJson | ConvertFrom-Json
        }
        
        $alerts += $alert
        
        # Keep only recent alerts in file (last 50)
        if ($alerts.Count -gt 50) {
            $alerts = $alerts | Select-Object -Last 50
        }
        
        $alerts | ConvertTo-Json -Depth 10 | Set-Content -Path $alertFile -Encoding UTF8
        
    } catch {
        Write-ResourceLog "Failed to save alert to file: $($_.Exception.Message)" -Level "WARNING"
    }
}

#endregion

#region Comprehensive Resource Monitoring

function Invoke-ComprehensiveResourceCheck {
    param([switch]$IncludeRecommendations)
    
    Write-ResourceLog "Starting comprehensive resource check" -Level "INFO"
    
    try {
        $resourceReport = @{
            Timestamp = Get-ResourceTimestamp
            Memory = @{}
            Disk = @{}
            Performance = @{}
            Alerts = @{}
            Recommendations = @()
        }
        
        # Memory analysis
        $memoryResult = Get-MemoryUsage -Detailed
        if ($memoryResult.Success) {
            $resourceReport.Memory = $memoryResult.MemoryInfo
            
            # Check against thresholds
            $workingSetMB = $memoryResult.MemoryInfo.WorkingSetMB
            if ($workingSetMB -gt $script:ResourceConfig.AlertThresholds.MemoryUsageMB) {
                $resourceReport.Alerts.MemoryAlert = @{
                    Type = "HighMemoryUsage"
                    Value = $workingSetMB
                    Threshold = $script:ResourceConfig.AlertThresholds.MemoryUsageMB
                }
                
                if ($IncludeRecommendations) {
                    $resourceReport.Recommendations += "Consider running garbage collection or session cleanup"
                }
            }
        }
        
        # Disk usage analysis
        try {
            $dataPathInfo = Get-Item $script:ResourceConfig.DataPath -ErrorAction SilentlyContinue
            if ($dataPathInfo) {
                $drive = Get-PSDrive -Name $dataPathInfo.PSDrive.Name
                $diskUsagePercent = [Math]::Round((($drive.Used / ($drive.Used + $drive.Free)) * 100), 2)
                
                $resourceReport.Disk = @{
                    Drive = $drive.Name
                    UsedGB = [Math]::Round($drive.Used / 1GB, 2)
                    FreeGB = [Math]::Round($drive.Free / 1GB, 2)
                    UsagePercent = $diskUsagePercent
                }
                
                if ($diskUsagePercent -gt $script:ResourceConfig.AlertThresholds.DiskUsagePercentage) {
                    $resourceReport.Alerts.DiskAlert = @{
                        Type = "HighDiskUsage"
                        Value = $diskUsagePercent
                        Threshold = $script:ResourceConfig.AlertThresholds.DiskUsagePercentage
                    }
                    
                    if ($IncludeRecommendations) {
                        $resourceReport.Recommendations += "Consider running log rotation and file cleanup"
                    }
                }
            }
        } catch {
            Write-ResourceLog "Failed to get disk usage: $($_.Exception.Message)" -Level "WARNING"
        }
        
        # Performance metrics
        $resourceReport.Performance = @{
            TotalGarbageCollections = $script:ResourceMetrics.TotalGarbageCollections
            TotalMemoryFreedMB = [Math]::Round($script:ResourceMetrics.TotalMemoryFreed / 1MB, 2)
            TotalFilesDeleted = $script:ResourceMetrics.TotalFilesDeleted
            TotalSpaceFreedMB = [Math]::Round($script:ResourceMetrics.TotalSpaceFreed / 1MB, 2)
        }
        
        # Recent alerts
        $recentAlerts = $script:ResourceMetrics.AlertHistory | Where-Object { 
            (Get-Date $_.Timestamp) -gt (Get-Date).AddHours(-1) 
        }
        $resourceReport.Alerts.RecentAlertCount = $recentAlerts.Count
        
        # Add general recommendations
        if ($IncludeRecommendations) {
            $timeSinceLastCleanup = ((Get-Date) - $script:ResourceMetrics.LastCleanup).TotalHours
            if ($timeSinceLastCleanup -gt $script:ResourceConfig.CleanupIntervalHours) {
                $resourceReport.Recommendations += "Scheduled cleanup is overdue"
            }
            
            if ($script:ResourceMetrics.TotalGarbageCollections -eq 0) {
                $resourceReport.Recommendations += "No garbage collections performed yet - consider manual GC if memory usage is high"
            }
        }
        
        Write-ResourceLog "Comprehensive resource check completed" -Level "INFO"
        
        return @{
            Success = $true
            Report = $resourceReport
        }
        
    } catch {
        Write-ResourceLog "Comprehensive resource check failed: $($_.Exception.Message)" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.ToString()
        }
    }
}

function Start-AutomaticResourceOptimization {
    param([switch]$RunOnce)
    
    Write-ResourceLog "Starting automatic resource optimization" -Level "INFO"
    
    try {
        $results = @{
            MemoryMonitoring = $null
            LogRotation = $null
            SessionCleanup = $null
            EmergencyCleanup = $null
        }
        
        # Memory monitoring and GC
        $memoryResult = Invoke-MemoryMonitoring
        $results.MemoryMonitoring = $memoryResult
        
        # Log rotation
        if ($script:ResourceConfig.LogRotationEnabled) {
            $logResult = Invoke-LogRotation
            $results.LogRotation = $logResult
        }
        
        # Session cleanup
        if ($script:ResourceConfig.SessionCleanupEnabled) {
            $cleanupResult = Invoke-SessionCleanup
            $results.SessionCleanup = $cleanupResult
        }
        
        # Check if emergency cleanup is needed
        $memoryUsage = (Get-MemoryUsage).MemoryInfo.WorkingSetMB
        if ($memoryUsage -gt $script:ResourceConfig.CriticalMemoryThresholdMB) {
            Write-ResourceLog "Critical memory usage detected, triggering emergency cleanup" -Level "WARNING"
            $emergencyResult = Invoke-EmergencyCleanup -Reason "Critical memory usage: ${memoryUsage}MB"
            $results.EmergencyCleanup = $emergencyResult
        }
        
        Write-ResourceLog "Automatic resource optimization completed" -Level "INFO"
        
        return @{
            Success = $true
            Results = $results
            RunOnce = $RunOnce.IsPresent
        }
        
    } catch {
        Write-ResourceLog "Automatic resource optimization failed: $($_.Exception.Message)" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.ToString()
        }
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    # Memory management
    'Get-MemoryUsage',
    'Invoke-MemoryMonitoring',
    'Invoke-GarbageCollection',
    
    # Log management
    'Invoke-LogRotation',
    
    # Session and cache cleanup
    'Invoke-SessionCleanup',
    'Invoke-EmergencyCleanup',
    
    # Resource alerting
    'Invoke-ResourceAlert',
    
    # Comprehensive monitoring
    'Invoke-ComprehensiveResourceCheck',
    'Start-AutomaticResourceOptimization',
    
    # Utilities
    'Write-ResourceLog',
    'ConvertTo-HumanReadableSize'
)

#endregion

Write-Host "[ResourceOptimizer] Resource usage optimization module loaded successfully" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUfnSHPNqXQJE7pTmOGxcH6BQz
# U3OgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUXYUza62WI9K5zwZH/b5xBOPL9K0wDQYJKoZIhvcNAQEBBQAEggEAFoQ7
# xotizJa6arXKQt/o/HhsWxLfystvF6ZQ7ZQ7k1DtsLXRFjpijsZon9idzyZ7oXYT
# dd/2e6uxgmz+qkprs38yXpo6dsoZ7BKchrzuM56hQ+QtcYbbCXMqLksHu3Hh/G/C
# naqryfEwXPeOp4LPgS31IIYXdtdgMEvukb0iR9Wie9hxsEl+m4IfgJxzbM0ePEGq
# bzTPzX8iUCmfb3G/+0+A26Myd2H2jF7w/EB2hUniRPHY4a7u1EicCPtXtyGz41NL
# FuUKkj4xNv7GIGatWjxQGp/4alr7YjfH+KShFXe+pMiHe9MnHUdCN3oPp60uvLJ6
# 2Fbshnmf7PI1wjF/UQ==
# SIG # End signature block
