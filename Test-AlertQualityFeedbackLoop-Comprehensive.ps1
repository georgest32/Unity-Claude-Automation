# Test-AlertQualityFeedbackLoop-Comprehensive.ps1
# Week 3 Day 12 Hour 7-8: Comprehensive Alert Quality and Feedback Loop System Test
# Tests all components: FeedbackCollector, MLOptimizer, Analytics, and QualityReporting
# Research-validated test scenarios for feedback-driven quality enhancement

param(
    [Parameter(Mandatory = $false)]
    [switch]$TestMode = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeMLTests = $false,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeDashboardTests = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateDetailedReport = $true
)

# Test results tracking
$script:TestResults = @{
    TestName = "Alert Quality and Feedback Loop Comprehensive Test"
    StartTime = Get-Date
    EndTime = $null
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    Modules = @{
        AlertFeedbackCollector = @{ Tests = @{}; Status = "Pending" }
        AlertMLOptimizer = @{ Tests = @{}; Status = "Pending" }
        AlertAnalytics = @{ Tests = @{}; Status = "Pending" }
        AlertQualityReporting = @{ Tests = @{}; Status = "Pending" }
    }
    OverallStatus = "Running"
    Errors = @()
    Performance = @{
        FeedbackCollectionTime = 0
        OptimizationTime = 0
        AnalyticsTime = 0
        ReportingTime = 0
    }
}

Write-Host "=== Alert Quality and Feedback Loop Comprehensive Test ===" -ForegroundColor Cyan
Write-Host "Test Mode: $TestMode" -ForegroundColor Gray
Write-Host "Include ML Tests: $IncludeMLTests" -ForegroundColor Gray
Write-Host "Include Dashboard Tests: $IncludeDashboardTests" -ForegroundColor Gray
Write-Host "Started: $($script:TestResults.StartTime)" -ForegroundColor Gray
Write-Host ""

# Helper function for feedback loop verification (defined early for availability)
function Verify-FeedbackLoopCompletion {
    param($TestAlert, $FeedbackResult, $QualityReport)
    
    try {
        Write-Verbose "Verifying feedback loop completion for alert: $($TestAlert.Id)"
        
        # Check if feedback was collected
        if (-not $FeedbackResult) {
            Write-Verbose "Feedback collection failed"
            return $false
        }
        
        # Check if quality report was generated
        if (-not $QualityReport) {
            Write-Verbose "Quality report generation failed"
            return $false
        }
        
        # Check if quality metrics were calculated
        if (-not $QualityReport.QualityMetrics) {
            Write-Verbose "Quality metrics not found in report"
            return $false
        }
        
        # Verify feedback loop integration
        $feedbackInReport = $QualityReport.QualityMetrics.PrecisionRecall.TotalAlerts -gt 0
        
        Write-Verbose "Feedback loop completion verified: $feedbackInReport"
        return $feedbackInReport
    }
    catch {
        Write-Verbose "Exception in feedback loop verification: $($_.Exception.Message)"
        return $false
    }
}

