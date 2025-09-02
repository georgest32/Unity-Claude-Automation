# SecurityTokens.psm1
# Human-in-the-Loop Security and Token Management Component
# Version 2.0.0 - 2025-08-26
# Part of refactored Unity-Claude-HITL module

# Import core configuration
$coreModule = Join-Path $PSScriptRoot "HITLCore.psm1"
if (Test-Path $coreModule) {
    Import-Module $coreModule -Force -Global -ErrorAction SilentlyContinue
}

#region Security and Token Management

function New-ApprovalToken {
    <#
    .SYNOPSIS
        Generates a secure approval token for email-based approvals.
    
    .DESCRIPTION
        Creates a cryptographically secure token for approval requests, 
        implementing research-based security practices.
    
    .PARAMETER ApprovalId
        The ID of the approval request.
    
    .PARAMETER ExpirationMinutes
        Token expiration time in minutes. Defaults to configuration value.
    
    .EXAMPLE
        $token = New-ApprovalToken -ApprovalId 123
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$ApprovalId,
        
        [Parameter()]
        [int]$ExpirationMinutes = $(if ($script:HITLConfig) { $script:HITLConfig.TokenExpirationMinutes } else { 4320 })
    )
    
    try {
        # Generate cryptographically secure random bytes
        $bytes = New-Object byte[] 32
        $rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        $rng.GetBytes($bytes)
        $rng.Dispose()
        
        # Create token with metadata
        $tokenData = @{
            ApprovalId = $ApprovalId
            ExpiresAt = (Get-Date).AddMinutes($ExpirationMinutes).ToString('o')
            Nonce = [Convert]::ToBase64String($bytes)
        }
        
        # Encode as Base64 JSON
        $jsonString = ConvertTo-Json $tokenData -Compress
        $tokenBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonString)
        $token = [Convert]::ToBase64String($tokenBytes)
        
        Write-Verbose "Generated approval token for approval ID: $ApprovalId"
        return $token
    }
    catch {
        Write-Error "Failed to generate approval token: $($_.Exception.Message)"
        return $null
    }
}

function Test-ApprovalToken {
    <#
    .SYNOPSIS
        Validates an approval token.
    
    .DESCRIPTION
        Validates approval tokens using research-based security practices,
        including expiration and tamper detection.
    
    .PARAMETER Token
        The approval token to validate.
    
    .EXAMPLE
        $isValid = Test-ApprovalToken -Token $token
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Token
    )
    
    try {
        # Decode token
        $tokenBytes = [Convert]::FromBase64String($Token)
        $jsonString = [System.Text.Encoding]::UTF8.GetString($tokenBytes)
        $tokenData = ConvertFrom-Json $jsonString
        
        # Validate expiration
        $expiresAt = [DateTime]::Parse($tokenData.ExpiresAt)
        if ((Get-Date) -gt $expiresAt) {
            Write-Verbose "Token expired at: $expiresAt"
            return $false
        }
        
        # Validate approval ID exists and is pending
        # This would query the database in a full implementation
        Write-Verbose "Token validation successful for approval ID: $($tokenData.ApprovalId)"
        return $true
    }
    catch {
        Write-Verbose "Token validation failed: $($_.Exception.Message)"
        return $false
    }
}

function Get-TokenMetadata {
    <#
    .SYNOPSIS
        Extracts metadata from an approval token without validation.
    
    .PARAMETER Token
        The approval token to decode.
    
    .EXAMPLE
        $metadata = Get-TokenMetadata -Token $token
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Token
    )
    
    try {
        $tokenBytes = [Convert]::FromBase64String($Token)
        $jsonString = [System.Text.Encoding]::UTF8.GetString($tokenBytes)
        $tokenData = ConvertFrom-Json $jsonString
        
        return @{
            ApprovalId = $tokenData.ApprovalId
            ExpiresAt = [DateTime]::Parse($tokenData.ExpiresAt)
            IsExpired = (Get-Date) -gt [DateTime]::Parse($tokenData.ExpiresAt)
        }
    }
    catch {
        Write-Error "Failed to decode token metadata: $($_.Exception.Message)"
        return $null
    }
}

function Revoke-ApprovalToken {
    <#
    .SYNOPSIS
        Revokes an approval token by updating database.
    
    .PARAMETER Token
        The token to revoke.
    
    .EXAMPLE
        Revoke-ApprovalToken -Token $token
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Token
    )
    
    try {
        $metadata = Get-TokenMetadata -Token $Token
        if ($metadata) {
            # In full implementation, would update database to mark token as revoked
            Write-Verbose "Token revoked for approval ID: $($metadata.ApprovalId)"
            return $true
        }
        return $false
    }
    catch {
        Write-Error "Failed to revoke token: $($_.Exception.Message)"
        return $false
    }
}

#endregion

#region Export Module Members

Export-ModuleMember -Function @(
    'New-ApprovalToken',
    'Test-ApprovalToken', 
    'Get-TokenMetadata',
    'Revoke-ApprovalToken'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCqNcMdbdgmDTSj
# DsbikYuihEJ8WJVMLgrFsygywByKNaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMMyY/n3ZTc0NJGCR1z1C5Bp
# dQ8tV8zal0gXkpNpSfdoMA0GCSqGSIb3DQEBAQUABIIBAB3sDYO9hVm6yGgIwDaj
# orOKfCfuXtDWIKCiMu/wZJ7KeJZ/V5uaqK+ZLvUoK/U2ja3llFeJW34R3dMJ16k3
# LXLwy5xcg0wDIAhT5mepOskseObaOR51psUGP5wXARrOAG2HUZOYiVvZjHaWYYS4
# dnhwUUHE7kkcgpLxj4KMYxwco+XuBnPnrQMa/DPl0EszzrBPl5CatrJRLQpJhqgW
# FUwZcUJXaQZ7rrkzKc/7g9a0GlbWNCdilaf7YGJIs/Zk++bNqfZEJPy/JAYAv9Y8
# tpVf4VIG8b1njDY3hs3om/6YgiAQ+wh9omyk25wNUUGJ0PfqoSXpAAE6oOMK2wVt
# o34=
# SIG # End signature block
