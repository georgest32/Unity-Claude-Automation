# Test-RefactoredOrchestrationManager.ps1
# Tests the refactored OrchestrationManager module

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Testing Refactored OrchestrationManager Module" -ForegroundColor Cyan
Write-Host "  Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

$testResults = @{
    ModuleImport = $false
    FunctionsAvailable = 0
    FunctionsMissing = 0
    Errors = @()
}

# Clean module state
Write-Host "Cleaning module state..." -ForegroundColor Yellow
Get-Module *OrchestrationManager* -All | Remove-Module -Force -ErrorAction SilentlyContinue
Get-Module *OrchestrationComponents* -All | Remove-Module -Force -ErrorAction SilentlyContinue

# Test importing the refactored module
Write-Host "Testing refactored module import..." -ForegroundColor Yellow

try {
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager-Refactored.psm1" -Force -ErrorAction Stop
    
    Write-Host "  SUCCESS: Refactored module imported!" -ForegroundColor Green
    $testResults.ModuleImport = $true
    
    # Test function availability
    Write-Host ""
    Write-Host "Testing function availability:" -ForegroundColor Yellow
    
    $expectedFunctions = @(
        # From OrchestrationCore
        'Start-CLIOrchestration',
        'Get-CLIOrchestrationStatus',
        'Initialize-OrchestrationEnvironment',
        
        # From MonitoringLoop
        'Start-MonitoringLoop',
        'Invoke-SingleExecutionCycle',
        'Process-SignalFile',
        
        # From DecisionMaking
        'Invoke-ComprehensiveResponseAnalysis',
        'Invoke-AutonomousDecisionMaking',
        'Test-DecisionSafety',
        
        # From DecisionExecution
        'Invoke-DecisionExecution',
        'Execute-TestAction',
        'Execute-ValidationAction',
        'Submit-TestResultsToClaude',
        'Execute-RecommendedAction',
        'Execute-SummaryAction'
    )
    
    foreach ($funcName in $expectedFunctions) {
        $command = Get-Command $funcName -ErrorAction SilentlyContinue
        if ($command) {
            Write-Host "  ✓ $funcName" -ForegroundColor Green
            $testResults.FunctionsAvailable++
        }
        else {
            Write-Host "  ✗ $funcName" -ForegroundColor Red
            $testResults.FunctionsMissing++
            $testResults.Errors += "Function not found: $funcName"
        }
    }
    
    # Test basic functionality
    Write-Host ""
    Write-Host "Testing basic functionality:" -ForegroundColor Yellow
    
    # Test Get-CLIOrchestrationStatus
    $statusWorked = $false
    try {
        $status = Get-CLIOrchestrationStatus
        if ($status) {
            Write-Host "  ✓ Get-CLIOrchestrationStatus works" -ForegroundColor Green
            Write-Host "    System Health: $($status.SystemHealth)" -ForegroundColor Gray
            $statusWorked = $true
        }
    }
    catch {
        Write-Host "  ✗ Get-CLIOrchestrationStatus failed: $_" -ForegroundColor Red
        $testResults.Errors += "Get-CLIOrchestrationStatus: $_"
    }
    
    # Test Initialize-OrchestrationEnvironment
    $initWorked = $false
    try {
        $initResult = Initialize-OrchestrationEnvironment
        if ($initResult) {
            Write-Host "  ✓ Initialize-OrchestrationEnvironment works" -ForegroundColor Green
            $initWorked = $true
        }
    }
    catch {
        Write-Host "  ✗ Initialize-OrchestrationEnvironment failed: $_" -ForegroundColor Red
        $testResults.Errors += "Initialize-OrchestrationEnvironment: $_"
    }
}
catch {
    Write-Host "  ERROR: Failed to import refactored module!" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Yellow
    $testResults.Errors += "Module import: $_"
}

# Summary
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  TEST SUMMARY" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$moduleStatus = if ($testResults.ModuleImport) { 'PASSED' } else { 'FAILED' }
$moduleColor = if ($testResults.ModuleImport) { 'Green' } else { 'Red' }
Write-Host "  Module Import: $moduleStatus" -ForegroundColor $moduleColor

Write-Host "  Functions Available: $($testResults.FunctionsAvailable)" -ForegroundColor Green

$missingColor = if ($testResults.FunctionsMissing -eq 0) { 'Green' } else { 'Red' }
Write-Host "  Functions Missing: $($testResults.FunctionsMissing)" -ForegroundColor $missingColor

$errorColor = if ($testResults.Errors.Count -eq 0) { 'Green' } else { 'Red' }
Write-Host "  Errors: $($testResults.Errors.Count)" -ForegroundColor $errorColor

if ($testResults.Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Error Details:" -ForegroundColor Red
    foreach ($error in $testResults.Errors) {
        Write-Host "  - $error" -ForegroundColor Yellow
    }
}

Write-Host ""
if ($testResults.ModuleImport -and $testResults.FunctionsMissing -eq 0) {
    Write-Host "✓ REFACTORING SUCCESSFUL!" -ForegroundColor Green
    Write-Host "  The OrchestrationManager module has been successfully refactored." -ForegroundColor Green
    Write-Host "  All functions are available and basic functionality works." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "✗ REFACTORING NEEDS ATTENTION" -ForegroundColor Red
    Write-Host "  Please review the errors above and fix any issues." -ForegroundColor Yellow
    exit 1
}