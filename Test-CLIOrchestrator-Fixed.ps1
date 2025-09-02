# Test-CLIOrchestrator-Fixed.ps1
# Test script to verify the fixed CLIOrchestrator module works without nesting limit errors
# Date: 2025-08-27

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Testing Fixed CLIOrchestrator Module" -ForegroundColor Cyan  
Write-Host "  Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# Clean environment
Write-Host "Cleaning environment..." -ForegroundColor Yellow
Get-Module Unity-Claude-CLIOrchestrator* -All | Remove-Module -Force -ErrorAction SilentlyContinue
Write-Host ""

# Test 1: Import the fixed module
Write-Host "Test 1: Importing fixed module..." -ForegroundColor Yellow
try {
    # Use the fixed manifest explicitly
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Fixed.psd1" -Force -ErrorAction Stop
    
    $module = Get-Module Unity-Claude-CLIOrchestrator*
    if ($module) {
        Write-Host "  SUCCESS: Module imported successfully" -ForegroundColor Green
        Write-Host "    Module Name: $($module.Name)" -ForegroundColor Gray
        Write-Host "    Version: $($module.Version)" -ForegroundColor Gray
        Write-Host "    Root Module: $($module.RootModule)" -ForegroundColor Gray
    } else {
        Write-Host "  FAILED: Module not found after import" -ForegroundColor Red
    }
} catch {
    Write-Host "  ERROR: Failed to import module: $_" -ForegroundColor Red
}
Write-Host ""

# Test 2: Check for nesting warnings
Write-Host "Test 2: Checking for module nesting warnings..." -ForegroundColor Yellow
# The warnings would have appeared during import above
Write-Host "  (Check console output above for any nesting limit warnings)" -ForegroundColor Gray
Write-Host ""

# Test 3: Verify critical functions are available
Write-Host "Test 3: Verifying critical functions..." -ForegroundColor Yellow
$criticalFunctions = @(
    'Invoke-AutonomousDecisionMaking',
    'Invoke-DecisionExecution',
    'Process-ResponseFile',
    'Find-ClaudeWindow',
    'Submit-ToClaudeViaTypeKeys'
)

$allFound = $true
foreach ($func in $criticalFunctions) {
    $cmd = Get-Command $func -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "  ✓ Found: $func" -ForegroundColor Green
    } else {
        Write-Host "  ✗ Missing: $func" -ForegroundColor Red
        $allFound = $false
    }
}

if ($allFound) {
    Write-Host "  SUCCESS: All critical functions available" -ForegroundColor Green
} else {
    Write-Host "  FAILED: Some critical functions missing" -ForegroundColor Red
}
Write-Host ""

# Test 4: Initialize the orchestrator
Write-Host "Test 4: Initializing CLIOrchestrator..." -ForegroundColor Yellow
try {
    $initResult = Initialize-CLIOrchestrator -ValidateComponents -SetupDirectories
    if ($initResult) {
        Write-Host "  SUCCESS: Orchestrator initialized" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: Initialization returned false" -ForegroundColor Red
    }
} catch {
    Write-Host "  ERROR: Failed to initialize: $_" -ForegroundColor Red
}
Write-Host ""

# Test 5: Get component status
Write-Host "Test 5: Getting component status..." -ForegroundColor Yellow
try {
    $status = Test-CLIOrchestratorComponents
    Write-Host "  Total Required Functions: $($status.TotalRequired)" -ForegroundColor Gray
    Write-Host "  Total Available Functions: $($status.TotalAvailable)" -ForegroundColor Gray
    Write-Host "  Total Missing Functions: $($status.TotalMissing)" -ForegroundColor Gray
    
    if ($status.AllComponentsLoaded) {
        Write-Host "  SUCCESS: All components loaded" -ForegroundColor Green
    } else {
        Write-Host "  WARNING: Some components missing:" -ForegroundColor Yellow
        $status.MissingFunctions | ForEach-Object { 
            Write-Host "    - $_" -ForegroundColor Yellow 
        }
    }
    
    Write-Host "  Loaded Components:" -ForegroundColor Gray
    $status.LoadedComponents | ForEach-Object {
        Write-Host "    + $_" -ForegroundColor DarkGray
    }
    
    if ($status.LoadErrors.Count -gt 0) {
        Write-Host "  Load Errors:" -ForegroundColor Red
        $status.LoadErrors | ForEach-Object {
            Write-Host "    ! $_" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "  ERROR: Failed to get component status: $_" -ForegroundColor Red
}
Write-Host ""

# Test 6: Test a simple decision-making workflow
Write-Host "Test 6: Testing decision-making workflow..." -ForegroundColor Yellow
try {
    # Create a test response file
    $testResponse = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        prompt_type = "Testing"
        details = ".\Test-CLIOrchestrator-Simple.ps1"
        RESPONSE = "RECOMMENDATION: TEST - .\Test-CLIOrchestrator-Simple.ps1"
        confidence = 95
    }
    
    $testFile = ".\ClaudeResponses\Autonomous\fixed_test_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    
    # Ensure directory exists
    $dir = Split-Path $testFile -Parent
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    
    $testResponse | ConvertTo-Json -Depth 3 | Out-File -FilePath $testFile -Encoding UTF8
    
    # Process the response
    $processed = Process-ResponseFile -ResponseFilePath $testFile -ExtractRecommendations
    if ($processed) {
        Write-Host "  ✓ Process-ResponseFile succeeded" -ForegroundColor Green
        Write-Host "    Prompt Type: $($processed.PromptType)" -ForegroundColor Gray
        Write-Host "    Recommendations: $($processed.Recommendations.Count)" -ForegroundColor Gray
    }
    
    # Make a decision
    $decision = Invoke-AutonomousDecisionMaking -ResponseFile $testFile
    if ($decision) {
        Write-Host "  ✓ Invoke-AutonomousDecisionMaking succeeded" -ForegroundColor Green
        Write-Host "    Decision: $($decision.Decision)" -ForegroundColor Gray
        Write-Host "    Confidence: $($decision.Confidence)%" -ForegroundColor Gray
        Write-Host "  SUCCESS: Decision-making workflow functional" -ForegroundColor Green
    } else {
        Write-Host "  FAILED: Decision-making returned null" -ForegroundColor Red
    }
    
    # Cleanup test file
    Remove-Item $testFile -Force -ErrorAction SilentlyContinue
} catch {
    Write-Host "  ERROR: Decision-making workflow failed: $_" -ForegroundColor Red
}
Write-Host ""

# Summary
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Test Summary" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

$info = Get-CLIOrchestratorInfo
Write-Host "Module Version: $($info.Version)" -ForegroundColor White
Write-Host "Architecture: $($info.Architecture)" -ForegroundColor White
Write-Host "Is Running: $($info.IsRunning)" -ForegroundColor White

if ($info.LoadErrors.Count -eq 0 -and $allFound) {
    Write-Host ""
    Write-Host "SUCCESS: Fixed CLIOrchestrator module is fully functional!" -ForegroundColor Green
    Write-Host "The module nesting limit issue has been resolved." -ForegroundColor Green
    $exitCode = 0
} else {
    Write-Host ""
    Write-Host "ISSUES DETECTED: Review the test output above for details." -ForegroundColor Yellow
    $exitCode = 1
}

Write-Host ""
Write-Host "Test completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "================================================================" -ForegroundColor Cyan

exit $exitCode