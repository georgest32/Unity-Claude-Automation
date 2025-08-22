# Test-Week6-Days1-2-SystemIntegration.ps1
# Week 6 Days 1-2: System Integration Test
# Tests notification integration with Unity-Claude autonomous workflow
# Date: 2025-08-21

[CmdletBinding()]
param(
    [switch]$SaveResults
)

Write-Host "=== Week 6 Days 1-2: System Integration Test ===" -ForegroundColor Cyan
Write-Host "Testing notification integration with autonomous workflow" -ForegroundColor Green
Write-Host "Date: $(Get-Date)" -ForegroundColor Green

# Configure PSModulePath
$env:PSModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules;" + $env:PSModulePath

# Test results tracking
$TestResults = @{
    TestName = "Week6-Days1-2-SystemIntegration"
    StartTime = Get-Date
    Tests = @()
    Categories = @{
        ModuleLoading = @{Passed = 0; Failed = 0; Total = 0}
        NotificationSetup = @{Passed = 0; Failed = 0; Total = 0}
        IntegrationTriggers = @{Passed = 0; Failed = 0; Total = 0}
        SystemIntegration = @{Passed = 0; Failed = 0; Total = 0}
    }
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Duration = 0
        PassRate = 0
    }
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Message = "",
        [int]$Duration = 0,
        [string]$Category = "General"
    )
    
    $status = if ($Success) { "PASS" } else { "FAIL" }
    $color = if ($Success) { "Green" } else { "Red" }
    
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Message) {
        Write-Host "    $Message" -ForegroundColor Gray
    }
    if ($Duration -gt 0) {
        Write-Host "    Duration: ${Duration}ms" -ForegroundColor Gray
    }
    
    $TestResults.Summary.Total++
    if ($TestResults.Categories.ContainsKey($Category)) {
        $TestResults.Categories[$Category].Total++
        if ($Success) {
            $TestResults.Summary.Passed++
            $TestResults.Categories[$Category].Passed++
        } else {
            $TestResults.Summary.Failed++
            $TestResults.Categories[$Category].Failed++
        }
    }
    
    return $Success
}

