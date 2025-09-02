function Search-GitHubIssuesMultiRepo {
    <#
    .SYNOPSIS
    Searches for issues across multiple GitHub repositories
    
    .DESCRIPTION
    Performs cross-repository search for GitHub issues with support for
    multiple repositories and unified result aggregation
    
    .PARAMETER Repositories
    Array of repository objects or "owner/repo" strings
    
    .PARAMETER Query
    Search query string
    
    .PARAMETER State
    Issue state filter (open, closed, all)
    
    .PARAMETER Labels
    Labels to filter by
    
    .PARAMETER Sort
    Sort field (created, updated, comments)
    
    .PARAMETER Order
    Sort order (asc, desc)
    
    .PARAMETER MaxPerRepo
    Maximum results per repository
    
    .PARAMETER IncludePullRequests
    Include pull requests in results
    
    .EXAMPLE
    Search-GitHubIssuesMultiRepo -Repositories @("org/repo1", "org/repo2") -Query "CS0246" -State "all"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Repositories,
        
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [ValidateSet("open", "closed", "all")]
        [string]$State = "all",
        
        [string[]]$Labels,
        
        [ValidateSet("created", "updated", "comments")]
        [string]$Sort = "updated",
        
        [ValidateSet("asc", "desc")]
        [string]$Order = "desc",
        
        [int]$MaxPerRepo = 30,
        
        [switch]$IncludePullRequests
    )
    
    try {
        # Get PAT for authentication
        $pat = Get-GitHubPATInternal
        if (-not $pat) {
            throw "GitHub PAT not configured. Use Set-GitHubPAT to configure."
        }
        
        # Build headers
        $headers = @{
            "Authorization" = "Bearer $pat"
            "Accept" = "application/vnd.github+json"
            "X-GitHub-Api-Version" = "2022-11-28"
        }
        
        $allResults = @()
        $searchStats = @{
            TotalRepositories = 0
            SuccessfulSearches = 0
            FailedSearches = 0
            TotalIssuesFound = 0
            Errors = @()
        }
        
        # Process each repository
        foreach ($repo in $Repositories) {
            $searchStats.TotalRepositories++
            
            # Parse repository info
            if ($repo -is [string]) {
                $parts = $repo -split '/'
                $owner = $parts[0]
                $repoName = $parts[1]
                $repoFullName = $repo
            } elseif ($repo.Owner -and $repo.Name) {
                $owner = $repo.Owner
                $repoName = $repo.Name
                $repoFullName = "$owner/$repoName"
            } elseif ($repo.FullName) {
                $parts = $repo.FullName -split '/'
                $owner = $parts[0]
                $repoName = $parts[1]
                $repoFullName = $repo.FullName
            } else {
                Write-Warning "Invalid repository format: $repo"
                $searchStats.FailedSearches++
                continue
            }
            
            Write-Verbose "Searching repository: $repoFullName"
            
            try {
                # Build search query for this repository
                $searchQuery = "$Query repo:$repoFullName"
                
                # Add type filter if not including pull requests
                if (-not $IncludePullRequests) {
                    $searchQuery += " type:issue"
                }
                
                # Add state filter
                if ($State -ne "all") {
                    $searchQuery += " state:$State"
                }
                
                # Add label filters
                foreach ($label in $Labels) {
                    $searchQuery += " label:`"$label`""
                }
                
                # URL encode the query
                $encodedQuery = [System.Web.HttpUtility]::UrlEncode($searchQuery)
                
                # Build search URI
                $searchUri = "https://api.github.com/search/issues?q=$encodedQuery&sort=$Sort&order=$Order&per_page=$MaxPerRepo"
                
                Write-Verbose "Search URI: $searchUri"
                
                # Perform search
                $searchResults = Invoke-GitHubAPIWithRetry -Uri $searchUri -Headers $headers -Method Get
                
                if ($searchResults.items) {
                    foreach ($item in $searchResults.items) {
                        # Add repository information to each result
                        $item | Add-Member -NotePropertyName "repository_full_name" -NotePropertyValue $repoFullName -Force
                        $item | Add-Member -NotePropertyName "repository_owner" -NotePropertyValue $owner -Force
                        $item | Add-Member -NotePropertyName "repository_name" -NotePropertyValue $repoName -Force
                        
                        # Add search relevance score if available
                        if ($item.score) {
                            $item | Add-Member -NotePropertyName "search_score" -NotePropertyValue $item.score -Force
                        }
                        
                        $allResults += $item
                    }
                    
                    $searchStats.SuccessfulSearches++
                    $searchStats.TotalIssuesFound += $searchResults.items.Count
                    
                    Write-Verbose "Found $($searchResults.items.Count) issues in $repoFullName"
                } else {
                    Write-Verbose "No issues found in $repoFullName"
                    $searchStats.SuccessfulSearches++
                }
                
            } catch {
                Write-Warning "Failed to search repository $repoFullName`: $_"
                $searchStats.FailedSearches++
                $searchStats.Errors += [PSCustomObject]@{
                    Repository = $repoFullName
                    Error = $_.ToString()
                }
            }
        }
        
        # Sort all results by relevance and date
        $sortedResults = $allResults | Sort-Object -Property @{
            Expression = { $_.search_score }; Descending = $true
        }, @{
            Expression = { [DateTime]::Parse($_.updated_at) }; Descending = $true
        }
        
        # Build final result object
        $finalResult = [PSCustomObject]@{
            Query = $Query
            TotalCount = $allResults.Count
            Issues = $sortedResults
            Statistics = $searchStats
            SearchTime = [DateTime]::UtcNow
        }
        
        # Check for cross-repository duplicates
        if ($allResults.Count -gt 0) {
            Write-Verbose "Checking for cross-repository duplicates"
            
            $duplicateGroups = @{}
            foreach ($issue in $sortedResults) {
                # Create signature for duplicate detection
                $titleWords = ($issue.title -split '\s+' | Where-Object { $_.Length -gt 3 }) -join ' '
                $signature = "$titleWords"
                
                if (-not $duplicateGroups.ContainsKey($signature)) {
                    $duplicateGroups[$signature] = @()
                }
                $duplicateGroups[$signature] += $issue
            }
            
            # Mark potential duplicates
            foreach ($group in $duplicateGroups.Values) {
                if ($group.Count -gt 1) {
                    foreach ($issue in $group) {
                        $issue | Add-Member -NotePropertyName "has_cross_repo_duplicates" -NotePropertyValue $true -Force
                        $issue | Add-Member -NotePropertyName "duplicate_count" -NotePropertyValue $group.Count -Force
                    }
                }
            }
        }
        
        Write-Host "Multi-repository search complete: Found $($finalResult.TotalCount) issues across $($searchStats.SuccessfulSearches) repositories" -ForegroundColor Cyan
        
        return $finalResult
        
    } catch {
        Write-Error "Failed to search across repositories: $_"
        throw
    }
}

# Export the function
Export-ModuleMember -Function Search-GitHubIssuesMultiRepo
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB7c/HvfwFTZHi7
# iefnkaKdCWuAbeptSPigSw+LJCJbHKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIrKs0dUQwzmvlc7yr1GqOsB
# nHfBiAaWljADNHREUC2PMA0GCSqGSIb3DQEBAQUABIIBAJDAdlaaH+ryNdYeAIUd
# 5Il4XB3YRrV0c7AtLcOGcGsvyXT3RNZpWMIzEazSMA/RgQrzzVLIC8A67Kl+UppY
# jc+nT7ftYrVHqo/ER523+JNz0BYhntBZokS0NLD2DGjfLP35YeIWLzWDw7mnUkTm
# +nipusdcD2JwpLDMIwCMkQbLmFfw7T55gC1O7prIQcvQghJSuP++tpLiF/bF9ifo
# ICgb2MbdeF3MHNRdtUVB8/HrnUfwU6Roo7E4UMEi8mZ1/CGQrn9zrroOUTXQKIkr
# HKaCMRorpVcdPY0Dfm+BMydlzd6lhVL5DI5paCGSgZUt18aD6DKAzxBet73WheL6
# sHc=
# SIG # End signature block
