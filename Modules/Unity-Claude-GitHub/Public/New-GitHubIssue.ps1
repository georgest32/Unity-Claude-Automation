function New-GitHubIssue {
    <#
    .SYNOPSIS
    Creates a new issue in a GitHub repository
    
    .DESCRIPTION
    Creates a new issue in the specified GitHub repository using the GitHub API v3.
    Integrates with the Unity-Claude-GitHub module's authentication and retry logic.
    
    .PARAMETER Owner
    The owner of the repository (user or organization)
    
    .PARAMETER Repository
    The name of the repository
    
    .PARAMETER Title
    The title of the issue
    
    .PARAMETER Body
    The body content of the issue (supports markdown)
    
    .PARAMETER Labels
    Array of label names to apply to the issue
    
    .PARAMETER Assignees
    Array of usernames to assign to the issue
    
    .PARAMETER Milestone
    The milestone number to associate with the issue
    
    .EXAMPLE
    New-GitHubIssue -Owner "myorg" -Repository "myrepo" -Title "Unity Compilation Error" -Body "Error details..." -Labels @("bug", "unity")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Owner,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$Body,
        
        [Parameter()]
        [string[]]$Labels = @(),
        
        [Parameter()]
        [string[]]$Assignees = @(),
        
        [Parameter()]
        [int]$Milestone
    )
    
    begin {
        Write-Verbose "Starting New-GitHubIssue for $Owner/$Repository"
        
        # Log to unity_claude_automation.log
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logFile = Join-Path (Split-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) -Parent) "unity_claude_automation.log"
        $logEntry = "[$timestamp] [INFO] New-GitHubIssue: Creating issue in $Owner/$Repository - Title: $Title"
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
            $uri = "https://api.github.com/repos/$Owner/$Repository/issues"
            Write-Verbose "API Endpoint: $uri"
            
            # Build the request body
            $requestBody = @{
                title = $Title
                body = $Body
            }
            
            if ($Labels.Count -gt 0) {
                $requestBody.labels = $Labels
                Write-Verbose "Adding labels: $($Labels -join ', ')"
            }
            
            if ($Assignees.Count -gt 0) {
                $requestBody.assignees = $Assignees
                Write-Verbose "Adding assignees: $($Assignees -join ', ')"
            }
            
            if ($PSBoundParameters.ContainsKey('Milestone')) {
                $requestBody.milestone = $Milestone
                Write-Verbose "Adding milestone: $Milestone"
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
            $logEntry = "[$timestamp] [SUCCESS] New-GitHubIssue: Created issue #$($response.number) in $Owner/$Repository"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Verbose "Successfully created issue #$($response.number)"
            return $response
        }
        catch {
            # Log error
            $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            $logEntry = "[$timestamp] [ERROR] New-GitHubIssue: Failed to create issue - $($_.Exception.Message)"
            Add-Content -Path $logFile -Value $logEntry -ErrorAction SilentlyContinue
            
            Write-Error "Failed to create GitHub issue: $_"
            throw
        }
    }
    
    end {
        Write-Verbose "Completed New-GitHubIssue"
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBLKhHNQNOrWj8i
# MWX+WsgCzYyJ/7tXGPYcjVnKly2I7qCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIO8wpsNcpN5LTtj8ERPbPyhS
# lx+2HKxwLV9JxIRtHdbvMA0GCSqGSIb3DQEBAQUABIIBAEHGDD0+KcO/g+E3Eso/
# 5pnu/1kbCq5K6/oYu5ckRoyuiMtW6+IG2Ec9kVaAGLFP7EocGtTIW1gQMjAwUEaP
# n9lTgtQQl19bvtLk35Z2LI9D58A/ZaYOsYNqcl8MiWn7i1Fk+/4CUFl9MLZdy+A8
# t+KrxjNNikOkIuveYTyJnS07Uo4O2qUHAOEJL9yGBAt/b1b+hgRoUIiklKguGqZm
# tsfveoGqwO6uSY1XXRu0W0JE5F6nyAntSHc2TupEgoxpoU7KHWodyQjqzlqJ9UPe
# ArsbscG2v4USzWUHkgL1bVVnJ20jSaN/5L2+ad5y68TyO/AETlP5NKj9eU9o4WaI
# 3yg=
# SIG # End signature block
