# Invoke-RapidUnitySwitch-v2.ps1
# Version 2: Direct window activation instead of Alt+Tab (which is blocked by Windows security)
# Uses SetForegroundWindow with Alt key workaround and window enumeration
# Target: <500ms total operation time (150-300ms typical)
# Created: 2025-08-17
# Part of Unity-Claude-Automation v4.0

param(
    [int]$WaitMilliseconds = 75,  # Time to wait for Unity to process (default 75ms)
    [switch]$Measure,              # Return timing measurements
    [switch]$Debug,                # Enable debug output
    [switch]$TestMode,             # Test mode without actual switching
    [string]$ProjectName = "Dithering"  # Unity project name to search for
)

# Ensure UTF-8 with BOM encoding for PowerShell 5.1 compatibility
# This script should be saved as UTF-8 with BOM

# Initialize centralized logging
$logFile = Join-Path $PSScriptRoot "unity_claude_automation.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"

function Write-DebugLog {
    param([string]$Message)
    
    $logEntry = "$timestamp [RAPID_SWITCH_V2] $Message"
    
    # Write to centralized log
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    
    # Write to console if debug mode
    if ($Debug) {
        Write-Host $logEntry -ForegroundColor Cyan
    }
}

Write-DebugLog "=== Invoke-RapidUnitySwitch-v2 Started ==="
Write-DebugLog "Parameters: WaitMilliseconds=$WaitMilliseconds, Measure=$Measure, Debug=$Debug, TestMode=$TestMode, ProjectName=$ProjectName"

# Define P/Invoke structures for Windows API calls
Write-DebugLog "Defining P/Invoke structures for Windows API calls"

try {
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;
    using System.Collections.Generic;
    
    public class RapidSwitchV2 {
        // Window manipulation APIs
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr GetForegroundWindow();
        
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool IsIconic(IntPtr hWnd);
        
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool BringWindowToTop(IntPtr hWnd);
        
        // Window enumeration APIs
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
        
        [DllImport("user32.dll", SetLastError = true)]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
        
        [DllImport("user32.dll", SetLastError = true)]
        public static extern int GetWindowTextLength(IntPtr hWnd);
        
        [DllImport("user32.dll", SetLastError = true)]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
        
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool IsWindowVisible(IntPtr hWnd);
        
        // Thread attachment for focus bypass
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
        
        [DllImport("kernel32.dll")]
        public static extern uint GetCurrentThreadId();
        
        // Alt key simulation for SetForegroundWindow unlock
        [DllImport("user32.dll", SetLastError = true)]
        public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, IntPtr dwExtraInfo);
        
        // System parameters for foreground lock timeout
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, ref uint pvParam, uint fWinIni);
        
        // Delegate for window enumeration
        public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
        
        // Constants
        public const int SW_RESTORE = 9;
        public const int SW_SHOW = 5;
        public const int SW_MINIMIZE = 6;
        public const byte VK_MENU = 0x12;  // Alt key
        public const uint KEYEVENTF_KEYUP = 0x0002;
        public const uint SPI_GETFOREGROUNDLOCKTIMEOUT = 0x2000;
        public const uint SPI_SETFOREGROUNDLOCKTIMEOUT = 0x2001;
        public const uint SPIF_SENDCHANGE = 0x02;
        
        // Helper class to store window information
        public class WindowInfo {
            public IntPtr Handle { get; set; }
            public string Title { get; set; }
            public uint ProcessId { get; set; }
            public string ProcessName { get; set; }
        }
        
        // Find all Unity windows
        public static List<WindowInfo> FindUnityWindows(string projectName) {
            List<WindowInfo> unityWindows = new List<WindowInfo>();
            
            EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
                if (IsWindowVisible(hWnd)) {
                    int length = GetWindowTextLength(hWnd);
                    if (length > 0) {
                        StringBuilder sb = new StringBuilder(length + 1);
                        GetWindowText(hWnd, sb, sb.Capacity);
                        string title = sb.ToString();
                        
                        // Check if this is a Unity window
                        if ((title.Contains("Unity") && title.Contains(projectName)) || 
                            title.Contains(projectName + ".unity") ||
                            title.Contains(projectName + " - Unity")) {
                            
                            uint processId;
                            GetWindowThreadProcessId(hWnd, out processId);
                            
                            WindowInfo info = new WindowInfo {
                                Handle = hWnd,
                                Title = title,
                                ProcessId = processId
                            };
                            
                            try {
                                var process = System.Diagnostics.Process.GetProcessById((int)processId);
                                info.ProcessName = process.ProcessName;
                            } catch {
                                info.ProcessName = "Unknown";
                            }
                            
                            unityWindows.Add(info);
                        }
                    }
                }
                return true; // Continue enumeration
            }, IntPtr.Zero);
            
            return unityWindows;
        }
        
        // Activate window with focus bypass
        public static bool ActivateWindowWithBypass(IntPtr targetWindow) {
            // Method 1: Simulate Alt key press to unlock SetForegroundWindow
            keybd_event(VK_MENU, 0, 0, IntPtr.Zero);  // Alt down
            keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, IntPtr.Zero);  // Alt up
            
            // Small delay to let the Alt key register
            System.Threading.Thread.Sleep(10);
            
            // Restore window if minimized
            if (IsIconic(targetWindow)) {
                ShowWindow(targetWindow, SW_RESTORE);
            }
            
            // Bring to top and set foreground
            BringWindowToTop(targetWindow);
            bool result = SetForegroundWindow(targetWindow);
            
            return result;
        }
        
        // Enhanced activation with thread attachment
        public static bool ActivateWindowEnhanced(IntPtr targetWindow) {
            IntPtr currentForeground = GetForegroundWindow();
            
            if (currentForeground == targetWindow) {
                return true; // Already active
            }
            
            uint targetThreadId = GetWindowThreadProcessId(targetWindow, out uint targetProcessId);
            uint foregroundThreadId = GetWindowThreadProcessId(currentForeground, out uint foregroundProcessId);
            uint currentThreadId = GetCurrentThreadId();
            
            bool attached = false;
            bool result = false;
            
            try {
                // Attach to the foreground thread if different
                if (currentThreadId != foregroundThreadId) {
                    attached = AttachThreadInput(currentThreadId, foregroundThreadId, true);
                }
                
                // Set foreground lock timeout to 0
                uint timeout = 0;
                uint oldTimeout = 0;
                SystemParametersInfo(SPI_GETFOREGROUNDLOCKTIMEOUT, 0, ref oldTimeout, 0);
                SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, ref timeout, SPIF_SENDCHANGE);
                
                // Restore window if minimized
                if (IsIconic(targetWindow)) {
                    ShowWindow(targetWindow, SW_RESTORE);
                }
                
                // Activate the window
                BringWindowToTop(targetWindow);
                result = SetForegroundWindow(targetWindow);
                
                // Restore timeout
                SystemParametersInfo(SPI_SETFOREGROUNDLOCKTIMEOUT, 0, ref oldTimeout, SPIF_SENDCHANGE);
            }
            finally {
                // Detach threads
                if (attached) {
                    AttachThreadInput(currentThreadId, foregroundThreadId, false);
                }
            }
            
            return result;
        }
    }
