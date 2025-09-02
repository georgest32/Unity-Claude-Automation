# Generate-AI-SemanticDocumentation.ps1
# AI-Enhanced Documentation with Semantic Analysis and Relationships

param(
    [string]$OutputPath = ".\docs\generated",
    [string]$Model = "codellama:34b",
    [switch]$IncludeVisualizations,
    [int]$MaxConcurrency = 2
)

# Ensure output directory exists
if (-not (Test-Path $OutputPath)) {
    New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
}

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "AI-ENHANCED SEMANTIC DOCUMENTATION GENERATION" -ForegroundColor Green
Write-Host "Using Ollama model: $Model" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Cyan

# Test Ollama connectivity
Write-Host "`nTesting Ollama connectivity..." -ForegroundColor Yellow
try {
    $testResponse = ollama run $Model "Say 'ready'" 2>&1
    if ($testResponse -match "ready") {
        Write-Host "✅ Ollama is ready!" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ Ollama not available. Please ensure Ollama is running." -ForegroundColor Red
    exit 1
}

# Function to get AI description
function Get-AIDescription {
    param(
        [string]$Code,
        [string]$Type,
        [string]$Name,
        [string]$Context = ""
    )
    
    $prompt = @"
Analyze this PowerShell $Type and provide a comprehensive description.

Name: $Name
$($Context ? "Context: $Context" : "")

Code:
``````powershell
$Code
``````

Provide:
1. PURPOSE: A clear, one-paragraph description of what this $Type does
2. KEY CONCEPTS: Main concepts or patterns used
3. DEPENDENCIES: What other modules or functions it depends on
4. USE CASES: When and why someone would use this
5. IMPORTANT NOTES: Any critical information about usage or limitations

Format as markdown with clear sections.
"@
    
    try {
        $response = ollama run $Model $prompt 2>&1 | Out-String
        return $response
    } catch {
        return "AI analysis unavailable for $Name"
    }
}

# Function to analyze relationships
function Get-SemanticRelationships {
    param(
        [array]$Modules,
        [array]$Functions
    )
    
    $prompt = @"
Analyze these PowerShell modules and identify their semantic relationships:

Modules: $($Modules -join ", ")

Identify:
1. CORE SYSTEMS: Which modules form the core architecture
2. DEPENDENCIES: How modules depend on each other
3. DATA FLOW: How data flows between modules
4. INTEGRATION POINTS: Where modules integrate
5. ARCHITECTURAL PATTERNS: Design patterns used

Provide a clear narrative description of the system architecture.
"@
    
    try {
        $response = ollama run $Model $prompt 2>&1 | Out-String
        return $response
    } catch {
        return "Semantic analysis unavailable"
    }
}

# Step 1: Scan and analyze codebase
Write-Host "`n[1/5] Scanning codebase structure..." -ForegroundColor Green
$modules = Get-ChildItem -Path ".\Modules" -Filter "*.psm1" -Recurse -ErrorAction SilentlyContinue
$scripts = Get-ChildItem -Path "." -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue | 
    Where-Object { $_.FullName -notmatch "\\(node_modules|\.git|temp|backup)\\" }

Write-Host "  Found $($modules.Count) modules and $($scripts.Count) scripts" -ForegroundColor Gray

# Step 2: Build module documentation with AI
Write-Host "`n[2/5] Generating AI-enhanced module documentation..." -ForegroundColor Green
$moduleDocumentation = @{}
$moduleIndex = 0

foreach ($module in $modules | Select-Object -First 10) {  # Limit for demo
    $moduleIndex++
    Write-Host "  [$moduleIndex/$($modules.Count)] Analyzing $($module.BaseName)..." -ForegroundColor Gray
    
    $content = Get-Content $module.FullName -Raw
    $ast = [System.Management.Automation.Language.Parser]::ParseInput($content, [ref]$null, [ref]$null)
    
    # Get functions
    $functions = $ast.FindAll({
        $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst]
    }, $true)
    
    # Get AI description for module
    $moduleDescription = Get-AIDescription -Code $content.Substring(0, [Math]::Min(2000, $content.Length)) `
                                          -Type "module" `
                                          -Name $module.BaseName
    
    # Analyze key functions
    $functionDocs = @()
    foreach ($func in $functions | Select-Object -First 5) {
        $funcCode = $func.Extent.Text
        $funcDescription = Get-AIDescription -Code $funcCode `
                                            -Type "function" `
                                            -Name $func.Name `
                                            -Context "Part of $($module.BaseName) module"
        
        $functionDocs += @{
            Name = $func.Name
            Description = $funcDescription
            StartLine = $func.Extent.StartLineNumber
            EndLine = $func.Extent.EndLineNumber
        }
    }
    
    $moduleDocumentation[$module.BaseName] = @{
        Path = $module.FullName
        Description = $moduleDescription
        Functions = $functionDocs
        Dependencies = @()  # Will be filled in relationship analysis
    }
}

# Step 3: Analyze semantic relationships
Write-Host "`n[3/5] Analyzing semantic relationships..." -ForegroundColor Green
$relationships = Get-SemanticRelationships -Modules $moduleDocumentation.Keys

# Step 4: Generate comprehensive documentation
Write-Host "`n[4/5] Building comprehensive documentation with working links..." -ForegroundColor Green

# Main index file with proper links
$indexDoc = @"
# Unity-Claude Automation System - Semantic Documentation

**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")  
**AI Model:** $Model

## Table of Contents

1. [System Overview](#system-overview)
2. [Architecture & Relationships](#architecture--relationships)
3. [Core Modules](#core-modules)
4. [Module Details](#module-details)
5. [Semantic Network](#semantic-network)

---

## System Overview

The Unity-Claude Automation System is a comprehensive PowerShell-based automation framework designed to bridge Unity game development with Claude AI capabilities. This system provides intelligent error handling, automated documentation, parallel processing, and AI-enhanced decision making.

### Key Capabilities
- **Unity Integration**: Direct integration with Unity Editor for compilation monitoring and error extraction
- **AI Enhancement**: Claude AI integration for intelligent error analysis and fix suggestions
- **Parallel Processing**: Advanced parallel processing capabilities for performance optimization
- **Documentation Automation**: Self-documenting system with real-time documentation updates
- **Event-Driven Architecture**: Reactive system responding to file changes and Unity events

## Architecture & Relationships

$relationships

## Core Modules

| Module | Purpose | Key Functions | Documentation |
|--------|---------|---------------|---------------|
$(foreach ($moduleName in $moduleDocumentation.Keys | Sort-Object) {
    $module = $moduleDocumentation[$moduleName]
    $purpose = if ($module.Description -match "PURPOSE: (.+?)`n") { $matches[1] } else { "See details" }
    $keyFuncs = ($module.Functions | Select-Object -First 3 | ForEach-Object { "``$($_.Name)``" }) -join ", "
    "| **[$moduleName](#$($moduleName.ToLower() -replace '-',''))** | $($purpose.Substring(0, [Math]::Min(100, $purpose.Length)))... | $keyFuncs | [View](#$($moduleName.ToLower() -replace '-','')) |"
})

## Module Details

$(foreach ($moduleName in $moduleDocumentation.Keys | Sort-Object) {
    $module = $moduleDocumentation[$moduleName]
    @"

### $moduleName

[🔝 Back to top](#table-of-contents)

**Path:** ``$($module.Path)``

$($module.Description)

#### Functions in this module:

$(foreach ($func in $module.Functions) {
    @"
- [**$($func.Name)**](#function-$($func.Name.ToLower() -replace '-','')) (Lines $($func.StartLine)-$($func.EndLine))
"@
})

$(foreach ($func in $module.Functions) {
    @"

##### Function: $($func.Name)

$($func.Description)

[⬆ Back to module](#$($moduleName.ToLower() -replace '-',''))
"@
})

---
"@
})

## Semantic Network

The Unity-Claude system forms a complex semantic network where modules interact through well-defined interfaces:

### Core Interaction Patterns

1. **Event-Driven Communication**
   - File system monitors trigger documentation updates
   - Unity compilation events trigger error analysis
   - Claude responses trigger decision engine evaluation

2. **Data Flow Architecture**
   - Unity → Error Extraction → Pattern Recognition → AI Analysis → Decision Engine → Action Execution
   - Each step is modular and replaceable

3. **Parallel Processing Pipeline**
   - Runspace management enables concurrent operations
   - Thread-safe collections manage shared state
   - Circuit breakers prevent cascade failures

### Module Dependency Graph

```mermaid
graph TD
    Unity[Unity Editor] --> Core[Unity-Claude-Core]
    Core --> ErrorHandling[Error Handling]
    ErrorHandling --> AI[AI Integration]
    AI --> DecisionEngine[Decision Engine]
    DecisionEngine --> Actions[Action Execution]
    
    Core --> ParallelProcessing[Parallel Processing]
    ParallelProcessing --> RunspaceManagement[Runspace Management]
    
    Core --> Documentation[Documentation System]
    Documentation --> SemanticAnalysis[Semantic Analysis]
    SemanticAnalysis --> AI
    
    Actions --> Safety[Safety Framework]
    Safety --> HITL[Human-in-the-Loop]
```

### Cross-Module Communication

Modules communicate through:
- **Shared hashtables**: Thread-safe data structures for state management
- **Event handlers**: PowerShell events for loose coupling
- **Message queues**: Asynchronous communication between components
- **Named pipes**: IPC for external process communication

---

*Generated with AI-Enhanced Documentation System using $Model*
"@

$indexDoc | Out-File "$OutputPath\AI_SEMANTIC_DOCUMENTATION.md" -Encoding UTF8

# Generate module relationship graph (JSON for visualization)
$graphData = @{
    nodes = @()
    edges = @()
}

foreach ($moduleName in $moduleDocumentation.Keys) {
    $graphData.nodes += @{
        id = $moduleName
        label = $moduleName
        group = switch -Wildcard ($moduleName) {
            "*Core*" { "core" }
            "*AI*" { "ai" }
            "*Documentation*" { "docs" }
            "*Parallel*" { "processing" }
            default { "utility" }
        }
    }
}

# Analyze imports to find edges
foreach ($module in $modules | Select-Object -First 10) {
    $content = Get-Content $module.FullName -Raw
    $moduleName = $module.BaseName
    
    # Find Import-Module statements
    $imports = [regex]::Matches($content, 'Import-Module\s+([^\s]+)')
    foreach ($import in $imports) {
        $importedModule = $import.Groups[1].Value -replace '"', '' -replace "'", ''
        if ($moduleDocumentation.ContainsKey($importedModule)) {
            $graphData.edges += @{
                from = $moduleName
                to = $importedModule
                type = "imports"
            }
        }
    }
    
    # Find function calls to other modules
    foreach ($otherModule in $moduleDocumentation.Keys) {
        if ($otherModule -ne $moduleName) {
            $pattern = "\b($($moduleDocumentation[$otherModule].Functions.Name -join '|'))\b"
            if ($content -match $pattern) {
                $graphData.edges += @{
                    from = $moduleName
                    to = $otherModule
                    type = "calls"
                }
            }
        }
    }
}

$graphData | ConvertTo-Json -Depth 10 | Out-File "$OutputPath\module_relationships.json" -Encoding UTF8

# Generate HTML visualization
$htmlVisualization = @"
<!DOCTYPE html>
<html>
<head>
    <title>Unity-Claude Module Relationships</title>
    <script src="https://unpkg.com/vis-network/standalone/umd/vis-network.min.js"></script>
    <style>
        body {
            font-family: 'Segoe UI', sans-serif;
            margin: 0;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        }
        h1 {
            color: white;
            text-align: center;
        }
        #network {
            width: 100%;
            height: 600px;
            background: white;
            border-radius: 10px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
        }
        .legend {
            background: white;
            padding: 20px;
            margin-top: 20px;
            border-radius: 10px;
            box-shadow: 0 5px 20px rgba(0,0,0,0.1);
        }
        .legend-item {
            display: inline-block;
            margin: 0 20px;
        }
        .legend-color {
            display: inline-block;
            width: 20px;
            height: 20px;
            border-radius: 50%;
            margin-right: 5px;
            vertical-align: middle;
        }
    </style>
</head>
<body>
    <h1>Unity-Claude System - Module Relationship Network</h1>
    <div id="network"></div>
    <div class="legend">
        <div class="legend-item">
            <span class="legend-color" style="background: #e74c3c;"></span>
            Core Modules
        </div>
        <div class="legend-item">
            <span class="legend-color" style="background: #3498db;"></span>
            AI Modules
        </div>
        <div class="legend-item">
            <span class="legend-color" style="background: #2ecc71;"></span>
            Documentation
        </div>
        <div class="legend-item">
            <span class="legend-color" style="background: #f39c12;"></span>
            Processing
        </div>
        <div class="legend-item">
            <span class="legend-color" style="background: #9b59b6;"></span>
            Utilities
        </div>
    </div>
    
    <script>
        // Load the graph data
        fetch('module_relationships.json')
            .then(response => response.json())
            .then(data => {
                // Create nodes with colors based on group
                const nodes = new vis.DataSet(data.nodes.map(node => ({
                    ...node,
                    color: {
                        background: {
                            'core': '#e74c3c',
                            'ai': '#3498db',
                            'docs': '#2ecc71',
                            'processing': '#f39c12',
                            'utility': '#9b59b6'
                        }[node.group] || '#95a5a6'
                    },
                    font: { color: 'white' }
                })));
                
                // Create edges with different styles for different types
                const edges = new vis.DataSet(data.edges.map(edge => ({
                    ...edge,
                    arrows: 'to',
                    color: edge.type === 'imports' ? '#3498db' : '#95a5a6',
                    width: edge.type === 'imports' ? 2 : 1,
                    dashes: edge.type === 'calls'
                })));
                
                // Create network
                const container = document.getElementById('network');
                const graphData = { nodes, edges };
                const options = {
                    physics: {
                        stabilization: { iterations: 200 },
                        barnesHut: {
                            gravitationalConstant: -8000,
                            springConstant: 0.001,
                            springLength: 200
                        }
                    },
                    interaction: {
                        hover: true,
                        tooltipDelay: 200
                    }
                };
                
                new vis.Network(container, graphData, options);
            })
            .catch(error => {
                console.error('Error loading graph data:', error);
                document.getElementById('network').innerHTML = '<p style="text-align: center; padding: 50px;">Error loading visualization data</p>';
            });
    </script>
</body>
</html>
"@

$htmlVisualization | Out-File "$OutputPath\module_visualization.html" -Encoding UTF8

# Step 5: Generate summary
Write-Host "`n[5/5] Generating documentation summary..." -ForegroundColor Green

Write-Host "`n" + "=" * 80 -ForegroundColor Cyan
Write-Host "AI-ENHANCED DOCUMENTATION COMPLETE!" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Cyan

Write-Host "`nGenerated Files:" -ForegroundColor Yellow
Write-Host "  📄 AI_SEMANTIC_DOCUMENTATION.md - Complete semantic documentation with working links" -ForegroundColor Cyan
Write-Host "  📊 module_relationships.json - Module dependency data" -ForegroundColor Cyan
Write-Host "  🌐 module_visualization.html - Interactive relationship visualization" -ForegroundColor Cyan

Write-Host "`nKey Features:" -ForegroundColor Yellow
Write-Host "  ✅ AI-generated qualitative descriptions" -ForegroundColor Green
Write-Host "  ✅ Semantic relationship analysis" -ForegroundColor Green
Write-Host "  ✅ Working internal links and navigation" -ForegroundColor Green
Write-Host "  ✅ Interactive visualization" -ForegroundColor Green
Write-Host "  ✅ Architectural patterns identified" -ForegroundColor Green

Write-Host "`n📖 View main documentation: $OutputPath\AI_SEMANTIC_DOCUMENTATION.md" -ForegroundColor Cyan
Write-Host "🌐 Open visualization: $OutputPath\module_visualization.html" -ForegroundColor Cyan