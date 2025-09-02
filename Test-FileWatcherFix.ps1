# Test FileWatcher property fix in SystemStatus module

Write-Host "Testing SystemStatus FileWatcher fix..." -ForegroundColor Cyan

# Clean slate test
Get-Module Unity-Claude-SystemStatus -All | Remove-Module -Force -ErrorAction SilentlyContinue

try {
    # Import module
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force
    Write-Host "SystemStatus module imported successfully" -ForegroundColor Green
    
    # Test initialization function availability
    if (Get-Command Initialize-CommunicationState -ErrorAction SilentlyContinue) {
        Write-Host "Initialize-CommunicationState function available" -ForegroundColor Green
        
        # Initialize CommunicationState
        $result = Initialize-CommunicationState
        if ($result) {
            Write-Host "CommunicationState initialized successfully" -ForegroundColor Green
            
            # Test FileWatcher property assignment (the original failing operation)
            try {
                $script:CommunicationState.FileWatcher = "TEST_VALUE"
                Write-Host "SUCCESS: FileWatcher property assignment works!" -ForegroundColor Green
                Write-Host "Fix verified: SystemStatus FileWatcher error resolved" -ForegroundColor Cyan
                return $true
            } catch {
                Write-Host "FAILED: FileWatcher property assignment failed: $($_.Exception.Message)" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "FAILED: CommunicationState initialization returned false" -ForegroundColor Red
            return $false
        }
    } else {
        Write-Host "FAILED: Initialize-CommunicationState function not found" -ForegroundColor Red
        return $false
    }
} catch {
    Write-Host "FAILED: Module import or test error: $($_.Exception.Message)" -ForegroundColor Red
    return $false
}