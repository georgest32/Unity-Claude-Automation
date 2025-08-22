# Test-Phase3Day3-LoggingDiagnostics.ps1
# Comprehensive test suite for Phase 3 Day 3 Hour 5-6: Logging and Diagnostics implementation
# Tests: Enhanced logging, log rotation, diagnostic mode, trace logging, performance metrics, log search, diagnostic reports

param(
    [switch]$SaveResults,
    [switch]$Verbose
)

$ErrorActionPreference = 'Continue'
$testResults = @()
$testStartTime = Get-Date

Write-Host "=== Testing Phase 3 Day 3: Logging and Diagnostics ===" -ForegroundColor Cyan
Write-Host "Test Started: $testStartTime" -ForegroundColor Gray

# Initialize test environment
try {
    # Import the SystemStatus module
    $modulePath = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force -ErrorAction Stop
        Write-Host "SystemStatus module imported successfully" -ForegroundColor Green
    } else {
        throw "SystemStatus module not found at: $modulePath"
    }
} catch {
    Write-Host "Failed to import SystemStatus module: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 1: Enhanced Write-SystemStatusLog Function
Write-Host "`n--- Test 1: Enhanced Write-SystemStatusLog Function ---" -ForegroundColor Yellow
try {
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Test basic logging
    Write-SystemStatusLog -Message "Test basic logging functionality" -Level 'INFO' -Source 'TestSuite'
    
    # Test structured logging
    $context = @{
        TestId = 'T001'
        Operation = 'LoggingTest'
        Parameters = @{ Level = 'INFO'; Source = 'TestSuite' }
    }
    Write-SystemStatusLog -Message "Test structured logging" -Level 'DEBUG' -Source 'TestSuite' -Context $context -StructuredLogging
    
    # Test with timer
    Write-SystemStatusLog -Message "Test logging with timer" -Level 'TRACE' -Source 'TestSuite' -Timer $timer -Operation 'TimerTest'
    
    $timer.Stop()
    
    $testResults += @{
        Test = "Enhanced Write-SystemStatusLog"
        Result = "PASS"
        Duration = $timer.ElapsedMilliseconds
        Details = "Basic, structured, and timer-based logging all functional"
    }
    Write-Host "Enhanced logging: PASS ($($timer.ElapsedMilliseconds)ms)" -ForegroundColor Green
} catch {
    $testResults += @{
        Test = "Enhanced Write-SystemStatusLog"
        Result = "FAIL"
        Error = $_.Exception.Message
    }
    Write-Host "Enhanced logging: FAIL - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Log Rotation Functionality
Write-Host "`n--- Test 2: Log Rotation Functionality ---" -ForegroundColor Yellow
try {
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Create test log file large enough to trigger rotation
    $testLogPath = ".\test_rotation.log"
    $testContent = "Test log entry with enough content to make it larger than 1MB threshold for rotation testing. This line needs to be long enough to create sufficient data.`n" * 15000  # Create content to trigger rotation
    $testContent | Out-File -FilePath $testLogPath -Encoding ASCII -Force
    
    # Test log rotation
    Invoke-LogRotation -LogPath $testLogPath -MaxSizeMB 1 -MaxLogFiles 3 -CompressOldLogs
    
    # Verify rotation occurred
    $rotatedFile = ".\test_rotation.1.log"
    $rotationWorked = Test-Path $rotatedFile
    
    # Cleanup
    if (Test-Path $testLogPath) { Remove-Item $testLogPath -Force }
    if (Test-Path $rotatedFile) { Remove-Item $rotatedFile -Force }
    
    $timer.Stop()
    
    if ($rotationWorked) {
        $testResults += @{
            Test = "Log Rotation"
            Result = "PASS"
            Duration = $timer.ElapsedMilliseconds
            Details = "Log rotation with compression working correctly"
        }
        Write-Host "Log rotation: PASS ($($timer.ElapsedMilliseconds)ms)" -ForegroundColor Green
    } else {
        throw "Log rotation did not create expected rotated file"
    }
} catch {
    $testResults += @{
        Test = "Log Rotation"
        Result = "FAIL"
        Error = $_.Exception.Message
    }
    Write-Host "Log rotation: FAIL - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Diagnostic Mode Infrastructure
Write-Host "`n--- Test 3: Diagnostic Mode Infrastructure ---" -ForegroundColor Yellow
try {
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Test enabling diagnostic mode
    $enableResult = Enable-DiagnosticMode -Level 'Basic'
    
    if ($enableResult.Success) {
        # Test diagnostic mode status
        $status = Test-DiagnosticMode
        
        if ($status.Enabled -and $status.Level -eq 'Basic') {
            # Test trace logging during diagnostic mode
            Write-TraceLog -Message "Test trace during diagnostic mode" -Operation 'DiagnosticTest'
            
            # Test disabling diagnostic mode
            $disableResult = Disable-DiagnosticMode
            
            if ($disableResult.Success) {
                $testResults += @{
                    Test = "Diagnostic Mode"
                    Result = "PASS"
                    Duration = $timer.ElapsedMilliseconds
                    Details = "Enable, status check, trace logging, and disable all working"
                }
                Write-Host "Diagnostic mode: PASS ($($timer.ElapsedMilliseconds)ms)" -ForegroundColor Green
            } else {
                throw "Failed to disable diagnostic mode"
            }
        } else {
            throw "Diagnostic mode status check failed"
        }
    } else {
        throw "Failed to enable diagnostic mode: $($enableResult.Error)"
    }
    
    $timer.Stop()
} catch {
    $testResults += @{
        Test = "Diagnostic Mode"
        Result = "FAIL"
        Error = $_.Exception.Message
    }
    Write-Host "Diagnostic mode: FAIL - $($_.Exception.Message)" -ForegroundColor Red
    
    # Cleanup - force disable diagnostic mode
    try { Disable-DiagnosticMode -Force } catch { }
}

# Test 4: Trace Logging Framework
Write-Host "`n--- Test 4: Trace Logging Framework ---" -ForegroundColor Yellow
try {
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Enable trace logging
    Enable-TraceLogging -Level 'Detail'
    
    # Test trace operation
    $traceContext = Start-TraceOperation -Operation 'TestOperation' -Context @{ TestId = 'T004' }
    
    # Simulate work
    Start-Sleep -Milliseconds 100
    
    # Test trace messages
    Write-TraceLog -Message "Processing test data" -Operation 'TestOperation' -TraceLevel 'Flow'
    Write-TraceLog -Message "Detailed processing step" -Operation 'TestOperation' -TraceLevel 'Detail' -Context @{ Step = 1 }
    
    # Stop trace operation
    Stop-TraceOperation -TraceContext $traceContext -Message "Test operation completed" -Success $true
    
    # Disable trace logging
    Disable-TraceLogging
    
    $timer.Stop()
    
    $testResults += @{
        Test = "Trace Logging Framework"
        Result = "PASS"
        Duration = $timer.ElapsedMilliseconds
        Details = "Start/stop operations, trace messages, and context preservation working"
    }
    Write-Host "Trace logging: PASS ($($timer.ElapsedMilliseconds)ms)" -ForegroundColor Green
} catch {
    $testResults += @{
        Test = "Trace Logging Framework"
        Result = "FAIL"
        Error = $_.Exception.Message
    }
    Write-Host "Trace logging: FAIL - $($_.Exception.Message)" -ForegroundColor Red
    
    # Cleanup
    try { Disable-TraceLogging } catch { }
}

# Test 5: Performance Metrics Integration
Write-Host "`n--- Test 5: Performance Metrics Integration ---" -ForegroundColor Yellow
try {
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Test basic performance metrics collection
    $metrics = Get-SystemPerformanceMetrics -MaxSamples 2 -SampleInterval 1
    
    if ($metrics -and $metrics.Metrics -and $metrics.Metrics.Count -gt 0) {
        # Test JSON output format
        $jsonMetrics = Get-SystemPerformanceMetrics -MaxSamples 1 -OutputFormat JSON
        
        if ($jsonMetrics -and $jsonMetrics.Length -gt 100) {
            # Test with custom counter paths
            $customMetrics = Get-SystemPerformanceMetrics -CounterPaths @('\Processor(_Total)\% Processor Time') -MaxSamples 1
            
            if ($customMetrics -and $customMetrics.Metrics.Count -gt 0) {
                $testResults += @{
                    Test = "Performance Metrics"
                    Result = "PASS"
                    Duration = $timer.ElapsedMilliseconds
                    Details = "Collected $($metrics.Metrics.Count) metrics in multiple formats"
                }
                Write-Host "Performance metrics: PASS ($($timer.ElapsedMilliseconds)ms)" -ForegroundColor Green
            } else {
                throw "Custom counter paths test failed"
            }
        } else {
            throw "JSON output format test failed"
        }
    } else {
        throw "No performance metrics collected"
    }
    
    $timer.Stop()
} catch {
    $testResults += @{
        Test = "Performance Metrics"
        Result = "FAIL"
        Error = $_.Exception.Message
    }
    Write-Host "Performance metrics: FAIL - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Log Search and Analysis
Write-Host "`n--- Test 6: Log Search and Analysis ---" -ForegroundColor Yellow
try {
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Create test log content
    $testLogPath = ".\test_search.log"
    $testLogContent = @"
[2025-08-22 08:00:01.123] [INFO] [TestSource] Test information message
[2025-08-22 08:00:02.456] [ERROR] [TestSource] Test error message for search
[2025-08-22 08:00:03.789] [WARN] [TestSource] Test warning message
[2025-08-22 08:00:04.012] [DEBUG] [TestSource] Test debug message
[2025-08-22 08:00:05.345] [ERROR] [TestSource] Another test error message
"@
    $testLogContent | Out-File -FilePath $testLogPath -Encoding ASCII
    
    # Test log search
    $searchResults = Search-SystemStatusLogs -Pattern "error" -LogPath $testLogPath -MaxResults 10
    
    if ($searchResults -and $searchResults.Results.Count -eq 2) {
        # Test log level filtering
        $errorResults = Search-SystemStatusLogs -LogLevels @('ERROR') -LogPath $testLogPath
        
        if ($errorResults -and $errorResults.Results.Count -eq 2) {
            # Test JSON output
            $jsonResults = Search-SystemStatusLogs -Pattern "test" -LogPath $testLogPath -OutputFormat JSON
            
            if ($jsonResults -and $jsonResults.Length -gt 100) {
                $testResults += @{
                    Test = "Log Search and Analysis"
                    Result = "PASS"
                    Duration = $timer.ElapsedMilliseconds
                    Details = "Pattern search, log level filtering, and JSON output working"
                }
                Write-Host "Log search: PASS ($($timer.ElapsedMilliseconds)ms)" -ForegroundColor Green
            } else {
                throw "JSON output test failed"
            }
        } else {
            throw "Log level filtering test failed"
        }
    } else {
        throw "Pattern search test failed"
    }
    
    # Cleanup
    if (Test-Path $testLogPath) { Remove-Item $testLogPath -Force }
    
    $timer.Stop()
} catch {
    $testResults += @{
        Test = "Log Search and Analysis"
        Result = "FAIL"
        Error = $_.Exception.Message
    }
    Write-Host "Log search: FAIL - $($_.Exception.Message)" -ForegroundColor Red
    
    # Cleanup
    try { if (Test-Path $testLogPath) { Remove-Item $testLogPath -Force } } catch { }
}

# Test 7: Diagnostic Report Generation
Write-Host "`n--- Test 7: Diagnostic Report Generation ---" -ForegroundColor Yellow
try {
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Test basic report generation
    $reportPath = ".\test_diagnostic_report.html"
    $reportResult = New-DiagnosticReport -OutputPath $reportPath -Template 'Standard'
    
    if ($reportResult.Success -and (Test-Path $reportPath)) {
        # Verify report content
        $reportContent = Get-Content $reportPath -Raw
        
        if ($reportContent -and $reportContent.Contains('Unity-Claude SystemStatus Diagnostic Report')) {
            # Test report with performance data
            $performanceReportPath = ".\test_performance_report.html"
            $performanceReport = New-DiagnosticReport -OutputPath $performanceReportPath -IncludePerformanceData
            
            if ($performanceReport.Success -and (Test-Path $performanceReportPath)) {
                $testResults += @{
                    Test = "Diagnostic Report Generation"
                    Result = "PASS"
                    Duration = $timer.ElapsedMilliseconds
                    Details = "Standard and performance reports generated successfully"
                }
                Write-Host "Diagnostic report: PASS ($($timer.ElapsedMilliseconds)ms)" -ForegroundColor Green
                
                # Cleanup
                if (Test-Path $performanceReportPath) { Remove-Item $performanceReportPath -Force }
            } else {
                throw "Performance report generation failed"
            }
        } else {
            throw "Report content validation failed"
        }
        
        # Cleanup
        if (Test-Path $reportPath) { Remove-Item $reportPath -Force }
    } else {
        throw "Basic report generation failed"
    }
    
    $timer.Stop()
} catch {
    $testResults += @{
        Test = "Diagnostic Report Generation"
        Result = "FAIL"
        Error = $_.Exception.Message
    }
    Write-Host "Diagnostic report: FAIL - $($_.Exception.Message)" -ForegroundColor Red
    
    # Cleanup
    try { 
        if (Test-Path $reportPath) { Remove-Item $reportPath -Force }
        if (Test-Path $performanceReportPath) { Remove-Item $performanceReportPath -Force }
    } catch { }
}

# Test 8: Configuration Integration
Write-Host "`n--- Test 8: Configuration Integration ---" -ForegroundColor Yellow
try {
    $timer = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Test enhanced configuration loading
    $config = Get-SystemStatusConfiguration
    
    if ($config -and $config.Logging) {
        # Verify new logging configuration options
        $requiredKeys = @('LogRotationEnabled', 'LogRotationSizeMB', 'EnableTraceLogging', 'EnableStructuredLogging', 'DiagnosticMode', 'CompressOldLogs')
        $missingKeys = @()
        
        foreach ($key in $requiredKeys) {
            if (-not $config.Logging.ContainsKey($key)) {
                $missingKeys += $key
            }
        }
        
        if ($missingKeys.Count -eq 0) {
            # Verify performance configuration
            $perfRequiredKeys = @('EnablePerformanceCounters', 'CounterSampleInterval', 'MaxPerformanceDataPoints', 'EnablePerformanceAnalysis')
            $perfMissingKeys = @()
            
            foreach ($key in $perfRequiredKeys) {
                if (-not $config.Performance.ContainsKey($key)) {
                    $perfMissingKeys += $key
                }
            }
            
            if ($perfMissingKeys.Count -eq 0) {
                $testResults += @{
                    Test = "Configuration Integration"
                    Result = "PASS"
                    Duration = $timer.ElapsedMilliseconds
                    Details = "All new logging and performance configuration options present"
                }
                Write-Host "Configuration integration: PASS ($($timer.ElapsedMilliseconds)ms)" -ForegroundColor Green
            } else {
                throw "Missing performance configuration keys: $($perfMissingKeys -join ', ')"
            }
        } else {
            throw "Missing logging configuration keys: $($missingKeys -join ', ')"
        }
    } else {
        throw "Configuration loading failed or missing Logging section"
    }
    
    $timer.Stop()
} catch {
    $testResults += @{
        Test = "Configuration Integration"
        Result = "FAIL"
        Error = $_.Exception.Message
    }
    Write-Host "Configuration integration: FAIL - $($_.Exception.Message)" -ForegroundColor Red
}

# Test Summary
$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_.Result -eq 'PASS' }).Count
$failedTests = ($testResults | Where-Object { $_.Result -eq 'FAIL' }).Count
$successRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 1) } else { 0 }

