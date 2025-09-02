# Run-EnhancedDocumentationTests.ps1
# Test runner script for Enhanced Documentation System validation
# Week 3 Day 4-5: Testing & Validation execution script
# Date: 2025-08-28

#Requires -Version 5.1
#Requires -Module Pester

param(
    [Parameter(Mandatory = $false)]
    [string]$TestOutputPath = "$PSScriptRoot\TestResults",
    
    [Parameter(Mandatory = $false)]
    [string]$TestScope = "All",  # All, CPG, LLM, Templates, Performance
    
    [Parameter(Mandatory = $false)]
    [switch]$Detailed
)

# Ensure Pester v5 is available
if (-not (Get-Module -Name Pester -ListAvailable | Where-Object Version -ge '5.0.0')) {
    Write-Warning "Pester v5+ required. Installing..."
    Install-Module -Name Pester -Force -Scope CurrentUser
}

Import-Module Pester -Force

# Create test results directory
if (-not (Test-Path $TestOutputPath)) {
    New-Item -ItemType Directory -Path $TestOutputPath -Force | Out-Null
}

Write-Host "=== Enhanced Documentation System Test Runner ===" -ForegroundColor Cyan
Write-Host "Test Script: Test-EnhancedDocumentationSystem.ps1" -ForegroundColor Green
Write-Host "Test Scope: $TestScope" -ForegroundColor Green
Write-Host "Output Path: $TestOutputPath" -ForegroundColor Green
Write-Host "Start Time: $(Get-Date)" -ForegroundColor Green

# Configure Pester
$config = New-PesterConfiguration

# Set the test file to execute
$config.Run.Path = "$PSScriptRoot\Test-EnhancedDocumentationSystem.ps1"
$config.Run.PassThru = $true
$config.TestResult.Enabled = $true
$config.TestResult.OutputPath = "$TestOutputPath\EnhancedDocumentationSystem-UnitTests-$(Get-Date -Format 'yyyyMMdd-HHmmss').xml"
$config.Output.Verbosity = if ($Detailed) { 'Detailed' } else { 'Normal' }

# Add test parameters if needed
if ($TestScope -ne "All") {
    $config.Filter.Tag = $TestScope
    Write-Host "Filtering tests by tag: $TestScope" -ForegroundColor Yellow
}

Write-Host "`n=== Executing Pester Tests ===" -ForegroundColor Cyan
Write-Debug "Pester configuration: Run.Path = $($config.Run.Path)"
Write-Debug "Test scope filter: $TestScope"

try {
    $testResults = Invoke-Pester -Configuration $config
    
    # Performance summary (if available from test definitions)
    Write-Host "`n=== Test Results Summary ===" -ForegroundColor Cyan
    Write-Host "  Total Tests: $($testResults.TotalCount)" -ForegroundColor White
    Write-Host "  Passed: $($testResults.PassedCount)" -ForegroundColor Green
    Write-Host "  Failed: $($testResults.FailedCount)" -ForegroundColor $(if ($testResults.FailedCount -gt 0) { 'Red' } else { 'Green' })
    Write-Host "  Skipped: $($testResults.SkippedCount)" -ForegroundColor Yellow
    Write-Host "  Duration: $($testResults.Duration.TotalSeconds) seconds" -ForegroundColor White
    
    if ($testResults.TotalCount -gt 0) {
        $successRate = [math]::Round(($testResults.PassedCount / $testResults.TotalCount) * 100, 1)
        Write-Host "  Success Rate: $successRate%" -ForegroundColor $(if ($testResults.FailedCount -eq 0) { 'Green' } else { 'Yellow' })
    } else {
        Write-Host "  Success Rate: 0% (No tests discovered)" -ForegroundColor Red
    }
    
    # Save detailed results
    $detailedResults = @{
        Summary = @{
            TotalTests = $testResults.TotalCount
            Passed = $testResults.PassedCount
            Failed = $testResults.FailedCount
            Skipped = $testResults.SkippedCount
            SuccessRate = if ($testResults.TotalCount -gt 0) { 
                [math]::Round(($testResults.PassedCount / $testResults.TotalCount) * 100, 1) 
            } else { 0 }
            Duration = $testResults.Duration.TotalSeconds
            StartTime = Get-Date
            TestScript = "Test-EnhancedDocumentationSystem.ps1"
            TestScope = $TestScope
        }
        FailedTests = $testResults.Failed
        TestResults = $testResults
    }
    
    $resultsFile = "$TestOutputPath\EnhancedDocumentationSystem-TestRunner-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $detailedResults | ConvertTo-Json -Depth 5 | Set-Content -Path $resultsFile
    
    Write-Host "`n=== Test Artifacts ===" -ForegroundColor Cyan
    Write-Host "  XML Report: $($config.TestResult.OutputPath)" -ForegroundColor Gray
    Write-Host "  JSON Results: $resultsFile" -ForegroundColor Gray
    Write-Host "  Test Output Directory: $TestOutputPath" -ForegroundColor Gray
    
    if ($testResults.TotalCount -eq 0) {
        Write-Host "`nERROR: No tests discovered! Check test script structure." -ForegroundColor Red
        Write-Host "Test file: Test-EnhancedDocumentationSystem.ps1" -ForegroundColor Gray
        exit 1
    }
    elseif ($testResults.FailedCount -eq 0) {
        Write-Host "`n[PASS] All tests passed successfully!" -ForegroundColor Green
        exit 0
    } else {
        Write-Host "`n[FAIL] Some tests failed. Review the detailed results above." -ForegroundColor Yellow
        exit 1
    }
}
catch {
    Write-Error "Test execution failed: $_"
    Write-Host "Check test script syntax and Pester configuration" -ForegroundColor Red
    exit 1
}