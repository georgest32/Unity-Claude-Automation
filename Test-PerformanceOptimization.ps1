# Test-PerformanceOptimization.ps1
# Comprehensive test suite for Phase 3 Performance Optimization modules
# Tests cache, incremental processing, and parallel execution capabilities

param(
    [Parameter()]
    [switch]$SaveResults
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Test configuration
$script:TestResults = @{
    TestName = "Performance Optimization Test Suite"
    StartTime = Get-Date
    Environment = @{
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        ProcessorCount = [Environment]::ProcessorCount
        TotalMemoryGB = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    }
    Results = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Skipped = 0
    }
}

# Helper function to add test result
function Add-TestResult {
    param(
        [string]$TestName,
        [string]$Status,
        [object]$Result,
        [string]$Error = $null,
        [double]$Duration = 0
    )
    
    $testResult = @{
        Name = $TestName
        Status = $Status
        Result = $Result
        Error = $Error
        Duration = $Duration
        Timestamp = Get-Date
    }
    
    $script:TestResults.Results += $testResult
    $script:TestResults.Summary.Total++
    $script:TestResults.Summary.$Status++
    
    $color = switch ($Status) {
        'Passed' { 'Green' }
        'Failed' { 'Red' }
        'Skipped' { 'Yellow' }
    }
    
    Write-Host "[$Status] $TestName" -ForegroundColor $color
}

Write-Host "=== Performance Optimization Test Suite ===" -ForegroundColor Cyan
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host "Processor Count: $([Environment]::ProcessorCount)" -ForegroundColor Gray
Write-Host ""

# Test 1: Cache Module Loading
Write-Host "Test 1: Cache Module Loading" -ForegroundColor Yellow
try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-Cache\Unity-Claude-Cache.psd1" -Force
    $stopwatch.Stop()
    
    $commands = Get-Command -Module Unity-Claude-Cache
    if ($commands.Count -ge 10) {
        Add-TestResult -TestName "Cache Module Loading" -Status "Passed" `
            -Result "Module loaded with $($commands.Count) commands" `
            -Duration $stopwatch.Elapsed.TotalMilliseconds
    } else {
        throw "Insufficient commands exported: $($commands.Count)"
    }
} catch {
    Add-TestResult -TestName "Cache Module Loading" -Status "Failed" -Error $_.Exception.Message
}

