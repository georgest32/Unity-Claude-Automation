# Simple test for refactored OrchestrationManager

Write-Host "Testing Refactored OrchestrationManager Module" -ForegroundColor Cyan
Write-Host ""

# Clean and import
Get-Module *OrchestrationManager* -All | Remove-Module -Force -ErrorAction SilentlyContinue

$modulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager-Refactored.psm1"

Write-Host "Importing module..." -ForegroundColor Yellow
try {
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Host "SUCCESS: Module imported!" -ForegroundColor Green
    
    # Check functions
    $functions = @(
        'Start-CLIOrchestration',
        'Get-CLIOrchestrationStatus',
        'Initialize-OrchestrationEnvironment',
        'Invoke-ComprehensiveResponseAnalysis',
        'Invoke-AutonomousDecisionMaking'
    )
    
    Write-Host ""
    Write-Host "Checking key functions:" -ForegroundColor Yellow
    $found = 0
    foreach ($func in $functions) {
        if (Get-Command $func -ErrorAction SilentlyContinue) {
            Write-Host "  [OK] $func" -ForegroundColor Green
            $found++
        }
        else {
            Write-Host "  [MISSING] $func" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Host "Result: $found of $($functions.Count) functions available" -ForegroundColor Cyan
    
    if ($found -eq $functions.Count) {
        Write-Host ""
        Write-Host "[SUCCESS] REFACTORING SUCCESSFUL!" -ForegroundColor Green
        exit 0
    }
}
catch {
    Write-Host "ERROR: Failed to import module" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Yellow
    exit 1
}