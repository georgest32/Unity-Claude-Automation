# Start-AutonomousMonitoring-Enhanced.ps1
# Enhanced autonomous monitoring with integrated polling and better response handling
# Date: 2025-08-21


# PowerShell 7 Self-Elevation

param(
    [int]$PollIntervalSeconds = 5,
    [switch]$DebugMode
)

if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh7 = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $pwsh7) {
        Write-Host "Upgrading to PowerShell 7..." -ForegroundColor Yellow
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $MyInvocation.MyCommand.Path) + $args
        Start-Process -FilePath $pwsh7 -ArgumentList $arguments -NoNewWindow -Wait
        exit
    } else {
        Write-Warning "PowerShell 7 not found. Running in PowerShell $($PSVersionTable.PSVersion)"
    }
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "ENHANCED AUTONOMOUS MONITORING" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Get process ID for tracking
$agentPID = $PID
Write-Host "AutonomousAgent Process ID: $agentPID" -ForegroundColor Yellow

# Set working directory
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

# Import required modules
Write-Host "Loading modules..." -ForegroundColor Gray
Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force
Import-Module ".\Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent-Refactored.psd1" -Force

# Register with SystemStatus
Register-Subsystem -SubsystemName "AutonomousAgent" -ModulePath ".\Modules\Unity-Claude-AutonomousAgent" -HealthCheckLevel "Standard"
Write-Host "Registered AutonomousAgent subsystem" -ForegroundColor Green

# Initialize tracking
$script:ProcessedFiles = @{}
$script:LastSubmission = $null
$script:SubmissionCooldown = 30  # seconds between submissions
$watchPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous"
$pendingFile = Join-Path $watchPath ".pending"

Write-Host ""
Write-Host "Configuration:" -ForegroundColor Yellow
Write-Host "  Watch Path: $watchPath" -ForegroundColor Gray
Write-Host "  Poll Interval: $PollIntervalSeconds seconds" -ForegroundColor Gray
Write-Host "  Submission Cooldown: $script:SubmissionCooldown seconds" -ForegroundColor Gray
Write-Host ""

# Function to submit prompt to Claude
function Submit-ToClaudeCodeCLI {
    Write-Host ""
    Write-Host "[SUBMISSION] Preparing to submit to Claude Code CLI..." -ForegroundColor Cyan
    
    # Check cooldown
    if ($script:LastSubmission) {
        $timeSinceLastSubmission = (Get-Date) - $script:LastSubmission
        if ($timeSinceLastSubmission.TotalSeconds -lt $script:SubmissionCooldown) {
            $waitTime = [int]($script:SubmissionCooldown - $timeSinceLastSubmission.TotalSeconds)
            Write-Host "  Cooldown active, waiting $waitTime seconds..." -ForegroundColor Yellow
            Start-Sleep -Seconds $waitTime
        }
    }
    
    try {
        # First check if Submit-PromptToClaude is available
        if (Get-Command "Submit-PromptToClaude" -ErrorAction SilentlyContinue) {
            Write-Host "  Submit-PromptToClaude function found" -ForegroundColor Green
            
            # Try different parameter variations
            $submitCommand = Get-Command Submit-PromptToClaude
            
            if ($submitCommand.Parameters.ContainsKey("PromptText")) {
                Write-Host "  Using PromptText parameter" -ForegroundColor Gray
                $result = Submit-PromptToClaude -PromptText $PromptText
            } elseif ($submitCommand.Parameters.ContainsKey("Prompt")) {
                Write-Host "  Using Prompt parameter" -ForegroundColor Gray
                $result = Submit-PromptToClaude -Prompt $PromptText
            } else {
                Write-Host "  Using positional parameter" -ForegroundColor Gray
                $result = Submit-PromptToClaude $PromptText
            }
            
            Write-Host "  Submission successful!" -ForegroundColor Green
            $script:LastSubmission = Get-Date
            return $true
        } else {
            Write-Host "  Submit-PromptToClaude not available, using TypeKeys method..." -ForegroundColor Yellow
            
            # Alternative: Use TypeKeys to submit
            Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public class WindowHelper {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);
}
"@ -ReferencedAssemblies System.Windows.Forms
            
            # Find Claude Code CLI window
            $processes = Get-Process | Where-Object { $_.MainWindowTitle -like "*Claude Code CLI*" }
            if ($processes) {
                $claudeWindow = $processes[0].MainWindowHandle
                Write-Host "  Found Claude Code CLI window" -ForegroundColor Green
                
                # Switch to Claude window
                [WindowHelper]::SetForegroundWindow($claudeWindow) | Out-Null
                Start-Sleep -Milliseconds 500
                
                # Clear current input and type new prompt
                [System.Windows.Forms.SendKeys]::SendWait("^a")  # Select all
                Start-Sleep -Milliseconds 100
                [System.Windows.Forms.SendKeys]::SendWait("{DEL}")  # Delete
                Start-Sleep -Milliseconds 100
                
                # Type the prompt (escape special characters)
                $escapedPrompt = $PromptText -replace '{', '{{' -replace '}', '}}' -replace '\+', '{+}' -replace '\^', '{^}' -replace '%', '{%}' -replace '~', '{~}' -replace '\(', '{(}' -replace '\)', '{)}'
                [System.Windows.Forms.SendKeys]::SendWait($escapedPrompt)
                Start-Sleep -Milliseconds 500
                
                # Submit with Enter
                [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
                
                Write-Host "  Prompt submitted via TypeKeys!" -ForegroundColor Green
                $script:LastSubmission = Get-Date
                return $true
            } else {
                Write-Host "  Could not find Claude Code CLI window!" -ForegroundColor Red
                return $false
            }
        }
    } catch {
        Write-Host "  Error submitting to Claude: $_" -ForegroundColor Red
        return $false
    }
}

