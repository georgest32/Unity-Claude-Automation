#region WindowManager Component
<#
.SYNOPSIS
    Unity-Claude CLI Orchestrator - Window Management Component (ENHANCED WITH LOGGING)
    
.DESCRIPTION
    Manages Claude Code CLI window detection, switching, and information tracking.
    Provides reliable window management with multiple detection methods and system
    status integration. ENHANCED VERSION WITH COMPREHENSIVE DEBUGGING.
#>
#endregion

# Add Windows API functions for reliable window switching and input blocking
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

# Load required assemblies for SendKeys functionality
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue

function Update-ClaudeWindowInfo {
    [CmdletBinding()]
    param(
        [IntPtr]$WindowHandle,
        [int]$ProcessId, 
        [string]$WindowTitle,
        [string]$ProcessName
    )
    
    Write-Host "[WINDOW-UPDATE] Updating Claude window info in system_status.json..." -ForegroundColor Cyan
    Write-Host "[WINDOW-UPDATE]   - ProcessId: $ProcessId" -ForegroundColor Gray
    Write-Host "[WINDOW-UPDATE]   - WindowHandle: $WindowHandle" -ForegroundColor Gray
    Write-Host "[WINDOW-UPDATE]   - WindowTitle: '$WindowTitle'" -ForegroundColor Gray
    Write-Host "[WINDOW-UPDATE]   - ProcessName: $ProcessName" -ForegroundColor Gray
    
    try {
        $systemStatusPath = ".\system_status.json"
        $systemStatus = @{}
        
        # Load existing status or create new
        if (Test-Path $systemStatusPath) {
            $systemStatus = Get-Content $systemStatusPath -Raw | ConvertFrom-Json -AsHashtable
        }
        
        # Ensure structure exists
        if (-not $systemStatus.SystemInfo) { $systemStatus.SystemInfo = @{} }
        if (-not $systemStatus.SystemInfo.ClaudeCodeCLI) { $systemStatus.SystemInfo.ClaudeCodeCLI = @{} }
        
        # Update Claude window information
        $systemStatus.SystemInfo.ClaudeCodeCLI.ProcessId = $ProcessId
        $systemStatus.SystemInfo.ClaudeCodeCLI.WindowHandle = [int64]$WindowHandle
        $systemStatus.SystemInfo.ClaudeCodeCLI.WindowTitle = $WindowTitle
        $systemStatus.SystemInfo.ClaudeCodeCLI.ProcessName = $ProcessName
        $systemStatus.SystemInfo.ClaudeCodeCLI.LastDetected = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        $systemStatus.SystemInfo.ClaudeCodeCLI.DetectionMethod = "AutonomousAgent"
        
        # Save back to file
        $systemStatus | ConvertTo-Json -Depth 10 | Set-Content $systemStatusPath -Encoding UTF8
        
        Write-Host "[WINDOW-UPDATE] ✅ Claude window info updated successfully" -ForegroundColor Green
        
    } catch {
        Write-Host "[WINDOW-UPDATE] ❌ Could not update system_status.json: $_" -ForegroundColor Red
    }
}

