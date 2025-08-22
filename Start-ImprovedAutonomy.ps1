# Start-ImprovedAutonomy.ps1
# Improved autonomous system based on web research findings
# Uses safe Unity APIs and reliable PowerShell monitoring
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "STARTING IMPROVED AUTONOMOUS SYSTEM" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Research-based improvements:" -ForegroundColor White
Write-Host "• Safe Unity console export (no LogEntries assertions)" -ForegroundColor Gray
Write-Host "• Reliable PowerShell monitoring (Register-ObjectEvent + polling)" -ForegroundColor Gray
Write-Host "• Hybrid file watching with fallback mechanisms" -ForegroundColor Gray
Write-Host "• Fixed window detection and Alt+Tab automation" -ForegroundColor Gray

try {
    # Clean up any existing monitoring
    Write-Host "" -ForegroundColor White
    Write-Host "Cleaning up existing monitoring..." -ForegroundColor Yellow
    
    # Stop old background jobs
    $existingJobs = Get-Job -ErrorAction SilentlyContinue
    if ($existingJobs) {
        foreach ($job in $existingJobs) {
            Stop-Job $job -ErrorAction SilentlyContinue
            Remove-Job $job -Force -ErrorAction SilentlyContinue
        }
        Write-Host "  Cleaned up $($existingJobs.Count) background jobs" -ForegroundColor Green
    }
    
    # Clean up old file watchers and events
    Get-EventSubscriber | Where-Object { $_.SourceObject -is [System.IO.FileSystemWatcher] } | ForEach-Object {
        Unregister-Event $_.SubscriptionId -Force -ErrorAction SilentlyContinue
    }
    
    # Load improved modules
    Write-Host "Loading improved modules..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-ReliableMonitoring.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-SessionManager.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-AutonomousStateTracker.psm1" -Force
    Write-Host "  All modules loaded successfully" -ForegroundColor Green
    
    # Initialize session tracking
    Write-Host "Initializing autonomous session..." -ForegroundColor Yellow
    $session = New-ConversationSession -SessionName "ImprovedAutonomy" -SessionType "Research-Based"
    $sessionId = $session.Session.SessionId
    $agentId = "ImprovedAgent_$(Get-Date -Format 'HHmmss')"
    Initialize-AutonomousStateTracking -AgentId $agentId
    Write-Host "  Session: $sessionId" -ForegroundColor Green
    Write-Host "  Agent: $agentId" -ForegroundColor Green
    
    # Check Unity safe console exporter
    Write-Host "Verifying Unity safe console export..." -ForegroundColor Yellow
    $safeExportPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_errors_safe.json"
    
    if (Test-Path $safeExportPath) {
        $fileInfo = Get-Item $safeExportPath
        Write-Host "  ✓ Safe export file exists" -ForegroundColor Green
        Write-Host "    Modified: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
        Write-Host "    Size: $($fileInfo.Length) bytes" -ForegroundColor Gray
    } else {
        Write-Host "  ! Safe export file not found - Unity SafeConsoleExporter may not be running" -ForegroundColor Yellow
        Write-Host "    Expected: $safeExportPath" -ForegroundColor Gray
        Write-Host "    Make sure Unity is open with SafeConsoleExporter.cs" -ForegroundColor Yellow
    }
    
    # Define autonomous callback
    $autonomousCallback = {
        param($errors)
        
        Write-Host "" -ForegroundColor White
        Write-Host "🎯 AUTONOMOUS SYSTEM TRIGGERED!" -ForegroundColor Green
        Write-Host "================================" -ForegroundColor Green
        Write-Host "Detected $($errors.Count) Unity errors" -ForegroundColor Yellow
        
        foreach ($error in $errors) {
            Write-Host "  ERROR: $error" -ForegroundColor Red
        }
        
        try {
            # Generate intelligent prompt
            Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force
            $promptResult = New-AutonomousPrompt -Errors $errors -Context "Improved autonomous system"
            
            if ($promptResult.Success) {
                Write-Host "✓ Generated prompt for $($promptResult.ErrorCount) errors" -ForegroundColor Green
                
                # Submit to Claude Code CLI with improved window detection
                $submissionResult = Submit-PromptToClaudeCode -Prompt $promptResult.Prompt
                
                if ($submissionResult.Success) {
                    Write-Host "🚀 SUCCESS! Prompt submitted to Claude Code CLI!" -ForegroundColor Green
                    Write-Host "  Target: $($submissionResult.TargetWindow)" -ForegroundColor Gray
                    Write-Host "  Length: $($submissionResult.PromptLength) characters" -ForegroundColor Gray
                    Write-Host "  Time: $($submissionResult.SubmissionTime)" -ForegroundColor Gray
                } else {
                    Write-Host "❌ Failed to submit prompt: $($submissionResult.Error)" -ForegroundColor Red
                }
            } else {
                Write-Host "❌ Failed to generate prompt: $($promptResult.Error)" -ForegroundColor Red
            }
            
        } catch {
            Write-Host "❌ Autonomous callback error: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host "================================" -ForegroundColor Green
    }
    
    # Start improved monitoring
    Write-Host "" -ForegroundColor White
    Write-Host "STARTING IMPROVED AUTONOMOUS MONITORING..." -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    
    $monitoringResult = Start-ReliableUnityMonitoring -OnErrorDetected $autonomousCallback
    
    if ($monitoringResult.Success) {
        # Log session details
        Add-ConversationHistoryEntry -SessionId $sessionId -Type "SystemAction" -Content "Improved autonomous system started with research-based fixes"
        Set-AutonomousState -AgentId $agentId -NewState "Active" -Reason "Improved autonomous operation with safe APIs"
        
        Write-Host "" -ForegroundColor White
        Write-Host "🚀 IMPROVED AUTONOMOUS SYSTEM IS LIVE! 🚀" -ForegroundColor Green
        Write-Host "=========================================" -ForegroundColor Green
        Write-Host "" -ForegroundColor White
        Write-Host "SYSTEM IMPROVEMENTS:" -ForegroundColor Cyan
        Write-Host "✓ Safe Unity console export (no assertion failures)" -ForegroundColor Green
        Write-Host "✓ Reliable PowerShell monitoring (FileWatcher + polling)" -ForegroundColor Green
        Write-Host "✓ Improved window detection (WindowsTerminal support)" -ForegroundColor Green
        Write-Host "✓ Fixed Alt+Tab automation with fallback" -ForegroundColor Green
        Write-Host "✓ Hybrid monitoring approach for maximum reliability" -ForegroundColor Green
        Write-Host "" -ForegroundColor White
        Write-Host "MONITORING STATUS:" -ForegroundColor Yellow
        Write-Host "• Method: $($monitoringResult.Method)" -ForegroundColor Gray
        Write-Host "• FileWatcher: $($monitoringResult.FileWatcher)" -ForegroundColor Gray
        Write-Host "• Polling backup: $($monitoringResult.Polling)" -ForegroundColor Gray
        Write-Host "• Session ID: $sessionId" -ForegroundColor Gray
        Write-Host "• Agent ID: $agentId" -ForegroundColor Gray
        Write-Host "" -ForegroundColor White
        Write-Host "TO TEST THE IMPROVED SYSTEM:" -ForegroundColor Cyan
        Write-Host "1. Open Unity (make sure SafeConsoleExporter.cs is in the project)" -ForegroundColor White
        Write-Host "2. Create a syntax error in any C# script" -ForegroundColor White
        Write-Host "3. Save the file to trigger compilation" -ForegroundColor White
        Write-Host "4. Watch for autonomous activity in Claude Code CLI" -ForegroundColor White
        Write-Host "" -ForegroundColor White
        Write-Host "The improved system will:" -ForegroundColor Yellow
        Write-Host "• Detect errors via safe Unity APIs (no crashes)" -ForegroundColor Gray
        Write-Host "• Monitor using reliable PowerShell techniques" -ForegroundColor Gray
        Write-Host "• Switch to Claude Code CLI automatically" -ForegroundColor Gray
        Write-Host "• Submit prompts for analysis" -ForegroundColor Gray
        Write-Host "" -ForegroundColor White
        Write-Host "🎯 RESEARCH-VALIDATED AUTONOMOUS OPERATION! 🎯" -ForegroundColor Green
        Write-Host "" -ForegroundColor White
        Write-Host "Press Ctrl+C to stop or Enter to continue monitoring..." -ForegroundColor Yellow
        
    } else {
        Write-Host "❌ Failed to start improved monitoring: $($monitoringResult.Error)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Error starting improved autonomy: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Details: $($_.Exception)" -ForegroundColor DarkRed
}

# Keep running
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8d8G2h/d//XzaTT8Z1VZcQjq
# 3y+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU2QienBIR9zF9Ph7iGfYS/bvFZh4wDQYJKoZIhvcNAQEBBQAEggEAlg/V
# 5/6gdJD6wDMEkroGZDb5lQ8r7xO/nomMRDbK2oLS8qSL3w6TReaCdEnpacnIy2tR
# 3qLoTAAiefe7Qqc5stiXh56EJplfbsX2DQu0NHX5BDiUQ2XNJc92Bm9XMa/G27iF
# u4zmRbS5754hNDa8DYckDgibTzuIDIsBbTYNrnZykRIpDGLFfOWGwsTvTqLjGE4d
# IbAlKkcghn+luTlZAKYUsqlWd5nl1PlYrXnrE2swqLLuiWoVYNMPfWXtOwVagXM/
# TqgRf2HXov9pFqAhY+LrREHbik1ZIpJHpTTPmx9lIo4DVThB62BzGl63tAbIKbzt
# 4bB/xq8yM/TgMVBFMg==
# SIG # End signature block
