# Test-CacheDebug.ps1
# Debug cache test failures

$ErrorActionPreference = 'Stop'

Write-Host "=== Cache Debug Test ===" -ForegroundColor Cyan

try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-Cache\Unity-Claude-Cache.psd1" -Force
    $cache = New-CacheManager -MaxSize 100
    
    Write-Host "Cache created successfully" -ForegroundColor Green
    
    # Add single item
    Write-Host "Adding item to cache..." -ForegroundColor Yellow
    Set-CacheItem -CacheManager $cache -Key "test1" -Value "value1" -TTLSeconds 60 -Priority 5
    Write-Host "Item added" -ForegroundColor Green
    
    # Retrieve item
    Write-Host "Retrieving item from cache..." -ForegroundColor Yellow
    $value = Get-CacheItem -CacheManager $cache -Key "test1"
    
    if ($value -eq "value1") {
        Write-Host "Retrieved value: $value [CORRECT]" -ForegroundColor Green
    } else {
        Write-Host "Retrieved value: $value [INCORRECT - expected 'value1']" -ForegroundColor Red
    }
    
    # Test TTL
    Write-Host "`nTesting TTL..." -ForegroundColor Yellow
    Set-CacheItem -CacheManager $cache -Key "ttl1" -Value "expires" -TTLSeconds 1 -Priority 5
    $immediate = Get-CacheItem -CacheManager $cache -Key "ttl1"
    Write-Host "Immediate retrieval: $immediate" -ForegroundColor Gray
    
    Start-Sleep -Seconds 2
    $expired = Get-CacheItem -CacheManager $cache -Key "ttl1"
    if ($null -eq $expired) {
        Write-Host "TTL expiration works correctly" -ForegroundColor Green
    } else {
        Write-Host "TTL expiration failed - value still present: $expired" -ForegroundColor Red
    }
    
    # Test LRU eviction
    Write-Host "`nTesting LRU eviction..." -ForegroundColor Yellow
    $smallCache = New-CacheManager -MaxSize 3
    
    # Add 3 items
    Set-CacheItem -CacheManager $smallCache -Key "lru1" -Value "val1" -Priority 5
    Set-CacheItem -CacheManager $smallCache -Key "lru2" -Value "val2" -Priority 5
    Set-CacheItem -CacheManager $smallCache -Key "lru3" -Value "val3" -Priority 5
    
    # Access lru1 to make it most recently used
    $null = Get-CacheItem -CacheManager $smallCache -Key "lru1"
    
    # Add 4th item - should evict lru2 (least recently used)
    Set-CacheItem -CacheManager $smallCache -Key "lru4" -Value "val4" -Priority 5
    
    $stats = Get-CacheStatistics -CacheManager $smallCache
    Write-Host "Cache statistics after eviction:" -ForegroundColor Gray
    Write-Host "  Items: $($stats.ItemCount)" -ForegroundColor Gray
    Write-Host "  Evictions: $($stats.Evictions)" -ForegroundColor Gray
    
    if ((Test-CacheKey -CacheManager $smallCache -Key "lru2") -eq $false) {
        Write-Host "LRU eviction works correctly (lru2 was evicted)" -ForegroundColor Green
    } else {
        Write-Host "LRU eviction failed (lru2 still present)" -ForegroundColor Red
    }
    
    Write-Host "`n[SUCCESS] All cache operations work correctly" -ForegroundColor Green
}
catch {
    Write-Host "[ERROR] Cache test failed: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Gray
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAVKig70hkffPed
# 8bThUiC7zj6l0KS42cQ0VsD4wYA3XKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJNML0PCR4VJVJyOOVxmdRMD
# VZYxr5kLIXN505aCt3KBMA0GCSqGSIb3DQEBAQUABIIBAJ91Y8dfIkFTZD44AY0+
# R0daHPNXBeKbWLI2fql3B11GawlagAXbE+L0EI+ZbJE3+NKsTF+zWSJMkx7OHOcO
# fgHSG7+/u4mjLhK9u8WtwgGhtOuPhnEPhlKmdHocKkE1NiZWPDnBBQW6pCJlFLa8
# nh3sLYhjiy6eN5irXIMMTzW5aKZy2qAcEbsSsxDHXUxu+ZYritSTDyverzfFvLDa
# TdOkKy2T1MXAFuKxTpN3ZQOmgki+PzlKh1SpEfauQkuFIVdpioUxuWqNY6dc5jVT
# wo4OltZm5Bf4dtdtXn/5MJpHurP0hY5urtAfRPZWdNxO9VWp/8KgRYrnvev8sXYK
# XkU=
# SIG # End signature block
