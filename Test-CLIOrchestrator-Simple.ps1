# Simple CLIOrchestrator Core Function Test
# Tests basic functionality without signature blocks
# Date: 2025-08-27

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Unity-Claude CLIOrchestrator Simple Test" -ForegroundColor Cyan  
Write-Host "  Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$testsPassed = 0
$testsFailed = 0

# Clean module state first
Get-Module Unity-Claude-CLIOrchestrator* -All | Remove-Module -Force -ErrorAction SilentlyContinue

try {
    # Import the main CLIOrchestrator module
    Write-Host "Importing Unity-Claude-CLIOrchestrator module..." -ForegroundColor Yellow
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force -ErrorAction Stop
    Write-Host "Module imported successfully" -ForegroundColor Green
    
    Write-Host ""
    Write-Host "Testing Core function availability:" -ForegroundColor Yellow
    
    # Define critical functions to test
    $criticalFunctions = @(
        "Extract-ResponseEntities",
        "Find-RecommendationPatterns", 
        "Invoke-RuleBasedDecision",
        "Test-SafeFilePath",
        "Test-SafetyValidation",
        "Invoke-PatternRecognitionAnalysis",
        "Calculate-OverallConfidence",
        "Test-SafeCommand",
        "Invoke-EnhancedResponseAnalysis"
    )
    
    $available = 0
    $missing = 0
    
    foreach ($funcName in $criticalFunctions) {
        $command = Get-Command $funcName -ErrorAction SilentlyContinue
        if ($command) {
            Write-Host "  $funcName : Available" -ForegroundColor Green
            $available++
        } else {
            Write-Host "  $funcName : Missing" -ForegroundColor Red  
            $missing++
        }
    }
    
    Write-Host ""
    Write-Host "Results Summary:" -ForegroundColor Cyan
    Write-Host "  Available: $available" -ForegroundColor Green
    Write-Host "  Missing: $missing" -ForegroundColor Red
    Write-Host "  Total functions tested: $($criticalFunctions.Count)" -ForegroundColor White
    
    # Show total exported functions from the module
    $totalExported = (Get-Command -Module Unity-Claude-CLIOrchestrator).Count
    Write-Host "  Total functions exported from CLIOrchestrator: $totalExported" -ForegroundColor White
    
    if ($missing -eq 0) {
        Write-Host ""
        Write-Host "SUCCESS: All Core functions are now available!" -ForegroundColor Green
        return $true
    } else {
        Write-Host ""
        Write-Host "ISSUE: $missing Core functions are still missing" -ForegroundColor Red
        return $false
    }
    
} catch {
    Write-Host "ERROR: Failed to import CLIOrchestrator module" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
    return $false
}