# Test SystemStatus initialization including FileWatcher
Write-Host "Testing complete SystemStatus initialization with FileWatcher..." -ForegroundColor Cyan

# Clean slate
Get-Module Unity-Claude-SystemStatus -All | Remove-Module -Force -ErrorAction SilentlyContinue

try {
    # Import module
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force
    Write-Host "SystemStatus module imported" -ForegroundColor Green
    
    # Test the actual initialization that should call our fix
    Write-Host "Testing Initialize-SystemStatusMonitoring with EnableFileWatcher..." -ForegroundColor Yellow
    
    # This should trigger the Initialize-CommunicationState call and then try to use FileWatcher
    $result = Initialize-SystemStatusMonitoring -EnableFileWatcher $true -EnableNamedPipe $false
    
    if ($result) {
        Write-Host "SUCCESS: SystemStatus initialization with FileWatcher completed!" -ForegroundColor Green
        Write-Host "Fix verified: The FileWatcher property error has been resolved" -ForegroundColor Cyan
        return $true
    } else {
        Write-Host "FAILED: SystemStatus initialization returned false" -ForegroundColor Red
        return $false
    }
    
} catch {
    Write-Host "FAILED: SystemStatus initialization error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Yellow
    return $false
} finally {
    # Clean up any watchers that might have been started
    try {
        Stop-SystemStatusMonitoring | Out-Null
    } catch {
        # Ignore cleanup errors
    }
}