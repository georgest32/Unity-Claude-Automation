# Start-SystemStatusMonitoring-Enhanced.ps1
# Enhanced version with crash protection and comprehensive logging
# Date: 2025-08-20


# PowerShell 7 Self-Elevation

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

if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh7 = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $pwsh7) {
        Write-Host "Upgrading to PowerShell 7..." -ForegroundColor Yellow
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $MyInvocation.MyCommand.Path) + $args
        Start-Process -FilePath $pwsh7 -ArgumentList $arguments -NoNewWindow -Wait
        exit
    } else {
        Write-Warning "PowerShell 7 not found. Running in PowerShell $($PSVersionTable.PSVersion)"
    }
}

$ErrorActionPreference = "Continue"  # Changed from Stop to Continue
if ($Verbose) { $VerbosePreference = "Continue" }
if ($Debug) { $DebugPreference = "Continue" }

# Ensure we're in the correct directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($scriptDir) {
    Set-Location $scriptDir
    Write-Host "Changed to directory: $scriptDir" -ForegroundColor DarkGray
}

# Try to load compatibility layer for Bootstrap Orchestrator support
$compatibilityAvailable = $false
try {
    if (Test-Path ".\Migration\Legacy-Compatibility.psm1") {
        Import-Module ".\Migration\Legacy-Compatibility.psm1" -Force
        $compatibilityAvailable = $true
        Write-Host "Bootstrap Orchestrator compatibility layer loaded" -ForegroundColor Cyan
    }
} catch {
    Write-Host "Compatibility layer not available, using legacy mode only" -ForegroundColor Yellow
    $UseLegacyMode = $true
}

# Create log file for this session
$logFile = Join-Path (Get-Location) "SystemStatusMonitoring_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

