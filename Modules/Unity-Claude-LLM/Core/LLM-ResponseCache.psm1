#
# LLM-ResponseCache.psm1  
# Response caching system for LLM queries with TTL management and cleanup automation
# Part of Unity-Claude-LLM Enhanced Documentation System
# Created: 2025-08-28
#

# Module configuration
$script:CacheConfig = @{
    DefaultTTLMinutes = 30
    MaxCacheSize = 1000
    CleanupIntervalMinutes = 5
    MaxMemoryMB = 500
    EnableStatistics = $true
}

# Thread-safe cache storage using synchronized hashtable
$script:ResponseCache = [hashtable]::Synchronized(@{})
$script:CacheMetadata = [hashtable]::Synchronized(@{})
$script:CacheStatistics = [hashtable]::Synchronized(@{
    HitCount = 0
    MissCount = 0
    EvictionCount = 0
    TotalRequests = 0
    StartTime = Get-Date
})

# Background cleanup job tracking
$script:CleanupJob = $null

#
# Core cache functions
#

function Get-CacheKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        
        [string]$Model = "default",
        [hashtable]$Options = @{}
    )
    
    # Create deterministic cache key from prompt content and parameters
    $keyData = "$Model|$Prompt|$($Options | ConvertTo-Json -Compress)"
    
    # Generate SHA256 hash for consistent key generation
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $hasher.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($keyData))
    $hashString = [System.BitConverter]::ToString($hashBytes).Replace("-", "").ToLowerInvariant()
    
    Write-Debug "[CACHE] Generated cache key: $($hashString.Substring(0, 8))... for prompt length $($Prompt.Length)"
    
    return $hashString
}

function Get-CachedResponse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CacheKey,
        
        [int]$TTLMinutes = $script:CacheConfig.DefaultTTLMinutes
    )
    
    Write-Debug "[CACHE] Checking cache for key: $($CacheKey.Substring(0, 8))..."
    
    $script:CacheStatistics.TotalRequests++
    
    # Check if cache entry exists
    if ($script:ResponseCache.ContainsKey($CacheKey)) {
        $metadata = $script:CacheMetadata[$CacheKey]
        $currentTime = Get-Date
        
        # Check TTL expiration
        if ($currentTime -lt $metadata.ExpiresAt) {
            Write-Debug "[CACHE] Cache HIT - Entry valid until $($metadata.ExpiresAt)"
            $script:CacheStatistics.HitCount++
            
            # Update access time for LRU tracking
            $metadata.LastAccessed = $currentTime
            
            return @{
                Found = $true
                Response = $script:ResponseCache[$CacheKey]
                CachedAt = $metadata.CreatedAt
                ExpiresAt = $metadata.ExpiresAt
                AccessCount = ++$metadata.AccessCount
            }
        }
        else {
            Write-Debug "[CACHE] Cache EXPIRED - Removing stale entry"
            Remove-CacheEntry -CacheKey $CacheKey
        }
    }
    
    Write-Debug "[CACHE] Cache MISS - Entry not found or expired"
    $script:CacheStatistics.MissCount++
    
    return @{
        Found = $false
        Response = $null
    }
}

function Set-CachedResponse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CacheKey,
        
        [Parameter(Mandatory=$true)]
        $Response,
        
        [int]$TTLMinutes = $script:CacheConfig.DefaultTTLMinutes
    )
    
    Write-Debug "[CACHE] Storing response for key: $($CacheKey.Substring(0, 8))... TTL: $TTLMinutes minutes"
    
    # Check cache size limits before adding
    if ($script:ResponseCache.Count -ge $script:CacheConfig.MaxCacheSize) {
        Write-Debug "[CACHE] Cache size limit reached, performing LRU eviction"
        Invoke-LRUEviction
    }
    
    $currentTime = Get-Date
    $expiresAt = $currentTime.AddMinutes($TTLMinutes)
    
    # Store response and metadata
    $script:ResponseCache[$CacheKey] = $Response
    $script:CacheMetadata[$CacheKey] = @{
        CreatedAt = $currentTime
        LastAccessed = $currentTime
        ExpiresAt = $expiresAt
        AccessCount = 1
        Size = ($Response | ConvertTo-Json -Compress).Length
    }
    
    Write-Debug "[CACHE] Response cached successfully, expires at: $expiresAt"
    
    # Start background cleanup if not already running
    Start-CacheCleanupJob
    
    return $true
}

function Remove-CacheEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$CacheKey
    )
    
    if ($script:ResponseCache.ContainsKey($CacheKey)) {
        $script:ResponseCache.Remove($CacheKey)
        $script:CacheMetadata.Remove($CacheKey)
        $script:CacheStatistics.EvictionCount++
        
        Write-Debug "[CACHE] Removed cache entry: $($CacheKey.Substring(0, 8))..."
        return $true
    }
    
    return $false
}

