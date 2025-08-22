# Start-UnifiedSystem.ps1
# Unified startup for SystemStatusMonitoring and AutonomousAgent
# Ensures proper coordination without crashes
# Date: 2025-08-20


# PowerShell 7 Self-Elevation

param(
    [switch]$SkipAutonomousAgent = $false,
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

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Unity-Claude Unified System Startup" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Starting at: $(Get-Date)" -ForegroundColor Cyan
Write-Host ""

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

# Step 2: Start SystemStatusMonitoring in a new window
Write-Host ""
Write-Host "Step 2: Starting SystemStatusMonitoring..." -ForegroundColor Yellow

$systemStatusProcess = $null
try {
    # Check if already running
    $existingMonitor = Get-WmiObject Win32_Process | Where-Object {
        $_.CommandLine -like "*SystemStatusMonitoring*.ps1*"
    }
    
    if ($existingMonitor) {
        Write-Host "  SystemStatusMonitoring already running (PID: $($existingMonitor.ProcessId))" -ForegroundColor Green
        $systemStatusProcess = Get-Process -Id $existingMonitor.ProcessId -ErrorAction SilentlyContinue
    } else {
        # Start the enhanced version
        $scriptPath = ".\Start-SystemStatusMonitoring-Enhanced.ps1"
        if (-not (Test-Path $scriptPath)) {
            # Fall back to original if enhanced doesn't exist
            $scriptPath = ".\Start-SystemStatusMonitoring.ps1"
        }
        
        Write-Host "  Starting $scriptPath in new window..." -ForegroundColor Gray
        
        $processArgs = @{
            FilePath = "pwsh.exe"
            ArgumentList = @(
                "-NoExit",
                "-ExecutionPolicy", "Bypass",
                "-File", $scriptPath,
                "-EnableHeartbeat",
                "-EnableFileWatcher"
            )
            WindowStyle = "Normal"
            PassThru = $true
        }
        
        if ($Debug) {
            $processArgs.ArgumentList += "-Debug"
        }
        
        $systemStatusProcess = Start-Process @processArgs
        
        if ($systemStatusProcess -and $systemStatusProcess.Id) {
            Write-Host "  SystemStatusMonitoring started: PID $($systemStatusProcess.Id)" -ForegroundColor Green
            
            # Give it time to initialize
            Write-Host "  Waiting for initialization..." -ForegroundColor Gray
            Start-Sleep -Seconds 5
        } else {
            Write-Host "  Failed to start SystemStatusMonitoring" -ForegroundColor Red
        }
    }
} catch {
    Write-Host "  Error starting SystemStatusMonitoring: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 3: Load SystemStatus module in this session
Write-Host ""
Write-Host "Step 3: Loading SystemStatus module..." -ForegroundColor Yellow

try {
    $modulePath = ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force -Global
        Write-Host "  SystemStatus module loaded" -ForegroundColor Green
        
        # Verify we can communicate
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

# Step 4: Start AutonomousAgent (if not skipped)
if (-not $SkipAutonomousAgent) {
    Write-Host ""
    Write-Host "Step 4: Starting AutonomousAgent..." -ForegroundColor Yellow
    
    Start-Sleep -Seconds 3  # Give SystemStatus time to stabilize
    
    try {
        # Check if already running
        $existingAgent = Get-WmiObject Win32_Process | Where-Object {
            $_.CommandLine -like "*AutonomousMonitoring.ps1*" -or
            $_.CommandLine -like "*AutonomousAgent*.ps1*"
        }
        
        if ($existingAgent) {
            Write-Host "  AutonomousAgent already running (PID: $($existingAgent.ProcessId))" -ForegroundColor Green
        } else {
            # Load the safe version that doesn't crash SystemStatus
            Write-Host "  Loading AutonomousAgent module..." -ForegroundColor Gray
            
            $agentModulePath = ".\Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent-Refactored.psd1"
            if (Test-Path $agentModulePath) {
                Import-Module $agentModulePath -Force -DisableNameChecking
                Write-Host "  AutonomousAgent module loaded" -ForegroundColor Green
                
                # Register with SystemStatus
                try {
                    Register-Subsystem -SubsystemName "Unity-Claude-AutonomousAgent" `
                                     -ModulePath ".\Modules\Unity-Claude-AutonomousAgent" `
                                     -HealthCheckLevel "Standard"
                    Write-Host "  AutonomousAgent registered with SystemStatus" -ForegroundColor Green
                } catch {
                    Write-Host "  Warning: Could not register AutonomousAgent: $($_.Exception.Message)" -ForegroundColor Yellow
                }
                
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
                            $statusData = Read-SystemStatus
                            if ($statusData -and $statusData.subsystems) {
                                $statusData.subsystems["Unity-Claude-AutonomousAgent"] = @{
                                    ProcessId = $agentProcess.Id
                                    Status = "Running"
                                    LastHeartbeat = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
                                }
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
            } else {
                Write-Host "  AutonomousAgent module not found" -ForegroundColor Yellow
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
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "System Startup Complete!" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# Display running processes
Write-Host "Running Processes:" -ForegroundColor Yellow

if ($claudePID) {
    Write-Host "  [+] Claude Code CLI: PID $claudePID" -ForegroundColor Green
} else {
    Write-Host "  [-] Claude Code CLI: Not found" -ForegroundColor Yellow
}

if ($systemStatusProcess -and $systemStatusProcess.Id) {
    Write-Host "  [+] SystemStatusMonitoring: PID $($systemStatusProcess.Id)" -ForegroundColor Green
} else {
    $monitor = Get-WmiObject Win32_Process | Where-Object {
        $_.CommandLine -like "*SystemStatusMonitoring*.ps1*"
    } | Select-Object -First 1
    if ($monitor) {
        Write-Host "  [+] SystemStatusMonitoring: PID $($monitor.ProcessId)" -ForegroundColor Green
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
        Write-Host "  [+] AutonomousAgent: PID $($agent.ProcessId)" -ForegroundColor Green
    } else {
        Write-Host "  [-] AutonomousAgent: Not running" -ForegroundColor Yellow
    }
}

# Show system status
Write-Host ""
Write-Host "System Status:" -ForegroundColor Yellow
try {
    $status = Read-SystemStatus
    if ($status -and $status.subsystems) {
        foreach ($subsystem in $status.subsystems.Keys) {
            $sub = $status.subsystems[$subsystem]
            $statusColor = if ($sub.Status -eq "Running") { "Green" } else { "Yellow" }
            Write-Host "  $subsystem`: $($sub.Status)" -ForegroundColor $statusColor
            if ($sub.ProcessId) {
                Write-Host "    PID: $($sub.ProcessId)" -ForegroundColor Gray
            }
        }
    } else {
        Write-Host "  No subsystems registered yet" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Could not read system status: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Monitor the SystemStatusMonitoring window for heartbeat activity" -ForegroundColor Gray
Write-Host "2. Check the AutonomousAgent window for Claude response monitoring" -ForegroundColor Gray
Write-Host "3. Create Unity errors to test the autonomous system" -ForegroundColor Gray
Write-Host "4. Watch for automatic prompt submission to Claude Code CLI" -ForegroundColor Gray
Write-Host ""
Write-Host "To stop all systems, close each window or press Ctrl+C" -ForegroundColor Gray
Write-Host ""
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUtNgM57jy6AqHAlff3Eh+RJTc
# +begggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUTYXDRtykjifRXJrDK+D/V3kFhK0wDQYJKoZIhvcNAQEBBQAEggEALW+g
# 3zpFOdTVH6R5hE89c4kPQPzqi/POGhgfVSNflPx631LhRduqr0Moxh0NQGO13428
# tM+d3mF7b/uVxV0ccA6DCCQNCWvWxw4Q9aHo+Tvmjg93bO2QuQsm+kRLRDR1biSw
# gystMmR9gZogSMolSGJAvJgaTj3P57jyP10dOdU6sjtRjpiBSnxtsAcFeEtDKLMj
# qU9UsjEf1RLfDQfIHG7gfyI0mwQD7LbhLrZ9g4hWUZsfF+ANehnktYDp5YPJufKR
# hnuNzoy1Eu9Mm+OkrAqmcP4MY/RY2Lr0H1CH3KRKfgEmQAOYObYEbs/y5e7PeK9Y
# JJPrSanIdgGfvlwHug==
# SIG # End signature block



