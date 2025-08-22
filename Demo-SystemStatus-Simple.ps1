# Demo-SystemStatus-Simple.ps1
# Simple demonstration of Unity-Claude System Status module
# Date: 2025-08-19

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Unity-Claude System Status Module - Simple Demo" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# Import the module
Write-Host "Loading module..." -ForegroundColor Yellow
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force

# Initialize the system
Write-Host "Initializing system status monitoring..." -ForegroundColor Yellow
$initResult = Initialize-SystemStatusMonitoring
Write-Host "  Initialized: $initResult" -ForegroundColor Green
Write-Host ""

# Test 1: Register some subsystems
Write-Host "Test 1: Registering subsystems..." -ForegroundColor Cyan
try {
    # Register with actual module paths that exist
    Register-Subsystem -SubsystemName "Unity-Claude-SystemStatus" -ModulePath ".\Modules\Unity-Claude-SystemStatus"
    Write-Host "  Registered Unity-Claude-SystemStatus" -ForegroundColor Green
} catch {
    Write-Host "  Warning: $_" -ForegroundColor Yellow
}

# Test 2: Get registered subsystems
Write-Host ""
Write-Host "Test 2: Listing registered subsystems..." -ForegroundColor Cyan
$subsystems = Get-RegisteredSubsystems
if ($subsystems) {
    Write-Host "  Found $($subsystems.Count) subsystems:" -ForegroundColor Green
    foreach ($key in $subsystems.Keys) {
        Write-Host "    - $key" -ForegroundColor Gray
    }
} else {
    Write-Host "  No subsystems found" -ForegroundColor Yellow
}

# Test 3: Process health check
Write-Host ""
Write-Host "Test 3: Checking current process health..." -ForegroundColor Cyan
$health = Test-ProcessHealth -ProcessId $PID -HealthLevel "Standard"
Write-Host "  PID $PID Health Status:" -ForegroundColor Green
Write-Host "    PID Exists: $($health.PidHealthy)" -ForegroundColor Gray
Write-Host "    Service Responsive: $($health.ServiceHealthy)" -ForegroundColor Gray
Write-Host "    Overall Healthy: $($health.OverallHealthy)" -ForegroundColor Gray

# Test 4: Performance monitoring
Write-Host ""
Write-Host "Test 4: Getting performance metrics..." -ForegroundColor Cyan
$perfHealth = Test-ProcessPerformanceHealth -ProcessId $PID
Write-Host "  Performance Health: $perfHealth" -ForegroundColor Green

$counters = Get-ProcessPerformanceCounters -ProcessId $PID
if ($counters) {
    Write-Host "  Performance Counters:" -ForegroundColor Green
    Write-Host "    CPU: $([math]::Round($counters.CpuPercent, 2))%" -ForegroundColor Gray
    Write-Host "    Memory: $([math]::Round($counters.WorkingSetMB, 2)) MB" -ForegroundColor Gray
    Write-Host "    Threads: $($counters.ThreadCount)" -ForegroundColor Gray
    Write-Host "    Handles: $($counters.HandleCount)" -ForegroundColor Gray
}

# Test 5: Send an alert
Write-Host ""
Write-Host "Test 5: Sending health alerts..." -ForegroundColor Cyan
try {
    Send-HealthAlert -AlertLevel "Info" -SubsystemName "Unity-Claude-SystemStatus" -Message "System monitoring demo started"
    Write-Host "  Alert sent successfully" -ForegroundColor Green
} catch {
    Write-Host "  Warning: $_" -ForegroundColor Yellow
}

# Test 6: Write and read system status
Write-Host ""
Write-Host "Test 6: Writing system status..." -ForegroundColor Cyan
$statusData = @{
    SystemInfo = @{
        lastUpdate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff")
        hostName = $env:COMPUTERNAME
        powerShellVersion = $PSVersionTable.PSVersion.ToString()
        unityVersion = "2021.1.14f1"
    }
    Subsystems = Get-RegisteredSubsystems
    Alerts = @()
    Watchdog = @{
        Enabled = $true
        HeartbeatIntervalSeconds = 60
        FailureThreshold = 4
    }
}

