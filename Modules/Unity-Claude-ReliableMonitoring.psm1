# Unity-Claude-ReliableMonitoring.psm1
# Reliable Unity error monitoring using Register-ObjectEvent instead of Start-Job
# Based on web research findings about PowerShell monitoring best practices
# Date: 2025-08-18

$ErrorActionPreference = "Stop"

Write-Host "[ReliableMonitoring] Loading reliable Unity error monitoring module..." -ForegroundColor Cyan

# Module configuration
$script:MonitoringConfig = @{
    # Unity error file paths (using new safe exporter)
    SafeErrorPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_errors_safe.json"
    TimestampPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_errors_timestamp.txt"
    
    # Polling settings for reliability
    PollingIntervalSeconds = 2
    FileReadRetryCount = 3
    FileReadRetryDelayMs = 500
    
    # FileSystemWatcher settings
    UseFileWatcher = $true
    UseFallbackPolling = $true
    
    # Error detection
    LastModified = [DateTime]::MinValue
    LastErrorCount = 0
    LastTimestamp = ""
}

# Global variables for event management
$script:FileWatcher = $null
$script:PollingTimer = $null
$script:EventSubscriptions = @()
$script:OnErrorCallback = $null

#region Safe File Reading Functions

function Read-SafeJsonFile {
    <#
    .SYNOPSIS
    Safely reads and parses Unity error JSON file with retry logic
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )
    
    for ($retry = 0; $retry -lt $script:MonitoringConfig.FileReadRetryCount; $retry++) {
        try {
            if (-not (Test-Path $FilePath)) {
                return $null
            }
            
            $content = Get-Content $FilePath -Raw -ErrorAction Stop
            if ([string]::IsNullOrEmpty($content)) {
                return $null
            }
            
            $jsonData = $content | ConvertFrom-Json
            return $jsonData
            
        } catch {
            Write-Host "[ReliableMonitoring] File read attempt $($retry + 1) failed: $($_.Exception.Message)" -ForegroundColor Yellow
            
            if ($retry -lt ($script:MonitoringConfig.FileReadRetryCount - 1)) {
                Start-Sleep -Milliseconds $script:MonitoringConfig.FileReadRetryDelayMs
            }
        }
    }
    
    Write-Host "[ReliableMonitoring] Failed to read file after $($script:MonitoringConfig.FileReadRetryCount) attempts" -ForegroundColor Red
    return $null
}

