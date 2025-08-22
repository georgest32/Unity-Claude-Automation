# Invoke-RapidUnityCompile.ps1
# Complete Unity compilation triggering system with error capture
# Combines rapid window switching, input blocking, and error export coordination
# Created: 2025-08-17
# Part of Unity-Claude-Automation v4.0

param(
    [int]$CompileWaitTime = 2500,   # Time to wait for compilation (2.5 seconds for ConsoleErrorExporter)
    [switch]$BlockInput,             # Block keyboard/mouse during switch
    [switch]$ForceCompile,           # Force compilation even if no changes detected
    [switch]$Measure,                # Return detailed timing measurements
    [switch]$Debug,                  # Enable debug output
    [string]$ProjectName = "Dithering",  # Unity project name
    [string]$ErrorLogPath = ""      # Path to Unity error export (defaults to Assets/Editor.log)
)

#Requires -RunAsAdministrator

# Initialize logging
$logFile = Join-Path $PSScriptRoot "unity_claude_automation.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"

function Write-DebugLog {
    param([string]$Message)
    $logEntry = "$timestamp [RAPID_COMPILE] $Message"
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    if ($Debug) {
        Write-Host $logEntry -ForegroundColor Cyan
    }
}

Write-DebugLog "=== Invoke-RapidUnityCompile Started ==="
Write-DebugLog "Parameters: CompileWaitTime=$CompileWaitTime, BlockInput=$BlockInput, ForceCompile=$ForceCompile"

# Check administrator privileges if blocking input
if ($BlockInput) {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    if (-not $isAdmin) {
        Write-Warning "BlockInput requires administrator privileges. Input blocking disabled."
        $BlockInput = $false
    } else {
        Write-DebugLog "Administrator privileges confirmed for input blocking"
    }
}

# Define P/Invoke structures
Write-DebugLog "Defining P/Invoke structures"

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
public static extern bool BlockInput(bool fBlockIt);

public const int SW_RESTORE = 9;
public const byte VK_MENU = 0x12;
public const byte VK_CONTROL = 0x11;
public const byte VK_R = 0x52;
public const uint KEYEVENTF_KEYUP = 0x0002;
'@

try {
    $type = Add-Type -MemberDefinition $signature -Name Win32API -Namespace RapidCompile -PassThru -UsingNamespace System.Text -ErrorAction SilentlyContinue
    Write-DebugLog "P/Invoke structures defined successfully"
} catch {
    Write-DebugLog "P/Invoke structures already defined or minor error: $_"
}

function Get-WindowInfo {
    param([IntPtr]$WindowHandle)
    
    $length = [RapidCompile.Win32API]::GetWindowTextLength($WindowHandle)
    if ($length -gt 0) {
        $titleBuilder = New-Object System.Text.StringBuilder ($length + 1)
        [RapidCompile.Win32API]::GetWindowText($WindowHandle, $titleBuilder, $titleBuilder.Capacity) | Out-Null
        $title = $titleBuilder.ToString()
    } else {
        $title = ""
    }
    
    $processId = 0
    [RapidCompile.Win32API]::GetWindowThreadProcessId($WindowHandle, [ref]$processId) | Out-Null
    
    try {
        $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
        $processName = $process.ProcessName
    } catch {
        $processName = "Unknown"
    }
    
    return @{
        Handle = $WindowHandle
        Title = $title
        ProcessId = $processId
        ProcessName = $processName
    }
}

