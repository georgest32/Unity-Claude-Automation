# Performance-Cache.psm1
# Unity-Claude Automation - High-Performance Redis-like In-Memory Cache
# Implements LRU eviction, TTL support, cache warming, and thread-safe operations
# Research-validated implementation based on 2024 best practices

using namespace System.Collections.Generic
using namespace System.Collections.Concurrent
using namespace System.Threading

# Cache Item Class
class CacheItem {
    [object]$Value
    [DateTime]$CreatedAt
    [DateTime]$LastAccessedAt
    [DateTime]$ExpiresAt
    [int]$AccessCount
    [string]$Key
    
    CacheItem([string]$key, [object]$value, [int]$ttlSeconds) {
        $this.Key = $key
        $this.Value = $value
        $this.CreatedAt = [DateTime]::UtcNow
        $this.LastAccessedAt = [DateTime]::UtcNow
        $this.AccessCount = 0
        
        if ($ttlSeconds -gt 0) {
            $this.ExpiresAt = [DateTime]::UtcNow.AddSeconds($ttlSeconds)
        } else {
            $this.ExpiresAt = [DateTime]::MaxValue
        }
    }
    
    [bool] IsExpired() {
        return [DateTime]::UtcNow -gt $this.ExpiresAt
    }
    
    [void] UpdateAccess() {
        $this.LastAccessedAt = [DateTime]::UtcNow
        $this.AccessCount++
    }
}

# Cache Statistics Class
class CacheStatistics {
    [int]$Hits = 0
    [int]$Misses = 0
    [int]$Evictions = 0
    [int]$Expirations = 0
    [int]$TotalRequests = 0
    [int]$CurrentSize = 0
    [long]$EstimatedMemoryBytes = 0
    [DateTime]$StartTime = [DateTime]::UtcNow
    
    [double] GetHitRatio() {
        if ($this.TotalRequests -eq 0) { return 0.0 }
        return [Math]::Round(($this.Hits / $this.TotalRequests) * 100, 2)
    }
    
    [TimeSpan] GetUptime() {
        return [DateTime]::UtcNow - $this.StartTime
    }
}

# Main Performance Cache Class
class PerformanceCache {
    # Thread-safe collections based on research
    hidden [hashtable]$Cache
    hidden [System.Collections.Generic.LinkedList[string]]$LRUList
    hidden [System.Threading.ReaderWriterLockSlim]$Lock
    hidden [CacheStatistics]$Stats
    hidden [int]$MaxSize
    hidden [int]$DefaultTTL
    hidden [bool]$EnableAutoEviction
    hidden [System.Timers.Timer]$CleanupTimer
    
    # Constructor
    PerformanceCache([int]$maxSize, [int]$defaultTTL) {
        Write-Debug "[PerformanceCache] Initializing cache with maxSize=$maxSize, defaultTTL=$defaultTTL"
        
        # Use synchronized hashtable for thread safety (PowerShell 5.1 compatible)
        $this.Cache = [hashtable]::Synchronized(@{})
        $this.LRUList = [System.Collections.Generic.LinkedList[string]]::new()
        $this.Lock = [System.Threading.ReaderWriterLockSlim]::new()
        $this.Stats = [CacheStatistics]::new()
        $this.MaxSize = $maxSize
        $this.DefaultTTL = $defaultTTL
        $this.EnableAutoEviction = $true
        
        # Set up background cleanup timer (runs every 60 seconds)
        $this.InitializeCleanupTimer()
    }
    
    # Initialize background cleanup timer
    hidden [void] InitializeCleanupTimer() {
        $this.CleanupTimer = [System.Timers.Timer]::new(60000) # 60 seconds
        
        $action = {
            try {
                $this.CleanupExpiredItems()
            } catch {
                Write-Warning "[PerformanceCache] Cleanup timer error: $_"
            }
        }.GetNewClosure()
        
        Register-ObjectEvent -InputObject $this.CleanupTimer -EventName Elapsed -Action $action | Out-Null
        $this.CleanupTimer.Start()
    }
    
    # Add or update cache item
    [bool] Set([string]$key, [object]$value) {
        return $this.Set($key, $value, $this.DefaultTTL)
    }
    
