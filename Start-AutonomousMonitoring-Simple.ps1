# Start-AutonomousMonitoring-Simple.ps1
# Simple autonomous monitoring that submits recommendations with JSON creation directive
# Date: 2025-08-21

param(
    [int]$PollIntervalSeconds = 5,
    [switch]$DebugMode
)

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "SIMPLE AUTONOMOUS MONITORING" -ForegroundColor Cyan
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
Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force

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

# Critical directive to add to all prompts
$script:CriticalDirective = @"

==================================================
CRITICAL: AT THE END OF YOUR RESPONSE, YOU MUST CREATE A RESPONSE .JSON FILE AT ./ClaudeResponses/Autonomous/ AND IN IT WRITE THE END OF YOUR RESPONSE, WHICH SHOULD END WITH:
  [RECOMMENDATION: CONTINUE]
  [RECOMMENDATION: TEST <Name>]
  [RECOMMENDATION: FIX <File>]
  [RECOMMENDATION: COMPILE]
  [RECOMMENDATION: RESTART <Module>]
  [RECOMMENDATION: COMPLETE]
  [RECOMMENDATION: ERROR <Description>]
==================================================
"@

# Function to submit prompt to Claude via TypeKeys
function Submit-ToClaudeViaTypeKeys {
    param([string]$PromptText)
    
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
        # Add Windows type definitions if not already added
        if (-not ([System.Management.Automation.PSTypeName]'WindowHelper').Type) {
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
        }
        
        # Find Claude Code CLI window
        $processes = Get-Process | Where-Object { 
            $_.MainWindowTitle -like "*Claude Code CLI*" -or
            $_.MainWindowTitle -like "*claude*" -or
            $_.MainWindowTitle -eq "Claude Code CLI environment"
        }
        
        if ($processes) {
            $claudeProcess = $processes[0]
            $claudeWindow = $claudeProcess.MainWindowHandle
            Write-Host "  Found Claude window: $($claudeProcess.MainWindowTitle)" -ForegroundColor Green
            Write-Host "  PID: $($claudeProcess.Id), Handle: $claudeWindow" -ForegroundColor Gray
            
            # Switch to Claude window
            $switched = [WindowHelper]::SetForegroundWindow($claudeWindow)
            Write-Host "  Window switch result: $switched" -ForegroundColor Gray
            Start-Sleep -Milliseconds 1000
            
            # Clear current input and type new prompt
            Write-Host "  Clearing input..." -ForegroundColor Gray
            [System.Windows.Forms.SendKeys]::SendWait("^a")  # Select all
            Start-Sleep -Milliseconds 200
            [System.Windows.Forms.SendKeys]::SendWait("{DEL}")  # Delete
            Start-Sleep -Milliseconds 200
            
            # Type the prompt line by line to handle newlines properly
            Write-Host "  Typing prompt ($(($PromptText.Length)) characters)..." -ForegroundColor Gray
            
            $lines = $PromptText -split "`n"
            foreach ($line in $lines) {
                # Escape special characters for SendKeys
                $escapedLine = $line -replace '{', '{{' `
                                    -replace '}', '}}' `
                                    -replace '\+', '{+}' `
                                    -replace '\^', '{^}' `
                                    -replace '%', '{%}' `
                                    -replace '~', '{~}' `
                                    -replace '\(', '{(}' `
                                    -replace '\)', '{)}'
                
                [System.Windows.Forms.SendKeys]::SendWait($escapedLine)
                [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
                Start-Sleep -Milliseconds 50
            }
            
            Write-Host "  Prompt typed successfully!" -ForegroundColor Green
            
            # Don't submit yet - let user review
            Write-Host "  READY TO SUBMIT - Press Enter in Claude window to submit" -ForegroundColor Yellow
            
            $script:LastSubmission = Get-Date
            return $true
        } else {
            Write-Host "  Could not find Claude Code CLI window!" -ForegroundColor Red
            Write-Host "  Make sure the window title contains 'Claude' or rename it to 'Claude Code CLI environment'" -ForegroundColor Yellow
            return $false
        }
    } catch {
        Write-Host "  Error submitting to Claude: $_" -ForegroundColor Red
        return $false
    }
}

# Function to process response file
function Process-ResponseFile {
    param([string]$FilePath)
    
    try {
        Write-Host ""
        Write-Host "[PROCESSING] File: $(Split-Path $FilePath -Leaf)" -ForegroundColor Yellow
        
        $content = Get-Content $FilePath -Raw | ConvertFrom-Json
        $responseText = $content.response
        
        if (-not $responseText) {
            Write-Host "  No response field found in JSON" -ForegroundColor Red
            return
        }
        
        # Show response preview
        $preview = $responseText.Substring(0, [Math]::Min(200, $responseText.Length))
        Write-Host "  Response preview: $preview..." -ForegroundColor Gray
        
        # Simply copy the response text and add the directive
        $nextPrompt = $responseText + $script:CriticalDirective
        
        Write-Host "  Prepared prompt with directive (total: $($nextPrompt.Length) chars)" -ForegroundColor Cyan
        
        # Submit to Claude
        Write-Host "  Submitting to Claude via TypeKeys..." -ForegroundColor Cyan
        $submitted = Submit-ToClaudeViaTypeKeys -PromptText $nextPrompt
        
        if ($submitted) {
            Write-Host "  SUCCESSFULLY PREPARED PROMPT IN CLAUDE!" -ForegroundColor Green
            Write-Host "  Press Enter in Claude window to submit" -ForegroundColor Yellow
            
            # Log submission
            $logEntry = @{
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                SourceFile = Split-Path $FilePath -Leaf
                ResponseLength = $responseText.Length
                Status = "Submitted"
            }
            $logEntry | ConvertTo-Json -Compress | Add-Content -Path ".\autonomous_submissions.log"
        } else {
            Write-Host "  Failed to submit to Claude" -ForegroundColor Red
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
Write-Host "The agent will:" -ForegroundColor Yellow
Write-Host "  1. Detect new JSON files in $watchPath" -ForegroundColor Gray
Write-Host "  2. Copy the response text from the JSON" -ForegroundColor Gray
Write-Host "  3. Add the critical directive for JSON creation" -ForegroundColor Gray
Write-Host "  4. Type it into Claude Code CLI window" -ForegroundColor Gray
Write-Host "  5. You press Enter to submit" -ForegroundColor Gray
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
        
        # Update heartbeat
        try {
            Send-HeartbeatRequest -SubsystemName "AutonomousAgent" -ErrorAction SilentlyContinue
        } catch {}
    }
    
    # Wait before next poll
    Start-Sleep -Seconds $PollIntervalSeconds
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQ3iJ0dHvMUOdItWQdWzjIaT9
# YqSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUN4vSYeL590bBWCY/cXp20n8XBVkwDQYJKoZIhvcNAQEBBQAEggEAocHa
# keLRi7Wa7K+pRKiBxgTedZEzo2Lu0oRgN9ougYR2Txw9LgUwDobeeuuK2wNcNTZP
# LSrTTAKidarVpvsnhhZ5Y2no0nQl04a2FE75RkLSs0Unl0+e7BxSUPZEAMSs6/L4
# E1cH2skmes4PNycWs4D+sXX7Nlwa9cNqXToNvsne747aYkHOOMURLMwKgAPlxuX1
# 96W42nqAlBD0O8ZSJ663jtMdaq42+hjLjZBsjnNILjii/edaxBwqzQyp4zAuNmco
# PDUtd8Okb/Es3N+b8DVQkkouVbYvgV0TaXHWZJGQ+Iwc5u93i5yK1DQPBLLcoZiG
# O2WhkgoU6+VbJ+9EIA==
# SIG # End signature block
