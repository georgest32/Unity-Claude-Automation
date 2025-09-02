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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDpdo0n9j9IQJnD
# GEvQkRMBgxl4swaWzZfRr3oqenvrUaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFe83r1olDe6FpuH/5eLnCzM
# 3SLgShl3cqeyHaQpEsdeMA0GCSqGSIb3DQEBAQUABIIBABFRKUc7G5A5ty0cXBpy
# Z8xdUX2sS8EppT8Th0LSF9eUlohrgvmYzUa3KO5h80MrdPVqkHZeYuh/ssQjfWeo
# qbtmSyKKJ2IDgdb/VN3YsWTYnrvyJPbDlWFA6kG9PlPsGkgL1et9x1iE5+sa/at0
# AJGkRNE3j6C01Uv9oLWZOgSzc7g6TNwcZEjUiE/12Xvz4ywwVyNIZQ3FFklj4Qr+
# S5cx4XxeFESLhiB24TQAcbnMOiO3e5kTyjoJ6Fx2M4VzzlgJqkXceWsSo1ay4VLF
# IbzjB/8JJw520WFUGDisqEjrIxECf+XHSDGw2Nhf+9d693pqmGBIF/+qZ/eRqZwM
# ruU=
# SIG # End signature block
