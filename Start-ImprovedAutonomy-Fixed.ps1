# Start-ImprovedAutonomy-Fixed.ps1
# Improved autonomous system based on web research findings
# Uses safe Unity APIs and reliable PowerShell monitoring
# ASCII only, PowerShell 5.1 compatible
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "STARTING IMPROVED AUTONOMOUS SYSTEM" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host "Research-based improvements:" -ForegroundColor White
Write-Host "- Safe Unity console export (no LogEntries assertions)" -ForegroundColor Gray
Write-Host "- Reliable PowerShell monitoring (Register-ObjectEvent + polling)" -ForegroundColor Gray
Write-Host "- Hybrid file watching with fallback mechanisms" -ForegroundColor Gray
Write-Host "- Fixed window detection and Alt+Tab automation" -ForegroundColor Gray

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
    try {
        Get-EventSubscriber -ErrorAction SilentlyContinue | Where-Object { 
            $_.SourceObject -is [System.IO.FileSystemWatcher] -or 
            $_.SourceObject -is [System.Timers.Timer]
        } | ForEach-Object {
            try {
                Unregister-Event $_.SubscriptionId -Force -ErrorAction SilentlyContinue
            } catch {
                # Ignore disposal errors
            }
        }
    } catch {
        # Ignore any cleanup errors
    }
    
    # Load improved modules
    Write-Host "Loading improved modules..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-ReliableMonitoring.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-SessionManager.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-AutonomousStateTracker.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-ResponseMonitoring.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-RecompileSignaling.psm1" -Force
    Import-Module ".\Modules\Unity-Claude-WindowDetection.psm1" -Force
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
        Write-Host "  [+] Safe export file exists" -ForegroundColor Green
        Write-Host "    Modified: $($fileInfo.LastWriteTime)" -ForegroundColor Gray
        Write-Host "    Size: $($fileInfo.Length) bytes" -ForegroundColor Gray
    } else {
        Write-Host "  [!] Safe export file not found - Unity SafeConsoleExporter may not be running" -ForegroundColor Yellow
        Write-Host "    Expected: $safeExportPath" -ForegroundColor Gray
        Write-Host "    Make sure Unity is open with SafeConsoleExporter.cs" -ForegroundColor Yellow
    }
    
    # Define autonomous callback
    $autonomousCallback = {
        param($errors)
        
        Write-Host "" -ForegroundColor White
        Write-Host "[>] AUTONOMOUS SYSTEM TRIGGERED!" -ForegroundColor Green
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
                Write-Host "[+] Generated prompt for $($promptResult.ErrorCount) errors" -ForegroundColor Green
                
                # Submit to Claude Code CLI with improved window detection
                $submissionResult = Submit-PromptToClaudeCode -Prompt $promptResult.Prompt
                
                if ($submissionResult.Success) {
                    Write-Host "[>] SUCCESS! Prompt submitted to Claude Code CLI!" -ForegroundColor Green
                    Write-Host "  Target: $($submissionResult.TargetWindow)" -ForegroundColor Gray
                    Write-Host "  Length: $($submissionResult.PromptLength) characters" -ForegroundColor Gray
                    Write-Host "  Time: $($submissionResult.SubmissionTime)" -ForegroundColor Gray
                } else {
                    Write-Host "[-] Failed to submit prompt: $($submissionResult.Error)" -ForegroundColor Red
                }
            } else {
                Write-Host "[-] Failed to generate prompt: $($promptResult.Error)" -ForegroundColor Red
            }
            
        } catch {
            Write-Host "[-] Autonomous callback error: $($_.Exception.Message)" -ForegroundColor Red
        }
        
        Write-Host "================================" -ForegroundColor Green
    }
    
    # Define Claude response callback
    $responseCallback = {
        param($responses)
        
        Write-Host "" -ForegroundColor White
        Write-Host "[>] CLAUDE RESPONSE DETECTED!" -ForegroundColor Cyan
        Write-Host "=============================" -ForegroundColor Cyan
        Write-Host "Processing $($responses.Count) Claude responses" -ForegroundColor Yellow
        
        foreach ($response in $responses) {
            Write-Host "  Response: $($response.responseType) - $($response.summary)" -ForegroundColor White
            
            # Handle different response types
            switch ($response.responseType) {
                "Success" {
                    Write-Host "  [SUCCESS] Claude fixed the issues!" -ForegroundColor Green
                    Write-Host "  Actions: $($response.actionsTaken -join ', ')" -ForegroundColor Gray
                    # TODO: Verify Unity compilation status
                }
                "Partial" {
                    Write-Host "  [PARTIAL] Some issues resolved, monitoring for more" -ForegroundColor Yellow
                    if ($response.remainingIssues) {
                        Write-Host "  Remaining: $($response.remainingIssues -join ', ')" -ForegroundColor Red
                    }
                }
                "Failed" {
                    Write-Host "  [FAILED] Claude could not resolve issues" -ForegroundColor Red
                    Write-Host "  May need manual intervention" -ForegroundColor Yellow
                }
                "Questions" {
                    Write-Host "  [QUESTIONS] Claude needs clarification" -ForegroundColor Cyan
                    Write-Host "  May need additional context" -ForegroundColor Yellow
                }
                "Instructions" {
                    Write-Host "  [INSTRUCTIONS] Manual steps required" -ForegroundColor Magenta
                    if ($response.recommendations) {
                        Write-Host "  Steps: $($response.recommendations -join ', ')" -ForegroundColor Gray
                    }
                }
            }
            
            if ($response.requiresFollowUp) {
                Write-Host "  [FOLLOW-UP] Additional action needed" -ForegroundColor Yellow
            }
        }
        
        Write-Host "=============================" -ForegroundColor Cyan
    }
    
    # Start improved monitoring
    Write-Host "" -ForegroundColor White
    Write-Host "STARTING IMPROVED AUTONOMOUS MONITORING..." -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    
    $monitoringResult = Start-ReliableUnityMonitoring -OnErrorDetected $autonomousCallback
    
    # Start Claude response monitoring
    Write-Host "Starting Claude response monitoring..." -ForegroundColor Yellow
    $responseMonitoringResult = Start-ClaudeResponseMonitoring -OnResponseDetected $responseCallback
    
    if ($responseMonitoringResult.Success) {
        Write-Host "[+] Claude response monitoring started!" -ForegroundColor Green
        Write-Host "  Method: $($responseMonitoringResult.Method)" -ForegroundColor Gray
        Write-Host "  FileWatcher: $($responseMonitoringResult.FileWatcher)" -ForegroundColor Gray
        Write-Host "  Polling: $($responseMonitoringResult.Polling)" -ForegroundColor Gray
    } else {
        Write-Host "[-] Claude response monitoring failed: $($responseMonitoringResult.Error)" -ForegroundColor Red
    }
    
    # Start recompilation signal monitoring
    Write-Host "Starting Unity recompilation signal monitoring..." -ForegroundColor Yellow
    $signalMonitoringResult = Start-RecompileSignalMonitoring
    
    if ($signalMonitoringResult.Success) {
        Write-Host "[+] Recompilation signal monitoring started!" -ForegroundColor Green
    } else {
        Write-Host "[-] Recompilation signal monitoring failed: $($signalMonitoringResult.Error)" -ForegroundColor Red
    }
    
    if ($monitoringResult.Success) {
        # Log session details
        Add-ConversationHistoryEntry -SessionId $sessionId -Type "SystemAction" -Content "Improved autonomous system started with research-based fixes"
        Set-AutonomousState -AgentId $agentId -NewState "Active" -Reason "Improved autonomous operation with safe APIs"
        
        Write-Host "" -ForegroundColor White
        Write-Host "[>] IMPROVED AUTONOMOUS SYSTEM IS LIVE!" -ForegroundColor Green
        Write-Host "========================================" -ForegroundColor Green
        Write-Host "" -ForegroundColor White
        Write-Host "SYSTEM IMPROVEMENTS:" -ForegroundColor Cyan
        Write-Host "[+] Safe Unity console export (no assertion failures)" -ForegroundColor Green
        Write-Host "[+] Reliable PowerShell monitoring (FileWatcher + polling)" -ForegroundColor Green
        Write-Host "[+] Improved window detection (WindowsTerminal support)" -ForegroundColor Green
        Write-Host "[+] Fixed Alt+Tab automation with fallback" -ForegroundColor Green
        Write-Host "[+] Hybrid monitoring approach for maximum reliability" -ForegroundColor Green
        Write-Host "[+] Complete feedback loop with Claude response monitoring" -ForegroundColor Green
        Write-Host "[+] Automatic Unity recompilation triggering (Unity 2021.1.14f1)" -ForegroundColor Green
        Write-Host "[+] Intelligent Claude Code CLI window detection" -ForegroundColor Green
        Write-Host "" -ForegroundColor White
        Write-Host "MONITORING STATUS:" -ForegroundColor Yellow
        Write-Host "- Unity Error Method: $($monitoringResult.Method)" -ForegroundColor Gray
        Write-Host "- Unity FileWatcher: $($monitoringResult.FileWatcher)" -ForegroundColor Gray
        Write-Host "- Unity Polling backup: $($monitoringResult.Polling)" -ForegroundColor Gray
        Write-Host "- Claude Response Monitoring: $($responseMonitoringResult.Success)" -ForegroundColor Gray
        Write-Host "- Response FileWatcher: $($responseMonitoringResult.FileWatcher)" -ForegroundColor Gray
        Write-Host "- Unity Recompile Signaling: $($signalMonitoringResult.Success)" -ForegroundColor Gray
        Write-Host "- Session ID: $sessionId" -ForegroundColor Gray
        Write-Host "- Agent ID: $agentId" -ForegroundColor Gray
        Write-Host "" -ForegroundColor White
        Write-Host "TO TEST THE IMPROVED SYSTEM:" -ForegroundColor Cyan
        Write-Host "1. Open Unity (make sure SafeConsoleExporter.cs is in the project)" -ForegroundColor White
        Write-Host "2. Create a syntax error in any C# script" -ForegroundColor White
        Write-Host "3. Save the file to trigger compilation" -ForegroundColor White
        Write-Host "4. Watch for autonomous activity in Claude Code CLI" -ForegroundColor White
        Write-Host "" -ForegroundColor White
        Write-Host "The improved system will:" -ForegroundColor Yellow
        Write-Host "- Detect errors via safe Unity APIs (no crashes)" -ForegroundColor Gray
        Write-Host "- Monitor using reliable PowerShell techniques" -ForegroundColor Gray
        Write-Host "- Switch to Claude Code CLI automatically" -ForegroundColor Gray
        Write-Host "- Submit prompts for analysis" -ForegroundColor Gray
        Write-Host "- Monitor Claude responses for completion feedback" -ForegroundColor Gray
        Write-Host "- Take action based on response success/failure" -ForegroundColor Gray
        Write-Host "" -ForegroundColor White
        Write-Host "COMPLETE FEEDBACK LOOP:" -ForegroundColor Cyan
        Write-Host "Unity Error -> Autonomous System -> Claude Code CLI -> Response Monitor -> Action" -ForegroundColor Gray
        Write-Host "" -ForegroundColor White
        Write-Host "[>] RESEARCH-VALIDATED AUTONOMOUS OPERATION!" -ForegroundColor Green
        Write-Host "" -ForegroundColor White
        Write-Host "Press Ctrl+C to stop or Enter to continue monitoring..." -ForegroundColor Yellow
        
    } else {
        Write-Host "[-] Failed to start improved monitoring: $($monitoringResult.Error)" -ForegroundColor Red
    }
    
} catch {
    Write-Host "Error starting improved autonomy: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Details: $($_.Exception)" -ForegroundColor DarkRed
}

