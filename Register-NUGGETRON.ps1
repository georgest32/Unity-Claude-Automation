<#
.SYNOPSIS
    Registers THIS window as NUGGETRON - the one true Claude CLI window
#>

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "       NUGGETRON REGISTRATION" -ForegroundColor Magenta  
Write-Host "========================================" -ForegroundColor Magenta

# Set the unique NUGGETRON title
$uniqueID = "**NUGGETRON**"
$host.UI.RawUI.WindowTitle = $uniqueID

Write-Host "`n✅ Window title set to: $uniqueID" -ForegroundColor Green
Write-Host "No other window would dare use this name!" -ForegroundColor Cyan

# Update system_status.json with NUGGETRON
$statusPath = ".\system_status.json"
if (Test-Path $statusPath) {
    $status = Get-Content $statusPath -Raw | ConvertFrom-Json -AsHashtable
    if (-not $status) { $status = @{} }
    if (-not $status.SystemInfo) { $status.SystemInfo = @{} }
    
    $status.SystemInfo.ClaudeCodeCLI = @{
        ProcessId = $PID
        WindowHandle = [int64](Get-Process -Id $PID).MainWindowHandle
        WindowTitle = $uniqueID
        UniqueIdentifier = $uniqueID
        ProcessName = (Get-Process -Id $PID).ProcessName
        LastDetected = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        IsClaudeCodeCLI = $true
        IsNuggetron = $true  # Special marker
        DetectionMethod = "NUGGETRON"
    }
    
    $status | ConvertTo-Json -Depth 10 | Set-Content $statusPath -Encoding UTF8
    Write-Host "`n✅ NUGGETRON registered in system_status.json" -ForegroundColor Green
} else {
    Write-Host "❌ Could not find system_status.json" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "    NUGGETRON ACTIVATED!" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "`nThe orchestrator will now search for **NUGGETRON**" -ForegroundColor Cyan
Write-Host "No confusion possible with this unique name!" -ForegroundColor Green