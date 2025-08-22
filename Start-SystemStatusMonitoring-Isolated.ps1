# Start-SystemStatusMonitoring-Isolated.ps1
# Isolated version that prevents file watcher conflicts with other processes
# Date: 2025-08-20

param(
    [switch]$Debug = $false
)

$ErrorActionPreference = "Continue"

# Create log file with timestamp
$logTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = ".\SystemStatusMonitoring_$logTimestamp.log"

function Write-MonitorLog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Write to console with color
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "DEBUG" { "Gray" }
        default { "White" }
    }
    Write-Host $logMessage -ForegroundColor $color
    
    # Write to log file
    Add-Content -Path $logFile -Value $logMessage
}

Write-MonitorLog "=================================================" "INFO"
Write-MonitorLog "Unity-Claude System Status Monitoring (ISOLATED)" "INFO"
Write-MonitorLog "Starting at: $(Get-Date)" "INFO"
Write-MonitorLog "PID: $PID" "INFO"
Write-MonitorLog "Log file: $logFile" "INFO"
Write-MonitorLog "=================================================" "INFO"
Write-MonitorLog "" "INFO"

# Store our PID for other scripts to find
Write-MonitorLog "SystemStatusMonitoring Process ID: $PID" "INFO"

# Change to the Unity-Claude-Automation directory if needed
$currentDir = Get-Location
if ($currentDir.Path -notlike "*Unity-Claude-Automation*") {
    Write-MonitorLog "Changing directory to Unity-Claude-Automation" "DEBUG"
    Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"
}

# Step 1: Load the SystemStatus module
Write-MonitorLog "Step 1: Loading Unity-Claude-SystemStatus module..." "INFO"

$modulePath = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1"
if (-not (Test-Path $modulePath)) {
    $modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1"
}

Write-MonitorLog "Importing module from: $modulePath" "DEBUG"

try {
    Import-Module $modulePath -Force -Global
    $moduleInfo = Get-Module Unity-Claude-SystemStatus
    
    if ($moduleInfo) {
        Write-MonitorLog "Module loaded successfully" "INFO"
        Write-MonitorLog "Version: $($moduleInfo.Version)" "INFO"
        Write-MonitorLog "Functions available: $($moduleInfo.ExportedFunctions.Count)" "INFO"
    } else {
        Write-MonitorLog "Module loaded but info not available" "WARN"
    }
} catch {
    Write-MonitorLog "Failed to load module: $($_.Exception.Message)" "ERROR"
    Write-MonitorLog "Stack trace: $($_.ScriptStackTrace)" "DEBUG"
    exit 1
}

Write-MonitorLog "" "INFO"

# Step 2: Initialize monitoring
Write-MonitorLog "Step 2: Initializing System Status Monitoring..." "INFO"
Write-MonitorLog "Calling Initialize-SystemStatusMonitoring..." "DEBUG"

try {
    $result = Initialize-SystemStatusMonitoring
    Write-MonitorLog "Monitoring system initialized" "INFO"
} catch {
    Write-MonitorLog "Failed to initialize: $($_.Exception.Message)" "ERROR"
    Write-MonitorLog "Stack trace: $($_.ScriptStackTrace)" "DEBUG"
}

Write-MonitorLog "" "INFO"

# Step 3: Register core subsystems
Write-MonitorLog "Step 3: Registering subsystems..." "INFO"

$subsystemsToRegister = @(
    "Unity-Claude-Core",
    "Unity-Claude-SystemStatus"
)

foreach ($subsystem in $subsystemsToRegister) {
    Write-MonitorLog "Registering subsystem: $subsystem" "DEBUG"
    try {
        $registered = Register-Subsystem -SubsystemName $subsystem `
                                       -ModulePath ".\Modules\$subsystem" `
                                       -HealthCheckLevel "Standard"
        Write-MonitorLog "Registered: $subsystem" "INFO"
    } catch {
        Write-MonitorLog "Failed to register $subsystem`: $($_.Exception.Message)" "WARN"
    }
}

Write-MonitorLog "" "INFO"

# Step 4: SKIP FILE WATCHER TO AVOID CONFLICTS
Write-MonitorLog "Step 4: Skipping file watcher (conflict prevention)..." "INFO"
Write-MonitorLog "File watcher disabled to prevent conflicts with other processes" "WARN"

Write-MonitorLog "" "INFO"

# Step 5: Set up heartbeat timer WITHOUT file watcher
Write-MonitorLog "Step 5: Starting heartbeat monitoring..." "INFO"

# Create a timer for heartbeats
$global:heartbeatTimer = New-Object System.Timers.Timer
$global:heartbeatTimer.Interval = 30000  # 30 seconds (more frequent for monitoring)
$global:heartbeatTimer.AutoReset = $true

