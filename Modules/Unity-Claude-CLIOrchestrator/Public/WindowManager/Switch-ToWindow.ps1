# Add Windows API functions for reliable window switching
if (-not ([System.Management.Automation.PSTypeName]'WindowAPI').Type) {
    Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class WindowAPI {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    
    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
    
    [DllImport("user32.dll")]
    public static extern bool BringWindowToTop(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    
    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
    
    // Mouse and keyboard blocking functions
    [DllImport("user32.dll")]
    public static extern bool BlockInput(bool fBlockIt);
    
    [DllImport("user32.dll")]
    public static extern IntPtr SetCapture(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool ReleaseCapture();
    
    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);
    
    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);
    
    public struct POINT {
        public int X;
        public int Y;
    }
}
"@ -ErrorAction SilentlyContinue
}

function Switch-ToWindow {
    <#
    .SYNOPSIS
        Reliably switches to the specified window using Windows APIs
        
    .DESCRIPTION
        Uses multiple Windows API techniques to ensure reliable window switching,
        including AttachThreadInput for stubborn windows
        
    .PARAMETER WindowHandle
        The handle of the window to switch to
        
    .OUTPUTS
        Boolean - True if window switch was successful, False otherwise
        
    .EXAMPLE
        $success = Switch-ToWindow -WindowHandle $windowHandle
    #>
    [CmdletBinding()]
    param([IntPtr]$WindowHandle)
    
    if ($WindowHandle -eq 0 -or $WindowHandle -eq $null) {
        return $false
    }
    
    try {
        # Get current foreground window
        $currentWindow = [WindowAPI]::GetForegroundWindow()
        
        # Show the window if minimized (4 = SW_RESTORE)
        [WindowAPI]::ShowWindowAsync($WindowHandle, 4) | Out-Null
        Start-Sleep -Milliseconds 100
        
        # Bring to top
        [WindowAPI]::BringWindowToTop($WindowHandle) | Out-Null
        Start-Sleep -Milliseconds 100
        
        # Set as foreground window
        $result = [WindowAPI]::SetForegroundWindow($WindowHandle)
        
        if (-not $result) {
            # If SetForegroundWindow fails, try AttachThreadInput trick
            Write-Host "    Using AttachThreadInput for window switching..." -ForegroundColor Gray
            
            $currentThreadId = [WindowAPI]::GetCurrentThreadId()
            $targetProcessId = 0
            $targetThreadId = [WindowAPI]::GetWindowThreadProcessId($WindowHandle, [ref]$targetProcessId)
            
            if ($targetThreadId -ne 0 -and $currentThreadId -ne $targetThreadId) {
                [WindowAPI]::AttachThreadInput($currentThreadId, $targetThreadId, $true) | Out-Null
                [WindowAPI]::BringWindowToTop($WindowHandle) | Out-Null
                [WindowAPI]::SetForegroundWindow($WindowHandle) | Out-Null
                [WindowAPI]::AttachThreadInput($currentThreadId, $targetThreadId, $false) | Out-Null
            }
        }
        
        Start-Sleep -Milliseconds 500
        return $true
    } catch {
        Write-Host "    Error switching window: $_" -ForegroundColor Red
        return $false
    }
}