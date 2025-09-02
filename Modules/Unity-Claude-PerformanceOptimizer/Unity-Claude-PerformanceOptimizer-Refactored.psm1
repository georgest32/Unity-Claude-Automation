# Unity-Claude-PerformanceOptimizer-Refactored.psm1
# REFACTORED VERSION - Main orchestrator module for performance optimization
# Combines modular components for high-throughput file processing (100+ files/second)

using namespace System.Collections.Concurrent
using namespace System.Threading
using namespace System.IO

# Display refactoring status
Write-Host "[Unity-Claude-PerformanceOptimizer] Loading REFACTORED modular version" -ForegroundColor Green

# Import required external modules
Import-Module Unity-Claude-Cache -Force -ErrorAction SilentlyContinue
Import-Module Unity-Claude-IncrementalProcessor -Force -ErrorAction SilentlyContinue
Import-Module Unity-Claude-ParallelProcessor -Force -ErrorAction SilentlyContinue
Import-Module Unity-Claude-CPG -Force -ErrorAction SilentlyContinue

# Import refactored components
$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Import-Module "$PSScriptRoot\Core\OptimizerConfiguration.psm1" -Force
Import-Module "$PSScriptRoot\Core\FileSystemMonitoring.psm1" -Force
Import-Module "$PSScriptRoot\Core\PerformanceMonitoring.psm1" -Force
Import-Module "$PSScriptRoot\Core\PerformanceOptimization.psm1" -Force
Import-Module "$PSScriptRoot\Core\FileProcessing.psm1" -Force
Import-Module "$PSScriptRoot\Core\ReportingExport.psm1" -Force

# Performance Optimizer Class - Central coordinator
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
        
        # Initialize performance metrics using component
        $this.PerformanceMetrics = Initialize-PerformanceMetrics
        
        # Initialize components using refactored function
        $this.InitializeComponents()
    }
    
    hidden [void]InitializeComponents() {
        $components = Initialize-OptimizerComponents -Configuration $this.Configuration -BasePath $this.BasePath
        $this.CacheManager = $components.CacheManager
        $this.IncrementalProcessor = $components.IncrementalProcessor
        $this.ParallelProcessor = $components.ParallelProcessor
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
            
            # Start file system watcher using component
            $this.StartFileWatcher()
            
            # Start performance monitoring using component
            $this.StartPerformanceMonitoring()
            
            # Start processing workers
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
            
            if ($this.CancellationTokenSource) {
                $this.CancellationTokenSource.Cancel()
            }
            
            # Stop file watcher using component
            if ($this.FileWatcher) {
                Stop-FileSystemMonitoring -Watcher $this.FileWatcher
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
            
            # Save cache
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
        $this.FileWatcher = Initialize-FileSystemWatcher -BasePath $this.BasePath -IncludeSubdirectories
        
        $handler = {
            $optimizer = $Event.MessageData
            $changeInfo = New-FileChangeInfo -FilePath $Event.SourceEventArgs.FullPath `
                -ChangeType $Event.SourceEventArgs.ChangeType `
                -Priority (Get-FilePriority -FilePath $Event.SourceEventArgs.FullPath)
            $optimizer.ProcessingQueue.Enqueue($changeInfo)
        }
        
        Register-FileChangeHandler -Watcher $this.FileWatcher -Handler $handler -MessageData $this
        Start-FileSystemMonitoring -Watcher $this.FileWatcher
    }
    
    hidden [void]StartPerformanceMonitoring() {
        $callback = {
            param($state)
            $optimizer = $state
            $optimizer.UpdatePerformanceMetrics()
        }
        
        $intervalSeconds = $this.Configuration.PerformanceReportingInterval
        $this.PerformanceTimer = New-PerformanceTimer -Callback $callback -State $this -IntervalSeconds $intervalSeconds
    }
    
    hidden [void]UpdatePerformanceMetrics() {
        if (-not $this.IsRunning) { return }
        
        # Update metrics using component
        $filesPerSecond = Update-PerformanceMetrics `
            -Metrics $this.PerformanceMetrics `
            -StartTime $this.StartTime `
            -FilesProcessed $this.FilesProcessed `
            -CacheManager $this.CacheManager `
            -ProcessingQueue $this.ProcessingQueue
        
        # Analyze bottlenecks using component
        $this.PerformanceMetrics.BottleneckAnalysis = Get-PerformanceBottlenecks -Metrics $this.PerformanceMetrics
        
        # Check if optimization needed
        if (Test-PerformanceOptimizationNeeded -CurrentThroughput $filesPerSecond -TargetThroughput $this.FilesPerSecondTarget) {
            $this.OptimizePerformance()
        }
    }
    
    hidden [void]OptimizePerformance() {
        # Use component for optimization
        $optimizations = Optimize-Performance `
            -Configuration $this.Configuration `
            -Bottlenecks $this.PerformanceMetrics.BottleneckAnalysis `
            -CacheManager $this.CacheManager
        
        foreach ($optimization in $optimizations) {
            Write-Information "[PerformanceOptimizer] Applied optimization: $optimization"
        }
    }
    
    hidden [void]StartProcessingWorkers() {
        Write-Verbose "[PerformanceOptimizer] Starting processing worker threads"
        
        $workerCount = if ($this.ParallelProcessor) {
            $this.ParallelProcessor.GetOptimalThreadCount()
        } else {
            Get-OptimalThreadCount
        }
        
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
        $processingStartTime = [datetime]::Now
        
        try {
            # Process using component
            $result = Invoke-FileProcessing -FilePath $changeInfo.FilePath -CacheManager $this.CacheManager
            
            # Update dependent files using component
            if ($result) {
                Add-DependentFilesToQueue -SourceFilePath $changeInfo.FilePath `
                    -ProcessingQueue $this.ProcessingQueue `
                    -IncrementalProcessor $this.IncrementalProcessor
            }
            
            # Record completion using component
            $completionInfo = New-ProcessingCompletionRecord `
                -FilePath $changeInfo.FilePath `
                -StartTime $processingStartTime `
                -Result $result
            
            $this.CompletedQueue.Enqueue($completionInfo)
            $this.FilesProcessed++
        }
        catch {
            Write-Error "[PerformanceOptimizer] Error processing $($changeInfo.FilePath): $_"
            $this.PerformanceMetrics.ProcessingErrors++
            
            $completionInfo = New-ProcessingCompletionRecord `
                -FilePath $changeInfo.FilePath `
                -StartTime $processingStartTime `
                -Error $_.Exception.Message
            
            $this.CompletedQueue.Enqueue($completionInfo)
        }
    }
    
    [hashtable]GetPerformanceMetrics() {
        return $this.PerformanceMetrics.Clone()
    }
    
    [PSCustomObject]GetThroughputReport() {
        return Get-ThroughputAnalysis -Metrics $this.PerformanceMetrics `
            -TargetThroughput $this.FilesPerSecondTarget `
            -StartTime $this.StartTime
    }
}