function Find-ClaudeWindow {
    [CmdletBinding()]
    param()
    
    Write-Host "`n[WINDOW-FIND] ========================================" -ForegroundColor Magenta
    Write-Host "[WINDOW-FIND] STARTING CLAUDE WINDOW DETECTION" -ForegroundColor Magenta
    Write-Host "[WINDOW-FIND] ========================================" -ForegroundColor Magenta
    Write-Host "[WINDOW-FIND] Current PID: $PID" -ForegroundColor Cyan
    Write-Host "[WINDOW-FIND] Current Title: '$($host.UI.RawUI.WindowTitle)'" -ForegroundColor Cyan
    
    # Method 1: Check system_status.json for comprehensive window info
    $systemStatusPath = ".\system_status.json"
    Write-Host "[WINDOW-FIND] Method 1: Checking system_status.json..." -ForegroundColor Yellow
    
    if (Test-Path $systemStatusPath) {
        try {
            $systemStatus = Get-Content $systemStatusPath -Raw | ConvertFrom-Json
            Write-Host "[WINDOW-FIND] Successfully loaded system_status.json" -ForegroundColor Green
            
            $claudeInfo = $systemStatus.SystemInfo.ClaudeCodeCLI
            
            if ($claudeInfo) {
                Write-Host "[WINDOW-FIND] Found ClaudeCodeCLI section:" -ForegroundColor Green
                Write-Host "[WINDOW-FIND]   - ProcessId: $($claudeInfo.ProcessId)" -ForegroundColor Gray
                Write-Host "[WINDOW-FIND]   - WindowTitle: '$($claudeInfo.WindowTitle)'" -ForegroundColor Gray
                Write-Host "[WINDOW-FIND]   - UniqueIdentifier: '$($claudeInfo.UniqueIdentifier)'" -ForegroundColor Gray
                Write-Host "[WINDOW-FIND]   - IsClaudeCodeCLI: $($claudeInfo.IsClaudeCodeCLI)" -ForegroundColor Gray
                
                # PRIORITY 1: Check for unique identifier (most reliable)
                if ($claudeInfo.UniqueIdentifier) {
                    Write-Host "[WINDOW-FIND] PRIORITY 1: Looking for unique identifier: '$($claudeInfo.UniqueIdentifier)'" -ForegroundColor Cyan
                    
                    # Get ALL processes to debug
                    $allProcesses = Get-Process | Where-Object { $_.MainWindowHandle -ne 0 }
                    Write-Host "[WINDOW-FIND] Total processes with windows: $($allProcesses.Count)" -ForegroundColor Gray
                    
                    # List all for debugging
                    Write-Host "[WINDOW-FIND] All available windows:" -ForegroundColor DarkGray
                    foreach ($proc in $allProcesses) {
                        $marker = if ($proc.Id -eq $PID) { " <-- CURRENT PROCESS (EXCLUDING)" } else { "" }
                        Write-Host "[WINDOW-FIND]   - PID: $($proc.Id), Title: '$($proc.MainWindowTitle)'$marker" -ForegroundColor DarkGray
                    }
                    
                    # Search for exact match
                    $exactMatch = $allProcesses | Where-Object { 
                        $_.MainWindowTitle -eq $claudeInfo.UniqueIdentifier -and
                        $_.Id -ne $PID  # Exclude self
                    }
                    
                    if ($exactMatch) {
                        $proc = $exactMatch[0]
                        Write-Host "[WINDOW-FIND] ✅ SUCCESS: Found exact unique identifier match!" -ForegroundColor Green
                        Write-Host "[WINDOW-FIND]   - PID: $($proc.Id)" -ForegroundColor Green
                        Write-Host "[WINDOW-FIND]   - Title: '$($proc.MainWindowTitle)'" -ForegroundColor Green
                        Write-Host "[WINDOW-FIND]   - Handle: $($proc.MainWindowHandle)" -ForegroundColor Green
                        Write-Host "[WINDOW-FIND] ========================================" -ForegroundColor Magenta
                        return $proc.MainWindowHandle
                    } else {
                        Write-Host "[WINDOW-FIND] ❌ No exact match for unique identifier" -ForegroundColor Red
                    }
                    
                    # Also check for CLAUDE_CODE_CLI_TERMINAL pattern
                    Write-Host "[WINDOW-FIND] Checking for CLAUDE_CODE_CLI_TERMINAL_* pattern..." -ForegroundColor Yellow
                    $patternProcesses = $allProcesses | Where-Object { 
                        $_.MainWindowTitle -like "CLAUDE_CODE_CLI_TERMINAL_*" -and
                        $_.Id -ne $PID  # Exclude self
                    }
                    
                    if ($patternProcesses) {
                        $proc = $patternProcesses[0]
                        Write-Host "[WINDOW-FIND] ✅ SUCCESS: Found pattern match!" -ForegroundColor Green
                        Write-Host "[WINDOW-FIND]   - PID: $($proc.Id)" -ForegroundColor Green
                        Write-Host "[WINDOW-FIND]   - Title: '$($proc.MainWindowTitle)'" -ForegroundColor Green
                        Write-Host "[WINDOW-FIND]   - Handle: $($proc.MainWindowHandle)" -ForegroundColor Green
                        
                        # Update registration with new window
                        Update-ClaudeWindowInfo -WindowHandle $proc.MainWindowHandle -ProcessId $proc.Id -WindowTitle $proc.MainWindowTitle -ProcessName $proc.ProcessName
                        Write-Host "[WINDOW-FIND] ========================================" -ForegroundColor Magenta
                        return $proc.MainWindowHandle
                    } else {
                        Write-Host "[WINDOW-FIND] ❌ No pattern match found" -ForegroundColor Red
                    }
                }
                
                # PRIORITY 2: Check if registered window is NOT a subsystem
                if ($claudeInfo.ProcessId -and $claudeInfo.IsClaudeCodeCLI) {
                    $claudePID = $claudeInfo.ProcessId
                    Write-Host "[WINDOW-FIND] PRIORITY 2: Checking registered PID: $claudePID" -ForegroundColor Cyan
                    
                    # Skip if it's the current process
                    if ($claudePID -eq $PID) {
                        Write-Host "[WINDOW-FIND] ❌ Registered PID is current process - skipping" -ForegroundColor Red
                    } else {
                        $claudeProcess = Get-Process -Id $claudePID -ErrorAction SilentlyContinue
                        if ($claudeProcess -and $claudeProcess.MainWindowHandle -ne 0) {
                            Write-Host "[WINDOW-FIND] Process found with handle: $($claudeProcess.MainWindowHandle)" -ForegroundColor Gray
                            Write-Host "[WINDOW-FIND] Window title: '$($claudeProcess.MainWindowTitle)'" -ForegroundColor Gray
                            
                            # EXCLUDE subsystem windows
                            $excludePatterns = @("*Subsystem*", "*CLIOrchestrator*", "*SystemMonitoring*", "*NotificationIntegration*", "*AutonomousAgent*")
                            $isExcluded = $false
                            foreach ($pattern in $excludePatterns) {
                                if ($claudeProcess.MainWindowTitle -like $pattern) {
                                    Write-Host "[WINDOW-FIND] ❌ Window matches exclude pattern: $pattern" -ForegroundColor Red
                                    $isExcluded = $true
                                    break
                                }
                            }
                            
                            if (-not $isExcluded) {
                                Write-Host "[WINDOW-FIND] ✅ SUCCESS: Found valid non-subsystem Claude window!" -ForegroundColor Green
                                Write-Host "[WINDOW-FIND] ========================================" -ForegroundColor Magenta
                                return $claudeProcess.MainWindowHandle
                            }
                        } else {
                            Write-Host "[WINDOW-FIND] ❌ Process not found or has no window" -ForegroundColor Red
                        }
                    }
                }
            } else {
                Write-Host "[WINDOW-FIND] ❌ No ClaudeCodeCLI section in system_status.json" -ForegroundColor Red
            }
        } catch {
            Write-Host "[WINDOW-FIND] ❌ Error reading system_status.json: $_" -ForegroundColor Red
        }
    } else {
        Write-Host "[WINDOW-FIND] ❌ system_status.json not found" -ForegroundColor Red
    }
    
    Write-Host "[WINDOW-FIND] ❌ NO CLAUDE WINDOW FOUND!" -ForegroundColor Red
    Write-Host "[WINDOW-FIND] Please run Update-ClaudeWindowRegistration.ps1 in the Claude terminal" -ForegroundColor Yellow
    Write-Host "[WINDOW-FIND] ========================================" -ForegroundColor Magenta
    
    return $null
}

