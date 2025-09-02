# Generate-Real-Visualization-Data.ps1
# Generates comprehensive visualization data from actual Week 4 analysis
# Replaces mock data with real code analysis for D3.js dashboard
# Date: 2025-08-29

param(
    [string]$ModulesPath = ".\Modules",
    [string]$DataPath = ".\Visualization\public\static\data",
    [switch]$Verbose
)

function Write-DataLog {
    param([string]$Message, [string]$Level = "Info")
    $color = @{ "Info" = "White"; "Success" = "Green"; "Warning" = "Yellow"; "Error" = "Red"; "Data" = "Magenta" }[$Level]
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message" -ForegroundColor $color
}

Write-Host "=== Generating Real Visualization Data from Week 4 Analysis ===" -ForegroundColor Cyan

try {
    # Ensure data directory exists
    if (-not (Test-Path $DataPath)) {
        New-Item -Path $DataPath -ItemType Directory -Force | Out-Null
        Write-DataLog "Created data directory: $DataPath" -Level "Success"
    }
    
    # Generate comprehensive code analysis data
    Write-DataLog "Analyzing complete module ecosystem for visualization..." -Level "Info"
    
    # Get all PowerShell modules for analysis
    $allModules = Get-ChildItem -Path $ModulesPath -Filter "*.psm1" -Recurse | Where-Object {
        $_.FullName -notmatch "backup|temp|test" -and
        $_.Length -gt 1000  # Only significant modules
    }
    
    Write-DataLog "Found $($allModules.Count) modules for visualization analysis" -Level "Info"
    
    # Generate Week 4 churn analysis for all modules
    if (Get-Command Get-CodeChurnMetrics -ErrorAction SilentlyContinue) {
        Write-DataLog "Generating code churn analysis..." -Level "Data"
        
        $churnData = Get-CodeChurnMetrics -Path $ModulesPath -Since "6.months.ago"
        
        # Create comprehensive visualization dataset
        $vizData = @{
            nodes = @()
            edges = @()
            metadata = @{
                generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                type = "enhanced-documentation-analysis"
                totalModules = $allModules.Count
                churnAnalysis = $churnData.Count
                systemVersion = "v2.0.0"
            }
        }
        
        # Add nodes for each module with Week 4 analysis data
        foreach ($module in $allModules) {
            $moduleName = $module.BaseName
            $relativePath = $module.FullName.Replace((Get-Location).Path, "").TrimStart('\')
            
            # Find churn data for this module
            $moduleChurn = $churnData | Where-Object { $_.FilePath -like "*$moduleName*" } | Select-Object -First 1
            
            # Get module complexity
            $content = Get-Content $module.FullName -ErrorAction SilentlyContinue
            $functionCount = ($content | Select-String -Pattern "^function\s+" -AllMatches).Count
            $lineCount = $content.Count
            
            # Calculate module metrics
            $churnScore = if ($moduleChurn) { $moduleChurn.ChurnScore } else { 0.1 }
            $complexity = [math]::Max($functionCount * 2 + ($lineCount / 100), 1)
            
            # Determine node size and color based on analysis
            $nodeSize = [math]::Min([math]::Max($complexity * 2, 10), 100)
            $nodeColor = if ($churnScore -gt 3) { "#ff4444" }        # High churn - red
                        elseif ($churnScore -gt 1) { "#ffaa44" }     # Medium churn - orange  
                        elseif ($complexity -gt 20) { "#4444ff" }   # High complexity - blue
                        else { "#44aa44" }                          # Normal - green
            
            $vizData.nodes += @{
                id = $moduleName
                label = $moduleName
                path = $relativePath
                size = $nodeSize
                color = $nodeColor
                type = "module"
                metrics = @{
                    churnScore = [math]::Round($churnScore, 2)
                    complexity = [math]::Round($complexity, 2)
                    functions = $functionCount
                    lines = $lineCount
                    changeCount = if ($moduleChurn) { $moduleChurn.ChangeCount } else { 0 }
                }
                category = if ($relativePath -match "Week4|Predictive") { "Week4-Predictive" }
                          elseif ($relativePath -match "CPG") { "Core-Analysis" }
                          elseif ($relativePath -match "LLM") { "AI-Integration" }
                          else { "General" }
            }
        }
        
        # Add edges for module relationships (simplified)
        $categories = $vizData.nodes | Group-Object category
        
        foreach ($category in $categories) {
            $categoryNodes = $category.Group
            
            # Create connections within categories
            for ($i = 0; $i -lt $categoryNodes.Count - 1; $i++) {
                $vizData.edges += @{
                    source = $categoryNodes[$i].id
                    target = $categoryNodes[$i + 1].id
                    type = "category-relationship"
                    strength = 0.5
                    category = $category.Name
                }
            }
        }
        
        # Add special Week 4 connections
        $week4Nodes = $vizData.nodes | Where-Object { $_.category -eq "Week4-Predictive" }
        $coreNodes = $vizData.nodes | Where-Object { $_.category -eq "Core-Analysis" }
        
        if ($week4Nodes -and $coreNodes) {
            foreach ($week4 in $week4Nodes) {
                $targetCore = $coreNodes | Select-Object -First 1
                $vizData.edges += @{
                    source = $week4.id
                    target = $targetCore.id
                    type = "integration"
                    strength = 0.8
                    category = "Week4-Integration"
                }
            }
        }
        
        # Save comprehensive visualization data
        $vizData | ConvertTo-Json -Depth 10 | Out-File -FilePath "$DataPath\real-analysis-data.json" -Encoding UTF8
        
        Write-DataLog "Generated comprehensive visualization data:" -Level "Success"
        Write-DataLog "  • Nodes: $($vizData.nodes.Count) modules analyzed" -Level "Success"
        Write-DataLog "  • Edges: $($vizData.edges.Count) relationships mapped" -Level "Success" 
        Write-DataLog "  • Categories: $($categories.Count) module categories" -Level "Success"
        Write-DataLog "  • Week 4 Features: $(($vizData.nodes | Where-Object { $_.category -eq 'Week4-Predictive' }).Count) predictive modules" -Level "Success"
        
    } else {
        Write-DataLog "Week 4 churn analysis not available" -Level "Warning"
    }
    
    # Generate hotspot visualization data
    if (Get-Command Get-FileHotspots -ErrorAction SilentlyContinue) {
        Write-DataLog "Generating hotspot analysis visualization..." -Level "Data"
        
        $hotspots = Get-FileHotspots -Path $ModulesPath -Top 50
        
        if ($hotspots) {
            $hotspotViz = @{
                hotspots = $hotspots | ForEach-Object {
                    @{
                        id = [System.IO.Path]::GetFileNameWithoutExtension($_.FilePath)
                        file = $_.FilePath
                        hotspotScore = $_.HotspotScore
                        complexity = $_.ComplexityScore
                        churn = $_.ChurnScore
                        priority = $_.RefactoringPriority
                        changeCount = $_.ChangeCount
                        size = [math]::Min([math]::Max($_.HotspotScore * 5, 15), 80)
                        color = switch ($_.RefactoringPriority) {
                            "Critical" { "#ff0000" }
                            "High" { "#ff6600" }
                            "Medium" { "#ffaa00" } 
                            default { "#00aa00" }
                        }
                    }
                }
                metadata = @{
                    generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    type = "hotspot-analysis"
                    totalHotspots = $hotspots.Count
                    criticalCount = ($hotspots | Where-Object { $_.RefactoringPriority -eq "Critical" }).Count
                    highCount = ($hotspots | Where-Object { $_.RefactoringPriority -eq "High" }).Count
                }
            }
            
            $hotspotViz | ConvertTo-Json -Depth 10 | Out-File -FilePath "$DataPath\hotspot-analysis.json" -Encoding UTF8
            Write-DataLog "Generated hotspot visualization: $($hotspots.Count) hotspots analyzed" -Level "Success"
        }
    }
    
    # Create data index for visualization dashboard
    $dataIndex = @{
        datasets = @(
            @{
                name = "Real Analysis Data"
                file = "real-analysis-data.json"
                type = "network"
                description = "Complete module ecosystem with Week 4 predictive analysis"
                nodeCount = $vizData.nodes.Count
                edgeCount = $vizData.edges.Count
            }
            @{
                name = "Hotspot Analysis"  
                file = "hotspot-analysis.json"
                type = "scatter"
                description = "Code hotspots with refactoring priorities"
                dataPoints = if ($hotspots) { $hotspots.Count } else { 0 }
            }
        )
        generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        system = "Enhanced Documentation System v2.0.0"
    }
    
    $dataIndex | ConvertTo-Json -Depth 5 | Out-File -FilePath "$DataPath\data-index.json" -Encoding UTF8
    
    Write-DataLog "Real visualization data generation complete!" -Level "Success"
    Write-DataLog "Nodes: $($vizData.nodes.Count) (was 7 mock nodes)" -Level "Success"
    Write-DataLog "Comprehensive analysis: $($allModules.Count) modules processed" -Level "Success"
    
} catch {
    Write-DataLog "Real data generation failed: $($_.Exception.Message)" -Level "Error"
}

Write-Host "`n=== Real Visualization Data Generated ===" -ForegroundColor Green