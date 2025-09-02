# PerformanceOptimization.psm1
# Dynamic performance optimization strategies

# Optimize performance based on current metrics
function Optimize-Performance {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,
        
        [Parameter(Mandatory)]
        [hashtable]$Bottlenecks,
        
        [object]$CacheManager
    )
    
    Write-Verbose "[PerformanceOptimization] Optimizing performance based on current metrics"
    
    $optimizations = @()
    
    # Optimize based on identified bottlenecks
    if ($Bottlenecks.ContainsKey('QueueBacklog')) {
        $result = Optimize-BatchSize -Configuration $Configuration
        if ($result) { $optimizations += $result }
    }
    
    if ($Bottlenecks.ContainsKey('CacheEfficiency')) {
        $result = Optimize-CacheSettings -Configuration $Configuration -CacheManager $CacheManager
        if ($result) { $optimizations += $result }
    }
    
    if ($Bottlenecks.ContainsKey('MemoryPressure')) {
        $result = Optimize-MemoryUsage
        if ($result) { $optimizations += $result }
    }
    
    if ($Bottlenecks.ContainsKey('ThroughputDegradation')) {
        $result = Optimize-ThreadCount -Configuration $Configuration
        if ($result) { $optimizations += $result }
    }
    
    return $optimizations
}

# Increase batch size for better throughput
function Optimize-BatchSize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,
        
        [decimal]$IncreaseFactor = 1.5,
        [int]$MaxBatchSize = 200
    )
    
    $currentBatchSize = $Configuration.BatchSize
    $newBatchSize = [Math]::Min([int]($currentBatchSize * $IncreaseFactor), $MaxBatchSize)
    
    if ($newBatchSize -ne $currentBatchSize) {
        $Configuration.BatchSize = $newBatchSize
        Write-Information "[PerformanceOptimization] Increased batch size from $currentBatchSize to $newBatchSize"
        return "BatchSize increased to $newBatchSize"
    }
    
    return $null
}

# Optimize cache settings for better hit rate
function Optimize-CacheSettings {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,
        
        [object]$CacheManager,
        
        [decimal]$IncreaseFactor = 1.2,
        [int]$MaxCacheSize = 10000
    )
    
    if (-not $CacheManager) {
        Write-Warning "[PerformanceOptimization] CacheManager not available for optimization"
        return $null
    }
    
    $currentSize = $Configuration.CacheSize
    $newSize = [Math]::Min([int]($currentSize * $IncreaseFactor), $MaxCacheSize)
    
    if ($newSize -ne $currentSize) {
        $Configuration.CacheSize = $newSize
        
        # Apply new cache size if possible
        if ($CacheManager.SetMaxSize) {
            $CacheManager.SetMaxSize($newSize)
        }
        
        Write-Information "[PerformanceOptimization] Increased cache size from $currentSize to $newSize"
        return "CacheSize increased to $newSize"
    }
    
    return $null
}

# Reduce memory usage through cleanup
function Optimize-MemoryUsage {
    [CmdletBinding()]
    param()
    
    # Force garbage collection
    [GC]::Collect()
    [GC]::WaitForPendingFinalizers()
    [GC]::Collect()
    
    $memoryBefore = [GC]::GetTotalMemory($false) / 1MB
    [GC]::Collect(2, [GCCollectionMode]::Forced, $true)
    $memoryAfter = [GC]::GetTotalMemory($false) / 1MB
    
    $memorySaved = [Math]::Round($memoryBefore - $memoryAfter, 2)
    
    Write-Information "[PerformanceOptimization] Memory cleanup performed, freed $memorySaved MB"
    return "Memory freed: $memorySaved MB"
}

# Clean completed queue items
function Clear-CompletedQueue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Collections.Concurrent.ConcurrentQueue[PSCustomObject]]$CompletedQueue,
        
        [int]$ItemsToKeep = 100
    )
    
    $currentCount = $CompletedQueue.Count
    if ($currentCount -le $ItemsToKeep) {
        return 0
    }
    
    $itemsToRemove = $currentCount - $ItemsToKeep
    $removed = 0
    
    for ($i = 0; $i -lt $itemsToRemove; $i++) {
        $result = $null
        if ($CompletedQueue.TryDequeue([ref]$result)) {
            $removed++
        }
        else {
            break
        }
    }
    
    Write-Debug "[PerformanceOptimization] Cleared $removed items from completed queue"
    return $removed
}

