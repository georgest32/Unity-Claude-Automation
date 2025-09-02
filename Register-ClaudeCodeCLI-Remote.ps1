<#
.SYNOPSIS
    Registers a PowerShell window as the Claude Code CLI window remotely
    
.DESCRIPTION
    Run this script from ANY PowerShell window to register a specific window
    as the Claude Code CLI. It will show you all available windows and let
    you select which one is running Claude Code.
    
.EXAMPLE
    .\Register-ClaudeCodeCLI-Remote.ps1
    Shows all windows and lets you select the Claude window
    
.EXAMPLE
    .\Register-ClaudeCodeCLI-Remote.ps1 -AutoDetect
    Tries to automatically detect the Claude window
#>
[CmdletBinding()]
param(
    [switch]$AutoDetect
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Claude Code CLI Remote Registration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get all PowerShell/Terminal windows
$psProcessNames = @('pwsh', 'powershell', 'WindowsTerminal')
$psProcesses = Get-Process -Name $psProcessNames -ErrorAction SilentlyContinue | Where-Object { 
    $_.MainWindowHandle -ne 0 
}

if (-not $psProcesses) {
    Write-Error "No PowerShell or Terminal windows found!"
    return
}

Write-Host "Found PowerShell/Terminal Windows:" -ForegroundColor Yellow
Write-Host ""

$windows = @()
$index = 1
foreach ($proc in $psProcesses) {
    $windows += $proc
    Write-Host "[$index] PID: $($proc.Id) | Process: $($proc.ProcessName)" -ForegroundColor Cyan
    Write-Host "    Title: '$($proc.MainWindowTitle)'" -ForegroundColor Gray
    Write-Host "    Handle: $($proc.MainWindowHandle)" -ForegroundColor DarkGray
    
    # Check if this might be Claude based on title or recent activity
    if ($proc.MainWindowTitle -match "claude" -or 
        $proc.MainWindowTitle -match "Claude" -or
        $proc.MainWindowTitle -eq "Administrator: Windows PowerShell" -or
        $proc.MainWindowTitle -eq "Administrator: PowerShell 7") {
        Write-Host "    ⭐ Possible Claude window detected" -ForegroundColor Green
    }
    Write-Host ""
    $index++
}

# Auto-detect or ask user
$selectedWindow = $null

if ($AutoDetect) {
    Write-Host "Auto-detecting Claude window..." -ForegroundColor Yellow
    
    # Look for windows with claude in title first
    $claudeWindow = $windows | Where-Object { 
        $_.MainWindowTitle -match "claude" -and 
        $_.MainWindowTitle -notmatch "CLIOrchestrator" -and
        $_.MainWindowTitle -notmatch "Subsystem"
    } | Select-Object -First 1
    
    if ($claudeWindow) {
        $selectedWindow = $claudeWindow
        Write-Host "✅ Auto-detected: '$($selectedWindow.MainWindowTitle)'" -ForegroundColor Green
    } else {
        # Look for the most recently active PowerShell window that's not the orchestrator
        $selectedWindow = $windows | Where-Object {
            $_.MainWindowTitle -notmatch "CLIOrchestrator" -and
            $_.MainWindowTitle -notmatch "Subsystem"
        } | Sort-Object StartTime -Descending | Select-Object -First 1
        
        if ($selectedWindow) {
            Write-Host "⚠️ No 'claude' window found, using most recent: '$($selectedWindow.MainWindowTitle)'" -ForegroundColor Yellow
        }
    }
} else {
    # Manual selection
    Write-Host "Which window is running Claude Code CLI?" -ForegroundColor Yellow
    Write-Host "(Enter the number, or press Enter to cancel)" -ForegroundColor Gray
    $selection = Read-Host "Selection"
    
    if ($selection -match '^\d+$') {
        $selectedIndex = [int]$selection - 1
        if ($selectedIndex -ge 0 -and $selectedIndex -lt $windows.Count) {
            $selectedWindow = $windows[$selectedIndex]
        } else {
            Write-Error "Invalid selection!"
            return
        }
    } else {
        Write-Host "Registration cancelled." -ForegroundColor Yellow
        return
    }
}

if (-not $selectedWindow) {
    Write-Error "No window selected or detected!"
    return
}

Write-Host ""
Write-Host "Registering selected window:" -ForegroundColor Cyan
Write-Host "  PID: $($selectedWindow.Id)" -ForegroundColor Gray
Write-Host "  Process: $($selectedWindow.ProcessName)" -ForegroundColor Gray
Write-Host "  Title: '$($selectedWindow.MainWindowTitle)'" -ForegroundColor Gray
Write-Host "  Handle: $($selectedWindow.MainWindowHandle)" -ForegroundColor Gray
Write-Host ""

# Update system_status.json
$systemStatusPath = ".\system_status.json"
Write-Host "Updating system_status.json..." -ForegroundColor Cyan

try {
    # Read existing status or create new
    $systemStatus = @{}
    if (Test-Path $systemStatusPath) {
        $content = Get-Content $systemStatusPath -Raw
        if ($content) {
            $systemStatus = $content | ConvertFrom-Json -AsHashtable -ErrorAction SilentlyContinue
        }
    }
    
    if (-not $systemStatus) {
        $systemStatus = @{}
    }
    
    # Ensure structure exists
    if (-not $systemStatus.SystemInfo) { 
        $systemStatus.SystemInfo = @{} 
    }
    
    # Update Claude window information
    $systemStatus.SystemInfo.ClaudeCodeCLI = @{
        ProcessId = $selectedWindow.Id
        WindowHandle = [int64]$selectedWindow.MainWindowHandle
        WindowTitle = $selectedWindow.MainWindowTitle
        ProcessName = $selectedWindow.ProcessName
        LastDetected = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        DetectionMethod = "RemoteRegistration"
        IsClaudeCodeCLI = $true  # Explicit marker
    }
    
    # Save back to file
    $systemStatus | ConvertTo-Json -Depth 10 | Set-Content $systemStatusPath -Encoding UTF8
    
    Write-Host "✅ Successfully registered Claude Code CLI window!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Registration Complete:" -ForegroundColor Green
    Write-Host "  The CLI Orchestrator will now use PID $($selectedWindow.Id)" -ForegroundColor Gray
    Write-Host "  Window: '$($selectedWindow.MainWindowTitle)'" -ForegroundColor Gray
    Write-Host ""
    Write-Host "✨ The orchestrator should now correctly switch to the Claude window!" -ForegroundColor Cyan
    
} catch {
    Write-Error "Failed to update system_status.json: $_"
}

Write-Host ""
Write-Host "Tip: You can also rename the Claude window for easier detection:" -ForegroundColor Yellow
Write-Host '  In the Claude window, run: $host.UI.RawUI.WindowTitle = "Claude Code CLI"' -ForegroundColor DarkGray
Write-Host ""