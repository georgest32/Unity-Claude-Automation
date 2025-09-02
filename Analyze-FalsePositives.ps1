# Analyze why we have false positives
Import-Module ".\Modules\Unity-Claude-AIAlertClassifier\Unity-Claude-AIAlertClassifier.psm1" -Force
Initialize-AIAlertClassifier | Out-Null

$alertScenarios = @(
    @{Source = "SecurityMonitor"; Message = "Failed login attempt from IP 192.168.1.100"; ExpectedSeverity = "High"; ExpectedCategory = "Security"},
    @{Source = "PerformanceMonitor"; Message = "CPU usage at 95% for 5 minutes"; ExpectedSeverity = "High"; ExpectedCategory = "Performance"},
    @{Source = "ApplicationLog"; Message = "NullReferenceException in module DataProcessor"; ExpectedSeverity = "High"; ExpectedCategory = "Error"},
    @{Source = "DeploymentService"; Message = "Successfully deployed version 2.1.0 to production"; ExpectedSeverity = "Info"; ExpectedCategory = "Change"},
    @{Source = "SecurityAudit"; Message = "Unauthorized access attempt blocked"; ExpectedSeverity = "Critical"; ExpectedCategory = "Security"},
    @{Source = "SystemMonitor"; Message = "System health check completed successfully"; ExpectedSeverity = "Info"; ExpectedCategory = "System"},
    @{Source = "DatabaseMonitor"; Message = "Connection timeout after 30 seconds"; ExpectedSeverity = "High"; ExpectedCategory = "Performance"},
    @{Source = "ApplicationLog"; Message = "Warning: Memory usage approaching limit"; ExpectedSeverity = "High"; ExpectedCategory = "Performance"},
    @{Source = "SecurityScanner"; Message = "Critical: Potential security breach detected"; ExpectedSeverity = "Critical"; ExpectedCategory = "Security"},
    @{Source = "BackupService"; Message = "Backup completed successfully"; ExpectedSeverity = "Info"; ExpectedCategory = "Maintenance"}
)

Write-Host "Analyzing Alert Classifications vs Expectations" -ForegroundColor Cyan
Write-Host ("=" * 80) -ForegroundColor Gray

$falsePositives = 0
$falseNegatives = 0
$truePositives = 0
$trueNegatives = 0

foreach ($scenario in $alertScenarios) {
    $alert = [PSCustomObject]@{
        Id = [Guid]::NewGuid().ToString()
        Source = $scenario.Source
        Message = $scenario.Message
        Timestamp = Get-Date
        Component = "TestComponent"
    }
    
    $classification = Invoke-AIAlertClassification -Alert $alert
    
    $expectedSeverity = $scenario.ExpectedSeverity
    $isExpectedCritical = ($expectedSeverity -in @('Critical', 'High'))
    $isClassifiedCritical = ($classification.Severity -in @('Critical', 'High'))
    $alertRaised = $classification.Confidence -gt 0.7
    
    Write-Host "`nScenario: $($scenario.Message.Substring(0, [Math]::Min(50, $scenario.Message.Length)))" -ForegroundColor Yellow
    Write-Host "  Expected: Severity=$expectedSeverity, Critical=$isExpectedCritical" -ForegroundColor Gray
    Write-Host "  Classified: Severity=$($classification.Severity), Confidence=$($classification.Confidence), Raised=$alertRaised" -ForegroundColor Gray
    
    # Determine classification accuracy
    if ($isExpectedCritical) {
        # This SHOULD raise an alert
        if ($alertRaised) {
            $truePositives++
            Write-Host "  Result: TRUE POSITIVE (Correctly raised alert)" -ForegroundColor Green
        } else {
            $falseNegatives++
            Write-Host "  Result: FALSE NEGATIVE (Missed real issue)" -ForegroundColor Red
        }
    } else {
        # This should NOT raise an alert
        if ($alertRaised) {
            $falsePositives++
            Write-Host "  Result: FALSE POSITIVE (Incorrectly raised alert)" -ForegroundColor Red
            Write-Host "    Why: Non-critical '$expectedSeverity' but confidence $($classification.Confidence) > 0.7" -ForegroundColor Magenta
        } else {
            $trueNegatives++
            Write-Host "  Result: TRUE NEGATIVE (Correctly didn't raise)" -ForegroundColor Green
        }
    }
}

Write-Host "`n" ("=" * 80) -ForegroundColor Gray
Write-Host "ANALYSIS SUMMARY" -ForegroundColor Cyan
Write-Host "True Positives:  $truePositives (Correctly raised alerts)" -ForegroundColor Green
Write-Host "True Negatives:  $trueNegatives (Correctly didn't raise)" -ForegroundColor Green
Write-Host "False Positives: $falsePositives (Incorrectly raised - THE PROBLEM)" -ForegroundColor Red
Write-Host "False Negatives: $falseNegatives (Missed real issues)" -ForegroundColor Yellow

$totalAlerts = $truePositives + $falsePositives
$falsePositiveRate = if ($totalAlerts -gt 0) { 
    [Math]::Round(($falsePositives / $totalAlerts) * 100, 1) 
} else { 0 }

Write-Host "`nFalse Positive Rate: $falsePositiveRate% (Target: < 5%)" -ForegroundColor $(if ($falsePositiveRate -lt 5) { "Green" } else { "Red" })

Write-Host "`nROOT CAUSE:" -ForegroundColor Cyan
Write-Host "The classifier is giving high confidence to Info/Low severity messages" -ForegroundColor Yellow
Write-Host "This happens because the pattern matching doesn't properly distinguish" -ForegroundColor Yellow
Write-Host "between informational success messages and actual problems." -ForegroundColor Yellow