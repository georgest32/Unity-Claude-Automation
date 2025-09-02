#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Demonstrates the enhanced semantic graph visualization capabilities
    
.DESCRIPTION
    This script showcases the complete Unity-Claude enhanced visualization system:
    1. Generates rich semantic data from hybrid documentation
    2. Starts the visualization server with enhanced features
    3. Opens the browser to display the interactive graph
    4. Demonstrates key features and interactions
    
.PARAMETER AutoOpen
    Automatically opens the browser to view the visualization
    
.PARAMETER MaxNodes
    Maximum number of nodes to include in the visualization
    
.EXAMPLE
    .\Demo-EnhancedVisualization.ps1 -AutoOpen -MaxNodes 250
    
.NOTES
    Author: Unity-Claude-Automation
    Purpose: Demonstrate enhanced semantic visualization capabilities
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$AutoOpen = $true,
    
    [Parameter(Mandatory = $false)]
    [int]$MaxNodes = 300
)

Write-Host "=================================================================================" -ForegroundColor Cyan
Write-Host "UNITY-CLAUDE ENHANCED SEMANTIC VISUALIZATION DEMO" -ForegroundColor Yellow
Write-Host "Complete workflow: Documentation → Semantic Graph → Interactive Visualization" -ForegroundColor White
Write-Host "=================================================================================" -ForegroundColor Cyan

$ErrorActionPreference = 'Continue'
$startTime = Get-Date

# Step 1: Ensure hybrid documentation is available
Write-Host ""
Write-Host "[1/6] 🚀 Checking hybrid documentation..." -ForegroundColor Green

$docsPath = ".\docs\enhanced-documentation"
$moduleIndexPath = Join-Path $docsPath "module_index.json"

if (-not (Test-Path $moduleIndexPath)) {
    Write-Host "  📝 Hybrid documentation not found. Generating..." -ForegroundColor Yellow
    
    try {
        Write-Host "  🤖 Running hybrid documentation generation..." -ForegroundColor Cyan
        $docResult = & pwsh -ExecutionPolicy Bypass -File ".\Generate-HybridDocumentation.ps1" -MaxAIModules 50 -OutputPath $docsPath
        
        if (Test-Path $moduleIndexPath) {
            Write-Host "  ✅ Hybrid documentation generated successfully" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Failed to generate documentation" -ForegroundColor Red
            exit 1
        }
    }
    catch {
        Write-Host "  ❌ Error generating documentation: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "  ✅ Hybrid documentation found" -ForegroundColor Green
}

# Load documentation stats
try {
    $moduleIndex = Get-Content $moduleIndexPath | ConvertFrom-Json
    $stats = $moduleIndex.stats
    Write-Host "    📊 Total modules: $($stats.totalModules)" -ForegroundColor White
    Write-Host "    🤖 AI-enhanced: $($stats.aiEnhancedModules)" -ForegroundColor White
    Write-Host "    📋 Pattern-based: $($stats.patternBasedModules)" -ForegroundColor White
    Write-Host "    ⚡ Total functions: $($stats.totalFunctions)" -ForegroundColor White
}
catch {
    Write-Host "    ⚠️  Could not read documentation stats" -ForegroundColor Yellow
}

# Step 2: Generate enhanced visualization data
Write-Host ""
Write-Host "[2/6] 📊 Generating enhanced semantic graph data..." -ForegroundColor Green

try {
    Write-Host "  🎨 Processing semantic relationships and categories..." -ForegroundColor Cyan
    $vizResult = & pwsh -ExecutionPolicy Bypass -File ".\Generate-EnhancedVisualizationData.ps1" -MaxNodes $MaxNodes
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Enhanced visualization data generated" -ForegroundColor Green
    } else {
        Write-Host "  ❌ Failed to generate visualization data" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "  ❌ Error generating visualization data: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Step 3: Check if Node.js is available
Write-Host ""
Write-Host "[3/6] 🟢 Checking Node.js environment..." -ForegroundColor Green

try {
    $nodeVersion = & node --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Node.js version: $nodeVersion" -ForegroundColor Green
    } else {
        throw "Node.js not found"
    }
}
catch {
    Write-Host "  ❌ Node.js not available. Please install Node.js to run the visualization server." -ForegroundColor Red
    Write-Host "    Download from: https://nodejs.org/" -ForegroundColor Yellow
    exit 1
}

# Step 4: Install visualization dependencies
Write-Host ""
Write-Host "[4/6] 📦 Checking visualization dependencies..." -ForegroundColor Green

$vizDir = ".\Visualization"
$packageJsonPath = Join-Path $vizDir "package.json"

if (Test-Path $packageJsonPath) {
    Push-Location $vizDir
    try {
        Write-Host "  🔍 Checking dependencies..." -ForegroundColor Cyan
        $npmList = & npm list --depth=0 2>$null
        
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  📦 Installing Node.js dependencies..." -ForegroundColor Cyan
            & npm install
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "  ✅ Dependencies installed successfully" -ForegroundColor Green
            } else {
                Write-Host "  ❌ Failed to install dependencies" -ForegroundColor Red
                Pop-Location
                exit 1
            }
        } else {
            Write-Host "  ✅ Dependencies already installed" -ForegroundColor Green
        }
    }
    finally {
        Pop-Location
    }
} else {
    Write-Host "  ❌ package.json not found in Visualization directory" -ForegroundColor Red
    exit 1
}

