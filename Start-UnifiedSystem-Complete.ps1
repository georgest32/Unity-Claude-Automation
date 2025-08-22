# Start-UnifiedSystem-Complete.ps1
# Complete unified system startup that launches everything from one script
# Date: 2025-08-20
# Updated: 2025-08-22 (Added Bootstrap Orchestrator support)


# PowerShell 7 Self-Elevation

param(
    [switch]$SkipAutonomousAgent = $false,
    [switch]$UseLegacyMode = $false,        # NEW: Force legacy hardcoded configuration
    [switch]$UseManifestMode = $false,      # NEW: Force manifest-based Bootstrap Orchestrator
    [switch]$Debug = $false
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

$ErrorActionPreference = "Continue"

# Change to script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($scriptDir) {
    Set-Location $scriptDir
}

# Try to load compatibility layer for enhanced features
$compatibilityAvailable = $false
try {
    if (Test-Path ".\Migration\Legacy-Compatibility.psm1") {
        Import-Module ".\Migration\Legacy-Compatibility.psm1" -Force
        $compatibilityAvailable = $true
        Write-Host "Bootstrap Orchestrator compatibility layer loaded" -ForegroundColor Green
    }
} catch {
    Write-Host "Compatibility layer not available, using legacy mode only" -ForegroundColor Yellow
    $UseLegacyMode = $true
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Unity-Claude Complete Unified System Startup" -ForegroundColor Cyan
Write-Host "$(if ($compatibilityAvailable) { '(Bootstrap Orchestrator Ready)' } else { '(Legacy Mode Only)' })" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Starting at: $(Get-Date)" -ForegroundColor Cyan
Write-Host ""

# Show migration status if compatibility is available
if ($compatibilityAvailable -and -not $UseLegacyMode -and -not $UseManifestMode) {
    $migrationStatus = Test-MigrationStatus
    Write-Host "Migration Status: $($migrationStatus.Status)" -ForegroundColor Cyan
    
    if ($migrationStatus.Status -eq "Pre-Migration") {
        Write-Host "TIP: You can upgrade to manifest-based system for better features" -ForegroundColor Yellow
        Write-Host "     Run: .\Migration\Migrate-ToManifestSystem.ps1" -ForegroundColor Gray
    } elseif ($migrationStatus.Status -eq "Migration Complete") {
        Write-Host "Using manifest-based Bootstrap Orchestrator" -ForegroundColor Green
        $UseManifestMode = $true
    }
    Write-Host ""
}

# Step 1: Find and register Claude Code CLI
Write-Host "Step 1: Finding Claude Code CLI..." -ForegroundColor Yellow

$claudePID = $null
try {
    $claudePID = & ".\Get-ClaudeCodePID.ps1"
    if ($claudePID) {
        Write-Host "  Claude Code CLI found: PID $claudePID" -ForegroundColor Green
    } else {
        Write-Host "  Claude Code CLI not found (will continue anyway)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Error finding Claude Code CLI: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 2: Choose monitoring approach
Write-Host ""
Write-Host "Step 2: Starting SystemStatus monitoring..." -ForegroundColor Yellow

# Option to sign scripts first (recommended)
$signScripts = Read-Host "Sign all scripts to avoid execution policy issues? (Y/N) [Default: N]"
if ($signScripts -eq "Y") {
    Write-Host "  Signing all PowerShell scripts..." -ForegroundColor Cyan
    & .\Sign-PowerShellScripts.ps1
    Write-Host "  Scripts signed successfully" -ForegroundColor Green
}

# Determine startup approach based on mode
if ($compatibilityAvailable -and ($UseManifestMode -or ($migrationStatus.Status -eq "Migration Complete"))) {
    # USE MANIFEST-BASED BOOTSTRAP ORCHESTRATOR
    Write-Host "=== MANIFEST-BASED STARTUP ===" -ForegroundColor Green
    
    try {
        $result = Start-UnityClaudeSystem -UseManifestMode -Debug:$Debug
        
        if ($result.Success) {
            Write-Host "Manifest-based system started successfully!" -ForegroundColor Green
            Write-Host "Started subsystems: $($result.StartedSubsystems -join ', ')" -ForegroundColor Cyan
            
            # Keep monitoring
            Write-Host "System is running with Bootstrap Orchestrator management" -ForegroundColor Green
            Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
            
            try {
                while ($true) { Start-Sleep -Seconds 30 }
            } catch {
                Write-Host "System stopped: $($_.Exception.Message)" -ForegroundColor Yellow
            }
            
            exit 0
        } else {
            Write-Warning "Manifest-based startup failed: $($result.Message)"
            Write-Host "Falling back to legacy mode..." -ForegroundColor Yellow
            $UseLegacyMode = $true
        }
    } catch {
        Write-Error "Manifest-based startup error: $($_.Exception.Message)"
        Write-Host "Falling back to legacy mode..." -ForegroundColor Yellow
        $UseLegacyMode = $true
    }
}

# LEGACY MODE STARTUP
Write-Host "=== LEGACY MODE STARTUP ===" -ForegroundColor Yellow
if ($compatibilityAvailable) {
    Show-DeprecationWarning -FunctionName "Legacy System Startup" -Replacement "Manifest-based Bootstrap Orchestrator"
}

# Choose monitoring approach
$useWindow = Read-Host "Run monitoring in separate window (recommended) or background job? (W/J) [Default: W]"

if ($useWindow -ne "J") {
    # OPTION 1: Run in separate window (RECOMMENDED)
    Write-Host "  Starting monitoring in separate window..." -ForegroundColor Cyan
    if (Test-Path ".\Start-SystemStatusMonitoring-Window.ps1") {
        & .\Start-SystemStatusMonitoring-Window.ps1 -CheckIntervalSeconds 30
    } elseif (Test-Path ".\Start-SystemStatusMonitoring.ps1") {
        & .\Start-SystemStatusMonitoring.ps1 -CheckIntervalSeconds 30
    } else {
        Write-Host "  Warning: No SystemStatus monitoring script found" -ForegroundColor Yellow
    }
    
    $systemStatusJob = $null  # Set to null since we're using window
    Start-Sleep -Seconds 3
    
    # Check if window started
    if (Test-Path ".\monitoring_window_info.json") {
        $windowInfo = Get-Content ".\monitoring_window_info.json" | ConvertFrom-Json
        Write-Host "  Monitoring window started: PID $($windowInfo.ProcessId)" -ForegroundColor Green
    }
} else {
    # OPTION 2: Run as background job (original approach)
    Write-Host "  Starting monitoring as background job..." -ForegroundColor Yellow
    
    $systemStatusJob = $null
    
    # Clean up any existing jobs
    Get-Job -Name "SystemStatusMonitoring" -ErrorAction SilentlyContinue | Remove-Job -Force
    
    # Start the monitoring in a background job
    $systemStatusJob = Start-Job -Name "SystemStatusMonitoring" -ScriptBlock {
    Set-Location $WorkingDir
    
    # Run the working version directly in this job
    $ErrorActionPreference = "Continue"
    
    # Create log file
    $logTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $logFile = ".\SystemStatusMonitoring_Job_$logTimestamp.log"
    
    function Write-JobLog {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $logMessage = "[$timestamp] [$Level] $Message"
        Add-Content -Path $logFile -Value $logMessage
    }
    
    Write-JobLog "SystemStatusMonitoring Job Started"
    Write-JobLog "Working Directory: $WorkingDir"
    Write-JobLog "Process ID: $PID"
    
    try {
        # Set execution policy for this session to bypass restrictions
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
        Write-JobLog "Set ExecutionPolicy to Bypass for this job"
        
        # Load the module
        $modulePath = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1"
        Import-Module $modulePath -Force -Global
        Write-JobLog "Module loaded successfully"
        
        # Verify our critical functions are available
        if (Get-Command Test-AutonomousAgentStatus -ErrorAction SilentlyContinue) {
            Write-JobLog "Test-AutonomousAgentStatus function is available"
        } else {
            Write-JobLog "WARNING: Test-AutonomousAgentStatus function NOT available!" "WARN"
        }
        
        if (Get-Command Start-AutonomousAgentSafe -ErrorAction SilentlyContinue) {
            Write-JobLog "Start-AutonomousAgentSafe function is available"
        } else {
            Write-JobLog "WARNING: Start-AutonomousAgentSafe function NOT available!" "WARN"
        }
        
        # Initialize monitoring
        Initialize-SystemStatusMonitoring
        Write-JobLog "Monitoring initialized"
        
        # Register core subsystems
        Register-Subsystem -SubsystemName "Unity-Claude-Core" -ModulePath ".\Modules\Unity-Claude-Core" -HealthCheckLevel "Standard"
        Register-Subsystem -SubsystemName "Unity-Claude-SystemStatus" -ModulePath ".\Modules\Unity-Claude-SystemStatus" -HealthCheckLevel "Standard"
        Write-JobLog "Subsystems registered"
        
        # Start file watcher
        Start-SystemStatusFileWatcher
        Write-JobLog "File watcher started"
        
        # Create timer for heartbeats WITHOUT -Action
        $heartbeatTimer = New-Object System.Timers.Timer
        $heartbeatTimer.Interval = 60000  # 60 seconds
        $heartbeatTimer.AutoReset = $true
        
        # Register event to queue (not action)
        Register-ObjectEvent -InputObject $heartbeatTimer -EventName Elapsed -SourceIdentifier "JobHeartbeat"
        $heartbeatTimer.Start()
        Write-JobLog "Heartbeat timer started"
        
        # Update status to show we're running
        $status = Read-SystemStatus
        if ($status -and $status.Subsystems) {
            if (-not $status.Subsystems.ContainsKey("SystemStatusMonitoring")) {
                $status.Subsystems["SystemStatusMonitoring"] = @{}
            }
            $status.Subsystems["SystemStatusMonitoring"]["ProcessId"] = $PID
            $status.Subsystems["SystemStatusMonitoring"]["Status"] = "Running"
            $status.Subsystems["SystemStatusMonitoring"]["LastHeartbeat"] = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
            Write-SystemStatus -StatusData $status
        }
        
        # Main event loop
        $running = $true
        $eventCount = 0
        
        Write-JobLog "Entering main event loop"
        
        while ($running) {
            # Wait for events with timeout
            $event = Wait-Event -SourceIdentifier "JobHeartbeat" -Timeout 5
            
            if ($event) {
                $eventCount++
                Write-JobLog "Processing heartbeat event #$eventCount"
                
                try {
                    # Send heartbeats
                    Send-HeartbeatRequest -SubsystemName "SystemStatusMonitoring"
                    Send-HeartbeatRequest -SubsystemName "Unity-Claude-SystemStatus"
                    
                    # Always check AutonomousAgent status directly
                    Write-JobLog "============ AGENT CHECK START ============" "DEBUG"
                    Write-JobLog "Checking AutonomousAgent status at $(Get-Date -Format 'HH:mm:ss.fff')..." "DEBUG"
                    
                    try {
                        # Check if function exists
                        if (Get-Command Test-AutonomousAgentStatus -ErrorAction SilentlyContinue) {
                            Write-JobLog "Test-AutonomousAgentStatus function found" "DEBUG"
                        } else {
                            Write-JobLog "Test-AutonomousAgentStatus function NOT FOUND!" "ERROR"
                            Write-JobLog "Available functions: $(Get-Command -Module Unity-Claude-SystemStatus | Select-Object -ExpandProperty Name -First 10)" "ERROR"
                        }
                        
                        $agentStatus = Test-AutonomousAgentStatus
                        Write-JobLog "Agent status check returned: $agentStatus" "INFO"
                        
                        if (-not $agentStatus) {
                            Write-JobLog "AutonomousAgent is NOT running - will attempt restart" "WARN"
                            
                            # Check if restart function exists
                            if (Get-Command Start-AutonomousAgentSafe -ErrorAction SilentlyContinue) {
                                Write-JobLog "Start-AutonomousAgentSafe function found" "DEBUG"
                            } else {
                                Write-JobLog "Start-AutonomousAgentSafe function NOT FOUND!" "ERROR"
                            }
                            
                            Write-JobLog "Calling Start-AutonomousAgentSafe..." "INFO"
                            $restartResult = Start-AutonomousAgentSafe
                            Write-JobLog "Start-AutonomousAgentSafe returned: $restartResult" "INFO"
                            
                            if ($restartResult) {
                                Write-JobLog "AutonomousAgent RESTARTED SUCCESSFULLY" "INFO"
                            } else {
                                Write-JobLog "FAILED to restart AutonomousAgent" "ERROR"
                            }
                        } else {
                            Write-JobLog "AutonomousAgent is RUNNING normally" "DEBUG"
                        }
                    } catch {
                        Write-JobLog "EXCEPTION in agent check/restart: $_" "ERROR"
                        Write-JobLog "Exception type: $($_.Exception.GetType().FullName)" "ERROR"
                        Write-JobLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
                        Write-JobLog "Inner exception: $($_.Exception.InnerException)" "ERROR"
                    }
                    
                    Write-JobLog "============ AGENT CHECK END ============" "DEBUG"
                    
                    # Test all subsystems
                    $healthStatus = Test-AllSubsystemHeartbeats
                    if ($healthStatus -and $healthStatus.UnhealthySubsystems.Count -gt 0) {
                        Write-JobLog "Unhealthy subsystems: $($healthStatus.UnhealthySubsystems -join ', ')" "WARN"
                    }
                    
                    # Update our heartbeat
                    $status = Read-SystemStatus
                    if ($status -and $status.Subsystems -and $status.Subsystems.ContainsKey("SystemStatusMonitoring")) {
                        $status.Subsystems["SystemStatusMonitoring"]["LastHeartbeat"] = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
                        $status.Subsystems["SystemStatusMonitoring"]["Status"] = "Running"
                        Write-SystemStatus -StatusData $status
                    }
                    
                    Write-JobLog "Heartbeat processing complete"
                } catch {
                    Write-JobLog "Error processing heartbeat: $_" "ERROR"
                }
                
                # Remove event from queue
                Remove-Event -SourceIdentifier "JobHeartbeat" -ErrorAction SilentlyContinue
            }
            
            # Check for stop signal
            if (Test-Path ".\STOP_MONITORING.txt") {
                Write-JobLog "Stop signal detected - exiting"
                Remove-Item ".\STOP_MONITORING.txt" -Force
                $running = $false
            }
        }
        
        Write-JobLog "Exiting main loop"
    } catch {
        Write-JobLog "Critical error: $_" "ERROR"
        Write-JobLog "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    } finally {
        # Cleanup
        if ($heartbeatTimer) {
            $heartbeatTimer.Stop()
            $heartbeatTimer.Dispose()
        }
        Unregister-Event -SourceIdentifier "JobHeartbeat" -ErrorAction SilentlyContinue
        try { Stop-SystemStatusMonitoring } catch {}
        Write-JobLog "Cleanup complete"
    }
} -ArgumentList $PWD.Path

    if ($systemStatusJob) {
        Write-Host "  SystemStatusMonitoring job started: ID $($systemStatusJob.Id)" -ForegroundColor Green
        
        # Give it time to initialize
        Write-Host "  Waiting for initialization..." -ForegroundColor Gray
        Start-Sleep -Seconds 3
        
        # Check if it's still running
        $systemStatusJob = Get-Job -Id $systemStatusJob.Id
        if ($systemStatusJob.State -eq "Running") {
            Write-Host "  SystemStatusMonitoring is running successfully!" -ForegroundColor Green
        } else {
            Write-Host "  WARNING: SystemStatusMonitoring job stopped with state: $($systemStatusJob.State)" -ForegroundColor Red
            $jobOutput = Receive-Job -Job $systemStatusJob
            if ($jobOutput) {
                Write-Host "  Job output: $jobOutput" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "  Failed to start SystemStatusMonitoring job" -ForegroundColor Red
    }
}  # This closes the else block from line 61

# Step 3: Load SystemStatus module in main session for communication
Write-Host ""
Write-Host "Step 3: Loading SystemStatus module in main session..." -ForegroundColor Yellow

try {
    $modulePath = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force -Global
        Write-Host "  SystemStatus module loaded" -ForegroundColor Green
        
        # Verify communication
        Start-Sleep -Seconds 1
        try {
            $status = Read-SystemStatus
            if ($status) {
                Write-Host "  Communication with SystemStatus confirmed" -ForegroundColor Green
                Write-Host "  Subsystems registered: $($status.subsystems.Count)" -ForegroundColor Gray
            }
        } catch {
            Write-Host "  Warning: Cannot read system status yet" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  SystemStatus module not found" -ForegroundColor Red
    }
} catch {
    Write-Host "  Error loading SystemStatus module: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 4: Start AutonomousAgent
if (-not $SkipAutonomousAgent) {
    Write-Host ""
    Write-Host "Step 4: Starting AutonomousAgent..." -ForegroundColor Yellow
    
    Start-Sleep -Seconds 2  # Give SystemStatus time to stabilize
    
    try {
        # Check if already running via SystemStatus registration
        $existingAgent = $null
        try {
            $systemStatus = Get-SystemStatus -ErrorAction SilentlyContinue
            if ($systemStatus -and $systemStatus.subsystems -and $systemStatus.subsystems.AutonomousAgent) {
                $agentInfo = $systemStatus.subsystems.AutonomousAgent
                # Check if the process is still alive (handle both naming conventions)
                $agentPID = if ($agentInfo.ProcessId) { $agentInfo.ProcessId } else { $agentInfo.process_id }
                $agentProcess = Get-Process -Id $agentPID -ErrorAction SilentlyContinue
                if ($agentProcess) {
                    $existingAgent = $agentInfo
                    Write-Host "  AutonomousAgent already registered and running (PID: $agentPID)" -ForegroundColor Green
                } else {
                    Write-Host "  AutonomousAgent registered but process dead - will restart" -ForegroundColor Yellow
                }
            }
        } catch {
            Write-Host "  Could not check SystemStatus for existing agent: $_" -ForegroundColor Yellow
        }
        
        if ($existingAgent -and $agentProcess) {
            Write-Host "  Skipping AutonomousAgent startup - already active" -ForegroundColor Green
        } else {
            # Start monitoring in new window
            $monitoringScript = ".\Start-AutonomousMonitoring-Fixed.ps1"
            if (Test-Path $monitoringScript) {
                Write-Host "  Starting autonomous monitoring in new window..." -ForegroundColor Gray
                
                $agentArgs = @{
                    FilePath = "pwsh.exe"
                    ArgumentList = @(
                        "-NoExit",
                        "-ExecutionPolicy", "Bypass",
                        "-File", $monitoringScript
                    )
                    WindowStyle = "Normal"
                    PassThru = $true
                }
                
                $agentProcess = Start-Process @agentArgs
                
                if ($agentProcess -and $agentProcess.Id) {
                    Write-Host "  AutonomousAgent monitoring started: PID $($agentProcess.Id)" -ForegroundColor Green
                    
                    # Update SystemStatus with the PID
                    try {
                        Start-Sleep -Seconds 2
                        $statusData = Read-SystemStatus
                        if ($statusData -and $statusData.subsystems) {
                            if (-not $statusData.subsystems.ContainsKey("Unity-Claude-AutonomousAgent")) {
                                $statusData.subsystems["Unity-Claude-AutonomousAgent"] = @{}
                            }
                            $statusData.subsystems["Unity-Claude-AutonomousAgent"]["ProcessId"] = $agentProcess.Id
                            $statusData.subsystems["Unity-Claude-AutonomousAgent"]["Status"] = "Running"
                            $statusData.subsystems["Unity-Claude-AutonomousAgent"]["LastHeartbeat"] = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
                            Write-SystemStatus -StatusData $statusData
                            Write-Host "  Registered AutonomousAgent PID with SystemStatus" -ForegroundColor Green
                        }
                    } catch {
                        Write-Host "  Warning: Could not update SystemStatus: $($_.Exception.Message)" -ForegroundColor Yellow
                    }
                } else {
                    Write-Host "  Failed to start AutonomousAgent monitoring" -ForegroundColor Red
                }
            } else {
                Write-Host "  AutonomousAgent monitoring script not found" -ForegroundColor Yellow
            }
        }
    } catch {
        Write-Host "  Error starting AutonomousAgent: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host ""
    Write-Host "Step 4: Skipping AutonomousAgent (as requested)" -ForegroundColor Gray
}

# Step 5: Final status report
Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "System Startup Complete!" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Display running components
Write-Host "Running Components:" -ForegroundColor Yellow

if ($claudePID) {
    Write-Host "  [+] Claude Code CLI: PID $claudePID" -ForegroundColor Green
} else {
    Write-Host "  [-] Claude Code CLI: Not found" -ForegroundColor Yellow
}

# Check monitoring status based on method used
if ($systemStatusJob -and $systemStatusJob.State -eq "Running") {
    Write-Host "  [+] SystemStatusMonitoring: Job ID $($systemStatusJob.Id) (Running in background)" -ForegroundColor Green
    Write-Host "      View output: Receive-Job -Id $($systemStatusJob.Id) -Keep" -ForegroundColor Gray
    Write-Host "      View logs: Get-Content .\SystemStatusMonitoring_Job_*.log -Tail 20" -ForegroundColor Gray
} elseif (Test-Path ".\monitoring_window_info.json") {
    $windowInfo = Get-Content ".\monitoring_window_info.json" | ConvertFrom-Json
    $monitorProcess = Get-Process -Id $windowInfo.ProcessId -ErrorAction SilentlyContinue
    if ($monitorProcess) {
        Write-Host "  [+] SystemStatusMonitoring: PID $($windowInfo.ProcessId) (Running in window)" -ForegroundColor Green
        Write-Host "      View window for real-time status" -ForegroundColor Gray
        Write-Host "      View restart log: Get-Content .\agent_restart_log.txt -Tail 10" -ForegroundColor Gray
    } else {
        Write-Host "  [-] SystemStatusMonitoring: Window closed" -ForegroundColor Yellow
    }
} else {
    Write-Host "  [-] SystemStatusMonitoring: Not running" -ForegroundColor Red
}

if (-not $SkipAutonomousAgent) {
    $agent = Get-WmiObject Win32_Process | Where-Object {
        $_.CommandLine -like "*AutonomousMonitoring.ps1*" -or
        $_.CommandLine -like "*AutonomousAgent*.ps1*"
    } | Select-Object -First 1
    if ($agent) {
        Write-Host "  [+] AutonomousAgent: PID $($agent.ProcessId) (Running in separate window)" -ForegroundColor Green
    } else {
        Write-Host "  [-] AutonomousAgent: Not running" -ForegroundColor Yellow
    }
}

# Show system status summary
Write-Host ""
Write-Host "System Status Summary:" -ForegroundColor Yellow
try {
    $status = Read-SystemStatus
    if ($status -and $status.subsystems) {
        $runningCount = 0
        $totalCount = $status.subsystems.Count
        
        foreach ($subsystem in $status.subsystems.Keys) {
            $sub = $status.subsystems[$subsystem]
            if ($sub.Status -eq "Running") {
                $runningCount++
            }
        }
        
        Write-Host "  Total Subsystems: $totalCount" -ForegroundColor Gray
        Write-Host "  Running: $runningCount" -ForegroundColor Green
        Write-Host "  Not Running: $($totalCount - $runningCount)" -ForegroundColor Yellow
        
        if ($status.Alerts -and $status.Alerts.Count -gt 0) {
            Write-Host "  Active Alerts: $($status.Alerts.Count)" -ForegroundColor Red
        } else {
            Write-Host "  Active Alerts: 0" -ForegroundColor Green
        }
    } else {
        Write-Host "  No status data available yet" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Could not read system status: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "All systems launched successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "SystemStatusMonitoring is running in the background and will:" -ForegroundColor Cyan
Write-Host "  - Send heartbeats every 60 seconds" -ForegroundColor Gray
Write-Host "  - Monitor all registered subsystems" -ForegroundColor Gray
Write-Host "  - Restart failed subsystems automatically" -ForegroundColor Gray
Write-Host ""
Write-Host "To stop all systems:" -ForegroundColor Yellow
if ($systemStatusJob) {
    Write-Host "  1. Create file: New-Item .\STOP_MONITORING.txt" -ForegroundColor Gray
    Write-Host "  2. Stop job: Stop-Job -Name SystemStatusMonitoring" -ForegroundColor Gray
    Write-Host "  3. Close AutonomousAgent window manually" -ForegroundColor Gray
} else {
    Write-Host "  1. Create file: New-Item .\STOP_MONITORING_WINDOW.txt" -ForegroundColor Gray
    Write-Host "  2. Or close the monitoring window" -ForegroundColor Gray
    Write-Host "  3. Close AutonomousAgent window manually" -ForegroundColor Gray
}
Write-Host ""
Write-Host "To view monitoring logs:" -ForegroundColor Yellow
Write-Host "  Get-Content .\SystemStatusMonitoring_Job_*.log -Tail 20" -ForegroundColor Gray
Write-Host ""
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUZAW3Eq2EtMjpwgNbvQYybcV6
# 016gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUj+Ixtrk0fUBgY1GJ9LJgIsn4ZD0wDQYJKoZIhvcNAQEBBQAEggEAUqjP
# bOj+j0Su+UfMvjqH446CbPt+nLae58Jl0r+oXfnSeujjjJto+oKU5vkPyRBdcxMQ
# aZHQPHhFOu1O5UEqvrQjDvKomUVOTmgwy42Z5xkOjLliOPerYo1G51SuCaG65+V8
# CHBLOg49i5gr9nooHpUF0P4Jb1A2RwpybTHwKvFvG9UJQTpLkDobR2B+gtn2n33J
# qydyZMpxzYFoSvRCkXVSufjwjGmmgLRNWvv/nzZMGXgANkMUtaghKj1REg7s7nZS
# A8wmlCpG5yCr5P4rD6+9AKh824tLGiP5z8Tn/hRf6Z3L2r9dggm2Z1UGaspEaP4E
# 3r258Fo6KGMGPD0oqw==
# SIG # End signature block



