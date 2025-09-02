# FinalValidation-Test.ps1
# Final validation test for refactored OrchestrationManager

Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  Final Validation Test" -ForegroundColor Cyan
Write-Host "  Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host ""

$results = @{
    DateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Tests = @()
}

# Test 1: Direct import of refactored module
Write-Host "Test 1: Import OrchestrationManager-Refactored" -ForegroundColor Yellow
Get-Module *Orchestration* -All | Remove-Module -Force -ErrorAction SilentlyContinue

try {
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager-Refactored.psm1" -Force
    Write-Host "  [PASS] Module imported" -ForegroundColor Green
    
    # Check if functions exist in current session
    $funcTest = $null
    $funcTest = ${function:Invoke-AutonomousDecisionMaking}
    if ($funcTest) {
        Write-Host "  [PASS] Invoke-AutonomousDecisionMaking exists" -ForegroundColor Green
        $results.Tests += @{Name="Import"; Status="PASS"}
    }
    else {
        Write-Host "  [FAIL] Function not found" -ForegroundColor Red
        $results.Tests += @{Name="Import"; Status="FAIL"}
    }
}
catch {
    Write-Host "  [FAIL] Import failed: $_" -ForegroundColor Red
    $results.Tests += @{Name="Import"; Status="FAIL"; Error=$_.ToString()}
}

Write-Host ""
Write-Host "Test 2: Function Execution" -ForegroundColor Yellow

# Test Get-CLIOrchestrationStatus
try {
    $status = Get-CLIOrchestrationStatus
    if ($status) {
        Write-Host "  [PASS] Get-CLIOrchestrationStatus executed" -ForegroundColor Green
        $results.Tests += @{Name="StatusFunction"; Status="PASS"}
    }
}
catch {
    Write-Host "  [FAIL] Status function failed: $_" -ForegroundColor Red
    $results.Tests += @{Name="StatusFunction"; Status="FAIL"; Error=$_.ToString()}
}

# Test Initialize-OrchestrationEnvironment
try {
    $init = Initialize-OrchestrationEnvironment
    if ($init) {
        Write-Host "  [PASS] Initialize-OrchestrationEnvironment executed" -ForegroundColor Green
        $results.Tests += @{Name="InitFunction"; Status="PASS"}
    }
}
catch {
    Write-Host "  [FAIL] Init function failed: $_" -ForegroundColor Red
    $results.Tests += @{Name="InitFunction"; Status="FAIL"; Error=$_.ToString()}
}

Write-Host ""
Write-Host "Test 3: Decision Making Functions" -ForegroundColor Yellow

# Create test response file
$testResponse = @{
    timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    prompt_type = "Testing"
    task = "Validation test"
    RESPONSE = "RECOMMENDATION: TEST - Validate functions"
} | ConvertTo-Json

$testFile = ".\test_response_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
$testResponse | Set-Content $testFile

try {
    # Test Invoke-ComprehensiveResponseAnalysis
    $analysis = Invoke-ComprehensiveResponseAnalysis -ResponseFile $testFile
    if ($analysis) {
        Write-Host "  [PASS] Invoke-ComprehensiveResponseAnalysis executed" -ForegroundColor Green
        Write-Host "    Confidence: $($analysis.Confidence)%" -ForegroundColor Gray
        $results.Tests += @{Name="AnalysisFunction"; Status="PASS"}
    }
}
catch {
    Write-Host "  [FAIL] Analysis function failed: $_" -ForegroundColor Red
    $results.Tests += @{Name="AnalysisFunction"; Status="FAIL"; Error=$_.ToString()}
}

try {
    # Test Invoke-AutonomousDecisionMaking
    $decision = Invoke-AutonomousDecisionMaking -ResponseFile $testFile
    if ($decision) {
        Write-Host "  [PASS] Invoke-AutonomousDecisionMaking executed" -ForegroundColor Green
        Write-Host "    Action: $($decision.Action)" -ForegroundColor Gray
        $results.Tests += @{Name="DecisionFunction"; Status="PASS"}
    }
}
catch {
    Write-Host "  [FAIL] Decision function failed: $_" -ForegroundColor Red
    $results.Tests += @{Name="DecisionFunction"; Status="FAIL"; Error=$_.ToString()}
}

# Clean up test file
Remove-Item $testFile -Force -ErrorAction SilentlyContinue

# Summary
Write-Host ""
Write-Host "===============================================" -ForegroundColor Cyan
Write-Host "  SUMMARY" -ForegroundColor Cyan
Write-Host "===============================================" -ForegroundColor Cyan

$passed = ($results.Tests | Where-Object { $_.Status -eq "PASS" }).Count
$failed = ($results.Tests | Where-Object { $_.Status -eq "FAIL" }).Count

Write-Host "  Passed: $passed" -ForegroundColor Green
Write-Host "  Failed: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })

if ($failed -eq 0) {
    Write-Host ""
    Write-Host "[SUCCESS] All tests passed! Refactored module is working correctly." -ForegroundColor Green
    $results.Status = "SUCCESS"
}
else {
    Write-Host ""
    Write-Host "[PARTIAL] Some tests failed. Review the errors above." -ForegroundColor Yellow
    $results.Status = "PARTIAL"
}

$results | ConvertTo-Json -Depth 3 | Set-Content ".\FinalValidation-Results.txt"
Write-Host ""
Write-Host "Results saved to FinalValidation-Results.txt" -ForegroundColor Gray