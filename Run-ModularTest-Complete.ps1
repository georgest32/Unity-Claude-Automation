# Run the complete modular test suite without skipping any tests
Write-Host "Starting complete modular test suite..." -ForegroundColor Cyan
Write-Host "Target: 100% success with full functionality" -ForegroundColor Yellow
Write-Host ""

# Run the test and capture output
$testOutput = & .\Test-Week3Day13Hour5-6-Modular.ps1 2>&1

# Write output to both console and file
$testOutput | ForEach-Object {
    Write-Host $_
}

# Also save to results file
$testOutput | Out-File -FilePath ".\Test-Week3Day13Hour5-6-Results.txt" -Encoding UTF8

# Check exit code
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[SUCCESS] All tests passed!" -ForegroundColor Green
} else {
    Write-Host "`n[FAILURE] Some tests failed. Exit code: $LASTEXITCODE" -ForegroundColor Red
}

Write-Host "`nResults saved to: Test-Week3Day13Hour5-6-Results.txt" -ForegroundColor Cyan