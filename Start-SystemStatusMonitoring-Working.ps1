# Start-SystemStatusMonitoring-Working.ps1
# Working version that properly stays alive using correct event handling
# Based on research: Don't use -Action with Wait-Event
# Date: 2025-08-20


# PowerShell 7 Self-Elevation

param(
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

# Create log file with timestamp
$logTimestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = ".\SystemStatusMonitoring_$logTimestamp.log"

function Write-MonitorLog {
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
Write-MonitorLog "Unity-Claude System Status Monitoring (WORKING)" "INFO"
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

Write-MonitorLog "" "INFO"

# Step 5: Set up heartbeat timer WITHOUT -Action parameter (critical!)
Write-MonitorLog "Step 5: Starting heartbeat monitoring..." "INFO"

# Create a timer for heartbeats
$global:heartbeatTimer = New-Object System.Timers.Timer
$global:heartbeatTimer.Interval = 60000  # 60 seconds
$global:heartbeatTimer.AutoReset = $true

# Register the event WITHOUT -Action so it goes to the event queue
Register-ObjectEvent -InputObject $global:heartbeatTimer -EventName Elapsed -SourceIdentifier "SystemStatusHeartbeat"

# Start the timer
$global:heartbeatTimer.Start()

Write-MonitorLog "Heartbeat timer created and started (60s interval)" "INFO"
Write-MonitorLog "Event registered with SourceIdentifier: SystemStatusHeartbeat" "INFO"

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
Write-MonitorLog "Waiting for timer events..." "INFO"
Write-MonitorLog "" "INFO"

# Main event processing loop
Write-MonitorLog "Entering event processing loop" "INFO"

$script:Running = $true
$script:EventCount = 0

try {
    while ($script:Running) {
        # Wait for timer event with a timeout to check for stop signal
        $event = Wait-Event -SourceIdentifier "SystemStatusHeartbeat" -Timeout 5
        
        if ($event) {
            $script:EventCount++
            Write-MonitorLog "Processing heartbeat event #$script:EventCount" "DEBUG"
            
            # Process the heartbeat
            try {
                # Send heartbeats
                Send-HeartbeatRequest -SubsystemName "SystemStatusMonitoring"
                Send-HeartbeatRequest -SubsystemName "Unity-Claude-SystemStatus"
                
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
                    Write-SystemStatus -StatusData $status
                }
                
                Write-MonitorLog "Heartbeat processing complete" "DEBUG"
            } catch {
                Write-MonitorLog "Error processing heartbeat: $($_.Exception.Message)" "ERROR"
            }
            
            # Remove the event from the queue
            Remove-Event -SourceIdentifier "SystemStatusHeartbeat" -ErrorAction SilentlyContinue
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
    
    try {
        Stop-SystemStatusMonitoring
    } catch {
        Write-MonitorLog "Error during cleanup: $_" "WARN"
    }
    
    Write-MonitorLog "SystemStatusMonitoring stopped" "INFO"
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAqN/k9EL8CJ7T6
# b5yEGUjqepjx996A0riwSVQMnwpkD6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIIIRej6KuHpMPk0HS1Jf8z/O
# ne/bAETvDvr2aujiedxQMA0GCSqGSIb3DQEBAQUABIIBAHcBF0qf8TP0/HT17PBc
# JspMMdyF1VjDosEkRnMCQ9BfDf4IZh9U9OoEV7es+MDL8nvdRQ/k4ItBp3d8vRsC
# kgBDN0bQt1KioOohz2XkG24InQQlQTAXHP4d6lGW02oAjp4LmU3PcS5igyHpU5qD
# n1rPc04iL8YNwf6F/yYDzHaGLShspE2Tal50/l5zMGQKOELtR9tSTl7ntt7guYeQ
# mjsaDwKyUY+rGQ/eN2S0KzSTztnU+0OQnxHE4Gy4tQVxfvTx/iUzowChkAMErrbx
# Wv4bv2c3CsvWH4RQwxtXtRSXN3kdNn3iwkWvZ4bTCv7+LXYB9nBOHB79kDK5qhp3
# mQY=
# SIG # End signature block
