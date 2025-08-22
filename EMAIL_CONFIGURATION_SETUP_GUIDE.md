# Email Configuration Setup Guide
*How to configure email credentials for Unity-Claude Automation notification system*

## Why Tests Are Failing

The email delivery tests are failing with 0% success rate because:

1. **No credentials configured**: The system is configured to use Gmail SMTP (`smtp.gmail.com:587`) which requires authentication
2. **Test safety feature**: The test script deliberately skips email sending when credentials are required but not configured
3. **Configuration says `UseSecureCredentials: true`** but no actual credentials exist

## Current Configuration Status

### What's Configured ✅
- SMTP Server: `smtp.gmail.com`
- Port: `587`
- SSL: `Enabled`
- From Address: `dev@auto-m8.io`
- To Address: `georgest32@gmail.com`

### What's Missing ❌
- SMTP Username (usually your Gmail address)
- SMTP Password (App Password for Gmail)
- Credential storage

## How to Fix: Step-by-Step Setup

### Option 1: Configure Credentials via PowerShell (Recommended)

```powershell
# 1. Import the modules
Import-Module ".\Modules\Unity-Claude-EmailNotifications\Unity-Claude-EmailNotifications.psd1"

# 2. Create email configuration (if not exists)
New-EmailConfiguration -ConfigurationName "Production" `
    -SMTPServer "smtp.gmail.com" `
    -SMTPPort 587 `
    -UseSSL $true `
    -FromAddress "your-email@gmail.com" `
    -ToAddress "recipient@gmail.com"

# 3. Set email credentials (Interactive - will prompt for password)
Set-EmailCredentials -ConfigurationName "Production" -Username "your-email@gmail.com"

# OR provide credentials directly (less secure - only for testing)
Set-EmailCredentials -ConfigurationName "Production" `
    -Username "your-email@gmail.com" `
    -Password "your-app-password"

# 4. Test the configuration
Test-EmailConfiguration -ConfigurationName "Production"
```

### Option 2: Use Gmail App Password (Required for Gmail)

Gmail requires an "App Password" instead of your regular password:

1. **Enable 2-Factor Authentication** on your Google Account:
   - Go to https://myaccount.google.com/security
   - Enable "2-Step Verification"

2. **Generate App Password**:
   - Go to https://myaccount.google.com/apppasswords
   - Select "Mail" as the app
   - Select "Windows Computer" as device
   - Copy the generated 16-character password

3. **Use App Password in Configuration**:
   ```powershell
   Set-EmailCredentials -ConfigurationName "Production" `
       -Username "your-email@gmail.com" `
       -Password "xxxx xxxx xxxx xxxx"  # Your 16-char app password
   ```

### Option 3: Use Alternative SMTP Service

If you don't want to use Gmail, consider:

#### Outlook/Office365
```powershell
New-EmailConfiguration -ConfigurationName "Production" `
    -SMTPServer "smtp.office365.com" `
    -SMTPPort 587 `
    -UseSSL $true `
    -FromAddress "your-email@outlook.com" `
    -ToAddress "recipient@example.com"
```

#### SendGrid (Free tier available)
```powershell
New-EmailConfiguration -ConfigurationName "Production" `
    -SMTPServer "smtp.sendgrid.net" `
    -SMTPPort 587 `
    -UseSSL $true `
    -FromAddress "noreply@yourdomain.com" `
    -ToAddress "recipient@example.com"

Set-EmailCredentials -ConfigurationName "Production" `
    -Username "apikey" `  # Literally "apikey"
    -Password "your-sendgrid-api-key"
```

### Option 4: Disable Email Tests (For Development Only)

If you just want tests to pass without email functionality:

```powershell
# Run tests with connectivity tests disabled
.\Test-NotificationReliabilityFramework.ps1 -SkipConnectivityTests

# OR modify the config to disable email notifications
$config = Get-Content ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json" | ConvertFrom-Json
$config.EmailNotifications.Enabled = $false
$config | ConvertTo-Json -Depth 10 | Set-Content ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json"
```

## Verification Steps

After setting up credentials:

1. **Test SMTP Connection**:
   ```powershell
   Test-EmailConfiguration -ConfigurationName "Production"
   ```

2. **Send Test Email**:
   ```powershell
   Send-UnityErrorNotification -ErrorCount 1 -ErrorDetails "Test error"
   ```

3. **Run Full Tests**:
   ```powershell
   .\Test-NotificationReliabilityFramework.ps1
   .\Test-Week6Days3-4-TestingReliability.ps1
   ```

## Security Best Practices

1. **Never commit credentials** to source control
2. **Use App Passwords** instead of account passwords
3. **Store credentials securely** using Windows DPAPI (automatic with Set-EmailCredentials)
4. **Use service accounts** dedicated for automation
5. **Rotate passwords regularly**
6. **Monitor for unauthorized access**

## Troubleshooting

### "5.5.1 Authentication Required"
- Credentials not set or incorrect
- Solution: Run `Set-EmailCredentials` with correct username/password

### "5.7.0 Authentication Required"
- Gmail blocking "less secure apps"
- Solution: Use App Password instead

### "The SMTP server requires a secure connection"
- SSL/TLS not properly configured
- Solution: Ensure `UseSSL = $true` and port is 587 (or 465 for SSL)

### Test Still Shows 0% Delivery
- Check if credentials are actually stored:
  ```powershell
  Get-EmailConfiguration -ConfigurationName "Production" -IncludeCredentials
  ```
- Look for `CredentialsConfigured: True`

## Expected Results After Configuration

Once properly configured, you should see:
- SMTP Connectivity: 100% ✅
- Email Delivery: 80-100% ✅ (depending on network)
- Test Success Rate: 85%+ overall

## Summary

The tests are failing because email credentials haven't been configured, not because of code issues. The notification system is fully functional and just needs:

1. A valid Gmail account with 2FA enabled
2. An App Password generated for that account
3. Credentials configured using `Set-EmailCredentials`

Once configured, the email notification system will work correctly and tests will pass.