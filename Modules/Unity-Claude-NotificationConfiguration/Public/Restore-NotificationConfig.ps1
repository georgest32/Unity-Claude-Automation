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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDoWCvKwWb4/KRc
# K4FrhVfOKOdrWGR/HyvJ5KGWRr5q0KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIA5oJOdfl/4mminnyY8p8Wxh
# Q0+he7jaw8zjVX5Z0hVpMA0GCSqGSIb3DQEBAQUABIIBADK2LJY77pITnJH/CW8l
# i8jLse3fs/0l+2MQH+ZUswqJjVf91qdEGh/6LoUqP3RWGsr8whUwYpYWswN0i8U9
# aIohCDczyxaXUGO7m0vJSP5FwkdprjSSkTui7A0j37qilTnAkMAGypHM+RYOXyKB
# ZajJ0WCyep9146HtPLtfjIJlg6iHz/C3LRWoz7NQtw8w8SFF8TAu1ZwcAzicchgo
# /aa/7tf2G9d7462aQoAjOJ0Dl1mOmJp6EWZQYFmA0t3ByCvz/lcA8qiSfVnHpYv5
# hsFw5VVB7q6qTLbdmM11RTa0p4LBGDOsTAxzD9++082A1ZGPsGTUkgE7CoPtswE1
# Prg=
# SIG # End signature block
