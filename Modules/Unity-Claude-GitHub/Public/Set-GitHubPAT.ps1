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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCcxgmZxcL7v+UW
# W8d80zBw/0UH7xPe0uwtLCWhBugjcqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPjdzanvBqSMuNSGSui7hohU
# WqG7Gn0FQhSO/hz1hoYBMA0GCSqGSIb3DQEBAQUABIIBAIDebvT0y4v1MyDG4fVP
# qVMz6E6GVhyy31I0FRkWveRkLCrIG96w/pa9jw5Yy+ctC+Lf6Y6hVS+d4yusz3fB
# uyh3s6bl46YP1H0lfAMDr6EFQqf1hCJj/ESRh9SQfVnZCl0BG0L//whs/p98bOOZ
# 30+QlQ9RY1MuzC4BS8EgVBAAfEyRx8zcZyCAvPKocxuumYK3I8YBfJFPOxehgX3M
# r5+ZVDHAKVSX7g0urnfA/5qqaqg9kmLBwxRlifw2igJwj/n9XL5LdroDrgg2Egs5
# M9rRCTGnECLSwZENZ8DeJUv63JwivsoA5MTlw+SrmHMDjnowGgXnhMK/q2D2XSBZ
# hbs=
# SIG # End signature block
