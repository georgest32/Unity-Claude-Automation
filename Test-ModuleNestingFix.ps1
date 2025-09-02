# Test-ModuleNestingFix.ps1
# Verifies the module nesting limit fix works

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  Testing Module Nesting Limit Fix" -ForegroundColor Cyan
Write-Host "  Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

# Clean modules
Write-Host "Cleaning modules..." -ForegroundColor Yellow
Get-Module *CLIOrchestrator* -All | Remove-Module -Force -ErrorAction SilentlyContinue
Get-Module *OrchestrationManager* -All | Remove-Module -Force -ErrorAction SilentlyContinue

Write-Host "Testing direct import of OrchestrationManager-Refactored..." -ForegroundColor Yellow

try {
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager-Refactored.psm1" -Force -Verbose
    
    Write-Host "[SUCCESS] Module imported without nesting errors!" -ForegroundColor Green
    
    # Check critical functions
    Write-Host ""
    Write-Host "Checking functions from refactored components:" -ForegroundColor Yellow
    
    $functions = @{
        "OrchestrationCore" = @('Start-CLIOrchestration', 'Get-CLIOrchestrationStatus')
        "MonitoringLoop" = @('Start-MonitoringLoop', 'Process-SignalFile')
        "DecisionMaking" = @('Invoke-ComprehensiveResponseAnalysis', 'Invoke-AutonomousDecisionMaking')
        "DecisionExecution" = @('Invoke-DecisionExecution', 'Execute-TestAction')
    }
    
    $allFound = $true
    foreach ($component in $functions.Keys) {
        Write-Host "  From $component :" -ForegroundColor Cyan
        foreach ($func in $functions[$component]) {
            if (Get-Command $func -ErrorAction SilentlyContinue) {
                Write-Host "    [OK] $func" -ForegroundColor Green
            }
            else {
                Write-Host "    [MISSING] $func" -ForegroundColor Red
                $allFound = $false
            }
        }
    }
    
    Write-Host ""
    if ($allFound) {
        Write-Host "[SUCCESS] All refactored functions are available!" -ForegroundColor Green
        Write-Host "Module nesting limit fix is working correctly." -ForegroundColor Green
        
        # Save results
        $results = @{
            TestName = "ModuleNestingFix"
            DateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Status = "SUCCESS"
            ModuleLoaded = $true
            AllFunctionsAvailable = $true
            Message = "Dot-sourcing solution successfully avoids nesting limit"
        }
    }
    else {
        Write-Host "[WARNING] Some functions are missing" -ForegroundColor Yellow
        $results = @{
            TestName = "ModuleNestingFix"
            DateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Status = "PARTIAL"
            ModuleLoaded = $true
            AllFunctionsAvailable = $false
            Message = "Module loaded but some functions missing"
        }
    }
}
catch {
    Write-Host "[ERROR] Failed to import module: $_" -ForegroundColor Red
    $results = @{
        TestName = "ModuleNestingFix"
        DateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Status = "FAILED"
        Error = $_.ToString()
        Message = "Module import failed"
    }
}

$results | ConvertTo-Json | Set-Content ".\ModuleNestingFix-TestResults.txt"
Write-Host ""
Write-Host "Results saved to: ModuleNestingFix-TestResults.txt" -ForegroundColor Gray