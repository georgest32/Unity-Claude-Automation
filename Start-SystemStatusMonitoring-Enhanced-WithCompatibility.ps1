# Start-SystemStatusMonitoring-Enhanced-WithCompatibility.ps1
# Enhanced version with Bootstrap Orchestrator compatibility and migration support
# Date: 2025-08-22
# Phase 3 Day 2: Migration and Backward Compatibility - Hour 3-4

param(
    [switch]$EnableHeartbeat = $true,
    [switch]$EnableFileWatcher = $true,
    [switch]$EnableNamedPipes = $false,
    [int]$HeartbeatIntervalSeconds = 60,
    [switch]$UseLegacyMode = $false,           # NEW: Force legacy mode
    [switch]$UseManifestMode = $false,         # NEW: Force manifest-based mode
    [switch]$Verbose,
    [switch]$Debug
)

$ErrorActionPreference = "Continue"
if ($Verbose) { $VerbosePreference = "Continue" }
if ($Debug) { $DebugPreference = "Continue" }

# Ensure we're in the correct directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($scriptDir) {
    Set-Location $scriptDir
    Write-Host "Changed to directory: $scriptDir" -ForegroundColor DarkGray
}

# Load compatibility layer
try {
    Import-Module ".\Migration\Legacy-Compatibility.psm1" -Force
    Write-Host "Loaded backward compatibility layer" -ForegroundColor Cyan
} catch {
    Write-Warning "Could not load compatibility layer: $($_.Exception.Message)"
    Write-Warning "Falling back to legacy mode"
    $UseLegacyMode = $true
}

# Create log file for this session
$logFile = Join-Path (Get-Location) "SystemStatusMonitoring_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-MonitorLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $logFile -Value $logEntry
    
    # Also write to console
    switch ($Level) {
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "WARN"  { Write-Host $Message -ForegroundColor Yellow }
        "DEBUG" { if ($Debug) { Write-Host $Message -ForegroundColor DarkGray } }
        "INFO"  { Write-Host $Message -ForegroundColor White }
        default { Write-Host $Message -ForegroundColor Gray }
    }
}

function Start-LegacySystemStatusMonitoring {
    param(
        [switch]$EnableHeartbeat,
        [switch]$EnableFileWatcher,
        [switch]$EnableNamedPipes,
        [int]$HeartbeatIntervalSeconds
    )
    
    Show-DeprecationWarning -FunctionName "Start-LegacySystemStatusMonitoring" -Replacement "Start-ManifestBasedSystemStatusMonitoring"
    
    Write-MonitorLog "Starting SystemStatus monitoring (LEGACY MODE)" "INFO"
    
    # Original legacy implementation
    try {
        # Import required modules (legacy way)
        $modulePaths = @(
            ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1",
            ".\Modules\Unity-Claude-CLISubmission.psm1"
        )
        
        foreach ($modulePath in $modulePaths) {
            if (Test-Path $modulePath) {
                Import-Module $modulePath -Force
                Write-MonitorLog "Loaded module: $modulePath" "INFO"
            } else {
                Write-MonitorLog "Module not found: $modulePath" "WARN"
            }
        }
        
        # Register system status (legacy hardcoded)
        $subsystemInfo = @{
            Name = "SystemStatusMonitoring"
            PID = $PID
            Status = "Running"
            StartTime = Get-Date
            Version = "1.0.0"
            Type = "SystemMonitoring"
        }
        
        Write-SystemStatus -SubsystemName "SystemStatusMonitoring" -Status $subsystemInfo
        Write-MonitorLog "Registered SystemStatus subsystem (legacy)" "SUCCESS"
        
        # Start heartbeat if enabled
        if ($EnableHeartbeat) {
            Write-MonitorLog "Starting heartbeat timer (interval: $HeartbeatIntervalSeconds seconds)" "INFO"
            
            $heartbeatTimer = New-Object System.Timers.Timer
            $heartbeatTimer.Interval = $HeartbeatIntervalSeconds * 1000
            $heartbeatTimer.AutoReset = $true
            
            Register-ObjectEvent -InputObject $heartbeatTimer -EventName Elapsed -Action {
                try {
                    Send-Heartbeat -SubsystemName "SystemStatusMonitoring"
                    Write-Host "[$(Get-Date)] Heartbeat sent" -ForegroundColor DarkGreen
                } catch {
                    Write-Host "[$(Get-Date)] Heartbeat failed: $($_.Exception.Message)" -ForegroundColor Red
                }
            } | Out-Null
            
            $heartbeatTimer.Start()
            Write-MonitorLog "Heartbeat timer started" "SUCCESS"
        }
        
        # Start file watcher if enabled
        if ($EnableFileWatcher) {
            Write-MonitorLog "Starting file system watcher" "INFO"
            
            $watcher = New-Object System.IO.FileSystemWatcher
            $watcher.Path = Get-Location
            $watcher.Filter = "*.json"
            $watcher.EnableRaisingEvents = $true
            
            Register-ObjectEvent -InputObject $watcher -EventName Changed -Action {
                $path = $Event.SourceEventArgs.FullPath
                if ($path -like "*system_status.json") {
                    Write-Host "[$(Get-Date)] System status file changed: $path" -ForegroundColor Yellow
                }
            } | Out-Null
            
            Write-MonitorLog "File system watcher started" "SUCCESS"
        }
        
        return @{
            Success = $true
            Mode = "Legacy"
            Components = @("Heartbeat", "FileWatcher") | Where-Object { 
                ($_ -eq "Heartbeat" -and $EnableHeartbeat) -or 
                ($_ -eq "FileWatcher" -and $EnableFileWatcher) 
            }
        }
        
    } catch {
        Write-MonitorLog "Legacy monitoring startup failed: $($_.Exception.Message)" "ERROR"
        return @{
            Success = $false
            Mode = "Legacy"
            Error = $_.Exception.Message
        }
    }
}

