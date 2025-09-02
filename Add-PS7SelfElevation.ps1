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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCANbR0e3VNuDqtf
# Uy6neS9/slylh055WRrLVe1ltv/hnaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIM09ZzHnFogC9zc3AxZ8W6FH
# Eu2PPIZYEHW05GUqwtwOMA0GCSqGSIb3DQEBAQUABIIBAF62zF4A/upbvmPuoqU1
# FUr9265KC/HVSV7YJ0EYvdc8WHc3bbBZkqgAukrvkOQFc9SjO/zeM4RMcobeekCb
# BM1xFyJezBovescx/hQUBWlY0BiwqBci6v+ycPWdlhjqKolCci8xMH1Oy8c6eaoq
# H1Z+yJsrwG1aT6MOpsPqDupX5bf/4HDJpdPGbzf3qES2Y/+doGn7s0YHcZXnviKM
# NJzDpOWn0Mrqd3oRL+Szrm0FnyIu6YTsjTJ6K2KBZgY4M9XtvzZnLiFTbBANr1ES
# cfNjf0XKgsnYpW3PDZJNJ1D9Edl9xsFcLXohqHZHwher3oQ+EP5lXNc63czy8MXJ
# +ZA=
# SIG # End signature block
