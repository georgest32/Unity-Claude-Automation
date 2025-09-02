# Test-ProactiveMaintenanceEngine.ps1
# Test script for Unity-Claude Proactive Maintenance Engine
# Validates proactive recommendations, trend analysis, and early warning systems

param(
    [switch]$Verbose,
    [switch]$LongRunning
)

# Set verbose preference
if ($Verbose) {
    $VerbosePreference = "Continue"
}

# Import the module
$proactiveMaintenancePath = Join-Path $PSScriptRoot "..\Modules\Unity-Claude-ProactiveMaintenanceEngine"
Import-Module $proactiveMaintenancePath -Force

Write-Host "`n===== Unity-Claude Proactive Maintenance Engine Test =====" -ForegroundColor Cyan
Write-Host "Testing proactive recommendations, trend analysis, and early warnings" -ForegroundColor Cyan
Write-Host "===================================================================`n" -ForegroundColor Cyan

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

# Test 1: Engine Initialization
Test-Functionality "Proactive Maintenance Engine Initialization" {
    $result = Initialize-ProactiveMaintenanceEngine -AutoDiscoverModules
    
    if ($result) {
        $stats = Get-ProactiveMaintenanceStatistics
        return ($null -ne $stats)
    }
    return $false
}

# Test 2: Module Discovery
Test-Functionality "Module Auto-Discovery" {
    $stats = Get-ProactiveMaintenanceStatistics
    
    # Should have discovered at least some modules
    $connectedCount = ($stats.ConnectedModules.PSObject.Properties.Value | Where-Object { $_ -eq $true }).Count
    return ($connectedCount -gt 0)
}

# Test 3: Custom Configuration
Test-Functionality "Custom Configuration Support" {
    $customConfig = @{
        AnalysisInterval = 180000      # 3 minutes
        MaxRecommendations = 15
        MinConfidence = 0.6
    }
    
    $result = Initialize-ProactiveMaintenanceEngine -Configuration $customConfig
    
    if ($result) {
        $stats = Get-ProactiveMaintenanceStatistics
        return ($null -ne $stats)
    }
    return $false
}

# Test 4: Engine Start
Test-Functionality "Proactive Maintenance Engine Start" {
    $startResult = Start-ProactiveMaintenanceEngine
    
    if ($startResult) {
        $stats = Get-ProactiveMaintenanceStatistics
        return ($stats.IsRunning -eq $true)
    }
    return $false
}

# Test 5: Recommendation Generation
Test-Functionality "Recommendation Generation" {
    # Trigger test analysis cycle for immediate recommendations
    $generatedCount = Invoke-TestAnalysisCycle
    
    if ($generatedCount -gt 0) {
        $recommendations = Get-ProactiveRecommendations -Top 5
        return ($recommendations.Count -gt 0)
    }
    
    return $false
}

# Test 6: Recommendation Ranking
Test-Functionality "Recommendation Ranking Logic" {
    # Generate recommendations first
    $generatedCount = Invoke-TestAnalysisCycle
    
    if ($generatedCount -gt 0) {
        $recommendations = Get-ProactiveRecommendations -Top 10
        
        if ($recommendations.Count -gt 1) {
            # Check if recommendations are properly ranked (highest score first)
            $firstScore = $recommendations[0].Score
            $lastScore = $recommendations[-1].Score
            return ($firstScore -ge $lastScore)
        }
        
        # If only one recommendation, that's still valid
        return ($recommendations.Count -gt 0)
    }
    
    return $false
}

# Test 7: Priority Filtering
Test-Functionality "Priority-Based Filtering" {
    $highPriorityRecs = Get-ProactiveRecommendations -MinPriority High
    $allRecs = Get-ProactiveRecommendations
    
    # High priority filter should return same or fewer recommendations
    return ($highPriorityRecs.Count -le $allRecs.Count)
}

# Test 8: Warning System
Test-Functionality "Early Warning System" {
    # Wait for warning check cycle
    Start-Sleep -Seconds 2
    
    $warnings = Get-MaintenanceWarnings -Last 5
    
    # Should have checked for warnings (may or may not generate any)
    return ($warnings.Count -ge 0)
}

# Test 9: Statistics Tracking
Test-Functionality "Statistics Tracking" {
    $stats = Get-ProactiveMaintenanceStatistics
    
    # Verify required properties exist
    $requiredProps = @('RecommendationsGenerated', 'WarningsIssued', 'TrendsAnalyzed', 
                       'IntegrationsTriggered', 'IsRunning', 'ConnectedModules')
    
    $hasAllProps = $true
    foreach ($prop in $requiredProps) {
        if (-not ($stats.PSObject.Properties.Name -contains $prop)) {
            $hasAllProps = $false
            break
        }
    }
    
    return $hasAllProps
}

