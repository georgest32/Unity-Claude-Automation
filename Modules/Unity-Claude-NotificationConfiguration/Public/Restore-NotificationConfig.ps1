function Restore-NotificationConfig {
    <#
    .SYNOPSIS
    Restores configuration from a backup
    
    .DESCRIPTION
    Restores notification configuration from a previous backup.
    Shows available backups if no specific backup is provided.
    
    .PARAMETER BackupFile
    Specific backup file to restore from
    
    .PARAMETER Latest
    Restore from the most recent backup
    
    .PARAMETER Force
    Skip confirmation prompt
    
    .EXAMPLE
    Restore-NotificationConfig -Latest
    
    .EXAMPLE
    Restore-NotificationConfig -BackupFile "notificationconfig_backup_20250822_153000.json"
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$BackupFile,
        [switch]$Latest,
        [switch]$Force
    )
    
    # Determine which backup to restore
    if ($Latest) {
        $backups = Get-ChildItem $script:BackupPath -Filter "notificationconfig_backup_*.json" | Sort-Object LastWriteTime -Descending
        if ($backups.Count -eq 0) {
            Write-Warning "No backups found"
            return $false
        }
        $BackupFile = $backups[0].Name
    }
    
    if (-not $BackupFile) {
        # Show available backups
        Write-Host "Available backups:" -ForegroundColor Cyan
        $backups = Get-ConfigBackupHistory
        if ($backups.Count -eq 0) {
            Write-Warning "No backups found"
            return $false
        }
        
        $i = 1
        foreach ($backup in $backups) {
            Write-Host "[$i] $($backup.FileName) - $($backup.BackupTime) - $($backup.Description)" -ForegroundColor Gray
            $i++
        }
        
        $selection = Read-Host "Select backup number to restore (or 'c' to cancel)"
        if ($selection -eq 'c') {
            Write-Host "Restore cancelled" -ForegroundColor Yellow
            return $false
        }
        
        $BackupFile = $backups[[int]$selection - 1].FileName
    }
    
    $backupPath = Join-Path $script:BackupPath $BackupFile
    
    if (-not (Test-Path $backupPath)) {
        Write-Error "Backup file not found: $backupPath"
        return $false
    }
    
    if (-not $Force) {
        $confirmation = Read-Host "Restore configuration from $BackupFile? Current configuration will be backed up first. (y/n)"
        if ($confirmation -ne 'y') {
            Write-Host "Restore cancelled" -ForegroundColor Yellow
            return $false
        }
    }
    
    try {
        # Create backup of current configuration
        $currentBackup = Backup-NotificationConfig -Description "Auto-backup before restore" -Silent
        Write-Verbose "Current configuration backed up to: $currentBackup"
        
        # Load backup data
        $backupData = Get-Content $backupPath -Raw | ConvertFrom-Json
        
        # Restore configuration
        $currentConfig = Get-NotificationConfig -NoCache
        
        # Restore notification sections
        $currentConfig.Notifications = $backupData.Configuration.Notifications
        $currentConfig.EmailNotifications = $backupData.Configuration.EmailNotifications
        $currentConfig.WebhookNotifications = $backupData.Configuration.WebhookNotifications
        $currentConfig.NotificationTriggers = $backupData.Configuration.NotificationTriggers
        
        # Save restored configuration
        $currentConfig | ConvertTo-Json -Depth 10 | Set-Content $script:ConfigPath -Encoding UTF8
        
        # Clear cache
        $script:ConfigCache = $null
        $script:ConfigCacheTime = $null
        
        Write-Host "Configuration restored successfully from: $BackupFile" -ForegroundColor Green
        Write-Host "Backup created: $($backupData.BackupTime) by $($backupData.BackupBy)" -ForegroundColor Gray
        if ($backupData.Description) {
            Write-Host "Description: $($backupData.Description)" -ForegroundColor Gray
        }
        
        return $true
        
    } catch {
        Write-Error "Failed to restore configuration: $_"
        return $false
    }
}