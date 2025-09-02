# Test Migration Status Script
cd 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation'
Import-Module '.\Migration\Legacy-Compatibility.psm1' -Force

$status = Test-MigrationStatus
Write-Host ""
Write-Host "==============================" -ForegroundColor Cyan
Write-Host "MIGRATION STATUS CHECK" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Status: $($status.Status)" -ForegroundColor Yellow
Write-Host "Ready: $($status.Ready)" -ForegroundColor Yellow
Write-Host ""

if ($status.MissingManifests) {
    Write-Host "Missing Manifests:" -ForegroundColor Red
    $status.MissingManifests | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
}

if ($status.LegacyFiles) {
    Write-Host ""
    Write-Host "Legacy Files Still Present:" -ForegroundColor Yellow
    $status.LegacyFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
}

Write-Host ""
Write-Host "Full Status Details:" -ForegroundColor Cyan
$status | ConvertTo-Json -Depth 3