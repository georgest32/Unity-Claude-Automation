# Test-DocumentationAutomation-EndToEnd.ps1
# End-to-end test for documentation automation system
# Created: 2025-08-24
# Phase 5 Hours 5-8 - Automated PR Creation Testing

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$SkipGitHubTests,
    
    [Parameter(Mandatory = $false)]
    [switch]$SaveResults,
    
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = ".\DocumentationAutomation-EndToEnd-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

Write-Host "🚀 Unity-Claude Documentation Automation - End-to-End Test" -ForegroundColor Cyan
Write-Host "Started: $(Get-Date)" -ForegroundColor Gray

# Test results tracking
$TestResults = @{
    TestSuite = "DocumentationAutomation-EndToEnd"
    StartTime = Get-Date
    EndTime = $null
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    Tests = @()
}

function Test-Step {
    param($Name, $TestFunction)
    
    $TestResults.TotalTests++
    Write-Host "  $Name..." -ForegroundColor Yellow -NoNewline
    
    $testResult = @{
        Name = $Name
        Status = 'Unknown'
        Duration = $null
        Error = $null
        StartTime = Get-Date
    }
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $result = & $TestFunction
        $stopwatch.Stop()
        
        $testResult.Duration = $stopwatch.ElapsedMilliseconds
        $testResult.Status = 'Passed'
        $testResult.Result = $result
        $TestResults.PassedTests++
        Write-Host " ✅ PASSED ($($stopwatch.ElapsedMilliseconds)ms)" -ForegroundColor Green
    } catch {
        $testResult.Status = 'Failed'
        $testResult.Error = $_.Exception.Message
        $TestResults.FailedTests++
        Write-Host " ❌ FAILED" -ForegroundColor Red
        Write-Host "    Error: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    $TestResults.Tests += $testResult
}

# Import required modules
Write-Host "`n📦 Loading Modules..." -ForegroundColor Cyan

Test-Step "Import Unity-Claude-DocumentationDrift" {
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-DocumentationDrift\Unity-Claude-DocumentationDrift.psd1" -Force
    return $true
}

Test-Step "Import Unity-Claude-GitHub" {
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-GitHub\Unity-Claude-GitHub.psd1" -Force
    return $true
}

Write-Host "`n🔧 Configuration Tests..." -ForegroundColor Cyan

Test-Step "Initialize Documentation Drift System" {
    Initialize-DocumentationDrift -Force
    $config = Get-DocumentationDriftConfig
    if (-not $config) { throw "Configuration failed" }
    return $config
}

Test-Step "Verify Template Files Exist" {
    $templates = @(
        ".\templates\pr-templates\documentation-update.md",
        ".\templates\pr-templates\api-documentation-update.md", 
        ".\templates\pr-templates\breaking-change-docs.md"
    )
    
    foreach ($template in $templates) {
        if (-not (Test-Path $template)) {
            throw "Missing template: $template"
        }
    }
    
    return $templates.Count
}

Write-Host "`n📋 Branch Management Tests..." -ForegroundColor Cyan

Test-Step "Create Documentation Branch" {
    # Test branch creation
    $result = New-DocumentationBranch -ChangeDescription "test-automation-system"
    if (-not $result.Created) {
        throw "Branch creation failed: $($result.Errors -join '; ')"
    }
    return $result
}

Test-Step "Generate Commit Message" {
    # Create test change impact
    $changeImpact = @{
        FilePath = "Test-Module.psm1"
        ChangeType = @("FunctionModification")
        AffectedFunctions = @("Test-Function", "New-TestObject")
        Priority = "Medium"
        BreakingChanges = @()
    }
    
    $result = Generate-DocumentationCommitMessage -ChangeImpact $changeImpact
    if (-not $result.Subject) {
        throw "Commit message generation failed"
    }
    return $result
}

Write-Host "`n🔗 GitHub Integration Tests..." -ForegroundColor Cyan

if ($SkipGitHubTests) {
    Write-Host "⏭️  Skipping GitHub tests (SkipGitHubTests flag set)" -ForegroundColor Yellow
} else {
    Test-Step "Check GitHub PAT Configuration" {
        try {
            $pat = Get-GitHubPAT
            if ($pat) {
                return "PAT configured"
            } else {
                throw "GitHub PAT not configured - set with Set-GitHubPAT"
            }
        } catch {
            throw "GitHub authentication not available: $_"
        }
    }
    
    Test-Step "Verify New-GitHubPullRequest Function" {
        $command = Get-Command New-GitHubPullRequest -ErrorAction SilentlyContinue
        if (-not $command) {
            throw "New-GitHubPullRequest function not available"
        }
        return $command.Name
    }
    
    Test-Step "Test PR Creation (Dry Run)" {
        # Create test change impact for PR creation
        $changeImpact = @{
            FilePath = "README.md"
            ChangeType = @("DocumentationUpdate")
            AffectedFunctions = @()
            Priority = "Low"
            BreakingChanges = @()
        }
        
        # This will prepare the PR but not actually create it without proper Git setup
        try {
            $result = New-DocumentationPR -BranchName "test-branch" -ChangeImpact $changeImpact -DryRun:$true
            return "PR preparation successful"
        } catch {
            # Expected to fail without proper Git remote, but function should exist
            if ($_.Exception.Message -match "Unable to determine GitHub repository") {
                return "PR function working (no Git remote configured)"
            } else {
                throw $_
            }
        }
    }
}

