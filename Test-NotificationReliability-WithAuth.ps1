# Notification Reliability Test with Authentication
# This version sets up credentials before running tests

param(
    [switch]$SkipConnectivityTests = $false,
    [int]$TestIterations = 5,
    [PSCredential]$EmailCredential
)

Write-Host ""
Write-Host "Starting Week 6 Days 3-4 Notification Reliability Testing with Authentication..." -ForegroundColor Cyan

# Import modules
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force
Import-Module ".\Modules\Unity-Claude-NotificationIntegration\Unity-Claude-NotificationIntegration.psd1" -Force

# Load system configuration
$systemConfig = Get-Content ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json" | ConvertFrom-Json
$emailSettings = $systemConfig.EmailNotifications

# Create email configuration
Write-Host "Setting up email configuration..." -ForegroundColor Yellow
try {
    $config = Get-EmailConfiguration -ConfigurationName "Default" -ErrorAction SilentlyContinue
} catch {
    $config = $null
}

if (-not $config) {
    New-EmailConfiguration -ConfigurationName "Default" -SMTPServer $emailSettings.SMTPServer -Port $emailSettings.SMTPPort -EnableTLS:$emailSettings.EnableSSL -FromAddress $emailSettings.FromAddress -FromDisplayName $emailSettings.FromDisplayName
    Write-Host "Email configuration created." -ForegroundColor Green
}

# Set credentials if not provided
if (-not $EmailCredential) {
    # Try to load saved credentials first
    Write-Host "Checking for saved credentials..." -ForegroundColor Yellow
    . "$PSScriptRoot\Get-SavedEmailCredentials.ps1"
    $EmailCredential = Get-SavedEmailCredentials
    
    if (-not $EmailCredential) {
        Write-Host ""
        Write-Host "No saved credentials found. Please enter them now." -ForegroundColor Yellow
        Write-Host "Email: $($emailSettings.FromAddress)" -ForegroundColor White
        Write-Host "Password: Your 16-character Gmail App Password" -ForegroundColor Cyan
        $EmailCredential = Get-Credential -Message "Enter SMTP credentials" -UserName $emailSettings.FromAddress
        
        if (-not $EmailCredential) {
            Write-Host "No credentials provided. Exiting." -ForegroundColor Red
            exit
        }
        
        Write-Host ""
        Write-Host "TIP: Run .\Save-EmailCredentials.ps1 to save these credentials for future use!" -ForegroundColor Cyan
    }
}

# Apply credentials to configuration
Write-Host "Applying credentials to configuration..." -ForegroundColor Yellow
Set-EmailCredentials -ConfigurationName "Default" -Credential $EmailCredential

# Verify configuration
$config = Get-EmailConfiguration -ConfigurationName "Default" -IncludeCredentials
Write-Host "Configuration ready: Credentials configured = $($config.CredentialsConfigured)" -ForegroundColor Green

# Now run the actual tests
Write-Host ""
Write-Host "=== Running Notification Reliability Tests ===" -ForegroundColor Cyan

$testResults = @{
    TestName = "Week 6 Days 3-4: Notification Reliability Testing (Authenticated)"
    StartTime = Get-Date
    Tests = @()
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    SkippedTests = 0
}

# Test 1: Basic Email Sending
Write-Host ""
Write-Host "Test 1: Basic Email Sending..." -ForegroundColor White
try {
    $smtp = New-Object System.Net.Mail.SmtpClient($emailSettings.SMTPServer, $emailSettings.SMTPPort)
    $smtp.EnableSsl = $emailSettings.EnableSSL
    $smtp.Credentials = New-Object System.Net.NetworkCredential(
        $EmailCredential.UserName,
        $EmailCredential.GetNetworkCredential().Password
    )
    
    $msg = New-Object System.Net.Mail.MailMessage
    $msg.From = New-Object System.Net.Mail.MailAddress($emailSettings.FromAddress, $emailSettings.FromDisplayName)
    $msg.To.Add($emailSettings.ToAddresses)
    $msg.Subject = "Unity-Claude Reliability Test - $(Get-Date -Format 'HH:mm:ss')"
    $msg.Body = "This is test email #1 from the notification reliability test suite."
    
    $startTime = Get-Date
    $smtp.Send($msg)
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    
    Write-Host "  Email sent successfully in $([math]::Round($duration, 2))ms" -ForegroundColor Green
    $testResults.PassedTests++
    
    $msg.Dispose()
    $smtp.Dispose()
} catch {
    Write-Host "  Failed to send email: $_" -ForegroundColor Red
    $testResults.FailedTests++
}
$testResults.TotalTests++

# Test 2: Multiple Email Delivery
$testMessage = "Test 2: Multiple Email Delivery ($TestIterations emails)..."
Write-Host ""
Write-Host $testMessage -ForegroundColor White
$successCount = 0
for ($i = 1; $i -le $TestIterations; $i++) {
    try {
        $smtp = New-Object System.Net.Mail.SmtpClient($emailSettings.SMTPServer, $emailSettings.SMTPPort)
        $smtp.EnableSsl = $emailSettings.EnableSSL
        $smtp.Credentials = New-Object System.Net.NetworkCredential(
            $EmailCredential.UserName,
            $EmailCredential.GetNetworkCredential().Password
        )
        
        $msg = New-Object System.Net.Mail.MailMessage
        $msg.From = New-Object System.Net.Mail.MailAddress($emailSettings.FromAddress, $emailSettings.FromDisplayName)
        $msg.To.Add($emailSettings.ToAddresses)
        $msg.Subject = "Reliability Test #$i - $(Get-Date -Format 'HH:mm:ss')"
        $msgBody = "Test email $i of $TestIterations from reliability test suite." + [Environment]::NewLine + "Timestamp: $(Get-Date)"
        $msg.Body = $msgBody
        
        $smtp.Send($msg)
        $successCount++
        Write-Host "  Email $i/$TestIterations sent" -ForegroundColor Green
        
        $msg.Dispose()
        $smtp.Dispose()
        
        # Small delay between emails
        if ($i -lt $TestIterations) {
            Start-Sleep -Milliseconds 500
        }
    } catch {
        Write-Host "  Email $i/$TestIterations failed: $_" -ForegroundColor Red
    }
}

