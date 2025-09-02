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
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCDzfcvbeSsWuok
# m1i8arfyXzCVKK9ERvXJmkVFIKACyKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPbw22p99D6z2nDfs6ZPOnrP
# 0jsNaJ9LKkB5oGE+V4MTMA0GCSqGSIb3DQEBAQUABIIBAGvYDNHD4dKQmRtYZHBC
# 6m+O4SgLJcjliM6juTKXjUUllEOEbzSTFXW3e5nroaKS9NUlU3DrA+P+0IjlHJUe
# vlc+Uwc6bJsqKqznrK8Vd+piuD91uEx4UIQKSvM9IN88AZcgbOZRvALlz4mf2Bxs
# xb2Cbh8ii2rmy6ecT2Wr0XicFB3tdVEzMiF+PfohGg3/C1zYsmO/cR/AEg20JVFc
# l+cs2H4nYcB/9/1+bhqSPf2uxKL0uEsIyJrBgxUjrTGH1ZcpRDzJIUUGm3ZsTnsR
# 7El1LyOxVHK1P6aWDKKVx404fcPzeQZ1/t7Kg/tJ73AZu9PrtLq+VshP7wVLGoZt
# pUg=
# SIG # End signature block
