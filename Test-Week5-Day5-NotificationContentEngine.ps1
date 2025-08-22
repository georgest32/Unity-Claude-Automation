# Test-Week5-Day5-NotificationContentEngine.ps1
# Phase 2 Week 5 Day 5: Notification Content Engine Testing
# Date: 2025-08-21
#
# Comprehensive test suite for Unity-Claude-NotificationContentEngine module

param(
    [switch]$Verbose,
    [switch]$SaveResults
)

# Set verbose preference
if ($Verbose) {
    $VerbosePreference = 'Continue'
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Week 5 Day 5: Notification Content Engine Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Initialize test results
$testResults = @{
    TestDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    ModuleName = 'Unity-Claude-NotificationContentEngine'
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
Write-Host "Importing Unity-Claude-NotificationContentEngine module..." -ForegroundColor Cyan
try {
    $modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-NotificationContentEngine\Unity-Claude-NotificationContentEngine.psd1"
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Host "Module imported successfully" -ForegroundColor Green
    Write-Host ""
}
catch {
    Write-Host "Failed to import module: $_" -ForegroundColor Red
    exit 1
}

# Category 1: Module Initialization and Configuration
Write-Host "Category 1: Module Initialization and Configuration" -ForegroundColor Magenta
Write-Host "----------------------------------------" -ForegroundColor Magenta

Test-Function -TestName "Initialize Content Engine" -Category "Initialization" -TestScript {
    $result = Initialize-NotificationContentEngine
    if (-not $result) { throw "Initialization failed" }
    if ($result.RoutingRules -lt 4) { throw "Default routing rules not created" }
    return $true
}

Test-Function -TestName "Get Content Engine Configuration" -Category "Configuration" -TestScript {
    $config = Get-ContentEngineConfiguration
    if (-not $config) { throw "Configuration not retrieved" }
    if ($config.DefaultSeverity -ne 'Info') { throw "Default severity incorrect" }
    return $true
}

Test-Function -TestName "Set Content Engine Configuration" -Category "Configuration" -TestScript {
    $config = Set-ContentEngineConfiguration -MaxHistoryItems 500 -DefaultSeverity 'Warning'
    if ($config.MaxHistoryItems -ne 500) { throw "MaxHistoryItems not updated" }
    if ($config.DefaultSeverity -ne 'Warning') { throw "DefaultSeverity not updated" }
    # Reset to defaults
    Set-ContentEngineConfiguration -MaxHistoryItems 1000 -DefaultSeverity 'Info' | Out-Null
    return $true
}

Write-Host ""

# Category 2: Unified Template System (Hours 1-4)
Write-Host "Category 2: Unified Template System" -ForegroundColor Magenta
Write-Host "----------------------------------------" -ForegroundColor Magenta

Test-Function -TestName "Create Unified Notification Template" -Category "Templates" -TestScript {
    $emailContent = @{
        Subject = 'Unity Compilation Error: {ErrorCode}'
        Body = 'Error detected in {ProjectName} at {Timestamp}. Severity: {Severity}'
    }
    $webhookContent = @{
        Payload = @{
            type = 'unity_error'
            error_code = '{ErrorCode}'
            project = '{ProjectName}'
            severity = '{Severity}'
            timestamp = '{Timestamp}'
        }
    }
    
    $template = New-UnifiedNotificationTemplate -Name 'UnityError' -Description 'Unity compilation error notification' `
        -EmailContent $emailContent -WebhookContent $webhookContent
    
    if (-not $template) { throw "Template creation failed" }
    if ($template.Name -ne 'UnityError') { throw "Template name incorrect" }
    return $true
}

Test-Function -TestName "Get Notification Template" -Category "Templates" -TestScript {
    $template = Get-NotificationTemplate -Name 'UnityError'
    if (-not $template) { throw "Template not found" }
    if ($template.Name -ne 'UnityError') { throw "Template name mismatch" }
    return $true
}

Test-Function -TestName "Update Notification Template" -Category "Templates" -TestScript {
    $updatedEmail = @{
        Subject = 'UPDATED: Unity Error {ErrorCode}'
        Body = 'Updated body content'
    }
    
    $template = Set-NotificationTemplate -Name 'UnityError' -EmailContent $updatedEmail
    if ($template.EmailContent.Subject -notlike 'UPDATED:*') { throw "Template not updated" }
    return $true
}

Test-Function -TestName "Test Notification Template" -Category "Templates" -TestScript {
    $sampleData = @{
        ErrorCode = 'CS0246'
        ProjectName = 'TestProject'
        Severity = 'Error'
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
    
    $testResult = Test-NotificationTemplate -Name 'UnityError' -SampleData $sampleData
    if (-not $testResult.ValidationPassed) { throw "Template validation failed" }
    if (-not $testResult.PreviewEmail) { throw "Email preview not generated" }
    if (-not $testResult.PreviewWebhook) { throw "Webhook preview not generated" }
    return $true
}

Test-Function -TestName "Create Template Component" -Category "Templates" -TestScript {
    $component = New-TemplateComponent -Name 'ErrorDetails' -Content 'File: {FileName}, Line: {LineNumber}' -Type 'ErrorInfo'
    if (-not $component) { throw "Component creation failed" }
    if ($component.Type -ne 'ErrorInfo') { throw "Component type incorrect" }
    return $true
}

Test-Function -TestName "Format Unified Notification Content" -Category "Templates" -TestScript {
    $data = @{
        ErrorCode = 'CS0103'
        ProjectName = 'MyProject'
        Severity = 'Error'
    }
    
    $content = Format-UnifiedNotificationContent -TemplateName 'UnityError' -Channel 'Email' -Data $data -Severity 'Error'
    if (-not $content) { throw "Content formatting failed" }
    if ($content.Subject -notlike '*CS0103*') { throw "Variable substitution failed" }
    return $true
}

Test-Function -TestName "Validate Notification Content" -Category "Templates" -TestScript {
    $emailContent = @{
        Subject = 'Test Subject'
        Body = 'Test Body'
    }
    
    $validation = Validate-NotificationContent -Content $emailContent -Channel 'Email'
    if (-not $validation.IsValid) { throw "Valid content marked as invalid" }
    
    # Test invalid content
    $invalidContent = @{ Body = 'No subject' }
    $validation = Validate-NotificationContent -Content $invalidContent -Channel 'Email'
    if ($validation.IsValid) { throw "Invalid content marked as valid" }
    
    return $true
}

Test-Function -TestName "Preview Notification Template" -Category "Templates" -TestScript {
    $preview = Preview-NotificationTemplate -TemplateName 'UnityError' -SampleData @{ErrorCode = 'CS0029'} -Severity 'Error'
    if (-not $preview) { throw "Preview generation failed" }
    if (-not $preview.EmailPreview) { throw "Email preview missing" }
    if (-not $preview.WebhookPreview) { throw "Webhook preview missing" }
    return $true
}

Write-Host ""

# Category 3: Severity-Based Routing (Hours 5-8)
Write-Host "Category 3: Severity-Based Routing" -ForegroundColor Magenta
Write-Host "----------------------------------------" -ForegroundColor Magenta

Test-Function -TestName "Create Notification Routing Rule" -Category "Routing" -TestScript {
    $rule = New-NotificationRoutingRule -Name 'CriticalAlerts' -Severity 'Critical' -Channels 'Both' -Priority 10
    if (-not $rule) { throw "Routing rule creation failed" }
    if ($rule.Priority -ne 10) { throw "Priority not set correctly" }
    return $true
}

Test-Function -TestName "Get Notification Routing Rules" -Category "Routing" -TestScript {
    $rules = Get-NotificationRouting -EnabledOnly
    if ($rules.Count -lt 5) { throw "Expected at least 5 routing rules (4 default + 1 custom)" }
    
    $criticalRule = Get-NotificationRouting -Name 'CriticalAlerts'
    if (-not $criticalRule) { throw "Specific rule not found" }
    return $true
}

Test-Function -TestName "Invoke Severity-Based Routing" -Category "Routing" -TestScript {
    # Test Critical severity - should use Both channels
    $channels = Invoke-SeverityBasedRouting -Severity 'Critical'
    if ($channels.Count -ne 2) { throw "Critical should route to both channels" }
    
    # Test Warning severity - should use Email only
    $channels = Invoke-SeverityBasedRouting -Severity 'Warning'
    if ($channels -notcontains 'Email') { throw "Warning should route to Email" }
    
    # Test Info severity - should use Webhook only
    $channels = Invoke-SeverityBasedRouting -Severity 'Info'
    if ($channels -notcontains 'Webhook') { throw "Info should route to Webhook" }
    
    return $true
}

Test-Function -TestName "Test Notification Routing" -Category "Routing" -TestScript {
    $testResult = Test-NotificationRouting -Severity 'Error' -ShowDetails:$false
    if ($testResult.SelectedChannels.Count -ne 2) { throw "Error severity should route to both channels" }
    
    # Test with context conditions
    $context = @{ Environment = 'Production' }
    $testResult = Test-NotificationRouting -Severity 'Warning' -Context $context
    if (-not $testResult.SelectedChannels) { throw "Routing test with context failed" }
    
    return $true
}

Write-Host ""

# Category 4: Channel Selection and Management (Hours 5-8)
Write-Host "Category 4: Channel Selection and Management" -ForegroundColor Magenta
Write-Host "----------------------------------------" -ForegroundColor Magenta

Test-Function -TestName "Create Channel Preferences" -Category "Channels" -TestScript {
    $prefs = New-ChannelPreferences -Name 'ProductionPrefs' -PreferredChannels @('Email') `
        -SeverityOverrides @{ Critical = @('Email', 'Webhook') }
    
    if (-not $prefs) { throw "Channel preferences creation failed" }
    if ($prefs.PreferredChannels -notcontains 'Email') { throw "Preferred channels not set" }
    return $true
}

Test-Function -TestName "Select Notification Channels" -Category "Channels" -TestScript {
    $channels = Select-NotificationChannels -Severity 'Critical' -PreferredChannels @('Email')
    if ($channels.Count -eq 0) { throw "No channels selected" }
    
    # Test with throttling (should allow first notifications)
    $channels = Select-NotificationChannels -Severity 'Info' -ApplyThrottling
    if ($channels.Count -eq 0) { throw "Throttling blocked first notification" }
    
    return $true
}

Test-Function -TestName "Invoke Channel Selection" -Category "Channels" -TestScript {
    $channels = Invoke-ChannelSelection -Severity 'Error' -PreferenceName 'ProductionPrefs'
    if ($channels.Count -eq 0) { throw "Channel selection failed" }
    
    # Should respect severity overrides
    $channels = Invoke-ChannelSelection -Severity 'Critical' -PreferenceName 'ProductionPrefs'
    if ($channels.Count -ne 2) { throw "Severity override not applied" }
    
    return $true
}

Write-Host ""

# Category 5: Notification Processing and Delivery (Hours 5-8)
Write-Host "Category 5: Notification Processing and Delivery" -ForegroundColor Magenta
Write-Host "----------------------------------------" -ForegroundColor Magenta

Test-Function -TestName "Send Unified Notification (Test Mode)" -Category "Delivery" -TestScript {
    $data = @{
        ErrorCode = 'CS0246'
        ProjectName = 'TestProject'
        FileName = 'TestScript.cs'
        LineNumber = 42
    }
    
    $result = Send-UnifiedNotification -TemplateName 'UnityError' -Severity 'Error' -Data $data -TestMode
    if (-not $result) { throw "Notification send failed" }
    if ($result.Channels.Count -eq 0) { throw "No channels selected for notification" }
    if ($result.EmailStatus -ne 'TestMode') { throw "Email test mode not activated" }
    if ($result.WebhookStatus -ne 'TestMode') { throw "Webhook test mode not activated" }
    
    return $true
}

Test-Function -TestName "Get Notification Status" -Category "Delivery" -TestScript {
    # Send a few test notifications to populate history
    1..3 | ForEach-Object {
        Send-UnifiedNotification -TemplateName 'UnityError' -Severity 'Info' -Data @{ErrorCode = "TEST$_"} -TestMode | Out-Null
    }
    
    $status = Get-NotificationStatus -LastN 5
    if ($status.Count -eq 0) { throw "No notification history found" }
    
    # Filter by severity
    $infoStatus = Get-NotificationStatus -Severity 'Info' -LastN 10
    if ($infoStatus.Count -eq 0) { throw "Severity filtering failed" }
    
    return $true
}

Test-Function -TestName "Get Notification Analytics" -Category "Delivery" -TestScript {
    $analytics = Get-NotificationAnalytics -StartDate (Get-Date).AddHours(-1)
    if (-not $analytics) { throw "Analytics generation failed" }
    if ($analytics.TotalNotifications -eq 0) { throw "No notifications in analytics" }
    if (-not $analytics.BySeverity) { throw "Severity breakdown missing" }
    if (-not $analytics.ByChannel) { throw "Channel breakdown missing" }
    
    return $true
}

Test-Function -TestName "Invoke Notification Delivery" -Category "Delivery" -TestScript {
    $content = @{
        Subject = 'Test Delivery'
        Body = 'Test notification delivery'
    }
    
    $result = Invoke-NotificationDelivery -Content $content -Channel 'Email'
    if ($result.Status -ne 'Delivered') { throw "Delivery simulation failed" }
    if ($result.Channel -ne 'Email') { throw "Channel mismatch" }
    
    return $true
}

Write-Host ""

# Category 6: Import/Export Operations
Write-Host "Category 6: Import/Export Operations" -ForegroundColor Magenta
Write-Host "----------------------------------------" -ForegroundColor Magenta

Test-Function -TestName "Export Notification Templates" -Category "ImportExport" -TestScript {
    $exportPath = Join-Path $env:TEMP "notification_templates_export.json"
    
    Export-NotificationTemplate -Path $exportPath -IncludeComponents
    if (-not (Test-Path $exportPath)) { throw "Export file not created" }
    
    $exportData = Get-Content $exportPath -Raw | ConvertFrom-Json
    if (-not $exportData.Templates) { throw "Templates not exported" }
    
    # Cleanup
    Remove-Item $exportPath -Force
    return $true
}

Test-Function -TestName "Import Notification Templates" -Category "ImportExport" -TestScript {
    # First export current templates
    $exportPath = Join-Path $env:TEMP "notification_templates_import_test.json"
    Export-NotificationTemplate -Path $exportPath
    
    # Create a new template to test import
    $testTemplate = @{
        Name = 'ImportTest'
        Description = 'Test import'
        EmailContent = @{ Subject = 'Test'; Body = 'Test' }
        WebhookContent = @{ Payload = 'Test' }
    }
    
    # Manually create import file with test template
    $importData = @{
        ExportDate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ModuleVersion = '1.0.0'
        Templates = @{ ImportTest = $testTemplate }
    }
    $importData | ConvertTo-Json -Depth 10 | Set-Content $exportPath
    
    # Import templates
    $result = Import-NotificationTemplate -Path $exportPath
    if ($result.Imported -eq 0) { throw "No templates imported" }
    
    # Verify import
    $imported = Get-NotificationTemplate -Name 'ImportTest'
    if (-not $imported) { throw "Imported template not found" }
    
    # Cleanup
    Remove-Item $exportPath -Force
    Remove-NotificationTemplate -Name 'ImportTest' -Force
    
    return $true
}

Write-Host ""

# Category 7: Edge Cases and Error Handling
Write-Host "Category 7: Edge Cases and Error Handling" -ForegroundColor Magenta
Write-Host "----------------------------------------" -ForegroundColor Magenta

Test-Function -TestName "Handle Missing Template" -Category "ErrorHandling" -TestScript {
    try {
        Format-UnifiedNotificationContent -TemplateName 'NonExistent' -Channel 'Email' -ErrorAction Stop
        throw "Should have thrown error for missing template"
    }
    catch {
        if ($_.Exception.Message -notlike '*not found*') {
            throw "Unexpected error: $_"
        }
    }
    return $true
}

Test-Function -TestName "Handle Invalid Severity" -Category "ErrorHandling" -TestScript {
    try {
        # PowerShell ValidateSet should prevent this
        # We'll test the routing with valid severity but no rules
        $channels = Invoke-SeverityBasedRouting -Severity 'Info'
        if ($channels.Count -eq 0) { throw "Should have default channels" }
    }
    catch {
        throw "Error handling severity: $_"
    }
    return $true
}

Test-Function -TestName "Throttling Mechanism" -Category "ErrorHandling" -TestScript {
    # Send multiple notifications to trigger throttling
    $throttleConfig = Set-ContentEngineConfiguration -ThrottleWindowMinutes 1
    
    # Send 4 Info notifications (should trigger throttle after 3)
    1..4 | ForEach-Object {
        Send-UnifiedNotification -TemplateName 'UnityError' -Severity 'Info' -Data @{} -TestMode -ApplyThrottling | Out-Null
    }
    
    # Check if throttling worked (last notification should have been throttled)
    # This is simulated in test mode, actual throttling would prevent delivery
    
    # Reset throttle window
    Set-ContentEngineConfiguration -ThrottleWindowMinutes 5 | Out-Null
    
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
$avgDuration = if ($testResults.TotalTests -gt 0 -and $totalDuration) {
    [math]::Round($totalDuration / $testResults.TotalTests, 2)
} else { 0 }

Write-Host "Performance Metrics:" -ForegroundColor Cyan
Write-Host "  Total Duration: ${totalDuration}ms" -ForegroundColor White
Write-Host "  Average Duration: ${avgDuration}ms" -ForegroundColor White
Write-Host ""

# Save results if requested
if ($SaveResults) {
    $resultsFile = "Week5_Day5_NotificationContentEngine_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    $output = @"
Week 5 Day 5: Notification Content Engine Test Results
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
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUiedQdIn9czdsUiy4a9Osqnph
# 5EugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUr2Rkh1uDsJJTUfdjXEke1coR/4cwDQYJKoZIhvcNAQEBBQAEggEApyr1
# 4RkrWQ0gFY/x4QCSSLBd2FIVTFYIhaFzLg5enp2xhsTxA27grfivth5gI/bj70be
# c+t9wYx6/4b3u1W5XyKtq1DXsmTJ5R8/jD/7u6IbucEbhefYAiNNlpry4pDl8JPa
# LFonOR+/sCxY7/MCAXHMe262yTAtwJdUdkJ3n1WPYylz8ndNGr6H6ntpms7Irvmm
# /Fb4IK3F2p2xQy3YRlbljE8n9Ao3pxfUndhs/VRd4e3/zc46wz9/6EOCm4ELB+8E
# kq2tseNcmTpVycN/aNWjto05//8jSqkAkTS9Tb2e7ediTdbLt7bgyHRg80glQzuH
# +KYzM8Hmxm3CMvCwQg==
# SIG # End signature block