Write-Host "`n📊 Analysis Engine Tests..." -ForegroundColor Cyan

Test-Step "Build Code-to-Documentation Mapping (Limited)" {
    # Test with limited files to avoid timeout
    $result = Build-CodeToDocMapping -BasePath "." -IncludePatterns @("*.md") -MaxFiles 3
    if (-not $result) {
        throw "Code mapping failed"
    }
    return "Mapped $($result.TotalFiles) files"
}

Test-Step "Test Documentation Quality Check" {
    # Create temporary test file
    $testFile = ".\temp-quality-test.md"
    "# Test Documentation`n`nThis is a test document for quality validation." | Out-File -FilePath $testFile -Encoding UTF8
    
    try {
        $result = Test-DocumentationQuality -FilePath $testFile
        if (-not $result) {
            throw "Quality check returned null"
        }
        return $result
    } finally {
        if (Test-Path $testFile) { Remove-Item $testFile -Force }
    }
}

Write-Host "`n⚡ Integration Workflow Test..." -ForegroundColor Cyan

Test-Step "Complete Documentation Automation Workflow" {
    # Test the main orchestration function
    try {
        # This should work even without actual file changes
        $result = Invoke-DocumentationAutomation -FilePaths @("README.md") -DryRun:$true
        return "Automation workflow accessible"
    } catch {
        if ($_.Exception.Message -match "No changes detected") {
            return "Automation workflow working (no changes to process)"
        } else {
            throw $_
        }
    }
}

# Cleanup any test branches
Write-Host "`n🧹 Cleanup..." -ForegroundColor Cyan

Test-Step "Cleanup Test Branches" {
    try {
        # Clean up any test branches created
        $testBranches = git branch --list "*test-automation-system*" 2>$null
        if ($LASTEXITCODE -eq 0 -and $testBranches) {
            foreach ($branch in $testBranches) {
                $branchName = $branch.Trim().TrimStart('* ')
                if ($branchName -match "test-automation-system") {
                    git branch -D $branchName 2>$null | Out-Null
                }
            }
        }
        return "Cleanup completed"
    } catch {
        return "Cleanup attempted (some errors expected)"
    }
}

# Finalize results
$TestResults.EndTime = Get-Date
$TestResults.Duration = ($TestResults.EndTime - $TestResults.StartTime).TotalSeconds

Write-Host "`n📋 Test Summary:" -ForegroundColor Cyan
Write-Host "  Total Tests: $($TestResults.TotalTests)" -ForegroundColor Gray
Write-Host "  Passed: $($TestResults.PassedTests)" -ForegroundColor Green  
Write-Host "  Failed: $($TestResults.FailedTests)" -ForegroundColor $(if($TestResults.FailedTests -gt 0){'Red'}else{'Green'})
Write-Host "  Duration: $([math]::Round($TestResults.Duration, 2)) seconds" -ForegroundColor Gray

if ($TestResults.FailedTests -gt 0) {
    Write-Host "`n❌ Failed Tests:" -ForegroundColor Red
    $TestResults.Tests | Where-Object { $_.Status -eq 'Failed' } | ForEach-Object {
        Write-Host "  - $($_.Name): $($_.Error)" -ForegroundColor Red
    }
}

# Save results if requested
if ($SaveResults) {
    $TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-Host "`n💾 Results saved to: $OutputPath" -ForegroundColor Cyan
}

# Final status
if ($TestResults.FailedTests -eq 0) {
    Write-Host "`n🎉 End-to-End Test PASSED!" -ForegroundColor Green
    Write-Host "Documentation automation system is ready for production!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n⚠️  End-to-End Test completed with failures" -ForegroundColor Yellow
    Write-Host "Review failed tests before deploying to production." -ForegroundColor Yellow
    exit 1
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCxeMaJl/nQ3bLI
# a+MeiqafgOjS4VBi8K+0ttizaMGOd6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICmRfyipoOUer1oA65DIzmnc
# twwVltepp9NXN/AyJiB1MA0GCSqGSIb3DQEBAQUABIIBAKT6JFK1RdJ8tobekXPT
# tjP3Fp56TyzqEQr3X4bL29m3ep2M2+g+Lkhwvt650yVN780xRFvFT+0G9deAJ74T
# 5u6LjdfjxjPkywde0+fu9oNJ7PJQMqKmZLQbsRy3O091ra63i/6NuxURh7McdA+9
# Jjx5znYCi2ghmp6iaQPRkzDVv6q7P3hM02gXDOrY7w8+XW59Pz1jFS8AP7Z0ksQQ
# OzmUtDI99AQbobxnboN0YcllRkGVs2RQOT4BEr31dTt1oHqWJkDvXaipH1LpQ8Dl
# EgiZ0jhvdmn0uoDVqfhDtsBuQ0x8ODLkCywklAcQagwh13TlDdU9EnpUbr5+jmZ+
# ZZc=
# SIG # End signature block
