# Migrate-ToManifestSystem.ps1
# Migration script to convert existing Unity-Claude-Automation configurations to manifest-based system
# Date: 2025-08-22
# Author: Claude
# Phase 3 Day 2: Migration and Backward Compatibility - Hour 1-2

param(
    [switch]$WhatIf = $false,           # Show what would be migrated without making changes
    [switch]$Force = $false,            # Overwrite existing manifests
    [switch]$Backup = $true,            # Create backup before migration (default: true)
    [string]$BackupPath = ".\Backups\Migration_$(Get-Date -Format 'yyyyMMdd_HHmmss')",
    [switch]$Verbose = $false,
    [switch]$Debug = $false
)

$ErrorActionPreference = "Continue"
if ($Verbose) { $VerbosePreference = "Continue" }
if ($Debug) { $DebugPreference = "Continue" }

# Set up directories
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
$manifestsDir = Join-Path $rootDir "Manifests"
$templatesDir = Join-Path $rootDir "Modules\Unity-Claude-SystemStatus\Templates"

# Create directories if they don't exist
if (-not (Test-Path $manifestsDir)) {
    New-Item -ItemType Directory -Path $manifestsDir -Force | Out-Null
}

# Migration logging
$migrationLog = Join-Path $rootDir "Migration_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"

function Write-MigrationLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $migrationLog -Value $logEntry
    
    # Also write to console with color coding
    switch ($Level) {
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "WARN"  { Write-Host $Message -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        "INFO"  { Write-Host $Message -ForegroundColor White }
        default { Write-Host $Message -ForegroundColor Gray }
    }
}

function New-BackupDirectory {
    if ($Backup -and -not $WhatIf) {
        if (-not (Test-Path $BackupPath)) {
            New-Item -ItemType Directory -Path $BackupPath -Force | Out-Null
            Write-MigrationLog "Created backup directory: $BackupPath" "INFO"
        }
        return $BackupPath
    }
    return $null
}

function Backup-ExistingConfiguration {
    param([string]$BackupDir)
    
    if (-not $BackupDir) { return }
    
    Write-MigrationLog "Creating backup of existing configuration..." "INFO"
    
    # Backup key configuration files
    $filesToBackup = @(
        "Start-SystemStatusMonitoring-Enhanced.ps1",
        "Start-UnifiedSystem-Complete.ps1",
        "Start-AutonomousMonitoring-Fixed.ps1",
        "Unity-Claude-Configuration.psm1",
        "system_status.json"
    )
    
    foreach ($file in $filesToBackup) {
        $sourcePath = Join-Path $rootDir $file
        if (Test-Path $sourcePath) {
            $destPath = Join-Path $BackupDir $file
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            Write-MigrationLog "Backed up: $file" "INFO"
        }
    }
    
    # Backup existing manifests
    if (Test-Path $manifestsDir) {
        $manifestBackupDir = Join-Path $BackupDir "Manifests"
        Copy-Item -Path $manifestsDir -Destination $manifestBackupDir -Recurse -Force
        Write-MigrationLog "Backed up existing manifests" "INFO"
    }
}

function Get-AutonomousAgentConfiguration {
    # Analyze existing AutonomousAgent configuration from scripts and files
    Write-MigrationLog "Analyzing AutonomousAgent configuration..." "INFO"
    
    $config = @{
        Name = "AutonomousAgent"
        Version = "1.0.0"
        Description = "Autonomous monitoring and response agent for Unity error detection and automated fixes"
        StartScript = ".\Start-AutonomousMonitoring-Fixed.ps1"
        Dependencies = @("SystemStatus")
        HealthCheckFunction = "Test-AutonomousAgentStatus"
        HealthCheckInterval = 30
        RestartPolicy = "OnFailure"
        MaxRestarts = 3
        RestartDelay = 5
        MaxMemoryMB = 500
        MaxCpuPercent = 25
        MutexName = "Global\UnityClaudeAutonomousAgent"
    }
    
    # Try to extract actual configuration from existing scripts
    $startScript = Join-Path $rootDir "Start-AutonomousMonitoring-Fixed.ps1"
    if (Test-Path $startScript) {
        $content = Get-Content $startScript -Raw
        
        # Extract heartbeat interval if present
        if ($content -match 'HeartbeatIntervalSeconds\s*=\s*(\d+)') {
            $config.HealthCheckInterval = [int]$matches[1]
            Write-MigrationLog "Extracted HealthCheckInterval: $($config.HealthCheckInterval)" "INFO"
        }
        
        # Check for memory/CPU limits in comments or variables
        if ($content -match 'MaxMemoryMB\s*=\s*(\d+)') {
            $config.MaxMemoryMB = [int]$matches[1]
        }
        if ($content -match 'MaxCpuPercent\s*=\s*(\d+)') {
            $config.MaxCpuPercent = [int]$matches[1]
        }
    }
    
    # Check system_status.json for existing configuration
    $systemStatusFile = Join-Path $rootDir "system_status.json"
    if (Test-Path $systemStatusFile) {
        try {
            $systemStatus = Get-Content $systemStatusFile -Raw | ConvertFrom-Json
            if ($systemStatus.subsystems -and $systemStatus.subsystems.AutonomousAgent) {
                $agentConfig = $systemStatus.subsystems.AutonomousAgent
                Write-MigrationLog "Found existing AutonomousAgent configuration in system_status.json" "INFO"
                
                # Extract relevant settings
                if ($agentConfig.settings) {
                    if ($agentConfig.settings.heartbeat_interval) {
                        $config.HealthCheckInterval = $agentConfig.settings.heartbeat_interval
                    }
                    if ($agentConfig.settings.restart_policy) {
                        $config.RestartPolicy = $agentConfig.settings.restart_policy
                    }
                }
            }
        } catch {
            Write-MigrationLog "Could not parse system_status.json: $($_.Exception.Message)" "WARN"
        }
    }
    
    return $config
}

