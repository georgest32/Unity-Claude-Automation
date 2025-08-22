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