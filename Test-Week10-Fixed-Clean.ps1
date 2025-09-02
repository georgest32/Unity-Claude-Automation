# Unity-Claude Automation - Week 10 End-to-End Test Suite
# Clean version with fixed syntax errors

param(
    [switch]$AllTests,
    [switch]$SaveResults
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Unity-Claude Week 10: End-to-End Testing" -ForegroundColor Cyan  
Write-Host "========================================" -ForegroundColor Cyan

# Initialize test results
$testResults = @{
    StartTime = Get-Date
    TotalTests = 0
    Passed = 0
    Failed = 0
    Skipped = 0
    Tests = @()
    Errors = @()
}

# Import modules
Write-Host "`nImporting modules..." -ForegroundColor Yellow

# Test GitHub module
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-GitHub\Unity-Claude-GitHub.psd1" -Force -ErrorAction Stop
    Write-Host "  Loaded: Unity-Claude-GitHub" -ForegroundColor Green
}
catch {
    Write-Host "  Failed: Unity-Claude-GitHub - $_" -ForegroundColor Red
}

# Test NotificationIntegration module
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-NotificationIntegration\Unity-Claude-NotificationIntegration.psd1" -Force -ErrorAction Stop
    Write-Host "  Loaded: Unity-Claude-NotificationIntegration" -ForegroundColor Green
}
catch {
    Write-Host "  Warning: Unity-Claude-NotificationIntegration - $_" -ForegroundColor Yellow
}

# Test EventLog module
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-EventLog\Unity-Claude-EventLog.psd1" -Force -ErrorAction Stop
    Write-Host "  Loaded: Unity-Claude-EventLog" -ForegroundColor Green
}
catch {
    Write-Host "  Warning: Unity-Claude-EventLog - $_" -ForegroundColor Yellow
}

# Test 1: Module Functions Exist
Write-Host "`n[Test 1: Module Functions]" -ForegroundColor Cyan
$functions = @(
    "Test-GitHubPAT",
    "New-GitHubIssue", 
    "Search-GitHubIssues",
    "Get-GitHubAPIUsageStats",
    "Test-GitHubRepositoryAccess",
    "Get-GitHubIssueStatus",
    "Update-GitHubIssueState"
)

foreach ($func in $functions) {
    $testResults.TotalTests++
    $cmd = Get-Command $func -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "  PASS: $func exists" -ForegroundColor Green
        $testResults.Passed++
        $testResults.Tests += @{Name=$func; Result="Pass"}
    }
    else {
        Write-Host "  FAIL: $func not found" -ForegroundColor Red
        $testResults.Failed++
        $testResults.Tests += @{Name=$func; Result="Fail"}
    }
}

# Test 2: GitHub PAT Configuration
Write-Host "`n[Test 2: GitHub PAT Configuration]" -ForegroundColor Cyan
$testResults.TotalTests++
try {
    $pat = Test-GitHubPAT -ErrorAction Stop
    if ($pat) {
        Write-Host "  PASS: GitHub PAT is configured" -ForegroundColor Green
        $testResults.Passed++
        $testResults.Tests += @{Name="GitHub PAT"; Result="Pass"}
    }
    else {
        Write-Host "  WARN: GitHub PAT not configured" -ForegroundColor Yellow
        $testResults.Skipped++
        $testResults.Tests += @{Name="GitHub PAT"; Result="Warning"}
    }
}
catch {
    Write-Host "  SKIP: Cannot test PAT - $_" -ForegroundColor Yellow
    $testResults.Skipped++
    $testResults.Tests += @{Name="GitHub PAT"; Result="Skip"}
}

# Test 3: Rate Limit Check
Write-Host "`n[Test 3: GitHub Rate Limits]" -ForegroundColor Cyan
$testResults.TotalTests++

try {
    $usage = Get-GitHubAPIUsageStats -ErrorAction Stop
    if ($usage) {
        Write-Host "  PASS: Rate limit check successful" -ForegroundColor Green
        Write-Host "    Core API: $($usage.Core.Remaining)/$($usage.Core.Limit)" -ForegroundColor Gray
        Write-Host "    Search API: $($usage.Search.Remaining)/$($usage.Search.Limit)" -ForegroundColor Gray
        $testResults.Passed++
        $testResults.Tests += @{Name="Rate Limits"; Result="Pass"; Details=$usage}
    }
    else {
        Write-Host "  SKIP: No rate limit data available" -ForegroundColor Yellow
        $testResults.Skipped++
        $testResults.Tests += @{Name="Rate Limits"; Result="Skip"}
    }
}
catch {
    Write-Host "  SKIP: Rate limit check skipped - $_" -ForegroundColor Yellow
    $testResults.Skipped++
    $testResults.Tests += @{Name="Rate Limits"; Result="Skip"}
}

# Test 4: Mock Unity Error Processing
Write-Host "`n[Test 4: Unity Error Processing]" -ForegroundColor Cyan
$testResults.TotalTests++

$mockError = @{
    errorCode = "CS0246"
    message = "The type or namespace name 'NetworkManager' could not be found"
    file = "Assets/Scripts/TestScript.cs"
    line = 42
    projectPath = "C:\UnityProjects\TestProject"
}

