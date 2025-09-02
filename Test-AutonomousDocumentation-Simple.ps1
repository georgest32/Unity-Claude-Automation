# Test-AutonomousDocumentation-Simple.ps1
# Week 3 Day 13 Hour 1-2: Simple Autonomous Documentation System Test
# Validates core functionality that is working without complex cross-module dependencies

param(
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport = $true
)

Write-Host "=== Simple Autonomous Documentation System Test ===" -ForegroundColor Cyan
Write-Host "Started: $(Get-Date)" -ForegroundColor Gray

$testResults = @{
    TestName = "Simple Autonomous Documentation System Test"
    StartTime = Get-Date
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    Tests = @{}
}

# Test 1: Check if autonomous documentation engine module can load
try {
    $testResults.TotalTests++
    $testResults.Tests["AutonomousDocumentationEngine_Load"] = @{ Status = "Running" }
    
    $engineModulePath = ".\Modules\Unity-Claude-AutonomousDocumentationEngine\Unity-Claude-AutonomousDocumentationEngine.psm1"
    if (Test-Path $engineModulePath) {
        Import-Module $engineModulePath -Force -Global -ErrorAction Stop
        Write-Host "[PASS] AutonomousDocumentationEngine module loaded" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["AutonomousDocumentationEngine_Load"].Status = "Passed"
    }
    else {
        throw "Module file not found"
    }
}
catch {
    Write-Host "[FAIL] AutonomousDocumentationEngine module load failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["AutonomousDocumentationEngine_Load"].Status = "Failed"
}

# Test 2: Initialize autonomous documentation engine
try {
    $testResults.TotalTests++
    $testResults.Tests["AutonomousDocumentationEngine_Init"] = @{ Status = "Running" }
    
    $initResult = Initialize-AutonomousDocumentationEngine -EnableQualityMonitoring -AutoDiscoverSystems
    if ($initResult) {
        Write-Host "[PASS] AutonomousDocumentationEngine initialized" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["AutonomousDocumentationEngine_Init"].Status = "Passed"
    }
    else {
        throw "Initialization returned false"
    }
}
catch {
    Write-Host "[FAIL] AutonomousDocumentationEngine initialization failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["AutonomousDocumentationEngine_Init"].Status = "Failed"
}

# Test 3: Check if intelligent triggers module can load
try {
    $testResults.TotalTests++
    $testResults.Tests["IntelligentTriggers_Load"] = @{ Status = "Running" }
    
    $triggersModulePath = ".\Modules\Unity-Claude-IntelligentDocumentationTriggers\Unity-Claude-IntelligentDocumentationTriggers.psm1"
    if (Test-Path $triggersModulePath) {
        Import-Module $triggersModulePath -Force -Global -ErrorAction Stop
        Write-Host "[PASS] IntelligentDocumentationTriggers module loaded" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["IntelligentTriggers_Load"].Status = "Passed"
    }
    else {
        throw "Module file not found"
    }
}
catch {
    Write-Host "[FAIL] IntelligentDocumentationTriggers module load failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["IntelligentTriggers_Load"].Status = "Failed"
}

# Test 4: Initialize intelligent triggers
try {
    $testResults.TotalTests++
    $testResults.Tests["IntelligentTriggers_Init"] = @{ Status = "Running" }
    
    $triggersInit = Initialize-IntelligentDocumentationTriggers -EnableContextAwareness -AutoDiscoverSystems
    if ($triggersInit) {
        Write-Host "[PASS] IntelligentDocumentationTriggers initialized" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["IntelligentTriggers_Init"].Status = "Passed"
    }
    else {
        throw "Initialization returned false"
    }
}
catch {
    Write-Host "[FAIL] IntelligentDocumentationTriggers initialization failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["IntelligentTriggers_Init"].Status = "Failed"
}

# Test 5: Check if documentation versioning module can load
try {
    $testResults.TotalTests++
    $testResults.Tests["DocumentationVersioning_Load"] = @{ Status = "Running" }
    
    $versioningModulePath = ".\Modules\Unity-Claude-DocumentationVersioning\Unity-Claude-DocumentationVersioning.psm1"
    if (Test-Path $versioningModulePath) {
        Import-Module $versioningModulePath -Force -Global -ErrorAction Stop
        Write-Host "[PASS] DocumentationVersioning module loaded" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["DocumentationVersioning_Load"].Status = "Passed"
    }
    else {
        throw "Module file not found"
    }
}
catch {
    Write-Host "[FAIL] DocumentationVersioning module load failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["DocumentationVersioning_Load"].Status = "Failed"
}

# Test 6: Initialize documentation versioning
try {
    $testResults.TotalTests++
    $testResults.Tests["DocumentationVersioning_Init"] = @{ Status = "Running" }
    
    $versioningInit = Initialize-DocumentationVersioning -GitRepositoryPath "." -EnableSemanticVersioning -EnableConventionalCommits
    if ($versioningInit) {
        Write-Host "[PASS] DocumentationVersioning initialized" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["DocumentationVersioning_Init"].Status = "Passed"
    }
    else {
        throw "Initialization returned false"
    }
}
catch {
    Write-Host "[FAIL] DocumentationVersioning initialization failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["DocumentationVersioning_Init"].Status = "Failed"
}