# Optimize thread count based on performance
function Optimize-ThreadCount {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Configuration,
        
        [decimal]$IncreaseFactor = 1.25,
        [int]$MaxThreads = 64
    )
    
    $currentThreads = if ($Configuration.ContainsKey('ThreadCount')) {
        $Configuration.ThreadCount
    } else {
        [Environment]::ProcessorCount * 2
    }
    
    $newThreads = [Math]::Min([int]($currentThreads * $IncreaseFactor), $MaxThreads)
    
    if ($newThreads -ne $currentThreads) {
        $Configuration.ThreadCount = $newThreads
        Write-Information "[PerformanceOptimization] Increased thread count from $currentThreads to $newThreads"
        return "ThreadCount increased to $newThreads"
    }
    
    return $null
}

# Apply adaptive throttling based on system resources
function Get-AdaptiveThrottling {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Metrics,
        
        [int]$TargetQueueLength = 100,
        [decimal]$MemoryThresholdMB = 1000
    )
    
    $throttleSettings = @{
        ShouldThrottle = $false
        ThrottleDelayMs = 0
        Reason = ""
    }
    
    # Check queue length
    if ($Metrics.QueueLength -gt ($TargetQueueLength * 2)) {
        $throttleSettings.ShouldThrottle = $true
        $throttleSettings.ThrottleDelayMs = [Math]::Min(($Metrics.QueueLength - $TargetQueueLength) * 10, 1000)
        $throttleSettings.Reason = "Queue backlog"
    }
    
    # Check memory usage
    if ($Metrics.MemoryUsage -gt $MemoryThresholdMB) {
        $throttleSettings.ShouldThrottle = $true
        $memoryDelay = [Math]::Min((($Metrics.MemoryUsage - $MemoryThresholdMB) / 10), 500)
        $throttleSettings.ThrottleDelayMs = [Math]::Max($throttleSettings.ThrottleDelayMs, $memoryDelay)
        $throttleSettings.Reason = if ($throttleSettings.Reason) { "$($throttleSettings.Reason), Memory pressure" } else { "Memory pressure" }
    }
    
    return $throttleSettings
}

# Dynamic batch size adjustment
function Get-DynamicBatchSize {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Metrics,
        
        [int]$BaseBatchSize = 50,
        [int]$MinBatchSize = 10,
        [int]$MaxBatchSize = 200
    )
    
    $queueLength = $Metrics.QueueLength
    $throughput = $Metrics.FilesPerSecond
    
    # Adjust batch size based on queue length
    $batchSize = if ($queueLength -gt 500) {
        [Math]::Min($BaseBatchSize * 2, $MaxBatchSize)
    }
    elseif ($queueLength -gt 100) {
        [Math]::Min([int]($BaseBatchSize * 1.5), $MaxBatchSize)
    }
    elseif ($queueLength -lt 10) {
        [Math]::Max([int]($BaseBatchSize * 0.5), $MinBatchSize)
    }
    else {
        $BaseBatchSize
    }
    
    Write-Debug "[PerformanceOptimization] Dynamic batch size: $batchSize (queue: $queueLength)"
    return $batchSize
}

Export-ModuleMember -Function @(
    'Optimize-Performance',
    'Optimize-BatchSize',
    'Optimize-CacheSettings',
    'Optimize-MemoryUsage',
    'Clear-CompletedQueue',
    'Optimize-ThreadCount',
    'Get-AdaptiveThrottling',
    'Get-DynamicBatchSize'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCsMCXVVaIKeoyk
# nUGtkqtEQNRmkdnaAXeqFTXKrzl0a6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDIZCFeETHEeRdyrl9gQR8IB
# pUmToxIrWuH1BEpwRw0sMA0GCSqGSIb3DQEBAQUABIIBAHN/ufr4mjHEqsl193jG
# kIXubQQhJhhCJOGnq7Ykpz2Hm08BKXFZHN4Ck9i1EeZj5ZNZiSoMRhuJqc40+Ti/
# WYxoIM79RK1xU7K+Cgi4RCv1kOORWxCSV8Cgj4iUofbHFKfoDGB43l4FXN2kfN20
# 0b8QEgmlmH1gg2V6vmRp9GUf9J16TaLqL8sMhUEgE0EWkoT1kUrm8hAaSGSwOhJE
# MUuQFyhkDjU3rZ6X8T2OFEMtMyRAQwvWMFp8fGJb4apPypVrcCb2kFcNeEKG+qGy
# Ezb43Afu56X3uYiqU5v8R7NMMBJYFUSvO/k7+rTwSefUSZ9Oj+DxtIXvwUDA0N2e
# 8L8=
# SIG # End signature block
