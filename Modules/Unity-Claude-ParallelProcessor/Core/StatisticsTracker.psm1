# StatisticsTracker.psm1
# Performance statistics collection, monitoring, and reporting for parallel processing

using namespace System.Collections.Concurrent
using namespace System.Threading

Write-Debug "[StatisticsTracker] Module loaded - REFACTORED VERSION"

# Core functions are available from parent module import - no local import needed
# Import-Module "$PSScriptRoot\ParallelProcessorCore.psm1" -Force

#region Statistics Tracking Class

class StatisticsTracker {
    [hashtable]$Statistics
    [string]$ProcessorId
    [datetime]$CreatedAt
    [System.Collections.Generic.Queue[hashtable]]$ExecutionHistory
    [int]$MaxHistoryItems
    [System.Threading.ReaderWriterLockSlim]$StatisticsLock
    
    StatisticsTracker([string]$processorId) {
        Write-ParallelProcessorLog "Initializing StatisticsTracker" -Level Debug -ProcessorId $processorId -Component "StatisticsTracker"
        
        $this.ProcessorId = $processorId
        $this.CreatedAt = [datetime]::Now
        $this.MaxHistoryItems = 1000  # Keep last 1000 job records
        
        # Initialize thread-safe statistics
        $this.Statistics = [hashtable]::Synchronized(@{
            TotalJobsSubmitted = 0
            TotalJobsCompleted = 0
            TotalJobsFailed = 0
            TotalJobsRetried = 0
            TotalJobsCancelled = 0
            AverageExecutionTime = 0
            MinExecutionTime = [int]::MaxValue
            MaxExecutionTime = 0
            TotalExecutionTime = 0
            LastJobCompleted = [datetime]::MinValue
            LastJobFailed = [datetime]::MinValue
            CurrentThroughputPerSecond = 0
            PeakThroughputPerSecond = 0
            TotalBytesProcessed = 0
            ErrorRate = 0
            SuccessRate = 0
        })
        
        # Initialize execution history
        $this.ExecutionHistory = [System.Collections.Generic.Queue[hashtable]]::new()
        $this.StatisticsLock = [System.Threading.ReaderWriterLockSlim]::new()
        
        Write-ParallelProcessorLog "StatisticsTracker initialized" -Level Debug -ProcessorId $processorId -Component "StatisticsTracker"
    }
    
    # Record job submission
    [void]RecordJobSubmission() {
        $this.StatisticsLock.EnterWriteLock()
        try {
            $this.Statistics.TotalJobsSubmitted++
            Write-ParallelProcessorLog "Job submission recorded. Total: $($this.Statistics.TotalJobsSubmitted)" -Level Debug -ProcessorId $this.ProcessorId -Component "StatisticsTracker"
        } finally {
            $this.StatisticsLock.ExitWriteLock()
        }
    }
    
    # Record job completion
    [void]RecordJobCompletion([double]$executionTimeMs, [bool]$wasRetry = $false) {
        $this.StatisticsLock.EnterWriteLock()
        try {
            $this.Statistics.TotalJobsCompleted++
            $this.Statistics.LastJobCompleted = [datetime]::Now
            
            if ($wasRetry) {
                $this.Statistics.TotalJobsRetried++
            }
            
            # Update execution time statistics
            $this.UpdateExecutionTimeStatistics($executionTimeMs)
            
            # Add to execution history
            $this.AddExecutionRecord(@{
                Timestamp = [datetime]::Now
                ExecutionTime = $executionTimeMs
                Status = 'Completed'
                WasRetry = $wasRetry
            })
            
            # Update rates
            $this.UpdateRates()
            
            Write-ParallelProcessorLog "Job completion recorded. Execution time: $executionTimeMs ms" -Level Debug -ProcessorId $this.ProcessorId -Component "StatisticsTracker"
        } finally {
            $this.StatisticsLock.ExitWriteLock()
        }
    }
    
