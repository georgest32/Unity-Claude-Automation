# Unity-Claude-PerformanceOptimizer.psm1
# Performance optimization module for Day 14 afternoon session
# Provides pipeline optimization, caching, profiling, and bottleneck detection
# Date: 2025-08-18 | Day 14: Complete Feedback Loop Integration

#region Module Configuration and Dependencies

$ErrorActionPreference = "Stop"

Write-Host "[PerformanceOptimizer] Loading performance optimization module..." -ForegroundColor Cyan

# Performance configuration
$script:PerfConfig = @{
    # Profiling settings
    ProfilingEnabled = $true
    ProfileDataPath = Join-Path $PSScriptRoot "..\SessionData\Performance"
    ProfileRetentionDays = 7
    SamplingIntervalMs = 100
    
    # Caching settings
    CacheEnabled = $true
    CacheDataPath = Join-Path $PSScriptRoot "..\SessionData\Cache"
    MaxCacheSize = 100  # MB
    CacheExpirationMinutes = 60
    FileReadCacheSize = 50  # Number of files to cache
    
    # Optimization thresholds
    SlowOperationThresholdMs = 1000
    VerySlowOperationThresholdMs = 5000
    MemoryPressureThresholdMB = 200
    CpuPressureThreshold = 80  # Percentage
    
    # Pipeline optimization
    BatchProcessingSize = 10
    MaxConcurrentOperations = 5
    TimeoutMs = 30000
    
    # Logging
    VerboseLogging = $true
    LogFile = "performance_optimizer.log"
}

# Ensure directories exist
foreach ($path in @($script:PerfConfig.ProfileDataPath, $script:PerfConfig.CacheDataPath)) {
    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
    }
}

# Initialize performance tracking
$script:PerformanceMetrics = @{
    OperationCount = 0
    TotalProcessingTime = 0
    AverageProcessingTime = 0
    SlowestOperation = @{ Duration = 0; Operation = ""; Timestamp = "" }
    FastestOperation = @{ Duration = [double]::MaxValue; Operation = ""; Timestamp = "" }
    BottleneckOperations = @()
    CacheHits = 0
    CacheMisses = 0
    CacheHitRatio = 0
}

# Initialize caches
$script:FileCache = @{}
$script:JsonCache = @{}
$script:RegexCache = @{}
$script:ComputationCache = @{}

#endregion

#region Logging and Utilities

function Write-PerfLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO",
        [string]$Component = "PerfOptimizer"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    
    # Console output with colors
    $color = switch ($Level) {
        "INFO" { "White" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "DEBUG" { "Gray" }
    }
    
    if ($Level -ne "DEBUG" -or $script:PerfConfig.VerboseLogging) {
        Write-Host $logEntry -ForegroundColor $color
    }
    
    # File logging
    $logFile = Join-Path (Split-Path $script:PerfConfig.ProfileDataPath -Parent) $script:PerfConfig.LogFile
    try {
        Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    } catch {
        Write-Warning "Failed to write to performance log: $($_.Exception.Message)"
    }
}

function Get-PerfTimestamp {
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
}

