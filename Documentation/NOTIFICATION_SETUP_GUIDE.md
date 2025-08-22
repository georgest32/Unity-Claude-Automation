# Unity-Claude Notification Setup Guide
*Week 6 Day 5 - Hour 5-8: Documentation*
*Created: 2025-08-22*

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Email Notification Setup](#email-notification-setup)
4. [Webhook Notification Setup](#webhook-notification-setup)
5. [Configuration Management](#configuration-management)
6. [Testing Your Setup](#testing-your-setup)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

## Overview

The Unity-Claude Automation notification system provides real-time alerts for:
- Unity compilation errors and warnings
- Claude submission failures and rate limits
- System health warnings and critical events
- Autonomous agent failures and interventions
- Fix application results

Notifications can be sent via:
- **Email** (SMTP) - Gmail, Outlook, Yahoo, or custom servers
- **Webhooks** - Discord, Slack, Teams, or custom endpoints

## Prerequisites

### Required Components
- PowerShell 5.1 or higher
- Unity-Claude Automation system installed
- Network connectivity to SMTP server or webhook endpoints

### Module Dependencies
- Unity-Claude-SystemStatus
- Unity-Claude-EmailNotifications
- Unity-Claude-WebhookNotifications
- Unity-Claude-NotificationIntegration
- Unity-Claude-NotificationConfiguration (new)

## Email Notification Setup

### Step 1: Gmail App Password Setup

Gmail requires App Passwords for SMTP authentication:

1. **Enable 2-Factor Authentication**
   - Go to https://myaccount.google.com/security
   - Click on "2-Step Verification"
   - Follow the setup wizard

2. **Generate App Password**
   - Go to https://myaccount.google.com/apppasswords
   - Select "Mail" from the app dropdown
   - Select "Windows Computer" from device dropdown
   - Copy the 16-character password shown

3. **Save Credentials**
   ```powershell
   # Run the credential saving script
   .\Save-EmailCredentials.ps1
   
   # Enter your email and App Password when prompted
   Email: your-email@gmail.com
   Password: xxxx xxxx xxxx xxxx  # Your 16-character App Password
   ```

### Step 2: Configure Email Settings

#### Option A: Interactive Configuration Wizard
```powershell
# Import the configuration module
Import-Module .\Modules\Unity-Claude-NotificationConfiguration

# Run the configuration wizard
Start-NotificationConfigWizard -ConfigureEmail

# Follow the prompts:
# - SMTP Server: smtp.gmail.com
# - Port: 587
# - Enable SSL: Yes
# - From Address: your-email@gmail.com
# - To Address: recipient@example.com
```

#### Option B: Manual Configuration
```powershell
# Load configuration module
Import-Module .\Modules\Unity-Claude-NotificationConfiguration

# Update email settings
Set-NotificationConfig -Section 'EmailNotifications' -Settings @{
    Enabled = $true
    SMTPServer = 'smtp.gmail.com'
    SMTPPort = 587
    EnableSSL = $true
    FromAddress = 'your-email@gmail.com'
    ToAddresses = 'recipient@example.com'
    RetryAttempts = 3
    TimeoutSeconds = 30
}
```

### Step 3: Test Email Configuration
```powershell
# Test with saved credentials
.\Test-NotificationReliability-WithAuth.ps1

# Or test directly
.\TEST_EMAIL_DIRECT.ps1
```

### Common SMTP Servers

| Provider | SMTP Server | Port | SSL/TLS |
|----------|------------|------|---------|
| Gmail | smtp.gmail.com | 587 | Yes |
| Outlook | smtp-mail.outlook.com | 587 | Yes |
| Yahoo | smtp.mail.yahoo.com | 587 or 465 | Yes |
| Office 365 | smtp.office365.com | 587 | Yes |

## Webhook Notification Setup

### Step 1: Obtain Webhook URL

#### Discord Webhook
1. Open Discord Server Settings
2. Go to Integrations → Webhooks
3. Click "New Webhook"
4. Copy the webhook URL

#### Slack Webhook
1. Go to https://api.slack.com/apps
2. Create or select your app
3. Enable Incoming Webhooks
4. Add webhook to workspace
5. Copy the webhook URL

#### Microsoft Teams Webhook
1. Right-click on channel
2. Select "Connectors"
3. Configure "Incoming Webhook"
4. Copy the webhook URL

### Step 2: Configure Webhook Settings

```powershell
# Configure webhook notifications
Set-NotificationConfig -Section 'WebhookNotifications' -Settings @{
    Enabled = $true
    WebhookURLs = @('https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_TOKEN')
    AuthenticationMethod = 'None'
    RetryAttempts = 3
    TimeoutSeconds = 30
    ContentType = 'application/json'
}
```

### Step 3: Test Webhook Configuration
```powershell
# Validate configuration
Test-NotificationConfig -TestConnections

# Send test notification
$testMessage = @{
    title = "Unity-Claude Test"
    description = "Testing webhook integration"
    color = 5814783
} | ConvertTo-Json

Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $testMessage -ContentType 'application/json'
```

## Configuration Management

### Backup and Restore

```powershell
# Create a backup before changes
Backup-NotificationConfig -Description "Before production setup"

# View backup history
Get-ConfigBackupHistory

# Restore from backup if needed
Restore-NotificationConfig -Latest
# Or restore specific backup
Restore-NotificationConfig -BackupFile "notificationconfig_backup_20250822_150000.json"
```

### Configuration Validation

```powershell
# Basic validation
Test-NotificationConfig

# Full validation with connection tests
Test-NotificationConfig -TestConnections -Detailed

# Generate configuration report
Get-ConfigurationReport -OutputPath ".\config_report.txt"
```

### Export and Import

```powershell
# Export current configuration
Export-NotificationConfig -Path ".\config_export.json" -Format JSON

# Import configuration on another system
Import-NotificationConfig -Path ".\config_export.json"
```

## Testing Your Setup

### Comprehensive Test Suite
```powershell
# Run full notification test suite
.\Test-NotificationReliabilityFramework.ps1

# Test specific components
.\Test-Week6Days3-4-TestingReliability.ps1
```

### Manual Testing
```powershell
# Test email delivery
$emailTest = @{
    To = "recipient@example.com"
    Subject = "Test from Unity-Claude"
    Body = "This is a test email"
}
Send-EmailNotification @emailTest

# Test webhook delivery
$webhookTest = @{
    Message = "Test notification from Unity-Claude"
    Level = "INFO"
}
Send-WebhookNotification @webhookTest
```

## Troubleshooting

### Email Issues

#### Authentication Failed (5.7.0 Error)
**Problem**: Gmail rejecting credentials
**Solutions**:
1. Verify 2FA is enabled on Google account
2. Use App Password, not regular password
3. Check for typos in email address
4. Ensure no spaces in App Password

#### Connection Timeout
**Problem**: Cannot connect to SMTP server
**Solutions**:
1. Check firewall settings for port 587
2. Verify network connectivity: `Test-NetConnection smtp.gmail.com -Port 587`
3. Try alternative ports (465, 2525)
4. Check antivirus/security software

#### Credentials Not Persisting
**Problem**: Have to enter password every time
**Solutions**:
1. Run `.\Save-EmailCredentials.ps1` to save credentials
2. Check file exists: `Test-Path ".\Modules\Unity-Claude-SystemStatus\Config\email.credential"`
3. Ensure running PowerShell as same user who saved credentials

### Webhook Issues

#### 404 Not Found
**Problem**: Webhook URL invalid
**Solutions**:
1. Verify webhook URL is complete and correct
2. Check if webhook was deleted or disabled
3. Regenerate webhook if necessary

#### 401 Unauthorized
**Problem**: Authentication required
**Solutions**:
1. Add authentication headers if required
2. Check API key or token validity
3. Verify authentication method matches endpoint requirements

#### Rate Limiting
**Problem**: Too many requests error
**Solutions**:
1. Enable notification batching in configuration
2. Increase DebounceSeconds for triggers
3. Implement exponential backoff

### Configuration Issues

#### Configuration Not Loading
**Problem**: Get-NotificationConfig returns null
**Solutions**:
```powershell
# Check if config file exists
Test-Path ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json"

# Validate JSON syntax
$config = Get-Content ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json" -Raw
try { $config | ConvertFrom-Json } catch { Write-Error $_ }

# Reset to defaults if corrupted
Reset-NotificationConfig -Force
```

#### Changes Not Taking Effect
**Problem**: Configuration updates not working
**Solutions**:
1. Clear configuration cache: `Get-NotificationConfig -NoCache`
2. Restart PowerShell session
3. Check for file permissions issues

## Best Practices

### Security
1. **Never commit credentials to source control**
   - Use `.gitignore` for credential files
   - Store credentials separately from code

2. **Use encrypted credential storage**
   - Windows DPAPI for local storage
   - Azure Key Vault for cloud deployments

3. **Rotate credentials regularly**
   - Update App Passwords quarterly
   - Regenerate webhook URLs if compromised

### Performance
1. **Enable notification batching**
   - Reduces email/webhook spam
   - Improves system performance

2. **Set appropriate debounce times**
   - Prevents duplicate notifications
   - Reduces noise from rapid events

3. **Use caching wisely**
   - 5-minute cache duration by default
   - Force refresh when testing changes

### Reliability
1. **Configure retry logic**
   - 3 retry attempts by default
   - Exponential backoff for failures

2. **Set up fallback mechanisms**
   - Multiple notification channels
   - Dead letter queue for failed notifications

3. **Monitor notification health**
   - Regular connectivity tests
   - Review notification metrics

### Maintenance
1. **Regular backups**
   - Before configuration changes
   - Weekly automated backups

2. **Documentation**
   - Document custom configurations
   - Keep troubleshooting log

3. **Testing**
   - Test after configuration changes
   - Monthly notification drills

## Configuration Reference

### Email Notification Settings
```json
{
  "EmailNotifications": {
    "Enabled": true,
    "SMTPServer": "smtp.gmail.com",
    "SMTPPort": 587,
    "EnableSSL": true,
    "FromAddress": "sender@example.com",
    "FromDisplayName": "Unity-Claude Automation",
    "ToAddresses": "recipient@example.com",
    "CCAddresses": [],
    "RetryAttempts": 3,
    "RetryDelaySeconds": 5,
    "ExponentialBackoff": true,
    "TimeoutSeconds": 30,
    "NotificationTypes": {
      "UnityCompilationError": true,
      "ClaudeSubmissionFailure": true,
      "FixApplicationSuccess": false,
      "SystemHealthWarning": true,
      "AutonomousAgentFailure": true
    }
  }
}
```

### Webhook Notification Settings
```json
{
  "WebhookNotifications": {
    "Enabled": false,
    "WebhookURLs": ["https://your-webhook-url"],
    "AuthenticationMethod": "None",
    "RetryAttempts": 3,
    "RetryDelaySeconds": 5,
    "ExponentialBackoff": true,
    "TimeoutSeconds": 30,
    "ContentType": "application/json",
    "NotificationTypes": {
      "UnityCompilationError": true,
      "ClaudeSubmissionFailure": true,
      "FixApplicationSuccess": false,
      "SystemHealthWarning": true,
      "AutonomousAgentFailure": true
    }
  }
}
```

## Support

For additional help:
1. Check logs: `.\unity_claude_automation.log`
2. Run diagnostics: `.\DIAGNOSE_SMTP_AUTH.ps1`
3. Generate report: `Get-ConfigurationReport`
4. Review implementation guide: `ROADMAP_FEATURES_ANALYSIS_ARP_2025_08_20.md`

## Next Steps

After setting up notifications:
1. Configure notification triggers for your workflow
2. Set up notification templates for consistent formatting
3. Implement custom notification rules
4. Integrate with monitoring dashboards
5. Set up notification analytics

---
*End of Setup Guide - Week 6 Day 5 Implementation Complete*