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
        $token = Get-GitHubPAT -AsPlainText
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
        # If NoRetry is specified, make single attempt
        if ($NoRetry) {
            $MaxAttempts = 1
        }
        
        for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
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