# Test-FunctionAvailability.ps1
# Check which functions are actually available from CLIOrchestrator

Write-Host "Testing Function Availability from CLIOrchestrator" -ForegroundColor Cyan
Write-Host ""

# Clean and import
Get-Module *CLIOrchestrator* -All | Remove-Module -Force -ErrorAction SilentlyContinue

Write-Host "Importing Unity-Claude-CLIOrchestrator module..." -ForegroundColor Yellow
Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force

Write-Host ""
Write-Host "Checking specific orchestration functions:" -ForegroundColor Yellow

$orchestrationFunctions = @(
    'Start-CLIOrchestration',
    'Get-CLIOrchestrationStatus', 
    'Initialize-OrchestrationEnvironment',
    'Start-MonitoringLoop',
    'Invoke-SingleExecutionCycle',
    'Process-SignalFile',
    'Invoke-ComprehensiveResponseAnalysis',
    'Invoke-AutonomousDecisionMaking',
    'Test-DecisionSafety',
    'Invoke-DecisionExecution',
    'Execute-TestAction',
    'Execute-ValidationAction'
)

$available = @()
$missing = @()

foreach ($func in $orchestrationFunctions) {
    if (Get-Command $func -ErrorAction SilentlyContinue) {
        Write-Host "  [OK] $func" -ForegroundColor Green
        $available += $func
    }
    else {
        Write-Host "  [MISSING] $func" -ForegroundColor Red
        $missing += $func
    }
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Available: $($available.Count)" -ForegroundColor Green
Write-Host "  Missing: $($missing.Count)" -ForegroundColor Red

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "Missing functions:" -ForegroundColor Yellow
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

# Save results
$results = @{
    DateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Available = $available
    Missing = $missing
    TotalChecked = $orchestrationFunctions.Count
}

$results | ConvertTo-Json -Depth 2 | Set-Content ".\FunctionAvailability-Results.txt"
Write-Host ""
Write-Host "Results saved to FunctionAvailability-Results.txt" -ForegroundColor Gray