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
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCQ5un2eEChzJSv
# vN0ATwMNHroK0tiNXSpUJPLOth+wlqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIJraevCyBG5anTOkJe9a/KH+
# sZkTx4aFYfePw2A91rY1MA0GCSqGSIb3DQEBAQUABIIBADsfOcHP4qW+oecXwWPW
# gVwZtySfztRU/NJ4QwGve5bp9d3Ur172ahvd70qbCePwjC5NZWXV4wz1cjpmgpPY
# 3FXfUoELO9lJEXSm7dhbXDABO+rfUupWONUhVqezAoFP7+ALSM3Mt0TRu/p3E6AN
# 5DvX8RANnAymLdR1A1rVbSPMwl1oO5U3qgJPoy4zjzMKeDFF6IvpnSzLyz9GMwK3
# S5UtQgNtifcUmPUJn7g/0eMoUB3TlvkTNv32w0QHNxrQgBaPyEhbPAIigVZHWIFY
# 0VyX17xqvpqUVVGuaOjF2Qg7iRPMKCcdQaJHmFdYkwCXDhsLHEsmv1sY1ClpJn/4
# boc=
# SIG # End signature block
