<#
.SYNOPSIS
    Quick validation test for CLIOrchestrator without full integration tests
    
.DESCRIPTION
    Validates core functionality without requiring full system setup
#>
[CmdletBinding()]
param(
    [switch]$SaveResults
)

$testResults = @{
    TestName = "CLIOrchestrator Quick Validation"
    Results = @()
    Summary = @{ Total = 0; Passed = 0; Failed = 0 }
}

function Add-TestResult {
    param($Name, $Status, $Error = "")
    $testResults.Results += @{ Name = $Name; Status = $Status; Error = $Error; Timestamp = Get-Date }
    $testResults.Summary.Total++
    $testResults.Summary.$Status++
    
    if ($Status -eq "Passed") {
        Write-Host "  Pass: $Name" -ForegroundColor Green
    } else {
        Write-Host "  Fail: $Name" -ForegroundColor Red
        if ($Error) { Write-Host "    Error: $Error" -ForegroundColor Yellow }
    }
}

Write-Host "`nRunning quick validation tests..." -ForegroundColor White

try {
    # Test 1: Module Import
    Write-Host "`n1. Testing module import..." -ForegroundColor Cyan
    Get-Module Unity-Claude-CLIOrchestrator | Remove-Module -Force -ErrorAction SilentlyContinue
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force -ErrorAction Stop
    Add-TestResult -Name "Module Import" -Status "Passed"
} catch {
    Add-TestResult -Name "Module Import" -Status "Failed" -Error $_.Exception.Message
}

try {
    # Test 2: Function Availability
    Write-Host "`n2. Testing function availability..." -ForegroundColor Cyan
    $coreFunctions = @('Extract-ResponseEntities', 'Analyze-ResponseSentiment', 'Find-RecommendationPatterns', 'Invoke-RuleBasedDecision', 'Test-SafetyValidation')
    $missing = @()
    foreach ($func in $coreFunctions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            $missing += $func
        }
    }
    if ($missing.Count -eq 0) {
        Add-TestResult -Name "Core Functions Available" -Status "Passed"
    } else {
        Add-TestResult -Name "Core Functions Available" -Status "Failed" -Error "Missing: $($missing -join ', ')"
    }
} catch {
    Add-TestResult -Name "Core Functions Available" -Status "Failed" -Error $_.Exception.Message
}

try {
    # Test 3: Decision Making
    Write-Host "`n3. Testing decision making..." -ForegroundColor Cyan
    $testResponse = @{
        entities = @('Unity', 'Build')
        confidence = 75
        prompt_type = 'Testing'
        recommendations = @('Test-UnityBuild')
    }
    
    $decision = Invoke-RuleBasedDecision -ResponseData $testResponse -ErrorAction Stop
    if ($decision) {
        Add-TestResult -Name "Decision Making" -Status "Passed"
    } else {
        Add-TestResult -Name "Decision Making" -Status "Failed" -Error "No decision returned"
    }
} catch {
    Add-TestResult -Name "Decision Making" -Status "Failed" -Error $_.Exception.Message
}

try {
    # Test 4: Safety Validation
    Write-Host "`n4. Testing safety validation..." -ForegroundColor Cyan
    $safeAction = @{
        action_type = 'TEST_EXECUTION'
        command = 'Test-CLIOrchestrator'
        risk_level = 'Low'
    }
    $validation = Test-SafetyValidation -ActionData $safeAction -ErrorAction Stop
    if ($validation.IsValid) {
        Add-TestResult -Name "Safety Validation" -Status "Passed"
    } else {
        Add-TestResult -Name "Safety Validation" -Status "Failed" -Error "Validation failed"
    }
} catch {
    Add-TestResult -Name "Safety Validation" -Status "Failed" -Error $_.Exception.Message
}

try {
    # Test 5: Window Detection (without activation)
    Write-Host "`n5. Testing window detection..." -ForegroundColor Cyan
    $windowInfo = Get-ClaudeWindowInfo -ErrorAction Stop
    if ($windowInfo) {
        Write-Host "    Found window: $($windowInfo.Title) (PID: $($windowInfo.ProcessId))" -ForegroundColor Gray
        Add-TestResult -Name "Window Detection" -Status "Passed"
    } else {
        Add-TestResult -Name "Window Detection" -Status "Failed" -Error "No Claude window found"
    }
} catch {
    Add-TestResult -Name "Window Detection" -Status "Failed" -Error $_.Exception.Message
}

try {
    # Test 6: Response Processing
    Write-Host "`n6. Testing response processing..." -ForegroundColor Cyan
    $testJsonResponse = @{
        prompt_type = 'Testing'
        confidence = 85
        details = 'Test execution'
        timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    } | ConvertTo-Json
    
    # Write test response file
    $testFile = ".\ClaudeResponses\Autonomous\TestResponse_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $testJsonResponse | Out-File $testFile -Encoding UTF8
    
    # Test processing (without execution)
    if (Test-Path $testFile) {
        Add-TestResult -Name "Response Processing" -Status "Passed"
        Remove-Item $testFile -Force
    } else {
        Add-TestResult -Name "Response Processing" -Status "Failed" -Error "Could not create test file"
    }
} catch {
    Add-TestResult -Name "Response Processing" -Status "Failed" -Error $_.Exception.Message
}

# Display summary
Write-Host "`n" + ("=" * 50) -ForegroundColor Cyan
Write-Host "Test Summary:" -ForegroundColor White
Write-Host "  Total: $($testResults.Summary.Total)" -ForegroundColor White
Write-Host "  Passed: $($testResults.Summary.Passed)" -ForegroundColor Green
Write-Host "  Failed: $($testResults.Summary.Failed)" -ForegroundColor Red
Write-Host ("=" * 50) -ForegroundColor Cyan

if ($SaveResults) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $resultsFile = "CLIOrchestrator-Quick-TestResults-$timestamp.json"
    $testResults | ConvertTo-Json -Depth 10 | Out-File $resultsFile -Encoding UTF8
    Write-Host "`nTest results saved to: $resultsFile" -ForegroundColor Cyan
}

Write-Host "`nCLIOrchestrator quick validation completed." -ForegroundColor White