function New-GitHubCodeOwnersFile {
    <#
    .SYNOPSIS
        Creates or updates a CODEOWNERS file for GitHub repository governance.
    
    .DESCRIPTION
        Generates a CODEOWNERS file based on repository structure analysis or provided
        ownership rules. Supports pattern matching and team/individual assignments.
    
    .PARAMETER RepositoryPath
        Local path to the repository root directory.
    
    .PARAMETER OutputPath
        Path where to create the CODEOWNERS file. Defaults to .github/CODEOWNERS.
    
    .PARAMETER OwnershipRules
        Hashtable of file patterns to owners. Format: @{ "pattern" = @("@owner1", "@org/team") }
    
    .PARAMETER DefaultOwners
        Default owners to assign to all files (fallback). Can be usernames or teams.
    
    .PARAMETER AnalyzeStructure
        Automatically analyze repository structure to suggest ownership patterns.
    
    .PARAMETER IncludeComments
        Include explanatory comments in the CODEOWNERS file.
    
    .PARAMETER Validate
        Validate CODEOWNERS syntax and ownership assignments.
    
    .EXAMPLE
        New-GitHubCodeOwnersFile -RepositoryPath "C:\MyRepo" -DefaultOwners @("@myorg/admin")
    
    .EXAMPLE
        $rules = @{
            "*.ps1" = @("@myorg/powershell-team")
            "*.md" = @("@myorg/docs-team")
            "/src/" = @("@myorg/dev-team")
            "/.github/" = @("@myorg/devops-team")
        }
        New-GitHubCodeOwnersFile -RepositoryPath "C:\MyRepo" -OwnershipRules $rules
    
    .EXAMPLE
        New-GitHubCodeOwnersFile -RepositoryPath "C:\MyRepo" -AnalyzeStructure -IncludeComments -Validate
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepositoryPath,
        
        [Parameter(Mandatory = $false)]
        [string]$OutputPath,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$OwnershipRules = @{},
        
        [Parameter(Mandatory = $false)]
        [string[]]$DefaultOwners = @(),
        
        [Parameter(Mandatory = $false)]
        [switch]$AnalyzeStructure,
        
        [Parameter(Mandatory = $false)]
        [switch]$IncludeComments,
        
        [Parameter(Mandatory = $false)]
        [switch]$Validate
    )
    
    begin {
        Write-Verbose "Starting New-GitHubCodeOwnersFile for repository: $RepositoryPath"
        
        # Validate repository path
        if (-not (Test-Path $RepositoryPath)) {
            throw "Repository path does not exist: $RepositoryPath"
        }
        
        # Set default output path
        if (-not $OutputPath) {
            $githubDir = Join-Path $RepositoryPath ".github"
            if (-not (Test-Path $githubDir)) {
                New-Item -Path $githubDir -ItemType Directory -Force | Out-Null
                Write-Verbose "Created .github directory: $githubDir"
            }
            $OutputPath = Join-Path $githubDir "CODEOWNERS"
        }
    }
    
    process {
        try {
            $codeownersContent = @()
            
            # Add header comments if requested
            if ($IncludeComments) {
                $codeownersContent += @(
                    "# CODEOWNERS file for Unity-Claude-Automation repository",
                    "# Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')",
                    "# ",
                    "# This file defines code ownership and review requirements.",
                    "# See: https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners",
                    "",
                    "# Default owners for all files (fallback)",
                    "# Pattern precedence: Last matching pattern takes priority",
                    ""
                )
            }
            
            # Add default owners if specified
            if ($DefaultOwners.Count -gt 0) {
                $ownersString = ($DefaultOwners | ForEach-Object { 
                    if ($_ -notmatch "^@") { "@$_" } else { $_ }
                }) -join " "
                $codeownersContent += "* $ownersString"
                
                if ($IncludeComments) {
                    $codeownersContent += ""
                }
            }
            
            # Analyze repository structure if requested
            if ($AnalyzeStructure) {
                Write-Verbose "Analyzing repository structure for ownership patterns..."
                
                $analysisRules = @{}
                
                # PowerShell files
                $psFiles = Get-ChildItem -Path $RepositoryPath -Filter "*.ps1" -Recurse | Measure-Object
                if ($psFiles.Count -gt 0) {
                    $analysisRules["*.ps1"] = @("@powershell-team")
                    $analysisRules["*.psm1"] = @("@powershell-team")
                    $analysisRules["*.psd1"] = @("@powershell-team")
                }
                
                # Documentation files
                $docFiles = Get-ChildItem -Path $RepositoryPath -Filter "*.md" -Recurse | Measure-Object
                if ($docFiles.Count -gt 0) {
                    $analysisRules["*.md"] = @("@docs-team")
                    $analysisRules["docs/"] = @("@docs-team")
                }
                
                # Configuration files
                if (Test-Path (Join-Path $RepositoryPath ".github")) {
                    $analysisRules["/.github/"] = @("@devops-team")
                    $analysisRules["/.github/workflows/"] = @("@devops-team", "@ci-team")
                }
                
                # Module directories
                $moduleDir = Join-Path $RepositoryPath "Modules"
                if (Test-Path $moduleDir) {
                    $analysisRules["/Modules/"] = @("@dev-team")
                }
                
                # Testing files
                $testFiles = Get-ChildItem -Path $RepositoryPath -Filter "*test*" -Recurse | Measure-Object
                if ($testFiles.Count -gt 0) {
                    $analysisRules["*test*"] = @("@qa-team")
                }
                
                # Merge analysis rules with provided rules (provided rules take precedence)
                foreach ($pattern in $analysisRules.Keys) {
                    if (-not $OwnershipRules.ContainsKey($pattern)) {
                        $OwnershipRules[$pattern] = $analysisRules[$pattern]
                    }
                }
            }
            
            # Add ownership rules
            if ($OwnershipRules.Keys.Count -gt 0) {
                if ($IncludeComments) {
                    $codeownersContent += "# Specific ownership rules"
                }
                
                # Sort patterns for logical organization
                $sortedPatterns = $OwnershipRules.Keys | Sort-Object {
                    # Sort order: specific files, directories, wildcards
                    if ($_ -match "^\*") { 2 }        # Wildcards last
                    elseif ($_ -match "/$") { 1 }     # Directories middle
                    else { 0 }                        # Specific files first
                }
                
                foreach ($pattern in $sortedPatterns) {
                    $owners = $OwnershipRules[$pattern]
                    $ownersString = ($owners | ForEach-Object { 
                        if ($_ -notmatch "^@") { "@$_" } else { $_ }
                    }) -join " "
                    
                    if ($IncludeComments) {
                        $comment = ""
                        switch -Regex ($pattern) {
                            "^\*\.ps1?$" { $comment = "  # PowerShell scripts" }
                            "^\*\.md$" { $comment = "  # Documentation files" }
                            "^/\.github/" { $comment = "  # GitHub configuration" }
                            "^/Modules/" { $comment = "  # PowerShell modules" }
                            "\*test\*" { $comment = "  # Test files" }
                        }
                        $codeownersContent += "$pattern $ownersString$comment"
                    } else {
                        $codeownersContent += "$pattern $ownersString"
                    }
                }
            }
            
            # Add footer if including comments
            if ($IncludeComments) {
                $codeownersContent += @(
                    "",
                    "# End of CODEOWNERS file",
                    "# For questions about code ownership, contact the repository administrators."
                )
            }
            
            # Validate CODEOWNERS content if requested
            if ($Validate) {
                Write-Verbose "Validating CODEOWNERS content..."
                $validationResult = Test-CodeOwnersContent -Content $codeownersContent
                if (-not $validationResult.IsValid) {
                    Write-Warning "CODEOWNERS validation warnings: $($validationResult.Warnings -join ', ')"
                }
            }
            
            # Write CODEOWNERS file
            if ($PSCmdlet.ShouldProcess($OutputPath, "Create CODEOWNERS file")) {
                $codeownersContent | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
                Write-Verbose "CODEOWNERS file created: $OutputPath"
                
                return @{
                    Success = $true
                    OutputPath = $OutputPath
                    RulesCount = $OwnershipRules.Keys.Count
                    HasDefaultOwners = $DefaultOwners.Count -gt 0
                    Content = $codeownersContent
                    Validation = if ($Validate) { $validationResult } else { $null }
                }
            }
        }
        catch {
            Write-Error "Failed to create CODEOWNERS file: $($_.Exception.Message)"
            return @{
                Success = $false
                OutputPath = $OutputPath
                Error = $_.Exception.Message
            }
        }
    }
}

