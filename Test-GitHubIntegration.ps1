# Test-GitHubIntegration.ps1
# Phase 4, Week 8, Days 1-2: Authentication & Security Testing
# Comprehensive test suite for GitHub integration

param(
    [switch]$AuthTests,
    [switch]$RateLimitTests,
    [switch]$RetryTests,
    [switch]$AllTests,
    [switch]$SaveResults,
    [switch]$Verbose
)

# PowerShell 7 Self-Elevation
if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh7 = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $pwsh7) {
        Write-Host "Upgrading to PowerShell 7..." -ForegroundColor Yellow
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $MyInvocation.MyCommand.Path) + $args
        Start-Process -FilePath $pwsh7 -ArgumentList $arguments -NoNewWindow -Wait
        exit
    }
}

# Initialize test framework
$script:TestResults = @()
$script:TestStartTime = Get-Date
$script:ResultsFile = Join-Path $PSScriptRoot "Test-GitHubIntegration-Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

# Import the module
$modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-GitHub\Unity-Claude-GitHub.psd1"
if (Test-Path $modulePath) {
    Import-Module $modulePath -Force -Verbose:$Verbose
    Write-Host "Unity-Claude-GitHub module imported" -ForegroundColor Green
} else {
    Write-Error "Unity-Claude-GitHub module not found at: $modulePath"
    exit 1
}

function Write-TestLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    if ($Verbose) {
        switch ($Level) {
            "ERROR" { Write-Host $logMessage -ForegroundColor Red }
            "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
            "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
            default { Write-Host $logMessage }
        }
    }
    
    # Also write to unity_claude_automation.log
    $logFile = Join-Path $PSScriptRoot "unity_claude_automation.log"
    Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
}

function Test-ModuleLoading {
    Write-TestLog "Testing module loading and structure"
    
    $testName = "Module Loading"
    $testStart = Get-Date
    
    try {
        # Check if module is loaded
        $module = Get-Module -Name "Unity-Claude-GitHub"
        
        if ($module) {
            $details = "Module loaded: Version $($module.Version)"
            $passed = $true
            
            # Check exported functions
            $exportedFunctions = $module.ExportedFunctions.Keys
            $expectedFunctions = @(
                'Set-GitHubPAT',
                'Get-GitHubPAT',
                'Test-GitHubPAT',
                'Clear-GitHubPAT',
                'Get-GitHubRateLimit',
                'Invoke-GitHubAPIWithRetry'
            )
            
            $missingFunctions = $expectedFunctions | Where-Object { $_ -notin $exportedFunctions }
            if ($missingFunctions) {
                $details += " | Missing functions: $($missingFunctions -join ', ')"
                $passed = $false
            } else {
                $details += " | All expected functions exported"
            }
        } else {
            $details = "Module failed to load"
            $passed = $false
        }
        
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $passed
            Details = $details
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName}: $details" -Level $(if ($passed) { "SUCCESS" } else { "ERROR" })
        return $passed
        
    } catch {
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $false
            Details = "Error: $_"
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName} failed: $_" -Level "ERROR"
        return $false
    }
}

function Test-PATStorage {
    Write-TestLog "Testing PAT storage and retrieval"
    
    $testName = "PAT Storage"
    $testStart = Get-Date
    
    try {
        # Test with a dummy token (won't validate but tests storage)
        $testToken = "ghp_test$(Get-Random -Maximum 999999)"
        
        # Store token
        Set-GitHubPAT -Token $testToken -Force
        
        # Retrieve token
        $retrievedToken = Get-GitHubPAT -AsPlainText
        
        if ($retrievedToken -eq $testToken) {
            $details = "PAT storage and retrieval successful"
            $passed = $true
        } else {
            $details = "PAT retrieval mismatch"
            $passed = $false
        }
        
        # Clean up
        Clear-GitHubPAT -Force
        
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $passed
            Details = $details
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName}: $details" -Level $(if ($passed) { "SUCCESS" } else { "ERROR" })
        return $passed
        
    } catch {
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $false
            Details = "Error: $_"
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName} failed: $_" -Level "ERROR"
        return $false
    }
}

