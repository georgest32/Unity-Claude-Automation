# Unity-Claude-ParallelProcessor.psm1
# MONOLITHIC VERSION - 907 lines - REFACTORED
# This file has been refactored into a modular component-based architecture
# 
# REFACTORED COMPONENTS:
#   Core/ParallelProcessorCore.psm1     - Core utilities and configuration
#   Core/RunspacePoolManager.psm1      - Runspace pool lifecycle management
#   Core/JobScheduler.psm1              - Job submission, execution and tracking
#   Core/StatisticsTracker.psm1         - Performance statistics and monitoring
#   Core/BatchProcessingEngine.psm1     - Batch processing with producer-consumer patterns
#   Core/ModuleFunctions.psm1           - Public API and main processor class
#   Unity-Claude-ParallelProcessor-Refactored.psm1 - Orchestrator module
#
# Use Unity-Claude-ParallelProcessor-Refactored.psm1 for new implementations
# This monolithic version is preserved for reference and legacy compatibility
#
# Original: Parallel processing framework using PowerShell runspace pools for high-performance execution
# Provides optimal thread calculation, job scheduling, result aggregation, and error handling

using namespace System.Management.Automation.Runspaces
using namespace System.Collections.Concurrent
using namespace System.Threading

# Parallel Processor Class
class ParallelProcessor {
    [RunspacePool]$RunspacePool
    [int]$MinThreads
    [int]$MaxThreads
    [ConcurrentBag[object]]$Results
    [ConcurrentDictionary[string, object]]$Jobs
    [hashtable]$Statistics
    [bool]$IsRunning
    [int]$OptimalThreadCount
    [System.Collections.Generic.List[object]]$RunningJobs
    [scriptblock]$InitializationScript
    [hashtable]$SharedData
    [System.Threading.CancellationTokenSource]$CancellationTokenSource
    [int]$RetryCount
    [int]$TimeoutSeconds
    
    ParallelProcessor() {
        $this.Initialize(1, 0, $null)
    }
    
    ParallelProcessor([int]$minThreads, [int]$maxThreads) {
        $this.Initialize($minThreads, $maxThreads, $null)
    }
    
    ParallelProcessor([int]$minThreads, [int]$maxThreads, [scriptblock]$initScript) {
        $this.Initialize($minThreads, $maxThreads, $initScript)
    }
    
    hidden [void]Initialize([int]$minThreads, [int]$maxThreads, [scriptblock]$initScript) {
        Write-Debug "[ParallelProcessor] Initializing with min threads: $minThreads, max threads: $maxThreads"
        
        # Calculate optimal thread count if not specified
        if ($maxThreads -eq 0) {
            $this.OptimalThreadCount = $this.CalculateOptimalThreads()
            $this.MaxThreads = $this.OptimalThreadCount
        } else {
            $this.OptimalThreadCount = $maxThreads
            $this.MaxThreads = $maxThreads
        }
        
        $this.MinThreads = [Math]::Max(1, $minThreads)
        $this.InitializationScript = $initScript
        $this.RetryCount = 3
        $this.TimeoutSeconds = 300  # 5 minutes default
        
        # Initialize collections
        $this.Results = [ConcurrentBag[object]]::new()
        $this.Jobs = [ConcurrentDictionary[string, object]]::new()
        $this.RunningJobs = [System.Collections.Generic.List[object]]::new()
        $this.SharedData = [hashtable]::Synchronized(@{})
        $this.CancellationTokenSource = [System.Threading.CancellationTokenSource]::new()
        
        # Initialize statistics
        $this.Statistics = [hashtable]::Synchronized(@{
            TotalJobsSubmitted = 0
            TotalJobsCompleted = 0
            TotalJobsFailed = 0
            TotalJobsRetried = 0
            AverageExecutionTime = 0
            MinExecutionTime = [int]::MaxValue
            MaxExecutionTime = 0
            TotalExecutionTime = 0
            CreatedAt = [datetime]::Now
            LastJobCompleted = [datetime]::MinValue
        })
        
        # Create runspace pool
        $this.CreateRunspacePool()
        
        Write-Debug "[ParallelProcessor] Initialization complete with $($this.MaxThreads) max threads"
    }
    
