# Fix-PartialDuplicate.ps1
# Fixes the partial duplication in OrchestrationManager.psm1

$filePath = 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager.psm1'
$content = Get-Content $filePath

Write-Host "Analyzing file structure..." -ForegroundColor Cyan
Write-Host "Current file has $($content.Count) lines" -ForegroundColor Gray

# The problem:
# - Invoke-AutonomousDecisionMaking function appears to be incomplete (starts at line 476)
# - The incomplete function's try block never closes properly
# - Invoke-DecisionExecution appears twice (lines 614 and 813)

# Solution: Remove the incomplete Invoke-AutonomousDecisionMaking function (lines 476-612)
# Keep only the complete Invoke-DecisionExecution function (lines 813-920)

$newContent = @()

# Add lines 1-475 (everything before the incomplete function)
$newContent += $content[0..474]

# Skip the incomplete Invoke-AutonomousDecisionMaking (lines 475-612)
# Add the complete Invoke-DecisionExecution and export (lines 813-end)
$newContent += $content[812..($content.Count - 1)]

Write-Host "Original lines: $($content.Count)"
Write-Host "New lines: $($newContent.Count)"

# Backup the original
$backupPath = $filePath + '.backup2_' + (Get-Date -Format 'yyyyMMdd_HHmmss')
Copy-Item $filePath $backupPath
Write-Host "Backed up original to: $backupPath" -ForegroundColor Gray

# Save the fixed content
$newContent | Set-Content $filePath -Encoding UTF8
Write-Host "File fixed and saved!" -ForegroundColor Green