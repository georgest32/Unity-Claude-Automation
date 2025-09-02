<#
.SYNOPSIS
    Sets the current PowerShell window title to identify it as the Claude Code CLI window
    
.DESCRIPTION
    This script sets the window title to help the CLI Orchestrator identify the correct
    window for sending commands to Claude Code CLI. Run this in the PowerShell window
    where you have Claude Code CLI running.
    
.EXAMPLE
    .\Set-ClaudeWindowTitle.ps1
    Sets the title to "Claude Code CLI environment"
    
.EXAMPLE
    .\Set-ClaudeWindowTitle.ps1 -Title "Claude Code CLI - Project X"
    Sets a custom title that includes "Claude Code CLI"
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Title = "Claude Code CLI environment"
)

# Ensure the title contains "Claude" for detection
if ($Title -notlike "*Claude*") {
    Write-Warning "Title should contain 'Claude' for proper detection. Adding it..."
    $Title = "Claude Code CLI - $Title"
}

# Set the window title
try {
    $host.UI.RawUI.WindowTitle = $Title
    Write-Host "✅ Window title set to: '$Title'" -ForegroundColor Green
    Write-Host ""
    Write-Host "This window will now be detected by the CLI Orchestrator." -ForegroundColor Cyan
    Write-Host ""
    
    # Also update system_status.json with this window's information
    $systemStatusPath = ".\system_status.json"
    if (Test-Path $systemStatusPath) {
        try {
            $systemStatus = Get-Content $systemStatusPath -Raw | ConvertFrom-Json -AsHashtable -ErrorAction SilentlyContinue
            if (-not $systemStatus) {
                $systemStatus = @{}
            }
            
            # Ensure structure exists
            if (-not $systemStatus.SystemInfo) { $systemStatus.SystemInfo = @{} }
            if (-not $systemStatus.SystemInfo.ClaudeCodeCLI) { $systemStatus.SystemInfo.ClaudeCodeCLI = @{} }
            
            # Update Claude window information
            $currentProcess = Get-Process -Id $PID
            $systemStatus.SystemInfo.ClaudeCodeCLI.ProcessId = $PID
            $systemStatus.SystemInfo.ClaudeCodeCLI.WindowTitle = $Title
            $systemStatus.SystemInfo.ClaudeCodeCLI.ProcessName = $currentProcess.ProcessName
            $systemStatus.SystemInfo.ClaudeCodeCLI.LastDetected = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
            $systemStatus.SystemInfo.ClaudeCodeCLI.DetectionMethod = "ManualSet"
            
            # Save back to file
            $systemStatus | ConvertTo-Json -Depth 10 | Set-Content $systemStatusPath -Encoding UTF8
            
            Write-Host "✅ Updated system_status.json with this window's information" -ForegroundColor Green
            Write-Host "   PID: $PID" -ForegroundColor Gray
            Write-Host "   Process: $($currentProcess.ProcessName)" -ForegroundColor Gray
            Write-Host ""
        }
        catch {
            Write-Warning "Could not update system_status.json: $_"
        }
    }
    
    Write-Host "You can now run the CLI Orchestrator and it will find this window." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "To verify detection, run:" -ForegroundColor Gray
    Write-Host "  Import-Module .\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psm1" -ForegroundColor DarkGray
    Write-Host "  Find-ClaudeWindow" -ForegroundColor DarkGray
}
catch {
    Write-Error "Failed to set window title: $_"
    Write-Host ""
    Write-Host "Alternative: You can manually set the title in this window by running:" -ForegroundColor Yellow
    Write-Host '  $host.UI.RawUI.WindowTitle = "Claude Code CLI environment"' -ForegroundColor Cyan
}