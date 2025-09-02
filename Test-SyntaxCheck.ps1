# Test-SyntaxCheck.ps1
# Simple syntax check for OrchestrationManager.psm1

$filePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager.psm1"

Write-Host "Checking syntax of: $filePath" -ForegroundColor Cyan

try {
    $errors = $null
    $tokens = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$tokens, [ref]$errors)
    
    if ($errors -and $errors.Count -gt 0) {
        Write-Host "Found $($errors.Count) syntax errors:" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "  Line $($error.Extent.StartLineNumber): $($error.Message)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "No syntax errors found!" -ForegroundColor Green
    }
} catch {
    Write-Host "Failed to parse file: $_" -ForegroundColor Red
}