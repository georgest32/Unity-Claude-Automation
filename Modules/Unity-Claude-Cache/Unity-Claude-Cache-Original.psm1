# Unity-Claude-Cache.psm1
# Redis-like in-memory cache implementation for high-performance documentation system
# Provides TTL management, LRU eviction, and thread-safe operations

using namespace System.Collections.Concurrent
using namespace System.Threading

# Cache Manager Class - Core caching functionality
class CacheManager {
    [hashtable]$Cache
    [hashtable]$Metadata
    [ConcurrentDictionary[string, datetime]]$Expiration
    [System.Collections.Generic.LinkedList[string]]$LRUList
    [hashtable]$LRUNodes
    [int]$MaxSize
    [int]$CurrentSize
    [hashtable]$Statistics
    [System.Threading.ReaderWriterLockSlim]$Lock
    [bool]$EnablePersistence
    [string]$PersistencePath
    [System.Timers.Timer]$CleanupTimer
    
    CacheManager() {
        $this.Initialize(1000, $false, "")
    }
    
    CacheManager([int]$maxSize) {
        $this.Initialize($maxSize, $false, "")
    }
    
    CacheManager([int]$maxSize, [bool]$enablePersistence, [string]$persistencePath) {
        $this.Initialize($maxSize, $enablePersistence, $persistencePath)
    }
    
    hidden [void]Initialize([int]$maxSize, [bool]$enablePersistence, [string]$persistencePath) {
        Write-Debug "[CacheManager] Initializing with maxSize: $maxSize"
        
        $this.Cache = [hashtable]::Synchronized(@{})
        $this.Metadata = [hashtable]::Synchronized(@{})
        $this.Expiration = [ConcurrentDictionary[string, datetime]]::new()
        $this.LRUList = [System.Collections.Generic.LinkedList[string]]::new()
        $this.LRUNodes = [hashtable]::Synchronized(@{})
        $this.MaxSize = $maxSize
        $this.CurrentSize = 0
        $this.Lock = [System.Threading.ReaderWriterLockSlim]::new()
        $this.EnablePersistence = $enablePersistence
        $this.PersistencePath = $persistencePath
        
        # Initialize statistics
        $this.Statistics = [hashtable]::Synchronized(@{
            Hits = 0
            Misses = 0
            Evictions = 0
            Expirations = 0
            TotalSets = 0
            TotalGets = 0
            TotalRemoves = 0
            AverageGetTime = 0
            AverageSetTime = 0
            LastCleanup = [datetime]::Now
            CreatedAt = [datetime]::Now
        })
        
        # Setup cleanup timer (runs every 60 seconds)
        $this.CleanupTimer = [System.Timers.Timer]::new(60000)
        Register-ObjectEvent -InputObject $this.CleanupTimer -EventName Elapsed -Action {
            $Event.MessageData.CleanupExpired()
        } -MessageData $this | Out-Null
        $this.CleanupTimer.Start()
        
        # Load from persistence if enabled
        if ($this.EnablePersistence -and $persistencePath -and (Test-Path $persistencePath)) {
            $this.LoadFromDisk()
        }
        
        Write-Debug "[CacheManager] Initialization complete"
    }
    
    # Set cache item with optional TTL and priority
    [bool]Set([string]$key, [object]$value, [nullable[int]]$ttlSeconds, [int]$priority) {
        $startTime = [datetime]::Now
        Write-Debug "[CacheManager] Setting key: $key with TTL: $ttlSeconds seconds"
        
        try {
            $this.Lock.EnterWriteLock()
            
            # Check if we need to evict items
            if ($this.CurrentSize -ge $this.MaxSize -and -not $this.Cache.ContainsKey($key)) {
                $this.EvictLRU()
            }
            
            # Set or update the cache item
            $this.Cache[$key] = $value
            
            # Set metadata
            $this.Metadata[$key] = @{
                Priority = $priority
                CreatedAt = [datetime]::Now
                LastAccessed = [datetime]::Now
                AccessCount = 0
                Size = $this.GetItemSize($value)
            }
            
            # Set expiration if TTL provided
            if ($null -ne $ttlSeconds -and $ttlSeconds -gt 0) {
                $expireAt = [datetime]::Now.AddSeconds($ttlSeconds)
                $this.Expiration[$key] = $expireAt
                Write-Debug "[CacheManager] Key $key will expire at $expireAt"
            }
            
            # Update LRU list
            $this.UpdateLRU($key)
            
            # Update size
            if (-not $this.Cache.ContainsKey($key)) {
                $this.CurrentSize++
            }
            
            # Update statistics
            $this.Statistics.TotalSets++
            $elapsed = ([datetime]::Now - $startTime).TotalMilliseconds
            $this.Statistics.AverageSetTime = (($this.Statistics.AverageSetTime * ($this.Statistics.TotalSets - 1)) + $elapsed) / $this.Statistics.TotalSets
            
            Write-Debug "[CacheManager] Successfully set key: $key"
            return $true
        }
        catch {
            Write-Error "[CacheManager] Error setting key $key : $_"
            return $false
        }
        finally {
            if ($this.Lock.IsWriteLockHeld) {
                $this.Lock.ExitWriteLock()
            }
        }
    }
    
