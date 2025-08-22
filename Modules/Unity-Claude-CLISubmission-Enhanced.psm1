# Unity-Claude-CLISubmission-Enhanced.psm1
# Enhanced CLI submission with input locking integration
# Week 6 Day 5: Configuration & Documentation integration
# Builds on existing CLISubmission module with notification configuration

#region Module Initialization
$ErrorActionPreference = "Stop"

Write-Host "[CLISubmission-Enhanced] Loading enhanced CLI submission module..." -ForegroundColor Cyan

# Import notification configuration module
try {
    Import-Module (Join-Path $PSScriptRoot "Unity-Claude-NotificationConfiguration\Unity-Claude-NotificationConfiguration.psm1") -Force
    Write-Host "[CLISubmission-Enhanced] Notification configuration module loaded" -ForegroundColor Green
} catch {
    Write-Warning "[CLISubmission-Enhanced] Notification configuration module not available: $_"
}

# Add required .NET types
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

#endregion

#region Enhanced Submission Functions

function Submit-ToClaudeWithInputLock {
    <#
    .SYNOPSIS
    Submits content to Claude Code CLI with automatic input locking
    
    .DESCRIPTION
    Enhanced submission that automatically locks keyboard/mouse during response typing
    
    .PARAMETER Content
    Content to submit to Claude
    
    .PARAMETER Context
    Additional context information
    
    .PARAMETER DisableInputLock
    Disable input locking for this submission
    
    .EXAMPLE
    Submit-ToClaudeWithInputLock -Content "Fix Unity compilation errors" -Context "Error details from Editor.log"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Content,
        
        [string]$Context = "",
        
        [switch]$DisableInputLock
    )
    
    try {
        Write-Host "Enhanced Claude Code CLI submission starting..." -ForegroundColor Cyan
        
        # Get input lock configuration
        $inputLockEnabled = $false
        $lockJob = $null
        
        if (-not $DisableInputLock) {
            try {
                $inputConfig = Get-InputLockConfiguration
                $inputLockEnabled = ($inputConfig.Configuration.Enabled -and 
                                   $inputConfig.Configuration.AutoLockOnSubmission -and 
                                   $inputConfig.RuntimeStatus.CanUseInputLock)
                
                if ($inputLockEnabled) {
                    Write-Host "Input locking enabled for this submission" -ForegroundColor Yellow
                } elseif ($inputConfig.Configuration.Enabled -and -not $inputConfig.RuntimeStatus.HasAdminPrivileges) {
                    Write-Warning "Input locking configured but requires Administrator privileges"
                } else {
                    Write-Host "Input locking not configured or disabled" -ForegroundColor Gray
                }
            } catch {
                Write-Warning "Could not check input lock configuration: $_"
            }
        }
        
        # Start input locking if enabled
        if ($inputLockEnabled) {
            Write-Host "Starting input lock protection..." -ForegroundColor Magenta
            $lockJob = Start-InputLockProtection
        }
        
        try {
            # Perform the actual submission
            Write-Host "Submitting to Claude Code CLI..." -ForegroundColor Green
            
            # Build full prompt
            $fullPrompt = if ($Context) {
                "$Content`n`nContext: $Context"
            } else {
                $Content
            }
            
            # Submit using existing submission logic (would integrate with existing module)
            $submissionResult = Submit-ToClaude -Content $fullPrompt
            
            # Monitor for response completion
            if ($inputLockEnabled -and $lockJob) {
                Write-Host "Monitoring for response completion..." -ForegroundColor Yellow
                $responseResult = Wait-ForResponseCompletion -LockJob $lockJob
            }
            
            return @{
                Success = $true
                SubmissionResult = $submissionResult
                InputLockUsed = $inputLockEnabled
                ResponseMonitored = ($lockJob -ne $null)
            }
            
        } finally {
            # Always clean up input locking
            if ($lockJob) {
                Write-Host "Cleaning up input lock protection..." -ForegroundColor Green
                Stop-InputLockProtection -LockJob $lockJob
            }
        }
        
    } catch {
        Write-Error "Enhanced CLI submission failed: $_"
        
        # Emergency input unlock
        if ($lockJob) {
            try {
                Stop-InputLockProtection -LockJob $lockJob -Emergency
            } catch {
                Write-Warning "Emergency input unlock failed: $_"
            }
        }
        
        return @{
            Success = $false
            Error = $_.Exception.Message
            InputLockUsed = $inputLockEnabled
        }
    }
}

