# Deploy-DockerServices.ps1
# Deployment script for pulling and deploying Docker services from registry
# Supports rolling updates, health checks, and rollback

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment = 'dev',
    
    [Parameter(Mandatory=$false)]
    [string]$Version = 'latest',
    
    [Parameter(Mandatory=$false)]
    [string]$Registry = 'ghcr.io',
    
    [Parameter(Mandatory=$false)]
    [string]$Namespace = '',
    
    [Parameter(Mandatory=$false)]
    [switch]$Rollback = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force = $false,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun = $false,
    
    [Parameter(Mandatory=$false)]
    [int]$HealthCheckTimeout = 60,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipHealthCheck = $false
)

# Configuration
$ErrorActionPreference = 'Stop'
$script:config = @{
    Registry = $Registry
    Namespace = if ($Namespace) { $Namespace } else { 
        if ($Registry -eq 'ghcr.io') {
            # Get from git config or use default
            'georgest32'  # Update this to your GitHub username
        } else {
            'unity-claude'
        }
    }
    Services = @{
        'powershell-modules' = @{
            Port = $null
            HealthEndpoint = $null
            Essential = $true
        }
        'langgraph-api' = @{
            Port = 8000
            HealthEndpoint = 'http://localhost:8000/health'
            Essential = $true
        }
        'autogen-groupchat' = @{
            Port = 8001
            HealthEndpoint = 'http://localhost:8001/health'
            Essential = $true
        }
        'docs-server' = @{
            Port = 8080
            HealthEndpoint = 'http://localhost:8080/health'
            Essential = $false
        }
        'file-monitor' = @{
            Port = $null
            HealthEndpoint = $null
            Essential = $false
        }
    }
    ComposeFile = ".\docker-compose.$Environment.yml"
    BackupDir = ".\docker\backups"
}

# Functions
function Test-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Cyan
    
    # Check Docker
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker is not installed or not in PATH"
        return $false
    }
    
    # Check Docker daemon
    $dockerVersion = docker version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Docker daemon is not running"
        return $false
    }
    
    # Check docker-compose
    if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        Write-Warning "docker-compose not found, trying docker compose"
        $script:composeCmd = 'docker', 'compose'
    } else {
        $script:composeCmd = 'docker-compose'
    }
    
    Write-Host "Prerequisites check passed" -ForegroundColor Green
    return $true
}

function Get-CurrentDeployment {
    Write-Host "Getting current deployment status..." -ForegroundColor Cyan
    
    $deployment = @{
        Services = @{}
        Version = 'unknown'
    }
    
    foreach ($service in $script:config.Services.Keys) {
        $containerName = "unity-claude-$service"
        $info = docker ps --filter "name=$containerName" --format "json" 2>$null | ConvertFrom-Json
        
        if ($info) {
            $deployment.Services[$service] = @{
                Status = 'running'
                Image = $info.Image
                Created = $info.CreatedAt
                Ports = $info.Ports
            }
            
            # Try to extract version from image tag
            if ($info.Image -match ':(\d+\.\d+\.\d+)') {
                $deployment.Version = $matches[1]
            }
        } else {
            $deployment.Services[$service] = @{
                Status = 'stopped'
            }
        }
    }
    
    return $deployment
}

function Backup-CurrentDeployment {
    param([hashtable]$Deployment)
    
    Write-Host "Backing up current deployment..." -ForegroundColor Cyan
    
    if (-not (Test-Path $script:config.BackupDir)) {
        New-Item -Path $script:config.BackupDir -ItemType Directory -Force | Out-Null
    }
    
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $backupFile = Join-Path $script:config.BackupDir "deployment-$timestamp.json"
    
    if (-not $DryRun) {
        $Deployment | ConvertTo-Json -Depth 10 | Set-Content $backupFile
        Write-Host "Backup saved to: $backupFile" -ForegroundColor Green
    } else {
        Write-Host "[DRY RUN] Would save backup to: $backupFile" -ForegroundColor Yellow
    }
    
    return $backupFile
}

