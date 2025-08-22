# Unity-Claude-ConcurrentProcessor.psm1
# Concurrent processing module for Day 14 afternoon session
# Provides ThreadJob-based parallel processing, resource throttling, and coordination
# Date: 2025-08-18 | Day 14: Complete Feedback Loop Integration

#region Module Configuration and Dependencies

$ErrorActionPreference = "Stop"

Write-Host "[ConcurrentProcessor] Loading concurrent processing module..." -ForegroundColor Cyan

# Check for ThreadJob module availability
if (-not (Get-Module -ListAvailable -Name "ThreadJob")) {
    Write-Host "[ConcurrentProcessor] ThreadJob module not found. Installing..." -ForegroundColor Yellow
    try {
        Install-Module -Name ThreadJob -Scope CurrentUser -Force -AllowClobber
        Write-Host "[ConcurrentProcessor] ThreadJob module installed successfully" -ForegroundColor Green
    } catch {
        Write-Host "[ConcurrentProcessor] Failed to install ThreadJob: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "[ConcurrentProcessor] Falling back to standard jobs" -ForegroundColor Yellow
    }
}

# Import ThreadJob if available
try {
    Import-Module ThreadJob -Force
    $script:UseThreadJob = $true
    Write-Host "[ConcurrentProcessor] ThreadJob module loaded" -ForegroundColor Green
} catch {
    $script:UseThreadJob = $false
    Write-Host "[ConcurrentProcessor] Using standard PowerShell jobs" -ForegroundColor Yellow
}

# Concurrent processing configuration
$script:ConcurrentConfig = @{
    # Threading settings
    MaxConcurrentJobs = 5
    MaxConcurrentFileOperations = 3
    MaxConcurrentNetworkOperations = 2
    MaxConcurrentProcessingJobs = 4
    
    # Job management
    JobTimeoutSeconds = 300  # 5 minutes
    JobPollingIntervalMs = 500
    JobCleanupIntervalMinutes = 5
    MaxCompletedJobsRetained = 20
    
    # Throttling settings
    ThrottleCpuThreshold = 80  # Percentage
    ThrottleMemoryThresholdMB = 300
    ThrottleEnabled = $true
    ThrottleCheckIntervalSeconds = 30
    
    # Resource coordination
    UseMutexes = $true
    FileOperationMutex = "UnityClaudeFileOps"
    DatabaseOperationMutex = "UnityClaudeDbOps"
    LoggingMutex = "UnityClaudeLogging"
    
    # Data sharing
    SharedDataPath = Join-Path $PSScriptRoot "..\SessionData\Shared"
    CoordinationDataPath = Join-Path $PSScriptRoot "..\SessionData\Coordination"
    
    # Monitoring
    EnableJobMonitoring = $true
    MonitoringIntervalSeconds = 60
    LogFile = "concurrent_processor.log"
    VerboseLogging = $true
}

# Ensure directories exist
foreach ($path in @($script:ConcurrentConfig.SharedDataPath, $script:ConcurrentConfig.CoordinationDataPath)) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# Initialize job tracking
$script:JobRegistry = @{
    ActiveJobs = @{}
    CompletedJobs = @{}
    FailedJobs = @{}
    JobCounter = 0
    LastCleanup = Get-Date
}

# Initialize resource monitors
$script:ResourceMonitors = @{
    CpuUsage = 0
    MemoryUsage = 0
    ActiveJobCount = 0
    ThrottleActive = $false
    LastResourceCheck = Get-Date
}

# Initialize mutexes
$script:Mutexes = @{}

#endregion

#region Logging and Utilities

function Write-ConcurrentLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO",
        [string]$JobId = "SYSTEM"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [Job:$JobId] $Message"
    
    # Console output with colors
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "DEBUG" { "Gray" }
    }
    
    if ($Level -ne "DEBUG" -or $script:ConcurrentConfig.VerboseLogging) {
        Write-Host $logEntry -ForegroundColor $color
    }
    
    # File logging (thread-safe)
    $logFile = Join-Path (Split-Path $script:ConcurrentConfig.SharedDataPath -Parent) $script:ConcurrentConfig.LogFile
    try {
        $logMutex = Get-ProcessMutex -MutexName $script:ConcurrentConfig.LoggingMutex
        $acquired = $logMutex.WaitOne(1000)
        if ($acquired) {
            try {
                Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
            } finally {
                $logMutex.ReleaseMutex()
            }
        }
    } catch {
        Write-Warning "Failed to write to concurrent log: $($_.Exception.Message)"
    }
}

