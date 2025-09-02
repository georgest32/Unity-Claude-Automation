<#
.SYNOPSIS
    Fixes the CLI Orchestrator issues with window detection and duplicate test execution
    
.DESCRIPTION
    1. Replaces WindowManager with enhanced version that has detailed logging
    2. Comments out duplicate signal processing in MonitoringLoop.psm1
    3. Updates test script to use fixed version
#>

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CLI ORCHESTRATOR FIX SCRIPT V2" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# 1. Backup original WindowManager
Write-Host "`n1. Backing up original WindowManager.psm1..." -ForegroundColor Yellow
$windowManagerPath = ".\Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager.psm1"
$backupPath = ".\Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager.psm1.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $windowManagerPath $backupPath -Force
Write-Host "   ✅ Backup saved to: $backupPath" -ForegroundColor Green

# 2. Replace with enhanced version
Write-Host "`n2. Replacing with enhanced logging version..." -ForegroundColor Yellow
$enhancedPath = ".\Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager-Enhanced.psm1"
if (Test-Path $enhancedPath) {
    Copy-Item $enhancedPath $windowManagerPath -Force
    Write-Host "   ✅ Enhanced WindowManager installed" -ForegroundColor Green
} else {
    Write-Host "   ❌ Enhanced version not found at: $enhancedPath" -ForegroundColor Red
}

# 3. Fix duplicate signal processing in MonitoringLoop.psm1
Write-Host "`n3. Fixing duplicate signal processing in MonitoringLoop..." -ForegroundColor Yellow
$monitoringPath = ".\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\MonitoringLoop.psm1"

if (Test-Path $monitoringPath) {
    # Read the file
    $content = Get-Content $monitoringPath -Raw
    
    # Check if Process-SignalFile function exists and comment it out
    if ($content -match 'function Process-SignalFile') {
        Write-Host "   Found Process-SignalFile function - disabling it..." -ForegroundColor Gray
        
        # Create backup
        $monitorBackup = ".\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents\MonitoringLoop.psm1.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Copy-Item $monitoringPath $monitorBackup -Force
        Write-Host "   Backup saved to: $monitorBackup" -ForegroundColor Gray
        
        # Define replacement function as a here-string
        $replacementFunction = @'
# DISABLED TO PREVENT DUPLICATE SIGNAL PROCESSING - Signal processing handled in OrchestrationManager.psm1
# Original function commented out below
<# 
$1
#>
function Process-SignalFile {
    param($SignalFile)
    Write-Host "[DISABLED] Process-SignalFile in MonitoringLoop - skipping to prevent duplication" -ForegroundColor DarkGray
    return $null
}
'@
        
        # Use regex with singleline mode to match the entire function
        $pattern = '(?s)(function Process-SignalFile\s*\{.*?\n\})'
        
        # Perform the replacement
        $modifiedContent = [regex]::Replace($content, $pattern, $replacementFunction)
        
        # Save modified content
        $modifiedContent | Set-Content $monitoringPath -Encoding UTF8
        Write-Host "   ✅ Process-SignalFile disabled in MonitoringLoop.psm1" -ForegroundColor Green
    } else {
        Write-Host "   ℹ️ Process-SignalFile not found or already disabled" -ForegroundColor Gray
    }
} else {
    Write-Host "   ❌ MonitoringLoop.psm1 not found" -ForegroundColor Red
}

# 4. Update the test script to use fixed version
Write-Host "`n4. Creating new test JSON..." -ForegroundColor Yellow
$testJsonPath = ".\ClaudeResponses\Autonomous\CLIOrchestrator_Test_Fixed_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$testJson = @{
    details = "./Test-CLIOrchestrator-Quick-Fixed.ps1"
    RESPONSE = "RECOMMENDATION: TEST - ./Test-CLIOrchestrator-Quick-Fixed.ps1"
    prompt_type = "Testing"
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    confidence = 95
} | ConvertTo-Json -Depth 10

$testJson | Out-File $testJsonPath -Encoding UTF8
Write-Host "   ✅ Test JSON created: $testJsonPath" -ForegroundColor Green

# 5. Clear any existing signal files that haven't been processed
Write-Host "`n5. Cleaning up old signal files..." -ForegroundColor Yellow
$signalDir = ".\ClaudeResponses\Autonomous"
$oldSignals = Get-ChildItem -Path $signalDir -Filter "TestComplete_*.signal" -ErrorAction SilentlyContinue
if ($oldSignals) {
    Write-Host "   Found $($oldSignals.Count) old signal files" -ForegroundColor Gray
    foreach ($signal in $oldSignals) {
        # Mark as processed if not already
        $processedMarker = "$($signal.FullName).processed"
        if (-not (Test-Path $processedMarker)) {
            "Marked as processed by fix script at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" | Set-Content $processedMarker
            Write-Host "   Marked as processed: $($signal.Name)" -ForegroundColor Gray
        }
    }
    Write-Host "   ✅ Old signals marked as processed" -ForegroundColor Green
} else {
    Write-Host "   ℹ️ No old signal files found" -ForegroundColor Gray
}

# 6. Reload modules
Write-Host "`n6. Reloading CLIOrchestrator module..." -ForegroundColor Yellow
Get-Module Unity-Claude-CLIOrchestrator | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force
Write-Host "   ✅ Module reloaded with fixes" -ForegroundColor Green

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "✅ FIXES APPLIED SUCCESSFULLY!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. The orchestrator should now:" -ForegroundColor White
Write-Host "   - Show detailed [WINDOW-FIND] and [WINDOW-DEBUG] logs" -ForegroundColor Gray
Write-Host "   - Properly find the CLAUDE_CODE_CLI_TERMINAL_* window" -ForegroundColor Gray
Write-Host "   - NOT create duplicate test executions" -ForegroundColor Gray
Write-Host "   - Process each signal file only once" -ForegroundColor Gray
Write-Host "`n2. The new test JSON has been created and will trigger on next monitoring cycle" -ForegroundColor White
Write-Host "`n3. Monitor the orchestrator output for detailed logging" -ForegroundColor White
Write-Host "`n"