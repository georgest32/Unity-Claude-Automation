# NUGGETRON Window Manager with Windows API Detection
# Uses P/Invoke for reliable window detection across security contexts

Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue

# Add Windows API definitions if not already loaded
if (-not ([System.Management.Automation.PSTypeName]'WindowHelper').Type) {
    Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
using System.Collections.Generic;

public class WindowHelper {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);
    
    [DllImport("user32.dll", CharSet = CharSet.Auto)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    
    [DllImport("user32.dll")]
    public static extern int GetWindowTextLength(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    
    [DllImport("user32.dll")]
    public static extern bool IsWindowVisible(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    
    [DllImport("user32.dll")]
    public static extern bool BringWindowToTop(IntPtr hWnd);
    
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);
    
    public static List<WindowInfo> GetAllWindows() {
        List<WindowInfo> windows = new List<WindowInfo>();
        
        EnumWindows(delegate(IntPtr hWnd, IntPtr lParam) {
            if (IsWindowVisible(hWnd)) {
                int length = GetWindowTextLength(hWnd);
                if (length > 0) {
                    StringBuilder sb = new StringBuilder(length + 1);
                    GetWindowText(hWnd, sb, sb.Capacity);
                    
                    uint processId;
                    GetWindowThreadProcessId(hWnd, out processId);
                    
                    windows.Add(new WindowInfo {
                        Handle = hWnd,
                        Title = sb.ToString(),
                        ProcessId = (int)processId
                    });
                }
            }
            return true;
        }, IntPtr.Zero);
        
        return windows;
    }
}

public class WindowInfo {
    public IntPtr Handle { get; set; }
    public string Title { get; set; }
    public int ProcessId { get; set; }
}
"@
}

function Get-ClaudeWindowInfo {
    [CmdletBinding()]
    param()
    
    Write-Host "  Using Windows API to find NUGGETRON..." -ForegroundColor Cyan
    
    try {
        # Get all windows using Windows API
        $allWindows = [WindowHelper]::GetAllWindows()
        
        # Find NUGGETRON
        $nuggetronWindow = $allWindows | Where-Object { $_.Title -like "*NUGGETRON*" } | Select-Object -First 1
        
        if ($nuggetronWindow) {
            Write-Host "    [OK] FOUND NUGGETRON via Windows API!" -ForegroundColor Green
            Write-Host "    Title: '$($nuggetronWindow.Title)'" -ForegroundColor Gray
            Write-Host "    ProcessId: $($nuggetronWindow.ProcessId)" -ForegroundColor Gray
            Write-Host "    Handle: $($nuggetronWindow.Handle)" -ForegroundColor Gray
            
            # Verify process exists
            $proc = Get-Process -Id $nuggetronWindow.ProcessId -ErrorAction SilentlyContinue
            if ($proc) {
                Write-Host "    Process: $($proc.ProcessName)" -ForegroundColor Gray
                
                # Update protected registration
                Update-ProtectedRegistration -ProcessId $nuggetronWindow.ProcessId `
                                            -WindowHandle $nuggetronWindow.Handle `
                                            -WindowTitle $nuggetronWindow.Title `
                                            -ProcessName $proc.ProcessName
                
                return @{
                    ProcessId = $nuggetronWindow.ProcessId
                    WindowHandle = [int64]$nuggetronWindow.Handle
                    WindowTitle = $nuggetronWindow.Title
                    ProcessName = $proc.ProcessName
                    Source = "WindowsAPI"
                }
            } else {
                Write-Host "    [WARNING] Process no longer exists" -ForegroundColor Yellow
            }
        }
        
        # Fallback: Check protected registration file
        $protectedRegPath = ".\.nuggetron_registration.json"
        if (Test-Path $protectedRegPath) {
            Write-Host "    Checking protected registration as fallback..." -ForegroundColor Gray
            $protectedReg = Get-Content $protectedRegPath -Raw | ConvertFrom-Json
            if ($protectedReg.ProcessId) {
                $proc = Get-Process -Id $protectedReg.ProcessId -ErrorAction SilentlyContinue
                if ($proc) {
                    Write-Host "    [WARNING] Process exists but Windows API doesn't see NUGGETRON" -ForegroundColor Yellow
                    Write-Host "    Using registration data..." -ForegroundColor Yellow
                    return @{
                        ProcessId = $protectedReg.ProcessId
                        WindowHandle = [int64]$protectedReg.WindowHandle
                        WindowTitle = $protectedReg.WindowTitle
                        ProcessName = $protectedReg.ProcessName
                        Source = "ProtectedRegistration"
                    }
                }
            }
        }
        
        # Not found - show all windows
        Write-Host "    [ERROR] NUGGETRON window not found!" -ForegroundColor Red
        Write-Host "    All visible windows (via Windows API):" -ForegroundColor Yellow
        $windowCount = 0
        foreach ($window in $allWindows) {
            if ($window.Title -and $windowCount -lt 10) {
                Write-Host "      - PID $($window.ProcessId): '$($window.Title)'" -ForegroundColor Gray
                $windowCount++
            }
        }
        if ($allWindows.Count -gt 10) {
            Write-Host "      ... and $($allWindows.Count - 10) more windows" -ForegroundColor Gray
        }
        
        return $null
    }
    catch {
        Write-Host "  [ERROR] Windows API detection failed: $_" -ForegroundColor Red
        return $null
    }
}

function Update-ProtectedRegistration {
    [CmdletBinding()]
    param(
        [int]$ProcessId,
        [IntPtr]$WindowHandle,
        [string]$WindowTitle,
        [string]$ProcessName
    )
    
    # Update protected registration file
    $protectedRegPath = ".\.nuggetron_registration.json"
    $nuggetronInfo = @{
        ProcessId = $ProcessId
        WindowHandle = [int64]$WindowHandle
        WindowTitle = $WindowTitle
        UniqueIdentifier = '**NUGGETRON**'
        ProcessName = $ProcessName
        RegisteredAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        IsNuggetron = $true
        Protected = $true
        Note = "DO NOT DELETE - This is the Claude CLI window registration"
    }
    
    try {
        $nuggetronInfo | ConvertTo-Json -Depth 10 | Set-Content $protectedRegPath -Encoding UTF8
        Write-Host "    Protected registration updated" -ForegroundColor Gray
    }
    catch {
        Write-Host "    Warning: Could not update protected registration" -ForegroundColor Yellow
    }
}

function Update-ClaudeWindowInfo {
    [CmdletBinding()]
    param(
        [IntPtr]$WindowHandle,
        [int]$ProcessId,
        [string]$WindowTitle,
        [string]$ProcessName
    )
    
    # This function is kept for compatibility but now updates protected registration
    Update-ProtectedRegistration -ProcessId $ProcessId `
                                -WindowHandle $WindowHandle `
                                -WindowTitle $WindowTitle `
                                -ProcessName $ProcessName
}

function Switch-ToClaudeWindow {
    [CmdletBinding()]
    param(
        [hashtable]$WindowInfo
    )
    
    if (-not $WindowInfo) {
        Write-Host "  [ERROR] No NUGGETRON window info provided" -ForegroundColor Red
        return $false
    }
    
    # Debug: Show what we received
    Write-Host "  Window Info received:" -ForegroundColor Gray
    Write-Host "    ProcessId: $($WindowInfo.ProcessId)" -ForegroundColor Gray
    Write-Host "    WindowHandle: $($WindowInfo.WindowHandle)" -ForegroundColor Gray
    Write-Host "    WindowTitle: $($WindowInfo.WindowTitle)" -ForegroundColor Gray
    Write-Host "    Source: $($WindowInfo.Source)" -ForegroundColor Gray
    
    if (-not $WindowInfo.WindowHandle -and $WindowInfo.WindowHandle -ne 0) {
        Write-Host "  [ERROR] No valid window handle provided" -ForegroundColor Red
        return $false
    }
    
    Write-Host "  Switching to NUGGETRON window (from: $($WindowInfo.Source))..." -ForegroundColor Cyan
    
    try {
        $handle = [IntPtr]$WindowInfo.WindowHandle
        Write-Host "  Attempting to switch to window handle: $handle" -ForegroundColor Gray
        
        # Try to get available methods
        $methods = [WindowHelper] | Get-Member -Static -MemberType Method | Select-Object -ExpandProperty Name
        Write-Host "  Available WindowHelper methods: $($methods -join ', ')" -ForegroundColor Gray
        
        # Use System.Windows.Forms methods as fallback if WindowHelper methods fail
        try {
            [WindowHelper]::ShowWindow($handle, 9) | Out-Null  # SW_RESTORE
            [WindowHelper]::BringWindowToTop($handle) | Out-Null
            [WindowHelper]::SetForegroundWindow($handle) | Out-Null
            Write-Host "  Used WindowHelper methods successfully" -ForegroundColor Gray
        }
        catch {
            Write-Host "  WindowHelper methods failed, trying alternative approach: $_" -ForegroundColor Yellow
            # Alternative: Use Add-Type for individual methods
            Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WindowSwitcher {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern bool BringWindowToTop(IntPtr hWnd);
}
"@ -ErrorAction SilentlyContinue
            
            [WindowSwitcher]::ShowWindow($handle, 9) | Out-Null
            [WindowSwitcher]::BringWindowToTop($handle) | Out-Null
            [WindowSwitcher]::SetForegroundWindow($handle) | Out-Null
            Write-Host "  Used WindowSwitcher methods successfully" -ForegroundColor Gray
        }
        
        Start-Sleep -Milliseconds 500
        Write-Host "  [OK] Switched to NUGGETRON successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  [ERROR] Failed to switch: $_" -ForegroundColor Red
        return $false
    }
}

function Submit-ToClaudeWindow {
    [CmdletBinding()]
    param(
        [string]$Text
    )
    
    Write-Host "[SUBMISSION] Preparing to submit to NUGGETRON..." -ForegroundColor Cyan
    
    # Find NUGGETRON
    $windowInfo = Get-ClaudeWindowInfo
    if (-not $windowInfo) {
        Write-Host "[ERROR] Cannot find NUGGETRON window" -ForegroundColor Red
        Write-Host "Please run .\Register-NUGGETRON-Protected.ps1 in your Claude terminal" -ForegroundColor Yellow
        return $false
    }
    
    # Switch to window
    if (-not (Switch-ToClaudeWindow -WindowInfo $windowInfo)) {
        Write-Host "[ERROR] Failed to switch to NUGGETRON" -ForegroundColor Red
        return $false
    }
    
    Write-Host "  Typing text into NUGGETRON..." -ForegroundColor Cyan
    
    try {
        # Clear any existing content
        [System.Windows.Forms.SendKeys]::SendWait("^a")
        Start-Sleep -Milliseconds 100
        [System.Windows.Forms.SendKeys]::SendWait("{DEL}")
        Start-Sleep -Milliseconds 100
        
        # ENHANCED: Use clipboard paste method to avoid line-by-line submission
        Write-Host "  Using clipboard paste method for reliable single-message submission..." -ForegroundColor Green
        
        try {
            # Set complete text to clipboard (preserves original formatting)
            Set-Clipboard -Value $Text
            Write-Host "  Text copied to clipboard ($($Text.Length) characters)" -ForegroundColor Gray
            
            # Use Ctrl+V to paste entire text at once
            Write-Host "  Pasting complete text via Ctrl+V..." -ForegroundColor Gray
            [System.Windows.Forms.SendKeys]::SendWait("^v")
            
            # Brief delay to ensure paste completes
            Start-Sleep -Milliseconds 300
            
        } catch {
            Write-Host "  WARNING: Clipboard paste failed, falling back to direct typing" -ForegroundColor Yellow
            Write-Host "  Error: $_" -ForegroundColor Yellow
            
            # Fallback: Remove newlines and type as single operation (NO CHUNKING)
            $cleanText = $Text -replace "`n", " " -replace "`r", ""
            Write-Host "  Fallback: Typing as single message ($($cleanText.Length) chars)" -ForegroundColor Gray
            
            # Escape special characters for SendKeys but keep as single operation
            $escapedText = $cleanText -replace '([+^%~(){}])', '{$1}'
            $escapedText = $escapedText -replace '\[', '{[}'
            $escapedText = $escapedText -replace '\]', '{]}'
            
            # Type entire text as ONE operation
            [System.Windows.Forms.SendKeys]::SendWait($escapedText)
            Start-Sleep -Milliseconds 200
        }
        
        # CRITICAL: Send ENTER to actually submit the prompt!
        Write-Host "  Sending ENTER to submit prompt..." -ForegroundColor Yellow
        Start-Sleep -Milliseconds 500  # Brief pause before Enter
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        Start-Sleep -Milliseconds 500  # Brief pause after Enter
        
        Write-Host "  [OK] Text submitted to NUGGETRON with ENTER!" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "  [ERROR] Error submitting: $_" -ForegroundColor Red
        return $false
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Get-ClaudeWindowInfo',
    'Update-ClaudeWindowInfo', 
    'Update-ProtectedRegistration',
    'Switch-ToClaudeWindow',
    'Submit-ToClaudeWindow'
)