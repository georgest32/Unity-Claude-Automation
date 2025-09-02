# Test-ErrorHandling-Demo.ps1
# This test intentionally fails to demonstrate error handling

Write-Host "Starting Error Handling Demo Test" -ForegroundColor Cyan
Write-Host "This test will intentionally fail to test error capture" -ForegroundColor Yellow

# Try to import a non-existent module (will fail)
Write-Host "Attempting to import non-existent module..." -ForegroundColor Gray
try {
    Import-Module "ThisModuleDoesNotExist" -ErrorAction Stop
    Write-Host "Module imported successfully (this shouldn't happen)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to import module - $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "This is expected behavior for this demo" -ForegroundColor Yellow
}

# Try to access a non-existent file
Write-Host ""
Write-Host "Attempting to read non-existent file..." -ForegroundColor Gray
try {
    $content = Get-Content "C:\NonExistentFile\DoesNotExist.txt" -ErrorAction Stop
    Write-Host "File read successfully (this shouldn't happen)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to read file - $($_.Exception.Message)" -ForegroundColor Red
}

# Intentionally throw an error
Write-Host ""
Write-Host "Throwing intentional error..." -ForegroundColor Gray
throw "This is an intentional error to test error handling in Execute-TestInWindow.ps1"

# This line should never be reached
Write-Host "Test completed successfully" -ForegroundColor Green
exit 0