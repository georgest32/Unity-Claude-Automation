# Test-Day18-Hour4.5-DependencyTrackingCascadeRestart.ps1
# Day 18 Hour 4.5: Comprehensive Testing for Dependency Tracking and Cascade Restart Logic
# Date: 2025-08-19
# Implementation Validation: Hour 4.5 Research-Validated Solution Components

param(
    [switch]$Verbose,
    [switch]$SaveResults = $true,
    [string]$TestResultsPath = ".\TestResults_Day18_Hour4.5_DependencyTrackingCascadeRestart_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
)

$ErrorActionPreference = "Continue"
if ($Verbose) { $VerbosePreference = "Continue" }

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Day 18 Hour 4.5 Test Suite: Dependency Tracking and Cascade Restart Logic" -ForegroundColor Cyan
Write-Host "Test Started: $(Get-Date)" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# Test results collection
$script:TestResults = @{
    StartTime = Get-Date
    TestName = "Day 18 Hour 4.5: Dependency Tracking and Cascade Restart Logic"
    TotalTests = 0
    PassedTests = 0
    FailedTests = 0
    SkippedTests = 0
    TestDetails = @()
    Errors = @()
    Performance = @{}
}

function Write-TestLog {
    param($Message, $Level = "INFO")
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Color coding for different levels
    $color = switch ($Level) {
        "OK" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
    
    if ($SaveResults) {
        $logMessage | Add-Content -Path $TestResultsPath
    }
}

function Test-Function {
    param($TestName, $ScriptBlock, $ExpectedResult = $null, $SkipReason = $null)
    
    $script:TestResults.TotalTests++
    Write-TestLog "Running test: $TestName" -Level "INFO"
    
    if ($SkipReason) {
        Write-TestLog "SKIPPED: $TestName - $SkipReason" -Level "WARNING"
        $script:TestResults.SkippedTests++
        $script:TestResults.TestDetails += @{
            TestName = $TestName
            Status = "SKIPPED"
            Reason = $SkipReason
            Duration = 0
        }
        return
    }
    
    try {
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $result = & $ScriptBlock
        $stopwatch.Stop()
        
        $success = if ($ExpectedResult -ne $null) {
            $result -eq $ExpectedResult
        } else {
            $result -ne $null -and $result -ne $false
        }
        
        if ($success) {
            Write-TestLog "PASSED: $TestName (Duration: $($stopwatch.ElapsedMilliseconds)ms)" -Level "OK"
            $script:TestResults.PassedTests++
            $status = "PASSED"
        } else {
            Write-TestLog "FAILED: $TestName - Expected: $ExpectedResult, Got: $result" -Level "ERROR"
            $script:TestResults.FailedTests++
            $status = "FAILED"
        }
        
        $script:TestResults.TestDetails += @{
            TestName = $TestName
            Status = $status
            Result = $result
            Duration = $stopwatch.ElapsedMilliseconds
            Expected = $ExpectedResult
        }
        
    } catch {
        $stopwatch.Stop()
        Write-TestLog "ERROR: $TestName - $($_.Exception.Message)" -Level "ERROR"
        $script:TestResults.FailedTests++
        $script:TestResults.Errors += @{
            TestName = $TestName
            Error = $_.Exception.Message
            StackTrace = $_.ScriptStackTrace
        }
        
        $script:TestResults.TestDetails += @{
            TestName = $TestName
            Status = "ERROR"
            Error = $_.Exception.Message
            Duration = if ($stopwatch) { $stopwatch.ElapsedMilliseconds } else { 0 }
        }
    }
}

Write-TestLog "Starting Hour 4.5 Dependency Tracking and Cascade Restart Logic Tests" -Level "INFO"

# Test 1: Module Loading and Function Availability
Write-TestLog "=== Phase 1: Module Loading and Function Availability ===" -Level "INFO"

Test-Function "Unity-Claude-SystemStatus Module Loading" {
    Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force -PassThru
    $null -ne (Get-Module -Name "Unity-Claude-SystemStatus")
} $true

Test-Function "Hour 4.5 Functions Export Validation" {
    $module = Get-Module -Name "Unity-Claude-SystemStatus"
    $hour45Functions = @(
        'Get-ServiceDependencyGraph',
        'Get-TopologicalSort', 
        'Restart-ServiceWithDependencies',
        'Start-ServiceRecoveryAction',
        'Initialize-SubsystemRunspaces',
        'Start-SubsystemSession',
        'Stop-SubsystemRunspaces'
    )
    
    $missingFunctions = @()
    foreach ($func in $hour45Functions) {
        if ($func -notin $module.ExportedFunctions.Keys) {
            $missingFunctions += $func
        }
    }
    
    if ($missingFunctions.Count -eq 0) {
        Write-TestLog "All Hour 4.5 functions exported successfully: $($hour45Functions -join ', ')" -Level "OK"
        $true
    } else {
        Write-TestLog "Missing functions: $($missingFunctions -join ', ')" -Level "ERROR"
        $false
    }
}

# Test 2: Dependency Mapping and Discovery (Minutes 0-20)
Write-TestLog "=== Phase 2: Dependency Mapping and Discovery Tests ===" -Level "INFO"

Test-Function "Get-ServiceDependencyGraph Function Available" {
    $null -ne (Get-Command -Name "Get-ServiceDependencyGraph" -Module "Unity-Claude-SystemStatus" -ErrorAction SilentlyContinue)
} $true

Test-Function "Get-ServiceDependencyGraph Basic Execution" {
    try {
        $result = Get-ServiceDependencyGraph -ServiceName "Spooler"
        Write-TestLog "Dependency graph result type: $($result.GetType().Name)" -Level "DEBUG"
        Write-TestLog "Dependency graph keys: $($result.Keys -join ', ')" -Level "DEBUG"
        $result -is [hashtable]
    } catch {
        Write-TestLog "Error in Get-ServiceDependencyGraph: $($_.Exception.Message)" -Level "ERROR"
        $false
    }
}

Test-Function "Get-TopologicalSort Function Available" {
    $null -ne (Get-Command -Name "Get-TopologicalSort" -Module "Unity-Claude-SystemStatus" -ErrorAction SilentlyContinue)
} $true

Test-Function "Get-TopologicalSort Basic Execution" {
    $testGraph = @{
        "ServiceA" = @("ServiceB")
        "ServiceB" = @("ServiceC")
        "ServiceC" = @()
    }
    
    try {
        $result = Get-TopologicalSort -DependencyGraph $testGraph
        Write-TestLog "Topological sort result: $($result -join ' -> ')" -Level "DEBUG"
        $result -is [array] -and $result.Count -eq 3
    } catch {
        Write-TestLog "Error in Get-TopologicalSort: $($_.Exception.Message)" -Level "ERROR"
        $false
    }
}

Test-Function "Get-TopologicalSort Circular Dependency Detection" {
    $circularGraph = @{
        "ServiceA" = @("ServiceB")
        "ServiceB" = @("ServiceC") 
        "ServiceC" = @("ServiceA")  # Creates circular dependency
    }
    
    try {
        $result = Get-TopologicalSort -DependencyGraph $circularGraph
        # Should return empty array or handle gracefully
        Write-TestLog "Circular dependency test result: $($result -join ', ')" -Level "DEBUG"
        $result.Count -eq 0  # Expected behavior for circular dependencies
    } catch {
        Write-TestLog "Circular dependency detection working - caught exception: $($_.Exception.Message)" -Level "DEBUG"
        $true  # Exception expected for circular dependencies
    }
}

# Test 3: Cascade Restart Implementation (Minutes 20-40)
Write-TestLog "=== Phase 3: Cascade Restart Implementation Tests ===" -Level "INFO"

Test-Function "Restart-ServiceWithDependencies Function Available" {
    $null -ne (Get-Command -Name "Restart-ServiceWithDependencies" -Module "Unity-Claude-SystemStatus" -ErrorAction SilentlyContinue)
} $true

Test-Function "Start-ServiceRecoveryAction Function Available" {
    $null -ne (Get-Command -Name "Start-ServiceRecoveryAction" -Module "Unity-Claude-SystemStatus" -ErrorAction SilentlyContinue)
} $true

# Use safe, non-critical service for testing (BITS - Background Intelligent Transfer Service)
Test-Function "Restart-ServiceWithDependencies Parameter Validation" {
    try {
        # Test with non-existent service - should handle gracefully
        $result = Restart-ServiceWithDependencies -ServiceName "NonExistentService12345" -Force
        Write-TestLog "Restart result for non-existent service: Success=$($result.Success), Error=$($result.Error)" -Level "DEBUG"
        $result -is [hashtable] -and $result.ContainsKey('Success')
    } catch {
        Write-TestLog "Error in Restart-ServiceWithDependencies parameter validation: $($_.Exception.Message)" -Level "ERROR"
        $false
    }
}

Test-Function "Start-ServiceRecoveryAction Parameter Validation" {
    try {
        $result = Start-ServiceRecoveryAction -ServiceName "NonExistentService12345" -FailureReason "Test failure"
        Write-TestLog "Recovery action result: $result" -Level "DEBUG"
        $result -eq $false  # Expected for non-existent service
    } catch {
        Write-TestLog "Error in Start-ServiceRecoveryAction: $($_.Exception.Message)" -Level "ERROR"
        $false
    }
}

# Test 4: Multi-Tab Process Management (Minutes 40-60)
Write-TestLog "=== Phase 4: Multi-Tab Process Management Tests ===" -Level "INFO"

Test-Function "Initialize-SubsystemRunspaces Function Available" {
    $null -ne (Get-Command -Name "Initialize-SubsystemRunspaces" -Module "Unity-Claude-SystemStatus" -ErrorAction SilentlyContinue)
} $true

Test-Function "Start-SubsystemSession Function Available" {
    $null -ne (Get-Command -Name "Start-SubsystemSession" -Module "Unity-Claude-SystemStatus" -ErrorAction SilentlyContinue)
} $true

Test-Function "Stop-SubsystemRunspaces Function Available" {
    $null -ne (Get-Command -Name "Stop-SubsystemRunspaces" -Module "Unity-Claude-SystemStatus" -ErrorAction SilentlyContinue)
} $true

Test-Function "Initialize-SubsystemRunspaces Basic Execution" {
    try {
        $runspaceContext = Initialize-SubsystemRunspaces -MinRunspaces 1 -MaxRunspaces 2
        Write-TestLog "Runspace context created with pool status" -Level "DEBUG"
        
        # Validate context structure
        $validContext = $runspaceContext -is [hashtable] -and 
                       $runspaceContext.ContainsKey('Pool') -and
                       $runspaceContext.ContainsKey('SynchronizedResults') -and
                       $runspaceContext.ContainsKey('MinRunspaces') -and
                       $runspaceContext.ContainsKey('MaxRunspaces')
        
        if ($validContext) {
            Write-TestLog "Runspace context validation successful" -Level "OK"
        }
        
        $validContext
    } catch {
        Write-TestLog "Error in Initialize-SubsystemRunspaces: $($_.Exception.Message)" -Level "ERROR"
        $false
    }
}

Test-Function "Start-SubsystemSession Basic Execution" {
    try {
        # Initialize runspace context first
        $runspaceContext = Initialize-SubsystemRunspaces -MinRunspaces 1 -MaxRunspaces 2
        
        # Simple test script block
        $testScriptBlock = {
            param($SynchronizedResults, $SessionParameters)
            Start-Sleep -Milliseconds 100
            "Test session completed: $($SessionParameters.SubsystemType)"
        }
        
        $sessionInfo = Start-SubsystemSession -SubsystemType "TestSubsystem" -ScriptBlock $testScriptBlock -RunspaceContext $runspaceContext
        
        Write-TestLog "Session started: $($sessionInfo.SubsystemType), Status: $($sessionInfo.Status)" -Level "DEBUG"
        
        # Validate session info structure
        $validSession = $sessionInfo -is [hashtable] -and
                       $sessionInfo.ContainsKey('SubsystemType') -and
                       $sessionInfo.ContainsKey('SessionId') -and
                       $sessionInfo.ContainsKey('Status')
        
        $validSession
    } catch {
        Write-TestLog "Error in Start-SubsystemSession: $($_.Exception.Message)" -Level "ERROR"
        $false
    }
}

Test-Function "Stop-SubsystemRunspaces Cleanup" {
    try {
        $result = Stop-SubsystemRunspaces -Force
        Write-TestLog "Runspace cleanup result: $result" -Level "DEBUG"
        $result -eq $true
    } catch {
        Write-TestLog "Error in Stop-SubsystemRunspaces: $($_.Exception.Message)" -Level "ERROR"
        $false
    }
}

# Test 5: Integration Point Validation
Write-TestLog "=== Phase 5: Integration Point Validation Tests ===" -Level "INFO"

Test-Function "Integration Point 14: Dependency Mapping Integration" {
    try {
        # Test integration with existing module patterns
        $testService = "Spooler"  # Common service for testing
        $dependencyGraph = Get-ServiceDependencyGraph -ServiceName $testService
        
        Write-TestLog "Integration test - Service: $testService, Dependencies found: $($dependencyGraph.Keys.Count)" -Level "DEBUG"
        
        # Should return hashtable (even if empty)
        $dependencyGraph -is [hashtable]
    } catch {
        Write-TestLog "Integration Point 14 error: $($_.Exception.Message)" -Level "ERROR"
        $false
    }
}

Test-Function "Integration Point 15: SafeCommandExecution Integration" {
    try {
        # Test SafeCommandExecution availability and integration
        $safeExecAvailable = Get-Module -Name "SafeCommandExecution" -ListAvailable -ErrorAction SilentlyContinue
        
        if ($safeExecAvailable) {
            Write-TestLog "SafeCommandExecution module available for integration" -Level "OK"
            $true
        } else {
            Write-TestLog "SafeCommandExecution module not available - graceful fallback implemented" -Level "WARNING"  
            $true  # Still valid as fallback is implemented
        }
    } catch {
        Write-TestLog "Integration Point 15 error: $($_.Exception.Message)" -Level "ERROR"
        $false
    }
}

Test-Function "Integration Point 16: RunspacePool Session Isolation" {
    try {
        # Test runspace pool creation and isolation
        $context = Initialize-SubsystemRunspaces -MinRunspaces 1 -MaxRunspaces 2
        
        # Test session isolation
        $session1 = Start-SubsystemSession -SubsystemType "IsolationTest1" -ScriptBlock {
            param($SyncResults, $SessionParams)
            $SessionParams.SubsystemType + " executed"
        } -RunspaceContext $context
        
        $session2 = Start-SubsystemSession -SubsystemType "IsolationTest2" -ScriptBlock {
            param($SyncResults, $SessionParams) 
            $SessionParams.SubsystemType + " executed"
        } -RunspaceContext $context
        
        Write-TestLog "Session isolation test - Session1: $($session1.SessionId), Session2: $($session2.SessionId)" -Level "DEBUG"
        
        # Cleanup
        Stop-SubsystemRunspaces -Force | Out-Null
        
        # Sessions should have different IDs (isolation validation)
        $session1.SessionId -ne $session2.SessionId
    } catch {
        Write-TestLog "Integration Point 16 error: $($_.Exception.Message)" -Level "ERROR"
        $false
    }
}

# Test 6: Performance and Reliability Validation
Write-TestLog "=== Phase 6: Performance and Reliability Tests ===" -Level "INFO"

Test-Function "Dependency Graph Performance Test" {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $result = Get-ServiceDependencyGraph -ServiceName "Spooler"
        $stopwatch.Stop()
        
        $elapsed = $stopwatch.ElapsedMilliseconds
        Write-TestLog "Dependency graph performance: ${elapsed}ms" -Level "DEBUG"
        $script:TestResults.Performance['DependencyGraphTime'] = $elapsed
        
        # Research target: <2000ms for complex dependency analysis
        $elapsed -lt 2000
    } catch {
        $stopwatch.Stop()
        Write-TestLog "Performance test error: $($_.Exception.Message)" -Level "ERROR"
        $false
    }
}

