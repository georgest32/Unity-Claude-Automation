# Unity-Claude-CLIOrchestrator.psm1
# Core autonomous monitoring functionality module
# Date: 2025-08-21

# Import nested modules (Phase 7 Implementation)
$ModuleRoot = $PSScriptRoot
. "$ModuleRoot\Core\ResponseAnalysisEngine.psm1"
. "$ModuleRoot\Core\PatternRecognitionEngine.psm1"
. "$ModuleRoot\Core\DecisionEngine.psm1"
. "$ModuleRoot\Core\ActionExecutionEngine.psm1"

# Simple directive to append to recommendations
$script:SimpleDirective = " ================================================== CRITICAL: AT THE END OF YOUR RESPONSE, YOU MUST CREATE A RESPONSE .JSON FILE AT ./ClaudeResponses/Autonomous/ AND IN IT WRITE THE END OF YOUR RESPONSE, WHICH SHOULD END WITH: [RECOMMENDATION: CONTINUE]; [RECOMMENDATION: TEST <Name>]; [RECOMMENDATION: FIX <File>]; [RECOMMENDATION: COMPILE]; [RECOMMENDATION: RESTART <Module>]; [RECOMMENDATION: COMPLETE]; [RECOMMENDATION: ERROR <Description>]=================================================="

# Full boilerplate prompt stored as a resource
$script:BoilerplatePrompt = $null
try {
    $boilerplatePath = Join-Path $PSScriptRoot "Resources\BoilerplatePrompt.txt"
    if (Test-Path $boilerplatePath) {
        $script:BoilerplatePrompt = Get-Content -Path $boilerplatePath -Raw
    }
} catch {
    Write-Host "Warning: Could not load boilerplate prompt file: $_" -ForegroundColor Yellow
}

if (-not $script:BoilerplatePrompt) {
    # Fallback to simple directive if file not found
    $script:BoilerplatePrompt = "Please process the following recommendation and provide a detailed response."
}

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

# Helper function to properly serialize complex objects to strings
function Convert-ToSerializedString {
    param(
        [Parameter(Mandatory = $false)]
        $InputObject
    )
    
    # Handle null or empty input
    if ($null -eq $InputObject) {
        return ""
    }
    
    # If already a string, return as-is
    if ($InputObject -is [string]) {
        return $InputObject
    }
    
    # Handle hashtables
    if ($InputObject -is [hashtable]) {
        # Check for common file path properties
        $pathProperties = @('Path', 'FilePath', 'FullName', 'ImplementationPlan', 'File', 'Document')
        
        foreach ($prop in $pathProperties) {
            if ($InputObject.ContainsKey($prop) -and $InputObject[$prop]) {
                return $InputObject[$prop].ToString()
            }
        }
        
        # If no path properties found, check for week priorities (implementation plan structure)
        if ($InputObject.ContainsKey('week_1_priorities')) {
            # This looks like an implementation plan object
            # Try to find the actual implementation plan file path
            $planDetails = @()
            
            # Check each week for file paths
            for ($i = 1; $i -le 4; $i++) {
                $weekKey = "week_${i}_priorities"
                if ($InputObject.ContainsKey($weekKey)) {
                    $weekData = $InputObject[$weekKey]
                    if ($weekData -is [string]) {
                        $planDetails += $weekData
                    } elseif ($weekData -is [array] -and $weekData.Count -gt 0) {
                        # Extract first item if it's a path
                        $firstItem = $weekData[0]
                        if ($firstItem -is [string] -and $firstItem -match '\.(md|txt|json)$') {
                            return $firstItem
                        }
                    }
                }
            }
            
            # If we found plan details but no file path, describe the structure
            if ($planDetails.Count -gt 0) {
                return "Implementation plan with " + $planDetails.Count + " week priorities"
            }
        }
        
        # Fallback to JSON serialization for complex objects
        try {
            $json = $InputObject | ConvertTo-Json -Depth 5 -Compress
            # If JSON is too long, truncate and add indicator
            if ($json.Length -gt 200) {
                return $json.Substring(0, 197) + "..."
            }
            return $json
        } catch {
            # If JSON conversion fails, try to get keys
            if ($InputObject -is [hashtable]) {
                $keys = $InputObject.Keys -join ', '
                return "Hashtable with keys: $keys"
            }
            return "Complex object of type: " + $InputObject.GetType().Name
        }
    }
    
    # Handle PSCustomObjects separately
    if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
        # Check for common file path properties
        $pathProperties = @('Path', 'FilePath', 'FullName', 'ImplementationPlan', 'File', 'Document')
        
        foreach ($prop in $pathProperties) {
            if ($InputObject.PSObject.Properties.Name -contains $prop) {
                $value = $InputObject.PSObject.Properties[$prop].Value
                if ($value) {
                    return $value.ToString()
                }
            }
        }
        
        # If no path properties found, check for week priorities
        if ($InputObject.PSObject.Properties.Name -contains 'week_1_priorities') {
            $weekData = $InputObject.week_1_priorities
            if ($weekData -is [string]) {
                return $weekData
            } elseif ($weekData -is [array] -and $weekData.Count -gt 0) {
                $firstItem = $weekData[0]
                if ($firstItem -is [string] -and $firstItem -match '\.(md|txt|json)$') {
                    return $firstItem
                }
            }
        }
        
        # Fallback to JSON for PSCustomObjects
        try {
            $json = $InputObject | ConvertTo-Json -Depth 5 -Compress
            if ($json.Length -gt 200) {
                return $json.Substring(0, 197) + "..."
            }
            return $json
        } catch {
            return "PSCustomObject with properties: " + ($InputObject.PSObject.Properties.Name -join ', ')
        }
    }
    
    # For arrays, join elements
    if ($InputObject -is [array]) {
        if ($InputObject.Count -eq 0) {
            return "Empty array"
        }
        # Check if first element is a file path
        if ($InputObject[0] -is [string] -and $InputObject[0] -match '^[A-Z]:\\' -and $InputObject[0] -match '\.(md|txt|json|ps1|psm1)$') {
            return $InputObject[0]  # Return the first file path
        }
        # Join first few elements
        $preview = ($InputObject | Select-Object -First 3) -join ', '
        if ($InputObject.Count -gt 3) {
            $preview += "... (" + $InputObject.Count + " items total)"
        }
        return $preview
    }
    
    # Default: convert to string
    return $InputObject.ToString()
}

