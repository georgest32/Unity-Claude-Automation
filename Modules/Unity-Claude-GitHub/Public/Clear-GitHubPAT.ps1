function Clear-GitHubPAT {
    <#
    .SYNOPSIS
    Clears the stored GitHub Personal Access Token
    
    .DESCRIPTION
    Removes the stored GitHub PAT from secure storage
    
    .PARAMETER Force
    Clear without confirmation prompt
    
    .EXAMPLE
    Clear-GitHubPAT
    
    .EXAMPLE
    Clear-GitHubPAT -Force
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter()]
        [switch]$Force
    )
    
    begin {
        Write-Verbose "Clearing GitHub PAT from storage"
        $moduleRoot = Split-Path $PSScriptRoot -Parent
        $projectRoot = Split-Path $moduleRoot -Parent
        $logFile = Join-Path $projectRoot "unity_claude_automation.log"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    process {
        try {
            # Check if credential exists
            if (-not (Test-Path $script:CredentialPath)) {
                Write-Warning "No GitHub PAT found to clear"
                return
            }
            
            # Confirm deletion unless Force is specified
            if (-not $Force) {
                $response = Read-Host "Are you sure you want to clear the stored GitHub PAT? (Y/N)"
                if ($response -ne 'Y') {
                    Write-Warning "Operation cancelled by user"
                    return
                }
            }
            
            if ($PSCmdlet.ShouldProcess($script:CredentialPath, "Remove GitHub PAT")) {
                # Remove credential file
                Remove-Item -Path $script:CredentialPath -Force
                Write-Host "GitHub PAT cleared successfully" -ForegroundColor Green
                
                # Clear from PowerShellForGitHub if loaded
                if ($script:PowerShellForGitHubAvailable -and (Get-Module -Name PowerShellForGitHub)) {
                    try {
                        Write-Verbose "Clearing PowerShellForGitHub authentication"
                        Clear-GitHubAuthentication -ErrorAction Stop
                    } catch {
                        Write-Verbose "Could not clear PowerShellForGitHub authentication: $_"
                    }
                }
                
                # Update configuration
                $script:Config.LastTokenRotation = $null
                $script:Config.TokenExpirationDate = $null
                $script:Config | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ConfigFile -Force
                
                Add-Content -Path $logFile -Value "[$timestamp] [INFO] GitHub PAT cleared from storage" -ErrorAction SilentlyContinue
            }
            
        } catch {
            Write-Error "Failed to clear GitHub PAT: $_"
            Add-Content -Path $logFile -Value "[$timestamp] [ERROR] Failed to clear GitHub PAT: $_" -ErrorAction SilentlyContinue
            throw
        }
    }
}