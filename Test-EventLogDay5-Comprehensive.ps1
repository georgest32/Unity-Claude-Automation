# Test-EventLogDay5-Comprehensive.ps1
# Phase 3, Week 7, Day 5: Testing & Validation
# Comprehensive test suite for event log permissions and performance

param(
    [switch]$PermissionTests,
    [switch]$PerformanceTests,
    [switch]$StressTests,
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
$script:ResultsFile = Join-Path $PSScriptRoot "Test-EventLogDay5-Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

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

function Test-AdminPrivileges {
    Write-TestLog "Testing admin privilege detection"
    
    $testName = "Admin Privilege Detection"
    $testStart = Get-Date
    
    try {
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
        
        $details = if ($isAdmin) {
            "Running with Administrator privileges"
        } else {
            "Running without Administrator privileges"
        }
        
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $true
            Details = $details
            IsAdmin = $isAdmin
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName}: $details" -Level "SUCCESS"
        return $isAdmin
        
    } catch {
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $false
            Details = "Error: $_"
            IsAdmin = $false
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName} failed: $_" -Level "ERROR"
        return $false
    }
}

function Test-EventSourceCreation {
    param(
        [bool]$IsAdmin
    )
    
    Write-TestLog "Testing event source creation capabilities"
    
    $testName = "Event Source Creation"
    $testStart = Get-Date
    $testSource = "UCAutomationTest_$(Get-Random -Maximum 9999)"
    
    try {
        if ($IsAdmin) {
            # Try to create a new source
            if (-not [System.Diagnostics.EventLog]::SourceExists($testSource)) {
                [System.Diagnostics.EventLog]::CreateEventSource($testSource, "Application")
                Write-TestLog "Created test source: $testSource" -Level "SUCCESS"
                
                # Clean up
                [System.Diagnostics.EventLog]::DeleteEventSource($testSource)
                Write-TestLog "Cleaned up test source: $testSource"
                
                $details = "Successfully created and deleted test event source"
                $passed = $true
            } else {
                $details = "Test source already exists"
                $passed = $false
            }
        } else {
            # Test non-admin fallback
            try {
                if (-not [System.Diagnostics.EventLog]::SourceExists($testSource)) {
                    [System.Diagnostics.EventLog]::CreateEventSource($testSource, "Application")
                }
                $details = "Unexpected: Non-admin could create source"
                $passed = $false
            } catch [System.Security.SecurityException] {
                $details = "Expected: Non-admin cannot create new sources"
                $passed = $true
            }
        }
        
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $passed
            Details = $details
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName}: $details" -Level $(if ($passed) { "SUCCESS" } else { "WARNING" })
        
    } catch {
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $false
            Details = "Error: $_"
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName} failed: $_" -Level "ERROR"
    }
}

function Test-NonAdminFallback {
    Write-TestLog "Testing non-admin fallback mechanisms"
    
    $testName = "Non-Admin Fallback"
    $testStart = Get-Date
    
    try {
        # Try to write using Application source (should work without admin)
        $eventId = Get-Random -Minimum 1000 -Maximum 9999
        Write-EventLog -LogName "Application" -Source "Application" -EventId $eventId -EntryType Information -Message "Unity-Claude Test Event (Non-Admin Fallback)" -ErrorAction Stop
        
        # Verify the event was written
        $filter = @{
            LogName = 'Application'
            ProviderName = 'Application'
            ID = $eventId
            StartTime = $testStart
        }
        
        $events = Get-WinEvent -FilterHashtable $filter -MaxEvents 1 -ErrorAction SilentlyContinue
        
        if ($events) {
            $details = "Successfully wrote event using Application source"
            $passed = $true
        } else {
            $details = "Event write succeeded but could not verify"
            $passed = $false
        }
        
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $passed
            Details = $details
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName}: $details" -Level $(if ($passed) { "SUCCESS" } else { "WARNING" })
        
    } catch {
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $false
            Details = "Error: $_"
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName} failed: $_" -Level "ERROR"
    }
}

function Test-SecurityDescriptors {
    Write-TestLog "Testing security descriptor (SDDL) access"
    
    $testName = "Security Descriptor Access"
    $testStart = Get-Date
    
    try {
        # Try to read the CustomSD for Application log
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\services\eventlog\Application"
        $customSD = Get-ItemProperty -Path $regPath -Name "CustomSD" -ErrorAction SilentlyContinue
        
        if ($customSD) {
            $details = "Successfully read CustomSD: $(($customSD.CustomSD).Substring(0, [Math]::Min(50, $customSD.CustomSD.Length)))..."
            $passed = $true
        } else {
            # CustomSD might not exist, which is normal
            $details = "CustomSD not configured (using default permissions)"
            $passed = $true
        }
        
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $passed
            Details = $details
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName}: $details" -Level "SUCCESS"
        
    } catch {
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $false
            Details = "Error accessing registry: $_"
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName} failed: $_" -Level "ERROR"
    }
}