# Enhanced function to generate a complete autonomous prompt
function New-AutonomousPrompt {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RecommendationType,
        
        [Parameter()]
        $ActionDetails = "",  # Changed from [string] to allow any type
        
        [Parameter()]
        [hashtable]$Context = @{},
        
        [Parameter()]
        [string]$TestResultPath,
        
        [Parameter()]
        [switch]$IncludeBoilerplate
    )
    
    Write-Host "[PROMPT GENERATION] Creating autonomous prompt for: $RecommendationType" -ForegroundColor Cyan
    
    # Properly serialize ActionDetails if it's not a string
    $serializedDetails = Convert-ToSerializedString -InputObject $ActionDetails
    Write-Host "  Action Details Type: $($ActionDetails.GetType().Name)" -ForegroundColor Gray
    if ($ActionDetails -isnot [string]) {
        Write-Host "  Serialized to: $serializedDetails" -ForegroundColor Yellow
    }
    
    # Determine prompt type based on recommendation
    $promptType = switch ($RecommendationType) {
        "TEST" { "Test Results" }
        "FIX" { "Debugging" }
        "CONTINUE" { "Continue Implementation Plan" }
        "COMPILE" { "Debugging" }
        "RESTART" { "Debugging" }
        "COMPLETE" { "Review" }
        "ERROR" { "Debugging" }
        default { "Continue Implementation Plan" }
    }
    
    Write-Host "  Prompt Type: $promptType" -ForegroundColor Gray
    
    # Build the specific request based on recommendation type
    $specificRequest = switch ($RecommendationType) {
        "TEST" {
            if ($TestResultPath -and (Test-Path $TestResultPath)) {
                $testContent = Get-Content $TestResultPath -Raw
                "Prompt-type: Test Results`n`nTest results from $serializedDetails have been generated and saved to $TestResultPath. Please review the results and determine next steps.`n`nTest Output:`n$testContent"
            } else {
                "Prompt-type: Test Results`n`nTest $serializedDetails has been executed. Please review the results and determine next steps."
            }
        }
        "FIX" {
            "Prompt-type: Debugging`n`nErrors have been detected in $serializedDetails. Please review and fix the issues."
        }
        "CONTINUE" {
            # Special handling for Continue to ensure proper path/plan reference
            if ($serializedDetails) {
                "Prompt-type: Continue Implementation Plan`n`nPlease continue with the implementation plan set out in $serializedDetails. Review the implementation plan and current codebase to determine which step is next."
            } else {
                "Prompt-type: Continue Implementation Plan`n`nPlease continue with the implementation plan. Review the current codebase and documentation to determine which step is next."
            }
        }
        "COMPILE" {
            "Prompt-type: Debugging`n`nCompilation has been triggered. Please review any compilation errors and address them."
        }
        "RESTART" {
            "Prompt-type: Debugging`n`nModule $serializedDetails has been restarted. Please verify functionality and continue."
        }
        "COMPLETE" {
            "Prompt-type: Review`n`nTask appears to be complete. Please perform a comprehensive review and confirm completion."
        }
        "ERROR" {
            "Prompt-type: Debugging`n`nAn error has occurred: $serializedDetails. Please investigate and resolve."
        }
        default {
            "Prompt-type: Continue Implementation Plan`n`nPlease continue processing. $serializedDetails"
        }
    }
    
    # Add context information if provided
    if ($Context.Count -gt 0) {
        $contextInfo = "`n`nContext Information:"
        foreach ($key in $Context.Keys) {
            $contextInfo += "`n- ${key}: $($Context[$key])"
        }
        $specificRequest += $contextInfo
    }
    
    # Build complete prompt
    if ($IncludeBoilerplate) {
        # Insert specific request after the boilerplate
        $completePrompt = $script:BoilerplatePrompt -replace '\*\*\*END OF BOILERPLATE\*\*\*', "***END OF BOILERPLATE***`n`n$specificRequest"
        
        # Add the critical directive at the end
        $completePrompt += "`n`n$script:SimpleDirective"
    } else {
        # Just the specific request with directive
        $completePrompt = $specificRequest + "`n`n$script:SimpleDirective"
    }
    
    Write-Host "  Generated prompt: $(($completePrompt.Length)) characters" -ForegroundColor Gray
    
    return $completePrompt
}

