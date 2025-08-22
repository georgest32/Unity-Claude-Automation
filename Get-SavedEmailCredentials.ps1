# Get Saved Email Credentials
# This function loads previously saved email credentials

function Get-SavedEmailCredentials {
    <#
    .SYNOPSIS
    Loads saved email credentials from encrypted file
    
    .DESCRIPTION
    Retrieves email credentials that were previously saved using Save-EmailCredentials.ps1
    The credentials are encrypted using Windows DPAPI and can only be decrypted by the
    same user on the same computer.
    
    .PARAMETER CredentialPath
    Path to the credential file (defaults to standard location)
    
    .EXAMPLE
    $cred = Get-SavedEmailCredentials
    Set-EmailCredentials -ConfigurationName "Default" -Credential $cred
    #>
    [CmdletBinding()]
    param(
        [string]$CredentialPath = "$PSScriptRoot\Modules\Unity-Claude-SystemStatus\Config\email.credential"
    )
    
    if (-not (Test-Path $CredentialPath)) {
        Write-Host "No saved credentials found at: $CredentialPath" -ForegroundColor Yellow
        Write-Host "Run .\Save-EmailCredentials.ps1 to save your credentials first." -ForegroundColor White
        return $null
    }
    
    try {
        # Load credential object from file
        $credentialObject = Get-Content $CredentialPath -Raw | ConvertFrom-Json
        
        # Convert secure string back to PSCredential
        $securePassword = $credentialObject.Password | ConvertTo-SecureString
        $credential = New-Object System.Management.Automation.PSCredential(
            $credentialObject.Username,
            $securePassword
        )
        
        Write-Host "Loaded saved credentials for: $($credentialObject.Username)" -ForegroundColor Green
        Write-Host "Saved on: $($credentialObject.SavedAt)" -ForegroundColor Gray
        
        return $credential
        
    } catch {
        Write-Host "ERROR: Failed to load credentials: $_" -ForegroundColor Red
        Write-Host "The credentials may have been saved by a different user or on a different computer." -ForegroundColor Yellow
        return $null
    }
}

# Export the function if running as a module
if ($MyInvocation.MyCommand.CommandType -eq 'ExternalScript') {
    # Running as a script - execute the function
    Get-SavedEmailCredentials
} else {
    # Being dot-sourced - just define the function
    Export-ModuleMember -Function Get-SavedEmailCredentials
}