"@ -ErrorAction SilentlyContinue
    Write-DebugLog "P/Invoke structures defined successfully"
} catch {
    # Type might already be defined from previous run
    Write-DebugLog "P/Invoke structures already defined or error: $_"
}

function Get-WindowInfo {
    param([IntPtr]$WindowHandle)
    
    Write-DebugLog "Getting window information for handle: $WindowHandle"
    
    # Get window title
    $titleBuilder = New-Object System.Text.StringBuilder 256
    $titleLength = [RapidSwitchV2]::GetWindowText($WindowHandle, $titleBuilder, $titleBuilder.Capacity)
    $title = $titleBuilder.ToString()
    
    # Get process ID
    $processId = 0
    [RapidSwitchV2]::GetWindowThreadProcessId($WindowHandle, [ref]$processId) | Out-Null
    
    # Get process name
    try {
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
        $processName = $process.ProcessName
    } catch {
        $processName = "Unknown"
    }
    
    Write-DebugLog "Window: Title='$title', Process='$processName', PID=$processId"
    
    return @{
        Handle = $WindowHandle
        Title = $title
        ProcessId = $processId
        ProcessName = $processName
    }
}

function Find-UnityWindow {
    param([string]$ProjectName)
    
    Write-DebugLog "Searching for Unity window with project name: $ProjectName"
    
    # Method 1: Try to find via process name
    $unityProcesses = Get-Process -Name "Unity" -ErrorAction SilentlyContinue
    
    if ($unityProcesses) {
        foreach ($proc in $unityProcesses) {
            if ($proc.MainWindowHandle -ne 0) {
                $windowInfo = Get-WindowInfo -WindowHandle $proc.MainWindowHandle
                if ($windowInfo.Title -like "*$ProjectName*") {
                    Write-DebugLog "Found Unity window via process: $($windowInfo.Title)"
                    return $windowInfo
                }
            }
        }
    }
    
    # Method 2: Use window enumeration
    Write-DebugLog "Process search failed, using window enumeration"
    $unityWindows = [RapidSwitchV2]::FindUnityWindows($ProjectName)
    
    if ($unityWindows.Count -gt 0) {
        $firstWindow = $unityWindows[0]
        Write-DebugLog "Found Unity window via enumeration: $($firstWindow.Title)"
        return @{
            Handle = $firstWindow.Handle
            Title = $firstWindow.Title
            ProcessId = $firstWindow.ProcessId
            ProcessName = $firstWindow.ProcessName
        }
    }
    
    Write-DebugLog "No Unity window found for project: $ProjectName"
    return $null
}