# Step 5: Start the enhanced visualization server
Write-Host ""
Write-Host "[5/6] 🌐 Starting enhanced visualization server..." -ForegroundColor Green

$serverUrl = "http://localhost:3001"

# Check if server is already running
try {
    $response = Invoke-WebRequest -Uri "$serverUrl/health" -TimeoutSec 3 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "  ✅ Visualization server already running at $serverUrl" -ForegroundColor Green
        $serverRunning = $true
    }
}
catch {
    $serverRunning = $false
}

if (-not $serverRunning) {
    Write-Host "  🚀 Starting server with enhanced semantic features..." -ForegroundColor Cyan
    
    # Start server in background
    $serverJob = Start-Job -ScriptBlock {
        param($vizPath)
        Set-Location $vizPath
        & npm start
    } -ArgumentList (Resolve-Path $vizDir).Path
    
    Write-Host "    Server job started with ID: $($serverJob.Id)" -ForegroundColor White
    
    # Wait for server to be ready
    Write-Host "  ⏳ Waiting for server to initialize..." -ForegroundColor Cyan
    $maxWaitTime = 30
    $waitTime = 0
    
    do {
        Start-Sleep -Seconds 2
        $waitTime += 2
        
        try {
            $healthCheck = Invoke-WebRequest -Uri "$serverUrl/health" -TimeoutSec 3 -ErrorAction Stop
            if ($healthCheck.StatusCode -eq 200) {
                Write-Host "  ✅ Server ready at $serverUrl" -ForegroundColor Green
                $serverRunning = $true
                break
            }
        }
        catch {
            Write-Host "    🔄 Still waiting... ($waitTime/$maxWaitTime seconds)" -ForegroundColor Yellow
        }
    } while ($waitTime -lt $maxWaitTime)
    
    if (-not $serverRunning) {
        Write-Host "  ❌ Server failed to start within $maxWaitTime seconds" -ForegroundColor Red
        Stop-Job $serverJob -ErrorAction SilentlyContinue
        Remove-Job $serverJob -ErrorAction SilentlyContinue
        exit 1
    }
}

# Step 6: Open visualization and provide demo instructions
Write-Host ""
Write-Host "[6/6] 🎨 Opening enhanced semantic visualization..." -ForegroundColor Green