    [bool] Set([string]$key, [object]$value, [int]$ttlSeconds) {
        Write-Debug "[PerformanceCache] Setting key='$key' with TTL=$ttlSeconds seconds"
        
        try {
            $this.Lock.EnterWriteLock()
            
            # Check if we need to evict items
            if ($this.Cache.Count -ge $this.MaxSize -and -not $this.Cache.ContainsKey($key)) {
                $this.EvictLRU()
            }
            
            # Create new cache item
            $item = [CacheItem]::new($key, $value, $ttlSeconds)
            
            # Update cache
            if ($this.Cache.ContainsKey($key)) {
                # Remove old LRU entry
                $this.LRUList.Remove($key) | Out-Null
            }
            
            $this.Cache[$key] = $item
            $this.LRUList.AddFirst($key) | Out-Null
            
            # Update stats
            $this.Stats.CurrentSize = $this.Cache.Count
            $this.UpdateMemoryEstimate()
            
            Write-Debug "[PerformanceCache] Successfully set key='$key', cache size=$($this.Cache.Count)"
            return $true
            
        } catch {
            Write-Warning "[PerformanceCache] Error setting key='$key': $_"
            return $false
        } finally {
            if ($this.Lock.IsWriteLockHeld) {
                $this.Lock.ExitWriteLock()
            }
        }
    }
    
    # Get cache item
    [object] Get([string]$key) {
        Write-Debug "[PerformanceCache] Getting key='$key'"
        
        try {
            $this.Lock.EnterUpgradeableReadLock()
            $this.Stats.TotalRequests++
            
            if (-not $this.Cache.ContainsKey($key)) {
                $this.Stats.Misses++
                Write-Debug "[PerformanceCache] Cache miss for key='$key'"
                return $null
            }
            
            $item = $this.Cache[$key]
            
            # Check expiration
            if ($item.IsExpired()) {
                Write-Debug "[PerformanceCache] Key='$key' has expired"
                $this.Lock.EnterWriteLock()
                try {
                    $this.Cache.Remove($key)
                    $this.LRUList.Remove($key) | Out-Null
                    $this.Stats.Expirations++
                    $this.Stats.Misses++
                    $this.Stats.CurrentSize = $this.Cache.Count
                } finally {
                    $this.Lock.ExitWriteLock()
                }
                return $null
            }
            
            # Update LRU and access time
            $this.Lock.EnterWriteLock()
            try {
                $item.UpdateAccess()
                $this.LRUList.Remove($key) | Out-Null
                $this.LRUList.AddFirst($key) | Out-Null
                $this.Stats.Hits++
            } finally {
                $this.Lock.ExitWriteLock()
            }
            
            Write-Debug "[PerformanceCache] Cache hit for key='$key'"
            return $item.Value
            
        } catch {
            Write-Warning "[PerformanceCache] Error getting key='$key': $_"
            return $null
        } finally {
            if ($this.Lock.IsUpgradeableReadLockHeld) {
                $this.Lock.ExitUpgradeableReadLock()
            }
        }
    }
    
    # Remove cache item
    [bool] Remove([string]$key) {
        Write-Debug "[PerformanceCache] Removing key='$key'"
        
        try {
            $this.Lock.EnterWriteLock()
            
            if ($this.Cache.ContainsKey($key)) {
                $this.Cache.Remove($key)
                $this.LRUList.Remove($key) | Out-Null
                $this.Stats.CurrentSize = $this.Cache.Count
                Write-Debug "[PerformanceCache] Successfully removed key='$key'"
                return $true
            }
            
            return $false
            
        } catch {
            Write-Warning "[PerformanceCache] Error removing key='$key': $_"
            return $false
        } finally {
            if ($this.Lock.IsWriteLockHeld) {
                $this.Lock.ExitWriteLock()
            }
        }
    }
    
    # Check if key exists
    [bool] ContainsKey([string]$key) {
        try {
            $this.Lock.EnterReadLock()
            
            if (-not $this.Cache.ContainsKey($key)) {
                return $false
            }
            
            $item = $this.Cache[$key]
            return -not $item.IsExpired()
            
        } finally {
            if ($this.Lock.IsReadLockHeld) {
                $this.Lock.ExitReadLock()
            }
        }
    }
    