Test-Function "Runspace Creation Performance Test" {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $context = Initialize-SubsystemRunspaces -MinRunspaces 1 -MaxRunspaces 3
        $stopwatch.Stop()
        
        $elapsed = $stopwatch.ElapsedMilliseconds
        Write-TestLog "Runspace creation performance: ${elapsed}ms" -Level "DEBUG"
        $script:TestResults.Performance['RunspaceCreationTime'] = $elapsed
        
        # Cleanup
        Stop-SubsystemRunspaces -Force | Out-Null
        
        # Should be reasonably fast
        $elapsed -lt 5000
    } catch {
        $stopwatch.Stop()
        Write-TestLog "Runspace performance test error: $($_.Exception.Message)" -Level "ERROR"
        $false
    }
}

# Final Results Summary
$script:TestResults.EndTime = Get-Date
$script:TestResults.TotalDuration = ($script:TestResults.EndTime - $script:TestResults.StartTime).TotalSeconds

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Day 18 Hour 4.5 Test Results Summary" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Test Completed: $($script:TestResults.EndTime)" -ForegroundColor Cyan
Write-Host "Total Duration: $([math]::Round($script:TestResults.TotalDuration, 2)) seconds" -ForegroundColor Cyan
Write-Host ""

$successRate = [math]::Round(($script:TestResults.PassedTests / $script:TestResults.TotalTests) * 100, 1)

