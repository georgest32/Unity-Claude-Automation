# Test-Week2-Days3-4-RunspacePoolManagement.ps1
# Phase 1 Week 2 Days 3-4: Runspace Pool Management Testing
# Comprehensive test suite for production runspace pool functionality
# Date: 2025-08-21

[CmdletBinding()]
param(
    [switch]$SaveResults,
    [switch]$EnableResourceMonitoring
)

$ErrorActionPreference = "Stop"

# Test configuration
$TestConfig = @{
    TestName = "Week2-Days3-4-RunspacePoolManagement"
    Date = Get-Date
    SaveResults = $SaveResults
    TestTimeout = 600 # 10 minutes
    EnableResourceMonitoring = $EnableResourceMonitoring
}

# Initialize test results
$TestResults = @{
    TestName = $TestConfig.TestName
    StartTime = Get-Date
    Tests = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Skipped = 0
        Duration = 0
        PassRate = 0
    }
}

# Color functions for output
function Write-TestHeader {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-TestResult {
    param([string]$TestName, [bool]$Success, [string]$Message = "", [int]$Duration = 0)
    
    $status = if ($Success) { "PASS" } else { "FAIL" }
    $color = if ($Success) { "Green" } else { "Red" }
    
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Message) {
        Write-Host "    $Message" -ForegroundColor Gray
    }
    if ($Duration -gt 0) {
        Write-Host "    Duration: ${Duration}ms" -ForegroundColor Gray
    }
    
    # Add to results
    $TestResults.Tests += @{
        TestName = $TestName
        Success = $Success
        Message = $Message
        Duration = $Duration
        Timestamp = Get-Date
    }
    $TestResults.Summary.Total++
    if ($Success) {
        $TestResults.Summary.Passed++
    } else {
        $TestResults.Summary.Failed++
    }
}

function Test-Function {
    param(
        [string]$TestName,
        [scriptblock]$TestScript,
        [int]$TimeoutMs = 60000
    )
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $result = & $TestScript
        $stopwatch.Stop()
        
        if ($result -is [bool]) {
            Write-TestResult -TestName $TestName -Success $result -Duration $stopwatch.ElapsedMilliseconds
        } elseif ($result -is [hashtable] -and $result.ContainsKey('Success')) {
            Write-TestResult -TestName $TestName -Success $result.Success -Message $result.Message -Duration $stopwatch.ElapsedMilliseconds
        } else {
            Write-TestResult -TestName $TestName -Success $true -Message "Test completed" -Duration $stopwatch.ElapsedMilliseconds
        }
    } catch {
        $stopwatch.Stop()
        Write-TestResult -TestName $TestName -Success $false -Message $_.Exception.Message -Duration $stopwatch.ElapsedMilliseconds
    }
}

# Main test execution
Write-TestHeader "Unity-Claude-RunspaceManagement Days 3-4 Testing"
Write-Host "Phase 1 Week 2 Days 3-4: Runspace Pool Management" -ForegroundColor Yellow
Write-Host "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)"
Write-Host "Resource Monitoring: $($TestConfig.EnableResourceMonitoring)"

#region Module Loading and Validation

Write-TestHeader "1. Module Loading and Function Validation"

Test-Function "Module Import with New Functions" {
    try {
        Import-Module ".\Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psd1" -Force -ErrorAction Stop
        return @{Success = $true; Message = "Module imported successfully"}
    } catch {
        return @{Success = $false; Message = "Failed to import module: $($_.Exception.Message)"}
    }
}

Test-Function "New Function Export Validation" {
    $exportedFunctions = Get-Command -Module Unity-Claude-RunspaceManagement
    $expectedNewFunctions = @(
        'New-ProductionRunspacePool', 'Submit-RunspaceJob', 'Update-RunspaceJobStatus',
        'Wait-RunspaceJobs', 'Get-RunspaceJobResults', 'Test-RunspacePoolResources',
        'Set-AdaptiveThrottling', 'Invoke-RunspacePoolCleanup'
    )
    
    $missingFunctions = $expectedNewFunctions | Where-Object { $_ -notin $exportedFunctions.Name }
    
    if ($missingFunctions.Count -eq 0) {
        return @{Success = $true; Message = "All $($expectedNewFunctions.Count) new functions exported, total: $($exportedFunctions.Count)"}
    } else {
        return @{Success = $false; Message = "Missing new functions: $($missingFunctions -join ', ')"}
    }
}

