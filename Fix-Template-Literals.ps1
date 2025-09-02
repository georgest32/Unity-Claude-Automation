# Fix-Template-Literals.ps1
# Fixes missing backticks in JavaScript template literals
# Date: 2025-08-29

Write-Host "=== Fixing JavaScript Template Literal Syntax ===" -ForegroundColor Cyan

try {
    $serverPath = ".\Visualization\server.js"
    $content = Get-Content $serverPath -Raw
    
    # Fix line 87 - missing backticks
    $content = $content -replace 
        "console\.log\(\[API\] Loaded real data with \$\{realData\.nodes\.length\} nodes and \$\{realData\.edges\.length\} edges\);",
        "console.log(`[API] Loaded real data with `$`{realData.nodes.length`} nodes and `$`{realData.edges.length`} edges`);"
    
    # Fix line 106 - missing backticks  
    $content = $content -replace 
        "console\.log\(\[API\] Served real data with \$\{realData\.nodes\.length\} nodes and \$\{realData\.edges\.length\} edges\);",
        "console.log(`[API] Served real data with `$`{realData.nodes.length`} nodes and `$`{realData.edges.length`} edges`);"
    
    # Write fixed content
    $content | Out-File -FilePath $serverPath -Encoding UTF8 -NoNewline
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Success] Fixed template literal syntax" -ForegroundColor Green
    
    # Test syntax
    Set-Location ".\Visualization"
    $test = node -c server.js 2>&1
    Set-Location ".."
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Success] JavaScript syntax validated" -ForegroundColor Green
        
        # Now generate real data and restart server
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Info] Generating real visualization data..." -ForegroundColor White
        ./Generate-Module-Visualization-Direct.ps1
        
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Success] Ready to start visualization with real data!" -ForegroundColor Green
        Write-Host "Run: ./Start-Visualization-Dashboard.ps1 -OpenBrowser" -ForegroundColor Cyan
        
    } else {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Error] Syntax test failed: $test" -ForegroundColor Red
    }
    
} catch {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Error] Template literal fix failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Template Literal Fix Complete ===" -ForegroundColor Green