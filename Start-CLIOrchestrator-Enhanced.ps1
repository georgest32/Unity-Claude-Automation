# Start-CLIOrchestrator-Enhanced.ps1
# Enhanced CLI orchestration with integrated polling and better response handling
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
Write-Host "ENHANCED CLI orchestration" -ForegroundColor Cyan
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
                $escapedPrompt = $PromptText -replace '{', '{{' -replace '}', '}}' -replace '\+', '{+}' -replace '\^', '{^}' -replace '%', '{%}' -replace '~', '{~}'
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
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDofqJnMrplD2+i
# C7O8u9SH9L4oH6GC4+8XkvXvjwrekaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIEAiQO35Y7UavqpJhd81BW+c
# 9vCchwAtVIX/gNN+Kaw+MA0GCSqGSIb3DQEBAQUABIIBAH/zGhrWIjVJF8Xkgjxy
# CgzbBibXBOTOwbDCc5yUwKfPHs7YrMTg8lGR2SNtnWoNHjtCJFZTHVQY7grasCb1
# pq6H5ciT6HuhWiI8LoWTjslsnLZ37RLJvB48dj5DjgEBR5qewWa4QqvCYbybwQ4I
# FHkgSUhguLvaNWxTFHwWWXFz3ynZ8k4BhyvNAg+eSS9hlzq+5Ls4RIB0twi0GaKy
# w6lZH+yj8qWuweyDAtNUJDCYwIb49XjdRDbwdZbOPADAKegbNeNVsS6qD7cVV5Co
# 6FSg/pcOZvTTHD9HHQoyHE97hLyWdWUqg/nr5f6plOYrZDLo4FA4Ha2w9D+lxI4z
# YJE=
# SIG # End signature block

