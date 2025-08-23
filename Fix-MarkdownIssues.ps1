# Fix-MarkdownIssues.ps1
# Auto-fixes markdown linting issues

param(
    [Parameter(Mandatory=$false)]
    [string]$Path = "docs",
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

Write-Host "Running markdownlint auto-fix..." -ForegroundColor Cyan

$mdFiles = Get-ChildItem -Path $Path -Filter "*.md" -Recurse

if ($DryRun) {
    Write-Host "DRY RUN - No changes will be made" -ForegroundColor Yellow
    markdownlint $Path --config .markdownlintrc
}
else {
    Write-Host "Fixing markdown issues in $($mdFiles.Count) files..." -ForegroundColor Yellow
    
    # Run markdownlint with fix flag
    markdownlint $Path --config .markdownlintrc --fix
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ All markdown issues fixed!" -ForegroundColor Green
    }
    else {
        Write-Host "⚠ Some issues could not be auto-fixed" -ForegroundColor Yellow
        Write-Host "Run 'markdownlint $Path' to see remaining issues" -ForegroundColor Cyan
    }
}

# Additional custom fixes
Write-Host "`nApplying custom fixes..." -ForegroundColor Cyan

foreach ($file in $mdFiles) {
    $content = Get-Content $file.FullName -Raw
    $changed = $false
    
    # Fix trailing whitespace
    if ($content -match '\s+$') {
        $content = $content -replace '\s+$', ''
        $changed = $true
    }
    
    # Ensure file ends with single newline
    if (-not $content.EndsWith("`n")) {
        $content += "`n"
        $changed = $true
    }
    
    # Fix multiple consecutive blank lines
    if ($content -match '\n{3,}') {
        $content = $content -replace '\n{3,}', "`n`n"
        $changed = $true
    }
    
    if ($changed -and -not $DryRun) {
        Set-Content -Path $file.FullName -Value $content -NoNewline -Encoding UTF8
        Write-Host "  Fixed: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "`n✓ Markdown auto-fix complete!" -ForegroundColor Green