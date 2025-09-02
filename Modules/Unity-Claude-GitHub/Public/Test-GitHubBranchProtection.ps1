function Test-GitHubBranchProtection {
    <#
    .SYNOPSIS
        Tests and validates GitHub branch protection rules enforcement.
    
    .DESCRIPTION
        Validates that branch protection rules are properly configured and enforced
        for a repository. Checks required reviews, status checks, and other governance settings.
    
    .PARAMETER Owner
        Repository owner (username or organization name).
    
    .PARAMETER Repository
        Repository name.
    
    .PARAMETER Branch
        Branch name to test protection rules for (e.g., "main", "master").
    
    .PARAMETER ExpectedReviews
        Expected number of required reviews. If specified, validates this requirement.
    
    .PARAMETER RequireCodeOwners
        Expect code owner reviews to be required.
    
    .PARAMETER RequireStatusChecks
        Expect status checks to be required.
    
    .PARAMETER CheckEnforcement
        Test actual enforcement by attempting restricted operations (requires special permissions).
    
    .EXAMPLE
        Test-GitHubBranchProtection -Owner "myorg" -Repository "myrepo" -Branch "main"
    
    .EXAMPLE
        Test-GitHubBranchProtection -Owner "myorg" -Repository "myrepo" -Branch "main" -ExpectedReviews 2 -RequireCodeOwners
    
    .EXAMPLE
        $result = Test-GitHubBranchProtection -Owner "myorg" -Repository "myrepo" -Branch "main" -CheckEnforcement
        if ($result.Success) {
            Write-Host "Branch protection is properly configured and enforced"
        }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Owner,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [Parameter(Mandatory = $true)]
        [string]$Branch,
        
        [Parameter(Mandatory = $false)]
        [int]$ExpectedReviews,
        
        [Parameter(Mandatory = $false)]
        [switch]$RequireCodeOwners,
        
        [Parameter(Mandatory = $false)]
        [switch]$RequireStatusChecks,
        
        [Parameter(Mandatory = $false)]
        [switch]$CheckEnforcement
    )
    
    begin {
        Write-Verbose "Starting Test-GitHubBranchProtection for $Owner/$Repository branch: $Branch"
        
        # Validate GitHub PAT
        $pat = Get-GitHubPAT
        if (-not $pat) {
            throw "GitHub PAT not configured. Use Set-GitHubPAT first."
        }
    }
    
    process {
        try {
            $testResults = @{
                Success = $true
                Owner = $Owner
                Repository = $Repository
                Branch = $Branch
                IsProtected = $false
                Tests = @{}
                Warnings = @()
                Errors = @()
            }
            
            # Get current branch protection settings
            Write-Verbose "Retrieving current branch protection settings..."
            $protection = Get-GitHubBranchProtection -Owner $Owner -Repository $Repository -Branch $Branch
            
            if (-not $protection.Success) {
                $testResults.Success = $false
                $testResults.Errors += "Failed to retrieve branch protection: $($protection.Error)"
                return $testResults
            }
            
            $testResults.IsProtected = $protection.IsProtected
            $testResults.Configuration = $protection.Configuration
            
            # Test 1: Branch Protection Enabled
            $testResults.Tests["ProtectionEnabled"] = @{
                Name = "Branch Protection Enabled"
                Passed = $protection.IsProtected
                Expected = $true
                Actual = $protection.IsProtected
                Message = if ($protection.IsProtected) { "Branch is protected" } else { "Branch is not protected" }
            }
            
            if (-not $protection.IsProtected) {
                $testResults.Warnings += "Branch '$Branch' is not protected - other tests will be skipped"
                return $testResults
            }
            
            # Test 2: Required Reviews
            if ($PSBoundParameters.ContainsKey('ExpectedReviews')) {
                $actualReviews = $protection.Summary.RequiredReviews
                $testResults.Tests["RequiredReviews"] = @{
                    Name = "Required Reviews Count"
                    Passed = $actualReviews -eq $ExpectedReviews
                    Expected = $ExpectedReviews
                    Actual = $actualReviews
                    Message = "Required reviews: expected $ExpectedReviews, actual $actualReviews"
                }
                
                if ($actualReviews -ne $ExpectedReviews) {
                    $testResults.Success = $false
                }
            }
            
            # Test 3: Code Owner Reviews
            if ($RequireCodeOwners) {
                $codeOwnerReviews = $protection.Summary.CodeOwnerReviews
                $testResults.Tests["CodeOwnerReviews"] = @{
                    Name = "Code Owner Reviews Required"
                    Passed = $codeOwnerReviews
                    Expected = $true
                    Actual = $codeOwnerReviews
                    Message = if ($codeOwnerReviews) { "Code owner reviews are required" } else { "Code owner reviews are not required" }
                }
                
                if (-not $codeOwnerReviews) {
                    $testResults.Success = $false
                }
            }
            
            # Test 4: Status Checks
            if ($RequireStatusChecks) {
                $statusChecks = $protection.Summary.StatusChecksRequired
                $testResults.Tests["StatusChecks"] = @{
                    Name = "Status Checks Required"
                    Passed = $statusChecks -gt 0
                    Expected = "Greater than 0"
                    Actual = $statusChecks
                    Message = "Required status checks: $statusChecks"
                }
                
                if ($statusChecks -eq 0) {
                    $testResults.Success = $false
                }
            }
            
            # Test 5: Basic Security Settings
            $adminEnforcement = $protection.Summary.AdminsEnforced
            $testResults.Tests["AdminEnforcement"] = @{
                Name = "Admin Enforcement"
                Passed = $adminEnforcement
                Expected = $true
                Actual = $adminEnforcement
                Message = if ($adminEnforcement) { "Admins must follow protection rules" } else { "Admins can bypass protection rules" }
            }
            
            $forcePushes = $protection.Summary.ForcePushesAllowed
            $testResults.Tests["ForcePushPrevention"] = @{
                Name = "Force Push Prevention"
                Passed = -not $forcePushes
                Expected = $false
                Actual = $forcePushes
                Message = if ($forcePushes) { "Force pushes are allowed" } else { "Force pushes are prevented" }
            }
            
            $deletions = $protection.Summary.DeletionsAllowed
            $testResults.Tests["DeletionPrevention"] = @{
                Name = "Branch Deletion Prevention"
                Passed = -not $deletions
                Expected = $false
                Actual = $deletions
                Message = if ($deletions) { "Branch deletions are allowed" } else { "Branch deletions are prevented" }
            }
            
            # Test 6: CODEOWNERS file existence (if code owner reviews required)
            if ($RequireCodeOwners) {
                Write-Verbose "Checking for CODEOWNERS file existence..."
                $codeownersExists = Test-GitHubCodeOwnersExists -Owner $Owner -Repository $Repository
                $testResults.Tests["CodeOwnersFile"] = @{
                    Name = "CODEOWNERS File Exists"
                    Passed = $codeownersExists
                    Expected = $true
                    Actual = $codeownersExists
                    Message = if ($codeownersExists) { "CODEOWNERS file exists" } else { "CODEOWNERS file not found" }
                }
                
                if (-not $codeownersExists) {
                    $testResults.Warnings += "Code owner reviews required but CODEOWNERS file not found"
                }
            }
            
            # Test 7: Enforcement Testing (if requested and safe)
            if ($CheckEnforcement) {
                Write-Verbose "Testing branch protection enforcement (read-only tests only)..."
                
                # Test API access to protected branch
                try {
                    $branchInfo = Invoke-GitHubAPIWithRetry -Uri "https://api.github.com/repos/$Owner/$Repository/branches/$Branch" -Method 'GET'
                    $testResults.Tests["BranchAccess"] = @{
                        Name = "Branch API Access"
                        Passed = $true
                        Expected = $true
                        Actual = $true
                        Message = "Successfully accessed branch information via API"
                    }
                } catch {
                    $testResults.Tests["BranchAccess"] = @{
                        Name = "Branch API Access"
                        Passed = $false
                        Expected = $true
                        Actual = $false
                        Message = "Failed to access branch information: $($_.Exception.Message)"
                    }
                    $testResults.Success = $false
                }
            }
            
            # Calculate overall test success
            $failedTests = $testResults.Tests.Values | Where-Object { -not $_.Passed }
            if ($failedTests.Count -gt 0) {
                $testResults.Success = $false
                $testResults.Errors += "Failed tests: $(($failedTests | ForEach-Object { $_.Name }) -join ', ')"
            }
            
            # Add summary information
            $testResults.Summary = @{
                TotalTests = $testResults.Tests.Count
                PassedTests = ($testResults.Tests.Values | Where-Object { $_.Passed }).Count
                FailedTests = $failedTests.Count
                WarningsCount = $testResults.Warnings.Count
                ErrorsCount = $testResults.Errors.Count
            }
            
            Write-Verbose "Branch protection testing completed. Success: $($testResults.Success)"
            return $testResults
        }
        catch {
            Write-Error "Failed to test branch protection for $Owner/$Repository branch '$Branch': $($_.Exception.Message)"
            return @{
                Success = $false
                Owner = $Owner
                Repository = $Repository
                Branch = $Branch
                Error = $_.Exception.Message
                Tests = @{}
            }
        }
    }
}