# Function to run test with error handling and result tracking
function Invoke-TestWithTracking {
    param(
        [string]$TestName,
        [string]$ModuleName,
        [scriptblock]$TestScript
    )
    
    Write-Host "Running test: $TestName..." -ForegroundColor Yellow
    $script:TestResults.TotalTests++
    
    try {
        $testStart = Get-Date
        $result = & $TestScript
        $testEnd = Get-Date
        $duration = ($testEnd - $testStart).TotalMilliseconds
        
        if ($result) {
            $script:TestResults.PassedTests++
            $script:TestResults.Modules[$ModuleName].Tests[$TestName] = @{
                Status = "Passed"
                Duration = $duration
                Result = $result
            }
            Write-Host "[PASS] $TestName - PASSED ($([Math]::Round($duration, 0))ms)" -ForegroundColor Green
        }
        else {
            $script:TestResults.FailedTests++
            $script:TestResults.Modules[$ModuleName].Tests[$TestName] = @{
                Status = "Failed"
                Duration = $duration
                Result = $result
                Error = "Test returned false"
            }
            Write-Host "[FAIL] $TestName - FAILED ($([Math]::Round($duration, 0))ms)" -ForegroundColor Red
        }
    }
    catch {
        $script:TestResults.FailedTests++
        $script:TestResults.Modules[$ModuleName].Tests[$TestName] = @{
            Status = "Error"
            Duration = 0
            Result = $null
            Error = $_.Exception.Message
        }
        $script:TestResults.Errors += "[$TestName] $($_.Exception.Message)"
        Write-Host "[ERROR] $TestName - ERROR: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Test 1: Load and initialize alert feedback collector module
Invoke-TestWithTracking -TestName "Load AlertFeedbackCollector Module" -ModuleName "AlertFeedbackCollector" -TestScript {
    try {
        $modulePath = ".\Modules\Unity-Claude-AlertFeedbackCollector\Unity-Claude-AlertFeedbackCollector.psm1"
        if (-not (Test-Path $modulePath)) {
            throw "Module file not found: $modulePath"
        }
        
        Import-Module $modulePath -Force -Global
        
        # Verify key functions are available
        $requiredFunctions = @(
            'Initialize-AlertFeedbackCollector',
            'Collect-AlertFeedback',
            'Test-AlertFeedbackSystem'
        )
        
        foreach ($func in $requiredFunctions) {
            if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                throw "Required function not found: $func"
            }
        }
        
        Write-Verbose "AlertFeedbackCollector module loaded with all required functions"
        return $true
    }
    catch {
        throw "Failed to load AlertFeedbackCollector module: $($_.Exception.Message)"
    }
}

# Test 2: Initialize feedback collection system
Invoke-TestWithTracking -TestName "Initialize AlertFeedbackCollector" -ModuleName "AlertFeedbackCollector" -TestScript {
    try {
        $performanceStart = Get-Date
        $result = Initialize-AlertFeedbackCollector -EnableAutomatedSurveys -AutoDiscoverSystems
        $script:TestResults.Performance.FeedbackCollectionTime = ((Get-Date) - $performanceStart).TotalMilliseconds
        
        if (-not $result) {
            throw "Initialization returned false"
        }
        
        Write-Verbose "AlertFeedbackCollector system initialized successfully"
        return $true
    }
    catch {
        throw "Failed to initialize AlertFeedbackCollector: $($_.Exception.Message)"
    }
}

# Test 3: Test feedback collection system
Invoke-TestWithTracking -TestName "AlertFeedbackCollector System Test" -ModuleName "AlertFeedbackCollector" -TestScript {
    try {
        $result = Test-AlertFeedbackSystem
        
        if (-not $result -or $result.SuccessRate -lt 75) {
            throw "Feedback system test failed. Success rate: $($result.SuccessRate)%"
        }
        
        Write-Verbose "AlertFeedbackCollector system test passed with $($result.SuccessRate)% success rate"
        return $true
    }
    catch {
        throw "AlertFeedbackCollector system test failed: $($_.Exception.Message)"
    }
}

# Test 4: Load and test ML optimizer (if enabled)
if ($IncludeMLTests) {
    Invoke-TestWithTracking -TestName "Load AlertMLOptimizer Module" -ModuleName "AlertMLOptimizer" -TestScript {
        try {
            $modulePath = ".\Modules\Unity-Claude-AlertMLOptimizer\Unity-Claude-AlertMLOptimizer.psm1"
            if (-not (Test-Path $modulePath)) {
                throw "Module file not found: $modulePath"
            }
            
            Import-Module $modulePath -Force -Global
            
            # Initialize ML optimizer
            $result = Initialize-AlertMLOptimizer -IntegrationMethod "Subprocess"
            
            if (-not $result) {
                throw "ML optimizer initialization failed"
            }
            
            Write-Verbose "AlertMLOptimizer module loaded and initialized"
            return $true
        }
        catch {
            throw "Failed to load AlertMLOptimizer: $($_.Exception.Message)"
        }
    }
    
    Invoke-TestWithTracking -TestName "AlertMLOptimizer System Test" -ModuleName "AlertMLOptimizer" -TestScript {
        try {
            $performanceStart = Get-Date
            $result = Test-AlertMLOptimizer
            $script:TestResults.Performance.OptimizationTime = ((Get-Date) - $performanceStart).TotalMilliseconds
            
            if (-not $result -or $result.SuccessRate -lt 70) {
                throw "ML optimizer test failed. Success rate: $($result.SuccessRate)%"
            }
            
            Write-Verbose "AlertMLOptimizer test passed with $($result.SuccessRate)% success rate"
            return $true
        }
        catch {
            throw "AlertMLOptimizer test failed: $($_.Exception.Message)"
        }
    }
}

# Test 5: Load and test alert analytics module
Invoke-TestWithTracking -TestName "Load AlertAnalytics Module" -ModuleName "AlertAnalytics" -TestScript {
    try {
        $modulePath = ".\Modules\Unity-Claude-AlertAnalytics\Unity-Claude-AlertAnalytics.psm1"
        if (-not (Test-Path $modulePath)) {
            throw "Module file not found: $modulePath"
        }
        
        Import-Module $modulePath -Force -Global
        
        # Initialize analytics system
        $result = Initialize-AlertAnalytics -EnableRealTimeProcessing -EnablePatternRecognition
        
        if (-not $result) {
            throw "Analytics initialization failed"
        }
        
        Write-Verbose "AlertAnalytics module loaded and initialized"
        return $true
    }
    catch {
        throw "Failed to load AlertAnalytics: $($_.Exception.Message)"
    }
}

# Test 6: Test analytics system
Invoke-TestWithTracking -TestName "AlertAnalytics System Test" -ModuleName "AlertAnalytics" -TestScript {
    try {
        $performanceStart = Get-Date
        $result = Test-AlertAnalytics
        $script:TestResults.Performance.AnalyticsTime = ((Get-Date) - $performanceStart).TotalMilliseconds
        
        if (-not $result -or $result.SuccessRate -lt 75) {
            throw "Analytics system test failed. Success rate: $($result.SuccessRate)%"
        }
        
        Write-Verbose "AlertAnalytics test passed with $($result.SuccessRate)% success rate"
        return $true
    }
    catch {
        throw "AlertAnalytics test failed: $($_.Exception.Message)"
    }
}

# Test 7: Load and test quality reporting module
Invoke-TestWithTracking -TestName "Load AlertQualityReporting Module" -ModuleName "AlertQualityReporting" -TestScript {
    try {
        $modulePath = ".\Modules\Unity-Claude-AlertQualityReporting\Unity-Claude-AlertQualityReporting.psm1"
        if (-not (Test-Path $modulePath)) {
            throw "Module file not found: $modulePath"
        }
        
        Import-Module $modulePath -Force -Global
        
        # Initialize quality reporting system
        $result = Initialize-AlertQualityReporting -DashboardIntegration:$IncludeDashboardTests -EnableRealTimeUpdates -AutoDiscoverSystems
        
        if (-not $result) {
            throw "Quality reporting initialization failed"
        }
        
        Write-Verbose "AlertQualityReporting module loaded and initialized"
        return $true
    }
    catch {
        throw "Failed to load AlertQualityReporting: $($_.Exception.Message)"
    }
}

# Test 8: Test quality reporting system
Invoke-TestWithTracking -TestName "AlertQualityReporting System Test" -ModuleName "AlertQualityReporting" -TestScript {
    try {
        $performanceStart = Get-Date
        $result = Test-AlertQualityReporting
        $script:TestResults.Performance.ReportingTime = ((Get-Date) - $performanceStart).TotalMilliseconds
        
        if (-not $result -or $result.SuccessRate -lt 75) {
            throw "Quality reporting test failed. Success rate: $($result.SuccessRate)%"
        }
        
        Write-Verbose "AlertQualityReporting test passed with $($result.SuccessRate)% success rate"
        return $true
    }
    catch {
        throw "AlertQualityReporting test failed: $($_.Exception.Message)"
    }
}

# Test 9: End-to-end feedback loop test
Invoke-TestWithTracking -TestName "End-to-End Feedback Loop Test" -ModuleName "AlertQualityReporting" -TestScript {
    try {
        Write-Host "Running comprehensive end-to-end feedback loop test..." -ForegroundColor Blue
        
        # Step 1: Create test alert
        $testAlert = [PSCustomObject]@{
            Id = [Guid]::NewGuid().ToString()
            Severity = "High"
            Source = "FeedbackLoopTest"
            Component = "EndToEndValidation"
            Message = "Comprehensive test of alert quality and feedback loop system"
            Timestamp = Get-Date
            Classification = [PSCustomObject]@{
                Severity = "High"
                Category = "Quality"
                Priority = 2
                Confidence = 0.95
            }
        }
        
        # Step 2: Collect feedback
        $feedbackResult = Collect-AlertFeedback -AlertId $testAlert.Id -UserRating Good -AlertOutcome Actionable -Comments "End-to-end test feedback" -ResponseTime 900
        
        if (-not $feedbackResult) {
            throw "Feedback collection failed in end-to-end test"
        }
        
        # Step 3: Generate quality report
        $qualityReport = Generate-QualityReport -ReportType Daily -AlertSources @("FeedbackLoopTest") -IncludeDashboardUpdate:$IncludeDashboardTests
        
        if (-not $qualityReport) {
            throw "Quality report generation failed in end-to-end test"
        }
        
        # Step 4: Verify feedback loop completion
        $feedbackLoopComplete = Verify-FeedbackLoopCompletion -TestAlert $testAlert -FeedbackResult $feedbackResult -QualityReport $qualityReport
        
        if (-not $feedbackLoopComplete) {
            throw "Feedback loop completion verification failed"
        }
        
        Write-Verbose "End-to-end feedback loop test completed successfully"
        return $true
    }
    catch {
        throw "End-to-end feedback loop test failed: $($_.Exception.Message)"
    }
}

# Test 10: Performance and scalability test
Invoke-TestWithTracking -TestName "Performance and Scalability Test" -ModuleName "AlertQualityReporting" -TestScript {
    try {
        Write-Host "Running performance and scalability test..." -ForegroundColor Yellow
        
        $performanceResults = @{
            FeedbackEntriesProcessed = 0
            QualityReportsGenerated = 0
            TotalTime = 0
            AverageProcessingTime = 0
            Errors = 0
        }
        
        $startTime = Get-Date
        
        # Process multiple feedback entries to test scalability
        for ($i = 1; $i -le 20; $i++) {
            try {
                $testAlert = [PSCustomObject]@{
                    Id = [Guid]::NewGuid().ToString()
                    Severity = @("Critical", "High", "Medium", "Low")[(Get-Random -Maximum 4)]
                    Source = "PerformanceTest"
                    Component = "Test$i"
                    Message = "Performance test alert #$i"
                    Timestamp = Get-Date
                }
                
                $entryStart = Get-Date
                # Use string values instead of enum types for PowerShell 5.1 compatibility
                $ratingValues = @("VeryPoor", "Poor", "Fair", "Good", "Excellent")
                $outcomeValues = @("Actionable", "Informational", "FalsePositive", "TruePositive", "Noise", "Critical")
                $randomRating = $ratingValues[(Get-Random -Maximum $ratingValues.Count)]
                $randomOutcome = $outcomeValues[(Get-Random -Maximum $outcomeValues.Count)]
                
                $feedbackResult = Collect-AlertFeedback -AlertId $testAlert.Id -UserRating $randomRating -AlertOutcome $randomOutcome
                $entryEnd = Get-Date
                
                $performanceResults.FeedbackEntriesProcessed++
                $performanceResults.TotalTime += ($entryEnd - $entryStart).TotalMilliseconds
                
                if (-not $feedbackResult) {
                    $performanceResults.Errors++
                }
                
                # Brief pause to prevent overwhelming the system
                Start-Sleep -Milliseconds 50
            }
            catch {
                $performanceResults.Errors++
                Write-Warning "Performance test entry $i failed: $($_.Exception.Message)"
            }
        }
        
        # Generate performance report
        $reportResult = Generate-QualityReport -ReportType Custom -AlertSources @("PerformanceTest")
        if ($reportResult) {
            $performanceResults.QualityReportsGenerated++
        }
        
        $endTime = Get-Date
        $totalTestTime = ($endTime - $startTime).TotalSeconds
        
        # Calculate metrics
        if ($performanceResults.FeedbackEntriesProcessed -gt 0) {
            $performanceResults.AverageProcessingTime = $performanceResults.TotalTime / $performanceResults.FeedbackEntriesProcessed
        }
        
        # Validate performance targets (research-validated < 30 second response time)
        if ($performanceResults.AverageProcessingTime -gt 5000) {  # 5 seconds per feedback entry
            throw "Performance target not met. Average time: $($performanceResults.AverageProcessingTime)ms per entry"
        }
        
        if ($performanceResults.Errors -gt 3) {  # Allow some errors in performance testing
            throw "Too many errors in performance test: $($performanceResults.Errors)"
        }
        
        Write-Host "Performance test completed:" -ForegroundColor Green
        Write-Host "- Feedback entries processed: $($performanceResults.FeedbackEntriesProcessed)" -ForegroundColor Gray
        Write-Host "- Average time per entry: $([Math]::Round($performanceResults.AverageProcessingTime, 1))ms" -ForegroundColor Gray
        Write-Host "- Quality reports generated: $($performanceResults.QualityReportsGenerated)" -ForegroundColor Gray
        Write-Host "- Total test time: $([Math]::Round($totalTestTime, 1))s" -ForegroundColor Gray
        Write-Host "- Errors: $($performanceResults.Errors)" -ForegroundColor Gray
        
        return $true
    }
    catch {
        throw "Performance test failed: $($_.Exception.Message)"
    }
}

# Test 11: Integration validation test
Invoke-TestWithTracking -TestName "System Integration Validation" -ModuleName "AlertQualityReporting" -TestScript {
    try {
        Write-Host "Validating system integration..." -ForegroundColor Blue
        
        # Check if all modules can work together
        $integrationChecks = @{
            FeedbackToAnalytics = $false
            AnalyticsToOptimizer = $false
            OptimizerToReporting = $false
            ReportingToDashboard = $false
        }
        
        # Test 1: Feedback to Analytics integration
        try {
            # Simulate feedback collection and analytics processing
            $testAlert = [PSCustomObject]@{
                Id = [Guid]::NewGuid().ToString()
                Severity = "Medium"
                Source = "IntegrationTest"
                Component = "SystemIntegration"
                Message = "Integration validation test alert"
                Timestamp = Get-Date
            }
            
            $feedbackResult = Collect-AlertFeedback -AlertId $testAlert.Id -UserRating Fair -AlertOutcome Informational
            $analyticsResult = Analyze-AlertPatterns -AlertSource "IntegrationTest" -AnalysisWindow Short
            
            $integrationChecks.FeedbackToAnalytics = ($feedbackResult -and $analyticsResult)
        }
        catch {
            Write-Warning "Feedback to Analytics integration test failed: $($_.Exception.Message)"
        }
        
        # Test 2: Analytics to Optimizer integration (if ML tests enabled)
        if ($IncludeMLTests) {
            try {
                $optimizerResult = Optimize-AlertThresholds -AlertSource "IntegrationTest" -OptimizationMethod AdaptiveThreshold
                $integrationChecks.AnalyticsToOptimizer = ($null -ne $optimizerResult)
            }
            catch {
                Write-Warning "Analytics to Optimizer integration test failed: $($_.Exception.Message)"
            }
        }
        else {
            $integrationChecks.AnalyticsToOptimizer = $null  # Not tested
        }
        
        # Test 3: Optimizer to Reporting integration
        try {
            $qualityReport = Generate-QualityReport -ReportType Custom -AlertSources @("IntegrationTest")
            $integrationChecks.OptimizerToReporting = ($null -ne $qualityReport)
        }
        catch {
            Write-Warning "Optimizer to Reporting integration test failed: $($_.Exception.Message)"
        }
        
        # Test 4: Reporting to Dashboard integration
        if ($IncludeDashboardTests) {
            try {
                # Check if dashboard data was generated
                $dashboardDataPath = ".\Visualization\public\static\data\quality-metrics.json"
                $integrationChecks.ReportingToDashboard = (Test-Path $dashboardDataPath)
            }
            catch {
                Write-Warning "Reporting to Dashboard integration test failed: $($_.Exception.Message)"
            }
        }
        else {
            $integrationChecks.ReportingToDashboard = $null  # Not tested
        }
        
        # Evaluate integration success
        $testedIntegrations = $integrationChecks.Values | Where-Object { $null -ne $_ }
        $successfulIntegrations = ($testedIntegrations | Where-Object { $_ }).Count
        $totalIntegrations = $testedIntegrations.Count
        
        if ($totalIntegrations -eq 0) {
            throw "No integrations could be tested"
        }
        
        $integrationSuccessRate = [Math]::Round(($successfulIntegrations / $totalIntegrations) * 100, 1)
        
        if ($integrationSuccessRate -lt 75) {
            throw "Integration success rate too low: $integrationSuccessRate%"
        }
        
        Write-Host "System integration validation completed:" -ForegroundColor Green
        Write-Host "- Successful integrations: $successfulIntegrations/$totalIntegrations" -ForegroundColor Gray
        Write-Host "- Integration success rate: $integrationSuccessRate%" -ForegroundColor Gray
        
        return $true
    }
    catch {
        throw "System integration validation failed: $($_.Exception.Message)"
    }
}

# Duplicate function removed - already defined at line 52

# Update module statuses based on test results
foreach ($moduleName in $script:TestResults.Modules.Keys) {
    $moduleTests = $script:TestResults.Modules[$moduleName].Tests
    if ($moduleTests.Count -gt 0) {
        $passedCount = ($moduleTests.Values | Where-Object { $_.Status -eq "Passed" }).Count
        $totalCount = $moduleTests.Count
        
        if ($passedCount -eq $totalCount) {
            $script:TestResults.Modules[$moduleName].Status = "Passed"
        }
        elseif ($passedCount -gt 0) {
            $script:TestResults.Modules[$moduleName].Status = "Partial"
        }
        else {
            $script:TestResults.Modules[$moduleName].Status = "Failed"
        }
    }
}

# Finalize test results
$script:TestResults.EndTime = Get-Date
$script:TestResults.TotalDuration = ($script:TestResults.EndTime - $script:TestResults.StartTime).TotalSeconds
$script:TestResults.SuccessRate = if ($script:TestResults.TotalTests -gt 0) {
    [Math]::Round(($script:TestResults.PassedTests / $script:TestResults.TotalTests) * 100, 1)
} else { 0 }

# Determine overall status
if ($script:TestResults.SuccessRate -ge 90) {
    $script:TestResults.OverallStatus = "Success"
}
elseif ($script:TestResults.SuccessRate -ge 70) {
    $script:TestResults.OverallStatus = "Partial"
}
else {
    $script:TestResults.OverallStatus = "Failed"
}

# Display final results
Write-Host "=== Alert Quality and Feedback Loop Test Results ===" -ForegroundColor Cyan
Write-Host "Overall Status: $($script:TestResults.OverallStatus)" -ForegroundColor $(
    switch ($script:TestResults.OverallStatus) {
        'Success' { 'Green' }
        'Partial' { 'Yellow' }
        'Failed' { 'Red' }
    }
)
Write-Host "Total Tests: $($script:TestResults.TotalTests)" -ForegroundColor Gray
Write-Host "Passed: $($script:TestResults.PassedTests)" -ForegroundColor Green
Write-Host "Failed: $($script:TestResults.FailedTests)" -ForegroundColor Red
Write-Host "Success Rate: $($script:TestResults.SuccessRate)%" -ForegroundColor Gray
Write-Host "Duration: $([Math]::Round($script:TestResults.TotalDuration, 1)) seconds" -ForegroundColor Gray

# Performance metrics
Write-Host ""
Write-Host "Performance Metrics:" -ForegroundColor Cyan
Write-Host "- Feedback Collection: $([Math]::Round($script:TestResults.Performance.FeedbackCollectionTime, 0))ms" -ForegroundColor Gray
Write-Host "- Analytics Processing: $([Math]::Round($script:TestResults.Performance.AnalyticsTime, 0))ms" -ForegroundColor Gray
Write-Host "- Quality Reporting: $([Math]::Round($script:TestResults.Performance.ReportingTime, 0))ms" -ForegroundColor Gray

if ($IncludeMLTests) {
    Write-Host "- ML Optimization: $([Math]::Round($script:TestResults.Performance.OptimizationTime, 0))ms" -ForegroundColor Gray
}

# Module-specific results
Write-Host ""
Write-Host "Module Results:" -ForegroundColor Cyan
foreach ($moduleName in $script:TestResults.Modules.Keys) {
    $moduleResult = $script:TestResults.Modules[$moduleName]
    $color = switch ($moduleResult.Status) {
        'Passed' { 'Green' }
        'Partial' { 'Yellow' }
        'Failed' { 'Red' }
        'Pending' { 'Gray' }
    }
    Write-Host "- $moduleName : $($moduleResult.Status) ($($moduleResult.Tests.Count) tests)" -ForegroundColor $color
}

# Display errors if any
if ($script:TestResults.Errors.Count -gt 0) {
    Write-Host ""
    Write-Host "Errors:" -ForegroundColor Red
    foreach ($errorItem in $script:TestResults.Errors) {
        Write-Host "- $errorItem" -ForegroundColor Red
    }
}

# Generate detailed report if requested
if ($GenerateDetailedReport) {
    $reportPath = ".\AlertQuality-FeedbackLoop-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $jsonContent = $script:TestResults | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($reportPath, $jsonContent, [System.Text.UTF8Encoding]::new($false))
    
    Write-Host ""
    Write-Host "Detailed test report saved to: $reportPath" -ForegroundColor Cyan
}

# Research-validated success criteria
$researchCriteria = @{
    "False Positive Reduction" = "Target: 30-40% reduction (Enterprise 2025 standard)"
    "Response Time Improvement" = "Target: 30% improvement (Research-validated)"
    "User Satisfaction" = "Target: 70+ CSAT score (NPS/CSAT enterprise standard)"
    "System Integration" = "Target: 75%+ integration success rate"
    "Performance" = "Target: < 5 seconds per feedback entry processing"
}

Write-Host ""
Write-Host "Research-Validated Success Criteria:" -ForegroundColor Cyan
foreach ($criterion in $researchCriteria.GetEnumerator()) {
    Write-Host "- $($criterion.Key): $($criterion.Value)" -ForegroundColor Gray
}

# Return test results for programmatic access
return $script:TestResults