# Module Functions

function New-PerformanceOptimizer {
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
    
    # Validate configuration
    if (-not (Test-OptimizerConfiguration -Configuration $config)) {
        throw "Invalid configuration parameters"
    }
    
    return [PerformanceOptimizer]::new($config)
}

function Start-OptimizedProcessing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceOptimizer]$Optimizer
    )
    
    Write-Information "Starting optimized processing with target $($Optimizer.FilesPerSecondTarget) files/second"
    $Optimizer.Start()
}

function Stop-OptimizedProcessing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceOptimizer]$Optimizer
    )
    
    Write-Information "Stopping optimized processing"
    $Optimizer.Stop()
}

function Get-PerformanceMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceOptimizer]$Optimizer
    )
    
    return $Optimizer.GetPerformanceMetrics()
}

function Get-ThroughputMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceOptimizer]$Optimizer
    )
    
    return $Optimizer.GetThroughputReport()
}

function Start-BatchProcessor {
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
    
    # Use dynamic batch size from component
    $dynamicBatchSize = Get-DynamicBatchSize -Metrics $Optimizer.PerformanceMetrics -BaseBatchSize $BatchSize
    
    $batches = [Math]::Ceiling($FilePaths.Count / $dynamicBatchSize)
    $processed = 0
    
    for ($i = 0; $i -lt $batches; $i++) {
        $start = $i * $dynamicBatchSize
        $end = [Math]::Min(($start + $dynamicBatchSize - 1), ($FilePaths.Count - 1))
        $batch = $FilePaths[$start..$end]
        
        foreach ($filePath in $batch) {
            $changeInfo = New-FileChangeInfo -FilePath $filePath -ChangeType 'Batch' -Priority 7
            $Optimizer.ProcessingQueue.Enqueue($changeInfo)
        }
        
        $processed += $batch.Count
        
        if ($ShowProgress) {
            $percentComplete = [Math]::Round(($processed / $FilePaths.Count) * 100, 1)
            Write-Progress -Activity "Batch Processing" -Status "Processed $processed of $($FilePaths.Count) files" -PercentComplete $percentComplete
        }
        
        # Apply adaptive throttling
        $throttle = Get-AdaptiveThrottling -Metrics $Optimizer.PerformanceMetrics
        if ($throttle.ShouldThrottle) {
            Start-Sleep -Milliseconds $throttle.ThrottleDelayMs
        }
    }
    
    if ($ShowProgress) {
        Write-Progress -Activity "Batch Processing" -Completed
    }
    
    Write-Information "Queued $($FilePaths.Count) files for batch processing"
}

