# Deploy-EnhancedDocumentationSystem-Rollback.ps1
# Week 4 Day 4: Deployment Rollback Mechanism
# Enhanced Documentation System - Automated Recovery
# Date: 2025-08-29

<#
.SYNOPSIS
    Enhanced Documentation System deployment rollback and recovery mechanism.

.DESCRIPTION
    Provides automated rollback capabilities for Enhanced Documentation System deployments
    including state preservation, service rollback, configuration restore, and health validation.
    Implements research-validated rollback best practices with comprehensive logging.

.PARAMETER BackupPath
    Path to backup directory for rollback data (default: .\backups)

.PARAMETER RollbackToVersion
    Specific version to rollback to (optional)

.PARAMETER Force
    Force rollback without confirmation prompts

.PARAMETER SkipHealthCheck
    Skip post-rollback health validation

.EXAMPLE
    .\Deploy-EnhancedDocumentationSystem-Rollback.ps1 -Force

.EXAMPLE
    .\Deploy-EnhancedDocumentationSystem-Rollback.ps1 -RollbackToVersion "v2.0.0" -BackupPath ".\custom-backups"
#>

[CmdletBinding()]
param(
    [string]$BackupPath = ".\backups",
    [string]$RollbackToVersion = $null,
    [switch]$Force,
    [switch]$SkipHealthCheck
)

$ErrorActionPreference = 'Stop'

# Logging function compatible with main deployment script
function Write-RollbackLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $color = switch ($Level) {
        'Info' { 'White' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Success' { 'Green' }
    }
    
    Write-Host "[$timestamp] [ROLLBACK] [$Level] $Message" -ForegroundColor $color
    
    # Log to rollback-specific file
    $logFile = "rollback-$(Get-Date -Format 'yyyy-MM-dd').log"
    "[$timestamp] [ROLLBACK] [$Level] $Message" | Out-File -FilePath $logFile -Append -Encoding UTF8
}

# Phase 1: Pre-rollback validation and backup discovery
function Get-RollbackState {
    param([string]$BackupPath)
    
    Write-RollbackLog "Discovering available rollback states..." -Level Info
    
    if (-not (Test-Path -Path $BackupPath)) {
        throw "Backup directory not found: $BackupPath"
    }
    
    # Find available backup states
    $backupStates = Get-ChildItem -Path $BackupPath -Directory | 
        Where-Object { $_.Name -match 'deployment-\d{8}-\d{6}' } |
        Sort-Object CreationTime -Descending
    
    if (-not $backupStates) {
        throw "No backup states found in: $BackupPath"
    }
    
    Write-RollbackLog "Found $($backupStates.Count) available backup states" -Level Info
    
    # Get latest backup if no specific version requested
    $targetBackup = if ($RollbackToVersion) {
        $backupStates | Where-Object { $_.Name -like "*$RollbackToVersion*" } | Select-Object -First 1
    } else {
        $backupStates | Select-Object -First 1
    }
    
    if (-not $targetBackup) {
        throw "Target backup not found for version: $RollbackToVersion"
    }
    
    Write-RollbackLog "Selected backup state: $($targetBackup.Name)" -Level Success
    return $targetBackup
}

# Phase 2: Service state preservation and rollback
function Invoke-ServiceRollback {
    param([System.IO.DirectoryInfo]$BackupState)
    
    Write-RollbackLog "Beginning service rollback to state: $($BackupState.Name)" -Level Info
    
    try {
        # Preserve current state before rollback (safety measure)
        $rollbackBackupPath = ".\backups\pre-rollback-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        New-Item -Path $rollbackBackupPath -ItemType Directory -Force | Out-Null
        
        # Backup current Docker state
        Write-RollbackLog "Creating pre-rollback backup..." -Level Info
        docker-compose config > "$rollbackBackupPath\docker-compose-current.yml"
        docker images --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}" > "$rollbackBackupPath\docker-images-current.txt"
        
        # Stop all current services
        Write-RollbackLog "Stopping current services..." -Level Info
        docker-compose down --remove-orphans --volumes
        docker-compose -f docker-compose.monitoring.yml down --remove-orphans --volumes 2>$null
        
        # Restore backup configuration
        $backupConfigPath = Join-Path -Path $BackupState.FullName -ChildPath "config"
        if (Test-Path -Path $backupConfigPath) {
            Write-RollbackLog "Restoring configuration from backup..." -Level Info
            Copy-Item -Path "$backupConfigPath\*" -Destination ".\config" -Recurse -Force
        }
        
        # Restore Docker compose files from backup
        $backupComposePath = Join-Path -Path $BackupState.FullName -ChildPath "docker"
        if (Test-Path -Path $backupComposePath) {
            Write-RollbackLog "Restoring Docker configuration from backup..." -Level Info
            Copy-Item -Path "$backupComposePath\docker-compose*.yml" -Destination "." -Force
        }
        
        # Restore container images if available
        $imageBackupPath = Join-Path -Path $BackupState.FullName -ChildPath "docker-images"
        if (Test-Path -Path $imageBackupPath) {
            Write-RollbackLog "Restoring Docker images from backup..." -Level Info
            Get-ChildItem -Path $imageBackupPath -Filter "*.tar" | ForEach-Object {
                Write-RollbackLog "Loading image: $($_.Name)" -Level Info
                docker load -i $_.FullName
            }
        }
        
        # Restart services with restored configuration
        Write-RollbackLog "Starting services with restored configuration..." -Level Info
        docker-compose up -d
        
        # Wait for services to initialize
        Write-RollbackLog "Waiting for services to initialize..." -Level Info
        Start-Sleep -Seconds 30
        
        Write-RollbackLog "Service rollback completed successfully" -Level Success
        
    } catch {
        Write-RollbackLog "Service rollback failed: $_" -Level Error
        throw
    }
}

