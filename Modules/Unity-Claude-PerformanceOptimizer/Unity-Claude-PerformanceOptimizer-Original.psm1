# Unity-Claude-PerformanceOptimizer.psm1
# Phase 3 Day 1-2: Performance Optimization Integration Module
# Combines caching, incremental processing, and parallel execution for 100+ files/second processing

<#
.SYNOPSIS
    Unity-Claude-PerformanceOptimizer Module - MONOLITHIC VERSION
    
.DESCRIPTION
    This is the original monolithic version of the PerformanceOptimizer module.
    
    ** REFACTORED VERSION AVAILABLE **
    A refactored modular version is available that splits this 891-line module into:
    - 6 focused component modules (~150-270 lines each)
    - Main orchestrator module (Unity-Claude-PerformanceOptimizer-Refactored.psm1)
    - Improved maintainability and testability
    
    To use the refactored version, update the manifest (.psd1) RootModule to:
    'Unity-Claude-PerformanceOptimizer-Refactored.psm1'
    
    Components in refactored version:
    - Core\OptimizerConfiguration.psm1 - Configuration and initialization
    - Core\FileSystemMonitoring.psm1 - File system watcher functionality  
    - Core\PerformanceMonitoring.psm1 - Performance metrics and analysis
    - Core\PerformanceOptimization.psm1 - Dynamic optimization strategies
    - Core\FileProcessing.psm1 - File processing engine and type handlers
    - Core\ReportingExport.psm1 - Performance reporting and export utilities
    
.NOTES
    Refactored: 2025-08-26
    Original Version: 891 lines
    Refactored Total: ~1433 lines (includes orchestrator and better documentation)
#>

using namespace System.Collections.Concurrent
using namespace System.Threading
using namespace System.IO

# Import required modules
Import-Module Unity-Claude-Cache -Force
Import-Module Unity-Claude-IncrementalProcessor -Force  
Import-Module Unity-Claude-ParallelProcessor -Force
Import-Module Unity-Claude-CPG -Force

# Performance Optimizer Class - Central coordinator for optimized processing
class PerformanceOptimizer {
    [object]$CacheManager
    [object]$IncrementalProcessor
    [object]$ParallelProcessor
    [FileSystemWatcher]$FileWatcher
    [System.Collections.Concurrent.ConcurrentQueue[PSCustomObject]]$ProcessingQueue
    [System.Collections.Concurrent.ConcurrentQueue[PSCustomObject]]$CompletedQueue
    [hashtable]$PerformanceMetrics
    [hashtable]$Configuration
    [bool]$IsRunning
    [System.Threading.CancellationTokenSource]$CancellationTokenSource
    [System.Threading.Timer]$PerformanceTimer
    [System.Threading.Timer]$CleanupTimer
    [datetime]$StartTime
    [int]$FilesProcessed
    [int]$FilesPerSecondTarget
    [string]$BasePath
    
    PerformanceOptimizer([hashtable]$config) {
        Write-Verbose "[PerformanceOptimizer] Initializing with configuration"
        
        $this.Configuration = $config
        $this.FilesPerSecondTarget = $config.TargetThroughput
        $this.BasePath = $config.BasePath
        $this.IsRunning = $false
        $this.FilesProcessed = 0
        $this.StartTime = [datetime]::Now
        $this.ProcessingQueue = [System.Collections.Concurrent.ConcurrentQueue[PSCustomObject]]::new()
        $this.CompletedQueue = [System.Collections.Concurrent.ConcurrentQueue[PSCustomObject]]::new()
        
        # Initialize performance metrics
        $this.PerformanceMetrics = [hashtable]::Synchronized(@{
            TotalFilesProcessed = 0
            FilesPerSecond = 0.0
            AverageProcessingTime = 0.0
            CacheHitRate = 0.0
            QueueLength = 0
            ActiveThreads = 0
            MemoryUsage = 0
            LastUpdate = [datetime]::Now
            ProcessingErrors = 0
            ThroughputHistory = [System.Collections.Generic.List[double]]::new()
            BottleneckAnalysis = @{}
        })
        
        $this.InitializeComponents()
    }
    
