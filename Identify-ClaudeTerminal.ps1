# Identify-ClaudeTerminal.ps1
# Helps identify and mark the correct Claude Code CLI terminal window

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "Claude Code CLI Terminal Identification" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Show all PowerShell windows
Write-Host "Available PowerShell Windows:" -ForegroundColor Yellow
$psWindows = Get-Process | Where-Object { 
    $_.ProcessName -match "powershell|pwsh" -and 
    $_.MainWindowTitle 
} | Select-Object Id, ProcessName, MainWindowTitle

$index = 1
$psWindows | ForEach-Object {
    Write-Host "$index. PID: $($_.Id) - $($_.MainWindowTitle)" -ForegroundColor Gray
    $index++
}

Write-Host "`nTo identify this window for Claude Code CLI:" -ForegroundColor Green
Write-Host "1. Note which window above is THIS Claude Code CLI window" -ForegroundColor White
Write-Host "2. Enter the PID of THIS window when prompted" -ForegroundColor White
Write-Host ""

# Prompt user to identify the correct window
$userPID = Read-Host "Enter the PID of THIS Claude Code CLI window"

if ($userPID -match '^\d+$') {
    $selectedPID = [int]$userPID
    
    # Verify the PID exists
    $selectedWindow = Get-Process -Id $selectedPID -ErrorAction SilentlyContinue
    if ($selectedWindow) {
        Write-Host "`nSelected window: $($selectedWindow.MainWindowTitle) (PID: $selectedPID)" -ForegroundColor Green
        
        # Update the marker file with the correct PID
        $markerFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\.claude_code_cli_pid"
        $content = @(
            $PSVersionTable.PSVersion.ToString()
            $selectedPID
            "Claude Code CLI - Unity Automation"
        )
        $content | Set-Content $markerFile -Encoding UTF8
        Write-Host "Updated PID marker file with PID: $selectedPID" -ForegroundColor Green
        
        # Also update system_status.json with the terminal PID
        $statusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
        if (Test-Path $statusFile) {
            try {
                $status = Get-Content $statusFile -Raw | ConvertFrom-Json
                if ($status.SystemInfo -and $status.SystemInfo.ClaudeCodeCLI) {
                    # Add terminal PID info
                    if ($status.SystemInfo.ClaudeCodeCLI -is [PSCustomObject]) {
                        $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "TerminalPID" -Value $selectedPID -Force
                        $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "TerminalTitle" -Value $selectedWindow.MainWindowTitle -Force
                    }
                    $status | ConvertTo-Json -Depth 10 | Set-Content $statusFile -Encoding UTF8
                    Write-Host "Updated system_status.json with terminal PID" -ForegroundColor Green
                }
            } catch {
                Write-Warning "Could not update system_status.json: $_"
            }
        }
        
        Write-Host "`nConfiguration complete!" -ForegroundColor Cyan
        Write-Host "The autonomous agent will now correctly target this window." -ForegroundColor Yellow
        
    } else {
        Write-Host "PID $selectedPID not found!" -ForegroundColor Red
    }
} else {
    Write-Host "Invalid PID entered!" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1oAZ2kx+Tq9vgnxoyH+bLteY
# zOGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUyKEAoKONy6R1c/WpZcDBcD43N2YwDQYJKoZIhvcNAQEBBQAEggEAGD7d
# yqjpDs/AZV1HA5O1p+IWGSJPbX5yULxYn58ErmaAdkFL0xD1cr4MwU1odcTozd5Q
# djpwHxSm/BXHkhpNXq2BEOlrq1aQn/SQKHbFQJb0tf5UOEwtTC5dyPvic74yosQ6
# o8/2TS0VcISmtV73Yoc+r8Z7pTz6TA2NQV/7Qnnc75fiMXot07Y+0xb47RjfcciD
# kCZfHdstVN9hhoclgxvmEFTrWyB8I+riduQHNovHKFsGYvWYLfJH3URISQIcp7x1
# uJjVvxpw5htGaLqUYaUw4c3omVEb5wzWiRlvjWQbeCafEV3d/iWmkSJJClLjkP2a
# drXyqU7UOpmW9iH+Yw==
# SIG # End signature block