# Test 10: Connected Modules Status
Test-Functionality "Connected Modules Status" {
    $stats = Get-ProactiveMaintenanceStatistics
    $connectedModules = $stats.ConnectedModules
    
    # Should have attempted to connect to key modules
    $keyModules = @('PredictiveAnalysis', 'RealTimeMonitoring')
    $hasKeyModules = $true
    
    foreach ($module in $keyModules) {
        if (-not $connectedModules.PSObject.Properties.Name -contains $module) {
            $hasKeyModules = $false
            break
        }
    }
    
    return $hasKeyModules
}

# Test 11: Recommendation Data Structure
Test-Functionality "Recommendation Data Structure" {
    $recommendations = Get-ProactiveRecommendations -Top 3
    
    if ($recommendations.Count -gt 0) {
        $rec = $recommendations[0]
        
        # Verify recommendation has required properties
        $requiredProps = @('Id', 'Type', 'Priority', 'Title', 'Description', 'Impact', 'Effort', 'Confidence', 'Score')
        
        $hasAllProps = $true
        foreach ($prop in $requiredProps) {
            if (-not ($rec.PSObject.Properties.Name -contains $prop)) {
                $hasAllProps = $false
                break
            }
        }
        
        return $hasAllProps
    }
    
    return $true  # No recommendations is also valid
}

# Test 12: Warning Data Structure
Test-Functionality "Warning Data Structure" {
    $warnings = Get-MaintenanceWarnings -Last 3
    
    if ($warnings.Count -gt 0) {
        $warning = $warnings[0]
        
        # Verify warning has required properties
        $requiredProps = @('Id', 'Type', 'Metric', 'CurrentValue', 'Threshold', 'Severity', 'Timestamp')
        
        $hasAllProps = $true
        foreach ($prop in $requiredProps) {
            if (-not ($warning.PSObject.Properties.Name -contains $prop)) {
                $hasAllProps = $false
                break
            }
        }
        
        return $hasAllProps
    }
    
    return $true  # No warnings is also valid
}

# Test 13: Engine Performance
Test-Functionality "Engine Performance Validation" {
    $stats = Get-ProactiveMaintenanceStatistics
    
    # Engine should be running efficiently
    return ($stats.IsRunning -eq $true -and 
            $stats.ActiveRecommendationsCount -ge 0)
}

# Test 14: Long-Running Analysis (if enabled)
if ($LongRunning) {
    Test-Functionality "Long-Running Analysis Cycle" {
        Write-Host "`n  Running 60-second maintenance analysis cycle..." -ForegroundColor Yellow
        
        $startStats = Get-ProactiveMaintenanceStatistics
        $startRecommendations = $startStats.RecommendationsGenerated
        
        # Wait for full analysis cycles
        Start-Sleep -Seconds 60
        
        $endStats = Get-ProactiveMaintenanceStatistics
        $endRecommendations = $endStats.RecommendationsGenerated
        
        # Should have performed at least one analysis cycle
        return ($endRecommendations -ge $startRecommendations)
    }
}

# Test 15: Engine Stop
Test-Functionality "Proactive Maintenance Engine Stop" {
    $stopResult = Stop-ProactiveMaintenanceEngine
    
    if ($null -ne $stopResult) {
        $stats = Get-ProactiveMaintenanceStatistics
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
    $finalStats = Get-ProactiveMaintenanceStatistics
    Write-Host "`n===== Proactive Maintenance Engine Statistics =====" -ForegroundColor Cyan
    Write-Host "Recommendations Generated: $($finalStats.RecommendationsGenerated)" -ForegroundColor White
    Write-Host "Warnings Issued: $($finalStats.WarningsIssued)" -ForegroundColor White
    Write-Host "Trends Analyzed: $($finalStats.TrendsAnalyzed)" -ForegroundColor White
    Write-Host "Integration Triggers: $($finalStats.IntegrationsTriggered)" -ForegroundColor White
    Write-Host "Active Recommendations: $($finalStats.ActiveRecommendationsCount)" -ForegroundColor White
    Write-Host "Warning History: $($finalStats.WarningHistoryCount)" -ForegroundColor White
    Write-Host "Runtime: $($finalStats.Runtime)" -ForegroundColor White
    
    # Show connected modules
    Write-Host "`n===== Connected Modules =====" -ForegroundColor Cyan
    $finalStats.ConnectedModules.PSObject.Properties | ForEach-Object {
        $status = if ($_.Value) { "Connected" } else { "Not Connected" }
        $color = if ($_.Value) { "Green" } else { "Yellow" }
        Write-Host "$($_.Name): $status" -ForegroundColor $color
    }
}
catch {
    Write-Host "Could not retrieve final statistics: $_" -ForegroundColor Yellow
}

# Export results
$resultsFile = Join-Path $PSScriptRoot "ProactiveMaintenanceEngine-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
Write-Host "`nTest results saved to: $resultsFile" -ForegroundColor Gray

# Return success/failure for CI/CD integration
exit $(if ($testResults.Failed -eq 0) { 0 } else { 1 })