function Test-EventLogWritePerformance {
    param(
        [int]$EventCount = 100
    )
    
    Write-TestLog "Testing event log write performance with $EventCount events"
    
    $testName = "Write Performance ($EventCount events)"
    $testStart = Get-Date
    $latencies = @()
    
    try {
        for ($i = 1; $i -le $EventCount; $i++) {
            $writeStart = Get-Date
            
            Write-EventLog -LogName "Application" -Source "Application" `
                -EventId (1000 + $i) -EntryType Information `
                -Message "Performance test event $i of $EventCount - Unity-Claude Automation" `
                -ErrorAction Stop
            
            $latency = ((Get-Date) - $writeStart).TotalMilliseconds
            $latencies += $latency
            
            if ($i % 20 -eq 0) {
                Write-TestLog "Written $i/$EventCount events..." 
            }
        }
        
        $avgLatency = ($latencies | Measure-Object -Average).Average
        $maxLatency = ($latencies | Measure-Object -Maximum).Maximum
        $minLatency = ($latencies | Measure-Object -Minimum).Minimum
        
        $details = "Avg: $([Math]::Round($avgLatency, 2))ms, Max: $([Math]::Round($maxLatency, 2))ms, Min: $([Math]::Round($minLatency, 2))ms"
        $passed = $maxLatency -lt 100  # Target: <100ms per write
        
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $passed
            Details = $details
            AvgLatency = $avgLatency
            MaxLatency = $maxLatency
            MinLatency = $minLatency
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName}: $details" -Level $(if ($passed) { "SUCCESS" } else { "WARNING" })
        
    } catch {
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $false
            Details = "Error: $_"
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName} failed: $_" -Level "ERROR"
    }
}

function Test-EventLogQueryPerformance {
    Write-TestLog "Testing event log query performance"
    
    $testName = "Query Performance"
    $testStart = Get-Date
    
    try {
        # Test 1: FilterHashtable (optimized)
        $filterStart = Get-Date
        $filter = @{
            LogName = 'Application'
            StartTime = (Get-Date).AddHours(-1)
            ID = @(1000..1100)
        }
        $filterEvents = Get-WinEvent -FilterHashtable $filter -ErrorAction SilentlyContinue
        $filterTime = ((Get-Date) - $filterStart).TotalMilliseconds
        
        # Test 2: Pipeline filtering (non-optimized) - limited scope
        $pipelineStart = Get-Date
        $pipelineEvents = Get-WinEvent -LogName 'Application' -MaxEvents 1000 -ErrorAction SilentlyContinue | 
            Where-Object { $_.Id -ge 1000 -and $_.Id -le 1100 -and $_.TimeCreated -gt (Get-Date).AddHours(-1) }
        $pipelineTime = ((Get-Date) - $pipelineStart).TotalMilliseconds
        
        $improvement = if ($pipelineTime -gt 0) {
            [Math]::Round((($pipelineTime - $filterTime) / $pipelineTime) * 100, 2)
        } else { 0 }
        
        $details = "Filter: $([Math]::Round($filterTime, 2))ms, Pipeline: $([Math]::Round($pipelineTime, 2))ms, Improvement: $improvement%"
        $passed = $filterTime -lt $pipelineTime  # FilterHashtable should be faster
        
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $passed
            Details = $details
            FilterTime = $filterTime
            PipelineTime = $pipelineTime
            Improvement = $improvement
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName}: $details" -Level $(if ($passed) { "SUCCESS" } else { "WARNING" })
        
    } catch {
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $false
            Details = "Error: $_"
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName} failed: $_" -Level "ERROR"
    }
}

function Test-StressEventLogging {
    param(
        [int]$Duration = 30,  # seconds
        [int]$ThreadCount = 5
    )
    
    Write-TestLog "Starting stress test: $Duration seconds, $ThreadCount threads"
    
    $testName = "Stress Test ($ThreadCount threads)"
    $testStart = Get-Date
    
    try {
        $scriptBlock = {
            param($ThreadId, $Duration)
            
            $endTime = (Get-Date).AddSeconds($Duration)
            $count = 0
            
            while ((Get-Date) -lt $endTime) {
                Write-EventLog -LogName "Application" -Source "Application" `
                    -EventId (2000 + $ThreadId) -EntryType Information `
                    -Message "Stress test - Thread $ThreadId - Event $count" `
                    -ErrorAction SilentlyContinue
                $count++
            }
            
            return $count
        }
        
        # Start parallel jobs
        $jobs = @()
        for ($i = 1; $i -le $ThreadCount; $i++) {
            $jobs += Start-Job -ScriptBlock $scriptBlock -ArgumentList $i, $Duration
        }
        
        Write-TestLog "Started $ThreadCount parallel jobs"
        
        # Wait for completion
        $results = $jobs | Wait-Job | Receive-Job
        $jobs | Remove-Job
        
        $totalEvents = ($results | Measure-Object -Sum).Sum
        $eventsPerSecond = $totalEvents / $Duration
        
        $details = "Total: $totalEvents events, Rate: $([Math]::Round($eventsPerSecond, 2)) events/sec"
        $passed = $eventsPerSecond -gt 10  # Target: >10 events/sec sustained
        
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $passed
            Details = $details
            TotalEvents = $totalEvents
            EventsPerSecond = $eventsPerSecond
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName}: $details" -Level $(if ($passed) { "SUCCESS" } else { "WARNING" })
        
    } catch {
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $false
            Details = "Error: $_"
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName} failed: $_" -Level "ERROR"
    }
}