    hidden [void]InitializeComponents() {
        Write-Verbose "[PerformanceOptimizer] Initializing performance components"
        
        try {
            # Initialize cache manager with optimized settings
            $cacheConfig = @{
                MaxSize = $this.Configuration.CacheSize
                EnablePersistence = $true
                PersistencePath = Join-Path $this.BasePath ".cache"
            }
            $this.CacheManager = New-CacheManager @cacheConfig
            
            # Initialize incremental processor
            $incrementalConfig = @{
                BasePath = $this.BasePath
                ChangeDetectionInterval = $this.Configuration.IncrementalCheckInterval
            }
            $this.IncrementalProcessor = New-IncrementalProcessor @incrementalConfig
            
            # Initialize parallel processor with optimal thread count
            $optimalThreads = $this.CalculateOptimalThreadCount()
            $parallelConfig = @{
                MaxThreads = $optimalThreads
                BatchSize = $this.Configuration.BatchSize
            }
            $this.ParallelProcessor = New-ParallelProcessor @parallelConfig
            
            Write-Verbose "[PerformanceOptimizer] Components initialized successfully"
        }
        catch {
            Write-Error "[PerformanceOptimizer] Failed to initialize components: $_"
            throw
        }
    }
    
    [int]CalculateOptimalThreadCount() {
        $cpuCores = [Environment]::ProcessorCount
        $optimalThreads = [Math]::Min($cpuCores * 4, 32)  # 4x CPU cores, max 32
        
        # Adjust based on available memory
        $availableMemoryGB = (Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB
        if ($availableMemoryGB -lt 8) {
            $optimalThreads = [Math]::Max($optimalThreads / 2, 4)
        }
        
        Write-Verbose "[PerformanceOptimizer] Calculated optimal thread count: $optimalThreads"
        return $optimalThreads
    }
    
    [void]Start() {
        Write-Verbose "[PerformanceOptimizer] Starting optimized processing"
        
        if ($this.IsRunning) {
            Write-Warning "[PerformanceOptimizer] Already running"
            return
        }
        
        try {
            $this.IsRunning = $true
            $this.StartTime = [datetime]::Now
            $this.CancellationTokenSource = [System.Threading.CancellationTokenSource]::new()
            
            # Start file system watcher for incremental updates
            $this.StartFileWatcher()
            
            # Start performance monitoring timer
            $this.StartPerformanceMonitoring()
            
            # Start processing worker threads
            $this.StartProcessingWorkers()
            
            Write-Information "[PerformanceOptimizer] Optimized processing started successfully"
        }
        catch {
            Write-Error "[PerformanceOptimizer] Failed to start: $_"
            $this.Stop()
            throw
        }
    }
    
    [void]Stop() {
        Write-Verbose "[PerformanceOptimizer] Stopping optimized processing"
        
        if (-not $this.IsRunning) {
            Write-Warning "[PerformanceOptimizer] Not currently running"
            return
        }
        
        try {
            $this.IsRunning = $false
            
            # Cancel all operations
            if ($this.CancellationTokenSource) {
                $this.CancellationTokenSource.Cancel()
            }
            
            # Stop file watcher
            if ($this.FileWatcher) {
                $this.FileWatcher.Dispose()
                $this.FileWatcher = $null
            }
            
            # Stop timers
            if ($this.PerformanceTimer) {
                $this.PerformanceTimer.Dispose()
                $this.PerformanceTimer = $null
            }
            
            if ($this.CleanupTimer) {
                $this.CleanupTimer.Dispose()
                $this.CleanupTimer = $null
            }
            
            # Save cache to disk
            if ($this.CacheManager) {
                $this.CacheManager.SaveToDisk()
            }
            
            Write-Information "[PerformanceOptimizer] Optimized processing stopped successfully"
        }
        catch {
            Write-Error "[PerformanceOptimizer] Error during shutdown: $_"
        }
    }
    
    hidden [void]StartFileWatcher() {
        Write-Verbose "[PerformanceOptimizer] Starting file system watcher"
        
        $this.FileWatcher = [FileSystemWatcher]::new($this.BasePath)
        $this.FileWatcher.IncludeSubdirectories = $true
        $this.FileWatcher.Filter = "*"
        $this.FileWatcher.NotifyFilter = [NotifyFilters]::FileName -bor [NotifyFilters]::LastWrite
        
        # Register event handlers
        Register-ObjectEvent -InputObject $this.FileWatcher -EventName Changed -Action {
            $optimizer = $Event.MessageData
            $optimizer.HandleFileChange($Event.SourceEventArgs)
        } -MessageData $this | Out-Null
        
        $this.FileWatcher.EnableRaisingEvents = $true
        Write-Verbose "[PerformanceOptimizer] File system watcher started"
    }
    
    hidden [void]HandleFileChange([System.IO.FileSystemEventArgs]$args) {
        if (-not $this.IsRunning) { return }
        
        $changeInfo = [PSCustomObject]@{
            FilePath = $args.FullPath
            ChangeType = $args.ChangeType
            Timestamp = [datetime]::Now
            Priority = $this.CalculateFilePriority($args.FullPath)
        }
        
        $this.ProcessingQueue.Enqueue($changeInfo)
        Write-Debug "[PerformanceOptimizer] Queued file change: $($args.FullPath)"
    }
    
    [int]CalculateFilePriority([string]$filePath) {
        # Higher priority for critical files
        if ($filePath -match '\.(ps1|psm1|psd1)$') { return 10 }
        if ($filePath -match '\.(cs|py|js|ts)$') { return 8 }
        if ($filePath -match '\.(md|txt)$') { return 3 }
        return 5  # default priority
    }
    
    hidden [void]StartPerformanceMonitoring() {
        $interval = $this.Configuration.PerformanceReportingInterval * 1000  # Convert to milliseconds
        
        $this.PerformanceTimer = [System.Threading.Timer]::new({
            param($state)
            $optimizer = $state
            $optimizer.UpdatePerformanceMetrics()
        }, $this, $interval, $interval)
        
        Write-Verbose "[PerformanceOptimizer] Performance monitoring started"
    }
    
    hidden [void]UpdatePerformanceMetrics() {
        if (-not $this.IsRunning) { return }
        
        $now = [datetime]::Now
        $elapsedMinutes = ($now - $this.StartTime).TotalMinutes
        
        # Calculate files per second
        $filesPerSecond = if ($elapsedMinutes -gt 0) { 
            $this.FilesProcessed / ($elapsedMinutes * 60) 
        } else { 0 }
        
        # Update metrics
        $this.PerformanceMetrics.TotalFilesProcessed = $this.FilesProcessed
        $this.PerformanceMetrics.FilesPerSecond = [Math]::Round($filesPerSecond, 2)
        $this.PerformanceMetrics.QueueLength = $this.ProcessingQueue.Count
        $this.PerformanceMetrics.LastUpdate = $now
        
        # Add to throughput history
        $this.PerformanceMetrics.ThroughputHistory.Add($filesPerSecond)
        if ($this.PerformanceMetrics.ThroughputHistory.Count -gt 100) {
            $this.PerformanceMetrics.ThroughputHistory.RemoveAt(0)
        }
        
        # Update cache hit rate
        if ($this.CacheManager) {
            $cacheStats = $this.CacheManager.GetStatistics()
            $this.PerformanceMetrics.CacheHitRate = if ($cacheStats.TotalGets -gt 0) {
                [Math]::Round(($cacheStats.Hits / $cacheStats.TotalGets) * 100, 2)
            } else { 0 }
        }
        
        # Check if we're meeting performance targets
        if ($filesPerSecond -lt ($this.FilesPerSecondTarget * 0.8)) {
            $this.AnalyzeBottlenecks()
            $this.OptimizePerformance()
        }
        
        Write-Debug "[PerformanceOptimizer] Performance metrics updated: $filesPerSecond files/sec"
    }
    
    hidden [void]AnalyzeBottlenecks() {
        $bottlenecks = @{}
        
        # Analyze queue length
        if ($this.ProcessingQueue.Count -gt 100) {
            $bottlenecks.QueueBacklog = "Processing queue has $($this.ProcessingQueue.Count) items"
        }
        
        # Analyze cache performance
        if ($this.PerformanceMetrics.CacheHitRate -lt 70) {
            $bottlenecks.CacheEfficiency = "Cache hit rate is $($this.PerformanceMetrics.CacheHitRate)% (target >70%)"
        }
        
        # Analyze memory usage
        $memoryUsage = [GC]::GetTotalMemory($false) / 1MB
        if ($memoryUsage -gt 1000) {
            $bottlenecks.MemoryPressure = "Memory usage is $([Math]::Round($memoryUsage, 2)) MB"
        }
        
        $this.PerformanceMetrics.BottleneckAnalysis = $bottlenecks
        
        if ($bottlenecks.Count -gt 0) {
            Write-Warning "[PerformanceOptimizer] Bottlenecks detected: $($bottlenecks.Keys -join ', ')"
        }
    }
    
    hidden [void]OptimizePerformance() {
        Write-Verbose "[PerformanceOptimizer] Optimizing performance based on current metrics"
        
        $bottlenecks = $this.PerformanceMetrics.BottleneckAnalysis
        
        # Optimize based on identified bottlenecks
        if ($bottlenecks.ContainsKey('QueueBacklog')) {
            $this.IncreaseBatchSize()
        }
        
        if ($bottlenecks.ContainsKey('CacheEfficiency')) {
            $this.OptimizeCacheSettings()
        }
        
        if ($bottlenecks.ContainsKey('MemoryPressure')) {
            $this.ReduceMemoryUsage()
        }
    }
    
    hidden [void]IncreaseBatchSize() {
        $currentBatchSize = $this.Configuration.BatchSize
        $newBatchSize = [Math]::Min($currentBatchSize * 1.5, 200)
        
        if ($newBatchSize -ne $currentBatchSize) {
            $this.Configuration.BatchSize = $newBatchSize
            Write-Information "[PerformanceOptimizer] Increased batch size to $newBatchSize"
        }
    }
    
    hidden [void]OptimizeCacheSettings() {
        if ($this.CacheManager) {
            # Increase cache size if hit rate is low
            $currentSize = $this.Configuration.CacheSize
            $newSize = [Math]::Min($currentSize * 1.2, 10000)
            
            if ($newSize -ne $currentSize) {
                $this.Configuration.CacheSize = $newSize
                Write-Information "[PerformanceOptimizer] Increased cache size to $newSize"
            }
        }
    }
    
    hidden [void]ReduceMemoryUsage() {
        # Force garbage collection
        [GC]::Collect()
        [GC]::WaitForPendingFinalizers()
        
        # Clean up completed items
        $itemsToRemove = [Math]::Min($this.CompletedQueue.Count / 2, 100)
        for ($i = 0; $i -lt $itemsToRemove; $i++) {
            $null = $this.CompletedQueue.TryDequeue([ref]$null)
        }
        
        Write-Information "[PerformanceOptimizer] Performed memory cleanup"
    }
    
    hidden [void]StartProcessingWorkers() {
        Write-Verbose "[PerformanceOptimizer] Starting processing worker threads"
        
        # Start multiple worker threads for processing queue
        $workerCount = $this.ParallelProcessor.GetOptimalThreadCount()
        
        for ($i = 0; $i -lt $workerCount; $i++) {
            $worker = [System.Threading.Thread]::new({
                param($optimizer)
                $optimizer.ProcessingWorker()
            })
            $worker.IsBackground = $true
            $worker.Start($this)
        }
        
        Write-Verbose "[PerformanceOptimizer] Started $workerCount processing workers"
    }
    
    hidden [void]ProcessingWorker() {
        Write-Debug "[PerformanceOptimizer] Processing worker started"
        
        while ($this.IsRunning -and -not $this.CancellationTokenSource.Token.IsCancellationRequested) {
            try {
                $changeInfo = $null
                if ($this.ProcessingQueue.TryDequeue([ref]$changeInfo)) {
                    $this.ProcessFileChange($changeInfo)
                } else {
                    # No work available, sleep briefly
                    [System.Threading.Thread]::Sleep(10)
                }
            }
            catch {
                Write-Error "[PerformanceOptimizer] Processing worker error: $_"
                $this.PerformanceMetrics.ProcessingErrors++
            }
        }
        
        Write-Debug "[PerformanceOptimizer] Processing worker stopped"
    }
    
    hidden [void]ProcessFileChange([PSCustomObject]$changeInfo) {
        $this.StartTime = [datetime]::Now
        
        try {
            Write-Debug "[PerformanceOptimizer] Processing file: $($changeInfo.FilePath)"
            
            # Check cache first
            $cacheKey = "cpg:$($changeInfo.FilePath)"
            $cachedData = $this.CacheManager.Get($cacheKey)
            
            if ($cachedData) {
                Write-Debug "[PerformanceOptimizer] Cache hit for $($changeInfo.FilePath)"
                $result = $cachedData
            } else {
                # Process file and cache result
                $result = $this.ProcessFileInternal($changeInfo.FilePath)
                if ($result) {
                    $this.CacheManager.Set($cacheKey, $result, 3600, $changeInfo.Priority)  # Cache for 1 hour
                    Write-Debug "[PerformanceOptimizer] Cached result for $($changeInfo.FilePath)"
                }
            }
            
            # Update dependent files if needed
            $this.UpdateDependentFiles($changeInfo.FilePath, $result)
            
            # Record completion
            $completionInfo = [PSCustomObject]@{
                FilePath = $changeInfo.FilePath
                ProcessingTime = ([datetime]::Now - $this.StartTime).TotalMilliseconds
                Success = $true
                Timestamp = [datetime]::Now
                Result = $result
            }
            
            $this.CompletedQueue.Enqueue($completionInfo)
            $this.FilesProcessed++
            
            Write-Debug "[PerformanceOptimizer] Completed processing: $($changeInfo.FilePath)"
        }
        catch {
            Write-Error "[PerformanceOptimizer] Error processing $($changeInfo.FilePath): $_"
            $this.PerformanceMetrics.ProcessingErrors++
            
            # Record failure
            $completionInfo = [PSCustomObject]@{
                FilePath = $changeInfo.FilePath
                ProcessingTime = ([datetime]::Now - $this.StartTime).TotalMilliseconds
                Success = $false
                Error = $_.Exception.Message
                Timestamp = [datetime]::Now
            }
            
            $this.CompletedQueue.Enqueue($completionInfo)
        }
    }
    
    hidden [PSCustomObject]ProcessFileInternal([string]$filePath) {
        Write-Debug "[PerformanceOptimizer] Processing file internally: $filePath"
        
        # Determine file type and process accordingly
        $extension = [System.IO.Path]::GetExtension($filePath).ToLower()
        
        switch ($extension) {
            { $_ -in @('.ps1', '.psm1', '.psd1') } {
                return $this.ProcessPowerShellFile($filePath)
            }
            { $_ -in @('.cs', '.cpp', '.h') } {
                return $this.ProcessCSharpFile($filePath)
            }
            { $_ -in @('.py', '.pyx') } {
                return $this.ProcessPythonFile($filePath)
            }
            { $_ -in @('.js', '.ts', '.jsx', '.tsx') } {
                return $this.ProcessJavaScriptFile($filePath)
            }
            default {
                return $this.ProcessGenericFile($filePath)
            }
        }
        
        # This should never be reached but ensures all code paths return a value
        return $null
    }
    
    hidden [PSCustomObject]ProcessPowerShellFile([string]$filePath) {
        try {
            # Use CPG module for PowerShell processing
            $cpgData = ConvertTo-CPGFromFile -FilePath $filePath -Verbose:$false
            
            return [PSCustomObject]@{
                Type = 'PowerShell'
                FilePath = $filePath
                CPG = $cpgData
                LastModified = (Get-Item $filePath).LastWriteTime
                ProcessedAt = [datetime]::Now
            }
        }
        catch {
            Write-Warning "[PerformanceOptimizer] Failed to process PowerShell file $filePath : $_"
            return $null
        }
    }
    
    hidden [PSCustomObject]ProcessCSharpFile([string]$filePath) {
        # Placeholder for C# processing - would use tree-sitter or similar
        return [PSCustomObject]@{
            Type = 'CSharp'
            FilePath = $filePath
            LastModified = (Get-Item $filePath).LastWriteTime
            ProcessedAt = [datetime]::Now
        }
    }
    
    hidden [PSCustomObject]ProcessPythonFile([string]$filePath) {
        # Placeholder for Python processing - would use tree-sitter or similar
        return [PSCustomObject]@{
            Type = 'Python'
            FilePath = $filePath
            LastModified = (Get-Item $filePath).LastWriteTime
            ProcessedAt = [datetime]::Now
        }
    }
    
    hidden [PSCustomObject]ProcessJavaScriptFile([string]$filePath) {
        # Placeholder for JavaScript processing - would use tree-sitter or similar
        return [PSCustomObject]@{
            Type = 'JavaScript'
            FilePath = $filePath
            LastModified = (Get-Item $filePath).LastWriteTime
            ProcessedAt = [datetime]::Now
        }
    }
    
    hidden [PSCustomObject]ProcessGenericFile([string]$filePath) {
        return [PSCustomObject]@{
            Type = 'Generic'
            FilePath = $filePath
            LastModified = (Get-Item $filePath).LastWriteTime
            ProcessedAt = [datetime]::Now
        }
    }
    
    hidden [void]UpdateDependentFiles([string]$filePath, [PSCustomObject]$result) {
        # Update files that depend on the changed file
        if ($result -and $this.IncrementalProcessor) {
            try {
                $dependentFiles = $this.IncrementalProcessor.GetDependentFiles($filePath)
                foreach ($dependentFile in $dependentFiles) {
                    # Queue dependent file for processing with lower priority
                    $dependentChange = [PSCustomObject]@{
                        FilePath = $dependentFile
                        ChangeType = 'Dependent'
                        Timestamp = [datetime]::Now
                        Priority = 3  # Lower priority for dependent changes
                    }
                    $this.ProcessingQueue.Enqueue($dependentChange)
                }
                Write-Debug "[PerformanceOptimizer] Queued $($dependentFiles.Count) dependent files for $filePath"
            }
            catch {
                Write-Warning "[PerformanceOptimizer] Failed to update dependent files for $filePath : $_"
            }
        }
    }
    
    [hashtable]GetPerformanceMetrics() {
        return $this.PerformanceMetrics.Clone()
    }
    
    [PSCustomObject]GetThroughputReport() {
        $metrics = $this.GetPerformanceMetrics()
        $history = $metrics.ThroughputHistory
        
        return [PSCustomObject]@{
            CurrentThroughput = $metrics.FilesPerSecond
            TargetThroughput = $this.FilesPerSecondTarget
            PerformanceRatio = if ($this.FilesPerSecondTarget -gt 0) { 
                [Math]::Round(($metrics.FilesPerSecond / $this.FilesPerSecondTarget) * 100, 2) 
            } else { 0 }
            AverageThroughput = if ($history.Count -gt 0) { 
                [Math]::Round(($history | Measure-Object -Average).Average, 2) 
            } else { 0 }
            PeakThroughput = if ($history.Count -gt 0) { 
                [Math]::Round(($history | Measure-Object -Maximum).Maximum, 2) 
            } else { 0 }
            TotalFilesProcessed = $metrics.TotalFilesProcessed
            CacheHitRate = $metrics.CacheHitRate
            ProcessingErrors = $metrics.ProcessingErrors
            QueueLength = $metrics.QueueLength
            Bottlenecks = $metrics.BottleneckAnalysis
            UpTime = [datetime]::Now - $this.StartTime
        }
    }
}

# Module Functions

function New-PerformanceOptimizer {
    <#
    .SYNOPSIS
        Creates a new performance optimizer instance for high-throughput processing
    
    .PARAMETER BasePath
        Base directory path for file monitoring and processing
    
    .PARAMETER TargetThroughput
        Target processing throughput in files per second (default: 100)
    
    .PARAMETER CacheSize
        Maximum cache size for CPG data (default: 5000)
    
    .PARAMETER BatchSize
        Batch size for parallel processing (default: 50)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$BasePath,
        
        [int]$TargetThroughput = 100,
        [int]$CacheSize = 5000,
        [int]$BatchSize = 50,
        [int]$IncrementalCheckInterval = 500,
        [int]$PerformanceReportingInterval = 30
    )
    