# Keep running with non-blocking loop to allow FileSystemWatcher events
Write-Host "" -ForegroundColor White
Write-Host "AUTONOMOUS MONITORING ACTIVE - Press Ctrl+C to stop" -ForegroundColor Green
Write-Host "Waiting for Unity errors to be detected..." -ForegroundColor Gray

try {
    # Non-blocking loop that allows FileSystemWatcher events to process
    while ($true) {
        Start-Sleep -Seconds 1
        
        # Optional: Show periodic heartbeat
        $timestamp = Get-Date -Format "HH:mm:ss"
        Write-Host "." -NoNewline -ForegroundColor DarkGray
        
        # Clear line every 60 dots (1 minute)
        if ((Get-Date).Second -eq 0) {
            Write-Host "" -ForegroundColor White
            Write-Host "[$timestamp] Monitoring active - waiting for Unity errors..." -ForegroundColor DarkGray
        }
    }
} catch [System.Management.Automation.PipelineStoppedException] {
    # Ctrl+C was pressed
    Write-Host "" -ForegroundColor White
    Write-Host "Stopping autonomous monitoring..." -ForegroundColor Yellow
} finally {
    # Cleanup monitoring
    try {
        Stop-ReliableUnityMonitoring -ErrorAction SilentlyContinue
        Stop-ClaudeResponseMonitoring -ErrorAction SilentlyContinue
        Stop-RecompileSignalMonitoring -ErrorAction SilentlyContinue
        Write-Host "Autonomous monitoring stopped" -ForegroundColor Green
    } catch {
        Write-Host "Cleanup completed" -ForegroundColor Gray
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUIWbYeq4fyexWYvL+pcrVjNqp
# QLqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUANmoBXYZElpFB00+DwpFjaNDny0wDQYJKoZIhvcNAQEBBQAEggEApWpR
# 9GcWY1RlxB3m7GmJX9WA0ZNE8rxPrvCK1yRPgrANKjlsxgopLY5+x01ab5oEJfnN
# r+OO05aXcCkZnvP5eBzrYgTFeW2E/BmbK9FarBxIWKtkSjREvXpWLJvhrTI1efX4
# xD9oiKKi00ukYxZS2t/YP3/CDwhDpiO+mqlVZgGt51KDHcP30ex3uoFIf1M8F4ZX
# SyTBR71e2qbL17sH4+C+AZc/+XV3hOVOSDJ+RQ1J53ITu/QfOrb5Quj0p9PPOOBj
# 8u0v5fKjyihhhPjweJKi8krJ6lDgLUA4LvUDXm5URrB1E2ZKDMTl1fFNWjUw0FLL
# E1uwKTZmuHeMXcbWLQ==
# SIG # End signature block
