#Requires -Version 7.0
<#
.SYNOPSIS
    Migrates Unity-Claude-Automation project from PowerShell 5.1 to PowerShell 7
.DESCRIPTION
    Updates all scripts to use pwsh.exe instead of powershell.exe and fixes compatibility issues
#>

param(
    [switch]$WhatIf,
    [switch]$BackupFirst
)

$ErrorActionPreference = 'Stop'

Write-Host "Unity-Claude-Automation PowerShell 7 Migration Tool" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# Backup if requested
if ($BackupFirst) {
    $backupPath = ".\Backups\PS7Migration_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Write-Host "Creating backup at: $backupPath" -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
    Copy-Item -Path ".\*.ps1", ".\*.psm1", ".\*.psd1" -Destination $backupPath -Recurse
}

# Files to update
$filesToUpdate = @(
    ".\Start-UnifiedSystem-Complete.ps1",
    ".\Start-UnifiedSystem.ps1",
    ".\Start-UnifiedSystem-Final.ps1",
    ".\Start-UnifiedSystem-Fixed.ps1",
    ".\Start-SystemStatusMonitoring-Generic.ps1",
    ".\Start-SystemStatusMonitoring-Window.ps1",
    ".\Start-BidirectionalServer-Launcher.ps1",
    ".\Test-AgentDeduplication.ps1",
    ".\Run-Phase3Day1-ComprehensiveTesting.ps1",
    ".\CLI-Automation\Submit-ErrorsToClaude-Automated.ps1",
    ".\Modules\Unity-Claude-SystemStatus\Execution\Start-SubsystemSafe.ps1",
    ".\Modules\Unity-Claude-SystemStatus\Monitoring\Test-AutonomousAgentStatus.ps1"
)

$updateCount = 0

foreach ($file in $filesToUpdate) {
    if (Test-Path $file) {
        Write-Host "Processing: $file" -ForegroundColor Gray
        
        $content = Get-Content $file -Raw
        $originalContent = $content
        
        # Replace powershell.exe with pwsh.exe
        $content = $content -replace 'powershell\.exe', 'pwsh.exe'
        $content = $content -replace '"powershell"', '"pwsh"'
        $content = $content -replace "'powershell'", "'pwsh'"
        
        # Update Start-Process calls
        $content = $content -replace 'Start-Process powershell(?!\.exe)', 'Start-Process pwsh'
        
        if ($content -ne $originalContent) {
            if ($WhatIf) {
                Write-Host "  Would update: $file" -ForegroundColor Yellow
            } else {
                Set-Content -Path $file -Value $content -Encoding UTF8
                Write-Host "  Updated: $file" -ForegroundColor Green
                $updateCount++
            }
        }
    }
}

# Update Get-ClaudeCodePID.ps1 specially (it checks for both)
$pidScript = ".\Get-ClaudeCodePID.ps1"
if (Test-Path $pidScript) {
    $content = Get-Content $pidScript -Raw
    # Ensure it checks for both pwsh.exe and powershell.exe for compatibility
    if ($content -notmatch "pwsh\.exe") {
        Write-Host "Get-ClaudeCodePID.ps1 already checks for both versions" -ForegroundColor Green
    }
}

# Create a compatibility checker
$compatScript = @'
#Requires -Version 7.0
<#
.SYNOPSIS
    Checks PowerShell 7 compatibility for Unity-Claude-Automation
#>

Write-Host "PowerShell 7 Compatibility Check" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan

# Check version
$version = $PSVersionTable.PSVersion
Write-Host "PowerShell Version: $version" -ForegroundColor Green

# Check important modules
$modules = @(
    'Unity-Claude-SystemStatus',
    'Unity-Claude-ParallelProcessing',
    'Unity-Claude-RunspaceManagement'
)

foreach ($module in $modules) {
    try {
        Import-Module ".\Modules\$module" -ErrorAction Stop
        Write-Host "  [OK] $module" -ForegroundColor Green
    } catch {
        Write-Host "  [FAIL] $module - $_" -ForegroundColor Red
    }
}

# Check concurrent collections
try {
    $queue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
    $queue.Enqueue("test")
    $result = $null
    if ($queue.TryDequeue([ref]$result)) {
        Write-Host "  [OK] ConcurrentQueue works" -ForegroundColor Green
    }
} catch {
    Write-Host "  [FAIL] ConcurrentQueue - $_" -ForegroundColor Red
}

Write-Host "`nCompatibility check complete!" -ForegroundColor Cyan
'@

if (-not $WhatIf) {
    $compatScript | Set-Content -Path ".\Test-PS7Compatibility.ps1" -Encoding UTF8
    Write-Host "`nCreated Test-PS7Compatibility.ps1" -ForegroundColor Green
}

Write-Host "`nMigration Summary:" -ForegroundColor Cyan
Write-Host "  Files updated: $updateCount" -ForegroundColor Green
if ($WhatIf) {
    Write-Host "  (WhatIf mode - no actual changes made)" -ForegroundColor Yellow
}

Write-Host "`nNext steps:" -ForegroundColor Cyan
Write-Host "1. Run: pwsh.exe .\Test-PS7Compatibility.ps1" -ForegroundColor White
Write-Host "2. Test main entry point: pwsh.exe .\Start-UnifiedSystem-Complete.ps1" -ForegroundColor White
Write-Host "3. Update any scheduled tasks or shortcuts to use pwsh.exe" -ForegroundColor White
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB9PtbkWrT2/Kt4
# k/xj3rz2YLhTg0//Kz8PFZBOW9jJqaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICulW9PM34YWylf/dnC9oHse
# l0a5Avhvt5dTE3KXQ/IoMA0GCSqGSIb3DQEBAQUABIIBAGwh/I/WYHycTeHU8Dt9
# iF7A4HkEDcK629qc68T0HFCo3xMFyF3d8eSuGdXX7QoZdOT3h1a+vYrexKLqG10i
# b8SfuqSAXjXKyv/PNnnUs4hv9Kg1rp+ykl6h7ZmamJ4PDzkIvyKwxN4Q6e75eatL
# sZRT8J0+JcXLicE6l2Pyss7IFV+l4OsR27hG01raZ00EeE83vJKur8+6SSDXXZyj
# IpKhZmYFtuIe/NyAndNvqPFckWhnrLt8qtJnA2pI1Hkmvp8p561DzgS9h2miHlPs
# Y69iwr0296uqHxYbvEvLI2eWBHyLJ3wX4+m0Wm6sF53Wx3wamDMSuTTJUGToz2ru
# O0I=
# SIG # End signature block