    # Calculate optimal thread count
    hidden [int]CalculateOptimalThreads() {
        $cpuCount = [Environment]::ProcessorCount
        
        # For I/O bound operations, use 2-4x CPU count
        # For CPU bound operations, use CPU count
        # Default to 2x for mixed workloads
        $optimal = $cpuCount * 2
        
        # Cap at reasonable maximum
        $optimal = [Math]::Min($optimal, 50)
        
        Write-Debug "[ParallelProcessor] Calculated optimal threads: $optimal (CPU count: $cpuCount)"
        return $optimal
    }
    
    # Create runspace pool
    hidden [void]CreateRunspacePool() {
        Write-Debug "[ParallelProcessor] Creating runspace pool"
        
        # Create initial session state
        $sessionState = [InitialSessionState]::CreateDefault()
        
        # Add initialization script if provided
        if ($this.InitializationScript) {
            $sessionState.StartupScripts.Add($this.InitializationScript)
        }
        
        # Create runspace pool with session state
        $this.RunspacePool = [RunspaceFactory]::CreateRunspacePool(
            $this.MinThreads, 
            $this.MaxThreads,
            $sessionState,
            [System.Management.Automation.Host.PSHost]$global:Host
        )
        
        # Configure the pool
        $this.RunspacePool.ApartmentState = [System.Threading.ApartmentState]::MTA
        $this.RunspacePool.ThreadOptions = [PSThreadOptions]::ReuseThread
        
        # Open the pool
        $this.RunspacePool.Open()
        $this.IsRunning = $true
        
        Write-Debug "[ParallelProcessor] Runspace pool created and opened"
    }
    
    # Submit job for execution
    [string]SubmitJob([scriptblock]$scriptBlock, [hashtable]$parameters = @{}) {
        if (-not $this.IsRunning) {
            throw "Parallel processor is not running"
        }
        
        $jobId = [Guid]::NewGuid().ToString()
        Write-Debug "[ParallelProcessor] Submitting job: $jobId"
        
        # Create PowerShell instance
        $powershell = [PowerShell]::Create()
        $powershell.RunspacePool = $this.RunspacePool
        
        # Add script block
        [void]$powershell.AddScript($scriptBlock)
        
        # Add parameters
        foreach ($param in $parameters.GetEnumerator()) {
            [void]$powershell.AddParameter($param.Key, $param.Value)
        }
        
        # Add shared data as a parameter
        [void]$powershell.AddParameter('SharedData', $this.SharedData)
        
        # Create job object
        $job = @{
            Id = $jobId
            PowerShell = $powershell
            Handle = $null
            StartTime = [datetime]::Now
            Parameters = $parameters
            Status = 'Submitted'
            Result = $null
            Error = $null
            RetryCount = 0
        }
        
        # Start async execution
        $job.Handle = $powershell.BeginInvoke()
        $job.Status = 'Running'
        
        # Store job
        $this.Jobs[$jobId] = $job
        $this.RunningJobs.Add($job)
        $this.Statistics.TotalJobsSubmitted++
        
        Write-Debug "[ParallelProcessor] Job submitted: $jobId"
        return $jobId
    }
    
    # Submit multiple jobs
    [string[]]SubmitJobs([scriptblock]$scriptBlock, [array]$parameterSets) {
        $jobIds = @()
        
        foreach ($params in $parameterSets) {
            if ($params -is [hashtable]) {
                $jobIds += $this.SubmitJob($scriptBlock, $params)
            } else {
                $jobIds += $this.SubmitJob($scriptBlock, @{ InputObject = $params })
            }
        }
        
        return $jobIds
    }
    
    # Wait for job completion
    [object]WaitForJob([string]$jobId, [int]$timeoutSeconds = 0) {
        Write-Debug "[ParallelProcessor] Waiting for job: $jobId"
        
        if (-not $this.Jobs.ContainsKey($jobId)) {
            throw "Job not found: $jobId"
        }
        
        $job = $this.Jobs[$jobId]
        $timeout = if ($timeoutSeconds -gt 0) { $timeoutSeconds } else { $this.TimeoutSeconds }
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        while ($job.Status -eq 'Running') {
            if ($job.Handle.IsCompleted) {
                $this.CollectJobResult($job)
                break
            }
            
            if ($stopwatch.Elapsed.TotalSeconds -gt $timeout) {
                Write-Warning "[ParallelProcessor] Job $jobId timed out after $timeout seconds"
                $this.CancelJob($jobId)
                throw "Job timed out: $jobId"
            }
            
            Start-Sleep -Milliseconds 100
        }
        
        return $job.Result
    }
    