function Start-ManifestBasedSystemStatusMonitoring {
    Write-MonitorLog "Starting SystemStatus monitoring (MANIFEST MODE)" "INFO"
    
    try {
        # Import SystemStatus module with manifest support
        $systemStatusModule = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1"
        if (Test-Path $systemStatusModule) {
            Import-Module $systemStatusModule -Force
            Write-MonitorLog "Loaded SystemStatus module with manifest support" "INFO"
        } else {
            throw "SystemStatus module not found: $systemStatusModule"
        }
        
        # Check for manifest
        $manifestPath = ".\Manifests\SystemMonitoring.manifest.psd1"
        if (-not (Test-Path $manifestPath)) {
            Write-MonitorLog "SystemMonitoring manifest not found, creating default..." "WARN"
            
            # Create default manifest
            $defaultManifest = @{
                Name = "SystemMonitoring"
                Version = "1.0.0"
                StartScript = ".\Start-SystemStatusMonitoring-Enhanced-WithCompatibility.ps1"
                Dependencies = @()
                HealthCheckFunction = "Test-SystemStatusHealth"
                HealthCheckInterval = 15
                RestartPolicy = "Always"
                MaxRestarts = 10
                RestartDelay = 3
                MutexName = "Global\UnityClaudeSystemMonitoring"
            }
            
            # This would normally create the manifest, but for now just log
            Write-MonitorLog "Would create default SystemMonitoring manifest" "INFO"
        }
        
        # Initialize using manifest-based configuration
        $initResult = Initialize-SystemStatusMonitoring -EnableManifestMode
        
        if ($initResult.Success) {
            Write-MonitorLog "Manifest-based monitoring initialized successfully" "SUCCESS"
            
            # Register using manifest system
            $manifestConfig = Get-SubsystemManifests -Path ".\Manifests" | Where-Object { $_.Name -eq "SystemMonitoring" }
            if ($manifestConfig) {
                $registerResult = Register-SubsystemFromManifest -Manifest $manifestConfig
                if ($registerResult.Success) {
                    Write-MonitorLog "Registered via manifest system" "SUCCESS"
                }
            }
            
            return @{
                Success = $true
                Mode = "Manifest"
                ManifestPath = $manifestPath
                InitializationResult = $initResult
            }
        } else {
            throw "Manifest-based initialization failed: $($initResult.Message)"
        }
        
    } catch {
        Write-MonitorLog "Manifest-based monitoring startup failed: $($_.Exception.Message)" "ERROR"
        Write-MonitorLog "Falling back to legacy mode..." "WARN"
        
        # Fallback to legacy mode
        return Start-LegacySystemStatusMonitoring -EnableHeartbeat:$EnableHeartbeat -EnableFileWatcher:$EnableFileWatcher -EnableNamedPipes:$EnableNamedPipes -HeartbeatIntervalSeconds:$HeartbeatIntervalSeconds
    }
}