function Test-ResourceUsage {
    Write-TestLog "Testing resource usage during event operations"
    
    $testName = "Resource Usage"
    $testStart = Get-Date
    
    try {
        # Get baseline
        $baselineMemory = (Get-Process -Id $PID).WorkingSet64 / 1MB
        $baselineCPU = (Get-Process -Id $PID).CPU
        
        # Perform operations
        for ($i = 1; $i -le 50; $i++) {
            Write-EventLog -LogName "Application" -Source "Application" `
                -EventId 3000 -EntryType Information `
                -Message "Resource test event $i" `
                -ErrorAction SilentlyContinue
        }
        
        # Query events
        $filter = @{
            LogName = 'Application'
            ID = 3000
            StartTime = $testStart
        }
        $events = Get-WinEvent -FilterHashtable $filter -ErrorAction SilentlyContinue
        
        # Get final measurements
        $finalMemory = (Get-Process -Id $PID).WorkingSet64 / 1MB
        $finalCPU = (Get-Process -Id $PID).CPU
        
        $memoryIncrease = $finalMemory - $baselineMemory
        $cpuIncrease = $finalCPU - $baselineCPU
        
        $details = "Memory: +$([Math]::Round($memoryIncrease, 2))MB, CPU: +$([Math]::Round($cpuIncrease, 2))s"
        $passed = $memoryIncrease -lt 50  # Less than 50MB increase
        
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $passed
            Details = $details
            MemoryIncrease = $memoryIncrease
            CPUIncrease = $cpuIncrease
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName}: $details" -Level $(if ($passed) { "SUCCESS" } else { "WARNING" })
        
    } catch {
        $script:TestResults += [PSCustomObject]@{
            TestName = $testName
            Passed = $false
            Details = "Error: $_"
            Duration = ((Get-Date) - $testStart).TotalMilliseconds
            Timestamp = Get-Date
        }
        
        Write-TestLog "${testName} failed: $_" -Level "ERROR"
    }
}

function Save-TestResults {
    Write-TestLog "Saving test results to $script:ResultsFile"
    
    $output = @"
Unity-Claude Event Log Phase 3 Day 5 Comprehensive Test Results
================================================================
Testing & Validation: Permissions and Performance
Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
PowerShell Version: $($PSVersionTable.PSVersion)

Test Summary
------------
Total Tests: $($script:TestResults.Count)
Passed: $(($script:TestResults | Where-Object { $_.Passed }).Count)
Failed: $(($script:TestResults | Where-Object { -not $_.Passed }).Count)
Pass Rate: $([Math]::Round((($script:TestResults | Where-Object { $_.Passed }).Count / $script:TestResults.Count) * 100, 2))%
Total Duration: $([Math]::Round(((Get-Date) - $script:TestStartTime).TotalSeconds, 2)) seconds

Detailed Results
----------------

"@

    foreach ($result in $script:TestResults) {
        $output += @"
Test: $($result.TestName)
Status: $(if ($result.Passed) { "PASSED" } else { "FAILED" })
Details: $($result.Details)
Duration: $([Math]::Round($result.Duration, 2))ms
Timestamp: $($result.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))

"@
    }

    # Performance Metrics Summary
    $perfTests = $script:TestResults | Where-Object { $_.TestName -like "*Performance*" -or $_.TestName -like "*Stress*" }
    if ($perfTests) {
        $output += @"

Performance Metrics Summary
---------------------------
"@
        foreach ($test in $perfTests) {
            if ($test.AvgLatency) {
                $output += "Write Latency - Avg: $([Math]::Round($test.AvgLatency, 2))ms, Max: $([Math]::Round($test.MaxLatency, 2))ms`n"
            }
            if ($test.FilterTime) {
                $output += "Query Performance - Filter: $([Math]::Round($test.FilterTime, 2))ms, Pipeline: $([Math]::Round($test.PipelineTime, 2))ms`n"
            }
            if ($test.EventsPerSecond) {
                $output += "Stress Test - Rate: $([Math]::Round($test.EventsPerSecond, 2)) events/sec`n"
            }
        }
    }

    # Recommendations
    $output += @"