    # Simplified Set overloads
    [bool]Set([string]$key, [object]$value) {
        return $this.Set($key, $value, $null, 0)
    }
    
    [bool]Set([string]$key, [object]$value, [int]$ttlSeconds) {
        return $this.Set($key, $value, $ttlSeconds, 0)
    }
    
    # Get cache item
    [object]Get([string]$key) {
        $startTime = [datetime]::Now
        Write-Debug "[CacheManager] Getting key: $key"
        
        try {
            $this.Lock.EnterReadLock()
            
            # Check if key exists
            if (-not $this.Cache.ContainsKey($key)) {
                $this.Statistics.Misses++
                $this.Statistics.TotalGets++
                Write-Debug "[CacheManager] Cache miss for key: $key"
                return $null
            }
            
            # Check expiration
            if ($this.Expiration.ContainsKey($key)) {
                $expireAt = $this.Expiration[$key]
                if ([datetime]::Now -gt $expireAt) {
                    Write-Debug "[CacheManager] Key $key has expired"
                    $this.Lock.ExitReadLock()
                    $this.Lock.EnterWriteLock()
                    $this.RemoveInternal($key)
                    $this.Statistics.Expirations++
                    $this.Statistics.Misses++
                    $this.Statistics.TotalGets++
                    return $null
                }
            }
            
            # Get value
            $value = $this.Cache[$key]
            
            # Update metadata
            if ($this.Metadata.ContainsKey($key)) {
                $this.Metadata[$key].LastAccessed = [datetime]::Now
                $this.Metadata[$key].AccessCount++
            }
            
            # Update LRU
            $this.Lock.ExitReadLock()
            $this.Lock.EnterWriteLock()
            $this.UpdateLRU($key)
            
            # Update statistics
            $this.Statistics.Hits++
            $this.Statistics.TotalGets++
            $elapsed = ([datetime]::Now - $startTime).TotalMilliseconds
            $this.Statistics.AverageGetTime = (($this.Statistics.AverageGetTime * ($this.Statistics.TotalGets - 1)) + $elapsed) / $this.Statistics.TotalGets
            
            Write-Debug "[CacheManager] Cache hit for key: $key"
            return $value
        }
        catch {
            Write-Error "[CacheManager] Error getting key $key : $_"
            return $null
        }
        finally {
            if ($this.Lock.IsWriteLockHeld) {
                $this.Lock.ExitWriteLock()
            }
            elseif ($this.Lock.IsReadLockHeld) {
                $this.Lock.ExitReadLock()
            }
        }
    }
    
    # Remove cache item
    [bool]Remove([string]$key) {
        Write-Debug "[CacheManager] Removing key: $key"
        
        try {
            $this.Lock.EnterWriteLock()
            
            if ($this.RemoveInternal($key)) {
                $this.Statistics.TotalRemoves++
                Write-Debug "[CacheManager] Successfully removed key: $key"
                return $true
            }
            
            return $false
        }
        catch {
            Write-Error "[CacheManager] Error removing key $key : $_"
            return $false
        }
        finally {
            if ($this.Lock.IsWriteLockHeld) {
                $this.Lock.ExitWriteLock()
            }
        }
    }
    
    # Internal remove (must be called within write lock)
    hidden [bool]RemoveInternal([string]$key) {
        if (-not $this.Cache.ContainsKey($key)) {
            return $false
        }
        
        # Remove from cache
        $this.Cache.Remove($key)
        $this.Metadata.Remove($key)
        
        # Remove from expiration
        if ($this.Expiration.ContainsKey($key)) {
            [datetime]$dummy = [datetime]::MinValue
            $this.Expiration.TryRemove($key, [ref]$dummy) | Out-Null
        }
        
        # Remove from LRU
        if ($this.LRUNodes.ContainsKey($key)) {
            $node = $this.LRUNodes[$key]
            $this.LRUList.Remove($node)
            $this.LRUNodes.Remove($key)
        }
        
        $this.CurrentSize--
        return $true
    }
    