    Write-Verbose "Creating new PerformanceOptimizer for path: $BasePath"
    
    $config = @{
        BasePath = $BasePath
        TargetThroughput = $TargetThroughput
        CacheSize = $CacheSize
        BatchSize = $BatchSize
        IncrementalCheckInterval = $IncrementalCheckInterval
        PerformanceReportingInterval = $PerformanceReportingInterval
    }
    
    return [PerformanceOptimizer]::new($config)
}

function Start-OptimizedProcessing {
    <#
    .SYNOPSIS
        Starts optimized processing with the performance optimizer
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceOptimizer]$Optimizer
    )
    
    Write-Information "Starting optimized processing with target $($Optimizer.FilesPerSecondTarget) files/second"
    $Optimizer.Start()
}

function Stop-OptimizedProcessing {
    <#
    .SYNOPSIS
        Stops optimized processing
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceOptimizer]$Optimizer
    )
    
    Write-Information "Stopping optimized processing"
    $Optimizer.Stop()
}

function Get-PerformanceMetrics {
    <#
    .SYNOPSIS
        Gets current performance metrics from the optimizer
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceOptimizer]$Optimizer
    )
    
    return $Optimizer.GetPerformanceMetrics()
}

function Get-ThroughputMetrics {
    <#
    .SYNOPSIS
        Gets detailed throughput analysis and performance report
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceOptimizer]$Optimizer
    )
    
    return $Optimizer.GetThroughputReport()
}

