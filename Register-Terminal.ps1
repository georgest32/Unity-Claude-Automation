# Register-Terminal.ps1
# Universal terminal registration for system_status.json

param(
    [Parameter(Mandatory=$true)]
    [string]$WindowType,
    
    [string]$CustomName = "",
    
    [string]$StatusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
)

Write-Host "=== Terminal Window Registration ===" -ForegroundColor Cyan
Write-Host "Window Type: $WindowType" -ForegroundColor Yellow

# Get terminal info
$terminalInfo = @{
    ProcessId = $PID
    ProcessName = (Get-Process -Id $PID).ProcessName
    StartTime = (Get-Process -Id $PID).StartTime.ToString('yyyy-MM-dd HH:mm:ss.fff')
    WindowTitle = $Host.UI.RawUI.WindowTitle
    WorkingDirectory = (Get-Location).Path
    PowerShellVersion = $PSVersionTable.PSVersion.ToString()
}

# Get parent process info
try {
    $wmiProcess = Get-WmiObject Win32_Process -Filter "ProcessId=$PID"
    $terminalInfo['ParentProcessId'] = $wmiProcess.ParentProcessId
    $terminalInfo['CommandLine'] = $wmiProcess.CommandLine
} catch {
    $terminalInfo['ParentProcessId'] = 0
}

Write-Host "Terminal Information:" -ForegroundColor Green
Write-Host "  Process ID: $($terminalInfo.ProcessId)" -ForegroundColor Gray
Write-Host "  Parent PID: $($terminalInfo.ParentProcessId)" -ForegroundColor Gray
Write-Host "  Window Title: $($terminalInfo.WindowTitle)" -ForegroundColor Gray

# Read existing status
$status = $null
if (Test-Path $StatusFile) {
    $status = Get-Content $StatusFile -Raw | ConvertFrom-Json
} else {
    $status = @{
        SystemInfo = @{}
        RegisteredTerminals = @{}
        Subsystems = @{}
    }
}

# Ensure RegisteredTerminals exists
if (-not $status.PSObject.Properties.Name -contains 'RegisteredTerminals') {
    $status | Add-Member -MemberType NoteProperty -Name 'RegisteredTerminals' -Value @{} -Force
}

# Create registration key
$registrationKey = "${WindowType}_$($terminalInfo.ProcessId)"

# Create registration entry
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
    Write-Host "Updating ClaudeCodeCLI entry..." -ForegroundColor Magenta
    
    if (-not $status.SystemInfo) {
        $status | Add-Member -MemberType NoteProperty -Name 'SystemInfo' -Value @{} -Force
    }
    
    # Get existing entry if present
    $existingClaude = $null
    if ($status.SystemInfo.PSObject.Properties.Name -contains 'ClaudeCodeCLI') {
        $existingClaude = $status.SystemInfo.ClaudeCodeCLI
    }
    
    $claudeEntry = @{
        ProcessId = if ($existingClaude -and $existingClaude.ProcessId) { $existingClaude.ProcessId } else { 0 }
        TerminalPID = $terminalInfo.ProcessId
        TerminalTitle = $terminalInfo.WindowTitle
        ParentProcessId = $terminalInfo.ParentProcessId
        Status = "Active"
        DetectionMethod = "Terminal Registration"
        LastDetected = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
        WorkingDirectory = $terminalInfo.WorkingDirectory
    }
    
    $status.SystemInfo | Add-Member -MemberType NoteProperty -Name 'ClaudeCodeCLI' -Value $claudeEntry -Force
    Write-Host "  Updated with Terminal PID: $($terminalInfo.ProcessId)" -ForegroundColor Green
}

# Special handling for UnifiedSystem
if ($WindowType -eq 'UnifiedSystem') {
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

Write-Host "Terminal successfully registered!" -ForegroundColor Green
Write-Host "  Registration Key: $registrationKey" -ForegroundColor Cyan

# Return success
return @{
    Success = $true
    RegistrationKey = $registrationKey
    ProcessId = $terminalInfo.ProcessId
    WindowTitle = $terminalInfo.WindowTitle
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUBC2lUL66BhUOveDptoLqSK/T
# lMugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUyu0porCSZDVZx8XOoB0DoMzJWWMwDQYJKoZIhvcNAQEBBQAEggEAR/5v
# +ardWUA09p8kDUkLpyhAEawKPekrec9v2tpLCSV9iqkRoYkA7Zq7KF6N5QvyHHqC
# 9RgyZvusaHqzJ2J2+mbl5wd8Nco0nH6vdzLLmvwwebhValY7L5Dx4J8JXAAAgp78
# AkXB/+udPrUqQlSvHQc3OvLMQYFud6qhVnuGWAc2s4uhKMGfGZRfaVDe8ZHST60x
# X02CTEjNEMiaBPlN2IVtNvrhZvMNrDpvtAv3/GXFM0eJosplRm2LEoFEq4dD97qA
# qkoJs4lsLpyLhaozzmWUBpxHklDyVc6QN5GEgCX+YfC6LlYYF1Pbd+5BJR3NGf2L
# egKiy2c7M/Fh7izaBA==
# SIG # End signature block
