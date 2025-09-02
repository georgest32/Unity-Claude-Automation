# Test-GitHubIntegrationFramework.ps1
# Comprehensive test suite for GitHub Integration Framework
# Phase 4, Week 8, Day 5

param(
    [switch]$AllTests,
    [switch]$TestConfiguration,
    [switch]$TestTemplates,
    [switch]$TestIntegration,
    [switch]$SaveResults,
    [switch]$Verbose
)

# Set verbose preference
if ($Verbose) {
    $VerbosePreference = "Continue"
    $DebugPreference = "Continue"
    Write-Host "Debug and Verbose output enabled" -ForegroundColor Yellow
}

# Test results storage
$testResults = @{
    StartTime = Get-Date
    Tests = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Skipped = 0
    }
}

# Helper function for test execution
function Invoke-TestCase {
    param(
        [string]$Name,
        [scriptblock]$Test,
        [switch]$Critical
    )
    
    Write-Host "`n[TEST] $Name" -ForegroundColor Cyan
    $testResult = @{
        Name = $Name
        StartTime = Get-Date
        Status = "Failed"
        Error = $null
        Critical = $Critical.IsPresent
    }
    
    try {
        $result = & $Test
        $testResult.Status = "Passed"
        Write-Host "  [PASS] $Name" -ForegroundColor Green
        $script:testResults.Summary.Passed++
    }
    catch {
        $testResult.Status = "Failed"
        $testResult.Error = $_.ToString()
        Write-Host "  [FAIL] $Name" -ForegroundColor Red
        Write-Host "    Error: $_" -ForegroundColor Red
        $script:testResults.Summary.Failed++
        
        if ($Critical) {
            Write-Host "  [CRITICAL] This is a critical test. Stopping execution." -ForegroundColor Red
            throw "Critical test failed: $Name"
        }
    }
    finally {
        $testResult.EndTime = Get-Date
        $testResult.Duration = ($testResult.EndTime - $testResult.StartTime).TotalSeconds
        $script:testResults.Tests += $testResult
        $script:testResults.Summary.Total++
    }
}

Write-Host "=======================================" -ForegroundColor Yellow
Write-Host " GitHub Integration Framework Tests    " -ForegroundColor Yellow
Write-Host "=======================================" -ForegroundColor Yellow
Write-Host "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

# Import the module
Write-Host "`n[SETUP] Importing Unity-Claude-GitHub module..." -ForegroundColor Yellow
try {
    $modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-GitHub"
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Host "  Module imported successfully" -ForegroundColor Green
}
catch {
    Write-Host "  Failed to import module: $_" -ForegroundColor Red
    exit 1
}

# Test 1: Configuration System Tests
if ($AllTests -or $TestConfiguration) {
    Invoke-TestCase -Name "Load Default Configuration" -Critical -Test {
        $config = Get-GitHubIntegrationConfig -Validate $true
        
        if (-not $config) {
            throw "Failed to load default configuration"
        }
        if (-not $config.global) {
            throw "Configuration missing global section"
        }
        if (-not $config.templates) {
            throw "Configuration missing templates section" 
        }
        
        Write-Verbose "Configuration loaded with version: $($config.version)"
        return $true
    }
    
    Invoke-TestCase -Name "Configuration Validation" -Test {
        # Test valid configuration
        $validConfig = @{
            version = "1.0.0"
            global = @{
                createIssues = $true
                checkDuplicates = $true
            }
        } | ConvertTo-Json | ConvertFrom-Json
        
        $result = Test-GitHubIntegrationConfig -Config $validConfig
        
        if (-not $result.IsValid) {
            throw "Valid configuration failed validation: $($result.Errors -join ', ')"
        }
        
        Write-Verbose "Configuration validation working correctly"
        return $true
    }
    
    Invoke-TestCase -Name "Configuration Individual Updates" -Test {
        # Test setting individual configuration values
        Set-GitHubIntegrationConfig -DefaultOwner "test-owner" -DefaultRepository "test-repo" -CreateIssues $true
        
        $updatedConfig = Get-GitHubIntegrationConfig
        
        if ($updatedConfig.global.defaultOwner -ne "test-owner") {
            throw "DefaultOwner not updated correctly"
        }
        if ($updatedConfig.global.defaultRepository -ne "test-repo") {
            throw "DefaultRepository not updated correctly"
        }
        
        Write-Verbose "Individual configuration updates working"
        return $true
    }
}

# Test 2: Template System Tests  
if ($AllTests -or $TestTemplates) {
    # Create mock Unity error for template testing
    $mockError = @{
        ErrorText = "Assets/Scripts/PlayerController.cs(42,10): error CS0103: The name 'playerSpeed' does not exist in the current context"
        Message = "The name 'playerSpeed' does not exist in the current context"
        Code = "CS0103"
        File = "Assets/Scripts/PlayerController.cs"
        Line = 42
        Column = 10
        Project = "TestGame"
        UnityVersion = "2022.3.10f1"
    }
    
    # Note: Private functions cannot be tested directly, they are tested through public functions
    Invoke-TestCase -Name "Template Processing via Get-GitHubIssueTemplate" -Test {
        # This tests the private functions indirectly through the public interface
        $issueTemplate = Get-GitHubIssueTemplate -UnityError $mockError
        
        if (-not $issueTemplate) {
            throw "Failed to generate issue template"
        }
        
        # Verify that template type detection worked (tests Get-UnityErrorTemplateType)
        if ($issueTemplate.Title -notmatch "CS0103") {
            throw "Template type detection may have failed - error code not in title"
        }
        
        # Verify that template data construction worked (tests Build-TemplateDataFromUnityError)
        if ($issueTemplate.Body -notmatch "PlayerController.cs") {
            throw "Template data construction may have failed - file name not in body"
        }
        
        # Verify that template expansion worked (tests Expand-IssueTemplate)
        if ($issueTemplate.Body -notmatch "Line.*42") {
            throw "Template expansion may have failed - line number not properly formatted"
        }
        
        Write-Verbose "Template processing pipeline working correctly"
        return $true
    }
    
}

