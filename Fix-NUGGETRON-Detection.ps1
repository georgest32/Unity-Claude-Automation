<#
.SYNOPSIS
    Fixes the orchestrator to properly detect NUGGETRON window
#>

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "FIXING NUGGETRON DETECTION" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# First, clear any stale registration
Write-Host "`n1. Clearing stale window registration..." -ForegroundColor Yellow
$statusPath = ".\system_status.json"
if (Test-Path $statusPath) {
    $status = Get-Content $statusPath -Raw | ConvertFrom-Json -AsHashtable
    if ($status.SystemInfo -and $status.SystemInfo.ClaudeCodeCLI) {
        # Check if the registered process still has NUGGETRON title
        $regPid = $status.SystemInfo.ClaudeCodeCLI.ProcessId
        $proc = Get-Process -Id $regPid -ErrorAction SilentlyContinue
        if (-not $proc -or $proc.MainWindowTitle -ne '**NUGGETRON**') {
            Write-Host "   Clearing stale registration (PID $regPid)" -ForegroundColor Red
            $status.SystemInfo.ClaudeCodeCLI = $null
            $status | ConvertTo-Json -Depth 10 | Set-Content $statusPath -Encoding UTF8
        }
    }
}

Write-Host "`n2. Instructions for user:" -ForegroundColor Yellow
Write-Host @"
   
   The NUGGETRON window needs to be re-registered.
   
   PLEASE DO THIS IN YOUR CLAUDE TERMINAL:
   1. First, ensure your window title is NUGGETRON:
      `$host.UI.RawUI.WindowTitle = "**NUGGETRON**"
   
   2. Then run:
      .\Register-NUGGETRON.ps1
   
   This will properly register your window for the orchestrator to find.
"@ -ForegroundColor Cyan

Write-Host "`n========================================" -ForegroundColor Green