function Start-BatchProcessor {
    <#
    .SYNOPSIS
        Starts batch processing of files for high-throughput scenarios
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceOptimizer]$Optimizer,
        
        [Parameter(Mandatory)]
        [string[]]$FilePaths,
        
        [int]$BatchSize = 50,
        [switch]$ShowProgress
    )
    
    Write-Information "Starting batch processing of $($FilePaths.Count) files"
    
    $batches = [Math]::Ceiling($FilePaths.Count / $BatchSize)
    $processed = 0
    
    for ($i = 0; $i -lt $batches; $i++) {
        $start = $i * $BatchSize
        $end = [Math]::Min(($start + $BatchSize - 1), ($FilePaths.Count - 1))
        $batch = $FilePaths[$start..$end]
        
        # Queue batch for processing
        foreach ($filePath in $batch) {
            $changeInfo = [PSCustomObject]@{
                FilePath = $filePath
                ChangeType = 'Batch'
                Timestamp = [datetime]::Now
                Priority = 7  # Higher priority for batch processing
            }
            $Optimizer.ProcessingQueue.Enqueue($changeInfo)
        }
        
        $processed += $batch.Count
        
        if ($ShowProgress) {
            $percentComplete = [Math]::Round(($processed / $FilePaths.Count) * 100, 1)
            Write-Progress -Activity "Batch Processing" -Status "Processed $processed of $($FilePaths.Count) files" -PercentComplete $percentComplete
        }
        
        # Brief pause between batches to prevent overwhelming
        Start-Sleep -Milliseconds 100
    }
    
    if ($ShowProgress) {
        Write-Progress -Activity "Batch Processing" -Completed
    }
    
    Write-Information "Queued $($FilePaths.Count) files for batch processing"
}

