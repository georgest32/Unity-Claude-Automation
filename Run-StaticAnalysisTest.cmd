@echo off
REM Batch file to run static analysis tests with PowerShell 7

echo Unity-Claude Static Analysis Test Runner
echo =========================================
echo.

REM Check if pwsh (PowerShell 7) exists
where pwsh >nul 2>nul
if %errorlevel% == 0 (
    echo Using PowerShell 7...
    pwsh -ExecutionPolicy Bypass -File "%~dp0Test-StaticAnalysisIntegration-Final.ps1" -SaveResults
) else (
    echo PowerShell 7 not found, using Windows PowerShell...
    echo Note: Some features may not work correctly.
    powershell -ExecutionPolicy Bypass -File "%~dp0Test-StaticAnalysisIntegration-Final.ps1" -SaveResults
)

echo.
echo Test completed. Press any key to exit...
pause >nul