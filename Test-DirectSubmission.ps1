# Test-DirectSubmission.ps1
# Tests direct submission to the current active window
# Date: 2025-08-26

Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "TESTING DIRECT WINDOW SUBMISSION" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "This test will submit text directly to your current window in 3 seconds..." -ForegroundColor Yellow
Write-Host "You should see the text appear where you're typing." -ForegroundColor Yellow
Write-Host ""

# Countdown
for ($i = 3; $i -gt 0; $i--) {
    Write-Host "  $i..." -ForegroundColor Gray
    Start-Sleep -Seconds 1
}

# Import the updated module
Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLISubmission.psm1" -Force

# Test message
$testMessage = "TEST: This is an automated submission test from CLIOrchestrator. If you can see this message, the submission mechanism is working correctly!"

Write-Host "Submitting test message..." -ForegroundColor Cyan
Write-Host ""

# Submit the test message
$result = Submit-ToClaudeViaTypeKeys -PromptText $testMessage

if ($result.Success) {
    Write-Host "SUCCESS: Test message submitted!" -ForegroundColor Green
    Write-Host "  Window Handle: $($result.WindowHandle)" -ForegroundColor Gray
    Write-Host "  Message: $($result.Message)" -ForegroundColor Gray
} else {
    Write-Host "FAILED: Could not submit message" -ForegroundColor Red
    Write-Host "  Error: $($result.Error)" -ForegroundColor Red
}