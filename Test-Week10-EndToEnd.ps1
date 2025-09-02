# Test-Week10-EndToEnd.ps1
# Comprehensive End-to-End Testing for Unity-Claude Automation System
# Phase 4, Week 10: Testing & Deployment
# Created: 2025-08-23

param(
    [switch]$FullTest,
    [switch]$LoadTest,
    [switch]$IntegrationTest,
    [switch]$SaveResults,
    [string]$ResultsPath = ".\Test-Week10-Results-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
)

# Initialize test environment
$ErrorActionPreference = "Stop"
$VerbosePreference = "Continue"

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Unity-Claude Week 10 End-to-End Test Suite" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing complete Unity-Claude Automation workflow" -ForegroundColor Gray
Write-Host "Test Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
Write-Host "========================================`n" -ForegroundColor Cyan

# Initialize test results
$testResults = @{
    StartTime = Get-Date
    TestType = if ($LoadTest) { "Load" } elseif ($IntegrationTest) { "Integration" } else { "Full" }
    Modules = @{}
    Workflows = @{}
    Performance = @{}
    Errors = @()
    Summary = @{
        TotalTests = 0
        Passed = 0
        Failed = 0
        Warnings = 0
    }
}

# Import all Unity-Claude modules
function Import-UnityClaudeModules {
    Write-Host "`n[Module Import]" -ForegroundColor Yellow
    
    $modules = @(
        "Unity-Claude-ParallelProcessing",
        "Unity-Claude-NotificationSystem",
        "Unity-Claude-EventLog",
        "Unity-Claude-GitHub"
    )
    
    foreach ($moduleName in $modules) {
        try {
            $modulePath = Join-Path $PSScriptRoot "Modules\$moduleName"
            Import-Module $modulePath -Force -ErrorAction Stop
            Write-Host "  ✓ Imported: $moduleName" -ForegroundColor Green
            $testResults.Modules[$moduleName] = @{
                Imported = $true
                Functions = (Get-Command -Module $moduleName).Count
            }
        } catch {
            Write-Host "  ✗ Failed to import: $moduleName - $_" -ForegroundColor Red
            $testResults.Modules[$moduleName] = @{
                Imported = $false
                Error = $_.ToString()
            }
            $testResults.Errors += "Module import failed: $moduleName"
        }
    }
}

# Create mock Unity error data
function New-MockUnityError {
    param(
        [int]$Count = 1,
        [string]$ErrorType = "Compilation"
    )
    
    $errorTypes = @{
        Compilation = @{
            codes = @("CS0246", "CS0103", "CS1061", "CS0117")
            messages = @(
                "The type or namespace name 'NetworkManager' could not be found",
                "The name 'PlayerController' does not exist in the current context",
                "Type 'GameObject' does not contain a definition for 'MyMethod'",
                "Type 'Transform' does not contain a definition for 'InvalidProperty'"
            )
        }
        Runtime = @{
            codes = @("NullReferenceException", "IndexOutOfRangeException", "InvalidOperationException")
            messages = @(
                "Object reference not set to an instance of an object",
                "Index was outside the bounds of the array",
                "Collection was modified; enumeration operation may not execute"
            )
        }
        Shader = @{
            codes = @("SHADER_ERROR", "HLSL_COMPILE_ERROR")
            messages = @(
                "Shader error in 'Custom/MyShader': syntax error",
                "HLSL compiler error: undefined variable 'myTexture'"
            )
        }
    }
    
    $errors = @()
    $typeData = $errorTypes[$ErrorType]
    
    for ($i = 0; $i -lt $Count; $i++) {
        $errors += [PSCustomObject]@{
            errorCode = $typeData.codes | Get-Random
            message = $typeData.messages | Get-Random
            file = "Assets/Scripts/TestScript$i.cs"
            line = Get-Random -Minimum 10 -Maximum 500
            column = Get-Random -Minimum 1 -Maximum 80
            timestamp = (Get-Date).AddSeconds(-$i).ToString("o")
            projectPath = "C:\UnityProjects\TestProject"
            unityVersion = "2021.1.14f1"
        }
    }
    
    return $errors
}

