function Update-GitHubIssue {
    <#
    .SYNOPSIS
    Updates an existing GitHub issue
    
    .DESCRIPTION
    Updates properties of an existing GitHub issue including title, body, state, labels, and assignees.
    Uses the GitHub API v3 PATCH endpoint for issues.
    
    .PARAMETER Owner
    The owner of the repository
    
    .PARAMETER Repository
    The name of the repository
    
    .PARAMETER IssueNumber
    The issue number to update
    
    .PARAMETER Title
    New title for the issue (optional)
    
    .PARAMETER Body
    New body content for the issue (optional)
    
    .PARAMETER State
    New state for the issue: open or closed (optional)
    
    .PARAMETER Labels
    New array of label names (replaces existing labels)
    
    .PARAMETER Assignees
    New array of assignee usernames (replaces existing assignees)
    
    .PARAMETER Milestone
    New milestone number (optional)
    
    .EXAMPLE
    Update-GitHubIssue -Owner "myorg" -Repository "myrepo" -IssueNumber 42 -State "closed"
    
    .EXAMPLE
    Update-GitHubIssue -Owner "myorg" -Repository "myrepo" -IssueNumber 42 -Labels @("bug", "fixed")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Owner,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [Parameter(Mandatory = $true)]
        [int]$IssueNumber,
        
        [Parameter()]
        [string]$Title,
        
        [Parameter()]
        [string]$Body,
        
        [Parameter()]
        [ValidateSet('open', 'closed')]
        [string]$State,
        
        [Parameter()]
        [string[]]$Labels,
        
        [Parameter()]
        [string[]]$Assignees,
        
        [Parameter()]
        [int]$Milestone
    )
    
    begin {
        Write-Verbose "Starting Update-GitHubIssue for $Owner/$Repository issue #$IssueNumber"
        
        # Log to unity_claude_automation.log
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logFile = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "unity_claude_automation.log"
        $logEntry = "[$timestamp] [INFO] Update-GitHubIssue: Updating issue #$IssueNumber in $Owner/$Repository"
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
            $uri = "https://api.github.com/repos/$Owner/$Repository/issues/$IssueNumber"
            Write-Verbose "API Endpoint: $uri"
            
            # Build the request body with only specified parameters
            $requestBody = @{}
            
            if ($PSBoundParameters.ContainsKey('Title')) {
                $requestBody.title = $Title
                Write-Verbose "Updating title"
            }
            
            if ($PSBoundParameters.ContainsKey('Body')) {
                $requestBody.body = $Body
                Write-Verbose "Updating body"
            }
            
            if ($PSBoundParameters.ContainsKey('State')) {
                $requestBody.state = $State.ToLower()
                Write-Verbose "Updating state to: $State"
            }
            
            if ($PSBoundParameters.ContainsKey('Labels')) {
                $requestBody.labels = $Labels
                Write-Verbose "Updating labels: $($Labels -join ', ')"
            }
            
            if ($PSBoundParameters.ContainsKey('Assignees')) {
                $requestBody.assignees = $Assignees
                Write-Verbose "Updating assignees: $($Assignees -join ', ')"
            }
            
            if ($PSBoundParameters.ContainsKey('Milestone')) {
                $requestBody.milestone = $Milestone
                Write-Verbose "Updating milestone: $Milestone"
            }
            
            # Check if there's anything to update
            if ($requestBody.Count -eq 0) {
                Write-Warning "No update parameters specified. Nothing to update."
                return
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
            $response = Invoke-GitHubAPIWithRetry -Uri $uri -Method 'PATCH' -Headers $headers -Body $json
            
            # Log success
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $updateSummary = $requestBody.Keys -join ', '
            $logEntry = "[$timestamp] [SUCCESS] Update-GitHubIssue: Updated issue #$IssueNumber - Changed: $updateSummary"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Verbose "Successfully updated issue #$IssueNumber"
            return $response
        }
        catch {
            # Log error
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [ERROR] Update-GitHubIssue: Failed to update issue #$IssueNumber - $($_.Exception.Message)"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Error "Failed to update GitHub issue: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Completed Update-GitHubIssue"
    }
}