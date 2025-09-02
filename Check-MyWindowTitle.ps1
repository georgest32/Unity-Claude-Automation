<#
.SYNOPSIS
    Check what your actual window title is
#>

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "CHECKING YOUR WINDOW TITLE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

Write-Host "`nYour current window title is:" -ForegroundColor Yellow
Write-Host "  '$($host.UI.RawUI.WindowTitle)'" -ForegroundColor Green

Write-Host "`nYour Process ID is:" -ForegroundColor Yellow
Write-Host "  $PID" -ForegroundColor Green

Write-Host "`nTo set your window to NUGGETRON, run this command directly:" -ForegroundColor Yellow
Write-Host '  $host.UI.RawUI.WindowTitle = "**NUGGETRON**"' -ForegroundColor Cyan

Write-Host "`nThen run:" -ForegroundColor Yellow
Write-Host "  .\Register-NUGGETRON-Protected.ps1" -ForegroundColor Cyan

Write-Host "`n========================================" -ForegroundColor Cyan