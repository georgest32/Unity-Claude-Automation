# Test-Week3Day13Hour5-6-Modular.ps1
# Main orchestrator for Week 3 Day 13 Hour 5-6: Cross-Reference and Link Management tests
# This runs all modular sub-tests and aggregates results

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$EnableVerbose = $false,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\Week3Day13Hour5-6-ModularResults-$(Get-Date -Format 'yyyyMMddHHmmss').json",
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipSlowTests = $false
)

# Set verbose preference
if ($EnableVerbose) {
    $VerbosePreference = "Continue"
    $DebugPreference = "Continue"
}

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "Week 3 Day 13 Hour 5-6: Cross-Reference and Link Management" -ForegroundColor Cyan
Write-Host "Modular Test Suite Orchestrator" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host ""

# Initialize aggregate results
$aggregateResults = @{
    TestSuite = "Week 3 Day 13 Hour 5-6 - Cross-Reference Management (Modular)"
    StartTime = Get-Date
    EndTime = $null
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    SkippedTests = 0
    SuccessRate = 0
    SubTests = @{}
    Summary = @{
        ASTAnalysis = @{}
        LinkManagement = @{}
        GraphAnalysis = @{}
    }
    Errors = @()
    SystemInfo = @{
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        OS = [System.Environment]::OSVersion.ToString()
        MachineName = [System.Environment]::MachineName
    }
}

# Helper function to run sub-tests safely
function Invoke-SubTest {
    param(
        [string]$TestName,
        [string]$TestPath,
        [switch]$Critical
    )
    
    Write-Host "`nRunning: $TestName" -ForegroundColor Cyan
    Write-Host ("=" * 50) -ForegroundColor Cyan
    
    try {
        if (-not (Test-Path $TestPath)) {
            Write-Host "  [ERROR] Test file not found: $TestPath" -ForegroundColor Red
            $aggregateResults.Errors += @{
                Test = $TestName
                Error = "Test file not found"
                Path = $TestPath
                Time = Get-Date
            }
            return $null
        }
        
        # Run the sub-test
        $subTestResult = & $TestPath -EnableVerbose:$EnableVerbose
        
        if ($subTestResult) {
            # Aggregate the results
            $aggregateResults.SubTests[$TestName] = $subTestResult
            $aggregateResults.TotalTests += ($subTestResult.Passed + $subTestResult.Failed)
            $aggregateResults.PassedTests += $subTestResult.Passed
            $aggregateResults.FailedTests += $subTestResult.Failed
            
            Write-Host "`n  Sub-test completed: $($subTestResult.Passed) passed, $($subTestResult.Failed) failed" -ForegroundColor Yellow
            
            return $subTestResult
        }
        else {
            Write-Host "  [WARN] No results returned from $TestName" -ForegroundColor Yellow
            return $null
        }
    }
    catch {
        Write-Host "  [ERROR] Failed to run $TestName : $_" -ForegroundColor Red
        $aggregateResults.Errors += @{
            Test = $TestName
            Error = $_.Exception.Message
            Time = Get-Date
        }
        
        if ($Critical) {
            Write-Host "  [CRITICAL] This was a critical test. Stopping execution." -ForegroundColor Red
            throw
        }
        
        return $null
    }
}

# Test 1: AST Analysis Tests
$astResults = Invoke-SubTest -TestName "AST Analysis" -TestPath ".\Tests\CrossReference\Test-ASTAnalysis.ps1"
if ($astResults) {
    $aggregateResults.Summary.ASTAnalysis = $astResults.Tests
}

# Test 2: Link Management Tests
$linkResults = Invoke-SubTest -TestName "Link Management" -TestPath ".\Tests\CrossReference\Test-LinkManagement.ps1"
if ($linkResults) {
    $aggregateResults.Summary.LinkManagement = $linkResults.Tests
}