#endregion

#region Hour 1-2: Production Runspace Pool Infrastructure

Write-TestHeader "2. Hour 1-2: Production Runspace Pool Infrastructure"

# Create session state for testing
$script:TestSessionConfig = New-RunspaceSessionState
Initialize-SessionStateVariables -SessionStateConfig $script:TestSessionConfig | Out-Null

Test-Function "New-ProductionRunspacePool - Basic Creation" {
    $productionPool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 3 -Name "TestProductionPool"
    
    if ($productionPool -and $productionPool.RunspacePool -and $productionPool.Status -eq 'Created') {
        return @{Success = $true; Message = "Production pool created: Min: $($productionPool.MinRunspaces), Max: $($productionPool.MaxRunspaces)"}
    } else {
        return @{Success = $false; Message = "Failed to create production runspace pool"}
    }
}

Test-Function "New-ProductionRunspacePool - With Resource Monitoring" {
    $monitoredPool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 2 -Name "MonitoredPool" -EnableResourceMonitoring
    
    if ($monitoredPool -and $monitoredPool.ResourceMonitoring.Enabled) {
        return @{Success = $true; Message = "Production pool with monitoring created successfully"}
    } else {
        return @{Success = $false; Message = "Resource monitoring not enabled properly"}
    }
}

Test-Function "Submit-RunspaceJob - Simple Job" {
    $productionPool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 2 -Name "JobTestPool"
    Open-RunspacePool -PoolManager $productionPool | Out-Null
    
    $simpleScript = { param($x) Start-Sleep -Milliseconds 100; return $x * 2 }
    $job = Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock $simpleScript -Parameters @{x=5} -JobName "SimpleTest"
    
    if ($job -and $job.JobId -and $job.Status -eq 'Running') {
        # Cleanup
        Close-RunspacePool -PoolManager $productionPool | Out-Null
        return @{Success = $true; Message = "Job submitted: $($job.JobName), Status: $($job.Status)"}
    } else {
        return @{Success = $false; Message = "Job submission failed or incorrect status"}
    }
}

Test-Function "Update-RunspaceJobStatus - Job Monitoring" {
    $productionPool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 2 -Name "StatusTestPool"
    Open-RunspacePool -PoolManager $productionPool | Out-Null
    
    # Submit a quick job
    $quickScript = { param($x) return $x + 1 }
    $job = Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock $quickScript -Parameters @{x=10} -JobName "QuickTest"
    
    # Wait a moment and update status
    Start-Sleep -Milliseconds 200
    $statusUpdate = Update-RunspaceJobStatus -PoolManager $productionPool -ProcessCompletedJobs
    
    # Cleanup
    Close-RunspacePool -PoolManager $productionPool | Out-Null
    
    if ($statusUpdate -and $statusUpdate.ContainsKey('CompletedJobs')) {
        return @{Success = $true; Message = "Status update: Completed: $($statusUpdate.CompletedJobs), Active: $($statusUpdate.ActiveJobs)"}
    } else {
        return @{Success = $false; Message = "Failed to update job status properly"}
    }
}

Test-Function "Wait-RunspaceJobs - Job Completion" {
    $productionPool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 2 -Name "WaitTestPool"
    Open-RunspacePool -PoolManager $productionPool | Out-Null
    
    # Submit multiple jobs
    $testScript = { param($delay, $value) Start-Sleep -Milliseconds $delay; return $value * 3 }
    Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock $testScript -Parameters @{delay=50; value=2} -JobName "Job1" | Out-Null
    Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock $testScript -Parameters @{delay=75; value=3} -JobName "Job2" | Out-Null
    Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock $testScript -Parameters @{delay=100; value=4} -JobName "Job3" | Out-Null
    
    # Wait for completion
    $waitResult = Wait-RunspaceJobs -PoolManager $productionPool -TimeoutSeconds 10 -ProcessResults
    
    # Cleanup
    Close-RunspacePool -PoolManager $productionPool | Out-Null
    
    if ($waitResult.Success -and $waitResult.CompletedJobs -eq 3) {
        return @{Success = $true; Message = "All 3 jobs completed in $($waitResult.ElapsedSeconds)s"}
    } else {
        return @{Success = $false; Message = "Job completion failed: Success: $($waitResult.Success), Completed: $($waitResult.CompletedJobs)"}
    }
}