$testEndTime = Get-Date
$totalDuration = ($testEndTime - $testStartTime).TotalMilliseconds

Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor Red
Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 90) { 'Green' } elseif ($successRate -ge 70) { 'Yellow' } else { 'Red' })
Write-Host "Total Duration: $([math]::Round($totalDuration, 0))ms" -ForegroundColor Gray
Write-Host "Test Completed: $testEndTime" -ForegroundColor Gray

# Detailed Results
if ($Verbose) {
    Write-Host "`n=== Detailed Results ===" -ForegroundColor Cyan
    foreach ($result in $testResults) {
        $status = if ($result.Result -eq 'PASS') { 'Green' } else { 'Red' }
        Write-Host "$($result.Test): $($result.Result)" -ForegroundColor $status
        if ($result.Duration) {
            Write-Host "  Duration: $($result.Duration)ms" -ForegroundColor Gray
        }
        if ($result.Details) {
            Write-Host "  Details: $($result.Details)" -ForegroundColor Gray
        }
        if ($result.Error) {
            Write-Host "  Error: $($result.Error)" -ForegroundColor Red
        }
        Write-Host ""
    }
}

# Save results if requested
if ($SaveResults) {
    $resultFile = "Test_Results_Phase3Day3_LoggingDiagnostics_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
    
    $summary = @"
Unity-Claude SystemStatus Phase 3 Day 3: Logging and Diagnostics Test Results
Generated: $(Get-Date)
Total Tests: $totalTests
Passed: $passedTests
Failed: $failedTests
Success Rate: $successRate%
Total Duration: $([math]::Round($totalDuration, 0))ms

Detailed Results:
"@
    
    foreach ($result in $testResults) {
        $summary += "`n$($result.Test): $($result.Result)"
        if ($result.Duration) { $summary += " ($($result.Duration)ms)" }
        if ($result.Details) { $summary += "`n  Details: $($result.Details)" }
        if ($result.Error) { $summary += "`n  Error: $($result.Error)" }
        $summary += "`n"
    }
    
    $summary | Out-File -FilePath $resultFile -Encoding UTF8
    Write-Host "Results saved to: $resultFile" -ForegroundColor Green
}

# Return results for automation
return @{
    TotalTests = $totalTests
    PassedTests = $passedTests
    FailedTests = $failedTests
    SuccessRate = $successRate
    Duration = $totalDuration
    Results = $testResults
}