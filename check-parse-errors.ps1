$errors = $null
$tokens = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile(
    '.\Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1',
    [ref]$tokens,
    [ref]$errors
)

if ($errors) {
    Write-Host "Parse errors found:" -ForegroundColor Red
    $errors | Select-Object -First 10 | ForEach-Object {
        Write-Host "Line $($_.Extent.StartLineNumber): $($_.Message)" -ForegroundColor Yellow
        Write-Host "  Near: $($_.Extent.Text.Substring(0, [Math]::Min(50, $_.Extent.Text.Length)))" -ForegroundColor Gray
    }
} else {
    Write-Host "No parse errors found" -ForegroundColor Green
}