# Register-TerminalWindow.ps1
# Universal function for any PowerShell/terminal window to register itself with system_status.json
# This creates a centralized registry of all terminal windows in the system

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('ClaudeCodeCLI', 'UnifiedSystem', 'SystemStatusMonitoring', 'AutonomousAgent', 'Testing', 'Other')]
    [string]$WindowType,
    
    [Parameter()]
    [string]$CustomName = "",
    
    [Parameter()]
    [switch]$UpdateOnly,
    
    [Parameter()]
    [string]$StatusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
)

function Get-TerminalInfo {
    <#
    .SYNOPSIS
    Gathers comprehensive information about the current terminal window
    #>
    
    $info = @{
        ProcessId = $PID
        ParentProcessId = (Get-WmiObject Win32_Process -Filter "ProcessId=$PID").ParentProcessId
        ProcessName = (Get-Process -Id $PID).ProcessName
        StartTime = (Get-Process -Id $PID).StartTime.ToString('yyyy-MM-dd HH:mm:ss.fff')
        WindowTitle = $Host.UI.RawUI.WindowTitle
        CommandLine = (Get-WmiObject Win32_Process -Filter "ProcessId=$PID").CommandLine
        WorkingDirectory = (Get-Location).Path
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        IsElevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        HostName = $Host.Name
        Culture = $Host.CurrentCulture.Name
        UIculture = $Host.CurrentUICulture.Name
    }
    
    # Try to get the actual window handle for SendKeys
    try {
        Add-Type @"
            using System;
            using System.Diagnostics;
            using System.Runtime.InteropServices;
            
            public class WindowHelper {
                [DllImport("kernel32.dll")]
                public static extern IntPtr GetConsoleWindow();
                
                [DllImport("user32.dll")]
                public static extern int GetWindowThreadProcessId(IntPtr hWnd, out int processId);
            }
"@ -ErrorAction SilentlyContinue
        
        $consoleWindow = [WindowHelper]::GetConsoleWindow()
        if ($consoleWindow -ne [IntPtr]::Zero) {
            $windowPID = 0
            [WindowHelper]::GetWindowThreadProcessId($consoleWindow, [ref]$windowPID) | Out-Null
            $info['ConsoleWindowHandle'] = $consoleWindow.ToString()
            $info['ConsoleWindowPID'] = $windowPID
        }
    } catch {
        # Silent fail - not all environments support this
    }
    
    # Get parent window information if available
    if ($info.ParentProcessId) {
        $parentProcess = Get-Process -Id $info.ParentProcessId -ErrorAction SilentlyContinue
        if ($parentProcess) {
            $info['ParentProcessName'] = $parentProcess.ProcessName
            $info['ParentMainWindowTitle'] = $parentProcess.MainWindowTitle
        }
    }
    
    return $info
}

# Main registration logic
Write-Host "`n=== Terminal Window Registration ===" -ForegroundColor Cyan
Write-Host "Window Type: $WindowType" -ForegroundColor Yellow
if ($CustomName) {
    Write-Host "Custom Name: $CustomName" -ForegroundColor Yellow
}

# Gather terminal information
$terminalInfo = Get-TerminalInfo

Write-Host "`nTerminal Information:" -ForegroundColor Green
Write-Host "  Process ID: $($terminalInfo.ProcessId)" -ForegroundColor Gray
Write-Host "  Parent PID: $($terminalInfo.ParentProcessId)" -ForegroundColor Gray
Write-Host "  Process Name: $($terminalInfo.ProcessName)" -ForegroundColor Gray
Write-Host "  Window Title: $($terminalInfo.WindowTitle)" -ForegroundColor Gray
Write-Host "  Working Dir: $($terminalInfo.WorkingDirectory)" -ForegroundColor Gray
if ($terminalInfo.ConsoleWindowPID) {
    Write-Host "  Console Window PID: $($terminalInfo.ConsoleWindowPID)" -ForegroundColor Cyan
}

# Read existing status
$status = $null
if (Test-Path $StatusFile) {
    $status = Get-Content $StatusFile -Raw | ConvertFrom-Json
} else {
    Write-Host "`nCreating new system_status.json..." -ForegroundColor Yellow
    $status = @{
        SystemInfo = @{}
        RegisteredTerminals = @{}
        Subsystems = @{}
        Communication = @{}
        Watchdog = @{}
        Dependencies = @{}
        Alerts = @{}
    }
}

# Ensure RegisteredTerminals section exists
if (-not $status.PSObject.Properties.Name -contains 'RegisteredTerminals') {
    $status | Add-Member -MemberType NoteProperty -Name 'RegisteredTerminals' -Value @{} -Force
}

# Create registration entry
$registrationKey = if ($CustomName) { 
    "${WindowType}_${CustomName}_$($terminalInfo.ProcessId)" 
} else { 
    "${WindowType}_$($terminalInfo.ProcessId)" 
}

$registrationEntry = @{
    Type = $WindowType
    CustomName = $CustomName
    RegistrationTime = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
    LastUpdate = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
    Status = "Active"
    TerminalInfo = $terminalInfo
}

