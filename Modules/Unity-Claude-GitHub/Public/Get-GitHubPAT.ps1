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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDLFJQz+RSMkhf4
# HYK3nXOHdgDu2E02NmUjbm5xaJzyA6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOO4jW6MQrXdIZm9ijzH1UWd
# HUeb3QkJNEh+RZqdFUOVMA0GCSqGSIb3DQEBAQUABIIBAHSjlQHuaKt8zsEdm8G7
# 0OAy5pxMD2sgAyoyF8/PftSOwiB+u4cwaupvFDG1TLndW9VX2YldL0ITLIuxSqv1
# TlyxMHgaC23Gxn9D7xsHJEAXB6XUZVcrgf9sHDgb6Tcegj1k+XOOEgf8QgGTXfYO
# xQNIw4Yp9sJq3WFgBv5Hbj29d0kI1kdla0ZBAnfOz38J1eyKzJUdi6xN/Cpe+BA+
# 946QqX5+Pjrzt5C8geHRW+D86bmMu+6wvf5HQFBs0Z9y8qhb2WQVl+TbNDV/Xr/H
# yyfT8n2793O5PlWEv+3jwQsPtKTOl9nVH7YEgzX27fzuDRmE4Mebj9nz9ROpUGxn
# jVI=
# SIG # End signature block
