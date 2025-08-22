# Invoke-RapidUnitySwitch-v3.ps1
# Version 3: Fixed compilation errors in P/Invoke definitions
# Uses direct window activation with SetForegroundWindow
# Target: <500ms total operation time
# Created: 2025-08-17
# Part of Unity-Claude-Automation v4.0

param(
    [int]$WaitMilliseconds = 75,
    [switch]$Measure,
    [switch]$Debug,
    [switch]$TestMode,
    [string]$ProjectName = "Dithering"
)

# Initialize logging
$logFile = Join-Path $PSScriptRoot "unity_claude_automation.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"

function Write-DebugLog {
    param([string]$Message)
    $logEntry = "$timestamp [RAPID_SWITCH_V3] $Message"
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    if ($Debug) {
        Write-Host $logEntry -ForegroundColor Cyan
    }
}

Write-DebugLog "=== Invoke-RapidUnitySwitch-v3 Started ==="
Write-DebugLog "Parameters: WaitMilliseconds=$WaitMilliseconds, Measure=$Measure, Debug=$Debug, TestMode=$TestMode, ProjectName=$ProjectName"

# Define simplified P/Invoke structures
Write-DebugLog "Defining P/Invoke structures for Windows API calls"

$signature = @'
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

[DllImport("user32.dll", SetLastError = true)]
public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

[DllImport("user32.dll", SetLastError = true)]
public static extern int GetWindowTextLength(IntPtr hWnd);

[DllImport("user32.dll", SetLastError = true)]
public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);

[DllImport("user32.dll", SetLastError = true)]
public static extern bool IsWindowVisible(IntPtr hWnd);

[DllImport("user32.dll", SetLastError = true)]
public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);

[DllImport("kernel32.dll")]
public static extern uint GetCurrentThreadId();

[DllImport("user32.dll", SetLastError = true)]
public static extern void keybd_event(byte bVk, byte bScan, uint dwFlags, IntPtr dwExtraInfo);

[DllImport("user32.dll", SetLastError = true)]
public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, IntPtr pvParam, uint fWinIni);

[DllImport("user32.dll", SetLastError = true)]
public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

public const int SW_RESTORE = 9;
public const int SW_SHOW = 5;
public const byte VK_MENU = 0x12;
public const uint KEYEVENTF_KEYUP = 0x0002;
public const uint SPI_GETFOREGROUNDLOCKTIMEOUT = 0x2000;
public const uint SPI_SETFOREGROUNDLOCKTIMEOUT = 0x2001;
public const uint SPIF_SENDCHANGE = 0x02;
'@

try {
    $type = Add-Type -MemberDefinition $signature -Name Win32Utils -Namespace Win32Functions -PassThru -UsingNamespace System.Text -ErrorAction SilentlyContinue
    Write-DebugLog "P/Invoke structures defined successfully"
} catch {
    Write-DebugLog "P/Invoke structures already defined or minor error: $_"
}

