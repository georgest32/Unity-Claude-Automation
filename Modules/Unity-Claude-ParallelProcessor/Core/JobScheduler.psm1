# JobScheduler.psm1
# Job submission, execution, tracking, and result collection for parallel processing

using namespace System.Management.Automation.Runspaces
using namespace System.Collections.Concurrent
using namespace System.Threading

Write-Debug "[JobScheduler] Module loaded - REFACTORED VERSION"

# Import core functions
Import-Module "$PSScriptRoot\ParallelProcessorCore.psm1" -Force
Import-Module "$PSScriptRoot\RunspacePoolManager.psm1" -Force

#region Job Management Classes

class ParallelJob {
    [string]$Id
    [PowerShell]$PowerShell
    [System.IAsyncResult]$Handle
    [datetime]$StartTime
    [datetime]$EndTime
    [hashtable]$Parameters
    [string]$Status  # 'Submitted', 'Running', 'Completed', 'Failed', 'Cancelled'
    [object]$Result
    [System.Management.Automation.ErrorRecord[]]$Errors
    [int]$RetryCount
    [string]$ProcessorId
    [scriptblock]$ScriptBlock
    
    ParallelJob([string]$id, [scriptblock]$scriptBlock, [hashtable]$parameters, [string]$processorId) {
        $this.Id = $id
        $this.ScriptBlock = $scriptBlock
        $this.Parameters = if ($parameters) { $parameters } else { @{} }
        $this.StartTime = [datetime]::Now
        $this.Status = 'Submitted'
        $this.RetryCount = 0
        $this.ProcessorId = $processorId
        $this.Errors = @()
    }
    
    # Get job duration
    [timespan]GetDuration() {
        if ($this.EndTime -eq [datetime]::MinValue) {
            return [datetime]::Now - $this.StartTime
        } else {
            return $this.EndTime - $this.StartTime
        }
    }
    
    # Get job summary
    [hashtable]GetSummary() {
        return @{
            Id = $this.Id
            Status = $this.Status
            StartTime = $this.StartTime
            EndTime = $this.EndTime
            Duration = $this.GetDuration()
            RetryCount = $this.RetryCount
            HasErrors = $this.Errors.Count -gt 0
            ErrorCount = $this.Errors.Count
            ParameterCount = $this.Parameters.Count
        }
    }
}

class JobScheduler {
    [ConcurrentDictionary[string, ParallelJob]]$Jobs
    [System.Collections.Generic.List[ParallelJob]]$RunningJobs
    [object]$PoolManager
    [hashtable]$SharedData
    [System.Threading.CancellationTokenSource]$CancellationTokenSource
    [int]$RetryCount
    [int]$TimeoutSeconds
    [string]$ProcessorId
    
    JobScheduler([object]$poolManager, [string]$processorId) {
        Write-ParallelProcessorLog "Initializing JobScheduler" -Level Debug -ProcessorId $processorId -Component "JobScheduler"
        
        $this.PoolManager = $poolManager
        $this.ProcessorId = $processorId
        $this.Jobs = [ConcurrentDictionary[string, ParallelJob]]::new()
        $this.RunningJobs = [System.Collections.Generic.List[ParallelJob]]::new()
        $this.SharedData = [hashtable]::Synchronized(@{})
        $this.CancellationTokenSource = [System.Threading.CancellationTokenSource]::new()
        
        # Get default configuration
        $config = Get-ParallelProcessorConfiguration
        $this.RetryCount = $config.DefaultRetryCount
        $this.TimeoutSeconds = $config.DefaultTimeoutSeconds
        
        Write-ParallelProcessorLog "JobScheduler initialized" -Level Debug -ProcessorId $processorId -Component "JobScheduler"
    }
    