function New-JobId {
    return [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
}

function Get-ConcurrentTimestamp {
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
}

#endregion

#region Mutex and Resource Coordination

function Get-ProcessMutex {
    param([string]$MutexName)
    
    if (-not $script:ConcurrentConfig.UseMutexes) {
        return $null
    }
    
    if (-not $script:Mutexes.ContainsKey($MutexName)) {
        try {
            $mutex = [System.Threading.Mutex]::new($false, $MutexName)
            $script:Mutexes[$MutexName] = $mutex
        } catch {
            Write-ConcurrentLog "Failed to create mutex ${MutexName}: $($_.Exception.Message)" -Level "WARNING"
            return $null
        }
    }
    
    return $script:Mutexes[$MutexName]
}

function Invoke-WithMutex {
    param(
        [string]$MutexName,
        [scriptblock]$ScriptBlock,
        [int]$TimeoutMs = 5000
    )
    
    $mutex = Get-ProcessMutex -MutexName $MutexName
    if ($null -eq $mutex) {
        # No mutex available, execute directly
        return & $ScriptBlock
    }
    
    $acquired = $false
    try {
        $acquired = $mutex.WaitOne($TimeoutMs)
        if ($acquired) {
            return & $ScriptBlock
        } else {
            throw "Failed to acquire mutex $MutexName within ${TimeoutMs}ms"
        }
    } finally {
        if ($acquired) {
            $mutex.ReleaseMutex()
        }
    }
}

function Update-SharedData {
    param(
        [string]$DataKey,
        [object]$Data,
        [string]$MutexName = $null
    )
    
    $operation = {
        $sharedFile = Join-Path $script:ConcurrentConfig.SharedDataPath "$DataKey.json"
        $Data | ConvertTo-Json -Depth 10 | Set-Content -Path $sharedFile -Encoding UTF8
    }
    
    if ($MutexName) {
        Invoke-WithMutex -MutexName $MutexName -ScriptBlock $operation
    } else {
        & $operation
    }
}

function Get-SharedData {
    param(
        [string]$DataKey,
        [string]$MutexName = $null
    )
    
    $operation = {
        $sharedFile = Join-Path $script:ConcurrentConfig.SharedDataPath "$DataKey.json"
        if (Test-Path $sharedFile) {
            $content = Get-Content -Path $sharedFile -Raw
            return $content | ConvertFrom-Json
        }
        return $null
    }
    
    if ($MutexName) {
        return Invoke-WithMutex -MutexName $MutexName -ScriptBlock $operation
    } else {
        return & $operation
    }
}

#endregion

#region Resource Monitoring and Throttling

function Update-ResourceMonitoring {
    try {
        # Get CPU usage
        $cpuUsage = Get-CimInstance -ClassName Win32_Processor | Measure-Object -Property LoadPercentage -Average | Select-Object -ExpandProperty Average
        
        # Get memory usage
        $process = Get-Process -Id $PID
        $memoryUsage = [Math]::Round($process.WorkingSet64 / 1MB, 2)
        
        # Update monitors
        $script:ResourceMonitors.CpuUsage = $cpuUsage
        $script:ResourceMonitors.MemoryUsage = $memoryUsage
        $script:ResourceMonitors.ActiveJobCount = $script:JobRegistry.ActiveJobs.Count
        $script:ResourceMonitors.LastResourceCheck = Get-Date
        
        # Check throttling conditions
        $shouldThrottle = $false
        
        if ($script:ConcurrentConfig.ThrottleEnabled) {
            if ($cpuUsage -gt $script:ConcurrentConfig.ThrottleCpuThreshold) {
                $shouldThrottle = $true
                Write-ConcurrentLog "CPU throttling triggered: ${cpuUsage}%" -Level "WARNING"
            }
            
            if ($memoryUsage -gt $script:ConcurrentConfig.ThrottleMemoryThresholdMB) {
                $shouldThrottle = $true
                Write-ConcurrentLog "Memory throttling triggered: ${memoryUsage}MB" -Level "WARNING"
            }
        }
        
        $script:ResourceMonitors.ThrottleActive = $shouldThrottle
        
    } catch {
        Write-ConcurrentLog "Failed to update resource monitoring: $($_.Exception.Message)" -Level "WARNING"
    }
}

function Test-ResourceAvailability {
    param(
        [string]$OperationType = "General"
    )
    
    # Update resource monitoring if stale
    $timeSinceLastCheck = ((Get-Date) - $script:ResourceMonitors.LastResourceCheck).TotalSeconds
    if ($timeSinceLastCheck -gt $script:ConcurrentConfig.ThrottleCheckIntervalSeconds) {
        Update-ResourceMonitoring
    }
    
    # Check if throttling is active
    if ($script:ResourceMonitors.ThrottleActive) {
        return @{
            Available = $false
            Reason = "Resource throttling active (CPU: $($script:ResourceMonitors.CpuUsage)%, Memory: $($script:ResourceMonitors.MemoryUsage)MB)"
        }
    }
    
    # Check operation-specific limits
    $activeJobs = $script:JobRegistry.ActiveJobs.Values | Where-Object { $_.OperationType -eq $OperationType }
    $activeCount = ($activeJobs | Measure-Object).Count
    
    $maxJobs = switch ($OperationType) {
        "FileOperation" { $script:ConcurrentConfig.MaxConcurrentFileOperations }
        "NetworkOperation" { $script:ConcurrentConfig.MaxConcurrentNetworkOperations }
        "Processing" { $script:ConcurrentConfig.MaxConcurrentProcessingJobs }
        default { $script:ConcurrentConfig.MaxConcurrentJobs }
    }
    
    if ($activeCount -ge $maxJobs) {
        return @{
            Available = $false
            Reason = "Maximum concurrent $OperationType jobs reached ($activeCount/$maxJobs)"
        }
    }
    
    return @{
        Available = $true
        Reason = "Resources available"
    }
}

#endregion

#region Concurrent Job Management

function Start-ConcurrentJob {
    param(
        [string]$JobName,
        [scriptblock]$ScriptBlock,
        [hashtable]$ArgumentList = @{},
        [string]$OperationType = "General",
        [int]$TimeoutSeconds = $null,
        [hashtable]$JobMetadata = @{}
    )
    
    # Check resource availability
    $resourceCheck = Test-ResourceAvailability -OperationType $OperationType
    if (-not $resourceCheck.Available) {
        Write-ConcurrentLog "Cannot start job ${JobName}: $($resourceCheck.Reason)" -Level "WARNING"
        return @{
            Success = $false
            Error = $resourceCheck.Reason
        }
    }
    
    $jobId = New-JobId
    $script:JobRegistry.JobCounter++
    
    if (-not $TimeoutSeconds) {
        $TimeoutSeconds = $script:ConcurrentConfig.JobTimeoutSeconds
    }
    
    try {
        # Prepare job parameters
        $jobParams = @{
            Name = "$JobName-$jobId"
            ScriptBlock = $ScriptBlock
        }
        
        # Add argument list if provided
        if ($ArgumentList.Count -gt 0) {
            $jobParams.ArgumentList = $ArgumentList.Values
        }
        
        # Start the job
        if ($script:UseThreadJob) {
            $job = Start-ThreadJob @jobParams
        } else {
            $job = Start-Job @jobParams
        }
        
        # Create job tracking entry
        $jobEntry = @{
            JobId = $jobId
            JobName = $JobName
            OperationType = $OperationType
            PowerShellJob = $job
            StartTime = Get-ConcurrentTimestamp
            TimeoutSeconds = $TimeoutSeconds
            Metadata = $JobMetadata
            Arguments = $ArgumentList
        }
        
        $script:JobRegistry.ActiveJobs[$jobId] = $jobEntry
        
        Write-ConcurrentLog "Started concurrent job: $JobName (Type: $OperationType, Timeout: ${TimeoutSeconds}s)" -Level "INFO" -JobId $jobId
        
        return @{
            Success = $true
            JobId = $jobId
            Job = $job
        }
        
    } catch {
        Write-ConcurrentLog "Failed to start job ${JobName}: $($_.Exception.Message)" -Level "ERROR" -JobId $jobId
        return @{
            Success = $false
            Error = $_.ToString()
        }
    }
}

function Wait-ConcurrentJob {
    param(
        [string]$JobId,
        [int]$TimeoutSeconds = $null
    )
    
    if (-not $script:JobRegistry.ActiveJobs.ContainsKey($JobId)) {
        return @{
            Success = $false
            Error = "Job not found: $JobId"
        }
    }
    
    $jobEntry = $script:JobRegistry.ActiveJobs[$JobId]
    $job = $jobEntry.PowerShellJob
    
    if (-not $TimeoutSeconds) {
        $TimeoutSeconds = $jobEntry.TimeoutSeconds
    }
    
    try {
        Write-ConcurrentLog "Waiting for job completion: $($jobEntry.JobName)" -Level "DEBUG" -JobId $JobId
        
        # Wait for job completion
        $completed = Wait-Job -Job $job -Timeout $TimeoutSeconds
        
        if ($completed) {
            $result = Receive-Job -Job $job
            $jobState = $job.State
            
            # Move job to completed registry
            $jobEntry.EndTime = Get-ConcurrentTimestamp
            $jobEntry.Result = $result
            $jobEntry.State = $jobState
            $jobEntry.Duration = ((Get-Date $jobEntry.EndTime) - (Get-Date $jobEntry.StartTime)).TotalMilliseconds
            
            if ($jobState -eq "Completed") {
                $script:JobRegistry.CompletedJobs[$JobId] = $jobEntry
                Write-ConcurrentLog "Job completed successfully: $($jobEntry.JobName) ($([Math]::Round($jobEntry.Duration, 2))ms)" -Level "INFO" -JobId $JobId
            } else {
                $script:JobRegistry.FailedJobs[$JobId] = $jobEntry
                Write-ConcurrentLog "Job failed: $($jobEntry.JobName) (State: $jobState)" -Level "ERROR" -JobId $JobId
            }
            
            # Remove from active jobs
            $script:JobRegistry.ActiveJobs.Remove($JobId)
            
            # Clean up job
            Remove-Job -Job $job -Force
            
            return @{
                Success = ($jobState -eq "Completed")
                Result = $result
                State = $jobState
                Duration = $jobEntry.Duration
            }
        } else {
            # Job timed out
            Write-ConcurrentLog "Job timed out: $($jobEntry.JobName) (${TimeoutSeconds}s)" -Level "ERROR" -JobId $JobId
            
            # Stop the job
            Stop-Job -Job $job
            Remove-Job -Job $job -Force
            
            # Move to failed jobs
            $jobEntry.EndTime = Get-ConcurrentTimestamp
            $jobEntry.State = "Timeout"
            $jobEntry.Duration = $TimeoutSeconds * 1000
            $script:JobRegistry.FailedJobs[$JobId] = $jobEntry
            $script:JobRegistry.ActiveJobs.Remove($JobId)
            
            return @{
                Success = $false
                Error = "Job timed out after ${TimeoutSeconds} seconds"
                State = "Timeout"
            }
        }
        
    } catch {
        Write-ConcurrentLog "Error waiting for job: $($_.Exception.Message)" -Level "ERROR" -JobId $JobId
        return @{
            Success = $false
            Error = $_.ToString()
        }
    }
}

function Get-ConcurrentJobStatus {
    param(
        [string]$JobId = $null
    )
    
    if ($JobId) {
        # Get specific job status
        foreach ($registry in @($script:JobRegistry.ActiveJobs, $script:JobRegistry.CompletedJobs, $script:JobRegistry.FailedJobs)) {
            if ($registry.ContainsKey($JobId)) {
                $jobEntry = $registry[$JobId]
                return @{
                    Success = $true
                    JobEntry = $jobEntry
                    Status = if ($registry -eq $script:JobRegistry.ActiveJobs) { "Active" }
                            elseif ($registry -eq $script:JobRegistry.CompletedJobs) { "Completed" }
                            else { "Failed" }
                }
            }
        }
        
        return @{
            Success = $false
            Error = "Job not found: $JobId"
        }
    } else {
        # Get overall status
        return @{
            Success = $true
            Summary = @{
                ActiveJobs = $script:JobRegistry.ActiveJobs.Count
                CompletedJobs = $script:JobRegistry.CompletedJobs.Count
                FailedJobs = $script:JobRegistry.FailedJobs.Count
                TotalJobsStarted = $script:JobRegistry.JobCounter
            }
            ResourceStatus = @{
                CpuUsage = $script:ResourceMonitors.CpuUsage
                MemoryUsage = $script:ResourceMonitors.MemoryUsage
                ThrottleActive = $script:ResourceMonitors.ThrottleActive
            }
        }
    }
}

function Stop-ConcurrentJob {
    param(
        [string]$JobId,
        [string]$Reason = "Manual stop"
    )
    
    if (-not $script:JobRegistry.ActiveJobs.ContainsKey($JobId)) {
        return @{
            Success = $false
            Error = "Active job not found: $JobId"
        }
    }
    
    $jobEntry = $script:JobRegistry.ActiveJobs[$JobId]
    $job = $jobEntry.PowerShellJob
    
    try {
        Write-ConcurrentLog "Stopping job: $($jobEntry.JobName) ($Reason)" -Level "INFO" -JobId $JobId
        
        Stop-Job -Job $job
        Remove-Job -Job $job -Force
        
        # Move to failed jobs with stop reason
        $jobEntry.EndTime = Get-ConcurrentTimestamp
        $jobEntry.State = "Stopped"
        $jobEntry.StopReason = $Reason
        $script:JobRegistry.FailedJobs[$JobId] = $jobEntry
        $script:JobRegistry.ActiveJobs.Remove($JobId)
        
        return @{ Success = $true }
        
    } catch {
        Write-ConcurrentLog "Failed to stop job: $($_.Exception.Message)" -Level "ERROR" -JobId $JobId
        return @{
            Success = $false
            Error = $_.ToString()
        }
    }
}

#endregion

#region Parallel Processing Operations

function Invoke-ParallelFileProcessing {
    param(
        [array]$FilePaths,
        [scriptblock]$ProcessingFunction,
        [int]$MaxConcurrency = $null,
        [hashtable]$SharedContext = @{}
    )
    
    if (-not $MaxConcurrency) {
        $MaxConcurrency = $script:ConcurrentConfig.MaxConcurrentFileOperations
    }
    
    Write-ConcurrentLog "Starting parallel file processing: $($FilePaths.Count) files, max concurrency: $MaxConcurrency" -Level "INFO"
    
    $jobResults = @{}
    $completedCount = 0
    $batchSize = [Math]::Min($MaxConcurrency, $FilePaths.Count)
    
    try {
        # Store shared context
        if ($SharedContext.Count -gt 0) {
            Update-SharedData -DataKey "ParallelProcessingContext" -Data $SharedContext -MutexName $script:ConcurrentConfig.FileOperationMutex
        }
        
        # Process files in batches
        for ($i = 0; $i -lt $FilePaths.Count; $i += $batchSize) {
            $batch = $FilePaths[$i..([Math]::Min($i + $batchSize - 1, $FilePaths.Count - 1))]
            $activeBatchJobs = @{}
            
            # Start jobs for this batch
            foreach ($filePath in $batch) {
                $resourceCheck = Test-ResourceAvailability -OperationType "FileOperation"
                if (-not $resourceCheck.Available) {
                    Write-ConcurrentLog "Delaying file processing due to resource constraints" -Level "WARNING"
                    Start-Sleep -Seconds 2
                }
                
                $jobParams = @{
                    JobName = "FileProcess-$(Split-Path $filePath -Leaf)"
                    ScriptBlock = $ProcessingFunction
                    ArgumentList = @{ FilePath = $filePath; SharedContext = $SharedContext }
                    OperationType = "FileOperation"
                    JobMetadata = @{ FilePath = $filePath }
                }
                
                $jobResult = Start-ConcurrentJob @jobParams
                if ($jobResult.Success) {
                    $activeBatchJobs[$jobResult.JobId] = $filePath
                }
            }
            
            # Wait for batch completion
            foreach ($jobId in $activeBatchJobs.Keys) {
                $waitResult = Wait-ConcurrentJob -JobId $jobId
                $filePath = $activeBatchJobs[$jobId]
                
                $jobResults[$filePath] = @{
                    Success = $waitResult.Success
                    Result = $waitResult.Result
                    Duration = $waitResult.Duration
                    Error = $waitResult.Error
                }
                
                $completedCount++
                
                if ($completedCount % 5 -eq 0) {
                    Write-ConcurrentLog "Parallel processing progress: $completedCount/$($FilePaths.Count) files completed" -Level "INFO"
                }
            }
        }
        
        $successCount = ($jobResults.Values | Where-Object { $_.Success }).Count
        $failureCount = $jobResults.Count - $successCount
        
        Write-ConcurrentLog "Parallel file processing completed: $successCount successful, $failureCount failed" -Level "INFO"
        
        return @{
            Success = $true
            Results = $jobResults
            Summary = @{
                TotalFiles = $FilePaths.Count
                SuccessfulFiles = $successCount
                FailedFiles = $failureCount
                SuccessRate = [Math]::Round(($successCount / $FilePaths.Count) * 100, 2)
            }
        }
        
    } catch {
        Write-ConcurrentLog "Parallel file processing failed: $($_.Exception.Message)" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.ToString()
            Results = $jobResults
        }
    }
}

