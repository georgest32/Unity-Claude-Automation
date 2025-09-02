# Test CLIOrchestrator End-to-End Testing Prompt-Type Workflow
# Validates that Unicode character fixes have restored full functionality
# Date: 2025-08-27

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Testing CLIOrchestrator End-to-End Workflow Validation" -ForegroundColor Cyan
Write-Host "  Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$testsPassed = 0
$testsFailed = 0

# Clean module state to prevent nesting issues
Write-Host "Cleaning module state to prevent nesting issues..." -ForegroundColor Yellow
Get-Module Unity-Claude-CLIOrchestrator* -All | Remove-Module -Force -ErrorAction SilentlyContinue

# Import CLIOrchestrator module
Write-Host "1. Importing CLIOrchestrator module..." -ForegroundColor Yellow
try {
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force -ErrorAction Stop
    Write-Host "   SUCCESS: CLIOrchestrator module imported" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "   ERROR: Failed to import CLIOrchestrator module" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Yellow
    $testsFailed++
    return $false
}

# Read the test JSON file
Write-Host ""
Write-Host "2. Reading test JSON file..." -ForegroundColor Yellow
$jsonFile = ".\ClaudeResponses\Autonomous\Test_CLIOrchestrator_FixValidation_2025_08_27.json"
try {
    if (-not (Test-Path $jsonFile)) {
        throw "JSON file not found: $jsonFile"
    }
    
    $jsonContent = Get-Content $jsonFile -Raw -ErrorAction Stop
    $jsonData = $jsonContent | ConvertFrom-Json -ErrorAction Stop
    Write-Host "   SUCCESS: JSON file parsed" -ForegroundColor Green
    Write-Host "   Prompt Type: $($jsonData.prompt_type)" -ForegroundColor Gray
    Write-Host "   Response Length: $($jsonData.RESPONSE.Length)" -ForegroundColor Gray
    $testsPassed++
} catch {
    Write-Host "   ERROR: Failed to read/parse JSON file" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Yellow
    $testsFailed++
    return $false
}

# Test pattern recognition
Write-Host ""
Write-Host "3. Testing pattern recognition..." -ForegroundColor Yellow
try {
    $patterns = Find-RecommendationPatterns -ResponseText $jsonData.RESPONSE
    if ($patterns -and $patterns.Count -gt 0) {
        Write-Host "   SUCCESS: Pattern recognition found $($patterns.Count) patterns" -ForegroundColor Green
        $firstPattern = $patterns[0]
        Write-Host "   Pattern Type: $($firstPattern.Type)" -ForegroundColor Gray
        Write-Host "   Action: $($firstPattern.Action)" -ForegroundColor Gray
        Write-Host "   Confidence: $($firstPattern.Confidence)" -ForegroundColor Gray
        Write-Host "   Priority: $($firstPattern.Priority)" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "   WARNING: No patterns found" -ForegroundColor Yellow
        Write-Host "   Response text was: $($jsonData.RESPONSE)" -ForegroundColor Gray
        $testsFailed++
    }
} catch {
    Write-Host "   ERROR: Pattern recognition failed" -ForegroundColor Red
    Write-Host "   $($_.Exception.Message)" -ForegroundColor Yellow
    $testsFailed++
}

# Test decision making (if patterns were found)
if ($patterns -and $patterns.Count -gt 0) {
    Write-Host ""
    Write-Host "4. Testing decision making..." -ForegroundColor Yellow
    try {
        $analysisResult = @{
            Recommendations = $patterns
            ConfidenceAnalysis = @{
                OverallConfidence = 0.9
                QualityRating = "High"
            }
            Entities = @{ 
                FilePaths = @($firstPattern.Action)
                PowerShellCommands = @()
            }
            ProcessingSuccess = $true
            TotalProcessingTimeMs = 100
        }
        
        $decision = Invoke-RuleBasedDecision -AnalysisResult $analysisResult -DryRun
        if ($decision -and $decision.Decision) {
            Write-Host "   SUCCESS: Decision made" -ForegroundColor Green
            Write-Host "   Decision: $($decision.Decision)" -ForegroundColor Gray
            Write-Host "   Reasoning: $($decision.Reasoning)" -ForegroundColor Gray
            $testsPassed++
        } else {
            Write-Host "   ERROR: No decision returned" -ForegroundColor Red
            $testsFailed++
        }
    } catch {
        Write-Host "   ERROR: Decision making failed" -ForegroundColor Red
        Write-Host "   $($_.Exception.Message)" -ForegroundColor Yellow
        $testsFailed++
    }
}

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  End-to-End Workflow Test Complete" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Test Results:" -ForegroundColor Cyan
Write-Host "  Tests Passed: $testsPassed" -ForegroundColor Green
Write-Host "  Tests Failed: $testsFailed" -ForegroundColor Red
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "SUCCESS: All end-to-end workflow tests passed!" -ForegroundColor Green
    Write-Host "Testing prompt-type functionality is working correctly after Unicode fixes" -ForegroundColor Green
    return $true
} else {
    Write-Host "PARTIAL SUCCESS: $testsPassed tests passed, $testsFailed tests failed" -ForegroundColor Yellow
    return $false
}