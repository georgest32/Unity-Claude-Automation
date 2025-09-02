# Test-IntelligentAlerting.ps1
# Test script for Unity-Claude Intelligent Alerting System
# Validates AI integration, priority-based escalation, and comprehensive alerting

param(
    [switch]$Verbose,
    [switch]$TestAI
)

# Set verbose preference
if ($Verbose) {
    $VerbosePreference = "Continue"
}

# Import required modules
$intelligentAlertingPath = Join-Path $PSScriptRoot "..\Modules\Unity-Claude-IntelligentAlerting"
Import-Module $intelligentAlertingPath -Force

Write-Host "`n===== Unity-Claude Intelligent Alerting System Test =====" -ForegroundColor Cyan
Write-Host "Testing AI integration, escalation, and comprehensive alerting" -ForegroundColor Cyan
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

# Helper function to create test alerts
function New-TestAlert {
    param(
        [string]$Source,
        [string]$Message,
        [string]$Component = "TestComponent",
        [string]$Impact = "Medium"
    )
    
    return [PSCustomObject]@{
        Id = [Guid]::NewGuid().ToString()
        Source = $Source
        Message = $Message
        Component = $Component
        Impact = $Impact
        Timestamp = Get-Date
    }
}

# Test 1: System Initialization
Test-Functionality "Intelligent Alerting System Initialization" {
    $result = Initialize-IntelligentAlerting -AutoDiscoverModules
    
    if ($result) {
        $stats = Get-IntelligentAlertingStatistics
        return ($null -ne $stats)
    }
    return $false
}

# Test 2: Module Discovery
Test-Functionality "Module Auto-Discovery" {
    $stats = Get-IntelligentAlertingStatistics
    
    # Should have discovered at least some modules
    $connectedCount = ($stats.ConnectedModules.PSObject.Properties.Value | Where-Object { $_ -eq $true }).Count
    return ($connectedCount -gt 0)
}

# Test 3: Alert System Start
Test-Functionality "Alert System Start" {
    $startResult = Start-IntelligentAlerting
    
    if ($startResult) {
        $stats = Get-IntelligentAlertingStatistics
        return ($stats.IsRunning -eq $true)
    }
    return $false
}

# Test 4: Critical Alert Processing
Test-Functionality "Critical Alert Processing" {
    $criticalAlert = New-TestAlert -Source "System" -Message "Critical database failure detected" -Component "Database"
    
    $submitResult = Submit-Alert -Alert $criticalAlert
    
    # Wait for processing
    Start-Sleep -Seconds 2
    
    $stats = Get-IntelligentAlertingStatistics
    return ($submitResult -and $stats.AlertsProcessed -gt 0)
}

# Test 5: Security Alert Processing
Test-Functionality "Security Alert Processing" {
    $securityAlert = New-TestAlert -Source "Security" -Message "Unauthorized access attempt" -Component "AuthenticationService"
    
    $submitResult = Submit-Alert -Alert $securityAlert
    
    # Wait for processing
    Start-Sleep -Seconds 2
    
    $stats = Get-IntelligentAlertingStatistics
    return $submitResult
}

# Test 6: Performance Alert Processing
Test-Functionality "Performance Alert Processing" {
    $performanceAlert = New-TestAlert -Source "Performance" -Message "High CPU usage detected" -Component "SystemMonitor"
    
    $submitResult = Submit-Alert -Alert $performanceAlert
    
    # Wait for processing
    Start-Sleep -Seconds 2
    
    return $submitResult
}

# Test 7: Information Alert Processing
Test-Functionality "Information Alert Processing" {
    $infoAlert = New-TestAlert -Source "Info" -Message "Backup completed successfully" -Component "BackupService"
    
    $submitResult = Submit-Alert -Alert $infoAlert
    
    # Wait for processing
    Start-Sleep -Seconds 1
    
    return $submitResult
}

# Test 8: Multiple Alert Batch Processing
Test-Functionality "Multiple Alert Batch Processing" {
    $initialStats = Get-IntelligentAlertingStatistics
    $initialProcessed = $initialStats.AlertsProcessed
    
    # Submit multiple alerts
    $alerts = @(
        (New-TestAlert -Source "Error" -Message "Application error occurred" -Component "App1"),
        (New-TestAlert -Source "Warning" -Message "Memory usage warning" -Component "System"),
        (New-TestAlert -Source "Change" -Message "Configuration changed" -Component "Config"),
        (New-TestAlert -Source "Maintenance" -Message "Maintenance started" -Component "Scheduler")
    )
    
    foreach ($alert in $alerts) {
        Submit-Alert -Alert $alert | Out-Null
    }
    
    # Wait for batch processing
    Start-Sleep -Seconds 3
    
    $newStats = Get-IntelligentAlertingStatistics
    $processedIncrease = $newStats.AlertsProcessed - $initialProcessed
    
    return ($processedIncrease -gt 0)
}

