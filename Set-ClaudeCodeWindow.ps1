# Set-ClaudeCodeWindow.ps1
# Detects and saves the Claude Code CLI terminal window for automation

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class ClaudeWindow {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc enumProc, IntPtr lParam);
    
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    
    [DllImport("user32.dll")]
    public static extern int GetWindowTextLength(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    
    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
    
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, string lParam);
    
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    
    public const uint WM_SETTEXT = 0x000C;
    
    public static IntPtr FindClaudeWindow() {
        IntPtr claudeWindow = IntPtr.Zero;
        
        EnumWindows((hWnd, lParam) => {
            if (IsWindowVisible(hWnd)) {
                int length = GetWindowTextLength(hWnd);
                if (length > 0) {
                    StringBuilder sb = new StringBuilder(length + 1);
                    GetWindowText(hWnd, sb, sb.Capacity);
                    string title = sb.ToString();
                    
                    // Look specifically for "Claude Code CLI environment"
                    if (title.Contains("Claude Code CLI")) {
                        claudeWindow = hWnd;
                        return false; // Stop enumeration
                    }
                }
            }
            return true; // Continue enumeration
        }, IntPtr.Zero);
        
        return claudeWindow;
    }
    
    public static bool ActivateWindow(IntPtr hWnd) {
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
    
    public static void SendText(IntPtr hWnd, string text) {
        SendMessage(hWnd, WM_SETTEXT, IntPtr.Zero, text);
    }
}
"@

Write-Host "=== Claude Code CLI Window Detection ===" -ForegroundColor Cyan

# Find the Claude Code CLI window
$claudeHwnd = [ClaudeWindow]::FindClaudeWindow()

if ($claudeHwnd -eq [IntPtr]::Zero) {
    Write-Host "Claude Code CLI window not found!" -ForegroundColor Red
    Write-Host "Please ensure the terminal window title is 'Claude Code CLI environment'" -ForegroundColor Yellow
    return
}

# Get window information
$windowPid = 0
[ClaudeWindow]::GetWindowThreadProcessId($claudeHwnd, [ref]$windowPid) | Out-Null

$titleLength = [ClaudeWindow]::GetWindowTextLength($claudeHwnd)
$titleBuilder = New-Object System.Text.StringBuilder($titleLength + 1)
[ClaudeWindow]::GetWindowText($claudeHwnd, $titleBuilder, $titleBuilder.Capacity) | Out-Null
$windowTitle = $titleBuilder.ToString()

Write-Host "`nFound Claude Code CLI Window:" -ForegroundColor Green
Write-Host "  Window Handle: $claudeHwnd" -ForegroundColor Gray
Write-Host "  Window Title: $windowTitle" -ForegroundColor Gray
Write-Host "  Process ID: $windowPid" -ForegroundColor Gray

# Get process information
try {
    $process = Get-Process -Id $windowPid -ErrorAction Stop
    Write-Host "  Process Name: $($process.ProcessName)" -ForegroundColor Gray
} catch {
    Write-Host "  Process Name: Unknown" -ForegroundColor Yellow
}

# Update system_status.json
$statusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
if (Test-Path $statusFile) {
    try {
        $status = Get-Content $statusFile -Raw | ConvertFrom-Json
        
        if (-not $status.SystemInfo.ClaudeCodeCLI) {
            $status.SystemInfo | Add-Member -MemberType NoteProperty -Name "ClaudeCodeCLI" -Value @{} -Force
        }
        
        # Keep the Node.js process ID if it exists
        $existingNodePid = $status.SystemInfo.ClaudeCodeCLI.ProcessId
        
        # Update with terminal window information
        $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "ProcessId" -Value $existingNodePid -Force
        $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "TerminalWindowHandle" -Value $claudeHwnd.ToString() -Force
        $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "TerminalProcessId" -Value $windowPid -Force
        $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "WindowTitle" -Value $windowTitle -Force
        $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "Status" -Value "Active" -Force
        $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "DetectionMethod" -Value "Window Handle Detection" -Force
        $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "LastDetected" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") -Force
        
        $status | ConvertTo-Json -Depth 10 | Set-Content $statusFile -Encoding UTF8
        Write-Host "`nUpdated system_status.json successfully!" -ForegroundColor Green
    } catch {
        Write-Host "`nError updating system_status.json: $_" -ForegroundColor Red
    }
}

# Test window activation
Write-Host "`nTesting window activation..." -ForegroundColor Cyan
if ([ClaudeWindow]::ActivateWindow($claudeHwnd)) {
    Write-Host "Successfully activated Claude Code CLI window!" -ForegroundColor Green
    Write-Host "The window should now be in focus." -ForegroundColor Gray
} else {
    Write-Host "Failed to activate window" -ForegroundColor Red
}

Write-Host "`n=== Window Detection Complete ===" -ForegroundColor Cyan
Write-Host "Window handle saved for automation: $claudeHwnd" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUC4LfQvV4D3XdW2l5C3A2ve16
# OwigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUaAa6/d8h2NMZfLYsaRmAkMdkMS4wDQYJKoZIhvcNAQEBBQAEggEApuTp
# W2Ccz3szkygdf8xahyIu9N5k+br3SuOV5Co4RzUiYDasNgPwKnL53J8rz26pDF+J
# 5/f26ZzUgTYtMPpE/bWqXZzactfXKgCJ0ZADxM+h7fUTUshjML0oODmzTfgE4drl
# fXLMI0URO8zKMnz1f3VkgWyTtcgtvGdE8GqtiUG3iS+B4KSOSmTFt+WCusKYczf9
# PXf6dPLzwn5M6cQp9TWv84YhYkkUvGHItoVRtHA24MulsiBFDqu1AlsYJsPLr5W0
# a5E2bi/MzppXsynlz/BBWi+rRpHQVoS2LKXQUqcpJEROpDUvdhSyaaUH7y+D70Bg
# cdHI+oapFiCxZVCLgw==
# SIG # End signature block
