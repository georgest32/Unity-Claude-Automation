# Fix-IntegrationTestEnvironment.ps1
# Fixes environment issues causing integration test failures
# Date: 2025-08-19

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Fixing Integration Test Environment" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Create missing directories
Write-Host "Creating required directories..." -ForegroundColor Yellow
$directories = @(
    ".\SessionData\Health",
    ".\SessionData\Watchdog"
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -Path $dir -ItemType Directory -Force | Out-Null
        Write-Host "  Created: $dir" -ForegroundColor Green
    } else {
        Write-Host "  Exists: $dir" -ForegroundColor Gray
    }
}

# 2. Create system_status.json if it doesnt exist
Write-Host ""
Write-Host "Creating system status file..." -ForegroundColor Yellow
$statusFile = ".\system_status.json"
if (-not (Test-Path $statusFile)) {
    $statusData = @{
        systemInfo = @{
            lastUpdate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff")
            hostName = $env:COMPUTERNAME
            powerShellVersion = $PSVersionTable.PSVersion.ToString()
            unityVersion = "2021.1.14f1"
            systemStatus = "Healthy"
        }
        subsystems = @{
            UnityEngine = @{
                status = "Running"
                pid = $null
                lastHeartbeat = (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff")
            }
            ErrorMonitor = @{
                status = "Active"
                pid = $null
                lastHeartbeat = (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff")
            }
        }
        alerts = @()
        performance = @{
            cpuUsage = 0
            memoryUsage = 0
            responseTime = 0
        }
    }
    $statusData | ConvertTo-Json -Depth 10 | Out-File $statusFile -Encoding UTF8
    Write-Host "  Created: $statusFile" -ForegroundColor Green
} else {
    Write-Host "  Exists: $statusFile" -ForegroundColor Gray
}

# 3. Verify module is properly loaded
Write-Host ""
Write-Host "Verifying module..." -ForegroundColor Yellow
try {
    Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force -Global
    $module = Get-Module "Unity-Claude-SystemStatus"
    if ($module) {
        Write-Host "  Module loaded: $($module.Name)" -ForegroundColor Green
        Write-Host "  Functions: $($module.ExportedFunctions.Count)" -ForegroundColor Green
        
        # List critical functions
        $criticalFunctions = @(
            "Write-SystemStatusLog",
            "Send-HeartbeatRequest",
            "Test-ProcessPerformanceHealth",
            "Invoke-CircuitBreakerCheck",
            "Get-ServiceDependencyGraph",
            "Initialize-SubsystemRunspaces"
        )
        
        Write-Host ""
        Write-Host "  Checking critical functions:" -ForegroundColor Cyan
        foreach ($func in $criticalFunctions) {
            $cmd = Get-Command -Name $func -ErrorAction SilentlyContinue
            if ($cmd) {
                Write-Host "    OK: $func" -ForegroundColor Green
            } else {
                Write-Host "    MISSING: $func" -ForegroundColor Red
            }
        }
    }
} catch {
    Write-Host "  Error loading module: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Environment fix complete!" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUNkL/TuHKH+GI/Llc2rbTgOph
# tlGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUM71nh85Yl5kvazvxuNlcddIk1k4wDQYJKoZIhvcNAQEBBQAEggEAa3nr
# Zh+qAfCECv6XZL8EkyOWeZtA9rwiViGN016nqIxrmUVTL6Dhh71a2vGN4JHdjOf1
# tO6YDZ+VJbqksoYS3HzcMrAnaWxmm1qV3rJY8jL1ye/YCeHTavqtOtQQvDvw0c+I
# 67SjjpbuONW4mKjbhq2lt/Y7aelysqiN7zMf0i6ad805xarD/za+QYkOcByRCL1E
# gbNE0sHkyLKTjunNorlQRHgT7mHawqDmJXiYm88VBrksRKroxnpteRZzkjbDhGSv
# wLi6WqHti8Jyu+8t8imkhvFqwXK503/zb3fGWxYpfDXLUkvOBCKqxeNTKB+hDGDZ
# hOH/EmqIOxBx0//4mA==
# SIG # End signature block