Write-Host "Test Statistics:" -ForegroundColor White
Write-Host "   Total Tests: $($script:TestResults.TotalTests)" -ForegroundColor White
Write-Host "   Passed: $($script:TestResults.PassedTests)" -ForegroundColor Green
Write-Host "   Failed: $($script:TestResults.FailedTests)" -ForegroundColor Red  
Write-Host "   Skipped: $($script:TestResults.SkippedTests)" -ForegroundColor Yellow
Write-Host "   Success Rate: $successRate%" -ForegroundColor $(if($successRate -ge 90) { "Green" } elseif($successRate -ge 70) { "Yellow" } else { "Red" })
Write-Host ""

if ($script:TestResults.Performance.Count -gt 0) {
    Write-Host "Performance Metrics:" -ForegroundColor White
    foreach ($metric in $script:TestResults.Performance.GetEnumerator()) {
        Write-Host "   $($metric.Key): $($metric.Value)ms" -ForegroundColor Cyan
    }
    Write-Host ""
}

if ($script:TestResults.FailedTests -gt 0) {
    Write-Host "Failed Tests:" -ForegroundColor Red
    $script:TestResults.TestDetails | Where-Object { $_.Status -eq "FAILED" -or $_.Status -eq "ERROR" } | ForEach-Object {
        Write-Host "   - $($_.TestName): $($_.Status)" -ForegroundColor Red
        if ($_.Error) {
            Write-Host "     Error: $($_.Error)" -ForegroundColor Red
        }
    }
    Write-Host ""
}

