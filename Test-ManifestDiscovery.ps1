# Test-ManifestDiscovery.ps1
# Test that manifest discovery properly excludes backup directories

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST: Manifest Discovery (Exclude Backups)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$projectRoot = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
Set-Location $projectRoot

# Load the SystemStatus module
Write-Host "Loading SystemStatus module..." -ForegroundColor Yellow
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1" -Force
Write-Host "  Module loaded" -ForegroundColor Green

# Test manifest discovery
Write-Host "`nDiscovering manifests..." -ForegroundColor Yellow
$manifests = Get-SubsystemManifests -Path @(".\Manifests", ".")

Write-Host "`nResults:" -ForegroundColor Cyan
Write-Host "  Total manifests found: $($manifests.Count)" -ForegroundColor White

# Check for duplicates
$names = $manifests | ForEach-Object { $_.Name }
$uniqueNames = $names | Select-Object -Unique
if ($names.Count -ne $uniqueNames.Count) {
    Write-Host "  [WARNING] Duplicate subsystem names detected!" -ForegroundColor Yellow
    $duplicates = $names | Group-Object | Where-Object { $_.Count -gt 1 }
    foreach ($dup in $duplicates) {
        Write-Host "    - $($dup.Name): $($dup.Count) instances" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [OK] No duplicate subsystem names" -ForegroundColor Green
}

# List manifests
Write-Host "`nManifests discovered:" -ForegroundColor Cyan
foreach ($manifest in $manifests) {
    $color = if ($manifest.IsValid) { "Green" } else { "Red" }
    $status = if ($manifest.IsValid) { "VALID" } else { "INVALID" }
    Write-Host "  - $($manifest.Name) v$($manifest.Version) [$status]" -ForegroundColor $color
    
    # Check if from backup directory (should not happen with fix)
    if ($manifest.Path -match "\\Backups\\" -or $manifest.Path -match "/Backups/") {
        Write-Host "    [ERROR] This manifest is from a backup directory!" -ForegroundColor Red
        Write-Host "    Path: $($manifest.Path)" -ForegroundColor Red
    }
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "TEST COMPLETE" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($manifests.Count -eq 3) {
    Write-Host "SUCCESS: Expected 3 manifests (no backups included)" -ForegroundColor Green
} else {
    Write-Host "WARNING: Expected 3 manifests but found $($manifests.Count)" -ForegroundColor Yellow
}