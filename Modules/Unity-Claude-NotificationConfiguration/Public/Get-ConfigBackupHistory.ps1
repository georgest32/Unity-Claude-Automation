function Get-ConfigBackupHistory {
    <#
    .SYNOPSIS
    Gets the history of configuration backups
    
    .DESCRIPTION
    Lists all available configuration backups with metadata
    
    .PARAMETER Limit
    Maximum number of backups to return
    
    .EXAMPLE
    Get-ConfigBackupHistory -Limit 10
    #>
    [CmdletBinding()]
    param(
        [int]$Limit = 20
    )
    
    $backups = @()
    
    if (-not (Test-Path $script:BackupPath)) {
        Write-Warning "Backup directory does not exist: $script:BackupPath"
        return $backups
    }
    
    $backupFiles = Get-ChildItem $script:BackupPath -Filter "notificationconfig_backup_*.json" -ErrorAction SilentlyContinue | 
                   Sort-Object LastWriteTime -Descending | 
                   Select-Object -First $Limit
    
    foreach ($file in $backupFiles) {
        try {
            $data = Get-Content $file.FullName -Raw | ConvertFrom-Json
            $backups += @{
                FileName = $file.Name
                FilePath = $file.FullName
                BackupTime = $data.BackupTime
                BackupBy = $data.BackupBy
                Description = $data.Description
                FileSize = $file.Length
            }
        } catch {
            Write-Warning "Could not read backup file: $($file.Name)"
        }
    }
    
    return $backups
}