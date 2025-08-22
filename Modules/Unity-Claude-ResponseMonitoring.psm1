# Unity-Claude-ResponseMonitoring.psm1
# Monitor Claude Code CLI responses for autonomous feedback loop completion
# Date: 2025-08-18

#region Module Initialization
$ErrorActionPreference = "Stop"

Write-Host "[ResponseMonitoring] Loading Claude response monitoring module..." -ForegroundColor Cyan

# Module configuration
$script:ResponseConfig = @{
    # File paths
    ResponseJsonPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\claude_responses.json"
    
    # Monitoring settings
    FileReadRetryCount = 3
    FileReadRetryDelayMs = 500
    
    # Response tracking
    LastResponseCount = 0
    LastResponseTime = [DateTime]::MinValue
    LastSessionId = ""
}

# Global variables for monitoring
$script:ResponseWatcher = $null
$script:ResponsePollingTimer = $null
$script:ResponseEventSubscriptions = @()
$script:OnResponseCallback = $null

Write-Host "[ResponseMonitoring] Claude response monitoring module loaded successfully" -ForegroundColor Green

#endregion

#region Response File Reading Functions

function Read-SafeResponseFile {
    <#
    .SYNOPSIS
    Safely reads and parses Claude response JSON file with retry logic
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    for ($retry = 0; $retry -lt $script:ResponseConfig.FileReadRetryCount; $retry++) {
        try {
            if (-not (Test-Path $FilePath)) {
                return $null
            }
            
            $content = Get-Content $FilePath -Raw -ErrorAction Stop -Encoding UTF8
            if ([string]::IsNullOrEmpty($content)) {
                return $null
            }
            
            # Remove BOM if present
            if ($content[0] -eq [char]0xFEFF) {
                $content = $content.Substring(1)
            }
            
            $jsonData = $content | ConvertFrom-Json
            return $jsonData
            
        } catch {
            Write-Host "[ResponseMonitoring] File read attempt $($retry + 1) failed: $($_.Exception.Message)" -ForegroundColor Yellow
            
            if ($retry -lt ($script:ResponseConfig.FileReadRetryCount - 1)) {
                Start-Sleep -Milliseconds $script:ResponseConfig.FileReadRetryDelayMs
            }
        }
    }
    
    Write-Host "[ResponseMonitoring] Failed to read response file after $($script:ResponseConfig.FileReadRetryCount) attempts" -ForegroundColor Red
    return $null
}

