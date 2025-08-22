# Test-ReadSystemStatus-Debug.ps1
# Comprehensive debug test for Read-SystemStatus function
# Date: 2025-08-20

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "=== Read-SystemStatus Debug Test ===" -ForegroundColor Cyan
Write-Host "Testing with detailed logging to isolate null error source" -ForegroundColor Gray
Write-Host ""

# Load module with verbose output
Import-Module .\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1 -Force -Verbose

Write-Host ""
Write-Host "Testing Read-SystemStatus function..." -ForegroundColor Yellow

try {
    # Set verbose preference to see all debug logs
    $VerbosePreference = "Continue"
    
    Write-Host "Calling Read-SystemStatus..." -ForegroundColor Gray
    $result = Read-SystemStatus
    
    Write-Host ""
    if ($result) {
        Write-Host "SUCCESS: Read-SystemStatus returned data" -ForegroundColor Green
        Write-Host "Result type: $($result.GetType().Name)" -ForegroundColor Gray
        Write-Host "Result keys: $($result.Keys -join ', ')" -ForegroundColor Gray
    } else {
        Write-Host "FAILURE: Read-SystemStatus returned null" -ForegroundColor Red
    }
    
} catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Full exception: $($_.Exception | Out-String)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Debug test complete!" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8asIScT7VTt3Zg/xzH6ySg5J
# ZMugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUV0ed0Ef89iho8NpZPxjz9F1b2bwwDQYJKoZIhvcNAQEBBQAEggEALQpg
# VGNgstgGEx11R+lgEsp0rndIKkUiqHGb2VWgQ35ywdx0yCIQWwQQ+Z3Cl0DYwKpL
# omSwHmBJ8hAqvKzX3hdu69IV7HuNyJEvei+xzlwyQJ81jsuEo7dIy/QdWVZqQ3co
# QBuFfIbMEN/4HNXhG96FJBqYqVCP/CWp14F/5rGbHSLLCNaglqcGBmXobinNIDGC
# Rv5g6FnMaVRtNfg+cG9L3cnQMzbFBTCyTcCjhppZCfdUB1RrmK3LZ/RzsWEHkm+p
# w2RcLNX+CFDnaSU08wbJyllN+of8nssvFWbjIL4Muh3UyLgcatT1DBjQwykx/S7y
# A7uLRaDFT9AyKw2fWw==
# SIG # End signature block
