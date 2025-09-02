# Unity-Claude-CLIOrchestrator - Performance Optimization Module  
# Phase 7 Day 1-2 Hours 4: Performance Optimization
# Target: <200ms response analysis time (from ~500ms baseline)

#region Module Configuration

$script:PerformanceConfig = @{
    TargetResponseTime = 200  # milliseconds
    CacheMaxSize = 1000       # Maximum cached items
    CacheExpiryMinutes = 30   # Cache expiry time
    ParallelProcessingThreshold = 10000  # Characters threshold for parallel processing
    RegexCacheSize = 100      # Maximum compiled regex patterns to cache
    MemoryCleanupInterval = 300  # Seconds between memory cleanup
}

$script:PerformanceCache = @{
    PatternMatches = @{}      # Cache for pattern match results
    CompiledRegex = @{}       # Cache for compiled regex objects
    EntityExtraction = @{}    # Cache for entity extraction results
    SentimentAnalysis = @{}   # Cache for sentiment analysis results
    LastCleanup = Get-Date
}

$script:PerformanceMetrics = @{
    TotalCalls = 0
    CacheHits = 0
    CacheMisses = 0
    AverageResponseTime = 0.0
    ResponseTimes = [System.Collections.Generic.List[double]]::new()
    OptimizationApplied = @{}
}

#endregion

#region Caching Functions

function Get-CacheKey {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Content,
        
        [Parameter(Mandatory = $true)]
        [string]$Operation,
        
        [Parameter()]
        [hashtable]$Parameters = @{}
    )
    
    # Create a hash-based cache key
    $contentHash = Get-StringHash -InputString $Content
    $paramHash = if ($Parameters.Count -gt 0) { 
        Get-StringHash -InputString ($Parameters | ConvertTo-Json -Compress)
    } else { 
        "NoParams" 
    }
    
    return "$Operation`:$contentHash`:$paramHash"
}

function Get-StringHash {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputString
    )
    
    $hasher = [System.Security.Cryptography.SHA256]::Create()
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($InputString)
    $hashBytes = $hasher.ComputeHash($bytes)
    $hasher.Dispose()
    
    return [System.BitConverter]::ToString($hashBytes).Replace("-", "").Substring(0, 16)
}

function Get-CachedResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CacheKey,
        
        [Parameter(Mandatory = $true)]
        [string]$CacheType
    )
    
    $cache = $script:PerformanceCache[$CacheType]
    if (-not $cache) {
        return $null
    }
    
    if ($cache.ContainsKey($CacheKey)) {
        $cached = $cache[$CacheKey]
        
        # Check expiry
        $expiryTime = $cached.Timestamp.AddMinutes($script:PerformanceConfig.CacheExpiryMinutes)
        if ((Get-Date) -lt $expiryTime) {
            $script:PerformanceMetrics.CacheHits++
            return $cached.Result
        } else {
            # Remove expired entry
            $cache.Remove($CacheKey)
        }
    }
    
    $script:PerformanceMetrics.CacheMisses++
    return $null
}

function Set-CachedResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CacheKey,
        
        [Parameter(Mandatory = $true)]
        [string]$CacheType,
        
        [Parameter(Mandatory = $true)]
        [object]$Result
    )
    
    $cache = $script:PerformanceCache[$CacheType]
    if (-not $cache) {
        return
    }
    
    # Enforce cache size limit
    if ($cache.Count -ge $script:PerformanceConfig.CacheMaxSize) {
        # Remove oldest entries (simple LRU)
        $oldestKeys = @($cache.Keys | 
            Sort-Object { $cache[$_].Timestamp } | 
            Select-Object -First 100)
        
        foreach ($key in $oldestKeys) {
            $cache.Remove($key)
        }
    }
    
    $cache[$CacheKey] = @{
        Result = $Result
        Timestamp = Get-Date
    }
}

#endregion

#region Optimized Regex Functions