# Phase 3: Configuration and data rollback
function Restore-SystemConfiguration {
    param([System.IO.DirectoryInfo]$BackupState)
    
    Write-RollbackLog "Restoring system configuration..." -Level Info
    
    try {
        # Restore module configurations
        $moduleBackupPath = Join-Path -Path $BackupState.FullName -ChildPath "modules"
        if (Test-Path -Path $moduleBackupPath) {
            Write-RollbackLog "Restoring module configurations..." -Level Info
            Copy-Item -Path "$moduleBackupPath\*" -Destination ".\Modules" -Recurse -Force
        }
        
        # Restore environment configuration
        $envBackupPath = Join-Path -Path $BackupState.FullName -ChildPath "environment"
        if (Test-Path -Path $envBackupPath) {
            Write-RollbackLog "Restoring environment configuration..." -Level Info
            Get-ChildItem -Path $envBackupPath -Filter "*.env" | ForEach-Object {
                Copy-Item -Path $_.FullName -Destination "." -Force
                Write-RollbackLog "Restored: $($_.Name)" -Level Info
            }
        }
        
        # Restore data backups if available
        $dataBackupPath = Join-Path -Path $BackupState.FullName -ChildPath "data"
        if (Test-Path -Path $dataBackupPath) {
            Write-RollbackLog "Restoring system data..." -Level Info
            if (Test-Path -Path ".\data") {
                Remove-Item -Path ".\data" -Recurse -Force
            }
            Copy-Item -Path $dataBackupPath -Destination "." -Recurse -Force
        }
        
        Write-RollbackLog "System configuration restored successfully" -Level Success
        
    } catch {
        Write-RollbackLog "Configuration restore failed: $_" -Level Error
        throw
    }
}

# Phase 4: Post-rollback validation and health checks
function Test-RollbackHealth {
    Write-RollbackLog "Performing post-rollback health validation..." -Level Info
    
    $healthChecks = @()
    
    try {
        # Check Docker service status
        Write-RollbackLog "Checking Docker service status..." -Level Info
        $runningServices = docker-compose ps --services --filter "status=running"
        $expectedServices = @('docs-api', 'powershell-modules', 'docs-web')
        
        foreach ($service in $expectedServices) {
            $isRunning = $runningServices -contains $service
            $healthChecks += [PSCustomObject]@{
                Component = "Docker Service: $service"
                Status = if ($isRunning) { "HEALTHY" } else { "UNHEALTHY" }
                Message = if ($isRunning) { "Service running" } else { "Service not running" }
            }
        }
        
        # Check API endpoints
        Write-RollbackLog "Checking API endpoint health..." -Level Info
        $endpoints = @(
            @{ URL = "http://localhost:8091/health"; Name = "Documentation API" },
            @{ URL = "http://localhost:8080"; Name = "Documentation Web" }
        )
        
        foreach ($endpoint in $endpoints) {
            try {
                $response = Invoke-RestMethod -Uri $endpoint.URL -TimeoutSec 10 -ErrorAction Stop
                $healthChecks += [PSCustomObject]@{
                    Component = $endpoint.Name
                    Status = "HEALTHY"
                    Message = "Endpoint responding"
                }
            } catch {
                $healthChecks += [PSCustomObject]@{
                    Component = $endpoint.Name
                    Status = "UNHEALTHY"
                    Message = "Endpoint not responding: $_"
                }
            }
        }
        
        # Check PowerShell module availability
        Write-RollbackLog "Checking PowerShell module availability..." -Level Info
        $criticalModules = @('Unity-Claude-CPG', 'Unity-Claude-LLM', 'Unity-Claude-SemanticAnalysis')
        
        foreach ($module in $criticalModules) {
            try {
                $moduleInfo = Get-Module -ListAvailable -Name "*$module*" -ErrorAction Stop
                $healthChecks += [PSCustomObject]@{
                    Component = "PowerShell Module: $module"
                    Status = if ($moduleInfo) { "HEALTHY" } else { "UNHEALTHY" }
                    Message = if ($moduleInfo) { "Module available" } else { "Module not found" }
                }
            } catch {
                $healthChecks += [PSCustomObject]@{
                    Component = "PowerShell Module: $module"
                    Status = "UNHEALTHY"
                    Message = "Module check failed: $_"
                }
            }
        }
        
        # Generate health report
        $healthyCount = ($healthChecks | Where-Object { $_.Status -eq "HEALTHY" }).Count
        $totalCount = $healthChecks.Count
        $healthPercentage = [math]::Round(($healthyCount / $totalCount) * 100, 1)
        
        Write-RollbackLog "Health check summary: $healthyCount/$totalCount components healthy ($healthPercentage%)" -Level Info
        
        # Display detailed results
        $healthChecks | ForEach-Object {
            $level = if ($_.Status -eq "HEALTHY") { "Success" } else { "Warning" }
            Write-RollbackLog "$($_.Component): $($_.Status) - $($_.Message)" -Level $level
        }
        
        # Save health report
        $healthReport = [PSCustomObject]@{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            OverallHealth = $healthPercentage
            TotalComponents = $totalCount
            HealthyComponents = $healthyCount
            UnhealthyComponents = $totalCount - $healthyCount
            DetailedResults = $healthChecks
        }
        
        $healthReport | ConvertTo-Json -Depth 5 | Out-File -FilePath "rollback-health-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss').json" -Encoding UTF8
        
        if ($healthPercentage -lt 80) {
            Write-RollbackLog "WARNING: Health check shows $healthPercentage% healthy (below 80% threshold)" -Level Warning
            return $false
        } else {
            Write-RollbackLog "Health validation successful: $healthPercentage% healthy" -Level Success
            return $true
        }
        
    } catch {
        Write-RollbackLog "Health check failed: $_" -Level Error
        return $false
    }
}

