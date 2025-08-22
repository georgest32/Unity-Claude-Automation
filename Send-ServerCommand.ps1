# Send-ServerCommand.ps1
# Client script to send commands to the bidirectional server

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('trigger-compilation', 'check-errors', 'switch-window')]
    [string]$Command,
    
    [int]$Port = 5560
)

$ErrorActionPreference = 'Stop'

$uri = "http://localhost:$Port/command"

Write-Host "Sending command '$Command' to server..." -ForegroundColor Yellow

try {
    $body = @{
        command = $Command
    } | ConvertTo-Json
    
    $response = Invoke-RestMethod -Uri $uri -Method POST -Body $body -ContentType 'application/json'
    
    Write-Host "Response received:" -ForegroundColor Green
    $response | ConvertTo-Json -Depth 10 | Write-Host
    
    if ($response.status -eq 'success') {
        Write-Host "[OK] Command executed successfully" -ForegroundColor Green
        
        # Show specific results based on command
        if ($Command -eq 'check-errors' -and $response.errors) {
            if ($response.errors.Count -gt 0) {
                Write-Host ""
                Write-Host "Compilation errors found:" -ForegroundColor Red
                foreach ($error in $response.errors) {
                    Write-Host "  - $error" -ForegroundColor Yellow
                }
            } else {
                Write-Host "No compilation errors found!" -ForegroundColor Green
            }
        }
    } else {
        Write-Host "[ERROR] Command failed: $($response.message)" -ForegroundColor Red
    }
} catch {
    Write-Host "Failed to send command: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Make sure the server is running:" -ForegroundColor Yellow
    Write-Host "  .\Start-BidirectionalServer-Launcher.ps1" -ForegroundColor White
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9Z6aYH2uooMJf/NloJBkGXgM
# HJGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU5jsEudicYQoFAM9/EzP1BFD4zGswDQYJKoZIhvcNAQEBBQAEggEAFnUn
# R8t92iNuSacMc0l8Q/HZlfpGFly2+1WxQ1o5IeNs0X8SdZ8Rsox2hhxqIn+NO3Hn
# UdWU0CYynTcuQOSHXNg/riUiSfId5nKOsQt3GMKeWIUdRxGXblfwRRXqRXWVlsrB
# 74ZKK0H7+5p94fAe+L92x2wuHCJXYpq0FSX8YUyWZ99aW1wbqcVQIgM2R+9TgMal
# GYGMn+t8Mc0v1QD6Ms34oOxB3pVrODcySrZzh3NjRsVQikEI21+lXZw+Ke0mPzgU
# L3j8Nsh3OxiiK1tbZr6XjDqvMB7QKczN+08U385iqmwqcinry0ZkFclZ8Z/kT2mw
# UI1jvDh/3RTU9abJxw==
# SIG # End signature block
