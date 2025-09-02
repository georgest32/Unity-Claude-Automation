# Compare-Modules.ps1
# Compare function availability between original and simplified versions

Write-Host 'Comparing CLIOrchestrator Module Versions' -ForegroundColor Cyan
Write-Host ('=' * 50)

# Check what functions were supposed to be exported originally
Write-Host "1. Checking original manifest functions..." -ForegroundColor Yellow
$manifestPath = 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1'
$manifest = Import-PowerShellDataFile $manifestPath

Write-Host "   Original manifest FunctionsToExport: $($manifest.FunctionsToExport.Count)"

# Load simplified module
Write-Host "`n2. Loading current simplified version..." -ForegroundColor Yellow
Get-Module Unity-Claude-CLIOrchestrator* -All | Remove-Module -Force -ErrorAction SilentlyContinue
Import-Module $manifestPath -Force -WarningAction SilentlyContinue

$module = Get-Module Unity-Claude-CLIOrchestrator
Write-Host "   Current simplified version exports: $($module.ExportedFunctions.Count)"

Write-Host "`n3. Functions in current simplified version:" -ForegroundColor Yellow
$currentFunctions = $module.ExportedFunctions.Keys | Sort-Object
$currentFunctions | ForEach-Object {
    Write-Host "   ✓ $_" -ForegroundColor Green
}

Write-Host "`n4. Functions that were in original manifest but missing from simplified:" -ForegroundColor Yellow
$missingFunctions = $manifest.FunctionsToExport | Where-Object { $_ -notin $currentFunctions }
if ($missingFunctions) {
    $missingFunctions | ForEach-Object {
        Write-Host "   ✗ $_" -ForegroundColor Red
    }
    Write-Host "`n   Total missing functions: $($missingFunctions.Count)" -ForegroundColor Red
} else {
    Write-Host "   No functions missing!" -ForegroundColor Green
}

Write-Host "`n5. Critical functions for testing workflow:" -ForegroundColor Yellow
$criticalFunctions = @(
    'Invoke-AutonomousDecisionMaking',
    'Invoke-DecisionExecution', 
    'Process-ResponseFile',
    'Submit-ToClaudeViaTypeKeys',
    'Find-ClaudeWindow'
)

$allCriticalAvailable = $true
foreach ($func in $criticalFunctions) {
    $available = $func -in $currentFunctions
    if ($available) {
        Write-Host "   ✓ $func" -ForegroundColor Green
    } else {
        Write-Host "   ✗ $func" -ForegroundColor Red
        $allCriticalAvailable = $false
    }
}

Write-Host "`n" + ("=" * 50)
Write-Host "SUMMARY:" -ForegroundColor Cyan
Write-Host "  Original functions expected: $($manifest.FunctionsToExport.Count)"
Write-Host "  Current functions available: $($currentFunctions.Count)"
Write-Host "  Missing functions: $($missingFunctions.Count)"
Write-Host "  Critical functions available: $(if($allCriticalAvailable){'YES ✓'}else{'NO ✗'})" -ForegroundColor $(if($allCriticalAvailable){'Green'}else{'Red'})

if ($missingFunctions.Count -gt 0) {
    Write-Host "`nNOTE: The simplified version prioritizes testing workflow functionality" -ForegroundColor Yellow
    Write-Host "      over complete feature coverage to resolve the module nesting issue." -ForegroundColor Yellow
}