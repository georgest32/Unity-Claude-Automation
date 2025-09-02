# BatchProcessingEngine.psm1
# Batch processing engine with producer-consumer patterns and queue management

using namespace System.Collections.Concurrent
using namespace System.Threading

Write-Debug "[BatchProcessingEngine] Module loaded - REFACTORED VERSION"

# Import core functions and required modules
Import-Module "$PSScriptRoot\ParallelProcessorCore.psm1" -Force
Import-Module "$PSScriptRoot\RunspacePoolManager.psm1" -Force
Import-Module "$PSScriptRoot\JobScheduler.psm1" -Force
Import-Module "$PSScriptRoot\StatisticsTracker.psm1" -Force

#region Batch Processing Engine Class

class BatchProcessingEngine {
    [object]$JobScheduler
    [object]$StatisticsTracker
    [BlockingCollection[object]]$InputQueue
    [BlockingCollection[object]]$OutputQueue
    [int]$BatchSize
    [int]$ConsumerCount
    [bool]$IsRunning
    [scriptblock]$ProcessingScript
    [string]$ProcessorId
    [string[]]$ConsumerJobIds
    [hashtable]$BatchStatistics
    
    BatchProcessingEngine([int]$batchSize, [int]$consumerCount, [scriptblock]$processingScript, [object]$jobScheduler, [string]$processorId) {
        Write-ParallelProcessorLog "Initializing BatchProcessingEngine" -Level Debug -ProcessorId $processorId -Component "BatchProcessingEngine"
        
        $this.BatchSize = $batchSize
        $this.ConsumerCount = $consumerCount
        $this.ProcessingScript = $processingScript
        $this.JobScheduler = $jobScheduler
        $this.ProcessorId = $processorId
        $this.IsRunning = $false
        $this.ConsumerJobIds = @()
        
        # Create queues
        $this.InputQueue = [BlockingCollection[object]]::new()
        $this.OutputQueue = [BlockingCollection[object]]::new()
        
        # Create statistics tracker for batches
        $this.StatisticsTracker = New-StatisticsTracker -ProcessorId "$processorId-Batch"
        
        # Initialize batch-specific statistics
        $this.BatchStatistics = [hashtable]::Synchronized(@{
            TotalItemsQueued = 0
            TotalItemsProcessed = 0
            TotalBatchesProcessed = 0
            AverageItemsPerSecond = 0
            CurrentQueueSize = 0
            StartTime = [datetime]::Now
            LastProcessedTime = [datetime]::MinValue
            ConsumersRunning = 0
            AverageBatchProcessingTime = 0
            TotalBatchProcessingTime = 0
        })
        
        Write-ParallelProcessorLog "BatchProcessingEngine initialized" -Level Debug -ProcessorId $processorId -Component "BatchProcessingEngine"
    }
    