    # Record job failure
    [void]RecordJobFailure([double]$executionTimeMs, [string]$errorMessage = '') {
        $this.StatisticsLock.EnterWriteLock()
        try {
            $this.Statistics.TotalJobsFailed++
            $this.Statistics.LastJobFailed = [datetime]::Now
            
            # Add to execution history
            $this.AddExecutionRecord(@{
                Timestamp = [datetime]::Now
                ExecutionTime = $executionTimeMs
                Status = 'Failed'
                ErrorMessage = $errorMessage
                WasRetry = $false
            })
            
            # Update rates
            $this.UpdateRates()
            
            Write-ParallelProcessorLog "Job failure recorded. Error: $errorMessage" -Level Debug -ProcessorId $this.ProcessorId -Component "StatisticsTracker"
        } finally {
            $this.StatisticsLock.ExitWriteLock()
        }
    }
    
    # Record job cancellation
    [void]RecordJobCancellation() {
        $this.StatisticsLock.EnterWriteLock()
        try {
            $this.Statistics.TotalJobsCancelled++
            
            # Add to execution history
            $this.AddExecutionRecord(@{
                Timestamp = [datetime]::Now
                ExecutionTime = 0
                Status = 'Cancelled'
                WasRetry = $false
            })
            
            Write-ParallelProcessorLog "Job cancellation recorded" -Level Debug -ProcessorId $this.ProcessorId -Component "StatisticsTracker"
        } finally {
            $this.StatisticsLock.ExitWriteLock()
        }
    }
    