function Invoke-RapidUnitySwitch {
    Write-DebugLog "Starting rapid Unity switch operation"
    
    # Initialize stopwatch for timing measurement
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-DebugLog "Stopwatch started for timing measurement"
    
    # Step 1: Store current window handle
    Write-DebugLog "Step 1: Getting current foreground window"
    $originalWindow = [RapidSwitchV2]::GetForegroundWindow()
    $originalInfo = Get-WindowInfo -WindowHandle $originalWindow
    Write-DebugLog "Original window stored: $($originalInfo.Title) (Process: $($originalInfo.ProcessName))"
    
    # Step 2: Find Unity window
    Write-DebugLog "Step 2: Finding Unity window"
    $unityInfo = Find-UnityWindow -ProjectName $ProjectName
    
    if (-not $unityInfo) {
        Write-DebugLog "ERROR: Unity window not found for project: $ProjectName"
        Write-Error "Unity window not found. Is Unity running with the '$ProjectName' project open?"
        return @{
            Success = $false
            Error = "Unity window not found"
            OriginalWindow = $originalInfo
        }
    }
    
    Write-DebugLog "Unity window found: $($unityInfo.Title)"
    
    if ($TestMode) {
        Write-DebugLog "TEST MODE: Skipping actual window switching"
        $stopwatch.Stop()
        return @{
            Success = $true
            TestMode = $true
            OriginalWindow = $originalInfo
            UnityWindow = $unityInfo
            TotalMilliseconds = $stopwatch.Elapsed.TotalMilliseconds
        }
    }
    
    # Step 3: Switch to Unity window
    Write-DebugLog "Step 3: Switching to Unity window"
    $switchTime1 = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Try enhanced activation first, fall back to basic if it fails
    $activated = [RapidSwitchV2]::ActivateWindowEnhanced($unityInfo.Handle)
    if (-not $activated) {
        Write-DebugLog "Enhanced activation failed, trying basic activation"
        $activated = [RapidSwitchV2]::ActivateWindowWithBypass($unityInfo.Handle)
    }
    
    $switchTime1.Stop()
    Write-DebugLog "Unity activation attempted in $($switchTime1.Elapsed.TotalMilliseconds)ms (Success: $activated)"
    
    # Step 4: Wait for Unity to process focus change
    Write-DebugLog "Step 4: Waiting ${WaitMilliseconds}ms for Unity to process focus"
    Start-Sleep -Milliseconds $WaitMilliseconds
    
    # Verify switch
    $currentWindow = [RapidSwitchV2]::GetForegroundWindow()
    $currentInfo = Get-WindowInfo -WindowHandle $currentWindow
    Write-DebugLog "Current window after switch: $($currentInfo.Title) (Process: $($currentInfo.ProcessName))"
    
    # Check if we're in Unity
    $isUnity = ($currentWindow -eq $unityInfo.Handle) -or 
               ($currentInfo.ProcessName -eq "Unity") -or
               ($currentInfo.Title -like "*$ProjectName*")
    Write-DebugLog "Unity detected: $isUnity"
    
    # Step 5: Switch back to original window
    Write-DebugLog "Step 5: Switching back to original window"
    $switchTime2 = [System.Diagnostics.Stopwatch]::StartNew()
    
    $restoredOriginal = [RapidSwitchV2]::ActivateWindowWithBypass($originalWindow)
    
    $switchTime2.Stop()
    Write-DebugLog "Return switch completed in $($switchTime2.Elapsed.TotalMilliseconds)ms (Success: $restoredOriginal)"
    
    # Stop total timing
    $stopwatch.Stop()
    
    # Verify we returned to original window
    Start-Sleep -Milliseconds 50  # Small delay for window to settle
    $finalWindow = [RapidSwitchV2]::GetForegroundWindow()
    $finalInfo = Get-WindowInfo -WindowHandle $finalWindow
    Write-DebugLog "Final window: $($finalInfo.Title) (Process: $($finalInfo.ProcessName))"
    
    $returnedCorrectly = $finalWindow -eq $originalWindow
    Write-DebugLog "Returned to original window: $returnedCorrectly"
    
    # Calculate timing breakdown
    $timingBreakdown = @{
        TotalMilliseconds = $stopwatch.Elapsed.TotalMilliseconds
        FirstSwitchMs = $switchTime1.Elapsed.TotalMilliseconds
        WaitTimeMs = $WaitMilliseconds
        SecondSwitchMs = $switchTime2.Elapsed.TotalMilliseconds
        OverheadMs = $stopwatch.Elapsed.TotalMilliseconds - $switchTime1.Elapsed.TotalMilliseconds - $WaitMilliseconds - $switchTime2.Elapsed.TotalMilliseconds
    }
    
    Write-DebugLog "=== Timing Breakdown ==="
    Write-DebugLog "Total time: $($timingBreakdown.TotalMilliseconds)ms"
    Write-DebugLog "First switch: $($timingBreakdown.FirstSwitchMs)ms"
    Write-DebugLog "Wait time: $($timingBreakdown.WaitTimeMs)ms"
    Write-DebugLog "Second switch: $($timingBreakdown.SecondSwitchMs)ms"
    Write-DebugLog "Overhead: $($timingBreakdown.OverheadMs)ms"
    Write-DebugLog "========================"
    
    # Build result object
    $result = @{
        Success = $returnedCorrectly -and $isUnity
        OriginalWindow = $originalInfo
        UnityWindow = $unityInfo
        FinalWindow = $finalInfo
        ReturnedCorrectly = $returnedCorrectly
        UnityDetected = $isUnity
        UnityActivated = $activated
        TimingBreakdown = $timingBreakdown
    }
    
    if ($Measure) {
        return $result
    } else {
        if ($result.Success) {
            Write-Host "Rapid switch completed successfully in $([Math]::Round($timingBreakdown.TotalMilliseconds, 2))ms" -ForegroundColor Green
            Write-Host "  Unity window: $($unityInfo.Title)" -ForegroundColor Gray
        } else {
            Write-Host "Rapid switch completed with issues in $([Math]::Round($timingBreakdown.TotalMilliseconds, 2))ms" -ForegroundColor Yellow
            if (-not $isUnity) {
                Write-Host "  - Unity was not successfully activated" -ForegroundColor Yellow
            }
            if (-not $returnedCorrectly) {
                Write-Host "  - Did not return to original window correctly" -ForegroundColor Yellow
            }
        }
    }
}

