<#
.SYNOPSIS
    Updates NUGGETRON registration with current window PID
#>

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "   UPDATING NUGGETRON REGISTRATION" -ForegroundColor Magenta  
Write-Host "========================================" -ForegroundColor Magenta

# Verify this window is NUGGETRON
if ($host.UI.RawUI.WindowTitle -ne "**NUGGETRON**") {
    Write-Host "[ERROR] This window is not NUGGETRON!" -ForegroundColor Red
    Write-Host "Current title: '$($host.UI.RawUI.WindowTitle)'" -ForegroundColor Yellow
    Write-Host "Please set title first: " -ForegroundColor Yellow
    Write-Host '  $host.UI.RawUI.WindowTitle = "**NUGGETRON**"' -ForegroundColor Cyan
    exit 1
}

Write-Host "[OK] Window title confirmed: **NUGGETRON**" -ForegroundColor Green
Write-Host "[OK] Current Process ID: $PID" -ForegroundColor Green

# Get process info
$proc = Get-Process -Id $PID
$handle = $proc.MainWindowHandle

Write-Host "[INFO] Process Name: $($proc.ProcessName)" -ForegroundColor Cyan
Write-Host "[INFO] Window Handle: $handle" -ForegroundColor Cyan

# Update protected registration file
$protectedRegPath = ".\.nuggetron_registration.json"
$nuggetronInfo = @{
    ProcessId = $PID
    WindowHandle = [int64]$handle
    WindowTitle = "**NUGGETRON**"
    UniqueIdentifier = "**NUGGETRON**"
    ProcessName = $proc.ProcessName
    RegisteredAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    IsNuggetron = $true
    Protected = $true
    Note = "DO NOT DELETE - This is the Claude CLI window registration"
}

$nuggetronInfo | ConvertTo-Json -Depth 10 | Set-Content $protectedRegPath -Encoding UTF8
Write-Host "[OK] Updated .nuggetron_registration.json" -ForegroundColor Green

# Also update system_status.json
$statusPath = ".\system_status.json"
if (Test-Path $statusPath) {
    $status = Get-Content $statusPath -Raw | ConvertFrom-Json -AsHashtable
    if (-not $status) { $status = @{} }
    
    # Add protected NUGGETRON section
    $status.NUGGETRON_PROTECTED = @{
        ProcessId = $PID
        WindowHandle = [int64]$handle
        WindowTitle = "**NUGGETRON**"
        UniqueIdentifier = "**NUGGETRON**"
        ProcessName = $proc.ProcessName
        RegisteredAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        IsNuggetron = $true
        Protected = $true
        WARNING = "DO NOT MODIFY - Protected NUGGETRON registration"
    }
    
    $status | ConvertTo-Json -Depth 10 | Set-Content $statusPath -Encoding UTF8
    Write-Host "[OK] Updated system_status.json NUGGETRON_PROTECTED section" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "    REGISTRATION UPDATED!" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "`nNUGGETRON registration updated with PID $PID" -ForegroundColor Cyan