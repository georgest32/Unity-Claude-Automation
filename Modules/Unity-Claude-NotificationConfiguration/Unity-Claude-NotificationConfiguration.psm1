# Unity-Claude-NotificationConfiguration Module
# Purpose: Configuration management for notification settings
# Created: 2025-08-22
# Week 6 Day 5 Implementation - Hour 1-4

# Module Variables
$script:ConfigPath = Join-Path $PSScriptRoot "..\..\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json"
$script:BackupPath = Join-Path $PSScriptRoot "..\..\Backups\NotificationConfig"
$script:ConfigCache = $null
$script:ConfigCacheTime = $null
$script:CacheDuration = 300 # 5 minutes

# Initialize backup directory
if (-not (Test-Path $script:BackupPath)) {
    New-Item -Path $script:BackupPath -ItemType Directory -Force | Out-Null
    Write-Host "[NotificationConfiguration] Created backup directory: $script:BackupPath" -ForegroundColor Gray
}

# Load Public Functions
$publicFunctions = @(
    'Get-NotificationConfig',
    'Set-NotificationConfig',
    'Test-NotificationConfig',
    'Reset-NotificationConfig',
    'Backup-NotificationConfig',
    'Restore-NotificationConfig',
    'Get-ConfigBackupHistory',
    'Start-NotificationConfigWizard',
    'Export-NotificationConfig',
    'Import-NotificationConfig',
    'Compare-NotificationConfig',
    'Get-ConfigurationReport'
)

$publicPath = Join-Path $PSScriptRoot "Public"
foreach ($file in Get-ChildItem -Path $publicPath -Filter "*.ps1" -ErrorAction SilentlyContinue) {
    try {
        . $file.FullName
        Write-Debug "[NotificationConfiguration] Loaded public function: $($file.BaseName)"
    } catch {
        Write-Warning "[NotificationConfiguration] Failed to load public function $($file.BaseName): $_"
    }
}

# Load Private Functions
$privatePath = Join-Path $PSScriptRoot "Private"
foreach ($file in Get-ChildItem -Path $privatePath -Filter "*.ps1" -ErrorAction SilentlyContinue) {
    try {
        . $file.FullName
        Write-Debug "[NotificationConfiguration] Loaded private function: $($file.BaseName)"
    } catch {
        Write-Warning "[NotificationConfiguration] Failed to load private function $($file.BaseName): $_"
    }
}

# Module initialization
Write-Host "[NotificationConfiguration] Module loaded successfully" -ForegroundColor Green
Write-Debug "[NotificationConfiguration] Config path: $script:ConfigPath"
Write-Debug "[NotificationConfiguration] Backup path: $script:BackupPath"

# Export module members
Export-ModuleMember -Function $publicFunctions
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCWOfov90aI5nXa
# Julw7FG+LLafQrh78f8XclPQ/B/IFqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFbHFR2rw+QfJpVwgshypgp5
# NZE/wKdYpbDNC5wioI+zMA0GCSqGSIb3DQEBAQUABIIBAJXs4HRw6CueAatwuGag
# GLw+294glvDC//xnRZihIQRHQINbff2kzpyyOM2lv18HxU/hpzDXwCei4NAiAbqm
# cMWDacnfIE0gXPCX1MRmy5Jd5naCt1qYhEuyJM7Fqt57H6fG/spE0BfYHnxxW/Dy
# X4dwwXLxmiZ94NQc2Y5MUWr1f+BdpeP6XWibIYG2qKu/dst/0viJMRI6Cb2PyLP7
# YGmuhbfJx+ZmcRMyO/aAEbkbveuQkmf61f6Yf+cAmpLM0t+My05tBC/MK71MNMUw
# 9K/L+eDcClM83A1/YXZESbFu1Yfb2NSfaZA/5gjTKQAlY/DKFDpC2cUaGRq8B7+D
# pf4=
# SIG # End signature block