function Pull-Images {
    param([string]$Version)
    
    Write-Host "`nPulling images from registry..." -ForegroundColor Cyan
    $success = $true
    
    foreach ($service in $script:config.Services.Keys) {
        $imageName = "$($script:config.Registry)/$($script:config.Namespace)/unity-claude-$service`:$Version"
        Write-Host "Pulling $imageName..." -ForegroundColor Gray
        
        if (-not $DryRun) {
            $result = docker pull $imageName 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Failed to pull $imageName`: $result"
                $success = $false
                break
            }
            Write-Host "  Pulled successfully" -ForegroundColor Green
        } else {
            Write-Host "  [DRY RUN] Would pull $imageName" -ForegroundColor Yellow
        }
    }
    
    return $success
}

function Stop-Services {
    Write-Host "`nStopping current services..." -ForegroundColor Cyan
    
    if (-not $DryRun) {
        # Use docker-compose if available
        if (Test-Path ".\docker-compose.yml") {
            & $script:composeCmd down 2>&1 | Out-String | Write-Debug
        } else {
            # Stop individual containers
            foreach ($service in $script:config.Services.Keys) {
                $containerName = "unity-claude-$service"
                docker stop $containerName 2>$null | Out-Null
                docker rm $containerName 2>$null | Out-Null
            }
        }
        Write-Host "Services stopped" -ForegroundColor Green
    } else {
        Write-Host "[DRY RUN] Would stop services" -ForegroundColor Yellow
    }
}

function Start-Services {
    param([string]$Version)
    
    Write-Host "`nStarting services with version $Version..." -ForegroundColor Cyan
    
    # Create environment-specific compose file if it doesn't exist
    $composeFile = if ($Environment -eq 'dev') {
        ".\docker-compose.yml"
    } else {
        $script:config.ComposeFile
    }
    
    if (-not (Test-Path $composeFile)) {
        Write-Warning "Compose file not found: $composeFile"
        Write-Host "Using default docker-compose.yml" -ForegroundColor Yellow
        $composeFile = ".\docker-compose.yml"
    }
    
    if (-not $DryRun) {
        # Update image tags in environment
        $env:DOCKER_TAG = $Version
        
        # Start services
        & $script:composeCmd -f $composeFile up -d 2>&1 | Out-String | Write-Debug
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to start services"
            return $false
        }
        
        Write-Host "Services started" -ForegroundColor Green
    } else {
        Write-Host "[DRY RUN] Would start services with compose file: $composeFile" -ForegroundColor Yellow
    }
    
    return $true
}

function Test-ServiceHealth {
    param([int]$Timeout = 60)
    
    if ($SkipHealthCheck) {
        Write-Host "Skipping health checks" -ForegroundColor Yellow
        return $true
    }
    
    Write-Host "`nPerforming health checks (timeout: $Timeout seconds)..." -ForegroundColor Cyan
    $startTime = Get-Date
    $allHealthy = $false
    
    while ((Get-Date) -lt $startTime.AddSeconds($Timeout)) {
        $healthStatus = @{}
        $allHealthy = $true
        
        foreach ($service in $script:config.Services.Keys) {
            $serviceConfig = $script:config.Services[$service]
            
            if ($serviceConfig.HealthEndpoint) {
                try {
                    $response = Invoke-WebRequest -Uri $serviceConfig.HealthEndpoint -Method Get -TimeoutSec 5 -ErrorAction SilentlyContinue
                    $healthStatus[$service] = ($response.StatusCode -eq 200)
                } catch {
                    $healthStatus[$service] = $false
                }
                
                if (-not $healthStatus[$service]) {
                    $allHealthy = $false
                }
            } else {
                # For services without health endpoints, check if container is running
                $containerName = "unity-claude-$service"
                $running = docker ps --filter "name=$containerName" --format "{{.Names}}" 2>$null
                $healthStatus[$service] = [bool]$running
                
                if (-not $healthStatus[$service]) {
                    $allHealthy = $false
                }
            }
        }
        
        # Display status
        Write-Host "Health check status:" -ForegroundColor Gray
        foreach ($service in $healthStatus.Keys) {
            $status = if ($healthStatus[$service]) { "[OK]" } else { "[WAIT]" }
            $color = if ($healthStatus[$service]) { "Green" } else { "Yellow" }
            Write-Host "  $status $service" -ForegroundColor $color
        }
        
        if ($allHealthy) {
            Write-Host "All services healthy!" -ForegroundColor Green
            return $true
        }
        
        Start-Sleep -Seconds 5
        Write-Host ""
    }
    
    Write-Error "Health check timeout - not all services became healthy"
    return $false
}

function Invoke-Rollback {
    param([string]$BackupFile)
    
    Write-Host "`nPerforming rollback..." -ForegroundColor Yellow
    
    if (-not $BackupFile -or -not (Test-Path $BackupFile)) {
        # Find most recent backup
        $backups = Get-ChildItem -Path $script:config.BackupDir -Filter "deployment-*.json" | Sort-Object LastWriteTime -Descending
        if ($backups.Count -eq 0) {
            Write-Error "No backup found for rollback"
            return $false
        }
        $BackupFile = $backups[0].FullName
    }
    
    Write-Host "Using backup: $BackupFile" -ForegroundColor Gray
    $backup = Get-Content $BackupFile | ConvertFrom-Json
    
    # Stop current services
    Stop-Services
    
    # Restore previous version
    if ($backup.Version -and $backup.Version -ne 'unknown') {
        Start-Services -Version $backup.Version
    } else {
        Write-Warning "Previous version unknown, using 'latest'"
        Start-Services -Version 'latest'
    }
    
    return $true
}

# Main execution
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Docker Services Deployment" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Gray
Write-Host "Version: $Version" -ForegroundColor Gray
Write-Host "Registry: $($script:config.Registry)/$($script:config.Namespace)" -ForegroundColor Gray

# Check prerequisites
if (-not (Test-Prerequisites)) {
    exit 1
}

# Get current deployment
$currentDeployment = Get-CurrentDeployment

Write-Host "`nCurrent deployment:" -ForegroundColor Cyan
foreach ($service in $currentDeployment.Services.Keys) {
    $svc = $currentDeployment.Services[$service]
    $statusColor = if ($svc.Status -eq 'running') { 'Green' } else { 'Red' }
    Write-Host "  $service`: $($svc.Status)" -ForegroundColor $statusColor
}

# Handle rollback
if ($Rollback) {
    if (Invoke-Rollback) {
        Write-Host "`nRollback completed successfully" -ForegroundColor Green
    } else {
        Write-Error "Rollback failed"
        exit 1
    }
    exit 0
}

# Backup current deployment
$backupFile = Backup-CurrentDeployment -Deployment $currentDeployment

# Pull new images
if (-not (Pull-Images -Version $Version)) {
    Write-Error "Failed to pull images"
    exit 1
}

# Stop current services
Stop-Services

# Start new services
if (-not (Start-Services -Version $Version)) {
    Write-Error "Failed to start services"
    
    # Attempt rollback
    Write-Host "Attempting automatic rollback..." -ForegroundColor Yellow
    if (Invoke-Rollback -BackupFile $backupFile) {
        Write-Host "Rollback successful" -ForegroundColor Green
    } else {
        Write-Error "Rollback also failed - manual intervention required"
    }
    exit 1
}

# Health checks
if (-not (Test-ServiceHealth -Timeout $HealthCheckTimeout)) {
    Write-Error "Health checks failed"
    
    if (-not $Force) {
        # Attempt rollback
        Write-Host "Attempting automatic rollback due to health check failure..." -ForegroundColor Yellow
        if (Invoke-Rollback -BackupFile $backupFile) {
            Write-Host "Rollback successful" -ForegroundColor Green
        } else {
            Write-Error "Rollback also failed - manual intervention required"
        }
        exit 1
    } else {
        Write-Warning "Health checks failed but continuing due to -Force flag"
    }
}

Write-Host "`n==================================================" -ForegroundColor Green
Write-Host "Deployment completed successfully!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Display service URLs
Write-Host "`nService endpoints:" -ForegroundColor Cyan
Write-Host "  LangGraph API:     http://localhost:8000" -ForegroundColor Gray
Write-Host "  AutoGen GroupChat: http://localhost:8001" -ForegroundColor Gray
Write-Host "  Documentation:     http://localhost:8080" -ForegroundColor Gray

Write-Host "`nTo check service status:" -ForegroundColor Yellow
Write-Host "  docker ps" -ForegroundColor Gray
Write-Host "`nTo view logs:" -ForegroundColor Yellow
Write-Host "  docker-compose logs -f [service-name]" -ForegroundColor Gray
Write-Host "`nTo rollback:" -ForegroundColor Yellow
Write-Host "  .\Deploy-DockerServices.ps1 -Rollback" -ForegroundColor Gray