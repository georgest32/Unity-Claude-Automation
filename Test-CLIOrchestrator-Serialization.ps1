# Test script for CLIOrchestrator serialization fix
# Date: 2025-12-28
# Purpose: Validate that ActionDetails are properly serialized when building autonomous prompts

Write-Host "=== CLIOrchestrator Serialization Test ===" -ForegroundColor Cyan
Write-Host "Testing serialization fix for path corruption issue" -ForegroundColor Gray
Write-Host ""

# Test result file path
$testResultFile = ".\CLIOrchestrator-Serialization-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"

# Start test log
$testLog = @()
$testLog += "CLIOrchestrator Serialization Test Results"
$testLog += "Test Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$testLog += "=" * 60
$testLog += ""

# Import the module
Write-Host "[1] Importing Unity-Claude-CLIOrchestrator module..." -ForegroundColor Yellow
try {
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator-Original.psm1" -Force
    Write-Host "  Module imported successfully" -ForegroundColor Green
    $testLog += "Module Import: SUCCESS"
} catch {
    Write-Host "  Failed to import module: $_" -ForegroundColor Red
    $testLog += "Module Import: FAILED - $_"
    $testLog | Out-File -FilePath $testResultFile
    exit 1
}
$testLog += ""

# Test cases
$testCases = @(
    @{
        Name = "String ActionDetails"
        ActionDetails = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Enhanced_Documentation_Second_Pass_Implementation_2025_08_28.md"
        ExpectedContains = "Enhanced_Documentation_Second_Pass_Implementation_2025_08_28.md"
        ExpectedNotContains = "@{"
    },
    @{
        Name = "Hashtable with file path"
        ActionDetails = @{
            Path = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Implementation.md"
            Type = "ImplementationPlan"
        }
        ExpectedContains = "Implementation.md"
        ExpectedNotContains = "System.Object"
    },
    @{
        Name = "Complex hashtable (week priorities)"
        ActionDetails = @{
            week_1_priorities = @("C:\Test\Week1.md", "Priority1", "Priority2")
            week_2_priorities = @("Priority3", "Priority4")
            week_3_priorities = @()
            week_4_priorities = @()
        }
        ExpectedContains = "Week1.md"
        ExpectedNotContains = "System.Object[]"
    },
    @{
        Name = "PSObject with FilePath property"
        ActionDetails = [PSCustomObject]@{
            FilePath = "C:\Documents\TestPlan.md"
            Status = "InProgress"
            Priority = "High"
        }
        ExpectedContains = "TestPlan.md"
        ExpectedNotContains = "@{"
    },
    @{
        Name = "Array with file paths"
        ActionDetails = @(
            "C:\Path\File1.md",
            "C:\Path\File2.txt", 
            "C:\Path\File3.json"
        )
        ExpectedContains = "File1.md"
        ExpectedNotContains = "System.Object[]"
    }
)

$passedTests = 0
$failedTests = 0

Write-Host ""
Write-Host "[2] Running serialization tests..." -ForegroundColor Yellow