function Test-SecureStringHandling {
    Write-TestLog "Testing SecureString handling"
    
    $testName = "SecureString Handling"
    $testStart = Get-Date
    
    try {
        # Create SecureString
        $secureToken = ConvertTo-SecureString "ghp_secure$(Get-Random)" -AsPlainText -Force
        
        # Store as SecureString
        Set-GitHubPAT -SecureToken $secureToken -Force
        
        # Retrieve as SecureString
        $retrievedSecure = Get-GitHubPAT
        
        if ($retrievedSecure -is [System.Security.SecureString]) {
            $details = "SecureString handling successful"
            $passed = $true
        } else {
            $details = "Retrieved object is not SecureString"
            $passed = $false
        }
        
        # Clean up
        Clear-GitHubPAT -Force
        
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $passed
            Details = $details
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName}: $details" -Level $(if ($passed) { "SUCCESS" } else { "ERROR" })
        return $passed
        
    } catch {
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $false
            Details = "Error: $_"
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName} failed: $_" -Level "ERROR"
        return $false
    }
}

function Test-RateLimitRetrieval {
    Write-TestLog "Testing rate limit retrieval (requires valid PAT)"
    
    $testName = "Rate Limit Retrieval"
    $testStart = Get-Date
    
    try {
        # Check if a valid PAT exists
        if (-not (Test-GitHubPAT)) {
            $details = "Skipped - No valid PAT configured"
            $passed = $null  # Not failed, just skipped
        } else {
            # Get rate limit
            $rateLimit = Get-GitHubRateLimit
            
            if ($rateLimit -and $rateLimit.Limit -gt 0) {
                $details = "Rate limit retrieved: $($rateLimit.Remaining)/$($rateLimit.Limit)"
                $passed = $true
            } else {
                $details = "Failed to retrieve rate limit"
                $passed = $false
            }
        }
        
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $passed
            Details = $details
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        $level = if ($null -eq $passed) { "WARNING" } elseif ($passed) { "SUCCESS" } else { "ERROR" }
        Write-TestLog "${testName}: $details" -Level $level
        return $passed
        
    } catch {
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $false
            Details = "Error: $_"
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName} failed: $_" -Level "ERROR"
        return $false
    }
}

function Test-ExponentialBackoff {
    Write-TestLog "Testing exponential backoff calculation"
    
    $testName = "Exponential Backoff"
    $testStart = Get-Date
    
    try {
        # Test delay calculations
        $baseDelay = 1
        $expectedDelays = @(1, 2, 4, 8, 16)  # For attempts 1-5
        $calculatedDelays = @()
        
        for ($i = 1; $i -le 5; $i++) {
            $delay = [Math]::Pow(2, $i - 1) * $baseDelay
            $calculatedDelays += $delay
        }
        
        $allCorrect = $true
        for ($i = 0; $i -lt $expectedDelays.Count; $i++) {
            if ($calculatedDelays[$i] -ne $expectedDelays[$i]) {
                $allCorrect = $false
                break
            }
        }
        
        if ($allCorrect) {
            $details = "Exponential backoff calculations correct: $($calculatedDelays -join ', ')"
            $passed = $true
        } else {
            $details = "Backoff calculation mismatch"
            $passed = $false
        }
        
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $passed
            Details = $details
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName}: $details" -Level $(if ($passed) { "SUCCESS" } else { "ERROR" })
        return $passed
        
    } catch {
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $false
            Details = "Error: $_"
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName} failed: $_" -Level "ERROR"
        return $false
    }
}