try {
    Write-Host ""
    Write-Host "=== 1. Module Loading and Dependencies ===" -ForegroundColor Cyan
    
    # Test 1: Import notification modules
    $startTime = Get-Date
    try {
        Import-Module Unity-Claude-EmailNotifications -Force -ErrorAction Stop
        Import-Module Unity-Claude-WebhookNotifications -Force -ErrorAction Stop
        Import-Module Unity-Claude-NotificationContentEngine -Force -ErrorAction Stop
        Import-Module Unity-Claude-SystemStatus -Force -ErrorAction Stop
        $success = $true
        $message = "All notification modules imported successfully"
    } catch {
        $success = $false
        $message = "Module import failed: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Notification Modules Import" $success $message $duration "ModuleLoading"
    
    # Test 2: Import integration module
    $startTime = Get-Date
    try {
        Import-Module Unity-Claude-NotificationIntegration -Force -ErrorAction Stop
        $success = $true
        $message = "NotificationIntegration module imported successfully"
    } catch {
        $success = $false
        $message = "Integration module import failed: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Integration Module Import" $success $message $duration "ModuleLoading"
    
    Write-Host ""
    Write-Host "=== 2. Notification Integration Setup ===" -ForegroundColor Cyan
    
    # Test 3: Initialize notification integration
    $startTime = Get-Date
    try {
        $initResult = Initialize-NotificationIntegration -EnabledTriggers @("UnityError", "ClaudeSubmission", "WorkflowStatus", "SystemHealth")
        $success = ($initResult -and $initResult.Success)
        $message = if ($success) { 
            "Integration initialized: Email=$($initResult.EmailEnabled), Webhook=$($initResult.WebhookEnabled)" 
        } else { 
            "Integration initialization failed: $($initResult.Error)" 
        }
    } catch {
        $success = $false
        $message = "Integration initialization error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Notification Integration Initialization" $success $message $duration "NotificationSetup"
    
    # Test 4: Verify system status registration
    $startTime = Get-Date
    try {
        $status = Read-SystemStatus
        $hasIntegration = ($status -and $status.Subsystems -and $status.Subsystems.ContainsKey("NotificationIntegration"))
        $success = $hasIntegration
        $message = if ($success) { 
            "NotificationIntegration registered in SystemStatus" 
        } else { 
            "NotificationIntegration not found in SystemStatus" 
        }
    } catch {
        $success = $false
        $message = "SystemStatus check error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "SystemStatus Registration" $success $message $duration "NotificationSetup"
    
    Write-Host ""
    Write-Host "=== 3. Integration Trigger Testing ===" -ForegroundColor Cyan
    
    # Test 5: Unity error notification trigger
    $startTime = Get-Date
    try {
        $result = Send-UnityErrorNotification -ErrorDetails @{
            ErrorType = "CS0246"
            Message = "The type or namespace name 'TestClass' could not be found"
            File = "Assets/Scripts/TestScript.cs"
            Line = 15
            Column = 12
        } -Severity "Error"
        
        $success = ($result -ne $null)
        $message = if ($success) { 
            "Unity error notification sent successfully" 
        } else { 
            "Unity error notification failed" 
        }
    } catch {
        $success = $false
        $message = "Unity error notification error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Unity Error Notification Trigger" $success $message $duration "IntegrationTriggers"
    
    # Test 6: Claude submission notification trigger
    $startTime = Get-Date
    try {
        $result = Send-ClaudeSubmissionNotification -SubmissionResult @{
            Response = "I've analyzed the CS0246 error and created a fix by adding the missing using statement."
            Timestamp = Get-Date
            FixApplied = $true
            ErrorsFixed = 1
        } -IsSuccess $true
        
        $success = ($result -ne $null)
        $message = if ($success) { 
            "Claude submission notification sent successfully" 
        } else { 
            "Claude submission notification failed" 
        }
    } catch {
        $success = $false
        $message = "Claude submission notification error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Claude Submission Notification Trigger" $success $message $duration "IntegrationTriggers"
    
    Write-Host ""
    Write-Host "=== 4. Full Integration Test ===" -ForegroundColor Cyan
    
    # Test 7: Complete integration test
    $startTime = Get-Date
    try {
        $testResult = Test-NotificationIntegration
        $success = ($testResult -and $testResult.UnityError -and $testResult.ClaudeSubmission)
        $message = if ($success) { 
            "Complete integration test passed" 
        } else { 
            "Integration test failed or incomplete" 
        }
    } catch {
        $success = $false
        $message = "Integration test error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Complete Integration Test" $success $message $duration "SystemIntegration"
    
    # Test 8: System health check
    $startTime = Get-Date
    try {
        # Verify all notification channels are working
        $emailWorks = (Get-Command Send-EmailNotification -ErrorAction SilentlyContinue) -ne $null
        $webhookWorks = (Get-Command Send-WebhookNotification -ErrorAction SilentlyContinue) -ne $null
        $contentEngineWorks = (Get-Command New-NotificationContent -ErrorAction SilentlyContinue) -ne $null
        
        $success = ($emailWorks -and $webhookWorks -and $contentEngineWorks)
        $message = "Email: $emailWorks, Webhook: $webhookWorks, ContentEngine: $contentEngineWorks"
    } catch {
        $success = $false
        $message = "System health check error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "System Health Check" $success $message $duration "SystemIntegration"
    
    # Calculate final results
    $TestResults.EndTime = Get-Date
    $TestResults.Summary.Duration = (($TestResults.EndTime - $TestResults.StartTime).TotalSeconds)
    $TestResults.Summary.PassRate = if ($TestResults.Summary.Total -gt 0) { 
        [math]::Round(($TestResults.Summary.Passed / $TestResults.Summary.Total) * 100, 2) 
    } else { 0 }
    
    # Display summary
    Write-Host ""
    Write-Host "=== Week 6 Days 1-2 System Integration Results Summary ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Testing Execution Summary:" -ForegroundColor White
    Write-Host "Total Tests: $($TestResults.Summary.Total)" -ForegroundColor White
    Write-Host "Passed: $($TestResults.Summary.Passed)" -ForegroundColor Green
    Write-Host "Failed: $($TestResults.Summary.Failed)" -ForegroundColor Red
    Write-Host "Duration: $($TestResults.Summary.Duration) seconds" -ForegroundColor White
    Write-Host "Pass Rate: $($TestResults.Summary.PassRate)%" -ForegroundColor $(if ($TestResults.Summary.PassRate -ge 80) { "Green" } else { "Red" })
    
    Write-Host ""
    Write-Host "Category Breakdown:" -ForegroundColor White
    foreach ($category in $TestResults.Categories.GetEnumerator()) {
        $cat = $category.Value
        $catPassRate = if ($cat.Total -gt 0) { [math]::Round(($cat.Passed / $cat.Total) * 100, 2) } else { 0 }
        $color = if ($catPassRate -ge 80) { "Green" } else { "Red" }
        Write-Host "$($category.Key): $($cat.Passed)/$($cat.Total) ($catPassRate%)" -ForegroundColor $color
    }
    
    # Final status
    if ($TestResults.Summary.PassRate -ge 80) {
        Write-Host ""
        Write-Host "WEEK 6 DAYS 1-2 SYSTEM INTEGRATION: SUCCESS" -ForegroundColor Green
        Write-Host "Notification system successfully integrated with autonomous workflow" -ForegroundColor Green
    } else {
        Write-Host ""
        Write-Host "WEEK 6 DAYS 1-2 SYSTEM INTEGRATION: PARTIAL SUCCESS" -ForegroundColor Yellow
        Write-Host "Some integration components need attention" -ForegroundColor Yellow
    }
    
    # Save results if requested
    if ($SaveResults) {
        $resultsFile = "Week6Days1-2_SystemIntegration_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $TestResults | ConvertTo-Json -Depth 3 | Out-File $resultsFile
        Write-Host "Results saved to: $resultsFile" -ForegroundColor Green
    }
    
} catch {
    Write-Host "=== WEEK 6 DAYS 1-2 SYSTEM INTEGRATION: FAILED ===" -ForegroundColor Red
    Write-Host "Critical error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6qZt3uZYROPdJafarGC/8+m/
# c5egggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU3U9ld6usvRvp7wB9kzK5iRm0snAwDQYJKoZIhvcNAQEBBQAEggEAVXWi
# pluGMf01Iq03yZMXPwafF9ejYtkCVd8fANLyxh1MmCBwgi21Z9wnjY+j9iTumAtB
# YtqvS9YP3hL4ICiuVw45UrrDLQRJAGS5aY//BL1XppTuz0MhSqgZBIrWH7cHEatQ
# n3Tqal/OaZ22u8KArHeXJySF6bWFTXVG/XMkB6eeP6tmoeDodoDLloJZeNDaC+Dx
# mORxP68j2LuvnLka8IFuVf82PvpFtAMBkDu5NN0c42nf4fWH+2twyczhxoS9Q2rR
# 1kTNAvcMW/NK7OxTuJ3qJiiWk9mw4+g1bRM7gbwvlH74LIMpmtvcZVq9/txEg2fx
# LMlIAZznYLcpj6IFKw==
# SIG # End signature block
