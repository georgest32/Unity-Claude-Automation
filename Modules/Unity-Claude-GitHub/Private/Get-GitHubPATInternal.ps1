function Get-GitHubPATInternal {
    <#
    .SYNOPSIS
    Internal function to retrieve GitHub PAT without warnings
    
    .DESCRIPTION
    Internal helper function that retrieves the GitHub PAT as plain text
    without showing security warnings. Used by other module functions.
    
    .PARAMETER AsSecureString
    Return as SecureString instead of plain text
    #>
    [CmdletBinding()]
    param(
        [switch]$AsSecureString
    )
    
    try {
        # Check if credential file exists
        if (-not (Test-Path $script:CredentialPath)) {
            return $null
        }
        
        # Import the credential
        $credential = Import-Clixml -Path $script:CredentialPath
        
        if ($AsSecureString) {
            return $credential.Password
        } else {
            # Return as plain text without warning for internal use
            $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($credential.Password)
            try {
                $plainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
                return $plainText
            } finally {
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
            }
        }
    } catch {
        return $null
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCC+TpZkwsYbzGMO
# RM8mB4erwi/hPwDO7nQqzXvUwxYxfqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIG+emRXg4fyhV6QhaWi8zwxk
# 9GrWAyj08EM3Tx5p3pXyMA0GCSqGSIb3DQEBAQUABIIBADAsnDNtxpZS7gPy7u7c
# ipSjGAVpK/TPfOOKvJEhAPzg+4NlT0UeWV4AMYcJsKflpuXICJiaJdAFwPwTCALj
# upfF5dWeiuzlzgygdVSmANreJ0V3Dvj+4aq3j42Bi4DRwWQ4bCBceN5Lh1a3wHkD
# he08/J3diOc6hxT5bat+AJxI3LUO1IhP29bMjVMTjj7rnTk+UTu2iv6XvpQDtLqL
# f/K7kQa7WSWW64dVK6ZW8XepxWkTnsm+flpeN1DJ/XK/2iE4MI2fpfI2KMRf52FR
# mX0xmLu1BUQAnLuxFI4cmLNsWBeZDib8n6hWrxHPjAoZ4XATEu6xWGAUdW8QDP3D
# MNs=
# SIG # End signature block
