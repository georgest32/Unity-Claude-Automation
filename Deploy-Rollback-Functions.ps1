# Deploy-Rollback-Functions.ps1
# Rollback mechanism and verification functions for Deploy-EnhancedDocumentationSystem.ps1
# Week 4 Day 4: Deployment Automation completion
# Date: 2025-08-29

# Rollback and verification functions to be integrated into Deploy-EnhancedDocumentationSystem.ps1

function New-DeploymentSnapshot {
    <#
    .SYNOPSIS
        Creates a deployment snapshot for rollback capability.
        
    .DESCRIPTION
        Captures current deployment state including running containers,
        configuration files, and system state for rollback purposes.
        
    .OUTPUTS
        PSCustomObject with snapshot information
    #>
    try {
        $snapshotId = "snapshot-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        $snapshotPath = ".\backups\$snapshotId"
        
        # Create snapshot directory
        New-Item -Path $snapshotPath -ItemType Directory -Force | Out-Null
        
        # Capture current container state
        $containerState = docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>$null
        $containerState | Out-File -FilePath "$snapshotPath\containers.txt" -Encoding UTF8
        
        # Capture docker-compose configuration
        if (Test-Path "docker-compose.yml") {
            Copy-Item "docker-compose.yml" "$snapshotPath\docker-compose.yml.backup"
        }
        if (Test-Path "docker-compose.monitoring.yml") {
            Copy-Item "docker-compose.monitoring.yml" "$snapshotPath\docker-compose.monitoring.yml.backup"
        }
        
        # Capture environment configuration
        if (Test-Path ".env") {
            Copy-Item ".env" "$snapshotPath\.env.backup"
        }
        
        # Create snapshot metadata
        $metadata = [PSCustomObject]@{
            SnapshotId = $snapshotId
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Environment = $Environment
            ContainerCount = ($containerState | Measure-Object).Count
            BackupPath = $snapshotPath
        }
        
        $metadata | ConvertTo-Json | Out-File -FilePath "$snapshotPath\metadata.json" -Encoding UTF8
        
        Write-DeployLog "Deployment snapshot created: $snapshotId" -Level Info
        return $metadata
        
    } catch {
        Write-DeployLog "Failed to create deployment snapshot: $_" -Level Error
        throw
    }
}

function Test-DeploymentHealth {
    <#
    .SYNOPSIS
        Performs comprehensive health check validation of deployed services.
        
    .DESCRIPTION
        Validates deployment health including container status, service endpoints,
        API availability, and basic functionality tests.
        
    .PARAMETER EnvConfig
        Environment configuration hashtable
        
    .OUTPUTS
        PSCustomObject with health check results
    #>
    param([hashtable]$EnvConfig)
    
    Write-DeployLog "Performing deployment health check..." -Level Info
    
    $healthResults = [PSCustomObject]@{
        Success = $true
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        ContainerHealth = @{}
        ServiceHealth = @{}
        APIHealth = @{}
        FailedChecks = @()
    }
    
    try {
        # Check 1: Container Health
        Write-DeployLog "Checking container health..." -Level Info
        $containers = docker ps --format "table {{.Names}}\t{{.Status}}" 2>$null | ConvertFrom-String -PropertyNames Name, Status
        
        foreach ($container in $containers) {
            if ($container.Status -like "*Up*") {
                $healthResults.ContainerHealth[$container.Name] = "Healthy"
            } else {
                $healthResults.ContainerHealth[$container.Name] = "Unhealthy"
                $healthResults.FailedChecks += "Container $($container.Name) not running"
                $healthResults.Success = $false
            }
        }
        
        # Check 2: Service Endpoint Health
        Write-DeployLog "Checking service endpoints..." -Level Info
        $serviceChecks = @{
            "Documentation API" = @{ URL = "http://localhost:8091/health"; Timeout = 10 }
            "Main Documentation" = @{ URL = "http://localhost:8080"; Timeout = 10 }
        }
        
        if ($EnvConfig.MonitoringEnabled) {
            $serviceChecks["Monitoring Dashboard"] = @{ URL = "http://localhost:3000"; Timeout = 15 }
        }
        
        foreach ($service in $serviceChecks.Keys) {
            try {
                $check = $serviceChecks[$service]
                $response = Invoke-WebRequest -Uri $check.URL -TimeoutSec $check.Timeout -UseBasicParsing
                if ($response.StatusCode -eq 200) {
                    $healthResults.ServiceHealth[$service] = "Available"
                } else {
                    $healthResults.ServiceHealth[$service] = "Unavailable"
                    $healthResults.FailedChecks += "Service $service returned status $($response.StatusCode)"
                    $healthResults.Success = $false
                }
            } catch {
                $healthResults.ServiceHealth[$service] = "Error"
                $healthResults.FailedChecks += "Service $service failed: $($_.Exception.Message)"
                $healthResults.Success = $false
            }
        }
        
        # Check 3: Basic API Functionality
        Write-DeployLog "Testing basic API functionality..." -Level Info
        try {
            $apiTest = Invoke-RestMethod -Uri "http://localhost:8091/api/health" -TimeoutSec 10
            if ($apiTest) {
                $healthResults.APIHealth["REST API"] = "Functional"
            } else {
                $healthResults.APIHealth["REST API"] = "Non-functional"
                $healthResults.FailedChecks += "REST API not responding properly"
                $healthResults.Success = $false
            }
        } catch {
            $healthResults.APIHealth["REST API"] = "Error"
            $healthResults.FailedChecks += "REST API test failed: $($_.Exception.Message)"
            $healthResults.Success = $false
        }
        
        # Summary
        if ($healthResults.Success) {
            Write-DeployLog "All health checks passed" -Level Success
        } else {
            Write-DeployLog "Health check failed with $($healthResults.FailedChecks.Count) issues" -Level Error
            $healthResults.FailedChecks | ForEach-Object { Write-DeployLog "  - $_" -Level Error }
        }
        
        return $healthResults
        
    } catch {
        Write-DeployLog "Health check process failed: $_" -Level Error
        $healthResults.Success = $false
        $healthResults.FailedChecks += "Health check process error: $($_.Exception.Message)"
        return $healthResults
    }
}

