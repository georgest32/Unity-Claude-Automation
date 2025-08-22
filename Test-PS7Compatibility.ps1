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
