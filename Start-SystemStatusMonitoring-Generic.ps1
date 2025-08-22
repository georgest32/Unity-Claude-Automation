# Start-SystemStatusMonitoring-Generic.ps1
# Generic subsystem monitoring supporting multiple subsystem types
# Date: 2025-08-22


# PowerShell 7 Self-Elevation

param(
    [int]$CheckIntervalSeconds = 30,
    [switch]$Minimized,
    [switch]$Hidden,
    [switch]$IncludePerformanceData
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

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "STARTING GENERIC SYSTEMSTATUS MONITORING" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host ""

# Determine window style
$windowStyle = "Normal"
if ($Minimized) { $windowStyle = "Minimized" }
if ($Hidden) { $windowStyle = "Hidden" }

Write-Host "Window Style: $windowStyle" -ForegroundColor Yellow
Write-Host "Check Interval: $CheckIntervalSeconds seconds" -ForegroundColor Yellow
Write-Host "Performance Data: $IncludePerformanceData" -ForegroundColor Yellow

# Create generic monitoring script
$monitoringScript = @"
# Generic SystemStatus Monitoring Script
Write-Host ''
Write-Host '===========================================' -ForegroundColor Cyan
Write-Host 'GENERIC SYSTEMSTATUS MONITORING ACTIVE' -ForegroundColor Cyan
Write-Host '===========================================' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Window PID: ' -NoNewline
Write-Host `$PID -ForegroundColor Yellow
Write-Host 'Check Interval: $CheckIntervalSeconds seconds' -ForegroundColor Yellow
Write-Host 'Performance Monitoring: $IncludePerformanceData' -ForegroundColor Yellow
Write-Host ''

# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
Write-Host 'Execution policy set to Bypass' -ForegroundColor Green

# Import SystemStatus module
Import-Module '.\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1' -Force
Write-Host 'SystemStatus module loaded' -ForegroundColor Green

# Verify generic functions
if (Get-Command Test-SubsystemStatus -ErrorAction SilentlyContinue) {
    Write-Host '  [OK] Test-SubsystemStatus available' -ForegroundColor Green
} else {
    Write-Host '  [ERROR] Test-SubsystemStatus NOT FOUND' -ForegroundColor Red
    exit 1
}

if (Get-Command Start-SubsystemSafe -ErrorAction SilentlyContinue) {
    Write-Host '  [OK] Start-SubsystemSafe available' -ForegroundColor Green
} else {
    Write-Host '  [ERROR] Start-SubsystemSafe NOT FOUND' -ForegroundColor Red
    exit 1
}

if (Get-Command Get-SubsystemManifests -ErrorAction SilentlyContinue) {
    Write-Host '  [OK] Get-SubsystemManifests available' -ForegroundColor Green
} else {
    Write-Host '  [ERROR] Get-SubsystemManifests NOT FOUND' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host 'Loading subsystem manifests...' -ForegroundColor Cyan

# Load all manifests
try {
    `$manifests = Get-SubsystemManifests
    Write-Host "Found `$(`$manifests.Count) subsystem manifests" -ForegroundColor Green
    
    foreach (`$manifest in `$manifests) {
        Write-Host "  - `$(`$manifest.Name) v`$(`$manifest.Version)" -ForegroundColor Gray
    }
} catch {
    Write-Host "Error loading manifests: `$_" -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host 'Starting monitoring loop...' -ForegroundColor Cyan
Write-Host 'Press Ctrl+C to stop monitoring' -ForegroundColor Yellow
Write-Host ''

`$checkCount = 0
`$stopFile = '.\STOP_MONITORING_WINDOW.txt'

# Main monitoring loop
while (`$true) {
    `$checkCount++
    `$timestamp = Get-Date -Format 'HH:mm:ss'
    
    Write-Host "[`$timestamp] Check #`$checkCount - Testing `$(`$manifests.Count) subsystems..." -ForegroundColor Cyan
    
    # Monitor each subsystem
    foreach (`$manifest in `$manifests) {
        `$subsystemName = `$manifest.Name
        
        try {
            Write-Host "  Checking `$subsystemName..." -ForegroundColor Gray -NoNewline
            
            # Test subsystem health
            `$healthResult = Test-SubsystemStatus -SubsystemName `$subsystemName -Manifest `$manifest -IncludePerformanceData:$IncludePerformanceData
            
            if (`$healthResult.OverallHealthy) {
                `$statusText = "  [OK] `$subsystemName HEALTHY"
                if (`$healthResult.ProcessId) {
                    `$statusText += " (PID: `$(`$healthResult.ProcessId))"
                }
                if (`$healthResult.PerformanceData) {
                    `$statusText += " [Mem: `$(`$healthResult.PerformanceData.MemoryMB)MB"
                    if (`$healthResult.PerformanceData.CpuPercent) {
                        `$statusText += ", CPU: `$(`$healthResult.PerformanceData.CpuPercent)%"
                    }
                    `$statusText += "]"
                }
                Write-Host `$statusText -ForegroundColor Green
            } else {
                Write-Host "  [WARN] `$subsystemName NOT HEALTHY!" -ForegroundColor Yellow
                
                # Check restart policy
                `$restartPolicy = `$manifest.RestartPolicy
                if (`$restartPolicy -eq "OnFailure") {
                    Write-Host "    [ACTION] Restarting `$subsystemName..." -ForegroundColor Magenta
                    
                    `$restartResult = Start-SubsystemSafe -SubsystemName `$subsystemName -Manifest `$manifest
                    
                    if (`$restartResult.Success) {
                        Write-Host "    [SUCCESS] `$subsystemName RESTARTED (PID: `$(`$restartResult.ProcessId))" -ForegroundColor Green
                        
                        # Log restart
                        `$logEntry = "`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - `$subsystemName restarted (PID: `$(`$restartResult.ProcessId))"
                        Add-Content -Path '.\subsystem_restart_log.txt' -Value `$logEntry
                    } else {
                        Write-Host "    [ERROR] Failed to restart `$subsystemName`: `$(`$restartResult.ErrorMessage)" -ForegroundColor Red
                    }
                } elseif (`$restartPolicy -eq "Never") {
                    Write-Host "    [POLICY] No restart - policy is Never" -ForegroundColor Gray
                } else {
                    Write-Host "    [POLICY] Unknown restart policy: `$restartPolicy" -ForegroundColor Yellow
                }
                
                # Show error details
                if (`$healthResult.ErrorDetails.Count -gt 0) {
                    foreach (`$error in `$healthResult.ErrorDetails) {
                        Write-Host "    [ERROR] `$error" -ForegroundColor Red
                    }
                }
            }
            
            # Apply circuit breaker if enabled
            if (Get-Command Invoke-CircuitBreakerCheck -ErrorAction SilentlyContinue) {
                `$circuitResult = Invoke-CircuitBreakerCheck -SubsystemName `$subsystemName -TestResult `$healthResult
                if (`$circuitResult.State -ne "Closed") {
                    Write-Host "    [CIRCUIT] State: `$(`$circuitResult.State), Failures: `$(`$circuitResult.FailureCount)" -ForegroundColor Magenta
                }
            }
            
        } catch {
            Write-Host "  [ERROR] Exception testing `$subsystemName`: `$_" -ForegroundColor Red
        }
    }
    
    # Check for stop file
    if (Test-Path `$stopFile) {
        Write-Host ''
        Write-Host 'Stop file detected. Shutting down...' -ForegroundColor Yellow
        Remove-Item `$stopFile -Force
        break
    }
    
    # Wait for next check
    Start-Sleep -Seconds $CheckIntervalSeconds
}

