function Get-GitHubIssueStatus {
    <#
    .SYNOPSIS
    Gets the current status and lifecycle information for a GitHub issue
    
    .DESCRIPTION
    Retrieves comprehensive status information including state, labels, milestone,
    assignees, and lifecycle history for a GitHub issue
    
    .PARAMETER Owner
    Repository owner (organization or user)
    
    .PARAMETER Repository
    Repository name
    
    .PARAMETER IssueNumber
    Issue number to check status for
    
    .PARAMETER IncludeComments
    Include comment history in lifecycle tracking
    
    .PARAMETER IncludeEvents
    Include issue events (closed, reopened, labeled, etc.)
    
    .EXAMPLE
    Get-GitHubIssueStatus -Owner "myorg" -Repository "myrepo" -IssueNumber 123
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Owner,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [Parameter(Mandatory = $true)]
        [int]$IssueNumber,
        
        [switch]$IncludeComments,
        
        [switch]$IncludeEvents
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
        
        # Get issue details
        $issueUri = "https://api.github.com/repos/$Owner/$Repository/issues/$IssueNumber"
        Write-Verbose "Getting issue details from: $issueUri"
        
        $issue = Invoke-GitHubAPIWithRetry -Uri $issueUri -Headers $headers -Method Get
        
        # Build status object
        $status = [PSCustomObject]@{
            Number = $issue.number
            Title = $issue.title
            State = $issue.state
            StateReason = $issue.state_reason
            CreatedAt = $issue.created_at
            UpdatedAt = $issue.updated_at
            ClosedAt = $issue.closed_at
            Labels = $issue.labels | ForEach-Object { $_.name }
            Milestone = if ($issue.milestone) { $issue.milestone.title } else { $null }
            MilestoneState = if ($issue.milestone) { $issue.milestone.state } else { $null }
            Assignees = $issue.assignees | ForEach-Object { $_.login }
            Comments = $issue.comments
            ClosedBy = if ($issue.closed_by) { $issue.closed_by.login } else { $null }
            IsPullRequest = $null -ne $issue.pull_request
            Lifecycle = @()
        }
        
        # Add lifecycle history
        $lifecycle = @()
        
        # Creation event
        $lifecycle += [PSCustomObject]@{
            Event = "created"
            Actor = $issue.user.login
            Timestamp = $issue.created_at
            Details = "Issue created"
        }
        
        # Get events if requested
        if ($IncludeEvents) {
            $eventsUri = "https://api.github.com/repos/$Owner/$Repository/issues/$IssueNumber/events"
            Write-Verbose "Getting issue events from: $eventsUri"
            
            $events = Invoke-GitHubAPIWithRetry -Uri $eventsUri -Headers $headers -Method Get
            
            foreach ($event in $events) {
                $lifecycle += [PSCustomObject]@{
                    Event = $event.event
                    Actor = if ($event.actor) { $event.actor.login } else { "system" }
                    Timestamp = $event.created_at
                    Details = switch ($event.event) {
                        "closed" { "Issue closed" }
                        "reopened" { "Issue reopened" }
                        "labeled" { "Label added: $($event.label.name)" }
                        "unlabeled" { "Label removed: $($event.label.name)" }
                        "assigned" { "Assigned to: $($event.assignee.login)" }
                        "unassigned" { "Unassigned from: $($event.assignee.login)" }
                        "milestoned" { "Milestone set: $($event.milestone.title)" }
                        "demilestoned" { "Milestone removed: $($event.milestone.title)" }
                        "renamed" { "Title changed from: $($event.rename.from) to: $($event.rename.to)" }
                        default { $event.event }
                    }
                }
            }
        }
        
        # Get comments if requested
        if ($IncludeComments -and $issue.comments -gt 0) {
            $commentsUri = "https://api.github.com/repos/$Owner/$Repository/issues/$IssueNumber/comments"
            Write-Verbose "Getting issue comments from: $commentsUri"
            
            $comments = Invoke-GitHubAPIWithRetry -Uri $commentsUri -Headers $headers -Method Get
            
            foreach ($comment in $comments) {
                $lifecycle += [PSCustomObject]@{
                    Event = "commented"
                    Actor = $comment.user.login
                    Timestamp = $comment.created_at
                    Details = "Comment added ($($comment.body.Length) chars)"
                }
            }
        }
        
        # Sort lifecycle by timestamp
        $status.Lifecycle = $lifecycle | Sort-Object Timestamp
        
        # Calculate time metrics
        $created = [DateTime]::Parse($issue.created_at)
        $now = [DateTime]::UtcNow
        
        if ($issue.state -eq "closed" -and $issue.closed_at) {
            $closed = [DateTime]::Parse($issue.closed_at)
            $timeToClose = $closed - $created
            $status | Add-Member -NotePropertyName "TimeToClose" -NotePropertyValue $timeToClose
            $status | Add-Member -NotePropertyName "TimeToCloseHours" -NotePropertyValue $timeToClose.TotalHours
        } else {
            $openDuration = $now - $created
            $status | Add-Member -NotePropertyName "OpenDuration" -NotePropertyValue $openDuration
            $status | Add-Member -NotePropertyName "OpenDurationDays" -NotePropertyValue $openDuration.TotalDays
        }
        
        # Add resolution detection
        $resolutionIndicators = @("fixed", "resolved", "completed", "done", "merged")
        $hasResolutionLabel = $false
        foreach ($label in $status.Labels) {
            foreach ($indicator in $resolutionIndicators) {
                if ($label -like "*$indicator*") {
                    $hasResolutionLabel = $true
                    break
                }
            }
        }
        
        $status | Add-Member -NotePropertyName "HasResolutionIndicator" -NotePropertyValue $hasResolutionLabel
        
        return $status
        
    } catch {
        Write-Error "Failed to get issue status: $_"
        throw
    }
}

# Export the function
Export-ModuleMember -Function Get-GitHubIssueStatus
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBYiOXwKMwUps8e
# Rfw+hZSVF2OI8gXP8N2gZjOms03KvqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJCXPRsZ6KZszAjSk1L6Lp9k
# KEZ5QnZVMWM1UYRNqRQ/MA0GCSqGSIb3DQEBAQUABIIBAGPo3WI4u3fRR9kCzBPZ
# Yz7RB3VPLEIuuRyAQdRzSjErn70zdhlbebWbCDjb6b2fZI4UaiC1Q/5izKKhCQKr
# KAPcLifRi4jzee8WrCOZ4QxHuA5Tbnc/8M4PfKdpPOXOt7tcJdpCDFdsH5tqf7FD
# kq0DuuEtFj+3V1kprHd+hGz/n/miQVDEOwbJkRVEf8JI9UoCIe1kzjHX3tLYyjVj
# dTtgLvj3Q4Thku+ZKDXU64+WcvG+itdNDdpkvrz3RynSK8FjSf+/sc/uOPITQUWW
# E2scsbseVufC9HDOjL4OJyoHkfMV13tcf4vh8pCctXHqIWKFtA2vbbJzMHFaSpNl
# jnA=
# SIG # End signature block