function Find-UnityWindow {
    param([string]$ProjectName)
    
    Write-DebugLog "Searching for Unity window with project: $ProjectName"
    
    # Try to find Unity process
    $unityProcesses = Get-Process -Name "Unity" -ErrorAction SilentlyContinue
    
    if ($unityProcesses) {
        foreach ($proc in $unityProcesses) {
            if ($proc.MainWindowHandle -ne 0) {
                $windowInfo = Get-WindowInfo -WindowHandle $proc.MainWindowHandle
                if ($windowInfo.Title -like "*$ProjectName*") {
                    Write-DebugLog "Found Unity window: $($windowInfo.Title)"
                    return $windowInfo
                }
            }
        }
    }
    
    # Search all windows
    Get-Process | Where-Object { $_.MainWindowHandle -ne 0 } | ForEach-Object {
        $windowInfo = Get-WindowInfo -WindowHandle $_.MainWindowHandle
        if ($windowInfo.Title -like "*$ProjectName*" -and $windowInfo.Title -like "*Unity*") {
            Write-DebugLog "Found Unity window via search: $($windowInfo.Title)"
            return $windowInfo
        }
    }
    
    Write-DebugLog "No Unity window found"
    return $null
}

function Block-UserInput {
    param([bool]$Block)
    
    if (-not $BlockInput) {
        return $true
    }
    
    try {
        $result = [RapidCompile.Win32API]::BlockInput($Block)
        if ($Block) {
            Write-DebugLog "User input blocked: $result"
            Write-Host "Input blocked - DO NOT type or click!" -ForegroundColor Yellow -BackgroundColor Red
        } else {
            Write-DebugLog "User input unblocked: $result"
            Write-Host "Input restored - Safe to use keyboard and mouse" -ForegroundColor Green
        }
        return $result
    } catch {
        Write-DebugLog "Failed to block/unblock input: $_"
        return $false
    }
}

function Activate-UnityWindow {
    param([IntPtr]$TargetWindow)
    
    Write-DebugLog "Activating Unity window"
    
    # Alt key to unlock SetForegroundWindow
    [RapidCompile.Win32API]::keybd_event([RapidCompile.Win32API]::VK_MENU, 0, 0, [IntPtr]::Zero)
    [RapidCompile.Win32API]::keybd_event([RapidCompile.Win32API]::VK_MENU, 0, [RapidCompile.Win32API]::KEYEVENTF_KEYUP, [IntPtr]::Zero)
    
    Start-Sleep -Milliseconds 10
    
    # Restore if minimized
    if ([RapidCompile.Win32API]::IsIconic($TargetWindow)) {
        [RapidCompile.Win32API]::ShowWindow($TargetWindow, [RapidCompile.Win32API]::SW_RESTORE) | Out-Null
    }
    
    # Activate window
    [RapidCompile.Win32API]::BringWindowToTop($TargetWindow) | Out-Null
    $result = [RapidCompile.Win32API]::SetForegroundWindow($TargetWindow)
    
    Write-DebugLog "Unity activation result: $result"
    return $result
}