# Test 3: Integration Tests
if ($AllTests -or $TestIntegration) {
    Invoke-TestCase -Name "End-to-End Template to Issue Flow" -Test {
        # Test the complete flow: Unity Error → Template → Issue Data
        $config = Get-GitHubIntegrationConfig
        $issueTemplate = Get-GitHubIssueTemplate -UnityError $mockError -Config $config
        
        # Validate the generated issue would be suitable for GitHub
        if ($issueTemplate.Title.Length -gt 256) {
            throw "Generated title too long: $($issueTemplate.Title.Length) characters"
        }
        if (-not $issueTemplate.Body.Contains("Error Details")) {
            throw "Generated body missing expected sections"
        }
        if (-not ($issueTemplate.Labels -contains "unity")) {
            throw "Generated issue missing 'unity' label"
        }
        
        Write-Verbose "End-to-end template flow validated"
        return $true
    }
    
    Invoke-TestCase -Name "Configuration Override Testing" -Test {
        # Test environment-specific configuration
        $devConfig = Get-GitHubIntegrationConfig -Environment "development"
        $prodConfig = Get-GitHubIntegrationConfig -Environment "production"
        
        if ($devConfig.global.maxSearchResults -eq $prodConfig.global.maxSearchResults) {
            throw "Environment overrides not working - dev and prod configs identical"
        }
        
        Write-Verbose "Environment configuration overrides working"
        return $true
    }
}

# Generate summary
Write-Host "`n=======================================" -ForegroundColor Yellow
Write-Host "           TEST SUMMARY                 " -ForegroundColor Yellow  
Write-Host "=======================================" -ForegroundColor Yellow

$testResults.EndTime = Get-Date
$testResults.Duration = ($testResults.EndTime - $testResults.StartTime).TotalSeconds

Write-Host "Total Tests: $($testResults.Summary.Total)"
Write-Host "Passed: $($testResults.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Summary.Failed)" -ForegroundColor $(if ($testResults.Summary.Failed -gt 0) { "Red" } else { "Gray" })
Write-Host "Skipped: $($testResults.Summary.Skipped)" -ForegroundColor Gray
Write-Host "Duration: $([Math]::Round($testResults.Duration, 2)) seconds"

# Calculate success rate
if ($testResults.Summary.Total -gt 0) {
    $successRate = ($testResults.Summary.Passed / $testResults.Summary.Total) * 100
    Write-Host "Success Rate: $([Math]::Round($successRate, 1))%" -ForegroundColor $(if ($successRate -ge 80) { "Green" } elseif ($successRate -ge 60) { "Yellow" } else { "Red" })
}

# Save results if requested
if ($SaveResults) {
    $resultsFile = Join-Path $PSScriptRoot "Test-GitHubIntegrationFramework-Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    $output = @()
    $output += "GitHub Integration Framework Test Results"
    $output += "========================================"
    $output += "Test Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $output += ""
    $output += "Summary:"
    $output += "  Total Tests: $($testResults.Summary.Total)"
    $output += "  Passed: $($testResults.Summary.Passed)"
    $output += "  Failed: $($testResults.Summary.Failed)"
    $output += "  Duration: $([Math]::Round($testResults.Duration, 2))s"
    $output += ""
    $output += "Detailed Results:"
    
    foreach ($test in $testResults.Tests) {
        $output += ""
        $output += "Test: $($test.Name)"
        $output += "  Status: $($test.Status)"
        $output += "  Duration: $([Math]::Round($test.Duration, 3))s"
        if ($test.Error) {
            $output += "  Error: $($test.Error)"
        }
    }
    
    $output | Out-File -FilePath $resultsFile -Encoding UTF8
    Write-Host "`nResults saved to: $resultsFile" -ForegroundColor Cyan
}

# Exit with appropriate code
if ($testResults.Summary.Failed -gt 0) {
    exit 1
}
else {
    exit 0
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCHfU82DFTfTsTl
# IZLxRl93SZSHA+E2UZYUBsu5lcipe6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKynDIxll3Waw2UFmedGEm7Z
# lg9220cLkk2ADIvykoCiMA0GCSqGSIb3DQEBAQUABIIBABf4gEWsgcOlpYQrhgpu
# 6jhyZzag1AAo9q+TOVtDh3cVEcom8mYo2mQez1jzw8t+5hKs0Dxgbh/zPRJMlJDw
# 1uPmXv9xjk1f0SrEneTverC+tolLvTP2Fm/F/jchxVYXLO3Np8iMk+5hC6fvuTQr
# qUKzcEMPatIUxFP08SYE21O+lmL5FqytWev210/GtKeSfhKko6i50REHpoN/vpip
# z3YiqWNrOkpLkR31a3BC8AUOzRGi7ZDZQe4zqFmu6SZkc/0Bha+HacSTEZdLPhO6
# BOUM5Mk++BG3VH0xnwR/LeibSj51UB/NNHXZ/zMCk1oPigBmrgYfoIQuyshGZSd8
# Z/U=
# SIG # End signature block
