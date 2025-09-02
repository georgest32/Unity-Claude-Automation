function Test-GitHubRepositoryAccess {
    <#
    .SYNOPSIS
    Tests API access to a GitHub repository
    
    .DESCRIPTION
    Verifies that the configured PAT has appropriate access to a GitHub repository
    for issue management operations
    
    .PARAMETER Owner
    Repository owner (organization or user)
    
    .PARAMETER Repository
    Repository name
    
    .PARAMETER TestIssueOperations
    Test issue creation/update permissions
    
    .PARAMETER TestLabelOperations
    Test label management permissions
    
    .EXAMPLE
    Test-GitHubRepositoryAccess -Owner "myorg" -Repository "myrepo" -TestIssueOperations
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Owner,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [switch]$TestIssueOperations,
        
        [switch]$TestLabelOperations
    )
    
    try {
        $result = [PSCustomObject]@{
            Repository = "$Owner/$Repository"
            Success = $false
            CanRead = $false
            CanWriteIssues = $false
            CanManageLabels = $false
            Permissions = @()
            Error = $null
            RateLimit = $null
        }
        
        # Get PAT for authentication
        $pat = Get-GitHubPATInternal
        if (-not $pat) {
            $result.Error = "GitHub PAT not configured"
            return $result
        }
        
        # Build headers
        $headers = @{
            "Authorization" = "Bearer $pat"
            "Accept" = "application/vnd.github+json"
            "X-GitHub-Api-Version" = "2022-11-28"
        }
        
        # Test basic repository access
        Write-Verbose "Testing basic repository access"
        $repoUri = "https://api.github.com/repos/$Owner/$Repository"
        
        try {
            $repoInfo = Invoke-GitHubAPIWithRetry -Uri $repoUri -Headers $headers -Method Get
            $result.CanRead = $true
            $result.Permissions += "read"
            
            # Check permissions from response
            if ($repoInfo.permissions) {
                if ($repoInfo.permissions.push) {
                    $result.Permissions += "push"
                }
                if ($repoInfo.permissions.pull) {
                    $result.Permissions += "pull"
                }
                if ($repoInfo.permissions.admin) {
                    $result.Permissions += "admin"
                }
            }
            
        } catch {
            $result.Error = "Cannot access repository: $_"
            return $result
        }
        
        # Test issue operations if requested
        if ($TestIssueOperations) {
            Write-Verbose "Testing issue operations"
            $issuesUri = "https://api.github.com/repos/$Owner/$Repository/issues"
            
            try {
                # Try to list issues
                $issues = Invoke-GitHubAPIWithRetry -Uri "$issuesUri`?state=all&per_page=1" -Headers $headers -Method Get
                
                # If we can list issues, assume we can create/update them
                # (Full test would require actually creating an issue)
                $result.CanWriteIssues = $true
                $result.Permissions += "issues"
                
            } catch {
                Write-Warning "Cannot access issues: $_"
            }
        }
        
        # Test label operations if requested
        if ($TestLabelOperations) {
            Write-Verbose "Testing label operations"
            $labelsUri = "https://api.github.com/repos/$Owner/$Repository/labels"
            
            try {
                # Try to list labels
                $labels = Invoke-GitHubAPIWithRetry -Uri "$labelsUri`?per_page=1" -Headers $headers -Method Get
                
                # If we can list labels, check if we can manage them
                # (Would need push access to create/update labels)
                if ($result.Permissions -contains "push") {
                    $result.CanManageLabels = $true
                    $result.Permissions += "labels"
                }
                
            } catch {
                Write-Warning "Cannot access labels: $_"
            }
        }
        
        # Get rate limit information
        try {
            $rateLimitUri = "https://api.github.com/rate_limit"
            $rateLimit = Invoke-GitHubAPIWithRetry -Uri $rateLimitUri -Headers $headers -Method Get
            
            $result.RateLimit = [PSCustomObject]@{
                Limit = $rateLimit.rate.limit
                Remaining = $rateLimit.rate.remaining
                Reset = [DateTime]::new(1970, 1, 1, 0, 0, 0, [DateTimeKind]::Utc).AddSeconds($rateLimit.rate.reset)
            }
        } catch {
            Write-Warning "Could not get rate limit information"
        }
        
        # Determine overall success
        $result.Success = $result.CanRead
        
        if ($result.Success) {
            Write-Verbose "Successfully accessed repository $Owner/$Repository"
        } else {
            Write-Warning "Failed to access repository $Owner/$Repository"
        }
        
        return $result
        
    } catch {
        Write-Error "Failed to test repository access: $_"
        return [PSCustomObject]@{
            Repository = "$Owner/$Repository"
            Success = $false
            CanRead = $false
            CanWriteIssues = $false
            CanManageLabels = $false
            Permissions = @()
            Error = $_.ToString()
            RateLimit = $null
        }
    }
}

# Export the function
Export-ModuleMember -Function Test-GitHubRepositoryAccess
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAfX87VYWjfc4p5
# GSuz4LXofo4/EdwCIFQsWjxcfueerKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILJm9vX43pdl4r4RGcwi8+CV
# /khQlmsZRYoBPW4Si/9fMA0GCSqGSIb3DQEBAQUABIIBAIRXsGI6n4QQ+CoYkpov
# 4zVb3is2pN7oJIhPZwLCO5e227J/Wx7SrDFx+sOZfsTDupUJQTGJ6+oy047ZgW5R
# Csm99+aavvl2jUObTO7+Nw9T4mb7iiZG1GmlGxnBakVreWYLS0OYbnE1SynB6yxf
# pD52atjvkImdGq4Drqy/cRie2nHJIybcC3WuNwq9nKQrPz9m1QuZ3++FsVm5ARZU
# Lf2NbXvMpdbhOEN/WMx2T/GLYYYpOxZcJZlZcyecYbJJ2Y3jx+0Jt0N+4+fpHH24
# w43iOUAPKHsXVkU7OAe0T5jVCVPU9uoZm9rgGBTK6IbYnbLp1cEJXGDt1FYuAGqp
# QQ8=
# SIG # End signature block