    # Start batch processing with consumer threads
    [void]Start() {
        if ($this.IsRunning) {
            Write-ParallelProcessorLog "BatchProcessingEngine is already running" -Level Warning -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
            return
        }
        
        Write-ParallelProcessorLog "Starting BatchProcessingEngine with $($this.ConsumerCount) consumers" -Level Debug -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
        $this.IsRunning = $true
        
        # Create consumer script block
        $consumerScript = {
            param($ConsumerId, $InputQueue, $OutputQueue, $BatchSize, $ProcessingScript, $BatchStatistics, $ProcessorId)
            
            Write-ParallelProcessorLog "Consumer-$ConsumerId started" -Level Debug -ProcessorId $ProcessorId -Component "BatchConsumer-$ConsumerId"
            $batch = @()
            $consumerStats = @{
                ItemsProcessed = 0
                BatchesProcessed = 0
                ErrorsEncountered = 0
                StartTime = [datetime]::Now
            }
            
            try {
                while (-not $InputQueue.IsCompleted) {
                    $item = $null
                    $timeout = 1000  # 1 second timeout
                    
                    if ($InputQueue.TryTake([ref]$item, $timeout)) {
                        $batch += $item
                        
                        # Process batch when full or queue is completing
                        if ($batch.Count -ge $BatchSize -or ($InputQueue.IsCompleted -and $batch.Count -gt 0)) {
                            if ($batch.Count -gt 0) {
                                $batchStartTime = [datetime]::Now
                                
                                Write-ParallelProcessorLog "Consumer-$ConsumerId processing batch of $($batch.Count) items" -Level Debug -ProcessorId $ProcessorId -Component "BatchConsumer-$ConsumerId"
                                
                                try {
                                    # Process the batch
                                    $results = & $ProcessingScript $batch
                                    
                                    # Add results to output queue
                                    if ($results) {
                                        foreach ($result in $results) {
                                            if ($null -ne $result) {
                                                $OutputQueue.Add($result)
                                            }
                                        }
                                    }
                                    
                                    # Update statistics
                                    $batchProcessingTime = ([datetime]::Now - $batchStartTime).TotalMilliseconds
                                    $BatchStatistics.TotalItemsProcessed += $batch.Count
                                    $BatchStatistics.TotalBatchesProcessed++
                                    $BatchStatistics.LastProcessedTime = [datetime]::Now
                                    $BatchStatistics.TotalBatchProcessingTime += $batchProcessingTime
                                    $BatchStatistics.AverageBatchProcessingTime = $BatchStatistics.TotalBatchProcessingTime / $BatchStatistics.TotalBatchesProcessed
                                    
                                    # Update consumer stats
                                    $consumerStats.ItemsProcessed += $batch.Count
                                    $consumerStats.BatchesProcessed++
                                    
                                    Write-ParallelProcessorLog "Consumer-$ConsumerId completed batch ($($batch.Count) items, $([math]::Round($batchProcessingTime, 2)) ms)" -Level Debug -ProcessorId $ProcessorId -Component "BatchConsumer-$ConsumerId"
                                } catch {
                                    Write-ParallelProcessorLog "Consumer-$ConsumerId batch processing error: $_" -Level Error -ProcessorId $ProcessorId -Component "BatchConsumer-$ConsumerId"
                                    $consumerStats.ErrorsEncountered++
                                }
                                
                                # Clear batch
                                $batch = @()
                            }
                        }
                    } elseif ($InputQueue.IsCompleted) {
                        # Process any remaining items
                        if ($batch.Count -gt 0) {
                            Write-ParallelProcessorLog "Consumer-$ConsumerId processing final batch of $($batch.Count) items" -Level Debug -ProcessorId $ProcessorId -Component "BatchConsumer-$ConsumerId"
                            
                            try {
                                $results = & $ProcessingScript $batch
                                if ($results) {
                                    foreach ($result in $results) {
                                        if ($null -ne $result) {
                                            $OutputQueue.Add($result)
                                        }
                                    }
                                }
                                
                                $BatchStatistics.TotalItemsProcessed += $batch.Count
                                $BatchStatistics.TotalBatchesProcessed++
                                $consumerStats.ItemsProcessed += $batch.Count
                                $consumerStats.BatchesProcessed++
                            } catch {
                                Write-ParallelProcessorLog "Consumer-$ConsumerId final batch processing error: $_" -Level Error -ProcessorId $ProcessorId -Component "BatchConsumer-$ConsumerId"
                                $consumerStats.ErrorsEncountered++
                            }
                        }
                        break
                    }
                }
            } catch {
                Write-ParallelProcessorLog "Consumer-$ConsumerId fatal error: $_" -Level Error -ProcessorId $ProcessorId -Component "BatchConsumer-$ConsumerId"
            } finally {
                $consumerStats.EndTime = [datetime]::Now
                $consumerStats.Duration = $consumerStats.EndTime - $consumerStats.StartTime
                
                Write-ParallelProcessorLog "Consumer-$ConsumerId completed. Stats: $($consumerStats.ItemsProcessed) items, $($consumerStats.BatchesProcessed) batches, $($consumerStats.ErrorsEncountered) errors" -Level Debug -ProcessorId $ProcessorId -Component "BatchConsumer-$ConsumerId"
            }
        }
        
        # Start consumer threads
        $this.ConsumerJobIds = @()
        for ($i = 0; $i -lt $this.ConsumerCount; $i++) {
            $jobId = $this.JobScheduler.SubmitJob($consumerScript, @{
                ConsumerId = $i
                InputQueue = $this.InputQueue
                OutputQueue = $this.OutputQueue
                BatchSize = $this.BatchSize
                ProcessingScript = $this.ProcessingScript
                BatchStatistics = $this.BatchStatistics
                ProcessorId = $this.ProcessorId
            })
            
            $this.ConsumerJobIds += $jobId
        }
        
        $this.BatchStatistics.ConsumersRunning = $this.ConsumerJobIds.Count
        Write-ParallelProcessorLog "Started $($this.ConsumerJobIds.Count) consumer threads" -Level Debug -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
    }
    