function Clear-ExpiredCache {
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    $currentTime = Get-Date
    $expiredKeys = @()
    
    Write-Debug "[CACHE] Starting expired cache cleanup at $currentTime"
    
    # Find expired entries (thread-safe enumeration)
    $keysToCheck = @($script:CacheMetadata.Keys)
    
    foreach ($key in $keysToCheck) {
        if ($script:CacheMetadata.ContainsKey($key)) {
            $metadata = $script:CacheMetadata[$key]
            
            if ($Force -or $currentTime -gt $metadata.ExpiresAt) {
                $expiredKeys += $key
            }
        }
    }
    
    # Remove expired entries
    $removedCount = 0
    foreach ($key in $expiredKeys) {
        if (Remove-CacheEntry -CacheKey $key) {
            $removedCount++
        }
    }
    
    Write-Debug "[CACHE] Cleanup complete: $removedCount entries removed"
    
    return @{
        RemovedCount = $removedCount
        TotalChecked = $keysToCheck.Count
        CleanupTime = $currentTime
    }
}

function Invoke-LRUEviction {
    [CmdletBinding()]
    param(
        [int]$TargetSize = [math]::Floor($script:CacheConfig.MaxCacheSize * 0.8)
    )
    
    Write-Debug "[CACHE] Starting LRU eviction, target size: $TargetSize"
    
    # Get entries sorted by last access time (least recently used first)
    $entries = @()
    $keysToCheck = @($script:CacheMetadata.Keys)
    
    foreach ($key in $keysToCheck) {
        if ($script:CacheMetadata.ContainsKey($key)) {
            $metadata = $script:CacheMetadata[$key]
            $entries += @{
                Key = $key
                LastAccessed = $metadata.LastAccessed
                AccessCount = $metadata.AccessCount
            }
        }
    }
    
    # Sort by last access time (oldest first) and access count (least used first)
    $sortedEntries = $entries | Sort-Object LastAccessed, AccessCount
    
    # Remove entries until target size reached
    $removedCount = 0
    foreach ($entry in $sortedEntries) {
        if ($script:ResponseCache.Count -le $TargetSize) {
            break
        }
        
        Remove-CacheEntry -CacheKey $entry.Key
        $removedCount++
    }
    
    Write-Debug "[CACHE] LRU eviction complete: $removedCount entries removed"
    
    return $removedCount
}

function Get-CacheStatistics {
    [CmdletBinding()]
    param()
    
    $currentTime = Get-Date
    $uptime = $currentTime - $script:CacheStatistics.StartTime
    $totalRequests = $script:CacheStatistics.TotalRequests
    
    # Calculate memory usage
    $totalMemoryKB = 0
    $keysToCheck = @($script:CacheMetadata.Keys)
    
    foreach ($key in $keysToCheck) {
        if ($script:CacheMetadata.ContainsKey($key)) {
            $totalMemoryKB += [math]::Round($script:CacheMetadata[$key].Size / 1024, 2)
        }
    }
    
    return [PSCustomObject]@{
        TotalEntries = $script:ResponseCache.Count
        HitCount = $script:CacheStatistics.HitCount
        MissCount = $script:CacheStatistics.MissCount
        EvictionCount = $script:CacheStatistics.EvictionCount
        TotalRequests = $totalRequests
        HitRatio = if ($totalRequests -gt 0) { [math]::Round(($script:CacheStatistics.HitCount / $totalRequests) * 100, 2) } else { 0 }
        MemoryUsageKB = $totalMemoryKB
        UptimeMinutes = [math]::Round($uptime.TotalMinutes, 2)
        Configuration = $script:CacheConfig.Clone()
        LastCleanup = Get-Date
    }
}

function Start-CacheCleanupJob {
    [CmdletBinding()]
    param()
    
    # Only start if not already running
    if ($script:CleanupJob -and $script:CleanupJob.State -eq "Running") {
        Write-Debug "[CACHE] Cleanup job already running"
        return
    }
    
    Write-Debug "[CACHE] Starting background cleanup job"
    
    $script:CleanupJob = Start-Job -ScriptBlock {
        param($CacheConfigData)
        
        # Import the cache config
        $CleanupInterval = $CacheConfigData.CleanupIntervalMinutes
        
        while ($true) {
            try {
                # Wait for cleanup interval
                Start-Sleep -Seconds ($CleanupInterval * 60)
                
                # Note: This job runs in separate process, so it can't directly access module variables
                # The cleanup will be handled by the main process through periodic calls
                Write-Debug "[CACHE CLEANUP JOB] Cleanup interval reached"
            }
            catch {
                Write-Debug "[CACHE CLEANUP JOB] Error: $($_.Exception.Message)"
                break
            }
        }
    } -ArgumentList $script:CacheConfig
    
    Write-Debug "[CACHE] Background cleanup job started with ID: $($script:CleanupJob.Id)"
}