function Start-InputLockProtection {
    <#
    .SYNOPSIS
    Starts input lock protection for Claude response
    
    .DESCRIPTION
    Initiates keyboard and mouse locking to prevent interruption during response typing
    
    .EXAMPLE
    $lockJob = Start-InputLockProtection
    #>
    [CmdletBinding()]
    param()
    
    try {
        # Get input lock configuration
        $inputConfig = Get-InputLockConfiguration
        if (-not $inputConfig.RuntimeStatus.CanUseInputLock) {
            Write-Warning "Input locking not available"
            return $null
        }
        
        # Start lock script in background job
        $lockScriptPath = $inputConfig.RuntimeStatus.LockScriptPath
        if (-not (Test-Path $lockScriptPath)) {
            Write-Warning "Input lock script not found: $lockScriptPath"
            return $null
        }
        
        Write-Host "===== STARTING INPUT LOCK PROTECTION =====" -ForegroundColor White -BackgroundColor Blue
        Write-Host "Keyboard and mouse will be locked during Claude response" -ForegroundColor Yellow -BackgroundColor Blue
        Write-Host "Emergency unlock: Ctrl+Alt+Del" -ForegroundColor White -BackgroundColor Blue
        Write-Host "===============================================" -ForegroundColor White -BackgroundColor Blue
        
        $lockJob = Start-Job -ScriptBlock {
            param($ScriptPath, $TimeoutSeconds)
            & $ScriptPath -Lock -TimeoutSeconds $TimeoutSeconds
        } -ArgumentList $lockScriptPath, $inputConfig.Configuration.TimeoutSeconds
        
        # Give the lock job a moment to start
        Start-Sleep -Milliseconds 500
        
        return $lockJob
        
    } catch {
        Write-Error "Failed to start input lock protection: $_"
        return $null
    }
}

function Stop-InputLockProtection {
    <#
    .SYNOPSIS
    Stops input lock protection
    
    .DESCRIPTION
    Cleans up input locking and restores keyboard/mouse functionality
    
    .PARAMETER LockJob
    The lock job to stop
    
    .PARAMETER Emergency
    Emergency unlock without job cleanup
    
    .EXAMPLE
    Stop-InputLockProtection -LockJob $lockJob
    #>
    [CmdletBinding()]
    param(
        [System.Management.Automation.Job]$LockJob,
        [switch]$Emergency
    )
    
    try {
        Write-Host "===== STOPPING INPUT LOCK PROTECTION =====" -ForegroundColor White -BackgroundColor Green
        
        if ($LockJob) {
            # Stop the background job
            try {
                Stop-Job $LockJob -ErrorAction SilentlyContinue
                Remove-Job $LockJob -ErrorAction SilentlyContinue
                Write-Host "Lock job stopped and cleaned up" -ForegroundColor Green
            } catch {
                Write-Warning "Error stopping lock job: $_"
            }
        }
        
        # Ensure input is unlocked using direct script call
        try {
            $inputConfig = Get-InputLockConfiguration
            $unlockScriptPath = $inputConfig.RuntimeStatus.LockScriptPath
            
            if (Test-Path $unlockScriptPath) {
                & $unlockScriptPath -Unlock
                Write-Host "Input explicitly unlocked" -ForegroundColor Green
            }
        } catch {
            Write-Warning "Error during explicit unlock: $_"
        }
        
        Write-Host "KEYBOARD AND MOUSE RESTORED" -ForegroundColor Black -BackgroundColor Green
        Write-Host "============================================" -ForegroundColor White -BackgroundColor Green
        
    } catch {
        Write-Error "Error stopping input lock protection: $_"
        
        # Last resort: try to unlock using Windows API directly
        if ($Emergency) {
            try {
                Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public class EmergencyUnlock {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool BlockInput(bool fBlockIt);
}
'@ -ErrorAction SilentlyContinue
                
                [EmergencyUnlock]::BlockInput($false)
                Write-Host "EMERGENCY INPUT UNLOCK EXECUTED" -ForegroundColor Yellow -BackgroundColor Red
            } catch {
                Write-Warning "Emergency unlock failed: $_"
            }
        }
    }
}

