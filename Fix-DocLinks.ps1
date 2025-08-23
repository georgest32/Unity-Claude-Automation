# Fix-DocLinks.ps1
# Fixes relative links in API documentation

$apiFiles = Get-ChildItem -Path "docs\api" -Filter "*.md" -Recurse

foreach ($file in $apiFiles) {
    $content = Get-Content $file.FullName -Raw
    
    # Fix relative links to go up two directories
    $content = $content -replace '\[Home\]\(\.\./index\.md\)', '[Home](../../index.md)'
    $content = $content -replace '\[User Guide\]\(\.\./user-guide/overview\.md\)', '[User Guide](../../user-guide/overview.md)'
    $content = $content -replace '\[Getting Started\]\(\.\./getting-started/installation\.md\)', '[Getting Started](../../getting-started/installation.md)'
    
    Set-Content -Path $file.FullName -Value $content -Encoding UTF8
    Write-Host "Fixed links in: $($file.Name)" -ForegroundColor Green
}

Write-Host "`nAll API documentation links fixed!" -ForegroundColor Cyan