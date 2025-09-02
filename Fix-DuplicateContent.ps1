# Fix-DuplicateContent.ps1
# Removes duplicate content from OrchestrationManager.psm1

$filePath = 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager.psm1'
$content = Get-Content $filePath

Write-Host "Analyzing file for duplicate content..." -ForegroundColor Cyan
Write-Host "Original file has $($content.Count) lines" -ForegroundColor Gray

# Based on our analysis, the duplicate starts around line 577-598
# The first set (lines 1-576) is incomplete
# The second set (lines 577-end) appears to be complete

# Find the line where the complete module starts (second occurrence of module header)
$startLine = -1
for ($i = 576; $i -lt [Math]::Min(600, $content.Count); $i++) {
    if ($content[$i] -match '#region Module Header|^<#$' -and $i -gt 100) {
        $startLine = $i
        Write-Host "Found module header at line $($i + 1)" -ForegroundColor Yellow
        break
    }
}

if ($startLine -eq -1) {
    # If we can't find the header, use line 577 based on our function analysis
    $startLine = 576
    Write-Host "Using default start line 577" -ForegroundColor Yellow
}

# Extract the complete module content
$cleanContent = $content[$startLine..($content.Count - 1)]

Write-Host "Keeping lines from $($startLine + 1) to end" -ForegroundColor Green
Write-Host "New file will have $($cleanContent.Count) lines" -ForegroundColor Gray

# Backup the original
$backupPath = $filePath + '.backup_' + (Get-Date -Format 'yyyyMMdd_HHmmss')
Copy-Item $filePath $backupPath
Write-Host "Backed up original to: $backupPath" -ForegroundColor Gray

# Save the cleaned content
$cleanContent | Set-Content $filePath -Encoding UTF8
Write-Host "File cleaned and saved successfully!" -ForegroundColor Green