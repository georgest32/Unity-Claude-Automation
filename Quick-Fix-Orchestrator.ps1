# Quick fix for Orchestrator issues

Write-Host "`nAPPLYING QUICK FIXES..." -ForegroundColor Cyan

# 1. Install enhanced WindowManager
$src = ".\Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager-Enhanced.psm1"
$dst = ".\Modules\Unity-Claude-CLIOrchestrator\Core\WindowManager.psm1"
if (Test-Path $src) {
    Copy-Item $dst "$dst.backup" -Force
    Copy-Item $src $dst -Force
    Write-Host "✅ Enhanced WindowManager installed" -ForegroundColor Green
}

# 2. Mark old signals as processed
Get-ChildItem ".\ClaudeResponses\Autonomous\TestComplete_*.signal" -ErrorAction SilentlyContinue | 
    ForEach-Object { 
        if (-not (Test-Path "$($_.FullName).processed")) {
            "Processed" | Set-Content "$($_.FullName).processed"
        }
    }
Write-Host "✅ Old signals marked as processed" -ForegroundColor Green

# 3. Create test JSON
@{
    details = "./Test-CLIOrchestrator-Quick-Fixed.ps1"
    RESPONSE = "RECOMMENDATION: TEST - ./Test-CLIOrchestrator-Quick-Fixed.ps1"
    prompt_type = "Testing"
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    confidence = 95
} | ConvertTo-Json | Out-File ".\ClaudeResponses\Autonomous\Test_$(Get-Date -Format 'HHmmss').json" -Encoding UTF8
Write-Host "✅ Test JSON created" -ForegroundColor Green

# 4. Reload module
Get-Module Unity-Claude-CLIOrchestrator | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force
Write-Host "✅ Module reloaded" -ForegroundColor Green

Write-Host "`n✅ COMPLETE! Watch for [WINDOW-FIND] logs in orchestrator output" -ForegroundColor Green