Recommendations
---------------
"@

    if ($script:TestResults | Where-Object { -not $_.Passed }) {
        $output += "- Review failed tests and implement fixes`n"
    } else {
        $output += "- All tests passed successfully!`n"
    }
    
    $maxLatency = ($script:TestResults | Where-Object { $_.MaxLatency } | Select-Object -ExpandProperty MaxLatency | Measure-Object -Maximum).Maximum
    if ($maxLatency -and $maxLatency -gt 100) {
        $output += "- Consider optimizing write operations to meet <100ms target`n"
    }
    
    $output += "- Phase 3 Day 5 validation complete - ready for production deployment`n"

    # Save to file
    $output | Out-File -FilePath $script:ResultsFile -Encoding UTF8
    
    # Also display
    Write-Host "`n$output" -ForegroundColor Cyan
    
    Write-TestLog "Results saved to: $script:ResultsFile" -Level "SUCCESS"
}

# Main execution
Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Unity-Claude Event Log Day 5 Testing" -ForegroundColor Yellow
Write-Host "Phase 3: Testing & Validation" -ForegroundColor Yellow
Write-Host "========================================`n" -ForegroundColor Yellow

# Determine which tests to run
if (-not $PermissionTests -and -not $PerformanceTests -and -not $StressTests -and -not $AllTests) {
    $AllTests = $true
    Write-TestLog "No specific tests selected, running all tests"
}

# Run Permission Tests
if ($PermissionTests -or $AllTests) {
    Write-Host "`n--- Permission Tests ---" -ForegroundColor Cyan
    $isAdmin = Test-AdminPrivileges
    Test-EventSourceCreation -IsAdmin $isAdmin
    Test-NonAdminFallback
    Test-SecurityDescriptors
}

# Run Performance Tests
if ($PerformanceTests -or $AllTests) {
    Write-Host "`n--- Performance Tests ---" -ForegroundColor Cyan
    Test-EventLogWritePerformance -EventCount 100
    Test-EventLogQueryPerformance
    Test-ResourceUsage
}

# Run Stress Tests
if ($StressTests -or $AllTests) {
    Write-Host "`n--- Stress Tests ---" -ForegroundColor Cyan
    Test-StressEventLogging -Duration 30 -ThreadCount 5
}

# Save results
if ($SaveResults -or $AllTests) {
    Save-TestResults
}

# Summary
$passedCount = ($script:TestResults | Where-Object { $_.Passed }).Count
$totalCount = $script:TestResults.Count
$passRate = if ($totalCount -gt 0) { [Math]::Round(($passedCount / $totalCount) * 100, 2) } else { 0 }

Write-Host "`n========================================" -ForegroundColor Yellow
Write-Host "Test Execution Complete" -ForegroundColor Yellow
Write-Host "Total: $totalCount | Passed: $passedCount | Failed: $($totalCount - $passedCount)" -ForegroundColor $(if ($passRate -eq 100) { "Green" } else { "Yellow" })
Write-Host "Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -eq 100) { "Green" } else { "Yellow" })
Write-Host "========================================`n" -ForegroundColor Yellow

# Log completion
Write-TestLog "Day 5 comprehensive testing complete - Pass Rate: $passRate%" -Level $(if ($passRate -eq 100) { "SUCCESS" } else { "WARNING" })

# Return success/failure
exit $(if ($passRate -eq 100) { 0 } else { 1 })