    # Submit a job for execution
    [string]SubmitJob([scriptblock]$scriptBlock, [hashtable]$parameters = @{}) {
        # Validate inputs
        if (-not (Test-ScriptBlockSafety -ScriptBlock $scriptBlock)) {
            throw "Script block failed safety validation"
        }
        
        if (-not (Test-ParameterValidity -Parameters $parameters)) {
            throw "Parameters failed validation"
        }
        
        $jobId = [Guid]::NewGuid().ToString()
        Write-ParallelProcessorLog "Submitting job: $jobId" -Level Debug -ProcessorId $this.ProcessorId -Component "JobScheduler"
        
        # Create job object
        $job = [ParallelJob]::new($jobId, $scriptBlock, $parameters, $this.ProcessorId)
        
        try {
            # Create PowerShell instance
            $job.PowerShell = [PowerShell]::Create()
            $job.PowerShell.RunspacePool = $this.PoolManager.RunspacePool
            
            # Add script block
            [void]$job.PowerShell.AddScript($scriptBlock)
            
            # Add parameters
            foreach ($param in $parameters.GetEnumerator()) {
                [void]$job.PowerShell.AddParameter($param.Key, $param.Value)
            }
            
            # Add shared data as a parameter if not already present
            if (-not $parameters.ContainsKey('SharedData')) {
                [void]$job.PowerShell.AddParameter('SharedData', $this.SharedData)
            }
            
            # Start async execution
            $job.Handle = $job.PowerShell.BeginInvoke()
            $job.Status = 'Running'
            
            # Store job
            $this.Jobs[$jobId] = $job
            $this.RunningJobs.Add($job)
            
            Write-ParallelProcessorLog "Job submitted and started: $jobId" -Level Debug -ProcessorId $this.ProcessorId -Component "JobScheduler"
            return $jobId
        } catch {
            Write-ParallelProcessorLog "Failed to submit job $jobId : $_" -Level Error -ProcessorId $this.ProcessorId -Component "JobScheduler"
            $job.Status = 'Failed'
            $job.Errors += $_
            throw
        }
    }
    
    # Submit multiple jobs
    [string[]]SubmitJobs([scriptblock]$scriptBlock, [array]$parameterSets) {
        Write-ParallelProcessorLog "Submitting batch of $($parameterSets.Count) jobs" -Level Debug -ProcessorId $this.ProcessorId -Component "JobScheduler"
        
        $jobIds = @()
        
        foreach ($params in $parameterSets) {
            try {
                if ($params -is [hashtable]) {
                    $jobIds += $this.SubmitJob($scriptBlock, $params)
                } else {
                    $jobIds += $this.SubmitJob($scriptBlock, @{ InputObject = $params })
                }
            } catch {
                Write-ParallelProcessorLog "Failed to submit job in batch: $_" -Level Warning -ProcessorId $this.ProcessorId -Component "JobScheduler"
            }
        }
        
        Write-ParallelProcessorLog "Submitted $($jobIds.Count) jobs successfully" -Level Debug -ProcessorId $this.ProcessorId -Component "JobScheduler"
        return $jobIds
    }
    
    # Wait for a specific job
    [object]WaitForJob([string]$jobId, [int]$timeoutSeconds = 0) {
        if (-not $this.Jobs.ContainsKey($jobId)) {
            throw "Job not found: $jobId"
        }
        
        $job = $this.Jobs[$jobId]
        $timeout = if ($timeoutSeconds -gt 0) { $timeoutSeconds } else { $this.TimeoutSeconds }
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        Write-ParallelProcessorLog "Waiting for job: $jobId (timeout: $timeout seconds)" -Level Debug -ProcessorId $this.ProcessorId -Component "JobScheduler"
        
        while ($job.Status -eq 'Running') {
            if ($job.Handle.IsCompleted) {
                $this.CollectJobResult($job)
                break
            }
            
            if ($stopwatch.Elapsed.TotalSeconds -gt $timeout) {
                Write-ParallelProcessorLog "Job $jobId timed out after $timeout seconds" -Level Warning -ProcessorId $this.ProcessorId -Component "JobScheduler"
                $this.CancelJob($jobId)
                throw "Job timed out: $jobId"
            }
            
            Start-Sleep -Milliseconds 100
        }
        
        return $job.Result
    }
    
    # Wait for all running jobs
    [object[]]WaitForAllJobs([int]$timeoutSeconds = 0) {
        $timeout = if ($timeoutSeconds -gt 0) { $timeoutSeconds } else { $this.TimeoutSeconds }
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        Write-ParallelProcessorLog "Waiting for all jobs (count: $($this.RunningJobs.Count), timeout: $timeout seconds)" -Level Debug -ProcessorId $this.ProcessorId -Component "JobScheduler"
        
        while ($this.RunningJobs.Count -gt 0) {
            $completedJobs = @()
            
            # Check for completed jobs
            foreach ($job in $this.RunningJobs) {
                if ($job.Handle.IsCompleted) {
                    $this.CollectJobResult($job)
                    $completedJobs += $job
                }
            }
            
            # Remove completed jobs from running list
            foreach ($job in $completedJobs) {
                $this.RunningJobs.Remove($job)
            }
            
            # Check timeout
            if ($stopwatch.Elapsed.TotalSeconds -gt $timeout) {
                Write-ParallelProcessorLog "Timeout waiting for all jobs after $timeout seconds" -Level Warning -ProcessorId $this.ProcessorId -Component "JobScheduler"
                $this.CancelAllJobs()
                break
            }
            
            if ($this.RunningJobs.Count -gt 0) {
                Start-Sleep -Milliseconds 100
            }
        }
        
        # Collect all results
        $allResults = @()
        foreach ($job in $this.Jobs.Values) {
            if ($job.Status -eq 'Completed' -and $null -ne $job.Result) {
                $allResults += $job.Result
            }
        }
        
        Write-ParallelProcessorLog "All jobs completed. Results: $($allResults.Count)" -Level Debug -ProcessorId $this.ProcessorId -Component "JobScheduler"
        return $allResults
    }
    
