# Test-DotSourcing.ps1
# Test dot-sourcing components directly

Write-Host "Testing Dot-Sourcing of Components" -ForegroundColor Cyan
Write-Host ""

# Clean environment
Get-Module *Orchestration* -All | Remove-Module -Force -ErrorAction SilentlyContinue

$componentPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents"

Write-Host "Dot-sourcing OrchestrationCore.psm1..." -ForegroundColor Yellow
try {
    . "$componentPath\OrchestrationCore.psm1"
    Write-Host "  [OK] Dot-sourced successfully" -ForegroundColor Green
    
    # Check if functions are available
    if (Get-Command Start-CLIOrchestration -ErrorAction SilentlyContinue) {
        Write-Host "  [OK] Start-CLIOrchestration is available" -ForegroundColor Green
    }
    else {
        Write-Host "  [MISSING] Start-CLIOrchestration not found" -ForegroundColor Red
    }
}
catch {
    Write-Host "  [ERROR] $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Dot-sourcing DecisionMaking.psm1..." -ForegroundColor Yellow
try {
    . "$componentPath\DecisionMaking.psm1"
    Write-Host "  [OK] Dot-sourced successfully" -ForegroundColor Green
    
    # Check if functions are available
    if (Get-Command Invoke-AutonomousDecisionMaking -ErrorAction SilentlyContinue) {
        Write-Host "  [OK] Invoke-AutonomousDecisionMaking is available" -ForegroundColor Green
    }
    else {
        Write-Host "  [MISSING] Invoke-AutonomousDecisionMaking not found" -ForegroundColor Red
    }
}
catch {
    Write-Host "  [ERROR] $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "All available functions:" -ForegroundColor Yellow
Get-Command -CommandType Function | Where-Object { 
    $_.Name -like "*CLI*" -or 
    $_.Name -like "*Orchestration*" -or 
    $_.Name -like "*Decision*" -or
    $_.Name -like "*Monitoring*"
} | Select-Object -ExpandProperty Name | ForEach-Object {
    Write-Host "  - $_" -ForegroundColor Gray
}