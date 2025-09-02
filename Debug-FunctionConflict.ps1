# Debug-FunctionConflict.ps1
# Debug why Invoke-AutonomousDecisionMaking isn't available but similar functions are

Write-Host 'Debugging Function Conflict/Override Issues' -ForegroundColor Cyan
Write-Host ('=' * 50)

# Clear environment
Get-Module Unity-Claude-CLIOrchestrator* -All | Remove-Module -Force -ErrorAction SilentlyContinue

# Path to the module root
$moduleRoot = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator"
$decisionMakingPath = Join-Path $moduleRoot "Core\OrchestrationComponents\DecisionMaking.psm1"

Write-Host "Step 1: Checking available functions before dot-sourcing..." -ForegroundColor Yellow
$beforeCount = (Get-Command -CommandType Function | Measure-Object).Count
Write-Host "  Functions available before: $beforeCount"

Write-Host "`nStep 2: Dot-sourcing DecisionMaking.psm1 only..." -ForegroundColor Yellow
. $decisionMakingPath

Write-Host "`nStep 3: Checking available functions after dot-sourcing..." -ForegroundColor Yellow
$afterCount = (Get-Command -CommandType Function | Measure-Object).Count
Write-Host "  Functions available after: $afterCount"
Write-Host "  New functions added: $($afterCount - $beforeCount)"

# Look for functions that were added
$newFunctions = Get-Command -CommandType Function | Where-Object { $_.Source -eq "" }
Write-Host "`nNew functions added by dot-sourcing:"
$newFunctions | Sort-Object Name | ForEach-Object {
    Write-Host "  - $($_.Name)" -ForegroundColor Gray
}

# Check specifically for our target functions
Write-Host "`nChecking for target functions..." -ForegroundColor Yellow
$targetFunctions = @(
    'Invoke-AutonomousDecisionMaking',
    'Invoke-DecisionExecution',
    'Invoke-ComprehensiveResponseAnalysis'
)

foreach ($funcName in $targetFunctions) {
    $cmd = Get-Command $funcName -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "  [√] $funcName is available" -ForegroundColor Green
        Write-Host "    Source: $($cmd.Source)"
        Write-Host "    Module: $($cmd.ModuleName)"
    } else {
        Write-Host "  [X] $funcName is NOT available" -ForegroundColor Red
    }
}

# Check the function that IS available but similar
Write-Host "`nAnalyzing similar function that IS available..." -ForegroundColor Yellow
$similarCmd = Get-Command "Invoke-AutonomousDecision" -ErrorAction SilentlyContinue
if ($similarCmd) {
    Write-Host "  Invoke-AutonomousDecision:"
    Write-Host "    Source: $($similarCmd.Source)"  
    Write-Host "    Module: $($similarCmd.ModuleName)"
    Write-Host "    Definition preview:"
    $definition = $similarCmd.Definition
    if ($definition.Length -gt 200) {
        Write-Host "    $($definition.Substring(0, 200))..." -ForegroundColor Gray
    } else {
        Write-Host "    $definition" -ForegroundColor Gray
    }
}

# Search for any files that might define Invoke-AutonomousDecision to see if there's a conflict
Write-Host "`nSearching for potential conflicts..." -ForegroundColor Yellow
$searchResults = Get-ChildItem -Path $moduleRoot -Recurse -Filter "*.psm1" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw -ErrorAction SilentlyContinue
    if ($content -and $content -match "function\s+Invoke-AutonomousDecision\b") {
        return [PSCustomObject]@{
            File = $_.Name
            Path = $_.FullName
        }
    }
}

if ($searchResults) {
    Write-Host "  Files defining Invoke-AutonomousDecision (potential conflicts):"
    $searchResults | ForEach-Object {
        Write-Host "    - $($_.File): $($_.Path)" -ForegroundColor Yellow
    }
} else {
    Write-Host "  No other files found defining Invoke-AutonomousDecision"
}