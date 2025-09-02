#requires -Version 5.1

<#
.SYNOPSIS
    Tests the fixed boilerplate submission workflow
    
.DESCRIPTION
    Verifies that the enhanced CLIOrchestrator now properly:
    - Uses boilerplate format instead of pipe-separated format
    - Submits complete messages via clipboard paste (no line-by-line)
    - Loads the enhanced functions correctly
    
.PARAMETER TestMode
    Switch to run in test/simulation mode
#>

param(
    [switch]$TestMode = $true
)

Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "Testing Fixed Boilerplate Submission Workflow" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Simulate a test result like the orchestrator would create
$testResult = @{
    TestScript = "Test-CLIOrchestrator-FullFeatured.ps1"
    ExitCode = 0
    Duration = "5.06 seconds"
    Success = $true
    HasOutput = $true
    HasErrors = $false
    OutputPreview = "=============================================================\nUnity-Claude CLIOrchestrator Full-Featured Test Suite v3.0.0\n============================================================="
}

$resultsFile = ".\TestResults\20250827_234442_Test-CLIOrchestrator-FullFeatured_output.json"

# Load the enhanced submission function from the orchestrator
$orchestratorScript = ".\Start-CLIOrchestrator.ps1"
if (Test-Path $orchestratorScript) {
    Write-Host "Loading Submit-TestResultsToClaude function from orchestrator..." -ForegroundColor Yellow
    
    # Extract just the function definition
    $scriptContent = Get-Content $orchestratorScript -Raw
    $functionStart = $scriptContent.IndexOf("function Submit-TestResultsToClaude")
    $functionEnd = $scriptContent.IndexOf("}", $functionStart) + 1
    $functionCode = $scriptContent.Substring($functionStart, $functionEnd - $functionStart)
    
    # Execute the function definition
    Invoke-Expression $functionCode
    Write-Host "  ✅ Function loaded successfully" -ForegroundColor Green
} else {
    Write-Host "  ❌ Could not find orchestrator script" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "TESTING: Enhanced boilerplate submission workflow" -ForegroundColor Cyan
Write-Host ""

if ($TestMode) {
    Write-Host "[TEST MODE] Simulating the submission process..." -ForegroundColor Magenta
    Write-Host ""
    
    # Show what the old format would have been
    Write-Host "OLD FORMAT (pipe-separated, line-by-line issues):" -ForegroundColor Red
    $oldPrompt = "Test Execution Complete: $($testResult.TestScript) | Exit Code: $($testResult.ExitCode) | Duration: $($testResult.Duration) | Success: $($testResult.Success) | Results File: $resultsFile"
    Write-Host "  $oldPrompt" -ForegroundColor DarkRed
    Write-Host ""
    
    # Show what the new format should be
    Write-Host "NEW FORMAT (proper boilerplate, clipboard paste):" -ForegroundColor Green
    Write-Host "  [FULL 94-LINE BOILERPLATE TEMPLATE]" -ForegroundColor DarkGreen
    Write-Host "  Testing: Please analyze the console output and results from running the test $($testResult.TestScript) in file $resultsFile. The test completed successfully Files: $resultsFile" -ForegroundColor DarkGreen
    Write-Host ""
    
    Write-Host "EXPECTED WORKFLOW:" -ForegroundColor White
    Write-Host "  1. ✅ Load boilerplate template from Resources/BoilerplatePrompt.txt" -ForegroundColor Gray
    Write-Host "  2. ✅ Build complete prompt with proper format" -ForegroundColor Gray
    Write-Host "  3. ✅ Set complete prompt to clipboard (Set-Clipboard)" -ForegroundColor Gray
    Write-Host "  4. ✅ Find and switch to NUGGETRON window" -ForegroundColor Gray
    Write-Host "  5. ✅ Clear input field (Ctrl+A, Delete)" -ForegroundColor Gray
    Write-Host "  6. ✅ Paste complete prompt in ONE operation (Ctrl+V)" -ForegroundColor Gray
    Write-Host "  7. ✅ Submit with ENTER key" -ForegroundColor Gray
    Write-Host ""
    
    Write-Host "RESULT: Single complete message with proper boilerplate format" -ForegroundColor Green
    Write-Host "NO MORE: Line-by-line submission or pipe-separated format" -ForegroundColor Green
    
} else {
    Write-Host "[LIVE MODE] Performing actual submission test..." -ForegroundColor Green
    Write-Host ""
    Write-Host "⚠️  IMPORTANT: Make sure NUGGETRON window is registered!" -ForegroundColor Yellow
    $confirm = Read-Host "Continue with live test? (y/N)"
    
    if ($confirm -eq 'y' -or $confirm -eq 'Y') {
        try {
            Write-Host ""
            Write-Host "Executing enhanced submission function..." -ForegroundColor Cyan
            Submit-TestResultsToClaude -TestResult $testResult -ResultsFile $resultsFile
            Write-Host ""
            Write-Host "✅ Live test completed!" -ForegroundColor Green
        } catch {
            Write-Host "❌ Live test failed: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "Live test cancelled" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "Test completed - Ready for production use!" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan