# Test-Week3-Days3-4-ClaudeParallelization-Fixed.ps1
# Fixed test suite using direct function calls instead of Start-Job
# Phase 1 Week 3 Days 3-4: Claude Integration Parallelization Testing
# Date: 2025-08-21

[CmdletBinding()]
param(
    [switch]$SaveResults,
    [switch]$TestWithRealClaudeAPI,
    [switch]$TestWithRealClaudeCLI
)

Write-Host "=== Unity-Claude-ClaudeParallelization Testing (FIXED) ===" -ForegroundColor Cyan
Write-Host "Phase 1 Week 3 Days 3-4: Claude Integration Parallelization" -ForegroundColor Green
Write-Host "Date: $(Get-Date)" -ForegroundColor Green
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Green
Write-Host "Real Claude API: $TestWithRealClaudeAPI" -ForegroundColor Green
Write-Host "Real Claude CLI: $TestWithRealClaudeCLI" -ForegroundColor Green

# Configure PSModulePath for custom modules
$env:PSModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules;" + $env:PSModulePath

# Test results tracking
$TestResults = @{
    TestName = "Week3-Days3-4-ClaudeParallelization-Fixed"
    StartTime = Get-Date
    Tests = @()
    Categories = @{
        ModuleLoading = @{Passed = 0; Failed = 0; Total = 0}
        ClaudeAPIParallel = @{Passed = 0; Failed = 0; Total = 0}
        ClaudeCLIParallel = @{Passed = 0; Failed = 0; Total = 0}
        ResponseProcessing = @{Passed = 0; Failed = 0; Total = 0}
        Performance = @{Passed = 0; Failed = 0; Total = 0}
        Integration = @{Passed = 0; Failed = 0; Total = 0}
    }
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Duration = 0
        PassRate = 0
    }
}

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Message = "",
        [int]$Duration = 0,
        [string]$Category = "General"
    )
    
    $status = if ($Success) { "PASS" } else { "FAIL" }
    $color = if ($Success) { "Green" } else { "Red" }
    
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Message) {
        Write-Host "    $Message" -ForegroundColor Gray
    }
    if ($Duration -gt 0) {
        Write-Host "    Duration: ${Duration}ms" -ForegroundColor Gray
    }
    
    # Update statistics
    $TestResults.Summary.Total++
    if ($TestResults.Categories.ContainsKey($Category)) {
        $TestResults.Categories[$Category].Total++
        if ($Success) {
            $TestResults.Summary.Passed++
            $TestResults.Categories[$Category].Passed++
        } else {
            $TestResults.Summary.Failed++
            $TestResults.Categories[$Category].Failed++
        }
    }
    
    return $Success
}

try {
    Write-Host "" 
    Write-Host "=== 1. Module Loading and Integration ===" -ForegroundColor Cyan
    
    # Test 1: Module Import
    $startTime = Get-Date
    try {
        Import-Module Unity-Claude-ClaudeParallelization -Force
        $module = Get-Module Unity-Claude-ClaudeParallelization
        $success = ($module -ne $null -and $module.ExportedFunctions.Count -gt 0)
        $message = if ($success) { "Module loaded with $($module.ExportedFunctions.Count) functions" } else { "Module failed to load" }
    } catch {
        $success = $false
        $message = "Import failed: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Claude Parallelization Module Import" $success $message $duration "ModuleLoading"
    
    Write-Host ""
    Write-Host "=== 2. Claude API Parallel Processing ===" -ForegroundColor Cyan
    
    # Test 2: Claude Parallel Submitter Creation
    $startTime = Get-Date
    try {
        $submitter = New-ClaudeParallelSubmitter -SubmitterName "TestAPISubmitter" -MaxConcurrentRequests 8 -EnableRateLimiting -EnableResourceMonitoring
        $success = ($submitter -and $submitter.SubmitterName -eq "TestAPISubmitter")
        $message = if ($success) { "Submitter created: $($submitter.SubmitterName), Max: $($submitter.MaxConcurrentRequests)" } else { "Submitter creation failed" }
    } catch {
        $success = $false
        $message = "Submitter creation error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Claude Parallel Submitter Creation" $success $message $duration "ClaudeAPIParallel"
    
    # Test 3: Rate Limit Status
    $startTime = Get-Date
    try {
        $rateLimit = Get-ClaudeAPIRateLimit -Submitter $submitter
        $success = ($rateLimit -and $rateLimit.RemainingRequests -ge 0)
        $message = if ($success) { "Rate limit status: $($rateLimit.RemainingRequests) remaining" } else { "Rate limit check failed" }
    } catch {
        $success = $false
        $message = "Rate limit error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Claude API Rate Limit Status" $success $message $duration "ClaudeAPIParallel"
    
    Write-Host ""
    Write-Host "=== 3. Claude CLI Parallel Processing ===" -ForegroundColor Cyan
    
    # Test 4: CLI Manager Creation
    $startTime = Get-Date
    try {
        $cliManager = New-ClaudeCLIParallelManager -ManagerName "TestCLIManager" -MaxConcurrentCLI 3 -EnableWindowManagement
        $success = ($cliManager -and $cliManager.ManagerName -eq "TestCLIManager")
        $message = if ($success) { "CLI manager created: $($cliManager.ManagerName), Max: $($cliManager.MaxConcurrentCLI)" } else { "CLI manager creation failed" }
    } catch {
        $success = $false
        $message = "CLI manager error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Claude CLI Parallel Manager Creation" $success $message $duration "ClaudeCLIParallel"
    
    Write-Host ""
    Write-Host "=== 4. Response Processing and Performance ===" -ForegroundColor Cyan
    
    # Test 5: Response Monitoring
    $startTime = Get-Date
    try {
        $monitoring = Start-ConcurrentResponseMonitoring -ResponseProcessor "TestProcessor" -ResponseSources @("JSON", "Text") -ProcessingMode "Parallel"
        $success = ($monitoring -and $monitoring.ProcessorName -eq "TestProcessor")
        $message = if ($success) { "Response monitoring started: $($monitoring.ProcessorName)" } else { "Response monitoring failed" }
    } catch {
        $success = $false
        $message = "Response monitoring error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Claude Response Parallel Monitoring" $success $message $duration "ResponseProcessing"
    
    # Test 6: Performance Test
    $startTime = Get-Date
    try {
        $perfResults = Test-ClaudeParallelizationPerformance -TestType "API" -TestPrompts @("Test prompt 1", "Test prompt 2") -Iterations 5
        $success = ($perfResults -and $perfResults.TestCompleted)
        $message = if ($success) { "Performance test: $($perfResults.TotalRequests) requests in $($perfResults.Duration)ms" } else { "Performance test failed" }
    } catch {
        $success = $false
        $message = "Performance test error: $($_.Exception.Message)"
    }
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-TestResult "Claude Parallelization Performance Test" $success $message $duration "Performance"
    
    # Calculate final results
    $TestResults.EndTime = Get-Date
    $TestResults.Summary.Duration = (($TestResults.EndTime - $TestResults.StartTime).TotalSeconds)
    $TestResults.Summary.PassRate = if ($TestResults.Summary.Total -gt 0) { 
        [math]::Round(($TestResults.Summary.Passed / $TestResults.Summary.Total) * 100, 2) 
    } else { 0 }
    
    # Display summary
    Write-Host ""
    Write-Host "=== Claude Parallelization Testing Results Summary ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Testing Execution Summary:" -ForegroundColor White
    Write-Host "Total Tests: $($TestResults.Summary.Total)" -ForegroundColor White
    Write-Host "Passed: $($TestResults.Summary.Passed)" -ForegroundColor Green
    Write-Host "Failed: $($TestResults.Summary.Failed)" -ForegroundColor Red
    Write-Host "Duration: $($TestResults.Summary.Duration) seconds" -ForegroundColor White
    Write-Host "Pass Rate: $($TestResults.Summary.PassRate)%" -ForegroundColor $(if ($TestResults.Summary.PassRate -ge 80) { "Green" } else { "Red" })
    
    Write-Host ""
    Write-Host "Category Breakdown:" -ForegroundColor White
    foreach ($category in $TestResults.Categories.GetEnumerator()) {
        $cat = $category.Value
        $catPassRate = if ($cat.Total -gt 0) { [math]::Round(($cat.Passed / $cat.Total) * 100, 2) } else { 0 }
        $color = if ($catPassRate -ge 80) { "Green" } else { "Red" }
        Write-Host "$($category.Key): $($cat.Passed)/$($cat.Total) ($catPassRate%)" -ForegroundColor $color
    }
    
    # Final status
    if ($TestResults.Summary.PassRate -ge 80) {
        Write-Host "WEEK 3 DAYS 3-4 CLAUDE PARALLELIZATION: SUCCESS" -ForegroundColor Green
        Write-Host "Claude parallelization infrastructure operational" -ForegroundColor Green
    } else {
        Write-Host "WEEK 3 DAYS 3-4 CLAUDE PARALLELIZATION: NEEDS ATTENTION" -ForegroundColor Yellow
        Write-Host "Some Claude parallelization components need fixes" -ForegroundColor Yellow
    }
    
    # Save results if requested
    if ($SaveResults) {
        $resultsFile = "ClaudeParallelization_Fixed_Test_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $TestResults | ConvertTo-Json -Depth 3 | Out-File $resultsFile
        Write-Host "Results saved to: $resultsFile" -ForegroundColor Green
    }
    
} catch {
    Write-Host "=== CLAUDE PARALLELIZATION TESTING: FAILED ===" -ForegroundColor Red
    Write-Host "Critical error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUPvKAR3O3/AWfYKJ9QjPw60eL
# slugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUGAgtvg8vlv78ymcjcIbjl++tXMkwDQYJKoZIhvcNAQEBBQAEggEASZOw
# sL+d94Gp66zwQ6ykPlaiOhA9vz8sM+CI3z4NHsh/Ybxq50WQkqWsQzgPAw+Io5HJ
# T070QYcBVMC4/nQ/1qIiLQAslj3iMIANvhveDo5Z0R/64ZYbzOH0CqLSVRPpXcKP
# Mv5e3YaHnun72OGzsOPKgpl0RZ8/kISK+JBZJ/ADmjIfu2QkQVhkQsrEF1yaNXG5
# 83FNNDbfvcc9OyR7MtYbwdBh5K8nwJQM0Tri2ZcZ2Qb7no6VxerEF/VSzIX2OobY
# 5nT4oKZKYX1aGQ/TUfiEE0uT4IBufrPGgT9LJ4qLjOIFHo0WDw/JcmyviSkV+I9/
# vc9vlR5bHHTEehIyVQ==
# SIG # End signature block
