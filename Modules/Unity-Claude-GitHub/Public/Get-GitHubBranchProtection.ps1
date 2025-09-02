function Get-GitHubBranchProtection {
    <#
    .SYNOPSIS
        Retrieves branch protection rules for a GitHub repository.
    
    .DESCRIPTION
        Gets current branch protection configuration using the GitHub REST API,
        including required reviews, status checks, admin enforcement, and other settings.
    
    .PARAMETER Owner
        Repository owner (username or organization name).
    
    .PARAMETER Repository
        Repository name.
    
    .PARAMETER Branch
        Branch name to check protection rules for (e.g., "main", "master").
    
    .EXAMPLE
        Get-GitHubBranchProtection -Owner "myorg" -Repository "myrepo" -Branch "main"
    
    .EXAMPLE
        $protection = Get-GitHubBranchProtection -Owner "myorg" -Repository "myrepo" -Branch "main"
        if ($protection.Success) {
            Write-Host "Required reviews: $($protection.Configuration.required_pull_request_reviews.required_approving_review_count)"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Owner,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [Parameter(Mandatory = $true)]
        [string]$Branch
    )
    
    begin {
        Write-Verbose "Starting Get-GitHubBranchProtection for $Owner/$Repository branch: $Branch"
        
        # Validate GitHub PAT
        $pat = Get-GitHubPAT
        if (-not $pat) {
            throw "GitHub PAT not configured. Use Set-GitHubPAT first."
        }
    }
    
    process {
        try {
            $apiUrl = "https://api.github.com/repos/$Owner/$Repository/branches/$Branch/protection"
            
            Write-Verbose "Retrieving branch protection settings from: $apiUrl"
            
            $response = Invoke-GitHubAPIWithRetry -Uri $apiUrl -Method 'GET'
            
            Write-Verbose "Successfully retrieved branch protection configuration"
            
            # Parse and structure the response
            $protectionSummary = @{
                Success = $true
                Owner = $Owner
                Repository = $Repository
                Branch = $Branch
                IsProtected = $true
                Configuration = $response
                Summary = @{
                    RequiredReviews = if ($response.required_pull_request_reviews) { 
                        $response.required_pull_request_reviews.required_approving_review_count 
                    } else { 0 }
                    CodeOwnerReviews = if ($response.required_pull_request_reviews) { 
                        $response.required_pull_request_reviews.require_code_owner_reviews 
                    } else { $false }
                    StaleReviewDismissal = if ($response.required_pull_request_reviews) { 
                        $response.required_pull_request_reviews.dismiss_stale_reviews 
                    } else { $false }
                    StatusChecksRequired = if ($response.required_status_checks) { 
                        $response.required_status_checks.contexts.Count 
                    } else { 0 }
                    StatusChecksStrict = if ($response.required_status_checks) { 
                        $response.required_status_checks.strict 
                    } else { $false }
                    AdminsEnforced = $response.enforce_admins.enabled
                    ForcePushesAllowed = $response.allow_force_pushes.enabled
                    DeletionsAllowed = $response.allow_deletions.enabled
                    LinearHistoryRequired = $response.required_linear_history.enabled
                    ConversationResolutionRequired = $response.required_conversation_resolution.enabled
                }
            }
            
            return $protectionSummary
        }
        catch {
            # Handle 404 - branch not protected
            if ($_.Exception.Message -match "404" -or $_.Exception.Message -match "Not Found") {
                Write-Verbose "Branch '$Branch' is not protected"
                return @{
                    Success = $true
                    Owner = $Owner
                    Repository = $Repository
                    Branch = $Branch
                    IsProtected = $false
                    Configuration = $null
                    Summary = @{
                        RequiredReviews = 0
                        CodeOwnerReviews = $false
                        StaleReviewDismissal = $false
                        StatusChecksRequired = 0
                        StatusChecksStrict = $false
                        AdminsEnforced = $false
                        ForcePushesAllowed = $true
                        DeletionsAllowed = $true
                        LinearHistoryRequired = $false
                        ConversationResolutionRequired = $false
                    }
                }
            }
            
            Write-Error "Failed to get branch protection for $Owner/$Repository branch '$Branch': $($_.Exception.Message)"
            return @{
                Success = $false
                Owner = $Owner
                Repository = $Repository
                Branch = $Branch
                IsProtected = $null
                Error = $_.Exception.Message
            }
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDDW2GDN+SOFpb2
# J34JRsA1J8bQyWvZyG379j6JDVItlqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBo4+W72wv5a8fHcausg0w6g
# I5YVS6lbl/0xUkdvJSqDMA0GCSqGSIb3DQEBAQUABIIBACXeKksPDjrhgvJ1uCfb
# 5AOVZeoGPA9+43RI6CBSFZxVp6D+a1mPqwunV7jvd8T2f7AN1mhnyVtanvMMkeN9
# X9u/gMMHeadUprZ5g/4ZM5eWo+6XzYv3/XHNp9nsNHiLwI//GTq8TEn2t39nRNPH
# 22DDJjCe2ct9PjF6IbewI9gHGQlvn0XHhydT9/Sjj/bygVtbFHMu0VTxLsgOTGt/
# XYIOPUeJ/9NO/mZtHsSVY3eDWNQ8wdFkYK1Cjd52M6mMVGzesQP44TDVskbosuER
# pkbgxhTLlC+QIyT8DU+bBEMIWjsv+gk1747AbiUeOPpWWaNB/+5mZcTfVBW380gd
# THU=
# SIG # End signature block
