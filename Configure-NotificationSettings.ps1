# Configure-NotificationSettings.ps1
# Interactive configuration setup for Unity-Claude notification system
# Week 6 System Integration - Configuration Helper
# Date: 2025-08-22

param(
    [switch]$EmailOnly,
    [switch]$WebhookOnly,
    [switch]$DisableAll,
    [string]$ConfigPath = ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Unity-Claude Notification Configuration Setup ===" -ForegroundColor Cyan
Write-Host "This script will help you configure email and webhook notifications." -ForegroundColor White
Write-Host ""

if ($DisableAll) {
    Write-Host "Disabling all notifications..." -ForegroundColor Yellow
    
    # Load current configuration
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    
    # Disable notifications
    $config.Notifications.EnableNotifications = $false
    $config.EmailNotifications.Enabled = $false
    $config.WebhookNotifications.Enabled = $false
    
    # Save configuration
    $config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath
    Write-Host "All notifications disabled successfully." -ForegroundColor Green
    return
}

try {
    # Load current configuration
    if (-not (Test-Path $ConfigPath)) {
        Write-Host "Configuration file not found: $ConfigPath" -ForegroundColor Red
        return
    }
    
    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    
    # Enable overall notifications
    $config.Notifications.EnableNotifications = $true
    
    # Configure Email Notifications
    if (-not $WebhookOnly) {
        Write-Host "=== Email Configuration ===" -ForegroundColor Yellow
        
        $emailChoice = Read-Host "Enable email notifications? (y/n) [current: $($config.EmailNotifications.Enabled)]"
        if ($emailChoice -eq 'y' -or $emailChoice -eq 'Y' -or $emailChoice -eq '') {
            $config.EmailNotifications.Enabled = $true
            
            Write-Host "Email notification setup:" -ForegroundColor White
            Write-Host "Common SMTP servers:" -ForegroundColor Gray
            Write-Host "  Gmail: smtp.gmail.com:587 (SSL)" -ForegroundColor Gray
            Write-Host "  Office 365: smtp.office365.com:587 (SSL)" -ForegroundColor Gray
            Write-Host "  Outlook: smtp-mail.outlook.com:587 (SSL)" -ForegroundColor Gray
            Write-Host ""
            
            $smtpServer = Read-Host "SMTP Server [current: $($config.EmailNotifications.SMTPServer)]"
            if ($smtpServer) { $config.EmailNotifications.SMTPServer = $smtpServer }
            
            $smtpPort = Read-Host "SMTP Port [current: $($config.EmailNotifications.SMTPPort)]"
            if ($smtpPort) { $config.EmailNotifications.SMTPPort = [int]$smtpPort }
            
            $enableSSL = Read-Host "Enable SSL/TLS? (y/n) [current: $($config.EmailNotifications.EnableSSL)]"
            if ($enableSSL -eq 'y' -or $enableSSL -eq 'Y') { $config.EmailNotifications.EnableSSL = $true }
            elseif ($enableSSL -eq 'n' -or $enableSSL -eq 'N') { $config.EmailNotifications.EnableSSL = $false }
            
            $fromAddress = Read-Host "From email address [current: $($config.EmailNotifications.FromAddress)]"
            if ($fromAddress) { $config.EmailNotifications.FromAddress = $fromAddress }
            
            $toAddresses = Read-Host "To email addresses (comma-separated) [current: $($config.EmailNotifications.ToAddresses -join ', ')]"
            if ($toAddresses) { 
                $config.EmailNotifications.ToAddresses = $toAddresses -split ',' | ForEach-Object { $_.Trim() }
            }
            
            Write-Host "Email configuration updated." -ForegroundColor Green
        } else {
            $config.EmailNotifications.Enabled = $false
            Write-Host "Email notifications disabled." -ForegroundColor Yellow
        }
    }
    
    # Configure Webhook Notifications  
    if (-not $EmailOnly) {
        Write-Host "`n=== Webhook Configuration ===" -ForegroundColor Yellow
        
        $webhookChoice = Read-Host "Enable webhook notifications? (y/n) [current: $($config.WebhookNotifications.Enabled)]"
        if ($webhookChoice -eq 'y' -or $webhookChoice -eq 'Y' -or $webhookChoice -eq '') {
            $config.WebhookNotifications.Enabled = $true
            
            Write-Host "Webhook notification setup:" -ForegroundColor White
            Write-Host "Common webhook services:" -ForegroundColor Gray
            Write-Host "  Discord: https://discord.com/api/webhooks/ID/TOKEN" -ForegroundColor Gray
            Write-Host "  Slack: https://hooks.slack.com/services/YOUR/WEBHOOK/URL" -ForegroundColor Gray
            Write-Host "  Teams: https://company.webhook.office.com/webhookb2/YOUR_URL" -ForegroundColor Gray
            Write-Host ""
            
            $webhookURLs = Read-Host "Webhook URLs (comma-separated) [current: $($config.WebhookNotifications.WebhookURLs -join ', ')]"
            if ($webhookURLs) {
                $config.WebhookNotifications.WebhookURLs = $webhookURLs -split ',' | ForEach-Object { $_.Trim() }
            }
            
            Write-Host "Authentication methods: None, Bearer, Basic, APIKey" -ForegroundColor Gray
            $authMethod = Read-Host "Authentication method [current: $($config.WebhookNotifications.AuthenticationMethod)]"
            if ($authMethod) { $config.WebhookNotifications.AuthenticationMethod = $authMethod }
            
            if ($config.WebhookNotifications.AuthenticationMethod -eq "Bearer") {
                $bearerToken = Read-Host "Bearer Token [current: $(if($config.WebhookNotifications.BearerToken){'***SET***'}else{'NOT SET'})]"
                if ($bearerToken) { $config.WebhookNotifications.BearerToken = $bearerToken }
            }
            
            if ($config.WebhookNotifications.AuthenticationMethod -eq "APIKey") {
                $apiKeyHeader = Read-Host "API Key Header [current: $($config.WebhookNotifications.APIKeyHeader)]"
                if ($apiKeyHeader) { $config.WebhookNotifications.APIKeyHeader = $apiKeyHeader }
                
                $apiKey = Read-Host "API Key [current: $(if($config.WebhookNotifications.APIKey){'***SET***'}else{'NOT SET'})]"
                if ($apiKey) { $config.WebhookNotifications.APIKey = $apiKey }
            }
            
            Write-Host "Webhook configuration updated." -ForegroundColor Green
        } else {
            $config.WebhookNotifications.Enabled = $false
            Write-Host "Webhook notifications disabled." -ForegroundColor Yellow
        }
    }
    
    # Save updated configuration
    $config | ConvertTo-Json -Depth 10 | Set-Content $ConfigPath
    
    Write-Host "`n=== Configuration Summary ===" -ForegroundColor Cyan
    Write-Host "Configuration file: $ConfigPath" -ForegroundColor White
    Write-Host "Email notifications: $($config.EmailNotifications.Enabled)" -ForegroundColor White
    Write-Host "Webhook notifications: $($config.WebhookNotifications.Enabled)" -ForegroundColor White
    
    if ($config.EmailNotifications.Enabled) {
        Write-Host "Email SMTP: $($config.EmailNotifications.SMTPServer):$($config.EmailNotifications.SMTPPort)" -ForegroundColor White
        Write-Host "Email recipients: $($config.EmailNotifications.ToAddresses.Count)" -ForegroundColor White
    }
    
    if ($config.WebhookNotifications.Enabled) {
        Write-Host "Webhook URLs: $($config.WebhookNotifications.WebhookURLs.Count)" -ForegroundColor White
        Write-Host "Webhook auth: $($config.WebhookNotifications.AuthenticationMethod)" -ForegroundColor White
    }
    
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Test your configuration: Import-Module Unity-Claude-NotificationIntegration; Test-NotificationIntegrationHealth -Detailed" -ForegroundColor White
    Write-Host "2. Run integration tests: .\Test-Week6Days1-2-SystemIntegration.ps1" -ForegroundColor White
    Write-Host "3. For detailed setup help, see: .\NOTIFICATION_CONFIGURATION_SETUP_GUIDE.md" -ForegroundColor White
    
} catch {
    Write-Host "Error configuring notifications: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check your JSON syntax and try again." -ForegroundColor Red
}