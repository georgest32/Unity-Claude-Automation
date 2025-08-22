# Test-ResponseMonitoring.ps1
# Test the Claude response monitoring system
# Date: 2025-08-18

Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "TESTING CLAUDE RESPONSE MONITORING" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan

# Load the response monitoring module
Import-Module ".\Modules\Unity-Claude-ResponseMonitoring.psm1" -Force

# Define response callback
$responseCallback = {
    param($responses)
    
    Write-Host "" -ForegroundColor White
    Write-Host "[>] CLAUDE RESPONSE DETECTED!" -ForegroundColor Green
    Write-Host "=============================" -ForegroundColor Green
    Write-Host "Detected $($responses.Count) new Claude responses" -ForegroundColor Yellow
    
    foreach ($response in $responses) {
        Write-Host "" -ForegroundColor White
        Write-Host "Response Details:" -ForegroundColor Cyan
        Write-Host "  Session: $($response.sessionId)" -ForegroundColor Gray
        Write-Host "  Type: $($response.responseType)" -ForegroundColor Gray
        Write-Host "  Confidence: $($response.confidence)" -ForegroundColor Gray
        Write-Host "  Timestamp: $($response.timestamp)" -ForegroundColor Gray
        Write-Host "  Summary: $($response.summary)" -ForegroundColor White
        
        if ($response.actionsTaken -and $response.actionsTaken.Count -gt 0) {
            Write-Host "  Actions Taken:" -ForegroundColor Green
            foreach ($action in $response.actionsTaken) {
                Write-Host "    - $action" -ForegroundColor Gray
            }
        }
        
        if ($response.remainingIssues -and $response.remainingIssues.Count -gt 0) {
            Write-Host "  Remaining Issues:" -ForegroundColor Red
            foreach ($issue in $response.remainingIssues) {
                Write-Host "    - $issue" -ForegroundColor Gray
            }
        }
        
        if ($response.recommendations -and $response.recommendations.Count -gt 0) {
            Write-Host "  Recommendations:" -ForegroundColor Yellow
            foreach ($recommendation in $response.recommendations) {
                Write-Host "    - $recommendation" -ForegroundColor Gray
            }
        }
        
        # Response-specific actions
        switch ($response.responseType) {
            "Success" {
                Write-Host "  [SUCCESS] Claude successfully resolved the issues!" -ForegroundColor Green
                Write-Host "  Next: Verify Unity compilation and continue monitoring" -ForegroundColor Green
            }
            "Partial" {
                Write-Host "  [PARTIAL] Some issues resolved, others remain" -ForegroundColor Yellow
                Write-Host "  Next: Monitor for additional errors or follow-up actions" -ForegroundColor Yellow
            }
            "Failed" {
                Write-Host "  [FAILED] Claude could not resolve the issues" -ForegroundColor Red
                Write-Host "  Next: Manual intervention required" -ForegroundColor Red
            }
            "Questions" {
                Write-Host "  [QUESTIONS] Claude needs clarification" -ForegroundColor Cyan
                Write-Host "  Next: Provide additional context and resubmit" -ForegroundColor Cyan
            }
            "Instructions" {
                Write-Host "  [INSTRUCTIONS] Manual steps required" -ForegroundColor Magenta
                Write-Host "  Next: Follow provided instructions" -ForegroundColor Magenta
            }
        }
        
        if ($response.requiresFollowUp) {
            Write-Host "  [FOLLOW-UP REQUIRED] Additional action needed" -ForegroundColor Yellow
        }
    }
    
    Write-Host "=============================" -ForegroundColor Green
}

# Start response monitoring
Write-Host "Starting Claude response monitoring..." -ForegroundColor Yellow
$monitorResult = Start-ClaudeResponseMonitoring -OnResponseDetected $responseCallback