    # Wait for all jobs
    [object[]]WaitForAllJobs([int]$timeoutSeconds = 0) {
        Write-Debug "[ParallelProcessor] Waiting for all jobs"
        
        $timeout = if ($timeoutSeconds -gt 0) { $timeoutSeconds } else { $this.TimeoutSeconds }
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        while ($this.RunningJobs.Count -gt 0) {
            $completedJobs = @()
            
            foreach ($job in $this.RunningJobs) {
                if ($job.Handle.IsCompleted) {
                    $this.CollectJobResult($job)
                    $completedJobs += $job
                }
            }
            
            foreach ($job in $completedJobs) {
                $this.RunningJobs.Remove($job)
            }
            
            if ($stopwatch.Elapsed.TotalSeconds -gt $timeout) {
                Write-Warning "[ParallelProcessor] Timeout waiting for all jobs after $timeout seconds"
                $this.CancelAllJobs()
                break
            }
            
            if ($this.RunningJobs.Count -gt 0) {
                Start-Sleep -Milliseconds 100
            }
        }
        
        # Return all results
        $allResults = @()
        while ($this.Results.Count -gt 0) {
            $result = $null
            if ($this.Results.TryTake([ref]$result)) {
                $allResults += $result
            }
        }
        
        return $allResults
    }
    
    # Collect job result
    hidden [void]CollectJobResult([hashtable]$job) {
        Write-Debug "[ParallelProcessor] Collecting result for job: $($job.Id)"
        
        try {
            # End invoke and get result
            $result = $job.PowerShell.EndInvoke($job.Handle)
            
            # Check for errors
            if ($job.PowerShell.HadErrors) {
                $errors = $job.PowerShell.Streams.Error
                $job.Error = $errors
                $job.Status = 'Failed'
                
                # Retry logic
                if ($job.RetryCount -lt $this.RetryCount) {
                    Write-Warning "[ParallelProcessor] Job $($job.Id) failed, retrying (attempt $($job.RetryCount + 1)/$($this.RetryCount))"
                    $this.RetryJob($job)
                    return
                } else {
                    $this.Statistics.TotalJobsFailed++
                    Write-Error "[ParallelProcessor] Job $($job.Id) failed after $($this.RetryCount) retries"
                }
            } else {
                $job.Result = $result
                $job.Status = 'Completed'
                $this.Results.Add($result)
                $this.Statistics.TotalJobsCompleted++
            }
            
            # Update statistics
            $executionTime = ([datetime]::Now - $job.StartTime).TotalMilliseconds
            $this.UpdateExecutionStatistics($executionTime)
            $this.Statistics.LastJobCompleted = [datetime]::Now
            
        } catch {
            Write-Error "[ParallelProcessor] Error collecting job result: $_"
            $job.Status = 'Failed'
            $job.Error = $_
            $this.Statistics.TotalJobsFailed++
        } finally {
            # Dispose PowerShell instance
            if ($job.PowerShell) {
                $job.PowerShell.Dispose()
            }
        }
    }
    
    # Retry failed job
    hidden [void]RetryJob([hashtable]$job) {
        $job.RetryCount++
        $this.Statistics.TotalJobsRetried++
        
        # Create new PowerShell instance
        $powershell = [PowerShell]::Create()
        $powershell.RunspacePool = $this.RunspacePool
        
        # Re-add script block and parameters
        [void]$powershell.AddScript($job.PowerShell.Commands.Commands[0].CommandText)
        
        foreach ($param in $job.Parameters.GetEnumerator()) {
            [void]$powershell.AddParameter($param.Key, $param.Value)
        }
        
        [void]$powershell.AddParameter('SharedData', $this.SharedData)
        
        # Dispose old instance
        $job.PowerShell.Dispose()
        
        # Update job
        $job.PowerShell = $powershell
        $job.Handle = $powershell.BeginInvoke()
        $job.Status = 'Running'
        $job.Error = $null
    }
    
    # Cancel job
    [void]CancelJob([string]$jobId) {
        Write-Debug "[ParallelProcessor] Cancelling job: $jobId"
        
        if ($this.Jobs.ContainsKey($jobId)) {
            $job = $this.Jobs[$jobId]
            
            if ($job.Status -eq 'Running') {
                try {
                    $job.PowerShell.Stop()
                    $job.Status = 'Cancelled'
                } catch {
                    Write-Warning "[ParallelProcessor] Error cancelling job $jobId : $_"
                }
            }
        }
    }
    
