<#
.SYNOPSIS
    Robust NUGGETRON window detection using Windows API
.DESCRIPTION
    Uses P/Invoke to call Windows API directly for reliable window detection
#>

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

function Get-NuggetronWindowWinAPI {
    param(
        [switch]$ShowAll
    )
    
    Write-Host "`n[INFO] Using Windows API to find NUGGETRON window..." -ForegroundColor Cyan
    
    # Get all windows
    $allWindows = [WindowHelper]::GetAllWindows()
    
    # Find NUGGETRON
    $nuggetronWindow = $allWindows | Where-Object { $_.Title -like "*NUGGETRON*" } | Select-Object -First 1
    
    if ($nuggetronWindow) {
        Write-Host "[OK] Found NUGGETRON window!" -ForegroundColor Green
        Write-Host "  Title: $($nuggetronWindow.Title)" -ForegroundColor Gray
        Write-Host "  ProcessId: $($nuggetronWindow.ProcessId)" -ForegroundColor Gray
        Write-Host "  Handle: $($nuggetronWindow.Handle)" -ForegroundColor Gray
        
        # Verify process exists
        try {
            $process = Get-Process -Id $nuggetronWindow.ProcessId -ErrorAction Stop
            Write-Host "  Process: $($process.ProcessName)" -ForegroundColor Gray
            Write-Host "  Process Status: Running" -ForegroundColor Green
        } catch {
            Write-Host "  Process Status: Not Found" -ForegroundColor Red
        }
        
        return $nuggetronWindow
    } else {
        Write-Host "[WARNING] NUGGETRON window not found via Windows API" -ForegroundColor Yellow
        
        if ($ShowAll) {
            Write-Host "`nAll visible windows:" -ForegroundColor Cyan
            foreach ($window in $allWindows) {
                if ($window.Title) {
                    Write-Host "  - [$($window.ProcessId)] $($window.Title)" -ForegroundColor Gray
                }
            }
        }
        
        return $null
    }
}

# Run the detection
$nuggetron = Get-NuggetronWindowWinAPI -ShowAll

if ($nuggetron) {
    Write-Host "`n[SUCCESS] NUGGETRON detection successful via Windows API!" -ForegroundColor Green
    
    # Update registration file with WinAPI results
    $protectedRegPath = ".\.nuggetron_registration.json"
    if (Test-Path $protectedRegPath) {
        $regData = Get-Content $protectedRegPath -Raw | ConvertFrom-Json
        $regData.WindowHandle = [int64]$nuggetron.Handle
        $regData.LastVerifiedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $regData.VerificationMethod = "Windows API"
        $regData | ConvertTo-Json -Depth 10 | Set-Content $protectedRegPath -Encoding UTF8
        Write-Host "[OK] Updated registration with Windows API data" -ForegroundColor Green
    }
} else {
    Write-Host "`n[ERROR] Could not find NUGGETRON window" -ForegroundColor Red
    Write-Host "Please ensure:" -ForegroundColor Yellow
    Write-Host "  1. You have run Register-NUGGETRON-Protected.ps1 in THIS terminal" -ForegroundColor Gray
    Write-Host "  2. The window title shows **NUGGETRON**" -ForegroundColor Gray
    Write-Host "  3. The terminal window is visible (not minimized)" -ForegroundColor Gray
}