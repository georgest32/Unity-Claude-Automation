# Test-Week5-Day1-EmailNotifications.ps1
# Week 5 Day 1: MailKit Email System Foundation Testing
# Comprehensive test suite for email notification functionality
# Date: 2025-08-21

[CmdletBinding()]
param(
    [switch]$SaveResults,
    [switch]$TestRealSMTP,
    [string]$TestSMTPServer,
    [string]$TestEmailAddress,
    [string]$TestResultsFile
)

Write-Host "=== Week 5 Day 1: Email Notifications Testing ===" -ForegroundColor Cyan
Write-Host "MailKit Email System Foundation - Comprehensive Test Suite" -ForegroundColor White
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor White
Write-Host ""

# Test configuration
$TestConfig = @{
    TestName = "Week5-Day1-EmailNotifications"
    Date = Get-Date
    SaveResults = $SaveResults
    TestRealSMTP = $TestRealSMTP
    TestSMTPServer = $TestSMTPServer
    TestEmailAddress = $TestEmailAddress
    TestResultsFile = if ($TestResultsFile) { $TestResultsFile } else { 
        "Test_Results_Week5_Day1_EmailNotifications_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt" 
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
        
        # Execute test code
        Write-Host "[DEBUG] [EmailTest] Executing test code for: $TestName" -ForegroundColor Gray
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

# Load the email notifications module
Write-Host "Loading Unity-Claude-EmailNotifications module..."
try {
    Import-Module ".\Modules\Unity-Claude-EmailNotifications\Unity-Claude-EmailNotifications.psm1" -Force -Global -ErrorAction Stop
    Write-Host "Email notifications module loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to load email notifications module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test execution begins
Write-TestHeader "1. MailKit Installation and Assembly Loading"

Test-EmailNotificationFunction "MailKit Assembly Availability" {
    param($Config)
    
    try {
        Write-Host "[DEBUG] [EmailTest] Testing MailKit assembly loading..." -ForegroundColor Gray
        
        # Check if MailKit assemblies can be loaded
        $assembliesLoaded = Load-MailKitAssemblies
        
        if ($assembliesLoaded) {
            # Test creating MailKit objects
            $testClient = New-Object MailKit.Net.Smtp.SmtpClient
            $testMessage = New-Object MimeKit.MimeMessage
            
            if ($testClient -and $testMessage) {
                Write-Host "    MailKit assemblies loaded and functional" -ForegroundColor Green
                $testClient.Dispose()
                return $true
            } else {
                Write-Host "    MailKit objects could not be created" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "    MailKit assemblies not available" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "[DEBUG] [EmailTest] MailKit assembly test error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    MailKit assembly test failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
} -Category "Installation"

Write-TestHeader "2. Email Configuration Management"

Test-EmailNotificationFunction "Email Configuration Creation" {
    param($Config)
    
    try {
        Write-Host "[DEBUG] [EmailTest] Testing email configuration creation..." -ForegroundColor Gray
        
        # Create test email configuration
        $emailConfig = New-EmailConfiguration -ConfigurationName "TestConfig" -SMTPServer "smtp.gmail.com" -Port 587 -EnableTLS -FromAddress "test@example.com" -FromDisplayName "Test System"
        
        if ($emailConfig -and $emailConfig.ConfigurationName -eq "TestConfig") {
            Write-Host "    Email configuration created successfully" -ForegroundColor Green
            Write-Host "[DEBUG] [EmailTest] Config SMTP: $($emailConfig.SMTPServer):$($emailConfig.Port)" -ForegroundColor Gray
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
        
        # Get the test configuration
        $retrievedConfig = Get-EmailConfiguration -ConfigurationName "TestConfig"
        
        if ($retrievedConfig -and $retrievedConfig.ConfigurationName -eq "TestConfig") {
            Write-Host "    Email configuration retrieved successfully" -ForegroundColor Green
            Write-Host "[DEBUG] [EmailTest] Retrieved config: $($retrievedConfig.SMTPServer):$($retrievedConfig.Port)" -ForegroundColor Gray
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
        
        # Create test email template
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
        
        # Test variable substitution
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

# Optional real SMTP testing (if credentials provided)
if ($TestRealSMTP -and $TestSMTPServer -and $TestEmailAddress) {
    Write-TestHeader "4. Real SMTP Connection Testing"
    
    Test-EmailNotificationFunction "Real SMTP Connection Test" {
        param($Config)
        
        try {
            Write-Host "[DEBUG] [EmailTest] Testing real SMTP connection..." -ForegroundColor Gray
            Write-Host "[INFO] [EmailTest] SMTP Server: $($Config.TestSMTPServer)" -ForegroundColor White
            Write-Host "[INFO] [EmailTest] Test Email: $($Config.TestEmailAddress)" -ForegroundColor White
            
            # Create real SMTP configuration
            $realConfig = New-EmailConfiguration -ConfigurationName "RealTestConfig" -SMTPServer $Config.TestSMTPServer -Port 587 -EnableTLS -FromAddress $Config.TestEmailAddress -FromDisplayName "Unity-Claude Test"
            
            # Prompt for credentials
            Write-Host "[INFO] [EmailTest] Please enter SMTP credentials for testing..." -ForegroundColor Yellow
            $testCredentials = Get-Credential -Message "Enter SMTP credentials for $($Config.TestSMTPServer)"
            
            if ($testCredentials) {
                Set-EmailCredentials -ConfigurationName "RealTestConfig" -Credential $testCredentials
                
                # Test connection
                $connectionTest = Test-EmailConfiguration -ConfigurationName "RealTestConfig" -SendTestEmail -TestRecipient $Config.TestEmailAddress
                
                if ($connectionTest.Success) {
                    Write-Host "    Real SMTP connection and test email successful" -ForegroundColor Green
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
    Write-Host "[SUCCESS] WEEK 5 DAY 1 EMAIL NOTIFICATIONS: SUCCESS All email system components operational" -ForegroundColor Green
} elseif ($TestResults.Summary.Passed -gt 0) {
    Write-Host "[PARTIAL] WEEK 5 DAY 1 EMAIL NOTIFICATIONS: PARTIAL SUCCESS Some issues remain" -ForegroundColor Yellow
} else {
    Write-Host "[FAILURE] WEEK 5 DAY 1 EMAIL NOTIFICATIONS: NEEDS ATTENTION Significant issues in email system" -ForegroundColor Red
}

# Save test results if requested
if ($SaveResults) {
    $resultsOutput = @"
=== Unity-Claude Email Notifications Test Results (Week 5 Day 1) ===
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

Test Configuration:
Real SMTP Testing: $($TestConfig.TestRealSMTP)
Test SMTP Server: $($TestConfig.TestSMTPServer)
Test Email Address: $($TestConfig.TestEmailAddress)

Notes:
- MailKit assemblies must be installed for email functionality
- Run Install-MailKitForUnityClaudeAutomation.ps1 if assembly loading fails
- Real SMTP testing requires valid credentials and server access
- Use -TestRealSMTP switch to test actual email delivery
"@
    
    $resultsOutput | Out-File -FilePath $TestConfig.TestResultsFile -Encoding UTF8
    Write-Host "Test results saved to: $($TestConfig.TestResultsFile)" -ForegroundColor Gray
}

Write-Host ""
Write-Host "[DEBUG] [EmailTest] Email notifications testing completed" -ForegroundColor Gray

return $TestResults
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUFF8Iy//pkq8vC2tGnT5cPYO2
# r62gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU1tbnZlWbqyy0/BR8qPrK+TVPgOIwDQYJKoZIhvcNAQEBBQAEggEAXx3q
# 0KYQF4twJUji6Z0A5lgs4mLd+0pamprnAhkYF2tePfuV6PJB1AfKS2IthdRibT5f
# zoBrPI59BkwTUE4SpXWJy2jnA0xLYrjfKrHY9mUqh6fZ9vCkBneKG2m10/BgV22S
# CEbqldQgCkcjCdkieOUd9dYIU3YUPkGDMchL2LefvIaobvloin6o2CvwkZDQSy//
# L0B3404MOyiZLMn0OVVAJruKeBqIBEyj8T7lZBSWVMaMfnZeJlcPwZyAvnNqH/dQ
# c/GJLKqaFQxJjyYA9lx//guHl7gX+AGiCMPWzwZU5HbQHTtB+UEQg3qbKFHEUrs1
# 8aAcaEVfrYRDqXxYYA==
# SIG # End signature block
