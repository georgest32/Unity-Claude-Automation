# Test-AlertQualitySystem-Simple.ps1
# Week 3 Day 12 Hour 7-8: Simple Alert Quality and Feedback Loop System Test
# Validates core functionality and module loading

param(
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport = $true
)

Write-Host "=== Simple Alert Quality and Feedback Loop System Test ===" -ForegroundColor Cyan
Write-Host "Started: $(Get-Date)" -ForegroundColor Gray

$testResults = @{
    TestName = "Simple Alert Quality System Test"
    StartTime = Get-Date
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    Tests = @{}
}

# Test 1: Check if alert feedback collector module can load
try {
    $testResults.TotalTests++
    $testResults.Tests["AlertFeedbackCollector_Load"] = @{ Status = "Running" }
    
    $feedbackModulePath = ".\Modules\Unity-Claude-AlertFeedbackCollector\Unity-Claude-AlertFeedbackCollector.psm1"
    if (Test-Path $feedbackModulePath) {
        Import-Module $feedbackModulePath -Force -Global -ErrorAction Stop
        Write-Host "[PASS] AlertFeedbackCollector module loaded" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["AlertFeedbackCollector_Load"].Status = "Passed"
    }
    else {
        throw "Module file not found"
    }
}
catch {
    Write-Host "[FAIL] AlertFeedbackCollector module load failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["AlertFeedbackCollector_Load"].Status = "Failed"
}

# Test 2: Check if ML optimizer module can load
try {
    $testResults.TotalTests++
    $testResults.Tests["AlertMLOptimizer_Load"] = @{ Status = "Running" }
    
    $mlModulePath = ".\Modules\Unity-Claude-AlertMLOptimizer\Unity-Claude-AlertMLOptimizer.psm1"
    if (Test-Path $mlModulePath) {
        Import-Module $mlModulePath -Force -Global -ErrorAction Stop
        Write-Host "[PASS] AlertMLOptimizer module loaded" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["AlertMLOptimizer_Load"].Status = "Passed"
    }
    else {
        throw "Module file not found"
    }
}
catch {
    Write-Host "[FAIL] AlertMLOptimizer module load failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["AlertMLOptimizer_Load"].Status = "Failed"
}

# Test 3: Check if analytics module can load
try {
    $testResults.TotalTests++
    $testResults.Tests["AlertAnalytics_Load"] = @{ Status = "Running" }
    
    $analyticsModulePath = ".\Modules\Unity-Claude-AlertAnalytics\Unity-Claude-AlertAnalytics.psm1"
    if (Test-Path $analyticsModulePath) {
        Import-Module $analyticsModulePath -Force -Global -ErrorAction Stop
        Write-Host "[PASS] AlertAnalytics module loaded" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["AlertAnalytics_Load"].Status = "Passed"
    }
    else {
        throw "Module file not found"
    }
}
catch {
    Write-Host "[FAIL] AlertAnalytics module load failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["AlertAnalytics_Load"].Status = "Failed"
}

# Test 4: Check if quality reporting module can load
try {
    $testResults.TotalTests++
    $testResults.Tests["AlertQualityReporting_Load"] = @{ Status = "Running" }
    
    $reportingModulePath = ".\Modules\Unity-Claude-AlertQualityReporting\Unity-Claude-AlertQualityReporting.psm1"
    if (Test-Path $reportingModulePath) {
        Import-Module $reportingModulePath -Force -Global -ErrorAction Stop
        Write-Host "[PASS] AlertQualityReporting module loaded" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["AlertQualityReporting_Load"].Status = "Passed"
    }
    else {
        throw "Module file not found"
    }
}
catch {
    Write-Host "[FAIL] AlertQualityReporting module load failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["AlertQualityReporting_Load"].Status = "Failed"
}

# Test 5: Validate module structure and required directories
try {
    $testResults.TotalTests++
    $testResults.Tests["Module_Structure"] = @{ Status = "Running" }
    
    $requiredModules = @(
        "Unity-Claude-AlertFeedbackCollector",
        "Unity-Claude-AlertMLOptimizer",
        "Unity-Claude-AlertAnalytics",
        "Unity-Claude-AlertQualityReporting"
    )
    
    $modulesFound = 0
    foreach ($module in $requiredModules) {
        $modulePath = ".\Modules\$module\$module.psm1"
        if (Test-Path $modulePath) {
            $modulesFound++
            Write-Verbose "Found module: $module"
        }
        else {
            Write-Warning "Missing module: $module"
        }
    }
    
    # Check required directories
    $requiredDirectories = @(".\Data", ".\Reports", ".\Temp")
    $directoriesCreated = 0
    foreach ($dir in $requiredDirectories) {
        if (Test-Path $dir) {
            $directoriesCreated++
        }
        else {
            # Create directory for future use
            try {
                New-Item -ItemType Directory -Path $dir -Force | Out-Null
                $directoriesCreated++
                Write-Verbose "Created directory: $dir"
            }
            catch {
                Write-Warning "Failed to create directory: $dir"
            }
        }
    }
    
    if ($modulesFound -eq $requiredModules.Count -and $directoriesCreated -eq $requiredDirectories.Count) {
        Write-Host "[PASS] All required modules present and directories available ($modulesFound/$($requiredModules.Count) modules, $directoriesCreated/$($requiredDirectories.Count) directories)" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["Module_Structure"].Status = "Passed"
    }
    else {
        throw "Missing components. Modules: $modulesFound/$($requiredModules.Count), Directories: $directoriesCreated/$($requiredDirectories.Count)"
    }
}
catch {
    Write-Host "[FAIL] Module structure validation failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["Module_Structure"].Status = "Failed"
}