    # Clear all cache items
    [void] Clear() {
        Write-Debug "[PerformanceCache] Clearing cache"
        
        try {
            $this.Lock.EnterWriteLock()
            $this.Cache.Clear()
            $this.LRUList.Clear()
            $this.Stats.CurrentSize = 0
            Write-Debug "[PerformanceCache] Cache cleared"
        } finally {
            if ($this.Lock.IsWriteLockHeld) {
                $this.Lock.ExitWriteLock()
            }
        }
    }
    
    # Evict least recently used item
    hidden [void] EvictLRU() {
        if ($this.LRUList.Count -eq 0) { return }
        
        $keyToEvict = $this.LRUList.Last.Value
        Write-Debug "[PerformanceCache] Evicting LRU key='$keyToEvict'"
        
        $this.Cache.Remove($keyToEvict)
        $this.LRUList.RemoveLast()
        $this.Stats.Evictions++
        $this.Stats.CurrentSize = $this.Cache.Count
    }
    
    # Clean up expired items
    hidden [void] CleanupExpiredItems() {
        Write-Debug "[PerformanceCache] Running cleanup of expired items"
        $expiredKeys = @()
        
        try {
            $this.Lock.EnterReadLock()
            
            foreach ($key in $this.Cache.Keys) {
                $item = $this.Cache[$key]
                if ($item.IsExpired()) {
                    $expiredKeys += $key
                }
            }
            
        } finally {
            if ($this.Lock.IsReadLockHeld) {
                $this.Lock.ExitReadLock()
            }
        }
        
        # Remove expired items
        if ($expiredKeys.Count -gt 0) {
            try {
                $this.Lock.EnterWriteLock()
                
                foreach ($key in $expiredKeys) {
                    $this.Cache.Remove($key)
                    $this.LRUList.Remove($key) | Out-Null
                    $this.Stats.Expirations++
                }
                
                $this.Stats.CurrentSize = $this.Cache.Count
                Write-Debug "[PerformanceCache] Cleaned up $($expiredKeys.Count) expired items"
                
            } finally {
                if ($this.Lock.IsWriteLockHeld) {
                    $this.Lock.ExitWriteLock()
                }
            }
        }
    }
    
    # Update memory estimate
    hidden [void] UpdateMemoryEstimate() {
        # Rough estimate: 1KB per item average
        $this.Stats.EstimatedMemoryBytes = $this.Cache.Count * 1024
    }
    
    # Get cache statistics
    [CacheStatistics] GetStatistics() {
        return $this.Stats
    }
    
    # Get all keys
    [string[]] GetKeys() {
        try {
            $this.Lock.EnterReadLock()
            return @($this.Cache.Keys)
        } finally {
            if ($this.Lock.IsReadLockHeld) {
                $this.Lock.ExitReadLock()
            }
        }
    }
    
    # Dispose resources
    [void] Dispose() {
        if ($this.CleanupTimer) {
            $this.CleanupTimer.Stop()
            $this.CleanupTimer.Dispose()
        }
        if ($this.Lock) {
            $this.Lock.Dispose()
        }
        $this.Clear()
    }
}

# Cache Warming Strategy Class
class CacheWarmingStrategy {
    [PerformanceCache]$Cache
    [scriptblock]$DataLoader
    [string[]]$PriorityKeys
    [int]$WarmingBatchSize
    
    CacheWarmingStrategy([PerformanceCache]$cache) {
        $this.Cache = $cache
        $this.WarmingBatchSize = 10
        $this.PriorityKeys = @()
    }
    