function Test-ErrorFileChanged {
    <#
    .SYNOPSIS
    Tests if Unity error file has changed since last check
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Check timestamp file first (more reliable)
        if (Test-Path $script:MonitoringConfig.TimestampPath) {
            $currentTimestamp = Get-Content $script:MonitoringConfig.TimestampPath -Raw -ErrorAction SilentlyContinue
            if ($currentTimestamp -and $currentTimestamp.Trim() -ne $script:MonitoringConfig.LastTimestamp) {
                $script:MonitoringConfig.LastTimestamp = $currentTimestamp.Trim()
                return $true
            }
        }
        
        # Fallback to file modification time
        if (Test-Path $script:MonitoringConfig.SafeErrorPath) {
            $fileInfo = Get-Item $script:MonitoringConfig.SafeErrorPath
            if ($fileInfo.LastWriteTime -gt $script:MonitoringConfig.LastModified) {
                $script:MonitoringConfig.LastModified = $fileInfo.LastWriteTime
                return $true
            }
        }
        
        return $false
        
    } catch {
        Write-Host "[ReliableMonitoring] Error checking file changes: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

#endregion

#region Error Processing Functions

function Process-UnityErrors {
    <#
    .SYNOPSIS
    Processes detected Unity errors and triggers callback
    #>
    [CmdletBinding()]
    param()
    
    try {
        $errorData = Read-SafeJsonFile -FilePath $script:MonitoringConfig.SafeErrorPath
        
        if (-not $errorData) {
            return
        }
        
        $currentErrorCount = if ($errorData.totalErrors) { $errorData.totalErrors } else { 0 }
        
        # Only trigger if error count changed or we have new errors
        if ($currentErrorCount -gt 0 -and $currentErrorCount -ne $script:MonitoringConfig.LastErrorCount) {
            Write-Host "[ReliableMonitoring] Detected $currentErrorCount Unity errors (was $($script:MonitoringConfig.LastErrorCount))" -ForegroundColor Yellow
            
            # Extract error messages (using PSObject to avoid $Error variable conflict)
            $errorMessages = @()
            $errorList = $errorData.PSObject.Properties['errors'].Value
            if ($errorList) {
                foreach ($errorItem in $errorList) {
                    if ($errorItem.message) {
                        $errorMessages += $errorItem.message
                    }
                }
            }
            
            # Update count
            $script:MonitoringConfig.LastErrorCount = $currentErrorCount
            
            # Trigger callback
            if ($script:OnErrorCallback -and $errorMessages.Count -gt 0) {
                Write-Host "[ReliableMonitoring] Triggering autonomous callback with $($errorMessages.Count) errors" -ForegroundColor Green
                & $script:OnErrorCallback $errorMessages
            }
            
        } elseif ($currentErrorCount -eq 0 -and $script:MonitoringConfig.LastErrorCount -gt 0) {
            Write-Host "[ReliableMonitoring] Unity errors cleared" -ForegroundColor Green
            $script:MonitoringConfig.LastErrorCount = 0
        }
        
    } catch {
        Write-Host "[ReliableMonitoring] Error processing Unity errors: $($_.Exception.Message)" -ForegroundColor Red
    }
}

#endregion

#region FileSystemWatcher Functions

function Start-FileWatcher {
    <#
    .SYNOPSIS
    Starts FileSystemWatcher using Register-ObjectEvent (not Start-Job)
    #>
    [CmdletBinding()]
    param()
    
    try {
        $watchDirectory = Split-Path $script:MonitoringConfig.SafeErrorPath -Parent
        
        if (-not (Test-Path $watchDirectory)) {
            Write-Host "[ReliableMonitoring] Creating watch directory: $watchDirectory" -ForegroundColor Yellow
            New-Item -Path $watchDirectory -ItemType Directory -Force | Out-Null
        }
        
        # Create FileSystemWatcher
        $script:FileWatcher = New-Object System.IO.FileSystemWatcher
        $script:FileWatcher.Path = $watchDirectory
        $script:FileWatcher.Filter = "*.json"
        $script:FileWatcher.IncludeSubdirectories = $false
        $script:FileWatcher.EnableRaisingEvents = $true
        
        # Register events using Register-ObjectEvent (reliable approach)
        $changeAction = {
            Write-Host "[FileWatcher] File change detected" -ForegroundColor Cyan
            
            # Call the processing function with proper scope access
            $moduleName = "Unity-Claude-ReliableMonitoring"
            $module = Get-Module $moduleName
            if ($module) {
                & $module { Process-UnityErrors }
            }
        }
        
        $createdEvent = Register-ObjectEvent -InputObject $script:FileWatcher -EventName "Created" -Action $changeAction
        $changedEvent = Register-ObjectEvent -InputObject $script:FileWatcher -EventName "Changed" -Action $changeAction
        
        $script:EventSubscriptions += $createdEvent
        $script:EventSubscriptions += $changedEvent
        
        Write-Host "[ReliableMonitoring] FileSystemWatcher started on: $watchDirectory" -ForegroundColor Green
        return $true
        
    } catch {
        Write-Host "[ReliableMonitoring] Failed to start FileSystemWatcher: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Stop-FileWatcher {
    <#
    .SYNOPSIS
    Stops FileSystemWatcher and cleans up events
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Unregister events
        foreach ($subscription in $script:EventSubscriptions) {
            Unregister-Event -SubscriptionId $subscription.Id -Force -ErrorAction SilentlyContinue
        }
        $script:EventSubscriptions = @()
        
        # Dispose FileSystemWatcher
        if ($script:FileWatcher) {
            $script:FileWatcher.EnableRaisingEvents = $false
            $script:FileWatcher.Dispose()
            $script:FileWatcher = $null
        }
        
        Write-Host "[ReliableMonitoring] FileSystemWatcher stopped and cleaned up" -ForegroundColor Yellow
        
    } catch {
        Write-Host "[ReliableMonitoring] Error stopping FileSystemWatcher: $($_.Exception.Message)" -ForegroundColor Red
    }
}

#endregion

#region Polling Functions

function Start-PollingTimer {
    <#
    .SYNOPSIS
    Starts polling timer as backup to FileSystemWatcher
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Create timer for polling
        $script:PollingTimer = New-Object System.Timers.Timer
        $script:PollingTimer.Interval = $script:MonitoringConfig.PollingIntervalSeconds * 1000
        $script:PollingTimer.AutoReset = $true
        
        # Register timer event
        $timerAction = {
            if (Test-ErrorFileChanged) {
                Write-Host "[PollingTimer] File change detected via polling" -ForegroundColor Magenta
                
                # Call the processing function with proper scope access
                $moduleName = "Unity-Claude-ReliableMonitoring"
                $module = Get-Module $moduleName
                if ($module) {
                    & $module { Process-UnityErrors }
                }
            }
        }
        
        $timerEvent = Register-ObjectEvent -InputObject $script:PollingTimer -EventName "Elapsed" -Action $timerAction
        $script:EventSubscriptions += $timerEvent
        
        $script:PollingTimer.Start()
        
        Write-Host "[ReliableMonitoring] Polling timer started (interval: $($script:MonitoringConfig.PollingIntervalSeconds)s)" -ForegroundColor Green
        
    } catch {
        Write-Host "[ReliableMonitoring] Failed to start polling timer: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Stop-PollingTimer {
    <#
    .SYNOPSIS
    Stops polling timer
    #>
    [CmdletBinding()]
    param()
    
    try {
        if ($script:PollingTimer) {
            $script:PollingTimer.Stop()
            $script:PollingTimer.Dispose()
            $script:PollingTimer = $null
        }
        
        Write-Host "[ReliableMonitoring] Polling timer stopped" -ForegroundColor Yellow
        
    } catch {
        Write-Host "[ReliableMonitoring] Error stopping polling timer: $($_.Exception.Message)" -ForegroundColor Red
    }
}

#endregion

#region Public Interface

function Start-ReliableUnityMonitoring {
    <#
    .SYNOPSIS
    Starts reliable Unity error monitoring using hybrid FileSystemWatcher + polling approach
    
    .DESCRIPTION
    Uses Register-ObjectEvent instead of Start-Job for better reliability
    Combines FileSystemWatcher with polling as backup
    
    .PARAMETER OnErrorDetected
    Script block to execute when errors are detected
    
    .EXAMPLE
    Start-ReliableUnityMonitoring -OnErrorDetected { param($errors) Write-Host "Detected: $($errors.Count) errors" }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$OnErrorDetected
    )
    
    Write-Host "[ReliableMonitoring] Starting reliable Unity error monitoring..." -ForegroundColor Cyan
    
    # Store callback
    $script:OnErrorCallback = $OnErrorDetected
    
    # Reset state
    $script:MonitoringConfig.LastModified = [DateTime]::MinValue
    $script:MonitoringConfig.LastErrorCount = 0
    $script:MonitoringConfig.LastTimestamp = ""
    
    # Start FileSystemWatcher
    $watcherStarted = $false
    if ($script:MonitoringConfig.UseFileWatcher) {
        $watcherStarted = Start-FileWatcher
    }
    
    # Always start polling as backup
    if ($script:MonitoringConfig.UseFallbackPolling) {
        Start-PollingTimer
    }
    
    if ($watcherStarted -or $script:MonitoringConfig.UseFallbackPolling) {
        Write-Host "[ReliableMonitoring] [+] Reliable monitoring started successfully" -ForegroundColor Green
        Write-Host "[ReliableMonitoring]   Monitoring: $($script:MonitoringConfig.SafeErrorPath)" -ForegroundColor Gray
        Write-Host "[ReliableMonitoring]   FileWatcher: $($watcherStarted)" -ForegroundColor Gray
        Write-Host "[ReliableMonitoring]   Polling: $($script:MonitoringConfig.UseFallbackPolling)" -ForegroundColor Gray
        
        return @{
            Success = $true
            Method = "Hybrid"
            FileWatcher = $watcherStarted
            Polling = $script:MonitoringConfig.UseFallbackPolling
        }
    } else {
        Write-Host "[ReliableMonitoring] [-] Failed to start any monitoring method" -ForegroundColor Red
        return @{ Success = $false; Error = "Failed to start monitoring" }
    }
}

