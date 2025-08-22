# Set-ClaudeCodeCLITitle.ps1
# Sets the window title for the Claude Code CLI window
# This helps the automation system identify the correct window

param(
    [string]$Title = "Claude Code CLI environment"
)

Write-Host "Setting window title to: $Title" -ForegroundColor Cyan

# Set the console window title
$host.UI.RawUI.WindowTitle = $Title

Write-Host "Window title set successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "The automation system will now be able to identify this window correctly." -ForegroundColor Yellow
Write-Host "Make sure to run this script in the Claude Code CLI window." -ForegroundColor Yellow
Write-Host ""
Write-Host "Current window title: $($host.UI.RawUI.WindowTitle)" -ForegroundColor Gray

# Update system_status.json with the window title for reference
$statusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
if (Test-Path $statusFile) {
    try {
        $status = Get-Content $statusFile -Raw | ConvertFrom-Json
        if ($status.SystemInfo -and $status.SystemInfo.ClaudeCodeCLI) {
            # Add window title to the ClaudeCodeCLI info
            if ($status.SystemInfo.ClaudeCodeCLI -is [PSCustomObject]) {
                $status.SystemInfo.ClaudeCodeCLI | Add-Member -MemberType NoteProperty -Name "WindowTitle" -Value $Title -Force
            }
            $status | ConvertTo-Json -Depth 10 | Set-Content $statusFile -Encoding UTF8
            Write-Host "Updated system_status.json with window title" -ForegroundColor Green
        }
    } catch {
        Write-Warning "Could not update system_status.json: $_"
    }
}

# Also write to a marker file that this is the Claude Code CLI window
$markerFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\.claude_code_cli_pid"
$PSVersionTable.PSVersion.ToString() + "`n" + $PID + "`n" + $Title | Set-Content $markerFile -Encoding UTF8
Write-Host "Created PID marker file: $markerFile" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKIcQFL75/0ScSyptB9wUmQkr
# d1CgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU/VAqI8vfIc9RhsmdTR5u51rvuzUwDQYJKoZIhvcNAQEBBQAEggEAKFkI
# NghnGOCTHGRJR+9YPedSGEYMn9XgY6jxwPJARyiNxTPRbxsNZHs0Ssl2t6Carr4G
# zTbuiCRsA3R6BtO5WGekpQVSgs8mY0DXfkpG9SPj4DsE96xkg4wpizs9XNkazOP8
# ANEgn8+G+4iOMTXDFYaCcwk9bWJzCgddihe1l4QjvCJeBNT0svQpGPndHYNWT4Kj
# X5fBxPLYoPF1WS2sJFEiFeFWyRGqOYj2PEKchpJJF+4y90LkzR6QbYxX/S4UXq3X
# CRC1V0erMX+lkgrDZ7qmKFwlqWJPBW5UCphHoI6ZkOm8TxosCT4JLhldMe1uhFee
# ephT35rHIa3E7F0q2w==
# SIG # End signature block
