function Test-GitHubIssueDuplicate {
    <#
    .SYNOPSIS
    Tests if a Unity error already has an open GitHub issue
    
    .DESCRIPTION
    Searches for existing GitHub issues that match the Unity error signature.
    Returns the existing issue if found, or $null if no duplicate exists.
    
    .PARAMETER UnityError
    The Unity error object to check for duplicates
    
    .PARAMETER Owner
    The owner of the repository
    
    .PARAMETER Repository
    The name of the repository
    
    .PARAMETER IncludeClosedIssues
    Also check closed issues for duplicates (default: false)
    
    .PARAMETER SimilarityThreshold
    Minimum similarity score (0-1) to consider a match (default: 0.8)
    
    .EXAMPLE
    $error = Get-UnityErrors | Select-Object -First 1
    $duplicate = Test-GitHubIssueDuplicate -UnityError $error -Owner "myorg" -Repository "myrepo"
    if ($duplicate) {
        Write-Host "Duplicate found: Issue #$($duplicate.number)"
    }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$UnityError,
        
        [Parameter(Mandatory = $true)]
        [string]$Owner,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [Parameter()]
        [bool]$IncludeClosedIssues = $false,
        
        [Parameter()]
        [ValidateRange(0, 1)]
        [double]$SimilarityThreshold = 0.8
    )
    
    begin {
        Write-Verbose "Starting Test-GitHubIssueDuplicate for $Owner/$Repository"
        
        # Log to unity_claude_automation.log
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logFile = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "unity_claude_automation.log"
        $logEntry = "[$timestamp] [INFO] Test-GitHubIssueDuplicate: Checking for duplicate issues"
        Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
    }
    
    process {
        try {
            # Generate signature for the error
            $errorSignature = Get-UnityErrorSignature -UnityError $UnityError
            Write-Verbose "Error signature: $errorSignature"
            
            # Extract error details for searching
            $errorCode = ""
            $errorMessage = ""
            
            if ($UnityError.ErrorText -match 'error\s+(\w+):\s*(.+)$') {
                $errorCode = $Matches[1]
                $errorMessage = $Matches[2]
            }
            elseif ($UnityError.Code) {
                $errorCode = $UnityError.Code
                $errorMessage = $UnityError.Message
            }
            
            # Build search queries
            $searchQueries = @()
            
            # 1. Search by exact signature in comments (most reliable)
            $searchQueries += "Error-Hash: $errorSignature in:comments repo:$Owner/$Repository"
            
            # 2. Search by error code if available
            if ($errorCode) {
                $searchQueries += "$errorCode in:title repo:$Owner/$Repository"
            }
            
            # 3. Search by key error terms
            if ($errorMessage) {
                # Extract key terms from error message
                $keyTerms = $errorMessage -split '\s+' | 
                    Where-Object { $_.Length -gt 3 -and $_ -notmatch '^\d+$' } |
                    Select-Object -First 3
                
                if ($keyTerms) {
                    $searchQuery = ($keyTerms -join ' ') + " in:title,body repo:$Owner/$Repository"
                    $searchQueries += $searchQuery
                }
            }
            
            # Determine state filter
            $state = if ($IncludeClosedIssues) { 'all' } else { 'open' }
            
            # Search for potential duplicates
            $potentialDuplicates = @()
            
            foreach ($query in $searchQueries) {
                Write-Verbose "Searching with query: $query"
                
                try {
                    $results = Search-GitHubIssues -Query $query -State $state -MaxResults 10
                    
                    if ($results) {
                        Write-Verbose "Found $($results.Count) potential matches"
                        $potentialDuplicates += $results
                    }
                }
                catch {
                    Write-Warning "Search query failed: $_"
                }
                
                # Stop if we found exact signature match
                if ($potentialDuplicates | Where-Object { $_.body -match "Error-Hash:\s*$errorSignature" }) {
                    Write-Verbose "Found exact signature match"
                    break
                }
            }
            
            # Remove duplicates from results (same issue found by multiple queries)
            $uniqueIssues = $potentialDuplicates | Sort-Object -Property number -Unique
            
            Write-Verbose "Total unique potential duplicates: $($uniqueIssues.Count)"
            
            # Check each potential duplicate for similarity
            foreach ($issue in $uniqueIssues) {
                # Check for exact signature match in body/comments (highest confidence)
                if ($issue.body -match "Error-Hash:\s*$errorSignature") {
                    Write-Verbose "Exact signature match found in issue #$($issue.number)"
                    
                    # Log finding
                    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $logEntry = "[$timestamp] [SUCCESS] Test-GitHubIssueDuplicate: Found exact duplicate - Issue #$($issue.number)"
                    Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
                    
                    return $issue
                }
                
                # Calculate similarity score
                $similarityScore = 0.0
                $scoreComponents = 0
                
                # Check error code match
                if ($errorCode -and $issue.title -match $errorCode) {
                    $similarityScore += 0.4
                    $scoreComponents++
                    Write-Debug "Error code match: +0.4"
                }
                
                # Check title similarity
                if ($errorMessage) {
                    $titleWords = $issue.title -split '\s+' | Where-Object { $_.Length -gt 2 }
                    $messageWords = $errorMessage -split '\s+' | Where-Object { $_.Length -gt 2 }
                    
                    if ($titleWords.Count -gt 0 -and $messageWords.Count -gt 0) {
                        $matchingWords = $titleWords | Where-Object { $messageWords -contains $_ }
                        $titleSimilarity = $matchingWords.Count / [Math]::Min($titleWords.Count, $messageWords.Count)
                        $similarityScore += $titleSimilarity * 0.3
                        $scoreComponents++
                        Write-Debug "Title similarity: +$($titleSimilarity * 0.3)"
                    }
                }
                
                # Check for Unity and automation labels
                if ($issue.labels) {
                    $hasUnityLabel = $issue.labels | Where-Object { $_.name -eq 'unity' }
                    $hasAutomatedLabel = $issue.labels | Where-Object { $_.name -eq 'automated' }
                    
                    if ($hasUnityLabel) {
                        $similarityScore += 0.15
                        $scoreComponents++
                        Write-Debug "Unity label match: +0.15"
                    }
                    
                    if ($hasAutomatedLabel) {
                        $similarityScore += 0.15
                        $scoreComponents++
                        Write-Debug "Automated label match: +0.15"
                    }
                }
                
                # Normalize score
                if ($scoreComponents -gt 0) {
                    $normalizedScore = $similarityScore / $scoreComponents
                    Write-Verbose "Issue #$($issue.number) similarity score: $normalizedScore"
                    
                    if ($normalizedScore -ge $SimilarityThreshold) {
                        Write-Verbose "Duplicate found with similarity score $normalizedScore"
                        
                        # Log finding
                        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                        $logEntry = "[$timestamp] [SUCCESS] Test-GitHubIssueDuplicate: Found similar issue - Issue #$($issue.number) (score: $normalizedScore)"
                        Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
                        
                        return $issue
                    }
                }
            }
            
            # No duplicate found
            Write-Verbose "No duplicate issues found"
            
            # Log result
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [INFO] Test-GitHubIssueDuplicate: No duplicates found"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            return $null
        }
        catch {
            # Log error
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [ERROR] Test-GitHubIssueDuplicate: Failed to check - $($_.Exception.Message)"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Error "Failed to test for GitHub issue duplicate: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Completed Test-GitHubIssueDuplicate"
    }
}