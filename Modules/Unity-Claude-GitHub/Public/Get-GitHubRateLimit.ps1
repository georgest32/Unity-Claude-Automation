function Get-GitHubRateLimit {
    <#
    .SYNOPSIS
    Gets the current GitHub API rate limit status
    
    .DESCRIPTION
    Retrieves and displays the current rate limit status for the GitHub API
    
    .PARAMETER ShowAll
    Show all rate limit categories (core, search, graphql, etc.)
    
    .EXAMPLE
    Get-GitHubRateLimit
    
    .EXAMPLE
    Get-GitHubRateLimit -ShowAll
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$ShowAll
    )
    
    begin {
        Write-Verbose "Retrieving GitHub API rate limit status"
        $moduleRoot = Split-Path $PSScriptRoot -Parent
        $projectRoot = Split-Path $moduleRoot -Parent
        $logFile = Join-Path $projectRoot "unity_claude_automation.log"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    process {
        try {
            # Make API call to rate_limit endpoint
            $response = Invoke-GitHubAPIWithRetry -Uri "https://api.github.com/rate_limit" -Method GET -NoRetry
            
            if (-not $response) {
                Write-Warning "Failed to retrieve rate limit information"
                return $null
            }
            
            # Process core rate limit (main API)
            $core = $response.rate
            $corePercentUsed = [Math]::Round((($core.limit - $core.remaining) / $core.limit) * 100, 2)
            $coreResetTime = [DateTimeOffset]::FromUnixTimeSeconds($core.reset).LocalDateTime
            $coreTimeUntilReset = ($coreResetTime - (Get-Date)).TotalMinutes
            
            # Create output object
            $rateLimitInfo = [PSCustomObject]@{
                Category = "Core API"
                Limit = $core.limit
                Remaining = $core.remaining
                Used = $core.limit - $core.remaining
                PercentUsed = $corePercentUsed
                ResetsAt = $coreResetTime
                MinutesUntilReset = [Math]::Round($coreTimeUntilReset, 2)
            }
            
            # Display core rate limit
            Write-Host "`nGitHub API Rate Limit Status" -ForegroundColor Cyan
            Write-Host "=============================" -ForegroundColor Cyan
            Write-Host "Limit:      $($core.limit) requests/hour" -ForegroundColor White
            Write-Host "Remaining:  $($core.remaining) requests" -ForegroundColor $(if ($core.remaining -lt 1000) { "Yellow" } else { "Green" })
            Write-Host "Used:       $($core.limit - $core.remaining) requests ($corePercentUsed%)" -ForegroundColor White
            Write-Host "Resets:     $coreResetTime (in $([Math]::Round($coreTimeUntilReset, 0)) minutes)" -ForegroundColor White
            
            # Warn if approaching limit
            $warningThreshold = [int]($core.limit * $script:Config.RateLimitWarningThreshold)
            if ($core.remaining -le $warningThreshold) {
                Write-Warning "Approaching rate limit! Only $($core.remaining) requests remaining."
                Add-Content -Path $logFile -Value "[$timestamp] [WARNING] GitHub API approaching rate limit: $($core.remaining)/$($core.limit)" -ErrorAction SilentlyContinue
            }
            
            # Show all categories if requested
            if ($ShowAll) {
                Write-Host "`nOther Rate Limits:" -ForegroundColor Cyan
                
                # Search API
                if ($response.resources.search) {
                    $search = $response.resources.search
                    Write-Host "  Search API: $($search.remaining)/$($search.limit) remaining" -ForegroundColor Gray
                }
                
                # GraphQL API
                if ($response.resources.graphql) {
                    $graphql = $response.resources.graphql
                    Write-Host "  GraphQL API: $($graphql.remaining)/$($graphql.limit) remaining" -ForegroundColor Gray
                }
                
                # Integration Manifest
                if ($response.resources.integration_manifest) {
                    $manifest = $response.resources.integration_manifest
                    Write-Host "  Integration Manifest: $($manifest.remaining)/$($manifest.limit) remaining" -ForegroundColor Gray
                }
                
                # Code Scanning Upload
                if ($response.resources.code_scanning_upload) {
                    $scanning = $response.resources.code_scanning_upload
                    Write-Host "  Code Scanning: $($scanning.remaining)/$($scanning.limit) remaining" -ForegroundColor Gray
                }
            }
            
            # Log rate limit status
            Add-Content -Path $logFile -Value "[$timestamp] [INFO] GitHub rate limit: $($core.remaining)/$($core.limit) remaining" -ErrorAction SilentlyContinue
            
            return $rateLimitInfo
            
        } catch {
            Write-Error "Failed to retrieve rate limit status: $_"
            Add-Content -Path $logFile -Value "[$timestamp] [ERROR] Failed to retrieve GitHub rate limit: $_" -ErrorAction SilentlyContinue
            return $null
        }
    }
}