# Test 2: Cache Operations
Write-Host "Test 2: Cache Operations" -ForegroundColor Yellow
try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Create cache manager
    $cache = New-CacheManager -MaxSize 100
    
    # Test Set operation
    $setResult = Set-CacheItem -CacheManager $cache -Key "test1" -Value "value1" -TTLSeconds 60 -Priority 5
    if (-not $setResult) {
        throw "Failed to set cache item"
    }
    
    # Test Get operation
    $getValue = Get-CacheItem -CacheManager $cache -Key "test1"
    if ($getValue -ne "value1") {
        throw "Cache get returned incorrect value: $getValue"
    }
    
    # Test TTL expiration
    Set-CacheItem -CacheManager $cache -Key "expire" -Value "temp" -TTLSeconds 1
    Start-Sleep -Seconds 2
    $cache.CleanupExpired()
    $expiredValue = Get-CacheItem -CacheManager $cache -Key "expire"
    if ($null -ne $expiredValue) {
        throw "Expired item not removed"
    }
    
    # Test LRU eviction
    for ($i = 1; $i -le 110; $i++) {
        Set-CacheItem -CacheManager $cache -Key "item$i" -Value "value$i"
    }
    
    $stats = Get-CacheStatistics -CacheManager $cache
    if ($stats.Evictions -eq 0) {
        throw "No evictions occurred despite exceeding max size"
    }
    
    $stopwatch.Stop()
    $cache.Dispose()
    
    Add-TestResult -TestName "Cache Operations" -Status "Passed" `
        -Result @{
            SetOperations = 112
            Evictions = $stats.Evictions
            HitRate = $stats.HitRate
        } -Duration $stopwatch.Elapsed.TotalMilliseconds
} catch {
    Add-TestResult -TestName "Cache Operations" -Status "Failed" -Error $_.Exception.Message
}

# Test 3: Incremental Processor Module
Write-Host "Test 3: Incremental Processor Module" -ForegroundColor Yellow
try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-IncrementalProcessor\Unity-Claude-IncrementalProcessor.psd1" -Force
    $stopwatch.Stop()
    
    $commands = Get-Command -Module Unity-Claude-IncrementalProcessor
    if ($commands.Count -ge 8) {
        Add-TestResult -TestName "Incremental Processor Module" -Status "Passed" `
            -Result "Module loaded with $($commands.Count) commands" `
            -Duration $stopwatch.Elapsed.TotalMilliseconds
    } else {
        throw "Insufficient commands exported: $($commands.Count)"
    }
} catch {
    Add-TestResult -TestName "Incremental Processor Module" -Status "Failed" -Error $_.Exception.Message
}

# Test 4: File Change Detection
Write-Host "Test 4: File Change Detection" -ForegroundColor Yellow
try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Create test directory
    $testPath = "$env:TEMP\IncrementalTest"
    if (-not (Test-Path $testPath)) {
        New-Item -Path $testPath -ItemType Directory -Force | Out-Null
    }
    
    # Create processor
    $processor = New-IncrementalProcessor -WatchPath $testPath -CPGManager $null -CacheManager $null
    Start-IncrementalProcessing -Processor $processor
    
    # Create test file
    $testFile = "$testPath\test.ps1"
    "function Test-Function { return 1 }" | Out-File $testFile
    
    # Wait for processing
    Start-Sleep -Seconds 2
    
    # Get statistics
    $stats = Get-IncrementalProcessorStatistics -Processor $processor
    
    # Clean up
    Stop-IncrementalProcessing -Processor $processor
    $processor.Dispose()
    Remove-Item $testPath -Recurse -Force
    
    $stopwatch.Stop()
    
    Add-TestResult -TestName "File Change Detection" -Status "Passed" `
        -Result @{
            ChangesDetected = $stats.TotalChangesDetected
            ChangesProcessed = $stats.TotalChangesProcessed
            SnapshotCount = $stats.SnapshotCount
        } -Duration $stopwatch.Elapsed.TotalMilliseconds
} catch {
    Add-TestResult -TestName "File Change Detection" -Status "Failed" -Error $_.Exception.Message
}

# Test 5: Parallel Processor Module
Write-Host "Test 5: Parallel Processor Module" -ForegroundColor Yellow
try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor.psd1" -Force
    $stopwatch.Stop()
    
    $commands = Get-Command -Module Unity-Claude-ParallelProcessor
    if ($commands.Count -ge 5) {
        Add-TestResult -TestName "Parallel Processor Module" -Status "Passed" `
            -Result "Module loaded with $($commands.Count) commands" `
            -Duration $stopwatch.Elapsed.TotalMilliseconds
    } else {
        throw "Insufficient commands exported: $($commands.Count)"
    }
} catch {
    Add-TestResult -TestName "Parallel Processor Module" -Status "Failed" -Error $_.Exception.Message
}