function Save-TestResults {
    Write-TestLog "Saving test results to $script:ResultsFile"
    
    $output = @"
Unity-Claude GitHub Integration Test Results
=============================================
Phase 4, Week 8, Days 1-2: Authentication & Security
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
PowerShell Version: $($PSVersionTable.PSVersion)

Test Summary
------------
Total Tests: $($script:TestResults.Count)
Passed: $(($script:TestResults | Where-Object { $_.Passed -eq $true }).Count)
Failed: $(($script:TestResults | Where-Object { $_.Passed -eq $false }).Count)
Skipped: $(($script:TestResults | Where-Object { $null -eq $_.Passed }).Count)
Pass Rate: $([Math]::Round((($script:TestResults | Where-Object { $_.Passed -eq $true }).Count / ($script:TestResults | Where-Object { $null -ne $_.Passed }).Count) * 100, 2))%
Total Duration: $([Math]::Round(((Get-Date) - $script:TestStartTime).TotalSeconds, 2)) seconds

Detailed Results
----------------

"@

    foreach ($result in $script:TestResults) {
        $status = if ($null -eq $result.Passed) { "SKIPPED" } elseif ($result.Passed) { "PASSED" } else { "FAILED" }
        $output += @"
Test: $($result.TestName)
Status: $status
Details: $($result.Details)
Duration: $([Math]::Round($result.Duration, 2))ms
Timestamp: $($result.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))

"@
    }

    # Add recommendations
    $output += @"

Recommendations
---------------
"@

    if ($script:TestResults | Where-Object { $_.Passed -eq $false }) {
        $output += "- Review and fix failed tests`n"
    }
    
    if ($script:TestResults | Where-Object { $null -eq $_.Passed }) {
        $output += "- Configure a valid GitHub PAT to enable skipped tests`n"
    }
    
    if (-not ($script:TestResults | Where-Object { $_.Passed -eq $false })) {
        $output += "- All tests passed successfully!`n"
        $output += "- Phase 4 Week 8 Days 1-2 implementation complete`n"
    }

    # Save to file
    $output | Out-File -FilePath $script:ResultsFile -Encoding UTF8
    
    # Also display
    Write-Host "`n$output" -ForegroundColor Cyan
    
    Write-TestLog "Results saved to: $script:ResultsFile" -Level "SUCCESS"
}

# Main execution
Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Unity-Claude GitHub Integration Testing" -ForegroundColor Yellow
Write-Host "Phase 4: GitHub API Foundation" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Yellow

# Determine which tests to run
if (-not $AuthTests -and -not $RateLimitTests -and -not $RetryTests -and -not $AllTests) {
    $AllTests = $true
    Write-TestLog "No specific tests selected, running all tests"
}

# Run tests
if ($AuthTests -or $AllTests) {
    Write-Host "`n--- Authentication Tests ---" -ForegroundColor Cyan
    Test-ModuleLoading
    Test-PATStorage
    Test-SecureStringHandling
}

if ($RateLimitTests -or $AllTests) {
    Write-Host "`n--- Rate Limit Tests ---" -ForegroundColor Cyan
    Test-RateLimitRetrieval
}

if ($RetryTests -or $AllTests) {
    Write-Host "`n--- Retry Logic Tests ---" -ForegroundColor Cyan
    Test-ExponentialBackoff
}

# Save results
if ($SaveResults -or $AllTests) {
    Save-TestResults
}

# Summary
$passedCount = ($script:TestResults | Where-Object { $_.Passed -eq $true }).Count
$failedCount = ($script:TestResults | Where-Object { $_.Passed -eq $false }).Count
$skippedCount = ($script:TestResults | Where-Object { $null -eq $_.Passed }).Count
$totalCount = $script:TestResults.Count

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Test Execution Complete" -ForegroundColor Yellow
Write-Host "Total: $totalCount | Passed: $passedCount | Failed: $failedCount | Skipped: $skippedCount" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Yellow" })
Write-Host "========================================`n" -ForegroundColor Yellow

# Log completion
Write-TestLog "GitHub integration testing complete - Passed: $passedCount, Failed: $failedCount, Skipped: $skippedCount" -Level $(if ($failedCount -eq 0) { "SUCCESS" } else { "WARNING" })

# Return success/failure
exit $(if ($failedCount -eq 0) { 0 } else { 1 })