# Enhanced function to retrieve and summarize action results
function Get-ActionResultSummary {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ActionType,
        
        [Parameter()]
        [string]$ResultPath,
        
        [Parameter()]
        [hashtable]$ExecutionResult
    )
    
    Write-Host "[RESULT SUMMARY] Retrieving results for: $ActionType" -ForegroundColor Magenta
    
    $summary = @{
        ActionType = $ActionType
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        Success = $false
        Summary = ""
        Details = @{}
    }
    
    try {
        switch ($ActionType) {
            "TEST" {
                if ($ResultPath -and (Test-Path $ResultPath)) {
                    $testResult = Get-Content $ResultPath -Raw | ConvertFrom-Json
                    $summary.Success = ($testResult.Status -eq "SUCCESS")
                    $summary.Summary = "Test $($testResult.TestScript): $($testResult.Status). Execution time: $($testResult.ExecutionTime)"
                    $summary.Details = $testResult
                } elseif ($ExecutionResult) {
                    $summary.Success = $ExecutionResult.Success
                    $summary.Summary = "Test execution: $(if ($ExecutionResult.Success) { 'PASSED' } else { 'FAILED' })"
                    $summary.Details = $ExecutionResult
                }
            }
            "FIX" {
                if ($ExecutionResult) {
                    $summary.Success = $ExecutionResult.Success
                    $summary.Summary = "Fix applied: $(if ($ExecutionResult.Success) { 'Successfully' } else { 'Failed' })"
                    $summary.Details = $ExecutionResult
                }
            }
            "COMPILE" {
                if ($ExecutionResult) {
                    $summary.Success = $ExecutionResult.Success
                    $summary.Summary = "Compilation: $(if ($ExecutionResult.Success) { 'Succeeded' } else { 'Failed with errors' })"
                    $summary.Details = $ExecutionResult
                }
            }
            default {
                $summary.Success = $true
                $summary.Summary = "Action $ActionType completed"
                if ($ExecutionResult) {
                    $summary.Details = $ExecutionResult
                }
            }
        }
        
        Write-Host "  Summary: $($summary.Summary)" -ForegroundColor $(if ($summary.Success) { "Green" } else { "Red" })
        
    } catch {
        Write-Host "  Error summarizing results: $_" -ForegroundColor Red
        $summary.Summary = "Error retrieving results: $($_.Exception.Message)"
    }
    
    return $summary
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
        
        # Enhanced recommendation processing with full autonomous capabilities
        Write-Host "  Processing recommendation: $recommendationLine" -ForegroundColor Cyan
        
        # Parse the recommendation components
        $recommendationType = ""
        $actionDetails = ""
        $testResultPath = $null
        
        if ($recommendationLine -match "^RECOMMENDATION:\s*(\w+)\s*(-\s*(.+))?$") {
            $recommendationType = $matches[1].Trim()
            $actionDetails = if ($matches[3]) { $matches[3].Trim() } else { "" }
            
            Write-Host "  Type: $recommendationType" -ForegroundColor Gray
            Write-Host "  Details: $actionDetails" -ForegroundColor Gray
        }
        
        # Handle different recommendation types
        $executionResult = $null
        $context = @{}
        
        switch ($recommendationType) {
            "TEST" {
                # Extract test script path from details
                if ($actionDetails -match "(.+\.ps1)\s*:\s*(.+)") {
                    $testScriptPath = $matches[1].Trim()
                    $testDescription = $matches[2].Trim()
                } else {
                    # Handle simple format
                    $parts = $actionDetails -split '\s+', 2
                    $testScriptPath = $parts[0]
                    $testDescription = if ($parts.Count -gt 1) { $parts[1] } else { "Test execution" }
                }
                
                Write-Host "  DETECTED: TEST recommendation!" -ForegroundColor Magenta
                Write-Host "  Test Script: $testScriptPath" -ForegroundColor Cyan
                Write-Host "  Description: $testDescription" -ForegroundColor Cyan
                
                # Execute the test
                $testResult = Execute-TestScript -ScriptPath $testScriptPath -Description $testDescription
                
                # Get the test result file path
                $testFiles = Get-ChildItem -Path "." -Filter "Test_Results_*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                if ($testFiles) {
                    $testResultPath = $testFiles.FullName
                    $context["TestResultFile"] = $testFiles.Name
                }
                
                # Summarize results
                $resultSummary = Get-ActionResultSummary -ActionType "TEST" -ResultPath $testResultPath
                $context["TestStatus"] = if ($resultSummary.Success) { "PASSED" } else { "FAILED" }
            }
            "FIX" {
                Write-Host "  DETECTED: FIX recommendation for: $actionDetails" -ForegroundColor Magenta
                # For now, we'll prepare the context but actual fix would need implementation
                $context["TargetFile"] = $actionDetails
                $context["Action"] = "Fix requested"
            }
            "COMPILE" {
                Write-Host "  DETECTED: COMPILE recommendation" -ForegroundColor Magenta
                $context["CompilationRequested"] = $true
                # Actual compilation would be handled by Unity or build system
            }
            "RESTART" {
                Write-Host "  DETECTED: RESTART recommendation for: $actionDetails" -ForegroundColor Magenta
                $context["ModuleToRestart"] = $actionDetails
            }
            "COMPLETE" {
                Write-Host "  DETECTED: COMPLETE recommendation" -ForegroundColor Green
                $context["TaskCompleted"] = $true
            }
            "ERROR" {
                Write-Host "  DETECTED: ERROR recommendation: $actionDetails" -ForegroundColor Red
                $context["ErrorDescription"] = $actionDetails
            }
            default {
                Write-Host "  DETECTED: CONTINUE or custom recommendation" -ForegroundColor Gray
                $context["ContinuationRequested"] = $true
            }
        }
        
        # Generate the autonomous prompt with full boilerplate
        $nextPrompt = New-AutonomousPrompt `
            -RecommendationType $recommendationType `
            -ActionDetails $actionDetails `
            -Context $context `
            -TestResultPath $testResultPath `
            -IncludeBoilerplate $true
        
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

# Enhanced autonomous decision and execution loop
function Invoke-AutonomousExecutionLoop {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseFilePath,
        
        [Parameter()]
        [switch]$AutoSubmit = $true,
        
        [Parameter()]
        [switch]$SafeMode = $false
    )
    
    Write-Host ""
    Write-Host "[AUTONOMOUS EXECUTION] Starting enhanced autonomous loop" -ForegroundColor Cyan
    Write-Host "=========================================" -ForegroundColor Cyan
    
    try {
        # Step 1: Read and analyze the response
        Write-Host "[Step 1] Reading response file..." -ForegroundColor Yellow
        $responseContent = Get-Content $ResponseFilePath -Raw
        $responseJson = $responseContent | ConvertFrom-Json
        
        # Step 2: Comprehensive response analysis
        Write-Host "[Step 2] Performing comprehensive response analysis..." -ForegroundColor Yellow
        $analysisResult = Invoke-ComprehensiveResponseAnalysis -ResponseContent $responseJson.response
        
        Write-Host "  Found $($analysisResult.Recommendations.Count) recommendations" -ForegroundColor Gray
        Write-Host "  Overall confidence: $($analysisResult.ConfidenceAnalysis.OverallConfidence)" -ForegroundColor Gray
        Write-Host "  Quality rating: $($analysisResult.OverallQuality)" -ForegroundColor Gray
        
        # Step 3: Autonomous decision making
        Write-Host "[Step 3] Making autonomous decision..." -ForegroundColor Yellow
        $decisionResult = Invoke-AutonomousDecisionMaking `
            -ResponseContent $responseJson.response `
            -DryRun:$SafeMode `
            -AutoExecute:(-not $SafeMode)
        
        Write-Host "  Decision: $($decisionResult.Decision.Decision)" -ForegroundColor Cyan
        Write-Host "  Priority: $($decisionResult.Decision.Priority)" -ForegroundColor Gray
        Write-Host "  Safety: $($decisionResult.SafetyLevel)" -ForegroundColor Gray
        
        # Step 4: Execute the decided action
        Write-Host "[Step 4] Executing action..." -ForegroundColor Yellow
        $executionResult = $null
        
        if (-not $SafeMode -and $decisionResult.SafetyValidated) {
            # Execute based on decision type
            switch ($decisionResult.Decision.Decision) {
                "TEST" {
                    # Extract test details from the action
                    $testPath = ""
                    $testDescription = $decisionResult.Decision.Action
                    
                    if ($decisionResult.Analysis.Entities.FilePaths) {
                        $testPath = $decisionResult.Analysis.Entities.FilePaths[0]
                        if ($testPath -is [hashtable]) {
                            $testPath = $testPath.Value
                        }
                    }
                    
                    if ($testPath -and (Test-Path $testPath)) {
                        Write-Host "  Executing test: $testPath" -ForegroundColor Magenta
                        $executionResult = Execute-TestScript -ScriptPath $testPath -Description $testDescription
                    } else {
                        Write-Host "  Test path not found or not specified" -ForegroundColor Yellow
                        $executionResult = "Test execution skipped - path not found"
                    }
                }
                "FIX" {
                    Write-Host "  Processing fix action..." -ForegroundColor Magenta
                    # Actual fix implementation would go here
                    $executionResult = "Fix action prepared for manual execution"
                }
                "COMPILE" {
                    Write-Host "  Compilation requested..." -ForegroundColor Magenta
                    $executionResult = "Compilation request prepared"
                }
                "RESTART" {
                    Write-Host "  Restart requested for: $($decisionResult.Decision.Action)" -ForegroundColor Magenta
                    $executionResult = "Restart prepared for: $($decisionResult.Decision.Action)"
                }
                "COMPLETE" {
                    Write-Host "  Task marked as complete" -ForegroundColor Green
                    $executionResult = "Task completion confirmed"
                }
                "ERROR" {
                    Write-Host "  Error handling: $($decisionResult.Decision.Action)" -ForegroundColor Red
                    $executionResult = "Error acknowledged: $($decisionResult.Decision.Action)"
                }
                default {
                    Write-Host "  Continuing with: $($decisionResult.Decision.Action)" -ForegroundColor Gray
                    $executionResult = "Continuation action: $($decisionResult.Decision.Action)"
                }
            }
        } elseif ($SafeMode) {
            Write-Host "  SAFE MODE: Action would be executed but skipped" -ForegroundColor Yellow
            $executionResult = "Safe mode - no execution"
        } else {
            Write-Host "  Action not executed - failed safety validation" -ForegroundColor Red
            $executionResult = "Blocked by safety validation"
        }
        
        # Step 5: Retrieve and summarize results
        Write-Host "[Step 5] Retrieving and summarizing results..." -ForegroundColor Yellow
        $resultSummary = Get-ActionResultSummary `
            -ActionType $decisionResult.Decision.Decision `
            -ExecutionResult @{ Output = $executionResult; Success = ($null -ne $executionResult) }
        
        Write-Host "  Result: $($resultSummary.Summary)" -ForegroundColor $(if ($resultSummary.Success) { "Green" } else { "Yellow" })
        
        # Step 6: Generate next prompt
        Write-Host "[Step 6] Generating next autonomous prompt..." -ForegroundColor Yellow
        $nextPrompt = New-AutonomousPrompt `
            -RecommendationType $decisionResult.Decision.Decision `
            -ActionDetails $executionResult `
            -Context @{
                PreviousDecision = $decisionResult.Decision.Decision
                ExecutionSuccess = $resultSummary.Success
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            } `
            -IncludeBoilerplate $true
        
        Write-Host "  Generated prompt: $($nextPrompt.Length) characters" -ForegroundColor Gray
        
        # Step 7: Submit to Claude if auto-submit enabled
        if ($AutoSubmit -and -not $SafeMode) {
            Write-Host "[Step 7] Submitting to Claude Code CLI..." -ForegroundColor Yellow
            $submitted = Submit-ToClaudeViaTypeKeys -PromptText $nextPrompt
            
            if ($submitted) {
                Write-Host "  Successfully submitted to Claude!" -ForegroundColor Green
            } else {
                Write-Host "  Failed to submit to Claude" -ForegroundColor Red
            }
        } else {
            Write-Host "[Step 7] Auto-submit disabled or in safe mode" -ForegroundColor Yellow
            Write-Host "  Next prompt prepared but not submitted" -ForegroundColor Gray
        }
        
        # Return comprehensive result
        return @{
            Success = $true
            Analysis = $analysisResult
            Decision = $decisionResult
            Execution = $executionResult
            Summary = $resultSummary
            NextPrompt = $nextPrompt
            Submitted = $submitted
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        }
        
    } catch {
        Write-Host "[ERROR] Autonomous execution failed: $_" -ForegroundColor Red
        return @{
            Success = $false
            Error = $_.Exception.Message
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        }
    }
}

