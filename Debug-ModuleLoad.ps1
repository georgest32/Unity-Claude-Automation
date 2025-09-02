# Debug-ModuleLoad.ps1
# Debug why functions aren't being loaded

Write-Host "Debugging CLIOrchestrator Module Loading" -ForegroundColor Cyan
Write-Host ('=' * 50)

# Clean environment
Get-Module Unity-Claude-CLIOrchestrator* -All | Remove-Module -Force -ErrorAction SilentlyContinue

# Import with verbose to see what's happening
Write-Host "`nImporting module with verbose output..." -ForegroundColor Yellow
try {
    Import-Module 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1' -Force -Verbose 2>&1 | Tee-Object -Variable verboseOutput
} catch {
    Write-Host "Import failed: $_" -ForegroundColor Red
    exit 1
}

# Check module state
$module = Get-Module Unity-Claude-CLIOrchestrator
Write-Host "`nModule State:" -ForegroundColor Yellow
Write-Host "  Loaded: $($module -ne $null)"
Write-Host "  Version: $($module.Version)"
Write-Host "  RootModule: $($module.RootModule)"
Write-Host "  Path: $($module.Path)"
Write-Host "  ExportedFunctions: $($module.ExportedFunctions.Count)"

# Check if the fixed PSM1 file exists
$fixedPSM1Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Refactored-Fixed.psm1"
Write-Host "`nFixed PSM1 file check:" -ForegroundColor Yellow
Write-Host "  Path: $fixedPSM1Path"
Write-Host "  Exists: $(Test-Path $fixedPSM1Path)"

# Check for component files
Write-Host "`nChecking component files..." -ForegroundColor Yellow
$componentPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationComponents"
$decisionMakingPath = Join-Path $componentPath "DecisionMaking.psm1"
$decisionExecutionPath = Join-Path $componentPath "DecisionExecution.psm1"

Write-Host "  DecisionMaking.psm1: $(Test-Path $decisionMakingPath)"
Write-Host "  DecisionExecution.psm1: $(Test-Path $decisionExecutionPath)"

# Try to directly check if functions are defined in the global scope
Write-Host "`nChecking global function definitions..." -ForegroundColor Yellow
$functionsToCheck = @(
    'Invoke-AutonomousDecisionMaking',
    'Invoke-DecisionExecution',
    'Process-ResponseFile',
    'Submit-ToClaudeViaTypeKeys'
)

foreach ($func in $functionsToCheck) {
    $globalFunc = Get-Command $func -Scope Global -ErrorAction SilentlyContinue
    Write-Host "  $func (Global): $($globalFunc -ne $null)"
}

# Check if any warning/error messages in verbose output
Write-Host "`nLooking for errors in import process..." -ForegroundColor Yellow
$errors = $verboseOutput | Where-Object { $_ -match "error|fail|exception" }
if ($errors) {
    Write-Host "  Found potential issues:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
} else {
    Write-Host "  No obvious errors in verbose output" -ForegroundColor Green
}

# List all functions that ARE available
Write-Host "`nAll available CLIOrchestrator functions:" -ForegroundColor Yellow
Get-Command -Module Unity-Claude-CLIOrchestrator | Sort-Object Name | ForEach-Object {
    Write-Host "  - $($_.Name)" -ForegroundColor Gray
}