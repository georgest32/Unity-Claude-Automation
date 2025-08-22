# Email Credential Configuration Script
# Run this to set up email credentials for Unity-Claude Automation

Write-Host "`n=== Unity-Claude Email Credential Setup ===" -ForegroundColor Cyan
Write-Host "This script will help you configure email credentials for notifications.`n" -ForegroundColor White

# Import the module
Import-Module ".\Modules\Unity-Claude-EmailNotifications\Unity-Claude-EmailNotifications.psd1"

# Check if configuration exists, create if not
$config = $null
try {
    $config = Get-EmailConfiguration -ConfigurationName "Default" -ErrorAction Stop
} catch {
    Write-Host "No existing configuration found. Creating default configuration..." -ForegroundColor Yellow
    
    # Read from systemstatus.config.json to get current settings
    $systemConfigFile = ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json"
    $systemConfig = Get-Content $systemConfigFile | ConvertFrom-Json
    $emailSettings = $systemConfig.EmailNotifications
    
    # Create the configuration
    New-EmailConfiguration -ConfigurationName "Default" `
        -SMTPServer $emailSettings.SMTPServer `
        -Port $emailSettings.SMTPPort `
        -EnableTLS:$emailSettings.EnableSSL `
        -FromAddress $emailSettings.FromAddress `
        -FromDisplayName $emailSettings.FromDisplayName
    
    $config = Get-EmailConfiguration -ConfigurationName "Default"
    Write-Host "Configuration created successfully!" -ForegroundColor Green
}
Write-Host "Current Configuration:" -ForegroundColor Yellow
Write-Host "  SMTP Server: $($config.SMTPServer):$($config.Port)" -ForegroundColor Gray
Write-Host "  From Address: $($config.FromAddress)" -ForegroundColor Gray
Write-Host "  Credentials Configured: $($config.CredentialsConfigured)" -ForegroundColor Gray

if ($config.CredentialsConfigured) {
    Write-Host "`n[INFO] Credentials are already configured." -ForegroundColor Green
    $reconfigure = Read-Host "Do you want to reconfigure? (y/n)"
    if ($reconfigure -ne 'y') {
        exit
    }
}

Write-Host "`n=== Choose Email Account ===" -ForegroundColor Cyan
Write-Host "The current From address is: $($config.FromAddress)" -ForegroundColor White
Write-Host "`nDo you have access to this email account?" -ForegroundColor Yellow
Write-Host "1. Yes, I have access to dev@auto-m8.io" -ForegroundColor White
Write-Host "2. No, I want to use my own Gmail account" -ForegroundColor White
Write-Host "3. No, I want to use a different email service" -ForegroundColor White

$choice = Read-Host "`nEnter your choice (1-3)"