Write-Host ''
Write-Host '===========================================' -ForegroundColor Cyan
Write-Host 'MONITORING ENDED' -ForegroundColor Cyan
Write-Host '===========================================' -ForegroundColor Cyan
"@

# Save script to temp file
$tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
Set-Content -Path $tempScript -Value $monitoringScript -Encoding ASCII

Write-Host "Monitoring script saved to: $tempScript" -ForegroundColor Gray
Write-Host ""

# Start monitoring in new window
Write-Host "Starting generic monitoring in new PowerShell window..." -ForegroundColor Cyan
$processArgs = @{
    FilePath = "pwsh.exe"
    ArgumentList = "-NoExit", "-ExecutionPolicy", "Bypass", "-File", $tempScript
    WindowStyle = $windowStyle
    PassThru = $true
}

$monitorProcess = Start-Process @processArgs

if ($monitorProcess) {
    Write-Host "  Generic monitoring window started!" -ForegroundColor Green
    Write-Host "  Process ID: $($monitorProcess.Id)" -ForegroundColor Yellow
    
    # Save process info
    $processInfo = @{
        ProcessId = $monitorProcess.Id
        StartTime = Get-Date
        ScriptPath = $tempScript
        WindowStyle = $windowStyle
        MonitoringType = "Generic"
    }
    $processInfo | ConvertTo-Json | Set-Content -Path ".\monitoring_window_info.json"
    
    Write-Host ""
    Write-Host "To stop monitoring:" -ForegroundColor Cyan
    Write-Host "  1. Press Ctrl+C in the monitoring window" -ForegroundColor Gray
    Write-Host "  2. Or create file: .\STOP_MONITORING_WINDOW.txt" -ForegroundColor Gray
    Write-Host "  3. Or run: Stop-Process -Id $($monitorProcess.Id)" -ForegroundColor Gray
}
else {
    Write-Host "  Failed to start monitoring window!" -ForegroundColor Red
}

Write-Host ""
Write-Host "===========================================" -ForegroundColor Cyan
Write-Host "SETUP COMPLETE" -ForegroundColor Cyan
Write-Host "===========================================" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUfvdiB3htpoK8KzTf7IYk+hGq
# y0egggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUdGaAKfWLLus7hPofxlWQgTLV9H4wDQYJKoZIhvcNAQEBBQAEggEAoZVR
# 6claySHMNsUA78LFPOBYRRXZgsN5grK1cdrOtVlUyHwBqNyd+GivZvijQpWiLEZc
# 9reeRvY4KQ7wJT9AZoMTRN8to5ILscQ1NwRiI6+dRw4sowsmylg4a3PWOR0brCbL
# NCF98IY6kOBYxeOxl6PX1RoLryGtYxUPXdYuyAwB3gi97sxg8mHNGa7V6xO4VBO/
# uDx3JFjk9XAZivIptdCJ+51EwvNKmyST6oORL8zUZIaOfcrGI4khpUSCGeSaEdCE
# mOOdK9Qx7IVIcZv2wuVdiSGXc61aVx8aidk37wYx4l5MtjGjquHdX6Qngm6afIh4
# /kLvg8hZU40IqR5qbw==
# SIG # End signature block



