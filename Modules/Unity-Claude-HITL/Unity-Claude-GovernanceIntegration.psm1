# Unity-Claude-GovernanceIntegration.psm1
# HITL Integration with GitHub Governance
# Extends HITL workflows with GitHub branch protection and CODEOWNERS enforcement

#region GitHub Governance Integration Functions

function Test-GitHubGovernanceCompliance {
    <#
    .SYNOPSIS
        Tests if proposed changes comply with GitHub governance policies.
    
    .DESCRIPTION
        Validates proposed changes against branch protection rules, CODEOWNERS requirements,
        and other governance policies before allowing workflow continuation.
    
    .PARAMETER Owner
        Repository owner (username or organization name).
    
    .PARAMETER Repository
        Repository name.
    
    .PARAMETER Branch
        Target branch for the changes.
    
    .PARAMETER ChangedFiles
        Array of file paths that will be modified.
    
    .PARAMETER ChangeType
        Type of change (Documentation, Code, Config, Critical).
    
    .PARAMETER RequesterUsername
        GitHub username of the person requesting the change.
    
    .EXAMPLE
        Test-GitHubGovernanceCompliance -Owner "myorg" -Repository "myrepo" -Branch "main" -ChangedFiles @("README.md", "src/app.js")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Owner,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [Parameter(Mandatory = $true)]
        [string]$Branch,
        
        [Parameter(Mandatory = $true)]
        [string[]]$ChangedFiles,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Documentation", "Code", "Config", "Critical")]
        [string]$ChangeType = "Code",
        
        [Parameter(Mandatory = $false)]
        [string]$RequesterUsername
    )
    
    begin {
        Write-Verbose "Starting GitHub governance compliance check for $Owner/$Repository"
    }
    
    process {
        try {
            $complianceResult = @{
                Success = $true
                Owner = $Owner
                Repository = $Repository
                Branch = $Branch
                ChangedFiles = $ChangedFiles
                ChangeType = $ChangeType
                RequesterUsername = $RequesterUsername
                GovernanceChecks = @{}
                RequiredApprovals = @()
                PolicyViolations = @()
                Recommendations = @()
            }
            
            # Check 1: Branch Protection Rules
            Write-Verbose "Checking branch protection rules..."
            $branchProtection = Get-GitHubBranchProtection -Owner $Owner -Repository $Repository -Branch $Branch
            
            if ($branchProtection.Success -and $branchProtection.IsProtected) {
                $complianceResult.GovernanceChecks["BranchProtection"] = @{
                    Enabled = $true
                    RequiredReviews = $branchProtection.Summary.RequiredReviews
                    CodeOwnerReviews = $branchProtection.Summary.CodeOwnerReviews
                    StatusChecks = $branchProtection.Summary.StatusChecksRequired
                    AdminsEnforced = $branchProtection.Summary.AdminsEnforced
                }
                
                # Add required approvals based on branch protection
                if ($branchProtection.Summary.RequiredReviews -gt 0) {
                    $complianceResult.RequiredApprovals += @{
                        Type = "PeerReview"
                        Count = $branchProtection.Summary.RequiredReviews
                        Reason = "Branch protection requires $($branchProtection.Summary.RequiredReviews) approving review(s)"
                    }
                }
                
                if ($branchProtection.Summary.CodeOwnerReviews) {
                    $complianceResult.RequiredApprovals += @{
                        Type = "CodeOwnerReview"
                        Count = 1
                        Reason = "Branch protection requires code owner approval"
                    }
                }
            } else {
                $complianceResult.GovernanceChecks["BranchProtection"] = @{
                    Enabled = $false
                    RequiredReviews = 0
                    CodeOwnerReviews = $false
                }
                
                $complianceResult.Recommendations += "Consider enabling branch protection for '$Branch' branch"
            }
            
            # Check 2: CODEOWNERS Analysis
            Write-Verbose "Analyzing CODEOWNERS requirements..."
            $codeownersCheck = Get-CodeOwnersRequirements -Owner $Owner -Repository $Repository -ChangedFiles $ChangedFiles
            
            if ($codeownersCheck.Success) {
                $complianceResult.GovernanceChecks["CodeOwners"] = $codeownersCheck
                
                if ($codeownersCheck.RequiredOwners.Count -gt 0) {
                    $complianceResult.RequiredApprovals += @{
                        Type = "CodeOwnerApproval"
                        Owners = $codeownersCheck.RequiredOwners
                        Files = $codeownersCheck.AffectedFiles
                        Reason = "CODEOWNERS file specifies approval requirements for modified files"
                    }
                }
            }
            
            # Check 3: Change Type Risk Assessment
            Write-Verbose "Assessing change type risk level..."
            $riskAssessment = Get-ChangeRiskAssessment -ChangeType $ChangeType -ChangedFiles $ChangedFiles -Branch $Branch
            
            $complianceResult.GovernanceChecks["RiskAssessment"] = $riskAssessment
            
            if ($riskAssessment.RiskLevel -eq "High" -or $riskAssessment.RiskLevel -eq "Critical") {
                $complianceResult.RequiredApprovals += @{
                    Type = "AdditionalReview"
                    Count = 1
                    Reason = "$($riskAssessment.RiskLevel) risk changes require additional oversight"
                }
            }
            
            # Check 4: Policy Violations
            Write-Verbose "Checking for policy violations..."
            $violations = Test-GovernancePolicyViolations -ChangedFiles $ChangedFiles -ChangeType $ChangeType -RequesterUsername $RequesterUsername
            
            if ($violations.Count -gt 0) {
                $complianceResult.PolicyViolations = $violations
                $complianceResult.Success = $false
            }
            
            # Generate final compliance status
            $complianceResult.RequiresApproval = $complianceResult.RequiredApprovals.Count -gt 0
            $complianceResult.TotalApprovals = ($complianceResult.RequiredApprovals | Measure-Object -Property Count -Sum).Sum
            
            Write-Verbose "Governance compliance check completed. Requires approval: $($complianceResult.RequiresApproval)"
            return $complianceResult
        }
        catch {
            Write-Error "Failed to check GitHub governance compliance: $($_.Exception.Message)"
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

function New-GovernanceAwareApprovalRequest {
    <#
    .SYNOPSIS
        Creates an approval request that integrates with GitHub governance policies.
    
    .DESCRIPTION
        Extends the standard HITL approval request with GitHub governance context,
        including required reviewers, policy compliance, and approval routing.
    
    .PARAMETER WorkflowId
        Unique identifier for the workflow requiring approval.
    
    .PARAMETER Title
        Title of the approval request.
    
    .PARAMETER Description
        Detailed description of the changes requiring approval.
    
    .PARAMETER GitHubContext
        Hashtable containing GitHub repository context (Owner, Repository, Branch, etc.).
    
    .PARAMETER ChangedFiles
        Array of file paths that will be modified.
    
    .PARAMETER ChangeType
        Type of change (Documentation, Code, Config, Critical).
    
    .PARAMETER RequesterEmail
        Email address of the person requesting approval.
    
    .EXAMPLE
        $context = @{ Owner = "myorg"; Repository = "myrepo"; Branch = "main" }
        New-GovernanceAwareApprovalRequest -WorkflowId "doc-update-001" -Title "Update API documentation" -GitHubContext $context -ChangedFiles @("docs/api.md")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$WorkflowId,
        
        [Parameter(Mandatory = $true)]
        [string]$Title,
        
        [Parameter(Mandatory = $true)]
        [string]$Description,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$GitHubContext,
        
        [Parameter(Mandatory = $true)]
        [string[]]$ChangedFiles,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Documentation", "Code", "Config", "Critical")]
        [string]$ChangeType = "Code",
        
        [Parameter(Mandatory = $false)]
        [string]$RequesterEmail
    )
    
    begin {
        Write-Verbose "Creating governance-aware approval request for workflow: $WorkflowId"
    }
    
    process {
        try {
            # First, check governance compliance
            $complianceCheck = Test-GitHubGovernanceCompliance -Owner $GitHubContext.Owner -Repository $GitHubContext.Repository -Branch $GitHubContext.Branch -ChangedFiles $ChangedFiles -ChangeType $ChangeType -RequesterUsername $GitHubContext.RequesterUsername
            
            if (-not $complianceCheck.Success) {
                throw "Governance compliance check failed: $(($complianceCheck.PolicyViolations | ForEach-Object { $_.Message }) -join ', ')"
            }
            
            # Create enhanced approval request context
            $enhancedDescription = @"
$Description

## GitHub Governance Context
**Repository**: $($GitHubContext.Owner)/$($GitHubContext.Repository)
**Branch**: $($GitHubContext.Branch)
**Change Type**: $ChangeType
**Files Modified**: $($ChangedFiles.Count) file(s)

### Modified Files:
$(($ChangedFiles | ForEach-Object { "- $_" }) -join "`n")

### Required Approvals:
$(if ($complianceCheck.RequiredApprovals.Count -gt 0) {
    ($complianceCheck.RequiredApprovals | ForEach-Object { 
        "- $($_.Type): $($_.Reason)" 
    }) -join "`n"
} else {
    "- No specific approval requirements"
})

### Governance Compliance:
- **Branch Protection**: $(if ($complianceCheck.GovernanceChecks.BranchProtection.Enabled) { "✅ Enabled" } else { "❌ Not enabled" })
- **Required Reviews**: $($complianceCheck.GovernanceChecks.BranchProtection.RequiredReviews)
- **Code Owner Reviews**: $(if ($complianceCheck.GovernanceChecks.BranchProtection.CodeOwnerReviews) { "✅ Required" } else { "❌ Not required" })
- **Risk Level**: $($complianceCheck.GovernanceChecks.RiskAssessment.RiskLevel)

$(if ($complianceCheck.Recommendations.Count -gt 0) {
"### Recommendations:
$(($complianceCheck.Recommendations | ForEach-Object { "- $_" }) -join "`n")"
})
"@

            # Create the approval request using the base HITL function
            $approvalRequest = New-ApprovalRequest -WorkflowId $WorkflowId -Title $Title -Description $enhancedDescription -RequestType $ChangeType -RequesterEmail $RequesterEmail
            
            if ($approvalRequest.Success) {
                # Enhance the approval request with governance metadata
                $approvalRequest.GovernanceContext = $complianceCheck
                $approvalRequest.GitHubContext = $GitHubContext
                $approvalRequest.RequiredApprovals = $complianceCheck.RequiredApprovals
                $approvalRequest.EstimatedApprovers = $complianceCheck.TotalApprovals
                
                Write-Verbose "Governance-aware approval request created successfully"
            }
            
            return $approvalRequest
        }
        catch {
            Write-Error "Failed to create governance-aware approval request: $($_.Exception.Message)"
            return @{
                Success = $false
                WorkflowId = $WorkflowId
                Error = $_.Exception.Message
            }
        }
    }
}

function Wait-GovernanceApproval {
    <#
    .SYNOPSIS
        Waits for governance-compliant approval with GitHub integration.
    
    .DESCRIPTION
        Extends the standard HITL wait functionality to include GitHub governance
        validation and can optionally create GitHub PR review requests.
    
    .PARAMETER ApprovalId
        Unique identifier for the approval request.
    
    .PARAMETER CreateGitHubReview
        Create a GitHub PR review request in addition to HITL approval.
    
    .PARAMETER TimeoutMinutes
        Timeout in minutes for the approval wait.
    
    .PARAMETER EscalationEnabled
        Enable automatic escalation if approval times out.
    
    .EXAMPLE
        Wait-GovernanceApproval -ApprovalId "approval-001" -CreateGitHubReview -TimeoutMinutes 60
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ApprovalId,
        
        [Parameter(Mandatory = $false)]
        [switch]$CreateGitHubReview,
        
        [Parameter(Mandatory = $false)]
        [int]$TimeoutMinutes = 1440, # 24 hours default
        
        [Parameter(Mandatory = $false)]
        [switch]$EscalationEnabled
    )
    
    begin {
        Write-Verbose "Starting governance-aware approval wait for: $ApprovalId"
    }
    
    process {
        try {
            # Get approval request details
            $approvalStatus = Get-ApprovalStatus -ApprovalId $ApprovalId
            
            if (-not $approvalStatus.Success) {
                throw "Could not retrieve approval request: $($approvalStatus.Error)"
            }
            
            # If GitHub review requested, create PR review request
            if ($CreateGitHubReview -and $approvalStatus.GitHubContext) {
                Write-Verbose "Creating GitHub PR review request..."
                $prReview = New-GitHubPRReviewRequest -ApprovalContext $approvalStatus
                
                if ($prReview.Success) {
                    Write-Verbose "GitHub PR review request created: $($prReview.ReviewUrl)"
                } else {
                    Write-Warning "Failed to create GitHub PR review: $($prReview.Error)"
                }
            }
            
            # Wait for approval using base HITL functionality
            $approvalResult = Wait-HumanApproval -ApprovalId $ApprovalId -TimeoutMinutes $TimeoutMinutes
            
            # Validate governance compliance in approval result
            if ($approvalResult.Success -and $approvalResult.Status -eq "approved") {
                Write-Verbose "Validating governance compliance in approval..."
                
                # Check if required approvals were met
                $governanceValidation = Test-ApprovalGovernanceCompliance -ApprovalResult $approvalResult
                
                if (-not $governanceValidation.Success) {
                    Write-Warning "Governance compliance validation failed: $($governanceValidation.Error)"
                    $approvalResult.GovernanceCompliant = $false
                    $approvalResult.GovernanceIssues = $governanceValidation.Issues
                } else {
                    $approvalResult.GovernanceCompliant = $true
                }
            }
            
            return $approvalResult
        }
        catch {
            Write-Error "Failed to wait for governance approval: $($_.Exception.Message)"
            return @{
                Success = $false
                ApprovalId = $ApprovalId
                Error = $_.Exception.Message
            }
        }
    }
}

