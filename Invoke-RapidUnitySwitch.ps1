# Invoke-RapidUnitySwitch.ps1
# Rapid window switching to trigger Unity compilation with minimal disruption
# Uses P/Invoke SendInput for sub-second Alt+Tab switching
# Target: <500ms total operation time (150-300ms typical)
# Created: 2025-08-17
# Part of Unity-Claude-Automation v4.0

param(
    [int]$WaitMilliseconds = 75,  # Time to wait for Unity to process (default 75ms)
    [switch]$Measure,              # Return timing measurements
    [switch]$Debug,                # Enable debug output
    [switch]$TestMode              # Test mode without actual switching
)

# Ensure UTF-8 with BOM encoding for PowerShell 5.1 compatibility
# This script should be saved as UTF-8 with BOM

# Initialize centralized logging
$logFile = Join-Path $PSScriptRoot "unity_claude_automation.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"

function Write-DebugLog {
    param([string]$Message)
    
    $logEntry = "$timestamp [RAPID_SWITCH] $Message"
    
    # Write to centralized log
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    
    # Write to console if debug mode
    if ($Debug) {
        Write-Host $logEntry -ForegroundColor Cyan
    }
}

Write-DebugLog "=== Invoke-RapidUnitySwitch Started ==="
Write-DebugLog "Parameters: WaitMilliseconds=$WaitMilliseconds, Measure=$Measure, Debug=$Debug, TestMode=$TestMode"

# Define P/Invoke structures for SendInput
Write-DebugLog "Defining P/Invoke structures for Windows API calls"