foreach ($testCase in $testCases) {
    Write-Host "  Testing: $($testCase.Name)" -ForegroundColor Cyan
    $testLog += "-" * 40
    $testLog += "Test: $($testCase.Name)"
    
    try {
        # Call the New-AutonomousPrompt function
        $prompt = New-AutonomousPrompt -RecommendationType "CONTINUE" -ActionDetails $testCase.ActionDetails
        
        # Check if expected content is present
        if ($prompt -match [regex]::Escape($testCase.ExpectedContains)) {
            Write-Host "    [PASS] Expected content found: '$($testCase.ExpectedContains)'" -ForegroundColor Green
            $containsPass = $true
        } else {
            Write-Host "    [FAIL] Expected content NOT found: '$($testCase.ExpectedContains)'" -ForegroundColor Red
            Write-Host "      Actual prompt excerpt: $($prompt.Substring(0, [Math]::Min(200, $prompt.Length)))" -ForegroundColor Gray
            $containsPass = $false
        }
        
        # Check if unwanted content is absent
        if ($prompt -notmatch [regex]::Escape($testCase.ExpectedNotContains)) {
            Write-Host "    [PASS] Unwanted pattern absent: '$($testCase.ExpectedNotContains)'" -ForegroundColor Green
            $notContainsPass = $true
        } else {
            Write-Host "    [FAIL] Unwanted pattern PRESENT: '$($testCase.ExpectedNotContains)'" -ForegroundColor Red
            Write-Host "      This indicates serialization failure!" -ForegroundColor Yellow
            $notContainsPass = $false
        }
        
        if ($containsPass -and $notContainsPass) {
            Write-Host "    Result: PASSED" -ForegroundColor Green
            $passedTests++
            $testLog += "Result: PASSED"
            $testLog += "  - Expected content found: $($testCase.ExpectedContains)"
            $testLog += "  - No unwanted patterns detected"
        } else {
            Write-Host "    Result: FAILED" -ForegroundColor Red
            $failedTests++
            $testLog += "Result: FAILED"
            if (-not $containsPass) {
                $testLog += "  - Missing expected content: $($testCase.ExpectedContains)"
            }
            if (-not $notContainsPass) {
                $testLog += "  - Contains unwanted pattern: $($testCase.ExpectedNotContains)"
            }
            $testLog += "  - Prompt excerpt: $($prompt.Substring(0, [Math]::Min(200, $prompt.Length)))"
        }
        
    } catch {
        Write-Host "    [ERROR] Test execution error: $_" -ForegroundColor Red
        $failedTests++
        $testLog += "Result: ERROR - $_"
    }
    
    $testLog += ""
}

Write-Host ""
Write-Host "[3] Test Summary" -ForegroundColor Yellow
Write-Host "  Total Tests: $($testCases.Count)" -ForegroundColor Gray
Write-Host "  Passed: $passedTests" -ForegroundColor Green
Write-Host "  Failed: $failedTests" -ForegroundColor Red

$testLog += "=" * 60
$testLog += "TEST SUMMARY"
$testLog += "Total Tests: $($testCases.Count)"
$testLog += "Passed: $passedTests"
$testLog += "Failed: $failedTests"
$testLog += "Success Rate: $(($passedTests / $testCases.Count) * 100)%"

# Test the Convert-ToSerializedString function directly if available
Write-Host ""
Write-Host "[4] Testing Convert-ToSerializedString function directly..." -ForegroundColor Yellow

if (Get-Command Convert-ToSerializedString -ErrorAction SilentlyContinue) {
    $directTests = @(
        @{Input = "Simple String"; Expected = "Simple String"},
        @{Input = @{Path="C:\Test.md"}; Expected = "C:\Test.md"},
        @{Input = @{week_1_priorities=@("C:\Week1.md")}; Expected = "Week1.md"}
    )
    
    foreach ($test in $directTests) {
        $result = Convert-ToSerializedString -InputObject $test.Input
        if ($result -match [regex]::Escape($test.Expected)) {
            Write-Host "  [PASS] Direct test passed: Input type $($test.Input.GetType().Name)" -ForegroundColor Green
            $testLog += "Direct Serialization Test: PASSED - $($test.Input.GetType().Name)"
        } else {
            Write-Host "  [FAIL] Direct test failed: Expected '$($test.Expected)', got '$result'" -ForegroundColor Red
            $testLog += "Direct Serialization Test: FAILED - Expected '$($test.Expected)', got '$result'"
        }
    }
} else {
    Write-Host "  Convert-ToSerializedString function not found (not exported?)" -ForegroundColor Yellow
    $testLog += "Direct Serialization Test: SKIPPED - Function not exported"
}

# Save test results
$testLog | Out-File -FilePath $testResultFile
Write-Host ""
Write-Host "Test results saved to: $testResultFile" -ForegroundColor Cyan

# Final result
if ($failedTests -eq 0) {
    Write-Host ""
    Write-Host "=== ALL TESTS PASSED ===" -ForegroundColor Green
    Write-Host "The serialization fix is working correctly!" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "=== SOME TESTS FAILED ===" -ForegroundColor Red
    Write-Host "The serialization fix needs further adjustment." -ForegroundColor Yellow
    exit 1
}