# Test-Day3-Complete-Integration.ps1
# Week 1 Day 3 Hour 3-8: Complete Ollama Integration Testing
# Tests PowershAI, Intelligent Pipeline, Real-Time Analysis, and Batch Processing

param(
    [switch]$SkipPowershAI,
    [switch]$TestRealTime,
    [switch]$TestBatchProcessing
)

#region Test Framework Setup

$ErrorActionPreference = "Stop"

$script:TestResults = @{
    StartTime = Get-Date
    TestSuite = "Day 3 Complete Ollama Integration (Hours 3-8)"
    Tests = @()
    Summary = @{}
}

function Add-TestResult {
    param(
        [string]$TestName,
        [string]$Category,
        [bool]$Passed,
        [string]$Details,
        [hashtable]$Data = @{}
    )
    
    $script:TestResults.Tests += @{
        TestName = $TestName
        Category = $Category
        Passed = $Passed
        Details = $Details
        Data = $Data
        Timestamp = Get-Date
    }
    
    $status = if ($Passed) { "[PASS]" } else { "[FAIL]" }
    $color = if ($Passed) { "Green" } else { "Red" }
    Write-Host "  $status $TestName - $Details" -ForegroundColor $color
}

#endregion

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "Day 3 Complete Ollama Integration Test Suite" -ForegroundColor White
Write-Host "Testing Hours 3-8: PowershAI, Pipeline, Real-Time Analysis" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

#region Hour 3-4: Intelligent Documentation Pipeline Testing

Write-Host "`n[HOUR 3-4] Intelligent Documentation Pipeline..." -ForegroundColor Yellow

try {
    Write-Host "Loading enhanced Ollama module..." -ForegroundColor White
    Import-Module ".\Unity-Claude-Ollama-Enhanced.psm1" -Force
    
    $enhancedCommands = Get-Command -Module "Unity-Claude-Ollama-Enhanced"
    $commandCount = ($enhancedCommands | Measure-Object).Count
    
    Add-TestResult -TestName "Enhanced Module Loading" -Category "Pipeline" `
        -Passed ($commandCount -eq 10) `
        -Details "Enhanced functions loaded: $commandCount/10" `
        -Data @{ Commands = $enhancedCommands.Name }
}
catch {
    Add-TestResult -TestName "Enhanced Module Loading" -Category "Pipeline" `
        -Passed $false -Details "Error: $($_.Exception.Message)"
}

# Test PowershAI Integration
if (-not $SkipPowershAI) {
    try {
        Write-Host "Testing PowershAI integration..." -ForegroundColor White
        $powershAIResult = Initialize-PowershAI
        
        Add-TestResult -TestName "PowershAI Initialization" -Category "Pipeline" `
            -Passed $powershAIResult.Success `
            -Details $powershAIResult.Message `
            -Data $powershAIResult
    }
    catch {
        Add-TestResult -TestName "PowershAI Initialization" -Category "Pipeline" `
            -Passed $false -Details "PowershAI not available: $($_.Exception.Message)"
    }
}

# Test Documentation Pipeline
try {
    Write-Host "Testing intelligent documentation pipeline..." -ForegroundColor White
    $pipelineResult = Start-IntelligentDocumentationPipeline
    
    Add-TestResult -TestName "Documentation Pipeline Start" -Category "Pipeline" `
        -Passed $pipelineResult.Success `
        -Details "Pipeline status: $($pipelineResult.Status)" `
        -Data $pipelineResult
}
catch {
    Add-TestResult -TestName "Documentation Pipeline Start" -Category "Pipeline" `
        -Passed $false -Details "Error: $($_.Exception.Message)"
}