# Test 3: Graph Analysis Tests (can be slow, allow skipping)
if (-not $SkipSlowTests) {
    $graphResults = Invoke-SubTest -TestName "Graph Analysis" -TestPath ".\Tests\CrossReference\Test-GraphAnalysis.ps1"
    if ($graphResults) {
        $aggregateResults.Summary.GraphAnalysis = $graphResults.Tests
    }
}
else {
    Write-Host "`nSkipping Graph Analysis tests (SkipSlowTests flag set)" -ForegroundColor Yellow
    $aggregateResults.SkippedTests++
}

# Calculate final metrics
$aggregateResults.EndTime = Get-Date
$totalDuration = ($aggregateResults.EndTime - $aggregateResults.StartTime).TotalSeconds

if ($aggregateResults.TotalTests -gt 0) {
    $aggregateResults.SuccessRate = [math]::Round(($aggregateResults.PassedTests / $aggregateResults.TotalTests) * 100, 2)
}

# Display final summary
Write-Host "`n" -NoNewline
Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "FINAL TEST SUMMARY" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

Write-Host "`nTest Statistics:" -ForegroundColor Yellow
Write-Host "  Total Tests: $($aggregateResults.TotalTests)" -ForegroundColor White
Write-Host "  Passed: $($aggregateResults.PassedTests)" -ForegroundColor Green
Write-Host "  Failed: $($aggregateResults.FailedTests)" -ForegroundColor Red
if ($aggregateResults.SkippedTests -gt 0) {
    Write-Host "  Skipped: $($aggregateResults.SkippedTests)" -ForegroundColor Yellow
}
Write-Host "  Success Rate: $($aggregateResults.SuccessRate)%" -ForegroundColor $(if ($aggregateResults.SuccessRate -ge 80) { "Green" } elseif ($aggregateResults.SuccessRate -ge 60) { "Yellow" } else { "Red" })
Write-Host "  Duration: $([math]::Round($totalDuration, 2)) seconds" -ForegroundColor Cyan

# Component summary
Write-Host "`nComponent Results:" -ForegroundColor Yellow
foreach ($component in $aggregateResults.SubTests.Keys) {
    $subTest = $aggregateResults.SubTests[$component]
    $componentRate = if ($subTest.Passed + $subTest.Failed -gt 0) {
        [math]::Round(($subTest.Passed / ($subTest.Passed + $subTest.Failed)) * 100, 2)
    } else { 0 }
    
    $color = if ($componentRate -ge 80) { "Green" } elseif ($componentRate -ge 60) { "Yellow" } else { "Red" }
    Write-Host "  $component : $componentRate% ($($subTest.Passed)/$($subTest.Passed + $subTest.Failed))" -ForegroundColor $color
}

# Error summary
if ($aggregateResults.Errors.Count -gt 0) {
    Write-Host "`nErrors Encountered:" -ForegroundColor Red
    foreach ($error in $aggregateResults.Errors) {
        Write-Host "  - [$($error.Test)] $($error.Error)" -ForegroundColor Red
    }
}

# Recommendations
Write-Host "`nRecommendations:" -ForegroundColor Yellow
if ($aggregateResults.SuccessRate -eq 100) {
    Write-Host "  [OK] All tests passed! The cross-reference system is fully operational." -ForegroundColor Green
}
elseif ($aggregateResults.SuccessRate -ge 80) {
    Write-Host "  [OK] System is mostly functional with minor issues to address." -ForegroundColor Yellow
}
elseif ($aggregateResults.SuccessRate -ge 60) {
    Write-Host "  [WARN] Several components need attention. Review failed tests." -ForegroundColor Yellow
}
else {
    Write-Host "  [ERROR] Critical issues detected. Immediate attention required." -ForegroundColor Red
}

# Save results to JSON
try {
    $aggregateResults | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Force
    Write-Host "`nTest results saved to: $OutputPath" -ForegroundColor Green
}
catch {
    Write-Host "`nFailed to save results: $_" -ForegroundColor Red
}

# Return appropriate exit code
if ($aggregateResults.FailedTests -eq 0) {
    Write-Host "`n[PASS] TEST SUITE PASSED" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`n[FAIL] TEST SUITE FAILED" -ForegroundColor Red
    exit 1
}