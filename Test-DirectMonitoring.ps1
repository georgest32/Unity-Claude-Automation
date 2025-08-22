# Test-DirectMonitoring.ps1
# Direct test of monitoring functions without job complexity
# Date: 2025-08-21

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "DIRECT MONITORING TEST" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Set execution policy for this session
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
Write-Host "Execution policy set to Bypass" -ForegroundColor Green

# Import the module
Write-Host "Importing SystemStatus module..." -ForegroundColor Yellow
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force

# Check if functions exist
Write-Host ""
Write-Host "Checking if functions are available:" -ForegroundColor Cyan
$funcExists = Get-Command Test-AutonomousAgentStatus -ErrorAction SilentlyContinue
if ($funcExists) {
    Write-Host "  [OK] Test-AutonomousAgentStatus found" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Test-AutonomousAgentStatus NOT FOUND" -ForegroundColor Red
}

$funcExists = Get-Command Start-AutonomousAgentSafe -ErrorAction SilentlyContinue
if ($funcExists) {
    Write-Host "  [OK] Start-AutonomousAgentSafe found" -ForegroundColor Green
} else {
    Write-Host "  [ERROR] Start-AutonomousAgentSafe NOT FOUND" -ForegroundColor Red
}

# Test the functions directly
Write-Host ""
Write-Host "Testing Test-AutonomousAgentStatus function:" -ForegroundColor Cyan
try {
    $agentStatus = Test-AutonomousAgentStatus
    Write-Host "  Function returned: $agentStatus" -ForegroundColor $(if($agentStatus){'Green'}else{'Yellow'})
    
    if ($agentStatus) {
        Write-Host "  Agent is RUNNING" -ForegroundColor Green
        
        # Get PID
        $status = Read-SystemStatus
        $agentPid = $null
        if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
            $agentPid = $status.Subsystems["AutonomousAgent"].ProcessId
            Write-Host "  Agent PID: $agentPid" -ForegroundColor Green
        }
        
        # Kill it
        if ($agentPid) {
            Write-Host ""
            Write-Host "Killing agent process $agentPid to test restart..." -ForegroundColor Yellow
            Stop-Process -Id $agentPid -Force -ErrorAction SilentlyContinue
            Write-Host "  Process killed" -ForegroundColor Red
            
            Start-Sleep -Seconds 2
            
            # Check again
            Write-Host ""
            Write-Host "Checking agent status after kill:" -ForegroundColor Cyan
            $agentStatus = Test-AutonomousAgentStatus
            Write-Host "  Agent status: $agentStatus" -ForegroundColor $(if($agentStatus){'Green'}else{'Yellow'})
            
            if (-not $agentStatus) {
                Write-Host ""
                Write-Host "Testing Start-AutonomousAgentSafe function:" -ForegroundColor Cyan
                try {
                    $restartResult = Start-AutonomousAgentSafe
                    Write-Host "  Function returned: $restartResult" -ForegroundColor $(if($restartResult){'Green'}else{'Red'})
                    
                    if ($restartResult) {
                        Write-Host "  Agent RESTARTED successfully!" -ForegroundColor Green
                        
                        # Get new PID
                        $status = Read-SystemStatus
                        if ($status.Subsystems.ContainsKey("AutonomousAgent")) {
                            $newPid = $status.Subsystems["AutonomousAgent"].ProcessId
                            Write-Host "  New PID: $newPid" -ForegroundColor Green
                        }
                    } else {
                        Write-Host "  Failed to restart agent" -ForegroundColor Red
                    }
                }
                catch {
                    Write-Host "  EXCEPTION in Start-AutonomousAgentSafe: $_" -ForegroundColor Red
                    Write-Host "  Exception type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
                    Write-Host "  Stack trace:" -ForegroundColor Red
                    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
                }
            }
        }
    } else {
        Write-Host "  Agent is NOT running" -ForegroundColor Yellow
        
        Write-Host ""
        Write-Host "Attempting to start agent..." -ForegroundColor Cyan
        try {
            $startResult = Start-AutonomousAgentSafe
            Write-Host "  Start result: $startResult" -ForegroundColor $(if($startResult){'Green'}else{'Red'})
        }
        catch {
            Write-Host "  EXCEPTION: $_" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "  EXCEPTION in Test-AutonomousAgentStatus: $_" -ForegroundColor Red
    Write-Host "  Exception type: $($_.Exception.GetType().FullName)" -ForegroundColor Red
    Write-Host "  Stack trace:" -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Checking logs for our enhanced logging..." -ForegroundColor Cyan

# Check SystemStatus log
$logPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-SystemStatus\Logs\SystemStatus.log"
if (Test-Path $logPath) {
    Write-Host "  SystemStatus.log entries:" -ForegroundColor Yellow
    Get-Content $logPath -Tail 20 | Where-Object { $_ -like "*TEST-AUTONOMOUS*" -or $_ -like "*START-AUTONOMOUS*" } | ForEach-Object {
        Write-Host "    $_" -ForegroundColor Gray
    }
} else {
    Write-Host "  SystemStatus.log not found at: $logPath" -ForegroundColor Gray
}

# Check central log
$centralLog = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log"
if (Test-Path $centralLog) {
    Write-Host ""
    Write-Host "  Central log entries:" -ForegroundColor Yellow
    Get-Content $centralLog -Tail 30 | Where-Object { $_ -like "*SystemStatus*" -or $_ -like "*TEST-AUTONOMOUS*" -or $_ -like "*START-AUTONOMOUS*" } | Select-Object -Last 10 | ForEach-Object {
        Write-Host "    $_" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "DIRECT TEST COMPLETE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUjhMOqP9rjki/CFodWx5lWtYa
# hkGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUigCzbBLfVdXYlxbl9hi6TOfpmJIwDQYJKoZIhvcNAQEBBQAEggEALD5q
# wphLgpkq8GQarz5EkCFljUhQytKENhFrMhfUSdSZvu310vtYvwQEsM27wP8gRg1O
# G9bEHYYRdc0C77I6FtsNOvVIQroYOFf6XXV3H9DWuI9kj3G+2/VExSQ7D/ZGwIP0
# ovcV124J2F1t0ClWOgjJ6iAM9/nCQqyl9ePMviLDWPynEJkDNiPTJEQsrAVWrTSx
# 8MsUJQLXLi1S4ZiG0v8p2dEkICvwNudsjO3PBsD1Hjr7bUuO6GipFfRPad+7uJbq
# FgMD4oODutlvNc8bhvC8JlguT+l1UHLLn8vhoouGjiQpAcSlKCYwWP1vSPkwq9xV
# aW3YpZCpibtuUVdDog==
# SIG # End signature block