function Stop-ReliableUnityMonitoring {
    <#
    .SYNOPSIS
    Stops all Unity error monitoring
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "[ReliableMonitoring] Stopping reliable Unity error monitoring..." -ForegroundColor Yellow
    
    Stop-FileWatcher
    Stop-PollingTimer
    
    $script:OnErrorCallback = $null
    
    Write-Host "[ReliableMonitoring] [+] All monitoring stopped" -ForegroundColor Green
}

function Get-ReliableMonitoringStatus {
    <#
    .SYNOPSIS
    Gets current monitoring status
    #>
    [CmdletBinding()]
    param()
    
    $status = @{
        FileWatcherActive = ($script:FileWatcher -ne $null -and $script:FileWatcher.EnableRaisingEvents)
        PollingActive = ($script:PollingTimer -ne $null -and $script:PollingTimer.Enabled)
        EventSubscriptions = $script:EventSubscriptions.Count
        LastErrorCount = $script:MonitoringConfig.LastErrorCount
        LastModified = $script:MonitoringConfig.LastModified
        MonitoringPath = $script:MonitoringConfig.SafeErrorPath
    }
    
    return $status
}

#endregion

# Export public functions
Export-ModuleMember -Function @(
    'Start-ReliableUnityMonitoring',
    'Stop-ReliableUnityMonitoring',
    'Get-ReliableMonitoringStatus'
)

Write-Host "[ReliableMonitoring] Reliable Unity error monitoring module loaded successfully" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUWYQWyyUibYEwuy4vNxKe34Z+
# ufKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU8zzWXqkBXEqH805T7aszD2bxzjYwDQYJKoZIhvcNAQEBBQAEggEAPiig
# cQw531C0NuZC3W765sEcTuVLz7pyqzPCLAI2cyjcwe/MTriWUb7VKrEbgkKYCxol
# t08GWIa0CTROCOKoox6RHk8MTtdC8hg0dQTDUn6DH+eUTgf9j9jS4+w+3J0CKdox
# 4/txJjWnfzDziBFYEYkKep89DnzUx2gR9DXDj3lIcHMgLnGc7J2MGzjbm97B0toR
# 5u/WAM4UF8c1wtyxu4YLD2Gadl4s21Y3ep4uga29J86RJMsE8GjlA7VZbjBJSAUP
# XGWBbS9TOw+X1NoSylQxQMOcfKo8wFjvP6veMtNrCu40q1Yvu4YHT2j6aBs2zx2J
# NtflFqkgfNiBpVK5rA==
# SIG # End signature block
