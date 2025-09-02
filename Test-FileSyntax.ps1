# Test-FileSyntax.ps1
# Parse the OrchestrationManager.psm1 file to find syntax errors

$filePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager.psm1"

$tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$tokens, [ref]$errors)

if ($errors) {
    Write-Host "Found syntax errors:" -ForegroundColor Red
    foreach ($error in $errors) {
        Write-Host "Line $($error.Extent.StartLineNumber): $($error.Message)" -ForegroundColor Yellow
        Write-Host "Near: $($error.Extent.Text)" -ForegroundColor Gray
    }
} else {
    Write-Host "No syntax errors found" -ForegroundColor Green
}