    # Update execution time statistics
    hidden [void]UpdateExecutionTimeStatistics([double]$executionTime) {
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
    
    # Add execution record to history
    hidden [void]AddExecutionRecord([hashtable]$record) {
        $this.ExecutionHistory.Enqueue($record)
        
        # Maintain history size limit
        while ($this.ExecutionHistory.Count -gt $this.MaxHistoryItems) {
            $this.ExecutionHistory.Dequeue() | Out-Null
        }
    }
    
    # Update success and error rates
    hidden [void]UpdateRates() {
        $totalProcessed = $this.Statistics.TotalJobsCompleted + $this.Statistics.TotalJobsFailed
        
        if ($totalProcessed -gt 0) {
            $this.Statistics.SuccessRate = [math]::Round(($this.Statistics.TotalJobsCompleted / $totalProcessed) * 100, 2)
            $this.Statistics.ErrorRate = [math]::Round(($this.Statistics.TotalJobsFailed / $totalProcessed) * 100, 2)
        } else {
            $this.Statistics.SuccessRate = 0
            $this.Statistics.ErrorRate = 0
        }
    }
    
    # Calculate current throughput (internal method - assumes lock is already held)
    [void]CalculateThroughputInternal() {
        $recentPeriodMinutes = 5  # Look at last 5 minutes
        $cutoffTime = [datetime]::Now.AddMinutes(-$recentPeriodMinutes)
        
        $recentJobs = $this.ExecutionHistory | Where-Object { $_.Timestamp -gt $cutoffTime }
        
        if ($recentJobs.Count -gt 0) {
            $throughputPerSecond = [math]::Round($recentJobs.Count / ($recentPeriodMinutes * 60), 2)
            $this.Statistics.CurrentThroughputPerSecond = $throughputPerSecond
            
            if ($throughputPerSecond -gt $this.Statistics.PeakThroughputPerSecond) {
                $this.Statistics.PeakThroughputPerSecond = $throughputPerSecond
            }
        }
    }
    
    # Calculate current throughput (external method - acquires its own lock)
    [void]CalculateThroughput() {
        $this.StatisticsLock.EnterReadLock()
        try {
            $this.CalculateThroughputInternal()
        } finally {
            $this.StatisticsLock.ExitReadLock()
        }
    }
    
    # Get current statistics
    [hashtable]GetStatistics() {
        $this.StatisticsLock.EnterReadLock()
        try {
            # Calculate throughput
            $this.CalculateThroughputInternal()
            
            # Create snapshot
            $stats = $this.Statistics.Clone()
            
            # Add computed fields
            $uptime = [datetime]::Now - $this.CreatedAt
            $stats.Uptime = $uptime
            $stats.UptimeString = "$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m $($uptime.Seconds)s"
            $stats.CreatedAt = $this.CreatedAt
            $stats.ProcessorId = $this.ProcessorId
            
            # Fix min execution time display
            if ($stats.MinExecutionTime -eq [int]::MaxValue) {
                $stats.MinExecutionTime = 0
            } else {
                $stats.MinExecutionTime = [math]::Round($stats.MinExecutionTime, 2)
            }
            $stats.MaxExecutionTime = [math]::Round($stats.MaxExecutionTime, 2)
            $stats.AverageExecutionTime = [math]::Round($stats.AverageExecutionTime, 2)
            
            return $stats
        } finally {
            $this.StatisticsLock.ExitReadLock()
        }
    }
    
    # Get performance summary
    [hashtable]GetPerformanceSummary() {
        $this.StatisticsLock.EnterReadLock()
        try {
            $stats = $this.GetStatistics()
            
            return @{
                ProcessorId = $this.ProcessorId
                Uptime = $stats.Uptime
                TotalJobs = $stats.TotalJobsSubmitted
                CompletedJobs = $stats.TotalJobsCompleted
                FailedJobs = $stats.TotalJobsFailed
                SuccessRate = "$($stats.SuccessRate)%"
                ErrorRate = "$($stats.ErrorRate)%"
                AverageExecutionTime = "$($stats.AverageExecutionTime) ms"
                CurrentThroughput = "$($stats.CurrentThroughputPerSecond) jobs/sec"
                PeakThroughput = "$($stats.PeakThroughputPerSecond) jobs/sec"
                IsHealthy = $stats.ErrorRate -lt 10  # Healthy if error rate < 10%
            }
        } finally {
            $this.StatisticsLock.ExitReadLock()
        }
    }
    
    # Get execution history for analysis
    [hashtable[]]GetExecutionHistory([int]$maxRecords = 100) {
        $this.StatisticsLock.EnterReadLock()
        try {
            $history = @()
            $records = $this.ExecutionHistory.ToArray()
            
            # Get most recent records
            $startIndex = [Math]::Max(0, $records.Length - $maxRecords)
            for ($i = $startIndex; $i -lt $records.Length; $i++) {
                $history += $records[$i]
            }
            
            return $history
        } finally {
            $this.StatisticsLock.ExitReadLock()
        }
    }
    
    # Reset statistics
    [void]ResetStatistics() {
        Write-ParallelProcessorLog "Resetting statistics" -Level Information -ProcessorId $this.ProcessorId -Component "StatisticsTracker"
        
        $this.StatisticsLock.EnterWriteLock()
        try {
            # Reset all counters
            $this.Statistics.TotalJobsSubmitted = 0
            $this.Statistics.TotalJobsCompleted = 0
            $this.Statistics.TotalJobsFailed = 0
            $this.Statistics.TotalJobsRetried = 0
            $this.Statistics.TotalJobsCancelled = 0
            $this.Statistics.AverageExecutionTime = 0
            $this.Statistics.MinExecutionTime = [int]::MaxValue
            $this.Statistics.MaxExecutionTime = 0
            $this.Statistics.TotalExecutionTime = 0
            $this.Statistics.CurrentThroughputPerSecond = 0
            $this.Statistics.PeakThroughputPerSecond = 0
            $this.Statistics.ErrorRate = 0
            $this.Statistics.SuccessRate = 0
            
            # Clear history
            $this.ExecutionHistory.Clear()
            
            # Reset creation time
            $this.CreatedAt = [datetime]::Now
            
        } finally {
            $this.StatisticsLock.ExitWriteLock()
        }
    }
    
    # Dispose resources
    [void]Dispose() {
        Write-ParallelProcessorLog "Disposing StatisticsTracker" -Level Debug -ProcessorId $this.ProcessorId -Component "StatisticsTracker"
        
        if ($this.StatisticsLock) {
            $this.StatisticsLock.Dispose()
        }
    }
}

#endregion

#region Helper Functions

function New-StatisticsTracker {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProcessorId
    )
    
