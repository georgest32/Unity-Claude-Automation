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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCKa4SSWNty8sIq
# COTvr0de4qdA34dVu3HrAdirQqCQdqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKXtsHiNSQDCfATVXd6J78XB
# 3dJYeenBTW7C3+vhN2ASMA0GCSqGSIb3DQEBAQUABIIBAFml4N5OcswemmMl1Jve
# 4EOPGf686AihGM5wGzBr+TkqrhIDalvNbLDqrQMMbmVHqyZMoDg8sUy3KW3yf2n4
# qBG2k618YG+gCj0kc20Xrj9FNZLUzVG5hmMlBD7/G1DN5L4yQ0VmilphNqXtL002
# VtOtx6sshsNNeOC95LSbVtalTtS7QMUHfA+pXkzXXKMK1brlmnVZg75y3ObiXYD5
# JkbJ77D23eHE2dUfmn18HqYuAEVuCWQdo9XqgGA6v8LrjJwIhwrTFatx/cvbbycc
# Y83DH6hxdQon3r73fnXbJaki6pcA2mjeqD3GzK20S1vtr2thi446KTnFbuFq8vNE
# 6R8=
# SIG # End signature block
