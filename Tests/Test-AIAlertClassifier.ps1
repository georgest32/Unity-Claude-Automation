# Test-AIAlertClassifier.ps1
# Test script for Unity-Claude AI-Powered Alert Classifier
# Validates AI classification, prioritization, escalation, and correlation

param(
    [switch]$Verbose,
    [switch]$TestAI
)

# Set verbose preference
if ($Verbose) {
    $VerbosePreference = "Continue"
}

# Import required modules
$aiAlertClassifierPath = Join-Path $PSScriptRoot "..\Modules\Unity-Claude-AIAlertClassifier"
Import-Module $aiAlertClassifierPath -Force

Write-Host "`n===== Unity-Claude AI-Powered Alert Classifier Test =====" -ForegroundColor Cyan
Write-Host "Testing AI classification, prioritization, and escalation systems" -ForegroundColor Cyan
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

# Create test alerts for classification
function New-TestAlert {
    param(
        [string]$Source,
        [string]$Message,
        [string]$Component = "Test",
        [string]$Id = [Guid]::NewGuid().ToString()
    )
    
    return [PSCustomObject]@{
        Id = $Id
        Source = $Source
        Message = $Message
        Component = $Component
        Timestamp = Get-Date
        Impact = "Medium"
    }
}

# Test 1: Module Initialization
Test-Functionality "AI Alert Classifier Initialization" {
    $result = Initialize-AIAlertClassifier -EnableAI:$TestAI
    
    if ($result) {
        $stats = Get-AIAlertStatistics
        return ($null -ne $stats)
    }
    return $false
}

# Test 2: Rule-Based Classification
Test-Functionality "Rule-Based Alert Classification" {
    $criticalAlert = New-TestAlert -Source "System" -Message "Critical system failure detected" -Component "CoreService"
    
    $classification = Invoke-AIAlertClassification -Alert $criticalAlert
    
    return ($classification.Severity -eq 'Critical' -and 
            $classification.Priority -gt 7)
}

# Test 3: Security Alert Classification
Test-Functionality "Security Alert Classification" {
    $securityAlert = New-TestAlert -Source "Security" -Message "Failed login attempt detected" -Component "Authentication"
    
    $classification = Invoke-AIAlertClassification -Alert $securityAlert
    
    return ($classification.Category -eq 'Security' -and
            $classification.Severity -in @('High', 'Critical'))
}

# Test 4: Performance Alert Classification
Test-Functionality "Performance Alert Classification" {
    $performanceAlert = New-TestAlert -Source "Performance" -Message "High CPU usage detected" -Component "SystemMonitor"
    
    $classification = Invoke-AIAlertClassification -Alert $performanceAlert
    
    return ($classification.Category -eq 'Performance' -and
            $classification.Priority -gt 3)
}

# Test 5: Information Alert Classification
Test-Functionality "Information Alert Classification" {
    $infoAlert = New-TestAlert -Source "Info" -Message "System backup completed successfully" -Component "BackupService"
    
    $classification = Invoke-AIAlertClassification -Alert $infoAlert
    
    return ($classification.Severity -eq 'Info' -and
            $classification.Priority -le 3)
}

# Test 6: Priority Calculation
Test-Functionality "Priority Calculation Logic" {
    $highPriorityAlert = New-TestAlert -Source "Security" -Message "Critical security breach detected" -Component "Firewall"
    $lowPriorityAlert = New-TestAlert -Source "Info" -Message "Routine maintenance completed" -Component "MaintenanceService"
    
    $highClassification = Invoke-AIAlertClassification -Alert $highPriorityAlert
    $lowClassification = Invoke-AIAlertClassification -Alert $lowPriorityAlert
    
    return ($highClassification.Priority -gt $lowClassification.Priority)
}

# Test 7: Escalation Plan Generation
Test-Functionality "Escalation Plan Generation" {
    $escalationAlert = New-TestAlert -Source "System" -Message "Database connection failed" -Component "Database"
    
    $classification = Invoke-AIAlertClassification -Alert $escalationAlert
    
    return ($null -ne $classification.EscalationPlan -and
            $classification.EscalationPlan.Required -eq $true)
}

# Test 8: Contextual Information Integration
Test-Functionality "Contextual Information Integration" {
    # Create alert with file path for contextual enrichment
    $contextAlert = New-TestAlert -Source "FileSystem" -Message "File modification detected" -Component "FileWatcher"
    $contextAlert | Add-Member -NotePropertyName "FilePath" -NotePropertyValue "$PSScriptRoot\TestFile.ps1"
    
    $classification = Invoke-AIAlertClassification -Alert $contextAlert
    
    return ($classification.Context.Count -gt 0 -and
            $classification.Details.Count -ge 2)
}

