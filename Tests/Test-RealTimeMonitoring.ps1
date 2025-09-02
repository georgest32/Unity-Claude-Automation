# Test-RealTimeMonitoring.ps1
# Test script for Unity-Claude Real-Time Monitoring Framework
# Validates comprehensive FileSystemWatcher infrastructure

param(
    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Set verbose preference
if ($Verbose) {
    $VerbosePreference = "Continue"
}

# Import the module
$modulePath = Join-Path $PSScriptRoot "..\Modules\Unity-Claude-RealTimeMonitoring"
Import-Module $modulePath -Force

Write-Host "`n===== Unity-Claude Real-Time Monitoring Framework Test =====" -ForegroundColor Cyan
Write-Host "Testing comprehensive FileSystemWatcher infrastructure" -ForegroundColor Cyan
Write-Host "============================================================`n" -ForegroundColor Cyan

# Test results collection
$testResults = @{
    TotalTests = 0
    Passed = 0
    Failed = 0
    Details = @()
}

function Test-Functionality {
    param(
        [string]$TestName,
        [scriptblock]$TestScript
    )
    
    $testResults.TotalTests++
    Write-Host "Testing: $TestName" -NoNewline
    
    try {
        $result = & $TestScript
        if ($result) {
            Write-Host " [PASSED]" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Details += @{
                Test = $TestName
                Result = "Passed"
                Details = $result
            }
        }
        else {
            Write-Host " [FAILED]" -ForegroundColor Red
            $testResults.Failed++
            $testResults.Details += @{
                Test = $TestName
                Result = "Failed"
                Details = "Test returned false"
            }
        }
    }
    catch {
        Write-Host " [ERROR]" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        $testResults.Failed++
        $testResults.Details += @{
            Test = $TestName
            Result = "Error"
            Details = $_.Exception.Message
        }
    }
}

# Test 1: Module Initialization
Test-Functionality "Module Initialization" {
    $config = @{
        MonitoredPaths = @($PSScriptRoot)
        FileFilters = @("*.ps1", "*.txt")
        EventBufferSize = 500
    }
    
    $result = Initialize-RealTimeMonitoring -Configuration $config
    
    if ($result) {
        $currentConfig = Get-MonitoringConfiguration
        return ($currentConfig.MonitoredPaths -contains $PSScriptRoot)
    }
    return $false
}

# Test 2: Start Monitoring
Test-Functionality "Start FileSystem Monitoring" {
    # Create a test directory
    $testDir = Join-Path $PSScriptRoot "TestMonitoring"
    if (-not (Test-Path $testDir)) {
        New-Item -Path $testDir -ItemType Directory -Force | Out-Null
    }
    
    $result = Start-FileSystemMonitoring -Paths $testDir -Filters "*.txt", "*.ps1"
    
    if ($result.Success) {
        # Get statistics to verify monitoring started
        $stats = Get-MonitoringStatistics
        return ($stats.IsRunning -and $stats.WatcherCount -gt 0)
    }
    return $false
}

# Test 3: Event Detection
Test-Functionality "Event Detection and Queueing" {
    $testDir = Join-Path $PSScriptRoot "TestMonitoring"
    $testFile = Join-Path $testDir "test_$(Get-Date -Format 'yyyyMMddHHmmss').txt"
    
    # Create a test file to trigger event
    "Test content" | Out-File -FilePath $testFile -Force
    
    # Wait for event processing
    Start-Sleep -Seconds 2
    
    # Check statistics
    $stats = Get-MonitoringStatistics
    
    # Clean up test file
    Remove-Item -Path $testFile -Force -ErrorAction SilentlyContinue
    
    return ($stats.EventsReceived -gt 0)
}

# Test 4: Multiple File Changes
Test-Functionality "Multiple File Change Detection" {
    $testDir = Join-Path $PSScriptRoot "TestMonitoring"
    $initialStats = Get-MonitoringStatistics
    $initialEvents = $initialStats.EventsReceived
    
    # Create multiple test files
    $testFiles = @()
    for ($i = 1; $i -le 5; $i++) {
        $testFile = Join-Path $testDir "multi_test_$i.txt"
        "Content $i" | Out-File -FilePath $testFile -Force
        $testFiles += $testFile
    }
    
    # Wait for event processing
    Start-Sleep -Seconds 2
    
    # Check statistics
    $newStats = Get-MonitoringStatistics
    $newEvents = $newStats.EventsReceived - $initialEvents
    
    # Clean up test files
    foreach ($file in $testFiles) {
        Remove-Item -Path $file -Force -ErrorAction SilentlyContinue
    }
    
    return ($newEvents -ge 5)
}

# Test 5: Configuration Management
Test-Functionality "Configuration Management" {
    # Stop monitoring first
    Stop-FileSystemMonitoring | Out-Null
    
    # Test configuration update
    $newConfig = @{
        EventBufferSize = 2000
        ProcessingInterval = 250
        EnableAutoRecovery = $false
    }
    
    $result = Set-MonitoringConfiguration -Configuration $newConfig
    
    if ($result) {
        $currentConfig = Get-MonitoringConfiguration
        return ($currentConfig.EventBufferSize -eq 2000 -and 
                $currentConfig.ProcessingInterval -eq 250 -and
                $currentConfig.EnableAutoRecovery -eq $false)
    }
    return $false
}

# Test 6: Monitoring Health Check
Test-Functionality "Monitoring Health Check" {
    # Restart monitoring for health check
    Start-FileSystemMonitoring -Paths (Join-Path $PSScriptRoot "TestMonitoring") | Out-Null
    
    $health = Test-MonitoringHealth
    
    # Health should be good for a fresh start
    return ($health.IsHealthy -eq $true)
}

# Test 7: Statistics Tracking
Test-Functionality "Statistics Tracking" {
    $stats = Get-MonitoringStatistics
    
    # Verify statistics structure
    $hasRequiredProperties = $true
    $requiredProps = @('EventsReceived', 'EventsProcessed', 'ErrorCount', 'QueueLength', 'WatcherCount', 'IsRunning')
    
    foreach ($prop in $requiredProps) {
        if (-not ($stats.PSObject.Properties.Name -contains $prop)) {
            $hasRequiredProperties = $false
            break
        }
    }
    
    return $hasRequiredProperties
}

# Test 8: Subdirectory Monitoring
Test-Functionality "Subdirectory Monitoring" {
    $testDir = Join-Path $PSScriptRoot "TestMonitoring"
    $subDir = Join-Path $testDir "SubFolder"
    
    # Create subdirectory
    if (-not (Test-Path $subDir)) {
        New-Item -Path $subDir -ItemType Directory -Force | Out-Null
    }
    
    # Stop and restart monitoring with subdirectory support
    Stop-FileSystemMonitoring | Out-Null
    Start-FileSystemMonitoring -Paths $testDir -IncludeSubdirectories | Out-Null
    
    $initialStats = Get-MonitoringStatistics
    $initialEvents = $initialStats.EventsReceived
    
    # Create file in subdirectory
    $subFile = Join-Path $subDir "subtest.txt"
    "Subdirectory test" | Out-File -FilePath $subFile -Force
    
    # Wait for event processing
    Start-Sleep -Seconds 2
    
    $newStats = Get-MonitoringStatistics
    $eventDetected = ($newStats.EventsReceived -gt $initialEvents)
    
    # Clean up
    Remove-Item -Path $subFile -Force -ErrorAction SilentlyContinue
    
    return $eventDetected
}

# Test 9: Error Handling
Test-Functionality "Error Handling and Recovery" {
    $stats = Get-MonitoringStatistics
    
    # The system should handle errors gracefully
    # Check that error count is relatively low
    if ($stats.EventsReceived -gt 0) {
        $errorRate = $stats.ErrorCount / $stats.EventsReceived
        return ($errorRate -lt 0.05)  # Less than 5% error rate
    }
    return $true  # No events means no errors
}

# Test 10: Stop Monitoring
Test-Functionality "Stop Monitoring and Cleanup" {
    $stopResult = Stop-FileSystemMonitoring
    
    # Verify monitoring stopped
    $stats = Get-MonitoringStatistics
    
    # Check that monitoring is stopped and watchers are cleared
    $config = Get-MonitoringConfiguration
    
    return ($stats.IsRunning -eq $false -and $stats.WatcherCount -eq 0)
}

# Clean up test directory
$testDir = Join-Path $PSScriptRoot "TestMonitoring"
if (Test-Path $testDir) {
    Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
}

# Display test summary
Write-Host "`n===== Test Summary =====" -ForegroundColor Cyan
Write-Host "Total Tests: $($testResults.TotalTests)" -ForegroundColor White
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor $(if ($testResults.Failed -eq 0) { "Green" } else { "Red" })

# Calculate success rate
if ($testResults.TotalTests -gt 0) {
    $successRate = [math]::Round(($testResults.Passed / $testResults.TotalTests) * 100, 2)
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 95) { "Green" } elseif ($successRate -ge 80) { "Yellow" } else { "Red" })
}

# Export results
$resultsFile = Join-Path $PSScriptRoot "RealTimeMonitoring-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
Write-Host "`nTest results saved to: $resultsFile" -ForegroundColor Gray

# Return success/failure for CI/CD integration
exit $(if ($testResults.Failed -eq 0) { 0 } else { 1 })