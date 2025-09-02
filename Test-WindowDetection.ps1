# Test-WindowDetection.ps1
# Test the corrected window detection

# Import the CLIOrchestrator module
Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force

# Get the current PowerShell process info
Write-Host ""
Write-Host "Current PowerShell Process:" -ForegroundColor Cyan
Write-Host "  PID: $PID"
$currentProc = Get-Process -Id $PID
Write-Host "  Process Name: $($currentProc.ProcessName)"
Write-Host "  Window Title: $($Host.UI.RawUI.WindowTitle)"

# Test window detection
Write-Host ""
Write-Host "Testing window detection..." -ForegroundColor Yellow
$windowHandle = Get-CLIWindowHandle
if ($windowHandle) {
    Write-Host "  SUCCESS: Found window handle: $windowHandle" -ForegroundColor Green
    
    # Get process info for the found window
    $proc = Get-Process | Where-Object { $_.MainWindowHandle -eq $windowHandle } | Select-Object -First 1
    if ($proc) {
        Write-Host "  Process Name: $($proc.ProcessName)" -ForegroundColor Green
        Write-Host "  Process ID: $($proc.Id)" -ForegroundColor Green
        Write-Host "  Window Title: $($proc.MainWindowTitle)" -ForegroundColor Green
    }
} else {
    Write-Host "  ERROR: No window found!" -ForegroundColor Red
}

# Check system status
Write-Host ""
Write-Host "Checking system_status.json..." -ForegroundColor Yellow
$statusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
if (Test-Path $statusFile) {
    $status = Get-Content $statusFile | ConvertFrom-Json
    if ($status.WindowTitle -and $status.ProcessId) {
        Write-Host "  System status shows:" -ForegroundColor Gray
        Write-Host "    Window Title: $($status.WindowTitle)" -ForegroundColor Gray
        Write-Host "    Process ID: $($status.ProcessId)" -ForegroundColor Gray
        Write-Host "    Process Name: $($status.ProcessName)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "Test complete." -ForegroundColor Cyan