# Test-DirectOrchestration.ps1
# Test loading OrchestrationManager-Refactored directly

Write-Host "Testing Direct OrchestrationManager-Refactored Import" -ForegroundColor Cyan
Write-Host ""

# Clean modules
Get-Module *Orchestration* -All | Remove-Module -Force -ErrorAction SilentlyContinue

Write-Host "Importing OrchestrationManager-Refactored directly..." -ForegroundColor Yellow
try {
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager-Refactored.psm1" -Force -Verbose
    
    Write-Host "[SUCCESS] Module imported!" -ForegroundColor Green
    Write-Host ""
    
    # Test functions
    Write-Host "Testing key functions:" -ForegroundColor Yellow
    
    $functions = @(
        'Start-CLIOrchestration',
        'Get-CLIOrchestrationStatus',
        'Invoke-ComprehensiveResponseAnalysis',
        'Invoke-AutonomousDecisionMaking',
        'Invoke-DecisionExecution'
    )
    
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
    if ($found -eq $functions.Count) {
        Write-Host "[SUCCESS] All key functions available!" -ForegroundColor Green
        
        # Test basic functionality
        Write-Host ""
        Write-Host "Testing Get-CLIOrchestrationStatus..." -ForegroundColor Yellow
        try {
            $status = Get-CLIOrchestrationStatus
            Write-Host "  [OK] Function executed successfully" -ForegroundColor Green
            Write-Host "  System Health: $($status.SystemHealth)" -ForegroundColor Gray
        }
        catch {
            Write-Host "  [ERROR] $_" -ForegroundColor Red
        }
    }
    else {
        Write-Host "[WARNING] Only $found of $($functions.Count) functions available" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "[ERROR] Failed to import: $_" -ForegroundColor Red
}

# Save results
$results = @{
    DateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    ModuleLoaded = $true
    FunctionsFound = $found
    TestPassed = ($found -eq $functions.Count)
}

$results | ConvertTo-Json | Set-Content ".\DirectOrchestration-Results.txt"
Write-Host ""
Write-Host "Results saved to DirectOrchestration-Results.txt" -ForegroundColor Gray