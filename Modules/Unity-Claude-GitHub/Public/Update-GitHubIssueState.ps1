function Update-GitHubIssueState {
    <#
    .SYNOPSIS
    Updates the state of a GitHub issue with lifecycle tracking
    
    .DESCRIPTION
    Changes issue state (open/closed) and optionally updates labels, milestone,
    and adds a comment explaining the state change
    
    .PARAMETER Owner
    Repository owner (organization or user)
    
    .PARAMETER Repository
    Repository name
    
    .PARAMETER IssueNumber
    Issue number to update
    
    .PARAMETER State
    New state for the issue (open or closed)
    
    .PARAMETER StateReason
    Reason for closing (completed, not_planned, reopened)
    
    .PARAMETER Labels
    Labels to set on the issue (replaces existing)
    
    .PARAMETER AddLabels
    Labels to add to existing labels
    
    .PARAMETER RemoveLabels
    Labels to remove from existing labels
    
    .PARAMETER Milestone
    Milestone number to assign
    
    .PARAMETER Comment
    Comment to add explaining the state change
    
    .PARAMETER Assignees
    User logins to assign to the issue
    
    .EXAMPLE
    Update-GitHubIssueState -Owner "myorg" -Repository "myrepo" -IssueNumber 123 -State "closed" -StateReason "completed" -Comment "Fixed in PR #456"
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
        [ValidateSet("open", "closed")]
        [string]$State,
        
        [ValidateSet("completed", "not_planned", "reopened")]
        [string]$StateReason,
        
        [string[]]$Labels,
        
        [string[]]$AddLabels,
        
        [string[]]$RemoveLabels,
        
        [int]$Milestone,
        
        [string]$Comment,
        
        [string[]]$Assignees
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
            "Content-Type" = "application/json"
        }
        
        # Get current issue state for comparison
        $currentStatus = Get-GitHubIssueStatus -Owner $Owner -Repository $Repository -IssueNumber $IssueNumber
        
        # Build update body
        $body = @{
            state = $State
        }
        
        if ($StateReason) {
            $body.state_reason = $StateReason
        }
        
        # Handle labels
        if ($Labels) {
            # Replace all labels
            $body.labels = $Labels
        } elseif ($AddLabels -or $RemoveLabels) {
            # Modify existing labels
            $currentLabels = $currentStatus.Labels
            $newLabels = [System.Collections.ArrayList]::new()
            
            # Add existing labels
            foreach ($label in $currentLabels) {
                if (-not ($RemoveLabels -contains $label)) {
                    [void]$newLabels.Add($label)
                }
            }
            
            # Add new labels
            foreach ($label in $AddLabels) {
                if (-not ($newLabels -contains $label)) {
                    [void]$newLabels.Add($label)
                }
            }
            
            $body.labels = $newLabels.ToArray()
        }
        
        if ($Milestone) {
            $body.milestone = $Milestone
        }
        
        if ($Assignees) {
            $body.assignees = $Assignees
        }
        
        # Convert body to JSON
        $jsonBody = $body | ConvertTo-Json -Depth 10
        
        # Update the issue
        $issueUri = "https://api.github.com/repos/$Owner/$Repository/issues/$IssueNumber"
        Write-Verbose "Updating issue at: $issueUri"
        Write-Verbose "Update body: $jsonBody"
        
        $updatedIssue = Invoke-GitHubAPIWithRetry -Uri $issueUri -Headers $headers -Method Patch -Body $jsonBody
        
        # Add comment if provided
        if ($Comment) {
            # Build comment with state change information
            $commentBody = $Comment
            
            # Add state transition info if state changed
            if ($currentStatus.State -ne $State) {
                $transitionInfo = "`n`n---`n*Issue state changed from **$($currentStatus.State)** to **$State***"
                if ($StateReason) {
                    $transitionInfo += " (Reason: $StateReason)"
                }
                $commentBody += $transitionInfo
            }
            
            # Add label change info if labels changed
            if ($AddLabels -or $RemoveLabels) {
                $labelInfo = "`n"
                if ($AddLabels) {
                    $labelInfo += "`n*Labels added:* $($AddLabels -join ', ')"
                }
                if ($RemoveLabels) {
                    $labelInfo += "`n*Labels removed:* $($RemoveLabels -join ', ')"
                }
                $commentBody += $labelInfo
            }
            
            # Post the comment
            $commentUri = "https://api.github.com/repos/$Owner/$Repository/issues/$IssueNumber/comments"
            $commentJson = @{ body = $commentBody } | ConvertTo-Json
            
            Write-Verbose "Adding comment to issue"
            Invoke-GitHubAPIWithRetry -Uri $commentUri -Headers $headers -Method Post -Body $commentJson | Out-Null
        }
        
        # Build result object with transition details
        $result = [PSCustomObject]@{
            Number = $updatedIssue.number
            Title = $updatedIssue.title
            PreviousState = $currentStatus.State
            NewState = $updatedIssue.state
            StateChanged = $currentStatus.State -ne $updatedIssue.state
            Labels = $updatedIssue.labels | ForEach-Object { $_.name }
            Milestone = if ($updatedIssue.milestone) { $updatedIssue.milestone.title } else { $null }
            Assignees = $updatedIssue.assignees | ForEach-Object { $_.login }
            UpdatedAt = $updatedIssue.updated_at
            Url = $updatedIssue.html_url
        }
        
        Write-Verbose "Issue #$IssueNumber updated successfully"
        return $result
        
    } catch {
        Write-Error "Failed to update issue state: $_"
        throw
    }
}

# Export the function
Export-ModuleMember -Function Update-GitHubIssueState
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB2ynj+9YcLi5Sl
# v9q7g/WZKHl4dcuwyk6Otukw5mo1bqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBN+gWz3x7FqJ0GqtHvxBdAx
# FDryUrInePZw0+RpDhNoMA0GCSqGSIb3DQEBAQUABIIBABzCBaPgSYiHw6ZcsQfr
# kEYilNX76YOugGkJHy3j/A8IQghwEVZsXWknFvMdwx3XaxtMllIBLHns9znlq1dJ
# hAR9arjMFoesulEYyafoWLVonFnqUHF0jtPesin1NxM1I6fkRcXElV70f9IoXwK2
# tnjrpo6tqqTnMjw1NkitzwxWlugaD/ybmiYJ+7pX0QuBkwMiNQdNtt5W3LWNRWHO
# DuDWlFYoUuLvgpbKOx3dxvlIpfK3NeWTr+EM9m+N90IUPC9TtX7P1rFZ2wEivhnK
# 66F5snDxL2csRGGmOQ9HpbGFHM7hE2Osz61ihh95b9272rO7VBK9jYmvWXCK2sIw
# Ncg=
# SIG # End signature block
