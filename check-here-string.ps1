$content = Get-Content '.\Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1'

Write-Host "Checking here-string at line 492..." -ForegroundColor Cyan
$line492 = $content[491]
Write-Host "Line 492: '$line492'" -ForegroundColor Yellow
Write-Host "  Ends with '@""': $($line492.EndsWith('@"'))" -ForegroundColor Green
Write-Host "  Contains extra chars after '@""': $($line492.Length -gt 2)" -ForegroundColor Green

Write-Host "`nChecking closing at line 524..." -ForegroundColor Cyan  
$line524 = $content[523]
Write-Host "Line 524: '$line524'" -ForegroundColor Yellow
Write-Host "  Starts with '""@': $($line524.StartsWith('"@'))" -ForegroundColor Green
Write-Host "  Contains extra chars before '""@': $($line524.Length -gt 2)" -ForegroundColor Green

# Check if there are any issues with the content between
Write-Host "`nChecking lines 493-523 for issues..." -ForegroundColor Cyan
for ($i = 492; $i -le 522; $i++) {
    $line = $content[$i]
    if ($line -match '^\s*"@' -or $line -match '@"\s*$') {
        Write-Host "  Line $($i+1): Potential here-string delimiter: '$line'" -ForegroundColor Red
    }
}