function Export-PerformanceReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceOptimizer]$Optimizer,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [ValidateSet('JSON', 'CSV', 'HTML', 'XML')]
        [string]$Format = 'JSON'
    )
    
    $report = $Optimizer.GetThroughputReport()
    
    # Use component for export
    Export-PerformanceData -Report $report -OutputPath $OutputPath -Format $Format -Configuration $Optimizer.Configuration
}

# Component health monitoring functions
function Get-PerformanceOptimizerComponents {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceOptimizer]$Optimizer
    )
    
    return [PSCustomObject]@{
        Configuration = 'OptimizerConfiguration.psm1'
        FileSystemMonitoring = 'FileSystemMonitoring.psm1'
        PerformanceMonitoring = 'PerformanceMonitoring.psm1'
        PerformanceOptimization = 'PerformanceOptimization.psm1'
        FileProcessing = 'FileProcessing.psm1'
        ReportingExport = 'ReportingExport.psm1'
    }
}

function Test-PerformanceOptimizerHealth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceOptimizer]$Optimizer
    )
    
    $health = @{
        IsRunning = $Optimizer.IsRunning
        QueueHealth = Get-QueueHealth -ProcessingQueue $Optimizer.ProcessingQueue
        Metrics = Get-PerformanceSummary -Metrics $Optimizer.PerformanceMetrics -TargetThroughput $Optimizer.FilesPerSecondTarget
        Components = @{
            CacheManager = ($null -ne $Optimizer.CacheManager)
            IncrementalProcessor = ($null -ne $Optimizer.IncrementalProcessor)
            ParallelProcessor = ($null -ne $Optimizer.ParallelProcessor)
            FileWatcher = ($null -ne $Optimizer.FileWatcher)
        }
    }
    
    return [PSCustomObject]$health
}

# Export module members
Export-ModuleMember -Function @(
    'New-PerformanceOptimizer',
    'Start-OptimizedProcessing', 
    'Stop-OptimizedProcessing',
    'Get-PerformanceMetrics',
    'Get-ThroughputMetrics',
    'Start-BatchProcessor',
    'Export-PerformanceReport',
    'Get-PerformanceOptimizerComponents',
    'Test-PerformanceOptimizerHealth'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAP3vlPiY4OrSE+
# sx0FezDAc2bhmMvHs+hXB5i8xbZYWKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMXj70HH7BVNulO5MekKcEeI
# Sq9xCklGP1O4HT+HuR7wMA0GCSqGSIb3DQEBAQUABIIBAEngTXh6h1crRbMfUGJc
# CGVegQZAlvruUv2UQJ83T29dLMWthDS5l4z0T3EeLn1mP7edRiM6/b0Op+LZvbQK
# 2a0Wxg4BzGlDxrRjXozZcQlslTL2WQp+jsdMQI0NPPK5xtgoqPDOXg+YxoN1GAlJ
# HSdkYIfkQyGCabtJR2JLxdITaA0S0oNvRx4Hkto/sKhBsYKToNLT4K5g3fRDO5lL
# JaLNDUUJzk9l9jE04XtrwQWq3zoTrmtkJN0nMoACcHEATCtgeo+axKb04ZZJNaEn
# H9AigOvPb6XGHJF9BsCYZTmXl0MpOwTDn676V3+bOO8TbaWk23D4oHphWTkY4Prz
# 8Jg=
# SIG # End signature block
