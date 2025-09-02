# ModuleFunctions.psm1
# Public API functions for the Unity-Claude-ParallelProcessor module

using namespace System.Management.Automation.Runspaces
using namespace System.Collections.Concurrent
using namespace System.Threading

Write-Debug "[ModuleFunctions] Module loaded - REFACTORED VERSION"

# Import all required components
Import-Module "$PSScriptRoot\ParallelProcessorCore.psm1" -Force
Import-Module "$PSScriptRoot\RunspacePoolManager.psm1" -Force
Import-Module "$PSScriptRoot\JobScheduler.psm1" -Force
Import-Module "$PSScriptRoot\StatisticsTracker.psm1" -Force
Import-Module "$PSScriptRoot\BatchProcessingEngine.psm1" -Force

#region Main ParallelProcessor Class - Refactored

class ParallelProcessor {
    [string]$ProcessorId
    [object]$PoolManager
    [object]$JobScheduler
    [object]$StatisticsTracker
    [int]$MinThreads
    [int]$MaxThreads
    [bool]$IsRunning
    [int]$OptimalThreadCount
    [hashtable]$SharedData
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
        # Generate unique processor ID
        $this.ProcessorId = New-ProcessorId
        
        Write-ParallelProcessorLog "Initializing ParallelProcessor" -Level Debug -ProcessorId $this.ProcessorId -Component "ParallelProcessor"
        
        # Calculate optimal thread count if not specified
        if ($maxThreads -eq 0) {
            $this.OptimalThreadCount = Get-OptimalThreadCount -WorkloadType 'Mixed'
            $this.MaxThreads = $this.OptimalThreadCount
        } else {
            $this.OptimalThreadCount = $maxThreads
            $this.MaxThreads = $maxThreads
        }
        
        $this.MinThreads = [Math]::Max(1, $minThreads)
        
        # Get default configuration
        $config = Get-ParallelProcessorConfiguration
        $this.RetryCount = $config.DefaultRetryCount
        $this.TimeoutSeconds = $config.DefaultTimeoutSeconds
        
        # Initialize shared data
        $this.SharedData = [hashtable]::Synchronized(@{})
        
        # Create components
        $this.PoolManager = New-RunspacePoolManager -MinThreads $this.MinThreads -MaxThreads $this.MaxThreads -InitializationScript $initScript -ProcessorId $this.ProcessorId
        $this.JobScheduler = New-JobScheduler -PoolManager $this.PoolManager -ProcessorId $this.ProcessorId
        $this.StatisticsTracker = New-StatisticsTracker -ProcessorId $this.ProcessorId
        
        # Configure job scheduler
        $this.JobScheduler.SharedData = $this.SharedData
        $this.JobScheduler.RetryCount = $this.RetryCount
        $this.JobScheduler.TimeoutSeconds = $this.TimeoutSeconds
        
        $this.IsRunning = $true
        
        # Register this processor
        Register-ParallelProcessor -ProcessorId $this.ProcessorId -ProcessorInstance $this
        
