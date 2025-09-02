# PerformanceMonitoring.psm1
# Performance metrics monitoring and analysis

using namespace System.Threading
using namespace System.Collections.Generic

# Update performance metrics
function Update-PerformanceMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Metrics,
        
        [Parameter(Mandatory)]
        [datetime]$StartTime,
        
        [Parameter(Mandatory)]
        [int]$FilesProcessed,
        
        [object]$CacheManager,
        
        [System.Collections.Concurrent.ConcurrentQueue[PSCustomObject]]$ProcessingQueue
    )
    
    $now = [datetime]::Now
    $elapsedMinutes = ($now - $StartTime).TotalMinutes
    
    # Calculate files per second
    $filesPerSecond = if ($elapsedMinutes -gt 0) { 
        $FilesProcessed / ($elapsedMinutes * 60) 
    } else { 0 }
    
    # Update metrics
    $Metrics.TotalFilesProcessed = $FilesProcessed
    $Metrics.FilesPerSecond = [Math]::Round($filesPerSecond, 2)
    $Metrics.QueueLength = if ($ProcessingQueue) { $ProcessingQueue.Count } else { 0 }
    $Metrics.LastUpdate = $now
    
    # Add to throughput history
    $Metrics.ThroughputHistory.Add($filesPerSecond)
    if ($Metrics.ThroughputHistory.Count -gt 100) {
        $Metrics.ThroughputHistory.RemoveAt(0)
    }
    
    # Update cache hit rate
    if ($CacheManager) {
        $cacheStats = $CacheManager.GetStatistics()
        $Metrics.CacheHitRate = if ($cacheStats.TotalGets -gt 0) {
            [Math]::Round(($cacheStats.Hits / $cacheStats.TotalGets) * 100, 2)
        } else { 0 }
    }
    
    # Update memory usage
    $Metrics.MemoryUsage = [Math]::Round([GC]::GetTotalMemory($false) / 1MB, 2)
    
    Write-Debug "[PerformanceMonitoring] Metrics updated: $filesPerSecond files/sec, Queue: $($Metrics.QueueLength)"
    
    return $filesPerSecond
}

# Analyze performance bottlenecks
function Get-PerformanceBottlenecks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Metrics,
        
        [int]$QueueBacklogThreshold = 100,
        [int]$CacheHitRateThreshold = 70,
        [int]$MemoryThresholdMB = 1000
    )
    
    $bottlenecks = @{}
    
    # Analyze queue length
    if ($Metrics.QueueLength -gt $QueueBacklogThreshold) {
        $bottlenecks.QueueBacklog = "Processing queue has $($Metrics.QueueLength) items (threshold: $QueueBacklogThreshold)"
    }
    
    # Analyze cache performance
    if ($Metrics.CacheHitRate -lt $CacheHitRateThreshold) {
        $bottlenecks.CacheEfficiency = "Cache hit rate is $($Metrics.CacheHitRate)% (target >$CacheHitRateThreshold%)"
    }
    
    # Analyze memory usage
    if ($Metrics.MemoryUsage -gt $MemoryThresholdMB) {
        $bottlenecks.MemoryPressure = "Memory usage is $($Metrics.MemoryUsage) MB (threshold: $MemoryThresholdMB MB)"
    }
    
    # Analyze throughput trend
    if ($Metrics.ThroughputHistory.Count -ge 10) {
        $recentThroughput = $Metrics.ThroughputHistory[-10..-1]
        $avgRecent = ($recentThroughput | Measure-Object -Average).Average
        $avgOverall = ($Metrics.ThroughputHistory | Measure-Object -Average).Average
        
        if ($avgRecent -lt ($avgOverall * 0.8)) {
            $bottlenecks.ThroughputDegradation = "Recent throughput ($([Math]::Round($avgRecent, 2)) files/sec) is below average ($([Math]::Round($avgOverall, 2)) files/sec)"
        }
    }
    
    if ($bottlenecks.Count -gt 0) {
        Write-Warning "[PerformanceMonitoring] Bottlenecks detected: $($bottlenecks.Keys -join ', ')"
    }
    
    return $bottlenecks
}

# Create performance timer
function New-PerformanceTimer {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Callback,
        
        [Parameter(Mandatory)]
        [object]$State,
        
        [int]$IntervalSeconds = 30
    )
    
    $intervalMs = $IntervalSeconds * 1000
    
    $timer = [System.Threading.Timer]::new($Callback, $State, $intervalMs, $intervalMs)
    
    Write-Verbose "[PerformanceMonitoring] Performance timer created with interval: $IntervalSeconds seconds"
    return $timer
}

