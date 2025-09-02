# HITLCore.psm1
# Human-in-the-Loop Core Configuration and Utilities
# Version 2.0.0 - 2025-08-26
# Part of refactored Unity-Claude-HITL module

#region Module Variables and Configuration

# Global configuration storage
$script:HITLConfig = @{
    DatabasePath = Join-Path $env:USERPROFILE ".unity-claude\hitl.db"
    DefaultTimeout = 1440  # 24 hours in minutes
    EscalationTimeout = 720  # 12 hours in minutes
    TokenExpirationMinutes = 4320  # 3 days
    MaxEscalationLevels = 3
    EmailTemplate = "DefaultApproval"
    NotificationSettings = @{
        EmailEnabled = $true
        WebhookEnabled = $false
        MobileOptimized = $true
    }
    LangGraphEndpoint = "http://localhost:8001"
    SecuritySettings = @{
        RequireTokenValidation = $true
        AllowMobileApprovals = $true
        AuditAllActions = $true
    }
}

Write-Verbose "REFACTORED VERSION - HITLCore component initialized"

#endregion

#region Configuration Management Functions

function Set-HITLConfiguration {
    <#
    .SYNOPSIS
        Sets HITL module configuration.
    
    .DESCRIPTION
        Updates module configuration with validation and persistence.
    
    .PARAMETER Configuration
        Hashtable containing configuration settings.
    
    .EXAMPLE
        Set-HITLConfiguration -Configuration @{ DefaultTimeout = 720; EmailEnabled = $true }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Configuration
    )
    
    try {
        foreach ($key in $Configuration.Keys) {
            if ($script:HITLConfig.ContainsKey($key)) {
                $script:HITLConfig[$key] = $Configuration[$key]
                Write-Verbose "Updated configuration: $key = $($Configuration[$key])"
            } else {
                Write-Warning "Unknown configuration key: $key"
            }
        }
        
        Write-Host "HITL configuration updated successfully." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to update configuration: $($_.Exception.Message)"
        return $false
    }
}

function Get-HITLConfiguration {
    <#
    .SYNOPSIS
        Gets current HITL module configuration.
    
    .EXAMPLE
        $config = Get-HITLConfiguration
    #>
    [CmdletBinding()]
    param()
    
    return $script:HITLConfig.Clone()
}

#endregion

#region Governance Integration

# Import governance integration module
$governanceModule = Join-Path $PSScriptRoot "..\Unity-Claude-GovernanceIntegration.psm1"
if (Test-Path $governanceModule) {
    Import-Module $governanceModule -Force -ErrorAction SilentlyContinue
    Write-Verbose "Imported governance integration module"
}

#endregion

#region Export Module Members

Export-ModuleMember -Function @(
    'Set-HITLConfiguration',
    'Get-HITLConfiguration'
) -Variable @(
    'HITLConfig'
)

#endregion
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDBAegtTpbR5ISH
# fJtqA26QzsF+cvEMTEoonvi6ICUkh6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJnhhjSleBZQSJ+MDqkoOo/V
# /2k9VbpRVqZ0JdLEcK4vMA0GCSqGSIb3DQEBAQUABIIBAFNPLDFNaBoLCtByMXCp
# B8M1Koz2jVhajAKLhIxdQdRCcH8Lav7TVpwwY473yE1AnuJhjzZXSJHOGxe1cvQ9
# yA4qhd9QjL7aWBsJ1/MTnMb16Dvq3Bgr5dTTTb7KxB+2uKu5/rqVE+xD21iiKgd1
# sQ5k7SIkgvbVx6+6VjZ9LpdgNTdb+tTykRrIvH2h28D9sxuuD2I8NVYTNu3Pro55
# 5vK0JdvFAew8WQtQwgYSUGjv5tTRIXHmlH/Y/k2CJl8botT43+ImwUQFFqghAe0p
# hVj+gMnCV7IwQt+MsgC1XNSE6sXOxtPdAeA8rVHrQmgz6W5jP0SjMEmophseoiWw
# he4=
# SIG # End signature block