function Invoke-ParallelDataProcessing {
    param(
        [array]$DataItems,
        [scriptblock]$ProcessingFunction,
        [int]$MaxConcurrency = $null,
        [string]$OperationName = "DataProcessing"
    )
    
    if (-not $MaxConcurrency) {
        $MaxConcurrency = $script:ConcurrentConfig.MaxConcurrentProcessingJobs
    }
    
    Write-ConcurrentLog "Starting parallel data processing: $($DataItems.Count) items, max concurrency: $MaxConcurrency" -Level "INFO"
    
    $results = @{}
    $activeJobs = @{}
    $processedCount = 0
    
    try {
        # Process items with controlled concurrency
        for ($i = 0; $i -lt $DataItems.Count; $i++) {
            $dataItem = $DataItems[$i]
            
            # Wait if we've reached max concurrency
            while ($activeJobs.Count -ge $MaxConcurrency) {
                # Check for completed jobs
                $completedJobIds = @()
                foreach ($jobId in $activeJobs.Keys) {
                    $jobStatus = Get-ConcurrentJobStatus -JobId $jobId
                    if ($jobStatus.Success -and $jobStatus.Status -ne "Active") {
                        $completedJobIds += $jobId
                    }
                }
                
                # Process completed jobs
                foreach ($jobId in $completedJobIds) {
                    $waitResult = Wait-ConcurrentJob -JobId $jobId
                    $itemIndex = $activeJobs[$jobId]
                    
                    $results[$itemIndex] = @{
                        Success = $waitResult.Success
                        Result = $waitResult.Result
                        Duration = $waitResult.Duration
                        Error = $waitResult.Error
                    }
                    
                    $activeJobs.Remove($jobId)
                    $processedCount++
                }
                
                if ($activeJobs.Count -ge $MaxConcurrency) {
                    Start-Sleep -Milliseconds $script:ConcurrentConfig.JobPollingIntervalMs
                }
            }
            
            # Start new job
            $jobParams = @{
                JobName = "$OperationName-Item$i"
                ScriptBlock = $ProcessingFunction
                ArgumentList = @{ DataItem = $dataItem; ItemIndex = $i }
                OperationType = "Processing"
                JobMetadata = @{ ItemIndex = $i }
            }
            
            $jobResult = Start-ConcurrentJob @jobParams
            if ($jobResult.Success) {
                $activeJobs[$jobResult.JobId] = $i
            }
        }
        
        # Wait for remaining jobs
        while ($activeJobs.Count -gt 0) {
            $completedJobIds = @()
            foreach ($jobId in $activeJobs.Keys) {
                $waitResult = Wait-ConcurrentJob -JobId $jobId -TimeoutSeconds 1
                if ($waitResult.Success -or $waitResult.Error) {
                    $itemIndex = $activeJobs[$jobId]
                    
                    $results[$itemIndex] = @{
                        Success = $waitResult.Success
                        Result = $waitResult.Result
                        Duration = $waitResult.Duration
                        Error = $waitResult.Error
                    }
                    
                    $completedJobIds += $jobId
                    $processedCount++
                }
            }
            
            foreach ($jobId in $completedJobIds) {
                $activeJobs.Remove($jobId)
            }
            
            if ($activeJobs.Count -gt 0) {
                Start-Sleep -Milliseconds $script:ConcurrentConfig.JobPollingIntervalMs
            }
        }
        
        $successCount = ($results.Values | Where-Object { $_.Success }).Count
        $failureCount = $results.Count - $successCount
        
        Write-ConcurrentLog "Parallel data processing completed: $successCount successful, $failureCount failed" -Level "INFO"
        
        return @{
            Success = $true
            Results = $results
            Summary = @{
                TotalItems = $DataItems.Count
                SuccessfulItems = $successCount
                FailedItems = $failureCount
                SuccessRate = [Math]::Round(($successCount / $DataItems.Count) * 100, 2)
            }
        }
        
    } catch {
        Write-ConcurrentLog "Parallel data processing failed: $($_.Exception.Message)" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.ToString()
            Results = $results
        }
    }
}

