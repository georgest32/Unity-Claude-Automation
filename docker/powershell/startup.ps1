# PowerShell Module Service Startup Script
# Unity-Claude-Automation Container

Write-Host "Unity-Claude-Automation PowerShell Module Service Starting..." -ForegroundColor Green
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Cyan
Write-Host ""

# Import all Unity-Claude modules
Write-Host "Importing Unity-Claude modules..." -ForegroundColor Yellow
$modules = Get-Module -ListAvailable -Name Unity-Claude-* | Select-Object Name, Version

foreach ($module in $modules) {
    try {
        Import-Module $module.Name -Force
        Write-Host "  [OK] Imported $($module.Name) v$($module.Version)" -ForegroundColor Green
    }
    catch {
        Write-Host "  [ERROR] Failed to import $($module.Name): $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Module import complete. Available commands:" -ForegroundColor Cyan
Get-Command -Module Unity-Claude-* | Select-Object Name, Module | Format-Table

Write-Host ""
Write-Host "Service ready. Listening for requests..." -ForegroundColor Green

# Keep the container running
while ($true) {
    Start-Sleep -Seconds 60
    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Health check: Service is running" -ForegroundColor Gray
}