    # Add items to the processing queue
    [void]AddItems([array]$items) {
        if (-not $this.IsRunning) {
            throw "BatchProcessingEngine is not running. Call Start() first."
        }
        
        Write-ParallelProcessorLog "Adding $($items.Count) items to processing queue" -Level Debug -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
        
        foreach ($item in $items) {
            try {
                $this.InputQueue.Add($item)
                $this.BatchStatistics.TotalItemsQueued++
            } catch {
                Write-ParallelProcessorLog "Error adding item to queue: $_" -Level Warning -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
            }
        }
        
        $this.UpdateQueueStatistics()
        Write-ParallelProcessorLog "Added $($items.Count) items. Queue size: $($this.BatchStatistics.CurrentQueueSize)" -Level Debug -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
    }
    
    # Add single item to queue
    [void]AddItem([object]$item) {
        $this.AddItems(@($item))
    }
    
    # Complete adding items and signal consumers to finish
    [void]CompleteAdding() {
        Write-ParallelProcessorLog "Completing input queue - no more items will be added" -Level Debug -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
        
        try {
            $this.InputQueue.CompleteAdding()
        } catch {
            Write-ParallelProcessorLog "Error completing input queue: $_" -Level Warning -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
        }
    }
    
    # Get results from output queue
    [object[]]GetResults([int]$timeoutSeconds = 60) {
        Write-ParallelProcessorLog "Getting results (timeout: $timeoutSeconds seconds)" -Level Debug -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
        
        $results = @()
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        while ((-not $this.OutputQueue.IsCompleted -or $this.OutputQueue.Count -gt 0) -and $stopwatch.Elapsed.TotalSeconds -lt $timeoutSeconds) {
            $item = $null
            
            if ($this.OutputQueue.TryTake([ref]$item, 100)) {  # 100ms timeout per attempt
                $results += $item
            }
        }
        
        if ($stopwatch.Elapsed.TotalSeconds -ge $timeoutSeconds) {
            Write-ParallelProcessorLog "Timeout getting results after $timeoutSeconds seconds. Retrieved $($results.Count) results." -Level Warning -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
        } else {
            Write-ParallelProcessorLog "Retrieved $($results.Count) results" -Level Debug -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
        }
        
        return $results
    }
    
