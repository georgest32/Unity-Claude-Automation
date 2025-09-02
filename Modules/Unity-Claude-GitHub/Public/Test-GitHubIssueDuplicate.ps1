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
                Write-Debug "TEST-DUPLICATE: About to call Search-GitHubIssues with query: $query"
                
                try {
                    Write-Debug "TEST-DUPLICATE: Calling Search-GitHubIssues..."
                    $results = Search-GitHubIssues -Query $query -State $state -MaxResults 10
                    Write-Debug "TEST-DUPLICATE: Search-GitHubIssues returned successfully"
                    
                    if ($results) {
                        Write-Verbose "Found $($results.Count) potential matches"
                        Write-Debug "TEST-DUPLICATE: Adding $($results.Count) results to potentialDuplicates"
                        $potentialDuplicates += $results
                    } else {
                        Write-Debug "TEST-DUPLICATE: Search returned no results"
                    }
                }
                catch {
                    Write-Debug "TEST-DUPLICATE: Caught exception from Search-GitHubIssues"
                    Write-Debug "  Exception Type: $($_.GetType().FullName)"
                    Write-Debug "  Exception Message: $($_.Exception.Message)"
                    Write-Debug "  Full Error Object: $_"
                    
                    # Handle specific error types more gracefully
                    if ($_.Exception.Message -match "422|Validation Failed|cannot be searched") {
                        Write-Debug "TEST-DUPLICATE: Handling as expected 422/validation error"
                        Write-Verbose "Repository not found or not accessible - this is expected for test repositories"
                    } elseif ($_.Exception.Message -match "403|forbidden") {
                        Write-Debug "TEST-DUPLICATE: Handling as expected 403/forbidden error"
                        Write-Verbose "Access forbidden - insufficient permissions for repository search"
                    } else {
                        Write-Debug "TEST-DUPLICATE: Handling as unexpected error - will show warning"
                        Write-Warning "Search query failed: $_"
                    }
                    
                    Write-Debug "TEST-DUPLICATE: Error handling complete, continuing with next query"
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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDsbi86rbbR/VL0
# G5kz5xyL71GUchmMk9isFSsAP4capKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIggV6rGv+Nz5s1PTvX7KwK3
# kzO9ZRvVmz3IKGwn6aXIMA0GCSqGSIb3DQEBAQUABIIBADqH29u8mpWUuPvvIFXT
# k25dj4tJKWuW5ZEsYRPin/0PbcH5Qzddk3CCdPCFcSy8d1TnNBs6nfm/RkjaitHD
# Soa8lT91YB7AIwwe/wpVcRN1U2JGA3cft+06dTPEofLGu/UKWvUzuo1l0VkSQ/6s
# VX94fsAJOzJBVcGPNpPcrZqBeJT7c2iwus3rk1mQNdT3GuIJsK7vx3UdiH0Ro8T3
# Y5yMzwnGAmv4yjQs5LBFFsuV8knS7YQmRA25YRIr7iQRJzMAEAwtZre2l8/Y3uRZ
# iVxnN8p+yXrd1f9G3Q8TDqnu6gWjXo5MutIL7Uo6bfcuj8hge9lPkqxI0Th83UJY
# FPY=
# SIG # End signature block
