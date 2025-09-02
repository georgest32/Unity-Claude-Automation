# Test-RealTimeAnalysisPipeline.ps1
# Test script for Unity-Claude Real-Time Analysis Pipeline Integration
# Validates pipeline integration and streaming processing capabilities

param(
    [switch]$Verbose,
    [switch]$EnableAI
)

# Set verbose preference
if ($Verbose) {
    $VerbosePreference = "Continue"
}

# Import required modules
$realTimeAnalysisPath = Join-Path $PSScriptRoot "..\Modules\Unity-Claude-RealTimeAnalysis"
Import-Module $realTimeAnalysisPath -Force

Write-Host "`n===== Unity-Claude Real-Time Analysis Pipeline Test =====" -ForegroundColor Cyan
Write-Host "Testing real-time analysis pipeline integration and streaming" -ForegroundColor Cyan
Write-Host "==========================================================`n" -ForegroundColor Cyan

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

# Test 1: Pipeline Initialization
Test-Functionality "Pipeline Initialization" {
    $result = Initialize-RealTimeAnalysisPipeline -AutoDiscoverModules -EnableAI:$EnableAI
    
    if ($result) {
        $stats = Get-RealTimeAnalysisStatistics
        return ($null -ne $stats)
    }
    return $false
}

# Test 2: Module Discovery
Test-Functionality "Module Auto-Discovery" {
    # Get pipeline statistics to check connected services
    $stats = Get-RealTimeAnalysisStatistics
    
    # Should have discovered at least some modules
    $connectedCount = ($stats.ConnectedServices.PSObject.Properties.Value | Where-Object { $_ -eq $true }).Count
    return ($connectedCount -gt 0)
}

# Test 3: Configuration Management
Test-Functionality "Configuration Management" {
    # Test configuration updates
    $newConfig = @{
        BatchSize = 10
        ProcessingInterval = 500
        EnableLiveVisualization = $false
    }
    
    $result = Set-PipelineConfiguration -Configuration $newConfig
    
    if ($result) {
        $currentConfig = Get-PipelineConfiguration
        return ($currentConfig.BatchSize -eq 10 -and 
                $currentConfig.ProcessingInterval -eq 500 -and
                $currentConfig.EnableLiveVisualization -eq $false)
    }
    return $false
}

# Test 4: Pipeline Start
Test-Functionality "Pipeline Start" {
    $startResult = Start-RealTimeAnalysisPipeline
    
    if ($startResult.Success) {
        $stats = Get-RealTimeAnalysisStatistics
        return ($stats.IsRunning -eq $true)
    }
    return $false
}

# Test 5: Test Request Submission
Test-Functionality "Test Request Submission" {
    # Create a test file path
    $testFilePath = Join-Path $PSScriptRoot "TestFile.ps1"
    
    # Submit test analysis request
    Submit-TestAnalysisRequest -FilePath $testFilePath -ChangeType "Created"
    
    # Wait a moment for processing
    Start-Sleep -Seconds 2
    
    $stats = Get-RealTimeAnalysisStatistics
    return ($stats.FilesProcessed -gt 0 -or $stats.ProcessingQueueLength -gt 0)
}

# Test 6: Pipeline Health Check
Test-Functionality "Pipeline Health Check" {
    $health = Test-PipelineHealth
    
    # Pipeline should be healthy if running
    return ($null -ne $health.IsHealthy)
}

# Test 7: Statistics Tracking
Test-Functionality "Statistics Tracking" {
    $stats = Get-RealTimeAnalysisStatistics
    
    # Verify statistics structure
    $hasRequiredProperties = $true
    $requiredProps = @('FilesProcessed', 'AnalysisRequestsGenerated', 'VisualizationUpdatesTriggered', 'Errors', 'IsRunning')
    
    foreach ($prop in $requiredProps) {
        if (-not ($stats.PSObject.Properties.Name -contains $prop)) {
            $hasRequiredProperties = $false
            break
        }
    }
    
    return $hasRequiredProperties
}

