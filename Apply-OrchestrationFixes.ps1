<#
.SYNOPSIS
    Applies fixes for CLI Orchestrator window detection and duplicate test issues
#>

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "APPLYING CLI ORCHESTRATOR FIXES" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Replace WindowManager with enhanced version
Write-Host "`n1. Installing enhanced WindowManager..." -ForegroundColor Yellow
$windowManagerPath = ".\Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager.psm1"
$enhancedPath = ".\Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager-Enhanced.psm1"

if (Test-Path $enhancedPath) {
    # Backup original
    $backup = "$windowManagerPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $windowManagerPath $backup -Force
    Write-Host "   Backup: $backup" -ForegroundColor Gray
    
    # Replace with enhanced
    Copy-Item $enhancedPath $windowManagerPath -Force
    Write-Host "   ✅ Enhanced WindowManager installed" -ForegroundColor Green
}
else {
    Write-Host "   ❌ Enhanced version not found" -ForegroundColor Red
}

# 2. Disable duplicate signal processing
Write-Host "`n2. Disabling duplicate signal processing..." -ForegroundColor Yellow
$monitoringPath = ".\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\MonitoringLoop.psm1"

if (Test-Path $monitoringPath) {
    # Backup
    $backup = "$monitoringPath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $monitoringPath $backup -Force
    Write-Host "   Backup: $backup" -ForegroundColor Gray
    
    # Read content
    $content = Get-Content $monitoringPath -Raw
    
    # Add early return to Process-SignalFile if it exists
    if ($content -match 'function Process-SignalFile') {
        # Use simple string replacement to add early return
        $newContent = $content -replace '(function Process-SignalFile\s*\{[^}]*?param[^}]*?\))', @'
$1
    # DISABLED TO PREVENT DUPLICATE PROCESSING
    Write-Host "[DISABLED] Process-SignalFile in MonitoringLoop" -ForegroundColor DarkGray
    return $null
'@
        
        # Save
        $newContent | Set-Content $monitoringPath -Encoding UTF8
        Write-Host "   ✅ Process-SignalFile disabled" -ForegroundColor Green
    }
    else {
        Write-Host "   ℹ️ Process-SignalFile not found" -ForegroundColor Gray
    }
}
else {
    Write-Host "   ❌ MonitoringLoop.psm1 not found" -ForegroundColor Red
}

# 3. Mark old signals as processed
Write-Host "`n3. Cleaning up old signals..." -ForegroundColor Yellow
$signals = Get-ChildItem ".\ClaudeResponses\Autonomous" -Filter "TestComplete_*.signal" -ErrorAction SilentlyContinue
foreach ($signal in $signals) {
    $processed = "$($signal.FullName).processed"
    if (-not (Test-Path $processed)) {
        "Processed" | Set-Content $processed
        Write-Host "   Marked: $($signal.Name)" -ForegroundColor Gray
    }
}
Write-Host "   ✅ Signals cleaned" -ForegroundColor Green

# 4. Create test JSON
Write-Host "`n4. Creating test JSON..." -ForegroundColor Yellow
$json = @{
    details = "./Test-CLIOrchestrator-Quick-Fixed.ps1"
    RESPONSE = "RECOMMENDATION: TEST - ./Test-CLIOrchestrator-Quick-Fixed.ps1"
    prompt_type = "Testing"
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    confidence = 95
} | ConvertTo-Json

$jsonPath = ".\ClaudeResponses\Autonomous\Test_Fixed_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$json | Out-File $jsonPath -Encoding UTF8
Write-Host "   ✅ Created: $jsonPath" -ForegroundColor Green

# 5. Reload module
Write-Host "`n5. Reloading module..." -ForegroundColor Yellow
Get-Module Unity-Claude-CLIOrchestrator | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force
Write-Host "   ✅ Module reloaded" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "✅ FIXES APPLIED!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`nThe orchestrator should now:"
Write-Host "- Show [WINDOW-FIND] debug logs"
Write-Host "- Find CLAUDE_CODE_CLI_TERMINAL_* windows"
Write-Host "- NOT duplicate test executions"
Write-Host "- Process signals only once"
Write-Host ""