if ($AutoOpen) {
    Write-Host "  🌐 Opening browser..." -ForegroundColor Cyan
    Start-Process $serverUrl
}

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host ""
Write-Host "=================================================================================" -ForegroundColor Green
Write-Host "ENHANCED VISUALIZATION READY!" -ForegroundColor Yellow
Write-Host "=================================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Visualization URL: $serverUrl" -ForegroundColor Cyan
Write-Host "⏱️  Total setup time: $([math]::Round($duration, 1)) seconds" -ForegroundColor White
Write-Host ""
Write-Host "🎯 ENHANCED FEATURES AVAILABLE:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  📊 SEMANTIC GRAPH FEATURES:" -ForegroundColor Cyan
Write-Host "    • $MaxNodes nodes with intelligent relationship mapping" -ForegroundColor White
Write-Host "    • Category-based clustering and color coding" -ForegroundColor White
Write-Host "    • AI-enhanced vs pattern-based module differentiation" -ForegroundColor White
Write-Host "    • Interactive tooltips with detailed module information" -ForegroundColor White
Write-Host ""
Write-Host "  🎮 INTERACTIVE CONTROLS:" -ForegroundColor Cyan
Write-Host "    • Real-time search and filtering" -ForegroundColor White
Write-Host "    • Category toggles for selective viewing" -ForegroundColor White
Write-Host "    • Force-directed physics controls" -ForegroundColor White
Write-Host "    • Zoom, pan, and node selection" -ForegroundColor White
Write-Host ""
Write-Host "  🤖 AI INTEGRATION:" -ForegroundColor Cyan
Write-Host "    • Golden highlight for AI-enhanced modules" -ForegroundColor White
Write-Host "    • Glow effects for critical infrastructure" -ForegroundColor White
Write-Host "    • Intelligent relationship suggestions" -ForegroundColor White
Write-Host "    • Performance-optimized rendering" -ForegroundColor White
Write-Host ""
Write-Host "⌨️  KEYBOARD SHORTCUTS:" -ForegroundColor Yellow
Write-Host "    • ESC          - Clear selection and highlights" -ForegroundColor White
Write-Host "    • Ctrl+R       - Restart simulation" -ForegroundColor White
Write-Host "    • Ctrl+C       - Center graph" -ForegroundColor White
Write-Host "    • Double-click - Focus on node" -ForegroundColor White
Write-Host ""
Write-Host "🎛️  TRY THESE FEATURES:" -ForegroundColor Yellow
Write-Host "    1. Search for 'Core' or 'Orchestrator' modules" -ForegroundColor White
Write-Host "    2. Toggle category filters to focus on specific systems" -ForegroundColor White
Write-Host "    3. Hover over nodes to see detailed information" -ForegroundColor White
Write-Host "    4. Click and drag nodes to explore relationships" -ForegroundColor White
Write-Host "    5. Use the control panel for advanced settings" -ForegroundColor White
Write-Host ""
Write-Host "📊 DATA SOURCE:" -ForegroundColor Yellow
Write-Host "    Hybrid Documentation: $docsPath" -ForegroundColor White
Write-Host "    Visualization Data: .\Visualization\public\static\data\" -ForegroundColor White
Write-Host ""
Write-Host "🔄 To refresh data:" -ForegroundColor Yellow
Write-Host "    1. Modify modules or add new documentation" -ForegroundColor White
Write-Host "    2. Run: .\Generate-HybridDocumentation.ps1" -ForegroundColor White
Write-Host "    3. Run: .\Generate-EnhancedVisualizationData.ps1" -ForegroundColor White
Write-Host "    4. Refresh browser or click 'Refresh Data' button" -ForegroundColor White
Write-Host ""

# Provide continuous monitoring option
Write-Host "🔍 MONITOR SERVER:" -ForegroundColor Yellow
Write-Host "    Server job ID: $($serverJob.Id)" -ForegroundColor White
Write-Host "    To stop: Stop-Job $($serverJob.Id); Remove-Job $($serverJob.Id)" -ForegroundColor White
Write-Host ""

Write-Host "Press any key to continue monitoring or Ctrl+C to exit..." -ForegroundColor Green
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

Write-Host ""
Write-Host "🎯 Enhanced visualization demo completed successfully!" -ForegroundColor Green
Write-Host "   The visualization server will continue running in the background." -ForegroundColor Yellow
Write-Host ""

return @{
    Success = $true
    ServerUrl = $serverUrl
    JobId = $serverJob.Id
    Duration = $duration
    NodesGenerated = $MaxNodes
    DocumentationPath = $docsPath
}