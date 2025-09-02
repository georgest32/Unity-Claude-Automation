# Generate-Module-Visualization-Direct.ps1
# Direct module analysis for visualization without Week 4 function dependencies
# Creates comprehensive visualization data from actual module analysis
# Date: 2025-08-29

param(
    [string]$ModulesPath = ".\Modules",
    [string]$DataPath = ".\Visualization\public\static\data"
)

function Write-VizLog {
    param([string]$Message, [string]$Level = "Info")
    $color = @{ "Info" = "White"; "Success" = "Green"; "Warning" = "Yellow"; "Error" = "Red"; "Data" = "Magenta" }[$Level]
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message" -ForegroundColor $color
}

Write-Host "=== Direct Module Visualization Data Generation ===" -ForegroundColor Cyan

try {
    # Ensure data directory exists
    if (-not (Test-Path $DataPath)) {
        New-Item -Path $DataPath -ItemType Directory -Force | Out-Null
    }
    
    # Get key modules for visualization (focus on important ones)
    $keyModules = Get-ChildItem -Path $ModulesPath -Filter "*.psm1" -Recurse | Where-Object {
        $_.FullName -match "(CPG|LLM|Predictive|API|Documentation)" -and
        $_.FullName -notmatch "backup|temp|test" -and
        $_.Length -gt 2000  # Significant modules only
    }
    
    Write-VizLog "Analyzing $($keyModules.Count) key modules for visualization..." -Level "Info"
    
    $vizData = @{
        nodes = @()
        edges = @()
        metadata = @{
            generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            type = "enhanced-documentation-system-analysis" 
            version = "v2.0.0"
            totalModules = $keyModules.Count
            analysisType = "direct-module-analysis"
        }
    }
    
    # Process each module
    foreach ($module in $keyModules) {
        try {
            $moduleName = $module.BaseName
            $content = Get-Content $module.FullName -ErrorAction SilentlyContinue
            
            if ($content) {
                # Extract module metrics
                $functionCount = ($content | Select-String -Pattern "^function\s+" -AllMatches).Count
                $lineCount = $content.Count
                $classCount = ($content | Select-String -Pattern "^class\s+" -AllMatches).Count
                
                # Calculate complexity score
                $complexity = [math]::Round(($functionCount * 2) + ($lineCount / 100) + ($classCount * 3), 2)
                
                # Determine module category
                $category = if ($moduleName -match "Predictive") { "Week4-Predictive" }
                           elseif ($moduleName -match "CPG|Graph") { "Core-Analysis" }  
                           elseif ($moduleName -match "LLM|AI") { "AI-Integration" }
                           elseif ($moduleName -match "API|Documentation") { "Documentation" }
                           elseif ($moduleName -match "Parallel|Performance") { "Performance" }
                           else { "General" }
                
                # Determine visual properties
                $nodeSize = [math]::Min([math]::Max($complexity * 1.5, 15), 80)
                $nodeColor = switch ($category) {
                    "Week4-Predictive" { "#ff6b35" }  # Orange for Week 4
                    "Core-Analysis" { "#4ecdc4" }     # Teal for core
                    "AI-Integration" { "#a855f7" }    # Purple for AI
                    "Documentation" { "#22c55e" }     # Green for docs
                    "Performance" { "#3b82f6" }      # Blue for performance
                    default { "#6b7280" }             # Gray for general
                }
                
                # Add node to visualization
                $vizData.nodes += @{
                    id = $moduleName
                    label = $moduleName
                    category = $category
                    size = $nodeSize
                    color = $nodeColor
                    metrics = @{
                        functions = $functionCount
                        lines = $lineCount
                        classes = $classCount
                        complexity = $complexity
                        fileSize = [math]::Round($module.Length / 1KB, 2)
                    }
                    path = $module.FullName.Replace((Get-Location).Path, "").TrimStart('\')
                }
                
                Write-VizLog "Processed: $moduleName ($functionCount functions, $lineCount lines)" -Level "Data"
            }
            
        } catch {
            Write-VizLog "Skipped $($module.BaseName): $($_.Exception.Message)" -Level "Warning"
        }
    }
    
    # Create category-based edges
    $categories = $vizData.nodes | Group-Object category
    
    foreach ($categoryGroup in $categories) {
        $categoryNodes = $categoryGroup.Group
        
        # Connect nodes within same category
        for ($i = 0; $i -lt $categoryNodes.Count - 1; $i++) {
            $vizData.edges += @{
                source = $categoryNodes[$i].id
                target = $categoryNodes[$i + 1].id
                type = "category-connection"
                category = $categoryGroup.Name
                strength = 0.3
            }
        }
    }
    
    # Create inter-category connections
    $week4Nodes = $vizData.nodes | Where-Object { $_.category -eq "Week4-Predictive" }
    $coreNodes = $vizData.nodes | Where-Object { $_.category -eq "Core-Analysis" }
    $aiNodes = $vizData.nodes | Where-Object { $_.category -eq "AI-Integration" }
    
    # Connect Week 4 to Core
    foreach ($week4 in $week4Nodes) {
        $coreTarget = $coreNodes | Select-Object -First 1
        if ($coreTarget) {
            $vizData.edges += @{
                source = $week4.id
                target = $coreTarget.id
                type = "integration"
                category = "Week4-Core-Integration"
                strength = 0.7
            }
        }
    }
    
    # Connect AI to Core
    foreach ($ai in $aiNodes) {
        $coreTarget = $coreNodes | Select-Object -First 1
        if ($coreTarget) {
            $vizData.edges += @{
                source = $ai.id
                target = $coreTarget.id
                type = "ai-integration"
                category = "AI-Core-Integration"
                strength = 0.6
            }
        }
    }
    
    # Save the comprehensive visualization data
    $vizData | ConvertTo-Json -Depth 10 | Out-File -FilePath "$DataPath\enhanced-system-graph.json" -Encoding UTF8
    
    Write-VizLog "Comprehensive visualization data generated!" -Level "Success"
    Write-VizLog "Total nodes: $($vizData.nodes.Count) modules" -Level "Success"
    Write-VizLog "Total edges: $($vizData.edges.Count) relationships" -Level "Success"
    Write-VizLog "Categories: $(($categories | Select-Object Name).Name -join ', ')" -Level "Success"
    
    # Create category summary
    foreach ($cat in $categories) {
        Write-VizLog "  $($cat.Name): $($cat.Count) modules" -Level "Data"
    }
    
    # Update visualization to use real data
    Write-VizLog "Updating visualization dashboard to use real data..." -Level "Info"
    
    # Create a simple data endpoint override
    $dataOverride = @"
// Real data override for Enhanced Documentation System visualization
const realSystemData = $(($vizData | ConvertTo-Json -Depth 10));

// Export for use in visualization
if (typeof module !== 'undefined') {
    module.exports = realSystemData;
}
"@
    
    $dataOverride | Out-File -FilePath "$DataPath\real-system-data.js" -Encoding UTF8
    Write-VizLog "Created real data override: real-system-data.js" -Level "Success"
    
    Write-VizLog "🎨 Visualization now shows $($vizData.nodes.Count) real modules instead of 7 mock nodes!" -Level "Success"
    Write-VizLog "📊 Refresh your browser at http://localhost:3000 to see the complete system" -Level "Success"
    
} catch {
    Write-VizLog "Direct visualization generation failed: $($_.Exception.Message)" -Level "Error"
}

Write-Host "`n=== Module Visualization Data Generated ===" -ForegroundColor Green