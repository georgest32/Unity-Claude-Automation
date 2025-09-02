$content = Get-Content ".\Fix-OrchestrationIssues-v3.ps1" -Raw
$opens = ([regex]::Matches($content, '\{')).Count
$closes = ([regex]::Matches($content, '\}')).Count
Write-Host "Opens: $opens"
Write-Host "Closes: $closes"
Write-Host "Difference: $($opens - $closes)"

if ($opens -ne $closes) {
    Write-Host "`nSearching for unmatched braces..."
    $lines = $content -split "`n"
    $depth = 0
    $lineNum = 0
    
    foreach ($line in $lines) {
        $lineNum++
        $lineOpens = ([regex]::Matches($line, '\{')).Count
        $lineCloses = ([regex]::Matches($line, '\}')).Count
        $depth += $lineOpens - $lineCloses
        
        if ($lineOpens -gt 0 -or $lineCloses -gt 0) {
            Write-Host "Line $lineNum (depth: $depth): $line" -ForegroundColor $(if ($depth -lt 0) { "Red" } else { "Gray" })
        }
        
        if ($depth -lt 0) {
            Write-Host "ERROR: Extra closing brace at line $lineNum" -ForegroundColor Red
            break
        }
    }
    
    if ($depth -gt 0) {
        Write-Host "ERROR: Missing $depth closing brace(s)" -ForegroundColor Red
    }
}