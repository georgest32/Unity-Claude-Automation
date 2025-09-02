param()

$filePath = 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager.psm1'

Write-Host "Testing module syntax..." -ForegroundColor Cyan

# Try parsing with AST
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$tokens, [ref]$errors)

if ($errors) {
    Write-Host "SYNTAX ERRORS FOUND:" -ForegroundColor Red
    foreach ($parseError in $errors) {
        Write-Host ""
        Write-Host "Error Message: $($parseError.Message)" -ForegroundColor Yellow
        Write-Host "Error Location:" -ForegroundColor Cyan
        Write-Host "  Line: $($parseError.Extent.StartLineNumber)" -ForegroundColor White
        Write-Host "  Column: $($parseError.Extent.StartColumnNumber)" -ForegroundColor White
        Write-Host "  Text around error:" -ForegroundColor Gray
        
        # Get lines around the error
        $lines = Get-Content $filePath
        $startLine = [Math]::Max(0, $parseError.Extent.StartLineNumber - 3)
        $endLine = [Math]::Min($lines.Count - 1, $parseError.Extent.StartLineNumber + 2)
        
        for ($i = $startLine; $i -le $endLine; $i++) {
            if ($i -eq ($parseError.Extent.StartLineNumber - 1)) {
                Write-Host ">>> Line $($i + 1): $($lines[$i])" -ForegroundColor Red
            } else {
                Write-Host "    Line $($i + 1): $($lines[$i])" -ForegroundColor DarkGray
            }
        }
    }
} else {
    Write-Host "No syntax errors found!" -ForegroundColor Green
}