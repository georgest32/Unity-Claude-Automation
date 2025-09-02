function Get-NotificationConfig {
    <#
    .SYNOPSIS
    Retrieves the current notification configuration
    
    .DESCRIPTION
    Gets notification settings from the unified systemstatus.config.json file.
    Supports caching for performance and specific section retrieval.
    
    .PARAMETER Section
    Specific configuration section to retrieve (e.g., 'EmailNotifications', 'WebhookNotifications')
    
    .PARAMETER NoCache
    Force refresh from disk, bypassing cache
    
    .EXAMPLE
    Get-NotificationConfig
    
    .EXAMPLE
    Get-NotificationConfig -Section 'EmailNotifications'
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('All', 'Notifications', 'EmailNotifications', 'WebhookNotifications', 'NotificationTriggers')]
        [string]$Section = 'All',
        
        [switch]$NoCache
    )
    
    Write-Debug "[NotificationConfig] Getting configuration for section: $Section"
    
    # Check cache validity
    if (-not $NoCache -and $script:ConfigCache -and $script:ConfigCacheTime) {
        $cacheAge = (Get-Date) - $script:ConfigCacheTime
        if ($cacheAge.TotalSeconds -lt $script:CacheDuration) {
            Write-Debug "[NotificationConfig] Using cached configuration"
            if ($Section -eq 'All') {
                return $script:ConfigCache
            } else {
                return $script:ConfigCache.$Section
            }
        }
    }
    
    # Load configuration from disk
    try {
        if (Test-Path $script:ConfigPath) {
            $config = Get-Content $script:ConfigPath -Raw | ConvertFrom-Json
            
            # Update cache
            $script:ConfigCache = $config
            $script:ConfigCacheTime = Get-Date
            
            Write-Debug "[NotificationConfig] Configuration loaded from: $script:ConfigPath"
            
            if ($Section -eq 'All') {
                return $config
            } else {
                return $config.$Section
            }
        } else {
            Write-Warning "[NotificationConfig] Configuration file not found: $script:ConfigPath"
            return $null
        }
    } catch {
        Write-Error "[NotificationConfig] Failed to load configuration: $_"
        return $null
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDrd2rjl39isUUb
# qjv8TWBzqicVXQEe1OdBI2aQY5OQXqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOZIvEjbvg0g86QQVb/ZJoSE
# DjXNgWowMLEriNyuXqSkMA0GCSqGSIb3DQEBAQUABIIBAIQZr/JcmywEUmCyIeDJ
# XZHrTp5Dn1TKHgfaapJoBGuUMP5lrTqmPIKKARZgopsnC/63dZUbS7sUnrM1R4yp
# 1t/ymKdVStBidGNYvjIqpB27zsC+dDop89oBykVbmR/wvAEQAx92Fk0Li5K1GyFp
# 9vbnaIdVKXaYG29hThT5aYqi6s0jDTHbkE0UbvcZ3vEBWxYhlrOypxHLLgOd80Bz
# fUTuQ9VEDGqCoOHAppGHCvJVGkjhz3fqg0+d+LgDnD4ALECSXwpk48anw46InwAh
# LqZakvmAy1P9rQf8v8FZOooZp4z10a6xyFReWmcvu+/V0ezrBOHEQhvWQIAJKAwf
# uTs=
# SIG # End signature block
