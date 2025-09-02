$filePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLIOrchestrator\Core\OrchestrationManager.psm1"
$lines = Get-Content $filePath -Encoding UTF8

Write-Host "Checking problematic lines from OrchestrationManager.psm1" -ForegroundColor Cyan
Write-Host "=====================================================" -ForegroundColor Cyan

Write-Host "`nLine 191:" -ForegroundColor Yellow
Write-Host $lines[190]
Write-Host "Length: $($lines[190].Length)" -ForegroundColor Gray

Write-Host "`nLine 192:" -ForegroundColor Yellow  
Write-Host $lines[191]
Write-Host "Length: $($lines[191].Length)" -ForegroundColor Gray

Write-Host "`nLine 195:" -ForegroundColor Yellow
Write-Host $lines[194] 
Write-Host "Length: $($lines[194].Length)" -ForegroundColor Gray

Write-Host "`nLine 265:" -ForegroundColor Yellow
Write-Host $lines[264]
Write-Host "Length: $($lines[264].Length)" -ForegroundColor Gray

Write-Host "`nLine 271:" -ForegroundColor Yellow
Write-Host $lines[270]
Write-Host "Length: $($lines[270].Length)" -ForegroundColor Gray

Write-Host "`nLine 272:" -ForegroundColor Yellow
Write-Host $lines[271]
Write-Host "Length: $($lines[271].Length)" -ForegroundColor Gray

Write-Host "`nLine 276:" -ForegroundColor Yellow
Write-Host $lines[275]
Write-Host "Length: $($lines[275].Length)" -ForegroundColor Gray

# Check for non-printable characters
Write-Host "`nChecking for non-ASCII characters..." -ForegroundColor Cyan
$problematicLines = @(190, 191, 194, 264, 270, 271, 275)
foreach ($lineNum in $problematicLines) {
    $line = $lines[$lineNum]
    $nonAscii = $false
    for ($i = 0; $i -lt $line.Length; $i++) {
        $char = $line[$i]
        if ([int]$char -gt 127 -or [int]$char -lt 32 -and [int]$char -notin @(9, 10, 13)) {
            Write-Host "Line $($lineNum + 1) position $i has non-ASCII char: $([int]$char)" -ForegroundColor Red
            $nonAscii = $true
        }
    }
    if (-not $nonAscii) {
        Write-Host "Line $($lineNum + 1): No non-ASCII characters found" -ForegroundColor Green
    }
}