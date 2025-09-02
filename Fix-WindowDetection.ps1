# Fix Window Detection for Claude Code CLI
# Date: 2025-08-27
# Purpose: Ensure proper window detection using multiple methods

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "     Window Detection Fix for Claude Code CLI" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Method 1: Update current PowerShell window title directly
Write-Host "Method 1: Setting current PowerShell window title..." -ForegroundColor Yellow
$Host.UI.RawUI.WindowTitle = "Claude Code CLI environment"
Write-Host "  Current window title set to: $($Host.UI.RawUI.WindowTitle)" -ForegroundColor Green

# Method 2: Update system_status.json with correct PID
Write-Host ""
Write-Host "Method 2: Updating system_status.json with current PID..." -ForegroundColor Yellow
$currentPid = $PID
Write-Host "  Current PowerShell PID: $currentPid" -ForegroundColor Gray

$statusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
if (Test-Path $statusFile) {
    $status = Get-Content $statusFile | ConvertFrom-Json
    
    # Update Claude Code CLI section
    if ($status.SystemInfo.ClaudeCodeCLI) {
        $status.SystemInfo.ClaudeCodeCLI.ProcessId = $currentPid
        $status.SystemInfo.ClaudeCodeCLI.WindowTitle = "Claude Code CLI environment"
        $status.SystemInfo.ClaudeCodeCLI.ProcessName = "pwsh"
        $status.SystemInfo.ClaudeCodeCLI.LastDetected = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        # Get actual window handle using Win32 API
        Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Diagnostics;

public class Win32Window {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    
    [DllImport("user32.dll")]
    public static extern int GetWindowThreadProcessId(IntPtr hWnd, out int lpdwProcessId);
    
    public static IntPtr GetCurrentWindowHandle() {
        return GetForegroundWindow();
    }
    
    public static int GetWindowProcessId(IntPtr hWnd) {
        int processId;
        GetWindowThreadProcessId(hWnd, out processId);
        return processId;
    }
}
"@
        
        $currentHandle = [Win32Window]::GetForegroundWindow()
        if ($currentHandle -ne [IntPtr]::Zero) {
            $status.SystemInfo.ClaudeCodeCLI.WindowHandle = $currentHandle.ToInt32()
            Write-Host "  Window handle detected: $($currentHandle.ToInt32())" -ForegroundColor Green
        }
    }
    
    # Save updated status
    $status | ConvertTo-Json -Depth 10 | Out-File $statusFile -Encoding UTF8
    Write-Host "  system_status.json updated successfully" -ForegroundColor Green
} else {
    Write-Host "  Warning: system_status.json not found" -ForegroundColor Yellow
}

# Method 3: Create marker file for window identification
Write-Host ""
Write-Host "Method 3: Creating window marker file..." -ForegroundColor Yellow
$markerFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\.claude_code_cli_window"
@{
    WindowTitle = "Claude Code CLI environment"
    ProcessId = $PID
    ProcessName = (Get-Process -Id $PID).ProcessName
    WindowHandle = if ($currentHandle) { $currentHandle.ToInt32() } else { $null }
    CreatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
} | ConvertTo-Json | Out-File $markerFile -Encoding UTF8
Write-Host "  Marker file created: $markerFile" -ForegroundColor Green

# Method 4: Force Windows Terminal to respect title (if using Windows Terminal)
Write-Host ""
Write-Host "Method 4: Checking Windows Terminal settings..." -ForegroundColor Yellow
$wtSettings = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $wtSettings) {
    Write-Host "  Windows Terminal detected" -ForegroundColor Gray
    Write-Host "  Note: If title still doesn't change, add to your Windows Terminal profile:" -ForegroundColor Yellow
    Write-Host '    "suppressApplicationTitle": false' -ForegroundColor Cyan
} else {
    Write-Host "  Windows Terminal not detected (or using different terminal)" -ForegroundColor Gray
}

# Method 5: Test window detection
Write-Host ""
Write-Host "Method 5: Testing window detection..." -ForegroundColor Yellow
Write-Host "  Current process info:" -ForegroundColor Gray
$currentProcess = Get-Process -Id $PID
Write-Host "    Process Name: $($currentProcess.ProcessName)" -ForegroundColor Gray
Write-Host "    Process ID: $($currentProcess.Id)" -ForegroundColor Gray
Write-Host "    Main Window Title: $($currentProcess.MainWindowTitle)" -ForegroundColor Gray
Write-Host "    Host Window Title: $($Host.UI.RawUI.WindowTitle)" -ForegroundColor Gray

# Method 6: Alternative window search
Write-Host ""
Write-Host "Method 6: Searching for all PowerShell windows..." -ForegroundColor Yellow
$psWindows = Get-Process pwsh,powershell -ErrorAction SilentlyContinue | 
    Where-Object { $_.MainWindowHandle -ne 0 } |
    Select-Object Id, ProcessName, MainWindowTitle
    
if ($psWindows) {
    Write-Host "  Found PowerShell windows:" -ForegroundColor Gray
    $psWindows | ForEach-Object {
        $marker = if ($_.Id -eq $PID) { " <-- Current" } else { "" }
        Write-Host "    PID: $($_.Id), Name: $($_.ProcessName), Title: '$($_.MainWindowTitle)'$marker" -ForegroundColor Gray
    }
} else {
    Write-Host "  No PowerShell windows found with MainWindowHandle" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Window detection fix completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. If using Windows Terminal, ensure 'suppressApplicationTitle' is false in settings" -ForegroundColor White
Write-Host "2. Try running Execute-TestInWindow.ps1 again" -ForegroundColor White
Write-Host "3. If still not working, the window may need to be focused when setting title" -ForegroundColor White
Write-Host ""