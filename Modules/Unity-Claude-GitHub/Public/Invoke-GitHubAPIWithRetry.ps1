function Invoke-GitHubAPIWithRetry {
    <#
    .SYNOPSIS
    Invokes GitHub API with exponential backoff retry logic
    
    .DESCRIPTION
    Makes GitHub API calls with automatic retry on failure, exponential backoff, and rate limit handling
    
    .PARAMETER Uri
    The GitHub API endpoint URI
    
    .PARAMETER Method
    HTTP method (GET, POST, PUT, DELETE, PATCH)
    
    .PARAMETER Body
    Request body for POST/PUT/PATCH requests
    
    .PARAMETER Headers
    Additional headers to include
    
    .PARAMETER MaxAttempts
    Maximum number of retry attempts (default: 5)
    
    .PARAMETER BaseDelay
    Base delay in seconds for exponential backoff (default: 1)
    
    .PARAMETER NoRetry
    Disable retry logic
    
    .EXAMPLE
    Invoke-GitHubAPIWithRetry -Uri "https://api.github.com/user/repos" -Method GET
    
    .EXAMPLE
    $body = @{ name = "new-repo"; private = $true } | ConvertTo-Json
    Invoke-GitHubAPIWithRetry -Uri "https://api.github.com/user/repos" -Method POST -Body $body
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        
        [Parameter()]
        [ValidateSet('GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD')]
        [string]$Method = 'GET',
        
        [Parameter()]
        [string]$Body,
        
        [Parameter()]
        [hashtable]$Headers = @{},
        
        [Parameter()]
        [int]$MaxAttempts = 5,
        
        [Parameter()]
        [int]$BaseDelay = 1,
        
        [Parameter()]
        [switch]$NoRetry
    )
    
    begin {
        Write-Verbose "Preparing GitHub API call to: $Uri"
        $moduleRoot = Split-Path $PSScriptRoot -Parent
        $projectRoot = Split-Path $moduleRoot -Parent
        $logFile = Join-Path $projectRoot "unity_claude_automation.log"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Get stored PAT
        $token = Get-GitHubPATInternal
        if (-not $token) {
            throw "No GitHub PAT configured. Use Set-GitHubPAT to configure."
        }
        
        # Prepare headers
        $apiHeaders = @{
            "Authorization" = "Bearer $token"
            "Accept" = "application/vnd.github.v3+json"
            "User-Agent" = "Unity-Claude-GitHub/1.0"
        }
        
        # Merge additional headers
        foreach ($key in $Headers.Keys) {
            $apiHeaders[$key] = $Headers[$key]
        }
        
        # Clear token from memory
        $token = $null
        [System.GC]::Collect()
    }
    
    process {
        Write-Debug "INVOKE-RETRY: Starting API call"
        Write-Debug "  URI: $Uri"
        Write-Debug "  Method: $Method"
        Write-Debug "  MaxAttempts: $MaxAttempts"
        Write-Debug "  BaseDelay: $BaseDelay"
        
        # If NoRetry is specified, make single attempt
        if ($NoRetry) {
            $MaxAttempts = 1
            Write-Debug "INVOKE-RETRY: NoRetry specified, setting MaxAttempts to 1"
        }
        
        for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
            Write-Debug "INVOKE-RETRY: Attempt $attempt of $MaxAttempts"
            try {
                Write-Verbose "Attempt $attempt of ${MaxAttempts}: $Method $Uri"
                Add-Content -Path $logFile -Value "[$timestamp] [DEBUG] GitHub API attempt ${attempt}: $Method $Uri" -ErrorAction SilentlyContinue
                
                # Prepare parameters
                $params = @{
                    Uri = $Uri
                    Method = $Method
                    Headers = $apiHeaders
                    ErrorAction = 'Stop'
                }
                
                if ($Body) {
                    $params.Body = $Body
                    $params.ContentType = 'application/json'
                }
                
                # Make API call
                $response = Invoke-RestMethod @params
                
                # Check rate limit headers
                $rateLimitRemaining = $null
                $rateLimitLimit = $null
                $rateLimitReset = $null
                
                if ($PSVersionTable.PSVersion.Major -ge 7) {
                    # PowerShell 7+ provides response headers
                    $responseHeaders = $response.PSObject.Properties['Headers'].Value
                    if ($responseHeaders) {
                        $rateLimitRemaining = $responseHeaders['X-RateLimit-Remaining']
                        $rateLimitLimit = $responseHeaders['X-RateLimit-Limit']
                        $rateLimitReset = $responseHeaders['X-RateLimit-Reset']
                    }
                }
                
                # Log rate limit status
                if ($rateLimitRemaining) {
                    Write-Verbose "Rate limit: $rateLimitRemaining/$rateLimitLimit remaining"
                    
                    # Warn if approaching limit
                    $warningThreshold = [int]($rateLimitLimit * $script:Config.RateLimitWarningThreshold)
                    if ($rateLimitRemaining -le $warningThreshold) {
                        Write-Warning "Approaching GitHub rate limit: $rateLimitRemaining/$rateLimitLimit remaining"
                        Add-Content -Path $logFile -Value "[$timestamp] [WARNING] Approaching rate limit: $rateLimitRemaining/$rateLimitLimit" -ErrorAction SilentlyContinue
                    }
                }
                
                Write-Verbose "API call successful"
                Add-Content -Path $logFile -Value "[$timestamp] [INFO] GitHub API success: $METHOD $Uri" -ErrorAction SilentlyContinue
                return $response
                
            } catch {
                $exception = $_.Exception
                $statusCode = $null
                
                # Extract status code
                if ($exception.Response) {
                    $statusCode = [int]$exception.Response.StatusCode
                }
                
                Write-Verbose "API call failed with status code: $statusCode"
                Add-Content -Path $logFile -Value "[$timestamp] [ERROR] GitHub API failed (attempt $attempt): $statusCode - $_" -ErrorAction SilentlyContinue
                
                # Determine if we should retry
                $shouldRetry = $false
                $delay = 0
                
                switch ($statusCode) {
                    401 {
                        # Authentication failure - don't retry
                        Write-Error "Authentication failed. Check your GitHub token."
                        throw $_
                    }
                    403 {
                        # Could be rate limiting or permissions
                        if ($exception.Message -match "rate limit") {
                            $shouldRetry = $true
                            # Check for Retry-After header
                            if ($exception.Response.Headers -and $exception.Response.Headers['Retry-After']) {
                                $delay = [int]$exception.Response.Headers['Retry-After']
                                Write-Warning "Rate limited. Retry-After: $delay seconds"
                            } else {
                                # Use exponential backoff
                                $delay = [Math]::Pow(2, $attempt - 1) * $BaseDelay
                            }
                        } else {
                            Write-Error "Access forbidden. Check token permissions."
                            throw $_
                        }
                    }
                    404 {
                        # Not found - don't retry
                        Write-Error "Resource not found: $Uri"
                        throw $_
                    }
                    429 {
                        # Too many requests - definitely retry
                        $shouldRetry = $true
                        # Check for Retry-After header
                        if ($exception.Response.Headers -and $exception.Response.Headers['Retry-After']) {
                            $delay = [int]$exception.Response.Headers['Retry-After']
                            Write-Warning "Rate limited (429). Retry-After: $delay seconds"
                        } else {
                            # Use exponential backoff
                            $delay = [Math]::Pow(2, $attempt - 1) * $BaseDelay
                            Write-Warning "Rate limited (429). Using exponential backoff: $delay seconds"
                        }
                    }
                    422 {
                        Write-Debug "INVOKE-RETRY: Processing 422 Validation Failed error"
                        
                        # Validation failed - usually means bad query parameters, don't retry
                        # Extract error message with comprehensive defensive programming
                        $errorMsg = "Validation failed"  # Default fallback
                        
                        Write-Debug "INVOKE-RETRY: 422 Error - ErrorDetails.Message: [$($_.ErrorDetails.Message)]"
                        Write-Debug "INVOKE-RETRY: 422 Error - Exception.Message: [$($_.Exception.Message)]"
                        Write-Debug "INVOKE-RETRY: 422 Error - Full Error: [$_]"
                        
                        # Robust error message extraction with multiple fallbacks
                        if ($_.ErrorDetails.Message -and -not [string]::IsNullOrWhiteSpace($_.ErrorDetails.Message)) {
                            Write-Debug "INVOKE-RETRY: ErrorDetails.Message is not null/empty"
                            try {
                                $errorResponse = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction Stop
                                Write-Debug "INVOKE-RETRY: Successfully parsed JSON response"
                                if ($errorResponse.message) {
                                    $errorMsg = $errorResponse.message
                                    Write-Debug "INVOKE-RETRY: 422 Error - Parsed JSON message: $errorMsg"
                                } else {
                                    $errorMsg = $_.ErrorDetails.Message
                                    Write-Debug "INVOKE-RETRY: 422 Error - Using raw ErrorDetails.Message (no message field)"
                                }
                            } catch {
                                # JSON parsing failed, use raw message
                                $errorMsg = $_.ErrorDetails.Message
                                Write-Debug "INVOKE-RETRY: 422 Error - JSON parsing failed, using raw message: $($_.Exception.Message)"
                            }
                        } elseif ($_.Exception.Message -and -not [string]::IsNullOrWhiteSpace($_.Exception.Message)) {
                            # Fallback to exception message
                            $errorMsg = $_.Exception.Message
                            Write-Debug "INVOKE-RETRY: 422 Error - Using Exception.Message fallback"
                        } else {
                            Write-Debug "INVOKE-RETRY: 422 Error - Using default fallback message"
                        }
                        
                        Write-Debug "INVOKE-RETRY: Final error message: $errorMsg"
                        Write-Verbose "Validation failed (422): $errorMsg"
                        Write-Debug "INVOKE-RETRY: About to throw 422 exception"
                        throw $_
                    }
                    { $_ -in 500, 502, 503, 504 } {
                        # Server errors - retry
                        $shouldRetry = $true
                        $delay = [Math]::Pow(2, $attempt - 1) * $BaseDelay
                        Write-Warning "Server error ($statusCode). Will retry in $delay seconds"
                    }
                    default {
                        # Unknown error - retry with backoff
                        if ($attempt -lt $MaxAttempts) {
                            $shouldRetry = $true
                            $delay = [Math]::Pow(2, $attempt - 1) * $BaseDelay
                            Write-Warning "Request failed. Will retry in $delay seconds"
                        }
                    }
                }
                
                # Retry if appropriate
                if ($shouldRetry -and $attempt -lt $MaxAttempts) {
                    # Add jitter to prevent thundering herd
                    $jitter = Get-Random -Minimum 0 -Maximum 1000
                    $totalDelay = $delay + ($jitter / 1000)
                    
                    Write-Verbose "Waiting $totalDelay seconds before retry..."
                    Start-Sleep -Seconds $totalDelay
                } else {
                    # Max attempts reached or non-retryable error
                    if ($attempt -eq $MaxAttempts) {
                        Write-Error "Maximum retry attempts ($MaxAttempts) exceeded"
                    }
                    throw $_
                }
            }
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBm/OxBpq10BfP4
# fOZU/oq/oEOwgi9z4LnwMlNMOS2LNKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMzgFFfftaowCNt0IuAzns7q
# S1CHr1N9DsfkUF6HchJ2MA0GCSqGSIb3DQEBAQUABIIBAKuLVqR1Ze7muX3dQmpL
# ZgFd7SFSJVtbLmsKB4lg7FF27NVzlrlGzHBRaeh0wuE4Svmceq7lwUn3KsxuUOsm
# ENBpzm8uN6mTG7NrMf3AKXXsJivi08oXMJxHPY01KcM6nUfvXXcYiFgEm3kKMLYb
# Gz3NqIiswIArG0tZQ/Pk/Uvf8VHJUejdeJ0h3kjkatI83AcMnBK6BBguVjioqfLm
# fkUyHj74IYtrj383oWiopLhPBMPYUsaYDwxJxvOko+5Plh/WC1/G8TxiygKiN8Ag
# fTEK7mQ6Df94P34GSfitz912UhVEBNdnhwzT+OI5veUN4Swc1yubf+NXNCgvtpYH
# Cf8=
# SIG # End signature block