# Test 9: Alert Correlation Testing
Test-Functionality "Alert Correlation Detection" {
    # Create two similar alerts
    $alert1 = New-TestAlert -Source "System" -Message "Service timeout detected" -Component "WebService"
    $alert2 = New-TestAlert -Source "System" -Message "Service timeout detected" -Component "WebService"
    
    # Classify first alert
    Invoke-AIAlertClassification -Alert $alert1 | Out-Null
    
    # Test correlation with second alert
    $correlations = Test-AlertCorrelation -NewAlert $alert2
    
    return ($correlations.Count -gt 0)
}

# Test 10: Cache Performance
Test-Functionality "Classification Cache Performance" {
    $cacheAlert = New-TestAlert -Source "Test" -Message "Cache performance test alert" -Component "TestService"
    
    # First classification (should populate cache)
    $classification1 = Invoke-AIAlertClassification -Alert $cacheAlert
    
    # Second classification (should hit cache)
    $classification2 = Invoke-AIAlertClassification -Alert $cacheAlert
    
    $stats = Get-AIAlertStatistics
    
    return ($stats.CacheHits -gt 0)
}

# Test 11: Multiple Alert Categories
Test-Functionality "Multiple Alert Categories" {
    $alerts = @(
        (New-TestAlert -Source "Error" -Message "Application exception occurred" -Component "App"),
        (New-TestAlert -Source "Warning" -Message "Memory usage approaching limit" -Component "System"),
        (New-TestAlert -Source "Change" -Message "Configuration file updated" -Component "Config"),
        (New-TestAlert -Source "Maintenance" -Message "Scheduled maintenance started" -Component "Scheduler")
    )
    
    $categories = @()
    foreach ($alert in $alerts) {
        $classification = Invoke-AIAlertClassification -Alert $alert
        $categories += $classification.Category
    }
    
    # Should have classified into different categories
    $uniqueCategories = $categories | Sort-Object -Unique
    return ($uniqueCategories.Count -gt 1)
}

# Test 12: Statistics Tracking
Test-Functionality "Statistics Tracking" {
    $stats = Get-AIAlertStatistics
    
    # Verify statistics structure
    $requiredProps = @('AlertsClassified', 'AIClassificationsRequested', 'CacheHits', 
                       'AlertsCorrelated', 'IsInitialized', 'Runtime')
    
    $hasAllProps = $true
    foreach ($prop in $requiredProps) {
        if (-not ($stats.PSObject.Properties.Name -contains $prop)) {
            $hasAllProps = $false
            break
        }
    }
    
    return $hasAllProps
}

# Test 13: AI Classification (if enabled)
if ($TestAI) {
    Test-Functionality "AI-Enhanced Classification" {
        $aiAlert = New-TestAlert -Source "Complex" -Message "Unusual pattern detected in system behavior with potential security implications" -Component "MonitoringSystem"
        
        $classification = Invoke-AIAlertClassification -Alert $aiAlert -UseAI
        
        # Check if AI enhancement was applied
        return ($classification.AIEnhanced -eq $true -and
                $classification.ProcessingPath -contains "AI-Severity")
    }
}

# Test 14: Error Handling
Test-Functionality "Error Handling and Graceful Degradation" {
    # Create alert with invalid data to test error handling
    $errorAlert = [PSCustomObject]@{
        Id = $null
        Source = ""
        Message = $null
        Timestamp = "invalid"
    }
    
    try {
        $classification = Invoke-AIAlertClassification -Alert $errorAlert
        # Should handle gracefully without crashing
        return ($null -ne $classification)
    }
    catch {
        # Should not throw unhandled exceptions
        return $false
    }
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
    $finalStats = Get-AIAlertStatistics
    Write-Host "`n===== AI Alert Classifier Statistics =====" -ForegroundColor Cyan
    Write-Host "Alerts Classified: $($finalStats.AlertsClassified)" -ForegroundColor White
    Write-Host "AI Classifications Requested: $($finalStats.AIClassificationsRequested)" -ForegroundColor White
    Write-Host "AI Success Rate: $($finalStats.AISuccessRate)%" -ForegroundColor White
    Write-Host "Cache Hits: $($finalStats.CacheHits)" -ForegroundColor White
    Write-Host "Cache Hit Rate: $($finalStats.CacheHitRate)%" -ForegroundColor White
    Write-Host "Alerts Correlated: $($finalStats.AlertsCorrelated)" -ForegroundColor White
    Write-Host "Ollama Available: $($finalStats.OllamaAvailable)" -ForegroundColor White
    Write-Host "Runtime: $($finalStats.Runtime)" -ForegroundColor White
}
catch {
    Write-Host "Could not retrieve final statistics: $_" -ForegroundColor Yellow
}

# Export results
$resultsFile = Join-Path $PSScriptRoot "AIAlertClassifier-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
Write-Host "`nTest results saved to: $resultsFile" -ForegroundColor Gray

# Return success/failure for CI/CD integration
exit $(if ($testResults.Failed -eq 0) { 0 } else { 1 })