    # Cancel all jobs
    [void]CancelAllJobs() {
        Write-Debug "[ParallelProcessor] Cancelling all jobs"
        
        foreach ($job in $this.RunningJobs) {
            $this.CancelJob($job.Id)
        }
        
        $this.RunningJobs.Clear()
    }
    
    # Update execution statistics
    hidden [void]UpdateExecutionStatistics([double]$executionTime) {
        $this.Statistics.TotalExecutionTime += $executionTime
        
        $completedCount = $this.Statistics.TotalJobsCompleted
        if ($completedCount -gt 0) {
            $this.Statistics.AverageExecutionTime = $this.Statistics.TotalExecutionTime / $completedCount
        }
        
        if ($executionTime -lt $this.Statistics.MinExecutionTime) {
            $this.Statistics.MinExecutionTime = $executionTime
        }
        
        if ($executionTime -gt $this.Statistics.MaxExecutionTime) {
            $this.Statistics.MaxExecutionTime = $executionTime
        }
    }
    
    # Invoke parallel processing with ForEach pattern
    [object[]]InvokeParallel([array]$InputObjects, [scriptblock]$ScriptBlock, [int]$ThrottleLimit = 0) {
        Write-Debug "[ParallelProcessor] Invoking parallel processing for $($InputObjects.Count) objects"
        
        $originalMax = $this.MaxThreads
        if ($ThrottleLimit -gt 0) {
            $this.MaxThreads = [Math]::Min($ThrottleLimit, $this.MaxThreads)
            $this.RunspacePool.SetMaxRunspaces($this.MaxThreads)
        }
        
        try {
            # Submit all jobs
            $jobIds = @()
            foreach ($obj in $InputObjects) {
                $jobIds += $this.SubmitJob($ScriptBlock, @{ InputObject = $obj })
            }
            
            # Wait for all to complete
            $allResults = $this.WaitForAllJobs(0)
            
            return $allResults
        } finally {
            if ($ThrottleLimit -gt 0) {
                $this.MaxThreads = $originalMax
                $this.RunspacePool.SetMaxRunspaces($this.MaxThreads)
            }
        }
    }
    
    # Producer-Consumer pattern implementation
    [void]StartProducerConsumer([scriptblock]$Producer, [scriptblock]$Consumer, [int]$ConsumerCount = 0) {
        Write-Debug "[ParallelProcessor] Starting producer-consumer pattern"
        
        if ($ConsumerCount -eq 0) {
            $ConsumerCount = $this.OptimalThreadCount
        }
        
        # Create blocking collection for queue
        $queue = [System.Collections.Concurrent.BlockingCollection[object]]::new()
        
        # Start producer
        $producerJob = $this.SubmitJob($Producer, @{ Queue = $queue })
        
        # Start consumers
        $consumerJobs = @()
        for ($i = 0; $i -lt $ConsumerCount; $i++) {
            $consumerJobs += $this.SubmitJob($Consumer, @{ 
                Queue = $queue
                ConsumerId = $i 
            })
        }
        
        # Wait for completion
        $this.WaitForJob($producerJob)
        $queue.CompleteAdding()
        
        foreach ($jobId in $consumerJobs) {
            $this.WaitForJob($jobId)
        }
    }
    
    # Get statistics
    [hashtable]GetStatistics() {
        return @{
            TotalJobsSubmitted = $this.Statistics.TotalJobsSubmitted
            TotalJobsCompleted = $this.Statistics.TotalJobsCompleted
            TotalJobsFailed = $this.Statistics.TotalJobsFailed
            TotalJobsRetried = $this.Statistics.TotalJobsRetried
            SuccessRate = if ($this.Statistics.TotalJobsSubmitted -gt 0) {
                [math]::Round(($this.Statistics.TotalJobsCompleted / $this.Statistics.TotalJobsSubmitted) * 100, 2)
            } else { 0 }
            AverageExecutionTime = [math]::Round($this.Statistics.AverageExecutionTime, 2)
            MinExecutionTime = if ($this.Statistics.MinExecutionTime -eq [int]::MaxValue) { 0 } else { [math]::Round($this.Statistics.MinExecutionTime, 2) }
            MaxExecutionTime = [math]::Round($this.Statistics.MaxExecutionTime, 2)
            CurrentlyRunning = $this.RunningJobs.Count
            ThreadPoolSize = "$($this.MinThreads)-$($this.MaxThreads)"
            OptimalThreadCount = $this.OptimalThreadCount
            Uptime = ([datetime]::Now - $this.Statistics.CreatedAt)
        }
    }
    
