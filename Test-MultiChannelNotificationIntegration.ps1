# Test-MultiChannelNotificationIntegration.ps1
# Week 3 Day 12 Hour 5-6: Multi-Channel Notification Integration Comprehensive Test
# Tests all components: NotificationIntegration, Slack, Teams, and Preferences
# Research-validated test scenarios for 2025 compliance

param(
    [Parameter(Mandatory = $false)]
    [switch]$TestMode = $true,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeSlackTests = $false,
    
    [Parameter(Mandatory = $false)]
    [switch]$IncludeTeamsTests = $false,
    
    [Parameter(Mandatory = $false)]
    [switch]$GenerateDetailedReport = $true
)

# Test results tracking
$script:TestResults = @{
    TestName = "Multi-Channel Notification Integration Test"
    StartTime = Get-Date
    EndTime = $null
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    Modules = @{
        NotificationIntegration = @{ Tests = @{}; Status = "Pending" }
        SlackIntegration = @{ Tests = @{}; Status = "Pending" }
        TeamsIntegration = @{ Tests = @{}; Status = "Pending" }
        NotificationPreferences = @{ Tests = @{}; Status = "Pending" }
    }
    OverallStatus = "Running"
    Errors = @()
}

Write-Host "=== Multi-Channel Notification Integration Test ===" -ForegroundColor Cyan
Write-Host "Test Mode: $TestMode" -ForegroundColor Gray
Write-Host "Include Slack Tests: $IncludeSlackTests" -ForegroundColor Gray  
Write-Host "Include Teams Tests: $IncludeTeamsTests" -ForegroundColor Gray
Write-Host "Started: $($script:TestResults.StartTime)" -ForegroundColor Gray
Write-Host ""

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

# Test 1: Load and initialize notification integration module
Invoke-TestWithTracking -TestName "Load NotificationIntegration Module" -ModuleName "NotificationIntegration" -TestScript {
    try {
        $modulePath = ".\Modules\Unity-Claude-NotificationIntegration\Unity-Claude-NotificationIntegration.psm1"
        if (-not (Test-Path $modulePath)) {
            throw "Module file not found: $modulePath"
        }
        
        Import-Module $modulePath -Force -Global
        
        # Verify key functions are available
        $requiredFunctions = @(
            'Initialize-NotificationIntegration',
            'Send-NotificationMultiChannel',
            'Test-NotificationDeliveryMultiChannel'
        )
        
        foreach ($func in $requiredFunctions) {
            if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                throw "Required function not found: $func"
            }
        }
        
        Write-Verbose "NotificationIntegration module loaded with all required functions"
        return $true
    }
    catch {
        throw "Failed to load NotificationIntegration module: $($_.Exception.Message)"
    }
}

# Test 2: Initialize notification integration system
Invoke-TestWithTracking -TestName "Initialize NotificationIntegration" -ModuleName "NotificationIntegration" -TestScript {
    try {
        $result = Initialize-NotificationIntegration -AutoDiscoverChannels
        
        if (-not $result) {
            throw "Initialization returned false"
        }
        
        Write-Verbose "NotificationIntegration system initialized successfully"
        return $true
    }
    catch {
        throw "Failed to initialize NotificationIntegration: $($_.Exception.Message)"
    }
}

# Test 3: Test multi-channel delivery system
Invoke-TestWithTracking -TestName "Multi-Channel Delivery Test" -ModuleName "NotificationIntegration" -TestScript {
    try {
        $result = Test-NotificationDeliveryMultiChannel
        
        if (-not $result -or $result.SuccessRate -lt 80) {
            throw "Multi-channel delivery test failed. Success rate: $($result.SuccessRate)%"
        }
        
        Write-Verbose "Multi-channel delivery test passed with $($result.SuccessRate)% success rate"
        return $true
    }
    catch {
        throw "Multi-channel delivery test failed: $($_.Exception.Message)"
    }
}

# Test 4: Load notification preferences module
Invoke-TestWithTracking -TestName "Load NotificationPreferences Module" -ModuleName "NotificationPreferences" -TestScript {
    try {
        $modulePath = ".\Modules\Unity-Claude-NotificationPreferences\Unity-Claude-NotificationPreferences.psm1"
        if (-not (Test-Path $modulePath)) {
            throw "Module file not found: $modulePath"
        }
        
        Import-Module $modulePath -Force -Global
        
        # Verify key functions are available
        $requiredFunctions = @(
            'Initialize-NotificationPreferences',
            'Get-NotificationPreferencesForUser',
            'Get-DeliveryChannelsForAlert'
        )
        
        foreach ($func in $requiredFunctions) {
            if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
                throw "Required function not found: $func"
            }
        }
        
        Write-Verbose "NotificationPreferences module loaded with all required functions"
        return $true
    }
    catch {
        throw "Failed to load NotificationPreferences module: $($_.Exception.Message)"
    }
}

