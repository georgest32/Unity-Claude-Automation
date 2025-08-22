# Start-Autonomous-Fixed.ps1
# Fixed autonomous system startup script
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "STARTING AUTONOMOUS SYSTEM" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan

try {
    # Clean up existing jobs
    Write-Host "Cleaning up previous jobs..." -ForegroundColor Yellow
    $existingJobs = Get-Job
    if ($existingJobs) {
        foreach ($job in $existingJobs) {
            Stop-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -Force -ErrorAction SilentlyContinue
        }
        Write-Host "  Cleaned up jobs" -ForegroundColor Green
    }
    
    # Load modules
    Write-Host "Loading modules..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-SessionManager.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-AutonomousStateTracker.psm1" -Force
    Write-Host "  Modules loaded" -ForegroundColor Green
    
    # Initialize session
    Write-Host "Initializing session..." -ForegroundColor Yellow
    $session = New-ConversationSession -SessionName "AutonomousSystem" -SessionType "Production"
    $sessionId = $session.Session.SessionId
    $agentId = "Agent_$(Get-Date -Format 'HHmmss')"
    Initialize-AutonomousStateTracking -AgentId $agentId
    Write-Host "  Session: $sessionId" -ForegroundColor Green
    Write-Host "  Agent: $agentId" -ForegroundColor Green
    
    # Start autonomous loop
    Write-Host "Starting autonomous feedback loop..." -ForegroundColor Yellow
    $loopResult = Start-AutonomousFeedbackLoop
    
    if ($loopResult.Success) {
        Add-ConversationHistoryEntry -SessionId $sessionId -Type "SystemAction" -Content "Autonomous system started successfully"
        
        Write-Host "" -ForegroundColor White
        Write-Host "AUTONOMOUS SYSTEM IS LIVE!" -ForegroundColor Green
        Write-Host "==========================" -ForegroundColor Green
        Write-Host "• Unity error monitoring: ACTIVE" -ForegroundColor White
        Write-Host "• Auto window switching: ACTIVE" -ForegroundColor White
        Write-Host "• Claude CLI submission: ACTIVE" -ForegroundColor White
        Write-Host "" -ForegroundColor White
        Write-Host "Session: $sessionId" -ForegroundColor Gray
        Write-Host "Agent: $agentId" -ForegroundColor Gray
        Write-Host "" -ForegroundColor White
        Write-Host "Create Unity compilation errors to test!" -ForegroundColor Cyan
        Write-Host "Press Ctrl+C to stop..." -ForegroundColor Yellow
        
    } else {
        Write-Host "Failed to start: $($loopResult.Error)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Startup error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUiwvm+uKbpSBw5f3AC8Zng/xQ
# ormgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU1aV7DF+9sP9+RB5q9ku7ZfgPSbUwDQYJKoZIhvcNAQEBBQAEggEAZfIJ
# BoAGyabwLt47iuGSUilbiIyIFn+9io7XfzqizL+EfvM5lGBQj0N8kYJhwXJm1qRf
# 7T0JmvvhW4shch47XpGGPNnqy8AoaDtk+1gEjvJxiu15KHkSZ/S/35OoHR7gFOgE
# ttFkYRNm4lPbl7XAjcSUpCgDrZ1BlK/0htWpwTKWiWVoY+h8rL78JJCGUSoFrlJs
# UCmnS3h/l0Eu0OfySmcwM20+CRGZfGR5EB/HQvaIjUos/SUcGNmU2bip9xjIvVD3
# fypdrhjayNV+cDt71NBC/xRs+Y6iZA4S4cjUsUw/mnxlQ6gzc47R9Ia+CEmuJSMg
# 4Z2ChMJmaPSSlChU+A==
# SIG # End signature block