#endregion

#region Helper Functions

function Get-CodeOwnersRequirements {
    [CmdletBinding()]
    param(
        [string]$Owner,
        [string]$Repository,
        [string[]]$ChangedFiles
    )
    
    try {
        # This would normally parse the CODEOWNERS file from GitHub API
        # For now, return a simplified response based on file patterns
        $requiredOwners = @()
        $affectedFiles = @()
        
        foreach ($file in $ChangedFiles) {
            # Simplified CODEOWNERS pattern matching
            switch -Regex ($file) {
                "\.ps1$|\.psm1$|\.psd1$" { $requiredOwners += "@unity-claude/powershell-team"; $affectedFiles += $file }
                "\.md$" { $requiredOwners += "@unity-claude/docs-team"; $affectedFiles += $file }
                "^\.github/" { $requiredOwners += "@unity-claude/devops-team"; $affectedFiles += $file }
                "^Modules/" { $requiredOwners += "@unity-claude/dev-team"; $affectedFiles += $file }
                "test" { $requiredOwners += "@unity-claude/qa-team"; $affectedFiles += $file }
            }
        }
        
        return @{
            Success = $true
            RequiredOwners = ($requiredOwners | Sort-Object | Get-Unique)
            AffectedFiles = $affectedFiles
            TotalFiles = $ChangedFiles.Count
        }
    }
    catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Get-ChangeRiskAssessment {
    [CmdletBinding()]
    param(
        [string]$ChangeType,
        [string[]]$ChangedFiles,
        [string]$Branch
    )
    
    $riskLevel = "Low"
    $riskFactors = @()
    
    # Assess risk based on change type
    switch ($ChangeType) {
        "Critical" { $riskLevel = "Critical"; $riskFactors += "Critical change type" }
        "Code" { $riskLevel = "Medium"; $riskFactors += "Code changes" }
        "Config" { $riskLevel = "Medium"; $riskFactors += "Configuration changes" }
        "Documentation" { $riskLevel = "Low"; $riskFactors += "Documentation changes" }
    }
    
    # Assess risk based on files
    $criticalFiles = $ChangedFiles | Where-Object { 
        $_ -match "\.github/workflows/" -or 
        $_ -match "security" -or 
        $_ -match "auth" -or
        $_ -match "credential"
    }
    
    if ($criticalFiles.Count -gt 0) {
        $riskLevel = "High"
        $riskFactors += "Critical system files modified"
    }
    
    # Assess risk based on branch
    if ($Branch -eq "main" -or $Branch -eq "master" -or $Branch -eq "production") {
        if ($riskLevel -eq "Low") { $riskLevel = "Medium" }
        $riskFactors += "Changes to primary branch"
    }
    
    return @{
        RiskLevel = $riskLevel
        RiskFactors = $riskFactors
        FilesCount = $ChangedFiles.Count
        CriticalFiles = $criticalFiles.Count
    }
}

function Test-GovernancePolicyViolations {
    [CmdletBinding()]
    param(
        [string[]]$ChangedFiles,
        [string]$ChangeType,
        [string]$RequesterUsername
    )
    
    $violations = @()
    
    # Check for sensitive file modifications
    $sensitiveFiles = $ChangedFiles | Where-Object { 
        $_ -match "secret" -or 
        $_ -match "password" -or 
        $_ -match "\.key$" -or
        $_ -match "\.pem$"
    }
    
    if ($sensitiveFiles.Count -gt 0) {
        $violations += @{
            Type = "SensitiveFileModification"
            Message = "Sensitive files detected: $(($sensitiveFiles -join ', '))"
            Severity = "High"
        }
    }
    
    return $violations
}

function Test-ApprovalGovernanceCompliance {
    [CmdletBinding()]
    param(
        [hashtable]$ApprovalResult
    )
    
    # Simplified governance compliance check
    # In a real implementation, this would validate against actual GitHub PR approvals
    
    return @{
        Success = $true
        Issues = @()
        ComplianceScore = 100
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Test-GitHubGovernanceCompliance',
    'New-GovernanceAwareApprovalRequest', 
    'Wait-GovernanceApproval'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAv7Ea4jeCpHHlp
# JQyZhSoJG+1ziYnEVvC3cY7ZKD+rAKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIA+WwmxjCq5L7rvQLWFZmzPZ
# Q8ItTdPmxYR5E2U8T5a4MA0GCSqGSIb3DQEBAQUABIIBAB2k2WaiHqrJtqDKxppy
# L1Ea5xieGmIjzfqkbYdaaX8Y0TXd3VeNeyg3o2i+xFluycOUiYw5uBNcg/1HClQF
# sUVvobn17d2HnphQGTjbH4yjpc+h5c7JqfPq0ng26p4PQTQF9q8hGMxUUN8FOQgr
# +NA69ZzOa2EwdkRhiGvv5A1Adp3F7WMsHiIP/C/kiVjgD+X3loetD3F9uh+01YfE
# M0wh68NuRAEFih1vjpZ2GfwuLM9xFiAosBCucsBNZJZ0QVO88onHe2IwCuJBHe3y
# mEDFATVe8Ig1budU2f+QXTYINHNIllHw0sDyMbfv9zFJnTQkpXSvjW/T/ECilJRb
# VzM=
# SIG # End signature block
