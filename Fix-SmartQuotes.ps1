# Fix smart quotes in ResponseAnalysisEngine-Core.psm1
$filePath = 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\Components\ResponseAnalysisEngine-Core.psm1'

Write-Host "Reading file..." -ForegroundColor Cyan
$content = Get-Content $filePath -Raw

Write-Host "Replacing smart quotes with regular quotes..." -ForegroundColor Yellow

# Replace various types of smart quotes
$content = $content -replace '[\u201C\u201D\u201E\u201F\u2033\u2036]', '"'  # Smart double quotes
$content = $content -replace '[\u2018\u2019\u201A\u201B\u2032\u2035]', "'"  # Smart single quotes
$content = $content -replace '[""]', '"'  # Additional smart double quotes
$content = $content -replace '['']', "'"  # Additional smart single quotes

Write-Host "Saving file..." -ForegroundColor Yellow
$content | Out-File $filePath -Encoding UTF8

Write-Host "Smart quotes replaced successfully!" -ForegroundColor Green