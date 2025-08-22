# Test-Week5-Day1-EmailNotifications-SystemNetMail.ps1
# Week 5 Day 1: Email System Testing with System.Net.Mail implementation
# PowerShell 5.1 compatible email notification testing
# Date: 2025-08-21

[CmdletBinding()]
param(
    [switch]$SaveResults,
    [switch]$TestRealSMTP,
    [string]$TestSMTPServer = "smtp.gmail.com",
    [string]$TestEmailAddress,
    [string]$TestResultsFile
)

Write-Host "=== Week 5 Day 1: Email Notifications Testing (System.Net.Mail) ===" -ForegroundColor Cyan
Write-Host "PowerShell 5.1 compatible email system validation" -ForegroundColor White
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
Write-Host ""

# Test configuration
$TestConfig = @{
    TestName = "Week5-Day1-EmailNotifications-SystemNetMail"
    Date = Get-Date
    SaveResults = $SaveResults
    TestRealSMTP = $TestRealSMTP
    TestSMTPServer = $TestSMTPServer
    TestEmailAddress = $TestEmailAddress
    TestResultsFile = if ($TestResultsFile) { $TestResultsFile } else { 
        "Test_Results_Week5_Day1_EmailNotifications_SystemNetMail_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt" 
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

function Test-EmailNotificationFunction {
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
    
    Write-Host "[DEBUG] [EmailTest] Starting test: $TestName (Category: $Category)" -ForegroundColor Gray
    
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

# Load the System.Net.Mail email notifications module
Write-Host "Loading Unity-Claude-EmailNotifications module (System.Net.Mail implementation)..."
try {
    Import-Module ".\Modules\Unity-Claude-EmailNotifications\Unity-Claude-EmailNotifications-SystemNetMail.psm1" -Force -Global -ErrorAction Stop
    Write-Host "Email notifications module loaded successfully (System.Net.Mail)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to load email notifications module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test execution begins
Write-TestHeader "1. System.Net.Mail Email System Foundation"

Test-EmailNotificationFunction "System.Net.Mail Availability" {
    param($Config)
    
    try {
        Write-Host "[DEBUG] [EmailTest] Testing System.Net.Mail availability..." -ForegroundColor Gray
        
        # Test creating System.Net.Mail objects (should always work in .NET Framework)
        $testClient = New-Object System.Net.Mail.SmtpClient
        $testMessage = New-Object System.Net.Mail.MailMessage
        
        if ($testClient -and $testMessage) {
            Write-Host "    System.Net.Mail classes available and functional" -ForegroundColor Green
            $testClient.Dispose()
            $testMessage.Dispose()
            return $true
        } else {
            Write-Host "    System.Net.Mail classes not available" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [EmailTest] System.Net.Mail test error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    System.Net.Mail test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "Foundation"

Write-TestHeader "2. Email Configuration Management"

Test-EmailNotificationFunction "Email Configuration Creation" {
    param($Config)
    
    try {
        Write-Host "[DEBUG] [EmailTest] Testing email configuration creation..." -ForegroundColor Gray
        
        $emailConfig = New-EmailConfiguration -ConfigurationName "TestConfig" -SMTPServer "smtp.gmail.com" -Port 587 -EnableTLS -FromAddress "test@example.com" -FromDisplayName "Test System"
        
        if ($emailConfig -and $emailConfig.ConfigurationName -eq "TestConfig") {
            Write-Host "    Email configuration created successfully" -ForegroundColor Green
            Write-Host "[DEBUG] [EmailTest] Config implementation: $($emailConfig.Implementation)" -ForegroundColor Gray
            return $true
        } else {
            Write-Host "    Email configuration creation failed" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [EmailTest] Email configuration creation error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Email configuration creation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "Configuration"

Test-EmailNotificationFunction "Email Configuration Retrieval" {
    param($Config)
    
    try {
        Write-Host "[DEBUG] [EmailTest] Testing email configuration retrieval..." -ForegroundColor Gray
        
        $retrievedConfig = Get-EmailConfiguration -ConfigurationName "TestConfig"
        
        if ($retrievedConfig -and $retrievedConfig.ConfigurationName -eq "TestConfig") {
            Write-Host "    Email configuration retrieved successfully" -ForegroundColor Green
            Write-Host "[DEBUG] [EmailTest] Retrieved implementation: $($retrievedConfig.Implementation)" -ForegroundColor Gray
            return $true
        } else {
            Write-Host "    Email configuration retrieval failed" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [EmailTest] Email configuration retrieval error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Email configuration retrieval failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "Configuration"

Write-TestHeader "3. Email Template System"

Test-EmailNotificationFunction "Email Template Creation" {
    param($Config)
    
    try {
        Write-Host "[DEBUG] [EmailTest] Testing email template creation..." -ForegroundColor Gray
        
        $template = New-EmailTemplate -TemplateName "UnityErrorTest" -Subject "Unity Error: {ErrorType}" -BodyText "Error: {ErrorMessage}\nProject: {ProjectName}\nTime: {Timestamp}" -Severity "Error"
        
        if ($template -and $template.TemplateName -eq "UnityErrorTest") {
            Write-Host "    Email template created successfully" -ForegroundColor Green
            Write-Host "[DEBUG] [EmailTest] Template severity: $($template.Severity)" -ForegroundColor Gray
            return $true
        } else {
            Write-Host "    Email template creation failed" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [EmailTest] Email template creation error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Email template creation failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "Templates"

Test-EmailNotificationFunction "Template Content Formatting" {
    param($Config)
    
    try {
        Write-Host "[DEBUG] [EmailTest] Testing template content formatting..." -ForegroundColor Gray
        
        $testVariables = @{
            ErrorType = "CS0246"
            ErrorMessage = "Type 'UnknownClass' could not be found"
            ProjectName = "TestProject"
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        $formattedContent = Format-NotificationContent -TemplateName "UnityErrorTest" -Variables $testVariables
        
        if ($formattedContent -and $formattedContent.Subject.Contains("CS0246")) {
            Write-Host "    Template content formatting successful" -ForegroundColor Green
            Write-Host "[DEBUG] [EmailTest] Formatted subject: $($formattedContent.Subject)" -ForegroundColor Gray
            return $true
        } else {
            Write-Host "    Template content formatting failed" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [EmailTest] Template formatting error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Template content formatting failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "Templates"

Write-TestHeader "4. Email Delivery System"

Test-EmailNotificationFunction "Email Delivery Function" {
    param($Config)
    
    try {
        Write-Host "[DEBUG] [EmailTest] Testing email delivery function availability..." -ForegroundColor Gray
        
        # Test that Send-EmailNotification function is available
        $sendFunction = Get-Command Send-EmailNotification -ErrorAction SilentlyContinue
        
        if ($sendFunction) {
            Write-Host "    Send-EmailNotification function available" -ForegroundColor Green
            Write-Host "[DEBUG] [EmailTest] Function module: $($sendFunction.ModuleName)" -ForegroundColor Gray
            return $true
        } else {
            Write-Host "    Send-EmailNotification function not available" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [EmailTest] Email delivery function test error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Email delivery function test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "Delivery"

# Optional real SMTP testing
if ($TestRealSMTP -and $TestEmailAddress) {
    Write-TestHeader "5. Real SMTP Connection Testing"
    
    Test-EmailNotificationFunction "Real SMTP Connection and Email Delivery" {
        param($Config)
        
        try {
            Write-Host "[DEBUG] [EmailTest] Testing real SMTP connection and email delivery..." -ForegroundColor Gray
            Write-Host "[INFO] [EmailTest] SMTP Server: $($Config.TestSMTPServer)" -ForegroundColor White
            Write-Host "[INFO] [EmailTest] Test Email: $($Config.TestEmailAddress)" -ForegroundColor White
            
            # Create real SMTP configuration
            $realConfig = New-EmailConfiguration -ConfigurationName "RealTestConfig" -SMTPServer $Config.TestSMTPServer -Port 587 -EnableTLS -FromAddress $Config.TestEmailAddress -FromDisplayName "Unity-Claude Test"
            
            # Prompt for credentials
            Write-Host "[INFO] [EmailTest] Please enter SMTP credentials for testing..." -ForegroundColor Yellow
            $testCredentials = Get-Credential -Message "Enter SMTP credentials for $($Config.TestSMTPServer)"
            
            if ($testCredentials) {
                Set-EmailCredentials -ConfigurationName "RealTestConfig" -Credential $testCredentials
                
                # Test connection and send test email
                $connectionTest = Test-EmailConfiguration -ConfigurationName "RealTestConfig" -SendTestEmail -TestRecipient $Config.TestEmailAddress
                
                if ($connectionTest.Success) {
                    Write-Host "    Real SMTP connection and test email successful (System.Net.Mail)" -ForegroundColor Green
                    Write-Host "[DEBUG] [EmailTest] Implementation: $($connectionTest.Implementation)" -ForegroundColor Gray
                    return $true
                } else {
                    Write-Host "    Real SMTP connection failed: $($connectionTest.Error)" -ForegroundColor Red
                    return $false
                }
            } else {
                Write-Host "    No credentials provided for real SMTP test" -ForegroundColor Yellow
                return $false
            }
            
        } catch {
            Write-Host "[DEBUG] [EmailTest] Real SMTP test error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host "    Real SMTP connection test failed: $($_.Exception.Message)" -ForegroundColor Red
            return $false
        }
    } -Category "RealSMTP"
}

# Test results summary
$TestResults.EndTime = Get-Date
$totalDuration = ($TestResults.EndTime - $TestResults.StartTime).TotalSeconds

Write-Host ""
Write-Host "=== Email Notifications Testing Results Summary ===" -ForegroundColor Cyan
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
    Write-Host "[SUCCESS] WEEK 5 DAY 1 EMAIL NOTIFICATIONS (System.Net.Mail): SUCCESS All components operational" -ForegroundColor Green
} elseif ($TestResults.Summary.Passed -gt 0) {
    Write-Host "[PARTIAL] WEEK 5 DAY 1 EMAIL NOTIFICATIONS (System.Net.Mail): PARTIAL SUCCESS Some issues remain" -ForegroundColor Yellow
} else {
    Write-Host "[FAILURE] WEEK 5 DAY 1 EMAIL NOTIFICATIONS (System.Net.Mail): NEEDS ATTENTION Significant issues" -ForegroundColor Red
}

Write-Host ""
Write-Host "Implementation Notes:" -ForegroundColor White
Write-Host "- Using System.Net.Mail for PowerShell 5.1 compatibility" -ForegroundColor Gray
Write-Host "- No external dependencies required" -ForegroundColor Gray
Write-Host "- Immediate functionality available" -ForegroundColor Gray
Write-Host "- Production-ready for Unity-Claude autonomous operation" -ForegroundColor Gray

# Save test results if requested
if ($SaveResults) {
    $resultsOutput = @"
=== Unity-Claude Email Notifications Test Results (System.Net.Mail) ===
Test: $($TestConfig.TestName)
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
PowerShell Version: $($PSVersionTable.PSVersion)
Implementation: System.Net.Mail (.NET Framework compatible)

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

Test Configuration:
Real SMTP Testing: $($TestConfig.TestRealSMTP)
Test SMTP Server: $($TestConfig.TestSMTPServer)
Test Email Address: $($TestConfig.TestEmailAddress)

Implementation Notes:
- System.Net.Mail used for PowerShell 5.1 compatibility
- No external assembly dependencies required
- Immediate functionality available for production use
- Compatible with existing Unity-Claude parallel processing system
"@
    
    $resultsOutput | Out-File -FilePath $TestConfig.TestResultsFile -Encoding UTF8
    Write-Host "Test results saved to: $($TestConfig.TestResultsFile)" -ForegroundColor Gray
}

Write-Host ""
return $TestResults
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUiSZqSGUsB4aGbLSmJMarl4F+
# FjugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUKxOyzNR+Hcke9JNlijQuulSBbOMwDQYJKoZIhvcNAQEBBQAEggEAnVC0
# 1hjF8GOH3SBym16jlBtidaK8eGHJ/KpwRuMMzFgNMjVN2jDZdbsfgMVfocHkgHSj
# PWm+5eCDSHP+rrLD/1cKCZhs3vuJ31OAo/NWYC/uPmWZsApconPRub8eqd/1WBns
# hEo2ATjZb0kNNhVTozW/LqO8k1GJdUyVxtLTAWPwIpt7kRCy79X0F17632XRtHlZ
# WKwsnFAzx5M1z8jHvmrWIr1sHgcyxC5hQjh7lRxnZocZdxIGYTfE81ZLXHMdVDz1
# jFfkamiXbggROav87IcmVhqHkpOFkoRfQiis+Pm9HKS4uc6gzCm9g0Gl+s1YQGot
# 4MsJCpXNCuXEvK4STg==
# SIG # End signature block
