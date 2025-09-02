function Set-GitHubBranchProtection {
    <#
    .SYNOPSIS
        Configures branch protection rules for a GitHub repository.
    
    .DESCRIPTION
        Sets up branch protection rules using the GitHub REST API, including required reviews,
        status checks, admin enforcement, and other security settings.
    
    .PARAMETER Owner
        Repository owner (username or organization name).
    
    .PARAMETER Repository
        Repository name.
    
    .PARAMETER Branch
        Branch name to protect (e.g., "main", "master").
    
    .PARAMETER RequiredReviews
        Number of required approving reviews (1-6). Default is 1.
    
    .PARAMETER RequireCodeOwnerReviews
        Require review from code owners when CODEOWNERS file exists.
    
    .PARAMETER DismissStaleReviews
        Dismiss approving reviews when new commits are pushed.
    
    .PARAMETER RequiredStatusChecks
        Array of required status check contexts that must pass.
    
    .PARAMETER StrictStatusChecks
        Require branches to be up to date before merging.
    
    .PARAMETER EnforceAdmins
        Apply protection rules to administrators.
    
    .PARAMETER AllowForcePushes
        Allow force pushes to the protected branch.
    
    .PARAMETER AllowDeletions
        Allow deletion of the protected branch.
    
    .PARAMETER RequireLinearHistory
        Require linear history (no merge commits).
    
    .PARAMETER RequireConversationResolution
        Require conversation resolution before merging.
    
    .EXAMPLE
        Set-GitHubBranchProtection -Owner "myorg" -Repository "myrepo" -Branch "main" -RequiredReviews 2 -RequireCodeOwnerReviews
    
    .EXAMPLE
        Set-GitHubBranchProtection -Owner "myorg" -Repository "myrepo" -Branch "main" -RequiredStatusChecks @("ci/build", "ci/test") -StrictStatusChecks
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Owner,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [Parameter(Mandatory = $true)]
        [string]$Branch,
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 6)]
        [int]$RequiredReviews = 1,
        
        [Parameter(Mandatory = $false)]
        [switch]$RequireCodeOwnerReviews,
        
        [Parameter(Mandatory = $false)]
        [switch]$DismissStaleReviews,
        
        [Parameter(Mandatory = $false)]
        [string[]]$RequiredStatusChecks = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$StrictStatusChecks,
        
        [Parameter(Mandatory = $false)]
        [switch]$EnforceAdmins,
        
        [Parameter(Mandatory = $false)]
        [switch]$AllowForcePushes,
        
        [Parameter(Mandatory = $false)]
        [switch]$AllowDeletions,
        
        [Parameter(Mandatory = $false)]
        [switch]$RequireLinearHistory,
        
        [Parameter(Mandatory = $false)]
        [switch]$RequireConversationResolution
    )
    
    begin {
        Write-Verbose "Starting Set-GitHubBranchProtection for $Owner/$Repository branch: $Branch"
        
        # Validate GitHub PAT
        $pat = Get-GitHubPAT
        if (-not $pat) {
            throw "GitHub PAT not configured. Use Set-GitHubPAT first."
        }
    }
    
    process {
        try {
            # Build protection configuration
            $protectionConfig = @{
                required_status_checks = if ($RequiredStatusChecks.Count -gt 0) {
                    @{
                        strict = $StrictStatusChecks.IsPresent
                        contexts = $RequiredStatusChecks
                    }
                } else { $null }
                
                enforce_admins = $EnforceAdmins.IsPresent
                
                required_pull_request_reviews = @{
                    required_approving_review_count = $RequiredReviews
                    dismiss_stale_reviews = $DismissStaleReviews.IsPresent
                    require_code_owner_reviews = $RequireCodeOwnerReviews.IsPresent
                    require_last_push_approval = $false
                }
                
                restrictions = $null  # Allow all users/teams by default
                
                allow_force_pushes = $AllowForcePushes.IsPresent
                allow_deletions = $AllowDeletions.IsPresent
                required_linear_history = $RequireLinearHistory.IsPresent
                required_conversation_resolution = $RequireConversationResolution.IsPresent
                lock_branch = $false
            }
            
            # Remove null values to avoid API issues
            $cleanConfig = @{}
            foreach ($key in $protectionConfig.Keys) {
                if ($null -ne $protectionConfig[$key]) {
                    $cleanConfig[$key] = $protectionConfig[$key]
                }
            }
            
            $apiUrl = "https://api.github.com/repos/$Owner/$Repository/branches/$Branch/protection"
            
            Write-Verbose "Configuring branch protection with settings: $(($cleanConfig | ConvertTo-Json -Depth 3 -Compress))"
            
            if ($PSCmdlet.ShouldProcess("$Owner/$Repository branch '$Branch'", "Set branch protection")) {
                $response = Invoke-GitHubAPIWithRetry -Uri $apiUrl -Method 'PUT' -Body $cleanConfig
                
                Write-Verbose "Branch protection configured successfully"
                return @{
                    Success = $true
                    Owner = $Owner
                    Repository = $Repository
                    Branch = $Branch
                    Configuration = $cleanConfig
                    Response = $response
                }
            }
        }
        catch {
            Write-Error "Failed to set branch protection for $Owner/$Repository branch '$Branch': $($_.Exception.Message)"
            return @{
                Success = $false
                Owner = $Owner
                Repository = $Repository
                Branch = $Branch
                Error = $_.Exception.Message
            }
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDC0horhlATyRpt
# wboTZxAu5Hvt56/kKrs2/YuyWGrRX6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKnRxCER2swekWklSDgQGOxn
# 9dxhZb0sZeQVSMliWsXuMA0GCSqGSIb3DQEBAQUABIIBAGJHln0InmX3Ot6GAQHw
# RqbyAOjahVrD3m0iM80rwPUEG3dmPLqbf+hSEefAp6zJrNMZoTa9LPlTVYDWOVul
# I8xtSKnTOqB7YvD9pOEdKR4/4ATnp5GnJ/5mSVyqd9u5aytsxDIojv/BFeMt0Wau
# 2fiAPRuehWYgYXZvVgYcOV8q43/iz9hdAaahiNOEJejO50+QSavDDg3huofjImob
# GyDbkCv3oWaOqd1oFRMG0Kipylbrbtiy/+A8trOxYC6HxMesEOuBzZqOPXHORtfR
# 74ZJw6CyMIBSJHu6iYsg/fFK+IX/W61mNaeZ/CYWbG1RDFJ2YTeuqRj6uULZa3Vr
# HIc=
# SIG # End signature block
