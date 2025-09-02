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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCXZFFISNShvIMZ
# r8jouPwKoSTO+p0uIyrcHul6araCbqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGp7ijcTVX/WTQ5WZ6hLNEL2
# DNa8iMlJNSHycdPrbQ25MA0GCSqGSIb3DQEBAQUABIIBAIBgEtVd67jB/m0kctMV
# H9gbS+MrloW8n3OYr5SUUKtpYFMn6RirKURUThkkMaQ2qIDAhDy/xvGKWKW/rfW/
# +fu3PQTulyEe/6bBorJ+xxnn4ex/Nz8amwBD37CccjpOlcwyyrY04h/HBbTqD4Oc
# ai5lPYX82Kx7hyf+5GK9P7GCZzDxjDPDfCE0yva3cDCr2WPi/E+AA8AO3AMA9ajW
# X+YDyfUVbFVxOmpjioPWU6bdWV4TMokAOxqAqOdMgSMIqtVm50NA5mF/7nAj7xs0
# 5+G9S7Yd46klQlwZZMz8g3JSOLM8lx5uoBSUR8oi79mJWxtg3zn5Rd+jKLuE12vm
# 8Ec=
# SIG # End signature block
