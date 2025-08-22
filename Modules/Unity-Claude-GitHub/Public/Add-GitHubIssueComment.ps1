function Add-GitHubIssueComment {
    <#
    .SYNOPSIS
    Adds a comment to a GitHub issue
    
    .DESCRIPTION
    Adds a new comment to an existing GitHub issue or pull request.
    Useful for adding additional context, error occurrences, or status updates.
    
    .PARAMETER Owner
    The owner of the repository
    
    .PARAMETER Repository
    The name of the repository
    
    .PARAMETER IssueNumber
    The issue number to comment on
    
    .PARAMETER Comment
    The comment text (supports markdown)
    
    .PARAMETER IncludeTimestamp
    Include a timestamp in the comment (default: true)
    
    .EXAMPLE
    Add-GitHubIssueComment -Owner "myorg" -Repository "myrepo" -IssueNumber 42 -Comment "This error occurred again"
    
    .EXAMPLE
    $error = Get-UnityErrors | Select-Object -First 1
    Add-GitHubIssueComment -Owner "myorg" -Repository "myrepo" -IssueNumber 42 -Comment "Error recurrence: $($error.ErrorText)"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Owner,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [Parameter(Mandatory = $true)]
        [int]$IssueNumber,
        
        [Parameter(Mandatory = $true)]
        [string]$Comment,
        
        [Parameter()]
        [bool]$IncludeTimestamp = $true
    )
    
    begin {
        Write-Verbose "Starting Add-GitHubIssueComment for $Owner/$Repository issue #$IssueNumber"
        
        # Log to unity_claude_automation.log
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logFile = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "unity_claude_automation.log"
        $logEntry = "[$timestamp] [INFO] Add-GitHubIssueComment: Adding comment to issue #$IssueNumber in $Owner/$Repository"
        Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
        
        # Ensure TLS 1.2
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    }
    
    process {
        try {
            # Test authentication
            Write-Verbose "Testing GitHub authentication"
            if (-not (Test-GitHubPAT)) {
                throw "GitHub authentication not configured. Use Set-GitHubPAT to configure."
            }
            
            # Get the PAT
            $pat = Get-GitHubPAT
            if (-not $pat) {
                throw "Failed to retrieve GitHub Personal Access Token"
            }
            
            # Construct the API endpoint
            $uri = "https://api.github.com/repos/$Owner/$Repository/issues/$IssueNumber/comments"
            Write-Verbose "API Endpoint: $uri"
            
            # Build the comment body
            $commentBody = ""
            
            # Add timestamp if requested
            if ($IncludeTimestamp) {
                $timestampStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
                $commentBody = "**[Automated Update - $timestampStr]**`n`n"
            }
            
            # Add the main comment
            $commentBody += $Comment
            
            # Add metadata footer
            $commentBody += "`n`n---`n_Posted by Unity-Claude-GitHub Automation_"
            
            # Build the request body
            $requestBody = @{
                body = $commentBody
            }
            
            # Convert to JSON
            $json = $requestBody | ConvertTo-Json -Depth 10
            Write-Debug "Request Body: $json"
            
            # Prepare headers
            $authToken = [System.Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
            $headers = @{
                "Authorization" = "Basic $authToken"
                "Content-Type" = "application/json"
                "Accept" = "application/vnd.github+json"
                "X-GitHub-Api-Version" = "2022-11-28"
            }
            
            # Use the module's retry logic
            Write-Verbose "Calling GitHub API with retry logic"
            $response = Invoke-GitHubAPIWithRetry -Uri $uri -Method 'POST' -Headers $headers -Body $json
            
            # Log success
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [SUCCESS] Add-GitHubIssueComment: Added comment to issue #$IssueNumber (Comment ID: $($response.id))"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Verbose "Successfully added comment to issue #$IssueNumber"
            return $response
        }
        catch {
            # Log error
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [ERROR] Add-GitHubIssueComment: Failed to add comment - $($_.Exception.Message)"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Error "Failed to add GitHub issue comment: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Completed Add-GitHubIssueComment"
    }
}