function Get-WindowInfo {
    param([IntPtr]$WindowHandle)
    
    Write-DebugLog "Getting window information for handle: $WindowHandle"
    
    # Get window title
    $length = [Win32Functions.Win32Utils]::GetWindowTextLength($WindowHandle)
    if ($length -gt 0) {
        $titleBuilder = New-Object System.Text.StringBuilder ($length + 1)
        [Win32Functions.Win32Utils]::GetWindowText($WindowHandle, $titleBuilder, $titleBuilder.Capacity) | Out-Null
        $title = $titleBuilder.ToString()
    } else {
        $title = ""
    }
    
    # Get process ID
    $processId = 0
    [Win32Functions.Win32Utils]::GetWindowThreadProcessId($WindowHandle, [ref]$processId) | Out-Null
    
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
    
    # Method 1: Find Unity process
    $unityProcesses = Get-Process -Name "Unity" -ErrorAction SilentlyContinue
    
    if ($unityProcesses) {
        Write-DebugLog "Found $($unityProcesses.Count) Unity process(es)"
        foreach ($proc in $unityProcesses) {
            if ($proc.MainWindowHandle -ne 0) {
                $windowInfo = Get-WindowInfo -WindowHandle $proc.MainWindowHandle
                Write-DebugLog "Checking Unity window: '$($windowInfo.Title)'"
                if ($windowInfo.Title -like "*$ProjectName*" -or $windowInfo.Title -like "*Unity*") {
                    Write-DebugLog "Found Unity window via process: $($windowInfo.Title)"
                    return $windowInfo
                }
            }
        }
    } else {
        Write-DebugLog "No Unity.exe process found"
    }
    
    # Method 2: Search all windows for Unity-like titles
    Write-DebugLog "Searching all windows for Unity project"
    $foundWindows = @()
    
    # Get all processes and check their main windows
    Get-Process | Where-Object { $_.MainWindowHandle -ne 0 } | ForEach-Object {
        $windowInfo = Get-WindowInfo -WindowHandle $_.MainWindowHandle
        if ($windowInfo.Title -like "*$ProjectName*" -or 
            $windowInfo.Title -like "*Unity*$ProjectName*" -or
            $windowInfo.Title -like "*$ProjectName*Unity*") {
            Write-DebugLog "Found potential Unity window: $($windowInfo.Title)"
            $foundWindows += $windowInfo
        }
    }
    
    if ($foundWindows.Count -gt 0) {
        Write-DebugLog "Found $($foundWindows.Count) potential Unity window(s)"
        return $foundWindows[0]
    }
    
    Write-DebugLog "No Unity window found for project: $ProjectName"
    return $null
}

function Activate-WindowWithBypass {
    param([IntPtr]$TargetWindow)
    
    Write-DebugLog "Attempting to activate window: $TargetWindow"
    
    # Simulate Alt key press to unlock SetForegroundWindow
    [Win32Functions.Win32Utils]::keybd_event([Win32Functions.Win32Utils]::VK_MENU, 0, 0, [IntPtr]::Zero)
    [Win32Functions.Win32Utils]::keybd_event([Win32Functions.Win32Utils]::VK_MENU, 0, [Win32Functions.Win32Utils]::KEYEVENTF_KEYUP, [IntPtr]::Zero)
    
    Start-Sleep -Milliseconds 10
    
    # Restore window if minimized
    if ([Win32Functions.Win32Utils]::IsIconic($TargetWindow)) {
        Write-DebugLog "Window is minimized, restoring"
        [Win32Functions.Win32Utils]::ShowWindow($TargetWindow, [Win32Functions.Win32Utils]::SW_RESTORE) | Out-Null
    }
    
    # Bring to top and set foreground
    [Win32Functions.Win32Utils]::BringWindowToTop($TargetWindow) | Out-Null
    $result = [Win32Functions.Win32Utils]::SetForegroundWindow($TargetWindow)
    
    Write-DebugLog "Window activation result: $result"
    return $result
}

function Activate-WindowEnhanced {
    param([IntPtr]$TargetWindow)
    
    Write-DebugLog "Attempting enhanced window activation"
    
    $currentForeground = [Win32Functions.Win32Utils]::GetForegroundWindow()
    if ($currentForeground -eq $TargetWindow) {
        Write-DebugLog "Window already active"
        return $true
    }
    
    $targetThreadId = [Win32Functions.Win32Utils]::GetWindowThreadProcessId($TargetWindow, [ref]$null)
    $foregroundThreadId = [Win32Functions.Win32Utils]::GetWindowThreadProcessId($currentForeground, [ref]$null)
    $currentThreadId = [Win32Functions.Win32Utils]::GetCurrentThreadId()
    
    $attached = $false
    try {
        # Attach to foreground thread
        if ($currentThreadId -ne $foregroundThreadId) {
            $attached = [Win32Functions.Win32Utils]::AttachThreadInput($currentThreadId, $foregroundThreadId, $true)
            Write-DebugLog "Thread attachment: $attached"
        }
        
        # Set foreground lock timeout to 0
        $null = [Win32Functions.Win32Utils]::SystemParametersInfo(
            [Win32Functions.Win32Utils]::SPI_SETFOREGROUNDLOCKTIMEOUT, 
            0, 
            [IntPtr]::Zero, 
            [Win32Functions.Win32Utils]::SPIF_SENDCHANGE
        )
        
        # Activate window
        if ([Win32Functions.Win32Utils]::IsIconic($TargetWindow)) {
            [Win32Functions.Win32Utils]::ShowWindow($TargetWindow, [Win32Functions.Win32Utils]::SW_RESTORE) | Out-Null
        }
        
        [Win32Functions.Win32Utils]::BringWindowToTop($TargetWindow) | Out-Null
        $result = [Win32Functions.Win32Utils]::SetForegroundWindow($TargetWindow)
        
        Write-DebugLog "Enhanced activation result: $result"
        return $result
    }
    finally {
        if ($attached) {
            [Win32Functions.Win32Utils]::AttachThreadInput($currentThreadId, $foregroundThreadId, $false) | Out-Null
        }
    }
}