function Get-CLISubmissionConfiguration {
    # Analyze CLI submission subsystem configuration
    Write-MigrationLog "Analyzing CLISubmission configuration..." "INFO"
    
    $config = @{
        Name = "CLISubmission"
        Version = "1.0.0"
        Description = "CLI interface for submitting Unity errors to Claude AI for analysis and fixes"
        StartScript = ".\CLI-Automation\Submit-ErrorsToClaude-Final.ps1"
        Dependencies = @("SystemStatus")
        HealthCheckFunction = $null  # Use default PID check
        HealthCheckInterval = 60
        RestartPolicy = "OnFailure"
        MaxRestarts = 5
        RestartDelay = 2
        MaxMemoryMB = 200
        MaxCpuPercent = 15
        MutexName = "Global\UnityClaudeCLISubmission"
    }
    
    # Check if Claude API is preferred over CLI automation
    $apiScript = Join-Path $rootDir "API-Integration\Submit-ErrorsToClaude-API.ps1"
    if (Test-Path $apiScript) {
        $config.StartScript = ".\API-Integration\Submit-ErrorsToClaude-API.ps1"
        Write-MigrationLog "Using API integration for CLISubmission" "INFO"
    }
    
    return $config
}

function Get-SystemMonitoringConfiguration {
    # Analyze system monitoring configuration
    Write-MigrationLog "Analyzing SystemMonitoring configuration..." "INFO"
    
    $config = @{
        Name = "SystemMonitoring"
        Version = "1.0.0"
        Description = "Core system status monitoring and health tracking subsystem"
        StartScript = ".\Start-SystemStatusMonitoring-Enhanced.ps1"
        Dependencies = @()  # Base subsystem
        HealthCheckFunction = "Test-SystemStatusHealth"
        HealthCheckInterval = 15
        RestartPolicy = "Always"
        MaxRestarts = 10
        RestartDelay = 3
        MaxMemoryMB = 300
        MaxCpuPercent = 20
        MutexName = "Global\UnityClaudeSystemMonitoring"
    }
    
    return $config
}

