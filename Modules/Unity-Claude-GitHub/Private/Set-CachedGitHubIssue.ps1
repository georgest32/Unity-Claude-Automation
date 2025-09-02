function Set-CachedGitHubIssue {
    <#
    .SYNOPSIS
    Stores a GitHub issue in cache
    
    .DESCRIPTION
    Caches a GitHub issue to reduce future API calls
    
    .PARAMETER CacheKey
    Unique cache key for the issue
    
    .PARAMETER Data
    Issue data to cache
    
    .PARAMETER Tags
    Optional tags for cache categorization
    
    .EXAMPLE
    Set-CachedGitHubIssue -CacheKey "org/repo/issue/123" -Data $issueData
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CacheKey,
        
        [Parameter(Mandatory = $true)]
        [object]$Data,
        
        [string[]]$Tags
    )
    
    try {
        $cachePath = Join-Path $env:TEMP "GitHubIssueCache"
        
        # Initialize cache if needed
        if (-not (Test-Path $cachePath)) {
            Initialize-GitHubIssueCache | Out-Null
        }
        
        # Sanitize cache key for filename
        $safeKey = $CacheKey -replace '[^a-zA-Z0-9-_]', '_'
        $cacheFile = Join-Path $cachePath "$safeKey.cache.json"
        
        # Create cache entry
        $cacheEntry = [PSCustomObject]@{
            CacheKey = $CacheKey
            CachedAt = [DateTime]::UtcNow.ToString("o")
            Tags = $Tags
            Data = $Data
        }
        
        # Save to cache
        $cacheEntry | ConvertTo-Json -Depth 10 -Compress | Set-Content $cacheFile
        
        Write-Verbose "Cached: $CacheKey"
        
        # Update cache statistics
        $metadataFile = Join-Path $cachePath "cache_metadata.json"
        if (Test-Path $metadataFile) {
            $metadata = Get-Content $metadataFile -Raw | ConvertFrom-Json
            
            # Update file count and size
            $cacheFiles = Get-ChildItem -Path $cachePath -Filter "*.cache.json"
            $totalSize = ($cacheFiles | Measure-Object -Property Length -Sum).Sum
            
            $metadata.Statistics.CurrentSize = [Math]::Round($totalSize / 1MB, 2)
            $metadata.Statistics.FileCount = $cacheFiles.Count
            
            $metadata | ConvertTo-Json -Depth 10 | Set-Content $metadataFile
        }
        
        return $true
        
    } catch {
        Write-Warning "Failed to cache item: $_"
        return $false
    }
}

# Export the function (for internal module use)
Export-ModuleMember -Function Set-CachedGitHubIssue
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBf655wst5dJkJy
# b5TuKESFgMBFLC/g/VAXhb/newqvlaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDVk2zE1Yq3sHYLZEMyQyT5M
# /YpvTJvEFL7w2xbyI0psMA0GCSqGSIb3DQEBAQUABIIBAC7YxhJ3dkR+jto9xSp+
# XV6P4vrnfdNINhSYet2RPOFYnXCANLlOzcgM364dUnoMiCgbDFRazlVX1ow3KQHr
# LHVuMJx4BWqzuHZTjDoaqrJwYR4yZN6utGB5dM3e2imUnq7pMM9pQ/sTFpCnvG5I
# v9LxMH8BQIl5vwOrK5UgV9IBsTknc8b0DTRKW6mMSbQ4at7YHmqHlLMtPgn+jpUC
# zRqf21aPmFtlbAUuUNjtPiKCwyEUTKQXyOvO87mlz5Axw2pKyiRhvBqyEKxoisvy
# 5o8XB0SuWAfyIBqtKGUbw3rXfvwBgrNQGYMwj18ChlEcBm3/7N4xhXtzDpBYKcIY
# GHE=
# SIG # End signature block