function Export-PerformanceReport {
    <#
    .SYNOPSIS
        Exports detailed performance report to file
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceOptimizer]$Optimizer,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [ValidateSet('JSON', 'CSV', 'HTML')]
        [string]$Format = 'JSON'
    )
    
    $report = $Optimizer.GetThroughputReport()
    $metrics = $Optimizer.GetPerformanceMetrics()
    
    $fullReport = [PSCustomObject]@{
        GeneratedAt = [datetime]::Now
        ThroughputAnalysis = $report
        DetailedMetrics = $metrics
        Configuration = $Optimizer.Configuration
        Summary = @{
            MeetingTarget = $report.PerformanceRatio -ge 100
            Recommendation = if ($report.PerformanceRatio -lt 100) { 
                "Consider increasing cache size, batch size, or thread count" 
            } else { 
                "Performance targets are being met" 
            }
        }
    }
    
    switch ($Format) {
        'JSON' {
            $fullReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        }
        'CSV' {
            # Flatten for CSV export
            $csvData = [PSCustomObject]@{
                Timestamp = $fullReport.GeneratedAt
                CurrentThroughput = $report.CurrentThroughput
                TargetThroughput = $report.TargetThroughput
                PerformanceRatio = $report.PerformanceRatio
                TotalFilesProcessed = $report.TotalFilesProcessed
                CacheHitRate = $report.CacheHitRate
                ProcessingErrors = $report.ProcessingErrors
                MeetingTarget = $fullReport.Summary.MeetingTarget
            }
            $csvData | Export-Csv -Path $OutputPath -NoTypeInformation
        }
        'HTML' {
            # Basic HTML report
            $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Performance Optimization Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .metric { margin: 10px 0; }
        .success { color: green; }
        .warning { color: orange; }
        .error { color: red; }
    </style>
</head>
<body>
    <h1>Performance Optimization Report</h1>
    <p><strong>Generated:</strong> $($fullReport.GeneratedAt)</p>
    
    <h2>Throughput Analysis</h2>
    <div class="metric"><strong>Current Throughput:</strong> $($report.CurrentThroughput) files/sec</div>
    <div class="metric"><strong>Target Throughput:</strong> $($report.TargetThroughput) files/sec</div>
    <div class="metric"><strong>Performance Ratio:</strong> <span class="$(if($report.PerformanceRatio -ge 100){'success'}else{'warning'})">${($report.PerformanceRatio)}%</span></div>
    <div class="metric"><strong>Cache Hit Rate:</strong> $($report.CacheHitRate)%</div>
    
    <h2>Summary</h2>
    <p><strong>Meeting Target:</strong> $(if($fullReport.Summary.MeetingTarget){'Yes'}else{'No'})</p>
    <p><strong>Recommendation:</strong> $($fullReport.Summary.Recommendation)</p>
</body>
</html>
"@
            $html | Out-File -FilePath $OutputPath -Encoding UTF8
        }
    }
    
    Write-Information "Performance report exported to: $OutputPath"
}

