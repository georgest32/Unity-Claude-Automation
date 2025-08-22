function Set-GitHubPAT {
    <#
    .SYNOPSIS
    Sets and securely stores a GitHub Personal Access Token
    
    .DESCRIPTION
    Stores a GitHub PAT using Windows Data Protection API (DPAPI) for secure storage.
    The token is encrypted and can only be decrypted by the same user on the same machine.
    
    .PARAMETER Token
    The GitHub Personal Access Token as a plain text string
    
    .PARAMETER SecureToken
    The GitHub Personal Access Token as a SecureString
    
    .PARAMETER Credential
    A PSCredential object containing the token in the password field
    
    .PARAMETER ExpirationDate
    Optional expiration date for the token
    
    .PARAMETER Force
    Overwrite existing token without confirmation
    
    .EXAMPLE
    Set-GitHubPAT -Token "ghp_xxxxxxxxxxxxxxxxxxxx"
    
    .EXAMPLE
    $secureToken = Read-Host "Enter GitHub PAT" -AsSecureString
    Set-GitHubPAT -SecureToken $secureToken -ExpirationDate (Get-Date).AddDays(90)
    #>
    [CmdletBinding(DefaultParameterSetName = 'PlainText')]
    param(
        [Parameter(Mandatory = $true, ParameterSetName = 'PlainText')]
        [string]$Token,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'SecureString')]
        [System.Security.SecureString]$SecureToken,
        
        [Parameter(Mandatory = $true, ParameterSetName = 'Credential')]
        [System.Management.Automation.PSCredential]$Credential,
        
        [Parameter()]
        [DateTime]$ExpirationDate,
        
        [Parameter()]
        [switch]$Force
    )
    
    begin {
        Write-Verbose "Setting GitHub PAT using parameter set: $($PSCmdlet.ParameterSetName)"
        $moduleRoot = Split-Path $PSScriptRoot -Parent
        $projectRoot = Split-Path $moduleRoot -Parent
        $logFile = Join-Path $projectRoot "unity_claude_automation.log"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    process {
        try {
            # Convert token to SecureString based on parameter set
            switch ($PSCmdlet.ParameterSetName) {
                'PlainText' {
                    Write-Verbose "Converting plain text token to SecureString"
                    $secureString = ConvertTo-SecureString -String $Token -AsPlainText -Force
                    # Clear the plain text token from memory
                    $Token = $null
                    [System.GC]::Collect()
                }
                'SecureString' {
                    Write-Verbose "Using provided SecureString"
                    $secureString = $SecureToken
                }
                'Credential' {
                    Write-Verbose "Extracting SecureString from credential"
                    $secureString = $Credential.Password
                }
            }
            
            # Check if token already exists
            if ((Test-Path $script:CredentialPath) -and -not $Force) {
                $response = Read-Host "A GitHub PAT already exists. Overwrite? (Y/N)"
                if ($response -ne 'Y') {
                    Write-Warning "Operation cancelled by user"
                    return
                }
            }
            
            # Create credential object (username is ignored by GitHub API)
            $credential = New-Object System.Management.Automation.PSCredential("GitHubPAT", $secureString)
            
            # Store credential securely using DPAPI
            Write-Verbose "Storing credential at: $script:CredentialPath"
            $credential | Export-Clixml -Path $script:CredentialPath -Force
            
            # Update configuration with token metadata
            $script:Config.LastTokenRotation = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            if ($ExpirationDate) {
                $script:Config.TokenExpirationDate = $ExpirationDate.ToString("yyyy-MM-dd")
                Write-Verbose "Token expiration set to: $($ExpirationDate.ToString('yyyy-MM-dd'))"
            }
            
            # Save configuration
            $script:Config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile -Force
            
            # Validate the token
            Write-Verbose "Validating token..."
            if (Test-GitHubPAT) {
                Write-Host "GitHub PAT successfully stored and validated" -ForegroundColor Green
                
                # Configure PowerShellForGitHub if available
                if ($script:PowerShellForGitHubAvailable) {
                    try {
                        Write-Verbose "Configuring PowerShellForGitHub module..."
                        Import-Module PowerShellForGitHub -ErrorAction Stop
                        Set-GitHubAuthentication -Credential $credential -SessionOnly
                        Write-Verbose "PowerShellForGitHub configured with new token"
                    } catch {
                        Write-Verbose "Could not configure PowerShellForGitHub: $_"
                    }
                }
                
                # Log success
                Add-Content -Path $logFile -Value "[$timestamp] [INFO] GitHub PAT successfully configured" -ErrorAction SilentlyContinue
                
                return $true
            } else {
                Write-Warning "Token stored but validation failed. Please verify the token is correct."
                Add-Content -Path $logFile -Value "[$timestamp] [WARNING] GitHub PAT stored but validation failed" -ErrorAction SilentlyContinue
                return $false
            }
            
        } catch {
            Write-Error "Failed to set GitHub PAT: $_"
            Add-Content -Path $logFile -Value "[$timestamp] [ERROR] Failed to set GitHub PAT: $_" -ErrorAction SilentlyContinue
            throw
        } finally {
            # Clear sensitive data from memory
            if ($secureString) {
                $secureString.Dispose()
            }
            if ($credential) {
                $credential = $null
            }
            [System.GC]::Collect()
        }
    }
}