#endregion

#region Job Cleanup and Monitoring

function Invoke-JobCleanup {
    param(
        [switch]$ForceCleanup
    )
    
    $timeSinceLastCleanup = ((Get-Date) - $script:JobRegistry.LastCleanup).TotalMinutes
    
    if (-not $ForceCleanup -and $timeSinceLastCleanup -lt $script:ConcurrentConfig.JobCleanupIntervalMinutes) {
        return @{ Success = $true; Message = "Cleanup not needed yet" }
    }
    
    Write-ConcurrentLog "Starting job cleanup" -Level "INFO"
    
    $cleanedCount = 0
    
    try {
        # Clean up old completed jobs
        if ($script:JobRegistry.CompletedJobs.Count -gt $script:ConcurrentConfig.MaxCompletedJobsRetained) {
            $jobsToRemove = $script:JobRegistry.CompletedJobs.Count - $script:ConcurrentConfig.MaxCompletedJobsRetained
            $oldestJobs = $script:JobRegistry.CompletedJobs.GetEnumerator() | 
                         Sort-Object { $_.Value.StartTime } | 
                         Select-Object -First $jobsToRemove
            
            foreach ($job in $oldestJobs) {
                $script:JobRegistry.CompletedJobs.Remove($job.Key)
                $cleanedCount++
            }
        }
        
        # Clean up old failed jobs (keep more for analysis)
        $maxFailedJobs = $script:ConcurrentConfig.MaxCompletedJobsRetained * 2
        if ($script:JobRegistry.FailedJobs.Count -gt $maxFailedJobs) {
            $jobsToRemove = $script:JobRegistry.FailedJobs.Count - $maxFailedJobs
            $oldestJobs = $script:JobRegistry.FailedJobs.GetEnumerator() | 
                         Sort-Object { $_.Value.StartTime } | 
                         Select-Object -First $jobsToRemove
            
            foreach ($job in $oldestJobs) {
                $script:JobRegistry.FailedJobs.Remove($job.Key)
                $cleanedCount++
            }
        }
        
        # Check for stale active jobs
        $staleJobs = @()
        foreach ($jobEntry in $script:JobRegistry.ActiveJobs.Values) {
            $jobAge = ((Get-Date) - (Get-Date $jobEntry.StartTime)).TotalSeconds
            if ($jobAge -gt ($jobEntry.TimeoutSeconds * 2)) {  # Double timeout threshold
                $staleJobs += $jobEntry.JobId
            }
        }
        
        foreach ($jobId in $staleJobs) {
            Write-ConcurrentLog "Cleaning up stale job: $jobId" -Level "WARNING"
            Stop-ConcurrentJob -JobId $jobId -Reason "Stale job cleanup"
            $cleanedCount++
        }
        
        $script:JobRegistry.LastCleanup = Get-Date
        
        Write-ConcurrentLog "Job cleanup completed: $cleanedCount jobs cleaned" -Level "INFO"
        
        return @{
            Success = $true
            CleanedJobs = $cleanedCount
            ActiveJobs = $script:JobRegistry.ActiveJobs.Count
            CompletedJobs = $script:JobRegistry.CompletedJobs.Count
            FailedJobs = $script:JobRegistry.FailedJobs.Count
        }
        
    } catch {
        Write-ConcurrentLog "Job cleanup failed: $($_.Exception.Message)" -Level "ERROR"
        return @{
            Success = $false
            Error = $_.ToString()
        }
    }
}

