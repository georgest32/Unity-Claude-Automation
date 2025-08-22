# Set-ClaudeTerminalPID.ps1
# Properly sets the TerminalPID for the Claude Code CLI window
# This should be run FROM the Claude Code CLI window itself

param(
    [switch]$Force
)

Write-Host "Setting Claude Code CLI Terminal PID..." -ForegroundColor Cyan
Write-Host "Current window PID: $PID" -ForegroundColor Yellow

# Get current window title
$currentTitle = $Host.UI.RawUI.WindowTitle
Write-Host "Current window title: $currentTitle" -ForegroundColor Gray

# Check if this looks like a Claude Code CLI window
$isClaudeWindow = $currentTitle -match "Claude" -or 
                  $currentTitle -match "claude" -or
                  $Force

if (-not $isClaudeWindow) {
    Write-Host "WARNING: This doesn't appear to be a Claude Code CLI window!" -ForegroundColor Red
    Write-Host "Window title: $currentTitle" -ForegroundColor Yellow
    Write-Host "Use -Force to override this check" -ForegroundColor Yellow
    if (-not $Force) {
        exit 1
    }
}

# Read current system status
$statusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
if (Test-Path $statusFile) {
    $status = Get-Content $statusFile -Raw | ConvertFrom-Json
    
    # Ensure structure exists
    if (-not $status.SystemInfo) {
        $status | Add-Member -MemberType NoteProperty -Name "SystemInfo" -Value @{} -Force
    }
    
    # Check if ClaudeCodeCLI exists
    if ($status.SystemInfo.PSObject.Properties.Name -contains 'ClaudeCodeCLI') {
        # Update existing entry with TerminalPID
        $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "TerminalPID" -Value $PID -Force
        $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "TerminalTitle" -Value $currentTitle -Force
        $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "TerminalVerified" -Value (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff') -Force
        
        Write-Host "Updated existing ClaudeCodeCLI entry with TerminalPID: $PID" -ForegroundColor Green
    } else {
        # Create new entry with TerminalPID
        $claudeInfo = @{
            ProcessId = 0  # Will be filled by Update-ClaudeCodePID.ps1
            TerminalPID = $PID
            TerminalTitle = $currentTitle
            Status = "Active"
            DetectionMethod = "Terminal Window"
            LastDetected = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
            TerminalVerified = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
        }
        
        $status.SystemInfo | Add-Member -MemberType NoteProperty -Name 'ClaudeCodeCLI' -Value $claudeInfo -Force
        Write-Host "Created new ClaudeCodeCLI entry with TerminalPID: $PID" -ForegroundColor Green
    }
    
    # Save the updated status
    $status | ConvertTo-Json -Depth 10 | Set-Content $statusFile -Encoding UTF8
    
    Write-Host "`nSuccessfully set Terminal PID for Claude Code CLI!" -ForegroundColor Green
    Write-Host "TerminalPID: $PID" -ForegroundColor Cyan
    Write-Host "Window Title: $currentTitle" -ForegroundColor Cyan
    
    # Also update the marker file
    $markerFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\.claude_code_cli_pid"
    @(
        $PSVersionTable.PSVersion.ToString()
        $PID
        "Claude Code CLI Terminal (Verified)"
        $currentTitle
    ) | Set-Content $markerFile -Encoding UTF8
    Write-Host "Updated marker file with Terminal PID" -ForegroundColor Green
    
} else {
    Write-Host "ERROR: system_status.json not found!" -ForegroundColor Red
    exit 1
}

Write-Host "`nIMPORTANT: The TerminalPID has been set to $PID" -ForegroundColor Yellow
Write-Host "This will be preserved by the fixed Write-SystemStatus function" -ForegroundColor Yellow
Write-Host "The autonomous agent should now target this window correctly" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1KTh25UwV5BPOg4mfoTkebiz
# GqWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUCYALP8BPmnAanl8NR+6I5P+EuMswDQYJKoZIhvcNAQEBBQAEggEAT00E
# YPG12lDd0ylVotEq6rBr5EmIVql8jXvkWvik+iij5H2L4gZQ9W3HOxVnFKKqnW1D
# PPqKbxhZTXxIjRPMzvdOVp+/BgYKHD9xwdlwf5C8GToo1Yls9Umzj/Iqm7y1rpd6
# oWBphaOl/MUDtMVrSOc8XdIz24P6KhSKPkFM5R7Hr7n1gYs9DDpjzPcsZfVrl56E
# C67C0d9ZxWoi4FG4J70eSsfHa8X1Ky9RSoMnvgdCZKBvUpACXXDlz3x2mn6kROoL
# LRQFFHpCyHT4HdIfo8RdzsAbX6CNipHL9uYUbcbXbFn/xeHJmO1LXJAwm8DTA71F
# 97W/WWK1mYn9lZwFWA==
# SIG # End signature block