# Test 7: Test intelligent trigger evaluation with existing file
try {
    $testResults.TotalTests++
    $testResults.Tests["Trigger_Evaluation"] = @{ Status = "Running" }
    
    # Use an actual existing file for testing
    $testFile = ".\Modules\Unity-Claude-AlertFeedbackCollector\Unity-Claude-AlertFeedbackCollector.psm1"
    if (Test-Path $testFile) {
        $testChangeInfo = [PSCustomObject]@{
            LinesChanged = 25
            ChangeType = "CodeModification"
            Timestamp = Get-Date
        }
        
        $triggerDecision = Evaluate-IntelligentTrigger -FilePath $testFile -ChangeInfo $testChangeInfo
        if ($triggerDecision) {
            Write-Host "[PASS] Intelligent trigger evaluation working (Decision: $triggerDecision)" -ForegroundColor Green
            $testResults.PassedTests++
            $testResults.Tests["Trigger_Evaluation"].Status = "Passed"
        }
        else {
            throw "Trigger evaluation returned null"
        }
    }
    else {
        throw "Test file not found: $testFile"
    }
}
catch {
    Write-Host "[FAIL] Trigger evaluation test failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["Trigger_Evaluation"].Status = "Failed"
}

# Test 8: Test system integration status
try {
    $testResults.TotalTests++
    $testResults.Tests["System_Integration"] = @{ Status = "Running" }
    
    # Check connected systems
    $autonomousStats = Get-AutonomousDocumentationStatistics
    $triggersStats = Get-IntelligentTriggersStatistics  
    $versioningStats = Get-DocumentationVersioningStatistics
    
    $allInitialized = $autonomousStats.IsInitialized -and $triggersStats.IsInitialized -and $versioningStats.IsInitialized
    
    if ($allInitialized) {
        $connectedCount = ($autonomousStats.ConnectedSystems.Values | Where-Object { $_ }).Count
        Write-Host "[PASS] System integration successful ($connectedCount systems connected)" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["System_Integration"].Status = "Passed"
    }
    else {
        throw "Not all systems properly initialized"
    }
}
catch {
    Write-Host "[FAIL] System integration test failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["System_Integration"].Status = "Failed"
}

# Test 9: Test basic functionality availability
try {
    $testResults.TotalTests++
    $testResults.Tests["Function_Availability"] = @{ Status = "Running" }
    
    $criticalFunctions = @(
        "Initialize-AutonomousDocumentationEngine",
        "Initialize-IntelligentDocumentationTriggers", 
        "Initialize-DocumentationVersioning",
        "Evaluate-IntelligentTrigger",
        "Get-AutonomousDocumentationStatistics"
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

# Test 10: Performance validation
try {
    $testResults.TotalTests++
    $testResults.Tests["Performance_Validation"] = @{ Status = "Running" }
    
    # Test simple operations for performance
    $perfStart = Get-Date
    
    # Test 3 simple operations
    for ($i = 1; $i -le 3; $i++) {
        $testChangeInfo = [PSCustomObject]@{
            LinesChanged = 10
            ChangeType = "CodeModification"
            Timestamp = Get-Date
        }
        
        $triggerResult = Evaluate-IntelligentTrigger -FilePath ".\TestFile$i.psm1" -ChangeInfo $testChangeInfo
        Start-Sleep -Milliseconds 100  # Brief pause
    }
    
    $perfEnd = Get-Date
    $totalTime = ($perfEnd - $perfStart).TotalSeconds
    
    # Performance target: operations should complete quickly
    if ($totalTime -lt 5) {  # 5 seconds for 3 operations
        Write-Host "[PASS] Performance validation successful ($([Math]::Round($totalTime, 1))s for 3 operations)" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["Performance_Validation"].Status = "Passed"
    }
    else {
        throw "Performance too slow: $([Math]::Round($totalTime, 1))s"
    }
}
catch {
    Write-Host "[FAIL] Performance validation failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["Performance_Validation"].Status = "Failed"
}

# Finalize results
$testResults.EndTime = Get-Date
$testResults.Duration = ($testResults.EndTime - $testResults.StartTime).TotalSeconds
$testResults.SuccessRate = if ($testResults.TotalTests -gt 0) {
    [Math]::Round(($testResults.PassedTests / $testResults.TotalTests) * 100, 1)
} else { 0 }

# Display results
Write-Host ""
Write-Host "=== Simple Autonomous Documentation Test Results ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.TotalTests)" -ForegroundColor Gray
Write-Host "Passed: $($testResults.PassedTests)" -ForegroundColor Green
Write-Host "Failed: $($testResults.FailedTests)" -ForegroundColor Red
Write-Host "Success Rate: $($testResults.SuccessRate)%" -ForegroundColor Gray
Write-Host "Duration: $([Math]::Round($testResults.Duration, 1)) seconds" -ForegroundColor Gray

# Determine overall status
$overallStatus = if ($testResults.SuccessRate -ge 90) {
    "SUCCESS"
} elseif ($testResults.SuccessRate -ge 80) {
    "EXCELLENT"
} elseif ($testResults.SuccessRate -ge 70) {
    "GOOD" 
} else {
    "NEEDS_IMPROVEMENT"
}

Write-Host ""
Write-Host "Overall Status: $overallStatus" -ForegroundColor $(
    switch ($overallStatus) {
        'SUCCESS' { 'Green' }
        'EXCELLENT' { 'Green' }
        'GOOD' { 'Yellow' }
        'NEEDS_IMPROVEMENT' { 'Red' }
    }
)

# Generate report if requested
if ($GenerateReport) {
    $reportPath = ".\AutonomousDocumentation-Simple-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $jsonContent = $testResults | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($reportPath, $jsonContent, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Test report saved to: $reportPath" -ForegroundColor Cyan
}

return $testResults