# Test 5: Initialize and test notification preferences
Invoke-TestWithTracking -TestName "Initialize NotificationPreferences" -ModuleName "NotificationPreferences" -TestScript {
    try {
        $result = Initialize-NotificationPreferences -EnableUserOverrides
        
        if (-not $result) {
            throw "Preferences initialization returned false"
        }
        
        # Test preferences system
        $prefsTest = Test-NotificationPreferences
        
        if (-not $prefsTest -or $prefsTest.SuccessRate -lt 75) {
            throw "Preferences test failed. Success rate: $($prefsTest.SuccessRate)%"
        }
        
        Write-Verbose "NotificationPreferences system initialized and tested successfully"
        return $true
    }
    catch {
        throw "Failed to initialize and test NotificationPreferences: $($_.Exception.Message)"
    }
}

# Test 6: Slack integration (if enabled)
if ($IncludeSlackTests) {
    Invoke-TestWithTracking -TestName "Load Slack Integration Module" -ModuleName "SlackIntegration" -TestScript {
        try {
            $modulePath = ".\Modules\Unity-Claude-SlackIntegration\Unity-Claude-SlackIntegration.psm1"
            if (-not (Test-Path $modulePath)) {
                throw "Module file not found: $modulePath"
            }
            
            Import-Module $modulePath -Force -Global
            
            # Initialize with test webhook (would need real webhook for actual testing)
            $testWebhook = "https://hooks.slack.com/services/TEST/TEST/TEST"
            $result = Initialize-SlackIntegration -WebhookUrl $testWebhook -DefaultChannel "#test-alerts"
            
            if (-not $result) {
                throw "Slack initialization failed"
            }
            
            Write-Verbose "Slack integration module loaded and initialized"
            return $true
        }
        catch {
            throw "Failed to load Slack integration: $($_.Exception.Message)"
        }
    }
    
    Invoke-TestWithTracking -TestName "Slack Integration Test" -ModuleName "SlackIntegration" -TestScript {
        try {
            $result = Test-SlackIntegration
            
            if (-not $result -or $result.SuccessRate -lt 100) {
                throw "Slack integration test failed. Success rate: $($result.SuccessRate)%"
            }
            
            Write-Verbose "Slack integration test passed with $($result.SuccessRate)% success rate"
            return $true
        }
        catch {
            throw "Slack integration test failed: $($_.Exception.Message)"
        }
    }
}

# Test 7: Teams integration (if enabled)
if ($IncludeTeamsTests) {
    Invoke-TestWithTracking -TestName "Load Teams Integration Module" -ModuleName "TeamsIntegration" -TestScript {
        try {
            $modulePath = ".\Modules\Unity-Claude-TeamsIntegration\Unity-Claude-TeamsIntegration.psm1"
            if (-not (Test-Path $modulePath)) {
                throw "Module file not found: $modulePath"
            }
            
            Import-Module $modulePath -Force -Global
            
            # Initialize with test workflow webhook (would need real webhook for actual testing)
            $testWebhook = "https://prod-XX.eastus.logic.azure.com:443/workflows/TEST/triggers/TEST"
            $result = Initialize-TeamsIntegration -WebhookUrl $testWebhook -UseWorkflowPattern
            
            if (-not $result) {
                throw "Teams initialization failed"
            }
            
            Write-Verbose "Teams integration module loaded and initialized"
            return $true
        }
        catch {
            throw "Failed to load Teams integration: $($_.Exception.Message)"
        }
    }
    
    Invoke-TestWithTracking -TestName "Teams Integration Test" -ModuleName "TeamsIntegration" -TestScript {
        try {
            $result = Test-TeamsIntegration
            
            if (-not $result -or $result.SuccessRate -lt 100) {
                throw "Teams integration test failed. Success rate: $($result.SuccessRate)%"
            }
            
            Write-Verbose "Teams integration test passed with $($result.SuccessRate)% success rate"
            return $true
        }
        catch {
            throw "Teams integration test failed: $($_.Exception.Message)"
        }
    }
}

# Test 8: End-to-end integration test
Invoke-TestWithTracking -TestName "End-to-End Integration Test" -ModuleName "NotificationIntegration" -TestScript {
    try {
        # Create comprehensive test alert
        $testAlert = [PSCustomObject]@{
            Id = [Guid]::NewGuid().ToString()
            Severity = "High"
            Source = "MultiChannelIntegrationTest"
            Component = "EndToEndValidation"
            Message = "Comprehensive test of multi-channel notification integration system"
            Timestamp = Get-Date
            Classification = [PSCustomObject]@{
                Severity = "High"
                Category = "Integration"
                Priority = 2
                Confidence = 0.95
                Details = @("This is a comprehensive integration test for the multi-channel notification system")
            }
        }
        
        # Test with notification integration
        $deliveryResult = Send-NotificationMultiChannel -Alert $testAlert -TestMode:$TestMode
        
        if (-not $deliveryResult) {
            throw "Multi-channel delivery returned false"
        }
        
        # Verify results
        $successfulDeliveries = ($deliveryResult.GetEnumerator() | Where-Object { $_.Value -eq "Success" }).Count
        if ($successfulDeliveries -eq 0) {
            throw "No successful deliveries in end-to-end test"
        }
        
        Write-Verbose "End-to-end test completed with $successfulDeliveries successful deliveries"
        return $true
    }
    catch {
        throw "End-to-end integration test failed: $($_.Exception.Message)"
    }
}

