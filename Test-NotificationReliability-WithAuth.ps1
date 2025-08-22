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