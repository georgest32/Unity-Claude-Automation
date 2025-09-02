# Test-Week9-AdvancedFeatures.ps1
# Comprehensive test suite for Week 9 GitHub integration advanced features
# Phase 4, Week 9: Issue Lifecycle, Multi-Repository, Performance Optimization
# Created: 2025-08-23

param(
    [switch]$SkipAPITests,
    [switch]$UseTestRepository,
    [string]$TestOwner = "Unity-Claude",
    [string]$TestRepository = "TestRepo",
    [switch]$SaveResults
)

# Initialize test environment
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

# Import module
$modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-GitHub"
Import-Module $modulePath -Force

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Unity-Claude GitHub Week 9 Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing advanced GitHub integration features" -ForegroundColor Gray
Write-Host "Module Version: 2.0.0" -ForegroundColor Gray
Write-Host "Test Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "========================================`n" -ForegroundColor Cyan

# Initialize test results
$testResults = @{
    TotalTests = 0
    Passed = 0
    Failed = 0
    Skipped = 0
    Details = @()
    StartTime = Get-Date
}

# Helper function to run tests
function Test-Function {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [switch]$SkipInNoAPI
    )
    
    $testResults.TotalTests++
    
    if ($SkipInNoAPI -and $SkipAPITests) {
        Write-Host "  [SKIP] $Name - API tests disabled" -ForegroundColor Yellow
        $testResults.Skipped++
        $testResults.Details += [PSCustomObject]@{
            Test = $Name
            Result = "Skipped"
            Error = "API tests disabled"
            Duration = 0
        }
        return
    }
    
    $startTime = Get-Date
    try {
        $result = & $Test
        $duration = (Get-Date) - $startTime
        
        if ($result) {
            Write-Host "  [PASS] $Name ($([Math]::Round($duration.TotalSeconds, 2))s)" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Details += [PSCustomObject]@{
                Test = $Name
                Result = "Passed"
                Error = $null
                Duration = $duration.TotalSeconds
            }
        } else {
            Write-Host "  [FAIL] $Name - Test returned false" -ForegroundColor Red
            $testResults.Failed++
            $testResults.Details += [PSCustomObject]@{
                Test = $Name
                Result = "Failed"
                Error = "Test returned false"
                Duration = $duration.TotalSeconds
            }
        }
    } catch {
        $duration = (Get-Date) - $startTime
        Write-Host "  [FAIL] $Name - $_" -ForegroundColor Red
        $testResults.Failed++
        $testResults.Details += [PSCustomObject]@{
            Test = $Name
            Result = "Failed"
            Error = $_.ToString()
            Duration = $duration.TotalSeconds
        }
    }
}

# Test Category 1: Issue Lifecycle Management
Write-Host "`n[Test Category 1: Issue Lifecycle Management]" -ForegroundColor Cyan

Test-Function "Get-GitHubIssueStatus exists" {
    $cmd = Get-Command Get-GitHubIssueStatus -ErrorAction SilentlyContinue
    $null -ne $cmd
}

Test-Function "Update-GitHubIssueState exists" {
    $cmd = Get-Command Update-GitHubIssueState -ErrorAction SilentlyContinue
    $null -ne $cmd
}

Test-Function "Test-UnityErrorResolved exists" {
    $cmd = Get-Command Test-UnityErrorResolved -ErrorAction SilentlyContinue
    $null -ne $cmd
}

Test-Function "Close-GitHubIssueIfResolved exists" {
    $cmd = Get-Command Close-GitHubIssueIfResolved -ErrorAction SilentlyContinue
    $null -ne $cmd
}

Test-Function "Test-UnityErrorResolved with mock data" {
    # Create mock current_errors.json
    $mockErrors = @{
        errors = @()
        compilationSucceeded = $true
        errorCount = 0
        timestamp = (Get-Date).ToString("o")
    }
    $mockFile = Join-Path $env:TEMP "mock_current_errors.json"
    $mockErrors | ConvertTo-Json | Set-Content $mockFile
    
    $result = Test-UnityErrorResolved -IssueNumber 999 -ErrorSignature "CS0246" -CurrentErrorsPath $mockFile
    
    # Cleanup
    Remove-Item $mockFile -Force -ErrorAction SilentlyContinue
    
    $result.IsResolved -eq $true -and $result.CompilationSucceeded -eq $true
}

