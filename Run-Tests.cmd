@echo off
echo ============================================================
echo Unity-Claude Static Analysis Test Runner
echo ============================================================
echo.
echo Using PowerShell 7 to run tests...
echo.
pwsh -ExecutionPolicy Bypass -File "%~dp0Test-StaticAnalysisIntegration-Final.ps1" -SaveResults
echo.
echo Press any key to exit...
pause >nul