# Special handling for ClaudeCodeCLI
if ($WindowType -eq 'ClaudeCodeCLI') {
    Write-Host "`nSpecial handling for Claude Code CLI registration..." -ForegroundColor Magenta
    
    # Update the main ClaudeCodeCLI entry
    if (-not $status.SystemInfo) {
        $status | Add-Member -MemberType NoteProperty -Name 'SystemInfo' -Value @{} -Force
    }
    
    # Preserve existing Node.js process info if available
    $existingClaude = $null
    if ($status.SystemInfo.PSObject.Properties.Name -contains 'ClaudeCodeCLI') {
        $existingClaude = $status.SystemInfo.ClaudeCodeCLI
    }
    
    $claudeEntry = @{
        ProcessId = if ($existingClaude -and $existingClaude.ProcessId) { $existingClaude.ProcessId } else { 0 }
        TerminalPID = $terminalInfo.ProcessId
        ConsoleWindowPID = if ($terminalInfo.ConsoleWindowPID) { $terminalInfo.ConsoleWindowPID } else { $terminalInfo.ProcessId }
        TerminalTitle = $terminalInfo.WindowTitle
        ParentProcessId = $terminalInfo.ParentProcessId
        Status = "Active"
        DetectionMethod = "Terminal Registration"
        LastDetected = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
        TerminalVerified = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
        WorkingDirectory = $terminalInfo.WorkingDirectory
    }
    
    $status.SystemInfo | Add-Member -MemberType NoteProperty -Name 'ClaudeCodeCLI' -Value $claudeEntry -Force
    Write-Host "  Updated main ClaudeCodeCLI entry with Terminal PID: $($terminalInfo.ProcessId)" -ForegroundColor Green
}

# Special handling for UnifiedSystem
if ($WindowType -eq 'UnifiedSystem') {
    Write-Host "`nMarking UnifiedSystem window to prevent misidentification..." -ForegroundColor Magenta
    if (-not $status.SystemInfo) {
        $status | Add-Member -MemberType NoteProperty -Name 'SystemInfo' -Value @{} -Force
    }
    $status.SystemInfo | Add-Member -MemberType NoteProperty -Name 'UnifiedSystemPID' -Value $terminalInfo.ProcessId -Force
    Write-Host "  Marked PID $($terminalInfo.ProcessId) as UnifiedSystem" -ForegroundColor Green
}

# Add to registered terminals
$status.RegisteredTerminals | Add-Member -MemberType NoteProperty -Name $registrationKey -Value $registrationEntry -Force

# Save the updated status
$status | ConvertTo-Json -Depth 10 | Set-Content $StatusFile -Encoding UTF8

Write-Host "`n✓ Terminal successfully registered!" -ForegroundColor Green
Write-Host "  Registration Key: $registrationKey" -ForegroundColor Cyan
Write-Host "  Status File: $StatusFile" -ForegroundColor Gray

# Create a marker file for this specific terminal
$markerDir = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\.terminal_markers"
if (-not (Test-Path $markerDir)) {
    New-Item -Path $markerDir -ItemType Directory -Force | Out-Null
}

$markerFile = Join-Path $markerDir "$registrationKey.marker"
$markerData = @{
    RegistrationKey = $registrationKey
    WindowType = $WindowType
    CustomName = $CustomName
    ProcessId = $terminalInfo.ProcessId
    ParentProcessId = $terminalInfo.ParentProcessId
    ConsoleWindowPID = if ($terminalInfo.ConsoleWindowPID) { $terminalInfo.ConsoleWindowPID } else { $null }
    WindowTitle = $terminalInfo.WindowTitle
    WorkingDirectory = $terminalInfo.WorkingDirectory
    RegistrationTime = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
}
$markerData | ConvertTo-Json -Depth 5 | Set-Content $markerFile -Encoding UTF8

Write-Host "  Marker File Created" -ForegroundColor Gray

# Return the registration info
return @{
    Success = $true
    RegistrationKey = $registrationKey
    ProcessId = $terminalInfo.ProcessId
    ConsoleWindowPID = if ($terminalInfo.ConsoleWindowPID) { $terminalInfo.ConsoleWindowPID } else { $terminalInfo.ProcessId }
    WindowTitle = $terminalInfo.WindowTitle
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnuKHpUaguUoVf8Y/DjMTx8fi
# P2egggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUKQTEA/xJTMK+2BYZfVeIgS/se30wDQYJKoZIhvcNAQEBBQAEggEAjBk9
# IJ0a4rIpSzSg4t/XE/nxKP1g2aF17M6+KxQC28UnnC7X8S25Q3xQdjE8b6OlIJpW
# /bHaozyxiBjMMv5IJWX8OuutWp8qN+bhnLo8By82Z1k2wfofQxr6mswKRpff3E0l
# 4zZ7AGcWj+auWscRj8RIlswXrD+lv2FGV5TQEAIO/ju4QmXTlM+n3JjZ/Xshm2xa
# xSiLV3UhmXUMVjnUVWrA4ccbMLvrQy6fw1DVRiXX50EfIrE0qF5RAxIsVVjsPu1c
# euGtLQLNtSzTkmwSsXhcNx5xIueqQe4FYPYF2y+E6OdiBxkcCdtNC2TXTrspAX4n
# c01SDpfu6DR6fmWDug==
# SIG # End signature block