function Invoke-DeploymentRollback {
    <#
    .SYNOPSIS
        Performs automated rollback to previous deployment state.
        
    .DESCRIPTION
        Restores system to previous working state using deployment snapshot,
        including container rollback and configuration restoration.
        
    .PARAMETER SnapshotId
        Snapshot ID to rollback to
        
    .PARAMETER Force
        Force rollback even if current deployment appears healthy
    #>
    param(
        [Parameter(Mandatory)]
        [string]$SnapshotId,
        
        [switch]$Force
    )
    
    Write-DeployLog "Initiating deployment rollback to snapshot: $SnapshotId" -Level Warning
    
    try {
        $snapshotPath = ".\backups\$SnapshotId"
        
        # Verify snapshot exists
        if (-not (Test-Path "$snapshotPath\metadata.json")) {
            throw "Snapshot $SnapshotId not found or incomplete"
        }
        
        # Load snapshot metadata
        $metadata = Get-Content "$snapshotPath\metadata.json" | ConvertFrom-Json
        Write-DeployLog "Rolling back to deployment from $($metadata.Timestamp)" -Level Info
        
        # Step 1: Stop current services
        Write-DeployLog "Stopping current services for rollback..." -Level Info
        docker-compose down --remove-orphans --volumes 2>$null
        docker-compose -f docker-compose.monitoring.yml down 2>$null
        
        # Step 2: Restore configuration files
        Write-DeployLog "Restoring configuration files..." -Level Info
        if (Test-Path "$snapshotPath\docker-compose.yml.backup") {
            Copy-Item "$snapshotPath\docker-compose.yml.backup" "docker-compose.yml" -Force
        }
        if (Test-Path "$snapshotPath\docker-compose.monitoring.yml.backup") {
            Copy-Item "$snapshotPath\docker-compose.monitoring.yml.backup" "docker-compose.monitoring.yml" -Force
        }
        if (Test-Path "$snapshotPath\.env.backup") {
            Copy-Item "$snapshotPath\.env.backup" ".env" -Force
        }
        
        # Step 3: Start services with previous configuration
        Write-DeployLog "Starting services with rolled-back configuration..." -Level Info
        docker-compose up -d
        Start-Sleep -Seconds 30
        
        # Step 4: Verify rollback success
        $rollbackHealth = Test-DeploymentHealth -EnvConfig @{ MonitoringEnabled = $false }
        if ($rollbackHealth.Success) {
            Write-DeployLog "Rollback completed successfully" -Level Success
            Set-DeploymentStatus -SnapshotId $SnapshotId -Status "RolledBack"
        } else {
            Write-DeployLog "Rollback validation failed" -Level Error
            throw "Rollback completed but health check still failing"
        }
        
    } catch {
        Write-DeployLog "Rollback failed: $_" -Level Error
        throw
    }
}

function Set-DeploymentStatus {
    <#
    .SYNOPSIS
        Updates deployment status in snapshot metadata.
    #>
    param(
        [string]$SnapshotId,
        [ValidateSet('Success', 'Failed', 'RolledBack')]
        [string]$Status
    )
    
    try {
        $snapshotPath = ".\backups\$SnapshotId"
        if (Test-Path "$snapshotPath\metadata.json") {
            $metadata = Get-Content "$snapshotPath\metadata.json" | ConvertFrom-Json
            $metadata | Add-Member -MemberType NoteProperty -Name "FinalStatus" -Value $Status -Force
            $metadata | Add-Member -MemberType NoteProperty -Name "CompletionTime" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Force
            $metadata | ConvertTo-Json | Out-File -FilePath "$snapshotPath\metadata.json" -Encoding UTF8
        }
    } catch {
        Write-DeployLog "Failed to update deployment status: $_" -Level Warning
    }
}