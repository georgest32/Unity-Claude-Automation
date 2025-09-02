# Test-DirectDotSourced.ps1
# Manually test if dot-sourcing the component files works

Write-Host "Testing Direct Dot-Sourcing of Component Files" -ForegroundColor Cyan
Write-Host ('=' * 50)

# Path to the module root
$moduleRoot = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator"

# Test specific component files that should contain our functions
$componentFiles = @(
    'Core\OrchestrationComponents\DecisionMaking.psm1',
    'Core\OrchestrationComponents\DecisionExecution.psm1'
)

Write-Host "`nDot-sourcing component files..." -ForegroundColor Yellow
foreach ($componentFile in $componentFiles) {
    $fullPath = Join-Path $moduleRoot $componentFile
    $componentName = Split-Path $componentFile -Leaf
    
    Write-Host "  Testing: $componentName" -ForegroundColor Gray
    Write-Host "  Path: $fullPath"
    Write-Host "  Exists: $(Test-Path $fullPath)"
    
    if (Test-Path $fullPath) {
        try {
            Write-Host "  Dot-sourcing..." -ForegroundColor Yellow
            . $fullPath
            Write-Host "  [SUCCESS] Dot-sourced successfully" -ForegroundColor Green
            
            # Check if the expected functions are now available
            if ($componentName -eq "DecisionMaking.psm1") {
                $func = Get-Command "Invoke-AutonomousDecisionMaking" -ErrorAction SilentlyContinue
                Write-Host "  [CHECK] Invoke-AutonomousDecisionMaking available: $($func -ne $null)" -ForegroundColor $(if ($func) { 'Green' } else { 'Red' })
            }
            
            if ($componentName -eq "DecisionExecution.psm1") {
                $func = Get-Command "Invoke-DecisionExecution" -ErrorAction SilentlyContinue
                Write-Host "  [CHECK] Invoke-DecisionExecution available: $($func -ne $null)" -ForegroundColor $(if ($func) { 'Green' } else { 'Red' })
            }
            
        } catch {
            Write-Host "  [ERROR] Dot-sourcing failed: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "  [ERROR] File not found" -ForegroundColor Red
    }
    Write-Host ""
}

# Final check
Write-Host "`nFinal function availability check:" -ForegroundColor Cyan
$criticalFunctions = @(
    'Invoke-AutonomousDecisionMaking',
    'Invoke-DecisionExecution'
)

foreach ($func in $criticalFunctions) {
    $cmd = Get-Command $func -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "  [√] $func is available" -ForegroundColor Green
    } else {
        Write-Host "  [X] $func is NOT available" -ForegroundColor Red
    }
}