# Helper function for CODEOWNERS validation
function Test-CodeOwnersContent {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Content
    )
    
    $warnings = @()
    $isValid = $true
    
    foreach ($line in $Content) {
        $line = $line.Trim()
        
        # Skip comments and empty lines
        if ($line -match "^\s*#" -or $line -eq "") {
            continue
        }
        
        # Check basic pattern format
        if ($line -notmatch "^\S+\s+@\w+") {
            $warnings += "Line may have invalid format: $line"
            $isValid = $false
        }
        
        # Check for common pattern issues
        if ($line -match "^\*[^.]*$" -and $line -notmatch "^\*\s") {
            $warnings += "Wildcard pattern may be too broad: $line"
        }
    }
    
    return @{
        IsValid = $isValid
        Warnings = $warnings
        LineCount = $Content.Count
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAacqcZZvd6l2O2
# CPaD8uzl8hmjaRDKe1K8O5nXENL+o6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMymFu+1a6HoLUCpCTmTIRRe
# MH3fKOYocPcHmJCQgC+2MA0GCSqGSIb3DQEBAQUABIIBAIFYe5fdgZTmFYvNZ1Hi
# YnMJRkVY/YhmIKOflyFTIHrfG2Ux+ggQbk2yZYVoy5LbJc4fH1JJHQDgMXhiKyPM
# xEd/XqzpZHblzFwYWuyz2mVAJg/kuL/2cYk0WFEQn/+ySP79/b7RlDQ2H0t1uXUc
# PHWB9iFPEylh+lLhu79VpR1k5ypx11p4bu0IQxb8TTRGCMQcjovTzRLIAKOeMkjy
# EHk00sAUzSc6YmI028KSxuF3NXeHnfSzvyATXmGoqdLPBwt9tgUFUN1sFcpJpYI+
# hFS9ksG4wkFl4WLXN4loeVXkNml7bn0uTHs13ylgUi2dfPupYoH//ao1yDlpavmJ
# 7OQ=
# SIG # End signature block
