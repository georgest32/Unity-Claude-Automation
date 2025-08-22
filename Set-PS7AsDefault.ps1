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