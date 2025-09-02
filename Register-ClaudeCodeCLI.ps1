<#
.SYNOPSIS
    Registers the current PowerShell window as the Claude Code CLI window
    
.DESCRIPTION
    Run this script IN the Claude Code CLI window to register it properly
    in system_status.json. This ensures the CLI Orchestrator can find and
    switch to the correct window.
    
.EXAMPLE
    .\Register-ClaudeCodeCLI.ps1
    Registers current window as Claude Code CLI
#>
[CmdletBinding()]
param()

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Claude Code CLI Window Registration" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get current process information
$currentPID = $PID
$currentProcess = Get-Process -Id $currentPID
$windowTitle = "Claude Code CLI environment"

Write-Host "Current Window Information:" -ForegroundColor Yellow
Write-Host "  PID: $currentPID" -ForegroundColor Gray
Write-Host "  Process: $($currentProcess.ProcessName)" -ForegroundColor Gray
Write-Host "  Handle: $($currentProcess.MainWindowHandle)" -ForegroundColor Gray
Write-Host ""

# Set the window title to make it easily identifiable
try {
    $host.UI.RawUI.WindowTitle = $windowTitle
    Write-Host "✅ Window title set to: '$windowTitle'" -ForegroundColor Green
} catch {
    Write-Warning "Could not set window title: $_"
    $windowTitle = $host.UI.RawUI.WindowTitle
    Write-Host "  Using existing title: '$windowTitle'" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Updating system_status.json..." -ForegroundColor Cyan

# Update system_status.json
$systemStatusPath = ".\system_status.json"
if (Test-Path $systemStatusPath) {
    try {
        # Read existing status
        $systemStatus = Get-Content $systemStatusPath -Raw | ConvertFrom-Json -AsHashtable -ErrorAction SilentlyContinue
        if (-not $systemStatus) {
            $systemStatus = @{}
        }
        
        # Ensure structure exists
        if (-not $systemStatus.SystemInfo) { 
            $systemStatus.SystemInfo = @{} 
        }
        if (-not $systemStatus.SystemInfo.ClaudeCodeCLI) { 
            $systemStatus.SystemInfo.ClaudeCodeCLI = @{} 
        }
        
        # Update Claude window information
        $systemStatus.SystemInfo.ClaudeCodeCLI = @{
            ProcessId = $currentPID
            WindowHandle = [int64]$currentProcess.MainWindowHandle
            WindowTitle = $windowTitle
            ProcessName = $currentProcess.ProcessName
            LastDetected = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
            DetectionMethod = "ManualRegistration"
            IsClaudeCodeCLI = $true  # Explicit marker
        }
        
        # Save back to file
        $systemStatus | ConvertTo-Json -Depth 10 | Set-Content $systemStatusPath -Encoding UTF8
        
        Write-Host "✅ Successfully registered Claude Code CLI window in system_status.json" -ForegroundColor Green
        Write-Host ""
        Write-Host "Registration Details:" -ForegroundColor Yellow
        Write-Host "  PID: $currentPID" -ForegroundColor Gray
        Write-Host "  Process: $($currentProcess.ProcessName)" -ForegroundColor Gray
        Write-Host "  Title: '$windowTitle'" -ForegroundColor Gray
        Write-Host "  Handle: $($currentProcess.MainWindowHandle)" -ForegroundColor Gray
        Write-Host "  Method: ManualRegistration" -ForegroundColor Gray
        Write-Host ""
        Write-Host "✅ The CLI Orchestrator will now correctly identify this window!" -ForegroundColor Green
        
    } catch {
        Write-Error "Failed to update system_status.json: $_"
    }
} else {
    Write-Warning "system_status.json not found at: $systemStatusPath"
    Write-Host "Creating new system_status.json..." -ForegroundColor Yellow
    
    # Create new status file
    $systemStatus = @{
        SystemInfo = @{
            ClaudeCodeCLI = @{
                ProcessId = $currentPID
                WindowHandle = [int64]$currentProcess.MainWindowHandle
                WindowTitle = $windowTitle
                ProcessName = $currentProcess.ProcessName
                LastDetected = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
                DetectionMethod = "ManualRegistration"
                IsClaudeCodeCLI = $true
            }
        }
    }
    
    $systemStatus | ConvertTo-Json -Depth 10 | Set-Content $systemStatusPath -Encoding UTF8
    Write-Host "✅ Created new system_status.json with Claude window information" -ForegroundColor Green
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Registration Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. This window is now registered as the Claude Code CLI" -ForegroundColor Gray
Write-Host "2. The CLI Orchestrator will use this window for submissions" -ForegroundColor Gray
Write-Host "3. Keep this window open while running the orchestrator" -ForegroundColor Gray
Write-Host ""