    # Collect job result
    hidden [void]CollectJobResult([ParallelJob]$job) {
        Write-ParallelProcessorLog "Collecting result for job: $($job.Id)" -Level Debug -ProcessorId $this.ProcessorId -Component "JobScheduler"
        
        try {
            # End invoke and get result
            $result = $job.PowerShell.EndInvoke($job.Handle)
            $job.EndTime = [datetime]::Now
            
            # Check for errors
            if ($job.PowerShell.HadErrors) {
                $job.Errors = $job.PowerShell.Streams.Error
                $job.Status = 'Failed'
                
                # Retry logic
                if ($job.RetryCount -lt $this.RetryCount) {
                    Write-ParallelProcessorLog "Job $($job.Id) failed, retrying (attempt $($job.RetryCount + 1)/$($this.RetryCount))" -Level Warning -ProcessorId $this.ProcessorId -Component "JobScheduler"
                    $this.RetryJob($job)
                    return
                } else {
                    Write-ParallelProcessorLog "Job $($job.Id) failed after $($this.RetryCount) retries" -Level Error -ProcessorId $this.ProcessorId -Component "JobScheduler"
                }
            } else {
                $job.Result = $result
                $job.Status = 'Completed'
                Write-ParallelProcessorLog "Job $($job.Id) completed successfully" -Level Debug -ProcessorId $this.ProcessorId -Component "JobScheduler"
            }
        } catch {
            Write-ParallelProcessorLog "Error collecting job result for $($job.Id): $_" -Level Error -ProcessorId $this.ProcessorId -Component "JobScheduler"
            $job.Status = 'Failed'
            $job.Errors += $_
            $job.EndTime = [datetime]::Now
        } finally {
            # Dispose PowerShell instance
            if ($job.PowerShell) {
                $job.PowerShell.Dispose()
                $job.PowerShell = $null
            }
        }
    }
    
    # Retry failed job
    hidden [void]RetryJob([ParallelJob]$job) {
        $job.RetryCount++
        Write-ParallelProcessorLog "Retrying job $($job.Id) (attempt $($job.RetryCount))" -Level Debug -ProcessorId $this.ProcessorId -Component "JobScheduler"
        
        try {
            # Dispose old PowerShell instance
            if ($job.PowerShell) {
                $job.PowerShell.Dispose()
            }
            
            # Create new PowerShell instance
            $job.PowerShell = [PowerShell]::Create()
            $job.PowerShell.RunspacePool = $this.PoolManager.RunspacePool
            
            # Re-add script block and parameters
            [void]$job.PowerShell.AddScript($job.ScriptBlock)
            
            foreach ($param in $job.Parameters.GetEnumerator()) {
                [void]$job.PowerShell.AddParameter($param.Key, $param.Value)
            }
            
            [void]$job.PowerShell.AddParameter('SharedData', $this.SharedData)
            
            # Start execution
            $job.Handle = $job.PowerShell.BeginInvoke()
            $job.Status = 'Running'
            $job.Errors = @()
            $job.StartTime = [datetime]::Now  # Reset start time for retry
            
        } catch {
            Write-ParallelProcessorLog "Failed to retry job $($job.Id): $_" -Level Error -ProcessorId $this.ProcessorId -Component "JobScheduler"
            $job.Status = 'Failed'
            $job.Errors += $_
        }
    }
    
    # Cancel specific job
    [void]CancelJob([string]$jobId) {
        if ($this.Jobs.ContainsKey($jobId)) {
            $job = $this.Jobs[$jobId]
            
            if ($job.Status -eq 'Running') {
                Write-ParallelProcessorLog "Cancelling job: $jobId" -Level Debug -ProcessorId $this.ProcessorId -Component "JobScheduler"
                
                try {
                    $job.PowerShell.Stop()
                    $job.Status = 'Cancelled'
                    $job.EndTime = [datetime]::Now
                    
                    # Remove from running jobs list
                    $this.RunningJobs.Remove($job)
                } catch {
                    Write-ParallelProcessorLog "Error cancelling job $jobId : $_" -Level Warning -ProcessorId $this.ProcessorId -Component "JobScheduler"
                }
            }
        }
    }
    
