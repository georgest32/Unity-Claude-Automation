# Quick test of AIAlertClassifier module
Import-Module ".\Modules\Unity-Claude-AIAlertClassifier\Unity-Claude-AIAlertClassifier.psm1" -Force
Initialize-AIAlertClassifier

$alert = [PSCustomObject]@{
    Id = [Guid]::NewGuid().ToString()
    Source = "SecurityMonitor"
    Message = "Failed login attempt from IP 192.168.1.100"
    Component = "TestComponent"
    Timestamp = Get-Date
}

Write-Host "Testing Alert Classification..." -ForegroundColor Cyan
$classification = Invoke-AIAlertClassification -Alert $alert

Write-Host "`nClassification Result:" -ForegroundColor Yellow
$classification | Format-List

Write-Host "`nClassification Type:" -ForegroundColor Yellow
$classification.GetType().Name

Write-Host "`nProperties:" -ForegroundColor Yellow
$classification.Keys | ForEach-Object { Write-Host "  - $_`: $($classification[$_])" }