# Standalone NUGGETRON window switcher
# This script can be called independently to switch to NUGGETRON window

Add-Type @"
using System;
using System.Runtime.InteropServices;
public class NuggetronSwitcher {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern bool BringWindowToTop(IntPtr hWnd);
}
"@

Write-Host "[INFO] Standalone NUGGETRON switcher loaded" -ForegroundColor Cyan

# Check protected registration
$protectedRegPath = ".\.nuggetron_registration.json"
if (Test-Path $protectedRegPath) {
    $reg = Get-Content $protectedRegPath -Raw | ConvertFrom-Json
    Write-Host "[INFO] Found registration for PID: $($reg.ProcessId)" -ForegroundColor Green
    Write-Host "[INFO] Window Handle: $($reg.WindowHandle)" -ForegroundColor Green
    
    try {
        $handle = [IntPtr]$reg.WindowHandle
        Write-Host "[INFO] Attempting to switch to handle: $handle" -ForegroundColor Yellow
        
        [NuggetronSwitcher]::ShowWindow($handle, 9) | Out-Null     # SW_RESTORE
        [NuggetronSwitcher]::BringWindowToTop($handle) | Out-Null
        [NuggetronSwitcher]::SetForegroundWindow($handle) | Out-Null
        
        Write-Host "[SUCCESS] Switched to NUGGETRON window!" -ForegroundColor Green
        
        # Test typing
        Add-Type -AssemblyName System.Windows.Forms
        Start-Sleep -Milliseconds 1000
        
        Write-Host "[INFO] Testing text input..." -ForegroundColor Yellow
        [System.Windows.Forms.SendKeys]::SendWait("Test message from standalone switcher")
        Start-Sleep -Milliseconds 500
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        
        Write-Host "[SUCCESS] Test message sent with ENTER!" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to switch: $_" -ForegroundColor Red
    }
} else {
    Write-Host "[ERROR] No NUGGETRON registration found" -ForegroundColor Red
}

Read-Host "Press Enter to continue"