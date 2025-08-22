# Fix-LoggingIssue.ps1
# Fixes the "Stream was not readable" error in AgentLogging
# Date: 2025-08-21

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "FIXING LOGGING ISSUE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Check if log file exists and is locked
$logPath = ".\unity_claude_automation.log"

Write-Host "Checking log file: $logPath" -ForegroundColor Yellow

if (Test-Path $logPath) {
    try {
        # Try to open file for writing
        $stream = [System.IO.File]::Open($logPath, 'Append', 'Write', 'ReadWrite')
        $stream.Close()
        Write-Host "  Log file is accessible" -ForegroundColor Green
    }
    catch {
        Write-Host "  Log file is LOCKED!" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
        
        # Find processes that might have the file open
        Write-Host ""
        Write-Host "Checking for processes with file handles..." -ForegroundColor Yellow
        
        $processes = Get-Process | Where-Object {
            $_.ProcessName -like "*powershell*" -or 
            $_.ProcessName -like "*pwsh*"
        }
        
        Write-Host "  Found $($processes.Count) PowerShell processes:" -ForegroundColor Gray
        foreach ($proc in $processes) {
            Write-Host "    PID $($proc.Id): $($proc.ProcessName)" -ForegroundColor Gray
        }
        
        # Kill any orphaned monitoring processes
        Write-Host ""
        Write-Host "Looking for orphaned monitoring processes..." -ForegroundColor Yellow
        
        $orphaned = Get-WmiObject Win32_Process | Where-Object {
            $_.CommandLine -like "*AutonomousMonitoring.ps1*" -or
            $_.CommandLine -like "*SystemStatusMonitoring*"
        }
        
        if ($orphaned) {
            Write-Host "  Found $($orphaned.Count) orphaned processes" -ForegroundColor Yellow
            foreach ($proc in $orphaned) {
                Write-Host "    Killing PID $($proc.ProcessId)..." -ForegroundColor Red
                Stop-Process -Id $proc.ProcessId -Force -ErrorAction SilentlyContinue
            }
        } else {
            Write-Host "  No orphaned processes found" -ForegroundColor Green
        }
        
        # Rename the locked file
        Write-Host ""
        Write-Host "Renaming locked log file..." -ForegroundColor Yellow
        $backupName = "unity_claude_automation_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        
        try {
            Move-Item $logPath $backupName -Force
            Write-Host "  Renamed to: $backupName" -ForegroundColor Green
        }
        catch {
            Write-Host "  Could not rename file: $_" -ForegroundColor Red
            Write-Host "  Creating new log with different name..." -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  Log file does not exist (will be created)" -ForegroundColor Gray
}

# Test creating new log entry
Write-Host ""
Write-Host "Testing log write..." -ForegroundColor Cyan

try {
    $testEntry = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [INFO] [LogFix] Log file test after fix"
    Add-Content -Path $logPath -Value $testEntry -Encoding UTF8 -Force
    Write-Host "  Successfully wrote test entry!" -ForegroundColor Green
}
catch {
    Write-Host "  Failed to write test entry: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "FIX COMPLETE" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Close all PowerShell windows except this one" -ForegroundColor Gray
Write-Host "  2. Run: .\Start-UnifiedSystem-Complete.ps1" -ForegroundColor Gray
Write-Host "  3. Monitor for any new logging errors" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9d7FjjW0hyVD2rN5sseHlvW9
# nIKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUv/B3ZMYKPhQW6c/VY8f+7SkZF3UwDQYJKoZIhvcNAQEBBQAEggEAZkLp
# JJKv6n4wJ864glnBzvMKQeRArKoTdtd+txwjDGj0SU9oQXk8ypvBv/o6O6qiciWp
# 35OS7O0R26/4zd6SBWsSmY7iHvtGp61GsbVGVnEVcnG6rUi3UfADMPhHGjHeZOtt
# AB7lgToB3tu6wSBYhRMH7svNpCxSutVrtS7UBZQyQwVnMXrBwO5CSOHx7rmcviwG
# 9r720mzLsSM6BMo+pYVehW14hJkFD3ADh4WvjxXEPEVJEU7wONIU/sDBHm3So1Ty
# GN7Cc/YmoB5FJXyMdOcMGXPCuO7h5G6PCQ6zOXwd2FHD1dh9gCUy3QmYR2NNNEYj
# AH16gzvSU8yC2upBVw==
# SIG # End signature block