function Get-ClaudeWindowInfo {
    <#
    .SYNOPSIS
        Gets information about the Claude CLI window
    #>
    [CmdletBinding()]
    param()
    
    $handle = Find-ClaudeWindow
    if ($handle) {
        $proc = Get-Process | Where-Object { $_.MainWindowHandle -eq $handle }
        if ($proc) {
            return @{
                ProcessId = $proc.Id
                WindowHandle = $handle
                Title = $proc.MainWindowTitle
                ProcessName = $proc.ProcessName
            }
        }
    }
    return $null
}

function Switch-ToWindow {
    [CmdletBinding()]
    param([IntPtr]$WindowHandle)
    
    Write-Host "[WINDOW-SWITCH] Attempting to switch to window handle: $WindowHandle" -ForegroundColor Cyan
    
    if ($WindowHandle -eq 0 -or $WindowHandle -eq $null) {
        Write-Host "[WINDOW-SWITCH] ❌ Invalid window handle" -ForegroundColor Red
        return $false
    }
    
    try {
        # Get current foreground window
        $currentWindow = [WindowAPI]::GetForegroundWindow()
        Write-Host "[WINDOW-SWITCH] Current foreground window: $currentWindow" -ForegroundColor Gray
        
        # Show the window if minimized (4 = SW_RESTORE)
        [WindowAPI]::ShowWindowAsync($WindowHandle, 4) | Out-Null
        Start-Sleep -Milliseconds 100
        
        # Bring to top
        [WindowAPI]::BringWindowToTop($WindowHandle) | Out-Null
        Start-Sleep -Milliseconds 100
        
        # Set as foreground window
        $result = [WindowAPI]::SetForegroundWindow($WindowHandle)
        Write-Host "[WINDOW-SWITCH] SetForegroundWindow result: $result" -ForegroundColor Gray
        
        if (-not $result) {
            # If SetForegroundWindow fails, try AttachThreadInput trick
            Write-Host "[WINDOW-SWITCH] Using AttachThreadInput for window switching..." -ForegroundColor Yellow
            
            $currentThreadId = [WindowAPI]::GetCurrentThreadId()
            $targetProcessId = 0
            $targetThreadId = [WindowAPI]::GetWindowThreadProcessId($WindowHandle, [ref]$targetProcessId)
            
            Write-Host "[WINDOW-SWITCH] Current thread: $currentThreadId, Target thread: $targetThreadId" -ForegroundColor Gray
            
            if ($targetThreadId -ne 0 -and $currentThreadId -ne $targetThreadId) {
                [WindowAPI]::AttachThreadInput($currentThreadId, $targetThreadId, $true) | Out-Null
                [WindowAPI]::BringWindowToTop($WindowHandle) | Out-Null
                [WindowAPI]::SetForegroundWindow($WindowHandle) | Out-Null
                [WindowAPI]::AttachThreadInput($currentThreadId, $targetThreadId, $false) | Out-Null
                Write-Host "[WINDOW-SWITCH] ✅ AttachThreadInput completed" -ForegroundColor Green
            }
        } else {
            Write-Host "[WINDOW-SWITCH] ✅ Window switch successful" -ForegroundColor Green
        }
        
        Start-Sleep -Milliseconds 500
        return $true
    } catch {
        Write-Host "[WINDOW-SWITCH] ❌ Error switching window: $_" -ForegroundColor Red
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Update-ClaudeWindowInfo',
    'Find-ClaudeWindow',
    'Get-ClaudeWindowInfo', 
    'Switch-ToWindow'
)