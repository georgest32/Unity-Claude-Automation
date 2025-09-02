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

# Verify critical functions - try CLIOrchestrator first, fall back to AutonomousAgent
`$testFunc = `$null
`$startFunc = `$null
if (Get-Command Test-CLIOrchestratorStatus -ErrorAction SilentlyContinue) {
    Write-Host '  [OK] Test-CLIOrchestratorStatus available' -ForegroundColor Green
    `$testFunc = 'Test-CLIOrchestratorStatus'
    `$startFunc = 'Start-CLIOrchestratorSafe'
} elseif (Get-Command Test-AutonomousAgentStatus -ErrorAction SilentlyContinue) {
    Write-Host '  [OK] Test-AutonomousAgentStatus available (legacy)' -ForegroundColor Yellow
    `$testFunc = 'Test-AutonomousAgentStatus'
    `$startFunc = 'Start-AutonomousAgentSafe'
} else {
    Write-Host '  [ERROR] No monitoring functions found!' -ForegroundColor Red
    exit 1
}

if (Get-Command `$startFunc -ErrorAction SilentlyContinue) {
    Write-Host "  [OK] `$startFunc available" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] `$startFunc NOT FOUND" -ForegroundColor Red
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
    
    Write-Host "[`$timestamp] Check #`$checkCount - Testing orchestrator..." -ForegroundColor Cyan
    
    try {
        `$agentRunning = & `$testFunc
        
        if (`$agentRunning) {
            `$status = Read-SystemStatus
            `$agentPid = `$null
            if (`$status.Subsystems.ContainsKey('CLIOrchestrator')) {
                `$agentPid = `$status.Subsystems['CLIOrchestrator'].ProcessId
            } elseif (`$status.Subsystems.ContainsKey('AutonomousAgent')) {
                `$agentPid = `$status.Subsystems['AutonomousAgent'].ProcessId
            }
            Write-Host "  [OK] Orchestrator RUNNING (PID: `$agentPid)" -ForegroundColor Green
        }
        else {
            Write-Host "  [WARN] Orchestrator NOT running!" -ForegroundColor Yellow
            Write-Host "  [ACTION] Restarting orchestrator..." -ForegroundColor Magenta
            
            `$restartResult = & `$startFunc
            
            if (`$restartResult) {
                `$status = Read-SystemStatus
                `$newPid = `$null
                if (`$status.Subsystems.ContainsKey('CLIOrchestrator')) {
                    `$newPid = `$status.Subsystems['CLIOrchestrator'].ProcessId
                } elseif (`$status.Subsystems.ContainsKey('AutonomousAgent')) {
                    `$newPid = `$status.Subsystems['AutonomousAgent'].ProcessId
                }
                Write-Host "  [SUCCESS] Orchestrator RESTARTED (PID: `$newPid)" -ForegroundColor Green
                
                # Log restart
                `$logEntry = "`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Orchestrator restarted (PID: `$newPid)"
                Add-Content -Path '.\agent_restart_log.txt' -Value `$logEntry
            }
            else {
                Write-Host "  [ERROR] Failed to restart orchestrator!" -ForegroundColor Red
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
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAdb3Iv0I/AwYoz
# jRc2QfOGXmHs3mpaeRPPA4ofdsE+qqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGy2hK+KIlgQi7pAr5zTzB9t
# B142nhAsNH2Br94py7KvMA0GCSqGSIb3DQEBAQUABIIBAHHxittwUxtsqADRY/pv
# KNhjBBvVAdt+EKP0ZeE1GGd0mByjp4iHHQtrsVVHMHt5SO8zpSGfLsUze0U/LHk5
# p9mOGkjiDVsfDCl0Zx4T8vxMGYb5+7wmn6cden0TtzuH9Yc5Rz0l/ivWapg2xAlX
# +JFvTS+662Jzokg6OZK6q1qs9c8DbUtkJUEU+I7nC1V0B6OQYXhkv/IzdEyYla9q
# x+UE/X71+KIA+UNToqXhfxwzG9NnlPhlvmuiE5mrgV4qtTPQxdAqcGhsbMF64xHB
# 2/9Dmn2aUPL7UUGHiaq6VCj+Z4yJLs+GuvWsTtyphPc/B3nqsMZvuPwvgbGEt+2j
# hMw=
# SIG # End signature block