    # Warm cache with priority data
    [void] WarmCache([hashtable]$dataToPreload) {
        Write-Debug "[CacheWarming] Starting cache warming with $($dataToPreload.Count) items"
        
        $loaded = 0
        foreach ($key in $dataToPreload.Keys) {
            try {
                $this.Cache.Set($key, $dataToPreload[$key])
                $loaded++
                
                if ($loaded % $this.WarmingBatchSize -eq 0) {
                    Write-Debug "[CacheWarming] Loaded $loaded/$($dataToPreload.Count) items"
                }
            } catch {
                Write-Warning "[CacheWarming] Failed to warm key='$key': $_"
            }
        }
        
        Write-Debug "[CacheWarming] Cache warming complete. Loaded $loaded items"
    }
    
    # Progressive warming - load data in stages
    [void] ProgressiveWarm([hashtable[]]$dataBatches) {
        Write-Debug "[CacheWarming] Starting progressive warming with $($dataBatches.Count) batches"
        
        $batchNum = 1
        foreach ($batch in $dataBatches) {
            Write-Debug "[CacheWarming] Loading batch $batchNum/$($dataBatches.Count)"
            $this.WarmCache($batch)
            $batchNum++
            
            # Small delay between batches to avoid load spikes
            Start-Sleep -Milliseconds 100
        }
    }
    
    # Predictive warming based on patterns
    [void] PredictiveWarm([string[]]$recentlyAccessedKeys, [scriptblock]$relatedItemLoader) {
        Write-Debug "[CacheWarming] Starting predictive warming based on access patterns"
        
        foreach ($key in $recentlyAccessedKeys) {
            try {
                # Load related items that are likely to be requested next
                $relatedData = & $relatedItemLoader -Key $key
                
                if ($relatedData -is [hashtable]) {
                    foreach ($relatedKey in $relatedData.Keys) {
                        if (-not $this.Cache.ContainsKey($relatedKey)) {
                            $this.Cache.Set($relatedKey, $relatedData[$relatedKey])
                        }
                    }
                }
            } catch {
                Write-Warning "[CacheWarming] Predictive warming failed for key='$key': $_"
            }
        }
    }
}

# Module Functions

function New-PerformanceCache {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$MaxSize = 1000,
        
        [Parameter()]
        [int]$DefaultTTL = 1800,  # 30 minutes default
        
        [Parameter()]
        [switch]$EnableStatistics
    )
    
    Write-Debug "Creating new PerformanceCache with MaxSize=$MaxSize, DefaultTTL=$DefaultTTL"
    
    $cache = [PerformanceCache]::new($MaxSize, $DefaultTTL)
    
    if ($EnableStatistics) {
        Write-Debug "Cache statistics tracking enabled"
    }
    
    return $cache
}

function Set-CacheItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceCache]$Cache,
        
        [Parameter(Mandatory)]
        [string]$Key,
        
        [Parameter(Mandatory)]
        [object]$Value,
        
        [Parameter()]
        [int]$TTLSeconds = 0
    )
    
    Write-Debug "Setting cache item: Key='$Key', TTL=$TTLSeconds"
    
    if ($TTLSeconds -gt 0) {
        return $Cache.Set($Key, $Value, $TTLSeconds)
    } else {
        return $Cache.Set($Key, $Value)
    }
}

function Get-CacheItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceCache]$Cache,
        
        [Parameter(Mandatory)]
        [string]$Key
    )
    
    Write-Debug "Getting cache item: Key='$Key'"
    return $Cache.Get($Key)
}

function Remove-CacheItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceCache]$Cache,
        
        [Parameter(Mandatory)]
        [string]$Key
    )
    
    Write-Debug "Removing cache item: Key='$Key'"
    return $Cache.Remove($Key)
}

function Clear-Cache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceCache]$Cache
    )
    
    Write-Debug "Clearing all cache items"
    $Cache.Clear()
}

function Get-CacheStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceCache]$Cache
    )
    
    $stats = $Cache.GetStatistics()
    
    return [PSCustomObject]@{
        Hits = $stats.Hits
        Misses = $stats.Misses
        HitRatio = "$($stats.GetHitRatio())%"
        Evictions = $stats.Evictions
        Expirations = $stats.Expirations
        CurrentSize = $stats.CurrentSize
        TotalRequests = $stats.TotalRequests
        EstimatedMemoryMB = [Math]::Round($stats.EstimatedMemoryBytes / 1MB, 2)
        Uptime = $stats.GetUptime()
    }
}

