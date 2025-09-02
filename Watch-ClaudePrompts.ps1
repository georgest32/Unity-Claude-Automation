# Watch-ClaudePrompts.ps1
# Watches for Claude permission prompts and auto-responds

param(
    [switch]$AutoApprove,
    [string[]]$SafeCommands = @('git status', 'git diff', 'ls', 'pwd', 'dir', 'Get-ChildItem', 'Get-Location')
)

Write-Host @"
========================================
Claude Permission Auto-Responder
========================================
This script will monitor and auto-respond to permission prompts.
Safe commands will be auto-approved.

Safe commands:
$($SafeCommands -join "`n  ")

Press Ctrl+C to stop monitoring.
========================================

"@ -ForegroundColor Cyan

# Import Windows Forms for sending keystrokes
Add-Type -AssemblyName System.Windows.Forms

# Keep track of last response time to avoid duplicates
$lastResponseTime = Get-Date
$cooldownSeconds = 2

while ($true) {
    try {
        # Get the current active window
        $activeWindow = Get-Process | Where-Object { $_.MainWindowHandle -ne 0 } | 
            Where-Object { $_.MainWindowTitle -ne "" } |
            Sort-Object -Property StartTime -Descending |
            Select-Object -First 1
        
        if ($activeWindow) {
            $title = $activeWindow.MainWindowTitle
            
            # Check if this looks like a PowerShell/Terminal window
            if ($title -match "PowerShell|pwsh|Terminal|Claude") {
                
                # Check time since last response
                $timeSinceLastResponse = (Get-Date) - $lastResponseTime
                
                if ($timeSinceLastResponse.TotalSeconds -gt $cooldownSeconds) {
                    
                    # This is a heuristic - we assume if the terminal window is active
                    # and hasn't had input for a bit, it might be waiting for permission
                    
                    if ($AutoApprove) {
                        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Active window: $title" -ForegroundColor Gray
                        Write-Host "  Sending auto-approval (y + Enter)..." -ForegroundColor Green
                        
                        # Send 'y' and Enter
                        [System.Windows.Forms.SendKeys]::SendWait("y")
                        Start-Sleep -Milliseconds 50
                        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
                        
                        $lastResponseTime = Get-Date
                        Write-Host "  ✅ Sent approval" -ForegroundColor Green
                    }
                }
            }
        }
    }
    catch {
        Write-Warning "Error in monitoring: $_"
    }
    
    # Check every second
    Start-Sleep -Seconds 1
}