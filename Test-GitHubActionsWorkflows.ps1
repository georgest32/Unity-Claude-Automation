# Test script for GitHub Actions workflows
# Validates workflow syntax and configuration locally

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('All', 'PowerShell', 'Python', 'Quality', 'Deploy')]
    [string]$TestType = 'All',
    
    [Parameter(Mandatory = $false)]
    [switch]$ValidateOnly,
    
    [Parameter(Mandatory = $false)]
    [switch]$SaveResults
)

$ErrorActionPreference = 'Stop'

Write-Host "GitHub Actions Workflow Testing Script" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

# Test results collection
$testResults = @{
    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    TestType = $TestType
    Results = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Warnings = 0
    }
}

function Test-WorkflowSyntax {
    param(
        [string]$WorkflowPath
    )
    
    Write-Host "Testing workflow syntax: $(Split-Path $WorkflowPath -Leaf)" -ForegroundColor Gray
    
    try {
        # Check if file exists
        if (-not (Test-Path $WorkflowPath)) {
            throw "Workflow file not found: $WorkflowPath"
        }
        
        # Basic YAML validation (would need proper YAML parser for full validation)
        $content = Get-Content $WorkflowPath -Raw
        
        # Check for required fields
        $requiredFields = @('name', 'on', 'jobs')
        foreach ($field in $requiredFields) {
            if ($content -notmatch "^$field\s*:") {
                throw "Missing required field: $field"
            }
        }
        
        # Check for common syntax issues
        if ($content -match '\t') {
            Write-Warning "Workflow contains tabs (should use spaces): $WorkflowPath"
            $testResults.Summary.Warnings++
        }
        
        # Check for deprecated actions
        if ($content -match 'actions/checkout@v[12]') {
            Write-Warning "Workflow uses deprecated checkout action version"
            $testResults.Summary.Warnings++
        }
        
        Write-Host "  ✓ Syntax validation passed" -ForegroundColor Green
        return @{
            Status = 'Passed'
            File = Split-Path $WorkflowPath -Leaf
            Message = 'Syntax validation successful'
        }
    }
    catch {
        Write-Host "  ✗ Syntax validation failed: $_" -ForegroundColor Red
        return @{
            Status = 'Failed'
            File = Split-Path $WorkflowPath -Leaf
            Message = $_.ToString()
        }
    }
}

function Test-PowerShellWorkflow {
    Write-Host "`nTesting PowerShell workflow..." -ForegroundColor Yellow
    
    $workflowPath = Join-Path $PSScriptRoot ".github\workflows\powershell-tests.yml"
    $result = Test-WorkflowSyntax -WorkflowPath $workflowPath
    
    if ($result.Status -eq 'Passed' -and -not $ValidateOnly) {
        # Additional PowerShell-specific tests
        Write-Host "  Testing PowerShell module detection..." -ForegroundColor Gray
        
        $modules = Get-ChildItem -Path (Join-Path $PSScriptRoot "Modules") -Filter "*.psd1" -Recurse
        if ($modules.Count -eq 0) {
            Write-Warning "No PowerShell modules found for testing"
            $result.Message += "; Warning: No modules found"
        } else {
            Write-Host "    Found $($modules.Count) PowerShell modules" -ForegroundColor Green
        }
    }
    
    return $result
}

function Test-PythonWorkflow {
    Write-Host "`nTesting Python workflow..." -ForegroundColor Yellow
    
    $workflowPath = Join-Path $PSScriptRoot ".github\workflows\python-tests.yml"
    $result = Test-WorkflowSyntax -WorkflowPath $workflowPath
    
    if ($result.Status -eq 'Passed' -and -not $ValidateOnly) {
        # Additional Python-specific tests
        Write-Host "  Testing Python environment setup..." -ForegroundColor Gray
        
        $requirementsPath = Join-Path $PSScriptRoot "requirements.txt"
        if (Test-Path $requirementsPath) {
            Write-Host "    Found requirements.txt" -ForegroundColor Green
        } else {
            Write-Warning "No requirements.txt found"
            $result.Message += "; Warning: No requirements.txt"
        }
    }
    
    return $result
}

function Test-QualityGatesWorkflow {
    Write-Host "`nTesting Quality Gates workflow..." -ForegroundColor Yellow
    
    $workflowPath = Join-Path $PSScriptRoot ".github\workflows\quality-gates.yml"
    $result = Test-WorkflowSyntax -WorkflowPath $workflowPath
    
    if ($result.Status -eq 'Passed' -and -not $ValidateOnly) {
        # Check quality gate configurations
        Write-Host "  Checking quality gate thresholds..." -ForegroundColor Gray
        
        $content = Get-Content $workflowPath -Raw
        if ($content -match 'MIN_COVERAGE_PERCENT:\s*(\d+)') {
            $minCoverage = $Matches[1]
            Write-Host "    Minimum coverage threshold: $minCoverage%" -ForegroundColor Green
        }
        
        if ($content -match 'MIN_NEW_CODE_COVERAGE:\s*(\d+)') {
            $minNewCoverage = $Matches[1]
            Write-Host "    Minimum new code coverage: $minNewCoverage%" -ForegroundColor Green
        }
    }
    
    return $result
}