    # Wait for all consumers to complete
    [void]WaitForCompletion([int]$timeoutSeconds = 300) {
        Write-ParallelProcessorLog "Waiting for all consumers to complete (timeout: $timeoutSeconds seconds)" -Level Debug -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
        
        if ($this.ConsumerJobIds.Count -eq 0) {
            Write-ParallelProcessorLog "No consumer jobs to wait for" -Level Debug -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
            return
        }
        
        # Wait for all consumer jobs
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        foreach ($jobId in $this.ConsumerJobIds) {
            $remainingTime = [Math]::Max(1, $timeoutSeconds - $stopwatch.Elapsed.TotalSeconds)
            try {
                $this.JobScheduler.WaitForJob($jobId, $remainingTime)
            } catch {
                Write-ParallelProcessorLog "Consumer job $jobId did not complete within timeout: $_" -Level Warning -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
            }
        }
        
        # Complete output queue
        try {
            $this.OutputQueue.CompleteAdding()
        } catch {
            Write-ParallelProcessorLog "Error completing output queue: $_" -Level Warning -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
        }
        
        $this.BatchStatistics.ConsumersRunning = 0
        Write-ParallelProcessorLog "All consumers completed" -Level Debug -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
    }
    
    # Update queue size statistics
    hidden [void]UpdateQueueStatistics() {
        try {
            $this.BatchStatistics.CurrentQueueSize = $this.InputQueue.Count
            
            # Calculate throughput
            $elapsed = ([datetime]::Now - $this.BatchStatistics.StartTime).TotalSeconds
            if ($elapsed -gt 0) {
                $this.BatchStatistics.AverageItemsPerSecond = [math]::Round($this.BatchStatistics.TotalItemsProcessed / $elapsed, 2)
            }
        } catch {
            Write-ParallelProcessorLog "Error updating queue statistics: $_" -Level Warning -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
        }
    }
    
    # Get batch processing statistics
    [hashtable]GetStatistics() {
        $this.UpdateQueueStatistics()
        
        $stats = $this.BatchStatistics.Clone()
        $stats.ProcessorId = $this.ProcessorId
        $stats.IsRunning = $this.IsRunning
        $stats.Uptime = [datetime]::Now - $stats.StartTime
        $stats.BatchSize = $this.BatchSize
        $stats.ConsumerCount = $this.ConsumerCount
        
        # Add efficiency metrics
        if ($stats.TotalItemsQueued -gt 0) {
            $stats.ProcessingEfficiency = [math]::Round(($stats.TotalItemsProcessed / $stats.TotalItemsQueued) * 100, 2)
        } else {
            $stats.ProcessingEfficiency = 0
        }
        
        return $stats
    }
    
    # Stop batch processing
    [void]Stop() {
        if (-not $this.IsRunning) {
            Write-ParallelProcessorLog "BatchProcessingEngine is not running" -Level Debug -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
            return
        }
        
        Write-ParallelProcessorLog "Stopping BatchProcessingEngine" -Level Debug -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
        
        $this.IsRunning = $false
        $this.CompleteAdding()
        $this.WaitForCompletion(30)  # 30 second timeout for shutdown
    }
    
    # Dispose resources
    [void]Dispose() {
        Write-ParallelProcessorLog "Disposing BatchProcessingEngine" -Level Debug -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
        
        try {
            $this.Stop()
            
            if ($this.InputQueue) {
                $this.InputQueue.Dispose()
            }
            
            if ($this.OutputQueue) {
                $this.OutputQueue.Dispose()
            }
            
            if ($this.StatisticsTracker) {
                $this.StatisticsTracker.Dispose()
            }
        } catch {
            Write-ParallelProcessorLog "Error disposing BatchProcessingEngine: $_" -Level Warning -ProcessorId $this.ProcessorId -Component "BatchProcessingEngine"
        }
    }
}

#endregion

#region Helper Functions

