# Debug script to understand the data structure
Import-Module ".\Modules\Unity-Claude-AIAlertClassifier\Unity-Claude-AIAlertClassifier.psm1" -Force
Initialize-AIAlertClassifier

$alert = [PSCustomObject]@{
    Id = [Guid]::NewGuid().ToString()
    Source = "SecurityMonitor"
    Message = "Failed login attempt from IP 192.168.1.100"
    Component = "TestComponent"
    Timestamp = Get-Date
}

$classification = Invoke-AIAlertClassification -Alert $alert

Write-Host "Classification type: $($classification.GetType().Name)" -ForegroundColor Yellow
Write-Host "Has Confidence: $($classification.ContainsKey('Confidence'))" -ForegroundColor Yellow
Write-Host "Confidence value: $($classification.Confidence)" -ForegroundColor Yellow

# Create test structure like in the main test
$alertTests = @()
$alertTests += @{
    Alert = $alert
    Classification = $classification
    Confidence = $classification.Confidence
    Severity = $classification.Severity
    AlertRaised = $classification.Confidence -gt 0.7
}

Write-Host "`nTest array element type: $($alertTests[0].GetType().Name)" -ForegroundColor Cyan
Write-Host "Has Confidence in test: $($alertTests[0].ContainsKey('Confidence'))" -ForegroundColor Cyan
Write-Host "Confidence in test: $($alertTests[0].Confidence)" -ForegroundColor Cyan

# Test filtering
$raisedAlerts = $alertTests | Where-Object { $_.AlertRaised }
Write-Host "`nRaised alerts count: $($raisedAlerts.Count)" -ForegroundColor Green
Write-Host "First raised alert type: $($raisedAlerts[0].GetType().Name)" -ForegroundColor Green
Write-Host "First raised alert Confidence: $($raisedAlerts[0].Confidence)" -ForegroundColor Green

# Test Measure-Object
try {
    $avgConfidence = ($raisedAlerts | ForEach-Object { $_.Confidence } | Measure-Object -Average).Average
    Write-Host "`nAverage confidence (ForEach method): $avgConfidence" -ForegroundColor Green
} catch {
    Write-Host "ForEach method failed: $_" -ForegroundColor Red
}

try {
    $avgConfidence = ($raisedAlerts.Confidence | Measure-Object -Average).Average
    Write-Host "Average confidence (direct property): $avgConfidence" -ForegroundColor Green
} catch {
    Write-Host "Direct property method failed: $_" -ForegroundColor Red
}