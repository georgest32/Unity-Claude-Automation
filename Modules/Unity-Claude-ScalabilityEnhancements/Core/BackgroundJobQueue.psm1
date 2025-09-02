# Unity-Claude-ScalabilityEnhancements - Background Job Queue Component
# Concurrent job queue management with prioritization and cancellation

using namespace System.Collections.Concurrent
using namespace System.Threading

#region Background Job Queue Management

class BackgroundJobQueue {
    [ConcurrentQueue[object]]$Queue
    [ConcurrentDictionary[string, object]]$Jobs
    [ConcurrentDictionary[string, object]]$Results
    [bool]$IsProcessing
    [int]$MaxConcurrentJobs
    [System.Threading.CancellationTokenSource]$CancellationTokenSource
    [System.Collections.Generic.List[System.Threading.Tasks.Task]]$RunningTasks
    
    BackgroundJobQueue([int]$maxConcurrentJobs) {
        $this.Queue = [ConcurrentQueue[object]]::new()
        $this.Jobs = [ConcurrentDictionary[string, object]]::new()
        $this.Results = [ConcurrentDictionary[string, object]]::new()
        $this.IsProcessing = $false
        $this.MaxConcurrentJobs = $maxConcurrentJobs
        $this.CancellationTokenSource = [System.Threading.CancellationTokenSource]::new()
        $this.RunningTasks = [System.Collections.Generic.List[System.Threading.Tasks.Task]]::new()
    }
    
    [string] AddJob([scriptblock]$jobScript, [hashtable]$parameters, [int]$priority) {
        $jobId = [guid]::NewGuid().ToString()
        $job = @{
            Id = $jobId
            Script = $jobScript
            Parameters = $parameters
            Priority = $priority
            Status = 'Queued'
            CreatedAt = [datetime]::Now
            StartedAt = $null
            CompletedAt = $null
        }
        
        $this.Jobs.TryAdd($jobId, $job) | Out-Null
        $this.Queue.Enqueue($job)
        
        return $jobId
    }
    
    [void] StartProcessing() {
        if ($this.IsProcessing) { return }
        
        $this.IsProcessing = $true
        $token = $this.CancellationTokenSource.Token
        
        $task = [System.Threading.Tasks.Task]::Run({
            while (-not $token.IsCancellationRequested -and $this.IsProcessing) {
                $this.ProcessJobs()
                Start-Sleep -Milliseconds 100
            }
        })
        
        $this.RunningTasks.Add($task)
    }
    
    [void] ProcessJobs() {
        $runningJobsCount = ($this.Jobs.Values | Where-Object { $_.Status -eq 'Running' }).Count
        
        while ($runningJobsCount -lt $this.MaxConcurrentJobs) {
            $job = $null
            if (-not $this.Queue.TryDequeue([ref]$job)) {
                break
            }
            
            $job.Status = 'Running'
            $job.StartedAt = [datetime]::Now
            $this.Jobs.TryUpdate($job.Id, $job, $job) | Out-Null
            
            $this.ExecuteJob($job)
            $runningJobsCount++
        }
    }
    
    [void] ExecuteJob([object]$job) {
        $jobTask = [System.Threading.Tasks.Task]::Run({
            try {
                $result = if ($job.Parameters) {
                    & $job.Script @($job.Parameters)
                } else {
                    & $job.Script
                }
                
                $jobResult = @{
                    JobId = $job.Id
                    Result = $result
                    Status = 'Completed'
                    CompletedAt = [datetime]::Now
                    Error = $null
                }
            }
            catch {
                $jobResult = @{
                    JobId = $job.Id
                    Result = $null
                    Status = 'Failed'
                    CompletedAt = [datetime]::Now
                    Error = $_.Exception.Message
                }
            }
            
            $this.Results.TryAdd($job.Id, $jobResult) | Out-Null
            $job.Status = $jobResult.Status
            $job.CompletedAt = $jobResult.CompletedAt
            $this.Jobs.TryUpdate($job.Id, $job, $job) | Out-Null
        })
        
        $this.RunningTasks.Add($jobTask)
    }
    
    [void] StopProcessing() {
        $this.IsProcessing = $false
        $this.CancellationTokenSource.Cancel()
        
        # Wait for all tasks to complete
        foreach ($task in $this.RunningTasks) {
            try {
                $task.Wait(5000)  # 5 second timeout
            }
            catch {
                # Task was cancelled or timed out
            }
        }
        
        $this.RunningTasks.Clear()
    }
    
    [hashtable] GetQueueStatus() {
        $queuedJobs = ($this.Jobs.Values | Where-Object { $_.Status -eq 'Queued' }).Count
        $runningJobs = ($this.Jobs.Values | Where-Object { $_.Status -eq 'Running' }).Count
        $completedJobs = ($this.Jobs.Values | Where-Object { $_.Status -eq 'Completed' }).Count
        $failedJobs = ($this.Jobs.Values | Where-Object { $_.Status -eq 'Failed' }).Count
        
        return @{
            QueuedJobs = $queuedJobs
            RunningJobs = $runningJobs
            CompletedJobs = $completedJobs
            FailedJobs = $failedJobs
            TotalJobs = $this.Jobs.Count
            IsProcessing = $this.IsProcessing
            MaxConcurrentJobs = $this.MaxConcurrentJobs
        }
    }
}