# Function to process response file
function Process-ResponseFile {
    try {
        Write-Host ""
        Write-Host "[PROCESSING] File: $(Split-Path $FilePath -Leaf)" -ForegroundColor Yellow
        
        $content = Get-Content $FilePath -Raw | ConvertFrom-Json
        $responseText = $content.response
        
        if (-not $responseText) {
            Write-Host "  No response field found in JSON" -ForegroundColor Red
            return
        }
        
        Write-Host "  Response preview: $($responseText.Substring(0, [Math]::Min(100, $responseText.Length)))..." -ForegroundColor Gray
        
        # Enhanced pattern matching
        $recommendationPatterns = @(
            'RECOMMENDATION:\s*(.+)',
            'RECOMMENDED:\s*(.+)',
            'PROCEED\s+(?:WITH|TO)\s+(.+)',
            '\[RECOMMENDATION:\s*(.+?)\]',
            'Next\s+Step:\s*(.+)',
            'ACTION:\s*(.+)'
        )
        
        $matched = $false
        foreach ($pattern in $recommendationPatterns) {
            if ($responseText -match $pattern) {
                $matched = $true
                $recommendation = $Matches[1].Trim()
                Write-Host "  FOUND RECOMMENDATION: $recommendation" -ForegroundColor Green
                
                # Determine action type
                $action = ""
                if ($recommendation -match 'CONTINUE|NEXT|PROCEED') {
                    $action = "CONTINUE"
                } elseif ($recommendation -match 'TEST\s+([\w\-]+)') {
                    $action = "TEST"
                    $testName = $Matches[1]
                } elseif ($recommendation -match 'WEEK\s*(\d+)|DAY[S]?\s*(\d+[\-\d]*)|HOUR[S]?\s*(\d+[\-\d]*)') {
                    $action = "DEVELOPMENT"
                } elseif ($recommendation -match 'INTEGRATION|IMPLEMENT') {
                    $action = "IMPLEMENTATION"
                } elseif ($recommendation -match 'FIX|REPAIR|RESOLVE') {
                    $action = "FIX"
                } else {
                    $action = "GENERAL"
                }
                
                Write-Host "  ACTION TYPE: $action" -ForegroundColor Magenta
                
                # Prepare next prompt based on action
                $nextPrompt = ""
                
                switch ($action) {
                    "CONTINUE" {
                        $nextPrompt = $responseText
                    }
                    "TEST" {
                        if ($testName) {
                            $testScript = ".\Test-$testName.ps1"
                            if (Test-Path $testScript) {
                                Write-Host "  Running test: $testScript" -ForegroundColor Cyan
                                & $testScript
                                return  # Don't submit to Claude after running test
                            } else {
                                $nextPrompt = "Test script $testScript not found. $recommendation"
                            }
                        } else {
                            $nextPrompt = $recommendation
                        }
                    }
                    "DEVELOPMENT" {
                        $nextPrompt = "Implement: $recommendation. Please provide the implementation code."
                    }
                    "IMPLEMENTATION" {
                        $nextPrompt = "Proceed with: $recommendation. Create the necessary implementation files."
                    }
                    default {
                        $nextPrompt = $recommendation
                    }
                }
                
                # Add directive footer
                $nextPrompt += @"


==================================================
CRITICAL: End your response with a clear recommendation:
[RECOMMENDATION: CONTINUE] - for next step
[RECOMMENDATION: TEST <Name>] - to run a test
[RECOMMENDATION: FIX <File>] - to fix a file
[RECOMMENDATION: IMPLEMENT <Feature>] - to implement
[RECOMMENDATION: COMPLETE] - when done
==================================================
"@
                
                # Submit to Claude
                Write-Host "  Submitting to Claude..." -ForegroundColor Cyan
                $submitted = Submit-ToClaudeCodeCLI -PromptText $nextPrompt
                
                if ($submitted) {
                    Write-Host "  SUCCESSFULLY SUBMITTED TO CLAUDE!" -ForegroundColor Green
                } else {
                    Write-Host "  Failed to submit to Claude" -ForegroundColor Red
                }
                
                break  # Exit pattern loop after first match
            }
        }
        
        if (-not $matched) {
            Write-Host "  No recommendation pattern found in response" -ForegroundColor Yellow
            if ($DebugMode) {
                Write-Host "  Full response: $responseText" -ForegroundColor DarkGray
            }
        }
        
    } catch {
        Write-Host "  Error processing file: $_" -ForegroundColor Red
    }
}

