# Unity-Claude-IntegratedWorkflow Performance Optimization Component
# Performance optimization and throttling functions
# Part of refactored IntegratedWorkflow module

$ErrorActionPreference = "Stop"

# Import core component
$CorePath = Join-Path $PSScriptRoot "WorkflowCore.psm1"
Import-Module $CorePath -Force

<#
.SYNOPSIS
Creates an adaptive throttling system for integrated workflow performance optimization
.DESCRIPTION
Monitors system resources and automatically adjusts concurrent operations for optimal performance
#>
function Initialize-AdaptiveThrottling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$IntegratedWorkflow,
        [switch]$EnableCPUThrottling,
        [switch]$EnableMemoryThrottling,
        [int]$CPUThreshold = 80,
        [int]$MemoryThreshold = 85
    )
    
    $workflowName = $IntegratedWorkflow.WorkflowName
    Write-IntegratedWorkflowLog -Message "Initializing adaptive throttling for workflow '$workflowName' (CPU: $CPUThreshold%, Memory: $MemoryThreshold%)..." -Level "INFO"
    
    try {
        # Create adaptive throttling configuration
        $throttlingConfig = @{
            EnableCPUThrottling = $EnableCPUThrottling
            EnableMemoryThrottling = $EnableMemoryThrottling
            CPUThreshold = $CPUThreshold
            MemoryThreshold = $MemoryThreshold
            LastResourceCheck = Get-Date
            ResourceCheckInterval = 5  # seconds
            
            # Throttling state
            CurrentCPUUsage = 0
            CurrentMemoryUsage = 0
            ThrottlingActive = $false
            ThrottlingHistory = [System.Collections.ArrayList]::Synchronized(@())
            
            # Performance counters for monitoring
            PerformanceCounters = @{
                CPU = if (Get-Command Get-Counter -ErrorAction SilentlyContinue) { 
                    @{
                        Available = $true
                        CounterPath = '\Processor(_Total)\% Processor Time'
                    }
                } else { 
                    @{Available = $false} 
                }
                Memory = if (Get-Command Get-Counter -ErrorAction SilentlyContinue) { 
                    @{
                        Available = $true
                        CounterPath = '\Memory\Available MBytes'
                        TotalMemoryMB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1MB, 0)
                    }
                } else { 
                    @{Available = $false} 
                }
            }
            
            # Adaptive adjustments
            AdaptiveAdjustments = @{
                UnityMaxProjects = $IntegratedWorkflow.MaxUnityProjects
                ClaudeMaxSubmissions = $IntegratedWorkflow.MaxClaudeSubmissions
                OriginalUnityMax = $IntegratedWorkflow.MaxUnityProjects
                OriginalClaudeMax = $IntegratedWorkflow.MaxClaudeSubmissions
            }
        }
        
        # Add throttling config to workflow state
        $IntegratedWorkflow.WorkflowState.AdaptiveThrottling = $throttlingConfig
        
        Write-IntegratedWorkflowLog -Message "Adaptive throttling initialized for workflow '$workflowName'" -Level "DEBUG"
        Write-IntegratedWorkflowLog -Message "Performance counters available - CPU: $($throttlingConfig.PerformanceCounters.CPU.Available), Memory: $($throttlingConfig.PerformanceCounters.Memory.Available)" -Level "DEBUG"
        
        return @{
            Success = $true
            Message = "Adaptive throttling initialized successfully"
            Configuration = $throttlingConfig
        }
        
    } catch {
        Write-IntegratedWorkflowLog -Message "Failed to initialize adaptive throttling: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Updates adaptive throttling based on current system resource usage
.DESCRIPTION
Monitors CPU and memory usage and adjusts workflow concurrency settings
#>
function Update-AdaptiveThrottling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$IntegratedWorkflow
    )
    
    try {
        if (-not $IntegratedWorkflow.WorkflowState.ContainsKey('AdaptiveThrottling')) {
            Write-IntegratedWorkflowLog -Message "Adaptive throttling not initialized - skipping update" -Level "DEBUG"
            return $false
        }
        
        $throttlingConfig = $IntegratedWorkflow.WorkflowState.AdaptiveThrottling
        $currentTime = Get-Date
        
        # Check if it's time for resource monitoring
        if (($currentTime - $throttlingConfig.LastResourceCheck).TotalSeconds -lt $throttlingConfig.ResourceCheckInterval) {
            return $false  # Not time for update yet
        }
        
        $workflowName = $IntegratedWorkflow.WorkflowName
        Write-IntegratedWorkflowLog -Message "Updating adaptive throttling for workflow '$workflowName'..." -Level "DEBUG"
        
        $resourceSnapshot = @{
            Timestamp = $currentTime
            CPU = 0
            Memory = 0
            ThrottlingApplied = $false
            Adjustments = @{}
        }
        
        # Get current CPU usage
        if ($throttlingConfig.EnableCPUThrottling -and $throttlingConfig.PerformanceCounters.CPU.Available) {
            try {
                $cpuCounter = Get-Counter $throttlingConfig.PerformanceCounters.CPU.CounterPath -SampleInterval 1 -MaxSamples 1 -ErrorAction Stop
                $throttlingConfig.CurrentCPUUsage = [math]::Round($cpuCounter.CounterSamples[0].CookedValue, 2)
                $resourceSnapshot.CPU = $throttlingConfig.CurrentCPUUsage
                
                Write-IntegratedWorkflowLog -Message "Current CPU usage: $($throttlingConfig.CurrentCPUUsage)%" -Level "DEBUG"
            } catch {
                Write-IntegratedWorkflowLog -Message "Failed to get CPU usage: $($_.Exception.Message)" -Level "WARNING"
            }
        }
        
        # Get current memory usage
        if ($throttlingConfig.EnableMemoryThrottling -and $throttlingConfig.PerformanceCounters.Memory.Available) {
            try {
                $memoryCounter = Get-Counter $throttlingConfig.PerformanceCounters.Memory.CounterPath -SampleInterval 1 -MaxSamples 1 -ErrorAction Stop
                $availableMemoryMB = $memoryCounter.CounterSamples[0].CookedValue
                $totalMemoryMB = $throttlingConfig.PerformanceCounters.Memory.TotalMemoryMB
                $throttlingConfig.CurrentMemoryUsage = [math]::Round((($totalMemoryMB - $availableMemoryMB) / $totalMemoryMB) * 100, 2)
                $resourceSnapshot.Memory = $throttlingConfig.CurrentMemoryUsage
                
                Write-IntegratedWorkflowLog -Message "Current memory usage: $($throttlingConfig.CurrentMemoryUsage)%" -Level "DEBUG"
            } catch {
                Write-IntegratedWorkflowLog -Message "Failed to get memory usage: $($_.Exception.Message)" -Level "WARNING"
            }
        }
        
        # Apply throttling based on resource usage
        $applyThrottling = $false
        $throttleReason = @()
        
        if ($throttlingConfig.EnableCPUThrottling -and $throttlingConfig.CurrentCPUUsage -gt $throttlingConfig.CPUThreshold) {
            $applyThrottling = $true
            $throttleReason += "CPU: $($throttlingConfig.CurrentCPUUsage)% > $($throttlingConfig.CPUThreshold)%"
        }
        
        if ($throttlingConfig.EnableMemoryThrottling -and $throttlingConfig.CurrentMemoryUsage -gt $throttlingConfig.MemoryThreshold) {
            $applyThrottling = $true
            $throttleReason += "Memory: $($throttlingConfig.CurrentMemoryUsage)% > $($throttlingConfig.MemoryThreshold)%"
        }
        
        # Update concurrency settings
        if ($applyThrottling -and -not $throttlingConfig.ThrottlingActive) {
            Write-IntegratedWorkflowLog -Message "Applying throttling due to: $($throttleReason -join ', ')" -Level "WARNING"
            
            # Reduce concurrency by 50%
            $throttlingConfig.AdaptiveAdjustments.UnityMaxProjects = [math]::Max(1, [math]::Floor($IntegratedWorkflow.MaxUnityProjects / 2))
            $throttlingConfig.AdaptiveAdjustments.ClaudeMaxSubmissions = [math]::Max(1, [math]::Floor($IntegratedWorkflow.MaxClaudeSubmissions / 2))
            
            $throttlingConfig.ThrottlingActive = $true
            $resourceSnapshot.ThrottlingApplied = $true
            $resourceSnapshot.Adjustments = @{
                UnityMax = $throttlingConfig.AdaptiveAdjustments.UnityMaxProjects
                ClaudeMax = $throttlingConfig.AdaptiveAdjustments.ClaudeMaxSubmissions
            }
            
            Write-IntegratedWorkflowLog -Message "Throttling applied - Unity: $($throttlingConfig.AdaptiveAdjustments.UnityMaxProjects), Claude: $($throttlingConfig.AdaptiveAdjustments.ClaudeMaxSubmissions)" -Level "INFO"
            
        } elseif (-not $applyThrottling -and $throttlingConfig.ThrottlingActive) {
            Write-IntegratedWorkflowLog -Message "Removing throttling - resources within acceptable limits" -Level "INFO"
            
            # Restore original concurrency
            $throttlingConfig.AdaptiveAdjustments.UnityMaxProjects = $throttlingConfig.AdaptiveAdjustments.OriginalUnityMax
            $throttlingConfig.AdaptiveAdjustments.ClaudeMaxSubmissions = $throttlingConfig.AdaptiveAdjustments.OriginalClaudeMax
            
            $throttlingConfig.ThrottlingActive = $false
            $resourceSnapshot.ThrottlingApplied = $false
            $resourceSnapshot.Adjustments = @{
                UnityMax = $throttlingConfig.AdaptiveAdjustments.UnityMaxProjects
                ClaudeMax = $throttlingConfig.AdaptiveAdjustments.ClaudeMaxSubmissions
            }
            
            Write-IntegratedWorkflowLog -Message "Throttling removed - Unity: $($throttlingConfig.AdaptiveAdjustments.UnityMaxProjects), Claude: $($throttlingConfig.AdaptiveAdjustments.ClaudeMaxSubmissions)" -Level "INFO"
        }
        
        # Record history
        $throttlingConfig.ThrottlingHistory.Add($resourceSnapshot)
        
        # Trim history to last 100 entries
        if ($throttlingConfig.ThrottlingHistory.Count -gt 100) {
            $throttlingConfig.ThrottlingHistory.RemoveRange(0, $throttlingConfig.ThrottlingHistory.Count - 100)
        }
        
        $throttlingConfig.LastResourceCheck = $currentTime
        
        return $resourceSnapshot.ThrottlingApplied
        
    } catch {
        Write-IntegratedWorkflowLog -Message "Failed to update adaptive throttling: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

<#
.SYNOPSIS
Creates intelligent job batching for optimized processing
.DESCRIPTION
Analyzes jobs and creates optimized batches based on various strategies
#>
function New-IntelligentJobBatching {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$IntegratedWorkflow,
        [Parameter(Mandatory)]
        [array]$JobQueue,
        [ValidateSet('BySize', 'ByType', 'ByPriority', 'Hybrid')]
        [string]$BatchingStrategy = 'Hybrid',
        [int]$MaxBatchSize = 10
    )
    
    $workflowName = $IntegratedWorkflow.WorkflowName
    Write-IntegratedWorkflowLog -Message "Creating intelligent job batching for workflow '$workflowName' with $($JobQueue.Count) jobs using $BatchingStrategy strategy..." -Level "INFO"
    
    try {
        if ($JobQueue.Count -eq 0) {
            Write-IntegratedWorkflowLog -Message "No jobs to batch - returning empty result" -Level "DEBUG"
            return @{
                Batches = @()
                BatchingStrategy = $BatchingStrategy
                TotalJobs = 0
                TotalBatches = 0
            }
        }
        
        $batchingStartTime = Get-Date
        $batches = @()
        
        # Analyze job characteristics
        $jobAnalysis = @{
            TotalJobs = $JobQueue.Count
            JobTypes = @{}
            JobSizes = @()
            JobPriorities = @{}
            AverageJobSize = 0
        }
        
        foreach ($job in $JobQueue) {
            # Analyze job type
            $jobType = if ($job.ContainsKey('Type')) { $job.Type } else { 'Unknown' }
            if (-not $jobAnalysis.JobTypes.ContainsKey($jobType)) {
                $jobAnalysis.JobTypes[$jobType] = 0
            }
            $jobAnalysis.JobTypes[$jobType]++
            
            # Analyze job size (estimated processing time or complexity)
            $jobSize = if ($job.ContainsKey('EstimatedDuration')) { 
                $job.EstimatedDuration 
            } elseif ($job.ContainsKey('Complexity')) { 
                $job.Complexity 
            } else { 
                1  # Default size
            }
            $jobAnalysis.JobSizes += $jobSize
            
            # Analyze job priority
            $jobPriority = if ($job.ContainsKey('Priority')) { $job.Priority } else { 'Normal' }
            if (-not $jobAnalysis.JobPriorities.ContainsKey($jobPriority)) {
                $jobAnalysis.JobPriorities[$jobPriority] = 0
            }
            $jobAnalysis.JobPriorities[$jobPriority]++
        }
        
        $jobAnalysis.AverageJobSize = if ($jobAnalysis.JobSizes.Count -gt 0) { 
            ($jobAnalysis.JobSizes | Measure-Object -Average).Average 
        } else { 
            1 
        }
        
        Write-IntegratedWorkflowLog -Message "Job analysis: Types: $($jobAnalysis.JobTypes.Count), Avg Size: $($jobAnalysis.AverageJobSize), Priorities: $($jobAnalysis.JobPriorities.Count)" -Level "DEBUG"
        
        # Create batches based on strategy
        $batches = Get-BatchesByStrategy -JobQueue $JobQueue -BatchingStrategy $BatchingStrategy -MaxBatchSize $MaxBatchSize -JobAnalysis $jobAnalysis
        
        $batchingDuration = ((Get-Date) - $batchingStartTime).TotalMilliseconds
        
        $batchingSummary = @{
            Batches = $batches
            BatchingStrategy = $BatchingStrategy
            TotalJobs = $JobQueue.Count
            TotalBatches = $batches.Count
            AverageJobsPerBatch = if ($batches.Count -gt 0) { [math]::Round($JobQueue.Count / $batches.Count, 2) } else { 0 }
            JobAnalysis = $jobAnalysis
            BatchingDuration = $batchingDuration
        }
        
        Write-IntegratedWorkflowLog -Message "Intelligent job batching completed: $($batches.Count) batches created for $($JobQueue.Count) jobs in ${batchingDuration}ms" -Level "INFO"
        Write-IntegratedWorkflowLog -Message "Batching efficiency: $($batchingSummary.AverageJobsPerBatch) jobs per batch (max: $MaxBatchSize)" -Level "DEBUG"
        
        return $batchingSummary
        
    } catch {
        Write-IntegratedWorkflowLog -Message "Failed to create intelligent job batching: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
}

# Helper function to create batches by strategy
function Get-BatchesByStrategy {
    param(
        [array]$JobQueue,
        [string]$BatchingStrategy,
        [int]$MaxBatchSize,
        [hashtable]$JobAnalysis
    )
    
    $batches = @()
    
    switch ($BatchingStrategy) {
        'Hybrid' {
            # Hybrid approach: prioritize high-priority jobs, then balance by size and type
            $highPriorityJobs = @($JobQueue | Where-Object { 
                $_.ContainsKey('Priority') -and $_.Priority -in @('High', 'Critical', 'Urgent') 
            })
            $normalJobs = @($JobQueue | Where-Object { 
                -not $_.ContainsKey('Priority') -or $_.Priority -notin @('High', 'Critical', 'Urgent') 
            })
            
            # Create high-priority batches first
            if ($highPriorityJobs.Count -gt 0) {
                for ($i = 0; $i -lt $highPriorityJobs.Count; $i += $MaxBatchSize) {
                    $batchJobs = $highPriorityJobs[$i..[math]::Min($i + $MaxBatchSize - 1, $highPriorityJobs.Count - 1)]
                    
                    $batches += @{
                        BatchId = "HybridPriority-$([math]::Floor($i / $MaxBatchSize) + 1)"
                        Jobs = $batchJobs
                        JobCount = $batchJobs.Count
                        BatchType = "HighPriority"
                    }
                }
            }
            
            # Create balanced batches for normal jobs
            if ($normalJobs.Count -gt 0) {
                # Group by type, then create size-balanced batches within types
                $typeGroups = $normalJobs | Group-Object { 
                    if ($_.ContainsKey('Type')) { $_.Type } else { 'Normal' }
                }
                
                foreach ($group in $typeGroups) {
                    $groupJobs = @($group.Group | Sort-Object { 
                        if ($_.ContainsKey('EstimatedDuration')) { $_.EstimatedDuration }
                        elseif ($_.ContainsKey('Complexity')) { $_.Complexity }
                        else { 1 }
                    })
                    
                    for ($i = 0; $i -lt $groupJobs.Count; $i += $MaxBatchSize) {
                        $batchJobs = $groupJobs[$i..[math]::Min($i + $MaxBatchSize - 1, $groupJobs.Count - 1)]
                        
                        $batches += @{
                            BatchId = "HybridType-$($group.Name)-$([math]::Floor($i / $MaxBatchSize) + 1)"
                            Jobs = $batchJobs
                            JobCount = $batchJobs.Count
                            BatchType = "TypeBalanced"
                            JobType = $group.Name
                        }
                    }
                }
            }
        }
        
        default {
            # Simple batching for other strategies (simplified for brevity)
            for ($i = 0; $i -lt $JobQueue.Count; $i += $MaxBatchSize) {
                $batchJobs = $JobQueue[$i..[math]::Min($i + $MaxBatchSize - 1, $JobQueue.Count - 1)]
                
                $batches += @{
                    BatchId = "$BatchingStrategy-$([math]::Floor($i / $MaxBatchSize) + 1)"
                    Jobs = $batchJobs
                    JobCount = $batchJobs.Count
                }
            }
        }
    }
    
    return $batches
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-AdaptiveThrottling',
    'Update-AdaptiveThrottling',
    'New-IntelligentJobBatching',
    'Get-BatchesByStrategy'
)

Write-IntegratedWorkflowLog -Message "PerformanceOptimization component loaded successfully" -Level "DEBUG"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBMG3Nut5cwbEh1
# 1rjQ8suQTGwy1BrdQuvO4drPTNXa0qCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPAFZcTPj8+8LXaYmnZdZSpy
# duNz0VOx/zvtwq+//zTQMA0GCSqGSIb3DQEBAQUABIIBAEHkfQZqxeqBg9rMv+ii
# pxxsBfR7yJ9qyYIpNhCop1w3zz2NPvr+ylvoqkIsNjtpCfbewSNT8ukBBUW3eiGZ
# pb2dW1QlJB7BIk0gkFVk58iLJx7CXmmB+ytmDr14CnG7EtEz0PXroJW5D/5hHKDL
# V/vZspUsIQQJC+C9Bc9mrtdPx/Vp9AcEWJTDLrCIr7UQPFybmQm9nshBq3b2K2bj
# t1Ziup9OqqTRRSshSiANLt0DIdjku+t2OGtV4Qh54kQ82TVxwFXG0eIsS3t4KFMj
# zPFfZRevSUlsRiDrqMKYusubLFzYmnWU4JJzmntDbtyXudNw3rUDzRO82ccnAsSg
# uCU=
# SIG # End signature block
