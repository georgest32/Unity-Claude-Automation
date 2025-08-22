# Start-UnifiedSystem-Final.ps1  
# Final unified system startup using proper approach for persistent monitoring
# Uses Start-Process for SystemStatusMonitoring since events don't work in jobs
# Date: 2025-08-20


# PowerShell 7 Self-Elevation

param(
    [switch]$SkipAutonomousAgent = $false,
    [switch]$Debug = $false,
    [switch]$HideMonitoringWindow = $false
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

# Ensure we're running from the correct directory
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
if ($scriptPath -ne (Get-Location).Path) {
    Set-Location $scriptPath
    Write-Host "Working directory set to: $scriptPath" -ForegroundColor Gray
}

# Mark THIS window as UnifiedSystem (NOT Claude Code CLI)
$currentPID = $PID
$statusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
if (Test-Path $statusFile) {
    $status = Get-Content $statusFile -Raw | ConvertFrom-Json
    if (-not $status.SystemInfo) {
        $status | Add-Member -MemberType NoteProperty -Name "SystemInfo" -Value @{} -Force
    }
    # Add UnifiedSystem window info so it can be excluded from Claude Code CLI detection
    $status.SystemInfo | Add-Member -MemberType NoteProperty -Name "UnifiedSystemPID" -Value $currentPID -Force
    $status.SystemInfo | Add-Member -MemberType NoteProperty -Name "UnifiedSystemTitle" -Value "Start-UnifiedSystem-Final" -Force
    $status | ConvertTo-Json -Depth 10 | Set-Content $statusFile -Encoding UTF8
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Unity-Claude Complete Unified System (FINAL)" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Starting at: $(Get-Date)" -ForegroundColor Cyan
Write-Host ""

# Step 1: Find and register Claude Code CLI in system_status.json
Write-Host "Step 1: Finding and registering Claude Code CLI..." -ForegroundColor Yellow

$claudePID = $null
try {
    # Use Update-ClaudeCodePID.ps1 which both finds AND updates system_status.json
    . ".\Update-ClaudeCodePID.ps1"
    $claudePID = Update-ClaudeCodePID
    
    if ($claudePID) {
        Write-Host "  Claude Code CLI found and registered: PID $claudePID" -ForegroundColor Green
        Write-Host "  Updated system_status.json with Claude Code CLI info" -ForegroundColor Green
    } else {
        Write-Host "  Claude Code CLI not found (will check periodically)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  Error finding Claude Code CLI: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 2: Start SystemStatusMonitoring in separate window
# Research shows: Background jobs don't support event loops properly
# Must use Start-Process for timer-based monitoring scripts
Write-Host ""
Write-Host "Step 2: Starting SystemStatusMonitoring in separate process..." -ForegroundColor Yellow

$monitoringPID = $null

# Check if already running
$existingMonitoring = Get-WmiObject Win32_Process | Where-Object {
    $_.CommandLine -like "*SystemStatusMonitoring*.ps1*"
} | Select-Object -First 1

if ($existingMonitoring) {
    Write-Host "  SystemStatusMonitoring already running (PID: $($existingMonitoring.ProcessId))" -ForegroundColor Green
    $monitoringPID = $existingMonitoring.ProcessId
} else {
    # Start the isolated version to prevent file watcher conflicts
    $monitoringScript = ".\Start-SystemStatusMonitoring-Isolated.ps1"
    
    if (-not (Test-Path $monitoringScript)) {
        Write-Host "  Warning: $monitoringScript not found, using working version" -ForegroundColor Yellow
        $monitoringScript = ".\Start-SystemStatusMonitoring-Working.ps1"
        
        if (-not (Test-Path $monitoringScript)) {
            Write-Host "  Warning: $monitoringScript not found, using enhanced version" -ForegroundColor Yellow
            $monitoringScript = ".\Start-SystemStatusMonitoring-Enhanced.ps1"
        }
    }
    
    if (Test-Path $monitoringScript) {
        Write-Host "  Starting $monitoringScript..." -ForegroundColor Gray
        
        $monitoringArgs = @{
            FilePath = "pwsh.exe"
            ArgumentList = @(
                "-NoExit",
                "-ExecutionPolicy", "Bypass",
                "-File", $monitoringScript
            )
            PassThru = $true
        }
        
        # Option to hide the window (runs in background)
        if ($HideMonitoringWindow) {
            $monitoringArgs.WindowStyle = "Hidden"
            Write-Host "  Running in hidden mode (no window visible)" -ForegroundColor Gray
        } else {
            $monitoringArgs.WindowStyle = "Normal"
            Write-Host "  Running in normal mode (window visible)" -ForegroundColor Gray
        }
        
        $monitoringProcess = Start-Process @monitoringArgs
        
        if ($monitoringProcess -and $monitoringProcess.Id) {
            $monitoringPID = $monitoringProcess.Id
            Write-Host "  SystemStatusMonitoring started: PID $monitoringPID" -ForegroundColor Green
            
            # Give it time to initialize
            Write-Host "  Waiting for initialization..." -ForegroundColor Gray
            Start-Sleep -Seconds 3
            
            # Verify it's still running
            $stillRunning = Get-Process -Id $monitoringPID -ErrorAction SilentlyContinue
            if ($stillRunning) {
                Write-Host "  SystemStatusMonitoring is running successfully!" -ForegroundColor Green
            } else {
                Write-Host "  WARNING: SystemStatusMonitoring stopped unexpectedly" -ForegroundColor Red
                Write-Host "  Check logs: Get-Content .\SystemStatusMonitoring_*.log -Tail 20" -ForegroundColor Yellow
                $monitoringPID = $null
            }
        } else {
            Write-Host "  Failed to start SystemStatusMonitoring" -ForegroundColor Red
        }
    } else {
        Write-Host "  SystemStatusMonitoring script not found" -ForegroundColor Red
    }
}

# Step 3: Load SystemStatus module for communication
Write-Host ""
Write-Host "Step 3: Loading SystemStatus module for communication..." -ForegroundColor Yellow

try {
    $modulePath = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force -Global
        Write-Host "  SystemStatus module loaded" -ForegroundColor Green
        
        # Register monitoring PID if we have it
        if ($monitoringPID) {
            Start-Sleep -Seconds 1
            try {
                $status = Read-SystemStatus
                if ($status) {
                    if (-not $status.subsystems) {
                        $status.subsystems = @{}
                    }
                    if (-not $status.subsystems.ContainsKey("SystemStatusMonitoring")) {
                        $status.subsystems["SystemStatusMonitoring"] = @{}
                    }
                    $status.subsystems["SystemStatusMonitoring"]["ProcessId"] = $monitoringPID
                    $status.subsystems["SystemStatusMonitoring"]["Status"] = "Running"
                    $status.subsystems["SystemStatusMonitoring"]["LastHeartbeat"] = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
                    $status.subsystems["SystemStatusMonitoring"]["HealthScore"] = 1.0
                    Write-SystemStatus -StatusData $status
                    Write-Host "  Registered SystemStatusMonitoring PID with status system" -ForegroundColor Green
                }
            } catch {
                Write-Host "  Warning: Could not update status: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
        
        # Verify communication
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
        # Check if already running
        $existingAgent = Get-WmiObject Win32_Process | Where-Object {
            $_.CommandLine -like "*AutonomousMonitoring.ps1*" -or
            $_.CommandLine -like "*AutonomousAgent*.ps1*"
        }
        
        if ($existingAgent) {
            Write-Host "  AutonomousAgent already running (PID: $($existingAgent.ProcessId))" -ForegroundColor Green
        } else {
            # Start monitoring in new window
            $monitoringScript = ".\Start-AutonomousMonitoring.ps1"
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
                            $statusData.subsystems["Unity-Claude-AutonomousAgent"]["HealthScore"] = 1.0
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

# Check monitoring status
$monitoringRunning = $false
if ($monitoringPID) {
    $proc = Get-Process -Id $monitoringPID -ErrorAction SilentlyContinue
    if ($proc) {
        $monitoringRunning = $true
        Write-Host "  [+] SystemStatusMonitoring: PID $monitoringPID (Running)" -ForegroundColor Green
    }
}
if (-not $monitoringRunning) {
    $monitoring = Get-WmiObject Win32_Process | Where-Object {
        $_.CommandLine -like "*SystemStatusMonitoring*.ps1*"
    } | Select-Object -First 1
    if ($monitoring) {
        Write-Host "  [+] SystemStatusMonitoring: PID $($monitoring.ProcessId) (Running)" -ForegroundColor Green
        $monitoringRunning = $true
    } else {
        Write-Host "  [-] SystemStatusMonitoring: Not running" -ForegroundColor Red
    }
}

if (-not $SkipAutonomousAgent) {
    $agent = Get-WmiObject Win32_Process | Where-Object {
        $_.CommandLine -like "*AutonomousMonitoring.ps1*" -or
        $_.CommandLine -like "*AutonomousAgent*.ps1*"
    } | Select-Object -First 1
    if ($agent) {
        Write-Host "  [+] AutonomousAgent: PID $($agent.ProcessId) (Running)" -ForegroundColor Green
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

if ($monitoringRunning) {
    Write-Host "SystemStatusMonitoring is running and will:" -ForegroundColor Cyan
    Write-Host "  - Send heartbeats every 60 seconds" -ForegroundColor Gray
    Write-Host "  - Monitor all registered subsystems" -ForegroundColor Gray
    Write-Host "  - Restart failed subsystems automatically" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "Monitoring Windows:" -ForegroundColor Yellow
if ($HideMonitoringWindow) {
    Write-Host "  SystemStatusMonitoring: Hidden (use Task Manager to verify)" -ForegroundColor Gray
} else {
    Write-Host "  SystemStatusMonitoring: Visible in separate window" -ForegroundColor Gray
}
Write-Host "  AutonomousAgent: Visible in separate window" -ForegroundColor Gray
Write-Host ""

Write-Host "To stop all systems:" -ForegroundColor Yellow
Write-Host "  1. Create stop signal: New-Item .\STOP_MONITORING.txt" -ForegroundColor Gray
Write-Host "  2. Close windows manually or use Task Manager" -ForegroundColor Gray
Write-Host ""

Write-Host "To view logs:" -ForegroundColor Yellow
Write-Host "  Get-Content .\SystemStatusMonitoring_*.log -Tail 20" -ForegroundColor Gray
Write-Host ""

Write-Host "To hide monitoring window next time:" -ForegroundColor Yellow
Write-Host "  .\Start-UnifiedSystem-Final.ps1 -HideMonitoringWindow" -ForegroundColor Gray
Write-Host ""
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQURWf8FWn07XNNiq1mzGgZObxY
# R0GgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUfKWTYf1807Blsr2yUXSBHR5XDBkwDQYJKoZIhvcNAQEBBQAEggEAPHW9
# gxNkdl6CDT8B7rTDeEpIy3D90g/qVzjZUZcwpDXO6nnLKkQNbpLawpljSFuPcImo
# e7ypeEJlfRUifAPH+Rv0kiBnDPp2ipFJhyrPhbEUsuJ/kRwDmg96n/8rhpVma3yM
# LVfTcvv6w3YlzK6UkLblJgBOYlgLSPbcy3WxUb+Xyats1Sz8xONKrr3jCRu5ASWB
# jBMbmAixZ3YshmXiEmoX1w1Tmq0XeiJ/1p5NBrIJFcjZM1TZzHGUaTgcBCTmvdPb
# SjBZErcAtCISoM3cHkHET+3hSS3s4aEo1mA40UhRlD4FgWlNGLiw1qZXFR8JqNig
# g8RMq/FV1qVoLf/bJQ==
# SIG # End signature block