# Main autonomous monitoring function
function Start-CLIOrchestration {
    param(
        [int]$PollIntervalSeconds = 5,
        [switch]$DebugMode,
        [switch]$EnhancedMode = $true
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

#region Phase 7 Enhanced Integration Functions

# Comprehensive response analysis combining both engines
function Invoke-ComprehensiveResponseAnalysis {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent,
        
        [Parameter()]
        [string]$SchemaPath,
        
        [Parameter()]
        [switch]$AsHashtable,
        
        [Parameter()]
        [switch]$IncludeDetails
    )
    
    Write-Host "[CLIOrchestrator] Starting comprehensive response analysis" -ForegroundColor Cyan
    
    try {
        # Step 1: Enhanced Response Analysis (JSON processing, truncation handling)
        Write-Host "  Step 1: Enhanced JSON processing and validation" -ForegroundColor Gray
        $analysisResult = Invoke-EnhancedResponseAnalysis -ResponseContent $ResponseContent -SchemaPath $SchemaPath -AsHashtable:$AsHashtable
        
        # Step 2: Pattern Recognition Analysis
        Write-Host "  Step 2: Pattern recognition and classification" -ForegroundColor Gray
        $patternResult = Invoke-PatternRecognitionAnalysis -ResponseContent $ResponseContent -ParsedJson $analysisResult.ParsedContent -IncludeDetails:$IncludeDetails
        
        # Step 3: Integrate results
        $comprehensiveResult = @{
            # Core Analysis Results
            ParsedContent = $analysisResult.ParsedContent
            ProcessingSuccess = $analysisResult.Success
            
            # Processing Metadata
            OriginalLength = $analysisResult.OriginalLength
            ProcessedLength = $analysisResult.ProcessedLength
            WasRepaired = $analysisResult.WasRepaired
            SchemaValid = $analysisResult.SchemaValid
            RetryCount = $analysisResult.RetryCount
            
            # Pattern Recognition Results
            Recommendations = $patternResult.Recommendations
            Entities = $patternResult.Entities
            Classification = $patternResult.Classification
            ConfidenceAnalysis = $patternResult.ConfidenceAnalysis
            
            # Performance Metrics
            ResponseProcessingTimeMs = $(if ($analysisResult.ProcessingTimeMs) { $analysisResult.ProcessingTimeMs } else { 0 })
            PatternProcessingTimeMs = $patternResult.ProcessingTimeMs
            TotalProcessingTimeMs = $(if ($analysisResult.ProcessingTimeMs) { $analysisResult.ProcessingTimeMs } else { 0 }) + $patternResult.ProcessingTimeMs
            
            # Quality Assessment
            OverallQuality = $patternResult.ConfidenceAnalysis.QualityRating
            ProcessingTimestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        }
        
        # Add detailed information if requested
        if ($IncludeDetails -and $patternResult.Details) {
            $comprehensiveResult.Details = $patternResult.Details
        }
        
        # Performance warning if needed
        if ($comprehensiveResult.TotalProcessingTimeMs -gt 1000) {
            Write-Warning "Comprehensive analysis took $($comprehensiveResult.TotalProcessingTimeMs)ms - consider optimization"
        }
        
        Write-Host "  Analysis completed successfully" -ForegroundColor Green
        Write-Host "  Quality: $($comprehensiveResult.OverallQuality), Recommendations: $($comprehensiveResult.Recommendations.Count), Processing: $($comprehensiveResult.TotalProcessingTimeMs)ms" -ForegroundColor Gray
        
        return $comprehensiveResult
        
    } catch {
        Write-Error "Comprehensive response analysis failed: $($_.Exception.Message)"
        throw
    }
}

# Get CLIOrchestrator status and health information
function Get-CLIOrchestrationStatus {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$IncludeDetails
    )
    
    Write-Host "[CLIOrchestrator] Collecting system status" -ForegroundColor Cyan
    
    try {
        # Circuit Breaker Status
        $circuitBreakerStatus = Test-CircuitBreakerState
        
        # Module Status
        $coreModules = @(
            'Unity-Claude-CLIOrchestrator',
            'ResponseAnalysisEngine',
            'PatternRecognitionEngine'
        )
        
        $moduleStatus = @{}
        foreach ($moduleName in $coreModules) {
            $module = Get-Module -Name $moduleName -ErrorAction SilentlyContinue
            $moduleStatus[$moduleName] = @{
                Loaded = ($null -ne $module)
                Version = if ($module) { $module.Version.ToString() } else { "Not Loaded" }
                Path = if ($module) { $module.Path } else { $null }
            }
        }
        
        # Performance Status (basic)
        $performanceStatus = @{
            LastAnalysisTime = "Not Available"
            AverageProcessingTime = "Not Available"
            CacheSize = "Not Available"
        }
        
        # Compile status
        $status = @{
            # Core Status
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            OverallHealth = if ($circuitBreakerStatus) { "Healthy" } else { "Degraded" }
            
            # Component Status
            CircuitBreakerOpen = -not $circuitBreakerStatus
            ModuleStatus = $moduleStatus
            PerformanceStatus = $performanceStatus
            
            # Capabilities
            Capabilities = @{
                JsonTruncationDetection = $true
                MultiParserSupport = $true
                PatternRecognition = $true
                ResponseClassification = $true
                CircuitBreakerProtection = $true
                PerformanceMonitoring = $true
            }
        }
        
        if ($IncludeDetails) {
            # Add detailed system information
            $status.Details = @{
                PowerShellVersion = $PSVersionTable.PSVersion.ToString()
                ModulePath = $PSScriptRoot
                LogPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\unity_claude_automation.log"
                ConfigurationDefaults = @{
                    PerformanceTargetMs = 200
                    CircuitBreakerThreshold = 5
                    MaxRetryAttempts = 3
                }
            }
        }
        
        return $status
        
    } catch {
        Write-Error "Failed to get CLIOrchestration status: $($_.Exception.Message)"
        return @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            OverallHealth = "Error"
            ErrorMessage = $_.Exception.Message
        }
    }
}

