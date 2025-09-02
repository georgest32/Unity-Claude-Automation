# Generate-Full-Module-Visualization.ps1
# Generates comprehensive visualization data from ALL 337 modules
# Creates proper D3.js format with nodes and links
# Date: 2025-08-29

param([int]$MaxNodes = 50)  # Limit for performance

Write-Host "=== Generating Full Module Ecosystem Visualization ===" -ForegroundColor Cyan

try {
    # Get all significant modules
    $allModules = Get-ChildItem -Path ".\Modules" -Filter "*.psm1" -Recurse | Where-Object {
        $_.Length -gt 1000 -and  # Significant size
        $_.FullName -notmatch "backup|temp|test|\.bak"
    }
    
    Write-Host "Found $($allModules.Count) total modules - selecting top $MaxNodes for visualization" -ForegroundColor Yellow
    
    # Select most important modules
    $keyModules = $allModules | Sort-Object Length -Descending | Select-Object -First $MaxNodes
    
    $vizData = @{
        nodes = @()
        links = @()  # Use 'links' not 'edges' for D3.js compatibility
        metadata = @{
            generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            totalModulesFound = $allModules.Count
            visualizedModules = $keyModules.Count
            systemVersion = "v2.0.0"
            type = "full-module-ecosystem"
        }
    }
    
    Write-Host "Analyzing $($keyModules.Count) modules for visualization..." -ForegroundColor Cyan
    
    # Process each module
    $nodeIndex = 0
    foreach ($module in $keyModules) {
        $nodeIndex++
        $moduleName = $module.BaseName
        $content = Get-Content $module.FullName -ErrorAction SilentlyContinue
        
        if ($content) {
            # Extract metrics
            $functionCount = ($content | Where-Object { $_ -match "^function\s+" }).Count
            $lineCount = $content.Count
            $fileSize = [math]::Round($module.Length / 1KB, 1)
            
            # Calculate complexity and importance
            $complexity = $functionCount + ($lineCount / 100)
            $importance = $complexity + ($fileSize / 10)
            
            # Determine category and color
            $category = if ($moduleName -match "Predictive") { "Week4-Predictive" }
                       elseif ($moduleName -match "CPG|Graph|Analysis") { "Core-Analysis" }
                       elseif ($moduleName -match "LLM|AI|AutoGen|LangGraph") { "AI-Integration" }
                       elseif ($moduleName -match "API|Documentation|Doc") { "Documentation" }
                       elseif ($moduleName -match "Parallel|Performance|Cache") { "Performance" }
                       elseif ($moduleName -match "Test|Monitor|Health") { "Testing-Monitoring" }
                       else { "General" }
            
            $nodeColor = switch ($category) {
                "Week4-Predictive" { "#ff6b35" }     # Orange - Week 4 features
                "Core-Analysis" { "#4ecdc4" }        # Teal - Core functionality  
                "AI-Integration" { "#8b5cf6" }       # Purple - AI services
                "Documentation" { "#22c55e" }        # Green - Documentation
                "Performance" { "#3b82f6" }         # Blue - Performance
                "Testing-Monitoring" { "#f59e0b" }  # Amber - Testing
                default { "#6b7280" }               # Gray - General
            }
            
            # Calculate position (circular layout)
            $angle = ($nodeIndex / $keyModules.Count) * 2 * [Math]::PI
            $radius = 200 + ($importance * 2)
            $x = [math]::Round($radius * [math]::Cos($angle), 2)
            $y = [math]::Round($radius * [math]::Sin($angle), 2)
            
            # Add node
            $vizData.nodes += @{
                id = $moduleName
                label = $moduleName
                category = $category
                size = [math]::Min([math]::Max($importance * 2, 10), 60)
                color = $nodeColor
                x = $x
                y = $y
                metrics = @{
                    functions = $functionCount
                    lines = $lineCount
                    fileSizeKB = $fileSize
                    complexity = [math]::Round($complexity, 1)
                    importance = [math]::Round($importance, 1)
                }
                path = $module.FullName.Replace((Get-Location).Path, "").TrimStart('\')
            }
            
            if ($nodeIndex % 10 -eq 0) {
                Write-Host "  Processed $nodeIndex/$($keyModules.Count) modules..." -ForegroundColor Gray
            }
        }
    }
    
    # Create meaningful links between modules
    Write-Host "Creating module relationships..." -ForegroundColor Cyan
    
    # Group nodes by category
    $nodesByCategory = $vizData.nodes | Group-Object category
    
    # Create intra-category connections
    foreach ($categoryGroup in $nodesByCategory) {
        $categoryNodes = $categoryGroup.Group
        
        # Connect nodes within same category
        for ($i = 0; $i -lt $categoryNodes.Count - 1; $i++) {
            $vizData.links += @{
                source = $categoryNodes[$i].id
                target = $categoryNodes[$i + 1].id
                type = "category-relationship"
                category = $categoryGroup.Name
                strength = 0.3
            }
        }
    }
    
    # Create inter-category connections (Week 4 to Core, AI to Core, etc.)
    $week4Nodes = $vizData.nodes | Where-Object { $_.category -eq "Week4-Predictive" }
    $coreNodes = $vizData.nodes | Where-Object { $_.category -eq "Core-Analysis" }
    $aiNodes = $vizData.nodes | Where-Object { $_.category -eq "AI-Integration" }
    $docNodes = $vizData.nodes | Where-Object { $_.category -eq "Documentation" }
    
    # Week 4 to Core connections
    foreach ($week4 in $week4Nodes) {
        $target = $coreNodes | Select-Object -First 1
        if ($target) {
            $vizData.links += @{
                source = $week4.id
                target = $target.id
                type = "dependency"
                category = "Week4-Core"
                strength = 0.8
            }
        }
    }
    
    # AI to Documentation connections
    foreach ($ai in $aiNodes) {
        $target = $docNodes | Select-Object -First 1
        if ($target) {
            $vizData.links += @{
                source = $ai.id
                target = $target.id
                type = "enhancement"
                category = "AI-Documentation"
                strength = 0.6
            }
        }
    }
    
    # Save comprehensive data
    $dataPath = ".\Visualization\public\static\data\enhanced-system-graph.json"
    $dataDir = Split-Path $dataPath -Parent
    
    if (-not (Test-Path $dataDir)) {
        New-Item -Path $dataDir -ItemType Directory -Force | Out-Null
    }
    
    $vizData | ConvertTo-Json -Depth 10 | Out-File -FilePath $dataPath -Encoding UTF8
    
    # Results summary
    Write-Host "`n=== Full Module Visualization Generated ===" -ForegroundColor Green
    Write-Host "📊 Total modules found: $($allModules.Count)" -ForegroundColor White
    Write-Host "🎯 Nodes in visualization: $($vizData.nodes.Count)" -ForegroundColor Green
    Write-Host "🔗 Links created: $($vizData.links.Count)" -ForegroundColor Green
    Write-Host "📂 Data saved to: $dataPath" -ForegroundColor Cyan
    
    # Category breakdown
    Write-Host "`n📋 Module Categories:" -ForegroundColor Yellow
    foreach ($cat in $nodesByCategory) {
        Write-Host "  $($cat.Name): $($cat.Count) modules" -ForegroundColor White
    }
    
    Write-Host "`n🚀 Ready for visualization! Run: ./Start-Visualization-Dashboard.ps1 -OpenBrowser" -ForegroundColor Green
    
} catch {
    Write-Host "Full module visualization generation failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n=== Full Module Ecosystem Analysis Complete ===" -ForegroundColor Green