if ($monitorResult.Success) {
    Write-Host "[+] Response monitoring started successfully!" -ForegroundColor Green
    Write-Host "    Method: $($monitorResult.Method)" -ForegroundColor Gray
    Write-Host "    FileWatcher: $($monitorResult.FileWatcher)" -ForegroundColor Gray
    Write-Host "    Polling: $($monitorResult.Polling)" -ForegroundColor Gray
    
    # Get status
    $status = Get-ResponseMonitoringStatus
    Write-Host "" -ForegroundColor White
    Write-Host "Current monitoring status:" -ForegroundColor Yellow
    Write-Host "    FileWatcherActive: $($status.FileWatcherActive)" -ForegroundColor Gray
    Write-Host "    PollingActive: $($status.PollingActive)" -ForegroundColor Gray
    Write-Host "    EventSubscriptions: $($status.EventSubscriptions)" -ForegroundColor Gray
    Write-Host "    LastResponseCount: $($status.LastResponseCount)" -ForegroundColor Gray
    Write-Host "    LastSessionId: $($status.LastSessionId)" -ForegroundColor Gray
    
    Write-Host "" -ForegroundColor White
    Write-Host "TESTING INSTRUCTIONS:" -ForegroundColor Cyan
    Write-Host "1. Keep this window open" -ForegroundColor White
    Write-Host "2. In Claude Code CLI, run:" -ForegroundColor White
    Write-Host "   .\Claude-ResponseExporter.ps1 -Interactive" -ForegroundColor Gray
    Write-Host "3. Or export a test response:" -ForegroundColor White
    Write-Host "   .\Claude-ResponseExporter.ps1 -ResponseType 'Success' -Summary 'Test response'" -ForegroundColor Gray
    Write-Host "4. Watch for callback activity here" -ForegroundColor White
    
    Write-Host "" -ForegroundColor White
    Write-Host "Monitoring for responses for 60 seconds..." -ForegroundColor Yellow
    
    for ($i = 60; $i -gt 0; $i--) {
        Write-Host "." -NoNewline -ForegroundColor Gray
        Start-Sleep 1
        
        # Manual test trigger at 30 seconds
        if ($i -eq 30) {
            Write-Host "" -ForegroundColor White
            Write-Host "[TEST] Creating test response to trigger detection..." -ForegroundColor Magenta
            
            # Create a test response
            & ".\Claude-ResponseExporter.ps1" -ResponseType "Partial" -Summary "Test response from monitoring system" -ActionsTaken @("Created test response") -RequiresFollowUp $true -Confidence "Medium"
        }
    }
    
    # Stop monitoring
    Write-Host "" -ForegroundColor White
    Write-Host "Stopping response monitoring..." -ForegroundColor Yellow
    Stop-ClaudeResponseMonitoring
    Write-Host "[+] Response monitoring stopped" -ForegroundColor Green
    
} else {
    Write-Host "[-] Failed to start response monitoring: $($monitorResult.Error)" -ForegroundColor Red
}

Write-Host "" -ForegroundColor White
Write-Host "Response monitoring test complete. Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnuXkbr2CCaBeQ0v8jcRTNbvF
# ysmgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUI3oGCOkb4NCS98fhe0yI5JO/aQYwDQYJKoZIhvcNAQEBBQAEggEAmxcU
# myUATRwTxcfBFd6fQfB9dLZXTzHe0ljTq0lOR+nNw2AyBxdkCpgggL/XTdUnvjbr
# f/MAl7LCviAIxUMYuOg6rlJ5wZtg422w25jB+YpcUt7Sx2vmw2RWbbXNCbsxfCOi
# HIrOa8FKwZk9iQkYWvUKvxEUSLdzJI3pZLeGuE1nGDkCfi7O0Bomyu2cTHXgRYUU
# wtVT+J6VXZa63/uJ61RdIbsX0O0Ttk8o0kNZxqAFTMsEdvPUTxgzNcHSPZucygV5
# l3UyzSqvtjAZ8ED+VA2Ej9r6lpA+sg5H6V++T3lr+KCGfBZlg10mWpGVZ9KkfgMq
# M7L/rlUQc80Sfu/Gkg==
# SIG # End signature block
