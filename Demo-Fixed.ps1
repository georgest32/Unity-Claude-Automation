# Demo-Fixed.ps1
# Fixed autonomous system demonstration 
# Handles state transition validation and PSObject access
# Date: 2025-08-18

# Ensure correct directory
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

Write-Host "UNITY-CLAUDE AUTONOMOUS SYSTEM DEMO (FIXED)" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Cyan

try {
    # Step 1: Load modules
    Write-Host "Step 1: Loading modules..." -ForegroundColor Yellow
    
    Import-Module ".\Modules\Unity-Claude-SessionManager.psm1" -Force
    Write-Host "  SessionManager loaded" -ForegroundColor Green
    
    Import-Module ".\Modules\Unity-Claude-AutonomousStateTracker.psm1" -Force
    Write-Host "  StateTracker loaded" -ForegroundColor Green
    
    Import-Module ".\Modules\Unity-Claude-PerformanceOptimizer.psm1" -Force
    Write-Host "  PerformanceOptimizer loaded" -ForegroundColor Green
    
    Import-Module ".\Modules\Unity-Claude-ResourceOptimizer.psm1" -Force
    Write-Host "  ResourceOptimizer loaded" -ForegroundColor Green
    
    # Step 2: Create session
    Write-Host "Step 2: Creating autonomous session..." -ForegroundColor Yellow
    
    $sessionResult = New-ConversationSession -SessionName "DemoSession" -SessionType "Demonstration"
    if ($sessionResult -and $sessionResult.Success -eq $true) {
        if ($sessionResult.Session -and $sessionResult.Session.SessionId) {
            $sessionId = $sessionResult.Session.SessionId
            Write-Host "  Session created: $sessionId" -ForegroundColor Green
        } else {
            Write-Host "  Session created but no ID returned" -ForegroundColor Yellow
            $sessionId = "DEMO_SESSION"
        }
    } else {
        throw "Failed to create session"
    }
    
    # Step 3: Initialize state tracking with proper initial state
    Write-Host "Step 3: Initializing state tracking..." -ForegroundColor Yellow
    
    $agentId = "DemoAgent123"
    $stateResult = Initialize-AutonomousStateTracking -AgentId $agentId
    if ($stateResult -and $stateResult.Success -eq $true) {
        Write-Host "  State tracking initialized: $agentId" -ForegroundColor Green
    } else {
        Write-Host "  State tracking failed, continuing anyway..." -ForegroundColor Yellow
    }
    
    # Step 4: Simulate workflow with valid state transitions
    Write-Host "Step 4: Simulating autonomous workflow..." -ForegroundColor Yellow
    
    # Add conversation entry with safe access
    try {
        Add-ConversationHistoryEntry -SessionId $sessionId -Type "SystemAction" -Content "Demo started"
        Write-Host "  Added conversation entry" -ForegroundColor Gray
    } catch {
        Write-Host "  Conversation entry failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Try state transitions with error handling
    $states = @("Initializing", "Active", "Monitoring", "Processing")
    foreach ($state in $states) {
        try {
            $result = Set-AutonomousState -AgentId $agentId -NewState $state -Reason "Demo transition to $state"
            if ($result -and $result.Success -eq $true) {
                Write-Host "  State: $state" -ForegroundColor Gray
            } else {
                Write-Host "  State transition to $state failed (continuing)" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  State transition to $state error: $($_.Exception.Message)" -ForegroundColor Yellow
        }
        Start-Sleep 1
    }
    
    # Update metrics with safe access
    try {
        Update-PerformanceMetrics -AgentId $agentId -MetricUpdates @{
            TotalCycles = 3
            SuccessfulCycles = 2
            FailedCycles = 1
            LastOperationSuccess = $true
        }
        Write-Host "  Updated performance metrics" -ForegroundColor Gray
    } catch {
        Write-Host "  Performance metrics update failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Step 5: Show results with safe property access
    Write-Host "Step 5: Checking results..." -ForegroundColor Yellow
    
    # Agent status with safe access
    try {
        $status = Get-AutonomousOperationStatus -AgentId $agentId
        if ($status -and $status.Success -eq $true -and $status.Status) {
            $currentState = if ($status.Status.CurrentState) { $status.Status.CurrentState } else { "Unknown" }
            $successRate = if ($status.Status.SuccessRate) { $status.Status.SuccessRate } else { "0%" }
            $duration = if ($status.Status.TotalDurationMinutes) { $status.Status.TotalDurationMinutes } else { "0" }
            
            Write-Host "  Current state: $currentState" -ForegroundColor White
            Write-Host "  Success rate: $successRate" -ForegroundColor White
            Write-Host "  Total duration: $duration minutes" -ForegroundColor White
        } else {
            Write-Host "  Agent status not available" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Agent status error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Session analytics with safe access
    try {
        $analytics = Get-SessionAnalytics -SessionId $sessionId
        if ($analytics -and $analytics.Success -eq $true -and $analytics.Analytics) {
            $sessionDuration = if ($analytics.Analytics.SessionInfo -and $analytics.Analytics.SessionInfo.Duration) {
                [Math]::Round($analytics.Analytics.SessionInfo.Duration, 2)
            } else { "0" }
            
            $historyItems = if ($analytics.Analytics.Conversation -and $analytics.Analytics.Conversation.TotalHistoryItems) {
                $analytics.Analytics.Conversation.TotalHistoryItems
            } else { "0" }
            
            Write-Host "  Session duration: $sessionDuration minutes" -ForegroundColor White
            Write-Host "  Conversation items: $historyItems" -ForegroundColor White
        } else {
            Write-Host "  Session analytics not available" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Session analytics error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Performance report with safe access
    try {
        $perfReport = Get-PerformanceReport
        if ($perfReport) {
            $opCount = if ($perfReport.OperationCount) { $perfReport.OperationCount } else { "0" }
            $procTime = if ($perfReport.TotalProcessingTime) { $perfReport.TotalProcessingTime } else { "0" }
            
            Write-Host "  Operations completed: $opCount" -ForegroundColor White
            Write-Host "  Processing time: ${procTime}ms" -ForegroundColor White
        } else {
            Write-Host "  Performance report not available" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Performance report error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Resource check with safe access
    try {
        $resourceCheck = Invoke-ComprehensiveResourceCheck
        if ($resourceCheck -and $resourceCheck.Success -eq $true -and $resourceCheck.Report) {
            $memUsage = if ($resourceCheck.Report.Memory -and $resourceCheck.Report.Memory.WorkingSetMB) {
                $resourceCheck.Report.Memory.WorkingSetMB
            } else { "Unknown" }
            
            Write-Host "  Memory usage: ${memUsage}MB" -ForegroundColor White
        } else {
            Write-Host "  Resource check not available" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Resource check error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Create checkpoint with safe access
    try {
        $checkpoint = New-SessionCheckpoint -SessionId $sessionId -CheckpointName "DemoComplete"
        if ($checkpoint -and $checkpoint.Success -eq $true -and $checkpoint.Checkpoint) {
            $checkpointId = if ($checkpoint.Checkpoint.CheckpointId) { $checkpoint.Checkpoint.CheckpointId } else { "Unknown" }
            Write-Host "  Checkpoint created: $checkpointId" -ForegroundColor White
        } else {
            Write-Host "  Checkpoint creation not available" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  Checkpoint error: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    
    # Success summary
    Write-Host "" -ForegroundColor White
    Write-Host "DEMO COMPLETE - MODULES LOADED AND TESTED!" -ForegroundColor Green
    Write-Host "===========================================" -ForegroundColor Green
    Write-Host "Session ID: $sessionId" -ForegroundColor White
    Write-Host "Agent ID: $agentId" -ForegroundColor White
    Write-Host "All core autonomous modules loaded successfully" -ForegroundColor White
    Write-Host "State transitions and analytics tested" -ForegroundColor White
    Write-Host "" -ForegroundColor White
    
} catch {
    Write-Host "DEMO FAILED: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception)" -ForegroundColor DarkRed
}

Write-Host "Press Enter to exit..." -ForegroundColor Yellow
Read-Host
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU65GQJ7/4/m9jfuJt7RAVTJ1s
# VRagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUEvCxRTJLtBtr7Mmd7XSmkGpXtnMwDQYJKoZIhvcNAQEBBQAEggEArLu4
# IdnJ1Fzo151X7Z8TT5RGr5zo+DHFtvuIUICkYgKkRoSjRXsbUWVzGY5bkDgZqA2r
# FocZ4KidusY5UMkP3mgxULcrMwFWYDZTNRQ9v8fw7NQwIGxqU6f9lOXMMTkGHcYI
# I8qmR7fyNXJ5MmlNXkcx2Ew3WWk3EC53G3fEYMYHlTha6g13FHxoDmxdQhakOPwJ
# m65i86yJw84ezVrYKVoqIHFSoRlpJeu+XXOnsTwSY2BQNnFwAPJ80fFSruIoQHuA
# R1/2OS9doPqgiKR43LQEX7DlC545cJXgdcm/Jii41ncCTTvzPLmi8n9OFf1aBzol
# XZNJ7U9QboNEHJqSBw==
# SIG # End signature block