try {
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    
    public class RapidSwitch {
        // Windows API imports
        [DllImport("user32.dll", SetLastError = true)]
        public static extern uint SendInput(uint nInputs, INPUT[] pInputs, int cbSize);
        
        [DllImport("user32.dll", SetLastError = true)]
        public static extern IntPtr GetForegroundWindow();
        
        [DllImport("user32.dll", SetLastError = true)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        
        [DllImport("user32.dll", SetLastError = true)]
        public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);
        
        [DllImport("user32.dll", SetLastError = true)]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
        
        // INPUT structure for SendInput
        [StructLayout(LayoutKind.Sequential)]
        public struct INPUT {
            public uint type;
            public INPUTUNION union;
        }
        
        // Union structure for different input types
        [StructLayout(LayoutKind.Explicit)]
        public struct INPUTUNION {
            [FieldOffset(0)] public MOUSEINPUT mi;
            [FieldOffset(0)] public KEYBDINPUT ki;
            [FieldOffset(0)] public HARDWAREINPUT hi;
        }
        
        // Keyboard input structure
        [StructLayout(LayoutKind.Sequential)]
        public struct KEYBDINPUT {
            public ushort wVk;
            public ushort wScan;
            public uint dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }
        
        // Mouse input structure (not used but required for union)
        [StructLayout(LayoutKind.Sequential)]
        public struct MOUSEINPUT {
            public int dx;
            public int dy;
            public uint mouseData;
            public uint dwFlags;
            public uint time;
            public IntPtr dwExtraInfo;
        }
        
        // Hardware input structure (not used but required for union)
        [StructLayout(LayoutKind.Sequential)]
        public struct HARDWAREINPUT {
            public uint uMsg;
            public ushort wParamL;
            public ushort wParamH;
        }
        
        // Constants
        public const uint INPUT_KEYBOARD = 1;
        public const ushort VK_MENU = 0x12;      // Alt key
        public const ushort VK_TAB = 0x09;       // Tab key
        public const uint KEYEVENTF_KEYUP = 0x0002;
        public const uint KEYEVENTF_EXTENDEDKEY = 0x0001;
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
    $titleLength = [RapidSwitch]::GetWindowText($WindowHandle, $titleBuilder, $titleBuilder.Capacity)
    $title = $titleBuilder.ToString()
    
    # Get process ID
    $processId = 0
    [RapidSwitch]::GetWindowThreadProcessId($WindowHandle, [ref]$processId) | Out-Null
    
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

function Invoke-RapidUnitySwitch {
    Write-DebugLog "Starting rapid Unity switch operation"
    
    # Initialize stopwatch for timing measurement
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    Write-DebugLog "Stopwatch started for timing measurement"
    
    # Step 1: Store current window handle
    Write-DebugLog "Step 1: Getting current foreground window"
    $originalWindow = [RapidSwitch]::GetForegroundWindow()
    $originalInfo = Get-WindowInfo -WindowHandle $originalWindow
    Write-DebugLog "Original window stored: $($originalInfo.Title) (Process: $($originalInfo.ProcessName))"
    
    if ($TestMode) {
        Write-DebugLog "TEST MODE: Skipping actual window switching"
        $stopwatch.Stop()
        return @{
            Success = $true
            TestMode = $true
            OriginalWindow = $originalInfo
            TotalMilliseconds = $stopwatch.Elapsed.TotalMilliseconds
        }
    }
    
    # Step 2: Create Alt+Tab input sequence
    Write-DebugLog "Step 2: Creating Alt+Tab input sequence"
    
    # Create array of INPUT structures for Alt+Tab
    $inputs = New-Object 'RapidSwitch+INPUT[]' 4
    
    # Alt key down
    $inputs[0] = New-Object 'RapidSwitch+INPUT'
    $inputs[0].type = [RapidSwitch]::INPUT_KEYBOARD
    $inputs[0].union = New-Object 'RapidSwitch+INPUTUNION'
    $inputs[0].union.ki = New-Object 'RapidSwitch+KEYBDINPUT'
    $inputs[0].union.ki.wVk = [RapidSwitch]::VK_MENU
    $inputs[0].union.ki.dwFlags = 0
    Write-DebugLog "Created Alt key down input"
    
    # Tab key down
    $inputs[1] = New-Object 'RapidSwitch+INPUT'
    $inputs[1].type = [RapidSwitch]::INPUT_KEYBOARD
    $inputs[1].union = New-Object 'RapidSwitch+INPUTUNION'
    $inputs[1].union.ki = New-Object 'RapidSwitch+KEYBDINPUT'
    $inputs[1].union.ki.wVk = [RapidSwitch]::VK_TAB
    $inputs[1].union.ki.dwFlags = 0
    Write-DebugLog "Created Tab key down input"
    
    # Tab key up
    $inputs[2] = New-Object 'RapidSwitch+INPUT'
    $inputs[2].type = [RapidSwitch]::INPUT_KEYBOARD
    $inputs[2].union = New-Object 'RapidSwitch+INPUTUNION'
    $inputs[2].union.ki = New-Object 'RapidSwitch+KEYBDINPUT'
    $inputs[2].union.ki.wVk = [RapidSwitch]::VK_TAB
    $inputs[2].union.ki.dwFlags = [RapidSwitch]::KEYEVENTF_KEYUP
    Write-DebugLog "Created Tab key up input"
    
    # Alt key up
    $inputs[3] = New-Object 'RapidSwitch+INPUT'
    $inputs[3].type = [RapidSwitch]::INPUT_KEYBOARD
    $inputs[3].union = New-Object 'RapidSwitch+INPUTUNION'
    $inputs[3].union.ki = New-Object 'RapidSwitch+KEYBDINPUT'
    $inputs[3].union.ki.wVk = [RapidSwitch]::VK_MENU
    $inputs[3].union.ki.dwFlags = [RapidSwitch]::KEYEVENTF_KEYUP
    Write-DebugLog "Created Alt key up input"
    
    # Calculate size of INPUT structure
    $inputSize = [System.Runtime.InteropServices.Marshal]::SizeOf([Type]'RapidSwitch+INPUT')
    Write-DebugLog "INPUT structure size: $inputSize bytes"
    
    # Step 3: Send Alt+Tab to switch to Unity
    Write-DebugLog "Step 3: Sending first Alt+Tab sequence to switch to Unity"
    $switchTime1 = [System.Diagnostics.Stopwatch]::StartNew()
    
    $result1 = [RapidSwitch]::SendInput($inputs.Length, $inputs, $inputSize)
    
    $switchTime1.Stop()
    Write-DebugLog "First Alt+Tab sent in $($switchTime1.Elapsed.TotalMilliseconds)ms (Result: $result1)"
    
    if ($result1 -eq 0) {
        $error = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-DebugLog "ERROR: SendInput failed with error code: $error"
        throw "SendInput failed with error code: $error"
    }
    
    # Step 4: Wait for Unity to process focus change
    Write-DebugLog "Step 4: Waiting ${WaitMilliseconds}ms for Unity to process focus"
    Start-Sleep -Milliseconds $WaitMilliseconds
    
    # Get current window to verify switch
    $currentWindow = [RapidSwitch]::GetForegroundWindow()
    $currentInfo = Get-WindowInfo -WindowHandle $currentWindow
    Write-DebugLog "Current window after switch: $($currentInfo.Title) (Process: $($currentInfo.ProcessName))"
    
    # Check if we're in Unity
    $isUnity = $currentInfo.ProcessName -like "*Unity*"
    Write-DebugLog "Unity detected: $isUnity"
    
    # Step 5: Send Alt+Tab again to return to original window
    Write-DebugLog "Step 5: Sending second Alt+Tab to return to original window"
    $switchTime2 = [System.Diagnostics.Stopwatch]::StartNew()
    
    $result2 = [RapidSwitch]::SendInput($inputs.Length, $inputs, $inputSize)
    
    $switchTime2.Stop()
    Write-DebugLog "Second Alt+Tab sent in $($switchTime2.Elapsed.TotalMilliseconds)ms (Result: $result2)"
    
    if ($result2 -eq 0) {
        $error = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
        Write-DebugLog "ERROR: Second SendInput failed with error code: $error"
    }
    
    # Stop total timing
    $stopwatch.Stop()
    
    # Verify we returned to original window
    Start-Sleep -Milliseconds 50  # Small delay for window to settle
    $finalWindow = [RapidSwitch]::GetForegroundWindow()
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
        UnityWindow = $currentInfo
        FinalWindow = $finalInfo
        ReturnedCorrectly = $returnedCorrectly
        UnityDetected = $isUnity
        TimingBreakdown = $timingBreakdown
    }
    
    if ($Measure) {
        return $result
    } else {
        if ($result.Success) {
            Write-Host "Rapid switch completed successfully in $([Math]::Round($timingBreakdown.TotalMilliseconds, 2))ms" -ForegroundColor Green
        } else {
            Write-Host "Rapid switch completed with issues in $([Math]::Round($timingBreakdown.TotalMilliseconds, 2))ms" -ForegroundColor Yellow
            if (-not $isUnity) {
                Write-Host "  - Unity was not detected in the switched window" -ForegroundColor Yellow
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
    
    Write-DebugLog "=== Invoke-RapidUnitySwitch Completed Successfully ==="
} catch {
    Write-DebugLog "ERROR: $($_.Exception.Message)"
    Write-DebugLog "Stack trace: $($_.ScriptStackTrace)"
    Write-Error $_
    
    # Log to centralized file even on error
    $errorEntry = "$timestamp [RAPID_SWITCH_ERROR] $($_.Exception.Message)"
    Add-Content -Path $logFile -Value $errorEntry -Encoding UTF8
    
    throw
} finally {
    Write-DebugLog "=== Script Execution Ended ==="
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUeRzHguns2eWaMoXHrYSrSOum
# hI6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUZxSFaFvkbtQyCCJy/pnCubPZvHYwDQYJKoZIhvcNAQEBBQAEggEAeYLq
# 5hBS0v2M6TiveK//ARYCY3n9IrhauTeMS6kn7MmrIEXgs2se35bqu9vuWEx98qLC
# UlgbFUYMoERu/6zjQW3gz1FplHukhKZkO0y355vPuHMR3fmTbH1s8S/fAfFX3oVg
# 6VPjj+7Fi0hwj/8PtWOiO7qqsuWwdyqwVoNlAz6tHcBVixiRzdmQsW0BOSy8Zp6X
# AgkMQ0laBtPacQ9duXz5dwKZAGfmsaCvrXNX2qS2AwcwKoWjINFh2zHCb0LKX+8S
# zkVwaSxV9N+IXNcchzLhv8Tu+Y58OVL8wKvOIHqT3aACoZj3GFczxRyeHGYcomZl
# +DUK11znBQH0YuGJ1A==
# SIG # End signature block
