# Auto-Yes.ps1
# Simple auto-approval script - sends 'y + Enter' every 2 seconds

Write-Host @"
================================================================================
AUTO-YES FOR CLAUDE
================================================================================
This script will send 'y + Enter' every 2 seconds to approve Claude prompts.

HOW TO USE:
1. Start this script in a SEPARATE PowerShell window
2. Go back to your Claude Code CLI window  
3. When Claude asks for permission, it will be auto-approved

WARNING: This approves EVERYTHING. Use with caution!

Press Ctrl+C to stop
================================================================================
"@ -ForegroundColor Yellow

Add-Type -AssemblyName System.Windows.Forms

$count = 0
Write-Host "`nStarting auto-approval..." -ForegroundColor Green

while ($true) {
    # Send y + Enter
    [System.Windows.Forms.SendKeys]::SendWait("y")
    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    
    $count++
    Write-Host "Approval sent #$count at $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor DarkGreen
    
    Start-Sleep -Seconds 2
}