    # Clear all cache items
    [void]Clear() {
        Write-Debug "[CacheManager] Clearing all cache items"
        
        try {
            $this.Lock.EnterWriteLock()
            
            $this.Cache.Clear()
            $this.Metadata.Clear()
            $this.Expiration.Clear()
            $this.LRUList.Clear()
            $this.LRUNodes.Clear()
            $this.CurrentSize = 0
            
            Write-Debug "[CacheManager] Cache cleared"
        }
        finally {
            if ($this.Lock.IsWriteLockHeld) {
                $this.Lock.ExitWriteLock()
            }
        }
    }
    
    # Update LRU list (must be called within write lock)
    hidden [void]UpdateLRU([string]$key) {
        # Remove existing node if present
        if ($this.LRUNodes.ContainsKey($key)) {
            $node = $this.LRUNodes[$key]
            $this.LRUList.Remove($node)
        }
        
        # Add to front of list
        $newNode = $this.LRUList.AddFirst($key)
        $this.LRUNodes[$key] = $newNode
    }
    
    # Evict least recently used item
    hidden [void]EvictLRU() {
        Write-Debug "[CacheManager] Evicting LRU item"
        
        if ($this.LRUList.Last) {
            $keyToEvict = $this.LRUList.Last.Value
            
            # Check priority - don't evict high priority items if possible
            if ($this.Metadata.ContainsKey($keyToEvict)) {
                $priority = $this.Metadata[$keyToEvict].Priority
                if ($priority -ge 9) {
                    # Try to find a lower priority item to evict
                    $node = $this.LRUList.Last
                    while ($node -and $node.Previous) {
                        $candidateKey = $node.Value
                        if ($this.Metadata.ContainsKey($candidateKey)) {
                            $candidatePriority = $this.Metadata[$candidateKey].Priority
                            if ($candidatePriority -lt 9) {
                                $keyToEvict = $candidateKey
                                break
                            }
                        }
                        $node = $node.Previous
                    }
                }
            }
            
            Write-Debug "[CacheManager] Evicting key: $keyToEvict"
            $this.RemoveInternal($keyToEvict)
            $this.Statistics.Evictions++
        }
    }
    
    # Cleanup expired items
    [void]CleanupExpired() {
        Write-Debug "[CacheManager] Running cleanup of expired items"
        $expiredCount = 0
        
        try {
            $this.Lock.EnterWriteLock()
            
            $now = [datetime]::Now
            $keysToRemove = @()
            
            foreach ($kvp in $this.Expiration.GetEnumerator()) {
                if ($now -gt $kvp.Value) {
                    $keysToRemove += $kvp.Key
                }
            }
            
            foreach ($key in $keysToRemove) {
                if ($this.RemoveInternal($key)) {
                    $expiredCount++
                    $this.Statistics.Expirations++
                }
            }
            
            $this.Statistics.LastCleanup = $now
            
            if ($expiredCount -gt 0) {
                Write-Debug "[CacheManager] Cleaned up $expiredCount expired items"
            }
        }
        finally {
            if ($this.Lock.IsWriteLockHeld) {
                $this.Lock.ExitWriteLock()
            }
        }
    }
    
    # Get cache statistics
    [hashtable]GetStatistics() {
        try {
            $this.Lock.EnterReadLock()
            
            $stats = @{
                CurrentSize = $this.CurrentSize
                MaxSize = $this.MaxSize
                Hits = $this.Statistics.Hits
                Misses = $this.Statistics.Misses
                HitRate = if (($this.Statistics.Hits + $this.Statistics.Misses) -gt 0) { 
                    [math]::Round(($this.Statistics.Hits / ($this.Statistics.Hits + $this.Statistics.Misses)) * 100, 2) 
                } else { 0 }
                Evictions = $this.Statistics.Evictions
                Expirations = $this.Statistics.Expirations
                TotalSets = $this.Statistics.TotalSets
                TotalGets = $this.Statistics.TotalGets
                TotalRemoves = $this.Statistics.TotalRemoves
                AverageGetTime = [math]::Round($this.Statistics.AverageGetTime, 2)
                AverageSetTime = [math]::Round($this.Statistics.AverageSetTime, 2)
                LastCleanup = $this.Statistics.LastCleanup
                Uptime = ([datetime]::Now - $this.Statistics.CreatedAt)
            }
            
            return $stats
        }
        finally {
            if ($this.Lock.IsReadLockHeld) {
                $this.Lock.ExitReadLock()
            }
        }
    }
    
