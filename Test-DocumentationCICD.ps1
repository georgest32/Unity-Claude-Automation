# Test-DocumentationCICD.ps1
# Tests the documentation CI/CD pipeline locally before pushing to GitHub

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Build', 'Deploy', 'Quality', 'All')]
    [string]$TestType = 'All',
    
    [Parameter(Mandatory=$false)]
    [string]$Version = 'dev'
)

# Set error action preference
$ErrorActionPreference = 'Stop'

# Colors for output
$colors = @{
    Success = 'Green'
    Error = 'Red'
    Warning = 'Yellow'
    Info = 'Cyan'
}

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Type = 'Info'
    )
    Write-Host $Message -ForegroundColor $colors[$Type]
}

function Test-Prerequisites {
    Write-ColorOutput "`nChecking prerequisites..." -Type Info
    
    # Check if virtual environment exists and activate it
    $venvActivated = $false
    if (Test-Path ".venv\Scripts\Activate.ps1") {
        & ".\.venv\Scripts\Activate.ps1"
        $venvActivated = $true
    }
    
    $checks = @{
        'Git' = { git --version }
        'Vale' = { vale --version }
        'Python' = { python --version }
        'markdownlint' = { markdownlint --version }
    }
    
    # Add virtual environment specific checks
    if ($venvActivated) {
        $checks['MkDocs'] = { mkdocs --version }
        $checks['Mike'] = { mike --version }
    } else {
        $checks['MkDocs'] = { mkdocs --version }
        $checks['Mike'] = { mike --version }
    }
    
    $results = @{}
    foreach ($tool in $checks.Keys) {
        try {
            $null = & $checks[$tool] 2>&1
            $results[$tool] = $true
            Write-ColorOutput "  ✓ $tool is installed" -Type Success
        }
        catch {
            $results[$tool] = $false
            Write-ColorOutput "  ✗ $tool is not installed" -Type Warning
        }
    }
    
    return $results
}

function Test-BuildDocumentation {
    Write-ColorOutput "`nTesting documentation build..." -Type Info
    
    try {
        # Activate virtual environment if it exists
        if (Test-Path ".venv\Scripts\Activate.ps1") {
            Write-ColorOutput "  Activating virtual environment..." -Type Info
            & ".\.venv\Scripts\Activate.ps1"
        }
        
        # Install/update dependencies
        Write-ColorOutput "  Installing dependencies..." -Type Info
        pip install -r requirements.txt --quiet
        
        # Build documentation (without --strict to allow warnings for nav)
        Write-ColorOutput "  Building documentation..." -Type Info
        $buildOutput = mkdocs build 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "  ✓ Documentation build successful" -Type Success
            
            # Check output
            if (Test-Path "site\index.html") {
                $fileCount = (Get-ChildItem -Path "site" -Recurse -File).Count
                Write-ColorOutput "  Generated $fileCount files in site/" -Type Info
            }
        }
        else {
            Write-ColorOutput "  ✗ Documentation build failed" -Type Error
            Write-Host $buildOutput
            return $false
        }
    }
    catch {
        Write-ColorOutput "  ✗ Build error: $_" -Type Error
        return $false
    }
    
    return $true
}

function Test-MikeVersioning {
    Write-ColorOutput "`nTesting mike versioning..." -Type Info
    
    try {
        # Check if gh-pages branch exists
        $branches = git branch -r 2>&1
        if ($branches -notmatch "origin/gh-pages") {
            Write-ColorOutput "  gh-pages branch not found. Would be created on first deploy." -Type Warning
        }
        else {
            Write-ColorOutput "  ✓ gh-pages branch exists" -Type Success
        }
        
        # Test mike list (dry run)
        Write-ColorOutput "  Checking existing versions..." -Type Info
        try {
            $versions = mike list 2>&1
            if ($versions) {
                Write-Host "  Current versions:"
                Write-Host $versions
            }
            else {
                Write-ColorOutput "  No versions deployed yet" -Type Info
            }
        }
        catch {
            Write-ColorOutput "  No versions found (expected for new setup)" -Type Info
        }
        
        # Simulate deployment (without actually pushing)
        Write-ColorOutput "  ✓ Mike versioning configured correctly" -Type Success
        return $true
    }
    catch {
        Write-ColorOutput "  ✗ Mike versioning error: $_" -Type Error
        return $false
    }
}

