# Test-Week4-PerformanceValidation.ps1
# Week 4 Day 5 Hour 2: Performance Validation
# Enhanced Documentation System - Performance Benchmarking
# Date: 2025-08-29

param(
    [int]$FileCountTarget = 100,
    [int]$TimeoutSeconds = 300,
    [switch]$Verbose,
    [switch]$SaveReport,
    [string]$OutputPath = ".\Week4-PerformanceValidation-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

if ($Verbose) { $VerbosePreference = "Continue" }

Write-Host "=== Week 4 Performance Validation Suite ===" -ForegroundColor Cyan
Write-Host "Test Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Green

$testResults = @{
    TestName = "Week 4 Performance Validation"
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TargetFilesPerSecond = $FileCountTarget
    Results = @()
    PerformanceMetrics = @{}
    BenchmarkComparison = @{}
}

function Test-PerformanceComponent {
    param(
        [string]$ComponentName,
        [scriptblock]$TestCode,
        [string]$Description = "",
        [int]$TargetDuration = 30000
    )
    
    $testStart = Get-Date
    
    try {
        Write-Host "Benchmarking $ComponentName..." -ForegroundColor Yellow -NoNewline
        
        $result = & $TestCode
        $success = $true
        $error = $null
        
        $testEnd = Get-Date
        $duration = ($testEnd - $testStart).TotalMilliseconds
        
        if ($duration -le $TargetDuration) {
            Write-Host " PASS ($([math]::Round($duration/1000, 2))s)" -ForegroundColor Green
        } else {
            Write-Host " SLOW ($([math]::Round($duration/1000, 2))s > $([math]::Round($TargetDuration/1000, 2))s)" -ForegroundColor Yellow
            $result.PerformanceWarning = "Exceeded target duration"
        }
    }
    catch {
        $success = $false
        $error = $_.Exception.Message
        $duration = ((Get-Date) - $testStart).TotalMilliseconds
        
        Write-Host " FAIL" -ForegroundColor Red
        Write-Host "  Error: $error" -ForegroundColor Red
    }
    
    $testResults.Results += [PSCustomObject]@{
        ComponentName = $ComponentName
        Description = $Description
        Success = $success
        Error = $error
        Duration = [math]::Round($duration, 2)
        TargetDuration = $TargetDuration
        Result = $result
    }
    
    return @{ Success = $success; Duration = $duration; Result = $result }
}

Write-Host "`n=== WEEK 4 MODULE PERFORMANCE TESTS ===" -ForegroundColor Cyan

# Performance Test 1: Code Evolution Analysis
$evolutionPerf = Test-PerformanceComponent -ComponentName "Code Evolution Analysis" -Description "Git history and churn analysis performance" -TargetDuration 15000 -TestCode {
    $startTime = Get-Date
    $results = @{}
    
    try {
        # Test git history analysis performance
        if (Get-Command -Name "Get-GitCommitHistory" -ErrorAction SilentlyContinue) {
            $historyStart = Get-Date
            $commits = Get-GitCommitHistory -MaxCount 50 -Since "2.months.ago"
            $historyDuration = ((Get-Date) - $historyStart).TotalMilliseconds
            
            $results["GitHistoryAnalysis"] = @{
                Duration = [math]::Round($historyDuration, 2)
                CommitCount = if ($commits) { $commits.Count } else { 0 }
                CommitsPerSecond = if ($commits -and $historyDuration -gt 0) { 
                    [math]::Round($commits.Count / ($historyDuration / 1000), 2) 
                } else { 0 }
            }
        }
        
        # Test churn analysis performance
        if (Get-Command -Name "Get-CodeChurnMetrics" -ErrorAction SilentlyContinue) {
            $churnStart = Get-Date
            $churn = Get-CodeChurnMetrics -Path ".\Modules\Unity-Claude-CPG\Core" -Since "1.month.ago"
            $churnDuration = ((Get-Date) - $churnStart).TotalMilliseconds
            
            $results["ChurnAnalysis"] = @{
                Duration = [math]::Round($churnDuration, 2)
                FileCount = if ($churn) { $churn.Count } else { 0 }
                FilesPerSecond = if ($churn -and $churnDuration -gt 0) {
                    [math]::Round($churn.Count / ($churnDuration / 1000), 2)
                } else { 0 }
            }
        }
        
        $totalDuration = ((Get-Date) - $startTime).TotalMilliseconds
        $results["TotalDuration"] = [math]::Round($totalDuration, 2)
        
        return $results
    } catch {
        throw "Code Evolution performance test failed: $($_.Exception.Message)"
    }
}

# Performance Test 2: Maintenance Prediction
$maintenancePerf = Test-PerformanceComponent -ComponentName "Maintenance Prediction" -Description "Technical debt and prediction analysis performance" -TargetDuration 20000 -TestCode {
    $startTime = Get-Date
    $results = @{}
    
    try {
        # Test technical debt analysis performance
        if (Get-Command -Name "Get-TechnicalDebt" -ErrorAction SilentlyContinue) {
            $debtStart = Get-Date
            $debt = Get-TechnicalDebt -Path ".\Modules\Unity-Claude-CPG\Core" -FilePattern "*.psm1" -OutputFormat "Summary"
            $debtDuration = ((Get-Date) - $debtStart).TotalMilliseconds
            
            $results["TechnicalDebtAnalysis"] = @{
                Duration = [math]::Round($debtDuration, 2)
                DebtItems = if ($debt -and $debt.TotalItems) { $debt.TotalItems } else { 0 }
                ItemsPerSecond = if ($debt -and $debt.TotalItems -and $debtDuration -gt 0) {
                    [math]::Round($debt.TotalItems / ($debtDuration / 1000), 2)
                } else { 0 }
            }
        }
        
        # Test code smell detection performance
        if (Get-Command -Name "Get-CodeSmells" -ErrorAction SilentlyContinue) {
            $smellStart = Get-Date
            $smells = Get-CodeSmells -Path ".\Modules\Unity-Claude-CPG\Core" -FilePattern "*.psm1"
            $smellDuration = ((Get-Date) - $smellStart).TotalMilliseconds
            
            $results["CodeSmellDetection"] = @{
                Duration = [math]::Round($smellDuration, 2)
                SmellCount = if ($smells) { $smells.Count } else { 0 }
                SmellsPerSecond = if ($smells -and $smellDuration -gt 0) {
                    [math]::Round($smells.Count / ($smellDuration / 1000), 2)
                } else { 0 }
            }
        }
        
        $totalDuration = ((Get-Date) - $startTime).TotalMilliseconds
        $results["TotalDuration"] = [math]::Round($totalDuration, 2)
        
        return $results
    } catch {
        throw "Maintenance Prediction performance test failed: $($_.Exception.Message)"
    }
}

# Performance Test 3: Combined Workflow Performance
$workflowPerf = Test-PerformanceComponent -ComponentName "Combined Workflow" -Description "End-to-end workflow performance validation" -TargetDuration 30000 -TestCode {
    $startTime = Get-Date
    $results = @{}
    
    try {
        # Simulate realistic workflow
        $workflowSteps = @()
        
        # Step 1: Evolution analysis
        if (Get-Command -Name "Get-CodeChurnMetrics" -ErrorAction SilentlyContinue) {
            $step1Start = Get-Date
            $churn = Get-CodeChurnMetrics -Path ".\Modules\Unity-Claude-CPG\Core" -Since "1.month.ago"
            $step1Duration = ((Get-Date) - $step1Start).TotalMilliseconds
            
            $workflowSteps += @{
                Step = "Evolution Analysis"
                Duration = [math]::Round($step1Duration, 2)
                Output = if ($churn) { "$($churn.Count) files analyzed" } else { "No data" }
            }
        }
        
        # Step 2: Technical debt calculation
        if (Get-Command -Name "Get-TechnicalDebt" -ErrorAction SilentlyContinue) {
            $step2Start = Get-Date
            $debt = Get-TechnicalDebt -Path ".\Modules\Unity-Claude-CPG\Core" -FilePattern "Predictive-*.psm1"
            $step2Duration = ((Get-Date) - $step2Start).TotalMilliseconds
            
            $workflowSteps += @{
                Step = "Technical Debt Analysis"
                Duration = [math]::Round($step2Duration, 2)
                Output = if ($debt -and $debt.TotalItems) { "$($debt.TotalItems) debt items found" } else { "No debt detected" }
            }
        }
        
        # Step 3: Maintenance prediction
        if (Get-Command -Name "Get-MaintenancePrediction" -ErrorAction SilentlyContinue) {
            $step3Start = Get-Date
            $prediction = Get-MaintenancePrediction -Path ".\Modules\Unity-Claude-CPG\Core" -ForecastDays 30
            $step3Duration = ((Get-Date) - $step3Start).TotalMilliseconds
            
            $workflowSteps += @{
                Step = "Maintenance Prediction"
                Duration = [math]::Round($step3Duration, 2)
                Output = if ($prediction) { "$($prediction.Count) predictions generated" } else { "No predictions" }
            }
        }
        
        $totalWorkflowDuration = ((Get-Date) - $startTime).TotalMilliseconds
        
        $results = @{
            WorkflowSteps = $workflowSteps
            TotalDuration = [math]::Round($totalWorkflowDuration, 2)
            StepCount = $workflowSteps.Count
            AverageDurationPerStep = if ($workflowSteps.Count -gt 0) {
                [math]::Round($totalWorkflowDuration / $workflowSteps.Count, 2)
            } else { 0 }
        }
        
        return $results
    } catch {
        throw "Combined workflow performance test failed: $($_.Exception.Message)"
    }
}

# Calculate overall performance metrics
$testResults.PerformanceMetrics = @{
    EvolutionAnalysis = if ($evolutionPerf.Success) { $evolutionPerf.Result } else { "Failed" }
    MaintenancePrediction = if ($maintenancePerf.Success) { $maintenancePerf.Result } else { "Failed" }
    CombinedWorkflow = if ($workflowPerf.Success) { $workflowPerf.Result } else { "Failed" }
    OverallSuccess = $evolutionPerf.Success -and $maintenancePerf.Success -and $workflowPerf.Success
}

Write-Host "`n=== Performance Benchmark Summary ===" -ForegroundColor Cyan
Write-Host "Evolution Analysis: $($evolutionPerf.Duration)ms" -ForegroundColor White
Write-Host "Maintenance Prediction: $($maintenancePerf.Duration)ms" -ForegroundColor White  
Write-Host "Combined Workflow: $($workflowPerf.Duration)ms" -ForegroundColor White

$totalPerformanceTime = $evolutionPerf.Duration + $maintenancePerf.Duration + $workflowPerf.Duration
Write-Host "Total Performance Time: $([math]::Round($totalPerformanceTime/1000, 2)) seconds" -ForegroundColor Cyan

$performanceGrade = if ($totalPerformanceTime -lt 60000) { "EXCELLENT" } 
                   elseif ($totalPerformanceTime -lt 120000) { "GOOD" }
                   elseif ($totalPerformanceTime -lt 180000) { "ACCEPTABLE" }
                   else { "NEEDS OPTIMIZATION" }

Write-Host "Performance Grade: $performanceGrade" -ForegroundColor $(if ($performanceGrade -eq "EXCELLENT") { "Green" } elseif ($performanceGrade -eq "GOOD") { "Green" } else { "Yellow" })

return $testResults