function New-SubsystemManifest {
    param(
        [hashtable]$Config,
        [string]$OutputPath,
        [switch]$WhatIfMode
    )
    
    $manifestPath = Join-Path $OutputPath "$($Config.Name).manifest.psd1"
    
    if ((Test-Path $manifestPath) -and -not $Force) {
        Write-MigrationLog "Manifest already exists: $manifestPath (use -Force to overwrite)" "WARN"
        return $false
    }
    
    if ($WhatIfMode) {
        Write-MigrationLog "WHATIF: Would create manifest: $manifestPath" "INFO"
        return $true
    }
    
    # Generate dependencies array string properly
    $dependenciesString = if ($Config.Dependencies -and $Config.Dependencies.Count -gt 0) {
        '@("' + ($Config.Dependencies -join '", "') + '")'
    } else {
        '@()'
    }
    
    # Generate health check function string
    $healthCheckString = if ($Config.HealthCheckFunction) {
        '"' + $Config.HealthCheckFunction + '"'
    } else {
        '$null'
    }
    
    # Generate manifest content with proper PowerShell data file syntax
    $manifestContent = @"
# $($Config.Name) Subsystem Manifest
# Generated by Migrate-ToManifestSystem.ps1 on $(Get-Date)
# Bootstrap Orchestrator Configuration

@{
    # Required fields
    Name = "$($Config.Name)"
    Version = "$($Config.Version)"
    Description = "$($Config.Description)"
    StartScript = "$($Config.StartScript)"
    
    # Dependencies
    Dependencies = $dependenciesString
    
    # Health monitoring
    HealthCheckFunction = $healthCheckString
    HealthCheckInterval = $($Config.HealthCheckInterval)  # seconds
    
    # Recovery policy
    RestartPolicy = "$($Config.RestartPolicy)"  # OnFailure, Always, Never
    MaxRestarts = $($Config.MaxRestarts)
    RestartDelay = $($Config.RestartDelay)  # seconds
    
    # Resource limits
    MaxMemoryMB = $($Config.MaxMemoryMB)
    MaxCpuPercent = $($Config.MaxCpuPercent)
    
    # Mutex for singleton enforcement
    MutexName = "$($Config.MutexName)"
    
    # Migration metadata
    MigratedFrom = "Legacy configuration"
    MigrationDate = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    GeneratedBy = "Migrate-ToManifestSystem.ps1"
}
"@
    
    try {
        $manifestContent | Out-File -FilePath $manifestPath -Encoding UTF8
        Write-MigrationLog "Created manifest: $manifestPath" "SUCCESS"
        return $true
    } catch {
        Write-MigrationLog "Failed to create manifest: $manifestPath - $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-ManifestValidity {
    param([string]$ManifestPath)
    
    try {
        $manifest = Import-PowerShellDataFile -Path $ManifestPath
        
        # Basic validation
        $requiredFields = @('Name', 'Version', 'StartScript', 'Dependencies', 'RestartPolicy', 'MutexName')
        $missing = @()
        
        foreach ($field in $requiredFields) {
            if (-not $manifest.ContainsKey($field)) {
                $missing += $field
            }
        }
        
        if ($missing.Count -gt 0) {
            Write-MigrationLog "Manifest validation failed - missing fields: $($missing -join ', ')" "ERROR"
            return $false
        }
        
        Write-MigrationLog "Manifest validation passed: $ManifestPath" "SUCCESS"
        return $true
    } catch {
        Write-MigrationLog "Manifest validation failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function New-MigrationReport {
    param(
        [array]$Results,
        [string]$BackupPath
    )
    
    $reportPath = Join-Path $rootDir "Migration_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').md"
    
    $report = @"
# Unity-Claude-Automation Migration Report
## Generated: $(Get-Date)
## Migration Script: Migrate-ToManifestSystem.ps1

### Migration Summary
- **Total Subsystems Processed**: $($Results.Count)
- **Successful Migrations**: $($Results | Where-Object { $_.Success } | Measure-Object).Count
- **Failed Migrations**: $($Results | Where-Object { -not $_.Success } | Measure-Object).Count
- **Backup Location**: $BackupPath
- **WhatIf Mode**: $WhatIf

### Migrated Subsystems
$($Results | ForEach-Object {
    "- **$($_.Name)**: $(if ($_.Success) { 'SUCCESS' } else { 'FAILED' }) - $($_.Message)"
})

### Next Steps
1. **Test New Manifests**: Run Test-ManifestSystem.ps1 to validate all manifests
2. **Update Entry Scripts**: Modify start scripts to use -UseLegacyMode or new manifest system
3. **Verify Dependencies**: Ensure all dependency relationships are correct
4. **Performance Testing**: Test system startup with new manifest-based orchestration

### Rollback Instructions
If migration issues occur:
1. Stop all running subsystems
2. Restore files from backup: $BackupPath
3. Remove generated manifests from: $manifestsDir
4. Restart using legacy mode: -UseLegacyMode switch

### Generated Files
- **Migration Log**: $migrationLog
- **Migration Report**: $reportPath
- **Generated Manifests**: $(Get-ChildItem $manifestsDir -Filter "*.manifest.psd1" | ForEach-Object { $_.Name }) -join ', ')

### Configuration Analysis Results
$(if ($Results | Where-Object { $_.ConfigDetails }) {
    $Results | Where-Object { $_.ConfigDetails } | ForEach-Object {
        "#### $($_.Name)`n$($_.ConfigDetails)`n"
    }
})
"@
    
    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-MigrationLog "Generated migration report: $reportPath" "SUCCESS"
    return $reportPath
}

# Main Migration Logic
Write-MigrationLog "=================================================" "INFO"
Write-MigrationLog "Unity-Claude-Automation Manifest Migration" "INFO"
Write-MigrationLog "=================================================" "INFO"
Write-MigrationLog "Starting migration at: $(Get-Date)" "INFO"
Write-MigrationLog "WhatIf Mode: $WhatIf" "INFO"
Write-MigrationLog "Force Overwrite: $Force" "INFO"
Write-MigrationLog "Create Backup: $Backup" "INFO"

# Create backup if requested
$backupDir = New-BackupDirectory
if ($backupDir) {
    Backup-ExistingConfiguration $backupDir
}

# Discover and migrate subsystems
$migrationResults = @()

try {
    # 1. Migrate AutonomousAgent
    Write-MigrationLog "Migrating AutonomousAgent subsystem..." "INFO"
    $autonomousConfig = Get-AutonomousAgentConfiguration
    $autonomousResult = @{
        Name = "AutonomousAgent"
        Success = $false
        Message = ""
        ConfigDetails = "Extracted configuration: HeartbeatInterval=$($autonomousConfig.HealthCheckInterval), RestartPolicy=$($autonomousConfig.RestartPolicy)"
    }
    
    if (New-SubsystemManifest -Config $autonomousConfig -OutputPath $manifestsDir -WhatIfMode:$WhatIf) {
        $manifestPath = Join-Path $manifestsDir "$($autonomousConfig.Name).manifest.psd1"
        if ($WhatIf -or (Test-ManifestValidity $manifestPath)) {
            $autonomousResult.Success = $true
            $autonomousResult.Message = "Successfully migrated AutonomousAgent configuration"
        } else {
            $autonomousResult.Message = "Manifest creation succeeded but validation failed"
        }
    } else {
        $autonomousResult.Message = "Failed to create AutonomousAgent manifest"
    }
    $migrationResults += $autonomousResult
    
    # 2. Migrate CLISubmission
    Write-MigrationLog "Migrating CLISubmission subsystem..." "INFO"
    $cliConfig = Get-CLISubmissionConfiguration
    $cliResult = @{
        Name = "CLISubmission"
        Success = $false
        Message = ""
        ConfigDetails = "Detected submission method: $($cliConfig.StartScript)"
    }
    
    if (New-SubsystemManifest -Config $cliConfig -OutputPath $manifestsDir -WhatIfMode:$WhatIf) {
        $manifestPath = Join-Path $manifestsDir "$($cliConfig.Name).manifest.psd1"
        if ($WhatIf -or (Test-ManifestValidity $manifestPath)) {
            $cliResult.Success = $true
            $cliResult.Message = "Successfully migrated CLISubmission configuration"
        } else {
            $cliResult.Message = "Manifest creation succeeded but validation failed"
        }
    } else {
        $cliResult.Message = "Failed to create CLISubmission manifest"
    }
    $migrationResults += $cliResult
    
    # 3. Migrate SystemMonitoring
    Write-MigrationLog "Migrating SystemMonitoring subsystem..." "INFO"
    $monitorConfig = Get-SystemMonitoringConfiguration
    $monitorResult = @{
        Name = "SystemMonitoring"
        Success = $false
        Message = ""
        ConfigDetails = "Base monitoring configuration with enhanced features"
    }
    
    if (New-SubsystemManifest -Config $monitorConfig -OutputPath $manifestsDir -WhatIfMode:$WhatIf) {
        $manifestPath = Join-Path $manifestsDir "$($monitorConfig.Name).manifest.psd1"
        if ($WhatIf -or (Test-ManifestValidity $manifestPath)) {
            $monitorResult.Success = $true
            $monitorResult.Message = "Successfully migrated SystemMonitoring configuration"
        } else {
            $monitorResult.Message = "Manifest creation succeeded but validation failed"
        }
    } else {
        $monitorResult.Message = "Failed to create SystemMonitoring manifest"
    }
    $migrationResults += $monitorResult
    
} catch {
    Write-MigrationLog "Critical error during migration: $($_.Exception.Message)" "ERROR"
    Write-MigrationLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
}

# Generate comprehensive migration report
$reportPath = New-MigrationReport -Results $migrationResults -BackupPath $backupDir

# Summary
$successCount = ($migrationResults | Where-Object { $_.Success }).Count
$totalCount = $migrationResults.Count

Write-MigrationLog "=================================================" "INFO"
Write-MigrationLog "Migration Complete!" "INFO"
Write-MigrationLog "Success Rate: $successCount/$totalCount subsystems migrated" "INFO"
Write-MigrationLog "Migration Log: $migrationLog" "INFO"
Write-MigrationLog "Migration Report: $reportPath" "INFO"
if ($backupDir) {
    Write-MigrationLog "Backup Location: $backupDir" "INFO"
}
Write-MigrationLog "=================================================" "INFO"

# Return results for scripting
return @{
    Success = ($successCount -eq $totalCount)
    Results = $migrationResults
    LogPath = $migrationLog
    ReportPath = $reportPath
    BackupPath = $backupDir
}