    # Get job status
    [hashtable]GetJobStatus([string]$jobId) {
        if (-not $this.Jobs.ContainsKey($jobId)) {
            return @{ Status = 'NotFound' }
        }
        
        $job = $this.Jobs[$jobId]
        return @{
            Id = $job.Id
            Status = $job.Status
            StartTime = $job.StartTime
            RetryCount = $job.RetryCount
            HasError = $null -ne $job.Error
            Error = $job.Error
        }
    }
    
    # Dispose resources
    [void]Dispose() {
        Write-Debug "[ParallelProcessor] Disposing parallel processor"
        
        # Cancel all running jobs
        $this.CancelAllJobs()
        
        # Close runspace pool
        if ($this.RunspacePool) {
            $this.RunspacePool.Close()
            $this.RunspacePool.Dispose()
        }
        
        # Dispose cancellation token
        if ($this.CancellationTokenSource) {
            $this.CancellationTokenSource.Dispose()
        }
        
        $this.IsRunning = $false
    }
}

# Batch Processor Class - Producer-Consumer Pattern
class BatchProcessor {
    [ParallelProcessor]$ParallelProcessor
    [System.Collections.Concurrent.BlockingCollection[object]]$InputQueue
    [System.Collections.Concurrent.BlockingCollection[object]]$OutputQueue
    [int]$BatchSize
    [int]$ConsumerCount
    [bool]$IsRunning
    [hashtable]$Statistics
    [scriptblock]$ProcessingScript
    # [System.Threading.Timer]$MonitoringTimer  # Removed - causes runspace issues
    
    BatchProcessor([int]$batchSize, [int]$consumerCount, [scriptblock]$processingScript) {
        Write-Debug "[BatchProcessor] Initializing with batch size: $batchSize, consumers: $consumerCount"
        
        $this.BatchSize = $batchSize
        $this.ConsumerCount = $consumerCount
        $this.ProcessingScript = $processingScript
        $this.IsRunning = $false
        
        # Create queues
        $this.InputQueue = [System.Collections.Concurrent.BlockingCollection[object]]::new()
        $this.OutputQueue = [System.Collections.Concurrent.BlockingCollection[object]]::new()
        
        # Create parallel processor
        $this.ParallelProcessor = [ParallelProcessor]::new(1, $consumerCount)
        
        # Initialize statistics
        $this.Statistics = [hashtable]::Synchronized(@{
            TotalItemsQueued = 0
            TotalItemsProcessed = 0
            TotalBatchesProcessed = 0
            AverageItemsPerSecond = 0
            CurrentQueueSize = 0
            StartTime = [datetime]::Now
            LastProcessedTime = [datetime]::MinValue
        })
        
        # Monitoring timer removed - causes runspace issues
        # Manual statistics update should be called when needed
        
        Write-Debug "[BatchProcessor] Initialization complete"
    }
    
