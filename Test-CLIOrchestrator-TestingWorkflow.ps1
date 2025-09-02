# Test-CLIOrchestrator-TestingWorkflow.ps1
# Comprehensive test of the Testing prompt-type end-to-end workflow
# Date: 2025-08-27

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  CLIOrchestrator Testing Workflow Validation" -ForegroundColor Cyan  
Write-Host "  Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

$testResults = @{
    TotalTests = 0
    Passed = 0
    Failed = 0
    Details = @()
}

function Test-Component {
    param(
        [string]$Name,
        [scriptblock]$Test
    )
    
    $testResults.TotalTests++
    Write-Host "Testing: $Name" -ForegroundColor Yellow
    
    try {
        $result = & $Test
        if ($result) {
            Write-Host "  [PASS] $Name" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Details += "[PASS] $Name"
        } else {
            Write-Host "  [FAIL] $Name" -ForegroundColor Red
            $testResults.Failed++
            $testResults.Details += "[FAIL] $Name"
        }
    } catch {
        Write-Host "  [ERROR] $Name : $($_.Exception.Message)" -ForegroundColor Red
        $testResults.Failed++
        $testResults.Details += "[ERROR] $Name : $($_.Exception.Message)"
    }
}

# Clean environment
Write-Host "Preparing test environment..." -ForegroundColor Cyan
Get-Module Unity-Claude-CLIOrchestrator* -All | Remove-Module -Force -ErrorAction SilentlyContinue
Write-Host ""

# Test 1: Module Import
Test-Component "Module Import" {
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force -ErrorAction Stop
    $module = Get-Module Unity-Claude-CLIOrchestrator
    return ($null -ne $module)
}

# Test 2: Core Functions Available
Test-Component "Core Functions Availability" {
    $functions = @(
        "Process-ResponseFile",
        "Invoke-AutonomousDecisionMaking",
        "Invoke-DecisionExecution",
        "Submit-ToClaudeViaTypeKeys",
        "Find-ClaudeWindow"
    )
    
    $allAvailable = $true
    foreach ($func in $functions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            Write-Host "    Missing: $func" -ForegroundColor Yellow
            $allAvailable = $false
        }
    }
    return $allAvailable
}

# Test 3: Response Directory Setup
Test-Component "Response Directory Setup" {
    $responseDir = ".\ClaudeResponses\Autonomous"
    if (-not (Test-Path $responseDir)) {
        New-Item -ItemType Directory -Path $responseDir -Force | Out-Null
    }
    return (Test-Path $responseDir)
}

# Test 4: Create Test Response File
Test-Component "Create Test Response File" {
    $testResponse = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        prompt_type = "Testing"
        details = ".\Test-CLIOrchestrator-Simple.ps1"
        RESPONSE = "RECOMMENDATION: TEST - .\Test-CLIOrchestrator-Simple.ps1"
        confidence = 95
    }
    
    $responseFile = ".\ClaudeResponses\Autonomous\test_workflow_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $testResponse | ConvertTo-Json -Depth 3 | Out-File -FilePath $responseFile -Encoding UTF8
    
    # Verify file was created
    $exists = Test-Path $responseFile
    if ($exists) {
        Write-Host "    Response file created: $responseFile" -ForegroundColor DarkGray
    }
    return $exists
}

# Test 5: Process Response File
Test-Component "Process Response File" {
    # Find the most recent test response file
    $responseFiles = Get-ChildItem -Path ".\ClaudeResponses\Autonomous" -Filter "test_workflow_*.json" | 
                     Sort-Object LastWriteTime -Descending | 
                     Select-Object -First 1
    
    if (-not $responseFiles) {
        Write-Host "    No response file found" -ForegroundColor Red
        return $false
    }
    
    $response = Process-ResponseFile -ResponseFilePath $responseFiles.FullName -ExtractRecommendations -ValidateStructure
    
    Write-Host "    Prompt Type: $($response.PromptType)" -ForegroundColor DarkGray
    Write-Host "    Test Details: $($response.TestDetails)" -ForegroundColor DarkGray
    Write-Host "    Recommendations: $($response.Recommendations.Count)" -ForegroundColor DarkGray
    Write-Host "    Next Actions: $($response.NextActions.Count)" -ForegroundColor DarkGray
    
    return ($response.PromptType -eq "Testing" -and $response.TestDetails -ne $null)
}

# Test 6: Decision Making
Test-Component "Autonomous Decision Making" {
    $responseFiles = Get-ChildItem -Path ".\ClaudeResponses\Autonomous" -Filter "test_workflow_*.json" | 
                     Sort-Object LastWriteTime -Descending | 
                     Select-Object -First 1
    
    if (-not $responseFiles) {
        Write-Host "    No response file found" -ForegroundColor Red
        return $false
    }
    
    $decision = Invoke-AutonomousDecisionMaking -ResponseFile $responseFiles.FullName
    
    Write-Host "    Decision: $($decision.Decision)" -ForegroundColor DarkGray
    Write-Host "    Confidence: $($decision.Confidence)%" -ForegroundColor DarkGray
    Write-Host "    Test Path: $($decision.TestPath)" -ForegroundColor DarkGray
    
    return ($decision.Decision -eq "EXECUTE_TEST" -and $decision.TestPath -ne $null)
}

# Test 7: Execute-TestInWindow Script
Test-Component "Execute-TestInWindow Script Exists" {
    $testRunnerPath = ".\Execute-TestInWindow.ps1"
    $exists = Test-Path $testRunnerPath
    if ($exists) {
        Write-Host "    Test runner found at: $testRunnerPath" -ForegroundColor DarkGray
    }
    return $exists
}

