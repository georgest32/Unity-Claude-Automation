# Debug-Windows.ps1
# Debug window detection to find the actual Claude Code CLI process
# Date: 2025-08-18

Write-Host "DEBUGGING WINDOW DETECTION" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

Write-Host "All processes with main windows:" -ForegroundColor Yellow
$allProcesses = Get-Process | Where-Object { $_.MainWindowTitle -ne "" } | Sort-Object MainWindowTitle

foreach ($proc in $allProcesses) {
    $isTarget = $false
    
    # Check if this might be Claude Code
    if ($proc.MainWindowTitle -like "*Claude*" -or $proc.ProcessName -like "*claude*" -or $proc.MainWindowTitle -like "*terminal*") {
        Write-Host "  POTENTIAL CLAUDE: $($proc.MainWindowTitle) | Process: $($proc.ProcessName) | PID: $($proc.Id)" -ForegroundColor Green
        $isTarget = $true
    }
    
    # Check if this is a PowerShell window
    if ($proc.MainWindowTitle -like "*PowerShell*" -or $proc.ProcessName -eq "powershell" -or $proc.ProcessName -eq "pwsh") {
        Write-Host "  POWERSHELL: $($proc.MainWindowTitle) | Process: $($proc.ProcessName) | PID: $($proc.Id)" -ForegroundColor Cyan
        $isTarget = $true
    }
    
    # Check for terminal or console
    if ($proc.MainWindowTitle -like "*terminal*" -or $proc.MainWindowTitle -like "*console*" -or $proc.ProcessName -like "*terminal*") {
        Write-Host "  TERMINAL: $($proc.MainWindowTitle) | Process: $($proc.ProcessName) | PID: $($proc.Id)" -ForegroundColor Yellow
        $isTarget = $true
    }
    
    if (-not $isTarget) {
        Write-Host "    $($proc.MainWindowTitle) | $($proc.ProcessName)" -ForegroundColor DarkGray
    }
}

Write-Host "" -ForegroundColor White
Write-Host "Current PowerShell process info:" -ForegroundColor Yellow
$currentProcess = Get-Process -Id $PID
Write-Host "  Current PID: $PID" -ForegroundColor Gray
Write-Host "  Process name: $($currentProcess.ProcessName)" -ForegroundColor Gray
Write-Host "  Main window title: $($currentProcess.MainWindowTitle)" -ForegroundColor Gray
Write-Host "  Main window handle: $($currentProcess.MainWindowHandle)" -ForegroundColor Gray

Write-Host "" -ForegroundColor White
Write-Host "Processes by name:" -ForegroundColor Yellow

# Check common process names
$processNames = @("powershell", "pwsh", "WindowsTerminal", "wt", "claude", "cmd")

foreach ($name in $processNames) {
    $processes = Get-Process -Name $name -ErrorAction SilentlyContinue
    if ($processes) {
        Write-Host "  $name processes:" -ForegroundColor Cyan
        foreach ($proc in $processes) {
            Write-Host "    PID: $($proc.Id) | Title: $($proc.MainWindowTitle)" -ForegroundColor Gray
        }
    }
}

Write-Host "" -ForegroundColor White
Write-Host "RECOMMENDATION:" -ForegroundColor Cyan
Write-Host "The Claude Code CLI process is likely one of the PowerShell processes above." -ForegroundColor White
Write-Host "Check which one has this conversation active and note its exact title pattern." -ForegroundColor White

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUe2xlNQIaWDUPVcNYaxIwhYnh
# ioegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUBTfDjnNriSvOB5O48127pwima/MwDQYJKoZIhvcNAQEBBQAEggEAYDvM
# IBCzsLZW8jT9/2bQRVjuPq8tcU+MkcfnZSpvA4RAudWSID5+1qKD48QmFDP6WeVK
# pACjmfAncMVJc9DFvuwhw+JK0DswyOu75rQCZ85sKJ3vUZAnNJjqqIkFguN6XxMF
# bBGYjPPbaDYEIkpzAAXOJyz+HYjs1UG9eRDyEzP6IknDpRup4Na/X6YIuUzt/YrN
# uqdzgudymtJ1qQFL5HQXlNj0DPGQRnB0TAc8Ih4MtVtsAInVr6YPALjWEAw2UwrH
# BggbZaAS4gze+4pCXy3EKTFwvyfvutu8xU72KszSWGMqT/8/0hYvoUIHJqGpfT7i
# CPNJ7k/g1gc2P4LkBA==
# SIG # End signature block