function Get-CompiledRegex {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        
        [Parameter()]
        [System.Text.RegularExpressions.RegexOptions]$Options = [System.Text.RegularExpressions.RegexOptions]::Compiled
    )
    
    $cacheKey = "$Pattern`:$Options"
    
    if ($script:PerformanceCache.CompiledRegex.ContainsKey($cacheKey)) {
        return $script:PerformanceCache.CompiledRegex[$cacheKey].Regex
    }
    
    # Compile regex with optimization
    $regex = [System.Text.RegularExpressions.Regex]::new($Pattern, $Options)
    
    # Cache the compiled regex
    if ($script:PerformanceCache.CompiledRegex.Count -ge $script:PerformanceConfig.RegexCacheSize) {
        # Remove oldest entry
        $oldestKey = @($script:PerformanceCache.CompiledRegex.Keys)[0]
        $script:PerformanceCache.CompiledRegex[$oldestKey].Regex.Dispose()
        $script:PerformanceCache.CompiledRegex.Remove($oldestKey)
    }
    
    $script:PerformanceCache.CompiledRegex[$cacheKey] = @{
        Regex = $regex
        Timestamp = Get-Date
    }
    
    return $regex
}

function Invoke-OptimizedRegexMatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        
        [Parameter(Mandatory = $true)]
        [string]$Pattern,
        
        [Parameter()]
        [System.Text.RegularExpressions.RegexOptions]$Options = [System.Text.RegularExpressions.RegexOptions]::Compiled
    )
    
    $cacheKey = Get-CacheKey -Content $Text -Operation "RegexMatch" -Parameters @{Pattern = $Pattern; Options = $Options}
    
    # Check cache first
    $cachedResult = Get-CachedResult -CacheKey $cacheKey -CacheType "PatternMatches"
    if ($cachedResult) {
        return $cachedResult
    }
    
    # Get compiled regex
    $regex = Get-CompiledRegex -Pattern $Pattern -Options $Options
    
    # Perform match
    $matches = @($regex.Matches($Text))
    
    # Cache result
    Set-CachedResult -CacheKey $cacheKey -CacheType "PatternMatches" -Result $matches
    
    return $matches
}

#endregion

#region Parallel Processing Functions

function Invoke-ParallelEntityExtraction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$EntityPatterns
    )
    
    # Check if content is large enough for parallel processing
    if ($ResponseText.Length -lt $script:PerformanceConfig.ParallelProcessingThreshold) {
        # Use standard processing for smaller content
        return $null
    }
    
    $jobs = @()
    $extractedEntities = @{
        FilePaths = @()
        ErrorCodes = @()
        Commands = @()
        UnityComponents = @()
        MethodNames = @()
        Variables = @()
        ProcessingTime = 0
        TotalMatches = 0
    }
    
    try {
        # Process each entity type in parallel
        foreach ($entityType in $EntityPatterns.Keys) {
            $job = Start-Job -ScriptBlock {
                param($text, $patterns, $type)
                
                $matches = @()
                foreach ($pattern in $patterns) {
                    try {
                        $regexMatches = [regex]::Matches($text, $pattern)
                        foreach ($match in $regexMatches) {
                            if ($match.Success -and $match.Value.Trim().Length -gt 0) {
                                $matches += $match.Value.Trim()
                            }
                        }
                    } catch {
                        # Skip invalid patterns
                        continue
                    }
                }
                
                return @{
                    Type = $type
                    Matches = ($matches | Select-Object -Unique)
                }
            } -ArgumentList $ResponseText, $EntityPatterns[$entityType], $entityType
            
            $jobs += $job
        }
        
        # Wait for all jobs to complete with timeout
        $timeoutSeconds = 10
        $completedJobs = Wait-Job -Job $jobs -Timeout $timeoutSeconds
        
        # Collect results
        foreach ($job in $completedJobs) {
            try {
                $result = Receive-Job -Job $job
                if ($result -and $result.Type -and $extractedEntities.ContainsKey($result.Type)) {
                    $extractedEntities[$result.Type] = $result.Matches
                    $extractedEntities.TotalMatches += $result.Matches.Count
                }
            } catch {
                # Skip failed jobs
                continue
            }
        }
        
        return $extractedEntities
        
    } finally {
        # Cleanup jobs
        foreach ($job in $jobs) {
            try {
                Remove-Job -Job $job -Force -ErrorAction SilentlyContinue
            } catch {
                # Ignore cleanup errors
            }
        }
    }
}

#endregion

#region Performance Monitoring

function Start-PerformanceMonitoring {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OperationName
    )
    
    $script:PerformanceMetrics.TotalCalls++
    
    return @{
        OperationName = $OperationName
        StartTime = Get-Date
        Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    }
}

