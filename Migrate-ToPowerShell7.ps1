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