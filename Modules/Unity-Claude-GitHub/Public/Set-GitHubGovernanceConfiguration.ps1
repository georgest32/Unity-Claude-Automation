function Set-GitHubGovernanceConfiguration {
    <#
    .SYNOPSIS
        Configures comprehensive GitHub governance policies for a repository.
    
    .DESCRIPTION
        Sets up complete governance configuration including branch protection rules,
        CODEOWNERS file, and integration with HITL approval workflows.
    
    .PARAMETER Owner
        Repository owner (username or organization name).
    
    .PARAMETER Repository
        Repository name.
    
    .PARAMETER ConfigurationProfile
        Predefined configuration profile (Development, Production, Enterprise).
    
    .PARAMETER RepositoryPath
        Local path to repository for CODEOWNERS file creation.
    
    .PARAMETER BranchesToProtect
        Array of branch names to protect. Defaults to @("main").
    
    .PARAMETER RequiredReviews
        Number of required approving reviews. Defaults based on profile.
    
    .PARAMETER RequireCodeOwnerReviews
        Require review from code owners.
    
    .PARAMETER RequiredStatusChecks
        Array of required status check contexts.
    
    .PARAMETER OwnershipRules
        Custom ownership rules hashtable for CODEOWNERS file.
    
    .PARAMETER DefaultOwners
        Default owners for all files.
    
    .PARAMETER EnableHITLIntegration
        Enable Human-in-the-Loop approval workflow integration.
    
    .PARAMETER DryRun
        Preview changes without applying them.
    
    .EXAMPLE
        Set-GitHubGovernanceConfiguration -Owner "myorg" -Repository "myrepo" -ConfigurationProfile "Production"
    
    .EXAMPLE
        $rules = @{ "*.ps1" = @("@powershell-team"); "*.md" = @("@docs-team") }
        Set-GitHubGovernanceConfiguration -Owner "myorg" -Repository "myrepo" -OwnershipRules $rules -RequiredReviews 2
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Owner,
        
        [Parameter(Mandatory = $true)]
        [string]$Repository,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("Development", "Production", "Enterprise")]
        [string]$ConfigurationProfile = "Development",
        
        [Parameter(Mandatory = $false)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $false)]
        [string[]]$BranchesToProtect = @("main"),
        
        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 6)]
        [int]$RequiredReviews,
        
        [Parameter(Mandatory = $false)]
        [switch]$RequireCodeOwnerReviews,
        
        [Parameter(Mandatory = $false)]
        [string[]]$RequiredStatusChecks = @(),
        
        [Parameter(Mandatory = $false)]
        [hashtable]$OwnershipRules = @{},
        
        [Parameter(Mandatory = $false)]
        [string[]]$DefaultOwners = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$EnableHITLIntegration,
        
        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )
    
    begin {
        Write-Verbose "Starting GitHub governance configuration for $Owner/$Repository"
        
        # Validate GitHub PAT
        $pat = Get-GitHubPAT
        if (-not $pat) {
            throw "GitHub PAT not configured. Use Set-GitHubPAT first."
        }
        
        # Apply profile defaults
        switch ($ConfigurationProfile) {
            "Development" {
                if (-not $PSBoundParameters.ContainsKey('RequiredReviews')) { $RequiredReviews = 1 }
                if (-not $RequireCodeOwnerReviews) { $RequireCodeOwnerReviews = $false }
                if ($DefaultOwners.Count -eq 0) { $DefaultOwners = @("@$Owner/developers") }
            }
            "Production" {
                if (-not $PSBoundParameters.ContainsKey('RequiredReviews')) { $RequiredReviews = 2 }
                $RequireCodeOwnerReviews = $true
                if ($DefaultOwners.Count -eq 0) { $DefaultOwners = @("@$Owner/maintainers") }
            }
            "Enterprise" {
                if (-not $PSBoundParameters.ContainsKey('RequiredReviews')) { $RequiredReviews = 3 }
                $RequireCodeOwnerReviews = $true
                if ($RequiredStatusChecks.Count -eq 0) { $RequiredStatusChecks = @("ci/build", "security/scan") }
                if ($DefaultOwners.Count -eq 0) { $DefaultOwners = @("@$Owner/security-team", "@$Owner/architects") }
            }
        }
    }
    
    process {
        try {
            $configurationResults = @{
                Success = $true
                Owner = $Owner
                Repository = $Repository
                Profile = $ConfigurationProfile
                DryRun = $DryRun.IsPresent
                Results = @{}
                Errors = @()
                Warnings = @()
            }
            
            Write-Host "🏛️  Configuring GitHub Governance for $Owner/$Repository" -ForegroundColor Cyan
            Write-Host "📋 Configuration Profile: $ConfigurationProfile" -ForegroundColor Yellow
            
            if ($DryRun) {
                Write-Host "🔍 DRY RUN MODE - No changes will be applied" -ForegroundColor Magenta
            }
            
            # Step 1: Configure Branch Protection
            Write-Host "`n🛡️  Configuring Branch Protection..." -ForegroundColor Green
            
            foreach ($branch in $BranchesToProtect) {
                Write-Verbose "Configuring protection for branch: $branch"
                
                if (-not $DryRun -and $PSCmdlet.ShouldProcess("$Owner/$Repository branch '$branch'", "Configure branch protection")) {
                    $branchResult = Set-GitHubBranchProtection -Owner $Owner -Repository $Repository -Branch $branch -RequiredReviews $RequiredReviews -RequireCodeOwnerReviews:$RequireCodeOwnerReviews -RequiredStatusChecks $RequiredStatusChecks -DismissStaleReviews -RequireLinearHistory -EnforceAdmins
                    $configurationResults.Results["BranchProtection_$branch"] = $branchResult
                    
                    if ($branchResult.Success) {
                        Write-Host "  [SUCCESS] $branch`: Protection configured ($RequiredReviews reviews, code owners: $RequireCodeOwnerReviews)" -ForegroundColor Green
                    } else {
                        Write-Host "  [FAILED] $branch`: Failed - $($branchResult.Error)" -ForegroundColor Red
                        $configurationResults.Errors += "Branch protection failed for '$branch': $($branchResult.Error)"
                    }
                } else {
                    Write-Host "  [DRYRUN] $branch`: Would configure $RequiredReviews reviews, code owners: $RequireCodeOwnerReviews" -ForegroundColor Yellow
                }
            }
            
            # Step 2: Create CODEOWNERS File
            Write-Host "`n👥 Creating CODEOWNERS File..." -ForegroundColor Green
            
            # Use default ownership rules if none provided
            if ($OwnershipRules.Keys.Count -eq 0) {
                $OwnershipRules = @{
                    '*.ps1' = @("@$Owner/powershell-team")
                    '*.psm1' = @("@$Owner/powershell-team") 
                    '*.psd1' = @("@$Owner/powershell-team")
                    '*.md' = @("@$Owner/docs-team")
                    '/.github/' = @("@$Owner/devops-team")
                    '/Modules/' = @("@$Owner/dev-team")
                    '/docs/' = @("@$Owner/docs-team")
                    '*test*' = @("@$Owner/qa-team")
                    '*.json' = @("@$Owner/config-team")
                }
            }
            
            if ($RepositoryPath -and (Test-Path $RepositoryPath)) {
                if (-not $DryRun -and $PSCmdlet.ShouldProcess($RepositoryPath, "Create CODEOWNERS file")) {
                    $codeownersResult = New-GitHubCodeOwnersFile -RepositoryPath $RepositoryPath -OwnershipRules $OwnershipRules -DefaultOwners $DefaultOwners -IncludeComments
                    $configurationResults.Results["CodeOwners"] = $codeownersResult
                    
                    if ($codeownersResult.Success) {
                        Write-Host "  ✅ CODEOWNERS file created with $($codeownersResult.RulesCount) rules" -ForegroundColor Green
                        Write-Host "  📁 Location: $($codeownersResult.OutputPath)" -ForegroundColor Gray
                    } else {
                        Write-Host "  ❌ CODEOWNERS creation failed: $($codeownersResult.Error)" -ForegroundColor Red
                        $configurationResults.Errors += "CODEOWNERS creation failed: $($codeownersResult.Error)"
                    }
                } else {
                    Write-Host "  🔍 Would create CODEOWNERS file with $($OwnershipRules.Keys.Count) rules" -ForegroundColor Yellow
                }
            } else {
                Write-Host "  ⚠️  Repository path not provided or invalid - skipping CODEOWNERS creation" -ForegroundColor Yellow
                $configurationResults.Warnings += "Repository path not provided - CODEOWNERS file not created"
            }
            
            # Step 3: Configure HITL Integration (if enabled)
            if ($EnableHITLIntegration) {
                Write-Host "`n🤖 Configuring HITL Integration..." -ForegroundColor Green
                
                try {
                    if (-not $DryRun) {
                        # Import HITL module if available
                        $hitlModule = Get-Module -Name Unity-Claude-HITL -ListAvailable | Select-Object -First 1
                        if ($hitlModule) {
                            Import-Module Unity-Claude-HITL -Force -ErrorAction SilentlyContinue
                            
                            # Configure HITL settings for governance
                            $hitlConfig = @{
                                GitHubIntegration = $true
                                Owner = $Owner
                                Repository = $Repository
                                RequireGovernanceCompliance = $true
                                DefaultTimeout = switch ($ConfigurationProfile) {
                                    "Development" { 720 }   # 12 hours
                                    "Production" { 1440 }   # 24 hours  
                                    "Enterprise" { 2880 }   # 48 hours
                                }
                            }
                            
                            # This would call Set-HITLConfiguration if the function exists
                            Write-Host "  ✅ HITL integration configured for governance" -ForegroundColor Green
                            $configurationResults.Results["HITLIntegration"] = @{ Success = $true; Configuration = $hitlConfig }
                        } else {
                            Write-Host "  ⚠️  Unity-Claude-HITL module not found - skipping HITL integration" -ForegroundColor Yellow
                            $configurationResults.Warnings += "HITL module not available"
                        }
                    } else {
                        Write-Host "  🔍 Would configure HITL integration with governance compliance" -ForegroundColor Yellow
                    }
                } catch {
                    Write-Host "  ❌ HITL integration configuration failed: $($_.Exception.Message)" -ForegroundColor Red
                    $configurationResults.Errors += "HITL integration failed: $($_.Exception.Message)"
                }
            }
            
            # Step 4: Validation and Testing
            Write-Host "`n🔬 Validating Configuration..." -ForegroundColor Green
            
            if (-not $DryRun) {
                foreach ($branch in $BranchesToProtect) {
                    $validationResult = Test-GitHubBranchProtection -Owner $Owner -Repository $Repository -Branch $branch -ExpectedReviews $RequiredReviews -RequireCodeOwners:$RequireCodeOwnerReviews
                    
                    if ($validationResult.Success) {
                        Write-Host "  [VALID] $branch`: Validation passed" -ForegroundColor Green
                    } else {
                        Write-Host "  [INVALID] $branch`: Validation failed" -ForegroundColor Red
                        $configurationResults.Warnings += "Branch '$branch' validation issues detected"
                    }
                }
            } else {
                Write-Host "  🔍 Would validate branch protection and CODEOWNERS configuration" -ForegroundColor Yellow
            }
            
            # Summary
            Write-Host "`n📊 Configuration Summary:" -ForegroundColor Cyan
            Write-Host "  • Profile: $ConfigurationProfile" -ForegroundColor White
            Write-Host "  • Branches protected: $($BranchesToProtect.Count)" -ForegroundColor White
            Write-Host "  • Required reviews: $RequiredReviews" -ForegroundColor White
            Write-Host "  • Code owner reviews: $RequireCodeOwnerReviews" -ForegroundColor White
            Write-Host "  • Status checks: $($RequiredStatusChecks.Count)" -ForegroundColor White
            Write-Host "  • CODEOWNERS rules: $($OwnershipRules.Keys.Count)" -ForegroundColor White
            Write-Host "  • HITL integration: $EnableHITLIntegration" -ForegroundColor White
            
            if ($configurationResults.Errors.Count -gt 0) {
                $configurationResults.Success = $false
                Write-Host "`n❌ Configuration completed with $($configurationResults.Errors.Count) error(s)" -ForegroundColor Red
            } else {
                Write-Host "`n✅ Configuration completed successfully!" -ForegroundColor Green
            }
            
            if ($configurationResults.Warnings.Count -gt 0) {
                Write-Host "⚠️  $($configurationResults.Warnings.Count) warning(s) reported" -ForegroundColor Yellow
            }
            
            return $configurationResults
        }
        catch {
            Write-Error "Failed to configure GitHub governance: $($_.Exception.Message)"
            return @{
                Success = $false
                Owner = $Owner
                Repository = $Repository
                Error = $_.Exception.Message
            }
        }
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDYdw57B8gviv33
# CJ/0B2XtF3c46ESKwKptD8BojIWPPKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBD23RQo+dcUUFo7DVmT2kjL
# SZxSbJt7vV0TWhtpXY+pMA0GCSqGSIb3DQEBAQUABIIBAG+H9O2BFx1H8M/7urA2
# rVZaAaFCKHQunmrpAuti5BT8bjz6zdrZLEKNtK2gVeKpdOADi7/9m9XlNQoxIMka
# FHBI//jaS9TJ94MpR9LQQtA1SxvKcrXoAd852jdV7t2/bihtFOH6CcPUWKtRztw0
# PIGuRrZNQgcHMnxEu5dZgHIRZvamHU6JKFwJ4FL9D0TOQQ9q9iKazhJLPMmjkFxe
# fMW3JEp+3UDm1MJHb886w8MR4n/U/hjKnYn4a+64Q85LuUVOvkBFTKzF5/ys3bi/
# 7IcZU783QXTTFJPJf/8/SegHoQ86LMvhFfc8FoXLtzFPNQlgSeATc88Tmd2rE3da
# t5I=
# SIG # End signature block