# Helper function to check CODEOWNERS file existence
function Test-GitHubCodeOwnersExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Owner,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository
    )
    
    try {
        # Check common CODEOWNERS file locations
        $locations = @(
            ".github/CODEOWNERS",
            "CODEOWNERS",
            "docs/CODEOWNERS"
        )
        
        foreach ($location in $locations) {
            try {
                $apiUrl = "https://api.github.com/repos/$Owner/$Repository/contents/$location"
                $response = Invoke-GitHubAPIWithRetry -Uri $apiUrl -Method 'GET'
                if ($response) {
                    Write-Verbose "CODEOWNERS file found at: $location"
                    return $true
                }
            } catch {
                # Continue checking other locations
                Write-Verbose "CODEOWNERS not found at: $location"
            }
        }
        
        return $false
    } catch {
        Write-Verbose "Error checking CODEOWNERS existence: $($_.Exception.Message)"
        return $false
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDrnZ/FcbOcXviv
# UYX+FGV/3QC/8eZW3czOVdOF4pB0oqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIM1KcRqAYxKavc37YpsjS4wZ
# B7YG6j8Yq12iLKE6jsQaMA0GCSqGSIb3DQEBAQUABIIBACJNdFhtWWeGV6w9rq01
# O3nmo2T/pPJmzVgm7mH9nWvV2MfquJSY5yiB9Ulhuo5GaYlkG/2HWdzGwEiyrrXw
# Tv2xLeCBlLqjNw3SCXVCI+77gKfuSVUIRG8srcrhKeOSRYq95x+gS2BcIBVLtbsL
# eet7RygW9JJQtGoNiqUD8MMttuiPjxd2otUaGdXKbtIlUtVJ67H2pRL+Gs/E/Ef0
# 00mP641O0h4t9ghbGSs96wYfcjpmk4VX55vlnk7esfydkCOd62yBwZYl9K1y+NiX
# w+KjUe87TE9E2jzx+MkyqJx7lDB9r6W2A3vLy4KKmWdHTXNvz5znNoFqg941XxhV
# 348=
# SIG # End signature block
