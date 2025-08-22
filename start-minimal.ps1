# Minimal startup script - loads only working modules
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "Unity-Claude Autonomous System - Minimal Start" -ForegroundColor Cyan
Write-Host "Directory: $(Get-Location)" -ForegroundColor Green

try {
    # Load core modules that work
    Write-Host "Loading SessionManager..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-SessionManager.psm1" -Force
    Write-Host "SessionManager loaded!" -ForegroundColor Green
    
    Write-Host "Loading StateTracker..." -ForegroundColor Yellow  
    Import-Module ".\Modules\Unity-Claude-AutonomousStateTracker.psm1" -Force
    Write-Host "StateTracker loaded!" -ForegroundColor Green
    
    Write-Host "Loading PerformanceOptimizer..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-PerformanceOptimizer.psm1" -Force
    Write-Host "PerformanceOptimizer loaded!" -ForegroundColor Green
    
    Write-Host "Loading ResourceOptimizer..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-ResourceOptimizer.psm1" -Force
    Write-Host "ResourceOptimizer loaded!" -ForegroundColor Green
    
    Write-Host "`nAll modules loaded successfully!" -ForegroundColor Cyan
    Write-Host "Available functions:" -ForegroundColor Yellow
    
    # Show available functions
    $functions = Get-Command -Module Unity-Claude-SessionManager, Unity-Claude-AutonomousStateTracker, Unity-Claude-PerformanceOptimizer, Unity-Claude-ResourceOptimizer
    $functions.Name | Sort-Object | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    
    Write-Host "`nDemo: Creating a conversation session..." -ForegroundColor Cyan
    $session = New-ConversationSession -SessionName "TestSession" -SessionType "Manual"
    if ($session.Success) {
        Write-Host "Session created successfully: $($session.Session.SessionId)" -ForegroundColor Green
    }
    
    Write-Host "`nDemo: Initializing state tracking..." -ForegroundColor Cyan  
    $stateTracking = Initialize-AutonomousStateTracking -AgentId "TestAgent"
    if ($stateTracking.Success) {
        Write-Host "State tracking initialized: $($stateTracking.StateTracking.AgentId)" -ForegroundColor Green
    }
    
    Write-Host "`nDemo: Performance optimization..." -ForegroundColor Cyan
    $perfReport = Get-PerformanceReport
    Write-Host "Performance baseline established" -ForegroundColor Green
    
    Write-Host "`nMinimal system ready! All core modules working." -ForegroundColor Cyan
    Write-Host "Type 'exit' to close or continue testing..." -ForegroundColor Yellow
    
} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Details: $($_.Exception)" -ForegroundColor DarkRed
}

# Keep window open
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU3WD13Hr+Xtrxdi44EW4Q/ptN
# j8egggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUNRUwmF/gIdkPKNOb1n2eBYZoMvwwDQYJKoZIhvcNAQEBBQAEggEAqPza
# ps+GpvL5+DlAK2iAEh2JoEsAwRoV+8OTF09MM5EXqNjpHL5FAYvurNq4X261lKdS
# tfa7h9MLv/R8SNdgZKcKiK2oJVpr+jUjH7loOiLWQDhH8cfRcgsfJ6AIVX+Z2Y4L
# rRwsfV4QBl9OLF4UrMD8los4W949zGZYC3SJMe9gqY0VQXs0wIT9rPQueEmZ5uHe
# flmzlNJ0R7ZxnusGqErHtv7hrh8GKFzOIhHYqAM7mASuWMd616FN9RidWlAN5Jef
# wJkykmMPJcl4xkLLZX/64T3LlGCUsbr7XufqIuMJLFFjLBJ1EE9mc812p78kx+Mb
# +I/alVjLmnj6kkWgtw==
# SIG # End signature block
