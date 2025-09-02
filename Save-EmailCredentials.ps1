# Save Email Credentials Persistently
# This script saves your email credentials encrypted to a file so you don't have to re-enter them

param(
    [string]$EmailAddress = "dev@auto-m8.io",
    [switch]$Force
)

Write-Host "=== Email Credential Manager ===" -ForegroundColor Cyan
Write-Host "This script will save your email credentials securely for future use." -ForegroundColor White
Write-Host ""

# Define credential file path
$credentialPath = Join-Path $PSScriptRoot "Modules\Unity-Claude-SystemStatus\Config\email.credential"

# Check if credentials already exist
if ((Test-Path $credentialPath) -and -not $Force) {
    Write-Host "Credentials already saved at: $credentialPath" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite them? (y/n)"
    if ($overwrite -ne 'y') {
        Write-Host "Keeping existing credentials." -ForegroundColor Green
        exit
    }
}

# Get credentials from user
Write-Host "Please enter your email credentials:" -ForegroundColor Yellow
Write-Host "Email: $EmailAddress" -ForegroundColor Gray
Write-Host "Password: Your 16-character Gmail App Password" -ForegroundColor Gray
Write-Host ""

$credential = Get-Credential -Message "Enter SMTP credentials" -UserName $EmailAddress

if (-not $credential) {
    Write-Host "No credentials provided. Exiting." -ForegroundColor Red
    exit
}

# Save credentials to file
try {
    # Create a secure credential object
    $credentialObject = @{
        Username = $credential.UserName
        Password = $credential.Password | ConvertFrom-SecureString
        SavedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        SavedBy = $env:USERNAME
    }
    
    # Ensure directory exists
    $configDir = Split-Path $credentialPath -Parent
    if (-not (Test-Path $configDir)) {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }
    
    # Save to JSON file
    $credentialObject | ConvertTo-Json | Set-Content -Path $credentialPath -Encoding UTF8
    
    # Set file permissions (only current user can read)
    $acl = Get-Acl $credentialPath
    $acl.SetAccessRuleProtection($true, $false)
    $permission = [System.Security.AccessControl.FileSystemAccessRule]::new(
        $env:USERNAME,
        "FullControl",
        "Allow"
    )
    $acl.SetAccessRule($permission)
    Set-Acl -Path $credentialPath -AclObject $acl
    
    Write-Host ""
    Write-Host "SUCCESS: Credentials saved securely!" -ForegroundColor Green
    Write-Host "Location: $credentialPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "The credentials are encrypted using Windows DPAPI and can only be read by:" -ForegroundColor Yellow
    Write-Host "  - Your user account: $env:USERNAME" -ForegroundColor Gray
    Write-Host "  - On this computer: $env:COMPUTERNAME" -ForegroundColor Gray
    
} catch {
    Write-Host "ERROR: Failed to save credentials: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== How to Use Saved Credentials ===" -ForegroundColor Cyan
Write-Host "Your credentials will be automatically loaded by scripts that use the email module." -ForegroundColor White
Write-Host "To manually load them in a script, use:" -ForegroundColor White
Write-Host ""
Write-Host '  $cred = Get-SavedEmailCredentials' -ForegroundColor Yellow
Write-Host ""
Write-Host "To update credentials, run this script again with -Force" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA/5tAgXxQlvJbM
# ski5KFEP1/+XqPE24n/OvL8eDjkZEKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBTEhniXfKJC9PjcrQrNC9ao
# /wVLCWBKoiSdnAqka+U7MA0GCSqGSIb3DQEBAQUABIIBAGa5Nynx47rrvN0XAPR9
# cfhtBuk+wzStrvrgwTWa5CPwQtA6+swuUi2DtA/eHelSanTCpCfdc+aKpQTF6OkF
# 5l2DzHks5zWp41P8HL/EXCPpIEDuFeHg6ofzKz9qpSBf66tQXZgq2nHBrswYeaN4
# 4hHNioW7dVwvTrFLwA/UvnoA7sSXpak25577HDQpmj7Hj9UvFpsbW8vIRmIYWVKk
# lTKphPOD5iGmKt8uuTugdpVv6LRFaHlqvvInWJB4mHcoYPmlon669UHnt+6K1t5G
# CoVLgQEPUZQhyzzVfJSTRi4WpGIgY8b4gONLQ6fA/D2+K2jdRmi9Nu2i2o8Du1P4
# 3DM=
# SIG # End signature block
