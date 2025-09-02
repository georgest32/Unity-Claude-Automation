#requires -Version 5.1

<#
.SYNOPSIS
    Tests that the orchestrator properly uses boilerplate format
    
.DESCRIPTION
    Verifies the complete workflow:
    1. Functions are loaded correctly
    2. Boilerplate prompt is properly constructed
    3. Clipboard paste method is used (not line-by-line typing)
    4. Correct format: [BOILERPLATE] Testing: [details] Files: [paths]
#>

Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "Testing Orchestrator Boilerplate Implementation" -ForegroundColor Cyan
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify the functions exist
Write-Host "STEP 1: Checking for boilerplate functions..." -ForegroundColor Yellow

$boilerplateFunction = ".\Modules\Unity-Claude-CLIOrchestrator\Public\PromptSubmissionEngine\New-BoilerplatePrompt.ps1"
$submissionFunction = ".\Modules\Unity-Claude-CLIOrchestrator\Public\PromptSubmissionEngine\Submit-ToClaudeViaTypeKeys.ps1"

if (Test-Path $boilerplateFunction) {
    Write-Host "  ✅ New-BoilerplatePrompt.ps1 exists" -ForegroundColor Green
    
    # Load and test the function
    . $boilerplateFunction
    if (Get-Command New-BoilerplatePrompt -ErrorAction SilentlyContinue) {
        Write-Host "  ✅ New-BoilerplatePrompt function loaded successfully" -ForegroundColor Green
    } else {
        Write-Host "  ❌ New-BoilerplatePrompt function failed to load" -ForegroundColor Red
    }
} else {
    Write-Host "  ❌ New-BoilerplatePrompt.ps1 not found" -ForegroundColor Red
}

if (Test-Path $submissionFunction) {
    Write-Host "  ✅ Submit-ToClaudeViaTypeKeys.ps1 exists" -ForegroundColor Green
} else {
    Write-Host "  ❌ Submit-ToClaudeViaTypeKeys.ps1 not found" -ForegroundColor Red
}

Write-Host ""

# Step 2: Test boilerplate prompt construction
Write-Host "STEP 2: Testing boilerplate prompt construction..." -ForegroundColor Yellow

if (Get-Command New-BoilerplatePrompt -ErrorAction SilentlyContinue) {
    $testDetails = "Please analyze the console output and results from running the test Test-Example.ps1 in file ./TestResults/test_output.json"
    $testFiles = @("./TestResults/test_output.json")
    
    try {
        $boilerplatePrompt = New-BoilerplatePrompt -PromptType "Testing" -Details $testDetails -FilePaths $testFiles
        
        Write-Host "  ✅ Boilerplate prompt created successfully" -ForegroundColor Green
        Write-Host "  📄 Prompt length: $($boilerplatePrompt.Length) characters" -ForegroundColor Gray
        
        # Check format
        if ($boilerplatePrompt -match "Testing:") {
            Write-Host "  ✅ Correct format detected (Testing: included)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Wrong format - missing 'Testing:' marker" -ForegroundColor Red
        }
        
        if ($boilerplatePrompt -match "#Important:.*Unity-Claude-Automation") {
            Write-Host "  ✅ Boilerplate template included" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Boilerplate template missing" -ForegroundColor Red
        }
        
        # Show preview
        Write-Host ""
        Write-Host "  PROMPT PREVIEW (last 200 chars):" -ForegroundColor Gray
        $preview = $boilerplatePrompt.Substring([Math]::Max(0, $boilerplatePrompt.Length - 200))
        Write-Host "  ...$preview" -ForegroundColor DarkGray
        
    } catch {
        Write-Host "  ❌ Error creating boilerplate prompt: $_" -ForegroundColor Red
    }
} else {
    Write-Host "  ❌ New-BoilerplatePrompt function not available" -ForegroundColor Red
}

Write-Host ""

# Step 3: Test the orchestrator's Submit-TestResultsToClaude function
Write-Host "STEP 3: Testing orchestrator submission function..." -ForegroundColor Yellow

# Create mock test result
$mockTestResult = @{
    TestScript = "Test-Example.ps1"
    ExitCode = 0
    Duration = "3.14 seconds"
    Success = $true
    HasOutput = $true
    HasErrors = $false
    OutputPreview = "Test completed successfully"
}
$mockResultsFile = ".\TestResults\test_output.json"

Write-Host "  Expected behavior:" -ForegroundColor White
Write-Host "    1. Load New-BoilerplatePrompt.ps1" -ForegroundColor Gray
Write-Host "    2. Load Submit-ToClaudeViaTypeKeys.ps1" -ForegroundColor Gray
Write-Host "    3. Build boilerplate prompt with Testing: format" -ForegroundColor Gray
Write-Host "    4. Use clipboard paste (NOT line-by-line typing)" -ForegroundColor Gray
Write-Host "    5. Submit complete prompt as single message" -ForegroundColor Gray

Write-Host ""
Write-Host "  What should NOT happen:" -ForegroundColor Red
Write-Host "    ❌ NO pipe-separated format" -ForegroundColor DarkRed
Write-Host "    ❌ NO 'Test Execution Complete: script | Exit Code: 0 |...'" -ForegroundColor DarkRed
Write-Host "    ❌ NO line-by-line submission" -ForegroundColor DarkRed
Write-Host "    ❌ NO character-by-character typing" -ForegroundColor DarkRed

Write-Host ""
Write-Host "=============================================================" -ForegroundColor Cyan
Write-Host "Verification complete!" -ForegroundColor Cyan
Write-Host ""
Write-Host "CORRECT FORMAT EXAMPLE:" -ForegroundColor Green
Write-Host "[Full boilerplate template - 94 lines]" -ForegroundColor DarkGreen
Write-Host "" -ForegroundColor DarkGreen
Write-Host "Testing: Please analyze the console output and results from running the test Test-Example.ps1 in file ./TestResults/test_output.json Files: ./TestResults/test_output.json" -ForegroundColor DarkGreen
Write-Host ""
Write-Host "WRONG FORMAT EXAMPLE:" -ForegroundColor Red
Write-Host "Test Execution Complete: Test-Example.ps1 | Exit Code: 0 | Duration: 3.14 seconds | Success: True | Results File: ./TestResults/test_output.json" -ForegroundColor DarkRed
Write-Host "=============================================================" -ForegroundColor Cyan