# Get throughput analysis report
function Get-ThroughputAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Metrics,
        
        [Parameter(Mandatory)]
        [int]$TargetThroughput,
        
        [Parameter(Mandatory)]
        [datetime]$StartTime
    )
    
    $history = $Metrics.ThroughputHistory
    
    $report = [PSCustomObject]@{
        CurrentThroughput = $Metrics.FilesPerSecond
        TargetThroughput = $TargetThroughput
        PerformanceRatio = if ($TargetThroughput -gt 0) { 
            [Math]::Round(($Metrics.FilesPerSecond / $TargetThroughput) * 100, 2) 
        } else { 0 }
        AverageThroughput = if ($history.Count -gt 0) { 
            [Math]::Round(($history | Measure-Object -Average).Average, 2) 
        } else { 0 }
        PeakThroughput = if ($history.Count -gt 0) { 
            [Math]::Round(($history | Measure-Object -Maximum).Maximum, 2) 
        } else { 0 }
        MinimumThroughput = if ($history.Count -gt 0) { 
            [Math]::Round(($history | Measure-Object -Minimum).Minimum, 2) 
        } else { 0 }
        TotalFilesProcessed = $Metrics.TotalFilesProcessed
        CacheHitRate = $Metrics.CacheHitRate
        ProcessingErrors = $Metrics.ProcessingErrors
        QueueLength = $Metrics.QueueLength
        MemoryUsageMB = $Metrics.MemoryUsage
        Bottlenecks = $Metrics.BottleneckAnalysis
        UpTime = [datetime]::Now - $StartTime
        MeetingTarget = ($Metrics.FilesPerSecond -ge $TargetThroughput)
    }
    
    return $report
}

# Check if performance optimization is needed
function Test-PerformanceOptimizationNeeded {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [decimal]$CurrentThroughput,
        
        [Parameter(Mandatory)]
        [int]$TargetThroughput,
        
        [decimal]$ThresholdPercentage = 0.8
    )
    
    $threshold = $TargetThroughput * $ThresholdPercentage
    $needsOptimization = $CurrentThroughput -lt $threshold
    
    if ($needsOptimization) {
        Write-Warning "[PerformanceMonitoring] Performance below threshold: $CurrentThroughput < $threshold files/sec"
    }
    
    return $needsOptimization
}

# Generate performance recommendations
function Get-PerformanceRecommendations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Bottlenecks,
        
        [Parameter(Mandatory)]
        [hashtable]$Metrics
    )
    
    $recommendations = @()
    
    if ($Bottlenecks.ContainsKey('QueueBacklog')) {
        $recommendations += "Increase batch size or add more worker threads to process queue backlog"
    }
    
    if ($Bottlenecks.ContainsKey('CacheEfficiency')) {
        $recommendations += "Increase cache size or optimize cache key strategy for better hit rate"
    }
    
    if ($Bottlenecks.ContainsKey('MemoryPressure')) {
        $recommendations += "Reduce batch size, clear completed queue more frequently, or add memory"
    }
    
    if ($Bottlenecks.ContainsKey('ThroughputDegradation')) {
        $recommendations += "Investigate recent changes, check for resource contention, or restart processing"
    }
    
    if ($recommendations.Count -eq 0 -and $Metrics.FilesPerSecond -gt 0) {
        $recommendations += "Performance is meeting expectations"
    }
    
    return $recommendations
}

Export-ModuleMember -Function @(
    'Update-PerformanceMetrics',
    'Get-PerformanceBottlenecks',
    'New-PerformanceTimer',
    'Get-ThroughputAnalysis',
    'Test-PerformanceOptimizationNeeded',
    'Get-PerformanceRecommendations'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBr/2xxKqikCO15
# nD+E/4x26HlbUzVqekLQrXODGihfI6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICfEHVHctQdayRqoACubQK2U
# 8Dttz4BQ2r0zIaS+SyZXMA0GCSqGSIb3DQEBAQUABIIBAGzhW8alDGA6o+Vsws+O
# 5zAhE2VJw+8SZOwYStU2jR8f+BlAxEMBct7gTK7/55mfQDbyx6HU4ARuiCjWec4i
# P3MNNLED/fb+WY2Kbpo1I2O12UxJCIFUZS2bt0WFbhqqn5icIaj41NCkqscfQA2Z
# C3iqSYm8eTSnjRnvu9z37nbozzIxL0lVDfGuB7RKPnEw1q5zQGOsAw5LFGUMiK1H
# szdPDuFYSoJ6NarlPqElejhj2CuIAQd0vK29LA/SFdgztYkFLAth5k7LQvEtCV/x
# CYO8KOwbsrNBSwl0KweW2KFC867gv9HralL1z6LmwzYIwlgNqQ39dn86HPzwguip
# iBg=
# SIG # End signature block
