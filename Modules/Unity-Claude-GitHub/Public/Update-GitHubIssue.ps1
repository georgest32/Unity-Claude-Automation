function Update-GitHubIssue {
    <#
    .SYNOPSIS
    Updates an existing GitHub issue
    
    .DESCRIPTION
    Updates properties of an existing GitHub issue including title, body, state, labels, and assignees.
    Uses the GitHub API v3 PATCH endpoint for issues.
    
    .PARAMETER Owner
    The owner of the repository
    
    .PARAMETER Repository
    The name of the repository
    
    .PARAMETER IssueNumber
    The issue number to update
    
    .PARAMETER Title
    New title for the issue (optional)
    
    .PARAMETER Body
    New body content for the issue (optional)
    
    .PARAMETER State
    New state for the issue: open or closed (optional)
    
    .PARAMETER Labels
    New array of label names (replaces existing labels)
    
    .PARAMETER Assignees
    New array of assignee usernames (replaces existing assignees)
    
    .PARAMETER Milestone
    New milestone number (optional)
    
    .EXAMPLE
    Update-GitHubIssue -Owner "myorg" -Repository "myrepo" -IssueNumber 42 -State "closed"
    
    .EXAMPLE
    Update-GitHubIssue -Owner "myorg" -Repository "myrepo" -IssueNumber 42 -Labels @("bug", "fixed")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Owner,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [Parameter(Mandatory = $true)]
        [int]$IssueNumber,
        
        [Parameter()]
        [string]$Title,
        
        [Parameter()]
        [string]$Body,
        
        [Parameter()]
        [ValidateSet('open', 'closed')]
        [string]$State,
        
        [Parameter()]
        [string[]]$Labels,
        
        [Parameter()]
        [string[]]$Assignees,
        
        [Parameter()]
        [int]$Milestone
    )
    
    begin {
        Write-Verbose "Starting Update-GitHubIssue for $Owner/$Repository issue #$IssueNumber"
        
        # Log to unity_claude_automation.log
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logFile = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "unity_claude_automation.log"
        $logEntry = "[$timestamp] [INFO] Update-GitHubIssue: Updating issue #$IssueNumber in $Owner/$Repository"
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
            $uri = "https://api.github.com/repos/$Owner/$Repository/issues/$IssueNumber"
            Write-Verbose "API Endpoint: $uri"
            
            # Build the request body with only specified parameters
            $requestBody = @{}
            
            if ($PSBoundParameters.ContainsKey('Title')) {
                $requestBody.title = $Title
                Write-Verbose "Updating title"
            }
            
            if ($PSBoundParameters.ContainsKey('Body')) {
                $requestBody.body = $Body
                Write-Verbose "Updating body"
            }
            
            if ($PSBoundParameters.ContainsKey('State')) {
                $requestBody.state = $State.ToLower()
                Write-Verbose "Updating state to: $State"
            }
            
            if ($PSBoundParameters.ContainsKey('Labels')) {
                $requestBody.labels = $Labels
                Write-Verbose "Updating labels: $($Labels -join ', ')"
            }
            
            if ($PSBoundParameters.ContainsKey('Assignees')) {
                $requestBody.assignees = $Assignees
                Write-Verbose "Updating assignees: $($Assignees -join ', ')"
            }
            
            if ($PSBoundParameters.ContainsKey('Milestone')) {
                $requestBody.milestone = $Milestone
                Write-Verbose "Updating milestone: $Milestone"
            }
            
            # Check if there's anything to update
            if ($requestBody.Count -eq 0) {
                Write-Warning "No update parameters specified. Nothing to update."
                return
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
            $response = Invoke-GitHubAPIWithRetry -Uri $uri -Method 'PATCH' -Headers $headers -Body $json
            
            # Log success
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $updateSummary = $requestBody.Keys -join ', '
            $logEntry = "[$timestamp] [SUCCESS] Update-GitHubIssue: Updated issue #$IssueNumber - Changed: $updateSummary"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Verbose "Successfully updated issue #$IssueNumber"
            return $response
        }
        catch {
            # Log error
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [ERROR] Update-GitHubIssue: Failed to update issue #$IssueNumber - $($_.Exception.Message)"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Error "Failed to update GitHub issue: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Completed Update-GitHubIssue"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDpOr1xZ96WI2ut
# VSQRk5QT8uliYEgHTB7qXwNBjNT6zKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBgXWrYlIDZT3qp2zJsDmDtF
# AEPV0Ik+pAVqLRD+cpY5MA0GCSqGSIb3DQEBAQUABIIBACkoaxXOx+4iLYEEFqSM
# gkD8e/2DYyde1oWmCb2i284+VIZfdtZp+itaaQ5PDVqw3iE23w9QOl8qxcWrUu4N
# SmS+no//YICCu0skDnqSEj8ZoVzqOwGL/I0ZJpyLbRi4TlnYrCauDFYoXU3ManId
# kEhvM4Km1c7EoI+cmYwjdhPXv0ciNl3+u1DJtspja3XRa5cjRgBI+Zl165NMMx8e
# CojCbdANdlHtgA3EsQeVPAiE9iQ+P3P3ehHycFjKVX3H0r0fiO6ZmMltTdnxAg1k
# 8KHQrQFHHSlwztZB6CWsgbI93TUEHsgVTLA21XCZ+4ZIoeijaNBdqeOG/lLyoU+P
# ePQ=
# SIG # End signature block
