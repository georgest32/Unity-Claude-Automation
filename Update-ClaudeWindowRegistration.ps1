<#
.SYNOPSIS
    Updates the Claude Code CLI window registration with a unique title
    
.DESCRIPTION
    Run this in the Claude Code CLI window to give it a unique, easily
    identifiable title that won't conflict with other subsystem windows.
    
.EXAMPLE
    .\Update-ClaudeWindowRegistration.ps1
    Sets unique title and updates registration
#>
[CmdletBinding()]
param()

Write-Host ""
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host "  Claude Code CLI - Unique Window Registration" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan
Write-Host ""

# Create a unique title that won't match any subsystem
$uniqueTitle = "CLAUDE_CODE_CLI_TERMINAL_$(Get-Date -Format 'HHmmss')"

# Set the window title
try {
    $host.UI.RawUI.WindowTitle = $uniqueTitle
    Write-Host "✅ Window title set to: '$uniqueTitle'" -ForegroundColor Green
} catch {
    Write-Error "Could not set window title: $_"
    return
}

# Get current process info
$currentPID = $PID
$currentProcess = Get-Process -Id $currentPID

Write-Host ""
Write-Host "Window Information:" -ForegroundColor Yellow
Write-Host "  PID: $currentPID" -ForegroundColor Gray
Write-Host "  Process: $($currentProcess.ProcessName)" -ForegroundColor Gray
Write-Host "  Handle: $($currentProcess.MainWindowHandle)" -ForegroundColor Gray
Write-Host "  Title: $uniqueTitle" -ForegroundColor Gray
Write-Host ""

# Update system_status.json
$systemStatusPath = ".\system_status.json"
Write-Host "Updating system_status.json..." -ForegroundColor Cyan

try {
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
    
    # Update with very specific Claude window information
    $systemStatus.SystemInfo.ClaudeCodeCLI = @{
        ProcessId = $currentPID
        WindowHandle = [int64]$currentProcess.MainWindowHandle
        WindowTitle = $uniqueTitle
        ProcessName = $currentProcess.ProcessName
        LastDetected = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        DetectionMethod = "UniqueRegistration"
        IsClaudeCodeCLI = $true
        UniqueIdentifier = $uniqueTitle  # Extra field for verification
    }
    
    # Save back to file
    $systemStatus | ConvertTo-Json -Depth 10 | Set-Content $systemStatusPath -Encoding UTF8
    
    Write-Host "✅ Successfully registered with unique identifier!" -ForegroundColor Green
    Write-Host ""
    Write-Host "=====================================================" -ForegroundColor Green
    Write-Host "  Registration Complete!" -ForegroundColor Green
    Write-Host "=====================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "The CLI Orchestrator will now look for:" -ForegroundColor Yellow
    Write-Host "  Title pattern: CLAUDE_CODE_CLI_TERMINAL_*" -ForegroundColor Cyan
    Write-Host "  Exact title: $uniqueTitle" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "This unique title ensures no confusion with subsystem windows!" -ForegroundColor Green
    
} catch {
    Write-Error "Failed to update system_status.json: $_"
}