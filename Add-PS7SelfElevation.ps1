#Requires -Version 5.1
<#
.SYNOPSIS
    Adds PowerShell 7 self-elevation to all main scripts
.DESCRIPTION
    Modifies scripts to automatically re-launch themselves with PowerShell 7 if running in PS 5.1
#>

param(
    [switch]$WhatIf
)

$ErrorActionPreference = 'Stop'

Write-Host "Adding PowerShell 7 Self-Elevation to Scripts" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

# The self-elevation code to add to the beginning of each script
$selfElevationCode = @'
# PowerShell 7 Self-Elevation
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh7 = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $pwsh7) {
        Write-Host "Upgrading to PowerShell 7..." -ForegroundColor Yellow
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $MyInvocation.MyCommand.Path) + $args
        Start-Process -FilePath $pwsh7 -ArgumentList $arguments -NoNewWindow -Wait
        exit
    } else {
        Write-Warning "PowerShell 7 not found. Running in PowerShell $($PSVersionTable.PSVersion)"
    }
}
'@

# Get script directory
$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation" }

# List of main entry point scripts to update
$scriptsToUpdate = @(
    "$scriptDir\Start-UnifiedSystem-Complete.ps1",
    "$scriptDir\Start-UnifiedSystem.ps1",
    "$scriptDir\Start-UnifiedSystem-Final.ps1",
    "$scriptDir\Start-UnifiedSystem-Fixed.ps1",
    "$scriptDir\Start-SystemStatusMonitoring-Generic.ps1",
    "$scriptDir\Start-SystemStatusMonitoring-Window.ps1",
    "$scriptDir\Start-SystemStatusMonitoring-Enhanced.ps1",
    "$scriptDir\Start-SystemStatusMonitoring-Working.ps1",
    "$scriptDir\Start-SystemStatusMonitoring.ps1",
    "$scriptDir\Start-AutonomousMonitoring.ps1",
    "$scriptDir\Start-AutonomousMonitoring-Fixed.ps1",
    "$scriptDir\Start-AutonomousMonitoring-Enhanced.ps1",
    "$scriptDir\Start-UnityClaudeAutomation.ps1",
    "$scriptDir\Start-BidirectionalServer.ps1",
    "$scriptDir\Start-SimpleMonitoring.ps1",
    "$scriptDir\Start-SimpleDashboard.ps1",
    "$scriptDir\Start-EnhancedDashboard.ps1",
    "$scriptDir\Start-EnhancedDashboard-Fixed.ps1",
    "$scriptDir\Start-EnhancedDashboard-Working.ps1"
)

$updatedCount = 0
$skippedCount = 0

foreach ($scriptPath in $scriptsToUpdate) {
    if (Test-Path $scriptPath) {
        Write-Host "`nProcessing: $scriptPath" -ForegroundColor Gray
        
        $content = Get-Content $scriptPath -Raw
        
        # Check if already has PS7 elevation
        if ($content -match "PowerShell 7 Self-Elevation") {
            Write-Host "  Already has PS7 elevation - skipping" -ForegroundColor Yellow
            $skippedCount++
            continue
        }
        
        # Find the insertion point (after any #Requires statements and comments)
        $lines = $content -split "`r?`n"
        $insertIndex = 0
        
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i].Trim()
            
            # Skip empty lines, comments, and #Requires
            if ($line -eq "" -or $line.StartsWith("#") -or $line.StartsWith("<#")) {
                continue
            }
            
            # Found first real code line
            $insertIndex = $i
            break
        }
        
        # Insert the self-elevation code
        $newLines = @()
        $newLines += $lines[0..($insertIndex-1)]
        $newLines += ""
        $newLines += $selfElevationCode -split "`r?`n"
        $newLines += ""
        $newLines += $lines[$insertIndex..($lines.Count-1)]
        
        $newContent = $newLines -join "`r`n"
        
        if ($WhatIf) {
            Write-Host "  Would update script with PS7 elevation" -ForegroundColor Yellow
        } else {
            # Backup original
            $backupPath = "$scriptPath.ps5backup"
            Copy-Item -Path $scriptPath -Destination $backupPath -Force
            
            # Write updated content
            Set-Content -Path $scriptPath -Value $newContent -Encoding UTF8
            Write-Host "  Updated with PS7 elevation (backup: $backupPath)" -ForegroundColor Green
            $updatedCount++
        }
    } else {
        Write-Host "  Script not found: $scriptPath" -ForegroundColor DarkGray
    }
}

Write-Host "`n==============================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Scripts updated: $updatedCount" -ForegroundColor Green
Write-Host "  Scripts skipped: $skippedCount" -ForegroundColor Yellow

if ($WhatIf) {
    Write-Host "`n(WhatIf mode - no actual changes made)" -ForegroundColor Yellow
    Write-Host "Run without -WhatIf to apply changes" -ForegroundColor White
}

Write-Host "`nHow it works:" -ForegroundColor Cyan
Write-Host "1. Scripts check if running in PS 5.1" -ForegroundColor White
Write-Host "2. If yes, they automatically restart with PS7" -ForegroundColor White
Write-Host "3. If PS7 not found, they continue in PS 5.1 with a warning" -ForegroundColor White

Write-Host "`nTest it by running any updated script from:" -ForegroundColor Cyan
Write-Host "- Windows Explorer (double-click)" -ForegroundColor White
Write-Host "- PowerShell 5.1 (powershell.exe)" -ForegroundColor White
Write-Host "- Command Prompt (cmd.exe)" -ForegroundColor White
Write-Host "All should automatically upgrade to PowerShell 7!" -ForegroundColor Green