switch ($choice) {
    "1" {
        # Use dev@auto-m8.io
        Write-Host "`n=== Setting up dev@auto-m8.io ===" -ForegroundColor Cyan
        Write-Host "You'll need the Gmail App Password for this account." -ForegroundColor Yellow
        Write-Host "If you don't have it, go to: https://myaccount.google.com/apppasswords" -ForegroundColor Yellow
        
        Set-EmailCredentials -ConfigurationName "Default" -Username "dev@auto-m8.io"
    }
    
    "2" {
        # Use user's own Gmail
        Write-Host "`n=== Setting up your Gmail account ===" -ForegroundColor Cyan
        $email = Read-Host "Enter your Gmail address"
        
        # Update the configuration
        Write-Host "Updating email configuration..." -ForegroundColor Yellow
        $configFile = ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json"
        $systemConfig = Get-Content $configFile | ConvertFrom-Json
        $systemConfig.EmailNotifications.FromAddress = $email
        $systemConfig.EmailNotifications.ToAddresses = $email
        $systemConfig | ConvertTo-Json -Depth 10 | Set-Content $configFile
        
        # Update the email module configuration
        New-EmailConfiguration -ConfigurationName "Default" -SMTPServer "smtp.gmail.com" -Port 587 -EnableTLS -FromAddress $email -FromDisplayName "Unity-Claude Automation"
        
        Write-Host "`n[IMPORTANT] Gmail requires an App Password, not your regular password!" -ForegroundColor Yellow
        Write-Host "1. Enable 2-Factor Authentication at: https://myaccount.google.com/security" -ForegroundColor White
        Write-Host "2. Generate App Password at: https://myaccount.google.com/apppasswords" -ForegroundColor White
        Write-Host "3. Use the 16-character password below`n" -ForegroundColor White
        
        Set-EmailCredentials -ConfigurationName "Default" -Username $email
    }
    
    "3" {
        # Use different email service
        Write-Host "`n=== Setting up custom email service ===" -ForegroundColor Cyan
        Write-Host "Common SMTP servers:" -ForegroundColor Yellow
        Write-Host "  - Outlook: smtp.office365.com (port 587)" -ForegroundColor Gray
        Write-Host "  - Yahoo: smtp.mail.yahoo.com (port 587)" -ForegroundColor Gray
        Write-Host "  - SendGrid: smtp.sendgrid.net (port 587)" -ForegroundColor Gray
        
        $smtpServer = Read-Host "`nEnter SMTP server"
        $smtpPort = Read-Host "Enter SMTP port (usually 587)"
        $fromEmail = Read-Host "Enter From email address"
        $toEmail = Read-Host "Enter To email address (for notifications)"
        
        # Update configurations
        $configFile = ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json"
        $systemConfig = Get-Content $configFile | ConvertFrom-Json
        $systemConfig.EmailNotifications.SMTPServer = $smtpServer
        $systemConfig.EmailNotifications.SMTPPort = [int]$smtpPort
        $systemConfig.EmailNotifications.FromAddress = $fromEmail
        $systemConfig.EmailNotifications.ToAddresses = $toEmail
        $systemConfig | ConvertTo-Json -Depth 10 | Set-Content $configFile
        
        New-EmailConfiguration -ConfigurationName "Default" -SMTPServer $smtpServer -Port ([int]$smtpPort) -EnableTLS -FromAddress $fromEmail -FromDisplayName "Unity-Claude Automation"
        
        $username = Read-Host "`nEnter username for authentication (often same as email)"
        Set-EmailCredentials -ConfigurationName "Default" -Username $username
    }
    
    default {
        Write-Host "`nInvalid choice. Exiting." -ForegroundColor Red
        exit
    }
}

Write-Host "`n=== Testing Configuration ===" -ForegroundColor Cyan
Write-Host "Testing email connection..." -ForegroundColor White

try {
    Test-EmailConfiguration -ConfigurationName "Default"
    Write-Host "`n[SUCCESS] Email configuration is working!" -ForegroundColor Green
    
    $sendTest = Read-Host "`nDo you want to send a test email? (y/n)"
    if ($sendTest -eq 'y') {
        # Get the current To address
        $configFile = ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json"
        $systemConfig = Get-Content $configFile | ConvertFrom-Json
        $toAddress = $systemConfig.EmailNotifications.ToAddresses
        if ($toAddress -is [array]) { $toAddress = $toAddress[0] }
        
        Write-Host "Sending test email to: $toAddress" -ForegroundColor Yellow
        
        # Create and send test email
        $testSubject = "Unity-Claude Automation Test - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $testBody = "This is a test email from Unity-Claude Automation.`n`nIf you received this, your email configuration is working correctly!`n`nTimestamp: $(Get-Date)"
        
        # Use the Send-EmailNotification function if available
        if (Get-Command Send-EmailNotification -ErrorAction SilentlyContinue) {
            Send-EmailNotification -Subject $testSubject -Body $testBody -To $toAddress
        } else {
            Write-Host "Note: Send-EmailNotification function not available. Configuration saved but not tested." -ForegroundColor Yellow
        }
        
        Write-Host "`n[SUCCESS] Test email sent! Check your inbox." -ForegroundColor Green
    }
} catch {
    Write-Host "`n[ERROR] Configuration test failed: $_" -ForegroundColor Red
    Write-Host "`nPossible issues:" -ForegroundColor Yellow
    Write-Host "  - Incorrect password (use App Password for Gmail)" -ForegroundColor Gray
    Write-Host "  - 2-Factor Authentication not enabled (required for App Passwords)" -ForegroundColor Gray
    Write-Host "  - Firewall blocking SMTP port" -ForegroundColor Gray
    Write-Host "  - Incorrect SMTP server or port" -ForegroundColor Gray
}

Write-Host "`n=== Configuration Complete ===" -ForegroundColor Cyan
Write-Host "You can now run the notification tests:" -ForegroundColor White
Write-Host "  .\Test-NotificationReliabilityFramework.ps1" -ForegroundColor Green
Write-Host "  .\Test-Week6Days3-4-TestingReliability.ps1" -ForegroundColor Green