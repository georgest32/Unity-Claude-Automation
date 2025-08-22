# Notification Configuration Setup Guide
*Week 6 System Integration - Notification System Configuration*
*Date: 2025-08-22*

## 📋 Overview
This guide helps you configure the Unity-Claude notification system for email and webhook notifications. The system requires proper SMTP settings and webhook URLs to function.

## 🔧 Configuration File Location
**Main Configuration**: `Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json`

## 📧 Email Notification Configuration

### Required Settings
1. **SMTPServer**: Your email server hostname (e.g., "smtp.gmail.com", "smtp.office365.com")
2. **FromAddress**: Email address to send notifications from
3. **ToAddresses**: Array of recipient email addresses

### Common SMTP Configurations

#### Gmail Configuration
```json
"EmailNotifications": {
    "Enabled": true,
    "SMTPServer": "smtp.gmail.com",
    "SMTPPort": 587,
    "EnableSSL": true,
    "FromAddress": "your-email@gmail.com",
    "FromDisplayName": "Unity-Claude Automation",
    "ToAddresses": ["admin@yourdomain.com", "developer@yourdomain.com"],
    "UseSecureCredentials": true,
    "CredentialStore": "DPAPI"
}
```

#### Office 365 Configuration
```json
"EmailNotifications": {
    "Enabled": true,
    "SMTPServer": "smtp.office365.com",
    "SMTPPort": 587,
    "EnableSSL": true,
    "FromAddress": "your-email@company.com",
    "FromDisplayName": "Unity-Claude Automation",
    "ToAddresses": ["team@company.com"],
    "UseSecureCredentials": true,
    "CredentialStore": "DPAPI"
}
```

#### Local/Corporate SMTP
```json
"EmailNotifications": {
    "Enabled": true,
    "SMTPServer": "mail.yourcompany.com",
    "SMTPPort": 25,
    "EnableSSL": false,
    "FromAddress": "unity-automation@yourcompany.com",
    "FromDisplayName": "Unity-Claude Automation",
    "ToAddresses": ["devteam@yourcompany.com"],
    "UseSecureCredentials": false,
    "CredentialStore": "None"
}
```

## 🔗 Webhook Notification Configuration

### Required Settings
1. **WebhookURLs**: Array of webhook endpoint URLs
2. **AuthenticationMethod**: "Bearer", "Basic", "APIKey", or "None"
3. **Authentication credentials** based on the method chosen

### Common Webhook Configurations

#### Discord Webhook
```json
"WebhookNotifications": {
    "Enabled": true,
    "WebhookURLs": ["https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"],
    "AuthenticationMethod": "None",
    "ContentType": "application/json"
}
```

#### Slack Webhook
```json
"WebhookNotifications": {
    "Enabled": true,
    "WebhookURLs": ["https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK"],
    "AuthenticationMethod": "None",
    "ContentType": "application/json"
}
```

#### Microsoft Teams Webhook
```json
"WebhookNotifications": {
    "Enabled": true,
    "WebhookURLs": ["https://company.webhook.office.com/webhookb2/YOUR_WEBHOOK_URL"],
    "AuthenticationMethod": "None",
    "ContentType": "application/json"
}
```

#### Custom API with Bearer Token
```json
"WebhookNotifications": {
    "Enabled": true,
    "WebhookURLs": ["https://api.yourservice.com/notifications"],
    "AuthenticationMethod": "Bearer",
    "BearerToken": "your-api-token-here",
    "ContentType": "application/json"
}
```

#### Custom API with API Key
```json
"WebhookNotifications": {
    "Enabled": true,
    "WebhookURLs": ["https://api.yourservice.com/hooks"],
    "AuthenticationMethod": "APIKey",
    "APIKeyHeader": "X-API-Key",
    "APIKey": "your-api-key-here",
    "ContentType": "application/json"
}
```

## ⚙️ Setup Steps