        Write-ParallelProcessorLog "ParallelProcessor initialized successfully" -Level Debug -ProcessorId $this.ProcessorId -Component "ParallelProcessor"
    }
    
    # Submit job for execution
    [string]SubmitJob([scriptblock]$scriptBlock, [hashtable]$parameters = @{}) {
        if (-not $this.IsRunning) {
            throw "Parallel processor is not running"
        }
        
        $this.StatisticsTracker.RecordJobSubmission()
        $jobId = $this.JobScheduler.SubmitJob($scriptBlock, $parameters)
        
        return $jobId
    }
    
    # Submit multiple jobs
    [string[]]SubmitJobs([scriptblock]$scriptBlock, [array]$parameterSets) {
        $jobIds = $this.JobScheduler.SubmitJobs($scriptBlock, $parameterSets)
        
        # Record submissions
        foreach ($jobId in $jobIds) {
            $this.StatisticsTracker.RecordJobSubmission()
        }
        
        return $jobIds
    }
    
    # Wait for job completion
    [object]WaitForJob([string]$jobId, [int]$timeoutSeconds = 0) {
        $timeout = if ($timeoutSeconds -gt 0) { $timeoutSeconds } else { $this.TimeoutSeconds }
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        try {
            $result = $this.JobScheduler.WaitForJob($jobId, $timeout)
            
            # Record completion
            $executionTime = $stopwatch.Elapsed.TotalMilliseconds
            $this.StatisticsTracker.RecordJobCompletion($executionTime)
            
            return $result
        } catch {
            $executionTime = $stopwatch.Elapsed.TotalMilliseconds
            $this.StatisticsTracker.RecordJobFailure($executionTime, $_.Exception.Message)
            throw
        }
    }
    
    # Wait for all jobs
    [object[]]WaitForAllJobs([int]$timeoutSeconds = 0) {
        $timeout = if ($timeoutSeconds -gt 0) { $timeoutSeconds } else { $this.TimeoutSeconds }
        
        try {
            $results = $this.JobScheduler.WaitForAllJobs($timeout)
            
            # Update statistics based on job results
            $this.UpdateStatisticsFromJobResults()
            
            return $results
        } catch {
            $this.UpdateStatisticsFromJobResults()
            throw
        }
    }
    
    # Update statistics from completed jobs
    hidden [void]UpdateStatisticsFromJobResults() {
        $allJobs = $this.JobScheduler.GetAllJobStatuses()
        
        foreach ($job in $allJobs) {
            $executionTime = if ($job.Duration) { $job.Duration.TotalMilliseconds } else { 0 }
            
            switch ($job.Status) {
                'Completed' { 
                    $this.StatisticsTracker.RecordJobCompletion($executionTime, $job.RetryCount -gt 0)
                }
                'Failed' { 
                    $this.StatisticsTracker.RecordJobFailure($executionTime, 'Job failed')
                }
                'Cancelled' { 
                    $this.StatisticsTracker.RecordJobCancellation()
                }
            }
        }
    }
    
    # Invoke parallel processing with ForEach pattern
    [object[]]InvokeParallel([array]$InputObjects, [scriptblock]$ScriptBlock, [int]$ThrottleLimit = 0) {
        Write-ParallelProcessorLog "Invoking parallel processing for $($InputObjects.Count) objects" -Level Debug -ProcessorId $this.ProcessorId -Component "ParallelProcessor"
        
        # Adjust thread limit if specified
        $originalMax = $this.MaxThreads
        if ($ThrottleLimit -gt 0 -and $ThrottleLimit -lt $this.MaxThreads) {
            $this.PoolManager.SetRunspacePoolSize($this.MinThreads, $ThrottleLimit)
        }
        
        try {
            # Submit all jobs
            $jobIds = @()
            foreach ($obj in $InputObjects) {
                $jobIds += $this.SubmitJob($ScriptBlock, @{ InputObject = $obj })
            }
            
            # Wait for all to complete
            $results = $this.WaitForAllJobs(0)
            
            Write-ParallelProcessorLog "Parallel processing completed: $($results.Count) results" -Level Debug -ProcessorId $this.ProcessorId -Component "ParallelProcessor"
            return $results
        } finally {
            # Restore original thread limit
            if ($ThrottleLimit -gt 0 -and $ThrottleLimit -lt $originalMax) {
                $this.PoolManager.SetRunspacePoolSize($this.MinThreads, $originalMax)
            }
        }
    }
    
    # Producer-Consumer pattern implementation
    [void]StartProducerConsumer([scriptblock]$Producer, [scriptblock]$Consumer, [int]$ConsumerCount = 0) {
        Write-ParallelProcessorLog "Starting producer-consumer pattern" -Level Debug -ProcessorId $this.ProcessorId -Component "ParallelProcessor"
        
        if ($ConsumerCount -eq 0) {
            $ConsumerCount = $this.OptimalThreadCount
        }
        
        # Create blocking collection for queue
        $queue = [BlockingCollection[object]]::new()
        
        # Start producer
        $producerJobId = $this.SubmitJob($Producer, @{ Queue = $queue })
        
        # Start consumers
        $consumerJobIds = @()
        for ($i = 0; $i -lt $ConsumerCount; $i++) {
            $consumerJobIds += $this.SubmitJob($Consumer, @{ 
                Queue = $queue
                ConsumerId = $i 
            })
        }
        
        # Wait for completion
        $this.WaitForJob($producerJobId)
        $queue.CompleteAdding()
        
        foreach ($jobId in $consumerJobIds) {
            $this.WaitForJob($jobId)
        }
        
        Write-ParallelProcessorLog "Producer-consumer pattern completed" -Level Debug -ProcessorId $this.ProcessorId -Component "ParallelProcessor"
    }
    
    # Get statistics
    [hashtable]GetStatistics() {
        $stats = $this.StatisticsTracker.GetStatistics()
        
        # Add processor-specific information
        $poolInfo = $this.PoolManager.GetRunspacePoolInfo()
        $stats.ThreadPoolInfo = $poolInfo
        $stats.ThreadPoolSize = "$($this.MinThreads)-$($this.MaxThreads)"
        $stats.OptimalThreadCount = $this.OptimalThreadCount
        $stats.ProcessorId = $this.ProcessorId
        $stats.IsRunning = $this.IsRunning
        
        return $stats
    }
    
    # Get job status
    [hashtable]GetJobStatus([string]$jobId) {
        return $this.JobScheduler.GetJobStatus($jobId)
    }
    
    # Cancel job
    [void]CancelJob([string]$jobId) {
        $this.JobScheduler.CancelJob($jobId)
        $this.StatisticsTracker.RecordJobCancellation()
    }
    
    # Cancel all jobs
    [void]CancelAllJobs() {
        $runningJobs = $this.JobScheduler.RunningJobs.Count
        $this.JobScheduler.CancelAllJobs()
        
        # Record cancellations
        for ($i = 0; $i -lt $runningJobs; $i++) {
            $this.StatisticsTracker.RecordJobCancellation()
        }
    }
    
    # Cleanup completed jobs
    [void]CleanupCompletedJobs() {
        $this.JobScheduler.CleanupCompletedJobs()
    }
    
    # Dispose resources
    [void]Dispose() {
        Write-ParallelProcessorLog "Disposing ParallelProcessor" -Level Debug -ProcessorId $this.ProcessorId -Component "ParallelProcessor"
        
        try {
            # Cancel all running jobs
            $this.CancelAllJobs()
            
            # Dispose components
            if ($this.JobScheduler) {
                $this.JobScheduler.Dispose()
            }
            
            if ($this.PoolManager) {
                $this.PoolManager.Dispose()
            }
            
            if ($this.StatisticsTracker) {
                $this.StatisticsTracker.Dispose()
            }
            
            # Unregister processor
            Unregister-ParallelProcessor -ProcessorId $this.ProcessorId
            
            $this.IsRunning = $false
        } catch {
            Write-ParallelProcessorLog "Error disposing ParallelProcessor: $_" -Level Warning -ProcessorId $this.ProcessorId -Component "ParallelProcessor"
        }
    }
}