# Complete autonomous decision-making pipeline (Phase 7 Day 3-4)
function Invoke-AutonomousDecisionMaking {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ResponseContent,
        
        [Parameter()]
        [string]$SchemaPath,
        
        [Parameter()]
        [switch]$AsHashtable,
        
        [Parameter()]
        [switch]$IncludeDetails,
        
        [Parameter()]
        [switch]$DryRun,
        
        [Parameter()]
        [switch]$AutoExecute
    )
    
    Write-Host "[CLIOrchestrator] Starting autonomous decision-making pipeline" -ForegroundColor Cyan
    $pipelineStartTime = Get-Date
    
    try {
        # Step 1: Comprehensive Response Analysis (combines JSON processing and pattern recognition)
        Write-Host "  Phase 1: Comprehensive response analysis" -ForegroundColor Gray
        $analysisResult = Invoke-ComprehensiveResponseAnalysis -ResponseContent $ResponseContent -SchemaPath $SchemaPath -AsHashtable:$AsHashtable -IncludeDetails:$IncludeDetails
        
        if (-not $analysisResult.ProcessingSuccess) {
            throw "Response analysis failed: Unable to process Claude Code CLI response"
        }
        
        # Step 2: Rule-Based Decision Making
        Write-Host "  Phase 2: Rule-based decision making" -ForegroundColor Gray
        $decisionResult = Invoke-RuleBasedDecision -AnalysisResult $analysisResult -IncludeDetails:$IncludeDetails -DryRun:$DryRun
        
        if ($decisionResult.Decision -eq "BLOCK") {
            Write-Host "  Decision: BLOCKED - $($decisionResult.Reason)" -ForegroundColor Red
            return @{
                Success = $false
                Decision = $decisionResult
                Analysis = $analysisResult
                Reason = "Decision blocked for safety reasons"
                PipelineTimeMs = ((Get-Date) - $pipelineStartTime).TotalMilliseconds
                Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            }
        }
        
        # Step 3: Action Queue Management
        Write-Host "  Phase 3: Action queue management" -ForegroundColor Gray
        $queueStatus = Get-ActionQueueStatus -IncludeDetails:$IncludeDetails
        
        # Step 4: Auto-execution if requested and safe
        $executionResult = $null
        if ($AutoExecute -and -not $DryRun -and $decisionResult.SafetyValidated) {
            Write-Host "  Phase 4: Auto-executing approved decision" -ForegroundColor Yellow
            try {
                $executionResult = Invoke-DecisionExecution -Decision $decisionResult -AnalysisResult $analysisResult
            } catch {
                Write-Host "  Auto-execution failed: $($_.Exception.Message)" -ForegroundColor Red
                $executionResult = @{
                    Success = $false
                    Error = $_.Exception.Message
                    Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
                }
            }
        } elseif ($AutoExecute -and -not $decisionResult.SafetyValidated) {
            Write-Host "  Auto-execution skipped: Decision not safety validated" -ForegroundColor Yellow
        } elseif ($DryRun) {
            Write-Host "  Auto-execution skipped: Dry run mode" -ForegroundColor Gray
        }
        
        # Compile comprehensive result
        $pipelineResult = @{
            # Core Results
            Success = $true
            Decision = $decisionResult
            Analysis = $analysisResult
            QueueStatus = $queueStatus
            
            # Execution Results (if applicable)
            ExecutionResult = $executionResult
            AutoExecuted = ($null -ne $executionResult)
            
            # Performance Metrics
            AnalysisTimeMs = $analysisResult.TotalProcessingTimeMs
            DecisionTimeMs = $decisionResult.ProcessingTimeMs
            PipelineTimeMs = ((Get-Date) - $pipelineStartTime).TotalMilliseconds
            
            # Quality Assessment
            OverallConfidence = $analysisResult.ConfidenceAnalysis.OverallConfidence
            SafetyValidated = $decisionResult.SafetyValidated
            QualityRating = $analysisResult.OverallQuality
            
            # Metadata
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            DryRun = $DryRun.IsPresent
            
            # Summary Information
            RecommendationType = $decisionResult.Decision
            ActionPriority = $decisionResult.Priority
            SafetyLevel = $decisionResult.SafetyLevel
        }
        
        # Performance reporting
        $totalTime = [int]$pipelineResult.PipelineTimeMs
        Write-Host "  Pipeline completed successfully" -ForegroundColor Green
        Write-Host "  Decision: $($pipelineResult.RecommendationType) (Priority: $($pipelineResult.ActionPriority), Confidence: $($pipelineResult.OverallConfidence), Time: ${totalTime}ms)" -ForegroundColor Gray
        
        # Performance warning
        if ($totalTime -gt 1500) {
            Write-Warning "Autonomous decision-making pipeline took ${totalTime}ms - consider optimization"
        }
        
        return $pipelineResult
        
    } catch {
        $pipelineTime = ((Get-Date) - $pipelineStartTime).TotalMilliseconds
        Write-Error "Autonomous decision-making pipeline failed: $($_.Exception.Message)"
        
        return @{
            Success = $false
            Reason = "Pipeline execution error: $($_.Exception.Message)"
            Error = $_.Exception.ToString()
            PipelineTimeMs = $pipelineTime
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        }
    }
}