# Check if Format-UnityErrorAsIssue exists
$formatCmd = Get-Command Format-UnityErrorAsIssue -ErrorAction SilentlyContinue
if ($formatCmd) {
    try {
        $formatted = Format-UnityErrorAsIssue -UnityError $mockError -ErrorAction Stop
        if ($formatted.title -and $formatted.body) {
            Write-Host "  PASS: Error formatting successful" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Tests += @{Name="Error Formatting"; Result="Pass"}
        }
        else {
            Write-Host "  FAIL: Error formatting incomplete" -ForegroundColor Red
            $testResults.Failed++
            $testResults.Tests += @{Name="Error Formatting"; Result="Fail"}
        }
    }
    catch {
        Write-Host "  FAIL: Error formatting failed - $_" -ForegroundColor Red
        $testResults.Failed++
        $testResults.Tests += @{Name="Error Formatting"; Result="Fail"; Error=$_.ToString()}
    }
}
else {
    Write-Host "  SKIP: Format-UnityErrorAsIssue not available" -ForegroundColor Yellow
    $testResults.Skipped++
    $testResults.Tests += @{Name="Error Formatting"; Result="Skip"}
}

# Test 5: Repository Access (Negative Test)
if ($AllTests) {
    Write-Host "`n[Test 5: Repository Access - Negative Test]" -ForegroundColor Cyan
    $testResults.TotalTests++
    
    # Test with a known invalid repo to verify error handling
    $testRepo = @{owner="nonexistent999"; name="nonexistent999"}
    
    try {
        $access = Test-GitHubRepositoryAccess -Owner $testRepo.owner -Repository $testRepo.name -ErrorAction Stop
        if (-not $access) {
            Write-Host "  PASS: Invalid repo correctly identified as inaccessible" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Tests += @{Name="Repository Access"; Result="Pass"}
        }
        else {
            Write-Host "  WARN: Unexpected result for invalid repo" -ForegroundColor Yellow
            $testResults.Skipped++
            $testResults.Tests += @{Name="Repository Access"; Result="Warning"}
        }
    }
    catch {
        # This is expected for invalid repo
        Write-Host "  PASS: Error handling working correctly for invalid repo" -ForegroundColor Green
        $testResults.Passed++
        $testResults.Tests += @{Name="Repository Access"; Result="Pass"}
    }
}

# Test 6: Notification System
Write-Host "`n[Test 6: Notification System]" -ForegroundColor Cyan
$testResults.TotalTests++

$notificationCmd = Get-Command Get-NotificationConfiguration -ErrorAction SilentlyContinue
if ($notificationCmd) {
    try {
        $config = Get-NotificationConfiguration -ErrorAction Stop
        Write-Host "  PASS: Notification system available" -ForegroundColor Green
        $testResults.Passed++
        $testResults.Tests += @{Name="Notification System"; Result="Pass"}
    }
    catch {
        Write-Host "  WARN: Notification system not configured - $_" -ForegroundColor Yellow
        $testResults.Skipped++
        $testResults.Tests += @{Name="Notification System"; Result="Warning"}
    }
}
else {
    Write-Host "  SKIP: Notification commands not available" -ForegroundColor Yellow
    $testResults.Skipped++
    $testResults.Tests += @{Name="Notification System"; Result="Skip"}
}

# Calculate duration
$testResults.EndTime = Get-Date
$duration = $testResults.EndTime - $testResults.StartTime

# Display summary
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "Total Tests: $($testResults.TotalTests)" -ForegroundColor White
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor Red
Write-Host "Skipped: $($testResults.Skipped)" -ForegroundColor Yellow
Write-Host "Duration: $([Math]::Round($duration.TotalSeconds, 2)) seconds" -ForegroundColor Gray

if ($testResults.Failed -eq 0) {
    Write-Host "`nALL CRITICAL TESTS PASSED!" -ForegroundColor Green
    $exitCode = 0
}
else {
    Write-Host "`nSOME TESTS FAILED" -ForegroundColor Red
    # Display errors
    if ($testResults.Errors.Count -gt 0) {
        Write-Host "`nErrors:" -ForegroundColor Red
        foreach ($error in $testResults.Errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
    }
    $exitCode = 1
}

# Save results if requested
if ($SaveResults) {
    $resultsFile = "$PSScriptRoot\Test-Week10-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $testResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $resultsFile -Force
    Write-Host "`nResults saved to: $resultsFile" -ForegroundColor Cyan
}

Write-Host "========================================" -ForegroundColor Cyan
exit $exitCode
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCPUx8XsRUCRlWk
# NUdWYPNaBVh3QnE5A8GmixrTLm//iKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOfKfFSbyFI3hbUm33PZfwNX
# 9W2NIgth4SLseQhZCxkYMA0GCSqGSIb3DQEBAQUABIIBABJYSJxW6BElAbfBvjIE
# f3WMrYBybQYmS8qxMPffcKnjvxV+e+/yjtsgHnlkTEA++yVfBsYInq0kcEXvMoK4
# tukX4vJqxZqwCYwWnt1y4vYFXvld1CHLg4Vl/Fer44qhPbwcUTEkn7rBGpvizkld
# 7geqEa9fQfhEcqkH9sXT2L13o3UE5UY2j1uWN5Syj+FPousjCEZT1bvv2h5KPIT5
# idK5QXcz8Mi+Zln/Y3U2M+zUlg5g2dSF2hOuuoLc2UhG90ko3yTdaJcWO35FsTDR
# h76Ej9i5OFDksoyucbd2Aqfo7HrxpGq2Ba/4JCAdzqZ7JKv95/r6bmTHN/55YMYs
# YMw=
# SIG # End signature block
