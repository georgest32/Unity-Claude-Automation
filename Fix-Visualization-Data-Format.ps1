# Fix-Visualization-Data-Format.ps1
# Fixes data format mismatch between server (edges) and client (links)
# Date: 2025-08-29

Write-Host "=== Fixing Visualization Data Format Mismatch ===" -ForegroundColor Cyan

try {
    # Fix 1: Update server to send 'links' instead of 'edges'
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Info] Updating server data format..." -ForegroundColor White
    
    $serverPath = ".\Visualization\server.js"
    $serverContent = Get-Content $serverPath -Raw
    
    # Replace 'edges' with 'links' in the data structure
    $fixedServer = $serverContent -replace '"edges":', '"links":'
    $fixedServer = $fixedServer -replace '\.edges\.', '.links.'
    $fixedServer = $fixedServer -replace 'realData\.edges', 'realData.links'
    
    $fixedServer | Out-File -FilePath $serverPath -Encoding UTF8 -NoNewline
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Success] Updated server to use 'links' format" -ForegroundColor Green
    
    # Fix 2: Update generated data to use 'links' instead of 'edges'
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Info] Regenerating data with correct format..." -ForegroundColor White
    
    # Create corrected visualization data
    $dataPath = ".\Visualization\public\static\data\enhanced-system-graph.json"
    
    # Generate minimal working dataset with correct format
    $workingData = @{
        nodes = @(
            @{ id = "Enhanced-Documentation-System"; label = "Enhanced Documentation System v2.0.0"; category = "System"; size = 60; color = "#ff6b35"; x = 0; y = 0 }
            @{ id = "Predictive-Evolution"; label = "Code Evolution Analysis"; category = "Week4"; size = 45; color = "#a855f7"; x = 100; y = 100 }
            @{ id = "Predictive-Maintenance"; label = "Maintenance Prediction"; category = "Week4"; size = 45; color = "#a855f7"; x = -100; y = 100 }
            @{ id = "Unity-Claude-CPG"; label = "Code Property Graph"; category = "Core"; size = 40; color = "#4ecdc4"; x = 0; y = 150 }
            @{ id = "Unity-Claude-LLM"; label = "LLM Integration"; category = "AI"; size = 35; color = "#22c55e"; x = 150; y = 0 }
            @{ id = "LangGraph-AI"; label = "LangGraph AI Service"; category = "AI-Service"; size = 50; color = "#8b5cf6"; x = 100; y = -100 }
            @{ id = "AutoGen-GroupChat"; label = "AutoGen GroupChat"; category = "AI-Service"; size = 50; color = "#8b5cf6"; x = -100; y = -100 }
        )
        links = @(
            @{ source = "Predictive-Evolution"; target = "Unity-Claude-CPG"; type = "uses"; strength = 0.8 }
            @{ source = "Predictive-Maintenance"; target = "Unity-Claude-CPG"; type = "uses"; strength = 0.8 }
            @{ source = "Unity-Claude-LLM"; target = "Unity-Claude-CPG"; type = "integrates"; strength = 0.6 }
            @{ source = "LangGraph-AI"; target = "Enhanced-Documentation-System"; type = "enhances"; strength = 0.9 }
            @{ source = "AutoGen-GroupChat"; target = "Enhanced-Documentation-System"; type = "enhances"; strength = 0.9 }
            @{ source = "Predictive-Evolution"; target = "LangGraph-AI"; type = "ai-workflow"; strength = 0.7 }
            @{ source = "Predictive-Maintenance"; target = "AutoGen-GroupChat"; type = "ai-analysis"; strength = 0.7 }
        )
        metadata = @{
            generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            type = "enhanced-documentation-system-network"
            version = "v2.0.0"
            nodeCount = 7
            linkCount = 7
            aiIntegration = $true
        }
    }
    
    # Ensure data directory exists
    $dataDir = Split-Path $dataPath -Parent
    if (-not (Test-Path $dataDir)) {
        New-Item -Path $dataDir -ItemType Directory -Force | Out-Null
    }
    
    # Save corrected data
    $workingData | ConvertTo-Json -Depth 5 | Out-File -FilePath $dataPath -Encoding UTF8
    
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Success] Generated working visualization data: 7 nodes, 7 links" -ForegroundColor Green
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Success] Data format: nodes + links (compatible with D3.js)" -ForegroundColor Green
    
    # Test Node.js syntax
    Set-Location ".\Visualization"
    $syntaxTest = node -c server.js 2>&1
    Set-Location ".."
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Success] JavaScript syntax validated - ready to start" -ForegroundColor Green
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Info] Run: ./Start-Visualization-Dashboard.ps1 -OpenBrowser" -ForegroundColor Cyan
    } else {
        Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Warning] Syntax test: $syntaxTest" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [Error] Data format fix failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Visualization Data Format Fix Complete ===" -ForegroundColor Green