# Fix the here-string issue in DocumentationQualityAssessment module
$modulePath = ".\Modules\Unity-Claude-DocumentationQualityAssessment\Unity-Claude-DocumentationQualityAssessment.psm1"
$content = Get-Content $modulePath -Raw

# Find the problematic here-string section
$pattern = '(\$qualityPrompt = @"[\s\S]*?"@)'

if ($content -match $pattern) {
    Write-Host "Found here-string section" -ForegroundColor Yellow
    
    # Replace with proper here-string format - ensure the content is treated as literal
    $fixedContent = $content -replace '\$qualityPrompt = @"', '$qualityPrompt = @''
'
    $fixedContent = $fixedContent -replace '"@[\r\n]+(\s+# Generate)', '''@
$1'
    
    # Write the fixed content back
    Set-Content -Path $modulePath -Value $fixedContent -Encoding UTF8
    Write-Host "Fixed here-string format - using single quotes for literal content" -ForegroundColor Green
} else {
    Write-Host "Could not find here-string pattern" -ForegroundColor Red
}