function New-CacheWarmingStrategy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PerformanceCache]$Cache,
        
        [Parameter()]
        [int]$BatchSize = 10
    )
    
    Write-Debug "Creating cache warming strategy with batch size=$BatchSize"
    
    $strategy = [CacheWarmingStrategy]::new($Cache)
    $strategy.WarmingBatchSize = $BatchSize
    
    return $strategy
}

function Start-CacheWarming {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CacheWarmingStrategy]$Strategy,
        
        [Parameter(Mandatory)]
        [hashtable]$Data,
        
        [Parameter()]
        [switch]$Progressive
    )
    
    Write-Debug "Starting cache warming with $($Data.Count) items"
    
    if ($Progressive) {
        # Split data into batches for progressive warming
        $batchSize = $Strategy.WarmingBatchSize
        $batches = @()
        $currentBatch = @{}
        $count = 0
        
        foreach ($key in $Data.Keys) {
            $currentBatch[$key] = $Data[$key]
            $count++
            
            if ($count -ge $batchSize) {
                $batches += $currentBatch
                $currentBatch = @{}
                $count = 0
            }
        }
        
        if ($currentBatch.Count -gt 0) {
            $batches += $currentBatch
        }
        
        $Strategy.ProgressiveWarm($batches)
    } else {
        $Strategy.WarmCache($Data)
    }
}

function Test-CachePerformance {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$ItemCount = 100,
        
        [Parameter()]
        [int]$MaxSize = 1000,
        
        [Parameter()]
        [int]$TTL = 60
    )
    
    Write-Host "Testing Performance Cache with $ItemCount items..." -ForegroundColor Cyan
    
    $cache = New-PerformanceCache -MaxSize $MaxSize -DefaultTTL $TTL -EnableStatistics
    
    # Test write performance
    $writeStart = [DateTime]::UtcNow
    for ($i = 1; $i -le $ItemCount; $i++) {
        Set-CacheItem -Cache $cache -Key "key_$i" -Value "value_$i" | Out-Null
    }
    $writeTime = ([DateTime]::UtcNow - $writeStart).TotalMilliseconds
    
    # Test read performance
    $readStart = [DateTime]::UtcNow
    for ($i = 1; $i -le $ItemCount; $i++) {
        Get-CacheItem -Cache $cache -Key "key_$i" | Out-Null
    }
    $readTime = ([DateTime]::UtcNow - $readStart).TotalMilliseconds
    
    # Get statistics
    $stats = Get-CacheStatistics -Cache $cache
    
    Write-Host "`nPerformance Results:" -ForegroundColor Green
    Write-Host "  Write Time: $([Math]::Round($writeTime, 2))ms ($([Math]::Round($ItemCount / ($writeTime / 1000), 0)) ops/sec)"
    Write-Host "  Read Time: $([Math]::Round($readTime, 2))ms ($([Math]::Round($ItemCount / ($readTime / 1000), 0)) ops/sec)"
    Write-Host "`nCache Statistics:" -ForegroundColor Green
    Write-Host "  Hit Ratio: $($stats.HitRatio)"
    Write-Host "  Current Size: $($stats.CurrentSize)"
    Write-Host "  Memory Usage: $($stats.EstimatedMemoryMB) MB"
    
    # Clean up
    $cache.Dispose()
    
    return @{
        WriteTimeMs = $writeTime
        ReadTimeMs = $readTime
        WriteOpsPerSec = [Math]::Round($ItemCount / ($writeTime / 1000), 0)
        ReadOpsPerSec = [Math]::Round($ItemCount / ($readTime / 1000), 0)
        Statistics = $stats
    }
}

# Export module members
Export-ModuleMember -Function @(
    'New-PerformanceCache'
    'Set-CacheItem'
    'Get-CacheItem'
    'Remove-CacheItem'
    'Clear-Cache'
    'Get-CacheStatistics'
    'New-CacheWarmingStrategy'
    'Start-CacheWarming'
    'Test-CachePerformance'
)

Export-ModuleMember -Variable @()

Write-Debug "Performance-Cache module loaded successfully"