# Get-TerminalWindowHandle.ps1
# Finds the terminal window handle (HWND) for a given Node.js process
# This solves the core issue: Node.js has no window, the terminal does

param(
    [Parameter(Mandatory=$false)]
    [int]$NodeProcessId = 0,
    
    [Parameter(Mandatory=$false)]
    [string]$WindowTitle = "*Claude Code*"
)

# Define Win32 API functions for window detection
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Collections.Generic;

public class Win32Window {
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);
    
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    
    [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    
    [DllImport("user32.dll", SetLastError = true)]
    public static extern int GetWindowTextLength(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern IntPtr GetWindow(IntPtr hWnd, uint uCmd);
    
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern uint GetCurrentThreadId();
    
    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    
    public const uint GW_OWNER = 4;
    
    public static List<IntPtr> GetWindowsByProcessId(uint processId) {
        List<IntPtr> windows = new List<IntPtr>();
        
        EnumWindows((hWnd, lParam) => {
            uint pid;
            GetWindowThreadProcessId(hWnd, out pid);
            
            if (pid == processId && IsWindowVisible(hWnd)) {
                // Check if it's a main window (no owner)
                if (GetWindow(hWnd, GW_OWNER) == IntPtr.Zero) {
                    windows.Add(hWnd);
                }
            }
            return true; // Continue enumeration
        }, IntPtr.Zero);
        
        return windows;
    }
    
    public static string GetWindowTitle(IntPtr hWnd) {
        int length = GetWindowTextLength(hWnd);
        if (length == 0) return string.Empty;
        
        StringBuilder sb = new StringBuilder(length + 1);
        GetWindowText(hWnd, sb, sb.Capacity);
        return sb.ToString();
    }
    
    public static bool BringWindowToFront(IntPtr hWnd) {
        IntPtr foregroundWindow = GetForegroundWindow();
        uint dummy;
        uint foregroundThreadId = GetWindowThreadProcessId(foregroundWindow, out dummy);
        uint currentThreadId = GetCurrentThreadId();
        
        // Attach to foreground thread to bypass SetForegroundWindow restrictions
        AttachThreadInput(currentThreadId, foregroundThreadId, true);
        bool result = SetForegroundWindow(hWnd);
        AttachThreadInput(currentThreadId, foregroundThreadId, false);
        
        return result;
    }
}
"@

function Get-ParentProcessChain {
    param([int]$ProcessId)
    
    $chain = @()
    $currentId = $ProcessId
    
    while ($currentId -gt 0) {
        try {
            $proc = Get-CimInstance Win32_Process -Filter "ProcessId = $currentId" -ErrorAction Stop
            if ($proc) {
                $chain += [PSCustomObject]@{
                    ProcessId = $proc.ProcessId
                    Name = $proc.Name
                    ParentProcessId = $proc.ParentProcessId
                    CommandLine = $proc.CommandLine
                }
                $currentId = $proc.ParentProcessId
            } else {
                break
            }
        } catch {
            break
        }
    }
    
    return $chain
}

function Find-TerminalWindow {
    param([int]$NodeProcessId)
    
    Write-Host "Finding terminal window for Node.js process: $NodeProcessId" -ForegroundColor Cyan
    
    # Get the parent process chain
    $chain = Get-ParentProcessChain -ProcessId $NodeProcessId
    
    Write-Host "`nProcess Chain:" -ForegroundColor Yellow
    foreach ($proc in $chain) {
        Write-Host "  $($proc.ProcessId) - $($proc.Name)" -ForegroundColor Gray
    }
    
    # Look for terminal processes in the chain
    $terminalProcesses = @('WindowsTerminal.exe', 'mintty.exe', 'conhost.exe', 'cmd.exe', 'powershell.exe', 'pwsh.exe')
    $terminalPid = 0
    $terminalName = ""
    
    foreach ($proc in $chain) {
        if ($proc.Name -in $terminalProcesses) {
            $terminalPid = $proc.ProcessId
            $terminalName = $proc.Name
            Write-Host "`nFound terminal process: $terminalName (PID: $terminalPid)" -ForegroundColor Green
            break
        }
    }
    
    if ($terminalPid -eq 0) {
        Write-Host "No terminal process found in parent chain" -ForegroundColor Red
        return $null
    }
    
    # Get windows for the terminal process
    $windows = [Win32Window]::GetWindowsByProcessId($terminalPid)
    
    if ($windows.Count -eq 0) {
        Write-Host "No visible windows found for process $terminalPid" -ForegroundColor Red
        return $null
    }
    
    Write-Host "`nFound $($windows.Count) window(s) for $terminalName" -ForegroundColor Green
    
    # Return information about the windows
    $result = @()
    foreach ($hwnd in $windows) {
        $title = [Win32Window]::GetWindowTitle($hwnd)
        $info = [PSCustomObject]@{
            WindowHandle = $hwnd
            ProcessId = $terminalPid
            ProcessName = $terminalName
            WindowTitle = $title
        }
        $result += $info
        Write-Host "  Window: $title (Handle: $hwnd)" -ForegroundColor Gray
    }
    
    return $result
}

# Main execution
if ($NodeProcessId -eq 0) {
    # Try to detect Claude Code process automatically
    Write-Host "Detecting Claude Code process..." -ForegroundColor Cyan
    $nodeProcesses = Get-Process node -ErrorAction SilentlyContinue
    
    if ($nodeProcesses) {
        Write-Host "Found $($nodeProcesses.Count) Node.js process(es)" -ForegroundColor Yellow
        foreach ($proc in $nodeProcesses) {
            Write-Host "  PID: $($proc.Id)" -ForegroundColor Gray
        }
        
        # Use the first one or prompt user to specify
        if ($nodeProcesses.Count -eq 1) {
            $NodeProcessId = $nodeProcesses[0].Id
        } else {
            $NodeProcessId = $nodeProcesses[0].Id
            Write-Host "Using first Node.js process: $NodeProcessId" -ForegroundColor Yellow
        }
    } else {
        Write-Host "No Node.js processes found" -ForegroundColor Red
        return
    }
}

# Find the terminal window
$terminalInfo = Find-TerminalWindow -NodeProcessId $NodeProcessId

if ($terminalInfo) {
    Write-Host "`n=== Terminal Window Found ===" -ForegroundColor Green
    $terminalInfo | Format-Table -AutoSize
    
    # Save to system_status.json
    $statusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
    if (Test-Path $statusFile) {
        try {
            $status = Get-Content $statusFile -Raw | ConvertFrom-Json
            
            # Update with terminal window information
            if (-not $status.SystemInfo.ClaudeCodeCLI) {
                $status.SystemInfo | Add-Member -MemberType NoteProperty -Name "ClaudeCodeCLI" -Value @{} -Force
            }
            
            $status.SystemInfo.ClaudeCodeCLI.ProcessId = $NodeProcessId
            $status.SystemInfo.ClaudeCodeCLI.TerminalWindowHandle = $terminalInfo[0].WindowHandle.ToString()
            $status.SystemInfo.ClaudeCodeCLI.TerminalProcessId = $terminalInfo[0].ProcessId
            $status.SystemInfo.ClaudeCodeCLI.TerminalProcessName = $terminalInfo[0].ProcessName
            $status.SystemInfo.ClaudeCodeCLI.WindowTitle = $terminalInfo[0].WindowTitle
            $status.SystemInfo.ClaudeCodeCLI.LastDetected = (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff")
            
            $status | ConvertTo-Json -Depth 10 | Set-Content $statusFile -Encoding UTF8
            Write-Host "Updated system_status.json with terminal window handle" -ForegroundColor Green
        } catch {
            Write-Host "Error updating system_status.json: $_" -ForegroundColor Red
        }
    }
    
    # Test bringing window to front
    Write-Host "`nTesting window activation..." -ForegroundColor Cyan
    if ([Win32Window]::BringWindowToFront($terminalInfo[0].WindowHandle)) {
        Write-Host "Successfully brought terminal window to front!" -ForegroundColor Green
    } else {
        Write-Host "Failed to bring window to front" -ForegroundColor Red
    }
    
    return $terminalInfo
} else {
    Write-Host "Failed to find terminal window" -ForegroundColor Red
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU3hIP6YjWPYj+7MaxC7mPeJGd
# zOKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUg7CQ5WD+HPOsOtT0Rhi1F1WTuQkwDQYJKoZIhvcNAQEBBQAEggEAatIn
# AoQesxDr8dkeFCFLVslR1Wr/XWWjrJrpA+pqzRGvk3zGsF408Hwq03eQFo/XEKPF
# V0uFFKbSLLThSsn5JzMktr+kwgx0kuY0m9ye1t9R2/7eaDAG8xV7qKbDfFKZczTb
# i01HNz9F4wiWrnG+7fysRJ2JYX1VtMPi0FqUCh+QaeS83JzX4LlumEiTP0LXEshh
# mV868cU9b4ApD1uiiBYoqEQqRzzM1ZsW1pbAg5qwet6cDuS1DvzAbpY+8JnvYOrM
# fX/cmhM20zsd1hhBHaaDIstlZiC8lMSrfM9T9OiBpKMwUxiIsMnaPzvlclv4WVN2
# IzZucJQXKCkgftVsPA==
# SIG # End signature block
