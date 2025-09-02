# Auto-Approve-Claude-Window.ps1
# Targets the Claude window specifically for auto-approval

Write-Host @"
================================================================================
TARGETED CLAUDE AUTO-APPROVAL
================================================================================
This finds your Claude CLI window and sends approvals to it.
================================================================================
"@ -ForegroundColor Cyan

Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    
    public class Win32 {
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
"@ -ErrorAction SilentlyContinue

Write-Host "Looking for PowerShell windows..." -ForegroundColor Yellow

# Find all PowerShell windows
$pwshWindows = Get-Process | Where-Object { 
    $_.ProcessName -eq "pwsh" -and 
    $_.MainWindowTitle -ne ""
} | Select-Object Id, ProcessName, MainWindowTitle

if ($pwshWindows.Count -eq 0) {
    Write-Host "No PowerShell windows found!" -ForegroundColor Red
    exit
}

Write-Host "`nFound PowerShell windows:" -ForegroundColor Green
$i = 0
$pwshWindows | ForEach-Object {
    Write-Host "  [$i] $($_.MainWindowTitle) (PID: $($_.Id))" -ForegroundColor White
    $i++
}

Write-Host ""
$selection = Read-Host "Which window is running Claude? (enter number)"
$targetWindow = $pwshWindows[$selection]

if (-not $targetWindow) {
    Write-Host "Invalid selection!" -ForegroundColor Red
    exit
}

Write-Host "`nTargeting: $($targetWindow.MainWindowTitle)" -ForegroundColor Green
Write-Host "Starting auto-approval (press Ctrl+C to stop)..." -ForegroundColor Yellow

$process = Get-Process -Id $targetWindow.Id
$count = 0

while ($true) {
    # Activate the target window
    [Win32]::SetForegroundWindow($process.MainWindowHandle)
    Start-Sleep -Milliseconds 200
    
    # Send approval
    [System.Windows.Forms.SendKeys]::SendWait("y")
    Start-Sleep -Milliseconds 50
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    
    $count++
    Write-Host "[$((Get-Date -Format 'HH:mm:ss'))] Sent approval #$count" -ForegroundColor Green
    
    Start-Sleep -Seconds 2
}