    # Check if key exists
    [bool]ContainsKey([string]$key) {
        try {
            $this.Lock.EnterReadLock()
            
            if (-not $this.Cache.ContainsKey($key)) {
                return $false
            }
            
            # Check expiration
            if ($this.Expiration.ContainsKey($key)) {
                if ([datetime]::Now -gt $this.Expiration[$key]) {
                    return $false
                }
            }
            
            return $true
        }
        finally {
            if ($this.Lock.IsReadLockHeld) {
                $this.Lock.ExitReadLock()
            }
        }
    }
    
    # Get all keys
    [string[]]GetKeys() {
        try {
            $this.Lock.EnterReadLock()
            
            $keys = @()
            $now = [datetime]::Now
            
            foreach ($key in $this.Cache.Keys) {
                # Skip expired keys
                if ($this.Expiration.ContainsKey($key)) {
                    if ($now -gt $this.Expiration[$key]) {
                        continue
                    }
                }
                $keys += $key
            }
            
            return $keys
        }
        finally {
            if ($this.Lock.IsReadLockHeld) {
                $this.Lock.ExitReadLock()
            }
        }
    }
    
    # Estimate item size (simplified)
    hidden [int]GetItemSize([object]$item) {
        if ($null -eq $item) { return 0 }
        
        # Rough estimation based on type
        if ($item -is [string]) {
            return $item.Length * 2  # Unicode chars
        }
        elseif ($item -is [array]) {
            return $item.Count * 100  # Rough estimate
        }
        elseif ($item -is [hashtable]) {
            return $item.Count * 200  # Rough estimate
        }
        else {
            return 1000  # Default size
        }
    }
    
    # Save cache to disk
    [void]SaveToDisk() {
        if (-not $this.EnablePersistence -or -not $this.PersistencePath) {
            return
        }
        
        Write-Debug "[CacheManager] Saving cache to disk: $($this.PersistencePath)"
        
        try {
            $this.Lock.EnterReadLock()
            
            $data = @{
                Cache = $this.Cache
                Metadata = $this.Metadata
                Expiration = @{}
                Statistics = $this.Statistics
            }
            
            # Convert expiration dictionary
            foreach ($kvp in $this.Expiration.GetEnumerator()) {
                $data.Expiration[$kvp.Key] = $kvp.Value.ToString('o')
            }
            
            $json = $data | ConvertTo-Json -Depth 10 -Compress
            $json | Out-File -FilePath $this.PersistencePath -Encoding UTF8
            
            Write-Debug "[CacheManager] Cache saved to disk"
        }
        catch {
            Write-Error "[CacheManager] Error saving cache to disk: $_"
        }
        finally {
            if ($this.Lock.IsReadLockHeld) {
                $this.Lock.ExitReadLock()
            }
        }
    }
    
    # Load cache from disk
    [void]LoadFromDisk() {
        if (-not $this.EnablePersistence -or -not $this.PersistencePath) {
            return
        }
        
        if (-not (Test-Path $this.PersistencePath)) {
            return
        }
        
        Write-Debug "[CacheManager] Loading cache from disk: $($this.PersistencePath)"
        
        try {
            $json = Get-Content -Path $this.PersistencePath -Raw -Encoding UTF8
            $data = $json | ConvertFrom-Json
            
            $this.Lock.EnterWriteLock()
            
            # Restore cache data
            foreach ($prop in $data.Cache.PSObject.Properties) {
                $this.Cache[$prop.Name] = $prop.Value
            }
            
            # Restore metadata
            foreach ($prop in $data.Metadata.PSObject.Properties) {
                $this.Metadata[$prop.Name] = $prop.Value
            }
            
            # Restore expiration
            foreach ($prop in $data.Expiration.PSObject.Properties) {
                $expireAt = [datetime]::Parse($prop.Value)
                if ($expireAt -gt [datetime]::Now) {
                    $this.Expiration[$prop.Name] = $expireAt
                }
            }
            
            $this.CurrentSize = $this.Cache.Count
            
            Write-Debug "[CacheManager] Cache loaded from disk: $($this.CurrentSize) items"
        }
        catch {
            Write-Error "[CacheManager] Error loading cache from disk: $_"
        }
        finally {
            if ($this.Lock.IsWriteLockHeld) {
                $this.Lock.ExitWriteLock()
            }
        }
    }
    
    # Dispose resources
    [void]Dispose() {
        Write-Debug "[CacheManager] Disposing cache manager"
        
        if ($this.CleanupTimer) {
            $this.CleanupTimer.Stop()
            $this.CleanupTimer.Dispose()
        }
        
        if ($this.EnablePersistence) {
            $this.SaveToDisk()
        }
        
        if ($this.Lock) {
            $this.Lock.Dispose()
        }
        
        $this.Clear()
    }
}