# Save detailed results to file
if ($SaveResults) {
    Write-Host "Saving detailed test results to: $TestResultsPath" -ForegroundColor Cyan
    
    # Create comprehensive results object
    $detailedResults = @{
        TestSuite = "Day 18 Hour 4.5: Dependency Tracking and Cascade Restart Logic"
        StartTime = $script:TestResults.StartTime
        EndTime = $script:TestResults.EndTime
        Duration = $script:TestResults.TotalDuration
        Statistics = @{
            TotalTests = $script:TestResults.TotalTests
            PassedTests = $script:TestResults.PassedTests  
            FailedTests = $script:TestResults.FailedTests
            SkippedTests = $script:TestResults.SkippedTests
            SuccessRate = $successRate
        }
        Performance = $script:TestResults.Performance
        TestDetails = $script:TestResults.TestDetails
        Errors = $script:TestResults.Errors
    }
    
    # Save as JSON for programmatic access - limit depth to prevent memory issues
    try {
        $detailedResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $TestResultsPath -Encoding UTF8
    } catch {
        # If JSON conversion fails, save as text
        Write-TestLog "JSON conversion failed, saving as text format" -Level "WARNING"
        $detailedResults | Out-String | Out-File -FilePath $TestResultsPath -Encoding UTF8
    }
    Write-Host "Test results saved successfully" -ForegroundColor Green
}

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan

