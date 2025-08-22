# Fix-ClaudeWindowDetection.ps1
# Simple fix: Just find the PowerShell window that's NOT running our scripts

Write-Host "Fixing Claude Code CLI window detection..." -ForegroundColor Cyan

# Get all PowerShell windows
$psWindows = Get-Process | Where-Object { 
    ($_.ProcessName -eq "powershell" -or $_.ProcessName -eq "pwsh") -and 
    $_.MainWindowTitle 
}

Write-Host "Found $($psWindows.Count) PowerShell windows:" -ForegroundColor Yellow

$claudeWindow = $null
foreach ($window in $psWindows) {
    # Check the command line to see what script it's running
    $wmiProcess = Get-WmiObject Win32_Process -Filter "ProcessId = $($window.Id)"
    $commandLine = $wmiProcess.CommandLine
    
    # Skip if it's running our automation scripts
    $isAutomation = $commandLine -match "AutonomousAgent|SystemStatus|UnifiedSystem|Start-.*\.ps1"
    
    if ($isAutomation) {
        Write-Host "  - PID $($window.Id): $($window.MainWindowTitle) [AUTOMATION SCRIPT - SKIP]" -ForegroundColor Red
    } else {
        Write-Host "  - PID $($window.Id): $($window.MainWindowTitle) [CLAUDE CODE CLI WINDOW]" -ForegroundColor Green
        $claudeWindow = $window
    }
}

if ($claudeWindow) {
    Write-Host "`nFound Claude Code CLI window: PID $($claudeWindow.Id)" -ForegroundColor Green
    
    # Update the marker file
    $markerFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\.claude_code_cli_pid"
    @(
        $PSVersionTable.PSVersion.ToString()
        $claudeWindow.Id
        "Claude Code CLI (Verified)"
    ) | Set-Content $markerFile -Encoding UTF8
    Write-Host "Updated marker file with PID: $($claudeWindow.Id)" -ForegroundColor Green
    
    # FORCE update system_status.json with TerminalPID
    $statusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
    $jsonText = Get-Content $statusFile -Raw
    
    # Use regex to insert TerminalPID after ProcessId
    $pattern = '"ClaudeCodeCLI":\s*\{([^}]+)\}'
    $replacement = '"ClaudeCodeCLI":  {$1,
                                             "TerminalPID":  ' + $claudeWindow.Id + '}'
    
    $jsonText = $jsonText -replace $pattern, $replacement
    $jsonText | Set-Content $statusFile -Encoding UTF8
    
    Write-Host "FORCED TerminalPID into system_status.json" -ForegroundColor Green
    
} else {
    Write-Host "`nERROR: Could not find Claude Code CLI window!" -ForegroundColor Red
    Write-Host "Make sure this script is run from the Claude Code CLI window" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1RW0hfKeLkdclwdldqGdRE5B
# 32+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU6uvMN0U/ppqXoAuED09p0jX8xY4wDQYJKoZIhvcNAQEBBQAEggEANJ6r
# U759o6g2H772i5KTY15653mGSOHu8iPf8cME8Yfh8jIhKQsxtguedDUvmF7FTr6b
# oB2U5DZUtSx6YvjxXlGEAKAxQi/kMSfy3neg2g36Ltqj3oyelp31dk0FoQLmDSo8
# bYtK2hCE2FGWAgSwXjB0nrvPBDarFxtCOwJUNcI7sb8tSG11QvMbm26LN4hVOjt+
# ZzEXP4LG/FqKMj7lFJeFf9tKGCzfVF/PCsb5Wjqqpo9gqT3NWToN/qWbNIO2UpCC
# mUYLl2D9OizNhhz0MFs3tv1Esx5pGdd0z5WFrpBJbeXfxwttCFz0ZlE9+nBwbG8J
# ZIeTlOGIa3mi3KOYdA==
# SIG # End signature block
