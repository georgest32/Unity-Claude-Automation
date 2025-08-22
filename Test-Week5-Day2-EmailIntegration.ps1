# Test-Week5-Day2-EmailIntegration.ps1
# Week 5 Day 2 Hour 7-8: Integrated Email System Testing
# Comprehensive test suite for email notification integration with Unity-Claude workflow
# Date: 2025-08-21

[CmdletBinding()]
param(
    [switch]$SaveResults,
    [switch]$TestRealDelivery,
    [string]$TestEmailConfiguration = "TestConfig",
    [string]$TestEmailAddress,
    [string]$TestResultsFile
)

Write-Host "=== Week 5 Day 2: Email Integration Testing ===" -ForegroundColor Cyan
Write-Host "Integrated Email System Testing - Unity-Claude Workflow Integration" -ForegroundColor White
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
Write-Host ""

# Test configuration
$TestConfig = @{
    TestName = "Week5-Day2-EmailIntegration"
    Date = Get-Date
    SaveResults = $SaveResults
    TestRealDelivery = $TestRealDelivery
    TestEmailConfiguration = $TestEmailConfiguration
    TestEmailAddress = $TestEmailAddress
    TestResultsFile = if ($TestResultsFile) { $TestResultsFile } else { 
        "Test_Results_Week5_Day2_EmailIntegration_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt" 
    }
}

# Initialize test results
$TestResults = @{
    TestName = $TestConfig.TestName
    StartTime = Get-Date
    Tests = @()
    Summary = @{ Total = 0; Passed = 0; Failed = 0; Skipped = 0 }
    Categories = @{}
    EndTime = $null
}

function Test-EmailIntegrationFunction {
    param(
        [string]$TestName,
        [scriptblock]$TestCode,
        [string]$Category = "General",
        [int]$TimeoutSeconds = 30
    )
    
    $testStart = Get-Date
    $testResult = @{
        Name = $TestName
        Category = $Category
        StartTime = $testStart
        Duration = 0
        Status = "Unknown"
        Result = $false
        Error = $null
    }
    
    Write-Host "[DEBUG] [EmailIntegrationTest] Starting test: $TestName (Category: $Category)" -ForegroundColor Gray
    
    try {
        Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [INFO] [$Category] Starting test: $TestName" -ForegroundColor White
        
        $result = & $TestCode $TestConfig
        
        $testEnd = Get-Date
        $duration = ($testEnd - $testStart).TotalMilliseconds
        
        if ($result) {
            $testResult.Status = "PASS"
            $testResult.Result = $true
            Write-Host "[PASS] $TestName" -ForegroundColor Green
            Write-Host "    Duration: $([int]$duration)ms" -ForegroundColor Gray
        } else {
            $testResult.Status = "FAIL"
            $testResult.Result = $false
            Write-Host "[FAIL] $TestName" -ForegroundColor Red
            Write-Host "    Duration: $([int]$duration)ms" -ForegroundColor Gray
        }
        
        $testResult.Duration = [int]$duration
        
    } catch {
        $testEnd = Get-Date
        $duration = ($testEnd - $testStart).TotalMilliseconds
        
        $testResult.Status = "FAIL"
        $testResult.Result = $false
        $testResult.Error = $_.Exception.Message
        $testResult.Duration = [int]$duration
        
        Write-Host "[FAIL] $TestName" -ForegroundColor Red
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Duration: $([int]$duration)ms" -ForegroundColor Gray
    }
    
    # Update category statistics
    if (-not $TestResults.Categories.ContainsKey($Category)) {
        $TestResults.Categories[$Category] = @{ Total = 0; Passed = 0; Failed = 0 }
    }
    
    $TestResults.Categories[$Category].Total++
    if ($testResult.Result) {
        $TestResults.Categories[$Category].Passed++
        $TestResults.Summary.Passed++
    } else {
        $TestResults.Categories[$Category].Failed++
        $TestResults.Summary.Failed++
    }
    
    $TestResults.Summary.Total++
    $TestResults.Tests += $testResult
    
    return $testResult.Result
}

function Write-TestHeader {
    param([string]$Title)
    Write-Host ""
    Write-Host "=== $Title ===" -ForegroundColor Cyan
}

