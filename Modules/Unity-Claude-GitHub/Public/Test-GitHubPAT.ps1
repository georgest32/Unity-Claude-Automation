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
                $Token = Get-GitHubPAT -AsPlainText
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