function New-BackgroundJobQueue {
    [CmdletBinding()]
    param(
        [int]$MaxConcurrentJobs = 10
    )
    
    try {
        $queue = [BackgroundJobQueue]::new($MaxConcurrentJobs)
        return $queue
    }
    catch {
        Write-Error "Failed to create background job queue: $_"
        return $null
    }
}

function Add-JobToQueue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$JobQueue,
        
        [Parameter(Mandatory=$true)]
        [scriptblock]$JobScript,
        
        [hashtable]$Parameters = @{},
        
        [int]$Priority = 5
    )
    
    try {
        $jobId = $JobQueue.AddJob($JobScript, $Parameters, $Priority)
        
        return @{
            JobId = $jobId
            Status = 'Queued'
            Success = $true
        }
    }
    catch {
        Write-Error "Failed to add job to queue: $_"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Start-QueueProcessor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$JobQueue
    )
    
    try {
        $JobQueue.StartProcessing()
        return @{ Success = $true; Message = "Queue processing started" }
    }
    catch {
        Write-Error "Failed to start queue processor: $_"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Stop-QueueProcessor {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$JobQueue
    )
    
    try {
        $JobQueue.StopProcessing()
        return @{ Success = $true; Message = "Queue processing stopped" }
    }
    catch {
        Write-Error "Failed to stop queue processor: $_"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Get-QueueStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$JobQueue
    )
    
    try {
        $status = $JobQueue.GetQueueStatus()
        return $status
    }
    catch {
        Write-Error "Failed to get queue status: $_"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Get-JobResults {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$JobQueue,
        
        [string]$JobId
    )
    
    try {
        if ($JobId) {
            $result = $null
            if ($JobQueue.Results.TryGetValue($JobId, [ref]$result)) {
                return $result
            } else {
                return @{ Success = $false; Error = "Job not found or not completed" }
            }
        } else {
            return $JobQueue.Results.Values
        }
    }
    catch {
        Write-Error "Failed to get job results: $_"
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Remove-CompletedJobs {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$JobQueue,
        
        [switch]$KeepResults
    )
    
    $removedCount = 0
    $completedJobs = $JobQueue.Jobs.Values | Where-Object { $_.Status -eq 'Completed' -or $_.Status -eq 'Failed' }
    
    foreach ($job in $completedJobs) {
        $JobQueue.Jobs.TryRemove($job.Id, [ref]$null) | Out-Null
        if (-not $KeepResults) {
            $JobQueue.Results.TryRemove($job.Id, [ref]$null) | Out-Null
        }
        $removedCount++
    }
    
    return @{
        RemovedJobs = $removedCount
        ResultsKept = $KeepResults.IsPresent
        Success = $true
    }
}

function Invoke-JobPriorityUpdate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]$JobQueue,
        
        [Parameter(Mandatory=$true)]
        [string]$JobId,
        
        [Parameter(Mandatory=$true)]
        [int]$NewPriority
    )
    
    $job = $null
    if ($JobQueue.Jobs.TryGetValue($JobId, [ref]$job)) {
        $job.Priority = $NewPriority
        $JobQueue.Jobs.TryUpdate($JobId, $job, $job) | Out-Null
        
        return @{
            JobId = $JobId
            NewPriority = $NewPriority
            Success = $true
        }
    } else {
        return @{ Success = $false; Error = "Job not found" }
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'New-BackgroundJobQueue',
    'Add-JobToQueue',
    'Start-QueueProcessor',
    'Stop-QueueProcessor',
    'Get-QueueStatus',
    'Get-JobResults',
    'Remove-CompletedJobs',
    'Invoke-JobPriorityUpdate'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBgyg642BYxwtRF
# vGlY/opduKFSBTUP6T5kOrpRHj7BNKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIO6irX3Ag0w+dBWl9bu6Pm+t
# 3Cdil/6wyYYmV/sbaqXeMA0GCSqGSIb3DQEBAQUABIIBAKQJnD0yT9lcX313yyv5
# PnO3GB2UnnY4aA6vHWiLYGav0aRU5bBX7q0bbuubft+sO6Xt0Ivp1re8e5IzU+DJ
# boHehWR7JQY2wTFuB2xIYRGA/xc2lFkeiZqT2WFtKC69zElsRACxiYBslwPI5raA
# h4f7lnEBH8rzkUyKPWY/nZXriNB18OVad1Rm9txBF+IpdoQh4RtaYmkAp0uzuOso
# 3Kzo5uu0G1CYCv2KrE+sFkSMady1fD2EDUw0g1S4wla1G7/ScA5YLom9/CKIVJdB
# 03SFa1Reg0xDybRlU9Z0uW+l5PTrCwXye52mG1fhLIUT/hlWwLTJiNLmyvet/o/r
# Wco=
# SIG # End signature block