Test-Function "Get-RunspaceJobResults - Result Retrieval" {
    $productionPool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 2 -Name "ResultsTestPool"
    Open-RunspacePool -PoolManager $productionPool | Out-Null
    
    # Submit and complete jobs
    $resultScript = { param($base) return $base * $base }
    Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock $resultScript -Parameters @{base=4} -JobName "SquareTest" | Out-Null
    Wait-RunspaceJobs -PoolManager $productionPool -TimeoutSeconds 5 -ProcessResults | Out-Null
    
    # Get results
    $results = Get-RunspaceJobResults -PoolManager $productionPool
    
    # Cleanup
    Close-RunspacePool -PoolManager $productionPool | Out-Null
    
    if ($results -and $results.CompletedJobs.Count -eq 1 -and $results.CompletedJobs[0].Result -eq 16) {
        return @{Success = $true; Message = "Results retrieved: $($results.CompletedJobs[0].Result) (expected: 16)"}
    } else {
        return @{Success = $false; Message = "Failed to retrieve correct results"}
    }
}

#endregion

#region Hour 5-6: Throttling and Resource Control

Write-TestHeader "3. Hour 5-6: Throttling and Resource Control"

Test-Function "Test-RunspacePoolResources - Resource Monitoring" {
    if (-not $TestConfig.EnableResourceMonitoring) {
        return @{Success = $true; Message = "Resource monitoring not enabled - skipped"}
    }
    
    $productionPool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 2 -Name "ResourceTestPool" -EnableResourceMonitoring
    Open-RunspacePool -PoolManager $productionPool | Out-Null
    
    $resourceInfo = Test-RunspacePoolResources -PoolManager $productionPool
    
    # Cleanup
    Close-RunspacePool -PoolManager $productionPool | Out-Null
    
    if ($resourceInfo.Enabled -and $resourceInfo.CpuPercent -ge 0 -and $resourceInfo.MemoryUsedMB -ge 0) {
        return @{Success = $true; Message = "Resource monitoring: CPU: $($resourceInfo.CpuPercent)%, Memory: $($resourceInfo.MemoryUsedMB)MB"}
    } else {
        return @{Success = $false; Message = "Resource monitoring failed or returned invalid data"}
    }
}

Test-Function "Set-AdaptiveThrottling - Throttling Analysis" {
    $productionPool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 4 -Name "ThrottleTestPool" -EnableResourceMonitoring
    
    $adaptiveConfig = Set-AdaptiveThrottling -PoolManager $productionPool -CpuThreshold 70 -MemoryThresholdMB 800
    
    if ($adaptiveConfig -and $adaptiveConfig.ContainsKey('RecommendedMaxRunspaces')) {
        return @{Success = $true; Message = "Adaptive throttling: Current: $($adaptiveConfig.OriginalMaxRunspaces), Recommended: $($adaptiveConfig.RecommendedMaxRunspaces)"}
    } else {
        return @{Success = $false; Message = "Adaptive throttling analysis failed"}
    }
}

