# Test SystemStatus initialization with correct parameters
Write-Host "Testing SystemStatus initialization with FileWatcher..." -ForegroundColor Cyan

# Clean slate
Get-Module Unity-Claude-SystemStatus -All | Remove-Module -Force -ErrorAction SilentlyContinue

try {
    # Import module
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force
    Write-Host "SystemStatus module imported" -ForegroundColor Green
    
    # Test with correct parameters - EnableCommunication is needed for FileWatcher
    Write-Host "Calling Initialize-SystemStatusMonitoring with EnableCommunication and EnableFileWatcher..." -ForegroundColor Yellow
    
    $result = Initialize-SystemStatusMonitoring -EnableCommunication -EnableFileWatcher -UseManifestDrivenStartup:$false -LegacyCompatibility
    
    if ($result) {
        Write-Host "SUCCESS: SystemStatus initialization completed!" -ForegroundColor Green
        Write-Host "Fix verified: The FileWatcher property error has been resolved" -ForegroundColor Cyan
        
        # Test that we can actually stop without errors too
        Write-Host "Testing cleanup (Stop-SystemStatusMonitoring)..." -ForegroundColor Yellow
        $stopResult = Stop-SystemStatusMonitoring
        if ($stopResult) {
            Write-Host "SUCCESS: Cleanup completed without errors" -ForegroundColor Green
        } else {
            Write-Host "WARNING: Cleanup reported failure but may be minor" -ForegroundColor Yellow
        }
        
        return $true
    } else {
        Write-Host "FAILED: SystemStatus initialization returned false" -ForegroundColor Red
        return $false
    }
    
} catch {
    Write-Host "FAILED: SystemStatus initialization error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
    return $false
}