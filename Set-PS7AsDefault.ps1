#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Sets PowerShell 7 as the default handler for .ps1 files
.DESCRIPTION
    Updates Windows file associations and creates context menu entries for PowerShell 7
#>

param(
    [switch]$SystemWide,
    [switch]$CreateLaunchers
)

$ErrorActionPreference = 'Stop'

Write-Host "PowerShell 7 Default Configuration Tool" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$pwshPath = "C:\Program Files\PowerShell\7\pwsh.exe"

if (-not (Test-Path $pwshPath)) {
    Write-Error "PowerShell 7 not found at: $pwshPath"
    return
}

# Method 1: Update file association via registry
Write-Host "`nMethod 1: Updating file associations..." -ForegroundColor Yellow

try {
    # Update the .ps1 file association
    $regPath = if ($SystemWide) { "HKLM:\SOFTWARE\Classes" } else { "HKCU:\SOFTWARE\Classes" }
    
    # Create/update .ps1 file type
    $ps1Path = "$regPath\.ps1"
    if (-not (Test-Path $ps1Path)) {
        New-Item -Path $ps1Path -Force | Out-Null
    }
    Set-ItemProperty -Path $ps1Path -Name "(Default)" -Value "Microsoft.PowerShellScript.1"
    
    # Update the PowerShellScript handler
    $scriptPath = "$regPath\Microsoft.PowerShellScript.1\Shell\Open\Command"
    if (-not (Test-Path $scriptPath)) {
        New-Item -Path $scriptPath -Force | Out-Null
    }
    
    # Set PowerShell 7 as the default handler
    $command = "`"$pwshPath`" -NoLogo -File `"%1`" %*"
    Set-ItemProperty -Path $scriptPath -Name "(Default)" -Value $command
    
    Write-Host "  File association updated successfully" -ForegroundColor Green
    
    # Add "Run with PowerShell 7" context menu
    $contextPath = "$regPath\Microsoft.PowerShellScript.1\Shell\RunWithPowerShell7"
    New-Item -Path $contextPath -Force | Out-Null
    Set-ItemProperty -Path $contextPath -Name "(Default)" -Value "Run with PowerShell 7"
    Set-ItemProperty -Path $contextPath -Name "Icon" -Value "$pwshPath,0"
    
    $contextCmdPath = "$contextPath\Command"
    New-Item -Path $contextCmdPath -Force | Out-Null
    Set-ItemProperty -Path $contextCmdPath -Name "(Default)" -Value $command
    
    Write-Host "  Context menu entry added" -ForegroundColor Green
    
} catch {
    Write-Warning "Could not update registry: $_"
    Write-Host "You may need to run this script as Administrator" -ForegroundColor Yellow
}

# Method 2: Create launcher batch files
if ($CreateLaunchers) {
    Write-Host "`nMethod 2: Creating launcher batch files..." -ForegroundColor Yellow
    
    $launchersToCreate = @(
        "Start-UnifiedSystem-Complete",
        "Start-UnifiedSystem",
        "Start-SystemStatusMonitoring-Generic",
        "Start-AutonomousMonitoring-Fixed"
    )
    
    foreach ($launcher in $launchersToCreate) {
        $batchContent = @"
@echo off
"$pwshPath" -NoExit -ExecutionPolicy Bypass -File "%~dp0$launcher.ps1" %*
"@
        $batchFile = ".\$launcher.bat"
        Set-Content -Path $batchFile -Value $batchContent -Encoding ASCII
        Write-Host "  Created: $batchFile" -ForegroundColor Green
    }
}

# Method 3: Create a universal launcher
Write-Host "`nMethod 3: Creating universal PS7 launcher..." -ForegroundColor Yellow

$universalLauncher = @'
@echo off
REM Universal PowerShell 7 Launcher for Unity-Claude-Automation
REM Drop any .ps1 file onto this batch file to run it with PowerShell 7

set PWSH="C:\Program Files\PowerShell\7\pwsh.exe"

