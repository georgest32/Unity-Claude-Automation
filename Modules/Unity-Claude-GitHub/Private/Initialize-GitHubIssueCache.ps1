function Initialize-GitHubIssueCache {
    <#
    .SYNOPSIS
    Initializes the GitHub issue cache system
    
    .DESCRIPTION
    Creates and manages a local cache for GitHub issues to reduce API calls
    and improve performance
    
    .PARAMETER CachePath
    Path to the cache directory
    
    .PARAMETER MaxCacheAge
    Maximum age of cache entries in minutes
    
    .PARAMETER MaxCacheSize
    Maximum cache size in MB
    
    .EXAMPLE
    Initialize-GitHubIssueCache -MaxCacheAge 60
    #>
    [CmdletBinding()]
    param(
        [string]$CachePath = (Join-Path $env:TEMP "GitHubIssueCache"),
        
        [int]$MaxCacheAge = 30,
        
        [int]$MaxCacheSize = 100
    )
    
    try {
        # Create cache directory if it doesn't exist
        if (-not (Test-Path $CachePath)) {
            New-Item -Path $CachePath -ItemType Directory -Force | Out-Null
            Write-Verbose "Created cache directory: $CachePath"
        }
        
        # Create cache metadata file
        $metadataFile = Join-Path $CachePath "cache_metadata.json"
        $metadata = if (Test-Path $metadataFile) {
            Get-Content $metadataFile -Raw | ConvertFrom-Json
        } else {
            [PSCustomObject]@{
                Version = "1.0"
                Created = [DateTime]::UtcNow.ToString("o")
                LastCleanup = [DateTime]::UtcNow.ToString("o")
                MaxCacheAge = $MaxCacheAge
                MaxCacheSize = $MaxCacheSize
                Statistics = [PSCustomObject]@{
                    TotalHits = 0
                    TotalMisses = 0
                    TotalEvictions = 0
                    CurrentSize = 0
                    FileCount = 0
                }
            }
        }
        
        # Update settings
        $metadata.MaxCacheAge = $MaxCacheAge
        $metadata.MaxCacheSize = $MaxCacheSize
        
        # Clean up old cache entries
        $cleanupNeeded = $false
        $lastCleanup = [DateTime]::Parse($metadata.LastCleanup)
        
        if (([DateTime]::UtcNow - $lastCleanup).TotalMinutes -gt 60) {
            $cleanupNeeded = $true
        }
        
        if ($cleanupNeeded) {
            Write-Verbose "Performing cache cleanup"
            $removedCount = 0
            $freedSpace = 0
            
            Get-ChildItem -Path $CachePath -Filter "*.cache.json" | ForEach-Object {
                try {
                    $cacheEntry = Get-Content $_.FullName -Raw | ConvertFrom-Json
                    $entryAge = ([DateTime]::UtcNow - [DateTime]::Parse($cacheEntry.CachedAt)).TotalMinutes
                    
                    if ($entryAge -gt $MaxCacheAge) {
                        $freedSpace += $_.Length
                        Remove-Item $_.FullName -Force
                        $removedCount++
                        Write-Verbose "Removed expired cache entry: $($_.Name)"
                    }
                } catch {
                    # Remove corrupted cache files
                    Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
                    $removedCount++
                }
            }
            
            $metadata.LastCleanup = [DateTime]::UtcNow.ToString("o")
            $metadata.Statistics.TotalEvictions += $removedCount
            
            if ($removedCount -gt 0) {
                Write-Verbose "Cleaned up $removedCount expired cache entries, freed $([Math]::Round($freedSpace / 1MB, 2)) MB"
            }
        }
        
        # Update current cache statistics
        $cacheFiles = Get-ChildItem -Path $CachePath -Filter "*.cache.json"
        $totalSize = ($cacheFiles | Measure-Object -Property Length -Sum).Sum
        
        $metadata.Statistics.CurrentSize = [Math]::Round($totalSize / 1MB, 2)
        $metadata.Statistics.FileCount = $cacheFiles.Count
        
        # Check if cache size exceeds limit
        if ($metadata.Statistics.CurrentSize -gt $MaxCacheSize) {
            Write-Warning "Cache size ($($metadata.Statistics.CurrentSize) MB) exceeds limit ($MaxCacheSize MB). Removing oldest entries..."
            
            # Remove oldest entries until under limit
            $sortedFiles = $cacheFiles | Sort-Object LastWriteTime
            foreach ($file in $sortedFiles) {
                Remove-Item $file.FullName -Force
                $metadata.Statistics.TotalEvictions++
                
                $totalSize = (Get-ChildItem -Path $CachePath -Filter "*.cache.json" | Measure-Object -Property Length -Sum).Sum
                $metadata.Statistics.CurrentSize = [Math]::Round($totalSize / 1MB, 2)
                
                if ($metadata.Statistics.CurrentSize -le $MaxCacheSize * 0.8) {
                    break
                }
            }
        }
        
        # Save metadata
        $metadata | ConvertTo-Json -Depth 10 | Set-Content $metadataFile
        
        # Return cache configuration
        return [PSCustomObject]@{
            CachePath = $CachePath
            MetadataFile = $metadataFile
            MaxCacheAge = $MaxCacheAge
            MaxCacheSize = $MaxCacheSize
            Statistics = $metadata.Statistics
            Initialized = $true
        }
        
    } catch {
        Write-Error "Failed to initialize GitHub issue cache: $_"
        throw
    }
}

# Export the function (for internal module use)
Export-ModuleMember -Function Initialize-GitHubIssueCache
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAVUUfAHBV/TAdI
# UbKVG4NZjX4ESY8pXLP78hGoMNWhgKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIeW/df1lGRXBz2YYIONfLLa
# VyhlVwNvWRBjyy3XWaCyMA0GCSqGSIb3DQEBAQUABIIBAFqia+/pShjLImDXwWvU
# PpMrEbZDBdn9ReTsUlZ1Y0wmcciLCEORwOpTLJoATpjdpcHT7d3cRnGqjOCt/B2h
# yvn2tYFHwFK2sXsAmbHzzF53JSNwm6r6nwJg6cVCVCQq/WeyFG/j+d7MKTfhpcKq
# Jh+IwICCRXJXVR05uiUS4CxER57TYtFpKaVH2doOjpmj8KpbUKJuGhhyV1UEcGOD
# Gu8GbMLpxfvMposAGANeAN6hc0flTFsyP+x2seV/Pc5N4OHBpgxUBoLnDNKLPa+x
# vbEVBrjhe4Yw1RMLakzmzT7Y9SoxbLGZDmxmpt7SlgbB6qbVloOagFWm/E6Tlpgo
# OjI=
# SIG # End signature block
