# Start-SystemStatusMonitoring-Persistent.ps1
# A persistent version that uses a different approach to stay alive
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
Write-MonitorLog "Unity-Claude System Status Monitoring (PERSISTENT)" "INFO"
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
                                       -HealthCheckLevel "Critical"
        Write-MonitorLog "Registered: $subsystem" "INFO"
    } catch {
        Write-MonitorLog "Failed to register $subsystem`: $($_.Exception.Message)" "WARN"
    }
}

Write-MonitorLog "" "INFO"

# Step 4: Start optional components
Write-MonitorLog "Step 4: Starting optional components..." "INFO"

# Start file watcher
Write-MonitorLog "Starting file watcher..." "DEBUG"
try {
    Start-SystemStatusFileWatcher
    Write-MonitorLog "File watcher started for system status file" "INFO"
} catch {
    Write-MonitorLog "Failed to start file watcher: $($_.Exception.Message)" "WARN"
}

# Named pipes are optional
if ($false) {  # Disabled for now
    Write-MonitorLog "Starting named pipe server..." "DEBUG"
    try {
        Initialize-NamedPipeServer
        Write-MonitorLog "Named pipe server started" "INFO"
    } catch {
        Write-MonitorLog "Failed to start named pipe server: $($_.Exception.Message)" "WARN"
    }
} else {
    Write-MonitorLog "Named pipes disabled" "DEBUG"
}

Write-MonitorLog "" "INFO"

# Step 5: Create manual heartbeat loop instead of timer
Write-MonitorLog "Step 5: Starting heartbeat monitoring..." "INFO"

# Initialize heartbeat tracking
$script:LastHeartbeat = Get-Date
$script:HeartbeatInterval = 60  # seconds
$script:CheckInterval = 5        # seconds

Write-MonitorLog "Heartbeat monitoring configured (${HeartbeatInterval}s interval)" "INFO"

Write-MonitorLog "" "INFO"

# Step 6: Show current status
Write-MonitorLog "Step 6: Current System Status:" "INFO"

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
Write-MonitorLog "Press Ctrl+C to stop monitoring..." "INFO"
Write-MonitorLog "" "INFO"

# Main monitoring loop - using a more robust approach
Write-MonitorLog "Starting persistent monitoring loop" "INFO"

$script:Running = $true
$script:LoopCount = 0

# Register cleanup handler
Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Write-MonitorLog "Shutting down monitoring system..." "INFO"
    try {
        Stop-SystemStatusMonitoring
    } catch {}
    $script:Running = $false
} | Out-Null

# Main loop with explicit heartbeat management
while ($script:Running) {
    $script:LoopCount++
    
    # Check if it's time for a heartbeat
    $now = Get-Date
    $timeSinceLastHeartbeat = ($now - $script:LastHeartbeat).TotalSeconds
    
    if ($timeSinceLastHeartbeat -ge $script:HeartbeatInterval) {
        Write-MonitorLog "Sending heartbeat (loop #$script:LoopCount)" "DEBUG"
        
        try {
            # Send heartbeats
            Send-HeartbeatRequest -SubsystemName "SystemStatusMonitoring"
            Send-HeartbeatRequest -SubsystemName "Unity-Claude-SystemStatus"
            
            # Test all subsystem heartbeats
            $healthStatus = Test-AllSubsystemHeartbeats
            if ($healthStatus -and $healthStatus.UnhealthySubsystems.Count -gt 0) {
                Write-MonitorLog "Unhealthy subsystems detected: $($healthStatus.UnhealthySubsystems -join ', ')" "WARN"
                
                # Attempt recovery for critical subsystems
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
            
            # Update our own heartbeat in system status
            try {
                $status = Read-SystemStatus
                if ($status -and $status.Subsystems) {
                    if ($status.Subsystems.ContainsKey("SystemStatusMonitoring")) {
                        $status.Subsystems["SystemStatusMonitoring"]["LastHeartbeat"] = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
                        $status.Subsystems["SystemStatusMonitoring"]["Status"] = "Running"
                        $status.Subsystems["SystemStatusMonitoring"]["ProcessId"] = $PID
                        Write-SystemStatus -StatusData $status
                    }
                }
            } catch {
                Write-MonitorLog "Could not update status: $_" "DEBUG"
            }
            
            $script:LastHeartbeat = $now
        } catch {
            Write-MonitorLog "Error during heartbeat: $($_.Exception.Message)" "ERROR"
        }
    }
    
    # Check for stop signal
    if (Test-Path ".\STOP_MONITORING.txt") {
        Write-MonitorLog "Stop signal detected - exiting" "INFO"
        Remove-Item ".\STOP_MONITORING.txt" -Force
        $script:Running = $false
        break
    }
    
    # Sleep for check interval
    Start-Sleep -Seconds $script:CheckInterval
    
    # Every 12 loops (1 minute with 5-second checks), write a status update
    if ($script:LoopCount % 12 -eq 0) {
        Write-MonitorLog "Still running (loop #$script:LoopCount, uptime: $([int]($now - $script:StartTime).TotalMinutes) minutes)" "DEBUG"
    }
}

Write-MonitorLog "Monitoring loop ended" "INFO"
Write-MonitorLog "Cleaning up..." "INFO"

try {
    Stop-SystemStatusMonitoring
} catch {
    Write-MonitorLog "Error during cleanup: $_" "WARN"
}

Write-MonitorLog "SystemStatusMonitoring stopped" "INFO"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUH057c6j/6ZsFQ+aKwkuM9975
# FtKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU2stIXGh83P5M+NzAS4y8Ch1VHiQwDQYJKoZIhvcNAQEBBQAEggEATF7D
# WfY/WVr0Sha/ysQbobbQgn32mAiOSGiCZnO88AVmaBtOj/SsD8OSLZYMjHFi+lZq
# ylrCCbB9YccfynOSm6FO48VVEQQ1ELoQsk9NKC3oK6Iz1w/9N6pvycrr/bfZ2bAS
# rAEn4fpUHvXU8qQZ4b21GkV88XnLzdz9T05cmHMQkHJSiu/9GjqSrOLeCPlGeDGY
# NdULdgM87j2PKLoWPBMvFqwERWv3FMfIbWbuj1VNIuXgurIz0hoqxQ85Mce6wVhT
# qdT5hyHWTNQE8r9cpbUDqhxYopbVjGI0EI/VqpvwsgIH75/GweYpXRjhljnnrXl/
# q+ivx5ANvm/khbN/mg==
# SIG # End signature block
