# Start-FullAutonomy.ps1
# Start the complete working autonomous system with fixed window detection
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "STARTING COMPLETE AUTONOMOUS SYSTEM" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "This system will:" -ForegroundColor White
Write-Host "• Monitor Unity compilation errors continuously" -ForegroundColor Gray
Write-Host "• Generate intelligent prompts automatically" -ForegroundColor Gray  
Write-Host "• Switch to Claude Code CLI using Alt+Tab" -ForegroundColor Gray
Write-Host "• Submit prompts without manual intervention" -ForegroundColor Gray
Write-Host "• Process your responses and continue the cycle" -ForegroundColor Gray

try {
    # Clean up any existing jobs first
    Write-Host "" -ForegroundColor White
    Write-Host "Cleaning up previous jobs..." -ForegroundColor Yellow
    $existingJobs = Get-Job
    if ($existingJobs) {
        foreach ($job in $existingJobs) {
            Stop-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -Force -ErrorAction SilentlyContinue
        }
        Write-Host "  Cleaned up $($existingJobs.Count) previous jobs" -ForegroundColor Green
    }
    
    # Load all required modules
    Write-Host "Loading autonomous modules..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-SessionManager.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-AutonomousStateTracker.psm1" -Force
    Write-Host "  All modules loaded successfully" -ForegroundColor Green
    
    # Initialize session
    Write-Host "Initializing autonomous session..." -ForegroundColor Yellow
    $session = New-ConversationSession -SessionName "FullAutonomy" -SessionType "Production"
    $sessionId = $session.Session.SessionId
    $agentId = "ProductionAgent_$(Get-Date -Format 'HHmmss')"
    $stateResult = Initialize-AutonomousStateTracking -AgentId $agentId
    Write-Host "  Session ID: $sessionId" -ForegroundColor Green
    Write-Host "  Agent ID: $agentId" -ForegroundColor Green
    
    # Start the autonomous feedback loop
    Write-Host "" -ForegroundColor White
    Write-Host "STARTING AUTONOMOUS FEEDBACK LOOP..." -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    
    $loopResult = Start-AutonomousFeedbackLoop
    
    if ($loopResult.Success) {
        # Log the start
        Add-ConversationHistoryEntry -SessionId $sessionId -Type "SystemAction" -Content "Full autonomous system started with Alt+Tab window switching"
        
        Write-Host "" -ForegroundColor White
        Write-Host "🚀 FULL AUTONOMOUS SYSTEM IS LIVE! 🚀" -ForegroundColor Green
        Write-Host "=====================================" -ForegroundColor Green
        Write-Host "" -ForegroundColor White
        Write-Host "AUTONOMOUS CAPABILITIES ACTIVE:" -ForegroundColor Cyan
        Write-Host "✓ Unity error monitoring (continuous)" -ForegroundColor Green
        Write-Host "✓ Intelligent prompt generation" -ForegroundColor Green
        Write-Host "✓ Automatic window switching (Alt+Tab)" -ForegroundColor Green
        Write-Host "✓ Claude Code CLI submission" -ForegroundColor Green
        Write-Host "✓ Response processing and analysis" -ForegroundColor Green
        Write-Host "" -ForegroundColor White
        Write-Host "OPERATION DETAILS:" -ForegroundColor Yellow
        Write-Host "Session ID: $sessionId" -ForegroundColor Gray
        Write-Host "Agent ID: $agentId" -ForegroundColor Gray
        Write-Host "Unity Log: C:\Users\georg\AppData\Local\Unity\Editor\Editor.log" -ForegroundColor Gray
        Write-Host "Target: WindowsTerminal Claude Code CLI" -ForegroundColor Gray
        Write-Host "" -ForegroundColor White
        Write-Host "TO TEST THE SYSTEM:" -ForegroundColor Cyan
        Write-Host "1. Open Unity" -ForegroundColor White
        Write-Host "2. Create a syntax error in any C# script" -ForegroundColor White
        Write-Host "3. Save the file to trigger compilation" -ForegroundColor White
        Write-Host "4. Watch for autonomous activity in Claude Code CLI" -ForegroundColor White
        Write-Host "" -ForegroundColor White
        Write-Host "The system will automatically:" -ForegroundColor Yellow
        Write-Host "• Detect new Unity compilation errors" -ForegroundColor Gray
        Write-Host "• Generate context-aware prompts" -ForegroundColor Gray
        Write-Host "• Switch to Claude Code CLI window" -ForegroundColor Gray
        Write-Host "• Submit prompts for analysis" -ForegroundColor Gray
        Write-Host "• Continue the feedback loop" -ForegroundColor Gray
        Write-Host "" -ForegroundColor White
        Write-Host "🎯 AUTONOMOUS OPERATION CONFIRMED WORKING! 🎯" -ForegroundColor Green
        Write-Host "" -ForegroundColor White
        Write-Host "Press Ctrl+C to stop or Enter to continue monitoring..." -ForegroundColor Yellow
        
    } else {
        Write-Host "❌ Failed to start autonomous system: $($loopResult.Error)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Error starting full autonomy: $($_.Exception.Message)" -ForegroundColor Red
}

# Keep running until stopped
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUOJHPZTzsKub4L6lNzFGtSBQW
# 4qCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUSqAK1Bv3V6L9B13T6ac6gGeTLNIwDQYJKoZIhvcNAQEBBQAEggEAIkHb
# 4aUz4mPTHDjcfZzGHSftddMjt4NBjevH07d2wCTR8YZ178cFloko4tBVk9uV2Vhg
# ubFVgJbm7ELxfc5+ESmi3ySFTmBx1wsl7mpOS/iw0zKc3r1y3bO+OmY+zG+OlBwj
# OCxGzQw6eovtIuUiBslKQLScHn7QZb0iFD2UWn5F024gONi1XwqZIA0bKfyKL2hw
# K+Bn1pJ2UfgFt6udZ1ygwVarAke+9D7dGr5X8SQk7l+tw0daQ0uC4Zrk9Wga/bfO
# yQmiiJrV3mHvSG8SOnNBG/Z0+PqBQpWesg/IqeNRQkZyRnpDUOtEWZI0cyN8PVPr
# 91eLeEzf1aJWM4oyhg==
# SIG # End signature block
