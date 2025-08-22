# Find-ClaudeWindow.ps1
# Finds the PowerShell window that should be used for Claude Code CLI

Write-Host "`nSearching for Claude Code CLI terminal window..." -ForegroundColor Cyan

# Get all PowerShell windows
$psWindows = Get-Process | Where-Object { 
    ($_.ProcessName -eq "powershell" -or $_.ProcessName -eq "pwsh") -and 
    $_.MainWindowTitle 
}

Write-Host "Found $($psWindows.Count) PowerShell windows:" -ForegroundColor Yellow
foreach ($window in $psWindows) {
    $isAgent = $window.MainWindowTitle -match "AutonomousAgent" -or $window.MainWindowTitle -match "Autonomous"
    $isMonitoring = $window.MainWindowTitle -match "SystemStatus" -or $window.MainWindowTitle -match "Monitoring"
    $isCursor = $window.MainWindowTitle -match "Cursor"
    
    if ($isAgent) {
        Write-Host "  - PID $($window.Id): $($window.MainWindowTitle) [AUTONOMOUS AGENT - SKIP]" -ForegroundColor Red
    } elseif ($isMonitoring) {
        Write-Host "  - PID $($window.Id): $($window.MainWindowTitle) [SYSTEM MONITORING - SKIP]" -ForegroundColor Red
    } elseif ($isCursor) {
        Write-Host "  - PID $($window.Id): $($window.MainWindowTitle) [CURSOR EDITOR - SKIP]" -ForegroundColor Red
    } else {
        Write-Host "  - PID $($window.Id): $($window.MainWindowTitle) [POTENTIAL CLAUDE WINDOW]" -ForegroundColor Green
        
        # This is likely the Claude Code CLI window
        $claudeWindow = $window
    }
}

if ($claudeWindow) {
    Write-Host "`nDetected Claude Code CLI window:" -ForegroundColor Cyan
    Write-Host "  PID: $($claudeWindow.Id)" -ForegroundColor Green
    Write-Host "  Title: $($claudeWindow.MainWindowTitle)" -ForegroundColor Green
    
    # Update system_status.json with the correct TerminalPID
    $statusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
    if (Test-Path $statusFile) {
        $status = Get-Content $statusFile -Raw | ConvertFrom-Json
        if ($status.SystemInfo.ClaudeCodeCLI) {
            $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "TerminalPID" -Value $claudeWindow.Id -Force
            $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "TerminalTitle" -Value $claudeWindow.MainWindowTitle -Force
            $status | ConvertTo-Json -Depth 10 | Set-Content $statusFile -Encoding UTF8
            Write-Host "`nUpdated system_status.json with TerminalPID: $($claudeWindow.Id)" -ForegroundColor Green
        }
    }
    
    # Update the marker file
    $markerFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\.claude_code_cli_pid"
    @(
        $PSVersionTable.PSVersion.ToString()
        $claudeWindow.Id
        $claudeWindow.MainWindowTitle
    ) | Set-Content $markerFile -Encoding UTF8
    Write-Host "Updated PID marker file" -ForegroundColor Green
    
} else {
    Write-Host "`nCould not identify Claude Code CLI window!" -ForegroundColor Red
    Write-Host "Please ensure this script is run from the Claude Code CLI window" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUh0ndfUGn17cd0gogGOqU+zQq
# ZDOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUlrUIDNmqgkrB4XXiKVD2Wb3x11kwDQYJKoZIhvcNAQEBBQAEggEAl+CN
# hqOF/AKHJ+D5AdhKkp2LSyL/+z0VNs098ra92aSuBiohxMKKIddY7aKODe8D5LcI
# uI8du1v1trALCt214yPZWoo36hqdopFTd5KRvv3QAhbY8GX7ewWrDHY9bo4H6yYv
# 6bydhzmXj++2+vjtG8IkKY8ZGoHO/za46XonnI253rZDqKNw0WqPz0vSdkP12oDT
# yXU9GQUmh4hkrmXuqwNPN9NzS7J4HqSTgMNzo9QxY6p/JLE0WYB7XseXQg5Fq5Z3
# IXrhEAPY22VevBKiyDd08X/JmQUVPpq2onrwrZZyTX3vmyu1iSA7lBjslWbwUHnM
# LBw4Gw1Ccq1LQKo/Gw==
# SIG # End signature block
