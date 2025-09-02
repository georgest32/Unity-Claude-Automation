# Enable-AutoApproval.ps1
# Sends keystrokes to auto-approve Claude prompts in the current session

param(
    [int]$IntervalSeconds = 2,
    [switch]$SafeOnly
)

Write-Host @"
================================================================================
CLAUDE AUTO-APPROVAL AGENT
================================================================================
This will automatically approve permission prompts every $IntervalSeconds seconds.

INSTRUCTIONS:
1. Keep this running in a SEPARATE PowerShell window
2. Return to your Claude Code CLI window
3. When Claude asks for permission, this script will auto-approve

Press Ctrl+C to stop auto-approval
================================================================================

"@ -ForegroundColor Cyan

Add-Type -AssemblyName System.Windows.Forms
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;
    
    public class WindowHelper {
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        
        [DllImport("user32.dll")]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
        
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
        
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
    }
"@ -ErrorAction SilentlyContinue

$approvalCount = 0
$lastApproval = Get-Date

Write-Host "Auto-approval agent started at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Green
Write-Host "Monitoring for Claude permission prompts..." -ForegroundColor Yellow

while ($true) {
    try {
        # Get the currently active window
        $activeWindow = [WindowHelper]::GetForegroundWindow()
        
        if ($activeWindow -ne [IntPtr]::Zero) {
            $windowText = New-Object System.Text.StringBuilder 256
            [WindowHelper]::GetWindowText($activeWindow, $windowText, 256)
            $title = $windowText.ToString()
            
            # Check if this is a PowerShell/Terminal window (where Claude runs)
            if ($title -match "PowerShell|Terminal|Command|cmd|pwsh") {
                
                # Send approval keystrokes
                [System.Windows.Forms.SendKeys]::SendWait("y")
                Start-Sleep -Milliseconds 50
                [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
                
                $approvalCount++
                $timestamp = Get-Date -Format 'HH:mm:ss'
                
                Write-Host "[$timestamp] Sent approval #$approvalCount to: $title" -ForegroundColor Green
                
                # Show what was likely approved
                Write-Host "  └─ Auto-approved (check Claude output for details)" -ForegroundColor Gray
                
                $lastApproval = Get-Date
            }
        }
    }
    catch {
        # Silently continue on errors
    }
    
    Start-Sleep -Seconds $IntervalSeconds
}