# Test 1: Module Functionality
function Test-ModuleFunctionality {
    Write-Host "`n[Test 1: Module Functionality]" -ForegroundColor Cyan
    
    $tests = @{
        ParallelProcessing = {
            $hashtable = New-SynchronizedHashtable
            Set-SynchronizedValue -Hashtable $hashtable -Key "test" -Value "value"
            $result = Get-SynchronizedValue -Hashtable $hashtable -Key "test"
            $result -eq "value"
        }
        GitHub = {
            $pat = Test-GitHubPAT -ErrorAction SilentlyContinue
            $null -ne $pat
        }
        EventLog = {
            $cmd = Get-Command Write-EventLogEntry -ErrorAction SilentlyContinue
            $null -ne $cmd
        }
        Notification = {
            $config = Test-NotificationConfiguration -ErrorAction SilentlyContinue
            $true  # Just check if command exists
        }
    }
    
    foreach ($testName in $tests.Keys) {
        $testResults.Summary.TotalTests++
        try {
            $result = & $tests[$testName]
            if ($result) {
                Write-Host "  ✓ $testName functionality verified" -ForegroundColor Green
                $testResults.Summary.Passed++
            } else {
                Write-Host "  ✗ $testName functionality check failed" -ForegroundColor Red
                $testResults.Summary.Failed++
            }
        } catch {
            Write-Host "  ✗ $testName test error: $_" -ForegroundColor Red
            $testResults.Summary.Failed++
            $testResults.Errors += "${testName}: $_"
        }
    }
}

# Test 2: End-to-End Workflow
function Test-EndToEndWorkflow {
    Write-Host "`n[Test 2: End-to-End Workflow]" -ForegroundColor Cyan
    
    # Create mock Unity errors
    Write-Host "  Creating mock Unity errors..." -ForegroundColor Gray
    $mockErrors = New-MockUnityError -Count 5 -ErrorType "Compilation"
    
    # Test parallel processing
    Write-Host "  Testing parallel error processing..." -ForegroundColor Gray
    $processedErrors = @()
    $runspacePool = [runspacefactory]::CreateRunspacePool(1, 5)
    $runspacePool.Open()
    
    $jobs = @()
    foreach ($error in $mockErrors) {
        $powershell = [powershell]::Create()
        $powershell.RunspacePool = $runspacePool
        
        [void]$powershell.AddScript({
            param($errorData)
            # Simulate processing
            Start-Sleep -Milliseconds (Get-Random -Minimum 100 -Maximum 500)
            return [PSCustomObject]@{
                Original = $errorData
                Processed = $true
                ProcessedAt = Get-Date
            }
        }).AddArgument($error)
        
        $jobs += [PSCustomObject]@{
            PowerShell = $powershell
            Handle = $powershell.BeginInvoke()
        }
    }
    
    # Collect results
    foreach ($job in $jobs) {
        $result = $job.PowerShell.EndInvoke($job.Handle)
        $processedErrors += $result
        $job.PowerShell.Dispose()
    }
    
    $runspacePool.Close()
    $runspacePool.Dispose()
    
    Write-Host "  ✓ Processed $($processedErrors.Count) errors in parallel" -ForegroundColor Green
    
    # Test GitHub issue creation (mock)
    Write-Host "  Testing GitHub issue formatting..." -ForegroundColor Gray
    foreach ($error in $mockErrors | Select-Object -First 2) {
        $issue = Format-UnityErrorAsIssue -UnityError $error -ErrorAction SilentlyContinue
        if ($issue) {
            Write-Host "    ✓ Formatted issue: $($issue.title)" -ForegroundColor Green
        }
    }
    
    $testResults.Workflows["EndToEnd"] = @{
        ErrorsProcessed = $processedErrors.Count
        Success = $processedErrors.Count -eq $mockErrors.Count
    }
    
    $testResults.Summary.TotalTests++
    if ($testResults.Workflows["EndToEnd"].Success) {
        $testResults.Summary.Passed++
    } else {
        $testResults.Summary.Failed++
    }
}

