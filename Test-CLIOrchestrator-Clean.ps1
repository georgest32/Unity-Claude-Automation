# Test-CLIOrchestrator-Clean.ps1
# Quick validation test for Phase 7 CLIOrchestrator implementation
# Date: 2025-08-25

param([switch]$SaveResults)

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Unity-Claude CLIOrchestrator Quick Validation Test" -ForegroundColor Cyan
Write-Host "  Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

$testResults = @{
    TestSuite = "CLIOrchestrator-Quick"
    StartTime = Get-Date
    Results = @()
    Summary = @{ Total = 0; Passed = 0; Failed = 0 }
}

function Add-TestResult {
    param($Name, $Status, $Error = "")
    $testResults.Results += @{ Name = $Name; Status = $Status; Error = $Error; Timestamp = Get-Date }
    $testResults.Summary.Total++
    $testResults.Summary.$Status++
    
    if ($Status -eq "Passed") {
        Write-Host "  OK: $Name" -ForegroundColor Green
    } else {
        Write-Host "  FAIL: $Name" -ForegroundColor Red
        if ($Error) { Write-Host "    Error: $Error" -ForegroundColor Yellow }
    }
}

Write-Host ""
Write-Host "Running quick validation tests..." -ForegroundColor White

try {
    # Test 1: Module Import
    Write-Host ""
    Write-Host "1. Testing module import..." -ForegroundColor Cyan
    Get-Module Unity-Claude-CLIOrchestrator | Remove-Module -Force -ErrorAction SilentlyContinue
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force -ErrorAction Stop
    Add-TestResult -Name "Module Import" -Status "Passed"
} catch {
    Add-TestResult -Name "Module Import" -Status "Failed" -Error $_.Exception.Message
}

try {
    # Test 2: Function Availability
    Write-Host ""
    Write-Host "2. Testing function availability..." -ForegroundColor Cyan
    $coreFunctions = @('Extract-ResponseEntities', 'Analyze-ResponseSentiment', 'Find-RecommendationPatterns', 'Invoke-RuleBasedDecision', 'Test-SafetyValidation')
    $missing = @()
    foreach ($func in $coreFunctions) {
        if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
            $missing += $func
        }
    }
    if ($missing.Count -eq 0) {
        Add-TestResult -Name "Function Availability" -Status "Passed"
    } else {
        Add-TestResult -Name "Function Availability" -Status "Failed" -Error "Missing functions: $($missing -join ', ')"
    }
} catch {
    Add-TestResult -Name "Function Availability" -Status "Failed" -Error $_.Exception.Message
}

try {
    # Test 3: Configuration Files
    Write-Host ""
    Write-Host "3. Testing configuration files..." -ForegroundColor Cyan
    $configPath = ".\Modules\Unity-Claude-CLIOrchestrator\Config"
    $configFiles = @('DecisionTrees.json', 'SafetyPolicies.json', 'LearningParameters.json')
    $missing = @()
    foreach ($file in $configFiles) {
        if (-not (Test-Path (Join-Path $configPath $file))) {
            $missing += $file
        }
    }
    if ($missing.Count -eq 0) {
        Add-TestResult -Name "Configuration Files" -Status "Passed"
    } else {
        Add-TestResult -Name "Configuration Files" -Status "Failed" -Error "Missing files: $($missing -join ', ')"
    }
} catch {
    Add-TestResult -Name "Configuration Files" -Status "Failed" -Error $_.Exception.Message
}

try {
    # Test 4: Basic Function Execution
    Write-Host ""
    Write-Host "4. Testing basic function execution..." -ForegroundColor Cyan
    $testResponse = "RECOMMENDATION: TEST - Test-SemanticAnalysis.ps1: Run validation test"
    
    # Test pattern recognition
    $patterns = Find-RecommendationPatterns -ResponseText $testResponse
    if ($patterns -and $patterns.Count -gt 0) {
        Add-TestResult -Name "Pattern Recognition" -Status "Passed"
    } else {
        Add-TestResult -Name "Pattern Recognition" -Status "Failed" -Error "No patterns found in test response"
    }
} catch {
    Add-TestResult -Name "Pattern Recognition" -Status "Failed" -Error $_.Exception.Message
}

try {
    # Test 5: Decision Engine Basic Test
    Write-Host ""
    Write-Host "5. Testing decision engine..." -ForegroundColor Cyan
    $testAnalysisResult = @{
        Recommendations = @(@{
            Type = "TEST"
            Action = "Run validation test"  
            FilePath = ""
            Confidence = 0.95
            Priority = 1
        })
        ConfidenceAnalysis = @{ OverallConfidence = 0.90; QualityRating = "High" }
        Entities = @{ FilePaths = @(); Commands = @("Test-SemanticAnalysis") }
        ProcessingSuccess = $true
        TotalProcessingTimeMs = 150
    }
    
    $decision = Invoke-RuleBasedDecision -AnalysisResult $testAnalysisResult -DryRun
    if ($decision -and $decision.Decision -in @("PROCEED", "TEST", "CONTINUE")) {
        Add-TestResult -Name "Decision Engine" -Status "Passed"
    } else {
        Add-TestResult -Name "Decision Engine" -Status "Failed" -Error "Unexpected decision: $($decision.Decision)"
    }
} catch {
    Add-TestResult -Name "Decision Engine" -Status "Failed" -Error $_.Exception.Message
}

# Summary
$testResults.EndTime = Get-Date
$testResults.TotalDuration = ($testResults.EndTime - $testResults.StartTime).TotalMilliseconds

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  QUICK VALIDATION COMPLETE" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.Summary.Total)" -ForegroundColor White
Write-Host "Passed: $($testResults.Summary.Passed)" -ForegroundColor Green  
Write-Host "Failed: $($testResults.Summary.Failed)" -ForegroundColor Red
$successRate = [math]::Round(($testResults.Summary.Passed / $testResults.Summary.Total) * 100, 1)
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } else { "Yellow" })

if ($SaveResults) {
    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $resultsFile = "CLIOrchestrator-Quick-TestResults-$timestamp.json"
    $testResults | ConvertTo-Json -Depth 10 | Out-File $resultsFile -Encoding UTF8
    Write-Host ""
    Write-Host "Test results saved to: $resultsFile" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "CLIOrchestrator quick validation completed." -ForegroundColor White