# Main execution logic
Write-MonitorLog "=================================================" "INFO"
Write-MonitorLog "Unity-Claude System Status Monitoring (ENHANCED WITH COMPATIBILITY)" "INFO"
Write-MonitorLog "=================================================" "INFO"
Write-MonitorLog "Starting at: $(Get-Date)" "INFO"
Write-MonitorLog "PID: $PID" "INFO"

# Determine mode to use
if ($UseLegacyMode -and $UseManifestMode) {
    Write-MonitorLog "ERROR: Cannot specify both -UseLegacyMode and -UseManifestMode" "ERROR"
    exit 1
}

$useManifestMode = $false

if ($UseLegacyMode) {
    Write-MonitorLog "Mode: Legacy (forced by parameter)" "INFO"
    $useManifestMode = $false
} elseif ($UseManifestMode) {
    Write-MonitorLog "Mode: Manifest-based (forced by parameter)" "INFO" 
    $useManifestMode = $true
} else {
    # Auto-detect mode
    $migrationStatus = Test-MigrationStatus
    
    Write-MonitorLog "Migration Status: $($migrationStatus.Status)" "INFO"
    Write-MonitorLog "Recommendation: $($migrationStatus.RecommendedAction)" "INFO"
    
    if ($migrationStatus.ManifestsExist) {
        Write-MonitorLog "Mode: Manifest-based (auto-detected)" "INFO"
        $useManifestMode = $true
    } else {
        Write-MonitorLog "Mode: Legacy (auto-detected)" "INFO"
        $useManifestMode = $false
        
        Write-MonitorLog "MIGRATION AVAILABLE: Run .\Migration\Migrate-ToManifestSystem.ps1 to upgrade" "INFO"
    }
}

# Start monitoring using selected mode
try {
    if ($useManifestMode) {
        $result = Start-ManifestBasedSystemStatusMonitoring
    } else {
        $result = Start-LegacySystemStatusMonitoring -EnableHeartbeat:$EnableHeartbeat -EnableFileWatcher:$EnableFileWatcher -EnableNamedPipes:$EnableNamedPipes -HeartbeatIntervalSeconds:$HeartbeatIntervalSeconds
    }
    
    if ($result.Success) {
        Write-MonitorLog "SystemStatus monitoring started successfully in $($result.Mode) mode" "SUCCESS"
        Write-MonitorLog "Log file: $logFile" "INFO"
        
        if ($result.Components) {
            Write-MonitorLog "Active components: $($result.Components -join ', ')" "INFO"
        }
        
        # Keep the script running
        Write-MonitorLog "Monitoring active - press Ctrl+C to stop" "INFO"
        
        try {
            while ($true) {
                Start-Sleep -Seconds 30
                Write-MonitorLog "SystemStatus monitoring - heartbeat check" "DEBUG"
            }
        } catch {
            Write-MonitorLog "Monitoring stopped: $($_.Exception.Message)" "INFO"
        }
    } else {
        Write-MonitorLog "SystemStatus monitoring failed to start" "ERROR"
        if ($result.Error) {
            Write-MonitorLog "Error details: $($result.Error)" "ERROR"
        }
        exit 1
    }
    
} catch {
    Write-MonitorLog "Critical error during startup: $($_.Exception.Message)" "ERROR"
    Write-MonitorLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}

Write-MonitorLog "SystemStatus monitoring session ended" "INFO"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUO+NZDB+iQJCTj8WNO1olb5bv
# ryKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQU9b1YB/gQCp7WNFJjVMc7wwK7I2gwDQYJKoZIhvcNAQEBBQAEggEARjPk
# Sjjn+0NH8HmhldARFIYZm025NURJu4Bk9jqDoCDIQrlCdV+JEMKvwwRF7SnxlQPp
# 02lblOkGCHrAVfO28pj54EleqqnTfYvFDMM0/AddE/UapabQ+FVndDGktkbA76Mc
# 1c0hbCpBXb3g1dyPMcNPUIfbdYq+UlIVyFkyO+9B16AldpcqUclfpITuQvf/Puod
# Lm4V+dPfJwYofLMIp519lxLdjn8+CGSQnQxS9I3u71a9sEpzEGqB+xy8p/WRYEDF
# dRELAlHTNxVM8FuGbVwXvQwBm34wBZ+batnwkCGu2rH65tQQFDWNuDhOatfTFvPS
# FOkhtEzsdqCg1MtAIQ==
# SIG # End signature block
