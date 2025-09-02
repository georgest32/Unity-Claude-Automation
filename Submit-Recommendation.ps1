# Submit the recommendation directly to Claude
$recommendationText = "Continue implementing the C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Enhanced_Documentation_System_ARP_2025_08_24.md--please check every hourly line item and see what has been implemented, and what has not"

Write-Host "Testing direct submission of recommendation..." -ForegroundColor Cyan

# Import the CLIOrchestrator module
Import-Module "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Unity-Claude-CLIOrchestrator.psd1" -Force

# Try to submit via TypeKeys
if (Get-Command Submit-ToClaudeViaTypeKeys -ErrorAction SilentlyContinue) {
    Write-Host "Submitting recommendation to Claude..." -ForegroundColor Yellow
    Write-Host "Recommendation: $recommendationText" -ForegroundColor Gray
    
    $result = Submit-ToClaudeViaTypeKeys -PromptText $recommendationText
    
    if ($result) {
        Write-Host "Submission successful!" -ForegroundColor Green
    } else {
        Write-Host "Submission failed" -ForegroundColor Red
    }
} else {
    Write-Host "Submit-ToClaudeViaTypeKeys not found" -ForegroundColor Red
}