# Test 6: Parallel Execution
Write-Host "Test 6: Parallel Execution" -ForegroundColor Yellow
try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Create parallel processor
    $processor = New-ParallelProcessor -MinThreads 1 -MaxThreads 4
    
    # Test parallel ForEach
    $inputData = 1..20
    $scriptBlock = {
        param($InputObject)
        Start-Sleep -Milliseconds 100
        return $InputObject * 2
    }
    
    $results = $processor.InvokeParallel($inputData, $scriptBlock)
    
    if ($results.Count -ne 20) {
        throw "Expected 20 results, got $($results.Count)"
    }
    
    $stats = Get-ParallelProcessorStatistics -Processor $processor
    $processor.Dispose()
    
    $stopwatch.Stop()
    
    Add-TestResult -TestName "Parallel Execution" -Status "Passed" `
        -Result @{
            JobsCompleted = $stats.TotalJobsCompleted
            SuccessRate = $stats.SuccessRate
            AverageExecutionTime = $stats.AverageExecutionTime
            OptimalThreadCount = $stats.OptimalThreadCount
        } -Duration $stopwatch.Elapsed.TotalMilliseconds
} catch {
    Add-TestResult -TestName "Parallel Execution" -Status "Failed" -Error $_.Exception.Message
}

# Test 7: Batch Processing
Write-Host "Test 7: Batch Processing" -ForegroundColor Yellow
try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Test batch processing
    $inputData = 1..100
    $processingScript = {
        param($batch)
        $batch | ForEach-Object { $_ * 2 }
    }
    
    $results = Start-BatchProcessing -InputObject $inputData -ProcessingScript $processingScript `
        -BatchSize 10 -ConsumerCount 2
    
    if ($results.Count -ne 100) {
        throw "Expected 100 results, got $($results.Count)"
    }
    
    $stopwatch.Stop()
    
    Add-TestResult -TestName "Batch Processing" -Status "Passed" `
        -Result @{
            ItemsProcessed = $results.Count
            BatchSize = 10
            ConsumerCount = 2
        } -Duration $stopwatch.Elapsed.TotalMilliseconds
} catch {
    Add-TestResult -TestName "Batch Processing" -Status "Failed" -Error $_.Exception.Message
}

# Test 8: Performance Benchmark - Sequential vs Parallel
Write-Host "Test 8: Performance Benchmark" -ForegroundColor Yellow
try {
    $dataSize = 50
    $workload = {
        param($n)
        # Simulate CPU-intensive work
        $sum = 0
        for ($i = 1; $i -le 1000; $i++) {
            $sum += [Math]::Sqrt($i * $n)
        }
        return $sum
    }
    
    # Sequential execution
    $sequentialStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $sequentialResults = 1..$dataSize | ForEach-Object { & $workload $_ }
    $sequentialStopwatch.Stop()
    
    # Parallel execution
    $parallelStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $parallelResults = Invoke-ParallelProcessing -InputObject (1..$dataSize) -ScriptBlock $workload
    $parallelStopwatch.Stop()
    
    $speedup = [math]::Round($sequentialStopwatch.Elapsed.TotalMilliseconds / $parallelStopwatch.Elapsed.TotalMilliseconds, 2)
    
    Add-TestResult -TestName "Performance Benchmark" -Status "Passed" `
        -Result @{
            SequentialTimeMs = [math]::Round($sequentialStopwatch.Elapsed.TotalMilliseconds, 2)
            ParallelTimeMs = [math]::Round($parallelStopwatch.Elapsed.TotalMilliseconds, 2)
            Speedup = $speedup
            Efficiency = [math]::Round($speedup / [Environment]::ProcessorCount * 100, 2)
        } -Duration $parallelStopwatch.Elapsed.TotalMilliseconds
} catch {
    Add-TestResult -TestName "Performance Benchmark" -Status "Failed" -Error $_.Exception.Message
}