function Invoke-RapidUnitySwitch {
    Write-DebugLog "Starting rapid Unity switch operation"
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Step 1: Store current window
    Write-DebugLog "Step 1: Getting current foreground window"
    $originalWindow = [Win32Functions.Win32Utils]::GetForegroundWindow()
    $originalInfo = Get-WindowInfo -WindowHandle $originalWindow
    Write-DebugLog "Original window: $($originalInfo.Title) (Process: $($originalInfo.ProcessName))"
    
    # Step 2: Find Unity window
    Write-DebugLog "Step 2: Finding Unity window"
    $unityInfo = Find-UnityWindow -ProjectName $ProjectName
    
    if (-not $unityInfo) {
        Write-DebugLog "ERROR: Unity window not found"
        Write-Error "Unity window not found. Is Unity running with the '$ProjectName' project?"
        return @{
            Success = $false
            Error = "Unity window not found"
            OriginalWindow = $originalInfo
        }
    }
    
    Write-DebugLog "Unity window found: $($unityInfo.Title)"
    
    if ($TestMode) {
        Write-DebugLog "TEST MODE: Skipping actual switching"
        $stopwatch.Stop()
        return @{
            Success = $true
            TestMode = $true
            OriginalWindow = $originalInfo
            UnityWindow = $unityInfo
            TotalMilliseconds = $stopwatch.Elapsed.TotalMilliseconds
        }
    }
    
    # Step 3: Switch to Unity
    Write-DebugLog "Step 3: Switching to Unity window"
    $switchTime1 = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Try enhanced activation first
    $activated = Activate-WindowEnhanced -TargetWindow $unityInfo.Handle
    if (-not $activated) {
        Write-DebugLog "Enhanced activation failed, trying basic"
        $activated = Activate-WindowWithBypass -TargetWindow $unityInfo.Handle
    }
    
    $switchTime1.Stop()
    Write-DebugLog "Unity activation in $($switchTime1.Elapsed.TotalMilliseconds)ms (Success: $activated)"
    
    # Step 4: Wait for Unity
    Write-DebugLog "Step 4: Waiting ${WaitMilliseconds}ms for Unity"
    Start-Sleep -Milliseconds $WaitMilliseconds
    
    # Verify switch
    $currentWindow = [Win32Functions.Win32Utils]::GetForegroundWindow()
    $currentInfo = Get-WindowInfo -WindowHandle $currentWindow
    Write-DebugLog "Current window: $($currentInfo.Title)"
    
    $isUnity = ($currentWindow -eq $unityInfo.Handle) -or 
               ($currentInfo.ProcessName -eq "Unity") -or
               ($currentInfo.Title -like "*$ProjectName*")
    Write-DebugLog "Unity detected: $isUnity"
    
    # Step 5: Switch back
    Write-DebugLog "Step 5: Switching back to original window"
    $switchTime2 = [System.Diagnostics.Stopwatch]::StartNew()
    
    $restored = Activate-WindowWithBypass -TargetWindow $originalWindow
    
    $switchTime2.Stop()
    Write-DebugLog "Return switch in $($switchTime2.Elapsed.TotalMilliseconds)ms (Success: $restored)"
    
    $stopwatch.Stop()
    
    # Verify return
    Start-Sleep -Milliseconds 50
    $finalWindow = [Win32Functions.Win32Utils]::GetForegroundWindow()
    $finalInfo = Get-WindowInfo -WindowHandle $finalWindow
    Write-DebugLog "Final window: $($finalInfo.Title)"
    
    $returnedCorrectly = $finalWindow -eq $originalWindow
    Write-DebugLog "Returned correctly: $returnedCorrectly"
    
    # Timing breakdown
    $timingBreakdown = @{
        TotalMilliseconds = $stopwatch.Elapsed.TotalMilliseconds
        FirstSwitchMs = $switchTime1.Elapsed.TotalMilliseconds
        WaitTimeMs = $WaitMilliseconds
        SecondSwitchMs = $switchTime2.Elapsed.TotalMilliseconds
        OverheadMs = $stopwatch.Elapsed.TotalMilliseconds - $switchTime1.Elapsed.TotalMilliseconds - $WaitMilliseconds - $switchTime2.Elapsed.TotalMilliseconds
    }
    
    Write-DebugLog "=== Timing Breakdown ==="
    Write-DebugLog "Total: $($timingBreakdown.TotalMilliseconds)ms"
    Write-DebugLog "First switch: $($timingBreakdown.FirstSwitchMs)ms"
    Write-DebugLog "Wait: $($timingBreakdown.WaitTimeMs)ms"
    Write-DebugLog "Second switch: $($timingBreakdown.SecondSwitchMs)ms"
    Write-DebugLog "Overhead: $($timingBreakdown.OverheadMs)ms"
    
    # Result
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
            Write-Host "  Unity: $($unityInfo.Title)" -ForegroundColor Gray
        } else {
            Write-Host "Rapid switch completed with issues in $([Math]::Round($timingBreakdown.TotalMilliseconds, 2))ms" -ForegroundColor Yellow
            if (-not $isUnity) {
                Write-Host "  - Unity not activated" -ForegroundColor Yellow
            }
            if (-not $returnedCorrectly) {
                Write-Host "  - Did not return correctly" -ForegroundColor Yellow
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
    
    Write-DebugLog "=== Invoke-RapidUnitySwitch-v3 Completed ==="
} catch {
    Write-DebugLog "ERROR: $($_.Exception.Message)"
    Write-DebugLog "Stack trace: $($_.ScriptStackTrace)"
    Write-Error $_
    
    $errorEntry = "$timestamp [RAPID_SWITCH_V3_ERROR] $($_.Exception.Message)"
    Add-Content -Path $logFile -Value $errorEntry -Encoding UTF8
    
    throw
} finally {
    Write-DebugLog "=== Script Execution Ended ==="
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQbjaWx9JKFXeVpBfO2BFeww9
# 86ygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUi9HNlgrii0Xj5nYL8jrsubLAjhswDQYJKoZIhvcNAQEBBQAEggEAq+Y3
# ZMv+g6OKfuy1Rjfl/lhlCUlYM7875ul4zbaAE/uMVeKWi0qyZLXQioZPxsW94RRB
# ZfkVs+wSq5xwoKeQq3y+/IStOUW6uyMo3EmJ2C822UF0StR//jNuQEC2ZAvsyCm+
# EyGRWlFFC86BTlLFpyiitP/HT5g+aGmakz6StxpL4JPnfJ4kYYbQf0qLGb27ioAP
# 79862ru69AVt791Rmrx17I+g0P6qVrAiMK48mewnvrJj90pxZ7CXQOGiVNlMrJWi
# AXwHbM7/H2O/Y6Jm1lStbjdhDgj7l1mrM9ouS4k9Gy3d6//3W+owP10YRxNtfpDJ
# ioORIGLPIw71ezQq1g==
# SIG # End signature block