    Write-ParallelProcessorLog "Creating StatisticsTracker" -Level Debug -ProcessorId $ProcessorId -Component "StatisticsTracker"
    
    try {
        $tracker = [StatisticsTracker]::new($ProcessorId)
        Write-ParallelProcessorLog "StatisticsTracker created successfully" -Level Debug -ProcessorId $ProcessorId -Component "StatisticsTracker"
        return $tracker
    } catch {
        Write-ParallelProcessorLog "Failed to create StatisticsTracker: $_" -Level Error -ProcessorId $ProcessorId -Component "StatisticsTracker"
        throw
    }
}

function Format-StatisticsReport {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [StatisticsTracker]$StatisticsTracker,
        
        [Parameter()]
        [ValidateSet('Summary', 'Detailed', 'Performance')]
        [string]$ReportType = 'Summary'
    )
    
    $stats = $StatisticsTracker.GetStatistics()
    
    switch ($ReportType) {
        'Summary' {
            return $StatisticsTracker.GetPerformanceSummary()
        }
        'Detailed' {
            return $stats
        }
        'Performance' {
            $perfStats = $StatisticsTracker.GetPerformanceSummary()
            $history = $StatisticsTracker.GetExecutionHistory(50)
            
            return @{
                Summary = $perfStats
                RecentHistory = $history
                TrendAnalysis = @{
                    AverageExecutionTimeTrend = if ($history.Count -gt 10) {
                        $recent = $history | Select-Object -Last 10
                        $older = $history | Select-Object -First 10
                        $recentAvg = ($recent | Measure-Object ExecutionTime -Average).Average
                        $olderAvg = ($older | Measure-Object ExecutionTime -Average).Average
                        if ($olderAvg -gt 0) { [math]::Round((($recentAvg - $olderAvg) / $olderAvg) * 100, 2) } else { 0 }
                    } else { 0 }
                }
            }
        }
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'New-StatisticsTracker',
    'Format-StatisticsReport'
) -Variable @() -Alias @()
# Added by Fix-ParallelProcessorExports
Export-ModuleMember -Function Format-StatisticsReport


# Added by Fix-ParallelProcessorExports
Export-ModuleMember -Function New-StatisticsTracker


# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBTxpHdUub+PA7l
# Lkqy2qTnyLN1I5gFHzD68afI/klaLaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKY3U+40C9371tBaO7GB+bE+
# MUFcOorU9EXVrmhB/cO5MA0GCSqGSIb3DQEBAQUABIIBABXTFW5CFvLNf2EyzFUJ
# 7kyxkT0LMjWcMYF2d9+BVrGJ1HCzFAaDvmlLUBFLmaL7iIjVON/8G82ISX8fKA1o
# SgGubn5u/5a28Ix41yLIoNyhdSrQKT/powxJ1yBYP0m5ydCU1ZaWwp+A8tthcs8+
# udfFS1SouHgsbYFqtvmMF2jIDD7+EizCumjaV4fFPImvRuN8n/fTYASMhL2BPR4E
# k4z4KcVOM+iJ5gMUbRzFF/Zpa1inC3HXEYO9svAuJEJKEc85Qp52q4Vh2y+v7mKX
# csyu8YC7Lm6VRi0YC88tPl2UAann1IAvpRFHqpFBNx+df0AJQ16sD/gs4HovCohN
# iKY=
# SIG # End signature block
