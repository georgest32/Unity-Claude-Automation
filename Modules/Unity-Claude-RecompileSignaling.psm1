# Unity-Claude-RecompileSignaling.psm1
# Monitor for recompilation signals from Claude after code changes
# Automatically switch to Unity to trigger recompilation in 2021.1.14f1
# Date: 2025-08-18

#region Module Initialization
$ErrorActionPreference = "Stop"

Write-Host "[RecompileSignaling] Loading Unity recompilation signaling module..." -ForegroundColor Cyan

# Module configuration
$script:SignalingConfig = @{
    SignalFilePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_recompile_signal.json"
    LastSignalTime = [DateTime]::MinValue
    WindowSwitchDelayMs = 3000
    RetryCount = 3
}

# Global variables
$script:SignalWatcher = $null
$script:SignalEventSubscriptions = @()
$script:OnRecompileSignalCallback = $null

Write-Host "[RecompileSignaling] Unity recompilation signaling module loaded successfully" -ForegroundColor Green

#endregion

#region Unity Window Switching Functions

function Switch-ToUnityWindow {
    <#
    .SYNOPSIS
    Uses existing rapid switch system to trigger Unity recompilation quickly
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "[RecompileSignaling] Using rapid Unity switch (existing system)..." -ForegroundColor Yellow
        
        # Use existing rapid switch script with minimal wait time  
        $automationRoot = Split-Path $PSScriptRoot -Parent
        $rapidSwitchPath = Join-Path $automationRoot "Invoke-RapidUnitySwitch.ps1"
        
        if (Test-Path $rapidSwitchPath) {
            Write-Host "[RecompileSignaling] Executing rapid Unity switch..." -ForegroundColor Green
            
            # Use rapid switch with minimal 50ms wait (even faster than default 75ms)
            $result = & $rapidSwitchPath -WaitMilliseconds 50 -Measure
            
            if ($result.Success) {
                Write-Host "[RecompileSignaling] Rapid switch completed in $([Math]::Round($result.TimingBreakdown.TotalMilliseconds))ms" -ForegroundColor Green
                Write-Host "[RecompileSignaling] Unity detected: $($result.UnityDetected)" -ForegroundColor Gray
                return @{ 
                    Success = $true
                    UnityDetected = $result.UnityDetected
                    TotalTime = $result.TimingBreakdown.TotalMilliseconds
                    RapidSwitch = $true
                }
            } else {
                Write-Host "[RecompileSignaling] Rapid switch had issues" -ForegroundColor Yellow
                return @{ 
                    Success = $false
                    Error = "Rapid switch completed but with issues"
                    UnityDetected = $result.UnityDetected
                }
            }
            
        } else {
            Write-Host "[RecompileSignaling] Rapid switch script not found, using fallback" -ForegroundColor Yellow
            return @{ Success = $false; Error = "Rapid switch script not found" }
        }
        
    } catch {
        Write-Host "[RecompileSignaling] Error with rapid switch: $($_.Exception.Message)" -ForegroundColor Red
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

# Switch-BackToAutonomousSystem not needed - rapid switch handles return automatically

#endregion

#region Signal Processing Functions

function Process-RecompileSignal {
    <#
    .SYNOPSIS
    Processes recompilation signal from Claude
    #>
    [CmdletBinding()]
    param()
    
    try {
        $signalFile = $script:SignalingConfig.SignalFilePath
        
        if (-not (Test-Path $signalFile)) {
            return
        }
        
        $fileInfo = Get-Item $signalFile
        
        # Only process if signal is newer than last processed
        # Note: Allow first-time processing by checking if LastSignalTime is MinValue
        if ($fileInfo.LastWriteTime -le $script:SignalingConfig.LastSignalTime -and 
            $script:SignalingConfig.LastSignalTime -ne [DateTime]::MinValue) {
            Write-Host "[RecompileSignaling] Signal already processed, skipping" -ForegroundColor Gray
            return
        }
        
        # Read signal data
        $content = Get-Content $signalFile -Raw | ConvertFrom-Json
        $script:SignalingConfig.LastSignalTime = $fileInfo.LastWriteTime
        
        Write-Host "" -ForegroundColor White
        Write-Host "[>] RECOMPILATION SIGNAL DETECTED!" -ForegroundColor Cyan
        Write-Host "====================================" -ForegroundColor Cyan
        Write-Host "Timestamp: $($content.timestamp)" -ForegroundColor Gray
        Write-Host "Requested by: $($content.requestedBy)" -ForegroundColor Gray
        Write-Host "Reason: $($content.reason)" -ForegroundColor Gray
        Write-Host "Priority: $($content.priority)" -ForegroundColor Gray
        
        if ($content.windowSwitchRequired) {
            Write-Host "Initiating rapid Unity switch sequence..." -ForegroundColor Yellow
            
            # Use rapid switch to trigger Unity recompilation
            $switchResult = Switch-ToUnityWindow
            
            if ($switchResult.Success) {
                Write-Host "[+] Rapid Unity switch completed in $($switchResult.TotalTime)ms" -ForegroundColor Green
                Write-Host "[+] Unity recompilation should now be triggered" -ForegroundColor Green
                
                # Clean up signal file
                Remove-Item $signalFile -Force -ErrorAction SilentlyContinue
                Write-Host "[+] Recompilation signal processed and cleared" -ForegroundColor Green
                
            } else {
                Write-Host "[-] Rapid Unity switch failed: $($switchResult.Error)" -ForegroundColor Red
            }
        }
        
        Write-Host "====================================" -ForegroundColor Cyan
        
    } catch {
        Write-Host "[RecompileSignaling] Error processing signal: $($_.Exception.Message)" -ForegroundColor Red
    }
}

#endregion

#region Signal Monitoring Functions

function Start-RecompileSignalMonitoring {
    <#
    .SYNOPSIS
    Starts monitoring for Unity recompilation signals
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ScriptBlock]$OnSignalDetected
    )
    
    try {
        Write-Host "[RecompileSignaling] Starting recompilation signal monitoring..." -ForegroundColor Yellow
        
        $script:OnRecompileSignalCallback = $OnSignalDetected
        
        # Ensure signal directory exists
        $signalDir = Split-Path $script:SignalingConfig.SignalFilePath -Parent
        if (-not (Test-Path $signalDir)) {
            New-Item -ItemType Directory -Path $signalDir -Force | Out-Null
        }
        
        # Create FileSystemWatcher for signal file
        $script:SignalWatcher = New-Object System.IO.FileSystemWatcher
        $script:SignalWatcher.Path = $signalDir
        $script:SignalWatcher.Filter = "unity_recompile_signal.json"
        $script:SignalWatcher.IncludeSubdirectories = $false
        $script:SignalWatcher.EnableRaisingEvents = $true
        
        # Register events
        $signalAction = {
            Write-Host "[SignalWatcher] Recompilation signal detected" -ForegroundColor Cyan
            
            # Process signal with proper scope access
            $moduleName = "Unity-Claude-RecompileSignaling"
            $module = Get-Module $moduleName
            if ($module) {
                & $module { Process-RecompileSignal }
            }
            
            # Trigger callback if provided
            if ($script:OnRecompileSignalCallback) {
                & $script:OnRecompileSignalCallback
            }
        }
        
        $createdEvent = Register-ObjectEvent -InputObject $script:SignalWatcher -EventName "Created" -Action $signalAction
        $changedEvent = Register-ObjectEvent -InputObject $script:SignalWatcher -EventName "Changed" -Action $signalAction
        
        $script:SignalEventSubscriptions += $createdEvent
        $script:SignalEventSubscriptions += $changedEvent
        
        Write-Host "[RecompileSignaling] Signal monitoring started successfully" -ForegroundColor Green
        return @{ Success = $true }
        
    } catch {
        Write-Host "[RecompileSignaling] Failed to start signal monitoring: $($_.Exception.Message)" -ForegroundColor Red
        return @{ Success = $false; Error = $_.Exception.Message }
    }
}