Test-Function "Invoke-RunspacePoolCleanup - Memory Management" {
    $productionPool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 2 -Name "CleanupTestPool"
    Open-RunspacePool -PoolManager $productionPool | Out-Null
    
    # Submit and complete jobs to create cleanup scenario
    $cleanupScript = { param($x) return "Result: $x" }
    Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock $cleanupScript -Parameters @{x="Test1"} | Out-Null
    Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock $cleanupScript -Parameters @{x="Test2"} | Out-Null
    Wait-RunspaceJobs -PoolManager $productionPool -TimeoutSeconds 5 -ProcessResults | Out-Null
    
    # Perform cleanup
    $cleanupStats = Invoke-RunspacePoolCleanup -PoolManager $productionPool -Force
    
    # Cleanup
    Close-RunspacePool -PoolManager $productionPool | Out-Null
    
    if ($cleanupStats -and $cleanupStats.Duration -ge 0) {
        return @{Success = $true; Message = "Cleanup completed in $($cleanupStats.Duration)ms, Memory freed: $($cleanupStats.MemoryFreedMB)MB"}
    } else {
        return @{Success = $false; Message = "Cleanup failed or returned invalid data"}
    }
}

#endregion

#region Performance and Integration Tests

Write-TestHeader "4. Performance and Integration Tests"

Test-Function "Production Pool Creation Performance" {
    $iterations = 5
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    for ($i = 0; $i -lt $iterations; $i++) {
        $productionPool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 2 -Name "PerfPool$i"
        $null = $productionPool # Suppress output
    }
    
    $stopwatch.Stop()
    $averageMs = $stopwatch.ElapsedMilliseconds / $iterations
    
    if ($averageMs -lt 200) {
        return @{Success = $true; Message = "Average production pool creation: ${averageMs}ms (target: <200ms)"}
    } else {
        return @{Success = $false; Message = "Performance too slow: ${averageMs}ms (target: <200ms)"}
    }
}

Test-Function "Job Submission Performance" {
    $productionPool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 3 -Name "JobPerfPool"
    Open-RunspacePool -PoolManager $productionPool | Out-Null
    
    $iterations = 10
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    $fastScript = { param($x) return $x }
    for ($i = 0; $i -lt $iterations; $i++) {
        Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock $fastScript -Parameters @{x=$i} -JobName "PerfJob$i" | Out-Null
    }
    
    $stopwatch.Stop()
    $averageMs = $stopwatch.ElapsedMilliseconds / $iterations
    
    # Wait for jobs and cleanup
    Wait-RunspaceJobs -PoolManager $productionPool -TimeoutSeconds 10 -ProcessResults | Out-Null
    Close-RunspacePool -PoolManager $productionPool | Out-Null
    
    if ($averageMs -lt 50) {
        return @{Success = $true; Message = "Average job submission: ${averageMs}ms per job (target: <50ms)"}
    } else {
        return @{Success = $false; Message = "Job submission too slow: ${averageMs}ms (target: <50ms)"}
    }
}

Test-Function "End-to-End Production Pool Workflow" {
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Create production pool
    $productionPool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 3 -Name "E2EPool" -EnableResourceMonitoring:$TestConfig.EnableResourceMonitoring
    
    # Open pool
    $openResult = Open-RunspacePool -PoolManager $productionPool
    
    # Submit multiple jobs with different complexities
    $jobs = @()
    $jobs += Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock { param($x) Start-Sleep -Milliseconds 50; return $x * 2 } -Parameters @{x=5} -JobName "Math1"
    $jobs += Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock { param($text) Start-Sleep -Milliseconds 75; return $text.ToUpper() } -Parameters @{text="hello"} -JobName "Text1"
    $jobs += Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock { param($count) Start-Sleep -Milliseconds 25; return 1..$count } -Parameters @{count=3} -JobName "Array1"
    
    # Wait for completion
    $waitResult = Wait-RunspaceJobs -PoolManager $productionPool -TimeoutSeconds 10 -ProcessResults
    
    # Get results
    $results = Get-RunspaceJobResults -PoolManager $productionPool -IncludeFailedJobs
    
    # Resource monitoring if enabled
    $resourceCheck = if ($TestConfig.EnableResourceMonitoring) {
        Test-RunspacePoolResources -PoolManager $productionPool
    } else {
        @{Enabled = $false}
    }
    
    # Cleanup
    Invoke-RunspacePoolCleanup -PoolManager $productionPool | Out-Null
    $closeResult = Close-RunspacePool -PoolManager $productionPool
    
    $stopwatch.Stop()
    
    $success = $openResult.Success -and $waitResult.Success -and $results.CompletedJobs.Count -eq 3 -and $closeResult.Success
    
    if ($success) {
        $message = "E2E workflow success: $($results.CompletedJobs.Count) jobs completed in $($stopwatch.ElapsedMilliseconds)ms"
        if ($resourceCheck.Enabled) {
            $message += ", CPU: $($resourceCheck.CpuPercent)%, Memory: $($resourceCheck.MemoryUsedMB)MB"
        }
        return @{Success = $true; Message = $message}
    } else {
        return @{Success = $false; Message = "E2E workflow failed - Open: $($openResult.Success), Wait: $($waitResult.Success), Results: $($results.CompletedJobs.Count), Close: $($closeResult.Success)"}
    }
}

