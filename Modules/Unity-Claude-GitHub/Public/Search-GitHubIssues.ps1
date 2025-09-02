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
            
            # Get the PAT internally (no warnings)
            $pat = Get-GitHubPATInternal
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
            # Categorize errors appropriately
            $statusCode = $null
            $errorMessage = $_.Exception.Message
            
            # Debug logging for error analysis
            Write-Debug "Search-GitHubIssues Error Debug:"
            Write-Debug "  Exception Type: $($_.Exception.GetType().FullName)"
            Write-Debug "  Exception Message: $errorMessage"
            Write-Debug "  Has Response: $(if ($_.Exception.Response) { 'Yes' } else { 'No' })"
            
            # Try multiple ways to get status code
            if ($_.Exception.Response) {
                $statusCode = [int]$_.Exception.Response.StatusCode
                Write-Debug "  Status Code: $statusCode"
            } elseif ($errorMessage -match '\b(\d{3})\b') {
                # Try to extract status code from error message
                $statusCode = [int]$Matches[1]
                Write-Debug "  Status Code (extracted): $statusCode"
            }
            
            # Log error with appropriate severity
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            
            # Add comprehensive debug logging
            Write-Debug "SEARCH ERROR ANALYSIS START"
            Write-Debug "  Full Error: $_"
            Write-Debug "  Error Type: $($_.GetType().FullName)"
            Write-Debug "  StatusCode Variable: $statusCode"
            Write-Debug "  ErrorMessage Variable: $errorMessage" 
            Write-Debug "  Testing Conditions:"
            Write-Debug "    statusCode -eq 422: $(if ($statusCode -eq 422) { 'TRUE' } else { 'FALSE' })"
            Write-Debug "    statusCode -eq 403: $(if ($statusCode -eq 403) { 'TRUE' } else { 'FALSE' })"
            Write-Debug "    errorMessage matches 422|403: $(if ($errorMessage -match '422|403') { 'TRUE' } else { 'FALSE' })"
            
            # Handle expected vs unexpected errors differently
            if ($statusCode -eq 422 -or $statusCode -eq 403 -or $errorMessage -match '422|403') {
                Write-Debug "TAKING EXPECTED ERROR PATH (422/403)"
                
                # Expected errors (repository not found, access denied) - log as info, display as verbose
                $logEntry = "[$timestamp] [INFO] Search-GitHubIssues: Search validation failed (expected for test repositories) - Status: $statusCode"
                Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
                
                Write-Verbose "GitHub search validation failed (Status: $statusCode) - This is expected for non-existent test repositories"
                Write-Debug "EXPECTED ERROR - Using Write-Verbose output"
                
                # Still throw the exception for proper error propagation, but don't display as error
                Write-Debug "EXPECTED ERROR - About to throw exception for propagation"
                throw $_
            }
            else {
                Write-Debug "TAKING UNEXPECTED ERROR PATH (NOT 422/403)"
                
                # Unexpected errors - log as error and display
                $logEntry = "[$timestamp] [ERROR] Search-GitHubIssues: Unexpected search failure - $($_.Exception.Message)"
                Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
                
                Write-Debug "UNEXPECTED ERROR - Using Write-Error output"
                Write-Error "Failed to search GitHub issues: $_"
                throw
            }
            
            Write-Debug "SEARCH ERROR ANALYSIS END"
        }
    }
    
    end {
        Write-Verbose "Completed Search-GitHubIssues"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD8zKHcfQzyVAiD
# 5sOYCsdnzGB5uHW86cBwODg4b59iTKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEII7nx66nBtK3QHtemSa0HKRv
# R89WGFU7oEsj2/r+Rtq4MA0GCSqGSIb3DQEBAQUABIIBAGr499cGdpTqAFRHbmQr
# 0OOYh8rPUoszRJEZoZd+PBX3Tzfp+hHkribaW4XoPb+EPr29m0HvSXLnAzpXvEgk
# Yi5so8W3WEaKvoI+j8z7xYEaVoquzXQzM2MSeNkGAQEuqU1X4GIL9pAqu35g84mD
# ayScJa6YPJFpOtEqczfhWiLVQbKWi9vqQI1uF/AAMQGbNblFJ1bPai7T4Vl8Gy+d
# LBxT/eFGarnhh0jH5m2yorl+rwrGVyTqpkSxTU7McParHQx9t/Vs3e7A96aw94sQ
# RJD4IUgm+FK+Oe5P8/qryatDTYV00uVTgFzY6thDSQxvsXK8A8wkYytOMw1X4kzj
# ObE=
# SIG # End signature block