function Stop-CacheCleanupJob {
    [CmdletBinding()]
    param()
    
    if ($script:CleanupJob) {
        Write-Debug "[CACHE] Stopping background cleanup job"
        $script:CleanupJob | Stop-Job -PassThru | Remove-Job
        $script:CleanupJob = $null
    }
}

function Reset-Cache {
    [CmdletBinding()]
    param(
        [switch]$KeepStatistics
    )
    
    Write-Debug "[CACHE] Resetting cache - KeepStatistics: $KeepStatistics"
    
    # Clear cache data
    $script:ResponseCache.Clear()
    $script:CacheMetadata.Clear()
    
    # Reset statistics if requested
    if (-not $KeepStatistics) {
        $script:CacheStatistics.HitCount = 0
        $script:CacheStatistics.MissCount = 0
        $script:CacheStatistics.EvictionCount = 0
        $script:CacheStatistics.TotalRequests = 0
        $script:CacheStatistics.StartTime = Get-Date
    }
    
    Write-Debug "[CACHE] Cache reset complete"
}

function Set-CacheConfiguration {
    [CmdletBinding()]
    param(
        [int]$DefaultTTLMinutes,
        [int]$MaxCacheSize,
        [int]$CleanupIntervalMinutes,
        [int]$MaxMemoryMB,
        [bool]$EnableStatistics
    )
    
    if ($DefaultTTLMinutes) { $script:CacheConfig.DefaultTTLMinutes = $DefaultTTLMinutes }
    if ($MaxCacheSize) { $script:CacheConfig.MaxCacheSize = $MaxCacheSize }
    if ($CleanupIntervalMinutes) { $script:CacheConfig.CleanupIntervalMinutes = $CleanupIntervalMinutes }
    if ($MaxMemoryMB) { $script:CacheConfig.MaxMemoryMB = $MaxMemoryMB }
    if ($PSBoundParameters.ContainsKey('EnableStatistics')) { $script:CacheConfig.EnableStatistics = $EnableStatistics }
    
    Write-Debug "[CACHE] Configuration updated: TTL=$($script:CacheConfig.DefaultTTLMinutes)min, MaxSize=$($script:CacheConfig.MaxCacheSize), Cleanup=$($script:CacheConfig.CleanupIntervalMinutes)min"
}

function Invoke-CacheMaintenanceTask {
    [CmdletBinding()]
    param()
    
    Write-Debug "[CACHE] Starting maintenance task"
    
    # Perform cleanup
    $cleanupResult = Clear-ExpiredCache
    
    # Check memory pressure and perform additional eviction if needed
    $stats = Get-CacheStatistics
    if ($stats.MemoryUsageKB -gt ($script:CacheConfig.MaxMemoryMB * 1024)) {
        Write-Debug "[CACHE] Memory pressure detected, performing additional eviction"
        Invoke-LRUEviction -TargetSize ([math]::Floor($script:CacheConfig.MaxCacheSize * 0.7))
    }
    
    return @{
        CleanupResult = $cleanupResult
        CacheStatistics = $stats
        MaintenanceTime = Get-Date
    }
}

#
# High-level caching interface for LLM operations
#

function Get-LLMResponseFromCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        
        [string]$Model = "codellama:34b",
        [hashtable]$Options = @{},
        [int]$TTLMinutes = $script:CacheConfig.DefaultTTLMinutes
    )
    
    $cacheKey = Get-CacheKey -Prompt $Prompt -Model $Model -Options $Options
    $result = Get-CachedResponse -CacheKey $cacheKey -TTLMinutes $TTLMinutes
    
    Write-Debug "[CACHE] Cache lookup result: Found=$($result.Found)"
    
    return $result
}

function Set-LLMResponseToCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,
        
        [Parameter(Mandatory=$true)]
        $Response,
        
        [string]$Model = "codellama:34b",
        [hashtable]$Options = @{},
        [int]$TTLMinutes = $script:CacheConfig.DefaultTTLMinutes
    )
    
    $cacheKey = Get-CacheKey -Prompt $Prompt -Model $Model -Options $Options
    $success = Set-CachedResponse -CacheKey $cacheKey -Response $Response -TTLMinutes $TTLMinutes
    
    Write-Debug "[CACHE] Cache store result: Success=$success"
    
    return $success
}

# Export module functions
Export-ModuleMember -Function @(
    'Get-CacheKey',
    'Get-CachedResponse', 
    'Set-CachedResponse',
    'Remove-CacheEntry',
    'Clear-ExpiredCache',
    'Invoke-LRUEviction',
    'Get-CacheStatistics',
    'Start-CacheCleanupJob',
    'Stop-CacheCleanupJob',
    'Reset-Cache',
    'Set-CacheConfiguration',
    'Invoke-CacheMaintenanceTask',
    'Get-LLMResponseFromCache',
    'Set-LLMResponseToCache'
)