# Decision execution handler (placeholder for Phase 7 Day 5)
function Invoke-DecisionExecution {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Decision,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$AnalysisResult
    )
    
    Write-Host "    [DecisionExecution] Executing decision: $($Decision.Decision)" -ForegroundColor Yellow
    
    # This is a placeholder for Phase 7 Day 5: Action Execution Framework
    # For now, we'll just log the decision and return success
    
    $executionStart = Get-Date
    
    try {
        switch ($Decision.Decision) {
            "CONTINUE" {
                Write-Host "    Continuing with current process..." -ForegroundColor Green
            }
            "TEST" {
                Write-Host "    Would execute test: $($Decision.Action)" -ForegroundColor Cyan
            }
            "FIX" {
                Write-Host "    Would apply fix: $($Decision.Action)" -ForegroundColor Magenta
            }
            "COMPILE" {
                Write-Host "    Would compile project..." -ForegroundColor Blue
            }
            "RESTART" {
                Write-Host "    Would restart service: $($Decision.Action)" -ForegroundColor Yellow
            }
            "COMPLETE" {
                Write-Host "    Task completed successfully" -ForegroundColor Green
            }
            "ERROR" {
                Write-Host "    Error handling: $($Decision.Action)" -ForegroundColor Red
            }
            default {
                Write-Host "    Unknown decision type: $($Decision.Decision)" -ForegroundColor Yellow
            }
        }
        
        # Simulate some processing time
        Start-Sleep -Milliseconds 100
        
        $executionTime = ((Get-Date) - $executionStart).TotalMilliseconds
        
        return @{
            Success = $true
            Decision = $Decision.Decision
            Action = $Decision.Action
            ExecutionTimeMs = $executionTime
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
            Note = "Placeholder execution - Full implementation in Phase 7 Day 5"
        }
        
    } catch {
        return @{
            Success = $false
            Error = $_.Exception.Message
            ExecutionTimeMs = ((Get-Date) - $executionStart).TotalMilliseconds
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        }
    }
}