function Test-ResponseFileChanged {
    <#
    .SYNOPSIS
    Checks if the Claude response file has been updated
    #>
    [CmdletBinding()]
    param()
    
    try {
        if (-not (Test-Path $script:ResponseConfig.ResponseJsonPath)) {
            return $false
        }
        
        $fileInfo = Get-Item $script:ResponseConfig.ResponseJsonPath
        
        # Check if file was modified since last check
        if ($fileInfo.LastWriteTime -gt $script:ResponseConfig.LastResponseTime) {
            # Read and check response count
            $responseData = Read-SafeResponseFile -FilePath $script:ResponseConfig.ResponseJsonPath
            if ($responseData -and $responseData.totalResponses -gt $script:ResponseConfig.LastResponseCount) {
                $script:ResponseConfig.LastResponseTime = $fileInfo.LastWriteTime
                return $true
            }
        }
        
        return $false
        
    } catch {
        Write-Host "[ResponseMonitoring] Error checking response file changes: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

#endregion

#region Response Processing Functions

function Process-ClaudeResponse {
    <#
    .SYNOPSIS
    Processes new Claude responses and triggers appropriate actions
    #>
    [CmdletBinding()]
    param()
    
    try {
        $responseData = Read-SafeResponseFile -FilePath $script:ResponseConfig.ResponseJsonPath
        
        if (-not $responseData) {
            return
        }
        
        $currentResponseCount = if ($responseData.totalResponses) { $responseData.totalResponses } else { 0 }
        
        # Only process if we have new responses
        if ($currentResponseCount -gt $script:ResponseConfig.LastResponseCount) {
            Write-Host "[ResponseMonitoring] Detected $($currentResponseCount - $script:ResponseConfig.LastResponseCount) new Claude responses" -ForegroundColor Yellow
            
            # Get new responses (responses added since last check)
            $responseList = $responseData.PSObject.Properties['responses'].Value
            if ($responseList) {
                $newResponses = @()
                
                # Get only the new responses (from last count to current)
                for ($i = $script:ResponseConfig.LastResponseCount; $i -lt $currentResponseCount; $i++) {
                    if ($i -lt $responseList.Count) {
                        $newResponses += $responseList[$i]
                    }
                }
                
                # Update tracking
                $script:ResponseConfig.LastResponseCount = $currentResponseCount
                $script:ResponseConfig.LastSessionId = $responseData.lastSessionId
                
                # Trigger callback for each new response
                if ($script:OnResponseCallback -and $newResponses.Count -gt 0) {
                    Write-Host "[ResponseMonitoring] Triggering response callback for $($newResponses.Count) responses" -ForegroundColor Green
                    & $script:OnResponseCallback $newResponses
                }
            }
            
        } elseif ($currentResponseCount -eq 0 -and $script:ResponseConfig.LastResponseCount -gt 0) {
            Write-Host "[ResponseMonitoring] Response file cleared/reset" -ForegroundColor Green
            $script:ResponseConfig.LastResponseCount = 0
        }
        
    } catch {
        Write-Host "[ResponseMonitoring] Error processing Claude responses: $($_.Exception.Message)" -ForegroundColor Red
    }
}

#endregion

#region Response Monitoring Functions

function Start-ResponseFileWatcher {
    <#
    .SYNOPSIS
    Starts FileSystemWatcher for Claude response file
    #>
    [CmdletBinding()]
    param()
    
    try {
        $watchDirectory = Split-Path $script:ResponseConfig.ResponseJsonPath -Parent
        
        # Ensure directory exists
        if (-not (Test-Path $watchDirectory)) {
            New-Item -ItemType Directory -Path $watchDirectory -Force | Out-Null
        }
        
        $script:ResponseWatcher = New-Object System.IO.FileSystemWatcher
        $script:ResponseWatcher.Path = $watchDirectory
        $script:ResponseWatcher.Filter = "claude_responses.json"
        $script:ResponseWatcher.IncludeSubdirectories = $false
        $script:ResponseWatcher.EnableRaisingEvents = $true
        
        # Register events using Register-ObjectEvent (reliable approach)
        $changeAction = {
            Write-Host "[ResponseWatcher] Claude response file change detected" -ForegroundColor Cyan
            
            # Call the processing function with proper scope access
            $moduleName = "Unity-Claude-ResponseMonitoring"
            $module = Get-Module $moduleName
            if ($module) {
                & $module { Process-ClaudeResponse }
            }
        }
        
        $createdEvent = Register-ObjectEvent -InputObject $script:ResponseWatcher -EventName "Created" -Action $changeAction
        $changedEvent = Register-ObjectEvent -InputObject $script:ResponseWatcher -EventName "Changed" -Action $changeAction
        
        $script:ResponseEventSubscriptions += $createdEvent
        $script:ResponseEventSubscriptions += $changedEvent
        
        Write-Host "[ResponseMonitoring] FileSystemWatcher started on: $watchDirectory" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "[ResponseMonitoring] Failed to start response FileSystemWatcher: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Stop-ResponseFileWatcher {
    <#
    .SYNOPSIS
    Stops response FileSystemWatcher and cleans up events
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Unregister events
        foreach ($subscription in $script:ResponseEventSubscriptions) {
            Unregister-Event -SubscriptionId $subscription.Id -Force -ErrorAction SilentlyContinue
        }
        $script:ResponseEventSubscriptions = @()
        
        # Dispose FileSystemWatcher
        if ($script:ResponseWatcher) {
            $script:ResponseWatcher.EnableRaisingEvents = $false
            $script:ResponseWatcher.Dispose()
            $script:ResponseWatcher = $null
        }
        
        Write-Host "[ResponseMonitoring] Response FileSystemWatcher stopped and cleaned up" -ForegroundColor Yellow
        
    } catch {
        Write-Host "[ResponseMonitoring] Error stopping response FileSystemWatcher: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Start-ResponsePollingTimer {
    <#
    .SYNOPSIS
    Starts polling timer as backup for response file monitoring
    #>
    [CmdletBinding()]
    param()
    
    try {
        $script:ResponsePollingTimer = New-Object System.Timers.Timer
        $script:ResponsePollingTimer.Interval = 5000  # 5 seconds for responses
        $script:ResponsePollingTimer.AutoReset = $true
        
        # Register timer event
        $timerAction = {
            if (Test-ResponseFileChanged) {
                Write-Host "[ResponsePollingTimer] Response file change detected via polling" -ForegroundColor Magenta
                
                # Call the processing function with proper scope access
                $moduleName = "Unity-Claude-ResponseMonitoring"
                $module = Get-Module $moduleName
                if ($module) {
                    & $module { Process-ClaudeResponse }
                }
            }
        }
        
        $timerEvent = Register-ObjectEvent -InputObject $script:ResponsePollingTimer -EventName "Elapsed" -Action $timerAction
        $script:ResponseEventSubscriptions += $timerEvent
        
        $script:ResponsePollingTimer.Start()
        
        Write-Host "[ResponseMonitoring] Response polling timer started (interval: 5s)" -ForegroundColor Green
        
    } catch {
        Write-Host "[ResponseMonitoring] Failed to start response polling timer: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Stop-ResponsePollingTimer {
    <#
    .SYNOPSIS
    Stops response polling timer
    #>
    [CmdletBinding()]
    param()
    
    try {
        if ($script:ResponsePollingTimer) {
            $script:ResponsePollingTimer.Stop()
            $script:ResponsePollingTimer.Dispose()
            $script:ResponsePollingTimer = $null
        }
        
        Write-Host "[ResponseMonitoring] Response polling timer stopped" -ForegroundColor Yellow
        
    } catch {
        Write-Host "[ResponseMonitoring] Error stopping response polling timer: $($_.Exception.Message)" -ForegroundColor Red
    }
}

#endregion

#region Public Interface

function Start-ClaudeResponseMonitoring {
    <#
    .SYNOPSIS
    Starts monitoring Claude Code CLI responses for autonomous feedback loop
    
    .PARAMETER OnResponseDetected
    Script block to execute when new responses are detected
    
    .EXAMPLE
    Start-ClaudeResponseMonitoring -OnResponseDetected { param($responses) Process-ClaudeResponses $responses }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$OnResponseDetected
    )
    
    Write-Host "[ResponseMonitoring] Starting Claude response monitoring..." -ForegroundColor Yellow
    
    # Store callback
    $script:OnResponseCallback = $OnResponseDetected
    
    # Initialize baseline state
    $responseData = Read-SafeResponseFile -FilePath $script:ResponseConfig.ResponseJsonPath
    if ($responseData) {
        $script:ResponseConfig.LastResponseCount = if ($responseData.totalResponses) { $responseData.totalResponses } else { 0 }
        $script:ResponseConfig.LastSessionId = if ($responseData.lastSessionId) { $responseData.lastSessionId } else { "" }
        
        if (Test-Path $script:ResponseConfig.ResponseJsonPath) {
            $fileInfo = Get-Item $script:ResponseConfig.ResponseJsonPath
            $script:ResponseConfig.LastResponseTime = $fileInfo.LastWriteTime
        }
    }
    
    # Start monitoring systems
    $watcherStarted = Start-ResponseFileWatcher
    Start-ResponsePollingTimer
    
    if ($watcherStarted -or $script:ResponsePollingTimer) {
        Write-Host "[ResponseMonitoring] [+] Response monitoring started successfully" -ForegroundColor Green
        Write-Host "[ResponseMonitoring]   Monitoring: $($script:ResponseConfig.ResponseJsonPath)" -ForegroundColor Gray
        Write-Host "[ResponseMonitoring]   FileWatcher: $($watcherStarted)" -ForegroundColor Gray
        Write-Host "[ResponseMonitoring]   Polling: $($script:ResponsePollingTimer -ne $null)" -ForegroundColor Gray
        
        return @{
            Success = $true
            Method = "Hybrid"
            FileWatcher = $watcherStarted
            Polling = $script:ResponsePollingTimer -ne $null
        }
    } else {
        Write-Host "[ResponseMonitoring] [-] Failed to start response monitoring" -ForegroundColor Red
        return @{ Success = $false; Error = "Failed to start monitoring" }
    }
}

function Stop-ClaudeResponseMonitoring {
    <#
    .SYNOPSIS
    Stops Claude response monitoring and cleans up resources
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "[ResponseMonitoring] Stopping Claude response monitoring..." -ForegroundColor Yellow
    
    Stop-ResponseFileWatcher
    Stop-ResponsePollingTimer
    
    $script:OnResponseCallback = $null
    
    Write-Host "[ResponseMonitoring] [+] Response monitoring stopped" -ForegroundColor Green
}

function Get-ResponseMonitoringStatus {
    <#
    .SYNOPSIS
    Gets current status of Claude response monitoring
    #>
    [CmdletBinding()]
    param()
    
    return @{
        FileWatcherActive = $script:ResponseWatcher -ne $null -and $script:ResponseWatcher.EnableRaisingEvents
        PollingActive = $script:ResponsePollingTimer -ne $null -and $script:ResponsePollingTimer.Enabled
        EventSubscriptions = $script:ResponseEventSubscriptions.Count
        MonitoringPath = $script:ResponseConfig.ResponseJsonPath
        LastResponseCount = $script:ResponseConfig.LastResponseCount
        LastResponseTime = $script:ResponseConfig.LastResponseTime
        LastSessionId = $script:ResponseConfig.LastSessionId
    }
}

#endregion

#region Response Processing Helper Functions

function Format-ResponseSummary {
    <#
    .SYNOPSIS
    Formats Claude response for logging/display
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Response
    )
    
    $summary = @()
    $summary += "Session: $($Response.sessionId)"
    $summary += "Type: $($Response.responseType)"
    $summary += "Confidence: $($Response.confidence)"
    $summary += "Summary: $($Response.summary)"
    
    if ($Response.actionsTaken -and $Response.actionsTaken.Count -gt 0) {
        $summary += "Actions: $($Response.actionsTaken.Count) taken"
    }
    
    if ($Response.remainingIssues -and $Response.remainingIssues.Count -gt 0) {
        $summary += "Issues: $($Response.remainingIssues.Count) remaining"
    }
    
    if ($Response.requiresFollowUp) {
        $summary += "Follow-up: Required"
    }
    
    return $summary -join ", "
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Start-ClaudeResponseMonitoring',
    'Stop-ClaudeResponseMonitoring', 
    'Get-ResponseMonitoringStatus',
    'Format-ResponseSummary'
)

#endregion
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUOkYiZrIulXC1P3q2aiUAYAeY
# JuqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU6nlKPN0BCY4YBdCNNXSqtYUlcocwDQYJKoZIhvcNAQEBBQAEggEALMbZ
# rpISL1u0uA1rI7rOf1BvpScqBqtpMKQzx8FYhzXTtvVZ8fXbiXHlrWr5vZDZt0N8
# tX8ILKmCg3bmQew+WNYPq7vC5Tg7+PFfYKD96GSIceNVw6F+1y89P/jCerp3aqys
# XxIuRsismkDXm25SiGCr6aZEqOhrO4C/qeilJwGaGrUBrEJNvsZO88ZyTVhaxJGM
# ySPAVaTfZ5Gn8K8NG6i4/b1bAAR24Qqb4704N5Gat0h955w2tVEgI2/cMazUQC5y
# Ux2A18B1UHUi5TvxSqt5qsyflVkGFZUqsZ9hVLvr1K4szEW4GE5GAHCTdZBP/RIz
# eRY0zOxRQnpqcy/zTw==
# SIG # End signature block