    # Cancel all jobs
    [void]CancelAllJobs() {
        Write-ParallelProcessorLog "Cancelling all jobs (count: $($this.RunningJobs.Count))" -Level Debug -ProcessorId $this.ProcessorId -Component "JobScheduler"
        
        $jobsToCancel = $this.RunningJobs.ToArray()  # Create copy to avoid modification during iteration
        
        foreach ($job in $jobsToCancel) {
            $this.CancelJob($job.Id)
        }
        
        $this.RunningJobs.Clear()
        Write-ParallelProcessorLog "All jobs cancelled" -Level Debug -ProcessorId $this.ProcessorId -Component "JobScheduler"
    }
    
    # Get job status
    [hashtable]GetJobStatus([string]$jobId) {
        if (-not $this.Jobs.ContainsKey($jobId)) {
            return @{ Status = 'NotFound' }
        }
        
        $job = $this.Jobs[$jobId]
        return $job.GetSummary()
    }
    
    # Get all job statuses
    [hashtable[]]GetAllJobStatuses() {
        $statuses = @()
        foreach ($job in $this.Jobs.Values) {
            $statuses += $job.GetSummary()
        }
        return $statuses
    }
    
    # Cleanup completed jobs
    [void]CleanupCompletedJobs() {
        $jobsToRemove = @()
        
        foreach ($job in $this.Jobs.Values) {
            if ($job.Status -in @('Completed', 'Failed', 'Cancelled')) {
                $jobsToRemove += $job.Id
            }
        }
        
        foreach ($jobId in $jobsToRemove) {
            $removed = $null
            $this.Jobs.TryRemove($jobId, [ref]$removed)
        }
        
        if ($jobsToRemove.Count -gt 0) {
            Write-ParallelProcessorLog "Cleaned up $($jobsToRemove.Count) completed jobs" -Level Debug -ProcessorId $this.ProcessorId -Component "JobScheduler"
        }
    }
    
    # Dispose resources
    [void]Dispose() {
        Write-ParallelProcessorLog "Disposing JobScheduler" -Level Debug -ProcessorId $this.ProcessorId -Component "JobScheduler"
        
        # Cancel all running jobs
        $this.CancelAllJobs()
        
        # Dispose all PowerShell instances
        foreach ($job in $this.Jobs.Values) {
            if ($job.PowerShell) {
                $job.PowerShell.Dispose()
            }
        }
        
        # Dispose cancellation token
        if ($this.CancellationTokenSource) {
            $this.CancellationTokenSource.Dispose()
        }
        
        Write-ParallelProcessorLog "JobScheduler disposed" -Level Debug -ProcessorId $this.ProcessorId -Component "JobScheduler"
    }
}

#endregion

#region Helper Functions

function New-JobScheduler {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$PoolManager,
        
        [Parameter(Mandatory)]
        [string]$ProcessorId
    )
    
    Write-ParallelProcessorLog "Creating JobScheduler" -Level Debug -ProcessorId $ProcessorId -Component "JobScheduler"
    
    try {
        $scheduler = [JobScheduler]::new($PoolManager, $ProcessorId)
        Write-ParallelProcessorLog "JobScheduler created successfully" -Level Debug -ProcessorId $ProcessorId -Component "JobScheduler"
        return $scheduler
    } catch {
        Write-ParallelProcessorLog "Failed to create JobScheduler: $_" -Level Error -ProcessorId $ProcessorId -Component "JobScheduler"
        throw
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @('New-JobScheduler') -Variable @() -Alias @()
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC60h/aQ2TD204E
# zPtJA8hHUw/IspHyBaicdTaMWDY6g6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIH4YzCaNQCCaUMqLpKXdMBhx
# pmyEM2e+f5Qce7b9I4xmMA0GCSqGSIb3DQEBAQUABIIBAC59WogcdOpQyMWDXnDi
# d2t0HllGxcOiKYoVLzpiABuERDsUwA3eCMhXiI3U1Sw/cOuycnLNVsM4o+lEuhhc
# ajqf7Ea3U54dtcl/H929SDPUFNwGpBXx9r/JmC5DO+1wyclYCVx+q5FDs5tWDT3m
# 0as4DKhop2PQBnO6uqB6rdHVQkZIDuBbpRWS346Twnb+NEG2VtC38VvLaaBXQNdx
# Z7m+l5GHFomS5deATaJVQJQZp5d2c0Q28MZGkTYH8uMihQRtgaXgedcS7hHd55aq
# Om8ttwKM1N4BWNFNclYbXdAXdrkrLwoReDhT6Fek2rkR41QEerrBlPweSXoCGP0S
# xDE=
# SIG # End signature block