# Test Category 2: Repository Management
Write-Host "`n[Test Category 2: Repository Management]" -ForegroundColor Cyan

Test-Function "Get-GitHubRepositories exists" {
    $cmd = Get-Command Get-GitHubRepositories -ErrorAction SilentlyContinue
    $null -ne $cmd
}

Test-Function "Test-GitHubRepositoryAccess exists" {
    $cmd = Get-Command Test-GitHubRepositoryAccess -ErrorAction SilentlyContinue
    $null -ne $cmd
}

Test-Function "Get-UnityProjectCategory exists" {
    $cmd = Get-Command Get-UnityProjectCategory -ErrorAction SilentlyContinue
    $null -ne $cmd
}

Test-Function "Search-GitHubIssuesMultiRepo exists" {
    $cmd = Get-Command Search-GitHubIssuesMultiRepo -ErrorAction SilentlyContinue
    $null -ne $cmd
}

Test-Function "Get-UnityProjectCategory categorization" {
    $result = Get-UnityProjectCategory -ProjectName "TestProject" -ErrorContext "Shader compilation error with HLSL"
    $result.Category -eq "graphics" -and $result.Labels -contains "shader"
}

Test-Function "Get-UnityProjectCategory networking detection" {
    $result = Get-UnityProjectCategory -ProjectName "TestProject" -ErrorContext "Mirror NetworkManager connection failed"
    $result.Category -eq "networking" -and $result.Labels -contains "networking"
}

Test-Function "Get-UnityProjectCategory physics detection" {
    $result = Get-UnityProjectCategory -ProjectName "TestProject" -ErrorContext "Rigidbody2D collision detection error"
    $result.Category -eq "physics" -and $result.Labels -contains "physics"
}

Test-Function "Get-UnityProjectCategory UI detection" {
    $result = Get-UnityProjectCategory -ProjectName "TestProject" -ErrorContext "TextMeshPro component missing"
    $result.Category -eq "ui" -and $result.Labels -contains "ui"
}

# Test Category 3: Performance & Analytics
Write-Host "`n[Test Category 3: Performance & Analytics]" -ForegroundColor Cyan

Test-Function "Get-GitHubAPIUsageStats exists" {
    $cmd = Get-Command Get-GitHubAPIUsageStats -ErrorAction SilentlyContinue
    $null -ne $cmd
}

Test-Function "Get-GitHubAPIUsageStats without history" {
    if ($SkipAPITests) {
        throw "Skipping API test"
    }
    
    $stats = Get-GitHubAPIUsageStats
    $null -ne $stats.Core -and $null -ne $stats.Search -and $null -ne $stats.GraphQL
}

# Test Category 4: Cache System
Write-Host "`n[Test Category 4: Cache System]" -ForegroundColor Cyan

Test-Function "Initialize-GitHubIssueCache function exists" {
    # Check if private function is available within module
    $module = Get-Module Unity-Claude-GitHub
    $privateFunc = & $module { Get-Command Initialize-GitHubIssueCache -ErrorAction SilentlyContinue }
    $null -ne $privateFunc
}

Test-Function "Cache initialization creates directory" {
    $cachePath = Join-Path $env:TEMP "GitHubIssueCacheTest"
    
    # Clean up any existing test cache
    if (Test-Path $cachePath) {
        Remove-Item $cachePath -Recurse -Force
    }
    
    # Initialize cache through module internal function
    $module = Get-Module Unity-Claude-GitHub
    & $module { param($path) Initialize-GitHubIssueCache -CachePath $path } -path $cachePath | Out-Null
    
    $result = Test-Path $cachePath
    
    # Cleanup
    Remove-Item $cachePath -Recurse -Force -ErrorAction SilentlyContinue
    
    $result
}

# Test Category 5: Integration Tests
Write-Host "`n[Test Category 5: Integration Tests]" -ForegroundColor Cyan

