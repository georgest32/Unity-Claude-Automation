# Demo-SystemStatusModule.ps1
# Demonstrates the Unity-Claude System Status module capabilities
# Date: 2025-08-19

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Unity-Claude System Status Module Demo" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# Import the module
Write-Host "Loading module..." -ForegroundColor Yellow
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force

# Initialize the system
Write-Host "Initializing system status monitoring..." -ForegroundColor Yellow
Initialize-SystemStatusMonitoring

Write-Host ""
Write-Host "=== Demo 1: Subsystem Registration ===" -ForegroundColor Green
# Register-Subsystem requires ModulePath parameter
Register-Subsystem -SubsystemName "DemoSubsystem1" -ModulePath ".\Modules\Demo1" -HealthCheckLevel "Standard"
Register-Subsystem -SubsystemName "DemoSubsystem2" -ModulePath ".\Modules\Demo2" -HealthCheckLevel "Standard"

$subsystems = Get-RegisteredSubsystems
Write-Host "Registered subsystems:"
foreach ($sub in $subsystems.Keys) {
    Write-Host "  - $sub"
}

Write-Host ""
Write-Host "=== Demo 2: Process Health Check ===" -ForegroundColor Green
$health = Test-ProcessHealth -ProcessId $PID -HealthLevel "Standard"
Write-Host "Current process health:"
Write-Host "  PID Healthy: $($health.PidHealthy)"
Write-Host "  Service Healthy: $($health.ServiceHealthy)"
Write-Host "  Overall: $($health.OverallHealthy)"

Write-Host ""
Write-Host "=== Demo 3: Performance Monitoring ===" -ForegroundColor Green
$perfHealth = Test-ProcessPerformanceHealth -ProcessId $PID
Write-Host "Performance health: $perfHealth"

$counters = Get-ProcessPerformanceCounters -ProcessId $PID
Write-Host "Performance counters:"
Write-Host "  CPU: $([math]::Round($counters.CpuPercent, 2))%"
Write-Host "  Memory: $([math]::Round($counters.WorkingSetMB, 2)) MB"
Write-Host "  Threads: $($counters.ThreadCount)"

Write-Host ""
Write-Host "=== Demo 4: Heartbeat System ===" -ForegroundColor Green
Send-Heartbeat -SubsystemName "DemoSubsystem1"
Write-Host "Heartbeat sent for DemoSubsystem1"

$response = Test-HeartbeatResponse -SubsystemName "DemoSubsystem1"
Write-Host "Heartbeat response: $response"

$allHealth = Test-AllSubsystemHeartbeats
Write-Host "All subsystems healthy: $($allHealth.AllHealthy)"

Write-Host ""
Write-Host "=== Demo 5: Alert System ===" -ForegroundColor Green
# Send-HealthAlert uses AlertLevel instead of Severity
Send-HealthAlert -AlertLevel "Info" -SubsystemName "DemoSubsystem1" -Message "Demo alert - system running normally"
Send-HealthAlert -AlertLevel "Warning" -SubsystemName "DemoSubsystem1" -Message "Demo warning - high memory usage"

$alerts = Get-AlertHistory
Write-Host "Recent alerts: $($alerts.Count) found"
if ($alerts.Count -gt 0) {
    foreach ($alert in $alerts | Select-Object -First 5) {
        Write-Host "  [$($alert.AlertLevel)] $($alert.Message)"
    }
}

Write-Host ""
Write-Host "=== Demo 6: System Status File ===" -ForegroundColor Green
# Write-SystemStatus requires StatusData parameter
$statusData = @{
    SystemInfo = @{
        lastUpdate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff")
        hostName = $env:COMPUTERNAME
    }
    Subsystems = Get-RegisteredSubsystems
    Alerts = @()
}
Write-SystemStatus -StatusData $statusData
Write-Host "System status written to file"

$status = Read-SystemStatus
Write-Host "System status contents:"
Write-Host "  Host: $($status.systemInfo.hostName)"
Write-Host "  PowerShell: $($status.systemInfo.powerShellVersion)"
Write-Host "  Unity: $($status.systemInfo.unityVersion)"
Write-Host "  Subsystems: $($status.subsystems.Count)"
Write-Host "  Alerts: $($status.alerts.Count)"

Write-Host ""
Write-Host "=== Demo 7: Critical Subsystem Monitoring ===" -ForegroundColor Green
$critical = Get-CriticalSubsystems
Write-Host "Critical subsystems: $($critical -join ', ')"

$criticalHealth = Test-CriticalSubsystemHealth
Write-Host "Critical subsystems healthy: $criticalHealth"

Write-Host ""
Write-Host "=== Demo 8: Circuit Breaker ===" -ForegroundColor Green
$circuitStatus = Invoke-CircuitBreakerCheck -SubsystemName "DemoSubsystem1"
Write-Host "Circuit breaker status for DemoSubsystem1: $circuitStatus"

Write-Host ""
Write-Host "=== Demo 9: Message System ===" -ForegroundColor Green
$message = New-SystemStatusMessage -MessageType "StatusUpdate" -Source "Demo" -Target "SystemStatus" -Payload @{
    status = "Running"
    timestamp = Get-Date
}
Write-Host "Created message: $($message.messageType) from $($message.source)"

Write-Host ""
Write-Host "=== Demo 10: Communication Performance ===" -ForegroundColor Green
$perf = Measure-CommunicationPerformance -TestDurationSeconds 1
Write-Host "Communication performance:"
Write-Host "  Messages per second: $($perf.MessagesPerSecond)"
Write-Host "  Average latency: $($perf.AverageLatencyMs) ms"

Write-Host ""
Write-Host "=== Demo Complete ===" -ForegroundColor Cyan
Write-Host "Cleaning up..."

# Cleanup
Unregister-Subsystem -SubsystemName "DemoSubsystem1"
Unregister-Subsystem -SubsystemName "DemoSubsystem2"
Stop-SystemStatusMonitoring

Write-Host "Demo complete!" -ForegroundColor Green
Write-Host ""
Write-Host "To start full monitoring, run: .\Start-SystemStatusMonitoring.ps1" -ForegroundColor Yellow
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUrhAWbd91ChU/HVBKOYFBkmS
# IrmgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUoxV82bcKcChp4mWxEGo91D3r4+EwDQYJKoZIhvcNAQEBBQAEggEAlv+P
# CoBgci9SV8F4UrNm52Z5iHaSUqqN+Qx+J1Z9aqlfZgMA0qjMqSy+WZwsBS3PZRBe
# 4JWAquhst6kKPwrrpUj7DvilQnolT77R31dD1TFsVb4dkQROr8m3oqtJ2OJPUp+9
# 3ui5wJkgfp4r25lpdcFfRkHEP/FSY25LlF6Ur+nDa4lr3q6g2GxLONsAdaL4yJgW
# TQ5BgEkVY44iRS3dmjqHJx11uWd9YReB2HQcv/EiOpmp1D3RtPWi4cNoSGFO7CHt
# SATIUzxm9l20EiGWVP4Yja2eQlFeKh5fV206wHhXdehai8j/uY/6YQi0C3brnNFg
# O4dVBUQVECdrOlUXFg==
# SIG # End signature block
