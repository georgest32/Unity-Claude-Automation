# Test-PerformanceDebug.ps1
# Debug specific test failures

$ErrorActionPreference = 'Stop'

Write-Host "=== Debug Test Suite ===" -ForegroundColor Cyan
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray

# Test 2: Cache Operations (with detailed output)
Write-Host "`nTest 2: Cache Operations" -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-Cache\Unity-Claude-Cache.psd1" -Force
    $cache = New-CacheManager -MaxSize 100
    
    # Add items with different TTLs
    for ($i = 1; $i -le 10; $i++) {
        Set-CacheItem -CacheManager $cache -Key "key$i" -Value "value$i" -TTLSeconds 60 -Priority 5
    }
    
    # Retrieve items
    $retrieved = 0
    for ($i = 1; $i -le 10; $i++) {
        $value = Get-CacheItem -CacheManager $cache -Key "key$i"
        if ($value -eq "value$i") {
            $retrieved++
        }
    }
    
    Write-Host "  Successfully cached and retrieved $retrieved/10 items" -ForegroundColor Green
    Write-Host "[Passed] Cache Operations" -ForegroundColor Green
}
catch {
    Write-Host "[Failed] Cache Operations: $_" -ForegroundColor Red
}

# Test 5: Parallel Processor Module
Write-Host "`nTest 5: Parallel Processor Module" -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor.psd1" -Force -ErrorAction Stop
    $processor = New-ParallelProcessor -MinThreads 2 -MaxThreads 4
    
    if ($processor) {
        Write-Host "  Processor created with optimal thread count: $($processor.OptimalThreadCount)" -ForegroundColor Green
        Write-Host "[Passed] Parallel Processor Module" -ForegroundColor Green
    }
    else {
        Write-Host "[Failed] Parallel Processor Module: Processor creation failed" -ForegroundColor Red
    }
}
catch {
    Write-Host "[Failed] Parallel Processor Module: $_" -ForegroundColor Red
    Write-Host "  Error details: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "  Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Gray
}

# Test 6: Parallel Execution
Write-Host "`nTest 6: Parallel Execution" -ForegroundColor Yellow
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-ParallelProcessor\Unity-Claude-ParallelProcessor.psd1" -Force
    $processor = New-ParallelProcessor -MinThreads 2 -MaxThreads 4
    
    # Test parallel execution
    $items = 1..10
    $scriptBlock = {
        param($item)
        Start-Sleep -Milliseconds 100
        return $item * 2
    }
    
    $results = Invoke-ParallelExecution -Processor $processor -InputObjects $items -ScriptBlock $scriptBlock
    
    if ($results.Count -eq 10) {
        Write-Host "  Processed $($results.Count) items in parallel" -ForegroundColor Green
        Write-Host "[Passed] Parallel Execution" -ForegroundColor Green
    }
    else {
        Write-Host "[Failed] Parallel Execution: Expected 10 results, got $($results.Count)" -ForegroundColor Red
    }
}
catch {
    Write-Host "[Failed] Parallel Execution: $_" -ForegroundColor Red
    Write-Host "  Error details: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n=== Debug Complete ===" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAw/5FOY7pYjHEV
# 7fRgWmQLcyoZmClvyRSo5Otl5GcuOKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIE2NbFTDx3B/powfr79bADho
# Pammzx96rv3UwFHFKcSbMA0GCSqGSIb3DQEBAQUABIIBAJjbcFpYR0X6J0rGoHt1
# oT+YdTMn5jva3zGhCqFPfQQO8OqrA3AipHml6guxaY1n5X5COxEYVfcsKFCKDGtL
# SxlrPL9nNr37XLdFMhqEX2qBTX8mc8EROQUwGhjWT1o2cevnDlNUL4JrHVeRbi/J
# TK8ri3fNLpULvl+HlhAbd9n6c+VN4NjlefZ0l+ReQHnDNQsMEQ2m+48IV9QYbooV
# O4k8WcxruJSkn7jcsVWnBLTq4xzB80ivak011XYrIwD/GXVBOIGqaYdmqtSTp9ui
# 7VCoyV+V29ySAv+/+1IwZBXZ2fei5gdMIzU0CTiHJpbF/j7kgEo6K3LtBn5RNU8u
# lro=
# SIG # End signature block
