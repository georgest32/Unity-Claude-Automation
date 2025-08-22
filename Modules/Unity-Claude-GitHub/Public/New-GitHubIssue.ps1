function New-GitHubIssue {
    <#
    .SYNOPSIS
    Creates a new issue in a GitHub repository
    
    .DESCRIPTION
    Creates a new issue in the specified GitHub repository using the GitHub API v3.
    Integrates with the Unity-Claude-GitHub module's authentication and retry logic.
    
    .PARAMETER Owner
    The owner of the repository (user or organization)
    
    .PARAMETER Repository
    The name of the repository
    
    .PARAMETER Title
    The title of the issue
    
    .PARAMETER Body
    The body content of the issue (supports markdown)
    
    .PARAMETER Labels
    Array of label names to apply to the issue
    
    .PARAMETER Assignees
    Array of usernames to assign to the issue
    
    .PARAMETER Milestone
    The milestone number to associate with the issue
    
    .EXAMPLE
    New-GitHubIssue -Owner "myorg" -Repository "myrepo" -Title "Unity Compilation Error" -Body "Error details..." -Labels @("bug", "unity")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Owner,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$Body,
        
        [Parameter()]
        [string[]]$Labels = @(),
        
        [Parameter()]
        [string[]]$Assignees = @(),
        
        [Parameter()]
        [int]$Milestone
    )
    
    begin {
        Write-Verbose "Starting New-GitHubIssue for $Owner/$Repository"
        
        # Log to unity_claude_automation.log
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logFile = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "unity_claude_automation.log"
        $logEntry = "[$timestamp] [INFO] New-GitHubIssue: Creating issue in $Owner/$Repository - Title: $Title"
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
            $uri = "https://api.github.com/repos/$Owner/$Repository/issues"
            Write-Verbose "API Endpoint: $uri"
            
            # Build the request body
            $requestBody = @{
                title = $Title
                body = $Body
            }
            
            if ($Labels.Count -gt 0) {
                $requestBody.labels = $Labels
                Write-Verbose "Adding labels: $($Labels -join ', ')"
            }
            
            if ($Assignees.Count -gt 0) {
                $requestBody.assignees = $Assignees
                Write-Verbose "Adding assignees: $($Assignees -join ', ')"
            }
            
            if ($PSBoundParameters.ContainsKey('Milestone')) {
                $requestBody.milestone = $Milestone
                Write-Verbose "Adding milestone: $Milestone"
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
            $logEntry = "[$timestamp] [SUCCESS] New-GitHubIssue: Created issue #$($response.number) in $Owner/$Repository"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Verbose "Successfully created issue #$($response.number)"
            return $response
        }
        catch {
            # Log error
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [ERROR] New-GitHubIssue: Failed to create issue - $($_.Exception.Message)"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Error "Failed to create GitHub issue: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Completed New-GitHubIssue"
    }
}