#endregion

# Re-export nested module functions to ensure they are available
# This is needed because nested modules functions aren't automatically available to callers
if (Get-Command 'Invoke-RuleBasedDecision' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Invoke-RuleBasedDecision'
}
if (Get-Command 'Resolve-PriorityDecision' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Resolve-PriorityDecision'
}
if (Get-Command 'Test-SafetyValidation' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Test-SafetyValidation'
}
if (Get-Command 'Test-SafeFilePath' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Test-SafeFilePath'
}
if (Get-Command 'Test-SafeCommand' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Test-SafeCommand'
}
if (Get-Command 'Test-ActionQueueCapacity' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Test-ActionQueueCapacity'
}
if (Get-Command 'New-ActionQueueItem' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'New-ActionQueueItem'
}
if (Get-Command 'Get-ActionQueueStatus' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Get-ActionQueueStatus'
}
if (Get-Command 'Resolve-ConflictingRecommendations' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Resolve-ConflictingRecommendations'
}
if (Get-Command 'Invoke-GracefulDegradation' -ErrorAction SilentlyContinue) {
    Export-ModuleMember -Function 'Invoke-GracefulDegradation'
}

# Export all functions defined in this module (Phase 7 Day 3-4 Enhanced)
Export-ModuleMember -Function @(
    # Helper Functions
    'Convert-ToSerializedString',
    # Original Functions
    'Start-CLIOrchestration',
    'Find-ClaudeWindow',
    'Switch-ToWindow', 
    'Submit-ToClaudeViaTypeKeys',
    'Execute-TestScript',
    'Process-ResponseFile',
    'Update-ClaudeWindowInfo',
    
    # New Enhanced Autonomous Functions
    'New-AutonomousPrompt',
    'Get-ActionResultSummary',
    'Invoke-AutonomousExecutionLoop',
    
    # Phase 7 Integrated Functions
    'Invoke-ComprehensiveResponseAnalysis',
    'Get-CLIOrchestrationStatus',
    'Invoke-AutonomousDecisionMaking',
    
    # Decision Engine Functions
    'Invoke-RuleBasedDecision',
    'Resolve-PriorityDecision', 
    'Test-SafetyValidation',
    'Test-SafeFilePath',
    'Test-SafeCommand',
    'Test-ActionQueueCapacity',
    'New-ActionQueueItem',
    'Get-ActionQueueStatus',
    'Resolve-ConflictingRecommendations',
    'Invoke-GracefulDegradation',
    
    # Circuit Breaker Functions
    'Test-CircuitBreakerState',
    'Update-CircuitBreakerState',
    
    # Pattern Recognition Functions
    'Invoke-PatternRecognitionAnalysis',
    'Find-RecommendationPatterns',
    'Extract-ContextEntities',
    'Classify-ResponseType',
    'Calculate-OverallConfidence',
    
    # Response Analysis Functions
    'Invoke-EnhancedResponseAnalysis',
    'Test-JsonTruncation',
    'Repair-TruncatedJson',
    'Extract-ResponseEntities',
    'Analyze-ResponseSentiment',
    'Get-ResponseContext',
    
    # Action Execution Functions
    'Invoke-SafeAction',
    'Add-ActionToQueue',
    'Get-NextQueuedAction',
    'Get-ActionExecutionStatus',
    'Test-ActionSafety',
    
    # Autonomous Functions
    'New-AutonomousPrompt',
    'Get-ActionResultSummary',
    'Invoke-AutonomousExecutionLoop'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBbvw0fPsGVFPJx
# B+YAoSYGh30QOno2Vnt7JCKA6i1DraCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEINgM+n6a0SHZvXVZdKpYsdg0
# X931z7wy5ymORJCd6XA0MA0GCSqGSIb3DQEBAQUABIIBAIlz0cWYXMZ7gmYPWCwX
# xDF9UBjyGWuUGgkGc99xgE/ZXDqJRKco4g5RfkmyQ0ZnbFNwQfTPuZh+xdzRpP/t
# opKdFdv7K70GncAjlqfIoQimZr4GH9T7Qo9lQ5qENbYln2HhVS/TlYv4/tS32Av4
# hOQOkYgCUsDu8YgeK6s6j+z6isP+wQNGrPwWfl9B2e6bHMHtQk61eR4vKP6hE52T
# JbaxBvpsCU6TI4Uvm+Ru8LwUTcIeBWrQhXlwDDCibLgS6Pk9MVi7xDMhO9Okk0kM
# cnHpSvVdtQDHuTdvWtTGH+FPY05eYw65ToT1nk+Y9kEYDXd7cSuptmqOm7wNskc9
# DL8=
# SIG # End signature block