# Test 6: Test function availability
try {
    $testResults.TotalTests++
    $testResults.Tests["Function_Availability"] = @{ Status = "Running" }
    
    $criticalFunctions = @(
        "Initialize-AlertFeedbackCollector",
        "Collect-AlertFeedback",
        "Initialize-AlertMLOptimizer",
        "Optimize-AlertThresholds",
        "Initialize-AlertAnalytics",
        "Analyze-AlertPatterns",
        "Initialize-AlertQualityReporting",
        "Generate-QualityReport"
    )
    
    $functionsAvailable = 0
    foreach ($func in $criticalFunctions) {
        if (Get-Command $func -ErrorAction SilentlyContinue) {
            $functionsAvailable++
            Write-Verbose "Function available: $func"
        }
        else {
            Write-Warning "Function not available: $func"
        }
    }
    
    if ($functionsAvailable -eq $criticalFunctions.Count) {
        Write-Host "[PASS] All critical functions available ($functionsAvailable/$($criticalFunctions.Count))" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["Function_Availability"].Status = "Passed"
    }
    else {
        throw "Missing functions. Available: $functionsAvailable/$($criticalFunctions.Count)"
    }
}
catch {
    Write-Host "[FAIL] Function availability test failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["Function_Availability"].Status = "Failed"
}

# Test 7: Basic initialization test
try {
    $testResults.TotalTests++
    $testResults.Tests["Basic_Initialization"] = @{ Status = "Running" }
    
    $initResults = @{}
    
    # Test feedback collector initialization
    try {
        $feedbackInit = Initialize-AlertFeedbackCollector -AutoDiscoverSystems
        $initResults.FeedbackCollector = $feedbackInit
    }
    catch {
        $initResults.FeedbackCollector = $false
        Write-Warning "FeedbackCollector initialization failed: $($_.Exception.Message)"
    }
    
    # Test ML optimizer initialization
    try {
        $mlInit = Initialize-AlertMLOptimizer
        $initResults.MLOptimizer = $mlInit
    }
    catch {
        $initResults.MLOptimizer = $false
        Write-Warning "MLOptimizer initialization failed: $($_.Exception.Message)"
    }
    
    # Test analytics initialization
    try {
        $analyticsInit = Initialize-AlertAnalytics
        $initResults.Analytics = $analyticsInit
    }
    catch {
        $initResults.Analytics = $false
        Write-Warning "Analytics initialization failed: $($_.Exception.Message)"
    }
    
    # Test quality reporting initialization
    try {
        $reportingInit = Initialize-AlertQualityReporting
        $initResults.QualityReporting = $reportingInit
    }
    catch {
        $initResults.QualityReporting = $false
        Write-Warning "QualityReporting initialization failed: $($_.Exception.Message)"
    }
    
    $successfulInits = ($initResults.Values | Where-Object { $_ }).Count
    $totalInits = $initResults.Count
    
    if ($successfulInits -ge 3) {  # At least 3 out of 4 should initialize
        Write-Host "[PASS] Basic initialization successful ($successfulInits/$totalInits systems)" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["Basic_Initialization"].Status = "Passed"
    }
    else {
        throw "Too many initialization failures. Successful: $successfulInits/$totalInits"
    }
}
catch {
    Write-Host "[FAIL] Basic initialization test failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["Basic_Initialization"].Status = "Failed"
}

# Finalize results
$testResults.EndTime = Get-Date
$testResults.Duration = ($testResults.EndTime - $testResults.StartTime).TotalSeconds
$testResults.SuccessRate = if ($testResults.TotalTests -gt 0) {
    [Math]::Round(($testResults.PassedTests / $testResults.TotalTests) * 100, 1)
} else { 0 }

# Display results
Write-Host ""
Write-Host "=== Simple Alert Quality System Test Results ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.TotalTests)" -ForegroundColor Gray
Write-Host "Passed: $($testResults.PassedTests)" -ForegroundColor Green
Write-Host "Failed: $($testResults.FailedTests)" -ForegroundColor Red
Write-Host "Success Rate: $($testResults.SuccessRate)%" -ForegroundColor Gray
Write-Host "Duration: $([Math]::Round($testResults.Duration, 1)) seconds" -ForegroundColor Gray

# Determine overall status
$overallStatus = if ($testResults.SuccessRate -ge 80) {
    "SUCCESS"
} elseif ($testResults.SuccessRate -ge 60) {
    "PARTIAL"
} else {
    "FAILED"
}

Write-Host ""
Write-Host "Overall Status: $overallStatus" -ForegroundColor $(
    switch ($overallStatus) {
        'SUCCESS' { 'Green' }
        'PARTIAL' { 'Yellow' }
        'FAILED' { 'Red' }
    }
)

# Generate report if requested
if ($GenerateReport) {
    $reportPath = ".\AlertQuality-FeedbackLoop-Simple-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $jsonContent = $testResults | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($reportPath, $jsonContent, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Test report saved to: $reportPath" -ForegroundColor Cyan
}

return $testResults