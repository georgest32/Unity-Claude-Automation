# Start-Visualization-Dashboard.ps1
# Starts the D3.js visualization dashboard for Enhanced Documentation System
# Interactive visualization of code relationships and Week 4 predictive data
# Date: 2025-08-29

param(
    [int]$Port = 3000,
    [switch]$OpenBrowser,
    [switch]$GenerateData
)

function Write-VizLog {
    param([string]$Message, [string]$Level = "Info")
    $color = @{ "Info" = "White"; "Success" = "Green"; "Warning" = "Yellow"; "Error" = "Red"; "Viz" = "Magenta" }[$Level]
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] [$Level] $Message" -ForegroundColor $color
}

Write-Host "=== D3.js Visualization Dashboard Startup ===" -ForegroundColor Cyan
Write-Host "Advanced interactive visualization for Enhanced Documentation System" -ForegroundColor Magenta

try {
    # Check if Node.js is available
    Write-VizLog "Checking Node.js availability..." -Level "Info"
    
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            Write-VizLog "Node.js available: $nodeVersion" -Level "Success"
        } else {
            throw "Node.js not found"
        }
    } catch {
        Write-VizLog "Node.js not available - visualization requires Node.js installation" -Level "Error"
        Write-VizLog "Install Node.js from: https://nodejs.org/" -Level "Info"
        return
    }
    
    # Check visualization directory
    if (Test-Path ".\Visualization") {
        Write-VizLog "Visualization directory found" -Level "Success"
        Set-Location ".\Visualization"
    } else {
        Write-VizLog "Visualization directory not found" -Level "Error"
        return
    }
    
    # Check if dependencies are installed
    if (Test-Path ".\node_modules") {
        Write-VizLog "Node.js dependencies already installed" -Level "Success"
    } else {
        Write-VizLog "Installing Node.js dependencies..." -Level "Info"
        npm install
        
        if ($LASTEXITCODE -eq 0) {
            Write-VizLog "Dependencies installed successfully" -Level "Success"
        } else {
            Write-VizLog "Dependency installation failed" -Level "Error"
            return
        }
    }
    
    # Generate visualization data if requested
    if ($GenerateData) {
        Write-VizLog "Generating visualization data from Week 4 analysis..." -Level "Viz"
        
        Set-Location ".."  # Back to project root
        
        try {
            # Generate code evolution data for visualization
            if (Get-Command Get-CodeChurnMetrics -ErrorAction SilentlyContinue) {
                $churnData = Get-CodeChurnMetrics -Path ".\Modules" -Since "6.months.ago"
                
                if ($churnData) {
                    # Convert to visualization format
                    $vizData = @{
                        nodes = @()
                        edges = @()
                        metadata = @{
                            generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                            type = "code-churn-analysis"
                            count = $churnData.Count
                        }
                    }
                    
                    # Create nodes for files
                    foreach ($file in $churnData) {
                        $vizData.nodes += @{
                            id = $file.FilePath
                            label = [System.IO.Path]::GetFileName($file.FilePath)
                            size = $file.ChurnScore * 10
                            color = if ($file.ChurnScore -gt 5) { "#ff4444" } elseif ($file.ChurnScore -gt 2) { "#ffaa44" } else { "#44ff44" }
                            type = "file"
                            churnScore = $file.ChurnScore
                            changeCount = $file.ChangeCount
                        }
                    }
                    
                    $vizData | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\Visualization\public\static\data\churn-data.json" -Encoding UTF8
                    Write-VizLog "Generated churn visualization data: churn-data.json" -Level "Success"
                }
            }
            
            # Generate hotspot data for visualization
            if (Get-Command Get-FileHotspots -ErrorAction SilentlyContinue) {
                $hotspots = Get-FileHotspots -Path ".\Modules" -Top 20
                
                if ($hotspots) {
                    $hotspotViz = @{
                        hotspots = $hotspots | ForEach-Object {
                            @{
                                file = $_.FilePath
                                hotspotScore = $_.HotspotScore
                                complexity = $_.ComplexityScore
                                churn = $_.ChurnScore
                                priority = $_.RefactoringPriority
                            }
                        }
                        metadata = @{
                            generated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                            type = "hotspot-analysis"
                            count = $hotspots.Count
                        }
                    }
                    
                    $hotspotViz | ConvertTo-Json -Depth 10 | Out-File -FilePath ".\Visualization\public\static\data\hotspot-data.json" -Encoding UTF8
                    Write-VizLog "Generated hotspot visualization data: hotspot-data.json" -Level "Success"
                }
            }
            
        } catch {
            Write-VizLog "Visualization data generation failed: $($_.Exception.Message)" -Level "Warning"
        }
        
        Set-Location ".\Visualization"  # Back to visualization directory
    }
    
    # Start the visualization server
    Write-VizLog "Starting D3.js visualization dashboard on port $Port..." -Level "Viz"
    
    # Update server port if needed
    if ($Port -ne 3000) {
        $serverContent = Get-Content "server.js"
        $serverContent = $serverContent -replace "const PORT = \d+", "const PORT = $Port"
        $serverContent | Out-File -FilePath "server.js" -Encoding UTF8
    }
    
    Write-VizLog "🌟 D3.js Visualization Dashboard Starting..." -Level "Viz"
    Write-VizLog "📊 Interactive visualization with:" -Level "Info"
    Write-VizLog "  • Force-directed graph layout" -Level "Info"
    Write-VizLog "  • Interactive zoom, pan, selection" -Level "Info"
    Write-VizLog "  • Real-time filtering controls" -Level "Info"
    Write-VizLog "  • Code churn and hotspot visualization" -Level "Info"
    Write-VizLog "  • Week 4 predictive data integration" -Level "Info"
    
    Write-VizLog "🚀 Access visualization at: http://localhost:$Port" -Level "Success"
    Write-VizLog "⚡ Server starting - may take 30-60 seconds to fully load" -Level "Warning"
    
    if ($OpenBrowser) {
        Start-Sleep -Seconds 5
        Start-Process "http://localhost:$Port"
    }
    
    # Start the server
    npm start
    
} catch {
    Write-VizLog "Visualization startup failed: $($_.Exception.Message)" -Level "Error"
    Set-Location ".."  # Return to project root on error
} finally {
    Set-Location ".."  # Ensure we return to project root
}

Write-Host "`n=== Visualization Dashboard Startup Complete ===" -ForegroundColor Green