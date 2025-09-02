# Ensure WindowAPI type is available
if (-not ([System.Management.Automation.PSTypeName]'WindowAPI').Type) {
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
    public static extern bool BringWindowToTop(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    
    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
    
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
}

# Load required assemblies
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue

function Submit-ToClaudeViaTypeKeys {
    <#
    .SYNOPSIS
        Submits prompt to Claude via TypeKeys with input locking and safety measures
        
    .DESCRIPTION
        Provides secure prompt submission with user abort capability, window validation,
        and input blocking to prevent interference during submission
        
    .PARAMETER PromptText
        The text prompt to submit to Claude
        
    .OUTPUTS
        Boolean - True if submission was successful, False otherwise
        
    .EXAMPLE
        $success = Submit-ToClaudeViaTypeKeys -PromptText "Analyze this code"
    #>
    [CmdletBinding()]
    param([string]$PromptText)
    
    Write-Host ""
    Write-Host "[SUBMISSION] Preparing to submit to Claude Code CLI..." -ForegroundColor Cyan
    Write-Host "  Press Ctrl+C within 3 seconds to abort submission..." -ForegroundColor Yellow
    
    # Abort window - give user chance to cancel
    for ($i = 3; $i -gt 0; $i--) {
        Write-Host "  Starting in $i seconds... (Ctrl+C to abort)" -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }
    
    try {
        # Find Claude window using available function
        $claudeWindow = $null
        
        # Try to use available window functions
        if (Get-Command Get-ClaudeWindowInfo -ErrorAction SilentlyContinue) {
            Write-Host "  Using Get-ClaudeWindowInfo to find NUGGETRON..." -ForegroundColor Gray
            $claudeWindowInfo = Get-ClaudeWindowInfo
            if ($claudeWindowInfo -and $claudeWindowInfo.WindowHandle) {
                $claudeWindow = $claudeWindowInfo.WindowHandle
            }
        } elseif (Get-Command Find-ClaudeWindow -ErrorAction SilentlyContinue) {
            Write-Host "  Using Find-ClaudeWindow..." -ForegroundColor Gray
            $result = Find-ClaudeWindow
            if ($result -and $result.WindowHandle) {
                $claudeWindow = $result.WindowHandle
            } elseif ($result) {
                # Simple module returns different format
                $claudeWindow = $result
            }
        }
        
        if (-not $claudeWindow) {
            Write-Host "  Failed to find Claude Code CLI window!" -ForegroundColor Red
            Write-Host "  Please ensure NUGGETRON window is registered" -ForegroundColor Yellow
            return $false
        }
        
        # Switch to Claude window using available function
        Write-Host "  Switching to Claude window..." -ForegroundColor Gray
        $switched = $false
        
        if (Get-Command Switch-ToClaudeWindow -ErrorAction SilentlyContinue) {
            Write-Host "  Using Switch-ToClaudeWindow..." -ForegroundColor Gray
            # Switch-ToClaudeWindow expects a hashtable with window info
            $windowInfo = @{
                WindowHandle = $claudeWindow
                ProcessId = 0  # Will be populated if available
                WindowTitle = "NUGGETRON"
                Source = "Submit-ToClaudeViaTypeKeys"
            }
            $switched = Switch-ToClaudeWindow -WindowInfo $windowInfo
        } elseif (Get-Command Switch-ToWindow -ErrorAction SilentlyContinue) {
            Write-Host "  Using Switch-ToWindow..." -ForegroundColor Gray
            $switched = Switch-ToWindow -WindowHandle $claudeWindow
        } else {
            Write-Host "  [WARNING] No window switching function available" -ForegroundColor Yellow
            Write-Host "  Attempting to continue anyway..." -ForegroundColor Yellow
            $switched = $true  # Try to continue
        }
        
        if (-not $switched) {
            Write-Host "  Failed to switch to Claude window!" -ForegroundColor Red
            return $false
        }
        
        Write-Host "  Window switch successful, preparing text submission..." -ForegroundColor Green
        
        # Save current cursor position
        $originalPos = [WindowAPI+POINT]::new()
        [WindowAPI]::GetCursorPos([ref]$originalPos) | Out-Null
        
        try {
            # NOTE: BlockInput would prevent SendKeys from working, so we don't use it
            # Instead we rely on window focus and quick operation
            Write-Host "  Preparing for submission..." -ForegroundColor Gray
            
            # Additional safety - capture input to Claude window
            [WindowAPI]::SetCapture($claudeWindow) | Out-Null
            
            # Short delay to ensure window focus is stable
            Start-Sleep -Milliseconds 500
            
            # Clear any existing content (Ctrl+A, Delete)
            Write-Host "  Clearing existing content..." -ForegroundColor Gray
            [System.Windows.Forms.SendKeys]::SendWait("^a")
            Start-Sleep -Milliseconds 100
            [System.Windows.Forms.SendKeys]::SendWait("{DELETE}")
            Start-Sleep -Milliseconds 200
            
            # FIXED: Use clipboard copy/paste to avoid line-by-line submission
            Write-Host "  Using clipboard paste method for reliable single-message submission..." -ForegroundColor Gray
            
            try {
                # Set prompt text to clipboard
                Set-Clipboard -Value $PromptText
                Write-Host "  Prompt copied to clipboard ($($PromptText.Length) characters)" -ForegroundColor Gray
                
                # Use Ctrl+V to paste entire prompt at once
                Write-Host "  Pasting complete prompt via Ctrl+V..." -ForegroundColor Gray
                [System.Windows.Forms.SendKeys]::SendWait("^v")
                
                # Longer delay to ensure paste completes and dialog appears
                Start-Sleep -Milliseconds 1000
                
            } catch {
                Write-Host "  WARNING: Clipboard paste failed, falling back to direct typing" -ForegroundColor Yellow
                Write-Host "  Error: $_" -ForegroundColor Yellow
                
                # Fallback: Type as single string (NO CHUNKING to prevent line-by-line)
                Write-Host "  Typing prompt as single message..." -ForegroundColor Gray
                
                # Escape special characters for SendKeys but keep as single operation
                $escapedText = $PromptText.Replace("{", "{{").Replace("}", "}}")
                $escapedText = $escapedText.Replace("+", "{{+}}").Replace("^", "{{^}}")
                $escapedText = $escapedText.Replace("%", "{{%}}").Replace("~", "{{~}}")
                $escapedText = $escapedText.Replace("(", "{{(}}").Replace(")", "{{)}}")
                $escapedText = $escapedText.Replace("[", "{{[}}").Replace("]", "{{]}}")
                
                # Remove newlines to prevent accidental submission during typing
                $escapedText = $escapedText -replace "`n", " " -replace "`r", ""
                
                # Type entire text as ONE operation
                [System.Windows.Forms.SendKeys]::SendWait($escapedText)
            }
            
            # Submit the prompt (Enter key)
            # IMPORTANT: First ENTER might be consumed by paste confirmation dialog
            Write-Host "  Submitting prompt (handling paste confirmation)..." -ForegroundColor Gray
            Start-Sleep -Milliseconds 800
            
            # First ENTER - might confirm paste dialog
            Write-Host "  Sending first ENTER (paste confirmation)..." -ForegroundColor Gray
            [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
            
            # Longer delay to ensure dialog is fully processed
            Start-Sleep -Milliseconds 1000
            
            # Second ENTER - actually submits the prompt
            Write-Host "  Sending second ENTER (submit prompt)..." -ForegroundColor Gray
            [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
            
            Write-Host "  Prompt submitted successfully!" -ForegroundColor Green
            return $true
            
        } finally {
            # Always restore capture even if something goes wrong
            Write-Host "  Restoring window state..." -ForegroundColor Gray
            
            try {
                [WindowAPI]::ReleaseCapture() | Out-Null
                
                # Restore cursor position
                [WindowAPI]::SetCursorPos($originalPos.X, $originalPos.Y) | Out-Null
                
            } catch {
                Write-Host "    Warning: Could not fully restore window state: $_" -ForegroundColor Yellow
            }
        }
        
    } catch {
        Write-Host "  ERROR in prompt submission: $_" -ForegroundColor Red
        
        # Emergency restoration
        try {
            [WindowAPI]::ReleaseCapture() | Out-Null
        } catch {
            Write-Host "    Warning: Could not release capture." -ForegroundColor Yellow
        }
        
        return $false
    }
}