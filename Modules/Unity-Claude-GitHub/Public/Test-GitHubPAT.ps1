function Test-GitHubPAT {
    <#
    .SYNOPSIS
    Tests the validity of the stored GitHub Personal Access Token
    
    .DESCRIPTION
    Validates the stored GitHub PAT by making a test API call to GitHub
    
    .PARAMETER Token
    Optional token to test. If not provided, uses the stored token.
    
    .EXAMPLE
    Test-GitHubPAT
    
    .EXAMPLE
    if (Test-GitHubPAT) { Write-Host "Token is valid" }
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Token
    )
    
    begin {
        Write-Verbose "Testing GitHub PAT validity"
        $moduleRoot = Split-Path $PSScriptRoot -Parent
        $projectRoot = Split-Path $moduleRoot -Parent
        $logFile = Join-Path $projectRoot "unity_claude_automation.log"
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    process {
        try {
            # Get token if not provided
            if (-not $Token) {
                $Token = Get-GitHubPATInternal
                if (-not $Token) {
                    Write-Warning "No token available to test"
                    return $false
                }
            }
            
            # Prepare API call
            $headers = @{
                "Authorization" = "Bearer $Token"
                "Accept" = "application/vnd.github.v3+json"
            }
            
            $uri = "https://api.github.com/user"
            
            Write-Verbose "Making test API call to GitHub"
            
            # Make API call
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ErrorAction Stop
            
            if ($response.login) {
                Write-Verbose "Token validated successfully for user: $($response.login)"
                Write-Host "GitHub PAT is valid - User: $($response.login)" -ForegroundColor Green
                
                # Log rate limit status
                $rateLimitResponse = Invoke-RestMethod -Uri "https://api.github.com/rate_limit" -Headers $headers -ErrorAction SilentlyContinue
                if ($rateLimitResponse) {
                    $remaining = $rateLimitResponse.rate.remaining
                    $limit = $rateLimitResponse.rate.limit
                    Write-Verbose "Rate limit: $remaining/$limit remaining"
                }
                
                Add-Content -Path $logFile -Value "[$timestamp] [INFO] GitHub PAT validated successfully for user: $($response.login)" -ErrorAction SilentlyContinue
                return $true
            } else {
                Write-Warning "Token validation returned unexpected response"
                Add-Content -Path $logFile -Value "[$timestamp] [WARNING] Token validation returned unexpected response" -ErrorAction SilentlyContinue
                return $false
            }
            
        } catch {
            $statusCode = $_.Exception.Response.StatusCode.value__
            
            switch ($statusCode) {
                401 {
                    Write-Warning "Token is invalid or expired (401 Unauthorized)"
                    Add-Content -Path $logFile -Value "[$timestamp] [ERROR] Token validation failed: 401 Unauthorized" -ErrorAction SilentlyContinue
                }
                403 {
                    Write-Warning "Token lacks required permissions (403 Forbidden)"
                    Add-Content -Path $logFile -Value "[$timestamp] [ERROR] Token validation failed: 403 Forbidden" -ErrorAction SilentlyContinue
                }
                default {
                    Write-Warning "Token validation failed: $_"
                    Add-Content -Path $logFile -Value "[$timestamp] [ERROR] Token validation failed: $_" -ErrorAction SilentlyContinue
                }
            }
            
            return $false
            
        } finally {
            # Clear token from memory
            if ($Token) {
                $Token = $null
                [System.GC]::Collect()
            }
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCATb+PFJOqT1qps
# 0d9SryePoWju+SHK8qtyqQlThoYzXKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGzBhjeeAIxF0cqTmBvr3pek
# HQxfdOHdOHLGTMGhdoinMA0GCSqGSIb3DQEBAQUABIIBAIZVF3AtspV07pzVOESM
# 72h2Z3hP04sZqvdIROEQyFFmcx/sPB9MfaNzFIrgCqlyXSgaOERMFL7wiNFLDlb0
# oF9hai5Lty/1ih6qmcjz4A2I59D1wQ3Ztr8y7GKlJsxTU37TJVzDKbMWqq/AKsM4
# KqiJmpN100rY4qwFb7kSUV0NUbdEH+XiktS5zO/1ii60gjoX8nfpvW4Vvx5CdXUl
# i4eC0WQEgQI/Zd5m+yo2PwMEwLdbGsWRUArpa5x26eMtEpzsGNzHhjcr/R0MV6ya
# 42pOIN7DHC1G1Ab3zDsAg7lsI7/ilo2il0jV3FLqAwyI3nwdLvyJVQMhNTt2tpgN
# /dI=
# SIG # End signature block
