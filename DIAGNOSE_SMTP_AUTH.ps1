# SMTP Authentication Diagnostic Script
# This script helps diagnose why Gmail is rejecting authentication

Write-Host "`n=== Gmail SMTP Authentication Diagnostics ===" -ForegroundColor Cyan
Write-Host "This script will help identify why authentication is failing.`n" -ForegroundColor White

# Check current configuration
$systemConfig = Get-Content ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json" | ConvertFrom-Json
$emailSettings = $systemConfig.EmailNotifications

Write-Host "Current Configuration:" -ForegroundColor Yellow
Write-Host "  SMTP Server: $($emailSettings.SMTPServer)" -ForegroundColor Gray
Write-Host "  Port: $($emailSettings.SMTPPort)" -ForegroundColor Gray
Write-Host "  SSL/TLS: $($emailSettings.EnableSSL)" -ForegroundColor Gray
Write-Host "  From Address: $($emailSettings.FromAddress)" -ForegroundColor Gray

Write-Host "`n=== Authentication Check ===" -ForegroundColor Cyan
Write-Host "Gmail requires App Passwords for SMTP authentication." -ForegroundColor Yellow
Write-Host "`nPlease verify the following:" -ForegroundColor White

Write-Host "`n1. Is 2-Factor Authentication enabled?" -ForegroundColor Cyan
Write-Host "   Check at: https://myaccount.google.com/security" -ForegroundColor Gray
Write-Host "   Look for '2-Step Verification' - it must be ON" -ForegroundColor Gray

Write-Host "`n2. Are you using an App Password?" -ForegroundColor Cyan
Write-Host "   Regular passwords won't work with Gmail SMTP" -ForegroundColor Gray
Write-Host "   Generate one at: https://myaccount.google.com/apppasswords" -ForegroundColor Gray
Write-Host "   It should be 16 characters like: xxxx xxxx xxxx xxxx" -ForegroundColor Gray

Write-Host "`n3. Is 'Less secure app access' disabled?" -ForegroundColor Cyan
Write-Host "   This should be OFF (App Passwords are more secure)" -ForegroundColor Gray
Write-Host "   If it's ON, turn it OFF and use App Passwords instead" -ForegroundColor Gray

Write-Host "`n=== Let's Test with Detailed Debugging ===" -ForegroundColor Cyan

$testNow = Read-Host "`nDo you want to test with detailed debugging? (y/n)"
if ($testNow -ne 'y') {
    exit
}

Write-Host "`nEnter credentials for $($emailSettings.FromAddress):" -ForegroundColor Yellow
Write-Host "Username should be: dev@auto-m8.io" -ForegroundColor Gray
Write-Host "Password should be: Your 16-character App Password (with or without spaces)" -ForegroundColor Gray

$username = Read-Host "Username"
$password = Read-Host "Password" -AsSecureString

# Convert SecureString to plain text for testing
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

Write-Host "`nCredential Check:" -ForegroundColor Yellow
Write-Host "  Username: $username" -ForegroundColor Gray
Write-Host "  Password Length: $($plainPassword.Length) characters" -ForegroundColor Gray

# Check if it looks like an App Password
if ($plainPassword.Length -eq 16 -or $plainPassword.Length -eq 19) {
    Write-Host "  ✓ Password length matches App Password format" -ForegroundColor Green
} else {
    Write-Host "  ⚠ Password length doesn't match App Password format (should be 16 chars, or 19 with spaces)" -ForegroundColor Yellow
}

# Remove spaces from password if present (App Passwords work with or without spaces)
$plainPassword = $plainPassword -replace '\s', ''

Write-Host "`n=== Testing SMTP Connection ===" -ForegroundColor Cyan