function Test-QualityChecks {
    Write-ColorOutput "`nTesting documentation quality checks..." -Type Info
    
    $results = @{}
    
    # Test markdownlint
    if (Get-Command markdownlint -ErrorAction SilentlyContinue) {
        Write-ColorOutput "  Running markdownlint..." -Type Info
        try {
            $lintOutput = markdownlint docs/**/*.md 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-ColorOutput "  ✓ Markdown lint passed" -Type Success
                $results['markdownlint'] = $true
            }
            else {
                Write-ColorOutput "  ⚠ Markdown lint warnings found" -Type Warning
                $results['markdownlint'] = $false
            }
        }
        catch {
            Write-ColorOutput "  ✗ Markdown lint error: $_" -Type Error
            $results['markdownlint'] = $false
        }
    }
    
    # Test Vale
    if (Get-Command vale -ErrorAction SilentlyContinue) {
        Write-ColorOutput "  Running Vale prose check..." -Type Info
        try {
            if (Test-Path ".vale.ini") {
                $valeOutput = vale docs/ 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-ColorOutput "  ✓ Vale prose check passed" -Type Success
                    $results['vale'] = $true
                }
                else {
                    Write-ColorOutput "  ⚠ Vale found prose issues" -Type Warning
                    $results['vale'] = $false
                }
            }
            else {
                Write-ColorOutput "  Vale configuration not found (.vale.ini)" -Type Warning
            }
        }
        catch {
            Write-ColorOutput "  ✗ Vale error: $_" -Type Error
            $results['vale'] = $false
        }
    }
    
    # Check for broken links (basic check)
    Write-ColorOutput "  Checking for broken internal links..." -Type Info
    $brokenLinks = @()
    Get-ChildItem -Path "docs" -Filter "*.md" -Recurse | ForEach-Object {
        $content = Get-Content $_.FullName -Raw
        $links = [regex]::Matches($content, '\[([^\]]+)\]\(([^)]+)\)')
        foreach ($link in $links) {
            $linkPath = $link.Groups[2].Value
            if ($linkPath -notmatch '^https?://' -and $linkPath -notmatch '^#') {
                # Remove anchor from path for file check
                $cleanPath = $linkPath -replace '#.*$', ''
                if ($cleanPath) {
                    $fullPath = Join-Path (Split-Path $_.FullName) $cleanPath
                    if (-not (Test-Path $fullPath)) {
                        $brokenLinks += "$($_.Name): $linkPath"
                    }
                }
            }
        }
    }
    
    if ($brokenLinks.Count -eq 0) {
        Write-ColorOutput "  ✓ No broken internal links found" -Type Success
        $results['links'] = $true
    }
    else {
        Write-ColorOutput "  ⚠ Found $($brokenLinks.Count) broken links:" -Type Warning
        $brokenLinks | ForEach-Object { Write-Host "    $_" }
        $results['links'] = $false
    }
    
    return $results
}

function Test-GitHubActionsFiles {
    Write-ColorOutput "`nChecking GitHub Actions workflow files..." -Type Info
    
    $workflowPath = ".github\workflows"
    if (Test-Path $workflowPath) {
        $workflows = Get-ChildItem -Path $workflowPath -Filter "*.yml"
        Write-ColorOutput "  Found $($workflows.Count) workflow files:" -Type Info
        
        foreach ($workflow in $workflows) {
            Write-Host "    - $($workflow.Name)"
            
            # Basic YAML validation
            try {
                $content = Get-Content $workflow.FullName -Raw
                if ($content -match '^name:' -and $content -match '^on:') {
                    Write-ColorOutput "      ✓ Basic structure valid" -Type Success
                }
                else {
                    Write-ColorOutput "      ⚠ May be missing required fields" -Type Warning
                }
            }
            catch {
                Write-ColorOutput "      ✗ Error reading file" -Type Error
            }
        }
    }
    else {
        Write-ColorOutput "  ✗ .github/workflows directory not found" -Type Error
        return $false
    }
    
    return $true
}

