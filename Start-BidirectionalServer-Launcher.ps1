# Start-BidirectionalServer-Launcher.ps1
# Launches the bidirectional server in a new elevated PowerShell window

[CmdletBinding()]
param(
    [int]$Port = 5560,
    [switch]$NoElevate
)

$ErrorActionPreference = 'Stop'

Write-Host "=== Unity-Claude Bidirectional Server Launcher ===" -ForegroundColor Cyan

# Path to the actual server script
$serverScript = Join-Path $PSScriptRoot "Start-BidirectionalServer.ps1"

# Build the command to run in the new window
$arguments = @(
    "-NoExit",
    "-ExecutionPolicy", "Bypass",
    "-File", "`"$serverScript`"",
    "-Port", $Port
)

if ($NoElevate) {
    # Start without elevation
    Write-Host "Starting server in new PowerShell window (non-elevated)..." -ForegroundColor Yellow
    Start-Process pwsh.exe -ArgumentList $arguments
} else {
    # Start with elevation (admin)
    Write-Host "Starting server in new elevated PowerShell window..." -ForegroundColor Yellow
    Write-Host "You may see a UAC prompt requesting admin privileges." -ForegroundColor Gray
    Start-Process pwsh.exe -ArgumentList $arguments -Verb RunAs
}

Write-Host ""
Write-Host "Server launching in new window on port $Port" -ForegroundColor Green
Write-Host ""
Write-Host "The server window will remain open and show:" -ForegroundColor Cyan
Write-Host "  - Incoming requests" -ForegroundColor White
Write-Host "  - Command execution status" -ForegroundColor White
Write-Host "  - Any errors that occur" -ForegroundColor White
Write-Host ""
Write-Host "To test the server, run:" -ForegroundColor Yellow
Write-Host '  Invoke-RestMethod -Uri "http://localhost:5560/status" -Method GET' -ForegroundColor White
Write-Host ""

# Wait a moment for the server to start
Start-Sleep -Seconds 2

# Test if the server is running
try {
    $status = Invoke-RestMethod -Uri "http://localhost:$Port/status" -Method GET -ErrorAction SilentlyContinue
    if ($status.status -eq 'running') {
        Write-Host "[OK] Server is running successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "You can now send commands to the server." -ForegroundColor Cyan
    }
} catch {
    Write-Host "Note: Server may still be starting up. Check the server window for status." -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUaz6gYpqLEA4r+DHzbNiy3u+i
# UUCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUox84Mh7DJdZ1VV4+4igoApFgLREwDQYJKoZIhvcNAQEBBQAEggEAhlzr
# EamXcUiqF5KKMY21SCu+65Zdw5jwO4aP4sFKUlha2ydg0NvE2FmjzRP2jtyq2g6C
# +BsO+/WFbNciIbuYvMFrmRh8ejj1aNdPlrDTPQScPZSbzt+CyOyKNXH53nwnEkIK
# P/pAsRgkRT/rIMzT/lR/+ZaZ27vIe0puXe1EcJsaOuoi7zi9+TOnRswVeBElUT63
# 00tpRWghwGTwtiwhUc5sXtg3kiclrB1uPweTk3E7HRVpCLgdLQ6073f/go4MN1Mt
# Mr1uV5Qj94nyIKVWo0GHaLcpsfXK7dKsxspyjQATjhVSaFQhQhjyM+X5UStUimZU
# Foo29CGdfm0PazvuEg==
# SIG # End signature block