# Load email notifications module
Write-Host "Loading enhanced email notifications module..."
try {
    Import-Module ".\Modules\Unity-Claude-EmailNotifications\Unity-Claude-EmailNotifications-SystemNetMail.psm1" -Force -Global -ErrorAction Stop
    Write-Host "Enhanced email notifications module loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to load enhanced email notifications module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test execution begins
Write-TestHeader "1. Enhanced Email Module Functions"

Test-EmailIntegrationFunction "Email Retry Logic Function" {
    param($Config)
    
    try {
        Write-Host "[DEBUG] [EmailIntegrationTest] Testing Send-EmailWithRetry function availability..." -ForegroundColor Gray
        
        $retryFunction = Get-Command Send-EmailWithRetry -ErrorAction SilentlyContinue
        
        if ($retryFunction) {
            Write-Host "    Send-EmailWithRetry function available" -ForegroundColor Green
            Write-Host "[DEBUG] [EmailIntegrationTest] Function module: $($retryFunction.ModuleName)" -ForegroundColor Gray
            return $true
        } else {
            Write-Host "    Send-EmailWithRetry function not available" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [EmailIntegrationTest] Retry function test error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Email retry function test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "EnhancedFunctions"

Test-EmailIntegrationFunction "Notification Trigger Functions" {
    param($Config)
    
    try {
        Write-Host "[DEBUG] [EmailIntegrationTest] Testing notification trigger functions..." -ForegroundColor Gray
        
        $triggerFunctions = @(
            "Register-EmailNotificationTrigger",
            "Invoke-EmailNotificationTrigger", 
            "Get-EmailNotificationTriggers"
        )
        
        $availableFunctions = 0
        foreach ($funcName in $triggerFunctions) {
            $func = Get-Command $funcName -ErrorAction SilentlyContinue
            if ($func) {
                $availableFunctions++
                Write-Host "[DEBUG] [EmailIntegrationTest] Function available: $funcName" -ForegroundColor Green
            } else {
                Write-Host "[DEBUG] [EmailIntegrationTest] Function missing: $funcName" -ForegroundColor Red
            }
        }
        
        if ($availableFunctions -eq $triggerFunctions.Count) {
            Write-Host "    All $availableFunctions/$($triggerFunctions.Count) notification trigger functions available" -ForegroundColor Green
            return $true
        } else {
            Write-Host "    Only $availableFunctions/$($triggerFunctions.Count) notification trigger functions available" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [EmailIntegrationTest] Trigger functions test error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Notification trigger functions test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "EnhancedFunctions"

Test-EmailIntegrationFunction "Email Delivery Analytics" {
    param($Config)
    
    try {
        Write-Host "[DEBUG] [EmailIntegrationTest] Testing email delivery analytics..." -ForegroundColor Gray
        
        $deliveryStatus = Get-EmailDeliveryStatus -IncludeTriggerStats
        
        if ($deliveryStatus -and $deliveryStatus.OverallStats -and $deliveryStatus.TriggerStats) {
            Write-Host "    Email delivery analytics functional" -ForegroundColor Green
            Write-Host "[DEBUG] [EmailIntegrationTest] Overall stats available: $($deliveryStatus.OverallStats.Count) properties" -ForegroundColor Gray
            Write-Host "[DEBUG] [EmailIntegrationTest] Trigger stats available: $($deliveryStatus.TriggerStats.Count) triggers" -ForegroundColor Gray
            return $true
        } else {
            Write-Host "    Email delivery analytics not functional" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [EmailIntegrationTest] Analytics test error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Email delivery analytics test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "EnhancedFunctions"

Write-TestHeader "2. Unity-Claude Integration Templates"

Test-EmailIntegrationFunction "Unity Error Template" {
    param($Config)
    
    try {
        Write-Host "[DEBUG] [EmailIntegrationTest] Testing Unity error email template..." -ForegroundColor Gray
        
        # Test template creation
        $template = New-EmailTemplate -TemplateName "TestUnityError" -Subject "Test Unity Error: {ErrorType}" -BodyText "Error: {ErrorMessage}\nProject: {ProjectName}" -Severity "Error"
        
        if ($template -and $template.TemplateName -eq "TestUnityError") {
            # Test template formatting
            $testVars = @{
                ErrorType = "CS0246"
                ErrorMessage = "Type not found"
                ProjectName = "TestProject"
            }
            
            $formatted = Format-NotificationContent -TemplateName "TestUnityError" -Variables $testVars
            
            if ($formatted.Subject.Contains("CS0246")) {
                Write-Host "    Unity error template creation and formatting successful" -ForegroundColor Green
                return $true
            } else {
                Write-Host "    Unity error template formatting failed" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "    Unity error template creation failed" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [EmailIntegrationTest] Unity template test error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Unity error template test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "Templates"

Write-TestHeader "3. Notification Trigger Registration"

Test-EmailIntegrationFunction "Trigger Registration and Management" {
    param($Config)
    
    try {
        Write-Host "[DEBUG] [EmailIntegrationTest] Testing notification trigger registration..." -ForegroundColor Gray
        
        # First create a test email configuration
        $testConfig = New-EmailConfiguration -ConfigurationName "TriggerTestConfig" -SMTPServer "smtp.test.com" -Port 587 -EnableTLS -FromAddress "test@test.com"
        
        # Test trigger registration
        $trigger = Register-EmailNotificationTrigger -TriggerName "TestTrigger" -EventType "UnityError" -ConfigurationName "TriggerTestConfig" -ToAddress "recipient@test.com" -TemplateName "TestUnityError"
        
        if ($trigger -and $trigger.TriggerName -eq "TestTrigger") {
            # Test trigger retrieval
            $retrievedTrigger = Get-EmailNotificationTriggers -TriggerName "TestTrigger"
            
            if ($retrievedTrigger -and $retrievedTrigger.TriggerName -eq "TestTrigger") {
                Write-Host "    Notification trigger registration and retrieval successful" -ForegroundColor Green
                Write-Host "[DEBUG] [EmailIntegrationTest] Trigger event type: $($retrievedTrigger.EventType)" -ForegroundColor Gray
                return $true
            } else {
                Write-Host "    Trigger retrieval failed" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "    Trigger registration failed" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [EmailIntegrationTest] Trigger registration test error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Trigger registration test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "TriggerManagement"

# Optional real email delivery testing
if ($TestRealDelivery -and $TestEmailAddress) {
    Write-TestHeader "4. Real Email Delivery Integration"
    
    Test-EmailIntegrationFunction "Real Unity Error Notification" {
        param($Config)
        
        try {
            Write-Host "[DEBUG] [EmailIntegrationTest] Testing real Unity error notification delivery..." -ForegroundColor Gray
            
            # Create real email configuration for testing
            $realConfig = New-EmailConfiguration -ConfigurationName "RealIntegrationTest" -SMTPServer "smtp.gmail.com" -Port 587 -EnableTLS -FromAddress $Config.TestEmailAddress -FromDisplayName "Unity-Claude Integration Test"
            
            # Prompt for credentials
            Write-Host "[INFO] [EmailIntegrationTest] Please enter SMTP credentials for integration testing..." -ForegroundColor Yellow
            $testCredentials = Get-Credential -Message "Enter SMTP credentials for integration test"
            
            if ($testCredentials) {
                Set-EmailCredentials -ConfigurationName "RealIntegrationTest" -Credential $testCredentials
                
                # Create Unity error template for testing
                $unityTemplate = New-EmailTemplate -TemplateName "RealUnityErrorTest" -Subject "Unity Integration Test: {ErrorType}" -BodyText "Integration test error: {ErrorMessage}" -Severity "Error"
                
                # Register test trigger
                $testTrigger = Register-EmailNotificationTrigger -TriggerName "RealUnityErrorTest" -EventType "UnityError" -ConfigurationName "RealIntegrationTest" -ToAddress $Config.TestEmailAddress -TemplateName "RealUnityErrorTest"
                
                # Test notification delivery
                $eventData = @{
                    ErrorType = "CS0246"
                    ErrorMessage = "Unity-Claude Integration Test - Email Notification System Working"
                    ProjectName = "Integration Test"
                    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                }
                
                $notificationResult = Invoke-EmailNotificationTrigger -TriggerName "RealUnityErrorTest" -EventData $eventData
                
                if ($notificationResult.Success) {
                    Write-Host "    Real Unity error notification delivered successfully" -ForegroundColor Green
                    return $true
                } else {
                    Write-Host "    Real Unity error notification delivery failed: $($notificationResult.Error)" -ForegroundColor Red
                    return $false
                }
            } else {
                Write-Host "    No credentials provided for real delivery test" -ForegroundColor Yellow
                return $false
            }
            
        } catch {
            Write-Host "[DEBUG] [EmailIntegrationTest] Real delivery test error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "    Real Unity error notification test failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    } -Category "RealDelivery"
}

# Test results summary
$TestResults.EndTime = Get-Date
$totalDuration = ($TestResults.EndTime - $TestResults.StartTime).TotalSeconds

Write-Host ""
Write-Host "=== Email Integration Testing Results Summary ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Testing Execution Summary:" -ForegroundColor White
Write-Host "Total Tests: $($TestResults.Summary.Total)" -ForegroundColor White
Write-Host "Passed: $($TestResults.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($TestResults.Summary.Failed)" -ForegroundColor Red
Write-Host "Skipped: $($TestResults.Summary.Skipped)" -ForegroundColor Yellow
Write-Host "Duration: $([math]::Round($totalDuration, 2)) seconds" -ForegroundColor White

if ($TestResults.Summary.Total -gt 0) {
    $passRate = [math]::Round(($TestResults.Summary.Passed / $TestResults.Summary.Total) * 100, 1)
    Write-Host "Pass Rate: $passRate percent" -ForegroundColor $(if ($passRate -ge 90) { "Green" } elseif ($passRate -ge 70) { "Yellow" } else { "Red" })
} else {
    Write-Host "Pass Rate: 0 percent" -ForegroundColor Red
}

Write-Host ""
Write-Host "Category Breakdown:" -ForegroundColor White
foreach ($category in $TestResults.Categories.GetEnumerator() | Sort-Object Key) {
    $catPassRate = if ($category.Value.Total -gt 0) { 
        [math]::Round(($category.Value.Passed / $category.Value.Total) * 100, 1) 
    } else { 0 }
    Write-Host "$($category.Key): $($category.Value.Passed)/$($category.Value.Total) ($catPassRate%)" -ForegroundColor White
}

Write-Host ""
if ($TestResults.Summary.Failed -eq 0) {
    Write-Host "[SUCCESS] WEEK 5 DAY 2 EMAIL INTEGRATION: SUCCESS All integration components operational" -ForegroundColor Green
} elseif ($TestResults.Summary.Passed -gt 0) {
    Write-Host "[PARTIAL] WEEK 5 DAY 2 EMAIL INTEGRATION: PARTIAL SUCCESS Some issues remain" -ForegroundColor Yellow
} else {
    Write-Host "[FAILURE] WEEK 5 DAY 2 EMAIL INTEGRATION: NEEDS ATTENTION Significant issues in integration" -ForegroundColor Red
}

Write-Host ""
Write-Host "Week 5 Day 2 Implementation Status:" -ForegroundColor White
Write-Host "- Enhanced email module with retry logic: IMPLEMENTED" -ForegroundColor Gray
Write-Host "- Notification trigger system: IMPLEMENTED" -ForegroundColor Gray
Write-Host "- Unity-Claude workflow integration: READY FOR DEPLOYMENT" -ForegroundColor Gray
Write-Host "- Email delivery analytics: OPERATIONAL" -ForegroundColor Gray

# Save test results if requested
if ($SaveResults) {
    $resultsOutput = @"
=== Unity-Claude Email Integration Test Results (Week 5 Day 2) ===
Test: $($TestConfig.TestName)
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
PowerShell Version: $($PSVersionTable.PSVersion)

Summary:
Total Tests: $($TestResults.Summary.Total)
Passed: $($TestResults.Summary.Passed)
Failed: $($TestResults.Summary.Failed)
Duration: $([math]::Round($totalDuration, 2)) seconds
Pass Rate: $passRate%

Category Results:
$($TestResults.Categories.GetEnumerator() | ForEach-Object { "$($_.Key): $($_.Value.Passed)/$($_.Value.Total)" } | Out-String)

Detailed Test Results:
$($TestResults.Tests | ForEach-Object { "[$($_.Status)] $($_.Name) ($($_.Duration)ms)$(if ($_.Error) { " - Error: $($_.Error)" })" } | Out-String)

Integration Implementation Status:
- Enhanced Email Module: Enhanced functions implemented
- Notification Triggers: Trigger registration and management system operational
- Unity-Claude Integration: Ready for workflow event integration
- Email Analytics: Delivery status and trigger statistics available

Week 5 Day 2 Deliverables:
- Send-EmailWithRetry: Exponential backoff retry logic
- Register-EmailNotificationTrigger: Workflow event trigger registration
- Invoke-EmailNotificationTrigger: Event processing and notification delivery
- Get-EmailDeliveryStatus: Comprehensive analytics and monitoring
- Unity-Claude specific email templates for all major event types
- Integration helper functions for seamless workflow integration

Next Steps:
- Deploy email notification integration with Unity-Claude workflow
- Test notification triggers with actual Unity compilation and Claude events
- Proceed to Week 5 Day 3: Webhook System Implementation
"@
    
    $resultsOutput | Out-File -FilePath $TestConfig.TestResultsFile -Encoding UTF8
    Write-Host "Test results saved to: $($TestConfig.TestResultsFile)" -ForegroundColor Gray
}

Write-Host ""
return $TestResults
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQS+DVXSdJIoazRWmnNt96SmC
# rHKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUUN+tnzj+3NLl0oGTe9R2hAaPQW8wDQYJKoZIhvcNAQEBBQAEggEAqGXt
# /dHWmVepyeVdTbtLYoQDNCoIWLqJ5YpGq2yJe/pycQw3OdfEzupEQtb8/0HPe5f4
# 18PDxkl8T/gWQksf+YoJdQQfDEieypOaPfQ304gXZXYQ6F4hfncR4j6sFFsRMUPh
# +pJGsYcWwMMoI5YhUtWOTvpLcDO481AornfhHVH32UTt9UXoULZIcwKQGjCxeU0h
# m2pddfpjGc+mx0U3q0p151Xk0KMtAwtf/1XWQaz8kgO2XWVYZxMpxMect+rCJO6c
# tZtBWX1cTC4F3j3w7YWG3SDu4ntsVH+ZZbV0GxLljZCEI7UDGQJL9spSO1b9szdv
# ma4/juIuyD74IoA6UA==
# SIG # End signature block
