#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Triggers all enhanced visualization features
#>

Write-Host "TRIGGERING ALL ENHANCED FEATURES" -ForegroundColor Cyan

# 1. Generate enhanced semantic data
Write-Host "[1/4] Generating semantic graph..." -ForegroundColor Yellow
& .\Generate-EnhancedVisualizationData.ps1 -MaxNodes 300

# 2. Generate AST analysis
Write-Host "[2/4] Generating AST analysis..." -ForegroundColor Yellow
& .\Generate-ASTEnhancedVisualization.ps1 -MaxNodes 100

# 3. Check if visualization server is running
Write-Host "[3/4] Checking visualization server..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3001/health" -TimeoutSec 2
    Write-Host "✅ Server already running" -ForegroundColor Green
} catch {
    Write-Host "Starting visualization server..." -ForegroundColor Yellow
    Start-Process pwsh -ArgumentList "-NoExit", "-Command", "cd Visualization; npm start"
    Start-Sleep -Seconds 5
}

# 4. Open browser
Write-Host "[4/4] Opening enhanced visualization..." -ForegroundColor Yellow
Start-Process "http://localhost:3001"

Write-Host ""
Write-Host "✅ ALL FEATURES TRIGGERED!" -ForegroundColor Green
Write-Host ""
Write-Host "INTERACTIVE FEATURES:" -ForegroundColor Cyan
Write-Host "  🔍 Search: Type module names in search box" -ForegroundColor White
Write-Host "  🏷️ Filter: Toggle category checkboxes" -ForegroundColor White
Write-Host "  🤖 AI: Double-click nodes (if services running)" -ForegroundColor White
Write-Host "  📊 AST: View function relationships" -ForegroundColor White
Write-Host "  🎯 Focus: Double-click to zoom on node" -ForegroundColor White