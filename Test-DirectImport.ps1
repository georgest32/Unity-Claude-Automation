# Direct test without parsing
try {
    Write-Host "Testing direct import..." -ForegroundColor Cyan
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\PermissionHandler.psm1" -Force -Verbose
    Write-Host "✅ Import successful!" -ForegroundColor Green
    
    # Test functions
    if (Get-Command Initialize-PermissionHandler -ErrorAction SilentlyContinue) {
        Write-Host "✅ Initialize-PermissionHandler available" -ForegroundColor Green
    } else {
        Write-Host "❌ Initialize-PermissionHandler not found" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Import failed: $_" -ForegroundColor Red
    Write-Host "Error details:" -ForegroundColor Yellow
    $_.Exception | Format-List -Force
}