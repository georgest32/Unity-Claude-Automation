# Module: Unity-Claude-PerformanceOptimizer

**Version:** 0.0  
**Path:** `C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-PerformanceOptimizer.psm1`  
**Last Modified:** 08/20/2025 17:25:22  
**Total Functions:** 22  

## Description


## Exported Commands
- `Clear-PerformanceCache`
- `Get-CachedComputationResult`
- `Get-CachedFileContent`
- `Get-OptimizedRegex`
- `Get-PerformanceReport`
- `Invoke-OptimizedBatchProcessing`
- `Invoke-OptimizedRegexMatch`
- `Measure-OperationPerformance`
- `Optimize-JsonProcessing`
- `Optimize-MemoryUsage`
- `Start-OperationProfile`
- `Stop-OperationProfile`
- `Test-PerformanceThresholds`
- `Write-PerfLog`


## Functions


### Write-PerfLog
**Lines:** 73 - 103

**Synopsis:** 
Write-PerfLog [[-Message] <string>] [[-Level] <string>] [[-Component] <string>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARNING", "ERROR", "DEBUG")]
        [string]$Level = "INFO",
        [string]$Component = "PerfOptimizer"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
``` 
### Get-PerfTimestamp
**Lines:** 105 - 107




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    return Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
}
``` 
### New-PerformanceId
**Lines:** 109 - 111




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    return [System.Guid]::NewGuid().ToString("N").Substring(0, 8)
}
``` 
### Start-OperationProfile
**Lines:** 117 - 147

**Synopsis:** 
Start-OperationProfile [[-OperationName] <string>] [[-Metadata] <hashtable>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$OperationName,
        [hashtable]$Metadata = @{}
    )
    
    if (-not $script:PerfConfig.ProfilingEnabled) {
        return $null
    }
``` 
### Stop-OperationProfile
**Lines:** 149 - 190

**Synopsis:** 
Stop-OperationProfile [[-Profile] <hashtable>] [[-AdditionalMetadata] <hashtable>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [hashtable]$Profile,
        [hashtable]$AdditionalMetadata = @{}
    )
    
    if ($null -eq $Profile) {
        return $null
    }
``` 
### Measure-OperationPerformance
**Lines:** 192 - 221

**Synopsis:** 
Measure-OperationPerformance [[-OperationName] <string>] [[-Operation] <scriptblock>] [[-Metadata] <hashtable>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$OperationName,
        [scriptblock]$Operation,
        [hashtable]$Metadata = @{}
    )
    
    $profile = Start-OperationProfile -OperationName $OperationName -Metadata $Metadata
    
    try {
``` 
### Update-PerformanceMetrics
**Lines:** 223 - 247

