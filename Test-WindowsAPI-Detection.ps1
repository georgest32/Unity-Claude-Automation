<#
.SYNOPSIS
    Tests Windows API detection for NUGGETRON
#>

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  WINDOWS API DETECTION TEST" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Add Windows API definitions
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public class WindowHelper {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    
    [DllImport("user32.dll")]
    public static extern int GetWindowTextLength(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    
    public static List<WindowInfo> GetAllWindows() {
        List<WindowInfo> windows = new List<WindowInfo>();
        
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
            if (IsWindowVisible(hWnd)) {
                int length = GetWindowTextLength(hWnd);
                if (length > 0) {
                    StringBuilder sb = new StringBuilder(length + 1);
                    GetWindowText(hWnd, sb, sb.Capacity);
                    
                    uint processId;
                    GetWindowThreadProcessId(hWnd, out processId);
                    
                    windows.Add(new WindowInfo {
                        Handle = hWnd,
                        Title = sb.ToString(),
                        ProcessId = (int)processId
                    });
                }
            }
            return true;
        }, IntPtr.Zero);
        
        return windows;
    }
}

public class WindowInfo {
    public IntPtr Handle { get; set; }
    public string Title { get; set; }
    public int ProcessId { get; set; }
}
"@

Write-Host "`n1. Getting all visible windows via Windows API..." -ForegroundColor Yellow
$allWindows = [WindowHelper]::GetAllWindows()
Write-Host "   Found $($allWindows.Count) windows" -ForegroundColor Gray

Write-Host "`n2. Searching for NUGGETRON..." -ForegroundColor Yellow
$nuggetronWindows = $allWindows | Where-Object { $_.Title -like "*NUGGETRON*" }

if ($nuggetronWindows) {
    Write-Host "   [SUCCESS] Found NUGGETRON!" -ForegroundColor Green
    foreach ($window in $nuggetronWindows) {
        Write-Host "`n   Window Details:" -ForegroundColor Cyan
        Write-Host "   - Title: '$($window.Title)'" -ForegroundColor Gray
        Write-Host "   - ProcessId: $($window.ProcessId)" -ForegroundColor Gray
        Write-Host "   - Handle: $($window.Handle)" -ForegroundColor Gray
        
        # Check if process exists
        $proc = Get-Process -Id $window.ProcessId -ErrorAction SilentlyContinue
        if ($proc) {
            Write-Host "   - Process: $($proc.ProcessName)" -ForegroundColor Gray
            Write-Host "   - Status: Running" -ForegroundColor Green
        } else {
            Write-Host "   - Status: Process not found" -ForegroundColor Red
        }
    }
} else {
    Write-Host "   [FAILED] NUGGETRON not found via Windows API" -ForegroundColor Red
}

Write-Host "`n3. Windows containing 'PowerShell' or 'Terminal':" -ForegroundColor Yellow
$terminalWindows = $allWindows | Where-Object { 
    $_.Title -match 'PowerShell|Terminal|pwsh|Console'
}
foreach ($window in $terminalWindows | Select-Object -First 10) {
    Write-Host "   - PID $($window.ProcessId): '$($window.Title)'" -ForegroundColor Gray
}

Write-Host "`n4. Current process info:" -ForegroundColor Yellow
Write-Host "   - Current PID: $PID" -ForegroundColor Gray
Write-Host "   - Current Title: '$($host.UI.RawUI.WindowTitle)'" -ForegroundColor Gray
$currentProc = Get-Process -Id $PID
Write-Host "   - Process Name: $($currentProc.ProcessName)" -ForegroundColor Gray
Write-Host "   - Main Window Handle: $($currentProc.MainWindowHandle)" -ForegroundColor Gray
Write-Host "   - Main Window Title: '$($currentProc.MainWindowTitle)'" -ForegroundColor Gray

Write-Host "`n========================================" -ForegroundColor Cyan