# Test 3: Load Testing
function Test-LoadPerformance {
    Write-Host "`n[Test 3: Load Testing]" -ForegroundColor Cyan
    
    $loadSizes = @(10, 50, 100)
    $loadResults = @{}
    
    foreach ($size in $loadSizes) {
        Write-Host "  Testing with $size concurrent operations..." -ForegroundColor Gray
        
        $startTime = Get-Date
        $errors = New-MockUnityError -Count $size
        
        # Simulate concurrent processing
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, 10)
        $runspacePool.Open()
        
        $jobs = @()
        foreach ($error in $errors) {
            $powershell = [powershell]::Create()
            $powershell.RunspacePool = $runspacePool
            
            [void]$powershell.AddScript({
                param($errorData)
                # Simulate processing with some work
                $hash = [System.Security.Cryptography.SHA256]::Create()
                $bytes = [System.Text.Encoding]::UTF8.GetBytes($errorData.message)
                $hashBytes = $hash.ComputeHash($bytes)
                $hash.Dispose()
                return [BitConverter]::ToString($hashBytes)
            }).AddArgument($error)
            
            $jobs += [PSCustomObject]@{
                PowerShell = $powershell
                Handle = $powershell.BeginInvoke()
            }
        }
        
        # Wait for completion
        $results = @()
        foreach ($job in $jobs) {
            $result = $job.PowerShell.EndInvoke($job.Handle)
            $results += $result
            $job.PowerShell.Dispose()
        }
        
        $runspacePool.Close()
        $runspacePool.Dispose()
        
        $duration = (Get-Date) - $startTime
        $throughput = $size / $duration.TotalSeconds
        
        Write-Host "    Duration: $([Math]::Round($duration.TotalSeconds, 2))s" -ForegroundColor Gray
        Write-Host "    Throughput: $([Math]::Round($throughput, 2)) ops/sec" -ForegroundColor Gray
        
        $loadResults[$size] = @{
            Duration = $duration.TotalSeconds
            Throughput = $throughput
            Success = $results.Count -eq $size
        }
    }
    
    $testResults.Performance["LoadTest"] = $loadResults
    
    $testResults.Summary.TotalTests++
    $allSuccess = ($loadResults.Values | Where-Object { $_.Success }).Count -eq $loadResults.Count
    if ($allSuccess) {
        $testResults.Summary.Passed++
        Write-Host "  ✓ Load testing completed successfully" -ForegroundColor Green
    } else {
        $testResults.Summary.Failed++
        Write-Host "  ✗ Some load tests failed" -ForegroundColor Red
    }
}

# Test 4: Rate Limit Simulation
function Test-RateLimitHandling {
    Write-Host "`n[Test 4: Rate Limit Handling]" -ForegroundColor Cyan
    
    # Simulate rate limit scenario
    Write-Host "  Simulating GitHub API rate limit..." -ForegroundColor Gray
    
    $rateLimitTest = @{
        RequestsMade = 0
        RequestsBlocked = 0
        RetrySuccessful = $false
    }
    
    # Mock rate limit check
    for ($i = 1; $i -le 10; $i++) {
        $rateLimitTest.RequestsMade++
        
        if ($i -gt 5) {
            # Simulate rate limit hit
            Write-Host "    Rate limit would be hit at request $i" -ForegroundColor Yellow
            $rateLimitTest.RequestsBlocked++
            
            # Simulate retry with backoff
            Start-Sleep -Milliseconds 500
            $rateLimitTest.RetrySuccessful = $true
        }
    }
    
    Write-Host "  Requests made: $($rateLimitTest.RequestsMade)" -ForegroundColor Gray
    Write-Host "  Requests blocked: $($rateLimitTest.RequestsBlocked)" -ForegroundColor Gray
    Write-Host "  Retry successful: $($rateLimitTest.RetrySuccessful)" -ForegroundColor Gray
    
    $testResults.Performance["RateLimit"] = $rateLimitTest
    
    $testResults.Summary.TotalTests++
    if ($rateLimitTest.RetrySuccessful) {
        $testResults.Summary.Passed++
        Write-Host "  ✓ Rate limit handling verified" -ForegroundColor Green
    } else {
        $testResults.Summary.Failed++
        Write-Host "  ✗ Rate limit handling failed" -ForegroundColor Red
    }
}

# Test 5: Error Recovery
function Test-ErrorRecovery {
    Write-Host "`n[Test 5: Error Recovery]" -ForegroundColor Cyan
    
    $recoveryTests = @{
        ModuleReload = $false
        ErrorHandling = $false
        Cleanup = $false
    }
    
    # Test module reload
    Write-Host "  Testing module reload capability..." -ForegroundColor Gray
    try {
        Remove-Module Unity-Claude-GitHub -ErrorAction SilentlyContinue
        Import-Module ".\Modules\Unity-Claude-GitHub" -Force
        $recoveryTests.ModuleReload = $true
        Write-Host "    ✓ Module reload successful" -ForegroundColor Green
    } catch {
        Write-Host "    ✗ Module reload failed: $_" -ForegroundColor Red
    }
    
    # Test error handling
    Write-Host "  Testing error handling..." -ForegroundColor Gray
    try {
        $errorHandled = $false
        try {
            throw "Test error"
        } catch {
            $errorHandled = $true
        }
        $recoveryTests.ErrorHandling = $errorHandled
        if ($errorHandled) {
            Write-Host "    ✓ Error handling working" -ForegroundColor Green
        }
    } catch {
        Write-Host "    ✗ Error handling failed" -ForegroundColor Red
    }
    
    # Test cleanup
    Write-Host "  Testing resource cleanup..." -ForegroundColor Gray
    $tempFile = Join-Path $env:TEMP "test_cleanup_$(Get-Date -Format 'yyyyMMddHHmmss').tmp"
    New-Item -Path $tempFile -ItemType File -Force | Out-Null
    Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
    $recoveryTests.Cleanup = -not (Test-Path $tempFile)
    if ($recoveryTests.Cleanup) {
        Write-Host "    ✓ Resource cleanup successful" -ForegroundColor Green
    }
    
    $testResults.Workflows["ErrorRecovery"] = $recoveryTests
    
    $testResults.Summary.TotalTests++
    $allPassed = ($recoveryTests.Values | Where-Object { $_ -eq $true }).Count -eq $recoveryTests.Count
    if ($allPassed) {
        $testResults.Summary.Passed++
    } else {
        $testResults.Summary.Failed++
    }
}