Test-Function "Job Timeout Handling" {
    $productionPool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 2 -Name "TimeoutTestPool"
    Open-RunspacePool -PoolManager $productionPool | Out-Null
    
    # Submit job that will timeout
    $timeoutScript = { Start-Sleep -Seconds 10; return "Should not reach here" }
    Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock $timeoutScript -JobName "TimeoutJob" -TimeoutSeconds 2 | Out-Null
    
    # Wait and check timeout handling
    $waitResult = Wait-RunspaceJobs -PoolManager $productionPool -TimeoutSeconds 5 -ProcessResults
    $results = Get-RunspaceJobResults -PoolManager $productionPool -IncludeFailedJobs
    
    # Cleanup
    Close-RunspacePool -PoolManager $productionPool | Out-Null
    
    # Debug timeout job collection (PowerShell 5.1 defensive pattern)
    $timedOutJobs = @($results.FailedJobs | Where-Object { $_.Status -eq 'TimedOut' })
    
    # Additional debug logging for timeout test validation
    Write-Host "DEBUG - Timeout Test Analysis:" -ForegroundColor Magenta
    Write-Host "    Total failed jobs: $($results.FailedJobs.Count)" -ForegroundColor Gray
    Write-Host "    Timed out jobs found: $($timedOutJobs.Count)" -ForegroundColor Gray
    if ($timedOutJobs.Count -gt 0) {
        Write-Host "    First timed out job: $($timedOutJobs[0].JobName), Status: $($timedOutJobs[0].Status)" -ForegroundColor Gray
    }
    
    if ($timedOutJobs.Count -eq 1) {
        return @{Success = $true; Message = "Timeout handling working: 1 job timed out as expected"}
    } else {
        return @{Success = $false; Message = "Timeout handling validation issue: Expected 1, found $($timedOutJobs.Count) timed out jobs"}
    }
}

Test-Function "Error Handling in Jobs" {
    $productionPool = New-ProductionRunspacePool -SessionStateConfig $script:TestSessionConfig -MaxRunspaces 2 -Name "ErrorTestPool"
    Open-RunspacePool -PoolManager $productionPool | Out-Null
    
    # Submit job that will fail
    $errorScript = { throw "Intentional test error" }
    Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock $errorScript -JobName "ErrorJob" | Out-Null
    
    # Submit job that will succeed  
    $successScript = { return "Success" }
    Submit-RunspaceJob -PoolManager $productionPool -ScriptBlock $successScript -JobName "SuccessJob" | Out-Null
    
    # Wait for completion
    $waitResult = Wait-RunspaceJobs -PoolManager $productionPool -TimeoutSeconds 5 -ProcessResults
    $results = Get-RunspaceJobResults -PoolManager $productionPool -IncludeFailedJobs
    
    # Cleanup
    Close-RunspacePool -PoolManager $productionPool | Out-Null
    
    $hasFailedJob = $results.FailedJobs.Count -eq 1
    $hasSuccessJob = $results.CompletedJobs.Count -eq 1
    
    if ($hasFailedJob -and $hasSuccessJob) {
        return @{Success = $true; Message = "Error handling working: 1 failed, 1 succeeded as expected"}
    } else {
        return @{Success = $false; Message = "Error handling failed: Failed: $($results.FailedJobs.Count), Completed: $($results.CompletedJobs.Count)"}
    }
}