# Main rollback execution
function Invoke-SystemRollback {
    Write-RollbackLog "=== Enhanced Documentation System Rollback Started ===" -Level Info
    Write-RollbackLog "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level Info
    
    if (-not $Force) {
        $confirmation = Read-Host "Are you sure you want to rollback the Enhanced Documentation System? (yes/no)"
        if ($confirmation -ne "yes") {
            Write-RollbackLog "Rollback cancelled by user" -Level Warning
            exit 0
        }
    }
    
    $rollbackStart = Get-Date
    $rollbackSuccess = $false
    
    try {
        # Phase 1: Discover available backup states
        $backupState = Get-RollbackState -BackupPath $BackupPath
        Write-RollbackLog "Using backup state: $($backupState.Name) (Created: $($backupState.CreationTime))" -Level Info
        
        # Phase 2: Perform service rollback
        Invoke-ServiceRollback -BackupState $backupState
        
        # Phase 3: Restore system configuration  
        Restore-SystemConfiguration -BackupState $backupState
        
        # Phase 4: Post-rollback validation
        if (-not $SkipHealthCheck) {
            $healthPassed = Test-RollbackHealth
            if (-not $healthPassed) {
                Write-RollbackLog "Post-rollback health check failed - manual intervention may be required" -Level Warning
            }
        }
        
        $rollbackSuccess = $true
        $duration = (Get-Date) - $rollbackStart
        
        Write-RollbackLog "=== ROLLBACK COMPLETED SUCCESSFULLY ===" -Level Success
        Write-RollbackLog "Duration: $($duration.ToString('hh\:mm\:ss'))" -Level Success
        Write-RollbackLog "Backup used: $($backupState.Name)" -Level Success
        
    } catch {
        $duration = (Get-Date) - $rollbackStart
        Write-RollbackLog "=== ROLLBACK FAILED ===" -Level Error
        Write-RollbackLog "Duration: $($duration.ToString('hh\:mm\:ss'))" -Level Error
        Write-RollbackLog "Error: $_" -Level Error
        
        # Create failure report
        $failureReport = [PSCustomObject]@{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Duration = $duration.ToString('hh\:mm\:ss')
            BackupPath = $BackupPath
            TargetVersion = $RollbackToVersion
            Error = $_.Exception.Message
            StackTrace = $_.ScriptStackTrace
        }
        
        $failureReport | ConvertTo-Json -Depth 5 | Out-File -FilePath "rollback-failure-$(Get-Date -Format 'yyyy-MM-dd-HH-mm-ss').json" -Encoding UTF8
        
        throw
    }
    
    return $rollbackSuccess
}

# Execute main rollback process
try {
    $result = Invoke-SystemRollback
    exit 0
} catch {
    Write-RollbackLog "Rollback execution failed: $_" -Level Error
    exit 1
}