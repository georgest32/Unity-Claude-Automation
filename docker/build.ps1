# Unity-Claude-Automation Docker Build Script
# Builds and optionally starts all Docker services

param(
    [switch]$Build,
    [switch]$Start,
    [switch]$Clean,
    [switch]$Test,
    [string]$Service = "all",
    [switch]$NoCache
)

Write-Host "Unity-Claude-Automation Docker Build Script" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Check Docker is running
$dockerRunning = docker version 2>$null
if (-not $dockerRunning) {
    Write-Host "ERROR: Docker is not running. Please start Docker Desktop." -ForegroundColor Red
    exit 1
}

# Navigate to project root
$projectRoot = Split-Path -Parent $PSScriptRoot
Set-Location $projectRoot
Write-Host "Working directory: $projectRoot" -ForegroundColor Gray
Write-Host ""

# Clean operation
if ($Clean) {
    Write-Host "Cleaning Docker resources..." -ForegroundColor Yellow
    docker compose down -v
    docker system prune -f
    Write-Host "Clean complete." -ForegroundColor Green
    Write-Host ""
}

# Build operation
if ($Build) {
    Write-Host "Building Docker images..." -ForegroundColor Yellow
    
    $buildCommand = "docker compose build"
    if ($NoCache) {
        $buildCommand += " --no-cache"
    }
    
    if ($Service -ne "all") {
        $buildCommand += " $Service"
        Write-Host "Building service: $Service" -ForegroundColor Cyan
    } else {
        Write-Host "Building all services..." -ForegroundColor Cyan
    }
    
    Invoke-Expression $buildCommand
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Build successful!" -ForegroundColor Green
    } else {
        Write-Host "Build failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

# Start operation
if ($Start) {
    Write-Host "Starting Docker services..." -ForegroundColor Yellow
    
    $startCommand = "docker compose up -d"
    if ($Service -ne "all") {
        $startCommand += " $Service"
    }
    
    Invoke-Expression $startCommand
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Services started successfully!" -ForegroundColor Green
        Write-Host ""
        
        # Show service status
        Write-Host "Service Status:" -ForegroundColor Cyan
        docker compose ps
    } else {
        Write-Host "Failed to start services!" -ForegroundColor Red
        exit 1
    }
    Write-Host ""
}

# Test operation
if ($Test) {
    Write-Host "Testing Docker services..." -ForegroundColor Yellow
    Write-Host ""
    
    # Test each service health endpoint
    $services = @(
        @{Name="LangGraph API"; Url="http://localhost:8000/health"},
        @{Name="AutoGen GroupChat"; Url="http://localhost:8001/health"},
        @{Name="Documentation"; Url="http://localhost:8080/health"}
    )
    
    # Wait a moment for services to fully start
    Start-Sleep -Seconds 5
    
    $allHealthy = $true
    foreach ($service in $services) {
        Write-Host "Testing $($service.Name)..." -NoNewline
        try {
            $response = Invoke-WebRequest -Uri $service.Url -Method Get -TimeoutSec 5 -ErrorAction Stop
            if ($response.StatusCode -eq 200) {
                Write-Host " [OK]" -ForegroundColor Green
            } else {
                Write-Host " [FAILED]" -ForegroundColor Red
                $allHealthy = $false
            }
        } catch {
            Write-Host " [FAILED]" -ForegroundColor Red
            Write-Host "  Error: $_" -ForegroundColor Gray
            $allHealthy = $false
        }
    }
    
    Write-Host ""
    if ($allHealthy) {
        Write-Host "All services are healthy!" -ForegroundColor Green
    } else {
        Write-Host "Some services are not healthy. Check logs with: docker compose logs" -ForegroundColor Yellow
    }
}

# Show help if no parameters
if (-not ($Build -or $Start -or $Clean -or $Test)) {
    Write-Host "Usage:" -ForegroundColor Yellow
    Write-Host "  .\build.ps1 -Build              # Build all images"
    Write-Host "  .\build.ps1 -Build -NoCache     # Build without cache"
    Write-Host "  .\build.ps1 -Build -Service langgraph-api  # Build specific service"
    Write-Host "  .\build.ps1 -Start              # Start all services"
    Write-Host "  .\build.ps1 -Build -Start       # Build and start"
    Write-Host "  .\build.ps1 -Test               # Test service health"
    Write-Host "  .\build.ps1 -Clean              # Clean Docker resources"
    Write-Host ""
    Write-Host "Available services:" -ForegroundColor Cyan
    Write-Host "  - powershell-modules"
    Write-Host "  - langgraph-api"
    Write-Host "  - autogen-groupchat"
    Write-Host "  - docs-server"
    Write-Host "  - file-monitor"
}