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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCysMQMZqPaO4fR
# 7Ubo46R2J9wOco9Lx1YnaTnJUGd3S6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOCmB3yHryicsHmOhR6GgSG0
# 5ksp0Aqda4/P8hBidP+VMA0GCSqGSIb3DQEBAQUABIIBAC74xEv2qAc3zWmxw51i
# F4GE+hZgsEpAKIIm89LZB+N5SrrGo7XeBKlUbVO/Uy+YoS2N0v4uf8bZIkf/oLBQ
# v5SgUy0IoouLwf97rUKCjxFSHU7G75tue0VFlRZ4Ef70PogK+Jd2nNZ/mtFSAAs4
# L/p+ro6tiXncDZjZuvCrD6nIakgE4kayKe5YB41J9jBSIgTTxqwd57vnxtDIdSYA
# ++fDyLhC37OtDRdl+xergREXJv8OBT5vqT5yYYhaqWXN+IF5sCovuapSCRtzTFzX
# SlyYzu3NaBF8c/G70lpEo6jOeHDb4I9XOsrYNX35/DWJjEUAqaQV44cTx8Dzykzl
# TAc=
# SIG # End signature block
