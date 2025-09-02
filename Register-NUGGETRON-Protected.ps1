<#
.SYNOPSIS
    Registers THIS window as NUGGETRON with protected persistent storage
#>

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "       NUGGETRON REGISTRATION" -ForegroundColor Magenta  
Write-Host "========================================" -ForegroundColor Magenta

# Set the unique NUGGETRON title
$uniqueID = "**NUGGETRON**"
$host.UI.RawUI.WindowTitle = $uniqueID

Write-Host "`n[OK] Window title set to: $uniqueID" -ForegroundColor Green

# Create protected registration file
$protectedRegPath = ".\.nuggetron_registration.json"
$nuggetronInfo = @{
    ProcessId = $PID
    WindowHandle = [int64](Get-Process -Id $PID).MainWindowHandle
    WindowTitle = $uniqueID
    UniqueIdentifier = $uniqueID
    ProcessName = (Get-Process -Id $PID).ProcessName
    RegisteredAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    IsNuggetron = $true
    Protected = $true
    Note = "DO NOT DELETE - This is the Claude CLI window registration"
}

# Save to protected file
$nuggetronInfo | ConvertTo-Json -Depth 10 | Set-Content $protectedRegPath -Encoding UTF8
Write-Host "`n[OK] Protected registration saved to: $protectedRegPath" -ForegroundColor Green

# Also update system_status.json but mark it as protected
$statusPath = ".\system_status.json"
if (Test-Path $statusPath) {
    $status = Get-Content $statusPath -Raw | ConvertFrom-Json -AsHashtable
    if (-not $status) { $status = @{} }
    if (-not $status.SystemInfo) { $status.SystemInfo = @{} }
    
    # Add protected NUGGETRON section at root level
    $status.NUGGETRON_PROTECTED = @{
        ProcessId = $PID
        WindowHandle = [int64](Get-Process -Id $PID).MainWindowHandle
        WindowTitle = $uniqueID
        UniqueIdentifier = $uniqueID
        ProcessName = (Get-Process -Id $PID).ProcessName
        RegisteredAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        IsNuggetron = $true
        Protected = $true
        WARNING = "DO NOT MODIFY - Protected NUGGETRON registration"
    }
    
    # Also update regular section for compatibility
    $status.SystemInfo.ClaudeCodeCLI = $nuggetronInfo
    
    $status | ConvertTo-Json -Depth 10 | Set-Content $statusPath -Encoding UTF8
    Write-Host "[OK] Updated system_status.json with protected section" -ForegroundColor Green
}

Write-Host "`n========================================" -ForegroundColor Magenta
Write-Host "    NUGGETRON ACTIVATED!" -ForegroundColor Magenta
Write-Host "========================================" -ForegroundColor Magenta
Write-Host "`nProtected registration created!" -ForegroundColor Cyan
Write-Host "The orchestrator will check both:" -ForegroundColor Cyan
Write-Host "  1. .nuggetron_registration.json (protected)" -ForegroundColor Gray
Write-Host "  2. system_status.json -> NUGGETRON_PROTECTED section" -ForegroundColor Gray