function Send-CompileRefresh {
    Write-DebugLog "Sending Ctrl+R to force Unity refresh"
    
    # Ctrl down
    [RapidCompile.Win32API]::keybd_event([RapidCompile.Win32API]::VK_CONTROL, 0, 0, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 50
    
    # R down and up
    [RapidCompile.Win32API]::keybd_event([RapidCompile.Win32API]::VK_R, 0, 0, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 50
    [RapidCompile.Win32API]::keybd_event([RapidCompile.Win32API]::VK_R, 0, [RapidCompile.Win32API]::KEYEVENTF_KEYUP, [IntPtr]::Zero)
    
    # Ctrl up
    [RapidCompile.Win32API]::keybd_event([RapidCompile.Win32API]::VK_CONTROL, 0, [RapidCompile.Win32API]::KEYEVENTF_KEYUP, [IntPtr]::Zero)
    
    Write-DebugLog "Ctrl+R sent"
}

function Get-ErrorLogPath {
    if ($ErrorLogPath) {
        return $ErrorLogPath
    }
    
    # Find Unity project Assets folder
    $unityProjects = @(
        "C:\UnityProjects\Sound-and-Shoal\Dithering\Assets\Editor.log",
        ".\Dithering\Assets\Editor.log",
        "..\Dithering\Assets\Editor.log"
    )
    
    foreach ($path in $unityProjects) {
        if (Test-Path $path) {
            Write-DebugLog "Found error log at: $path"
            return $path
        }
    }
    
    Write-DebugLog "No error log found, using default"
    return "C:\UnityProjects\Sound-and-Shoal\Dithering\Assets\Editor.log"
}

function Wait-ForErrorExport {
    param([int]$WaitTime)
    
    $errorPath = Get-ErrorLogPath
    Write-DebugLog "Waiting ${WaitTime}ms for error export to: $errorPath"
    
    # Check initial modification time
    $initialTime = if (Test-Path $errorPath) {
        (Get-Item $errorPath).LastWriteTime
    } else {
        [DateTime]::MinValue
    }
    
    # Wait for ConsoleErrorExporter to run
    Start-Sleep -Milliseconds $WaitTime
    
    # Check if file was updated
    if (Test-Path $errorPath) {
        $newTime = (Get-Item $errorPath).LastWriteTime
        if ($newTime -gt $initialTime) {
            Write-DebugLog "Error log updated at: $newTime"
            return $true
        }
    }
    
    Write-DebugLog "Error log not updated during wait period"
    return $false
}

function Invoke-RapidUnityCompile {
    $totalStopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    # Step 1: Store current window
    Write-DebugLog "Step 1: Getting current window"
    $originalWindow = [RapidCompile.Win32API]::GetForegroundWindow()
    $originalInfo = Get-WindowInfo -WindowHandle $originalWindow
    Write-DebugLog "Original window: $($originalInfo.Title)"
    
    # Step 2: Find Unity window
    Write-DebugLog "Step 2: Finding Unity window"
    $unityInfo = Find-UnityWindow -ProjectName $ProjectName
    
    if (-not $unityInfo) {
        Write-Error "Unity window not found. Is Unity running with the '$ProjectName' project?"
        return @{
            Success = $false
            Error = "Unity window not found"
        }
    }
    
    # Step 3: Block input if requested
    if ($BlockInput) {
        Write-DebugLog "Step 3: Blocking user input"
        Block-UserInput -Block $true
    }
    
    try {
        # Step 4: Switch to Unity
        Write-DebugLog "Step 4: Switching to Unity"
        $switchTime = [System.Diagnostics.Stopwatch]::StartNew()
        $activated = Activate-UnityWindow -TargetWindow $unityInfo.Handle
        $switchTime.Stop()
        
        if (-not $activated) {
            throw "Failed to activate Unity window"
        }
        
        # Step 5: Force compilation if requested
        if ($ForceCompile) {
            Write-DebugLog "Step 5: Forcing compilation with Ctrl+R"
            Send-CompileRefresh
        }
        
        # Step 6: Wait for compilation and error export
        Write-DebugLog "Step 6: Waiting for compilation and error export"
        $exportUpdated = Wait-ForErrorExport -WaitTime $CompileWaitTime
        
        # Step 7: Switch back to original window
        Write-DebugLog "Step 7: Switching back to original window"
        $returnTime = [System.Diagnostics.Stopwatch]::StartNew()
        Activate-UnityWindow -TargetWindow $originalWindow
        $returnTime.Stop()
        
        # Step 8: Check final state
        Start-Sleep -Milliseconds 50
        $finalWindow = [RapidCompile.Win32API]::GetForegroundWindow()
        $returnedCorrectly = $finalWindow -eq $originalWindow
        
        Write-DebugLog "Returned to original window: $returnedCorrectly"
        
    } finally {
        # Always unblock input
        if ($BlockInput) {
            Write-DebugLog "Unblocking user input"
            Block-UserInput -Block $false
        }
    }
    
    $totalStopwatch.Stop()
    
    # Read error log if it exists
    $errorPath = Get-ErrorLogPath
    $errorContent = $null
    $errorCount = 0
    
    if (Test-Path $errorPath) {
        $errorContent = Get-Content $errorPath -Raw
        # Count compilation errors
        $errorMatches = [regex]::Matches($errorContent, "error CS\d+")
        $errorCount = $errorMatches.Count
        Write-DebugLog "Found $errorCount compilation errors"
    }
    
    # Build result
    $result = @{
        Success = $activated -and $returnedCorrectly
        UnityActivated = $activated
        ReturnedCorrectly = $returnedCorrectly
        ErrorLogUpdated = $exportUpdated
        ErrorCount = $errorCount
        ErrorLogPath = $errorPath
        TimingMs = @{
            Total = $totalStopwatch.Elapsed.TotalMilliseconds
            Switch = $switchTime.Elapsed.TotalMilliseconds
            CompileWait = $CompileWaitTime
            Return = $returnTime.Elapsed.TotalMilliseconds
        }
    }
    
    # Display results
    if ($Measure) {
        return $result
    } else {
        if ($result.Success) {
            Write-Host "`nRapid Unity compilation completed successfully!" -ForegroundColor Green
            Write-Host "  Total time: $([Math]::Round($result.TimingMs.Total, 0))ms" -ForegroundColor Gray
            Write-Host "  Errors found: $errorCount" -ForegroundColor $(if ($errorCount -gt 0) { "Red" } else { "Green" })
            if ($errorCount -gt 0) {
                Write-Host "  Error log: $errorPath" -ForegroundColor Yellow
            }
        } else {
            Write-Host "`nRapid Unity compilation had issues" -ForegroundColor Yellow
            if (-not $activated) {
                Write-Host "  - Failed to activate Unity window" -ForegroundColor Red
            }
            if (-not $returnedCorrectly) {
                Write-Host "  - Failed to return to original window" -ForegroundColor Red
            }
        }
    }
}

# Main execution
try {
    Write-DebugLog "Starting rapid Unity compilation"
    
    # Safety check for input blocking
    if ($BlockInput) {
        $response = Read-Host "WARNING: This will block keyboard and mouse input temporarily. Continue? (Y/N)"
        if ($response -ne 'Y') {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
            return
        }
    }
    
    $result = Invoke-RapidUnityCompile
    
    if ($Measure) {
        Write-DebugLog "Returning detailed measurements"
        return $result
    }
    
    Write-DebugLog "=== Invoke-RapidUnityCompile Completed ==="
    
} catch {
    Write-DebugLog "ERROR: $($_.Exception.Message)"
    Write-Error $_
    
    # Emergency unblock
    if ($BlockInput) {
        try {
            [RapidCompile.Win32API]::BlockInput($false)
            Write-Host "Emergency input unblock executed" -ForegroundColor Yellow
        } catch {}
    }
    
    throw
} finally {
    Write-DebugLog "=== Script Execution Ended ==="
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvKc5kIqjdzyl9N7oQiN788co
# WaKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUcB20eFBS/zqZRYWTGKbr4gJnM5wwDQYJKoZIhvcNAQEBBQAEggEAkhA9
# Au53BCVzzdXOQVW70R+LpNVP8eizplwfme85/qMT108F3Jw70DlHyWAISIjHfs42
# iqUi3+DsFthiY8B7+ujSbS2D4rxksVdQtWRfbUVfF/Yeauyr+tD4ItADupLqIKPf
# s2nJMGGOozBFdFruw++lsmy4bsIvKg6k5oPzUTj2JzJh5DFsEtDUfxWV/8lLiATO
# MdwfUDDKvBM8V6Y7nCKYjWDmqCK7L1NvucoWJs8MdZdz47y8YSjjAZScXGOVA+1b
# uR+2N0llt9Zvnaw6YVu0tGFzq6XQ0slWD3KUtIs/SoywLJne2oohWoJXAH34LFQG
# FgOw7gDwKROPAgxjxQ==
# SIG # End signature block
