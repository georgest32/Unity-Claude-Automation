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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAZXTeHcPqdT1Nb
# +NuzIiXJVktxjxcv3/pQQ9R8aKixfqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJJVKdtU5NJFThtLr9GeLtjf
# BR0mGWNiyzshGlLQnd5nMA0GCSqGSIb3DQEBAQUABIIBAHNQrlBz0fQHqXeLs5wQ
# ItvdYWNTOiF4nBbwe4/HrPdAX+XhEbnsuPXDgu+mD45X0fQr0VxzXJKwoxyr8FwE
# /EAc2yNDdHr2QzatCA52wnACJjFbnj0GrXs1aVdX/wX0CTYn0FNjA2mzlQfu8+rC
# mC7zGo5u4Izm2rwc0Muw4Hoq9eRAOKLJAyyVJFUG2yjrrk/2PRWCzHRE9CwdR1fY
# k3GZfNTTkIjuoPVCjj9OO3Qf5XOewCEXjJ/T0jlFjO6NxhrZ7O4XxNZMjLfc+R57
# +YF0CvupDgFpRgCDDZEmeBSblx61IXuFD1JF6gy1vqVzk2jjPsxAkhnUJ/6reRsh
# AWI=
# SIG # End signature block