function Test-DeploymentWorkflow {
    Write-Host "`nTesting Deployment workflow..." -ForegroundColor Yellow
    
    $workflowPath = Join-Path $PSScriptRoot ".github\workflows\deploy.yml"
    $result = Test-WorkflowSyntax -WorkflowPath $workflowPath
    
    if ($result.Status -eq 'Passed' -and -not $ValidateOnly) {
        # Check deployment configurations
        Write-Host "  Checking deployment environments..." -ForegroundColor Gray
        
        $content = Get-Content $workflowPath -Raw
        $environments = @('development', 'staging', 'production')
        
        foreach ($env in $environments) {
            if ($content -match "environment:\s*\n\s*name:\s*$env") {
                Write-Host "    ✓ $env environment configured" -ForegroundColor Green
            } else {
                Write-Warning "    $env environment not found"
            }
        }
        
        # Check for rollback mechanism
        if ($content -match 'rollback:') {
            Write-Host "    ✓ Rollback mechanism configured" -ForegroundColor Green
        } else {
            Write-Warning "    No rollback mechanism found"
        }
    }
    
    return $result
}

function Test-AllWorkflows {
    Write-Host "`nTesting all workflows in .github/workflows..." -ForegroundColor Yellow
    
    $workflowsPath = Join-Path $PSScriptRoot ".github\workflows"
    $workflows = Get-ChildItem -Path $workflowsPath -Filter "*.yml" -File
    
    Write-Host "Found $($workflows.Count) workflow files" -ForegroundColor Cyan
    
    $results = @()
    foreach ($workflow in $workflows) {
        $result = Test-WorkflowSyntax -WorkflowPath $workflow.FullName
        $results += $result
    }
    
    return $results
}

# Main test execution
Write-Host "Starting workflow tests (Type: $TestType)..." -ForegroundColor Cyan
Write-Host ""

$results = @()

switch ($TestType) {
    'PowerShell' {
        $results += Test-PowerShellWorkflow
    }
    'Python' {
        $results += Test-PythonWorkflow
    }
    'Quality' {
        $results += Test-QualityGatesWorkflow
    }
    'Deploy' {
        $results += Test-DeploymentWorkflow
    }
    'All' {
        $results += Test-PowerShellWorkflow
        $results += Test-PythonWorkflow
        $results += Test-QualityGatesWorkflow
        $results += Test-DeploymentWorkflow
        
        # Also test all other workflows
        Write-Host "`n--- Testing all workflows ---" -ForegroundColor Cyan
        $allResults = Test-AllWorkflows
        $results += $allResults
    }
}

# Process results
$testResults.Results = $results
$testResults.Summary.Total = $results.Count
$testResults.Summary.Passed = ($results | Where-Object { $_.Status -eq 'Passed' }).Count
$testResults.Summary.Failed = ($results | Where-Object { $_.Status -eq 'Failed' }).Count

# Display summary
Write-Host "`n" + "="*50 -ForegroundColor Cyan
Write-Host "TEST SUMMARY" -ForegroundColor Cyan
Write-Host "="*50 -ForegroundColor Cyan
Write-Host "Total Tests:    $($testResults.Summary.Total)" -ForegroundColor White
Write-Host "Passed:         $($testResults.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed:         $($testResults.Summary.Failed)" -ForegroundColor Red
Write-Host "Warnings:       $($testResults.Summary.Warnings)" -ForegroundColor Yellow

if ($testResults.Summary.Failed -gt 0) {
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    $results | Where-Object { $_.Status -eq 'Failed' } | ForEach-Object {
        Write-Host "  - $($_.File): $($_.Message)" -ForegroundColor Red
    }
}

# Save results if requested
if ($SaveResults) {
    $outputFile = Join-Path $PSScriptRoot "GitHubWorkflows-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $testResults | ConvertTo-Json -Depth 10 | Set-Content $outputFile
    Write-Host "`nTest results saved to: $outputFile" -ForegroundColor Green
}

# Check for GitHub CLI
Write-Host "`nChecking GitHub CLI installation..." -ForegroundColor Cyan
if (Get-Command gh -ErrorAction SilentlyContinue) {
    $ghVersion = gh --version
    Write-Host "  ✓ GitHub CLI installed: $($ghVersion[0])" -ForegroundColor Green
    
    # Validate workflows with GitHub CLI if available
    if (-not $ValidateOnly) {
        Write-Host "  Validating with GitHub CLI..." -ForegroundColor Gray
        try {
            # This would validate workflows against GitHub's schema
            # gh workflow list would show available workflows when authenticated
            Write-Host "    Note: Full validation requires GitHub authentication" -ForegroundColor Yellow
        }
        catch {
            Write-Warning "Could not validate with GitHub CLI: $_"
        }
    }
} else {
    Write-Warning "GitHub CLI not installed - cannot perform full validation"
    Write-Host "  Install from: https://cli.github.com/" -ForegroundColor Yellow
}

# Return success/failure
if ($testResults.Summary.Failed -gt 0) {
    Write-Host "`n❌ Workflow tests failed!" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ All workflow tests passed!" -ForegroundColor Green
    exit 0
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDAXMXTu9g7f68S
# oNfjIF+ASYL7UdlIX1kafRdQYkB+paCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFpPQHw1LwHuRrwIHVKHde1D
# NMYcrSGT/fuFprJy6E/PMA0GCSqGSIb3DQEBAQUABIIBAK4dMjbvZ7k2dP8y9Tv2
# xQ1ZPiVKD+c4gv+ZTTmujqKiZ8ze8brRXudF6v+gGnpLAi0tEUOpPOlo6cc3u1GN
# Tuh7I3WMh9zM0uQ0loRGAz6nDYnrbdZm8vt2jBkNtB203PzVy5OR/zeUQVf6xG29
# z3UGiEmg6pePOx8ovL7s5rfxlHleI3tIezrVJYx2w1ayCLcnSTO88bSIB1xwO3ZN
# /hIJ+vcs5Tcuqj8WVh6maiEDMigWoRU9ooiHNHzd579SKwXhtgMXLJgSoY81urka
# TuaY5HkMSEaPPCfwUJEuau2BdGO7UcM/GCjzbYKAd7LVo32EAvEaO6KSNw0r2mKa
# c38=
# SIG # End signature block