function Wait-ForResponseCompletion {
    <#
    .SYNOPSIS
    Monitors for Claude response completion
    
    .DESCRIPTION
    Waits for response to complete and automatically unlocks input
    
    .PARAMETER LockJob
    The input lock job to monitor
    
    .EXAMPLE
    Wait-ForResponseCompletion -LockJob $lockJob
    #>
    [CmdletBinding()]
    param(
        [System.Management.Automation.Job]$LockJob
    )
    
    try {
        Write-Host "Monitoring for response completion..." -ForegroundColor Yellow
        
        $inputConfig = Get-InputLockConfiguration
        $timeout = $inputConfig.Configuration.TimeoutSeconds
        $emergencyFile = $inputConfig.RuntimeStatus.EmergencyUnlockPath
        
        $startTime = Get-Date
        $endTime = $startTime.AddSeconds($timeout)
        
        while ((Get-Date) -lt $endTime) {
            # Check if emergency unlock file exists
            if (Test-Path $emergencyFile) {
                Write-Host "Emergency unlock file detected - stopping input lock" -ForegroundColor Yellow
                Remove-Item $emergencyFile -Force -ErrorAction SilentlyContinue
                break
            }
            
            # Check if lock job is still running
            if ($LockJob.State -ne "Running") {
                Write-Host "Lock job completed - input should be restored" -ForegroundColor Green
                break
            }
            
            # Check for Claude Code CLI window changes (basic heuristic)
            try {
                $currentTitle = Get-CurrentWindowTitle
                if ($currentTitle -notlike $inputConfig.Configuration.WindowTitlePattern) {
                    Write-Host "Claude window no longer active - releasing input lock" -ForegroundColor Yellow
                    break
                }
            } catch {
                # Ignore window title check errors
            }
            
            Start-Sleep -Seconds 1
        }
        
        if ((Get-Date) -ge $endTime) {
            Write-Warning "Response monitoring timeout reached ($timeout seconds)"
            return @{
                Success = $false
                Reason = "Timeout"
                Duration = $timeout
            }
        }
        
        return @{
            Success = $true
            Duration = ((Get-Date) - $startTime).TotalSeconds
        }
        
    } catch {
        Write-Error "Error during response monitoring: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

function Submit-ToClaude {
    <#
    .SYNOPSIS
    Core submission function (placeholder for existing implementation)
    
    .DESCRIPTION
    This would integrate with the existing Claude Code CLI submission logic
    
    .PARAMETER Content
    Content to submit
    
    .EXAMPLE
    Submit-ToClaude -Content "Fix compilation errors"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Content
    )
    
    # This is a placeholder - would integrate with existing Submit-ToClaudeCodeCLI function
    Write-Host "Submitting to Claude Code CLI: $($Content.Substring(0, [Math]::Min(50, $Content.Length)))..." -ForegroundColor Green
    
    # Simulate submission
    Start-Sleep -Seconds 2
    
    return @{
        Success = $true
        Timestamp = Get-Date
        ContentLength = $Content.Length
    }
}

function Get-CurrentWindowTitle {
    <#
    .SYNOPSIS
    Gets the current foreground window title
    
    .DESCRIPTION
    Helper function to check current window for response monitoring
    
    .EXAMPLE
    $title = Get-CurrentWindowTitle
    #>
    [CmdletBinding()]
    param()
    
    try {
        Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Text;

public class WindowHelper {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr GetForegroundWindow();
    
    [DllImport("user32.dll", SetLastError = true)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    
    [DllImport("user32.dll", SetLastError = true)]
    public static extern int GetWindowTextLength(IntPtr hWnd);
}
'@ -ErrorAction SilentlyContinue
        
        $window = [WindowHelper]::GetForegroundWindow()
        $length = [WindowHelper]::GetWindowTextLength($window)
        
        if ($length -gt 0) {
            $titleBuilder = New-Object System.Text.StringBuilder ($length + 1)
            [WindowHelper]::GetWindowText($window, $titleBuilder, $titleBuilder.Capacity) | Out-Null
            return $titleBuilder.ToString()
        }
        
        return ""
        
    } catch {
        return ""
    }
}

#endregion

# Export enhanced functions
Export-ModuleMember -Function @(
    'Submit-ToClaudeWithInputLock',
    'Start-InputLockProtection',
    'Stop-InputLockProtection',
    'Wait-ForResponseCompletion'
)
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6MmhTvtO3OGkjHfVj/iOg29r
# cnqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQURncOICxurswPEpmHiaw9O0hODlswDQYJKoZIhvcNAQEBBQAEggEATDsi
# sLJyZZ5gMwYVa48SbUhyYpomsLZNS9Pxt+5pBph+WMLP1bvkRAcUd89j9cfM39hI
# UaEyygeakXxzqhK4iDi5Lhy3WhKs8jKIm14n4nNP4xtgeOGX9gFWSVJbaqNljk/w
# /fQpf4HxDxZi32/zhuyDjuGnk/bFU2pFZfvv0L1OjKdQyAozrC9v7hR7XKHzAq69
# CD/fXjUwDbtOvEsTctcv7m4Jq0FqVoAH6UzdRZ6aXf7CGcBmTnCuxfdrozNz/zgB
# dRLHcG194YoPeADuzPEiNqCyUl2o7ntuRXncRJmMqF/h1hA0kCZKbAZAyPuvvthe
# YBG8qkkNCmh/bceOvQ==
# SIG # End signature block