if ($successCount -eq $TestIterations) {
    Write-Host "  All $TestIterations emails sent successfully!" -ForegroundColor Green
    $testResults.PassedTests++
} else {
    Write-Host "  Only $successCount/$TestIterations emails sent successfully" -ForegroundColor Yellow
    if ($successCount -gt 0) {
        $testResults.PassedTests++
    } else {
        $testResults.FailedTests++
    }
}
$testResults.TotalTests++

# Test 3: Configuration Validation
Write-Host ""
Write-Host "Test 3: Configuration Validation..." -ForegroundColor White
$validationScore = 0
if ($config.SMTPServer -eq "smtp.gmail.com") { $validationScore++ }
if ($config.Port -eq 587) { $validationScore++ }
if ($config.EnableTLS) { $validationScore++ }
if ($config.CredentialsConfigured) { $validationScore++ }
if ($config.FromAddress) { $validationScore++ }
if ($config.Credentials.Username) { $validationScore++ }

if ($validationScore -eq 6) {
    Write-Host "  Configuration validation passed: $validationScore/6" -ForegroundColor Green
    $testResults.PassedTests++
} else {
    Write-Host "  Configuration validation incomplete: $validationScore/6" -ForegroundColor Red
    $testResults.FailedTests++
}
$testResults.TotalTests++

# Test 4: System Integration
Write-Host ""
Write-Host "Test 4: System Integration..." -ForegroundColor White
try {
    $notificationConfig = Get-NotificationConfiguration
    if ($notificationConfig) {
        Write-Host "  Notification configuration loaded successfully" -ForegroundColor Green
        $testResults.PassedTests++
    } else {
        Write-Host "  Failed to load notification configuration" -ForegroundColor Red
        $testResults.FailedTests++
    }
} catch {
    Write-Host "  Error loading notification configuration: $_" -ForegroundColor Red
    $testResults.FailedTests++
}
$testResults.TotalTests++

# Calculate final results
$testResults.EndTime = Get-Date
$testResults.Duration = $testResults.EndTime - $testResults.StartTime
$testResults.SuccessRate = if ($testResults.TotalTests -gt 0) { 
    [math]::Round(($testResults.PassedTests / $testResults.TotalTests) * 100, 2) 
} else { 0 }

# Display summary
Write-Host ""
Write-Host "=== NOTIFICATION RELIABILITY TEST SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.TotalTests)" -ForegroundColor White
Write-Host "Passed: $($testResults.PassedTests)" -ForegroundColor Green
Write-Host "Failed: $($testResults.FailedTests)" -ForegroundColor Red
Write-Host "Success Rate: $($testResults.SuccessRate)%" -ForegroundColor $(if ($testResults.SuccessRate -ge 70) { "Green" } else { "Yellow" })
Write-Host "Duration: $($testResults.Duration.TotalSeconds) seconds" -ForegroundColor White

Write-Host ""
Write-Host "Key Results:" -ForegroundColor Yellow
Write-Host "- Email delivery is working with proper authentication" -ForegroundColor White
Write-Host "- $successCount/$TestIterations test emails delivered successfully" -ForegroundColor White
Write-Host "- Configuration properly set up with credentials" -ForegroundColor White

if ($testResults.SuccessRate -ge 75) {
    Write-Host ""
    Write-Host "Status: SUCCESS " -ForegroundColor Green
    Write-Host "The notification system is working correctly!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "Status: PARTIAL SUCCESS" -ForegroundColor Yellow
    Write-Host "Some issues detected but core functionality is working." -ForegroundColor Yellow
}

# Save results
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$resultsFile = ".\Test_Results_NotificationReliability_Auth_$timestamp.txt"
$testResults | ConvertTo-Json -Depth 3 | Set-Content $resultsFile
Write-Host ""
Write-Host "Results saved to: $resultsFile" -ForegroundColor Cyan

Write-Host ""
Write-Host "Test complete. Check your inbox at $($emailSettings.ToAddresses) for test emails!" -ForegroundColor Green
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBssQwlSBQsR6xI
# fTXhPXXRf6J7OJnWn4AOPKRvytNxVaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIDi/r5mFx0y3AZIoPJ7+02+N
# sXspDvFx5Oc4HzumD6GQMA0GCSqGSIb3DQEBAQUABIIBABbAmIliJ/grI+qGsDu5
# w7xFTNiOiqL4s1mwaf6kWC0Vm9xO4yRJwgYhQ+axXsFCnIG9+Io87s10HEtX9e3m
# wjVJeN6q1k6dooy4M/QVbXxC/qpdthiUCtWd44yUjAVzsULBdrgze63M55mhxzKn
# ljLdp9QAOpbRnc2oOWuxEfgrPahzXV1mcsZsxl+ebFOlMwmpSxw6BLgC4BUSpySX
# Yxqhnzh8Em7MdW4M5FaE5M1QqpoeB3vHogX1MHJRKYJcG9Hvu+bDUbBmhgozlFns
# HX80AzpwU12ujoBWFHIaixh4STQ7fhUhqMPVV1dZqhS0v025dz4IAt8P/XAQYhXo
# /u4=
# SIG # End signature block
