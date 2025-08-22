function Set-NotificationConfig {
    <#
    .SYNOPSIS
    Updates notification configuration settings
    
    .DESCRIPTION
    Modifies specific notification settings in the configuration file.
    Automatically creates a backup before making changes.
    
    .PARAMETER Section
    Configuration section to update
    
    .PARAMETER Settings
    Hashtable of settings to update
    
    .PARAMETER Force
    Skip confirmation prompt
    
    .EXAMPLE
    Set-NotificationConfig -Section 'EmailNotifications' -Settings @{SMTPPort=587; EnableSSL=$true}
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Notifications', 'EmailNotifications', 'WebhookNotifications', 'NotificationTriggers')]
        [string]$Section,
        
        [Parameter(Mandatory)]
        [hashtable]$Settings,
        
        [switch]$Force
    )
    
    # Create backup first
    $backupFile = Backup-NotificationConfig -Silent
    Write-Verbose "[NotificationConfig] Configuration backed up to: $backupFile"
    
    try {
        # Load current configuration
        $config = Get-NotificationConfig -NoCache
        
        if (-not $config) {
            throw "Failed to load current configuration"
        }
        
        # Update settings
        foreach ($key in $Settings.Keys) {
            if ($PSCmdlet.ShouldProcess("$Section.$key", "Update to '$($Settings[$key])'")) {
                $config.$Section.$key = $Settings[$key]
                Write-Verbose "[NotificationConfig] Updated $Section.$key = $($Settings[$key])"
            }
        }
        
        # Save configuration
        $config | ConvertTo-Json -Depth 10 | Set-Content $script:ConfigPath -Encoding UTF8
        
        # Clear cache to force reload
        $script:ConfigCache = $null
        $script:ConfigCacheTime = $null
        
        Write-Host "[NotificationConfig] Configuration updated successfully" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Error "[NotificationConfig] Failed to update configuration: $_"
        Write-Warning "[NotificationConfig] Configuration has been backed up to: $backupFile"
        return $false
    }
}