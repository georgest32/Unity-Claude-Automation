# Restart-Orchestrator.ps1
# Helper script to restart the CLI Orchestrator with new code changes

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " CLI ORCHESTRATOR RESTART HELPER" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Stop existing orchestrator processes
Write-Host "[1/3] Stopping existing orchestrator processes..." -ForegroundColor Yellow
$orchestratorProcesses = Get-Process | Where-Object {
    $_.MainWindowTitle -like "*CLIOrchestrator*" -or 
    $_.MainWindowTitle -like "*CLI Orchestrator*" -or
    $_.CommandLine -like "*Start-CLIOrchestrator.ps1*"
}

if ($orchestratorProcesses) {
    foreach ($proc in $orchestratorProcesses) {
        Write-Host "  Stopping process $($proc.Id) - $($proc.ProcessName)" -ForegroundColor Gray
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
    }
    Write-Host "  Orchestrator processes stopped." -ForegroundColor Green
    Start-Sleep -Seconds 2
} else {
    Write-Host "  No orchestrator processes found running." -ForegroundColor Gray
}

# Clear processed markers for testing (optional)
$clearProcessed = Read-Host "Clear processed markers for retesting? (y/n) [n]"
if ($clearProcessed -eq 'y') {
    Write-Host "[2/3] Clearing processed markers..." -ForegroundColor Yellow
    $processedFiles = Get-ChildItem ".\ClaudeResponses\Autonomous\*.processed" -ErrorAction SilentlyContinue
    if ($processedFiles) {
        $processedFiles | Remove-Item -Force
        Write-Host "  Cleared $($processedFiles.Count) processed markers." -ForegroundColor Green
    } else {
        Write-Host "  No processed markers to clear." -ForegroundColor Gray
    }
} else {
    Write-Host "[2/3] Keeping existing processed markers." -ForegroundColor Gray
}

# Start new orchestrator
Write-Host "[3/3] Starting new orchestrator instance..." -ForegroundColor Yellow
Write-Host "  Launching Start-CLIOrchestrator.ps1" -ForegroundColor Gray

# Launch in new window
Start-Process powershell -ArgumentList @(
    "-NoExit",
    "-ExecutionPolicy", "Bypass", 
    "-File", ".\Start-CLIOrchestrator.ps1"
) -WindowStyle Normal

Write-Host ""
Write-Host "✅ Orchestrator restarted successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "The orchestrator is now running with the latest code changes:" -ForegroundColor Cyan
Write-Host "  • Continue prompt type handler added" -ForegroundColor Gray
Write-Host "  • Will process JSON files with prompt_type: 'Continue'" -ForegroundColor Gray
Write-Host "  • Will submit boilerplate prompts for continuation tasks" -ForegroundColor Gray
Write-Host ""
Write-Host "To test the Continue handler:" -ForegroundColor Yellow
Write-Host "  1. Delete the .processed marker for Test_Continue_Handler_2025_08_28.json" -ForegroundColor Gray
Write-Host "  2. Or create a new JSON with prompt_type: 'Continue'" -ForegroundColor Gray
Write-Host ""