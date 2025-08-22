# Test-Week6-IntegrationTesting.ps1
# Phase 2 Week 6: Integration & Testing Validation
# Date: 2025-08-21
#
# Comprehensive test suite for Unity-Claude-NotificationIntegration module

param(
    [switch]$Verbose,
    [switch]$SaveResults
)

# Set verbose preference
if ($Verbose) {
    $VerbosePreference = 'Continue'
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Week 6: Integration & Testing Comprehensive Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Initialize test results
$testResults = @{
    TestDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    ModuleName = 'Unity-Claude-NotificationIntegration'
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    TestDetails = @()
}

# Test counter
$testNumber = 0

# Helper function to run tests
function Test-Function {
    param(
        [string]$TestName,
        [scriptblock]$TestScript,
        [string]$Category
    )
    
    $script:testNumber++
    $script:testResults.TotalTests++
    
    Write-Host "[$testNumber] Testing: $TestName" -ForegroundColor Yellow
    
    $testResult = @{
        TestNumber = $testNumber
        TestName = $TestName
        Category = $Category
        Status = 'Failed'
        Error = $null
        Duration = 0
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $result = & $TestScript
        if ($result -eq $false) {
            throw "Test returned false"
        }
        
        $testResult.Status = 'Passed'
        $script:testResults.PassedTests++
        Write-Host "  Status: PASSED" -ForegroundColor Green
    }
    catch {
        $testResult.Status = 'Failed'
        $testResult.Error = $_.Exception.Message
        $script:testResults.FailedTests++
        Write-Host "  Status: FAILED" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
    }
    finally {
        $stopwatch.Stop()
        $testResult.Duration = $stopwatch.ElapsedMilliseconds
        Write-Host "  Duration: $($testResult.Duration)ms" -ForegroundColor Gray
        $script:testResults.TestDetails += $testResult
    }
    
    Write-Host ""
}

# Import the module
Write-Host "Importing Unity-Claude-NotificationIntegration module..." -ForegroundColor Cyan
try {
    $modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-NotificationIntegration\Unity-Claude-NotificationIntegration.psd1"
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Host "Module imported successfully" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host "Failed to import module: $_" -ForegroundColor Red
    exit 1
}

# Category 1: Integration Core (Week 6 Days 1-2)
Write-Host "Category 1: Integration Core (Days 1-2)" -ForegroundColor Magenta
Write-Host "----------------------------------------" -ForegroundColor Magenta

Test-Function -TestName "Initialize Notification Integration" -Category "IntegrationCore" -TestScript {
    $result = Initialize-NotificationIntegration
    if (-not $result) { throw "Initialization failed" }
    if (-not $result.ModuleVersion) { throw "Module version not set" }
    if (-not $result.Configuration) { throw "Configuration not initialized" }
    return $true
}

Test-Function -TestName "Register Notification Hook" -Category "IntegrationCore" -TestScript {
    $action = {
        param($Context)
        Write-Verbose "Test hook triggered for: $($Context.EventType)"
        return @{ Status = 'Success'; EventType = $Context.EventType }
    }
    
    $hook = Register-NotificationHook -Name 'TestHook' -TriggerEvent 'TestEvent' -Action $action -Severity 'Info'
    if (-not $hook) { throw "Hook registration failed" }
    if ($hook.Name -ne 'TestHook') { throw "Hook name incorrect" }
    if ($hook.TriggerEvent -ne 'TestEvent') { throw "Trigger event incorrect" }
    return $true
}

Test-Function -TestName "Invoke Notification Hook" -Category "IntegrationCore" -TestScript {
    $eventData = @{
        TestMessage = 'Integration test event'
        TestId = [System.Guid]::NewGuid().ToString()
    }
    
    $result = Invoke-NotificationHook -TriggerEvent 'TestEvent' -EventData $eventData -Synchronous
    if (-not $result) { throw "Hook invocation failed" }
    if ($result.Triggered -eq 0) { throw "No hooks were triggered" }
    return $true
}

Test-Function -TestName "Get Notification Hooks" -Category "IntegrationCore" -TestScript {
    $hooks = Get-NotificationHooks
    if ($hooks.Count -eq 0) { throw "No hooks found" }
    
    $specificHook = Get-NotificationHooks -Name 'TestHook'
    if (-not $specificHook) { throw "Specific hook not found" }
    if ($specificHook.Name -ne 'TestHook') { throw "Wrong hook returned" }
    return $true
}

Test-Function -TestName "Unregister Notification Hook" -Category "IntegrationCore" -TestScript {
    $result = Unregister-NotificationHook -Name 'TestHook'
    if (-not $result) { throw "Hook unregistration failed" }
    
    $hook = Get-NotificationHooks -Name 'TestHook'
    if ($hook) { throw "Hook still exists after unregistration" }
    return $true
}

Write-Host ""

# Category 2: Workflow Integration (Week 6 Days 1-2)
Write-Host "Category 2: Workflow Integration (Days 1-2)" -ForegroundColor Magenta
Write-Host "----------------------------------------" -ForegroundColor Magenta

Test-Function -TestName "Add Workflow Notification Trigger" -Category "WorkflowIntegration" -TestScript {
    $hook = Add-WorkflowNotificationTrigger -TriggerType 'UnityCompilationError' -Severity 'Error' -Enabled $true
    if (-not $hook) { throw "Workflow trigger addition failed" }
    if ($hook.Name -ne 'Workflow_UnityCompilationError') { throw "Workflow hook name incorrect" }
    if ($hook.Severity -ne 'Error') { throw "Severity not set correctly" }
    return $true
}

Test-Function -TestName "Enable Workflow Notifications" -Category "WorkflowIntegration" -TestScript {
    # Add more workflow triggers
    Add-WorkflowNotificationTrigger -TriggerType 'ClaudeSubmissionFailure' -Severity 'Error' | Out-Null
    Add-WorkflowNotificationTrigger -TriggerType 'SystemHealthAlert' -Severity 'Warning' | Out-Null
    
    $enabledCount = Enable-WorkflowNotifications
    if ($enabledCount -eq 0) { throw "No workflows enabled" }
    return $true
}

Test-Function -TestName "Get Workflow Notification Status" -Category "WorkflowIntegration" -TestScript {
    $status = Get-WorkflowNotificationStatus
    if (-not $status) { throw "Failed to get workflow status" }
    if ($status.TotalHooks -eq 0) { throw "No workflow hooks found" }
    if ($status.EnabledHooks -eq 0) { throw "No enabled workflow hooks" }
    return $true
}

Test-Function -TestName "Disable Workflow Notifications" -Category "WorkflowIntegration" -TestScript {
    $disabledCount = Disable-WorkflowNotifications -TriggerTypes @('SystemHealthAlert')
    if ($disabledCount -eq 0) { throw "No workflows disabled" }
    
    $status = Get-WorkflowNotificationStatus
    if ($status.Hooks.SystemHealthAlert.Enabled) { throw "Workflow not properly disabled" }
    return $true
}

Test-Function -TestName "Remove Workflow Notification Trigger" -Category "WorkflowIntegration" -TestScript {
    $result = Remove-WorkflowNotificationTrigger -TriggerType 'SystemHealthAlert'
    if (-not $result) { throw "Workflow trigger removal failed" }
    
    $hook = Get-NotificationHooks -Name 'Workflow_SystemHealthAlert'
    if ($hook) { throw "Workflow hook still exists after removal" }
    return $true
}

Write-Host ""

# Category 3: Context Building (Week 6 Days 1-2)
Write-Host "Category 3: Context Building (Days 1-2)" -ForegroundColor Magenta
Write-Host "----------------------------------------" -ForegroundColor Magenta

Test-Function -TestName "Create Notification Context" -Category "ContextBuilding" -TestScript {
    $context = New-NotificationContext -EventType 'TestEvent' -Severity 'Info' -Data @{TestKey = 'TestValue'} -Channels @('Email')
    if (-not $context) { throw "Context creation failed" }
    if ($context.EventType -ne 'TestEvent') { throw "Event type not set correctly" }
    if ($context.Severity -ne 'Info') { throw "Severity not set correctly" }
    if (-not $context.ContextId) { throw "Context ID not generated" }
    return $true
}

Test-Function -TestName "Add Context Data" -Category "ContextBuilding" -TestScript {
    $context = New-NotificationContext -EventType 'TestEvent' -Severity 'Info'
    $additionalData = @{
        ErrorCode = 'E001'
        ProjectName = 'TestProject'
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
    
    $updatedContext = Add-NotificationContextData -Context $context -AdditionalData $additionalData
    if ($updatedContext.Data.ErrorCode -ne 'E001') { throw "Additional data not added correctly" }
    if (-not $updatedContext.ModifiedAt) { throw "Modified timestamp not set" }
    return $true
}

Test-Function -TestName "Format Notification Context" -Category "ContextBuilding" -TestScript {
    $context = New-NotificationContext -EventType 'TestEvent' -Severity 'Warning' -Data @{Key1 = 'Value1'; Key2 = 'Value2'}
    
    $briefFormat = Format-NotificationContext -Context $context -Format 'Brief'
    if (-not $briefFormat.EventType) { throw "Brief format missing event type" }
    
    $detailedFormat = Format-NotificationContext -Context $context -Format 'Detailed'
    if (-not $detailedFormat.ContextId) { throw "Detailed format missing context ID" }
    
    $debugFormat = Format-NotificationContext -Context $context -Format 'Debug'
    if (-not $debugFormat.SystemInfo) { throw "Debug format missing system info" }
    
    return $true
}

Test-Function -TestName "Clear Notification Context" -Category "ContextBuilding" -TestScript {
    $context = New-NotificationContext -EventType 'TestEvent' -Data @{Key1 = 'Value1'; Key2 = 'Value2'}
    $clearedContext = Clear-NotificationContext -Context $context
    if ($clearedContext.Data.Count -ne 0) { throw "Context data not cleared" }
    if (-not $clearedContext.ModifiedAt) { throw "Modified timestamp not updated" }
    return $true
}

Write-Host ""

# Category 4: Reliability Features (Week 6 Days 3-4)
Write-Host "Category 4: Reliability Features (Days 3-4)" -ForegroundColor Magenta
Write-Host "----------------------------------------" -ForegroundColor Magenta

Test-Function -TestName "Create Retry Policy" -Category "ReliabilityFeatures" -TestScript {
    $policy = New-NotificationRetryPolicy -MaxRetries 5 -BaseDelay 2000 -MaxDelay 60000 -BackoffMultiplier 2.5 -Jitter $true
    if (-not $policy) { throw "Retry policy creation failed" }
    if ($policy.MaxRetries -ne 5) { throw "MaxRetries not set correctly" }
    if ($policy.BaseDelay -ne 2000) { throw "BaseDelay not set correctly" }
    if (-not $policy.Jitter) { throw "Jitter not enabled" }
    return $true
}

Test-Function -TestName "Test Notification Delivery" -Category "ReliabilityFeatures" -TestScript {
    $channels = @('Email', 'Webhook')
    $testResults = Test-NotificationDelivery -Channels $channels -TestMessage 'Integration Test' -TimeoutSeconds 10
    if (-not $testResults) { throw "Delivery test failed" }
    if ($testResults.Channels.Count -ne 2) { throw "Not all channels tested" }
    if (-not $testResults.TestTime) { throw "Test time not recorded" }
    return $true
}

Test-Function -TestName "Get Notification Delivery Status" -Category "ReliabilityFeatures" -TestScript {
    $status = Get-NotificationDeliveryStatus -LastMinutes 30
    if (-not $status) { throw "Failed to get delivery status" }
    if (-not $status.Metrics) { throw "Metrics not included in status" }
    if (-not $status.QueueStatus) { throw "Queue status not included" }
    if (-not $status.Configuration) { throw "Configuration not included" }
    return $true
}

Test-Function -TestName "Reset Notification Retry State" -Category "ReliabilityFeatures" -TestScript {
    $result = Reset-NotificationRetryState -IncludeCircuitBreaker -Force
    if (-not $result) { throw "Retry state reset failed" }
    
    $status = Get-NotificationDeliveryStatus
    if ($status.Metrics.TotalRetries -ne 0) { throw "Retry count not reset" }
    if ($status.CircuitBreaker.State -ne 'Closed') { throw "Circuit breaker not reset" }
    return $true
}

Write-Host ""

# Category 5: Fallback Mechanisms (Week 6 Days 3-4)
Write-Host "Category 5: Fallback Mechanisms (Days 3-4)" -ForegroundColor Magenta
Write-Host "----------------------------------------" -ForegroundColor Magenta

Test-Function -TestName "Create Notification Fallback Chain" -Category "FallbackMechanisms" -TestScript {
    $fallbackChain = New-NotificationFallbackChain -Name 'TestFallback' -Channels @('Email', 'Webhook', 'Console') -MaxFallbackAttempts 2
    if (-not $fallbackChain) { throw "Fallback chain creation failed" }
    if ($fallbackChain.Name -ne 'TestFallback') { throw "Fallback chain name incorrect" }
    if ($fallbackChain.Channels.Count -ne 3) { throw "Channels not set correctly" }
    if ($fallbackChain.MaxFallbackAttempts -ne 2) { throw "Max attempts not set correctly" }
    return $true
}

Test-Function -TestName "Test Notification Fallback" -Category "FallbackMechanisms" -TestScript {
    $fallbackChain = New-NotificationFallbackChain -Name 'TestFallback2' -Channels @('Email', 'Webhook') -MaxFallbackAttempts 1
    $testResult = Test-NotificationFallback -FallbackChain $fallbackChain -SimulateFailedChannel 'Email'
    if (-not $testResult) { throw "Fallback test failed" }
    if ($testResult.AttemptedChannels.Count -eq 0) { throw "No fallback channels attempted" }
    return $true
}

Test-Function -TestName "Get Fallback Status" -Category "FallbackMechanisms" -TestScript {
    $fallbackChain = New-NotificationFallbackChain -Name 'StatusTest' -Channels @('Email', 'Webhook')
    $fallbackChain.UsageCount = 5
    $fallbackChain.LastUsed = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    
    $status = Get-FallbackStatus -FallbackChain $fallbackChain
    if (-not $status) { throw "Failed to get fallback status" }
    if ($status.UsageCount -ne 5) { throw "Usage count incorrect" }
    if (-not $status.LastUsed) { throw "Last used time not recorded" }
    return $true
}

Test-Function -TestName "Reset Fallback State" -Category "FallbackMechanisms" -TestScript {
    $fallbackChain = New-NotificationFallbackChain -Name 'ResetTest' -Channels @('Email', 'Webhook')
    $fallbackChain.UsageCount = 10
    $fallbackChain.LastUsed = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    
    $result = Reset-FallbackState -FallbackChain $fallbackChain
    if (-not $result) { throw "Fallback state reset failed" }
    if ($fallbackChain.UsageCount -ne 0) { throw "Usage count not reset" }
    if ($fallbackChain.LastUsed) { throw "Last used time not cleared" }
    return $true
}

Write-Host ""

# Category 6: Queue Management (Week 6 Days 3-4)
Write-Host "Category 6: Queue Management (Days 3-4)" -ForegroundColor Magenta
Write-Host "----------------------------------------" -ForegroundColor Magenta

Test-Function -TestName "Initialize Notification Queue" -Category "QueueManagement" -TestScript {
    $result = Initialize-NotificationQueue -MaxSize 500 -EnablePersistence $false
    if (-not $result) { throw "Queue initialization failed" }
    if ($result.MaxSize -ne 500) { throw "Max size not set correctly" }
    if ($result.QueueSize -ne 0) { throw "Queue not empty after initialization" }
    return $true
}

Test-Function -TestName "Add Notification to Queue" -Category "QueueManagement" -TestScript {
    $hook = @{
        Name = 'QueueTestHook'
        Action = { param($Context) Write-Verbose "Queue test"; return @{Status='Success'} }
        Severity = 'Info'
    }
    $context = New-NotificationContext -EventType 'QueueTest' -Severity 'Info'
    
    $position = Add-NotificationToQueue -Hook $hook -Context $context -Priority 5
    if ($position -lt 0) { throw "Failed to add notification to queue" }
    
    $status = Get-QueueStatus
    if ($status.QueueSize -ne 1) { throw "Queue size not updated" }
    return $true
}

Test-Function -TestName "Process Notification Queue" -Category "QueueManagement" -TestScript {
    # Add more items to queue for processing
    $hook = @{
        Name = 'ProcessTestHook'
        Action = { param($Context) Write-Verbose "Processing test"; return @{Status='Success'} }
        Severity = 'Info'
    }
    $context = New-NotificationContext -EventType 'ProcessTest' -Severity 'Info'
    Add-NotificationToQueue -Hook $hook -Context $context | Out-Null
    
    $result = Process-NotificationQueue -BatchSize 3
    if (-not $result) { throw "Queue processing failed" }
    if ($result.Processed -eq 0) { throw "No notifications processed" }
    return $true
}

Test-Function -TestName "Get Queue Status" -Category "QueueManagement" -TestScript {
    $status = Get-QueueStatus
    if (-not $status) { throw "Failed to get queue status" }
    if (-not $status.ContainsKey('QueueSize')) { throw "Queue size not in status" }
    if (-not $status.ContainsKey('MaxSize')) { throw "Max size not in status" }
    return $true
}

Test-Function -TestName "Clear Notification Queue" -Category "QueueManagement" -TestScript {
    # Add some items first
    $hook = @{ Name = 'ClearTestHook'; Action = { return @{} }; Severity = 'Info' }
    $context = New-NotificationContext -EventType 'ClearTest' -Severity 'Info'
    Add-NotificationToQueue -Hook $hook -Context $context | Out-Null
    
    $result = Clear-NotificationQueue -Force
    if (-not $result) { throw "Queue clearing failed" }
    
    $status = Get-QueueStatus
    if ($status.QueueSize -ne 0) { throw "Queue not cleared" }
    return $true
}

Write-Host ""

# Category 7: Configuration Management (Week 6 Day 5)
Write-Host "Category 7: Configuration Management (Day 5)" -ForegroundColor Magenta
Write-Host "----------------------------------------" -ForegroundColor Magenta

Test-Function -TestName "Create Notification Configuration" -Category "ConfigurationManagement" -TestScript {
    $config = New-NotificationConfiguration -Environment 'Test' -Settings @{MaxRetries = 5; QueueMaxSize = 2000}
    if (-not $config) { throw "Configuration creation failed" }
    if ($config.Environment -ne 'Test') { throw "Environment not set correctly" }
    if ($config.MaxRetries -ne 5) { throw "Custom setting not applied" }
    if ($config.QueueMaxSize -ne 2000) { throw "Custom queue size not applied" }
    return $true
}

Test-Function -TestName "Export Notification Configuration" -Category "ConfigurationManagement" -TestScript {
    $exportPath = Join-Path $env:TEMP "test_notification_config.json"
    
    $result = Export-NotificationConfiguration -Path $exportPath -IncludeCredentials:$false
    if (-not $result) { throw "Configuration export failed" }
    if (-not (Test-Path $exportPath)) { throw "Export file not created" }
    
    # Cleanup
    Remove-Item $exportPath -Force -ErrorAction SilentlyContinue
    return $true
}

Test-Function -TestName "Import Notification Configuration" -Category "ConfigurationManagement" -TestScript {
    # Create test config file
    $testConfig = @{
        Environment = 'ImportTest'
        Enabled = $false
        MaxRetries = 7
        DefaultChannels = @('Email')
    }
    $importPath = Join-Path $env:TEMP "import_test_config.json"
    $testConfig | ConvertTo-Json | Set-Content $importPath
    
    $result = Import-NotificationConfiguration -Path $importPath -Merge
    if (-not $result) { throw "Configuration import failed" }
    if ($result.MaxRetries -ne 7) { throw "Imported setting not applied" }
    
    # Cleanup
    Remove-Item $importPath -Force -ErrorAction SilentlyContinue
    return $true
}

Test-Function -TestName "Test Notification Configuration" -Category "ConfigurationManagement" -TestScript {
    $validConfig = @{
        Enabled = $true
        MaxRetries = 3
        DefaultChannels = @('Email', 'Webhook')
        QueueMaxSize = 1000
    }
    
    $validation = Test-NotificationConfiguration -Configuration $validConfig
    if (-not $validation.IsValid) { throw "Valid configuration marked as invalid" }
    
    # Test invalid config
    $invalidConfig = @{
        Enabled = $true
        # Missing required fields
    }
    $validation = Test-NotificationConfiguration -Configuration $invalidConfig
    if ($validation.IsValid) { throw "Invalid configuration marked as valid" }
    
    return $true
}

Test-Function -TestName "Get and Set Configuration" -Category "ConfigurationManagement" -TestScript {
    $originalValue = Get-NotificationConfiguration -Setting 'MaxRetries'
    
    Set-NotificationConfiguration -Setting 'MaxRetries' -Value 10
    $newValue = Get-NotificationConfiguration -Setting 'MaxRetries'
    if ($newValue -ne 10) { throw "Configuration setting not updated" }
    
    # Reset to original
    Set-NotificationConfiguration -Setting 'MaxRetries' -Value $originalValue
    return $true
}

Write-Host ""

# Category 8: Monitoring and Analytics (Week 6 Day 5)
Write-Host "Category 8: Monitoring and Analytics (Day 5)" -ForegroundColor Magenta
Write-Host "----------------------------------------" -ForegroundColor Magenta

Test-Function -TestName "Get Notification Metrics" -Category "MonitoringAnalytics" -TestScript {
    $metrics = Get-NotificationMetrics -LastHours 12
    if (-not $metrics) { throw "Failed to get notification metrics" }
    if (-not $metrics.ContainsKey('TotalSent')) { throw "Total sent not in metrics" }
    if (-not $metrics.ContainsKey('SuccessRate')) { throw "Success rate not calculated" }
    if ($metrics.Period -ne '12 hours') { throw "Period not set correctly" }
    return $true
}

Test-Function -TestName "Get Notification Health Check" -Category "MonitoringAnalytics" -TestScript {
    $healthCheck = Get-NotificationHealthCheck
    if (-not $healthCheck) { throw "Failed to get health check" }
    if (-not $healthCheck.OverallHealth) { throw "Overall health not determined" }
    if (-not $healthCheck.Checks) { throw "Individual checks not performed" }
    if (-not $healthCheck.Checks.Configuration) { throw "Configuration check missing" }
    if (-not $healthCheck.Checks.Queue) { throw "Queue check missing" }
    return $true
}

Test-Function -TestName "Generate Notification Report" -Category "MonitoringAnalytics" -TestScript {
    $report = New-NotificationReport -ReportPeriodHours 6 -Format 'Detailed'
    if (-not $report) { throw "Failed to generate report" }
    if ($report.Period -ne '6 hours') { throw "Report period incorrect" }
    if (-not $report.Summary) { throw "Report summary missing" }
    if (-not $report.Metrics) { throw "Report metrics missing" }
    if (-not $report.HealthCheck) { throw "Report health check missing" }
    return $true
}

Test-Function -TestName "Export Notification Analytics" -Category "MonitoringAnalytics" -TestScript {
    $exportPath = Join-Path $env:TEMP "test_analytics.json"
    
    $result = Export-NotificationAnalytics -Path $exportPath -ReportPeriodHours 1 -Format 'JSON'
    if (-not $result) { throw "Analytics export failed" }
    if (-not (Test-Path $exportPath)) { throw "Analytics file not created" }
    
    # Test CSV format
    $csvPath = Join-Path $env:TEMP "test_analytics.csv"
    $result = Export-NotificationAnalytics -Path $csvPath -Format 'CSV'
    if (-not $result) { throw "CSV analytics export failed" }
    if (-not (Test-Path $csvPath)) { throw "CSV file not created" }
    
    # Cleanup
    Remove-Item $exportPath -Force -ErrorAction SilentlyContinue
    Remove-Item $csvPath -Force -ErrorAction SilentlyContinue
    return $true
}

Test-Function -TestName "Reset Notification Metrics" -Category "MonitoringAnalytics" -TestScript {
    # First ensure we have some metrics
    $metrics = Get-NotificationMetrics
    
    $result = Reset-NotificationMetrics -Force
    if (-not $result) { throw "Metrics reset failed" }
    
    $newMetrics = Get-NotificationMetrics
    if ($newMetrics.TotalSent -ne 0) { throw "Total sent not reset" }
    if ($newMetrics.TotalFailed -ne 0) { throw "Total failed not reset" }
    if ($newMetrics.TotalRetries -ne 0) { throw "Total retries not reset" }
    return $true
}

Write-Host ""

# Category 9: Error Handling and Edge Cases
Write-Host "Category 9: Error Handling and Edge Cases" -ForegroundColor Magenta
Write-Host "----------------------------------------" -ForegroundColor Magenta

Test-Function -TestName "Handle Missing Hook" -Category "ErrorHandling" -TestScript {
    try {
        $result = Invoke-NotificationHook -TriggerEvent 'NonExistentEvent' -Synchronous
        if ($result.Triggered -ne 0) { throw "Should not have triggered any hooks" }
        if ($result.Skipped -ne 'NoHooks') { throw "Should indicate no hooks found" }
    }
    catch {
        throw "Error handling missing hook: $_"
    }
    return $true
}

Test-Function -TestName "Handle Invalid Configuration Import" -Category "ErrorHandling" -TestScript {
    try {
        $result = Import-NotificationConfiguration -Path 'NonExistentFile.json'
        throw "Should have thrown error for missing file"
    }
    catch {
        if ($_.Exception.Message -notlike '*not found*') {
            throw "Unexpected error: $_"
        }
    }
    return $true
}

Test-Function -TestName "Handle Queue Overflow" -Category "ErrorHandling" -TestScript {
    # Initialize small queue
    Initialize-NotificationQueue -MaxSize 2 | Out-Null
    
    # Add items beyond capacity
    $hook = @{ Name = 'OverflowTest'; Action = { return @{} }; Severity = 'Info' }
    $context = New-NotificationContext -EventType 'OverflowTest' -Severity 'Info'
    
    Add-NotificationToQueue -Hook $hook -Context $context | Out-Null
    Add-NotificationToQueue -Hook $hook -Context $context | Out-Null
    Add-NotificationToQueue -Hook $hook -Context $context | Out-Null  # This should trigger overflow
    
    $status = Get-QueueStatus
    if ($status.QueueSize -gt 2) { throw "Queue size exceeded maximum" }
    
    # Reset to normal size
    Initialize-NotificationQueue -MaxSize 1000 | Out-Null
    return $true
}

Test-Function -TestName "Handle Failed Notification in Queue" -Category "ErrorHandling" -TestScript {
    $failingHook = @{
        Name = 'FailingHook'
        Action = { throw "Simulated failure" }
        Severity = 'Info'
    }
    $context = New-NotificationContext -EventType 'FailTest' -Severity 'Info'
    
    Add-NotificationToQueue -Hook $failingHook -Context $context | Out-Null
    $result = Process-NotificationQueue -BatchSize 1
    
    if ($result.Failed -eq 0) { throw "Failed notification not recorded" }
    
    $failedNotifications = Get-FailedNotifications -LastN 5
    if ($failedNotifications.Count -eq 0) { throw "Failed notification not in failed queue" }
    return $true
}

Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.TotalTests)" -ForegroundColor White
Write-Host "Passed: $($testResults.PassedTests)" -ForegroundColor Green
Write-Host "Failed: $($testResults.FailedTests)" -ForegroundColor $(if ($testResults.FailedTests -eq 0) { 'Green' } else { 'Red' })

$successRate = if ($testResults.TotalTests -gt 0) {
    [math]::Round(($testResults.PassedTests / $testResults.TotalTests) * 100, 2)
} else { 0 }

Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { 'Green' } elseif ($successRate -ge 70) { 'Yellow' } else { 'Red' })
Write-Host ""