function Get-ConcurrentProcessingReport {
    param(
        [switch]$IncludeJobDetails,
        [switch]$IncludeResourceMetrics
    )
    
    # Update resource monitoring
    Update-ResourceMonitoring
    
    $report = @{
        Timestamp = Get-ConcurrentTimestamp
        JobSummary = @{
            ActiveJobs = $script:JobRegistry.ActiveJobs.Count
            CompletedJobs = $script:JobRegistry.CompletedJobs.Count
            FailedJobs = $script:JobRegistry.FailedJobs.Count
            TotalJobsStarted = $script:JobRegistry.JobCounter
        }
        Configuration = @{
            UseThreadJob = $script:UseThreadJob
            MaxConcurrentJobs = $script:ConcurrentConfig.MaxConcurrentJobs
            ThrottleEnabled = $script:ConcurrentConfig.ThrottleEnabled
        }
    }
    
    if ($IncludeResourceMetrics) {
        $report.ResourceMetrics = @{
            CpuUsage = $script:ResourceMonitors.CpuUsage
            MemoryUsage = $script:ResourceMonitors.MemoryUsage
            ThrottleActive = $script:ResourceMonitors.ThrottleActive
            LastResourceCheck = $script:ResourceMonitors.LastResourceCheck
        }
    }
    
    if ($IncludeJobDetails) {
        $report.ActiveJobDetails = $script:JobRegistry.ActiveJobs.Values | Select-Object JobId, JobName, OperationType, StartTime, TimeoutSeconds
        $report.RecentCompletedJobs = $script:JobRegistry.CompletedJobs.Values | Sort-Object EndTime -Descending | Select-Object -First 5
        $report.RecentFailedJobs = $script:JobRegistry.FailedJobs.Values | Sort-Object EndTime -Descending | Select-Object -First 5
    }
    
    return $report
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    # Job management
    'Start-ConcurrentJob',
    'Wait-ConcurrentJob',
    'Stop-ConcurrentJob',
    'Get-ConcurrentJobStatus',
    
    # Parallel processing
    'Invoke-ParallelFileProcessing',
    'Invoke-ParallelDataProcessing',
    
    # Resource coordination
    'Get-ProcessMutex',
    'Invoke-WithMutex',
    'Update-SharedData',
    'Get-SharedData',
    
    # Resource monitoring
    'Update-ResourceMonitoring',
    'Test-ResourceAvailability',
    
    # Cleanup and reporting
    'Invoke-JobCleanup',
    'Get-ConcurrentProcessingReport',
    
    # Utilities
    'Write-ConcurrentLog'
)

#endregion

Write-Host "[ConcurrentProcessor] Concurrent processing module loaded successfully" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU3rdPm8xA2v+wti3PDPiALHes
# 2+OgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUF2x7Qlz8yPyKF1yVY0pvLLazFKEwDQYJKoZIhvcNAQEBBQAEggEAhpMN
# hIO6He8I77GvgjTfPfb20q3iZGwzlSUOX7e09nCBfE4ZkVSehiD0RUtU1znhQzZM
# f8GJOTBxQ8CNHl1SInEU87Cod8yPo49QP45y+x60wciLO6M0/G5uxk2OvyC0KDOk
# OuEZsD/QaXxHHvooQvH+Hwx9al178s72efd/0X9E//80UnM2+p1eZA/OBxupGXnW
# fTk3oifo9yfM8NqjilTspj3HFpS2V36OiYJArCgWhbfGy5dV5p+O3MYvJCbBTtSo
# MLjHXW9zKfrkInGy500Kqu6XJKzxIBAlp0K0bXQl85eOtyW/vkgiGPxX2QY49Qmy
# +7URADUJ5Gtj4nPW8Q==
# SIG # End signature block