# Main execution
try {
    Write-DebugLog "Executing rapid Unity switch"
    $result = Invoke-RapidUnitySwitch
    
    if ($Measure) {
        Write-DebugLog "Returning measurement results"
        return $result
    }
    
    Write-DebugLog "=== Invoke-RapidUnitySwitch-v2 Completed ==="
} catch {
    Write-DebugLog "ERROR: $($_.Exception.Message)"
    Write-DebugLog "Stack trace: $($_.ScriptStackTrace)"
    Write-Error $_
    
    # Log to centralized file even on error
    $errorEntry = "$timestamp [RAPID_SWITCH_V2_ERROR] $($_.Exception.Message)"
    Add-Content -Path $logFile -Value $errorEntry -Encoding UTF8
    
    throw
} finally {
    Write-DebugLog "=== Script Execution Ended ==="
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUB+Misiie6Jme12ioA9cXTIrB
# muCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU1bwdAO0sywghTnZxiLvEfI6Hf64wDQYJKoZIhvcNAQEBBQAEggEAXaoa
# jyDK9D7VaIpWKRFwwLdjPLxc3TtV4pkmfdpNFxWZPp4f9avxqpkp0eixT4cHe2WH
# wiz+rMM1q1QVep2di5MYmATyKmGq6eC2M4VhOfYZQAZXaKEgTJIUQNqEoGzE/x7k
# OHZsk/0X0mtn5C4zdPlMj4MZ86kndA2MFfsNQ/An5HOL9UGIi9RQWjiv4WwOOgNE
# YVZNxsyHETJcKKF7dDzFvYjMdz4OfJzjRT2wWIXIGTH4Mu7xiCO1sER7sjfPHnrm
# Eh668XD+2Z0fuQEPOxgD6Oz7neRH3fvL0w3yTA5juJXXnAJCjaGDbUr6udMnSOF1
# Rz2fm/j/zduO+nZs8w==
# SIG # End signature block
