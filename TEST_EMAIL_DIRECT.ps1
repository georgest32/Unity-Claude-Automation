# Direct Email Test Script
# This script tests email sending directly without the complexity of the full test framework

Write-Host "`n=== Direct Email Sending Test ===" -ForegroundColor Cyan
Write-Host "This script will test sending email directly using your configured credentials.`n" -ForegroundColor White

# Import the email module
Import-Module ".\Modules\Unity-Claude-EmailNotifications\Unity-Claude-EmailNotifications.psd1" -Force

# Create configuration
Write-Host "Creating email configuration..." -ForegroundColor Yellow
$systemConfig = Get-Content ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json" | ConvertFrom-Json
$emailSettings = $systemConfig.EmailNotifications

New-EmailConfiguration -ConfigurationName "Default" `
    -SMTPServer $emailSettings.SMTPServer `
    -Port $emailSettings.SMTPPort `
    -EnableTLS:$emailSettings.EnableSSL `
    -FromAddress $emailSettings.FromAddress `
    -FromDisplayName $emailSettings.FromDisplayName

Write-Host "Configuration created." -ForegroundColor Green

# Set credentials
Write-Host "`nSetting credentials..." -ForegroundColor Yellow
Write-Host "Please enter the credentials for $($emailSettings.FromAddress)" -ForegroundColor White

$cred = Get-Credential -Message "Enter SMTP credentials" -UserName $emailSettings.FromAddress
if (-not $cred) {
    Write-Host "No credentials provided. Exiting." -ForegroundColor Red
    exit
}

Set-EmailCredentials -ConfigurationName "Default" -Credential $cred

# Verify configuration
$config = Get-EmailConfiguration -ConfigurationName "Default" -IncludeCredentials
Write-Host "`nConfiguration Status:" -ForegroundColor Yellow
Write-Host "  SMTP Server: $($config.SMTPServer):$($config.Port)" -ForegroundColor Gray
Write-Host "  From: $($config.FromAddress)" -ForegroundColor Gray
Write-Host "  Credentials Configured: $($config.CredentialsConfigured)" -ForegroundColor Gray
Write-Host "  Username: $($config.Credentials.Username)" -ForegroundColor Gray

# Test SMTP connection
Write-Host "`nTesting SMTP connection..." -ForegroundColor Yellow
try {
    Test-EmailConfiguration -ConfigurationName "Default"
    Write-Host "SMTP connection test passed!" -ForegroundColor Green
} catch {
    Write-Host "SMTP connection test failed: $_" -ForegroundColor Red
    Write-Host "`nCommon issues:" -ForegroundColor Yellow
    Write-Host "  - Wrong password (use App Password for Gmail)" -ForegroundColor Gray
    Write-Host "  - 2FA not enabled (required for App Passwords)" -ForegroundColor Gray
    Write-Host "  - Firewall blocking port 587" -ForegroundColor Gray
}

# Send test email using System.Net.Mail directly
Write-Host "`n=== Sending Test Email with System.Net.Mail ===" -ForegroundColor Cyan

$sendTest = Read-Host "Do you want to send a test email to $($emailSettings.ToAddresses)? (y/n)"
if ($sendTest -eq 'y') {
    try {
        Write-Host "Preparing email..." -ForegroundColor Yellow
        
        # Create SMTP client
        $smtpClient = New-Object System.Net.Mail.SmtpClient($emailSettings.SMTPServer, $emailSettings.SMTPPort)
        $smtpClient.EnableSsl = $emailSettings.EnableSSL
        $smtpClient.Timeout = 30000  # 30 seconds
        
        # Set credentials
        Write-Host "Setting authentication..." -ForegroundColor Yellow
        $smtpClient.Credentials = New-Object System.Net.NetworkCredential(
            $cred.UserName,
            $cred.GetNetworkCredential().Password
        )
        
        # Create message
        $mailMessage = New-Object System.Net.Mail.MailMessage
        $mailMessage.From = New-Object System.Net.Mail.MailAddress($emailSettings.FromAddress, $emailSettings.FromDisplayName)
        $mailMessage.To.Add($emailSettings.ToAddresses)
        $mailMessage.Subject = "Unity-Claude Test Email - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $mailMessage.Body = @"
This is a test email from Unity-Claude Automation.

Test Details:
- Timestamp: $(Get-Date)
- SMTP Server: $($emailSettings.SMTPServer):$($emailSettings.SMTPPort)
- From: $($emailSettings.FromAddress)
- To: $($emailSettings.ToAddresses)
- SSL/TLS: $($emailSettings.EnableSSL)

If you received this email, your configuration is working correctly!

Best regards,
Unity-Claude Automation System
"@
        $mailMessage.IsBodyHtml = $false
        
        # Send email
        Write-Host "Sending email..." -ForegroundColor Yellow
        $startTime = Get-Date
        $smtpClient.Send($mailMessage)
        $endTime = Get-Date
        $duration = ($endTime - $startTime).TotalMilliseconds
        
        Write-Host "[SUCCESS] Email sent successfully in $([math]::Round($duration, 2))ms!" -ForegroundColor Green
        Write-Host "Check your inbox at: $($emailSettings.ToAddresses)" -ForegroundColor Cyan
        
        # Cleanup
        $mailMessage.Dispose()
        $smtpClient.Dispose()
        
    } catch {
        Write-Host "[ERROR] Failed to send email: $_" -ForegroundColor Red
        Write-Host "`nError Details:" -ForegroundColor Yellow
        Write-Host $_.Exception.ToString() -ForegroundColor Gray
        
        if ($_.Exception.Message -match "5\.7\.\d+") {
            Write-Host "`nAuthentication Error Detected!" -ForegroundColor Red
            Write-Host "Make sure you're using:" -ForegroundColor Yellow
            Write-Host "  1. The correct username (full email address)" -ForegroundColor Gray
            Write-Host "  2. An App Password (not your regular password)" -ForegroundColor Gray
            Write-Host "  3. 2FA is enabled on your Google account" -ForegroundColor Gray
        }
        
        if ($_.Exception.Message -match "5\.5\.1") {
            Write-Host "`nAuthentication Required!" -ForegroundColor Red
            Write-Host "The server requires authentication but credentials may not be set correctly." -ForegroundColor Yellow
        }
    }
}

Write-Host "`n=== Test Complete ===" -ForegroundColor Cyan
Write-Host "If the email was sent successfully, the main tests should also work." -ForegroundColor White
Write-Host "If it failed, fix the issues above before running the main tests." -ForegroundColor White
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAAzfCR1qfgF0ax
# RFzbN3gLdJwd5KmZMDnlQZUCE7kFh6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIgkqJvrI7Wjrlj06FJ0wTl7
# Gp0BT27OuFSmr49xBzqHMA0GCSqGSIb3DQEBAQUABIIBAASOEodDG8kpASbtVgVn
# M8wcFPd1WSWeo6HvhXIQtjov3KflEET8caYEG+817XNmIfIOOreXS+hbcyLyGive
# tc4dWa1+vaUFgp59qrPu1Vigc3pM6YOfRNGGV/2FwBPhosOwRSQqAM9rqjfsZIhG
# sx5gC5YdO63RAnVD3NyV/EbaRDITQ6kzUxznFrRIJpgizHp8JwJrxPE6ObQoIXse
# zvtU7PfCsk/0i8JbP1yLdm0cv9JNerLQ2QFcBptCxLHZRVzIgLwJ6DGVNsLIky7z
# CY+78leNNfsRAbYDm3nqRsv7b1po7I7SyjvelpiCm1ysS/5EGbLhcEkjt8pbsiEa
# /+g=
# SIG # End signature block