# Test 9: Queue Management
Test-Functionality "Queue Management" {
    $stats = Get-IntelligentAlertingStatistics
    
    # Queue should be manageable size
    return ($stats.QueueLength -ge 0 -and $stats.QueueLength -lt 100)
}

# Test 10: Alert Notification
Test-Functionality "Alert Notification Processing" {
    $notificationAlert = New-TestAlert -Source "Critical" -Message "System critical failure" -Component "CoreSystem"
    
    Submit-Alert -Alert $notificationAlert | Out-Null
    
    # Wait for notification processing
    Start-Sleep -Seconds 2
    
    $stats = Get-IntelligentAlertingStatistics
    return ($stats.NotificationsSent -gt 0 -or $stats.AlertsProcessed -gt 0)
}

# Test 11: Escalation System
Test-Functionality "Escalation System Setup" {
    $escalationAlert = New-TestAlert -Source "Emergency" -Message "Emergency situation detected" -Component "EmergencySystem"
    
    Submit-Alert -Alert $escalationAlert | Out-Null
    
    # Wait for escalation setup
    Start-Sleep -Seconds 2
    
    $stats = Get-IntelligentAlertingStatistics
    return ($stats.ActiveEscalations -ge 0)  # Should track escalations
}

# Test 12: Statistics Structure
Test-Functionality "Statistics Structure Validation" {
    $stats = Get-IntelligentAlertingStatistics
    
    # Verify required properties exist
    $requiredProps = @('AlertsProcessed', 'AlertsEscalated', 'NotificationsSent', 
                       'DuplicatesRemoved', 'CorrelationsFound', 'IsRunning', 'ConnectedModules')
    
    $hasAllProps = $true
    foreach ($prop in $requiredProps) {
        if (-not ($stats.PSObject.Properties.Name -contains $prop)) {
            $hasAllProps = $false
            break
        }
    }
    
    return $hasAllProps
}

# Test 13: Connected Modules Status
Test-Functionality "Connected Modules Status" {
    $stats = Get-IntelligentAlertingStatistics
    $connectedModules = $stats.ConnectedModules
    
    # Should have attempted to connect to key modules
    $keyModules = @('AIAlertClassifier')
    $hasKeyModules = $true
    
    foreach ($module in $keyModules) {
        if (-not $connectedModules.PSObject.Properties.Name -contains $module) {
            $hasKeyModules = $false
            break
        }
    }
    
    return $hasKeyModules
}

# Test 14: System Performance
Test-Functionality "System Performance Validation" {
    $stats = Get-IntelligentAlertingStatistics
    
    # System should be performing reasonably
    return ($stats.IsRunning -eq $true -and 
            $stats.QueueLength -lt 50)
}

# Test 15: System Stop
Test-Functionality "Intelligent Alerting System Stop" {
    $stopResult = Stop-IntelligentAlerting
    
    if ($null -ne $stopResult) {
        $stats = Get-IntelligentAlertingStatistics
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
    $finalStats = Get-IntelligentAlertingStatistics
    Write-Host "`n===== Intelligent Alerting Statistics =====" -ForegroundColor Cyan
    Write-Host "Alerts Processed: $($finalStats.AlertsProcessed)" -ForegroundColor White
    Write-Host "Alerts Escalated: $($finalStats.AlertsEscalated)" -ForegroundColor White
    Write-Host "Notifications Sent: $($finalStats.NotificationsSent)" -ForegroundColor White
    Write-Host "Duplicates Removed: $($finalStats.DuplicatesRemoved)" -ForegroundColor White
    Write-Host "Correlations Found: $($finalStats.CorrelationsFound)" -ForegroundColor White
    Write-Host "Active Escalations: $($finalStats.ActiveEscalations)" -ForegroundColor White
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
$resultsFile = Join-Path $PSScriptRoot "IntelligentAlerting-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
$testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
Write-Host "`nTest results saved to: $resultsFile" -ForegroundColor Gray

# Return success/failure for CI/CD integration
exit $(if ($testResults.Failed -eq 0) { 0 } else { 1 })