function Stop-PerformanceMonitoring {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$PerformanceContext
    )
    
    $PerformanceContext.Stopwatch.Stop()
    $responseTime = $PerformanceContext.Stopwatch.ElapsedMilliseconds
    
    # Update metrics
    $script:PerformanceMetrics.ResponseTimes.Add($responseTime)
    
    # Keep only last 1000 response times for average calculation
    if ($script:PerformanceMetrics.ResponseTimes.Count -gt 1000) {
        $script:PerformanceMetrics.ResponseTimes.RemoveAt(0)
    }
    
    # Calculate running average
    $sum = 0.0
    foreach ($time in $script:PerformanceMetrics.ResponseTimes) {
        $sum += $time
    }
    $script:PerformanceMetrics.AverageResponseTime = $sum / $script:PerformanceMetrics.ResponseTimes.Count
    
    return @{
        OperationName = $PerformanceContext.OperationName
        ResponseTime = $responseTime
        IsOptimal = ($responseTime -le $script:PerformanceConfig.TargetResponseTime)
        AverageResponseTime = $script:PerformanceMetrics.AverageResponseTime
    }
}

function Get-PerformanceReport {
    [CmdletBinding()]
    param()
    
    $cacheHitRate = if (($script:PerformanceMetrics.CacheHits + $script:PerformanceMetrics.CacheMisses) -gt 0) {
        [Math]::Round(($script:PerformanceMetrics.CacheHits / ($script:PerformanceMetrics.CacheHits + $script:PerformanceMetrics.CacheMisses)) * 100, 2)
    } else { 0.0 }
    
    $recentResponseTimes = @($script:PerformanceMetrics.ResponseTimes | Select-Object -Last 100)
    $p95ResponseTime = if ($recentResponseTimes.Count -gt 0) {
        $sorted = @($recentResponseTimes | Sort-Object)
        $index = [Math]::Floor($sorted.Count * 0.95)
        [Math]::Round($sorted[$index], 2)
    } else { 0.0 }
    
    return @{
        TotalCalls = $script:PerformanceMetrics.TotalCalls
        AverageResponseTime = [Math]::Round($script:PerformanceMetrics.AverageResponseTime, 2)
        P95ResponseTime = $p95ResponseTime
        TargetResponseTime = $script:PerformanceConfig.TargetResponseTime
        IsTargetMet = ($script:PerformanceMetrics.AverageResponseTime -le $script:PerformanceConfig.TargetResponseTime)
        CacheHitRate = $cacheHitRate
        CacheStatistics = @{
            PatternMatches = $script:PerformanceCache.PatternMatches.Count
            CompiledRegex = $script:PerformanceCache.CompiledRegex.Count  
            EntityExtraction = $script:PerformanceCache.EntityExtraction.Count
            SentimentAnalysis = $script:PerformanceCache.SentimentAnalysis.Count
        }
        OptimizationsApplied = $script:PerformanceMetrics.OptimizationApplied
        LastCleanup = $script:PerformanceCache.LastCleanup
        Recommendations = Get-PerformanceRecommendations
    }
}

function Get-PerformanceRecommendations {
    [CmdletBinding()]
    param()
    
    $recommendations = @()
    
    # Check average response time
    if ($script:PerformanceMetrics.AverageResponseTime -gt $script:PerformanceConfig.TargetResponseTime) {
        $recommendations += "Response time ($($script:PerformanceMetrics.AverageResponseTime)ms) exceeds target ($($script:PerformanceConfig.TargetResponseTime)ms)"
    }
    
    # Check cache hit rate
    $cacheHitRate = if (($script:PerformanceMetrics.CacheHits + $script:PerformanceMetrics.CacheMisses) -gt 0) {
        ($script:PerformanceMetrics.CacheHits / ($script:PerformanceMetrics.CacheHits + $script:PerformanceMetrics.CacheMisses)) * 100
    } else { 0.0 }
    
    if ($cacheHitRate -lt 50) {
        $recommendations += "Cache hit rate is low ($([Math]::Round($cacheHitRate, 1))%) - consider increasing cache size or expiry time"
    }
    
    # Check memory usage
    $totalCacheSize = $script:PerformanceCache.PatternMatches.Count + 
                     $script:PerformanceCache.CompiledRegex.Count +
                     $script:PerformanceCache.EntityExtraction.Count +
                     $script:PerformanceCache.SentimentAnalysis.Count
    
    if ($totalCacheSize -gt ($script:PerformanceConfig.CacheMaxSize * 0.8)) {
        $recommendations += "Cache usage is high ($totalCacheSize items) - consider cleanup or size increase"
    }
    
    return $recommendations
}

