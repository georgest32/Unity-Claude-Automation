Set-Location 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation'


# PowerShell 7 Self-Elevation
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

Set-Location 'C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation'

# Load the CLISubmission module for submitting to Claude
Write-Host "Loading CLISubmission module..." -ForegroundColor Yellow
$cliSubmissionPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLISubmission.psm1"
if (Test-Path $cliSubmissionPath) {
    Import-Module $cliSubmissionPath -Force
    Write-Host "CLISubmission module loaded successfully" -ForegroundColor Green
    if (Get-Command "Submit-PromptToClaude" -ErrorAction SilentlyContinue) {
        Write-Host "Submit-PromptToClaude function is available" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Submit-PromptToClaude function not found in module" -ForegroundColor Red
    }
} else {
    Write-Host "WARNING: CLISubmission module not found at $cliSubmissionPath" -ForegroundColor Red
}

# Report this process to SystemStatus immediately
$currentPID = $PID
Write-Host "AutonomousAgent Process ID: $currentPID" -ForegroundColor Cyan

# Check if running as administrator
$currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
$isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "Running with ADMINISTRATOR privileges" -ForegroundColor Green
} else {
    Write-Host "WARNING: Running without administrator privileges" -ForegroundColor Red
    Write-Host "Some operations may fail due to insufficient permissions" -ForegroundColor Yellow
}

