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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCByTm2UnSdX6nX5
# WATGEDbLzqEI+xIiphhrN17TwJQwGqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBye9b3NS9Jy4LMy3BzpuDGe
# IDE0EutOu6/sW4fRFpx0MA0GCSqGSIb3DQEBAQUABIIBAGz7PJeVDMMbAVDJtDCT
# Dg0hQbSVy5wH9uKuKX5frb+KuBepsSro5GqGTmUDzYdrE6ur6aUZ3uH53bjiQinb
# 5Zu2YPlVGWGW8DIXqTPEtczC+Ldk5Goltl9bmMh9JvoCAACd9CfOcjLpmMwANduk
# dn5PAo+oGu541WGOHr5ykXWuH3mXD/Nw9NOGxj+FBiEkaXkAAkAND58U1EiQ66C/
# fre9R0BULL7eORqgbDmBUnfrwiCMNWbZ3yEsW2NeaXVqXGk2YTk3fwZ40Tpr9Z7/
# 5TMVbSq0QbH/6+L5OJThmYgy2zbIlYueMaU2TzDIBPK5mmWtQsJtgtP8jYL5idzF
# S9g=
# SIG # End signature block
