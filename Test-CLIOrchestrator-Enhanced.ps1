# Test script for enhanced CLIOrchestrator functionality
# UTF-8 with BOM encoding for PowerShell 5.1 compatibility

Write-Host "=== Enhanced CLIOrchestrator Test ===" -ForegroundColor Cyan

# Clean import to test the fixed module
Get-Module Unity-Claude-CLIOrchestrator* | Remove-Module -Force -ErrorAction SilentlyContinue

Write-Host "Importing CLIOrchestrator module..." -ForegroundColor Yellow
try {
    Import-Module "./Modules/Unity-Claude-CLIOrchestrator/Unity-Claude-CLIOrchestrator.psd1" -Force -ErrorAction Stop
    Write-Host "✅ Module imported successfully" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to import module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test the missing function
Write-Host "`nTesting Analyze-ResponseSentiment function:" -ForegroundColor Yellow
$testResult = Get-Command Analyze-ResponseSentiment -ErrorAction SilentlyContinue
if ($testResult) { 
    Write-Host "  ✅ Analyze-ResponseSentiment: Available" -ForegroundColor Green
    
    # Test the function
    try {
        $sentiment = Analyze-ResponseSentiment -ResponseText "This test was successful and everything is working correctly"
        Write-Host "  ✅ Function execution: Success" -ForegroundColor Green
        Write-Host "  Classification: $($sentiment.Classification) ($($sentiment.Confidence)%)" -ForegroundColor Green
        Write-Host "  Positive Score: $($sentiment.PositiveScore)" -ForegroundColor DarkGreen
        Write-Host "  Negative Score: $($sentiment.NegativeScore)" -ForegroundColor DarkRed
    } catch {
        Write-Host "  ❌ Function execution failed: $($_.Exception.Message)" -ForegroundColor Red
    }
} else { 
    Write-Host "  ❌ Analyze-ResponseSentiment: Missing" -ForegroundColor Red 
}

# Test other core functions
Write-Host "`nTesting other core functions:" -ForegroundColor Yellow
$coreFunctions = @(
    'Extract-ResponseEntities',
    'Find-RecommendationPatterns', 
    'Invoke-RuleBasedDecision',
    'Test-SafetyValidation',
    'Submit-ToClaudeViaTypeKeys',
    'Start-CLIOrchestration'
)

$availableCount = 0
foreach ($func in $coreFunctions) {
    $cmd = Get-Command $func -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "  ✅ ${func}: Available" -ForegroundColor Green
        $availableCount++
    } else {
        Write-Host "  ❌ ${func}: Missing" -ForegroundColor Red
    }
}

Write-Host "`n=== Results ===" -ForegroundColor Cyan
Write-Host "Total functions exported: $((Get-Command -Module Unity-Claude-CLIOrchestrator).Count)" -ForegroundColor White
Write-Host "Core functions available: $availableCount/$($coreFunctions.Count)" -ForegroundColor White

if ($availableCount -eq $coreFunctions.Count -and $testResult) {
    Write-Host "✅ All tests passed - CLIOrchestrator is functional!" -ForegroundColor Green
    
    # Test a simple decision making scenario
    Write-Host "`nTesting decision making with Testing prompt-type:" -ForegroundColor Yellow
    
    # Create a test JSON response file
    $testResponseData = @{
        timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        prompt_type = "Testing"
        RESPONSE = "RECOMMENDATION: TEST - C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Test-CLIOrchestrator-Simple.ps1"
    }
    
    $testJsonFile = "./TestResponse_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $testResponseData | ConvertTo-Json -Depth 3 | Out-File $testJsonFile -Encoding UTF8
    
    Write-Host "  Created test response file: $testJsonFile" -ForegroundColor DarkGray
    
    try {
        $decisionResult = Invoke-AutonomousDecisionMaking -ResponseFile $testJsonFile
        Write-Host "  ✅ Decision making test successful" -ForegroundColor Green
        Write-Host "  Decision: $($decisionResult.Decision)" -ForegroundColor Cyan
        Write-Host "  Prompt Type: $($decisionResult.PromptType)" -ForegroundColor Cyan
        Write-Host "  Test Path: $($decisionResult.TestPath)" -ForegroundColor Cyan
        Write-Host "  Confidence: $($decisionResult.Confidence)%" -ForegroundColor Cyan
    } catch {
        Write-Host "  ❌ Decision making test failed: $($_.Exception.Message)" -ForegroundColor Red
    } finally {
        # Clean up test file
        Remove-Item $testJsonFile -Force -ErrorAction SilentlyContinue
    }
    
} else {
    Write-Host "❌ Some tests failed - CLIOrchestrator needs attention" -ForegroundColor Red
}

Write-Host "`nTest complete!" -ForegroundColor Cyan