# Start-SystemStatusMonitoring-Window.ps1
# Runs SystemStatus monitoring in a separate PowerShell window instead of background job
# Date: 2025-08-21


# PowerShell 7 Self-Elevation

param(
    [int]$CheckIntervalSeconds = 30,
    [switch]$Minimized,
    [switch]$Hidden
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
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "STARTING SYSTEMSTATUS MONITORING WINDOW" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Determine window style
$windowStyle = "Normal"
if ($Minimized) { $windowStyle = "Minimized" }
if ($Hidden) { $windowStyle = "Hidden" }

Write-Host "Window Style: $windowStyle" -ForegroundColor Yellow
Write-Host "Check Interval: $CheckIntervalSeconds seconds" -ForegroundColor Yellow

# Create monitoring script that will run in the new window
$monitoringScript = @"
# SystemStatus Monitoring Script
# Running in separate window

Write-Host ''
Write-Host '==========================================' -ForegroundColor Cyan
Write-Host 'SYSTEMSTATUS MONITORING ACTIVE' -ForegroundColor Cyan
Write-Host '==========================================' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Window PID: ' -NoNewline
Write-Host `$PID -ForegroundColor Yellow
Write-Host 'Check Interval: $CheckIntervalSeconds seconds' -ForegroundColor Yellow
Write-Host ''

# Set execution policy for this window
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
Write-Host 'Execution policy set to Bypass for this window' -ForegroundColor Green

# Import SystemStatus module
Import-Module '.\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1' -Force
Write-Host 'SystemStatus module loaded' -ForegroundColor Green

# Verify critical functions
if (Get-Command Test-AutonomousAgentStatus -ErrorAction SilentlyContinue) {
    Write-Host '  [OK] Test-AutonomousAgentStatus available' -ForegroundColor Green
} else {
    Write-Host '  [ERROR] Test-AutonomousAgentStatus NOT FOUND' -ForegroundColor Red
    exit 1
}

if (Get-Command Start-AutonomousAgentSafe -ErrorAction SilentlyContinue) {
    Write-Host '  [OK] Start-AutonomousAgentSafe available' -ForegroundColor Green
} else {
    Write-Host '  [ERROR] Start-AutonomousAgentSafe NOT FOUND' -ForegroundColor Red
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
    
    Write-Host "[`$timestamp] Check #`$checkCount - Testing AutonomousAgent..." -ForegroundColor Cyan
    
    try {
        `$agentRunning = Test-AutonomousAgentStatus
        
        if (`$agentRunning) {
            `$status = Read-SystemStatus
            `$agentPid = `$null
            if (`$status.Subsystems.ContainsKey('AutonomousAgent')) {
                `$agentPid = `$status.Subsystems['AutonomousAgent'].ProcessId
            }
            Write-Host "  [OK] Agent RUNNING (PID: `$agentPid)" -ForegroundColor Green
        }
        else {
            Write-Host "  [WARN] Agent NOT running!" -ForegroundColor Yellow
            Write-Host "  [ACTION] Restarting agent..." -ForegroundColor Magenta
            
            `$restartResult = Start-AutonomousAgentSafe
            
            if (`$restartResult) {
                `$status = Read-SystemStatus
                `$newPid = `$null
                if (`$status.Subsystems.ContainsKey('AutonomousAgent')) {
                    `$newPid = `$status.Subsystems['AutonomousAgent'].ProcessId
                }
                Write-Host "  [SUCCESS] Agent RESTARTED (PID: `$newPid)" -ForegroundColor Green
                
                # Log restart
                `$logEntry = "`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Agent restarted (PID: `$newPid)"
                Add-Content -Path '.\agent_restart_log.txt' -Value `$logEntry
            }
            else {
                Write-Host "  [ERROR] Failed to restart agent!" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "  [ERROR] Exception: `$_" -ForegroundColor Red
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
Write-Host '==========================================' -ForegroundColor Cyan
Write-Host 'MONITORING ENDED' -ForegroundColor Cyan
Write-Host '==========================================' -ForegroundColor Cyan
"@

# Save script to temp file
$tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
Set-Content -Path $tempScript -Value $monitoringScript -Encoding ASCII

Write-Host "Monitoring script saved to: $tempScript" -ForegroundColor Gray
Write-Host ""

# Start monitoring in new window
Write-Host "Starting monitoring in new PowerShell window..." -ForegroundColor Cyan
$processArgs = @{
    FilePath = "pwsh.exe"
    ArgumentList = "-NoExit", "-ExecutionPolicy", "Bypass", "-File", $tempScript
    WindowStyle = $windowStyle
    PassThru = $true
}

$monitorProcess = Start-Process @processArgs

if ($monitorProcess) {
    Write-Host "  Monitoring window started!" -ForegroundColor Green
    Write-Host "  Process ID: $($monitorProcess.Id)" -ForegroundColor Yellow
    
    # Save process info
    $processInfo = @{
        ProcessId = $monitorProcess.Id
        StartTime = Get-Date
        ScriptPath = $tempScript
        WindowStyle = $windowStyle
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
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "SETUP COMPLETE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU/ot50wELUO0jVcLp8NIwhZxP
# ea2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUx3wdS1jjhwBccMWmvtPLH07qvU8wDQYJKoZIhvcNAQEBBQAEggEARNqJ
# ExC12e7y1BLPm21cI80z2qbkOTaSUimCl/ltRQIR5cci5otFBsIiCwGtrUVI/wAB
# d2Kr+I59HwnPtpfalnLbk6BhQrn1O4llmjejdhNo0bp+LoiqWLGO67ROK0rLCT1N
# qSm9MOrN9CUibFcTVz/PWD2vaSO+1Qsh8yDIvbI6JGdJ8vqGOg83YczQUfCvWXed
# iJtq+TtQMUcjgWhEQqcMyd/jqxVWpO/FbLaiyY6nAMkCkhDFWZ+JxaxdYQc6iU7O
# oSlnuHZwnRLZEKrNmNI65WpHUSfaYTxfXBTwiOJE7TpX3CDIijGdgVQQTtokz2Cq
# 1C8/LFHeXZl8XQti2A==
# SIG # End signature block



