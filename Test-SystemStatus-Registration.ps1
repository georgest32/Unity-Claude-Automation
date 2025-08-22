# Test-SystemStatus-Registration.ps1
# Test the fixed subsystem registration functionality
# Date: 2025-08-20

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "Testing SystemStatus Registration Fix..." -ForegroundColor Cyan

# Load the module
Import-Module .\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1 -Force

# Test subsystem registration
Write-Host ""
Write-Host "Test: Register-Subsystem function" -ForegroundColor Yellow
try {
    $result = Register-Subsystem -SubsystemName "TestModule" -ModulePath ".\Modules\Unity-Claude-Core\Unity-Claude-Core.psd1" -Dependencies @("Unity-Claude-SystemStatus") -HealthCheckLevel "Standard"
    
    if ($result) {
        Write-Host "  Registration: PASS" -ForegroundColor Green
        
        # Verify registration was successful
        $status = Read-SystemStatus
        Write-Host "  Status keys: $($status.Keys -join ', ')" -ForegroundColor Gray
        
        # Check both possible case variations
        $found = $false
        if ($status.Subsystems -and $status.Subsystems.ContainsKey("TestModule")) {
            Write-Host "  Subsystem found in status (Subsystems): PASS" -ForegroundColor Green
            Write-Host "  Status: $($status.Subsystems.TestModule.Status)" -ForegroundColor Gray
            $found = $true
        } elseif ($status.subsystems -and $status.subsystems.ContainsKey("TestModule")) {
            Write-Host "  Subsystem found in status (subsystems): PASS" -ForegroundColor Green
            Write-Host "  Status: $($status.subsystems.TestModule.Status)" -ForegroundColor Gray
            $found = $true
        } else {
            Write-Host "  Subsystem found in status: FAIL" -ForegroundColor Red
            if ($status.subsystems) {
                Write-Host "  Available subsystems: $($status.subsystems.Keys -join ', ')" -ForegroundColor Gray
            }
        }
        
        if ($status.Dependencies -and $status.Dependencies.ContainsKey("TestModule")) {
            Write-Host "  Dependencies recorded: PASS" -ForegroundColor Green
            Write-Host "  Dependencies: $($status.Dependencies.TestModule -join ', ')" -ForegroundColor Gray
        } else {
            Write-Host "  Dependencies recorded: FAIL" -ForegroundColor Red
            if ($status.Dependencies) {
                Write-Host "  Available dependencies: $($status.Dependencies.Keys -join ', ')" -ForegroundColor Gray
            }
        }
        
    } else {
        Write-Host "  Registration: FAIL" -ForegroundColor Red
    }
} catch {
    Write-Host "  Registration error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test complete!" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUp7sIWdtVn8FLLYYh+EVh6Fo5
# C6ygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUsZLwCf5I9KmzJQ1z7QjHZ+DTJ9MwDQYJKoZIhvcNAQEBBQAEggEAnBPD
# W3DmcWyr1AwL3wxzjsFTuzyuSEELKAj8/oEE03sUxOldsBnnj84Vwr2lfCwHIt7o
# N6eBY2li8z72t00OHV59US3wCW9QkskjjDpaONGS5PlPgNrSJK6AU/4tiLb2+LyB
# KeDen3NfGVxlH+nwUmZ7dXqyq1sLJ5p3n4X9KvS1vaNXsXBDOc4bWRDl14jzP3Qg
# XqvklKRkmvDZH2GyFFpXZ5A1Gu2cH6ZgYy+BMsl2+8jDEsAOd3I0fXPE4rIrtI5K
# R6QIw+jJq+MyKOkJRbJRDaq9eaq5RIM0jUwlujVmLb0E4B8KiZnUvhr06pGw3PIv
# wyv40iTEeAxdri2aow==
# SIG # End signature block