try {
    Write-Host "Creating SMTP client..." -ForegroundColor Gray
    $smtp = New-Object System.Net.Mail.SmtpClient($emailSettings.SMTPServer, $emailSettings.SMTPPort)
    $smtp.EnableSsl = $true
    $smtp.Timeout = 30000
    
    Write-Host "Setting credentials..." -ForegroundColor Gray
    $smtp.Credentials = New-Object System.Net.NetworkCredential($username, $plainPassword)
    
    Write-Host "Creating test message..." -ForegroundColor Gray
    $msg = New-Object System.Net.Mail.MailMessage
    $msg.From = $emailSettings.FromAddress
    $msg.To.Add($emailSettings.ToAddresses)
    $msg.Subject = "SMTP Auth Test - $(Get-Date -Format 'HH:mm:ss')"
    $msg.Body = "If you receive this, authentication is working!"
    
    Write-Host "Attempting to send..." -ForegroundColor Gray
    $smtp.Send($msg)
    
    Write-Host "`n✓ SUCCESS! Email sent successfully!" -ForegroundColor Green
    Write-Host "Check $($emailSettings.ToAddresses) for the test email." -ForegroundColor Cyan
    
} catch {
    Write-Host "`n✗ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    
    if ($_.Exception.Message -match "5\.7\.0") {
        Write-Host "`n=== Authentication Failed ===" -ForegroundColor Red
        Write-Host "Gmail rejected the credentials. Possible causes:" -ForegroundColor Yellow
        Write-Host "1. Wrong password - Make sure you're using an App Password" -ForegroundColor White
        Write-Host "2. Wrong username - Should be full email: dev@auto-m8.io" -ForegroundColor White
        Write-Host "3. App Passwords not enabled - Need 2FA enabled first" -ForegroundColor White
        Write-Host "4. Account suspended or locked" -ForegroundColor White
        
        Write-Host "`n=== How to Generate an App Password ===" -ForegroundColor Cyan
        Write-Host "1. Go to: https://accounts.google.com" -ForegroundColor White
        Write-Host "2. Sign in with dev@auto-m8.io" -ForegroundColor White
        Write-Host "3. Go to Security → 2-Step Verification (must be ON)" -ForegroundColor White
        Write-Host "4. Go to Security → App passwords" -ForegroundColor White
        Write-Host "5. Select 'Mail' and 'Windows Computer'" -ForegroundColor White
        Write-Host "6. Copy the 16-character password shown" -ForegroundColor White
        Write-Host "7. Use that password here (spaces optional)" -ForegroundColor White
    }
    
    if ($_.Exception.Message -match "5\.5\.1") {
        Write-Host "`n=== SMTP Authentication Not Configured ===" -ForegroundColor Red
        Write-Host "The SMTP client isn't sending credentials properly." -ForegroundColor Yellow
    }
    
    if ($_.Exception.Message -match "5\.7\.8") {
        Write-Host "`n=== Bad Username or Password ===" -ForegroundColor Red
        Write-Host "The username/password combination is incorrect." -ForegroundColor Yellow
    }
}

# Clean up password from memory
$plainPassword = $null
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
[System.GC]::Collect()

Write-Host "`n=== Additional Troubleshooting ===" -ForegroundColor Cyan
Write-Host "If authentication keeps failing:" -ForegroundColor Yellow
Write-Host "1. Try signing in to Gmail web to ensure account is active" -ForegroundColor Gray
Write-Host "2. Check for security alerts at: https://myaccount.google.com/notifications" -ForegroundColor Gray
Write-Host "3. Review recent activity at: https://myaccount.google.com/device-activity" -ForegroundColor Gray
Write-Host "4. For Google Workspace, check admin settings allow SMTP" -ForegroundColor Gray
Write-Host "5. Try generating a new App Password" -ForegroundColor Gray

Write-Host "`n=== Alternative: Use Your Personal Gmail ===" -ForegroundColor Cyan
Write-Host "If dev@auto-m8.io isn't working, you can use your personal Gmail:" -ForegroundColor Yellow
Write-Host "1. Update FromAddress in systemstatus.config.json to your Gmail" -ForegroundColor Gray
Write-Host "2. Enable 2FA on your account" -ForegroundColor Gray
Write-Host "3. Generate an App Password for your account" -ForegroundColor Gray
Write-Host "4. Use those credentials in tests" -ForegroundColor Gray