### Step 1: Choose Your Notification Methods
Decide which notification methods you want to use:
- **Email only**: Set EmailNotifications.Enabled = true, WebhookNotifications.Enabled = false
- **Webhook only**: Set EmailNotifications.Enabled = false, WebhookNotifications.Enabled = true  
- **Both**: Set both to true

### Step 2: Configure Email Settings (if using email)
1. **Get SMTP server details** from your email provider
2. **Update configuration** with your SMTP server, port, and SSL settings
3. **Set sender email** in FromAddress field
4. **Add recipients** to ToAddresses array
5. **Configure credentials** if required (most SMTP servers require authentication)

### Step 3: Configure Webhook Settings (if using webhooks)
1. **Get webhook URLs** from your chat service (Discord, Slack, Teams, etc.)
2. **Update WebhookURLs** array with your webhook endpoints
3. **Set authentication** method based on your service requirements
4. **Add credentials** if required (Bearer tokens, API keys, etc.)

### Step 4: Configure Notification Triggers
Update the NotificationTriggers section to specify when notifications should be sent:
```json
"NotificationTriggers": {
    "UnityCompilation": {
        "TriggerOnError": true,
        "TriggerOnSuccess": false,
        "TriggerOnWarning": true
    },
    "ClaudeSubmission": {
        "TriggerOnFailure": true,
        "TriggerOnSuccess": false,
        "TriggerOnRateLimit": true
    },
    "SystemHealth": {
        "TriggerOnCritical": true,
        "TriggerOnWarning": true,
        "TriggerOnRecovery": true
    },
    "AutonomousAgent": {
        "TriggerOnFailure": true,
        "TriggerOnRestart": true,
        "TriggerOnIntervention": true
    }
}
```

## 🔐 Security Considerations

### Email Credentials
- **Gmail**: Use App Passwords, not your regular password
- **Office 365**: May require enabling SMTP AUTH for your account
- **Corporate**: Check with your IT department for SMTP settings

### Webhook Security
- **Keep webhook URLs secret** - they contain authentication tokens
- **Use HTTPS only** for webhook endpoints
- **Consider rate limiting** if sending many notifications

### Credential Storage
The system supports secure credential storage using Windows DPAPI:
- **DPAPI**: Encrypted storage tied to user account (recommended)
- **None**: Plain text storage (use only for testing)

## 🧪 Testing Your Configuration

### Test Email Configuration
```powershell
# Test email notifications
Import-Module Unity-Claude-NotificationIntegration
$config = Get-NotificationConfiguration
$result = Test-EmailNotificationHealth -Detailed
Write-Host "Email Status: $($result.Status)"
```

### Test Webhook Configuration  
```powershell
# Test webhook notifications
Import-Module Unity-Claude-NotificationIntegration
$config = Get-NotificationConfiguration
$result = Test-WebhookNotificationHealth -Detailed
Write-Host "Webhook Status: $($result.Status)"
```

### Test Complete Integration
```powershell
# Test overall notification system
Import-Module Unity-Claude-NotificationIntegration
$result = Test-NotificationIntegrationHealth -Detailed
Write-Host "Integration Status: $($result.Status)"
```

## 🚨 Common Issues

### Email Issues
- **Authentication failures**: Check username/password and enable less secure apps or app passwords
- **Port/SSL issues**: Verify SMTP port (587 for TLS, 465 for SSL, 25 for unencrypted)
- **Firewall blocks**: Ensure outbound SMTP ports are not blocked

### Webhook Issues
- **URL validation**: Ensure webhook URLs are correct and accessible
- **Authentication**: Verify tokens/keys are correct and not expired
- **Rate limiting**: Some services limit webhook frequency

### Configuration Issues
- **JSON syntax**: Ensure valid JSON syntax (use JSON validator if needed)
- **Required fields**: All enabled services must have required configuration fields
- **Array format**: Use proper JSON array syntax for multiple values

## 📞 Need Help?
If you need assistance with specific email or webhook service configuration, refer to your service provider's documentation or IT department for SMTP/webhook settings.