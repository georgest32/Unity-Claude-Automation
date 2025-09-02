# Test-MultiChannelNotification-Simple.ps1
# Week 3 Day 12 Hour 5-6: Simple Multi-Channel Notification Integration Test
# Validates core functionality without complex module dependencies

param(
    [Parameter(Mandatory = $false)]
    [switch]$GenerateReport = $true
)

Write-Host "=== Simple Multi-Channel Notification Test ===" -ForegroundColor Cyan
Write-Host "Started: $(Get-Date)" -ForegroundColor Gray

$testResults = @{
    TestName = "Simple Multi-Channel Notification Test"
    StartTime = Get-Date
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    Tests = @{}
}

# Test 1: Check if notification preference module can load
try {
    $testResults.TotalTests++
    $testResults.Tests["NotificationPreferences_Load"] = @{ Status = "Running" }
    
    $prefsModulePath = ".\Modules\Unity-Claude-NotificationPreferences\Unity-Claude-NotificationPreferences.psm1"
    if (Test-Path $prefsModulePath) {
        Import-Module $prefsModulePath -Force -Global -ErrorAction Stop
        Write-Host "[PASS] NotificationPreferences module loaded" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["NotificationPreferences_Load"].Status = "Passed"
    }
    else {
        throw "Module file not found"
    }
}
catch {
    Write-Host "[FAIL] NotificationPreferences module load failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["NotificationPreferences_Load"].Status = "Failed"
}

# Test 2: Initialize preferences system
try {
    $testResults.TotalTests++
    $testResults.Tests["NotificationPreferences_Init"] = @{ Status = "Running" }
    
    $initResult = Initialize-NotificationPreferences -EnableUserOverrides
    if ($initResult) {
        Write-Host "[PASS] NotificationPreferences initialized" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["NotificationPreferences_Init"].Status = "Passed"
    }
    else {
        throw "Initialization returned false"
    }
}
catch {
    Write-Host "[FAIL] NotificationPreferences initialization failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["NotificationPreferences_Init"].Status = "Failed"
}

# Test 3: Check Slack integration module
try {
    $testResults.TotalTests++
    $testResults.Tests["SlackIntegration_Load"] = @{ Status = "Running" }
    
    $slackModulePath = ".\Modules\Unity-Claude-SlackIntegration\Unity-Claude-SlackIntegration.psm1"
    if (Test-Path $slackModulePath) {
        Import-Module $slackModulePath -Force -Global -ErrorAction Stop
        Write-Host "[PASS] SlackIntegration module loaded" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["SlackIntegration_Load"].Status = "Passed"
    }
    else {
        throw "Module file not found"
    }
}
catch {
    Write-Host "[FAIL] SlackIntegration module load failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["SlackIntegration_Load"].Status = "Failed"
}

# Test 4: Check Teams integration module
try {
    $testResults.TotalTests++
    $testResults.Tests["TeamsIntegration_Load"] = @{ Status = "Running" }
    
    $teamsModulePath = ".\Modules\Unity-Claude-TeamsIntegration\Unity-Claude-TeamsIntegration.psm1"
    if (Test-Path $teamsModulePath) {
        Import-Module $teamsModulePath -Force -Global -ErrorAction Stop
        Write-Host "[PASS] TeamsIntegration module loaded" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["TeamsIntegration_Load"].Status = "Passed"
    }
    else {
        throw "Module file not found"
    }
}
catch {
    Write-Host "[FAIL] TeamsIntegration module load failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["TeamsIntegration_Load"].Status = "Failed"
}

# Test 5: Validate module structure and files
try {
    $testResults.TotalTests++
    $testResults.Tests["Module_Structure"] = @{ Status = "Running" }
    
    $requiredModules = @(
        "Unity-Claude-NotificationIntegration",
        "Unity-Claude-SlackIntegration", 
        "Unity-Claude-TeamsIntegration",
        "Unity-Claude-NotificationPreferences"
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
    
    if ($modulesFound -eq $requiredModules.Count) {
        Write-Host "[PASS] All required modules present ($modulesFound/$($requiredModules.Count))" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["Module_Structure"].Status = "Passed"
    }
    else {
        throw "Missing modules. Found: $modulesFound/$($requiredModules.Count)"
    }
}
catch {
    Write-Host "[FAIL] Module structure validation failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["Module_Structure"].Status = "Failed"
}

# Test 6: Test configuration file creation
try {
    $testResults.TotalTests++
    $testResults.Tests["Configuration_Files"] = @{ Status = "Running" }
    
    $configPaths = @(
        ".\Config\notification-preferences.json",
        ".\Config\delivery-rules.json", 
        ".\Config\notification-tags.json"
    )
    
    $configsCreated = 0
    foreach ($configPath in $configPaths) {
        if (Test-Path $configPath) {
            $configsCreated++
            Write-Verbose "Configuration file exists: $configPath"
        }
        else {
            Write-Verbose "Configuration file missing: $configPath"
        }
    }
    
    if ($configsCreated -ge 1) {  # At least one config file should exist after initialization
        Write-Host "[PASS] Configuration files created ($configsCreated/$($configPaths.Count))" -ForegroundColor Green
        $testResults.PassedTests++
        $testResults.Tests["Configuration_Files"].Status = "Passed"
    }
    else {
        throw "No configuration files found"
    }
}
catch {
    Write-Host "[FAIL] Configuration file test failed: $($_.Exception.Message)" -ForegroundColor Red
    $testResults.FailedTests++
    $testResults.Tests["Configuration_Files"].Status = "Failed"
}

# Finalize results
$testResults.EndTime = Get-Date
$testResults.Duration = ($testResults.EndTime - $testResults.StartTime).TotalSeconds
$testResults.SuccessRate = if ($testResults.TotalTests -gt 0) {
    [Math]::Round(($testResults.PassedTests / $testResults.TotalTests) * 100, 1)
} else { 0 }

# Display results
Write-Host ""
Write-Host "=== Simple Test Results ===" -ForegroundColor Cyan
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
    $reportPath = ".\MultiChannel-NotificationIntegration-Simple-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $jsonContent = $testResults | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($reportPath, $jsonContent, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Test report saved to: $reportPath" -ForegroundColor Cyan
}

return $testResults