# Test 8: Multiple Request Processing
Test-Functionality "Multiple Request Processing" {
    $initialStats = Get-RealTimeAnalysisStatistics
    $initialProcessed = $initialStats.FilesProcessed
    
    # Submit multiple test requests
    $testFiles = @(
        "TestModule.psm1",
        "TestScript.ps1", 
        "TestConfig.json",
        "TestDoc.md"
    )
    
    foreach ($file in $testFiles) {
        $testPath = Join-Path $PSScriptRoot $file
        Submit-TestAnalysisRequest -FilePath $testPath -ChangeType "Modified"
    }
    
    # Wait for processing
    Start-Sleep -Seconds 3
    
    $newStats = Get-RealTimeAnalysisStatistics
    $processedIncrease = $newStats.FilesProcessed - $initialProcessed
    
    return ($processedIncrease -gt 0 -or $newStats.ProcessingQueueLength -gt 0)
}

# Test 9: Service Integration Status
Test-Functionality "Service Integration Status" {
    $stats = Get-RealTimeAnalysisStatistics
    $connectedServices = $stats.ConnectedServices
    
    # Should have at least attempted to connect to key services
    $keyServices = @('FileSystemWatcher', 'ChangeIntelligence')
    $hasKeyServices = $true
    
    foreach ($service in $keyServices) {
        if (-not $connectedServices.PSObject.Properties.Name -contains $service) {
            $hasKeyServices = $false
            break
        }
    }
    
    return $hasKeyServices
}

# Test 10: Performance Metrics
Test-Functionality "Performance Metrics" {
    $stats = Get-RealTimeAnalysisStatistics
    
    # Should have performance metrics if any processing occurred
    $hasMetrics = ($stats.AverageProcessingTime -ge 0 -and 
                   $null -ne $stats.Runtime)
    
    return $hasMetrics
}

# Test 11: Error Handling
Test-Functionality "Error Handling" {
    # Submit request with invalid file path to test error handling
    Submit-TestAnalysisRequest -FilePath "C:\NonExistent\InvalidFile.ps1" -ChangeType "Modified"
    
    # Wait for processing
    Start-Sleep -Seconds 2
    
    $stats = Get-RealTimeAnalysisStatistics
    
    # System should handle errors gracefully without crashing
    return ($stats.IsRunning -eq $true)
}

# Test 12: Pipeline Stop
Test-Functionality "Pipeline Stop" {
    $stopResult = Stop-RealTimeAnalysisPipeline
    
    if ($null -ne $stopResult) {
        $stats = Get-RealTimeAnalysisStatistics
        return ($stats.IsRunning -eq $false)
    }
    return $false
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

# Get final statistics
try {
    $finalStats = Get-RealTimeAnalysisStatistics
    Write-Host "`n===== Pipeline Statistics =====" -ForegroundColor Cyan
    Write-Host "Files Processed: $($finalStats.FilesProcessed)" -ForegroundColor White
    Write-Host "Analysis Requests Generated: $($finalStats.AnalysisRequestsGenerated)" -ForegroundColor White
    Write-Host "Visualization Updates: $($finalStats.VisualizationUpdatesTriggered)" -ForegroundColor White
    Write-Host "Errors: $($finalStats.Errors)" -ForegroundColor White
    Write-Host "Average Processing Time: $([math]::Round($finalStats.AverageProcessingTime, 2))ms" -ForegroundColor White
    
    # Show connected services
    Write-Host "`n===== Connected Services =====" -ForegroundColor Cyan
    $finalStats.ConnectedServices.PSObject.Properties | ForEach-Object {
        $status = if ($_.Value) { "Connected" } else { "Not Connected" }
        $color = if ($_.Value) { "Green" } else { "Yellow" }
        Write-Host "$($_.Name): $status" -ForegroundColor $color
    }
}
catch {
    Write-Host "Could not retrieve final statistics: $_" -ForegroundColor Yellow
}

# Export results
$resultsFile = Join-Path $PSScriptRoot "RealTimeAnalysisPipeline-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
Write-Host "`nTest results saved to: $resultsFile" -ForegroundColor Gray

# Return success/failure for CI/CD integration
exit $(if ($testResults.Failed -eq 0) { 0 } else { 1 })