# Test 9: Performance and scalability test
Invoke-TestWithTracking -TestName "Performance and Scalability Test" -ModuleName "NotificationIntegration" -TestScript {
    try {
        Write-Host "Running performance test with multiple alerts..." -ForegroundColor Yellow
        
        $performanceResults = @{
            AlertsProcessed = 0
            TotalTime = 0
            AverageTimePerAlert = 0
            Errors = 0
        }
        
        $startTime = Get-Date
        
        # Send 10 test alerts to measure performance
        for ($i = 1; $i -le 10; $i++) {
            try {
                $testAlert = [PSCustomObject]@{
                    Id = [Guid]::NewGuid().ToString()
                    Severity = @("Critical", "High", "Medium", "Low", "Info")[(Get-Random -Maximum 5)]
                    Source = "PerformanceTest"
                    Component = "Test$i"
                    Message = "Performance test alert #$i"
                    Timestamp = Get-Date
                }
                
                $alertStart = Get-Date
                $result = Send-NotificationMultiChannel -Alert $testAlert -TestMode:$TestMode
                $alertEnd = Get-Date
                
                $performanceResults.AlertsProcessed++
                $performanceResults.TotalTime += ($alertEnd - $alertStart).TotalMilliseconds
                
                if (-not $result) {
                    $performanceResults.Errors++
                }
                
                # Brief pause to prevent overwhelming the system
                Start-Sleep -Milliseconds 100
            }
            catch {
                $performanceResults.Errors++
                Write-Warning "Performance test alert $i failed: $($_.Exception.Message)"
            }
        }
        
        $endTime = Get-Date
        $totalTestTime = ($endTime - $startTime).TotalSeconds
        
        # Calculate metrics
        if ($performanceResults.AlertsProcessed -gt 0) {
            $performanceResults.AverageTimePerAlert = $performanceResults.TotalTime / $performanceResults.AlertsProcessed
        }
        
        # Validate performance targets (research-validated < 30 second response time)
        if ($performanceResults.AverageTimePerAlert -gt 30000) {  # 30 seconds in milliseconds
            throw "Performance target not met. Average time: $($performanceResults.AverageTimePerAlert)ms"
        }
        
        if ($performanceResults.Errors -gt 2) {  # Allow some errors in performance testing
            throw "Too many errors in performance test: $($performanceResults.Errors)"
        }
        
        Write-Host "Performance test completed:" -ForegroundColor Green
        Write-Host "- Alerts processed: $($performanceResults.AlertsProcessed)" -ForegroundColor Gray
        Write-Host "- Average time per alert: $([Math]::Round($performanceResults.AverageTimePerAlert, 1))ms" -ForegroundColor Gray
        Write-Host "- Total test time: $([Math]::Round($totalTestTime, 1))s" -ForegroundColor Gray
        Write-Host "- Errors: $($performanceResults.Errors)" -ForegroundColor Gray
        
        return $true
    }
    catch {
        throw "Performance test failed: $($_.Exception.Message)"
    }
}

# Test 10: Configuration and preferences validation
Invoke-TestWithTracking -TestName "Configuration Validation Test" -ModuleName "NotificationPreferences" -TestScript {
    try {
        # Test default user preferences
        $defaultPrefs = Get-NotificationPreferencesForUser -UserId "default"
        if (-not $defaultPrefs) {
            throw "Failed to get default preferences"
        }
        
        # Test rule-based channel selection
        $testAlert = [PSCustomObject]@{
            Id = [Guid]::NewGuid().ToString()
            Severity = "Critical"
            Source = "ConfigTest"
            Component = "Validation"
            Message = "Configuration validation test alert"
            Timestamp = Get-Date
        }
        
        $channels = Get-DeliveryChannelsForAlert -Alert $testAlert -UserId "default"
        if ($channels.Count -eq 0) {
            throw "No delivery channels determined for critical alert"
        }
        
        # Verify critical alerts get multiple channels
        if ($channels.Count -lt 2) {
            throw "Critical alerts should use multiple channels. Found: $($channels.Count)"
        }
        
        Write-Verbose "Configuration validation passed with $($channels.Count) channels for critical alert"
        return $true
    }
    catch {
        throw "Configuration validation failed: $($_.Exception.Message)"
    }
}

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
Write-Host "=== Test Results Summary ===" -ForegroundColor Cyan
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
    foreach ($error in $script:TestResults.Errors) {
        Write-Host "- $error" -ForegroundColor Red
    }
}

# Generate detailed report if requested
if ($GenerateDetailedReport) {
    $reportPath = ".\MultiChannel-NotificationIntegration-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $jsonContent = $script:TestResults | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($reportPath, $jsonContent, [System.Text.UTF8Encoding]::new($false))
    
    Write-Host ""
    Write-Host "Detailed test report saved to: $reportPath" -ForegroundColor Cyan
}

# Return test results for programmatic access
return $script:TestResults