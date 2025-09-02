function New-GitHubPullRequest {
    <#
    .SYNOPSIS
    Creates a new GitHub pull request
    
    .DESCRIPTION
    Creates a pull request on GitHub using the GitHub API with proper authentication and error handling
    
    .PARAMETER Owner
    Repository owner (username or organization)
    
    .PARAMETER Repository
    Repository name
    
    .PARAMETER Title
    Pull request title
    
    .PARAMETER Body
    Pull request body/description
    
    .PARAMETER Head
    The name of the branch where your changes are implemented
    
    .PARAMETER Base
    The name of the branch you want the changes pulled into (default: main)
    
    .PARAMETER Draft
    Create as draft pull request
    
    .PARAMETER Labels
    Array of label names to add to the pull request
    
    .PARAMETER Reviewers
    Array of usernames to request reviews from
    
    .PARAMETER TeamReviewers
    Array of team names to request reviews from
    
    .EXAMPLE
    New-GitHubPullRequest -Owner "myorg" -Repository "myrepo" -Title "Update documentation" -Body "Updates API docs" -Head "docs/update-api" -Base "main"
    
    .EXAMPLE
    New-GitHubPullRequest -Owner "myorg" -Repository "myrepo" -Title "Feature update" -Head "feature/new-api" -Draft -Labels @("documentation", "enhancement")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Owner,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter()]
        [string]$Body = "",
        
        [Parameter(Mandatory = $true)]
        [string]$Head,
        
        [Parameter()]
        [string]$Base = "main",
        
        [Parameter()]
        [switch]$Draft,
        
        [Parameter()]
        [string[]]$Labels = @(),
        
        [Parameter()]
        [string[]]$Reviewers = @(),
        
        [Parameter()]
        [string[]]$TeamReviewers = @()
    )
    
    Write-Verbose "[New-GitHubPullRequest] Creating PR: $Title"
    
    try {
        # Check authentication
        $pat = Get-GitHubPAT
        if (-not $pat) {
            throw "GitHub PAT not configured. Use Set-GitHubPAT to configure authentication."
        }
        
        # Prepare headers
        $headers = @{
            "Authorization" = "token $pat"
            "Accept" = "application/vnd.github.v3+json"
            "User-Agent" = "Unity-Claude-GitHub/1.0"
        }
        
        # Prepare PR payload
        $prData = @{
            title = $Title
            body = $Body
            head = $Head
            base = $Base
            draft = $Draft.IsPresent
        }
        
        $body = $prData | ConvertTo-Json -Depth 10
        $uri = "https://api.github.com/repos/$Owner/$Repository/pulls"
        
        Write-Verbose "[New-GitHubPullRequest] Creating PR with payload: $body"
        
        # Create pull request
        $response = Invoke-GitHubAPIWithRetry -Uri $uri -Method POST -Body $body -Headers $headers
        
        if ($response) {
            Write-Verbose "[New-GitHubPullRequest] PR created successfully: #$($response.number)"
            
            $result = @{
                PRNumber = $response.number
                PRURL = $response.html_url
                APIUrl = $response.url
                Title = $response.title
                State = $response.state
                Head = $response.head.ref
                Base = $response.base.ref
                Draft = $response.draft
                Created = $true
                Errors = @()
            }
            
            # Add labels if specified
            if ($Labels.Count -gt 0) {
                Write-Verbose "[New-GitHubPullRequest] Adding labels: $($Labels -join ', ')"
                try {
                    $labelUri = "https://api.github.com/repos/$Owner/$Repository/issues/$($response.number)/labels"
                    $labelPayload = $Labels | ConvertTo-Json
                    Invoke-GitHubAPIWithRetry -Uri $labelUri -Method POST -Body $labelPayload -Headers $headers | Out-Null
                    $result.Labels = $Labels
                } catch {
                    $result.Errors += "Failed to add labels: $_"
                    Write-Warning "[New-GitHubPullRequest] Failed to add labels: $_"
                }
            }
            
            # Request reviewers if specified
            if ($Reviewers.Count -gt 0 -or $TeamReviewers.Count -gt 0) {
                Write-Verbose "[New-GitHubPullRequest] Requesting reviewers..."
                try {
                    $reviewData = @{}
                    if ($Reviewers.Count -gt 0) { $reviewData.reviewers = $Reviewers }
                    if ($TeamReviewers.Count -gt 0) { $reviewData.team_reviewers = $TeamReviewers }
                    
                    $reviewUri = "https://api.github.com/repos/$Owner/$Repository/pulls/$($response.number)/requested_reviewers"
                    $reviewPayload = $reviewData | ConvertTo-Json
                    Invoke-GitHubAPIWithRetry -Uri $reviewUri -Method POST -Body $reviewPayload -Headers $headers | Out-Null
                    $result.RequestedReviewers = $Reviewers
                    $result.RequestedTeamReviewers = $TeamReviewers
                } catch {
                    $result.Errors += "Failed to request reviewers: $_"
                    Write-Warning "[New-GitHubPullRequest] Failed to request reviewers: $_"
                }
            }
            
            return $result
        } else {
            throw "No response received from GitHub API"
        }
        
    } catch {
        Write-Error "[New-GitHubPullRequest] Failed to create pull request: $_"
        
        return @{
            PRNumber = $null
            PRURL = $null
            Created = $false
            Errors = @("Failed to create PR: $_")
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDj+O7YPQLT/LpP
# 3W1QpX+y9JzLX5hRhWKRUJgsfA27i6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJoXxYFJWaq5Kz/rN75I3pkA
# npMrijbczfgIkvl8kzA7MA0GCSqGSIb3DQEBAQUABIIBAHUevPANGM4V/4+JpbfM
# eqj6T1IbQjrWzaTKX+2fDKjQXOgCBRcqGCF7YCkk43Psx2RSg6U5BTuuJGG7X1Ps
# qQLLw2y4I3p8PMMSD1EXfu9JN0Sj7f2UEvbpWu23ewNbPkmZGxUQ7UBoPLUdHTBH
# gT23bmMCkMPMfUGF3ZGgohCMSyzt0qrvDW4x8IF67XJCbIh1iQEYiyR832rDCl39
# xbhZyLa97LTgHuWVrT3pRoReUJeqxO6cEwdovubn+fjkyOg7oKMWPyoPwbYjp9sI
# OLNEj91R0TKTBxEwitudNkKK8U0VOG8zT9JusIAXuOa3MMKKvhewPGZ+QAsXRIcD
# tOY=
# SIG # End signature block
