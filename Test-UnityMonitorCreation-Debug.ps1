# Test-UnityMonitorCreation-Debug.ps1
# Debug test for Unity Parallel Monitor Creation null array error
# Date: 2025-08-21

Write-Host "=== Unity Monitor Creation Debug Test ===" -ForegroundColor Cyan
Write-Host "Debugging New-UnityParallelMonitor null array error" -ForegroundColor Yellow

try {
    Write-Host "`n1. Testing module import..." -ForegroundColor White
    Import-Module ".\Modules\Unity-Claude-UnityParallelization\Unity-Claude-UnityParallelization.psd1" -Force -ErrorAction Stop
    Write-Host "    [SUCCESS] Unity-Claude-UnityParallelization module imported" -ForegroundColor Green
    
    Write-Host "`n2. Checking module dependencies..." -ForegroundColor White
    $rmModule = Get-Module -Name Unity-Claude-RunspaceManagement -ErrorAction SilentlyContinue
    $ppModule = Get-Module -Name Unity-Claude-ParallelProcessing -ErrorAction SilentlyContinue
    
    Write-Host "    RunspaceManagement module: $(if ($rmModule) { 'Available' } else { 'Not Available' })" -ForegroundColor $(if ($rmModule) { 'Green' } else { 'Red' })
    Write-Host "    ParallelProcessing module: $(if ($ppModule) { 'Available' } else { 'Red' })" -ForegroundColor $(if ($ppModule) { 'Green' } else { 'Red' })
    
    Write-Host "`n3. Creating mock Unity project for testing..." -ForegroundColor White
    
    # Create mock Unity project registration that should work
    $mockProjectName = "DebugMockProject"
    $mockProjectPath = "C:\MockUnityProject"
    
    # Simulate the project registration that the test tries to do
    $mockProject = @{
        Name = $mockProjectName
        Path = $mockProjectPath
        ProjectSettingsPath = "$mockProjectPath\ProjectSettings"
        LogPath = "$env:TEMP\MockUnity.log"
        MonitoringEnabled = $true
        RegisteredTime = Get-Date
        Status = "Registered"
        MonitoringConfig = @{
            FileSystemWatcher = $null
            LogMonitoring = $false
            ErrorDetection = $false
            CompilationTracking = $false
            LastActivity = $null
        }
        Statistics = @{
            CompilationsDetected = 0
            ErrorsFound = 0
            ErrorsExported = 0
            LastCompilation = $null
            AverageCompilationTime = 0
        }
    }
    
    Write-Host "    [INFO] Mock project created: $mockProjectName" -ForegroundColor Gray
    
    Write-Host "`n4. Testing New-UnityParallelMonitor with comprehensive debug..." -ForegroundColor White
    
    try {
        $monitor = New-UnityParallelMonitor -MonitorName "DebugUnityMonitor" -ProjectNames @($mockProjectName) -MaxRunspaces 2
        
        if ($monitor) {
            Write-Host "    [SUCCESS] Unity monitor created successfully" -ForegroundColor Green
            Write-Host "        Monitor Name: $($monitor.MonitorName)" -ForegroundColor Gray
            Write-Host "        Project Count: $($monitor.ProjectNames.Count)" -ForegroundColor Gray
            Write-Host "        Status: $($monitor.Status)" -ForegroundColor Gray
        } else {
            Write-Host "    [FAIL] Unity monitor creation returned null" -ForegroundColor Red
        }
        
    } catch {
        Write-Host "    [FAIL] Unity monitor creation failed: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "    Full error details:" -ForegroundColor Yellow
        Write-Host $_.Exception.ToString() -ForegroundColor Red
        
        # Check for specific error patterns
        if ($_.Exception.Message -like "*Cannot index into a null array*") {
            Write-Host "`n    ANALYSIS: Null array access error detected" -ForegroundColor Magenta
            Write-Host "    This suggests an array or hashtable is null when trying to access elements" -ForegroundColor Magenta
        }
    }
    
    Write-Host "`n=== UNITY MONITOR CREATION DEBUG COMPLETE ===" -ForegroundColor Green
    
} catch {
    Write-Host "[FAIL] Debug test failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host $_.Exception.ToString() -ForegroundColor Red
}

Write-Host "`nDebug test completed at $(Get-Date)" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU0RC7ImhLXNsW60uMXO5gYhCw
# 1SSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU8NLjCYkIIHESlqJX3hdEzmzNjE0wDQYJKoZIhvcNAQEBBQAEggEAAYo9
# XPw2MvkNPMm+Ayn87whNS5oYzSsZX1N0ZdNQSjEpoQRF+rUfKdttAzKhZ0c7ZWvQ
# IlxFrvmP53/EfxDALLPBUaKzJc3nsPxjjpDLBaxFHTn2e4j/kLYdnf3w+smktQml
# TkXLcxxw7aqkHGLzFCZrsaHJrC9uG6Ot/UwWIcaiyDDHM0g4G1EbBl7MspoT+KeE
# tY1d4EAuFGo9j/zD1MyKiJF6IqdOxXrN8+KRZpOlSeJ5W33OdyzlZU5ympQpvHs2
# pHeuHCv+CkfNKt2iDmCvq91Fmi3/oS2FwvOXllh1M1VqgPJfo+bCLW+tpJJfKeh9
# vhuyzDkB+Vwe6HTunw==
# SIG # End signature block
