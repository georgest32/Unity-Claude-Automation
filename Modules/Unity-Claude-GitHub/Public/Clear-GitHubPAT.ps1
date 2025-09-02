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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCiRTK/6ZgdWkQg
# B8pPzR/KgqLsFN2YMqjJDwSyvaEbWqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILi/1LgiuFGDzn0fkLP0ZRIk
# OpSHqCH1IXjOjU308GnuMA0GCSqGSIb3DQEBAQUABIIBAJtwpZCmtG+qXSUBC9+E
# 3jXY55M1cD7eXLg+KoWCY3DI0mLMVZLe8OLkVJhc0deQtEDw7DxytEJ2BGAEHL2c
# v8XD6A7YCfIr3aQLfUAXQwwQrgaa0WHQwvc1wQo/QimjvjOLBybfAvox5ZmC3HD2
# eWNA6+GtUIHSyKSFBLHIpBeeQDhoHZ/E40v3F0ao/+GrKa0JxH3Uo34lJSQ3lqjY
# HMFU8t9LIuhsF2+C0cUo8eQVREOFQb4AVCKKbtJc92ymINHXeEKwG8qntm2wvwoM
# qE5D/qqXiz3zVQA25OduIRs0vSBaY8JuWdNFSGFoZY5AzK46S+py190HIacxqcdp
# RQQ=
# SIG # End signature block