#endregion

#region Public API Functions

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
    
    Write-Verbose "Creating parallel processor (Min: $MinThreads, Max: $MaxThreads)"
    
    try {
        $processor = New-Object -TypeName ParallelProcessor -ArgumentList $MinThreads, $MaxThreads, $InitializationScript
        $processor.RetryCount = $RetryCount
        $processor.TimeoutSeconds = $TimeoutSeconds
        
        Write-Verbose "Parallel processor created successfully with ID: $($processor.ProcessorId)"
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
        [object]$Processor
    )
    
    Write-Verbose "Invoking parallel processing for $($InputObject.Count) items"
    
    # Create processor if not provided
    $disposeProcessor = $false
    if (-not $Processor) {
        $Processor = New-ParallelProcessor -MaxThreads $ThrottleLimit
        $disposeProcessor = $true
    }
    
    try {
        $results = $Processor.InvokeParallel($InputObject, $ScriptBlock, $ThrottleLimit)
        Write-Verbose "Parallel processing completed: $($results.Count) results"
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
    
    Write-Verbose "Starting batch processing for $($InputObject.Count) items (BatchSize: $BatchSize)"
    
    try {
        $results = Start-SimpleBatchProcessing -InputObject $InputObject -ProcessingScript $ProcessingScript -BatchSize $BatchSize -ConsumerCount $ConsumerCount
        Write-Verbose "Batch processing completed: $($results.Count) results"
        return $results
    } catch {
        Write-Error "Batch processing failed: $_"
        throw
    }
}

