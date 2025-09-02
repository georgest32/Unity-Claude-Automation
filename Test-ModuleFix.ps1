# Test-ModuleFix.ps1
# Tests if the CLIOrchestrator module fix is working

Write-Host 'Testing CLIOrchestrator Module Import and Function Availability' -ForegroundColor Cyan
Write-Host ('=' * 60)

# Clean environment
Write-Host "`nCleaning environment..." -ForegroundColor Yellow
Get-Module Unity-Claude-CLIOrchestrator* -All | Remove-Module -Force -ErrorAction SilentlyContinue

# Import the module
Write-Host "`nImporting Unity-Claude-CLIOrchestrator module..." -ForegroundColor Yellow
try {
    Import-Module 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1' -Force -ErrorAction Stop
    Write-Host 'Module import command succeeded' -ForegroundColor Green
} catch {
    Write-Host "Module import failed: $_" -ForegroundColor Red
    exit 1
}

# Check if module loaded
$module = Get-Module Unity-Claude-CLIOrchestrator
if ($module) {
    Write-Host 'Module loaded successfully!' -ForegroundColor Green
    Write-Host "  Version: $($module.Version)"
    Write-Host "  RootModule: $($module.RootModule)"
    Write-Host "  ExportedFunctions Count: $($module.ExportedFunctions.Count)"
} else {
    Write-Host 'Module not found in loaded modules!' -ForegroundColor Red
}

# Check for critical functions
Write-Host "`nChecking for critical functions:" -ForegroundColor Yellow
$functions = @(
    'Invoke-AutonomousDecisionMaking',
    'Invoke-DecisionExecution',
    'Process-ResponseFile',
    'Submit-ToClaudeViaTypeKeys',
    'Find-ClaudeWindow',
    'Initialize-CLIOrchestrator',
    'Test-CLIOrchestratorComponents'
)

$found = 0
$notFound = 0
foreach ($func in $functions) {
    $cmd = Get-Command $func -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "  [√] $func" -ForegroundColor Green
        $found++
    } else {
        Write-Host "  [X] $func - NOT FOUND" -ForegroundColor Red
        $notFound++
    }
}

Write-Host "`nSummary:" -ForegroundColor Cyan
Write-Host "  Functions Found: $found" -ForegroundColor Green
Write-Host "  Functions Missing: $notFound" -ForegroundColor $(if ($notFound -eq 0) { 'Green' } else { 'Red' })

if ($notFound -eq 0) {
    Write-Host "`n✓ SUCCESS: All critical functions are available!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n✗ FAILURE: Some functions are still missing!" -ForegroundColor Red
    
    # Debug: List all exported functions
    Write-Host "`nAll exported functions from module:" -ForegroundColor Yellow
    $module = Get-Module Unity-Claude-CLIOrchestrator
    if ($module) {
        $module.ExportedFunctions.Keys | Sort-Object | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Gray
        }
    }
    exit 1
}