function Write-MonitorLog {
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

Write-MonitorLog "=================================================" "INFO"
Write-MonitorLog "Unity-Claude System Status Monitoring (ENHANCED)" "INFO"
if ($compatibilityAvailable) {
    Write-MonitorLog "Bootstrap Orchestrator Compatible" "INFO"
}
Write-MonitorLog "Starting at: $(Get-Date)" "INFO"
Write-MonitorLog "PID: $PID" "INFO"
Write-MonitorLog "Log file: $logFile" "INFO"
Write-MonitorLog "=================================================" "INFO"
Write-MonitorLog "" "INFO"

# Check migration status and determine mode
if ($compatibilityAvailable -and -not $UseLegacyMode -and -not $UseManifestMode) {
    $migrationStatus = Test-MigrationStatus
    Write-MonitorLog "Migration Status: $($migrationStatus.Status)" "INFO"
    
    if ($migrationStatus.ManifestsExist) {
        Write-MonitorLog "Auto-selecting manifest-based mode" "INFO"
        $UseManifestMode = $true
    } else {
        Write-MonitorLog "Auto-selecting legacy mode (no manifests found)" "INFO"
        $UseLegacyMode = $true
    }
}

# Mode validation
if ($UseLegacyMode -and $UseManifestMode) {
    Write-MonitorLog "ERROR: Cannot specify both -UseLegacyMode and -UseManifestMode" "ERROR"
    exit 1
}

# Determine final mode
$useManifestSystem = $UseManifestMode -and $compatibilityAvailable
Write-MonitorLog "Startup Mode: $(if ($useManifestSystem) { 'Manifest-based Bootstrap Orchestrator' } else { 'Legacy Hardcoded' })" "INFO"
Write-MonitorLog "" "INFO"

# Execute startup based on mode
if ($useManifestSystem) {
    Write-MonitorLog "Using manifest-based Bootstrap Orchestrator startup..." "INFO"
    
    try {
        # Delegate to compatibility layer
        $result = Invoke-ManifestBasedSystemStartup -Debug:$Debug
        
        if ($result.Success) {
            Write-MonitorLog "Manifest-based startup completed successfully" "SUCCESS"
            Write-MonitorLog "Initialization Result: $($result.InitializationResult)" "INFO"
        } else {
            Write-MonitorLog "Manifest-based startup failed, falling back to legacy" "WARN"
            $useManifestSystem = $false
        }
    } catch {
        Write-MonitorLog "Manifest-based startup error: $($_.Exception.Message)" "ERROR"
        Write-MonitorLog "Falling back to legacy mode" "WARN"
        $useManifestSystem = $false
    }
}

if (-not $useManifestSystem) {
    Write-MonitorLog "Using legacy hardcoded startup..." "INFO"
    if ($compatibilityAvailable) {
        Show-DeprecationWarning -FunctionName "Legacy SystemStatus Startup" -Replacement "Manifest-based Bootstrap Orchestrator"
    }
}

# Report this process PID immediately
$currentPID = $PID
Write-MonitorLog "SystemStatusMonitoring Process ID: $currentPID" "INFO"

# Step 1: Import the module with error handling
Write-MonitorLog "Step 1: Loading Unity-Claude-SystemStatus module..." "INFO"

try {
    $modulePath = Join-Path (Get-Location) "Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1"
    
    if (-not (Test-Path $modulePath)) {
        Write-MonitorLog "ERROR: Module file not found at: $modulePath" "ERROR"
        Write-MonitorLog "Current directory: $(Get-Location)" "ERROR"
        Write-MonitorLog "Script directory: $scriptDir" "ERROR"
        exit 1
    }
    
    Write-MonitorLog "Importing module from: $modulePath" "DEBUG"
    Import-Module $modulePath -Force -Global -ErrorAction Stop
    
    $module = Get-Module -Name "Unity-Claude-SystemStatus"
    if ($module) {
        Write-MonitorLog "Module loaded successfully" "INFO"
        Write-MonitorLog "Version: $($module.Version)" "INFO"
        Write-MonitorLog "Functions available: $($module.ExportedFunctions.Count)" "INFO"
        
        # List all exported functions for debugging
        if ($Debug) {
            $module.ExportedFunctions.Keys | ForEach-Object {
                Write-MonitorLog "  Function: $_" "DEBUG"
            }
        }
    } else {
        Write-MonitorLog "ERROR: Module imported but not found in Get-Module" "ERROR"
        exit 1
    }
} catch {
    Write-MonitorLog "CRITICAL ERROR: Failed to load module - $($_.Exception.Message)" "ERROR"
    Write-MonitorLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}

# Step 2: Initialize the monitoring system with crash protection
Write-MonitorLog "" "INFO"
Write-MonitorLog "Step 2: Initializing System Status Monitoring..." "INFO"

try {
    Write-MonitorLog "Calling Initialize-SystemStatusMonitoring..." "DEBUG"
    Initialize-SystemStatusMonitoring -Verbose:$Verbose
    Write-MonitorLog "Monitoring system initialized" "INFO"
} catch {
    Write-MonitorLog "ERROR: Failed to initialize - $($_.Exception.Message)" "ERROR"
    Write-MonitorLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    Write-MonitorLog "Attempting to continue anyway..." "WARN"
}

# Step 3: Register subsystems with individual error handling
Write-MonitorLog "" "INFO"
Write-MonitorLog "Step 3: Registering subsystems..." "INFO"

$subsystems = @(
    @{Name = "Unity-Claude-Core"; Path = Join-Path (Get-Location) "Modules\Unity-Claude-Core"},
    @{Name = "Unity-Claude-SystemStatus"; Path = Join-Path (Get-Location) "Modules\Unity-Claude-SystemStatus"}
    # AutonomousAgent will be registered separately when loaded
)

foreach ($subsystem in $subsystems) {
    try {
        Write-MonitorLog "Registering subsystem: $($subsystem.Name)" "DEBUG"
        Register-Subsystem -SubsystemName $subsystem.Name -ModulePath $subsystem.Path -HealthCheckLevel "Standard"
        Write-MonitorLog "Registered: $($subsystem.Name)" "INFO"
    } catch {
        Write-MonitorLog "Warning: Could not register $($subsystem.Name) - $($_.Exception.Message)" "WARN"
    }
}

# Step 4: Start optional components with error handling
Write-MonitorLog "" "INFO"
Write-MonitorLog "Step 4: Starting optional components..." "INFO"

# Start file watcher if enabled
if ($EnableFileWatcher) {
    try {
        Write-MonitorLog "Starting file watcher..." "DEBUG"
        Start-SystemStatusFileWatcher
        Write-MonitorLog "File watcher started for system status file" "INFO"
    } catch {
        Write-MonitorLog "Warning: Could not start file watcher - $($_.Exception.Message)" "WARN"
    }
} else {
    Write-MonitorLog "File watcher disabled" "DEBUG"
}

# Start named pipes if enabled
if ($EnableNamedPipes) {
    try {
        Write-MonitorLog "Starting named pipes server..." "DEBUG"
        Initialize-NamedPipeServer -PipeName "UnityClaudeSystemStatus"
        Start-MessageProcessor
        Write-MonitorLog "Named pipe server started" "INFO"
    } catch {
        Write-MonitorLog "Warning: Could not start named pipes - $($_.Exception.Message)" "WARN"
    }
} else {
    Write-MonitorLog "Named pipes disabled" "DEBUG"
}

# Step 5: Start heartbeat monitoring with enhanced error handling
if ($EnableHeartbeat) {
    Write-MonitorLog "" "INFO"
    Write-MonitorLog "Step 5: Starting heartbeat monitoring..." "INFO"
    
    $heartbeatTimer = New-Object System.Timers.Timer
    $heartbeatTimer.Interval = $HeartbeatIntervalSeconds * 1000
    $heartbeatTimer.AutoReset = $true
    
    # Create heartbeat action with comprehensive error handling
    $heartbeatAction = {
        $timerStart = Get-Date
        $cycleId = [Guid]::NewGuid().ToString().Substring(0, 8)
        $localLogFile = $Event.MessageData.LogFile
        
        try {
            # Use simpler logging without $using:
            $logMsg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [HEARTBEAT] Cycle $cycleId starting"
            if ($localLogFile -and (Test-Path (Split-Path $localLogFile -Parent))) {
                Add-Content -Path $localLogFile -Value $logMsg -ErrorAction SilentlyContinue
            }
            
            # Import required functions if needed
            if (-not (Get-Command "Get-RegisteredSubsystems" -ErrorAction SilentlyContinue)) {
                return  # Module not ready yet
            }
            
            # Get registered subsystems with error handling
            try {
                $subsystems = Get-RegisteredSubsystems
                
                if ($null -eq $subsystems) {
                    $logMsg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [HEARTBEAT] No subsystems registered"
                    if ($localLogFile) { Add-Content -Path $localLogFile -Value $logMsg -ErrorAction SilentlyContinue }
                    return
                }
                
                # Send heartbeats with simplified logic
                if ($subsystems -is [hashtable]) {
                    foreach ($subsystemName in $subsystems.Keys) {
                        try {
                            if (Get-Command "Send-HeartbeatRequest" -ErrorAction SilentlyContinue) {
                                Send-HeartbeatRequest -SubsystemName $subsystemName -ErrorAction SilentlyContinue
                                $logMsg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [HEARTBEAT] Sent to: $subsystemName"
                                if ($localLogFile) { Add-Content -Path $localLogFile -Value $logMsg -ErrorAction SilentlyContinue }
                            }
                        } catch {
                            # Silently continue on heartbeat errors
                        }
                    }
                }
            } catch {
                # Silently continue if subsystem operations fail
            }
            
            # Test all heartbeats with error handling
            try {
                if (Get-Command "Test-AllSubsystemHeartbeats" -ErrorAction SilentlyContinue) {
                    $healthStatus = Test-AllSubsystemHeartbeats -ErrorAction SilentlyContinue
                    
                    if ($healthStatus) {
                        if ($healthStatus.AllHealthy) {
                            Write-Host "  All subsystems healthy" -ForegroundColor Green -ErrorAction SilentlyContinue
                        } else {
                            Write-Host "  WARNING: $($healthStatus.UnhealthyCount) subsystems unhealthy" -ForegroundColor Yellow -ErrorAction SilentlyContinue
                        }
                    }
                }
            } catch {
                # Silently continue on health check errors
            }
            
            # Check for AutonomousAgent (simplified)
            try {
                $agentModule = Get-Module -Name "Unity-Claude-AutonomousAgent*" -ErrorAction SilentlyContinue
                if ($agentModule) {
                    $logMsg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [HEARTBEAT] AutonomousAgent is loaded"
                } else {
                    $logMsg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [HEARTBEAT] AutonomousAgent not loaded (normal)"
                }
                if ($localLogFile) { Add-Content -Path $localLogFile -Value $logMsg -ErrorAction SilentlyContinue }
            } catch {
                # Silently continue
            }
            
            $duration = ((Get-Date) - $timerStart).TotalMilliseconds
            $logMsg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [HEARTBEAT] Cycle $cycleId completed in $([math]::Round($duration, 2))ms"
            if ($localLogFile) { Add-Content -Path $localLogFile -Value $logMsg -ErrorAction SilentlyContinue }
            
        } catch {
            # Log critical errors but don't crash
            $logMsg = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [HEARTBEAT] ERROR in cycle $cycleId`: $($_.Exception.Message)"
            if ($localLogFile) { Add-Content -Path $localLogFile -Value $logMsg -ErrorAction SilentlyContinue }
        }
    }
    
    $eventJob = Register-ObjectEvent -InputObject $heartbeatTimer -EventName Elapsed -Action $heartbeatAction -MessageData @{LogFile = $logFile} -SourceIdentifier "SystemStatusHeartbeat"
    
    $heartbeatTimer.Start()
    Write-MonitorLog "Heartbeat monitoring started (${HeartbeatIntervalSeconds}s interval)" "INFO"
    Write-MonitorLog "Event job created: $($eventJob.Name)" "DEBUG"
}

# Step 6: Display current status
Write-MonitorLog "" "INFO"
Write-MonitorLog "Step 6: Current System Status:" "INFO"
try {
    $status = Read-SystemStatus
    Write-MonitorLog "System Status File: system_status.json" "INFO"
    Write-MonitorLog "Last Update: $($status.systemInfo.lastUpdate)" "INFO"
    Write-MonitorLog "Registered Subsystems: $($status.subsystems.Count)" "INFO"
    Write-MonitorLog "Active Alerts: $($status.alerts.Count)" "INFO"
} catch {
    Write-MonitorLog "No existing status file found - will be created on first update" "WARN"
}

# Update system status with our PID
try {
    $statusData = Read-SystemStatus
    if (-not $statusData) {
        $statusData = @{
            systemInfo = @{
                lastUpdate = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
            }
            subsystems = @{}
            alerts = @()
        }
    }
    
    # Add SystemStatusMonitoring itself
    $statusData.subsystems["SystemStatusMonitoring"] = @{
        ProcessId = $currentPID
        Status = "Running"
        LastHeartbeat = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
    }
    
    Write-SystemStatus -StatusData $statusData
    Write-MonitorLog "Updated system status with our PID: $currentPID" "INFO"
} catch {
    Write-MonitorLog "Could not update system status: $($_.Exception.Message)" "WARN"
}

# Display completion message
Write-MonitorLog "" "INFO"
Write-MonitorLog "=================================================" "INFO"
Write-MonitorLog "System Status Monitoring is now running!" "INFO"
Write-MonitorLog "=================================================" "INFO"
Write-MonitorLog "" "INFO"
Write-MonitorLog "Log file: $logFile" "INFO"
Write-MonitorLog "Press Ctrl+C to stop monitoring..." "INFO"
Write-MonitorLog "" "INFO"

# Keep the script running with proper event handling
if ($EnableHeartbeat) {
    $mainLoopError = $null
    try {
        Write-MonitorLog "Entering event wait loop - script will remain active for timer events" "DEBUG"
        
        # Create a separate timer for status updates
        $statusTimer = New-Object System.Timers.Timer
        $statusTimer.Interval = 30000  # 30 seconds
        $statusTimer.AutoReset = $true
        
        $loopCounter = 0
        $statusAction = {
            $script:loopCounter++
            $timestamp = Get-Date -Format 'HH:mm:ss'
            Write-Host "[$timestamp] SystemStatus monitoring active (cycle: $script:loopCounter)" -ForegroundColor DarkBlue
            
            # Periodic health check every 2 minutes (4 cycles)
            if ($script:loopCounter % 4 -eq 0) {
                try {
                    $heartbeatResults = Test-AllSubsystemHeartbeats
                    if ($heartbeatResults) {
                        Write-Host "  Systems: $($heartbeatResults.TotalSubsystems) total, $($heartbeatResults.HealthyCount) healthy, $($heartbeatResults.UnhealthyCount) unhealthy" -ForegroundColor Cyan
                    }
                } catch {
                    Write-Host "  Error in health check: $($_.Exception.Message)" -ForegroundColor Yellow
                }
            }
            
            # Log every 5 minutes (10 cycles)
            if ($script:loopCounter % 10 -eq 0) {
                $logMsg = "SystemStatus monitoring still alive after $script:loopCounter cycles"
                if ($Event.MessageData.LogFile) {
                    Add-Content -Path $Event.MessageData.LogFile -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [INFO] $logMsg" -ErrorAction SilentlyContinue
                }
            }
        }
        
        $statusJob = Register-ObjectEvent -InputObject $statusTimer -EventName Elapsed -Action $statusAction -MessageData @{LogFile = $logFile} -SourceIdentifier "SystemStatusUpdate"
        $statusTimer.Start()
        
        Write-MonitorLog "Status timer started for periodic updates" "DEBUG"
        Write-MonitorLog "Waiting for events... (script will stay active)" "INFO"
        
        # Simple infinite loop that works in all contexts
        # The timers will fire their events independently
        Write-MonitorLog "Starting main monitoring loop" "INFO"
        $loopIteration = 0
        
        while ($true) {
            try {
                $loopIteration++
                if ($loopIteration % 10 -eq 0) {
                    Write-MonitorLog "Main loop iteration $loopIteration - still running" "DEBUG"
                }
                
                Start-Sleep -Seconds 60
                
                # Optional: Check if we should exit (for future enhancement)
                if (Test-Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\STOP_MONITORING.txt") {
                    Write-MonitorLog "Stop signal detected - exiting" "INFO"
                    Remove-Item "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\STOP_MONITORING.txt" -Force
                    break
                }
            } catch {
                $mainLoopError = $_
                Write-MonitorLog "ERROR in main loop iteration $loopIteration`: $($_.Exception.Message)" "ERROR"
                Write-MonitorLog "Continuing despite error..." "WARN"
                Start-Sleep -Seconds 5
            }
        }
    } catch [System.OperationCanceledException] {
        Write-MonitorLog "SystemStatus monitoring interrupted by user" "INFO"
    } catch {
        Write-MonitorLog "UNEXPECTED ERROR in main section: $($_.Exception.Message)" "ERROR"
        Write-MonitorLog "Error type: $($_.Exception.GetType().FullName)" "ERROR"
        Write-MonitorLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
        
        if ($mainLoopError) {
            Write-MonitorLog "Last main loop error: $($mainLoopError.Exception.Message)" "ERROR"
        }
    } finally {
        Write-MonitorLog "" "INFO"
        Write-MonitorLog "Stopping System Status Monitoring..." "INFO"
        
        # Cleanup
        try {
            # Unregister events
            Unregister-Event -SourceIdentifier "SystemStatusHeartbeat" -ErrorAction SilentlyContinue
            Unregister-Event -SourceIdentifier "SystemStatusUpdate" -ErrorAction SilentlyContinue
            
            if ($heartbeatTimer) {
                $heartbeatTimer.Stop()
                $heartbeatTimer.Dispose()
                Write-MonitorLog "Heartbeat timer stopped" "INFO"
            }
            
            if ($statusTimer) {
                $statusTimer.Stop()
                $statusTimer.Dispose()
                Write-MonitorLog "Status timer stopped" "INFO"
            }
            
            if ($EnableFileWatcher) {
                Stop-SystemStatusFileWatcher
                Write-MonitorLog "File watcher stopped" "INFO"
            }
            
            if ($EnableNamedPipes) {
                Stop-MessageProcessor
                Stop-NamedPipeServer
                Write-MonitorLog "Named pipes stopped" "INFO"
            }
            
            Stop-SystemStatusMonitoring
            Write-MonitorLog "System Status Monitoring stopped." "INFO"
        } catch {
            Write-MonitorLog "Error during cleanup: $($_.Exception.Message)" "WARN"
        }
    }
} else {
    # If heartbeat is disabled, still keep the script running
    Write-MonitorLog "Heartbeat disabled - entering monitoring loop" "INFO"
    try {
        while ($true) {
            Start-Sleep -Seconds 60
            Write-Host "." -NoNewline -ForegroundColor DarkGray
        }
    } catch [System.OperationCanceledException] {
        Write-MonitorLog "SystemStatus monitoring interrupted by user" "INFO"
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUS7bI2i75iUbrm33btlAKDz8g
# VY+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU5RdiTugNvrfOUFyhQecZM0SnM4gwDQYJKoZIhvcNAQEBBQAEggEABQV5
# 8XVejkg6Y/qxKYu3ysDFQJ7uwcODE567RmVSiLTMwKZagTuRKWVh8MHjbkkVH3aT
# lf5VjyPrvgH1WONVK2Bl/PCpegr/wt6RneaDaJoMcmwLRN+mSKjxysqPhWJQOjHU
# eT75SpWthZvxt0nlU0hVUziDmec+3/1LuOAicV8Xr8O7RG4PfsnbT/geORjbExFn
# WqMMNpYibiuBxsedVNf14cDosEtRs2XvEKiOTZAf2714wJlDLXv8/qMzFTy69y8F
# 32HKjFSR48Mh5ZkjSpIPEqWrLOQtT3S3z10KuZRWlai6l8Ty0X4iXKnXjpFzXBdY
# 8wHBHW92l6gBQggZKQ==
# SIG # End signature block