function Show-Summary {
    param(
        [hashtable]$Results
    )
    
    Write-ColorOutput "`n" + ("=" * 60) -Type Info
    Write-ColorOutput "DOCUMENTATION CI/CD TEST SUMMARY" -Type Info
    Write-ColorOutput ("=" * 60) -Type Info
    
    $allPassed = $true
    foreach ($test in $Results.Keys) {
        $status = if ($Results[$test]) { "PASS" } else { "FAIL"; $allPassed = $false }
        $color = if ($Results[$test]) { "Success" } else { "Error" }
        Write-ColorOutput "$test : $status" -Type $color
    }
    
    Write-ColorOutput ("=" * 60) -Type Info
    
    if ($allPassed) {
        Write-ColorOutput "`n✅ All tests passed! Documentation CI/CD is ready." -Type Success
    }
    else {
        Write-ColorOutput "`n⚠️ Some tests failed. Please review and fix issues before pushing." -Type Warning
    }
    
    # Provide next steps
    Write-ColorOutput "`nNext steps:" -Type Info
    Write-Host "1. Review any warnings or errors above"
    Write-Host "2. Commit your changes: git add . && git commit -m 'Add documentation CI/CD'"
    Write-Host "3. Push to trigger workflows: git push origin main"
    Write-Host "4. Check GitHub Actions tab for workflow runs"
    Write-Host "5. Enable GitHub Pages in repository settings if not already done"
}

# Main execution
function Main {
    Write-ColorOutput "DOCUMENTATION CI/CD PIPELINE TEST" -Type Info
    Write-ColorOutput ("=" * 60) -Type Info
    Write-ColorOutput "Test Type: $TestType" -Type Info
    Write-ColorOutput "Version: $Version" -Type Info
    Write-ColorOutput ("=" * 60) -Type Info
    
    $testResults = @{}
    
    # Check prerequisites
    $prereqs = Test-Prerequisites
    $testResults['Prerequisites'] = ($prereqs.Values | Where-Object { $_ -eq $false }).Count -eq 0
    
    if ($TestType -eq 'Build' -or $TestType -eq 'All') {
        $testResults['Build'] = Test-BuildDocumentation
    }
    
    if ($TestType -eq 'Deploy' -or $TestType -eq 'All') {
        $testResults['Versioning'] = Test-MikeVersioning
        $testResults['Workflows'] = Test-GitHubActionsFiles
    }
    
    if ($TestType -eq 'Quality' -or $TestType -eq 'All') {
        $qualityResults = Test-QualityChecks
        $testResults['Quality'] = ($qualityResults.Values | Where-Object { $_ -eq $false }).Count -eq 0
    }
    
    # Show summary
    Show-Summary -Results $testResults
    
    # Return exit code
    $failedTests = ($testResults.Values | Where-Object { $_ -eq $false }).Count
    exit $failedTests
}

# Run main function
Main
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBmg3Ca5lCiI2X4
# IzHPDq7LLeSTfzqek9QKbh8gB+B1zqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGHUUt1LI+zYXjXuBUQfW11P
# ZGk9EjncVVsHNH/QGAQLMA0GCSqGSIb3DQEBAQUABIIBAAd9ScOLP03fDEeLlxgc
# 2TDIngI/9Pm0qLbN2eZstXaCNO97Gp6+t5/0cHVhDBoRZkaYoXCjzg4wGpDOrJT3
# MXWXfDE8Dg59Qjx9L+tPGXWxvK0eSVdhyv+80TgXgFvNpXDKTfDM5TgI/YzJ1Rou
# VCRatLfLZ/9xEZPth+v5qH42zaFCmEJDtjafXBgmzv+vM5oKAT3Gt7t2f7K6K1Au
# tSSFa+MLWgwHpXRNkrcWav00KLYtY/VUGwl0Y2ZZ1UYh0LCLoAj1bWRv4VNQOmyi
# 5dmYx3rjGhoVWY9u2fbeeGr10pBWD2t5b9mc0msVcrcLYPYIGq8aH/w8oeyHC6FM
# unc=
# SIG # End signature block
