# Check-Manifest.ps1
# Check the manifest's FunctionsToExport

$manifestPath = 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1'
Write-Host "Checking manifest: $manifestPath" -ForegroundColor Cyan

# Import the manifest data
$manifest = Import-PowerShellDataFile $manifestPath

Write-Host "`nManifest Configuration:" -ForegroundColor Yellow
Write-Host "  RootModule: $($manifest.RootModule)"
Write-Host "  ModuleVersion: $($manifest.ModuleVersion)"
Write-Host "  NestedModules count: $($manifest.NestedModules.Count)"
Write-Host "  FunctionsToExport count: $($manifest.FunctionsToExport.Count)"

if ($manifest.FunctionsToExport.Count -gt 0) {
    Write-Host "`nFirst 10 functions in FunctionsToExport:" -ForegroundColor Yellow
    $manifest.FunctionsToExport[0..9] | ForEach-Object { 
        Write-Host "  - $_" -ForegroundColor Gray
    }
    
    Write-Host "`nLooking for critical functions:" -ForegroundColor Yellow
    $criticalFunctions = @(
        'Invoke-AutonomousDecisionMaking',
        'Invoke-DecisionExecution',
        'Process-ResponseFile',
        'Submit-ToClaudeViaTypeKeys',
        'Find-ClaudeWindow'
    )
    
    foreach ($func in $criticalFunctions) {
        if ($func -in $manifest.FunctionsToExport) {
            Write-Host "  [√] $func - Found in manifest" -ForegroundColor Green
        } else {
            Write-Host "  [X] $func - NOT in manifest" -ForegroundColor Red
        }
    }
    
    # Check for any that match pattern
    Write-Host "`nFunctions containing 'Invoke-Autonomous' or 'Invoke-Decision':" -ForegroundColor Yellow
    $manifest.FunctionsToExport | Where-Object { $_ -match 'Invoke-(Autonomous|Decision)' } | ForEach-Object { 
        Write-Host "  - $_" -ForegroundColor Gray
    }
} else {
    Write-Host "`nWARNING: No functions in FunctionsToExport!" -ForegroundColor Red
}

# Check if FunctionsToExport has a wildcard
if ('*' -in $manifest.FunctionsToExport) {
    Write-Host "`nNote: Manifest uses wildcard (*) for FunctionsToExport" -ForegroundColor Cyan
}