Test-Function "Module exports all Week 9 functions" {
    $module = Get-Module Unity-Claude-GitHub
    $exportedFunctions = $module.ExportedFunctions.Keys
    
    $week9Functions = @(
        'Get-GitHubIssueStatus',
        'Update-GitHubIssueState',
        'Test-UnityErrorResolved',
        'Close-GitHubIssueIfResolved',
        'Get-GitHubRepositories',
        'Test-GitHubRepositoryAccess',
        'Get-UnityProjectCategory',
        'Search-GitHubIssuesMultiRepo',
        'Get-GitHubAPIUsageStats'
    )
    
    $allExported = $true
    foreach ($func in $week9Functions) {
        if ($exportedFunctions -notcontains $func) {
            Write-Verbose "Missing function: $func"
            $allExported = $false
        }
    }
    
    $allExported
}

Test-Function "Test-GitHubRepositoryAccess with invalid repo" {
    if ($SkipAPITests) {
        throw "Skipping API test"
    }
    
    $result = Test-GitHubRepositoryAccess -Owner "nonexistentowner99999" -Repository "nonexistentrepo99999"
    $result.Success -eq $false
}

# Test Category 6: Error Handling
Write-Host "`n[Test Category 6: Error Handling]" -ForegroundColor Cyan

Test-Function "Get-UnityProjectCategory handles null project" {
    $result = Get-UnityProjectCategory
    $null -ne $result -and $result.Category -eq "general"
}

Test-Function "Test-UnityErrorResolved handles missing files" {
    $result = Test-UnityErrorResolved -IssueNumber 999 -ErrorSignature "CS0246" -CurrentErrorsPath "C:\nonexistent\file.json"
    # When file doesn't exist, it means no errors found, so IsResolved = true (with 0% confidence)
    $null -ne $result -and $result.ResolutionConfidence -eq 0
}

# Final Summary
$testResults.EndTime = Get-Date
$testResults.Duration = $testResults.EndTime - $testResults.StartTime

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Results Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.TotalTests)" -ForegroundColor White
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor $(if ($testResults.Failed -gt 0) { "Red" } else { "Gray" })
Write-Host "Skipped: $($testResults.Skipped)" -ForegroundColor Yellow
Write-Host "Success Rate: $([Math]::Round(($testResults.Passed / ($testResults.TotalTests - $testResults.Skipped)) * 100, 2))%" -ForegroundColor $(if ($testResults.Failed -eq 0) { "Green" } else { "Yellow" })
Write-Host "Duration: $([Math]::Round($testResults.Duration.TotalSeconds, 2)) seconds" -ForegroundColor Gray
Write-Host "========================================`n" -ForegroundColor Cyan

# Save results if requested
if ($SaveResults) {
    $resultsFile = Join-Path $PSScriptRoot "Test-Week9-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $testResults | ConvertTo-Json -Depth 10 | Set-Content $resultsFile
    Write-Host "Results saved to: $resultsFile" -ForegroundColor Gray
}

# Return success/failure
exit $(if ($testResults.Failed -eq 0) { 0 } else { 1 })
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBITrKxVT1N8nhX
# GqYhikWauvp3OFnXzOtbthS6rxzZeqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIB2x+m7B6CYVvWhS+njJul4b
# KMuFv9C/X0WKWogQkVWhMA0GCSqGSIb3DQEBAQUABIIBAGaY97eyo5cYYnyLo11F
# aQeQWHhnWX1aIejRHrd1qXeeNsXO5y5WX2cuWkt6u0BKI8sTtiFUReGxp9vrF/ZT
# UjAotPsXMULa5/WKSV4pkFusOZOlreN+H05fx7QXxAcxNl5L+OBkbqGBMPuS5+Pl
# PIsNpD6BKhJEh1fY4XdJnlOr7b+hTLmYKZJGhnYNHNh1grMGWzJNIrHxBIe/xcbC
# qFZ8nJr6GuvT5+1SGzWQiroMhIaUAT8wwgQlofuHXRG5g1Szkb9W3cDn5hcEN+pP
# B3vUTaJVxg7u8ldK9vamooTepZX+6lFXTP48SI266IcTrYnZgefc8PG+qE24YPmi
# Gmo=
# SIG # End signature block