# Register the event WITHOUT -Action so it goes to the event queue
Register-ObjectEvent -InputObject $global:heartbeatTimer -EventName Elapsed -SourceIdentifier "SystemStatusHeartbeat"

# Start the timer
$global:heartbeatTimer.Start()

Write-MonitorLog "Heartbeat timer created and started (30s interval)" "INFO"
Write-MonitorLog "Event registered with SourceIdentifier: SystemStatusHeartbeat" "INFO"

Write-MonitorLog "" "INFO"

# Step 6: Detect Claude Code CLI immediately on startup
Write-MonitorLog "Step 6: Detecting Claude Code CLI..." "INFO"

try {
    # Load the Claude Code PID detection script
    . ".\Update-ClaudeCodePID.ps1"
    $claudePID = Update-ClaudeCodePID
    if ($claudePID) {
        Write-MonitorLog "Claude Code CLI detected on startup: PID $claudePID" "INFO"
    } else {
        Write-MonitorLog "Claude Code CLI not detected on startup (will check periodically)" "WARN"
    }
} catch {
    Write-MonitorLog "Error detecting Claude Code CLI on startup: $_" "WARN"
}

Write-MonitorLog "" "INFO"

# Step 7: Show current status
Write-MonitorLog "Step 7: Current System Status:" "INFO"

try {
    $status = Read-SystemStatus
    if ($status) {
        Write-MonitorLog "System Status File: system_status.json" "INFO"
        Write-MonitorLog "Last Update: $($status.SystemInfo.LastUpdate)" "INFO"
        Write-MonitorLog "Registered Subsystems: $($status.Subsystems.Count)" "INFO"
        Write-MonitorLog "Active Alerts: $($status.Alerts.Count)" "INFO"
        
        # Update with our PID
        if ($status.Subsystems -and $status.Subsystems.ContainsKey("SystemStatusMonitoring")) {
            $status.Subsystems["SystemStatusMonitoring"]["ProcessId"] = $PID
            $status.Subsystems["SystemStatusMonitoring"]["Status"] = "Running"
            $status.Subsystems["SystemStatusMonitoring"]["LastHeartbeat"] = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
            Write-SystemStatus -StatusData $status
            Write-MonitorLog "Updated system status with our PID: $PID" "INFO"
        }
    }
} catch {
    Write-MonitorLog "Could not read initial status: $($_.Exception.Message)" "WARN"
}

Write-MonitorLog "" "INFO"

# Display success message
Write-MonitorLog "=================================================" "INFO"
Write-MonitorLog "System Status Monitoring is now running!" "INFO"
Write-MonitorLog "=================================================" "INFO"
Write-MonitorLog "" "INFO"
Write-MonitorLog "Log file: $logFile" "INFO"
Write-MonitorLog "Waiting for timer events (no file watcher)..." "INFO"
Write-MonitorLog "" "INFO"

# Main event processing loop - simpler without file watcher
Write-MonitorLog "Entering event processing loop" "INFO"

$script:Running = $true
$script:EventCount = 0
$script:LastStatusCheck = Get-Date

