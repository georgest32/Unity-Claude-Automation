# Fix-Server-Syntax.ps1
# Fixes JavaScript syntax error in visualization server
# Date: 2025-08-29

Write-Host "=== Fixing Visualization Server JavaScript Syntax ===" -ForegroundColor Cyan

try {
    # Read the current server.js
    $serverPath = ".\Visualization\server.js"
    $content = Get-Content $serverPath -Raw
    
    # Fix the specific syntax error on line 87
    $fixedContent = $content -replace 
        "console\.log\(\[API\] Loaded real data with\s+nodes and\s+edges\);", 
        "console.log(`[API] Loaded real data with `${realData.nodes.length} nodes and `${realData.edges.length} edges`);"
    
    # Fix line 106 syntax error  
    $fixedContent = $fixedContent -replace 
        "console\.log\(\[API\] Served real data with.*edges\);",
        "console.log(`[API] Served real data with `${realData.nodes.length} nodes and `${realData.edges.length} edges`);"
    
    # Fix any other template literal issues
    $fixedContent = $fixedContent -replace 
        "size = 45,",
        "size: 45,"
    
    # Write the fixed content
    $fixedContent | Out-File -FilePath $serverPath -Encoding UTF8 -NoNewline
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Success] Fixed JavaScript syntax errors in server.js" -ForegroundColor Green
    
    # Verify the fix
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Info] Testing Node.js syntax..." -ForegroundColor White
    
    Set-Location ".\Visualization"
    $syntaxTest = node -c $serverPath 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Success] JavaScript syntax is now valid" -ForegroundColor Green
    } else {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Error] Syntax issues remain: $syntaxTest" -ForegroundColor Red
    }
    
    Set-Location ".."
    
} catch {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Error] Fix failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Server Syntax Fix Complete ===" -ForegroundColor Green