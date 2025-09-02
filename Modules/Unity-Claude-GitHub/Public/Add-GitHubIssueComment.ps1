function Add-GitHubIssueComment {
    <#
    .SYNOPSIS
    Adds a comment to a GitHub issue
    
    .DESCRIPTION
    Adds a new comment to an existing GitHub issue or pull request.
    Useful for adding additional context, error occurrences, or status updates.
    
    .PARAMETER Owner
    The owner of the repository
    
    .PARAMETER Repository
    The name of the repository
    
    .PARAMETER IssueNumber
    The issue number to comment on
    
    .PARAMETER Comment
    The comment text (supports markdown)
    
    .PARAMETER IncludeTimestamp
    Include a timestamp in the comment (default: true)
    
    .EXAMPLE
    Add-GitHubIssueComment -Owner "myorg" -Repository "myrepo" -IssueNumber 42 -Comment "This error occurred again"
    
    .EXAMPLE
    $error = Get-UnityErrors | Select-Object -First 1
    Add-GitHubIssueComment -Owner "myorg" -Repository "myrepo" -IssueNumber 42 -Comment "Error recurrence: $($error.ErrorText)"
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
        [string]$Comment,
        
        [Parameter()]
        [bool]$IncludeTimestamp = $true
    )
    
    begin {
        Write-Verbose "Starting Add-GitHubIssueComment for $Owner/$Repository issue #$IssueNumber"
        
        # Log to unity_claude_automation.log
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logFile = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "unity_claude_automation.log"
        $logEntry = "[$timestamp] [INFO] Add-GitHubIssueComment: Adding comment to issue #$IssueNumber in $Owner/$Repository"
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
            
            # Construct the API endpoint
            $uri = "https://api.github.com/repos/$Owner/$Repository/issues/$IssueNumber/comments"
            Write-Verbose "API Endpoint: $uri"
            
            # Build the comment body
            $commentBody = ""
            
            # Add timestamp if requested
            if ($IncludeTimestamp) {
                $timestampStr = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
                $commentBody = "**[Automated Update - $timestampStr]**`n`n"
            }
            
            # Add the main comment
            $commentBody += $Comment
            
            # Add metadata footer
            $commentBody += "`n`n---`n_Posted by Unity-Claude-GitHub Automation_"
            
            # Build the request body
            $requestBody = @{
                body = $commentBody
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
            $logEntry = "[$timestamp] [SUCCESS] Add-GitHubIssueComment: Added comment to issue #$IssueNumber (Comment ID: $($response.id))"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Verbose "Successfully added comment to issue #$IssueNumber"
            return $response
        }
        catch {
            # Log error
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [ERROR] Add-GitHubIssueComment: Failed to add comment - $($_.Exception.Message)"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Error "Failed to add GitHub issue comment: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Completed Add-GitHubIssueComment"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDiAIK3D6ckMPof
# 4B5LmSZDDjbpP+MrVYesxhuZafF6+qCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPYUZ/+hmik+Icsw4VE5Uy/R
# ub+rzmG2E9Sg8QWOk75oMA0GCSqGSIb3DQEBAQUABIIBABatPaGxGlA3t4UovmUe
# OPhGSyOTzAidX0KReA2fSHa+CqteWATpWNxroTUdbtHyjProalFeECSMMKxjOkpw
# OCYDO1jPTQ06r4r+XUp2krBH4Qc45kGD80TvC+siaK5sLC+FedTvyWsoAcWItLqU
# Pq0eNRgBiOcCi5oyxD6wqWQAlOXksEURc29dm40ZnAN0MLdGe0Re9KLAKobhVjwI
# B4V6eFRuIKAdRHS/RyvfB61MvrUFcFRGlMCZ7Xy+5X2741KNtvxL7B6IO/iJ38gJ
# MkhTEe6Yhk5kPPPHxZyqyHmpvqc1RnAavY3aQ46CmET1GAhtXR6Ut9qHEwNyMzlf
# zIc=
# SIG # End signature block