**Synopsis:** 
Update-PerformanceMetrics [[-AgentId] <string>] [[-MetricUpdates] <hashtable>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param([hashtable]$Profile)
    
    $script:PerformanceMetrics.OperationCount++
    $script:PerformanceMetrics.TotalProcessingTime += $Profile.Duration
    $script:PerformanceMetrics.AverageProcessingTime = $script:PerformanceMetrics.TotalProcessingTime / $script:PerformanceMetrics.OperationCount
    
    # Track slowest operation
    if ($Profile.Duration -gt $script:PerformanceMetrics.SlowestOperation.Duration) {
        $script:PerformanceMetrics.SlowestOperation = @{
``` 
### Record-Bottleneck
**Lines:** 249 - 269




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param([hashtable]$Profile)
    
    $bottleneck = @{
        OperationName = $Profile.OperationName
        Duration = $Profile.Duration
        Timestamp = $Profile.StartTimestamp
        MemoryDelta = $Profile.MemoryDelta
        CpuDelta = $Profile.CpuDelta
        Severity = if ($Profile.Duration -gt $script:PerfConfig.VerySlowOperationThresholdMs) { "Critical" } else { "Warning" }
``` 
### Save-ProfileData
**Lines:** 271 - 294




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param([hashtable]$Profile)
    
    try {
        $date = Get-Date -Format "yyyyMMdd"
        $profileFile = Join-Path $script:PerfConfig.ProfileDataPath "profiles_$date.json"
        
        # Load existing profiles for the day
        $profiles = @()
        if (Test-Path $profileFile) {
``` 
### Get-CachedFileContent
**Lines:** 300 - 357

**Synopsis:** 
Get-CachedFileContent [[-FilePath] <string>] [-AsJson]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$FilePath,
        [switch]$AsJson
    )
    
    if (-not $script:PerfConfig.CacheEnabled) {
        return Read-FileDirectly -FilePath $FilePath -AsJson:$AsJson
    }
``` 
### Read-FileDirectly
**Lines:** 359 - 382




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$FilePath,
        [switch]$AsJson
    )
    
    try {
        if (-not (Test-Path $FilePath)) {
            return @{ Success = $false; Error = "File not found: $FilePath" }
        }
``` 
### Get-CachedComputationResult
**Lines:** 384 - 423

**Synopsis:** 
Get-CachedComputationResult [[-ComputationKey] <string>] [[-Computation] <scriptblock>] [[-ExpirationMinutes] <int>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$ComputationKey,
        [scriptblock]$Computation,
        [int]$ExpirationMinutes = 60
    )
    
    if (-not $script:PerfConfig.CacheEnabled) {
        return & $Computation
    }
``` 
### Manage-CacheSize
**Lines:** 425 - 443




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param([hashtable]$Cache)
    
    if ($Cache.Count -le $script:PerfConfig.FileReadCacheSize) {
        return
    }
    
    # Remove oldest entries (simple LRU approximation)
    $entriesToRemove = $Cache.Count - $script:PerfConfig.FileReadCacheSize
    $oldestEntries = $Cache.GetEnumerator() |
``` 
### Clear-PerformanceCache
**Lines:** 445 - 485

**Synopsis:** 
Clear-PerformanceCache [[-CacheType] <string>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [ValidateSet("All", "Files", "Json", "Regex", "Computation")]
        [string]$CacheType = "All"
    )
    
    $clearedCaches = @()
    
    switch ($CacheType) {
        "All" {
``` 
### Get-OptimizedRegex
**Lines:** 491 - 511

**Synopsis:** 
Get-OptimizedRegex [[-Pattern] <string>] [[-Options] <RegexOptions>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$Pattern,
        [System.Text.RegularExpressions.RegexOptions]$Options = [System.Text.RegularExpressions.RegexOptions]::None
    )
    
    $cacheKey = "$Pattern|$Options"
    
    if ($script:RegexCache.ContainsKey($cacheKey)) {
        return $script:RegexCache[$cacheKey]
``` 
### Invoke-OptimizedRegexMatch
**Lines:** 513 - 542

**Synopsis:** 
Invoke-OptimizedRegexMatch [[-Text] <string>] [[-Pattern] <string>] [[-Options] <RegexOptions>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$Text,
        [string]$Pattern,
        [System.Text.RegularExpressions.RegexOptions]$Options = [System.Text.RegularExpressions.RegexOptions]::None
    )
    
    $profile = Start-OperationProfile -OperationName "RegexMatch" -Metadata @{ Pattern = $Pattern }
    
    try {
``` 
### Optimize-JsonProcessing
**Lines:** 544 - 578

**Synopsis:** 
Optimize-JsonProcessing [[-JsonString] <string>] [[-MaxDepth] <int>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [string]$JsonString,
        [int]$MaxDepth = 10
    )
    
    $profile = Start-OperationProfile -OperationName "JsonProcessing" -Metadata @{ JsonLength = $JsonString.Length }
    
    try {
        # Use streaming approach for large JSON
``` 
### Invoke-OptimizedBatchProcessing
**Lines:** 584 - 637

**Synopsis:** 
Invoke-OptimizedBatchProcessing [[-Items] <array>] [[-ProcessingFunction] <scriptblock>] [[-BatchSize] <int>] [[-OperationName] <string>]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [array]$Items,
        [scriptblock]$ProcessingFunction,
        [int]$BatchSize = $null,
        [string]$OperationName = "BatchProcessing"
    )
    
    if (-not $BatchSize) {
        $BatchSize = $script:PerfConfig.BatchProcessingSize
``` 
### Optimize-MemoryUsage
**Lines:** 639 - 688

**Synopsis:** 
Optimize-MemoryUsage [-ForceCollection] [-Aggressive]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [switch]$ForceCollection,
        [switch]$Aggressive
    )
    
    $profile = Start-OperationProfile -OperationName "MemoryOptimization"
    
    try {
        $memoryBefore = [GC]::GetTotalMemory($false)
``` 
### Clear-ExpiredCacheEntries
**Lines:** 690 - 710




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    $expiredCount = 0
    
    # Check computation cache for expired entries
    $expiredKeys = @()
    foreach ($entry in $script:ComputationCache.GetEnumerator()) {
        $expirationTime = $entry.Value.CacheTime.AddMinutes($script:PerfConfig.CacheExpirationMinutes)
        if ((Get-Date) -gt $expirationTime) {
            $expiredKeys += $entry.Key
        }
``` 
### Get-PerformanceReport
**Lines:** 716 - 749

**Synopsis:** 
Get-PerformanceReport [-IncludeBottlenecks] [-IncludeCacheStats]




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    param(
        [switch]$IncludeBottlenecks,
        [switch]$IncludeCacheStats
    )
    
    $report = @{
        Timestamp = Get-PerfTimestamp
        OperationCount = $script:PerformanceMetrics.OperationCount
        TotalProcessingTime = [Math]::Round($script:PerformanceMetrics.TotalProcessingTime, 2)
``` 
### Test-PerformanceThresholds
**Lines:** 751 - 786

**Synopsis:** 
Test-PerformanceThresholds 




**Parameters:**
*No parameters*

**Code Preview:**
```powershell
{
    $issues = @()
    
    # Check average processing time
    if ($script:PerformanceMetrics.AverageProcessingTime -gt $script:PerfConfig.SlowOperationThresholdMs) {
        $issues += "Average processing time is high: $([Math]::Round($script:PerformanceMetrics.AverageProcessingTime, 2))ms"
    }
    
    # Check cache hit ratio
    if ($script:PerformanceMetrics.CacheHitRatio -lt 50 -and ($script:PerformanceMetrics.CacheHits + $script:PerformanceMetrics.CacheMisses) -gt 10) {
```

---
*Generated by Unity-Claude Documentation System*