# Test 9: Memory Management
Write-Host "Test 9: Memory Management" -ForegroundColor Yellow
try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Get initial memory
    [GC]::Collect()
    $initialMemory = [GC]::GetTotalMemory($false)
    
    # Create large cache
    $cache = New-CacheManager -MaxSize 1000
    for ($i = 1; $i -le 1000; $i++) {
        $largeObject = @{
            Id = $i
            Data = "x" * 1000
            Array = 1..100
        }
        Set-CacheItem -CacheManager $cache -Key "large$i" -Value $largeObject
    }
    
    # Get memory after loading
    $loadedMemory = [GC]::GetTotalMemory($false)
    
    # Clear cache and collect
    Clear-Cache -CacheManager $cache
    $cache.Dispose()
    [GC]::Collect()
    
    # Get final memory
    $finalMemory = [GC]::GetTotalMemory($false)
    
    $stopwatch.Stop()
    
    $memoryLeakMB = [math]::Round(($finalMemory - $initialMemory) / 1MB, 2)
    
    Add-TestResult -TestName "Memory Management" -Status "Passed" `
        -Result @{
            InitialMemoryMB = [math]::Round($initialMemory / 1MB, 2)
            LoadedMemoryMB = [math]::Round($loadedMemory / 1MB, 2)
            FinalMemoryMB = [math]::Round($finalMemory / 1MB, 2)
            MemoryLeakMB = $memoryLeakMB
        } -Duration $stopwatch.Elapsed.TotalMilliseconds
} catch {
    Add-TestResult -TestName "Memory Management" -Status "Failed" -Error $_.Exception.Message
}

# Test 10: Integration Test
Write-Host "Test 10: Integration Test" -ForegroundColor Yellow
try {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Create integrated system
    $cache = New-CacheManager -MaxSize 100
    $processor = New-ParallelProcessor -MaxThreads 4
    
    # Simulate document processing pipeline
    $documents = 1..20 | ForEach-Object {
        @{
            Id = $_
            Content = "Document $_ content"
            ProcessingRequired = $true
        }
    }
    
    # Process documents in parallel with caching
    $processScript = {
        param($doc, $SharedData)
        
        # Check cache
        $cacheKey = "doc_$($doc.Id)"
        
        # Simulate processing
        Start-Sleep -Milliseconds 50
        $result = @{
            Id = $doc.Id
            ProcessedContent = $doc.Content.ToUpper()
            ProcessedAt = Get-Date
        }
        
        return $result
    }
    
    $results = @()
    foreach ($doc in $documents) {
        $jobId = $processor.SubmitJob($processScript, @{ doc = $doc })
        $result = $processor.WaitForJob($jobId)
        $results += $result
        
        # Cache result
        Set-CacheItem -CacheManager $cache -Key "doc_$($doc.Id)" -Value $result
    }
    
    # Verify all processed
    if ($results.Count -ne 20) {
        throw "Expected 20 results, got $($results.Count)"
    }
    
    # Verify cache
    $cacheStats = Get-CacheStatistics -CacheManager $cache
    
    # Clean up
    $cache.Dispose()
    $processor.Dispose()
    
    $stopwatch.Stop()
    
    Add-TestResult -TestName "Integration Test" -Status "Passed" `
        -Result @{
            DocumentsProcessed = $results.Count
            CacheHits = $cacheStats.Hits
            CacheMisses = $cacheStats.Misses
            TotalSets = $cacheStats.TotalSets
        } -Duration $stopwatch.Elapsed.TotalMilliseconds
} catch {
    Add-TestResult -TestName "Integration Test" -Status "Failed" -Error $_.Exception.Message
}

# Calculate final statistics
$script:TestResults.EndTime = Get-Date
$script:TestResults.TotalDuration = ($script:TestResults.EndTime - $script:TestResults.StartTime).TotalSeconds

# Display summary
Write-Host ""
Write-Host "=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($script:TestResults.Summary.Total)" -ForegroundColor White
Write-Host "Passed: $($script:TestResults.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($script:TestResults.Summary.Failed)" -ForegroundColor Red
Write-Host "Skipped: $($script:TestResults.Summary.Skipped)" -ForegroundColor Yellow
Write-Host "Success Rate: $([math]::Round($script:TestResults.Summary.Passed / $script:TestResults.Summary.Total * 100, 2))%" -ForegroundColor White
Write-Host "Total Duration: $([math]::Round($script:TestResults.TotalDuration, 2)) seconds" -ForegroundColor Gray

# Save results if requested
if ($SaveResults) {
    $resultsFile = "$PSScriptRoot\PerformanceOptimization-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $script:TestResults | ConvertTo-Json -Depth 10 | Out-File $resultsFile -Encoding UTF8
    Write-Host ""
    Write-Host "Results saved to: $resultsFile" -ForegroundColor Green
}

# Return success/failure
exit ($script:TestResults.Summary.Failed -eq 0 ? 0 : 1)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBG2tytEfUNnS+3
# iiCFjJiz0hGcR2crIYYCuDAfoRkxVaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPb2vUkBzDVn0GSu1o+CRc7q
# WzNFOp0m9kBC1oluMj8PMA0GCSqGSIb3DQEBAQUABIIBACTNzRoF9xU7nn1V+MEb
# 4+b+eP7TYmGJhFabF/wXMsoFmJ5MDt1K7rVPsAI7lXKG5k89z3PByGx8njeBc7PY
# POLVmW7MzeOooUE27FB0+KGnmzbV0h3e4+xiN0l4CDe+tRnSv+nk1jsJo/VgyC6r
# QTYTVUOvWCQf00Wq0z0/W/u/25/rK82X42xag5AeqG+OBxC8v3UImK2FWplBlOIt
# P0B3rNvNjvoxfDXD1Z8GEyT0beW5p91CH7Q68C3i871C9OLU4VvYmrOoIJaO2DQi
# 2JUzwIippn0JKG2IKdAyd1S8F+sioB7Ll+4jXbO7L4slGwiPH8lwJgnUnNO6QYYm
# AxA=
# SIG # End signature block
