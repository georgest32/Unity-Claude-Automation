function Search-GitHubIssues {
    <#
    .SYNOPSIS
    Searches for issues in GitHub repositories
    
    .DESCRIPTION
    Searches for issues using the GitHub Search API v3 with support for advanced query syntax.
    Supports filtering by repository, state, labels, author, and custom query strings.
    
    .PARAMETER Query
    The search query string (supports GitHub search syntax)
    
    .PARAMETER Owner
    The owner of the repository (optional, for repo-specific searches)
    
    .PARAMETER Repository
    The name of the repository (optional, for repo-specific searches)
    
    .PARAMETER State
    Filter by issue state: open, closed, or all (default: open)
    
    .PARAMETER Labels
    Array of label names to filter by
    
    .PARAMETER Sort
    Sort results by: created, updated, comments (default: created)
    
    .PARAMETER Order
    Sort order: asc or desc (default: desc)
    
    .PARAMETER PerPage
    Number of results per page (max 100, default 30)
    
    .PARAMETER MaxResults
    Maximum number of results to return (default 100)
    
    .EXAMPLE
    Search-GitHubIssues -Query "Unity compilation error" -Owner "myorg" -Repository "myrepo" -State "open"
    
    .EXAMPLE
    Search-GitHubIssues -Query "error CS0" -Labels @("bug", "unity") -MaxResults 50
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [Parameter()]
        [string]$Owner,
        
        [Parameter()]
        [string]$Repository,
        
        [Parameter()]
        [ValidateSet('open', 'closed', 'all')]
        [string]$State = 'open',
        
        [Parameter()]
        [string[]]$Labels = @(),
        
        [Parameter()]
        [ValidateSet('created', 'updated', 'comments')]
        [string]$Sort = 'created',
        
        [Parameter()]
        [ValidateSet('asc', 'desc')]
        [string]$Order = 'desc',
        
        [Parameter()]
        [ValidateRange(1, 100)]
        [int]$PerPage = 30,
        
        [Parameter()]
        [int]$MaxResults = 100
    )
    
    begin {
        Write-Verbose "Starting Search-GitHubIssues with query: $Query"
        
        # Log to unity_claude_automation.log
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logFile = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "unity_claude_automation.log"
        $logEntry = "[$timestamp] [INFO] Search-GitHubIssues: Searching with query: $Query"
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
            
            # Build the search query
            $searchQuery = $Query
            
            # Add repository filter if specified
            if ($Owner -and $Repository) {
                $searchQuery += " repo:$Owner/$Repository"
                Write-Verbose "Added repository filter: $Owner/$Repository"
            }
            
            # Add state filter (unless 'all' is specified)
            if ($State -ne 'all') {
                $searchQuery += " is:$State"
                Write-Verbose "Added state filter: $State"
            }
            
            # Always search for issues (not pull requests)
            $searchQuery += " is:issue"
            
            # Add label filters
            foreach ($label in $Labels) {
                $searchQuery += " label:`"$label`""
                Write-Verbose "Added label filter: $label"
            }
            
            Write-Verbose "Final search query: $searchQuery"
            
            # Construct the API endpoint with parameters
            $uri = "https://api.github.com/search/issues"
            $queryParams = @{
                q = $searchQuery
                sort = $Sort
                order = $Order
                per_page = $PerPage
            }
            
            # Build query string
            $queryString = ($queryParams.GetEnumerator() | ForEach-Object { 
                "$($_.Key)=$([System.Web.HttpUtility]::UrlEncode($_.Value))" 
            }) -join '&'
            
            $fullUri = "$uri`?$queryString"
            Write-Debug "Full URI: $fullUri"
            
            # Prepare headers
            $authToken = [System.Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(":$pat"))
            $headers = @{
                "Authorization" = "Basic $authToken"
                "Accept" = "application/vnd.github+json"
                "X-GitHub-Api-Version" = "2022-11-28"
            }
            
            # Collect all results (handle pagination)
            $allResults = @()
            $currentPage = 1
            $totalFetched = 0
            
            while ($totalFetched -lt $MaxResults) {
                Write-Verbose "Fetching page $currentPage (fetched $totalFetched of max $MaxResults)"
                
                # Update page number in URI
                $pageUri = "$fullUri&page=$currentPage"
                
                # Use the module's retry logic
                $response = Invoke-GitHubAPIWithRetry -Uri $pageUri -Method 'GET' -Headers $headers
                
                if (-not $response.items -or $response.items.Count -eq 0) {
                    Write-Verbose "No more results found"
                    break
                }
                
                # Add results up to MaxResults limit
                $remainingCapacity = $MaxResults - $totalFetched
                $itemsToAdd = [Math]::Min($response.items.Count, $remainingCapacity)
                
                for ($i = 0; $i -lt $itemsToAdd; $i++) {
                    $allResults += $response.items[$i]
                }
                
                $totalFetched = $allResults.Count
                Write-Verbose "Total issues fetched: $totalFetched"
                
                # Check if we've reached the end of results
                if ($response.items.Count -lt $PerPage) {
                    Write-Verbose "Reached end of search results"
                    break
                }
                
                $currentPage++
                
                # Note: GitHub Search API has known pagination issues over 100 results
                if ($totalFetched -ge 100) {
                    Write-Warning "GitHub Search API may return duplicates when paginating beyond 100 results"
                }
            }
            
            # Log success
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [SUCCESS] Search-GitHubIssues: Found $($allResults.Count) issues"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Verbose "Search completed. Found $($allResults.Count) issues"
            return $allResults
        }
        catch {
            # Log error
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [ERROR] Search-GitHubIssues: Failed to search - $($_.Exception.Message)"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Error "Failed to search GitHub issues: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Completed Search-GitHubIssues"
    }
}