function Stop-RecompileSignalMonitoring {
    <#
    .SYNOPSIS
    Stops recompilation signal monitoring
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Unregister events
        foreach ($subscription in $script:SignalEventSubscriptions) {
            Unregister-Event -SubscriptionId $subscription.Id -Force -ErrorAction SilentlyContinue
        }
        $script:SignalEventSubscriptions = @()
        
        # Dispose FileSystemWatcher
        if ($script:SignalWatcher) {
            $script:SignalWatcher.EnableRaisingEvents = $false
            $script:SignalWatcher.Dispose()
            $script:SignalWatcher = $null
        }
        
        Write-Host "[RecompileSignaling] Signal monitoring stopped" -ForegroundColor Yellow
        
    } catch {
        Write-Host "[RecompileSignaling] Error stopping signal monitoring: $($_.Exception.Message)" -ForegroundColor Red
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Start-RecompileSignalMonitoring',
    'Stop-RecompileSignalMonitoring',
    'Switch-ToUnityWindow',
    'Process-RecompileSignal'
)

#endregion
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUyIF4pKR+t7djTeslgzhsYfP5
# RDGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUd9Jb0DDX4CpH4XJE9BNXjXwHoKcwDQYJKoZIhvcNAQEBBQAEggEALwWz
# VbXO46a/u6NNJszQmBUEYrbTHFddxkVp+OesqhxkXyJE0fNLdEq+LNdWunIHJ8+d
# gTsf1FYH7M8QfIoVkaqjEvNfG4O3XuUCdChB1+FZZggf4BMSd6LlqXebuh0J629H
# 7udsUpriJJfb1xvsFiGfTzpUGBMcj/G27pNBFuuygUoBBFNzZNOvMPBSzHGcseF4
# Wr8t4gUNftGUruMFS3ltVbscVUNOrhsQx6WjdSSDEjSsLJba9MJD00xdsqIV+NL+
# 5807SN1fKwqHvH2X6YuCaCDWxg8EB7i180c+3rbK7cGB2gdc08Wu+2FNHCGYwHst
# 6HUgvgM4lakBW5IXNA==
# SIG # End signature block