if "%~1"=="" (
    echo Drag and drop a PowerShell script onto this file to run it with PowerShell 7
    echo Or double-click to open PowerShell 7 in this directory
    %PWSH% -NoExit -WorkingDirectory "%~dp0"
) else (
    %PWSH% -NoExit -ExecutionPolicy Bypass -File "%~1" %2 %3 %4 %5 %6 %7 %8 %9
)
'@

Set-Content -Path ".\RunWithPS7.bat" -Value $universalLauncher -Encoding ASCII
Write-Host "  Created: RunWithPS7.bat (universal launcher)" -ForegroundColor Green

# Method 4: Update PowerShell profile to detect version
Write-Host "`nMethod 4: Creating PS7 detection profile..." -ForegroundColor Yellow

$profileContent = @'
# PowerShell 7 Detection and Auto-Upgrade
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh7 = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $pwsh7) {
        Write-Warning "You are running PowerShell $($PSVersionTable.PSVersion). PowerShell 7 is available."
        Write-Host "To switch to PowerShell 7, type: " -NoNewline
        Write-Host "pwsh" -ForegroundColor Cyan
        Write-Host ""
    }
}

# Add PS7 to path if not already there
if ($env:Path -notlike "*PowerShell\7*") {
    $env:Path += ";C:\Program Files\PowerShell\7"
}
'@

$profilePath = ".\PS7-Profile-Addition.ps1"
Set-Content -Path $profilePath -Value $profileContent -Encoding UTF8
Write-Host "  Created: PS7-Profile-Addition.ps1" -ForegroundColor Green
Write-Host "  Add this to your `$PROFILE to get PS7 reminders" -ForegroundColor Yellow

# Show summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "`nWhat was configured:" -ForegroundColor Cyan

Write-Host "1. File associations updated (double-click .ps1 files to use PS7)" -ForegroundColor White
Write-Host "2. Context menu 'Run with PowerShell 7' added" -ForegroundColor White
Write-Host "3. Created RunWithPS7.bat universal launcher" -ForegroundColor White

if ($CreateLaunchers) {
    Write-Host "4. Created .bat launchers for main scripts" -ForegroundColor White
}

Write-Host "`nTo make changes take effect:" -ForegroundColor Yellow
Write-Host "1. Close and reopen File Explorer" -ForegroundColor White
Write-Host "2. Or run: Stop-Process -Name explorer -Force; Start-Process explorer" -ForegroundColor White

Write-Host "`nTest it:" -ForegroundColor Cyan
Write-Host "- Double-click any .ps1 file - it should open in PowerShell 7" -ForegroundColor White
Write-Host "- Right-click any .ps1 file - you should see 'Run with PowerShell 7'" -ForegroundColor White
Write-Host "- Double-click RunWithPS7.bat to open PS7 in current directory" -ForegroundColor White
'@

Set-Content -Path ".\Set-PS7AsDefault.ps1" -Value $profileContent -Encoding UTF8
Write-Host "  Created: Set-PS7AsDefault.ps1" -ForegroundColor Green
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCACxbUBbl//rUxo
# Q2JGcTeDC8SoPlPX2x2rcy20zcD/uaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFfu07LA9xT65hksr0qUUO7k
# VQjrX6hL85liOmlSeKMCMA0GCSqGSIb3DQEBAQUABIIBABCQ2w80/rSJ9ueh8uMf
# CK0fNNBb5VD7rlkQLtON0zYvTqdJgsPoiw7hTMzHrb9Us5HzQT/q4sWIsQdb8rLk
# sJj83Wxk+3yvhtd3Kk82ktZJTi5wbDcgOCOCEabBDeja7/aqf1LUwJ732VahC+E5
# uBlBMPbhF0Ca8qNdOtPMyvNoanOQkvbmDmQZr/5flPlDTJ8IkF7iAZXrULQn3xn1
# vYTULNZbEptg8Bhfhg21a7FYIYL9M2spO7J6sfy7k8Jp5AMAiA43qwtJAoCGSaqS
# tWGTAtAHb87BlvQUi3hFeDbMhAc6JImQ+sEmWNP8eLQvIwJLtMDhIkxJW7lnvXyb
# fqs=
# SIG # End signature block
