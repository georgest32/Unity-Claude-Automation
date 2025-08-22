# Test-LoggingFix.ps1
# Tests the logging fix for concurrent write issues
# Date: 2025-08-21

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "TESTING LOGGING FIX" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Import the module with the fixed logging
Write-Host "Importing AutonomousAgent module..." -ForegroundColor Yellow
Import-Module ".\Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent-Refactored.psd1" -Force

# Test concurrent writes
Write-Host ""
Write-Host "Testing concurrent log writes..." -ForegroundColor Cyan

$jobs = @()

# Start 5 concurrent jobs that write to the log
for ($i = 1; $i -le 5; $i++) {
    $job = Start-Job -Name "LogTest$i" -ScriptBlock {
        param($Index, $ModulePath)
        
        Import-Module $ModulePath -Force
        
        for ($j = 1; $j -le 10; $j++) {
            Write-AgentLog -Message "Test message $j from job $Index" -Level "INFO" -Component "TestJob$Index" -NoConsole
            Start-Sleep -Milliseconds (Get-Random -Minimum 10 -Maximum 100)
        }
    } -ArgumentList $i, "$PWD\Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent-Refactored.psd1"
    
    $jobs += $job
    Write-Host "  Started job $i (ID: $($job.Id))" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Waiting for jobs to complete..." -ForegroundColor Yellow

# Wait for all jobs
$jobs | Wait-Job | Out-Null

Write-Host "  All jobs completed" -ForegroundColor Green

# Check for errors
Write-Host ""
Write-Host "Checking job results..." -ForegroundColor Cyan

$hasErrors = $false
foreach ($job in $jobs) {
    if ($job.State -eq "Failed") {
        $hasErrors = $true
        Write-Host "  Job $($job.Name) FAILED" -ForegroundColor Red
        $job | Receive-Job -ErrorVariable jobErrors
        if ($jobErrors) {
            Write-Host "    Error: $jobErrors" -ForegroundColor Red
        }
    } else {
        Write-Host "  Job $($job.Name) succeeded" -ForegroundColor Green
    }
}

# Clean up jobs
$jobs | Remove-Job -Force

# Check log files
Write-Host ""
Write-Host "Checking log files..." -ForegroundColor Cyan

$mainLog = ".\unity_claude_automation.log"
$altLogs = Get-ChildItem -Path "." -Filter "unity_claude_automation_*.log" -ErrorAction SilentlyContinue

if (Test-Path $mainLog) {
    $lines = Get-Content $mainLog -Tail 20
    Write-Host "  Main log has $((Get-Content $mainLog).Count) lines" -ForegroundColor Green
    Write-Host "  Last few entries:" -ForegroundColor Gray
    $lines | Select-Object -Last 5 | ForEach-Object {
        Write-Host "    $_" -ForegroundColor DarkGray
    }
}

if ($altLogs) {
    Write-Host ""
    Write-Host "  Alternative log files created:" -ForegroundColor Yellow
    foreach ($log in $altLogs) {
        Write-Host "    $($log.Name) - $((Get-Content $log.FullName).Count) lines" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
if ($hasErrors) {
    Write-Host "TEST COMPLETED WITH ERRORS" -ForegroundColor Red
} else {
    Write-Host "TEST COMPLETED SUCCESSFULLY" -ForegroundColor Green
}
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

if (-not $hasErrors) {
    Write-Host "The logging fix appears to be working!" -ForegroundColor Green
    Write-Host "You can now restart the unified system." -ForegroundColor Cyan
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUSW1TIH8/XcGqm77Jn9pLbH0r
# /wOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUsx9rNnhgL0ZZlWVSCREPqWh53VswDQYJKoZIhvcNAQEBBQAEggEAAtxy
# op5vhWaffHxlJFcHerwkEieRdXWPGJVd9KgqzTWXKVQIiDr3Y5Z66QMMlJKauLCh
# eDeSzS+uffcyyASpeiwer1F0clRTq8sJpEhBCdn9MjK4HWmV7S+bDDDSux9aLBSq
# cIV0+ix0rVkXwbN0bYoJC1sV34dpScidvNlQkuZzjLB6Q9JxpfVmcJNEotYbDHUI
# ZnRUVEOmduqWxTMOUzIF7FV4uxgnV9vyXvA9/GM7gmd/ycFb6Ys4Ey0FtT7H1qOM
# ZsB13yQaBzOcFeky+IHsXIIh9C2XDSNWTcaofIPHft9DZZYTshJk5Vh5FBkFeZ5b
# j1kitVK9pFJ4cSNHKw==
# SIG # End signature block