# Test Documentation Request Queueing
try {
    Write-Host "Testing documentation request queueing..." -ForegroundColor White
    $testFile = ".\Unity-Claude-Ollama.psm1"
    
    if (Test-Path $testFile) {
        $request = Add-DocumentationRequest -FilePath $testFile -Priority "High" -EnhancementType "Complete"
        
        Add-TestResult -TestName "Documentation Request Queueing" -Category "Pipeline" `
            -Passed ($request -ne $null) `
            -Details "Request ID: $($request.Id)" `
            -Data @{ RequestId = $request.Id; Status = $request.Status }
    } else {
        Add-TestResult -TestName "Documentation Request Queueing" -Category "Pipeline" `
            -Passed $false -Details "Test file not found"
    }
}
catch {
    Add-TestResult -TestName "Documentation Request Queueing" -Category "Pipeline" `
        -Passed $false -Details "Error: $($_.Exception.Message)"
}

# Test Quality Assessment
try {
    Write-Host "Testing documentation quality assessment..." -ForegroundColor White
    
    $sampleDoc = "This function gets the current date"
    $sampleCode = "function Get-CurrentDate { Get-Date }"
    
    $quality = Get-DocumentationQualityAssessment -Documentation $sampleDoc -CodeContent $sampleCode
    
    Add-TestResult -TestName "Quality Assessment" -Category "Pipeline" `
        -Passed ($quality -ne $null) `
        -Details "Overall score: $($quality.OverallScore)/100" `
        -Data $quality
}
catch {
    Add-TestResult -TestName "Quality Assessment" -Category "Pipeline" `
        -Passed $false -Details "Error: $($_.Exception.Message)"
}

#endregion

#region Hour 5-6: Real-Time AI Analysis Testing

if ($TestRealTime) {
    Write-Host "`n[HOUR 5-6] Real-Time AI Analysis..." -ForegroundColor Yellow
    
    try {
        Write-Host "Starting real-time AI analysis monitoring..." -ForegroundColor White
        $testPath = ".\TestWatch"
        
        # Create test directory if it doesn't exist
        if (-not (Test-Path $testPath)) {
            New-Item -Path $testPath -ItemType Directory -Force | Out-Null
        }
        
        $rtResult = Start-RealTimeAIAnalysis -WatchPath $testPath -FileFilter "*.ps1"
        
        Add-TestResult -TestName "Real-Time Analysis Start" -Category "RealTime" `
            -Passed $rtResult.Success `
            -Details "Monitoring: $($rtResult.WatchPath)" `
            -Data $rtResult
        
        # Test file change detection
        Write-Host "Testing change detection..." -ForegroundColor White
        $testFilePath = Join-Path $testPath "test-change.ps1"
        "# Test file`nGet-Date" | Out-File -FilePath $testFilePath -Force
        
        Start-Sleep -Seconds 2
        
        # Check status
        $status = Get-RealTimeAnalysisStatus
        
        Add-TestResult -TestName "Real-Time Status Check" -Category "RealTime" `
            -Passed $status.MonitoringActive `
            -Details "Monitoring active: $($status.MonitoringActive)" `
            -Data $status
        
        # Stop monitoring
        $stopResult = Stop-RealTimeAIAnalysis
        
        Add-TestResult -TestName "Real-Time Analysis Stop" -Category "RealTime" `
            -Passed $stopResult.Success `
            -Details $stopResult.Message `
            -Data $stopResult
    }
    catch {
        Add-TestResult -TestName "Real-Time Analysis" -Category "RealTime" `
            -Passed $false -Details "Error: $($_.Exception.Message)"
    }
}

#endregion

#region Hour 7-8: Batch Processing and Optimization Testing

if ($TestBatchProcessing) {
    Write-Host "`n[HOUR 7-8] Batch Processing and Optimization..." -ForegroundColor Yellow
    
    try {
        Write-Host "Testing batch documentation processing..." -ForegroundColor White
        
        # Find test files
        $testFiles = Get-ChildItem -Path ".\Modules" -Filter "*.psm1" -Recurse | 
                     Select-Object -First 3 -ExpandProperty FullName
        
        if ($testFiles.Count -gt 0) {
            $batchResult = Start-BatchDocumentationProcessing -Files $testFiles -BatchSize 2
            
            Add-TestResult -TestName "Batch Documentation Processing" -Category "BatchProcessing" `
                -Passed ($batchResult.Successful -gt 0) `
                -Details "Processed: $($batchResult.Successful)/$($batchResult.TotalFiles)" `
                -Data $batchResult
        } else {
            Add-TestResult -TestName "Batch Documentation Processing" -Category "BatchProcessing" `
                -Passed $false -Details "No test files found"
        }
    }
    catch {
        Add-TestResult -TestName "Batch Documentation Processing" -Category "BatchProcessing" `
            -Passed $false -Details "Error: $($_.Exception.Message)"
    }
}

#endregion

#region Day 3 Success Criteria Validation

Write-Host "`n[DAY 3 SUCCESS CRITERIA]" -ForegroundColor Yellow

# Check Hour 3-4 Success (Intelligent Pipeline)
$pipelineTests = $script:TestResults.Tests | Where-Object { $_.Category -eq "Pipeline" }
$pipelinePassed = ($pipelineTests | Where-Object { $_.Passed } | Measure-Object).Count
$pipelineTotal = ($pipelineTests | Measure-Object).Count
$pipelineSuccess = if ($pipelineTotal -gt 0) { $pipelinePassed / $pipelineTotal -ge 0.8 } else { $false }

Add-TestResult -TestName "Hour 3-4: Intelligent Pipeline" -Category "SuccessCriteria" `
    -Passed $pipelineSuccess `
    -Details "Pipeline tests: $pipelinePassed/$pipelineTotal" `
    -Data @{ PassRate = if ($pipelineTotal -gt 0) { $pipelinePassed / $pipelineTotal } else { 0 } }

# Check Hour 5-6 Success (Real-Time Analysis)
if ($TestRealTime) {
    $rtTests = $script:TestResults.Tests | Where-Object { $_.Category -eq "RealTime" }
    $rtPassed = ($rtTests | Where-Object { $_.Passed } | Measure-Object).Count
    $rtTotal = ($rtTests | Measure-Object).Count
    $rtSuccess = if ($rtTotal -gt 0) { $rtPassed / $rtTotal -ge 0.8 } else { $false }
    
    Add-TestResult -TestName "Hour 5-6: Real-Time Analysis" -Category "SuccessCriteria" `
        -Passed $rtSuccess `
        -Details "Real-time tests: $rtPassed/$rtTotal" `
        -Data @{ PassRate = if ($rtTotal -gt 0) { $rtPassed / $rtTotal } else { 0 } }
}

# Check Hour 7-8 Success (Optimization)
if ($TestBatchProcessing) {
    $batchTests = $script:TestResults.Tests | Where-Object { $_.Category -eq "BatchProcessing" }
    $batchPassed = ($batchTests | Where-Object { $_.Passed } | Measure-Object).Count
    $batchTotal = ($batchTests | Measure-Object).Count
    $batchSuccess = if ($batchTotal -gt 0) { $batchPassed / $batchTotal -ge 0.8 } else { $false }
    
    Add-TestResult -TestName "Hour 7-8: Batch Processing" -Category "SuccessCriteria" `
        -Passed $batchSuccess `
        -Details "Batch tests: $batchPassed/$batchTotal" `
        -Data @{ PassRate = if ($batchTotal -gt 0) { $batchPassed / $batchTotal } else { 0 } }
}

#endregion

#region Results Summary

$script:TestResults.EndTime = Get-Date
$totalTests = ($script:TestResults.Tests | Measure-Object).Count
$passedTests = ($script:TestResults.Tests | Where-Object { $_.Passed } | Measure-Object).Count
$failedTests = $totalTests - $passedTests
$passRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 1) } else { 0 }

# Category summary
$categories = $script:TestResults.Tests | Group-Object Category
$categorySummary = @{}

foreach ($cat in $categories) {
    $catPassed = ($cat.Group | Where-Object { $_.Passed } | Measure-Object).Count
    $catTotal = $cat.Count
    $categorySummary[$cat.Name] = @{
        Passed = $catPassed
        Total = $catTotal
        PassRate = [math]::Round(($catPassed / $catTotal) * 100, 1)
    }
}

$script:TestResults.Summary = @{
    TotalTests = $totalTests
    PassedTests = $passedTests
    FailedTests = $failedTests
    PassRate = $passRate
    Categories = $categorySummary
    Duration = ($script:TestResults.EndTime - $script:TestResults.StartTime).TotalSeconds
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "Day 3 Complete Integration Test Results" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan

Write-Host "`n[CATEGORY RESULTS]" -ForegroundColor Yellow
foreach ($catName in $categorySummary.Keys | Sort-Object) {
    $cat = $categorySummary[$catName]
    $color = if ($cat.PassRate -ge 80) { "Green" } elseif ($cat.PassRate -ge 60) { "Yellow" } else { "Red" }
    Write-Host "  $catName`: $($cat.Passed)/$($cat.Total) ($($cat.PassRate)%)" -ForegroundColor $color
}

Write-Host "`n[OVERALL RESULTS]" -ForegroundColor Yellow
Write-Host "  Total Tests: $totalTests" -ForegroundColor White
Write-Host "  Passed: $passedTests" -ForegroundColor Green
Write-Host "  Failed: $failedTests" -ForegroundColor Red
Write-Host "  Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 80) { "Green" } elseif ($passRate -ge 60) { "Yellow" } else { "Red" })

# Save results
$resultFile = ".\Day3-Complete-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$script:TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultFile -Encoding UTF8

Write-Host "`nResults saved to: $resultFile" -ForegroundColor Gray

# Day 3 Implementation Status
$day3Complete = $passRate -ge 80
$status = if ($day3Complete) { "COMPLETE" } else { "PARTIAL" }
$color = if ($day3Complete) { "Green" } else { "Yellow" }

Write-Host "`n[DAY 3 IMPLEMENTATION STATUS]" -ForegroundColor Cyan
Write-Host "Day 3 Ollama Integration: $status" -ForegroundColor $color

if ($day3Complete) {
    Write-Host "Ready to proceed to Day 4: AI Workflow Integration Testing" -ForegroundColor Green
} else {
    Write-Host "Additional work needed on Day 3 features" -ForegroundColor Yellow
}

Write-Host "============================================================" -ForegroundColor Cyan

#endregion

return $script:TestResults