#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Simple demo of enhanced semantic visualization
#>

param(
    [Parameter(Mandatory = $false)]
    [switch]$AutoOpen = $false,
    [Parameter(Mandatory = $false)]
    [int]$MaxNodes = 250
)

Write-Host "Unity-Claude Enhanced Visualization Demo" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# Check if data exists, if not generate it
$dataPath = ".\Visualization\public\static\data\enhanced-system-graph.json"
if (-not (Test-Path $dataPath)) {
    Write-Host "Generating visualization data..." -ForegroundColor Yellow
    try {
        & pwsh -ExecutionPolicy Bypass -File ".\Generate-EnhancedVisualizationData.ps1" -MaxNodes $MaxNodes
        Write-Host "Data generation completed!" -ForegroundColor Green
    }
    catch {
        Write-Host "Error generating data: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Check server status
$serverUrl = "http://localhost:3001"
try {
    $response = Invoke-WebRequest -Uri "$serverUrl/health" -TimeoutSec 3 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "Server is running at $serverUrl" -ForegroundColor Green
    }
}
catch {
    Write-Host "Server not responding. Please ensure npm start is running in the Visualization directory" -ForegroundColor Yellow
}

if ($AutoOpen) {
    Start-Process $serverUrl
}

Write-Host ""
Write-Host "Enhanced Visualization Features:" -ForegroundColor Yellow
Write-Host "- Semantic graph with $MaxNodes nodes" -ForegroundColor White
Write-Host "- Category-based clustering" -ForegroundColor White  
Write-Host "- AI-enhanced module highlighting" -ForegroundColor White
Write-Host "- Interactive search and filtering" -ForegroundColor White
Write-Host "- Real-time tooltips and exploration" -ForegroundColor White
Write-Host ""
Write-Host "Visit: $serverUrl" -ForegroundColor Cyan
Write-Host ""