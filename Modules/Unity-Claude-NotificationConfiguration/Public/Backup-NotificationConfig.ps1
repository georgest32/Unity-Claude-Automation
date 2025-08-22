function Backup-NotificationConfig {
    <#
    .SYNOPSIS
    Creates a backup of the current configuration
    
    .DESCRIPTION
    Backs up the current notification configuration with timestamp.
    Maintains backup history for recovery.
    
    .PARAMETER Description
    Optional description for the backup
    
    .PARAMETER Silent
    Suppress output messages
    
    .EXAMPLE
    Backup-NotificationConfig -Description "Before email server change"
    #>
    [CmdletBinding()]
    param(
        [string]$Description = "",
        [switch]$Silent
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFileName = "notificationconfig_backup_$timestamp.json"
    $backupFilePath = Join-Path $script:BackupPath $backupFileName
    
    try {
        # Load current configuration
        $config = Get-NotificationConfig -NoCache
        
        # Add backup metadata
        $backupData = @{
            BackupTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            BackupBy = $env:USERNAME
            Description = $Description
            Configuration = $config
        }
        
        # Save backup
        $backupData | ConvertTo-Json -Depth 10 | Set-Content $backupFilePath -Encoding UTF8
        
        if (-not $Silent) {
            Write-Host "[NotificationConfig] Configuration backed up to: $backupFilePath" -ForegroundColor Green
        }
        
        return $backupFilePath
        
    } catch {
        Write-Error "[NotificationConfig] Failed to create backup: $_"
        return $null
    }
}