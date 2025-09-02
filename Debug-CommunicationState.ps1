# Debug CommunicationState object structure

Write-Host "Debugging CommunicationState object..." -ForegroundColor Cyan

# Clean slate
Get-Module Unity-Claude-SystemStatus -All | Remove-Module -Force -ErrorAction SilentlyContinue

try {
    # Import module
    Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force
    
    # Initialize
    $result = Initialize-CommunicationState
    Write-Host "Initialize result: $result"
    
    # Check if variable exists at script scope
    Write-Host "CommunicationState variable exists in script scope:" -ForegroundColor Yellow
    if (Get-Variable -Name CommunicationState -Scope Script -ErrorAction SilentlyContinue) {
        Write-Host "  EXISTS at script scope" -ForegroundColor Green
        
        # Show object properties
        Write-Host "Object properties:" -ForegroundColor Yellow
        $script:CommunicationState | Get-Member | Where-Object MemberType -eq Property | Select-Object Name, MemberType
        
        # Show object content
        Write-Host "Object content:" -ForegroundColor Yellow
        $script:CommunicationState | Format-List *
        
    } else {
        Write-Host "  DOES NOT EXIST at script scope" -ForegroundColor Red
        
        # Check if it exists in global scope
        if (Get-Variable -Name CommunicationState -Scope Global -ErrorAction SilentlyContinue) {
            Write-Host "  EXISTS at global scope" -ForegroundColor Yellow
        } else {
            Write-Host "  DOES NOT EXIST at global scope either" -ForegroundColor Red
        }
    }
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}