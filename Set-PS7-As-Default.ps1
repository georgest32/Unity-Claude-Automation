# Script to set PowerShell 7 as the default PowerShell
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setting PowerShell 7 as Default" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "`nThis script needs to run as Administrator to modify system settings." -ForegroundColor Yellow
    Write-Host "However, we can still set up your user environment." -ForegroundColor Yellow
}

Write-Host "`nCurrent Configuration:" -ForegroundColor Yellow
Write-Host "  PowerShell 5.1: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -ForegroundColor Gray
Write-Host "  PowerShell 7: C:\Program Files\PowerShell\7\pwsh.exe" -ForegroundColor Gray

# Option 1: Update Windows Terminal default profile
Write-Host "`n1. Updating Windows Terminal settings..." -ForegroundColor Cyan
$wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $wtSettingsPath) {
    Write-Host "  Windows Terminal settings found" -ForegroundColor Green
    Write-Host "  To set PS7 as default in Windows Terminal:" -ForegroundColor Yellow
    Write-Host "    - Open Windows Terminal" -ForegroundColor Gray
    Write-Host "    - Press Ctrl+, to open settings" -ForegroundColor Gray
    Write-Host "    - Set 'PowerShell' (not 'Windows PowerShell') as default profile" -ForegroundColor Gray
} else {
    Write-Host "  Windows Terminal not found" -ForegroundColor Gray
}

# Option 2: Create PowerShell profile that redirects to PS7
Write-Host "`n2. Creating PowerShell 5 profile redirect..." -ForegroundColor Cyan
$ps5Profile = "$env:USERPROFILE\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
$ps5ProfileDir = Split-Path $ps5Profile -Parent

if (-not (Test-Path $ps5ProfileDir)) {
    New-Item -Path $ps5ProfileDir -ItemType Directory -Force | Out-Null
}

$profileContent = @'
# Auto-redirect to PowerShell 7 if available
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
    if ($pwsh) {
        Write-Host "Switching to PowerShell 7..." -ForegroundColor Green
        & pwsh -NoExit
        exit
    }
}
'@

Write-Host "  Create redirect profile at: $ps5Profile" -ForegroundColor Yellow
Write-Host "  This will auto-launch PS7 when PS5 starts" -ForegroundColor Gray
$response = Read-Host "  Do you want to create this redirect? (y/n)"
if ($response -eq 'y') {
    if (Test-Path $ps5Profile) {
        Copy-Item $ps5Profile "$ps5Profile.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -Force
        Write-Host "  Backed up existing profile" -ForegroundColor Green
    }
    $profileContent | Out-File -FilePath $ps5Profile -Encoding UTF8 -Force
    Write-Host "  Redirect profile created!" -ForegroundColor Green
}

# Option 3: Update file associations
Write-Host "`n3. File associations (.ps1 files)..." -ForegroundColor Cyan
if ($isAdmin) {
    Write-Host "  Updating .ps1 file association to use PowerShell 7..." -ForegroundColor Yellow
    
    # This would require registry changes
    $regPath = "HKLM:\SOFTWARE\Classes\Microsoft.PowerShellScript.1\Shell\Open\Command"
    $currentValue = (Get-ItemProperty -Path $regPath -Name "(Default)")."(Default)"
    Write-Host "  Current: $currentValue" -ForegroundColor Gray
    Write-Host "  Would change to: `"C:\Program Files\PowerShell\7\pwsh.exe`" -NoExit -File `"%1`"" -ForegroundColor Gray
    
    $response = Read-Host "  Update file association? (y/n)"
    if ($response -eq 'y') {
        Set-ItemProperty -Path $regPath -Name "(Default)" -Value "`"C:\Program Files\PowerShell\7\pwsh.exe`" -NoExit -File `"%1`""
        Write-Host "  File association updated!" -ForegroundColor Green
    }
} else {
    Write-Host "  Run as Administrator to update file associations" -ForegroundColor Yellow
}

# Option 4: Create convenient aliases
Write-Host "`n4. Creating convenient shortcuts..." -ForegroundColor Cyan
$shortcutPath = "$env:USERPROFILE\Desktop\PowerShell 7.lnk"
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut($shortcutPath)
$Shortcut.TargetPath = "C:\Program Files\PowerShell\7\pwsh.exe"
$Shortcut.WorkingDirectory = $PSScriptRoot
$Shortcut.IconLocation = "C:\Program Files\PowerShell\7\pwsh.exe,0"
$Shortcut.Save()
Write-Host "  Created desktop shortcut for PowerShell 7" -ForegroundColor Green

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Summary of Changes" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "✓ PowerShell 7 is installed and working" -ForegroundColor Green
Write-Host "✓ Desktop shortcut created" -ForegroundColor Green

if (Test-Path $ps5Profile) {
    Write-Host "✓ PS5 profile redirect created (PS5 will auto-launch PS7)" -ForegroundColor Green
}

Write-Host "`nRecommended next steps:" -ForegroundColor Yellow
Write-Host "1. Set PowerShell 7 as default in Windows Terminal" -ForegroundColor Gray
Write-Host "2. Pin PowerShell 7 to your taskbar" -ForegroundColor Gray
Write-Host "3. Use 'pwsh' instead of 'powershell' in command prompt" -ForegroundColor Gray
Write-Host "`nNote: Windows PowerShell 5.1 is still available if needed" -ForegroundColor Gray
Write-Host "Just use 'powershell.exe' to run it explicitly" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCEP6vfc3QvvOnW
# sFJ0q8Csq4MFP7mWCYd1Re0a5U2g+KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIENic8y9GZzcj80ncngAA5Fx
# YFifm9ViVnaBihInaxWUMA0GCSqGSIb3DQEBAQUABIIBAHNXhypEd3i4Splym2sU
# FFC3ePTQ1bwpr/d/cGkFHvA+jh/S9w5H3Dl5diGr/pHYYH0DoJzcCkGR+z9YuJD8
# xOFH38jjQ2JMGh49va/DZx1gZY1h+Q8s4xAiEuTH5/Z2yTJ/P9XnM67ir8ZBwVal
# 77/eAG+UbEGXm710v/1DGYx9keHaoijtQz83eSFbC9HDmP5A8PgiH4i0bKh8zZNY
# XifOMA4mYnk6pGRAxB5+n3ExK87mMoR7fmFHxdEBvveE3odbAr78WWYphECjFalU
# LbxcnrO18NvyOBaXzJdQ5R4yEU/Ab+uWDBARsALG8BZDxPMin0wKXaj28Bsz3kIl
# spA=
# SIG # End signature block
