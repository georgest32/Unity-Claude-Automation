# Test-FunctionDependencies.ps1
# Test if function dependencies are the issue

Write-Host "Testing Function Dependencies" -ForegroundColor Cyan
Write-Host ('=' * 40)

# Clear environment
Get-Module Unity-Claude-CLIOrchestrator* -All | Remove-Module -Force -ErrorAction SilentlyContinue

# Path to the module root
$moduleRoot = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator"

Write-Host "`nStep 1: Dot-sourcing DecisionMaking.psm1..." -ForegroundColor Yellow
$decisionMakingPath = Join-Path $moduleRoot "Core\OrchestrationComponents\DecisionMaking.psm1"

# Check if the function is defined in the file before dot-sourcing
Write-Host "Checking if Invoke-AutonomousDecisionMaking exists in file..." -ForegroundColor Gray
$content = Get-Content $decisionMakingPath -Raw
$hasFunction = $content -match "function\s+Invoke-AutonomousDecisionMaking"
Write-Host "  Function definition found in file: $hasFunction"

# Check for dependencies in the function
$dependsOnAnalysis = $content -match "Invoke-ComprehensiveResponseAnalysis"
Write-Host "  Function depends on Invoke-ComprehensiveResponseAnalysis: $dependsOnAnalysis"

# Try to dot-source
Write-Host "`nDot-sourcing DecisionMaking.psm1..." -ForegroundColor Yellow
try {
    . $decisionMakingPath
    Write-Host "  Dot-source successful" -ForegroundColor Green
} catch {
    Write-Host "  Dot-source failed: $_" -ForegroundColor Red
    exit 1
}

# Check if the function exists after dot-sourcing
Write-Host "`nChecking function availability after dot-sourcing..." -ForegroundColor Yellow
$cmd = Get-Command "Invoke-AutonomousDecisionMaking" -ErrorAction SilentlyContinue
Write-Host "  Invoke-AutonomousDecisionMaking available: $($cmd -ne $null)"

if ($cmd) {
    Write-Host "  Function type: $($cmd.GetType().Name)"
    Write-Host "  Module: $($cmd.ModuleName)"
    Write-Host "  Source: $($cmd.Source)"
} else {
    # Check if we can find it in the function drive
    Write-Host "  Checking function: drive..."
    $funcExists = Test-Path "function:\Invoke-AutonomousDecisionMaking"
    Write-Host "  Function in function: drive: $funcExists"
    
    # List all functions that start with Invoke-
    Write-Host "`n  All functions starting with 'Invoke-' in current scope:"
    Get-ChildItem function: | Where-Object Name -like "Invoke-*" | ForEach-Object {
        Write-Host "    - $($_.Name)" -ForegroundColor Gray
    }
}

# Check for the dependency function
Write-Host "`nChecking for dependency function..." -ForegroundColor Yellow
$depCmd = Get-Command "Invoke-ComprehensiveResponseAnalysis" -ErrorAction SilentlyContinue
Write-Host "  Invoke-ComprehensiveResponseAnalysis available: $($depCmd -ne $null)"

# Try a simple test to see if PowerShell can see the function definition
Write-Host "`nTesting function definition parsing..." -ForegroundColor Yellow
$functionScript = {
    function Test-SimpleFunction {
        Write-Host "Test function works!"
    }
}

& $functionScript
$testCmd = Get-Command "Test-SimpleFunction" -ErrorAction SilentlyContinue
Write-Host "  Test function available after scriptblock: $($testCmd -ne $null)"