try {
    Write-SystemStatus -StatusData $statusData
    Write-Host "  Status written to file" -ForegroundColor Green
} catch {
    Write-Host "  Warning: $_" -ForegroundColor Yellow
}

# Test 7: Read system status
Write-Host ""
Write-Host "Test 7: Reading system status..." -ForegroundColor Cyan
try {
    $status = Read-SystemStatus
    if ($status) {
        Write-Host "  System Status:" -ForegroundColor Green
        Write-Host "    Host: $($status.SystemInfo.HostName)" -ForegroundColor Gray
        Write-Host "    Last Update: $($status.SystemInfo.LastUpdate)" -ForegroundColor Gray
        Write-Host "    Subsystems: $($status.Subsystems.Count)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Warning: $_" -ForegroundColor Yellow
}

# Test 8: Test heartbeat system
Write-Host ""
Write-Host "Test 8: Testing heartbeat system..." -ForegroundColor Cyan
Send-Heartbeat -SubsystemName "Unity-Claude-SystemStatus"
Write-Host "  Heartbeat sent" -ForegroundColor Green

$response = Test-HeartbeatResponse -SubsystemName "Unity-Claude-SystemStatus"
Write-Host "  Heartbeat response test result:" -ForegroundColor Green
if ($response.Healthy) {
    Write-Host "    Status: Healthy" -ForegroundColor Green
} else {
    Write-Host "    Status: Unhealthy" -ForegroundColor Yellow
    Write-Host "    Last Heartbeat: $($response.LastHeartbeat)" -ForegroundColor Gray
}

# Test 9: Alert history
Write-Host ""
Write-Host "Test 9: Checking alert history..." -ForegroundColor Cyan
$alerts = Get-AlertHistory
if ($alerts -and $alerts.Count -gt 0) {
    Write-Host "  Found $($alerts.Count) alerts:" -ForegroundColor Green
    foreach ($alert in $alerts | Select-Object -First 3) {
        Write-Host "    [$($alert.AlertLevel)] $($alert.Message)" -ForegroundColor Gray
    }
} else {
    Write-Host "  No alerts in history" -ForegroundColor Yellow
}

# Cleanup
Write-Host ""
Write-Host "Test 10: Cleanup..." -ForegroundColor Cyan
try {
    Unregister-Subsystem -SubsystemName "Unity-Claude-SystemStatus"
    Write-Host "  Unregistered subsystem" -ForegroundColor Green
} catch {
    Write-Host "  Warning during cleanup: $_" -ForegroundColor Yellow
}

Stop-SystemStatusMonitoring
Write-Host "  Monitoring stopped" -ForegroundColor Green

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Demo Complete!" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "To start full monitoring, run:" -ForegroundColor Yellow
Write-Host "  .\Start-SystemStatusMonitoring.ps1" -ForegroundColor White
Write-Host ""
Write-Host "To run the fixed test suite, run:" -ForegroundColor Yellow
Write-Host "  .\Test-Day18-Hour5-SystemIntegrationValidation-Direct.ps1" -ForegroundColor White
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUo6nPlYA019ZYP47YUfVa4MyA
# JP2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUnCGNeTKNmP7Y0jEcwA+/2cEXcjcwDQYJKoZIhvcNAQEBBQAEggEAQTzv
# oJI8OrFiP8GCPoF4c3w6vDBl6o307BtajrTrhkNVN2rwWGZAOXCC4Pa7oIPJFGKp
# l2X6grdhPR52QtIWVDrx9jf+e1nMEYjrOogJ1KJHh6w4jAIHX8VdkD4D/WeyujWP
# B0hFKJnfsYvZU5DMFFX0+wUZHL/CCPttfuXFxQto+pG4T4DLIGwdxGAtAneewa1+
# YqMlNOvdI9oXrRCoU4+V680MkO9HhdT3gz6UFVHt+wZCXwILYzamKJOXdsgYQPxe
# 7v3DCXYItaZ1VyCiqMFg0mISShEIaVzlSuX0dA3iQ5TD2UP+NaLP8MIIZhFKjts9
# Wr75/jsIW1pdDJPTeQ==
# SIG # End signature block