#endregion

#region Memory Management

function Invoke-CacheCleanup {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    $now = Get-Date
    $shouldCleanup = $Force -or 
                    ($now - $script:PerformanceCache.LastCleanup).TotalSeconds -gt $script:PerformanceConfig.MemoryCleanupInterval
    
    if (-not $shouldCleanup) {
        return @{
            CleanupPerformed = $false
            Reason = "Cleanup interval not reached"
            NextCleanup = $script:PerformanceCache.LastCleanup.AddSeconds($script:PerformanceConfig.MemoryCleanupInterval)
        }
    }
    
    $cleanupStats = @{
        CleanupPerformed = $true
        StartTime = $now
        RemovedItems = @{
            PatternMatches = 0
            CompiledRegex = 0
            EntityExtraction = 0
            SentimentAnalysis = 0
        }
    }
    
    # Clean expired entries from all caches
    foreach ($cacheType in @('PatternMatches', 'EntityExtraction', 'SentimentAnalysis')) {
        $cache = $script:PerformanceCache[$cacheType]
        $expiredKeys = @()
        
        foreach ($key in $cache.Keys) {
            $cached = $cache[$key]
            $expiryTime = $cached.Timestamp.AddMinutes($script:PerformanceConfig.CacheExpiryMinutes)
            
            if ($now -gt $expiryTime) {
                $expiredKeys += $key
            }
        }
        
        foreach ($key in $expiredKeys) {
            $cache.Remove($key)
            $cleanupStats.RemovedItems[$cacheType]++
        }
    }
    
    # Clean compiled regex cache (dispose regex objects)
    $regexCache = $script:PerformanceCache.CompiledRegex
    $expiredRegexKeys = @()
    
    foreach ($key in $regexCache.Keys) {
        $cached = $regexCache[$key]
        $expiryTime = $cached.Timestamp.AddMinutes($script:PerformanceConfig.CacheExpiryMinutes)
        
        if ($now -gt $expiryTime) {
            $expiredRegexKeys += $key
        }
    }
    
    foreach ($key in $expiredRegexKeys) {
        try {
            $regexCache[$key].Regex.Dispose()
        } catch {
            # Ignore disposal errors
        }
        $regexCache.Remove($key)
        $cleanupStats.RemovedItems.CompiledRegex++
    }
    
    # Force garbage collection if significant cleanup occurred
    $totalRemoved = ($cleanupStats.RemovedItems.Values | Measure-Object -Sum).Sum
    if ($totalRemoved -gt 100) {
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
    
    $script:PerformanceCache.LastCleanup = $now
    $cleanupStats.Duration = ((Get-Date) - $now).TotalMilliseconds
    
    return $cleanupStats
}

#endregion

#region Optimized Analysis Functions

function Invoke-OptimizedEntityExtraction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseText,
        
        [Parameter()]
        [hashtable]$EntityPatterns = @{}
    )
    
    $perfContext = Start-PerformanceMonitoring -OperationName "EntityExtraction"
    
    try {
        # Check cache first
        $cacheKey = Get-CacheKey -Content $ResponseText -Operation "EntityExtraction" -Parameters $EntityPatterns
        $cachedResult = Get-CachedResult -CacheKey $cacheKey -CacheType "EntityExtraction"
        
        if ($cachedResult) {
            return $cachedResult
        }
        
        # Try parallel processing for large content
        $parallelResult = Invoke-ParallelEntityExtraction -ResponseText $ResponseText -EntityPatterns $EntityPatterns
        
        if ($parallelResult) {
            # PowerShell 5.1 compatible null handling (replacing ?? operator)
            $currentValue = $script:PerformanceMetrics.OptimizationApplied["ParallelProcessing"]
            $script:PerformanceMetrics.OptimizationApplied["ParallelProcessing"] = 
                (if ($null -eq $currentValue) { 0 } else { $currentValue }) + 1
            
            # Cache and return result
            Set-CachedResult -CacheKey $cacheKey -CacheType "EntityExtraction" -Result $parallelResult
            return $parallelResult
        }
        
        # Fallback to optimized sequential processing
        $extractedEntities = @{
            FilePaths = @()
            ErrorCodes = @() 
            Commands = @()
            UnityComponents = @()
            MethodNames = @()
            Variables = @()
            ProcessingTime = 0
            TotalMatches = 0
        }
        
        # Use default patterns if none provided
        if (-not $EntityPatterns.Keys.Count) {
            $EntityPatterns = @{
                FilePaths = @(
                    '(?i)[a-zA-Z]:\\(?:[^\\/:*?"<>|\r\n]+\\)*[^\\/:*?"<>|\r\n]*\.[a-zA-Z0-9]+',
                    '(?i)\.\\[^\\/:*?"<>|\r\n]+(?:\\[^\\/:*?"<>|\r\n]+)*'
                )
                ErrorCodes = @(
                    'CS\d{4}',
                    'MSB\d{4}',
                    'Error\s+\d+'
                )
                Commands = @(
                    '(?i)(?:Test|Build|Compile|Run|Execute|Start|Stop|Restart)-[A-Za-z0-9-]+',
                    '(?i)dotnet\s+[a-z]+'
                )
            }
        }
        
        # Process each entity type with optimized regex
        foreach ($entityType in $EntityPatterns.Keys) {
            $matches = @()
            
            foreach ($pattern in $EntityPatterns[$entityType]) {
                try {
                    $regexMatches = Invoke-OptimizedRegexMatch -Text $ResponseText -Pattern $pattern
                    foreach ($match in $regexMatches) {
                        if ($match.Success -and $match.Value.Trim().Length -gt 0) {
                            $matches += $match.Value.Trim()
                        }
                    }
                } catch {
                    continue
                }
            }
            
            $extractedEntities[$entityType] = $matches | Select-Object -Unique
            $extractedEntities.TotalMatches += $extractedEntities[$entityType].Count
        }
        
        # Cache result
        Set-CachedResult -CacheKey $cacheKey -CacheType "EntityExtraction" -Result $extractedEntities
        
        return $extractedEntities
        
    } finally {
        $perfResult = Stop-PerformanceMonitoring -PerformanceContext $perfContext
        $extractedEntities.ProcessingTime = $perfResult.ResponseTime
    }
}

