# Comprehensive fix for all quote issues
$filePath = 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\Components\ResponseAnalysisEngine-Core.psm1'

Write-Host "Reading file..." -ForegroundColor Cyan
$content = Get-Content $filePath -Raw

Write-Host "Replacing ALL double quotes with single quotes for string literals..." -ForegroundColor Yellow

# Replace all "..." strings with '...' except where it contains variables
$lines = $content -split "`r?`n"
$newLines = @()

foreach ($line in $lines) {
    # Skip empty lines
    if ([string]::IsNullOrWhiteSpace($line)) {
        $newLines += $line
        continue
    }
    
    # If line contains -Level "...", replace with single quotes
    if ($line -match '-Level\s+"[^"]*"') {
        $line = $line -replace '-Level\s+"([^"]*)"', "-Level '`$1'"
    }
    
    # If line contains -Component "...", replace with single quotes
    if ($line -match '-Component\s+"[^"]*"') {
        $line = $line -replace '-Component\s+"([^"]*)"', "-Component '`$1'"
    }
    
    # If line contains Status = "...", replace with single quotes
    if ($line -match 'Status\s*=\s*"[^"]*"') {
        $line = $line -replace 'Status\s*=\s*"([^"]*)"', "Status = '`$1'"
    }
    
    # If line contains Name = "...", replace with single quotes
    if ($line -match 'Name\s*=\s*"[^"]*"') {
        $line = $line -replace 'Name\s*=\s*"([^"]*)"', "Name = '`$1'"
    }
    
    $newLines += $line
}

$content = $newLines -join "`r`n"

Write-Host "Saving file..." -ForegroundColor Yellow
$content | Out-File $filePath -Encoding UTF8

Write-Host "All quotes fixed successfully!" -ForegroundColor Green