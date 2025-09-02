# Fix-DebugBrackets.ps1
# Fixes all [DEBUG] square bracket issues in OrchestrationManager.psm1

$filePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager.psm1"

Write-Host "Reading file: $filePath" -ForegroundColor Cyan
$content = Get-Content $filePath -Raw

Write-Host "Replacing [DEBUG] with DEBUG..." -ForegroundColor Yellow

# Replace all [DEBUG] patterns  
$content = $content -replace '\[DEBUG\]', 'DEBUG'

# Also fix any remaining square bracket issues in Write-Host messages with emojis
$content = $content -replace '\[SIGNAL\]', 'SIGNAL'
$content = $content -replace '\[READ\]', 'READ'
$content = $content -replace '\[DONE\]', 'DONE'
$content = $content -replace '\[ARCHIVE\]', 'ARCHIVE'
$content = $content -replace '\[ERROR\]', 'ERROR'
$content = $content -replace '\[EXCEPTION\]', 'EXCEPTION'

Write-Host "Saving fixed file..." -ForegroundColor Green
$content | Out-File $filePath -Encoding UTF8

Write-Host "Complete! All square bracket issues should be fixed." -ForegroundColor Green
Write-Host "Test the module import again to verify." -ForegroundColor Cyan