# Quick Module Syntax Fix Verification Test
# Date: 2025-08-30
# Purpose: Verify that DocumentationQualityAssessment and DocumentationQualityOrchestrator modules load without errors

$testResults = @()
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Module Syntax Fix Verification Test" -ForegroundColor Cyan
Write-Host "Testing Date: $(Get-Date)" -ForegroundColor White
Write-Host "========================================" -ForegroundColor Cyan

# Test 1: DocumentationQualityAssessment Module
Write-Host "`nTest 1: Loading Unity-Claude-DocumentationQualityAssessment..." -ForegroundColor Yellow
try {
    Import-Module ".\Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1" -Force -ErrorAction Stop
    $testResults += @{
        Test = "DocumentationQualityAssessment Module Loading"
        Status = "PASS"
        Message = "Module loaded successfully"
    }
    Write-Host "  [PASS] DocumentationQualityAssessment module loaded" -ForegroundColor Green
}
catch {
    $testResults += @{
        Test = "DocumentationQualityAssessment Module Loading"
        Status = "FAIL"
        Message = $_.Exception.Message
    }
    Write-Host "  [FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: DocumentationQualityOrchestrator Module
Write-Host "`nTest 2: Loading Unity-Claude-DocumentationQualityOrchestrator..." -ForegroundColor Yellow
try {
    Import-Module ".\Modules\Unity-Claude-DocumentationQualityOrchestrator\Unity-Claude-DocumentationQualityOrchestrator.psm1" -Force -ErrorAction Stop
    $testResults += @{
        Test = "DocumentationQualityOrchestrator Module Loading"
        Status = "PASS"
        Message = "Module loaded successfully"
    }
    Write-Host "  [PASS] DocumentationQualityOrchestrator module loaded" -ForegroundColor Green
}
catch {
    $testResults += @{
        Test = "DocumentationQualityOrchestrator Module Loading"
        Status = "FAIL"
        Message = $_.Exception.Message
    }
    Write-Host "  [FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: DocumentationCrossReference Module
Write-Host "`nTest 3: Loading Unity-Claude-DocumentationCrossReference..." -ForegroundColor Yellow
try {
    Import-Module ".\Modules\Unity-Claude-DocumentationCrossReference\Unity-Claude-DocumentationCrossReference.psm1" -Force -ErrorAction Stop
    $testResults += @{
        Test = "DocumentationCrossReference Module Loading"
        Status = "PASS"
        Message = "Module loaded successfully"
    }
    Write-Host "  [PASS] DocumentationCrossReference module loaded" -ForegroundColor Green
}
catch {
    $testResults += @{
        Test = "DocumentationCrossReference Module Loading"
        Status = "FAIL"
        Message = $_.Exception.Message
    }
    Write-Host "  [FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Verify Cross-Reference Initialization
Write-Host "`nTest 4: Testing Cross-Reference System Initialization..." -ForegroundColor Yellow
try {
    $initResult = Initialize-DocumentationCrossReference -EnableRealTimeMonitoring -EnableAIEnhancement
    if ($initResult) {
        $testResults += @{
            Test = "CrossReference System Initialization"
            Status = "PASS"
            Message = "System initialized successfully"
        }
        Write-Host "  [PASS] CrossReference system initialized" -ForegroundColor Green
    }
    else {
        $testResults += @{
            Test = "CrossReference System Initialization"
            Status = "FAIL"
            Message = "Initialization returned false"
        }
        Write-Host "  [FAIL] Initialization failed" -ForegroundColor Red
    }
}
catch {
    $testResults += @{
        Test = "CrossReference System Initialization"
        Status = "FAIL"
        Message = $_.Exception.Message
    }
    Write-Host "  [FAIL] Error: $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$passCount = ($testResults | Where-Object { $_.Status -eq "PASS" }).Count
$failCount = ($testResults | Where-Object { $_.Status -eq "FAIL" }).Count
$totalCount = $testResults.Count

Write-Host "Total Tests: $totalCount" -ForegroundColor White
Write-Host "Passed: $passCount" -ForegroundColor Green
Write-Host "Failed: $failCount" -ForegroundColor $(if ($failCount -gt 0) { "Red" } else { "Green" })
Write-Host "Success Rate: $([Math]::Round(($passCount / $totalCount) * 100, 1))%" -ForegroundColor $(if ($passCount -eq $totalCount) { "Green" } else { "Yellow" })

# Save results
$resultsFile = ".\ModuleSyntaxFix-TestResults-$timestamp.txt"
$testResults | ForEach-Object {
    "[$($_.Status)] $($_.Test): $($_.Message)"
} | Out-File -FilePath $resultsFile

Write-Host "`nResults saved to: $resultsFile" -ForegroundColor Gray

# Return success/failure
if ($failCount -eq 0) {
    Write-Host "`n✅ All module syntax fixes verified successfully!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`n❌ Some modules still have issues. Please review the errors above." -ForegroundColor Red
    exit 1
}