# Export module members
Export-ModuleMember -Function @(
    'New-PerformanceOptimizer',
    'Start-OptimizedProcessing', 
    'Stop-OptimizedProcessing',
    'Get-PerformanceMetrics',
    'Get-ThroughputMetrics',
    'Start-BatchProcessor',
    'Export-PerformanceReport'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBwa7v66YBKccJP
# +AVUIDXOIadzHib1A0CZNitXjMo8iKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIF//f2fv97lb9vno9AAYfINy
# l9HYX8wuRBy2zQIrLiBbMA0GCSqGSIb3DQEBAQUABIIBAJm87Lh8sKI8JvAjDfVb
# ztpxH3rO7Yj2F9Z1qwJc3OZ9Ba2CcfJuB7kUSf7IUbPDEWBCQu586LQAlBRmdunR
# aU49CCfK+lXXio1kg3oc7S7IW7tfT28YoekQ//AOFw+NwTV5Xaafp16vQtreeF7/
# gjMNsBjEcOvArbZi9dAZEsd/y1Jd5wugd66ZKlFAG6BBrYbMDvcKtlmwPNqBtkBO
# 6iSls4yXBQ/SAFWXt0Td1B1jaIV297EoqYpBWee9I5scKMcggczrVAtfYXJ0YcAB
# CIkqpwynnI3d0ZZAQpbsyokxL2uXua2bPGxJxuZOt1w9fxTXL5MOkLbjUWHdxuDm
# Tow=
# SIG # End signature block
