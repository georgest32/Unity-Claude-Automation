# Find-ClaudeCodeWindow.ps1
# Alternative approach: Find terminal window by searching for windows with "Claude" in title

Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
using System.Collections.Generic;

public class WindowFinder {
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
    
    public static List<IntPtr> FindWindowsByTitle(string titlePattern) {
        List<IntPtr> windows = new List<IntPtr>();
        
        EnumWindows((hWnd, lParam) => {
            if (IsWindowVisible(hWnd)) {
                int length = GetWindowTextLength(hWnd);
                if (length > 0) {
                    StringBuilder sb = new StringBuilder(length + 1);
                    GetWindowText(hWnd, sb, sb.Capacity);
                    string title = sb.ToString();
                    
                    if (!string.IsNullOrEmpty(title) && 
                        title.IndexOf(titlePattern, StringComparison.OrdinalIgnoreCase) >= 0) {
                        windows.Add(hWnd);
                    }
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
    
    public static uint GetWindowProcessId(IntPtr hWnd) {
        uint pid;
        GetWindowThreadProcessId(hWnd, out pid);
        return pid;
    }
}
"@

Write-Host "=== Searching for Claude Code Windows ===" -ForegroundColor Cyan

# Search for windows with "Claude" in the title
$claudeWindows = [WindowFinder]::FindWindowsByTitle("Claude")

if ($claudeWindows.Count -eq 0) {
    Write-Host "No windows found with 'Claude' in the title" -ForegroundColor Red
    Write-Host "`nSearching for all visible terminal windows..." -ForegroundColor Yellow
    
    # List common terminal window patterns
    $terminalPatterns = @(
        "Windows PowerShell",
        "PowerShell",
        "Command Prompt",
        "Terminal",
        "Git Bash",
        "MINGW64",
        "MINGW32",
        "cmd.exe",
        "bash"
    )
    
    $allTerminals = @()
    foreach ($pattern in $terminalPatterns) {
        $found = [WindowFinder]::FindWindowsByTitle($pattern)
        foreach ($hwnd in $found) {
            $title = [WindowFinder]::GetWindowTitle($hwnd)
            $windowPid = [WindowFinder]::GetWindowProcessId($hwnd)
            $allTerminals += [PSCustomObject]@{
                WindowHandle = $hwnd
                ProcessId = $pid
                WindowTitle = $title
            }
        }
    }
    
    if ($allTerminals.Count -gt 0) {
        Write-Host "`nFound terminal windows:" -ForegroundColor Green
        $allTerminals | Format-Table -AutoSize
    }
} else {
    Write-Host "Found $($claudeWindows.Count) window(s) with 'Claude' in title:" -ForegroundColor Green
    
    foreach ($hwnd in $claudeWindows) {
        $title = [WindowFinder]::GetWindowTitle($hwnd)
        $windowPid = [WindowFinder]::GetWindowProcessId($hwnd)
        
        Write-Host "`n  Window Handle: $hwnd" -ForegroundColor Gray
        Write-Host "  Window Title: $title" -ForegroundColor Gray
        Write-Host "  Process ID: $windowPid" -ForegroundColor Gray
        
        # Try to get process information
        try {
            $process = Get-Process -Id $windowPid -ErrorAction Stop
            Write-Host "  Process Name: $($process.ProcessName)" -ForegroundColor Gray
        } catch {
            Write-Host "  Could not get process information" -ForegroundColor Yellow
        }
        
        # Save to system_status.json
        $statusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
        if (Test-Path $statusFile) {
            try {
                $status = Get-Content $statusFile -Raw | ConvertFrom-Json
                
                if (-not $status.SystemInfo.ClaudeCodeCLI) {
                    $status.SystemInfo | Add-Member -MemberType NoteProperty -Name "ClaudeCodeCLI" -Value @{} -Force
                }
                
                $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "TerminalWindowHandle" -Value $hwnd.ToString() -Force
                $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "TerminalProcessId" -Value $windowPid -Force
                $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "WindowTitle" -Value $title -Force
                $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "LastDetected" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff") -Force
                
                $status | ConvertTo-Json -Depth 10 | Set-Content $statusFile -Encoding UTF8
                Write-Host "`n  Updated system_status.json with window information" -ForegroundColor Green
            } catch {
                Write-Host "  Error updating system_status.json: $_" -ForegroundColor Red
            }
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUGUL0KRXviL0u4GWtjdIq1Jw+
# YOagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUaGF+CookY7Y7HCMzwwMNflSbdQ4wDQYJKoZIhvcNAQEBBQAEggEAXxYt
# WdkpBYQn3Ghw26zAmSgR05dkbGQTLLABoQeFDEUFonD24xARMwFIXuYVfXFMsYNP
# JrDikk7Safdqwc84JrKIUL0Hj8qGCHepHyYzZgI/T0yJ0ZmvW99U8eyjnxDJ27GF
# pcB7uBFvEIvI1zKKBQ5IHCtvch9Akk6fiXmlGBCGKkvnQwcfjrICn8gsXrIpR1XR
# UUjGFDhzFSeGyXCpu+Q3ySm5tKAShcPGvsLWnHDjgltPaQjBACCFZNIYAZgwZOLg
# GZ41lS6ax7LLE5qywdoKOsSMUgEwaK5E7i8CJtU65rbEOLmTYdyXrtHm8WS6nOIE
# +ZnlljK1K+3TQQkF2Q==
# SIG # End signature block
