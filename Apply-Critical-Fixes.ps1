# Critical fixes for CLI Orchestrator

Write-Host "`n====== CRITICAL ORCHESTRATOR FIXES ======" -ForegroundColor Cyan

# 1. Clear incorrect window registration
Write-Host "`n1. Clearing incorrect window registration..." -ForegroundColor Yellow
$statusPath = ".\system_status.json"
if (Test-Path $statusPath) {
    $status = Get-Content $statusPath -Raw | ConvertFrom-Json
    if ($status.SystemInfo.ClaudeCodeCLI.WindowTitle -like "*Orchestrator*" -or
        $status.SystemInfo.ClaudeCodeCLI.WindowTitle -like "*Subsystem*") {
        Write-Host "   Found wrong registration: $($status.SystemInfo.ClaudeCodeCLI.WindowTitle)" -ForegroundColor Red
        $status.SystemInfo.ClaudeCodeCLI = $null
        $status | ConvertTo-Json -Depth 10 | Set-Content $statusPath -Encoding UTF8
        Write-Host "   Cleared!" -ForegroundColor Green
    }
}

# 2. Mark JSON files as processed
Write-Host "`n2. Marking JSON files as processed..." -ForegroundColor Yellow
Get-ChildItem ".\ClaudeResponses\Autonomous\*.json" -ErrorAction SilentlyContinue | ForEach-Object {
    $processed = "$($_.FullName).processed"
    if (-not (Test-Path $processed)) {
        "Processed" | Set-Content $processed
        Write-Host "   Marked: $($_.Name)" -ForegroundColor Gray
    }
}

# 3. Mark signal files as processed
Write-Host "`n3. Marking signal files as processed..." -ForegroundColor Yellow
Get-ChildItem ".\ClaudeResponses\Autonomous\TestComplete_*.signal" -ErrorAction SilentlyContinue | ForEach-Object {
    $processed = "$($_.FullName).processed"
    if (-not (Test-Path $processed)) {
        "Processed" | Set-Content $processed
        Write-Host "   Marked: $($_.Name)" -ForegroundColor Gray
    }
}

Write-Host "`n====== FIXES APPLIED ======" -ForegroundColor Green
Write-Host "`nNOW RUN THIS IN YOUR CLAUDE TERMINAL:" -ForegroundColor Yellow
Write-Host '.\Register-ThisWindow-As-Claude.ps1' -ForegroundColor Cyan