#endregion

#region Finalize Results

Write-TestHeader "Test Results Summary"

$TestResults.EndTime = Get-Date
$TestResults.Summary.Duration = [math]::Round(($TestResults.EndTime - $TestResults.StartTime).TotalSeconds, 2)
$TestResults.Summary.PassRate = if ($TestResults.Summary.Total -gt 0) { 
    [math]::Round(($TestResults.Summary.Passed / $TestResults.Summary.Total) * 100, 2) 
} else { 0 }

Write-Host "`nTest Execution Summary:" -ForegroundColor Cyan
Write-Host "Total Tests: $($TestResults.Summary.Total)" -ForegroundColor White
Write-Host "Passed: $($TestResults.Summary.Passed)" -ForegroundColor Green
Write-Host "Failed: $($TestResults.Summary.Failed)" -ForegroundColor Red
Write-Host "Skipped: $($TestResults.Summary.Skipped)" -ForegroundColor Yellow
Write-Host "Duration: $($TestResults.Summary.Duration) seconds" -ForegroundColor White
Write-Host "Pass Rate: $($TestResults.Summary.PassRate)%" -ForegroundColor $(if ($TestResults.Summary.PassRate -ge 80) { "Green" } else { "Red" })

# Determine overall success
$overallSuccess = $TestResults.Summary.PassRate -ge 80 -and $TestResults.Summary.Failed -eq 0

if ($overallSuccess) {
    Write-Host "`n✅ WEEK 2 DAYS 3-4 RUNSPACE POOL MANAGEMENT: SUCCESS" -ForegroundColor Green
    Write-Host "All critical runspace pool functionality operational" -ForegroundColor Green
} else {
    Write-Host "`n❌ WEEK 2 DAYS 3-4 RUNSPACE POOL MANAGEMENT: NEEDS ATTENTION" -ForegroundColor Red
    Write-Host "Some tests failed - review implementation" -ForegroundColor Red
}

# Save results if requested
if ($SaveResults) {
    $resultsFile = "Week2_Days3-4_RunspacePool_Test_Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    # Create detailed results
    $detailedResults = @{
        TestConfig = $TestConfig
        TestResults = $TestResults
        SystemInfo = @{
            PowerShellVersion = $PSVersionTable.PSVersion
            ProcessorCount = [Environment]::ProcessorCount
            OSVersion = [Environment]::OSVersion
            MachineName = [Environment]::MachineName
        }
    }
    
    # Save both console output and detailed results
    $consoleOutput = $TestResults | Out-String
    $detailedOutput = $detailedResults | ConvertTo-Json -Depth 10
    
    "$consoleOutput`n`nDetailed Results:`n$detailedOutput" | Out-File -FilePath $resultsFile -Encoding UTF8
    Write-Host "`nResults saved to: $resultsFile" -ForegroundColor Cyan
}

#endregion

# Return results for automation
return $TestResults
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU3Fl3y7quF13Ou/IWzQkTstn5
# +i2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUqv5gbhDTMM2N6plHOQ5sqXN7CTcwDQYJKoZIhvcNAQEBBQAEggEATWFT
# 6KfjG7MiwLJUW7YUi1gF4DbbB0N1qFL1becefSVwwfCCclCOQqtaquWmRSVwOV8T
# kefqs2YWLYOjnhnoQEF2HfFbeSB9xNoAzCjVvgIUGL+BfhFXj+/mzvVOzsOd3cR9
# fomynvQt//nxrRGmS1lGuk6GjnIn4qK5Z0SMiVgru6+gCOZcmq/d6PHcwqn25Btj
# lj5tcCsjf5xwEn97oXdCPZqKR2I2jPxlNGMJA2+6O5MAxr9Ax89QF/XiZOof8naq
# P4Cr/ZHnApRbgnc1L88wf3wpSwBrheQsssGvF7u/CWUMUOnEINvia3guLQcwjM/K
# roz+5VGym+PTHUXw1g==
# SIG # End signature block
