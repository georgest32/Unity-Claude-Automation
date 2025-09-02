function Close-GitHubIssueIfResolved {
    <#
    .SYNOPSIS
    Automatically closes a GitHub issue if the associated Unity error has been resolved
    
    .DESCRIPTION
    Checks if a Unity error has been resolved and automatically closes the GitHub issue
    with appropriate comments and labels if resolution is confirmed
    
    .PARAMETER Owner
    Repository owner (organization or user)
    
    .PARAMETER Repository
    Repository name
    
    .PARAMETER IssueNumber
    Issue number to potentially close
    
    .PARAMETER ErrorSignature
    Unity error signature/hash to check for resolution
    
    .PARAMETER MinConfidence
    Minimum confidence threshold for automatic closing (0.0 to 1.0)
    
    .PARAMETER AddResolvedLabel
    Add a "resolved" label when closing
    
    .PARAMETER DryRun
    Test what would happen without actually closing the issue
    
    .PARAMETER ReopenIfRecurring
    Reopen the issue if the error recurs after being closed
    
    .EXAMPLE
    Close-GitHubIssueIfResolved -Owner "myorg" -Repository "myrepo" -IssueNumber 123 -ErrorSignature "CS0246" -MinConfidence 0.7
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Owner,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [Parameter(Mandatory = $true)]
        [int]$IssueNumber,
        
        [string]$ErrorSignature,
        
        [double]$MinConfidence = 0.8,
        
        [switch]$AddResolvedLabel,
        
        [switch]$DryRun,
        
        [switch]$ReopenIfRecurring
    )
    
    try {
        Write-Verbose "Checking if issue #$IssueNumber should be closed"
        
        # Get current issue status
        $issueStatus = Get-GitHubIssueStatus -Owner $Owner -Repository $Repository -IssueNumber $IssueNumber
        
        # Extract error signature from issue if not provided
        if (-not $ErrorSignature) {
            # Try to extract from issue title or body
            if ($issueStatus.Title -match '(CS\d{4})') {
                $ErrorSignature = $Matches[1]
                Write-Verbose "Extracted error signature from issue: $ErrorSignature"
            }
        }
        
        # Check current state
        if ($issueStatus.State -eq "closed" -and -not $ReopenIfRecurring) {
            Write-Verbose "Issue #$IssueNumber is already closed"
            return [PSCustomObject]@{
                IssueNumber = $IssueNumber
                Action = "none"
                Reason = "Issue already closed"
                State = "closed"
            }
        }
        
        # Test if error is resolved
        $resolutionCheck = Test-UnityErrorResolved -IssueNumber $IssueNumber -ErrorSignature $ErrorSignature `
            -Owner $Owner -Repository $Repository -CheckCompilationSuccess
        
        # Decision logic for closing
        $shouldClose = $false
        $shouldReopen = $false
        $actionReason = ""
        
        if ($issueStatus.State -eq "open") {
            # Issue is open - check if we should close it
            if ($resolutionCheck.IsResolved -and $resolutionCheck.ResolutionConfidence -ge $MinConfidence) {
                $shouldClose = $true
                $actionReason = "Unity error resolved with $([Math]::Round($resolutionCheck.ResolutionConfidence * 100, 1))% confidence"
            } else {
                $actionReason = "Resolution confidence ($([Math]::Round($resolutionCheck.ResolutionConfidence * 100, 1))%) below threshold ($([Math]::Round($MinConfidence * 100, 1))%)"
            }
        } elseif ($issueStatus.State -eq "closed" -and $ReopenIfRecurring) {
            # Issue is closed - check if we should reopen it
            if ($resolutionCheck.ErrorStillPresent) {
                $shouldReopen = $true
                $actionReason = "Unity error has recurred - reopening issue"
            } else {
                $actionReason = "Issue remains resolved"
            }
        }
        
        # Build result object
        $result = [PSCustomObject]@{
            IssueNumber = $IssueNumber
            Action = "none"
            Reason = $actionReason
            State = $issueStatus.State
            ResolutionCheck = $resolutionCheck
            DryRun = $DryRun
        }
        
        # Take action if needed
        if ($shouldClose) {
            $result.Action = "close"
            
            if (-not $DryRun) {
                Write-Verbose "Closing issue #$IssueNumber"
                
                # Build closing comment
                $closingComment = @"
## Issue Auto-Closed

This issue has been automatically closed as the associated Unity error appears to be resolved.

**Resolution Details:**
$($resolutionCheck.ResolutionDetails)

**Indicators:**
$($resolutionCheck.Indicators | ForEach-Object { "- $_" } | Out-String)

**Confidence:** $([Math]::Round($resolutionCheck.ResolutionConfidence * 100, 1))%
**Last Compilation:** $($resolutionCheck.LastCompilationTime)

---
*This is an automated action. If this error recurs, the issue can be reopened automatically or manually.*
"@
                
                # Prepare labels
                $labelsToAdd = @()
                if ($AddResolvedLabel) {
                    $labelsToAdd += "resolved"
                }
                $labelsToAdd += "auto-closed"
                
                # Close the issue
                $updateResult = Update-GitHubIssueState `
                    -Owner $Owner `
                    -Repository $Repository `
                    -IssueNumber $IssueNumber `
                    -State "closed" `
                    -StateReason "completed" `
                    -AddLabels $labelsToAdd `
                    -Comment $closingComment
                
                $result.State = "closed"
                Write-Host "Issue #$IssueNumber closed successfully" -ForegroundColor Green
            } else {
                Write-Host "DRY RUN: Would close issue #$IssueNumber" -ForegroundColor Yellow
            }
            
        } elseif ($shouldReopen) {
            $result.Action = "reopen"
            
            if (-not $DryRun) {
                Write-Verbose "Reopening issue #$IssueNumber"
                
                # Build reopening comment
                $reopeningComment = @"
## Issue Reopened

This issue has been automatically reopened as the associated Unity error has recurred.

**Error Status:**
$($resolutionCheck.ResolutionDetails)

**Indicators:**
$($resolutionCheck.Indicators | ForEach-Object { "- $_" } | Out-String)

**Last Compilation:** $($resolutionCheck.LastCompilationTime)

---
*This is an automated action based on Unity compilation monitoring.*
"@
                
                # Reopen the issue
                $updateResult = Update-GitHubIssueState `
                    -Owner $Owner `
                    -Repository $Repository `
                    -IssueNumber $IssueNumber `
                    -State "open" `
                    -StateReason "reopened" `
                    -AddLabels @("recurring") `
                    -RemoveLabels @("resolved", "auto-closed") `
                    -Comment $reopeningComment
                
                $result.State = "open"
                Write-Host "Issue #$IssueNumber reopened due to recurring error" -ForegroundColor Yellow
            } else {
                Write-Host "DRY RUN: Would reopen issue #$IssueNumber" -ForegroundColor Yellow
            }
        } else {
            Write-Verbose "No action needed for issue #$IssueNumber - $actionReason"
        }
        
        return $result
        
    } catch {
        Write-Error "Failed to process issue auto-close: $_"
        throw
    }
}

# Export the function
Export-ModuleMember -Function Close-GitHubIssueIfResolved
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCOULT+5S88tP2y
# l82ocFmHNpr+XZ/xBjAh8CybhYCOtKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBSLxNzp6s7xQuVvhGAaQBT1
# 9lOurKBollOJI8m0mFdGMA0GCSqGSIb3DQEBAQUABIIBAAGGtRqaN2mjHqmduY4M
# 5zAWaHtUvJHjQO8vjUww0FMhwB7ooDBZndIBZXYYu8oTwp52RC4mUvr5iAKcLY5A
# XlWM9teMki4MD58seVzE6L0s3qny8zZLDJM4nfa28d2zpjIZfDv4RbaKJqqUodFx
# +VJ4bVEOP7G2ZblkC7gLSjZoF+6KE6mWoN01NvtPtzSqcdW8Pr912Dd6UtKwnPF5
# EH498gbyqWUKxQ7C4h2bbNm9P9cZwdGsz4XOfQ3Jic8EBZq9c/dqLSh2NonNol8T
# zRDkT74P4E9klHgTmjUnQNbfsvhK6Y07/g1T6c89kLIpba2bp3kObpo51yw2hTJv
# 34A=
# SIG # End signature block