try {
    while ($script:Running) {
        # Wait for timer event with a timeout
        $event = Wait-Event -SourceIdentifier "SystemStatusHeartbeat" -Timeout 10
        
        if ($event) {
            $script:EventCount++
            Write-MonitorLog "Processing heartbeat event #$script:EventCount" "DEBUG"
            
            # Remove the event from the queue FIRST
            Remove-Event -SourceIdentifier "SystemStatusHeartbeat" -ErrorAction SilentlyContinue
            
            # Process the heartbeat
            try {
                # Send heartbeats (fixed parameter name: TargetSubsystem not SubsystemName)
                Send-HeartbeatRequest -TargetSubsystem "SystemStatusMonitoring"
                Send-HeartbeatRequest -TargetSubsystem "Unity-Claude-SystemStatus"
                
                # Test all subsystem heartbeats
                $healthStatus = Test-AllSubsystemHeartbeats
                if ($healthStatus -and $healthStatus.UnhealthySubsystems.Count -gt 0) {
                    Write-MonitorLog "Unhealthy subsystems detected: $($healthStatus.UnhealthySubsystems -join ', ')" "WARN"
                    
                    # Check AutonomousAgent specifically
                    foreach ($unhealthy in $healthStatus.UnhealthySubsystems) {
                        if ($unhealthy -eq "Unity-Claude-AutonomousAgent") {
                            Write-MonitorLog "Checking AutonomousAgent status..." "INFO"
                            try {
                                $agentStatus = Test-AutonomousAgentStatus
                                if (-not $agentStatus) {
                                    Write-MonitorLog "AutonomousAgent is down, attempting restart..." "WARN"
                                    Start-AutonomousAgentSafe
                                }
                            } catch {
                                Write-MonitorLog "Error checking AutonomousAgent: $_" "ERROR"
                            }
                        }
                    }
                }
                
                # Update our own heartbeat
                $status = Read-SystemStatus
                if ($status -and $status.Subsystems -and $status.Subsystems.ContainsKey("SystemStatusMonitoring")) {
                    $status.Subsystems["SystemStatusMonitoring"]["LastHeartbeat"] = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
                    $status.Subsystems["SystemStatusMonitoring"]["Status"] = "Running"
                    $status.Subsystems["SystemStatusMonitoring"]["ProcessId"] = $PID
                    Write-SystemStatus -StatusData $status
                }
                
                Write-MonitorLog "Heartbeat processing complete" "DEBUG"
            } catch {
                Write-MonitorLog "Error processing heartbeat: $($_.Exception.Message)" "ERROR"
            }
        } else {
            # No event received in timeout period - do periodic status check
            $now = Get-Date
            $timeSinceLastCheck = ($now - $script:LastStatusCheck).TotalSeconds
            
            if ($timeSinceLastCheck -ge 30) {
                Write-MonitorLog "Performing periodic status check..." "DEBUG"
                
                try {
                    # Update Claude Code CLI PID detection every 30 seconds
                    Write-MonitorLog "Checking for Claude Code CLI process..." "DEBUG"
                    . ".\Update-ClaudeCodePID.ps1"
                    $claudePID = Update-ClaudeCodePID
                    if ($claudePID) {
                        Write-MonitorLog "Claude Code CLI detected: PID $claudePID" "INFO"
                    }
                    
                    # Update our status to show we're still alive
                    $status = Read-SystemStatus
                    if ($status -and $status.Subsystems -and $status.Subsystems.ContainsKey("SystemStatusMonitoring")) {
                        $status.Subsystems["SystemStatusMonitoring"]["LastHeartbeat"] = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
                        $status.Subsystems["SystemStatusMonitoring"]["Status"] = "Running"
                        $status.Subsystems["SystemStatusMonitoring"]["ProcessId"] = $PID
                        Write-SystemStatus -StatusData $status
                        Write-MonitorLog "Updated heartbeat timestamp" "DEBUG"
                    }
                } catch {
                    Write-MonitorLog "Error updating status: $_" "DEBUG"
                }
                
                $script:LastStatusCheck = $now
            }
        }
        
        # Check for stop signal
        if (Test-Path ".\STOP_MONITORING.txt") {
            Write-MonitorLog "Stop signal detected - exiting" "INFO"
            Remove-Item ".\STOP_MONITORING.txt" -Force
            $script:Running = $false
        }
    }
} catch {
    Write-MonitorLog "Error in event loop: $($_.Exception.Message)" "ERROR"
    Write-MonitorLog "Stack trace: $($_.ScriptStackTrace)" "DEBUG"
} finally {
    # Cleanup
    Write-MonitorLog "Cleaning up..." "INFO"
    
    if ($global:heartbeatTimer) {
        $global:heartbeatTimer.Stop()
        $global:heartbeatTimer.Dispose()
        Write-MonitorLog "Timer stopped and disposed" "INFO"
    }
    
    Unregister-Event -SourceIdentifier "SystemStatusHeartbeat" -ErrorAction SilentlyContinue
    Write-MonitorLog "Event unregistered" "INFO"
    
    # Don't call Stop-SystemStatusFileWatcher since we didn't start it
    
    try {
        Stop-SystemStatusMonitoring
    } catch {
        Write-MonitorLog "Error during cleanup: $_" "WARN"
    }
    
    Write-MonitorLog "SystemStatusMonitoring stopped" "INFO"
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUO/FXFrpH3eGIn++ZYXWoYARe
# l/+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUyfX+i6fRHFD2YISx4Iuu6T1YxSkwDQYJKoZIhvcNAQEBBQAEggEAoOdS
# 98KycPZROm1Qz/FKSxqEQs586hmrDP1J5vCO5D5pogJ50ec8Cs7+a7KU/bkDUFsw
# OGpzC3lOQpgme23NxZ8WTOH/K+vyz/3QXy+LWCI3oOEzbTA1CHiM3qzoqM+LVOFk
# c1X4No5RmAOVAGajlY8NZnkZZy0BPu3KhezTLPqH06j7wbGHPPRaLedqRCa7sFUq
# Lf91KMEwdP0AhEGxNRovXozBb21xsQiBtBWj3pKK2jIrpuSirqcxmTZJDXvy6qaD
# jK15QbSFBk6xc+4C1WObDnLjQEloVnMgghetdEBnR4n5klZucdOwpdnktrz2dcb+
# fIABVyX9gmVR5ENQUg==
# SIG # End signature block