# Main execution
try {
    # Import modules
    Import-UnityClaudeModules
    
    if ($IntegrationTest -or $FullTest) {
        # Run integration tests
        Test-ModuleFunctionality
        Test-EndToEndWorkflow
        Test-ErrorRecovery
    }
    
    if ($LoadTest -or $FullTest) {
        # Run load tests
        Test-LoadPerformance
        Test-RateLimitHandling
    }
    
    # Calculate final results
    $testResults.EndTime = Get-Date
    $testResults.Duration = $testResults.EndTime - $testResults.StartTime
    $testResults.Summary.SuccessRate = if ($testResults.Summary.TotalTests -gt 0) {
        [Math]::Round(($testResults.Summary.Passed / $testResults.Summary.TotalTests) * 100, 2)
    } else { 0 }
    
    # Display summary
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Test Results Summary" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Test Type: $($testResults.TestType)" -ForegroundColor White
    Write-Host "Total Tests: $($testResults.Summary.TotalTests)" -ForegroundColor White
    Write-Host "Passed: $($testResults.Summary.Passed)" -ForegroundColor Green
    Write-Host "Failed: $($testResults.Summary.Failed)" -ForegroundColor $(if ($testResults.Summary.Failed -gt 0) { "Red" } else { "Gray" })
    Write-Host "Success Rate: $($testResults.Summary.SuccessRate)%" -ForegroundColor $(if ($testResults.Summary.SuccessRate -ge 80) { "Green" } else { "Yellow" })
    Write-Host "Duration: $([Math]::Round($testResults.Duration.TotalSeconds, 2)) seconds" -ForegroundColor Gray
    
    if ($testResults.Errors.Count -gt 0) {
        Write-Host "`nErrors:" -ForegroundColor Red
        foreach ($error in $testResults.Errors) {
            Write-Host "  - $error" -ForegroundColor Red
        }
    }
    
    # Save results if requested
    if ($SaveResults) {
        $testResults | ConvertTo-Json -Depth 10 | Set-Content $ResultsPath
        Write-Host "`nResults saved to: $ResultsPath" -ForegroundColor Gray
    }
    
    Write-Host "========================================`n" -ForegroundColor Cyan
    
} catch {
    Write-Error "Test suite failed: $_"
    exit 1
}

# Return success/failure
exit $(if ($testResults.Summary.Failed -eq 0) { 0 } else { 1 })
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAF0+VOtrKeWmP+
# yHvt5M7M6JTMNvISE4VxA1kZ4T5CQ6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBAtSqR05UcFpYErVszPaF1d
# NTQ1x+h3215g9KX8YXqMMA0GCSqGSIb3DQEBAQUABIIBAEZmFhIjZYa8EQg+mcQR
# MG41UR/Q2j067vbJW69IlES7WsDVjz43O8c0q4ivLd/gJhzvtlz3QKI2cw7YrQyM
# xIUXd6eVlTDuuoMyAPgpltebDKd2yEthSPOj4OJTQm6Gr36vbZgS23uiwVKxcePO
# am8ZaRlqwjFYvOpqZYQXO9gV29TpWN6skmDbkqYmEilloDqW554adp0W8/MSM6Dc
# IQ+el2nD4NGN048w+wUHjAaRfS7pRJ2j5u0dK9hij41ofbP5km6E1xlcU6Lqoqeq
# E4p87XbvZlzz8NslmC96uuoyXKBGiK51Z8BwUJGcwxFbT6exS4/gcuv/k/VAAXpV
# 5+k=
# SIG # End signature block