# Initial scan - mark existing files as processed
Write-Host "Initial scan of existing files..." -ForegroundColor Gray
Get-ChildItem -Path $watchPath -Filter "*.json" -ErrorAction SilentlyContinue | ForEach-Object {
    $script:ProcessedFiles[$_.FullName] = $true
}
Write-Host "  Found $($script:ProcessedFiles.Count) existing files (marked as processed)" -ForegroundColor Gray

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "MONITORING ACTIVE" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Main monitoring loop
$loopCounter = 0
while ($true) {
    $loopCounter++
    $timestamp = Get-Date -Format 'HH:mm:ss'
    
    # Check for pending file (from FileSystemWatcher)
    if (Test-Path $pendingFile) {
        try {
            $queuedFile = Get-Content $pendingFile -ErrorAction Stop
            Write-Host "[$timestamp] Found queued file from watcher: $(Split-Path $queuedFile -Leaf)" -ForegroundColor Yellow
            
            if (Test-Path $queuedFile) {
                Process-ResponseFile -FilePath $queuedFile
                $script:ProcessedFiles[$queuedFile] = $true
            }
            
            Remove-Item $pendingFile -Force
        } catch {
            Write-Host "[$timestamp] Error processing pending file: $_" -ForegroundColor Red
        }
    }
    
    # Poll for new files
    try {
        $currentFiles = Get-ChildItem -Path $watchPath -Filter "*.json" -ErrorAction SilentlyContinue
        
        foreach ($file in $currentFiles) {
            if (-not $script:ProcessedFiles.ContainsKey($file.FullName)) {
                Write-Host "[$timestamp] NEW FILE DETECTED: $($file.Name)" -ForegroundColor Green
                
                # Process the new file
                Process-ResponseFile -FilePath $file.FullName
                
                # Mark as processed
                $script:ProcessedFiles[$file.FullName] = $true
            }
        }
    } catch {
        Write-Host "[$timestamp] Polling error: $_" -ForegroundColor Red
    }
    
    # Status update every 6 loops (30 seconds if 5-second interval)
    if ($loopCounter % 6 -eq 0) {
        $uptime = $loopCounter * $PollIntervalSeconds
        Write-Host "[$timestamp] Monitoring active (uptime: $uptime seconds)" -ForegroundColor Cyan
        Write-Host "  Processed files: $($script:ProcessedFiles.Count)" -ForegroundColor Gray
        Write-Host "  Watching: $watchPath" -ForegroundColor Gray
    }
    
    # Wait before next poll
    Start-Sleep -Seconds $PollIntervalSeconds
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUVcJwwLiRWTb57fsdFlKC4BPp
# v1qgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUNBn9zKVG/bU8xdqPYa3FGPE0y2gwDQYJKoZIhvcNAQEBBQAEggEAjJRX
# XeCbKa1HhBlNAJMyXRcB11cYihjpb5I3KF98Q8+pSfUlq/WU5c6SafGH1X5pMkSx
# WqFJ9JTt4mhJEmnRvKyDKRSJXbJEjItM0itLp0oO9YQcmk7mwnU21u6dDqfBBz2C
# vnBRR40aOcos7SEu/gv3znY7FnJ7WQdkKOkM9NkmbiI1ZNSlJmGVrS4HAIY6ApCt
# 7mwENDfZzLH2h1JxYGIjlu7etbmc0OBKRcnolQSs4Kk/AYIoEXsKfuDGvMsNvlte
# z9lwc0Zs5G2aSkam2GTnvoIj/H9DcXpt5FcL6lvirAFVtld8ecy6gsZDfw4ZR46k
# cRbWEzN2RB6xOir0Vg==
# SIG # End signature block