    # Start batch processing
    [void]Start() {
        if ($this.IsRunning) {
            return
        }
        
        Write-Debug "[BatchProcessor] Starting batch processing"
        $this.IsRunning = $true
        
        # Consumer script block
        $consumerScript = {
            param($ConsumerId, $InputQueue, $OutputQueue, $BatchSize, $ProcessingScript, $Statistics)
            
            Write-Debug "[Consumer-$ConsumerId] Started"
            $batch = @()
            
            try {
                while (-not $InputQueue.IsCompleted) {
                    $item = $null
                    $timeout = 100  # milliseconds
                    
                    if ($InputQueue.TryTake([ref]$item, $timeout)) {
                        $batch += $item
                        
                        # Process batch when full or queue is completing
                        if ($batch.Count -ge $BatchSize -or $InputQueue.IsCompleted) {
                            if ($batch.Count -gt 0) {
                                Write-Debug "[Consumer-$ConsumerId] Processing batch of $($batch.Count) items"
                                
                                # Process the batch
                                $results = & $ProcessingScript $batch
                                
                                # Add results to output queue
                                foreach ($result in $results) {
                                    $OutputQueue.Add($result)
                                }
                                
                                # Update statistics
                                $Statistics.TotalItemsProcessed += $batch.Count
                                $Statistics.TotalBatchesProcessed++
                                $Statistics.LastProcessedTime = [datetime]::Now
                                
                                # Clear batch
                                $batch = @()
                            }
                        }
                    }
                }
                
                # Process any remaining items
                if ($batch.Count -gt 0) {
                    Write-Debug "[Consumer-$ConsumerId] Processing final batch of $($batch.Count) items"
                    $results = & $ProcessingScript $batch
                    foreach ($result in $results) {
                        $OutputQueue.Add($result)
                    }
                    $Statistics.TotalItemsProcessed += $batch.Count
                    $Statistics.TotalBatchesProcessed++
                }
            } catch {
                Write-Error "[Consumer-$ConsumerId] Error: $_"
            }
            
            Write-Debug "[Consumer-$ConsumerId] Completed"
        }
        
        # Start consumer threads
        for ($i = 0; $i -lt $this.ConsumerCount; $i++) {
            $this.ParallelProcessor.SubmitJob($consumerScript, @{
                ConsumerId = $i
                InputQueue = $this.InputQueue
                OutputQueue = $this.OutputQueue
                BatchSize = $this.BatchSize
                ProcessingScript = $this.ProcessingScript
                Statistics = $this.Statistics
            })
        }
    }
    
    # Add items to process
    [void]AddItems([array]$items) {
        foreach ($item in $items) {
            $this.InputQueue.Add($item)
            $this.Statistics.TotalItemsQueued++
        }
        
        $this.Statistics.CurrentQueueSize = $this.InputQueue.Count
    }
    
    # Complete adding items
    [void]CompleteAdding() {
        Write-Debug "[BatchProcessor] Completing input queue"
        $this.InputQueue.CompleteAdding()
    }
    
    # Get results
    [object[]]GetResults([int]$timeoutSeconds = 60) {
        Write-Debug "[BatchProcessor] Getting results"
        
        $results = @()
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        while (-not $this.OutputQueue.IsCompleted -or $this.OutputQueue.Count -gt 0) {
            $item = $null
            
            if ($this.OutputQueue.TryTake([ref]$item, 100)) {
                $results += $item
            }
            
            if ($stopwatch.Elapsed.TotalSeconds -gt $timeoutSeconds) {
                Write-Warning "[BatchProcessor] Timeout getting results"
                break
            }
        }
        
        return $results
    }
    
    # Wait for completion
    [void]WaitForCompletion() {
        Write-Debug "[BatchProcessor] Waiting for completion"
        
        # Wait for all jobs to complete
        $this.ParallelProcessor.WaitForAllJobs(0)
        
        # Complete output queue
        $this.OutputQueue.CompleteAdding()
    }
    
    # Update statistics
    hidden [void]UpdateStatistics() {
        $this.Statistics.CurrentQueueSize = $this.InputQueue.Count
        
        $elapsed = ([datetime]::Now - $this.Statistics.StartTime).TotalSeconds
        if ($elapsed -gt 0) {
            $this.Statistics.AverageItemsPerSecond = [math]::Round($this.Statistics.TotalItemsProcessed / $elapsed, 2)
        }
    }
    
    # Get statistics
    [hashtable]GetStatistics() {
        $this.UpdateStatistics()
        return $this.Statistics.Clone()
    }
    
    # Stop processing
    [void]Stop() {
        Write-Debug "[BatchProcessor] Stopping batch processing"
        
        $this.IsRunning = $false
        $this.CompleteAdding()
        $this.WaitForCompletion()
    }
    
    # Dispose resources
    [void]Dispose() {
        Write-Debug "[BatchProcessor] Disposing batch processor"
        
        $this.Stop()
        
        # Timer disposal removed - no longer using timer
        
        if ($this.ParallelProcessor) {
            $this.ParallelProcessor.Dispose()
        }
        
        if ($this.InputQueue) {
            $this.InputQueue.Dispose()
        }
        
        if ($this.OutputQueue) {
            $this.OutputQueue.Dispose()
        }
    }
}

# Module Functions

