# Read the file content
$content = Get-Content '.\Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1' -Raw

# Check if line 492 ends with @" and nothing else
$lines = $content -split "`r?`n"
Write-Host "Line 492 content: '$($lines[491])'" -ForegroundColor Yellow
Write-Host "Line 492 ends with '@""': $($lines[491] -match '@"$')" -ForegroundColor Cyan

# Check for the specific problematic pattern and fix it
if ($lines[491] -match '^\s*\$qualityPrompt = @".*$') {
    Write-Host "Found assignment with here-string on same line. This needs fixing." -ForegroundColor Red
    
    # Check if there's content after @"
    if ($lines[491] -match '@"(.+)$') {
        Write-Host "Content found after @"": $($matches[1])" -ForegroundColor Red
    }
}

Write-Host "`nLine 524 content: '$($lines[523])'" -ForegroundColor Yellow
Write-Host "Line 524 is just '""@': $($lines[523] -eq '"@')" -ForegroundColor Cyan