function Get-ParallelProcessorStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Processor
    )
    
    Write-Verbose "Getting parallel processor statistics for: $($Processor.ProcessorId)"
    return $Processor.GetStatistics()
}

function Get-JobStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Processor,
        
        [Parameter(Mandatory)]
        [string]$JobId
    )
    
    Write-Verbose "Getting status for job: $JobId"
    return $Processor.GetJobStatus($JobId)
}

function Stop-ParallelProcessor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Processor,
        
        [Parameter()]
        [int]$TimeoutSeconds = 30
    )
    
    Write-Verbose "Stopping parallel processor: $($Processor.ProcessorId)"
    
    try {
        # Cancel all running jobs
        $Processor.CancelAllJobs()
        
        # Wait a moment for jobs to cancel
        Start-Sleep -Milliseconds 500
        
        # Dispose the processor
        $Processor.Dispose()
        
        Write-Verbose "Parallel processor stopped successfully"
    } catch {
        Write-Warning "Error stopping parallel processor: $_"
    }
}

function Test-ParallelProcessorHealth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Processor
    )
    
    Write-Verbose "Testing parallel processor health: $($Processor.ProcessorId)"
    
    try {
        $health = @{
            ProcessorId = $Processor.ProcessorId
            IsRunning = $Processor.IsRunning
            IsHealthy = $true
            Issues = @()
            ComponentHealth = @{}
        }
        
        # Test runspace pool health
        $poolHealth = Test-RunspacePoolHealth -PoolManager $Processor.PoolManager
        $health.ComponentHealth.RunspacePool = $poolHealth
        
        if (-not $poolHealth.IsHealthy) {
            $health.IsHealthy = $false
            $health.Issues += "Runspace pool issues: $($poolHealth.Issues -join ', ')"
        }
        
        # Check processor state
        if (-not $Processor.IsRunning) {
            $health.IsHealthy = $false
            $health.Issues += "Processor is not running"
        }
        
        # Get performance summary
        $perfSummary = Format-StatisticsReport -StatisticsTracker $Processor.StatisticsTracker -ReportType 'Performance'
        $health.PerformanceSummary = $perfSummary
        
        return $health
    } catch {
        return @{
            ProcessorId = $Processor.ProcessorId
            IsHealthy = $false
            Issues = @("Error checking health: $_")
            ComponentHealth = @{}
        }
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'New-ParallelProcessor',
    'Invoke-ParallelProcessing', 
    'Start-BatchProcessing',
    'Get-ParallelProcessorStatistics',
    'Get-JobStatus',
    'Stop-ParallelProcessor',
    'Test-ParallelProcessorHealth'
) -Variable @() -Alias @()
# Added by Fix-ParallelProcessorExports
Export-ModuleMember -Function Test-ParallelProcessorHealth


# Added by Fix-ParallelProcessorExports
Export-ModuleMember -Function Stop-ParallelProcessor


# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCtjK6sJQ8En0Bi
# IPKiSE/wbrIkpTsBNjlmuhvXE8emR6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHop62dbXE6JhuJkAU4GBcZ9
# aqTSwrhXnz6ib2dJ/X0rMA0GCSqGSIb3DQEBAQUABIIBAKmflRIR2CjQH76JX818
# kxrqUIWcikYEeGFXwqAadBvIDfkuyPuhoBGaNK+dwqnGMFpZLxmlGFRqn95VnOw/
# tpRVLXha/8S//JYT9y4TVjEeOD0HSt10+P0KKqScl4xQkjsj8TgXIxQhMqqq73Ga
# JQuRvtcmKIV6AC7nHj4lI7A1UmmpsDWrGgZ9HcWcWnyL7Kp1bGYFeWy0sbOqUX7w
# 8zR6TlEa+lCI7pf2IKZJ5snwKljL73FdxhcYFr5lx0LUi6NevJ8HBrgQhkLOvzMW
# JU5AUmB+y4eJvK0xTKA2r7y7Rw5Fs2+oqwDUYVOUUHt9yjDmZxTy4XWfL/r2gjBO
# IMA=
# SIG # End signature block