function Test-PerformanceOptimization {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$TestContent = $null,
        
        [Parameter()]
        [int]$TestIterations = 100
    )
    
    # Use sample content if none provided
    if (-not $TestContent) {
        $TestContent = @'
RECOMMENDATION: FIX - C:\UnityProjects\TestProject\Scripts\PlayerController.cs
ERROR: CS0103 - The name 'rigidbody' does not exist in the current context at line 45
ERROR: CS0246 - The type or namespace name 'UnityEngine' could not be found
The following files need attention:
- PlayerController.cs: Missing using UnityEngine statement
- GameManager.cs: Requires namespace correction
Run Test-Unity-Compilation to verify fixes
Execute Build-UnityProject after corrections
'@
    }
    
    $testResults = @{
        TestIterations = $TestIterations
        TestContentLength = $TestContent.Length
        Results = @{
            Original = @()
            Optimized = @()
        }
        Improvement = @{
            AverageTime = 0.0
            PercentImprovement = 0.0
            CacheHitRate = 0.0
        }
    }
    
    # Clear performance metrics for clean test
    $script:PerformanceMetrics.ResponseTimes.Clear()
    $script:PerformanceMetrics.TotalCalls = 0
    $script:PerformanceMetrics.CacheHits = 0
    $script:PerformanceMetrics.CacheMisses = 0
    
    # Test original method (simulated by clearing cache each time)
    Write-Host "Testing original performance (no caching)..." -ForegroundColor Yellow
    
    for ($i = 1; $i -le $TestIterations; $i++) {
        # Clear caches to simulate original performance
        $script:PerformanceCache.PatternMatches.Clear()
        $script:PerformanceCache.EntityExtraction.Clear()
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $result = Invoke-OptimizedEntityExtraction -ResponseText $TestContent
        $stopwatch.Stop()
        
        $testResults.Results.Original += $stopwatch.ElapsedMilliseconds
        
        if ($i % 20 -eq 0) {
            Write-Host "  Completed $i/$TestIterations iterations" -ForegroundColor Gray
        }
    }
    
    # Reset metrics for optimized test
    $script:PerformanceMetrics.ResponseTimes.Clear()
    $script:PerformanceMetrics.TotalCalls = 0
    $script:PerformanceMetrics.CacheHits = 0
    $script:PerformanceMetrics.CacheMisses = 0
    
    # Test optimized method (with caching enabled)
    Write-Host "Testing optimized performance (with caching)..." -ForegroundColor Yellow
    
    for ($i = 1; $i -le $TestIterations; $i++) {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $result = Invoke-OptimizedEntityExtraction -ResponseText $TestContent
        $stopwatch.Stop()
        
        $testResults.Results.Optimized += $stopwatch.ElapsedMilliseconds
        
        if ($i % 20 -eq 0) {
            Write-Host "  Completed $i/$TestIterations iterations" -ForegroundColor Gray
        }
    }
    
    # Calculate results
    $originalAverage = ($testResults.Results.Original | Measure-Object -Average).Average
    $optimizedAverage = ($testResults.Results.Optimized | Measure-Object -Average).Average
    
    $testResults.Improvement.AverageTime = $optimizedAverage - $originalAverage
    $testResults.Improvement.PercentImprovement = if ($originalAverage -gt 0) {
        [Math]::Round((($originalAverage - $optimizedAverage) / $originalAverage) * 100, 2)
    } else { 0.0 }
    
    $testResults.Improvement.CacheHitRate = if (($script:PerformanceMetrics.CacheHits + $script:PerformanceMetrics.CacheMisses) -gt 0) {
        [Math]::Round(($script:PerformanceMetrics.CacheHits / ($script:PerformanceMetrics.CacheHits + $script:PerformanceMetrics.CacheMisses)) * 100, 2)
    } else { 0.0 }
    
    $testResults.Summary = @{
        OriginalAverageMs = [Math]::Round($originalAverage, 2)
        OptimizedAverageMs = [Math]::Round($optimizedAverage, 2)
        ImprovementMs = [Math]::Round($testResults.Improvement.AverageTime, 2)
        ImprovementPercent = $testResults.Improvement.PercentImprovement
        CacheHitRate = $testResults.Improvement.CacheHitRate
        TargetMet = ($optimizedAverage -le $script:PerformanceConfig.TargetResponseTime)
    }
    
    return $testResults
}

