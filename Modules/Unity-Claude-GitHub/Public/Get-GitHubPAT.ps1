function Get-GitHubPAT {
    <#
    .SYNOPSIS
    Retrieves the stored GitHub Personal Access Token
    
    .DESCRIPTION
    Retrieves the GitHub PAT from secure storage and returns it as a SecureString or PSCredential
    
    .PARAMETER AsCredential
    Returns the token as a PSCredential object
    
    .PARAMETER AsPlainText
    Returns the token as plain text (use with caution)
    
    .EXAMPLE
    $secureToken = Get-GitHubPAT
    
    .EXAMPLE
    $credential = Get-GitHubPAT -AsCredential
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$AsCredential,
        
        [Parameter()]
        [switch]$AsPlainText
    )
    
    begin {
        Write-Verbose "Retrieving GitHub PAT from: $script:CredentialPath"
        $moduleRoot = Split-Path $PSScriptRoot -Parent
        $projectRoot = Split-Path $moduleRoot -Parent
        $logFile = Join-Path $projectRoot "unity_claude_automation.log"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    process {
        try {
            # Check if credential file exists
            if (-not (Test-Path $script:CredentialPath)) {
                Write-Warning "No GitHub PAT found. Use Set-GitHubPAT to configure."
                Add-Content -Path $logFile -Value "[$timestamp] [WARNING] No GitHub PAT found in storage" -ErrorAction SilentlyContinue
                return $null
            }
            
            # Import the credential
            Write-Verbose "Importing credential from secure storage"
            $credential = Import-Clixml -Path $script:CredentialPath
            
            # Check for token expiration
            if ($script:Config.TokenExpirationDate) {
                $expirationDate = [DateTime]::Parse($script:Config.TokenExpirationDate)
                $daysUntilExpiration = ($expirationDate - (Get-Date)).Days
                
                if ($daysUntilExpiration -le 0) {
                    Write-Warning "GitHub PAT has expired! Please update with Set-GitHubPAT"
                    Add-Content -Path $logFile -Value "[$timestamp] [WARNING] GitHub PAT has expired" -ErrorAction SilentlyContinue
                } elseif ($daysUntilExpiration -le $script:Config.TokenExpirationWarningDays) {
                    Write-Warning "GitHub PAT expires in $daysUntilExpiration days"
                    Add-Content -Path $logFile -Value "[$timestamp] [WARNING] GitHub PAT expires in $daysUntilExpiration days" -ErrorAction SilentlyContinue
                }
            }
            
            # Return in requested format
            if ($AsCredential) {
                Write-Verbose "Returning PAT as PSCredential"
                return $credential
            } elseif ($AsPlainText) {
                Write-Warning "Returning PAT as plain text - use with caution!"
                $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password)
                try {
                    $plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
                    return $plainText
                } finally {
                    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
                }
            } else {
                Write-Verbose "Returning PAT as SecureString"
                return $credential.Password
            }
            
        } catch {
            Write-Error "Failed to retrieve GitHub PAT: $_"
            Add-Content -Path $logFile -Value "[$timestamp] [ERROR] Failed to retrieve GitHub PAT: $_" -ErrorAction SilentlyContinue
            return $null
        }
    }
}