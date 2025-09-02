# Unity-Claude-AutonomousMonitoring.psm1
# Core autonomous monitoring functionality module
# Date: 2025-08-21

# Simple directive to append to recommendations
$script:SimpleDirective = " ================================================== CRITICAL: AT THE END OF YOUR RESPONSE, YOU MUST CREATE A RESPONSE .JSON FILE AT ./ClaudeResponses/Autonomous/ AND IN IT WRITE THE END OF YOUR RESPONSE, WHICH SHOULD END WITH: [RECOMMENDATION: CONTINUE]; [RECOMMENDATION: TEST <Name>]; [RECOMMENDATION: FIX <File>]; [RECOMMENDATION: COMPILE]; [RECOMMENDATION: RESTART <Module>]; [RECOMMENDATION: COMPLETE]; [RECOMMENDATION: ERROR <Description>]=================================================="

# Add Windows API functions for reliable window switching and input blocking
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class WindowAPI {
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
    
    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
    
    [DllImport("user32.dll")]
    public static extern bool BringWindowToTop(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    
    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
    
    // Mouse and keyboard blocking functions
    [DllImport("user32.dll")]
    public static extern bool BlockInput(bool fBlockIt);
    
    [DllImport("user32.dll")]
    public static extern IntPtr SetCapture(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern bool ReleaseCapture();
    
    [DllImport("user32.dll")]
    public static extern bool GetCursorPos(out POINT lpPoint);
    
    [DllImport("user32.dll")]
    public static extern bool SetCursorPos(int X, int Y);
    
    public struct POINT {
        public int X;
        public int Y;
    }
}
"@ -ErrorAction SilentlyContinue

# Load required assemblies for SendKeys functionality
Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
Add-Type -AssemblyName System.Drawing -ErrorAction SilentlyContinue

# Function to update Claude window info in system_status.json
function Update-ClaudeWindowInfo {
    param(
        [IntPtr]$WindowHandle,
        [int]$ProcessId, 
        [string]$WindowTitle,
        [string]$ProcessName
    )
    
    Write-Host "    Updating Claude window info in system_status.json..." -ForegroundColor Gray
    
    try {
        $systemStatusPath = ".\system_status.json"
        $systemStatus = @{}
        
        # Load existing status or create new
        if (Test-Path $systemStatusPath) {
            $systemStatus = Get-Content $systemStatusPath -Raw | ConvertFrom-Json -AsHashtable
        }
        
        # Ensure structure exists
        if (-not $systemStatus.SystemInfo) { $systemStatus.SystemInfo = @{} }
        if (-not $systemStatus.SystemInfo.ClaudeCodeCLI) { $systemStatus.SystemInfo.ClaudeCodeCLI = @{} }
        
        # Update Claude window information
        $systemStatus.SystemInfo.ClaudeCodeCLI.ProcessId = $ProcessId
        $systemStatus.SystemInfo.ClaudeCodeCLI.WindowHandle = [int64]$WindowHandle
        $systemStatus.SystemInfo.ClaudeCodeCLI.WindowTitle = $WindowTitle
        $systemStatus.SystemInfo.ClaudeCodeCLI.ProcessName = $ProcessName
        $systemStatus.SystemInfo.ClaudeCodeCLI.LastDetected = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
        $systemStatus.SystemInfo.ClaudeCodeCLI.DetectionMethod = "AutonomousAgent"
        
        # Save back to file
        $systemStatus | ConvertTo-Json -Depth 10 | Set-Content $systemStatusPath -Encoding UTF8
        
        Write-Host "    Claude window info updated successfully" -ForegroundColor Green
        Write-Host "    PID: $ProcessId, Handle: $WindowHandle, Title: '$WindowTitle'" -ForegroundColor Gray
        
    } catch {
        Write-Host "    Warning: Could not update system_status.json: $_" -ForegroundColor Yellow
    }
}

# Function to find Claude Code CLI window
function Find-ClaudeWindow {
    Write-Host "  Searching for Claude Code CLI window..." -ForegroundColor Gray
    
    # Method 1: Check system_status.json for comprehensive window info
    $systemStatusPath = ".\system_status.json"
    if (Test-Path $systemStatusPath) {
        try {
            $systemStatus = Get-Content $systemStatusPath -Raw | ConvertFrom-Json
            $claudeInfo = $systemStatus.SystemInfo.ClaudeCodeCLI
            
            if ($claudeInfo) {
                Write-Host "    Found Claude info in system_status.json" -ForegroundColor Gray
                
                # Try PID first
                if ($claudeInfo.ProcessId) {
                    $claudePID = $claudeInfo.ProcessId
                    Write-Host "    Checking registered PID: $claudePID" -ForegroundColor Gray
                    
                    $claudeProcess = Get-Process -Id $claudePID -ErrorAction SilentlyContinue
                    if ($claudeProcess -and $claudeProcess.MainWindowHandle -ne 0) {
                        # Verify the window title matches what we expect
                        if ($claudeInfo.WindowTitle -and $claudeProcess.MainWindowTitle -eq $claudeInfo.WindowTitle) {
                            Write-Host "    SUCCESS: Found Claude window from registered PID with matching title!" -ForegroundColor Green
                            Write-Host "    PID: $claudePID, Title: '$($claudeProcess.MainWindowTitle)'" -ForegroundColor Gray
                            return $claudeProcess.MainWindowHandle
                        } else {
                            Write-Host "    Warning: Window title changed (expected: '$($claudeInfo.WindowTitle)', actual: '$($claudeProcess.MainWindowTitle)')" -ForegroundColor Yellow
                        }
                    }
                }
                
                # Try window handle if available
                if ($claudeInfo.WindowHandle) {
                    Write-Host "    Trying stored window handle: $($claudeInfo.WindowHandle)" -ForegroundColor Gray
                    $processes = Get-Process | Where-Object { $_.MainWindowHandle -eq $claudeInfo.WindowHandle }
                    if ($processes) {
                        $proc = $processes[0]
                        Write-Host "    SUCCESS: Found window using stored handle!" -ForegroundColor Green
                        Write-Host "    Process: $($proc.ProcessName) (PID: $($proc.Id)), Title: '$($proc.MainWindowTitle)'" -ForegroundColor Gray
                        return $proc.MainWindowHandle
                    }
                }
            }
        } catch {
            Write-Host "    Could not read system_status.json: $_" -ForegroundColor Yellow
        }
    }
    
    # Method 2: Search by window title patterns (enhanced)
    $titlePatterns = @(
        "Claude Code CLI environment",           # Exact match first
        "*Claude Code CLI*",                     # Contains Claude Code CLI
        "*claude*code*cli*",                     # Flexible case
        "*claude*code*environment*",             # Environment variant
        "*Administrator: Windows PowerShell*claude*",  # Admin PowerShell with claude
        "*Windows PowerShell*claude*",          # Regular PowerShell with claude
        "*PowerShell*claude*code*",              # PowerShell with claude code
        "*pwsh*claude*",                         # PowerShell 7 with claude
        "*Terminal*claude*"                      # Windows Terminal with claude
    )
    
    Write-Host "    Checking all running processes with windows..." -ForegroundColor Gray
    $allProcesses = Get-Process | Where-Object { $_.MainWindowHandle -ne 0 }
    Write-Host "    Found $($allProcesses.Count) processes with windows" -ForegroundColor Gray
    
    foreach ($pattern in $titlePatterns) {
        $processes = $allProcesses | Where-Object { 
            $_.MainWindowTitle -like $pattern
        }
        
        if ($processes) {
            $claudeProcess = $processes[0]
            Write-Host "    SUCCESS: Found window matching pattern: $pattern" -ForegroundColor Green
            Write-Host "    Process: $($claudeProcess.ProcessName) (PID: $($claudeProcess.Id))" -ForegroundColor Gray
            Write-Host "    Title: '$($claudeProcess.MainWindowTitle)'" -ForegroundColor Gray
            Write-Host "    Handle: $($claudeProcess.MainWindowHandle)" -ForegroundColor Gray
            
            # Update system_status.json with found window info
            Update-ClaudeWindowInfo -WindowHandle $claudeProcess.MainWindowHandle -ProcessId $claudeProcess.Id -WindowTitle $claudeProcess.MainWindowTitle -ProcessName $claudeProcess.ProcessName
            
            return $claudeProcess.MainWindowHandle
        } else {
            Write-Host "    No match for pattern: $pattern" -ForegroundColor DarkGray
        }
    }
    
    Write-Host "    CRITICAL: No suitable windows found!" -ForegroundColor Red
    Write-Host "    Please ensure the Claude Code CLI window is open and visible" -ForegroundColor Yellow
    return $null
}

# Function to reliably switch to window
function Switch-ToWindow {
    param([IntPtr]$WindowHandle)
    
    if ($WindowHandle -eq 0 -or $WindowHandle -eq $null) {
        return $false
    }
    
    try {
        # Get current foreground window
        $currentWindow = [WindowAPI]::GetForegroundWindow()
        
        # Show the window if minimized (4 = SW_RESTORE)
        [WindowAPI]::ShowWindowAsync($WindowHandle, 4) | Out-Null
        Start-Sleep -Milliseconds 100
        
        # Bring to top
        [WindowAPI]::BringWindowToTop($WindowHandle) | Out-Null
        Start-Sleep -Milliseconds 100
        
        # Set as foreground window
        $result = [WindowAPI]::SetForegroundWindow($WindowHandle)
        
        if (-not $result) {
            # If SetForegroundWindow fails, try AttachThreadInput trick
            Write-Host "    Using AttachThreadInput for window switching..." -ForegroundColor Gray
            
            $currentThreadId = [WindowAPI]::GetCurrentThreadId()
            $targetProcessId = 0
            $targetThreadId = [WindowAPI]::GetWindowThreadProcessId($WindowHandle, [ref]$targetProcessId)
            
            if ($targetThreadId -ne 0 -and $currentThreadId -ne $targetThreadId) {
                [WindowAPI]::AttachThreadInput($currentThreadId, $targetThreadId, $true) | Out-Null
                [WindowAPI]::BringWindowToTop($WindowHandle) | Out-Null
                [WindowAPI]::SetForegroundWindow($WindowHandle) | Out-Null
                [WindowAPI]::AttachThreadInput($currentThreadId, $targetThreadId, $false) | Out-Null
            }
        }
        
        Start-Sleep -Milliseconds 500
        return $true
    } catch {
        Write-Host "    Error switching window: $_" -ForegroundColor Red
        return $false
    }
}

# Function to submit prompt to Claude via TypeKeys with input locking
function Submit-ToClaudeViaTypeKeys {
    param([string]$PromptText)
    
    Write-Host ""
    Write-Host "[SUBMISSION] Preparing to submit to Claude Code CLI..." -ForegroundColor Cyan
    Write-Host "  Press Ctrl+C within 3 seconds to abort submission..." -ForegroundColor Yellow
    
    # Abort window - give user chance to cancel
    for ($i = 3; $i -gt 0; $i--) {
        Write-Host "  Starting in $i seconds... (Ctrl+C to abort)" -ForegroundColor Yellow
        Start-Sleep -Seconds 1
    }
    
    try {
        # Find Claude window
        $claudeWindow = Find-ClaudeWindow
        
        if (-not $claudeWindow) {
            Write-Host "  Failed to find Claude Code CLI window!" -ForegroundColor Red
            return $false
        }
        
        # Switch to Claude window
        Write-Host "  Switching to Claude window..." -ForegroundColor Gray
        $switched = Switch-ToWindow -WindowHandle $claudeWindow
        
        if (-not $switched) {
            Write-Host "  Failed to switch to Claude window!" -ForegroundColor Red
            return $false
        }
        
        Write-Host "  Window switched successfully!" -ForegroundColor Green
        
        # Block user input during typing to prevent interference
        Write-Host "  BLOCKING MOUSE AND KEYBOARD INPUT..." -ForegroundColor Magenta
        $inputBlocked = $false
        
        try {
            # Get current cursor position to restore later
            $cursorPos = New-Object WindowAPI+POINT
            [WindowAPI]::GetCursorPos([ref]$cursorPos) | Out-Null
            
            # Use window capture instead of BlockInput (more reliable)
            $captureResult = [WindowAPI]::SetCapture($claudeWindow)
            if ($captureResult -ne [IntPtr]::Zero) {
                Write-Host "  Window capture ACTIVE - input locked to Claude window!" -ForegroundColor Magenta
                $inputBlocked = $true
            } else {
                # Fallback: Try BlockInput (requires admin rights)
                $inputBlocked = [WindowAPI]::BlockInput($true)
                if ($inputBlocked) {
                    Write-Host "  Input blocking ACTIVE - hands off keyboard/mouse!" -ForegroundColor Magenta
                } else {
                    Write-Host "  Warning: Could not block input (may require admin rights)" -ForegroundColor Yellow
                    # Last resort: Just warn user and proceed
                    Write-Host "  IMPORTANT: DO NOT TOUCH KEYBOARD OR MOUSE DURING TYPING!" -ForegroundColor Red
                }
            }
            
            # Clear current input and type new prompt
            Write-Host "  Clearing input..." -ForegroundColor Gray
            [System.Windows.Forms.SendKeys]::SendWait("^a")  # Select all
            Start-Sleep -Milliseconds 200
            [System.Windows.Forms.SendKeys]::SendWait("{DEL}")  # Delete
            Start-Sleep -Milliseconds 200
            
            # Type the prompt as single line (no newlines for autonomous prompts)
            Write-Host "  Typing prompt ($(($PromptText.Length)) characters)..." -ForegroundColor Gray
            Write-Host "  Using single-line input method" -ForegroundColor Gray
            
            # Remove any newlines and escape special characters for SendKeys
            $singleLinePrompt = $PromptText -replace "`n", " " -replace "`r", ""
            $escapedPrompt = $singleLinePrompt -replace '{', '{{' `
                                               -replace '}', '}}' `
                                               -replace '\+', '{+}' `
                                               -replace '\^', '{^}' `
                                               -replace '%', '{%}' `
                                               -replace '~', '{~}' `
                                               -replace '\(', '{(}' `
                                               -replace '\)', '{)}'
            
            # Type the entire prompt as one line
            [System.Windows.Forms.SendKeys]::SendWait($escapedPrompt)
            
            Write-Host "  Prompt typed successfully!" -ForegroundColor Green
            
            # Auto-submit with Enter
            Write-Host "  Submitting prompt..." -ForegroundColor Cyan
            Start-Sleep -Milliseconds 500
            [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
            
            Write-Host "  PROMPT SUBMITTED TO CLAUDE!" -ForegroundColor Green
            
        } finally {
            # Always release input blocking
            if ($inputBlocked) {
                # Release window capture first
                [WindowAPI]::ReleaseCapture() | Out-Null
                
                # Release BlockInput if it was used
                [WindowAPI]::BlockInput($false) | Out-Null
                
                Write-Host "  Input blocking RELEASED - you can use mouse/keyboard again" -ForegroundColor Green
                
                # Restore cursor position
                if ($cursorPos) {
                    [WindowAPI]::SetCursorPos($cursorPos.X, $cursorPos.Y) | Out-Null
                }
            }
        }
        
        return $true
    } catch {
        Write-Host "  ERROR: Submission failed: $_" -ForegroundColor Red
        
        # Release input blocking on error too
        try {
            [WindowAPI]::ReleaseCapture() | Out-Null
            [WindowAPI]::BlockInput($false) | Out-Null
            Write-Host "  Input blocking released due to error" -ForegroundColor Yellow
        } catch {}
        
        # Ensure input is unblocked even on error
        try {
            [WindowAPI]::BlockInput($false) | Out-Null
            Write-Host "  Input blocking released due to error" -ForegroundColor Yellow
        } catch {
            Write-Host "  Warning: Could not release input block: $_" -ForegroundColor Yellow
        }
        
        return $false
    }
}

# Function to execute test scripts and capture results
function Execute-TestScript {
    param(
        [string]$ScriptPath,
        [string]$Description
    )
    
    Write-Host ""
    Write-Host "[TEST EXECUTION] Running test script..." -ForegroundColor Magenta
    
    try {
        # Generate timestamp for result files
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $testName = [System.IO.Path]::GetFileNameWithoutExtension($ScriptPath)
        $resultFile = ".\Test_Results_${testName}_${timestamp}.txt"
        
        Write-Host "  Script: $ScriptPath" -ForegroundColor Gray
        Write-Host "  Description: $Description" -ForegroundColor Gray
        Write-Host "  Result file: $resultFile" -ForegroundColor Gray
        
        # Check if test script exists
        if (-not (Test-Path $ScriptPath)) {
            $errorMessage = "Test script not found: $ScriptPath"
            Write-Host "  ERROR: $errorMessage" -ForegroundColor Red
            
            # Create error result file
            $errorResult = @{
                TestScript = $ScriptPath
                Description = $Description
                Status = "FAILED"
                Error = $errorMessage
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
                ExecutionTime = "0ms"
            }
            $errorResult | ConvertTo-Json | Set-Content $resultFile -Encoding UTF8
            
            return "Test execution failed: Script not found at $ScriptPath. Error details saved to $resultFile."
        }
        
        Write-Host "  Executing test directly (no separate window to avoid interference)..." -ForegroundColor Yellow
        
        # Execute test directly in current session to avoid window interference
        $testStartTime = Get-Date
        
        try {
            # Capture all output including errors
            $output = & $ScriptPath 2>&1
            $testEndTime = Get-Date
            $executionTime = ($testEndTime - $testStartTime).TotalMilliseconds
            
            Write-Host "  Test completed successfully!" -ForegroundColor Green
            
            # Create result object
            $result = @{
                TestScript = $ScriptPath
                Description = $Description
                Status = "SUCCESS"
                Output = $output | Out-String
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
                ExecutionTime = "$($executionTime)ms"
                ExitCode = 0
            }
            
        } catch {
            $testEndTime = Get-Date
            $executionTime = ($testEndTime - $testStartTime).TotalMilliseconds
            
            Write-Host "  Test failed with exception: $_" -ForegroundColor Red
            
            # Create error result object
            $result = @{
                TestScript = $ScriptPath
                Description = $Description
                Status = "FAILED"
                Output = $_.Exception.Message
                Error = $_.Exception.ToString()
                StackTrace = $_.ScriptStackTrace
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
                ExecutionTime = "$($executionTime)ms"
                ExitCode = 1
            }
        }
        
        # Save results to file
        Write-Host "  Saving results to: $resultFile" -ForegroundColor Gray
        $result | ConvertTo-Json -Depth 10 | Set-Content $resultFile -Encoding UTF8
        
        $status = if ($result.Status -eq "SUCCESS") { "PASSED" } else { "FAILED" }
        $summary = "Test $status - $($result.Description). Execution time: $($result.ExecutionTime). Full results: $resultFile"
        
        Write-Host "  Test Status: $($result.Status)" -ForegroundColor $(if ($result.Status -eq "SUCCESS") { "Green" } else { "Red" })
        Write-Host "  Result File: $resultFile" -ForegroundColor Cyan
        
        return $summary
        
    } catch {
        Write-Host "  ERROR executing test: $_" -ForegroundColor Red
        return "Test execution failed with error: $($_.Exception.Message)"
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
        
        # Extract only the RECOMMENDATION line from the response
        $recommendationLine = ""
        $lines = $responseText -split "`n"
        
        Write-Host "  DEBUG: Response has $($lines.Count) lines" -ForegroundColor Gray
        
        foreach ($line in $lines) {
            $trimmedLine = $line.Trim()
            if ($trimmedLine -match "^RECOMMENDATION:") {
                $recommendationLine = $trimmedLine
                Write-Host "  DEBUG: Found RECOMMENDATION line: $recommendationLine" -ForegroundColor Gray
                break
            }
        }
        
        if (-not $recommendationLine) {
            Write-Host "  ERROR: No RECOMMENDATION line found in response!" -ForegroundColor Red
            Write-Host "  DEBUG: First 500 chars of response: $($responseText.Substring(0, [Math]::Min(500, $responseText.Length)))" -ForegroundColor Gray
            return
        }
        
        # Check if this is a TEST recommendation and handle accordingly
        if ($recommendationLine -match "^RECOMMENDATION:\s*TEST\s*-\s*(.+\.ps1)\s+-\s+(.+)$") {
            $testScriptPath = $matches[1].Trim()
            $testDescription = $matches[2].Trim()
            
            Write-Host "  DETECTED: TEST recommendation!" -ForegroundColor Magenta
            Write-Host "  Test Script: $testScriptPath" -ForegroundColor Cyan
            Write-Host "  Description: $testDescription" -ForegroundColor Cyan
            
            # Execute the test and create response
            $testResult = Execute-TestScript -ScriptPath $testScriptPath -Description $testDescription
            $nextPrompt = $testResult + $script:SimpleDirective
        } else {
            # Regular recommendation - create simple prompt with just the recommendation and directive
            $nextPrompt = $recommendationLine + $script:SimpleDirective
        }
        
        Write-Host "  Extracted recommendation: $recommendationLine" -ForegroundColor Cyan
        Write-Host "  Prepared prompt for submission (total: $($nextPrompt.Length) chars)" -ForegroundColor Cyan
        
        # Submit to Claude
        Write-Host "  Submitting to Claude via TypeKeys..." -ForegroundColor Cyan
        $submitted = Submit-ToClaudeViaTypeKeys -PromptText $nextPrompt
        
        if ($submitted) {
            Write-Host "  SUCCESSFULLY SUBMITTED TO CLAUDE!" -ForegroundColor Green
            
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

# Main autonomous monitoring function
function Start-AutonomousMonitoring {
    param(
        [int]$PollIntervalSeconds = 5,
        [switch]$DebugMode
    )
    
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host "AUTONOMOUS MONITORING (MODULE VERSION)" -ForegroundColor Cyan
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""
    
    # Get process ID for tracking
    $agentPID = $PID
    Write-Host "AutonomousAgent Process ID: $agentPID" -ForegroundColor Yellow
    
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
    Write-Host "  2. Find Claude Code CLI window (from system_status.json or title)" -ForegroundColor Gray
    Write-Host "  3. Switch to the correct window" -ForegroundColor Gray
    Write-Host "  4. Type prompt with critical directive" -ForegroundColor Gray
    Write-Host "  5. Auto-submit with Enter key" -ForegroundColor Gray
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
                
                # Only remove pending file if it exists
                if (Test-Path $pendingFile) {
                    Remove-Item $pendingFile -Force -ErrorAction SilentlyContinue
                }
            } catch {
                if ($_.Exception.Message -notlike "*Cannot find path*") {
                    Write-Host "[$timestamp] Error processing pending file: $_" -ForegroundColor Red
                }
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
}

# Export all functions defined in this module
Export-ModuleMember -Function @(
    'Start-AutonomousMonitoring',
    'Find-ClaudeWindow',
    'Switch-ToWindow', 
    'Submit-ToClaudeViaTypeKeys',
    'Execute-TestScript',
    'Process-ResponseFile',
    'Update-ClaudeWindowInfo'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBwiPVSdxuJhalX
# ey7o8euPmyhyUjIcgOx645fP9FJDgaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFhn6BbpitRM40fKq8D27Wno
# w97/Nciq09/bBI1ohYe6MA0GCSqGSIb3DQEBAQUABIIBAKjW74AflFMQ81VdRhCI
# UdPIoyW1Tn/f/yMCQBUAw2pcLdoswBx6HLHNKPhC8vF1A70V6MLQoDZG3c5z4+Jd
# N5c/yX9Rc6iwiiE/D2tKJrLIWGJPVfv8QBZ4plOxZIPqLSM1BvFJJHznCBDNNH+t
# y7CjpQViU9GYVvVeMTwKM06nYced4KMNxf869mZehupQLtqJby5V0NCvRaihbSw3
# 5wjSg16kIBURyqqNawtT9dfRj+389jUw0KrMPiTx2hHikn3uyAKMWv4OJ6z6BJNE
# 8XNHusxW2Pd8hmDkGFHq2HLqPzBVy7QnGwfICnAR6hUfXd5ek/zJV1tQlkn66V97
# WMM=
# SIG # End signature block