# Module Functions

function New-CacheManager {
    [CmdletBinding()]
    param(
        [Parameter()]
        [int]$MaxSize = 1000,
        
        [Parameter()]
        [switch]$EnablePersistence,
        
        [Parameter()]
        [string]$PersistencePath = "$env:TEMP\unity-claude-cache.json"
    )
    
    Write-Verbose "Creating new cache manager with max size: $MaxSize"
    
    try {
        $cacheManager = [CacheManager]::new($MaxSize, $EnablePersistence.IsPresent, $PersistencePath)
        Write-Verbose "Cache manager created successfully"
        return $cacheManager
    }
    catch {
        Write-Error "Failed to create cache manager: $_"
        throw
    }
}

function Set-CacheItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CacheManager]$CacheManager,
        
        [Parameter(Mandatory)]
        [string]$Key,
        
        [Parameter(Mandatory)]
        [object]$Value,
        
        [Parameter()]
        [int]$TTLSeconds = 0,
        
        [Parameter()]
        [ValidateRange(0, 10)]
        [int]$Priority = 5
    )
    
    Write-Verbose "Setting cache item: $Key"
    
    if ($TTLSeconds -gt 0) {
        return $CacheManager.Set($Key, $Value, $TTLSeconds, $Priority)
    }
    else {
        return $CacheManager.Set($Key, $Value, $null, $Priority)
    }
}

function Get-CacheItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CacheManager]$CacheManager,
        
        [Parameter(Mandatory)]
        [string]$Key
    )
    
    Write-Verbose "Getting cache item: $Key"
    return $CacheManager.Get($Key)
}

function Remove-CacheItem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CacheManager]$CacheManager,
        
        [Parameter(Mandatory)]
        [string]$Key
    )
    
    Write-Verbose "Removing cache item: $Key"
    return $CacheManager.Remove($Key)
}

function Clear-Cache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CacheManager]$CacheManager
    )
    
    Write-Verbose "Clearing cache"
    $CacheManager.Clear()
}

function Get-CacheStatistics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CacheManager]$CacheManager
    )
    
    Write-Verbose "Getting cache statistics"
    return $CacheManager.GetStatistics()
}

function Test-CacheKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CacheManager]$CacheManager,
        
        [Parameter(Mandatory)]
        [string]$Key
    )
    
    Write-Verbose "Testing cache key: $Key"
    return $CacheManager.ContainsKey($Key)
}

function Get-CacheKeys {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CacheManager]$CacheManager
    )
    
    Write-Verbose "Getting all cache keys"
    return $CacheManager.GetKeys()
}

function Save-CacheToDisk {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CacheManager]$CacheManager
    )
    
    Write-Verbose "Saving cache to disk"
    $CacheManager.SaveToDisk()
}

function Start-CacheCleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [CacheManager]$CacheManager
    )
    
    Write-Verbose "Starting cache cleanup"
    $CacheManager.CleanupExpired()
}

# Export module members
Export-ModuleMember -Function @(
    'New-CacheManager',
    'Set-CacheItem',
    'Get-CacheItem',
    'Remove-CacheItem',
    'Clear-Cache',
    'Get-CacheStatistics',
    'Test-CacheKey',
    'Get-CacheKeys',
    'Save-CacheToDisk',
    'Start-CacheCleanup'
) -Variable @() -Alias @()
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB05ISBEz5PToqj
# 0AEWYrCdePThNUvPtU01oZ0lcsik86CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOLyLwZYOgwkcl9PD6HEkMeI
# y5PvjcHMU4wgPwyKGb8nMA0GCSqGSIb3DQEBAQUABIIBAIWuVUvIEIRojImk6MvC
# Vnh/T7bOBbzlYpnr1MSJ7ArGLblzvKJ3lo3izahfR2ClLwzt6r+j3DX6VaaW53LL
# CUw0XUNQbZUlw2SacRtHs79/ErKVH9HMMVxNPgWjlwLfb6+OyaYYKZ9YIFXCW/6Q
# YSsTIvQTnPsaxLF071QlsjzDwD/PLP/d25LArostP697TzBmIW1cT2RZ6ncAIvVh
# r6SkyM9BStcrnboVE2j8169edny7mXI2DWeCedGW+E+R7b/RFZUv8w+mamhogMTN
# X9B28eaT0PtLptEl/cKoEi70WYnI+uWWGhBMrLkuI1AqmOOYvPxrLsMX/ZWEdpef
# rmA=
# SIG # End signature block