function New-ParallelProcessor {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$MinThreads = 1,
        
        [Parameter()]
        [int]$MaxThreads = 0,  # 0 = auto-calculate
        
        [Parameter()]
        [scriptblock]$InitializationScript,
        
        [Parameter()]
        [int]$RetryCount = 3,
        
        [Parameter()]
        [int]$TimeoutSeconds = 300
    )
    
    Write-Verbose "Creating parallel processor"
    
    try {
        $processor = [ParallelProcessor]::new($MinThreads, $MaxThreads, $InitializationScript)
        $processor.RetryCount = $RetryCount
        $processor.TimeoutSeconds = $TimeoutSeconds
        
        Write-Verbose "Parallel processor created successfully"
        return $processor
    } catch {
        Write-Error "Failed to create parallel processor: $_"
        throw
    }
}

function Invoke-ParallelProcessing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$InputObject,
        
        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock,
        
        [Parameter()]
        [int]$ThrottleLimit = 0,
        
        [Parameter()]
        [ParallelProcessor]$Processor
    )
    
    Write-Verbose "Invoking parallel processing for $($InputObject.Count) items"
    
    # Create processor if not provided
    if (-not $Processor) {
        $Processor = New-ParallelProcessor -MaxThreads $ThrottleLimit
        $disposeProcessor = $true
    }
    
    try {
        $results = $Processor.InvokeParallel($InputObject, $ScriptBlock, $ThrottleLimit)
        return $results
    } finally {
        if ($disposeProcessor) {
            $Processor.Dispose()
        }
    }
}

function Start-BatchProcessing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$InputObject,
        
        [Parameter(Mandatory)]
        [scriptblock]$ProcessingScript,
        
        [Parameter()]
        [int]$BatchSize = 10,
        
        [Parameter()]
        [int]$ConsumerCount = 0  # 0 = auto-calculate
    )
    
    Write-Verbose "Starting batch processing for $($InputObject.Count) items"
    
    if ($ConsumerCount -eq 0) {
        $ConsumerCount = [Environment]::ProcessorCount * 2
    }
    
    $batchProcessor = [BatchProcessor]::new($BatchSize, $ConsumerCount, $ProcessingScript)
    
    try {
        $batchProcessor.Start()
        $batchProcessor.AddItems($InputObject)
        $batchProcessor.CompleteAdding()
        $batchProcessor.WaitForCompletion()
        
        $results = $batchProcessor.GetResults()
        
        Write-Verbose "Batch processing completed: $($results.Count) results"
        return $results
    } finally {
        $batchProcessor.Dispose()
    }
}

function Get-ParallelProcessorStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ParallelProcessor]$Processor
    )
    
    Write-Verbose "Getting parallel processor statistics"
    return $Processor.GetStatistics()
}

function Get-JobStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ParallelProcessor]$Processor,
        
        [Parameter(Mandatory)]
        [string]$JobId
    )
    
    Write-Verbose "Getting status for job: $JobId"
    return $Processor.GetJobStatus($JobId)
}

# Export module members
Export-ModuleMember -Function @(
    'New-ParallelProcessor',
    'Invoke-ParallelProcessing',
    'Start-BatchProcessing',
    'Get-ParallelProcessorStatistics',
    'Get-JobStatus'
) -Variable @() -Alias @()

# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC13W3NlLMsmVIm
# 0e4v4sgNlrKxZl9IZHfnHwOhhGroeaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIL2Lnec9uE+oVATRrQXFwNv/
# ACwYnZ6tfwcARTrlZqR2MA0GCSqGSIb3DQEBAQUABIIBAHqL9+QrDIlNRetkCOO6
# vAUJjzgSaPojq3I6BLwK3Azi7SHmvBntkiNavKCxZ4fyyU3pTA7GON/9WlXN912c
# Ue5IaV85fgSEnF5uQiUarFcqkg0kPZTFcghXTMLrb7J/5Um+Bs+n49QOMQMutuod
# yVcCd7WQPaYmmMX4gcLo7xdG+P0akIlpOpGoxEXLQS5LZbY+/sEJ0FObvwIzQGHo
# RVIMEgZUxYMr+C5mOu8tKlPwu4q0P3SA+tnhM9SqoFm6KVVDR89xYky4L6Ucnd4Y
# ZLZYoJTAGcFgvI3c35SkDGSJRwCaELIBWcSl2NvE5y8XLM7o299Qu3uXcOjMqG9T
# CwU=
# SIG # End signature block