# Performance Analysis
$totalDuration = if ($testResults.TestDetails.Count -gt 0) {
    ($testResults.TestDetails | Measure-Object -Property Duration -Sum).Sum
} else { 0 }
$avgDuration = if ($testResults.TotalTests -gt 0 -and $totalDuration -gt 0) {
    [math]::Round($totalDuration / $testResults.TotalTests, 2)
} else { 0 }

Write-Host "Performance Metrics:" -ForegroundColor Cyan
Write-Host "  Total Duration: ${totalDuration}ms" -ForegroundColor White
Write-Host "  Average Duration: ${avgDuration}ms" -ForegroundColor White
Write-Host ""

# Save results if requested
if ($SaveResults) {
    $resultsFile = "Week6_IntegrationTesting_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    $output = @"
Week 6: Integration & Testing Results
========================================
Test Date: $($testResults.TestDate)
Module: $($testResults.ModuleName)

Summary:
--------
Total Tests: $($testResults.TotalTests)
Passed: $($testResults.PassedTests)
Failed: $($testResults.FailedTests)
Success Rate: $successRate%

Performance:
-----------
Total Duration: ${totalDuration}ms
Average Duration: ${avgDuration}ms

Test Details:
------------
"@

    foreach ($test in $testResults.TestDetails) {
        $output += "`n[$($test.TestNumber)] $($test.TestName)"
        $output += "`n  Category: $($test.Category)"
        $output += "`n  Status: $($test.Status)"
        $output += "`n  Duration: $($test.Duration)ms"
        if ($test.Error) {
            $output += "`n  Error: $($test.Error)"
        }
        $output += "`n"
    }

    $output | Set-Content $resultsFile
    Write-Host "Results saved to: $resultsFile" -ForegroundColor Green
}

# Return success/failure
if ($testResults.FailedTests -eq 0) {
    Write-Host "ALL TESTS PASSED!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "SOME TESTS FAILED!" -ForegroundColor Red
    exit 1
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUfJVW01H4Z878abbGbpW92K30
# QS6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQU07OkTAy1NPMjiOd/VLLXNBTwJYwwDQYJKoZIhvcNAQEBBQAEggEAAXd8
# re6soxox9+eCmJU+TlL8QyqkCbJhrbwfZmnpXgsx+rQqV+3p3Ke/ksNMdDQeyYX7
# T4SWPn92uC9vVyHA5msm/FzZXzhEuqRVsr+uyLzYr8+jurMat98UKLIOtU1sJP+4
# wkosh54UhdYKpbz+suAUUbJI6kbkQjCs/DnhJoYRPVFr6YThLOSEFunAoUVR35P4
# 5/3fLVrX+OQgLfe2e0tvit/C4i2UZPYci2sBf9xBtJQKdk9N4NPjK2U//YhLNOsb
# VDTyYHwyrYa75S9eERb7qABS8ZDfzyOzW67lN2Y9OJyoMRQ3K/Hg1ieZd9IkgVjB
# PjOqIx/YfbSY2KY6qg==
# SIG # End signature block