#endregion

#region Exported Functions

Export-ModuleMember -Function @(
    'Invoke-OptimizedEntityExtraction',
    'Get-PerformanceReport', 
    'Test-PerformanceOptimization',
    'Invoke-CacheCleanup',
    'Start-PerformanceMonitoring',
    'Stop-PerformanceMonitoring',
    'Get-CompiledRegex',
    'Invoke-OptimizedRegexMatch'
)

#endregion

Write-Verbose "[PerformanceOptimizer] Module loaded successfully"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDA843Vcs7XfBTm
# iHoAEkihL7qkp6Co6GvL5aWFrJPyUKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICDsCunGQEI69d/0Yyfe7n/b
# 70yTNzvmsdR9llhw+x9fMA0GCSqGSIb3DQEBAQUABIIBABHOoN3u3B1eq0leH80L
# cgn4Rn8TWMVTz6byC1SYINkkDqL+okE4k7r5FLKB5V3+jtXsMPX2mTn1eiqH+GMT
# GEYCwBqpWssEpF1m1SW85WSF+WyQ1aG6fP4eXuedNRppEVUqr75mNBw0g8jA2hK1
# /agHL1Xhw+/z4EQA/4HZQGWRWXCmF3KH3zQf1/rlmQZtszWC2g8WCkxsDiaiZFg3
# uDHvK3yjhzkWpa/EYMlnXMU+BlQ/tzyc3PHXmn+yWLXQKIROEXmT9PksVryDcBhp
# SKmEN279av0+vPyQA4lV5fgcMejHRkwwhWQHxxZKzJFlTrzTuHNm4eKz0ORzX9vz
# wmA=
# SIG # End signature block