function New-BatchProcessingEngine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$BatchSize,
        
        [Parameter()]
        [int]$ConsumerCount = 0,
        
        [Parameter(Mandatory)]
        [scriptblock]$ProcessingScript,
        
        [Parameter(Mandatory)]
        [JobScheduler]$JobScheduler,
        
        [Parameter(Mandatory)]
        [string]$ProcessorId
    )
    
    # Auto-calculate consumer count if not specified
    if ($ConsumerCount -eq 0) {
        $ConsumerCount = Get-OptimalThreadCount -WorkloadType 'Mixed'
    }
    
    Write-ParallelProcessorLog "Creating BatchProcessingEngine (BatchSize: $BatchSize, Consumers: $ConsumerCount)" -Level Debug -ProcessorId $ProcessorId -Component "BatchProcessingEngine"
    
    try {
        $engine = [BatchProcessingEngine]::new($BatchSize, $ConsumerCount, $ProcessingScript, $JobScheduler, $ProcessorId)
        Write-ParallelProcessorLog "BatchProcessingEngine created successfully" -Level Debug -ProcessorId $ProcessorId -Component "BatchProcessingEngine"
        return $engine
    } catch {
        Write-ParallelProcessorLog "Failed to create BatchProcessingEngine: $_" -Level Error -ProcessorId $ProcessorId -Component "BatchProcessingEngine"
        throw
    }
}

function Start-SimpleBatchProcessing {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$InputObject,
        
        [Parameter(Mandatory)]
        [scriptblock]$ProcessingScript,
        
        [Parameter()]
        [int]$BatchSize = 10,
        
        [Parameter()]
        [int]$ConsumerCount = 0,
        
        [Parameter()]
        [JobScheduler]$JobScheduler
    )
    
    # Create temporary processor ID if no job scheduler provided
    $processorId = if ($JobScheduler) { $JobScheduler.ProcessorId } else { New-ProcessorId }
    
    Write-ParallelProcessorLog "Starting simple batch processing for $($InputObject.Count) items" -Level Debug -ProcessorId $processorId -Component "BatchProcessingEngine"
    
    # Create temporary job scheduler if not provided
    $disposeScheduler = $false
    if (-not $JobScheduler) {
        $poolManager = New-RunspacePoolManager -ProcessorId $processorId
        $JobScheduler = [JobScheduler]::new($poolManager, $processorId)
        $disposeScheduler = $true
    }
    
    # Create batch processing engine
    $batchEngine = New-BatchProcessingEngine -BatchSize $BatchSize -ConsumerCount $ConsumerCount -ProcessingScript $ProcessingScript -JobScheduler $JobScheduler -ProcessorId $processorId
    
    try {
        # Start processing
        $batchEngine.Start()
        $batchEngine.AddItems($InputObject)
        $batchEngine.CompleteAdding()
        $batchEngine.WaitForCompletion()
        
        # Get results
        $results = $batchEngine.GetResults()
        
        Write-ParallelProcessorLog "Simple batch processing completed: $($results.Count) results" -Level Debug -ProcessorId $processorId -Component "BatchProcessingEngine"
        return $results
    } finally {
        $batchEngine.Dispose()
        
        if ($disposeScheduler) {
            $JobScheduler.Dispose()
            $poolManager.Dispose()
        }
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'New-BatchProcessingEngine',
    'Start-SimpleBatchProcessing'
) -Variable @() -Alias @()
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDoeyY32nGofEaa
# Ix3hWaB7LXMbFA0vDGOIUKH8Ifw52KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOznwl53+oVYDZEIeubBZwMh
# kHfbHS6opqeDQ/4JieE8MA0GCSqGSIb3DQEBAQUABIIBAIIOiADxl/B9tPuL9psR
# Hi5iwtDOJy7gfe4Gty5iBTHTOP6tMh/85yq9h5q+oWGfrDOogOXDy9VhigrmZT2i
# mEdccunXhJTLYGgCzvvBopgaVWPVMIserl06+G31bsZMerPih5JP4GpFOm2LYx/g
# qvma9/FJehgLd0X2Em4xZvOEj8V6mdxq1MK8Q3nmJQsrYt/LCYusao65wl/mNgLq
# uRdg4BHvYVS9lun4QzucAlyys3K/D9Xrs+4bY3fle/MXIM10NaqN2td2ZgqudZRv
# /sap/6uvHQOjb7McSWPzCRljaRLd6tVDFCGU41Lx2myvk5lAOR3juYQi9RW3gbbm
# Zi8=
# SIG # End signature block