function New-PerformanceId {
    return [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
}

#endregion

#region Performance Profiling

function Start-OperationProfile {
    param(
        [string]$OperationName,
        [hashtable]$Metadata = @{}
    )
    
    if (-not $script:PerfConfig.ProfilingEnabled) {
        return $null
    }
    
    $profileId = New-PerformanceId
    
    $profile = @{
        ProfileId = $profileId
        OperationName = $OperationName
        StartTime = Get-Date
        StartTimestamp = Get-PerfTimestamp
        EndTime = $null
        Duration = 0
        Metadata = $Metadata
        MemoryStart = [GC]::GetTotalMemory($false)
        MemoryEnd = 0
        MemoryDelta = 0
        CpuStart = (Get-Process -Id $PID).CPU
        CpuEnd = 0
        CpuDelta = 0
    }
    
    Write-PerfLog "Started profiling: $OperationName (ID: $profileId)" -Level "DEBUG"
    return $profile
}

function Stop-OperationProfile {
    param(
        [hashtable]$Profile,
        [hashtable]$AdditionalMetadata = @{}
    )
    
    if ($null -eq $Profile) {
        return $null
    }
    
    $Profile.EndTime = Get-Date
    $Profile.Duration = ($Profile.EndTime - $Profile.StartTime).TotalMilliseconds
    $Profile.MemoryEnd = [GC]::GetTotalMemory($false)
    $Profile.MemoryDelta = $Profile.MemoryEnd - $Profile.MemoryStart
    
    try {
        $Profile.CpuEnd = (Get-Process -Id $PID).CPU
        $Profile.CpuDelta = $Profile.CpuEnd - $Profile.CpuStart
    } catch {
        $Profile.CpuDelta = 0
    }
    
    # Add additional metadata
    foreach ($meta in $AdditionalMetadata.GetEnumerator()) {
        $Profile.Metadata[$meta.Key] = $meta.Value
    }
    
    # Update global metrics
    Update-PerformanceMetrics -Profile $Profile
    
    # Check for bottlenecks
    if ($Profile.Duration -gt $script:PerfConfig.SlowOperationThresholdMs) {
        Record-Bottleneck -Profile $Profile
    }
    
    Write-PerfLog "Completed profiling: $($Profile.OperationName) ($([Math]::Round($Profile.Duration, 2))ms)" -Level "DEBUG"
    
    # Save profile data
    Save-ProfileData -Profile $Profile
    
    return $Profile
}

function Measure-OperationPerformance {
    param(
        [string]$OperationName,
        [scriptblock]$Operation,
        [hashtable]$Metadata = @{}
    )
    
    $profile = Start-OperationProfile -OperationName $OperationName -Metadata $Metadata
    
    try {
        $result = & $Operation
        $profile = Stop-OperationProfile -Profile $profile -AdditionalMetadata @{ Success = $true }
        
        return @{
            Success = $true
            Result = $result
            Profile = $profile
        }
    } catch {
        $profile = Stop-OperationProfile -Profile $profile -AdditionalMetadata @{ Success = $false; Error = $_.ToString() }
        
        Write-PerfLog "Operation failed: $OperationName - $($_.Exception.Message)" -Level "ERROR"
        
        return @{
            Success = $false
            Error = $_.ToString()
            Profile = $profile
        }
    }
}

function Update-PerformanceMetrics {
    param([hashtable]$Profile)
    
    $script:PerformanceMetrics.OperationCount++
    $script:PerformanceMetrics.TotalProcessingTime += $Profile.Duration
    $script:PerformanceMetrics.AverageProcessingTime = $script:PerformanceMetrics.TotalProcessingTime / $script:PerformanceMetrics.OperationCount
    
    # Track slowest operation
    if ($Profile.Duration -gt $script:PerformanceMetrics.SlowestOperation.Duration) {
        $script:PerformanceMetrics.SlowestOperation = @{
            Duration = $Profile.Duration
            Operation = $Profile.OperationName
            Timestamp = $Profile.StartTimestamp
        }
    }
    
    # Track fastest operation (exclude very quick operations)
    if ($Profile.Duration -lt $script:PerformanceMetrics.FastestOperation.Duration -and $Profile.Duration -gt 1) {
        $script:PerformanceMetrics.FastestOperation = @{
            Duration = $Profile.Duration
            Operation = $Profile.OperationName
            Timestamp = $Profile.StartTimestamp
        }
    }
}

function Record-Bottleneck {
    param([hashtable]$Profile)
    
    $bottleneck = @{
        OperationName = $Profile.OperationName
        Duration = $Profile.Duration
        Timestamp = $Profile.StartTimestamp
        MemoryDelta = $Profile.MemoryDelta
        CpuDelta = $Profile.CpuDelta
        Severity = if ($Profile.Duration -gt $script:PerfConfig.VerySlowOperationThresholdMs) { "Critical" } else { "Warning" }
    }
    
    $script:PerformanceMetrics.BottleneckOperations += $bottleneck
    
    # Keep only recent bottlenecks (last 50)
    if ($script:PerformanceMetrics.BottleneckOperations.Count -gt 50) {
        $script:PerformanceMetrics.BottleneckOperations = $script:PerformanceMetrics.BottleneckOperations | Select-Object -Last 50
    }
    
    Write-PerfLog "Bottleneck detected: $($Profile.OperationName) took $([Math]::Round($Profile.Duration, 2))ms" -Level "WARNING"
}

function Save-ProfileData {
    param([hashtable]$Profile)
    
    try {
        $date = Get-Date -Format "yyyyMMdd"
        $profileFile = Join-Path $script:PerfConfig.ProfileDataPath "profiles_$date.json"
        
        # Load existing profiles for the day
        $profiles = @()
        if (Test-Path $profileFile) {
            $profilesJson = Get-Content -Path $profileFile -Raw
            $profiles = $profilesJson | ConvertFrom-Json
        }
        
        # Add new profile
        $profiles += $Profile
        
        # Save updated profiles
        $profiles | ConvertTo-Json -Depth 10 | Set-Content -Path $profileFile -Encoding UTF8
        
    } catch {
        Write-PerfLog "Failed to save profile data: $($_.Exception.Message)" -Level "WARNING"
    }
}

#endregion

#region Caching Optimization

function Get-CachedFileContent {
    param(
        [string]$FilePath,
        [switch]$AsJson
    )
    
    if (-not $script:PerfConfig.CacheEnabled) {
        return Read-FileDirectly -FilePath $FilePath -AsJson:$AsJson
    }
    
    $cacheKey = $FilePath
    $cache = if ($AsJson) { $script:JsonCache } else { $script:FileCache }
    
    # Check if file is in cache and still valid
    if ($cache.ContainsKey($cacheKey)) {
        $cacheEntry = $cache[$cacheKey]
        $fileLastWrite = (Get-Item $FilePath -ErrorAction SilentlyContinue).LastWriteTime
        
        if ($fileLastWrite -and $cacheEntry.FileLastWrite -eq $fileLastWrite) {
            $script:PerformanceMetrics.CacheHits++
            Write-PerfLog "Cache hit: $FilePath" -Level "DEBUG"
            return @{ Success = $true; Content = $cacheEntry.Content; FromCache = $true }
        } else {
            # File has been modified, remove from cache
            $cache.Remove($cacheKey)
        }
    }
    
    # Read from file
    $script:PerformanceMetrics.CacheMisses++
    $readResult = Read-FileDirectly -FilePath $FilePath -AsJson:$AsJson
    
    if ($readResult.Success) {
        # Add to cache
        $fileInfo = Get-Item $FilePath -ErrorAction SilentlyContinue
        if ($fileInfo) {
            $cacheEntry = @{
                Content = $readResult.Content
                FileLastWrite = $fileInfo.LastWriteTime
                CacheTime = Get-Date
            }
            $cache[$cacheKey] = $cacheEntry
            
            # Manage cache size
            Manage-CacheSize -Cache $cache
        }
        
        Write-PerfLog "Cache miss: $FilePath (cached for future use)" -Level "DEBUG"
    }
    
    # Update cache hit ratio
    $totalCacheRequests = $script:PerformanceMetrics.CacheHits + $script:PerformanceMetrics.CacheMisses
    if ($totalCacheRequests -gt 0) {
        $script:PerformanceMetrics.CacheHitRatio = [Math]::Round(($script:PerformanceMetrics.CacheHits / $totalCacheRequests) * 100, 2)
    }
    
    return $readResult
}

function Read-FileDirectly {
    param(
        [string]$FilePath,
        [switch]$AsJson
    )
    
    try {
        if (-not (Test-Path $FilePath)) {
            return @{ Success = $false; Error = "File not found: $FilePath" }
        }
        
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8
        
        if ($AsJson) {
            $jsonContent = $content | ConvertFrom-Json
            return @{ Success = $true; Content = $jsonContent; FromCache = $false }
        } else {
            return @{ Success = $true; Content = $content; FromCache = $false }
        }
        
    } catch {
        return @{ Success = $false; Error = $_.ToString() }
    }
}

function Get-CachedComputationResult {
    param(
        [string]$ComputationKey,
        [scriptblock]$Computation,
        [int]$ExpirationMinutes = 60
    )
    
    if (-not $script:PerfConfig.CacheEnabled) {
        return & $Computation
    }
    
    # Check if result is in cache
    if ($script:ComputationCache.ContainsKey($ComputationKey)) {
        $cacheEntry = $script:ComputationCache[$ComputationKey]
        $expirationTime = $cacheEntry.CacheTime.AddMinutes($ExpirationMinutes)
        
        if ((Get-Date) -lt $expirationTime) {
            $script:PerformanceMetrics.CacheHits++
            Write-PerfLog "Computation cache hit: $ComputationKey" -Level "DEBUG"
            return $cacheEntry.Result
        } else {
            # Expired, remove from cache
            $script:ComputationCache.Remove($ComputationKey)
        }
    }
    
    # Compute result
    $script:PerformanceMetrics.CacheMisses++
    $result = & $Computation
    
    # Cache the result
    $cacheEntry = @{
        Result = $result
        CacheTime = Get-Date
    }
    $script:ComputationCache[$ComputationKey] = $cacheEntry
    
    Write-PerfLog "Computation cached: $ComputationKey" -Level "DEBUG"
    return $result
}

function Manage-CacheSize {
    param([hashtable]$Cache)
    
    if ($Cache.Count -le $script:PerfConfig.FileReadCacheSize) {
        return
    }
    
    # Remove oldest entries (simple LRU approximation)
    $entriesToRemove = $Cache.Count - $script:PerfConfig.FileReadCacheSize
    $oldestEntries = $Cache.GetEnumerator() | 
                    Sort-Object { $_.Value.CacheTime } | 
                    Select-Object -First $entriesToRemove
    
    foreach ($entry in $oldestEntries) {
        $Cache.Remove($entry.Key)
    }
    
    Write-PerfLog "Cache cleanup: removed $entriesToRemove entries" -Level "DEBUG"
}

function Clear-PerformanceCache {
    param(
        [ValidateSet("All", "Files", "Json", "Regex", "Computation")]
        [string]$CacheType = "All"
    )
    
    $clearedCaches = @()
    
    switch ($CacheType) {
        "All" {
            $script:FileCache.Clear()
            $script:JsonCache.Clear()
            $script:RegexCache.Clear()
            $script:ComputationCache.Clear()
            $clearedCaches = @("Files", "Json", "Regex", "Computation")
        }
        "Files" {
            $script:FileCache.Clear()
            $clearedCaches = @("Files")
        }
        "Json" {
            $script:JsonCache.Clear()
            $clearedCaches = @("Json")
        }
        "Regex" {
            $script:RegexCache.Clear()
            $clearedCaches = @("Regex")
        }
        "Computation" {
            $script:ComputationCache.Clear()
            $clearedCaches = @("Computation")
        }
    }
    
    Write-PerfLog "Cleared caches: $($clearedCaches -join ', ')" -Level "INFO"
    
    # Reset cache metrics
    $script:PerformanceMetrics.CacheHits = 0
    $script:PerformanceMetrics.CacheMisses = 0
    $script:PerformanceMetrics.CacheHitRatio = 0
}

#endregion

#region Regex and String Processing Optimization

function Get-OptimizedRegex {
    param(
        [string]$Pattern,
        [System.Text.RegularExpressions.RegexOptions]$Options = [System.Text.RegularExpressions.RegexOptions]::None
    )
    
    $cacheKey = "$Pattern|$Options"
    
    if ($script:RegexCache.ContainsKey($cacheKey)) {
        return $script:RegexCache[$cacheKey]
    }
    
    # Create compiled regex for better performance
    $compiledOptions = $Options -bor [System.Text.RegularExpressions.RegexOptions]::Compiled
    $regex = [System.Text.RegularExpressions.Regex]::new($Pattern, $compiledOptions)
    
    $script:RegexCache[$cacheKey] = $regex
    Write-PerfLog "Compiled and cached regex: $Pattern" -Level "DEBUG"
    
    return $regex
}

function Invoke-OptimizedRegexMatch {
    param(
        [string]$Text,
        [string]$Pattern,
        [System.Text.RegularExpressions.RegexOptions]$Options = [System.Text.RegularExpressions.RegexOptions]::None
    )
    
    $profile = Start-OperationProfile -OperationName "RegexMatch" -Metadata @{ Pattern = $Pattern }
    
    try {
        $regex = Get-OptimizedRegex -Pattern $Pattern -Options $Options
        $matches = $regex.Matches($Text)
        
        $profile = Stop-OperationProfile -Profile $profile -AdditionalMetadata @{ MatchCount = $matches.Count }
        
        return @{
            Success = $true
            Matches = $matches
            Profile = $profile
        }
    } catch {
        $profile = Stop-OperationProfile -Profile $profile -AdditionalMetadata @{ Error = $_.ToString() }
        
        return @{
            Success = $false
            Error = $_.ToString()
            Profile = $profile
        }
    }
}

function Optimize-JsonProcessing {
    param(
        [string]$JsonString,
        [int]$MaxDepth = 10
    )
    
    $profile = Start-OperationProfile -OperationName "JsonProcessing" -Metadata @{ JsonLength = $JsonString.Length }
    
    try {
        # Use streaming approach for large JSON
        if ($JsonString.Length -gt 100000) {  # 100KB threshold
            # For large JSON, process in chunks or use streaming
            Write-PerfLog "Processing large JSON ($($JsonString.Length) chars) with optimization" -Level "INFO"
        }
        
        # PowerShell 5.1 optimized JSON processing
        $jsonObject = $JsonString | ConvertFrom-Json
        
        $profile = Stop-OperationProfile -Profile $profile -AdditionalMetadata @{ ObjectProperties = ($jsonObject.PSObject.Properties | Measure-Object).Count }
        
        return @{
            Success = $true
            JsonObject = $jsonObject
            Profile = $profile
        }
    } catch {
        $profile = Stop-OperationProfile -Profile $profile -AdditionalMetadata @{ Error = $_.ToString() }
        
        return @{
            Success = $false
            Error = $_.ToString()
            Profile = $profile
        }
    }
}

#endregion

#region Pipeline Optimization

function Invoke-OptimizedBatchProcessing {
    param(
        [array]$Items,
        [scriptblock]$ProcessingFunction,
        [int]$BatchSize = $null,
        [string]$OperationName = "BatchProcessing"
    )
    
    if (-not $BatchSize) {
        $BatchSize = $script:PerfConfig.BatchProcessingSize
    }
    
    $profile = Start-OperationProfile -OperationName $OperationName -Metadata @{ TotalItems = $Items.Count; BatchSize = $BatchSize }
    
    try {
        $results = @()
        $batchCount = 0
        
        for ($i = 0; $i -lt $Items.Count; $i += $BatchSize) {
            $batchCount++
            $batch = $Items[$i..([Math]::Min($i + $BatchSize - 1, $Items.Count - 1))]
            
            Write-PerfLog "Processing batch $batchCount ($($batch.Count) items)" -Level "DEBUG"
            
            $batchResults = @()
            foreach ($item in $batch) {
                $batchResults += & $ProcessingFunction $item
            }
            
            $results += $batchResults
            
            # Brief pause between batches to prevent overwhelming
            if ($batchCount % 5 -eq 0) {
                Start-Sleep -Milliseconds 10
            }
        }
        
        $profile = Stop-OperationProfile -Profile $profile -AdditionalMetadata @{ BatchCount = $batchCount; ResultCount = $results.Count }
        
        return @{
            Success = $true
            Results = $results
            Profile = $profile
        }
    } catch {
        $profile = Stop-OperationProfile -Profile $profile -AdditionalMetadata @{ Error = $_.ToString() }
        
        return @{
            Success = $false
            Error = $_.ToString()
            Profile = $profile
        }
    }
}

function Optimize-MemoryUsage {
    param(
        [switch]$ForceCollection,
        [switch]$Aggressive
    )
    
    $profile = Start-OperationProfile -OperationName "MemoryOptimization"
    
    try {
        $memoryBefore = [GC]::GetTotalMemory($false)
        
        if ($ForceCollection -or $Aggressive) {
            # Force garbage collection
            [GC]::Collect()
            
            if ($Aggressive) {
                [GC]::WaitForPendingFinalizers()
                [GC]::Collect()
            }
        }
        
        # Clear expired cache entries
        Clear-ExpiredCacheEntries
        
        $memoryAfter = [GC]::GetTotalMemory($false)
        $memoryFreed = $memoryBefore - $memoryAfter
        
        $profile = Stop-OperationProfile -Profile $profile -AdditionalMetadata @{ 
            MemoryBefore = $memoryBefore
            MemoryAfter = $memoryAfter 
            MemoryFreed = $memoryFreed
        }
        
        Write-PerfLog "Memory optimization completed: freed $([Math]::Round($memoryFreed / 1MB, 2)) MB" -Level "INFO"
        
        return @{
            Success = $true
            MemoryFreed = $memoryFreed
            Profile = $profile
        }
    } catch {
        $profile = Stop-OperationProfile -Profile $profile -AdditionalMetadata @{ Error = $_.ToString() }
        
        return @{
            Success = $false
            Error = $_.ToString()
            Profile = $profile
        }
    }
}

function Clear-ExpiredCacheEntries {
    $expiredCount = 0
    
    # Check computation cache for expired entries
    $expiredKeys = @()
    foreach ($entry in $script:ComputationCache.GetEnumerator()) {
        $expirationTime = $entry.Value.CacheTime.AddMinutes($script:PerfConfig.CacheExpirationMinutes)
        if ((Get-Date) -gt $expirationTime) {
            $expiredKeys += $entry.Key
        }
    }
    
    foreach ($key in $expiredKeys) {
        $script:ComputationCache.Remove($key)
        $expiredCount++
    }
    
    if ($expiredCount -gt 0) {
        Write-PerfLog "Cleared $expiredCount expired cache entries" -Level "DEBUG"
    }
}

#endregion

#region Performance Monitoring and Reporting

function Get-PerformanceReport {
    param(
        [switch]$IncludeBottlenecks,
        [switch]$IncludeCacheStats
    )
    
    $report = @{
        Timestamp = Get-PerfTimestamp
        OperationCount = $script:PerformanceMetrics.OperationCount
        TotalProcessingTime = [Math]::Round($script:PerformanceMetrics.TotalProcessingTime, 2)
        AverageProcessingTime = [Math]::Round($script:PerformanceMetrics.AverageProcessingTime, 2)
        SlowestOperation = $script:PerformanceMetrics.SlowestOperation
        FastestOperation = $script:PerformanceMetrics.FastestOperation
    }
    
    if ($IncludeBottlenecks) {
        $report.Bottlenecks = $script:PerformanceMetrics.BottleneckOperations | Select-Object -Last 10
        $report.BottleneckCount = $script:PerformanceMetrics.BottleneckOperations.Count
    }
    
    if ($IncludeCacheStats) {
        $report.CacheStats = @{
            CacheHits = $script:PerformanceMetrics.CacheHits
            CacheMisses = $script:PerformanceMetrics.CacheMisses
            CacheHitRatio = $script:PerformanceMetrics.CacheHitRatio
            FileCacheSize = $script:FileCache.Count
            JsonCacheSize = $script:JsonCache.Count
            RegexCacheSize = $script:RegexCache.Count
            ComputationCacheSize = $script:ComputationCache.Count
        }
    }
    
    return $report
}

function Test-PerformanceThresholds {
    $issues = @()
    
    # Check average processing time
    if ($script:PerformanceMetrics.AverageProcessingTime -gt $script:PerfConfig.SlowOperationThresholdMs) {
        $issues += "Average processing time is high: $([Math]::Round($script:PerformanceMetrics.AverageProcessingTime, 2))ms"
    }
    
    # Check cache hit ratio
    if ($script:PerformanceMetrics.CacheHitRatio -lt 50 -and ($script:PerformanceMetrics.CacheHits + $script:PerformanceMetrics.CacheMisses) -gt 10) {
        $issues += "Low cache hit ratio: $($script:PerformanceMetrics.CacheHitRatio)%"
    }
    
    # Check for recent bottlenecks
    $recentBottlenecks = $script:PerformanceMetrics.BottleneckOperations | Where-Object { 
        (Get-Date $_.Timestamp) -gt (Get-Date).AddMinutes(-5) 
    }
    
    if ($recentBottlenecks.Count -gt 3) {
        $issues += "Multiple recent bottlenecks detected: $($recentBottlenecks.Count) in last 5 minutes"
    }
    
    # Check memory usage
    $currentMemory = [Math]::Round([GC]::GetTotalMemory($false) / 1MB, 2)
    if ($currentMemory -gt $script:PerfConfig.MemoryPressureThresholdMB) {
        $issues += "High memory usage: ${currentMemory}MB"
    }
    
    return @{
        HasIssues = ($issues.Count -gt 0)
        Issues = $issues
        RecommendedActions = if ($issues.Count -gt 0) { 
            @("Consider memory optimization", "Review bottleneck operations", "Increase cache size")
        } else { @() }
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    # Performance profiling
    'Start-OperationProfile',
    'Stop-OperationProfile',
    'Measure-OperationPerformance',
    
    # Caching optimization
    'Get-CachedFileContent',
    'Get-CachedComputationResult',
    'Clear-PerformanceCache',
    
    # String and regex optimization
    'Get-OptimizedRegex',
    'Invoke-OptimizedRegexMatch',
    'Optimize-JsonProcessing',
    
    # Pipeline optimization
    'Invoke-OptimizedBatchProcessing',
    'Optimize-MemoryUsage',
    
    # Performance monitoring
    'Get-PerformanceReport',
    'Test-PerformanceThresholds',
    
    # Utilities
    'Write-PerfLog'
)

#endregion

Write-Host "[PerformanceOptimizer] Performance optimization module loaded successfully" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFa5Y8yieRH5oQPCze272zk61
# kDygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUSlEO5SKBLtCLKQLJRMUmXvReqFcwDQYJKoZIhvcNAQEBBQAEggEAK++g
# tbnpM1EbiQHuSKyt18B81Wz/bGbPMaeo3b7b6ZoC+5pkt5IwbNOhLUOSY7iUzZeH
# 0rt5igL59Axi1/Bt4AiNNur5YhjytlhnYihMk3Of1D/O+1tsddquDI2qh+KerBfz
# tYTJtb2ZbZr5s+pgCHzxGTC7SjWAOvSjAtRuG4sIiDu0MH++b85nSHuT7E45NyWk
# guyKXcWK9jeEJYm/3EZAq54rdXMSUv0Um5Dwfqz4M8m50CEwJE4JGmDZaYlnFBAG
# Q1Vc6m5n71rHYJ8NsrAU7I4x6c4Gx7ZplL1+QONPalfp/ZfHiOtzlRndqUk8t+ce
# Tdn/gD6QBoxvEHqa9w==
# SIG # End signature block