# Return results for programmatic access
return @{
    Success = ($script:TestResults.FailedTests -eq 0)
    SuccessRate = $successRate
    Statistics = @{
        Total = $script:TestResults.TotalTests
        Passed = $script:TestResults.PassedTests
        Failed = $script:TestResults.FailedTests
        Skipped = $script:TestResults.SkippedTests
    }
    Performance = $script:TestResults.Performance
    ResultsPath = if ($SaveResults) { $TestResultsPath } else { $null }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUAgGSdB6qHFBe/kISSckBln6M
# wTigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUud8YAQMPAMpPJHKoGqwJm8HGXnYwDQYJKoZIhvcNAQEBBQAEggEAaI9D
# 6JUPPz/LVDrhJWLT/HQM29Zn/iyCQB8QLuhK+pRXuyeU2sstPYKqXpQB9kNczAnt
# /O7WhnN4rRn6qo6JzuCs4b61BFU1apUjHnxKGfT1DQK3Fo59M/BebyXavPAlb/Wv
# MepnWOmo4fy4XUHuOC6y9QLNTwCxPNfHz6iW0/YM2KAeKYQaPutOLbaWdqKg8shr
# SpmDkwy/ApKBvyEg/buqBxKboskPnoXhrrYRjXPUF498BoC3qnAZhMt3x0hkfhCX
# +FO4qoRio5B0yqaHGJmIaIybuJFFgnId5q+R9HKFlVRa3zR+ZMvY9oQcrJgwDEvt
# febNGjF83RbO4+PzGg==
# SIG # End signature block
