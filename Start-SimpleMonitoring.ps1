# Start-SimpleMonitoring.ps1
# Simple monitoring loop that checks and restarts AutonomousAgent
# Date: 2025-08-21


# PowerShell 7 Self-Elevation

param(
    [int]$CheckIntervalSeconds = 30,
    [switch]$RunOnce
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
Write-Host "SIMPLE AUTONOMOUS AGENT MONITORING" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Check Interval: $CheckIntervalSeconds seconds" -ForegroundColor Yellow
Write-Host "Run Mode: $(if($RunOnce){'Single Check'}else{'Continuous'})" -ForegroundColor Yellow
Write-Host ""

# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force

# Import module
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force

# Verify functions are available
if (-not (Get-Command Test-AutonomousAgentStatus -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Test-AutonomousAgentStatus function not found!" -ForegroundColor Red
    exit 1
}

if (-not (Get-Command Start-AutonomousAgentSafe -ErrorAction SilentlyContinue)) {
    Write-Host "ERROR: Start-AutonomousAgentSafe function not found!" -ForegroundColor Red
    exit 1
}

Write-Host "Monitoring functions loaded successfully" -ForegroundColor Green
Write-Host ""

# Create stop file path
$stopFile = ".\STOP_SIMPLE_MONITORING.txt"

if (-not $RunOnce) {
    Write-Host "To stop monitoring, create file: $stopFile" -ForegroundColor Cyan
    Write-Host "Or press Ctrl+C to stop" -ForegroundColor Cyan
    Write-Host ""
}

$checkCount = 0

# Main monitoring loop
do {
    $checkCount++
    $timestamp = Get-Date -Format "HH:mm:ss"
    
    Write-Host "[$timestamp] Check #$checkCount - Testing AutonomousAgent status..." -ForegroundColor Cyan
    
    try {
        $agentRunning = Test-AutonomousAgentStatus
        
        if ($agentRunning) {
            # Get PID for display
            $status = Read-SystemStatus
            $agentPid = $null
            if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
                $agentPid = $status.Subsystems["AutonomousAgent"].ProcessId
            }
            Write-Host "  [OK] Agent is RUNNING (PID: $agentPid)" -ForegroundColor Green
        }
        else {
            Write-Host "  [WARN] Agent is NOT running!" -ForegroundColor Yellow
            Write-Host "  [ACTION] Attempting to restart..." -ForegroundColor Magenta
            
            $restartResult = Start-AutonomousAgentSafe
            
            if ($restartResult) {
                # Get new PID
                $status = Read-SystemStatus
                $newPid = $null
                if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
                    $newPid = $status.Subsystems["AutonomousAgent"].ProcessId
                }
                Write-Host "  [SUCCESS] Agent RESTARTED (New PID: $newPid)" -ForegroundColor Green
                
                # Log to file
                $logEntry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - AutonomousAgent restarted with PID $newPid"
                Add-Content -Path ".\agent_restart_log.txt" -Value $logEntry
            }
            else {
                Write-Host "  [ERROR] Failed to restart agent!" -ForegroundColor Red
            }
        }
    }
    catch {
        Write-Host "  [ERROR] Exception during check: $_" -ForegroundColor Red
        Write-Host "  Exception type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    }
    
    if (-not $RunOnce) {
        # Check for stop file
        if (Test-Path $stopFile) {
            Write-Host ""
            Write-Host "Stop file detected. Shutting down monitoring..." -ForegroundColor Yellow
            Remove-Item $stopFile -Force
            break
        }
        
        # Wait for next check
        Write-Host "  Waiting $CheckIntervalSeconds seconds for next check..." -ForegroundColor Gray
        Start-Sleep -Seconds $CheckIntervalSeconds
    }
    
} while (-not $RunOnce)

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "MONITORING ENDED" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUqJH1lZpxFK0krwUXdndvVYzl
# CRCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUctdrQQ0IgRodxkNazI7HcGlS47AwDQYJKoZIhvcNAQEBBQAEggEApQyl
# FRwpswWsUqFmYC7m2b+LU0t7T9H1gUhjiA7qHxDWbq2dIu3FFdyZLXvs7qAmezbk
# qiaiFQrtXoiCeLp1i5nNHHiGmsZo1vdYg94BqetiLu/C+FvHov7eSnwKHRIgqIPQ
# oaV9xf76Dm9T8j+YGY/cBzsTMj97noqjoRBVd2b5KfDHAydqpJnxMpcV868mOtnM
# 3ZFEU1h3tqvuRptoZ2y9Qx7cXwtUKuryhigZQORzRQb+ODt44BWHGTu+GEt9giZQ
# UBzdI/hFSEntZ8NdYunk/VIL0TZLxqAtga4iZ1vh1ThGLivRfYw+v1W+2KR17+cF
# 4ragpVWuzT1IyASWUg==
# SIG # End signature block


