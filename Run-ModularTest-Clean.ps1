# Run the complete modular test suite with cleaner output
Write-Host "Starting complete modular test suite..." -ForegroundColor Cyan
Write-Host "Target: 100% success with minimal warnings" -ForegroundColor Yellow
Write-Host ""

# Suppress unapproved verb warnings for cleaner output
$WarningPreference = 'SilentlyContinue'

# Run the test and capture output
$testOutput = & .\Test-Week3Day13Hour5-6-Modular.ps1 2>&1

# Restore warning preference
$WarningPreference = 'Continue'

# Filter out unapproved verb warnings but keep other warnings
$cleanOutput = $testOutput | Where-Object {
    $_ -notmatch "unapproved verbs" -and
    $_ -notmatch "less discoverable" -and
    $_ -notmatch "Get-Verb"
}

# Write filtered output to both console and file
$cleanOutput | ForEach-Object {
    Write-Host $_
}

# Also save to results file
$cleanOutput | Out-File -FilePath ".\Test-Week3Day13Hour5-6-Results-Clean.txt" -Encoding UTF8

# Check exit code
if ($LASTEXITCODE -eq 0) {
    Write-Host "`n[SUCCESS] All tests passed!" -ForegroundColor Green
} else {
    Write-Host "`n[FAILURE] Some tests failed. Exit code: $LASTEXITCODE" -ForegroundColor Red
}

Write-Host "`nResults saved to: Test-Week3Day13Hour5-6-Results-Clean.txt" -ForegroundColor Cyan