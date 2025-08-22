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