# Try to update SystemStatus with our PID
try {
    Import-Module '.\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1' -Force -ErrorAction SilentlyContinue
    if (Get-Command "Read-SystemStatus" -ErrorAction SilentlyContinue) {
        $statusData = Read-SystemStatus
        
        # Use consistent naming - "AutonomousAgent" 
        $agentKey = "AutonomousAgent"
        
        # Create subsystem entry if it doesn't exist
        if (-not $statusData.Subsystems.ContainsKey($agentKey)) {
            Write-Host "Creating new AutonomousAgent entry in SystemStatus" -ForegroundColor Yellow
            $statusData.Subsystems[$agentKey] = @{
                HealthScore = 100
                ProcessId = $null
                Status = "Unknown"
                LastHeartbeat = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
                Performance = @{
                    ResponseTimeMs = 0
                    CpuPercent = 0
                    MemoryMB = 0
                }
                ModuleInfo = @{
                    Path = ".\Modules\Unity-Claude-AutonomousAgent"
                    ExportedFunctions = @{}
                    Version = "1.0.0"
                }
            }
        }
        
        # Update with current process info
        $statusData.Subsystems[$agentKey].ProcessId = $currentPID
        $statusData.Subsystems[$agentKey].Status = "Starting"
        $statusData.Subsystems[$agentKey].LastHeartbeat = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        $statusData.Subsystems[$agentKey].HealthScore = 100
        
        Write-SystemStatus -StatusData $statusData
        Write-Host "Reported PID $currentPID to SystemStatus as '$agentKey'" -ForegroundColor Green
        
        # Also register the subsystem properly
        if (Get-Command "Register-Subsystem" -ErrorAction SilentlyContinue) {
            Register-Subsystem -SubsystemName $agentKey -ModulePath ".\Modules\Unity-Claude-AutonomousAgent" -HealthCheckLevel "Standard"
            Write-Host "Registered $agentKey subsystem" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "Could not report to SystemStatus: $($_.Exception.Message)" -ForegroundColor Yellow
}

Import-Module '.\Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent-Refactored.psd1' -Force

Write-Host 'Starting Autonomous Claude Response Monitoring...' -ForegroundColor Green
Write-Host '=================================================' -ForegroundColor Cyan

# Set explicit path for ClaudeResponses monitoring
$monitorPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous"

# Verify the directory exists
if (-not (Test-Path $monitorPath)) {
    Write-Host "Creating monitoring directory: $monitorPath" -ForegroundColor Yellow
    New-Item -Path $monitorPath -ItemType Directory -Force | Out-Null
}

Write-Host "Monitoring directory: $monitorPath" -ForegroundColor Cyan
Write-Host "Directory exists: $(Test-Path $monitorPath)" -ForegroundColor Cyan

try {
    $ErrorActionPreference = 'Stop'
    # Use explicit path instead of relying on module's path resolution
    $result = Start-ClaudeResponseMonitoring -OutputDirectory $monitorPath -DebounceMs 500 -Filter "*.json"
    
    if ($result -and $result.Success) {
        Write-Host 'Monitoring started successfully!' -ForegroundColor Green
        Write-Host 'FileSystemWatcher is active and monitoring for Claude responses' -ForegroundColor Green
        Write-Host 'Press Ctrl+C to stop monitoring' -ForegroundColor Yellow
        Write-Host '=================================================' -ForegroundColor Cyan
        Write-Host ''
        
        # Debug FileSystemWatcher status with enhanced logging
        Write-Host "FileSystemWatcher Details:" -ForegroundColor Cyan
        Write-Host "  Path: $($result.Watcher.Path)" -ForegroundColor Gray
        Write-Host "  Filter: $($result.Watcher.Filter)" -ForegroundColor Gray
        Write-Host "  EnableRaisingEvents: $($result.Watcher.EnableRaisingEvents)" -ForegroundColor Gray
        Write-Host "  Event Handlers: $($result.EventHandlers.Count)" -ForegroundColor Gray
        Write-Host "  IncludeSubdirectories: $($result.Watcher.IncludeSubdirectories)" -ForegroundColor Gray
        Write-Host "  NotifyFilter: $($result.Watcher.NotifyFilter)" -ForegroundColor Gray
        Write-Host "  InternalBufferSize: $($result.Watcher.InternalBufferSize)" -ForegroundColor Gray
        
        # Log to file for persistence
        $logEntry = @"
[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [INFO] [AutonomousAgent] FileSystemWatcher initialized:
  - Path: $($result.Watcher.Path)
  - Filter: $($result.Watcher.Filter)
  - EnableRaisingEvents: $($result.Watcher.EnableRaisingEvents)
  - Event Handlers: $($result.EventHandlers.Count)
  - IncludeSubdirectories: $($result.Watcher.IncludeSubdirectories)
  - NotifyFilter: $($result.Watcher.NotifyFilter)
  - InternalBufferSize: $($result.Watcher.InternalBufferSize)
"@
        Add-Content -Path ".\unity_claude_automation.log" -Value $logEntry
        
        # Test event handler registration
        Write-Host "Testing event handler registration..." -ForegroundColor Yellow
        $eventSubscribers = Get-EventSubscriber | Where-Object { $_.SourceObject -is [System.IO.FileSystemWatcher] }
        if ($eventSubscribers) {
            Write-Host "  Event subscribers found: $($eventSubscribers.Count)" -ForegroundColor Green
            foreach ($sub in $eventSubscribers) {
                Write-Host "    $($sub.EventName): $($sub.SourceIdentifier)" -ForegroundColor Gray
            }
        } else {
            Write-Host "  WARNING: No FileSystemWatcher event subscribers found!" -ForegroundColor Red
            Write-Host "  This explains why file detection is not working." -ForegroundColor Red
        }
        Write-Host ''
        
        # Test the FileSystemWatcher immediately by creating a test file
        Write-Host "Testing FileSystemWatcher immediately..." -ForegroundColor Yellow
        try {
            # Use the same explicit path we're monitoring
            $testFileName = "watcher_immediate_test_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
            $testFile = Join-Path $monitorPath $testFileName
            
            Write-Host "  Creating test file at: $testFile" -ForegroundColor Gray
            
            $testContent = @{
                timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss.fff')
                response = "RECOMMENDATION: TEST - Immediate watcher test"
                type = "immediate_test"
                test_details = @{
                    created_by = "Start-AutonomousMonitoring.ps1"
                    purpose = "Verify FileSystemWatcher is detecting new files"
                    expected_action = "FileSystemWatcher should detect this file and process it"
                }
            } | ConvertTo-Json -Depth 3
            
            # Log the test file creation
            $testLog = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [TEST] Creating test file: $testFile"
            Add-Content -Path ".\unity_claude_automation.log" -Value $testLog
            
            Start-Sleep -Seconds 2  # Give watcher time to be ready
            
            # Use different write methods to ensure file creation triggers the watcher
            [System.IO.File]::WriteAllText($testFile, $testContent)
            
            # Force a file modification to trigger Changed event if Created doesn't fire
            Start-Sleep -Milliseconds 100
            Add-Content -Path $testFile -Value "`n"
            
            Write-Host "  Created test file: $testFileName" -ForegroundColor Green
            Write-Host "  File exists: $(Test-Path $testFile)" -ForegroundColor Green
            
            # Log successful test file creation
            $successLog = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [TEST] Test file created successfully: $testFile"
            Add-Content -Path ".\unity_claude_automation.log" -Value $successLog
            
            # Wait and check for event detection
            Start-Sleep -Seconds 5
            if (Test-Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous\.pending") {
                Write-Host "SUCCESS: Immediate test file was detected and queued!" -ForegroundColor Green
            } else {
                Write-Host "FAILURE: Immediate test file was NOT detected" -ForegroundColor Red
            }
        } catch {
            Write-Host "Error in immediate test: $($_.Exception.Message)" -ForegroundColor Red
        }
        Write-Host ''
        
        $counter = 1
        $pendingFilePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\ClaudeResponses\Autonomous\.pending"
        
        while ($true) {
            # Use Wait-Event instead of Start-Sleep to allow event handlers to execute
            # Reduced from 10 seconds to 2 seconds for faster response processing
            $event = Wait-Event -Timeout 2
            if ($event) {
                $eventDetails = "[$timestamp] Event received: $($event.SourceIdentifier), EventName: $($event.EventArgs)"
                Write-Host $eventDetails -ForegroundColor Yellow
                Remove-Event -EventIdentifier $event.EventIdentifier
            }
            
            $timestamp = Get-Date -Format 'HH:mm:ss'
            # CRITICAL FIX: Correct uptime calculation (2 second intervals, not 10)
            $uptime = $counter * 2
            
            # Add detailed FileSystemWatcher diagnostics every loop
            try {
                $watcherInfo = "Watcher Status: EnableRaisingEvents=$($result.Watcher.EnableRaisingEvents), Path=$($result.Watcher.Path), Filter=$($result.Watcher.Filter)"
                Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value "[$timestamp] [DEBUG] [MonitorLoop] $watcherInfo"
                
                $subscribers = Get-EventSubscriber | Where-Object { $_.SourceObject -is [System.IO.FileSystemWatcher] }
                $subInfo = "Event Subscribers: $($subscribers.Count) - $(($subscribers | ForEach-Object { $_.SourceIdentifier }) -join ', ')"
                Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value "[$timestamp] [DEBUG] [MonitorLoop] $subInfo"
            } catch {
                Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value "[$timestamp] [ERROR] [MonitorLoop] Error checking watcher status: $_"
            }
            
            # Check for pending files to process
            if (Test-Path $pendingFilePath) {
                try {
                    $queuedFile = Get-Content $pendingFilePath -ErrorAction Stop
                    Write-Host "[$timestamp] Processing queued file: $(Split-Path $queuedFile -Leaf)" -ForegroundColor Yellow
                    
                    # Log the processing attempt
                    Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [INFO] [AutonomousAgent] Processing queued file: $queuedFile"
                    
                    # Process the response file
                    if (Test-Path $queuedFile) {
                        $responseContent = Get-Content $queuedFile | ConvertFrom-Json -ErrorAction Stop
                        Write-Host "  Response: $($responseContent.response)" -ForegroundColor Cyan
                        
                        # Simplified response processing based on type
                        $responseText = $responseContent.response
                        Write-Host "  Response text: $responseText" -ForegroundColor Cyan
                        
                        if ($responseText -like "*RECOMMENDED:*" -or $responseText -like "*RECOMMENDATION:*") {
                            Write-Host "  FOUND RECOMMENDATION in response" -ForegroundColor Green
                            
                            # Determine recommendation type and handle accordingly
                            if ($responseText -like "*CONTINUE*") {
                                Write-Host "  TYPE: CONTINUE - Using response verbatim as next prompt" -ForegroundColor Magenta
                                
                                # Add critical directive to ensure Claude responds with a recommendation
                                $criticalDirective = @"

==================================================
CRITICAL: YOU MUST END YOUR RESPONSE WITH ONE OF:
[RECOMMENDATION: CONTINUE]
[RECOMMENDATION: TEST <Name>]
[RECOMMENDATION: FIX <File>]
[RECOMMENDATION: COMPILE]
[RECOMMENDATION: RESTART <Module>]
[RECOMMENDATION: COMPLETE]
==================================================
"@
                                
                                $nextPrompt = "$responseText`n`n$criticalDirective"
                                Write-Host "  EXECUTING: $nextPrompt" -ForegroundColor Green
                                
                                # Actually submit to Claude Code CLI
                                try {
                                    if (Get-Command "Submit-PromptToClaude" -ErrorAction SilentlyContinue) {
                                        Write-Host "  SUBMITTING TO CLAUDE CODE CLI..." -ForegroundColor Yellow
                                        
                                        # Check which version of Submit-PromptToClaude we have
                                        $submitCommand = Get-Command Submit-PromptToClaude
                                        $paramInfo = $submitCommand.Parameters["Prompt"] -or $submitCommand.Parameters["PromptText"]
                                        
                                        if ($submitCommand.Parameters.ContainsKey("PromptText")) {
                                            # Use the ClaudeIntegration version (expects string)
                                            Write-Host "  Using ClaudeIntegration version (string parameter)" -ForegroundColor Gray
                                            $result = Submit-PromptToClaude -PromptText $nextPrompt
                                        } elseif ($submitCommand.Parameters["Prompt"] -and $submitCommand.Parameters["Prompt"].ParameterType -eq [hashtable]) {
                                            # Use the AutonomousAgent version (expects hashtable)
                                            Write-Host "  Using AutonomousAgent version (hashtable parameter)" -ForegroundColor Gray
                                            $promptData = @{
                                                Text = $nextPrompt
                                                Type = "autonomous"
                                                Timestamp = Get-Date
                                            }
                                            $result = Submit-PromptToClaude -Prompt $promptData
                                        } else {
                                            # Try as string (fallback)
                                            Write-Host "  Using fallback string parameter" -ForegroundColor Gray
                                            $result = Submit-PromptToClaude -Prompt $nextPrompt
                                        }
                                        
                                        Write-Host "  Claude submission result: $result" -ForegroundColor Green
                                    } else {
                                        Write-Host "  Submit-PromptToClaude function not available" -ForegroundColor Red
                                    }
                                } catch {
                                    Write-Host "  Error submitting to Claude: $($_.Exception.Message)" -ForegroundColor Red
                                    Write-Host "  Error details: $($_.Exception.ToString())" -ForegroundColor Red
                                }
                                
                                Write-Host "  ACTION: Continue to Day 19 development phase" -ForegroundColor Yellow
                                
                            } elseif ($responseText -like "*TEST*") {
                                Write-Host "  TYPE: TEST - Extracting test name for execution" -ForegroundColor Magenta
                                
                                # Extract test name from the response (including hyphens and alphanumeric)
                                $testMatch = [regex]::Match($responseText, "TEST[:\s]+([\w\-]+)", [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
                                if ($testMatch.Success) {
                                    $testName = $testMatch.Groups[1].Value.Trim()
                                    Write-Host "  EXTRACTED TEST: $testName" -ForegroundColor Yellow
                                    Write-Host "  ACTION: Would run test: $testName" -ForegroundColor Yellow
                                    
                                    # Actually run the test if it exists
                                    $testScript = ".\Test-$testName.ps1"
                                    if (Test-Path $testScript) {
                                        Write-Host "  Found test script: $testScript" -ForegroundColor Green
                                        Write-Host "  Executing test..." -ForegroundColor Yellow
                                        try {
                                            & $testScript
                                            Write-Host "  Test completed successfully" -ForegroundColor Green
                                        } catch {
                                            Write-Host "  Test failed: $($_.Exception.Message)" -ForegroundColor Red
                                        }
                                    } else {
                                        Write-Host "  Test script not found: $testScript" -ForegroundColor Yellow
                                    }
                                } else {
                                    Write-Host "  Could not extract specific test name" -ForegroundColor Yellow
                                }
                                
                            } else {
                                Write-Host "  TYPE: UNKNOWN - Submitting to Claude Code CLI for interpretation" -ForegroundColor Magenta
                                
                                # Actually submit to Claude for unknown recommendation types
                                try {
                                    Write-Host "  Checking for Submit-PromptToClaude function..." -ForegroundColor Gray
                                    if (Get-Command "Submit-PromptToClaude" -ErrorAction SilentlyContinue) {
                                        Write-Host "  Submit-PromptToClaude is available, submitting..." -ForegroundColor Green
                                        
                                        # Add critical directive to ensure Claude responds with a recommendation
                                        $criticalDirective = @"

==================================================
CRITICAL: YOU MUST END YOUR RESPONSE WITH ONE OF:
[RECOMMENDATION: CONTINUE]
[RECOMMENDATION: TEST <Name>]
[RECOMMENDATION: FIX <File>]
[RECOMMENDATION: COMPILE]
[RECOMMENDATION: RESTART <Module>]
[RECOMMENDATION: COMPLETE]
[RECOMMENDATION: ERROR <Description>]
==================================================
"@
                                        
                                        # Use the full recommendation as the prompt with directive
                                        $promptText = "$responseText`n`n$criticalDirective"
                                        Write-Host "  PROMPT: $promptText" -ForegroundColor Yellow
                                        
                                        # Try submitting with different parameter names
                                        try {
                                            # Try PromptText parameter first
                                            $result = Submit-PromptToClaude -PromptText $promptText
                                        } catch {
                                            Write-Host "  PromptText parameter failed, trying Prompt parameter..." -ForegroundColor Yellow
                                            # Try Prompt parameter as fallback
                                            $result = Submit-PromptToClaude -Prompt $promptText
                                        }
                                        
                                        Write-Host "  Claude submission result: $result" -ForegroundColor Green
                                        Write-Host "  ACTION: Submitted unknown recommendation to Claude" -ForegroundColor Yellow
                                    } else {
                                        Write-Host "  ERROR: Submit-PromptToClaude function not available!" -ForegroundColor Red
                                        Write-Host "  Attempting to reload CLISubmission module..." -ForegroundColor Yellow
                                        
                                        $cliSubmissionPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLISubmission.psm1"
                                        if (Test-Path $cliSubmissionPath) {
                                            Import-Module $cliSubmissionPath -Force
                                            Write-Host "  CLISubmission module reloaded" -ForegroundColor Green
                                            
                                            # Try again after reload
                                            if (Get-Command "Submit-PromptToClaude" -ErrorAction SilentlyContinue) {
                                                $result = Submit-PromptToClaude -Prompt $promptText
                                                Write-Host "  Claude submission result: $result" -ForegroundColor Green
                                            }
                                        }
                                    }
                                } catch {
                                    Write-Host "  ERROR submitting to Claude: $($_.Exception.Message)" -ForegroundColor Red
                                    Write-Host "  Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
                                }
                            }
                            
                            Write-Host "  RECOMMENDATION PROCESSED SUCCESSFULLY" -ForegroundColor Green
                            
                        } else {
                            Write-Host "  No recommendation keywords found in response" -ForegroundColor Gray
                        }
                        
                        # Remove processed file from queue
                        Remove-Item $pendingFilePath -Force -ErrorAction SilentlyContinue
                        Write-Host "  File processed and removed from queue" -ForegroundColor Green
                    } else {
                        Write-Host "  Queued file no longer exists: $queuedFile" -ForegroundColor Yellow
                        Remove-Item $pendingFilePath -Force -ErrorAction SilentlyContinue
                    }
                } catch {
                    Write-Host "  Error processing queued file: $($_.Exception.Message)" -ForegroundColor Red
                    Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log" -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [ERROR] [AutonomousAgent] Error processing file: $($_.Exception.Message)"
                    
                    # Still remove the pending file to avoid reprocessing
                    Remove-Item $pendingFilePath -Force -ErrorAction SilentlyContinue
                    
                    # Continue monitoring instead of crashing
                    Write-Host "  Continuing monitoring despite error..." -ForegroundColor Yellow
                }
            } else {
                # Regular status update every 30 seconds (every 3rd loop)
                if ($counter % 3 -eq 0) {
                    Write-Host "[$timestamp] Autonomous monitoring active (uptime: $uptime seconds)" -ForegroundColor DarkGreen
                    
                    # Check FileSystemWatcher status
                    try {
                        if ($result.Watcher) {
                            $watcherStatus = "Active: $($result.Watcher.EnableRaisingEvents), Path: $($result.Watcher.Path)"
                            Write-Host "  FileSystemWatcher: $watcherStatus" -ForegroundColor Cyan
                            
                            # Check event subscribers
                            $subscribers = Get-EventSubscriber | Where-Object { $_.SourceObject -is [System.IO.FileSystemWatcher] }
                            Write-Host "  Event Subscribers: $($subscribers.Count)" -ForegroundColor Cyan
                            
                            if ($subscribers.Count -eq 0) {
                                Write-Host "  ERROR: FileSystemWatcher has no event subscribers!" -ForegroundColor Red
                            }
                        } else {
                            Write-Host "  ERROR: FileSystemWatcher object is null! Attempting to restart monitoring..." -ForegroundColor Red
                            
                            # Restart the FileSystemWatcher
                            try {
                                Write-Host "  Restarting Claude response monitoring..." -ForegroundColor Yellow
                                
                                # Clean up existing event subscribers first
                                Get-EventSubscriber | Where-Object { $_.SourceIdentifier -like "FSWatcher_*" } | Unregister-Event -Force
                                Write-Host "  Cleaned up existing event subscribers" -ForegroundColor Gray
                                
                                $newResult = Start-ClaudeResponseMonitoring
                                if ($newResult -and $newResult.Success) {
                                    $result = $newResult
                                    Write-Host "  FileSystemWatcher restarted successfully!" -ForegroundColor Green
                                } else {
                                    Write-Host "  Failed to restart FileSystemWatcher" -ForegroundColor Red
                                }
                            } catch {
                                Write-Host "  Error restarting FileSystemWatcher: $($_.Exception.Message)" -ForegroundColor Red
                            }
                        }
                    } catch {
                        Write-Host "  Error checking FileSystemWatcher status: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }
            
            $counter = $counter + 1
        }
    } else {
        Write-Host 'Failed to start monitoring!' -ForegroundColor Red
        if ($result -and $result.Error) {
            Write-Host "Error: $($result.Error)" -ForegroundColor Red
        }
        Read-Host 'Press Enter to close'
    }
    
} catch {
    Write-Host 'MONITORING ERROR:' -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host 'Press Enter to close'
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU4YhnQUhOnzwGlwZuNMHgUCKZ
# T9WgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUQnBJ1s45K2Bs3OEZ5t6JYnHwruowDQYJKoZIhvcNAQEBBQAEggEAEw4W
# qo6RLyCHydGV9Nmkv66mvc1jIKuJ+O6ecOq6VdeQDK2trY/15SiqbT4yp1qh0rWH
# IFj26m2XGagoi3124dp9AwzfgJP/0PNdywHDSV2+Cq2vrYbZoZTDM8rlnk89idLi
# 9UUQA7QoSBilESKUzUwd/Tz0J64pWvopOzkObl+4pj+fGp9xs56uqrfsOKnU/mtv
# A5Wk4eY2AP5UAu7Oyy18pV9MvKKdgsI/7f4u5OIKynnYoDPcbHRvimb9YFHV3j53
# 7dN/CCLXb+tw3035nWmlzYPD2gJWjHIwhAw+7D1PVqOdOUHVqy8vQChPcpqQWEur
# ekHcZWxhkK/hpj+kgQ==
# SIG # End signature block

