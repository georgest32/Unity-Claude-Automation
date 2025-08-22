# Identify-ThisWindow.ps1
# Identifies THIS specific window where the script is being run

Write-Host "`nIdentifying THIS PowerShell window..." -ForegroundColor Cyan

# Get the current process ID - this will be the actual PID of THIS window
$currentPID = [System.Diagnostics.Process]::GetCurrentProcess().Id
$parentProcess = Get-WmiObject Win32_Process -Filter "ProcessId = $currentPID"
$parentPID = $parentProcess.ParentProcessId

Write-Host "Current process PID: $currentPID" -ForegroundColor Yellow
Write-Host "Parent process PID: $parentPID" -ForegroundColor Yellow

# Get the parent process info (this should be the actual terminal window)
$terminalProcess = Get-Process -Id $parentPID -ErrorAction SilentlyContinue

if ($terminalProcess) {
    Write-Host "`nTHIS window information:" -ForegroundColor Green
    Write-Host "  Terminal PID: $parentPID" -ForegroundColor Cyan
    Write-Host "  Terminal Process: $($terminalProcess.ProcessName)" -ForegroundColor Cyan
    Write-Host "  Terminal Title: $($terminalProcess.MainWindowTitle)" -ForegroundColor Cyan
    
    # The actual window PID we need is the parent PID
    $actualWindowPID = $parentPID
    
    # Update system_status.json with the correct TerminalPID
    $statusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
    if (Test-Path $statusFile) {
        $status = Get-Content $statusFile -Raw | ConvertFrom-Json
        if ($status.SystemInfo.ClaudeCodeCLI) {
            $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "TerminalPID" -Value $actualWindowPID -Force
            $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "TerminalTitle" -Value "Claude Code CLI Terminal" -Force
            $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "VerifiedPID" -Value $true -Force
            $status | ConvertTo-Json -Depth 10 | Set-Content $statusFile -Encoding UTF8
            Write-Host "`nUpdated system_status.json with verified TerminalPID: $actualWindowPID" -ForegroundColor Green
        }
    }
    
    # Update the marker file
    $markerFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\.claude_code_cli_pid"
    @(
        $PSVersionTable.PSVersion.ToString()
        $actualWindowPID
        "Claude Code CLI Terminal (Verified)"
    ) | Set-Content $markerFile -Encoding UTF8
    Write-Host "Updated PID marker file with verified PID" -ForegroundColor Green
    
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "THIS is the Claude Code CLI window!" -ForegroundColor Green
    Write-Host "PID $actualWindowPID has been registered." -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    
} else {
    Write-Host "`nCould not determine parent terminal process!" -ForegroundColor Red
}

# Also mark the UnifiedSystem window to avoid confusion
Write-Host "`nChecking for UnifiedSystem window..." -ForegroundColor Yellow
$allWindows = Get-Process | Where-Object { 
    $_.ProcessName -match "powershell|pwsh" -and 
    $_.MainWindowTitle 
}

foreach ($window in $allWindows) {
    if ($window.Id -ne $actualWindowPID -and $window.Id -ne $currentPID) {
        Write-Host "  Other window: PID $($window.Id) - $($window.MainWindowTitle)" -ForegroundColor Gray
        
        # Check if this might be the UnifiedSystem window
        if ($window.MainWindowTitle -match "Administrator" -and $window.Id -ne $actualWindowPID) {
            Write-Host "    ^ This might be the UnifiedSystem window" -ForegroundColor Yellow
        }
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUPdIUA2Afeye4kh9HdV45KPGi
# RSOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUMccwoa7cFq0/8tRvxaaSodb9a5IwDQYJKoZIhvcNAQEBBQAEggEAbNiT
# B+HEs8l68bvAMBvfN/DdCtfHbUZqIt+hv73zZQXYoHVwzcU7YrApuRVEucJ4Sct7
# O4Y5d87vRslpKNuvGePtH1g5b3/L64ckXc5S/ccFEm2zm9bblCTq3+UTVqFGZR0i
# HzFM48fSescw0VLDFA3RUOUQOa4oYpmRsyHkxncoD9rep+5Mioeor8sjnmMVN+Xs
# 889SRQeVYcajn/AHOynEpIhuROJTAI8R1yfcK2NMBUrtD/u6ZIcK7moyEOUZgh91
# 9V+eU0HndFzXfXdfF3JHF8lT7Hhiui/5V0fouh+L4yV/19aEKzs2VNuQA7ed79oh
# pForG191wCgj6mdL/g==
# SIG # End signature block
