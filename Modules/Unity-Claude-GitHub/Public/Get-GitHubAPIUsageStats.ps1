function Get-GitHubAPIUsageStats {
    <#
    .SYNOPSIS
    Gets GitHub API usage statistics and rate limit information
    
    .DESCRIPTION
    Retrieves comprehensive API usage statistics including rate limits,
    call history, and usage patterns for optimization
    
    .PARAMETER IncludeHistory
    Include historical API call data from local tracking
    
    .PARAMETER Since
    Get statistics since this date/time
    
    .PARAMETER GroupBy
    Group statistics by (Hour, Day, Endpoint, Method)
    
    .EXAMPLE
    Get-GitHubAPIUsageStats -IncludeHistory -Since (Get-Date).AddDays(-7) -GroupBy Endpoint
    #>
    [CmdletBinding()]
    param(
        [switch]$IncludeHistory,
        
        [DateTime]$Since = (Get-Date).AddHours(-1),
        
        [ValidateSet("Hour", "Day", "Endpoint", "Method")]
        [string]$GroupBy = "Endpoint"
    )
    
    try {
        # Get PAT for authentication
        $pat = Get-GitHubPATInternal
        if (-not $pat) {
            throw "GitHub PAT not configured. Use Set-GitHubPAT to configure."
        }
        
        # Build headers
        $headers = @{
            "Authorization" = "Bearer $pat"
            "Accept" = "application/vnd.github+json"
            "X-GitHub-Api-Version" = "2022-11-28"
        }
        
        # Get current rate limit
        $rateLimitUri = "https://api.github.com/rate_limit"
        Write-Verbose "Getting rate limit information"
        $rateLimit = Invoke-GitHubAPIWithRetry -Uri $rateLimitUri -Headers $headers -Method Get
        
        # Build usage stats object
        $stats = [PSCustomObject]@{
            CurrentTime = [DateTime]::UtcNow
            Core = [PSCustomObject]@{
                Limit = $rateLimit.rate.limit
                Used = $rateLimit.rate.limit - $rateLimit.rate.remaining
                Remaining = $rateLimit.rate.remaining
                PercentUsed = [Math]::Round((($rateLimit.rate.limit - $rateLimit.rate.remaining) / $rateLimit.rate.limit) * 100, 2)
                ResetTime = [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc).AddSeconds($rateLimit.rate.reset)
                MinutesUntilReset = [Math]::Round(([DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc).AddSeconds($rateLimit.rate.reset) - [DateTime]::UtcNow).TotalMinutes, 1)
            }
            Search = [PSCustomObject]@{
                Limit = $rateLimit.resources.search.limit
                Used = $rateLimit.resources.search.limit - $rateLimit.resources.search.remaining
                Remaining = $rateLimit.resources.search.remaining
                PercentUsed = [Math]::Round((($rateLimit.resources.search.limit - $rateLimit.resources.search.remaining) / $rateLimit.resources.search.limit) * 100, 2)
                ResetTime = [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc).AddSeconds($rateLimit.resources.search.reset)
            }
            GraphQL = [PSCustomObject]@{
                Limit = $rateLimit.resources.graphql.limit
                Used = $rateLimit.resources.graphql.limit - $rateLimit.resources.graphql.remaining
                Remaining = $rateLimit.resources.graphql.remaining
                PercentUsed = if ($rateLimit.resources.graphql.limit -gt 0) { 
                    [Math]::Round((($rateLimit.resources.graphql.limit - $rateLimit.resources.graphql.remaining) / $rateLimit.resources.graphql.limit) * 100, 2)
                } else { 0 }
                ResetTime = [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc).AddSeconds($rateLimit.resources.graphql.reset)
            }
            History = $null
            Recommendations = @()
        }
        
        # Load API call history if requested
        if ($IncludeHistory) {
            $historyFile = Join-Path $env:TEMP "github_api_usage_history.json"
            
            if (Test-Path $historyFile) {
                Write-Verbose "Loading API usage history from $historyFile"
                $history = Get-Content $historyFile -Raw | ConvertFrom-Json
                
                # Filter by date
                $filteredHistory = $history | Where-Object { 
                    [DateTime]::Parse($_.Timestamp) -ge $Since 
                }
                
                # Group statistics
                $grouped = switch ($GroupBy) {
                    "Hour" {
                        $filteredHistory | Group-Object { 
                            [DateTime]::Parse($_.Timestamp).ToString("yyyy-MM-dd HH:00")
                        } | ForEach-Object {
                            [PSCustomObject]@{
                                Period = $_.Name
                                Count = $_.Count
                                Endpoints = ($_.Group.Endpoint | Select-Object -Unique).Count
                                AverageResponseTime = [Math]::Round(($_.Group.ResponseTime | Measure-Object -Average).Average, 2)
                            }
                        }
                    }
                    "Day" {
                        $filteredHistory | Group-Object { 
                            [DateTime]::Parse($_.Timestamp).ToString("yyyy-MM-dd")
                        } | ForEach-Object {
                            [PSCustomObject]@{
                                Period = $_.Name
                                Count = $_.Count
                                Endpoints = ($_.Group.Endpoint | Select-Object -Unique).Count
                                AverageResponseTime = [Math]::Round(($_.Group.ResponseTime | Measure-Object -Average).Average, 2)
                            }
                        }
                    }
                    "Endpoint" {
                        $filteredHistory | Group-Object Endpoint | ForEach-Object {
                            [PSCustomObject]@{
                                Endpoint = $_.Name
                                Count = $_.Count
                                Methods = ($_.Group.Method | Select-Object -Unique) -join ', '
                                AverageResponseTime = [Math]::Round(($_.Group.ResponseTime | Measure-Object -Average).Average, 2)
                                Errors = ($_.Group | Where-Object { $_.Error }).Count
                            }
                        } | Sort-Object Count -Descending
                    }
                    "Method" {
                        $filteredHistory | Group-Object Method | ForEach-Object {
                            [PSCustomObject]@{
                                Method = $_.Name
                                Count = $_.Count
                                Endpoints = ($_.Group.Endpoint | Select-Object -Unique).Count
                                AverageResponseTime = [Math]::Round(($_.Group.ResponseTime | Measure-Object -Average).Average, 2)
                                Errors = ($_.Group | Where-Object { $_.Error }).Count
                            }
                        }
                    }
                }
                
                $stats.History = [PSCustomObject]@{
                    Since = $Since
                    TotalCalls = $filteredHistory.Count
                    GroupedBy = $GroupBy
                    Groups = $grouped
                    TopEndpoints = $filteredHistory | Group-Object Endpoint | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object {
                        [PSCustomObject]@{
                            Endpoint = $_.Name
                            Count = $_.Count
                            Percentage = [Math]::Round(($_.Count / $filteredHistory.Count) * 100, 2)
                        }
                    }
                    ErrorRate = if ($filteredHistory.Count -gt 0) {
                        [Math]::Round((($filteredHistory | Where-Object { $_.Error }).Count / $filteredHistory.Count) * 100, 2)
                    } else { 0 }
                    AverageResponseTime = if ($filteredHistory.Count -gt 0) {
                        [Math]::Round(($filteredHistory.ResponseTime | Measure-Object -Average).Average, 2)
                    } else { 0 }
                }
            } else {
                Write-Verbose "No API usage history file found"
                $stats.History = [PSCustomObject]@{
                    Since = $Since
                    TotalCalls = 0
                    GroupedBy = $GroupBy
                    Groups = @()
                    TopEndpoints = @()
                    ErrorRate = 0
                    AverageResponseTime = 0
                }
            }
        }
        
        # Generate recommendations
        if ($stats.Core.PercentUsed -gt 80) {
            $stats.Recommendations += "WARNING: Core API rate limit usage is above 80%. Consider implementing request batching or caching."
        }
        
        if ($stats.Core.MinutesUntilReset -lt 10 -and $stats.Core.Remaining -lt 100) {
            $stats.Recommendations += "CRITICAL: Less than 100 API calls remaining with only $($stats.Core.MinutesUntilReset) minutes until reset."
        }
        
        if ($stats.Search.PercentUsed -gt 50) {
            $stats.Recommendations += "INFO: Search API usage is above 50%. Consider caching search results."
        }
        
        if ($stats.History -and $stats.History.ErrorRate -gt 5) {
            $stats.Recommendations += "WARNING: API error rate is $($stats.History.ErrorRate)%. Review error patterns."
        }
        
        if ($stats.History -and $stats.History.AverageResponseTime -gt 1000) {
            $stats.Recommendations += "INFO: Average API response time is $($stats.History.AverageResponseTime)ms. Consider optimizing queries."
        }
        
        # Display summary
        Write-Host "`nGitHub API Usage Statistics" -ForegroundColor Cyan
        Write-Host "===========================" -ForegroundColor Cyan
        Write-Host "Core API: $($stats.Core.Used)/$($stats.Core.Limit) used ($($stats.Core.PercentUsed)%)" -ForegroundColor $(if ($stats.Core.PercentUsed -gt 80) { "Yellow" } else { "Green" })
        Write-Host "Search API: $($stats.Search.Used)/$($stats.Search.Limit) used ($($stats.Search.PercentUsed)%)" -ForegroundColor $(if ($stats.Search.PercentUsed -gt 50) { "Yellow" } else { "Green" })
        Write-Host "Reset in: $($stats.Core.MinutesUntilReset) minutes" -ForegroundColor Gray
        
        if ($stats.History) {
            Write-Host "`nHistorical Usage (since $($Since.ToString('yyyy-MM-dd HH:mm'))):" -ForegroundColor Cyan
            Write-Host "Total API Calls: $($stats.History.TotalCalls)" -ForegroundColor Gray
            Write-Host "Error Rate: $($stats.History.ErrorRate)%" -ForegroundColor $(if ($stats.History.ErrorRate -gt 5) { "Yellow" } else { "Green" })
            Write-Host "Avg Response Time: $($stats.History.AverageResponseTime)ms" -ForegroundColor Gray
        }
        
        if ($stats.Recommendations.Count -gt 0) {
            Write-Host "`nRecommendations:" -ForegroundColor Yellow
            foreach ($rec in $stats.Recommendations) {
                Write-Host "  - $rec" -ForegroundColor Yellow
            }
        }
        
        return $stats
        
    } catch {
        Write-Error "Failed to get API usage statistics: $_"
        throw
    }
}

# Export the function
Export-ModuleMember -Function Get-GitHubAPIUsageStats
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA22CNCAx1YMoEd
# fu3zvtsRhTmlWmF9YFpvZ2UcwnpNhaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILGNCtOFeWF6sz/8QSQS3n/H
# vg/mXrjaQmSoaGZwSxiiMA0GCSqGSIb3DQEBAQUABIIBAGdUzhPnwfYDUc5Ef6iG
# MfH/1ttPPFre55lYDilV2FvPjd5noyTm4bExLHLvWWN+7pFSmAc1xBNbD/yriohX
# 5x3DIdTIihgHGw16sXoz8HefMELcRCXI8VsHRr+79fO+jNWDH0p6fKmsJCxeg2mY
# Sqgx92o/Ck4l0am0L7i6O46V7vkIVPejCnkEhlti1Dng0GtOGAs/KcHtug4YawdZ
# sf7pIgnx8vn7FoxTjB7wA6QCFcSdUyFXE1kIsWsyvp7V6h8FQP3M4+svmfYT2ihx
# wnDWPmcz3WhJlrPSfuY6BVYEvzeDVpfjIALwoR/z89JbdVKhBdZ5c9LRo91/xdwA
# nBY=
# SIG # End signature block
