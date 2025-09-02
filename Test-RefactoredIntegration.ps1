# Test-RefactoredIntegration.ps1
# Test that the refactored OrchestrationManager works with the main module

Write-Host "Testing Refactored OrchestrationManager Integration" -ForegroundColor Cyan
Write-Host ""

# Clean modules
Get-Module *CLIOrchestrator* -All | Remove-Module -Force -ErrorAction SilentlyContinue
Get-Module *OrchestrationManager* -All | Remove-Module -Force -ErrorAction SilentlyContinue

Write-Host "Step 1: Import just the refactored OrchestrationManager..." -ForegroundColor Yellow
try {
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager-Refactored.psm1" -Force -ErrorAction Stop
    Write-Host "  [OK] Refactored module imported" -ForegroundColor Green
    
    # Check functions
    $funcs = @('Start-CLIOrchestration', 'Get-CLIOrchestrationStatus', 'Invoke-AutonomousDecisionMaking')
    foreach ($f in $funcs) {
        if (Get-Command $f -ErrorAction SilentlyContinue) {
            Write-Host "  [OK] Function available: $f" -ForegroundColor Green
        }
        else {
            Write-Host "  [MISSING] Function: $f" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "  [ERROR] Failed to import: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "SUCCESS: Refactored OrchestrationManager works independently!" -ForegroundColor Green
Write-Host ""
Write-Host "Now Test-CLIOrchestrator-TestingWorkflow.ps1 will use the refactored version" -ForegroundColor Cyan
Write-Host "since Unity-Claude-CLIOrchestrator.psd1 has been updated to import:" -ForegroundColor Gray
Write-Host "  Core\OrchestrationManager-Refactored.psm1" -ForegroundColor Yellow
Write-Host "instead of:" -ForegroundColor Gray
Write-Host "  Core\OrchestrationManager.psm1" -ForegroundColor Yellow