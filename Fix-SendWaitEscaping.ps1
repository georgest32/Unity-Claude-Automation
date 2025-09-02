# Fix SendWait escaping issues in CLIOrchestrator-Enhanced.ps1
# The issue is with improper escaping of parentheses
# According to SendKeys documentation, parentheses should be escaped differently

$file = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Start-CLIOrchestrator-Enhanced.ps1"

Write-Host "Fixing SendWait parentheses escaping in Start-CLIOrchestrator-Enhanced.ps1..." -ForegroundColor Cyan

# Read the file
$content = Get-Content $file -Raw

# Fix the incorrect escaping - parentheses should NOT be escaped in SendKeys
# They're only special when used for grouping repeated keys like (AB 10)
# When sending literal parentheses, they should be sent as-is
$oldEscaping = @"
`$escapedPrompt = `$PromptText -replace '{', '{{' -replace '}', '}}' -replace '\+', '{+}' -replace '\^', '{^}' -replace '%', '{%}' -replace '~', '{~}' -replace '\(', '{(}' -replace '\)', '{)}'
"@

$newEscaping = @"
`$escapedPrompt = `$PromptText -replace '{', '{{' -replace '}', '}}' -replace '\+', '{+}' -replace '\^', '{^}' -replace '%', '{%}' -replace '~', '{~}'
"@

if ($content -match [regex]::Escape($oldEscaping)) {
    $content = $content -replace [regex]::Escape($oldEscaping), $newEscaping
    Write-Host "Fixed SendWait escaping - removed invalid parentheses escaping" -ForegroundColor Green
    
    # Save the fixed file
    $content | Out-File $file -Encoding UTF8
    Write-Host "File saved successfully" -ForegroundColor Green
} else {
    Write-Host "Pattern not found - checking for alternative format..." -ForegroundColor Yellow
    
    # Try a more flexible pattern match
    $pattern = "\`$escapedPrompt = .*-replace '\\\(', '\{\(\}' -replace '\\\)', '\{\)\}'"
    if ($content -match $pattern) {
        # Remove just the parentheses escaping part
        $content = $content -replace " -replace '\\\(', '\{\(\}' -replace '\\\)', '\{\)\}'", ""
        
        # Save the fixed file
        $content | Out-File $file -Encoding UTF8
        Write-Host "Fixed SendWait escaping using alternative method" -ForegroundColor Green
    } else {
        Write-Host "Could not find the problematic escaping pattern" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Note: According to SendKeys documentation:" -ForegroundColor Yellow
Write-Host "  - Curly brackets {} need to be escaped as {{ and }}" -ForegroundColor Gray
Write-Host "  - Plus +, caret ^, percent %, and tilde ~ need to be wrapped in {}" -ForegroundColor Gray
Write-Host "  - Parentheses () do NOT need escaping for literal use" -ForegroundColor Gray
Write-Host "  - Parentheses are only special when grouping repeated keys like (AB 10)" -ForegroundColor Gray
Write-Host ""