# Test-PerformanceOptimization-Simple.ps1
# Simplified test suite focusing on core functionality

$ErrorActionPreference = 'Continue'

Write-Host "=== Simplified Performance Test Suite ===" -ForegroundColor Cyan
Write-Host ""

$passed = 0
$failed = 0

# Test 1: Cache Module
Write-Host "Test 1: Cache Module" -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-Cache\Unity-Claude-Cache.psd1" -Force
    $cache = New-CacheManager -MaxSize 100
    
    # Suppress output when setting items
    $null = Set-CacheItem -CacheManager $cache -Key "test1" -Value "value1" -TTLSeconds 60
    $value = Get-CacheItem -CacheManager $cache -Key "test1"
    
    if ($value -eq "value1") {
        Write-Host "[PASSED] Cache operations work" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAILED] Cache get returned: $value" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "[FAILED] Cache module error: $_" -ForegroundColor Red
    $failed++
}

# Test 2: Incremental Processor
Write-Host "`nTest 2: Incremental Processor" -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-IncrementalProcessor\Unity-Claude-IncrementalProcessor.psd1" -Force
    $processor = New-IncrementalProcessor -WatchPath $env:TEMP
    
    if ($processor) {
        Write-Host "[PASSED] Incremental processor created" -ForegroundColor Green
        $passed++
        $processor.Dispose()
    } else {
        Write-Host "[FAILED] Could not create processor" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "[FAILED] Incremental processor error: $_" -ForegroundColor Red
    $failed++
}

# Test 3: Parallel Processor
Write-Host "`nTest 3: Parallel Processor" -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor.psd1" -Force
    $processor = New-ParallelProcessor -MinThreads 2 -MaxThreads 4
    
    if ($processor -and $processor.OptimalThreadCount -gt 0) {
        Write-Host "[PASSED] Parallel processor created with $($processor.OptimalThreadCount) threads" -ForegroundColor Green
        $passed++
        
        # Test parallel execution
        $items = 1..5
        $scriptBlock = {
            param($item)
            return $item * 2
        }
        
        $results = Invoke-ParallelProcessing -Processor $processor -InputObject $items -ScriptBlock $scriptBlock
        
        if ($results.Count -eq 5) {
            Write-Host "[PASSED] Parallel execution completed" -ForegroundColor Green
            $passed++
        } else {
            Write-Host "[FAILED] Expected 5 results, got $($results.Count)" -ForegroundColor Red
            $failed++
        }
        
        $processor.Dispose()
    } else {
        Write-Host "[FAILED] Could not create parallel processor" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "[FAILED] Parallel processor error: $_" -ForegroundColor Red
    Write-Host "  Details: $($_.Exception.Message)" -ForegroundColor Gray
    $failed++
}

# Test 4: Cache Statistics
Write-Host "`nTest 4: Cache Statistics" -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-Cache\Unity-Claude-Cache.psd1" -Force
    $cache = New-CacheManager -MaxSize 10
    
    # Add items
    for ($i = 1; $i -le 5; $i++) {
        $null = Set-CacheItem -CacheManager $cache -Key "stat$i" -Value "value$i"
    }
    
    # Get statistics
    $stats = Get-CacheStatistics -CacheManager $cache
    
    if ($stats.ItemCount -eq 5 -and $stats.TotalSets -eq 5) {
        Write-Host "[PASSED] Cache statistics tracking works correctly" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAILED] Statistics incorrect - ItemCount: $($stats.ItemCount), TotalSets: $($stats.TotalSets)" -ForegroundColor Red
        $failed++
    }
} catch {
    Write-Host "[FAILED] Cache statistics error: $_" -ForegroundColor Red
    $failed++
}

# Test 5: Integration
Write-Host "`nTest 5: Basic Integration" -ForegroundColor Yellow
try {
    # Create all components
    $cache = New-CacheManager -MaxSize 50
    $incremental = New-IncrementalProcessor -WatchPath $env:TEMP
    $parallel = New-ParallelProcessor -MinThreads 2 -MaxThreads 4
    
    # Basic workflow test
    $null = Set-CacheItem -CacheManager $cache -Key "integration" -Value "test"
    $cached = Get-CacheItem -CacheManager $cache -Key "integration"
    
    if ($cached -eq "test") {
        Write-Host "[PASSED] Integration test completed" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAILED] Integration test failed" -ForegroundColor Red
        $failed++
    }
    
    # Cleanup
    try { $cache.Dispose() } catch { }
    try { $incremental.Dispose() } catch { }
    try { $parallel.Dispose() } catch { }
} catch {
    Write-Host "[FAILED] Integration error: $_" -ForegroundColor Red
    $failed++
}

Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
$total = $passed + $failed
$rate = if ($total -gt 0) { [math]::Round(($passed / $total) * 100, 1) } else { 0 }
Write-Host "Success Rate: $rate%" -ForegroundColor $(if ($rate -ge 70) { 'Green' } else { 'Yellow' })
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCABLuPZ+w53XZNa
# yu4dfuFgvpRVN1OrnwFh5erEjRpHBKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAfnxHkvHObo7DMs1mQdAIAI
# KBQ/EHO3PA0mCDo2iplyMA0GCSqGSIb3DQEBAQUABIIBAFmoVlFtXuIZQT6yCsSI
# AsT27k2ydTiic1VMpA5ZZvoAvid9IFx0hwLnww73CtCt/16obWOLPNXGqPAIDyo2
# wIejkwZhjpRHckoahG1HfGsz2ZYmwKMW597o03iduWcJzNRyy7rloP+gBa2XPrlY
# kspBxgIpg7eOtGq47FwjDl5JTzi/fMocGbgcWXWgvmV+q/qQNwkM4yE/BnvupCjG
# uuGvkvTvcbnKr7lA7QdxTLtCC5C49AC4AaqZ6GsRBU0gdPfI08PYfPoxfKxT+Wmv
# lZvquWel763+KhjUy2yESnzQRLRFgkUIlx+fO97yggj3IC0KeCur/mSgCy16fBkM
# Q7o=
# SIG # End signature block
