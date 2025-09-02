# Test CLIOrchestrator Core Function Loading with Debug Logging
# Created: 2025-08-27

Write-Host "=== CLIOrchestrator Core Function Test with Debug Logging ===" -ForegroundColor Cyan
Write-Host "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')" -ForegroundColor Gray
Write-Host ""

# Clean slate with debug
Write-Host "[DEBUG] Step 1: Cleaning existing modules..." -ForegroundColor Magenta
$existingModules = Get-Module Unity-Claude-CLIOrchestrator* -All
$existingModules | ForEach-Object {
    Write-Host "[DEBUG] Removing module: $($_.Name)" -ForegroundColor Gray
    Remove-Module $_ -Force -ErrorAction SilentlyContinue
}

Get-Module ResponseAnalysisEngine* -All | ForEach-Object {
    Write-Host "[DEBUG] Removing ResponseAnalysisEngine module: $($_.Name)" -ForegroundColor Gray  
    Remove-Module $_ -Force -ErrorAction SilentlyContinue
}

Write-Host "[DEBUG] Modules cleaned" -ForegroundColor Magenta
Write-Host ""

# Test CLIOrchestrator main module import with debug
Write-Host "[DEBUG] Step 2: Testing CLIOrchestrator main module import..." -ForegroundColor Magenta
$modulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1"
Write-Host "[DEBUG] Module path: $modulePath" -ForegroundColor Gray

try {
    Import-Module $modulePath -Force -ErrorAction Stop -Global
    Write-Host "[SUCCESS] CLIOrchestrator module imported successfully!" -ForegroundColor Green
    
    # Get all imported functions for debugging
    $allFunctions = Get-Command -Module Unity-Claude-CLIOrchestrator -ErrorAction SilentlyContinue
    Write-Host "[DEBUG] Total functions imported: $($allFunctions.Count)" -ForegroundColor Gray
    
    if ($allFunctions.Count -gt 0) {
        Write-Host "[DEBUG] First 5 functions:" -ForegroundColor Gray
        $allFunctions | Select-Object -First 5 | ForEach-Object {
            Write-Host "[DEBUG]   - $($_.Name)" -ForegroundColor Gray
        }
    }
    
} catch {
    Write-Host "[ERROR] Failed to import CLIOrchestrator module" -ForegroundColor Red
    Write-Host "[ERROR] Exception Type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    Write-Host "[ERROR] Message: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[ERROR] Position: $($_.InvocationInfo.PositionMessage)" -ForegroundColor Red
    Write-Host "[ERROR] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Test the 9 Core functions with detailed debug
Write-Host "[DEBUG] Step 3: Testing Core functions availability..." -ForegroundColor Magenta
$coreFunctions = @(
    'Extract-ResponseEntities',
    'Find-RecommendationPatterns', 
    'Invoke-RuleBasedDecision',
    'Test-SafetyValidation',
    'Get-CLIWindowHandle',
    'Submit-ToClaudeViaTypeKeys',
    'Start-CLIOrchestration',
    'Get-CLIOrchestrationStatus',
    'Invoke-PatternRecognitionAnalysis'
)

$availableCount = 0
$missingFunctions = @()

foreach ($functionName in $coreFunctions) {
    Write-Host "[DEBUG] Testing function: $functionName" -ForegroundColor Gray
    $cmd = Get-Command $functionName -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "[SUCCESS] ✓ $functionName - Available (Source: $($cmd.Source))" -ForegroundColor Green
        $availableCount++
    } else {
        Write-Host "[MISSING] ✗ $functionName - NOT FOUND" -ForegroundColor Red
        $missingFunctions += $functionName
    }
}

Write-Host ""
Write-Host "[RESULTS] Core Functions Status:" -ForegroundColor Cyan
$color = if ($availableCount -eq 9) { 'Green' } else { 'Yellow' }
Write-Host "[RESULTS] Available: $availableCount/9" -ForegroundColor $color

if ($missingFunctions.Count -gt 0) {
    Write-Host "[RESULTS] Missing functions:" -ForegroundColor Red
    $missingFunctions | ForEach-Object { Write-Host "[RESULTS]   - $_" -ForegroundColor Red }
    
    # Additional debugging for missing functions
    Write-Host ""
    Write-Host "[DEBUG] Checking if missing functions exist in Core modules..." -ForegroundColor Magenta
    
    # Check specific Core modules
    $coreModules = @(
        "ResponseAnalysisEngine",
        "PatternRecognitionEngine", 
        "DecisionEngine",
        "ActionExecutionEngine"
    )
    
    foreach ($coreModule in $coreModules) {
        Write-Host "[DEBUG] Checking module: $coreModule" -ForegroundColor Gray
        $module = Get-Module $coreModule -ErrorAction SilentlyContinue
        if ($module) {
            $moduleFunctions = Get-Command -Module $coreModule -ErrorAction SilentlyContinue
            Write-Host "[DEBUG]   Module loaded with $($moduleFunctions.Count) functions" -ForegroundColor Gray
        } else {
            Write-Host "[DEBUG]   Module not loaded" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "[DEBUG] Test completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')" -ForegroundColor Gray