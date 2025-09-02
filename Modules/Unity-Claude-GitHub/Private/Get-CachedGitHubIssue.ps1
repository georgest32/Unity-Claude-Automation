function Get-CachedGitHubIssue {
    <#
    .SYNOPSIS
    Gets a GitHub issue from cache if available
    
    .DESCRIPTION
    Retrieves a cached GitHub issue to avoid unnecessary API calls
    
    .PARAMETER CacheKey
    Unique cache key for the issue
    
    .PARAMETER MaxAge
    Maximum age of cache entry in minutes
    
    .EXAMPLE
    Get-CachedGitHubIssue -CacheKey "org/repo/issue/123"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CacheKey,
        
        [int]$MaxAge = 30
    )
    
    try {
        $cachePath = Join-Path $env:TEMP "GitHubIssueCache"
        
        # Sanitize cache key for filename
        $safeKey = $CacheKey -replace '[^a-zA-Z0-9-_]', '_'
        $cacheFile = Join-Path $cachePath "$safeKey.cache.json"
        
        if (-not (Test-Path $cacheFile)) {
            Write-Verbose "Cache miss: $CacheKey"
            
            # Update cache statistics
            $metadataFile = Join-Path $cachePath "cache_metadata.json"
            if (Test-Path $metadataFile) {
                $metadata = Get-Content $metadataFile -Raw | ConvertFrom-Json
                $metadata.Statistics.TotalMisses++
                $metadata | ConvertTo-Json -Depth 10 | Set-Content $metadataFile
            }
            
            return $null
        }
        
        # Read cache entry
        $cacheEntry = Get-Content $cacheFile -Raw | ConvertFrom-Json
        
        # Check age
        $entryAge = ([DateTime]::UtcNow - [DateTime]::Parse($cacheEntry.CachedAt)).TotalMinutes
        
        if ($entryAge -gt $MaxAge) {
            Write-Verbose "Cache expired: $CacheKey (age: $([Math]::Round($entryAge, 1)) minutes)"
            Remove-Item $cacheFile -Force
            
            # Update cache statistics
            $metadataFile = Join-Path $cachePath "cache_metadata.json"
            if (Test-Path $metadataFile) {
                $metadata = Get-Content $metadataFile -Raw | ConvertFrom-Json
                $metadata.Statistics.TotalMisses++
                $metadata.Statistics.TotalEvictions++
                $metadata | ConvertTo-Json -Depth 10 | Set-Content $metadataFile
            }
            
            return $null
        }
        
        Write-Verbose "Cache hit: $CacheKey (age: $([Math]::Round($entryAge, 1)) minutes)"
        
        # Update cache statistics
        $metadataFile = Join-Path $cachePath "cache_metadata.json"
        if (Test-Path $metadataFile) {
            $metadata = Get-Content $metadataFile -Raw | ConvertFrom-Json
            $metadata.Statistics.TotalHits++
            $metadata | ConvertTo-Json -Depth 10 | Set-Content $metadataFile
        }
        
        # Update last access time
        (Get-Item $cacheFile).LastWriteTime = [DateTime]::Now
        
        return $cacheEntry.Data
        
    } catch {
        Write-Warning "Failed to get cached item: $_"
        return $null
    }
}

# Export the function (for internal module use)
Export-ModuleMember -Function Get-CachedGitHubIssue
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCmQFp0ouLi+TT1
# cnwxSPpOkn17NF+mf4+oL98bp0n2w6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICy7cP6BQOH3+gTHbktGtona
# 9GfTycY/TzIAEc23MuvYMA0GCSqGSIb3DQEBAQUABIIBAEXonX0oH8eOCcNFgu8p
# KfSlMJ35B3sMrq4T6zvj/C/B6FBtNQUUVbbJWQcjJxhYsXQu9uQyDuOJgpDNZMUC
# RD2gvRCQDHSTLh18KWDAIGS0Mu0y35Mue9bvKczFTnJBnbnBm0TbOvMWCx5dEgIr
# TxI0lBSgT5otqRaBst4javTrHgKDlTLaYEDruugO8/OQDFUdcFnuPyx6Fy4FyK3i
# +saPac1h9KZwRlwsQlacxJ/alN6GPKb7/bSWHZwId7b4LpMMW/93LsGnaah3QSlT
# PAX6jYYgFcGZCZXSVXvqS+Pm/+pHhBLlh3Zm3JmqP3aTO2zmM/qV1cF3ScUOzNXE
# Xhk=
# SIG # End signature block
