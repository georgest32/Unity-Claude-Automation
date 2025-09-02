function Get-UnityErrorSignature {
    <#
    .SYNOPSIS
    Generates a unique signature hash for Unity errors
    
    .DESCRIPTION
    Creates a deterministic hash signature for Unity compilation errors to enable
    duplicate detection. The signature is based on error code, message pattern,
    and file/line information while ignoring variable parts like timestamps.
    
    .PARAMETER UnityError
    The Unity error object to generate a signature for
    
    .PARAMETER IncludeLineNumber
    Include line number in signature (default: false for better fuzzy matching)
    
    .PARAMETER Algorithm
    Hash algorithm to use: MD5, SHA1, SHA256 (default: SHA256)
    
    .EXAMPLE
    $error = Get-UnityErrors | Select-Object -First 1
    $signature = Get-UnityErrorSignature -UnityError $error
    
    .EXAMPLE
    $sig1 = Get-UnityErrorSignature -UnityError $error1
    $sig2 = Get-UnityErrorSignature -UnityError $error2
    if ($sig1 -eq $sig2) { Write-Host "Errors are duplicates" }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [PSCustomObject]$UnityError,
        
        [Parameter()]
        [bool]$IncludeLineNumber = $false,
        
        [Parameter()]
        [ValidateSet('MD5', 'SHA1', 'SHA256')]
        [string]$Algorithm = 'SHA256'
    )
    
    begin {
        Write-Verbose "Starting Get-UnityErrorSignature with algorithm: $Algorithm"
        
        # Log to unity_claude_automation.log
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logFile = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "unity_claude_automation.log"
        $logEntry = "[$timestamp] [INFO] Get-UnityErrorSignature: Generating error signature"
        Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
    }
    
    process {
        try {
            # Initialize signature components
            $signatureComponents = @()
            
            # Extract and normalize error components
            $errorCode = ""
            $errorMessage = ""
            $scriptPath = ""
            $lineNumber = 0
            
            # Parse error text
            if ($UnityError.ErrorText) {
                # Standard Unity error format: "Path/File.cs(10,5): error CS0103: Message"
                if ($UnityError.ErrorText -match '^(.+?)\((\d+),(\d+)\):\s*error\s+(\w+):\s*(.+)$') {
                    $scriptPath = $Matches[1]
                    $lineNumber = [int]$Matches[2]
                    $errorCode = $Matches[4]
                    $errorMessage = $Matches[5]
                }
                else {
                    # Fallback parsing
                    $errorMessage = $UnityError.ErrorText
                }
            }
            
            # Override with explicit properties if available
            if ($UnityError.Code) { $errorCode = $UnityError.Code }
            if ($UnityError.Message) { $errorMessage = $UnityError.Message }
            if ($UnityError.File) { $scriptPath = $UnityError.File }
            if ($UnityError.Line) { $lineNumber = $UnityError.Line }
            
            Write-Debug "Error components - Code: $errorCode, File: $scriptPath, Line: $lineNumber"
            
            # 1. Add error code (highest priority for matching)
            if ($errorCode) {
                $signatureComponents += "CODE:$errorCode"
                Write-Verbose "Added error code to signature: $errorCode"
            }
            
            # 2. Normalize and add file path (remove project-specific paths)
            if ($scriptPath) {
                # Remove common Unity path prefixes
                $normalizedPath = $scriptPath -replace '^.*[/\\]Assets[/\\]', 'Assets/'
                $normalizedPath = $normalizedPath -replace '\\', '/'
                
                # Extract just the filename for better cross-project matching
                $fileName = Split-Path $normalizedPath -Leaf
                $signatureComponents += "FILE:$fileName"
                
                # Also include relative path within Assets for more specific matching
                if ($normalizedPath -match 'Assets/(.+)') {
                    $relativePath = $Matches[1]
                    $signatureComponents += "PATH:$relativePath"
                }
                
                Write-Verbose "Added file to signature: $fileName"
            }
            
            # 3. Process error message (remove variable parts)
            if ($errorMessage) {
                # Normalize the message by removing variable parts
                $normalizedMessage = $errorMessage
                
                # Remove quoted strings (they often contain variable names)
                $normalizedMessage = $normalizedMessage -replace "'[^']*'", "'<VAR>'"
                $normalizedMessage = $normalizedMessage -replace '"[^"]*"', '"<VAR>"'
                
                # Remove numeric values (line numbers, counts, etc.)
                $normalizedMessage = $normalizedMessage -replace '\b\d+\b', '<NUM>'
                
                # Remove common variable patterns
                $normalizedMessage = $normalizedMessage -replace '\b[a-z][a-zA-Z0-9_]*\b', '<var>'
                $normalizedMessage = $normalizedMessage -replace '\b[A-Z][a-zA-Z0-9_]*\b', '<Type>'
                
                # Normalize whitespace
                $normalizedMessage = $normalizedMessage -replace '\s+', ' '
                $normalizedMessage = $normalizedMessage.Trim()
                
                $signatureComponents += "MSG:$normalizedMessage"
                Write-Verbose "Added normalized message to signature"
            }
            
            # 4. Optionally include line number (for very specific matching)
            if ($IncludeLineNumber -and $lineNumber -gt 0) {
                # Round line number to nearest 10 for fuzzy matching
                $roundedLine = [Math]::Floor($lineNumber / 10) * 10
                $signatureComponents += "LINE:$roundedLine"
                Write-Verbose "Added line number to signature: $roundedLine"
            }
            
            # 5. Add error category if determinable
            if ($errorCode) {
                $category = switch -Regex ($errorCode) {
                    '^CS\d+' { "CSHARP" }
                    '^BCE\d+' { "BOO" }
                    '^US\d+' { "UNITYSCRIPT" }
                    'NullReference' { "NULL_REF" }
                    default { "UNKNOWN" }
                }
                $signatureComponents += "CAT:$category"
            }
            
            # Combine components into a single string
            $signatureString = $signatureComponents -join "|"
            Write-Debug "Signature string: $signatureString"
            
            # Generate hash based on selected algorithm
            $hashAlgorithm = switch ($Algorithm) {
                'MD5' { [System.Security.Cryptography.MD5]::Create() }
                'SHA1' { [System.Security.Cryptography.SHA1]::Create() }
                'SHA256' { [System.Security.Cryptography.SHA256]::Create() }
            }
            
            try {
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($signatureString)
                $hashBytes = $hashAlgorithm.ComputeHash($bytes)
                $signature = [BitConverter]::ToString($hashBytes) -replace '-', ''
                
                # Shorten signature for readability (first 16 chars should be sufficient)
                $signature = $signature.Substring(0, [Math]::Min(16, $signature.Length))
                
                Write-Verbose "Generated signature: $signature"
                
                # Log success
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $logEntry = "[$timestamp] [SUCCESS] Get-UnityErrorSignature: Generated signature $signature"
                Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
                
                return $signature
            }
            finally {
                if ($hashAlgorithm) {
                    $hashAlgorithm.Dispose()
                }
            }
        }
        catch {
            # Log error
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [ERROR] Get-UnityErrorSignature: Failed to generate - $($_.Exception.Message)"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Error "Failed to generate Unity error signature: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Completed Get-UnityErrorSignature"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBKEA7G7+fTfw+K
# SYRu9CmaFdvZRlZb7YUgI1Um5upSA6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIHnlZVGPEZjYTdepsTX4xVP+
# RjBPtVMh8fTFrfZsNSdxMA0GCSqGSIb3DQEBAQUABIIBAGQ8NsZEFX30As/aAwg9
# 9IjSelO7VkB4M+5iEJ2v8KxLDHu0ZZr4n1XWx9cj/5F7cskuY6nbN7k4sCQa9iXA
# QaD8bqoqo3g5pYQoeQBY35ksUe4I6tNmHnJ3g2DKb7ljuz2sdM9ynR06mgepqpge
# OUQoKUWqx8z1NPDFKyg9dertqOKVqVdpnZJBtimTIxowGtwOaY2Hn1U1qZqSYrzb
# A+IE5/g+cYrA3mOpCjbRZkVQ3TkLiSVCZdzURl2evfNNToEzYZ7JoG+goO8PUU9F
# NBhUMNCn15UZpnZFvfzboOin7WwfsWeT7M2ohd1GmCMm7nonZSCwb2ysRt6PLjjz
# zyg=
# SIG # End signature block