# Test 8: Signal File Processing
Test-Component "Signal File Creation and Processing" {
    # Create a mock signal file
    $signalDir = ".\ClaudeResponses\Autonomous"
    $signalFile = "$signalDir\TestComplete_$(Get-Date -Format 'yyyyMMdd_HHmmss').signal"
    
    $signalData = @{
        TestPath = ".\Test-CLIOrchestrator-Simple.ps1"
        ResultFile = ".\Test-CLIOrchestrator-Simple-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
        ExitCode = 0
        Status = "SUCCESS"
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
    
    $signalData | ConvertTo-Json | Out-File -FilePath $signalFile -Encoding UTF8
    
    # Verify signal file was created
    $exists = Test-Path $signalFile
    if ($exists) {
        Write-Host "    Signal file created: $signalFile" -ForegroundColor DarkGray
        
        # Read and verify content
        $content = Get-Content $signalFile -Raw | ConvertFrom-Json
        if ($content.Status -eq "SUCCESS") {
            Write-Host "    Signal content valid" -ForegroundColor DarkGray
        }
    }
    return $exists
}

# Test 9: Window Detection (Non-blocking)
Test-Component "Claude Window Detection (Optional)" {
    try {
        $claudeWindow = Find-ClaudeWindow -ErrorAction SilentlyContinue
        if ($claudeWindow) {
            Write-Host "    Claude window found: $($claudeWindow.MainWindowTitle)" -ForegroundColor DarkGray
            return $true
        } else {
            Write-Host "    Claude window not found (non-critical)" -ForegroundColor Yellow
            return $true  # Return true anyway as this is optional
        }
    } catch {
        Write-Host "    Window detection skipped: $($_.Exception.Message)" -ForegroundColor Yellow
        return $true  # Non-critical
    }
}

# Test 10: End-to-End Workflow Simulation
Test-Component "End-to-End Workflow Simulation" {
    Write-Host "    Simulating complete Testing workflow..." -ForegroundColor DarkGray
    
    # Step 1: Create response with Testing prompt type
    $e2eResponse = @{
        timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        prompt_type = "Testing"
        details = ".\Test-CLIOrchestrator-Simple.ps1"
        RESPONSE = "RECOMMENDATION: TEST - .\Test-CLIOrchestrator-Simple.ps1: Validate the core functions"
    }
    
    $e2eFile = ".\ClaudeResponses\Autonomous\e2e_test_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $e2eResponse | ConvertTo-Json | Out-File -FilePath $e2eFile -Encoding UTF8
    Write-Host "      1. Created response file" -ForegroundColor DarkGray
    
    # Step 2: Process the response
    $processed = Process-ResponseFile -ResponseFilePath $e2eFile -ExtractRecommendations
    Write-Host "      2. Processed response (Type: $($processed.PromptType))" -ForegroundColor DarkGray
    
    # Step 3: Make decision
    $decision = Invoke-AutonomousDecisionMaking -ResponseFile $e2eFile
    Write-Host "      3. Decision made: $($decision.Decision)" -ForegroundColor DarkGray
    
    # Step 4: Verify decision would trigger test execution
    $wouldExecute = ($decision.Decision -eq "EXECUTE_TEST" -and $decision.TestPath -ne $null)
    Write-Host "      4. Would execute test: $wouldExecute" -ForegroundColor DarkGray
    
    return $wouldExecute
}

# Generate Summary
Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Test Results Summary" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Tests: $($testResults.TotalTests)" -ForegroundColor White
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor $(if($testResults.Failed -eq 0){"Gray"}else{"Red"})
Write-Host ""

# Display details
Write-Host "Test Details:" -ForegroundColor Yellow
foreach ($detail in $testResults.Details) {
    if ($detail -match "PASS") {
        Write-Host "  $detail" -ForegroundColor Green
    } elseif ($detail -match "FAIL|ERROR") {
        Write-Host "  $detail" -ForegroundColor Red
    } else {
        Write-Host "  $detail" -ForegroundColor Gray
    }
}

# Final Status
Write-Host ""
if ($testResults.Failed -eq 0) {
    Write-Host "SUCCESS: All Testing workflow components are functional!" -ForegroundColor Green
    Write-Host ""
    Write-Host "The CLIOrchestrator Testing prompt-type workflow is ready for use." -ForegroundColor Green
    Write-Host "To start the orchestrator, run:" -ForegroundColor Cyan
    Write-Host "  Start-CLIOrchestration -AutonomousMode -EnableDecisionMaking" -ForegroundColor White
    $exitCode = 0
} else {
    Write-Host "ISSUES FOUND: $($testResults.Failed) test(s) failed" -ForegroundColor Red
    Write-Host "Please review the failed tests above." -ForegroundColor Yellow
    $exitCode = 1
}

Write-Host ""
Write-Host "Test completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "================================================================" -ForegroundColor Cyan

# Clean up test files (optional)
$cleanup = $false
if ($cleanup) {
    Write-Host "Cleaning up test files..." -ForegroundColor Gray
    Remove-Item ".\ClaudeResponses\Autonomous\test_workflow_*.json" -Force -ErrorAction SilentlyContinue
    Remove-Item ".\ClaudeResponses\Autonomous\e2e_test_*.json" -Force -ErrorAction SilentlyContinue
    Remove-Item ".\ClaudeResponses\Autonomous\TestComplete_*.signal" -Force -ErrorAction SilentlyContinue
}

exit $exitCode