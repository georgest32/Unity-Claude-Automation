# Unity-Claude-CLISubmission.psm1
# Autonomous Claude Code CLI prompt submission and response monitoring
# Implements the actual feedback loop: Unity errors -> Claude prompts -> responses -> actions
# Date: 2025-08-18

#region Module Initialization
$ErrorActionPreference = "Stop"

Write-Host "[CLISubmission] Loading Claude Code CLI submission module..." -ForegroundColor Cyan

# Add required .NET types
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Module configuration
$script:CLIConfig = @{
    # Claude Code CLI submission settings
    PromptSubmissionPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\claude_prompt_queue.txt"
    ResponseMonitorPath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\claude_responses"
    
    # Timing settings
    WindowFocusDelayMs = 2000
    KeystrokeDelayMs = 100
    ResponseTimeoutMs = 300000  # 5 minutes
    
    # Unity monitoring - use existing ConsoleErrorExporter system
    UnityConsoleErrorsPath = "C:\UnityProjects\Sound-and-Shoal\AutomationLogs\current_errors.json"
    UnityEditorLogPath = "C:\Users\georg\AppData\Local\Unity\Editor\Editor.log"
    ErrorPatterns = @(
        "CS0103:", "CS0246:", "CS1061:", "CS0029:", "CS1002:", "CS0117:", "CS0019:", "CS0266:", "CS0051:"
    )
}

#endregion

#region Unity Error Detection Functions

function Start-UnityErrorMonitoring {
    <#
    .SYNOPSIS
    Starts continuous monitoring of Unity compilation errors for autonomous processing
    
    .DESCRIPTION
    Monitors Unity Editor.log for compilation errors and triggers autonomous Claude prompt generation
    
    .PARAMETER OnErrorDetected
    Script block to execute when errors are detected
    
    .EXAMPLE
    Start-UnityErrorMonitoring -OnErrorDetected { param($errors) Submit-ErrorsToClaudeAutonomous $errors }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$OnErrorDetected
    )
    
    Write-Host "[CLISubmission] Starting Unity error monitoring..." -ForegroundColor Yellow
    Write-Host "[CLISubmission] Monitoring: $($script:CLIConfig.UnityConsoleErrorsPath)" -ForegroundColor Gray
    
    # Check if ConsoleErrorExporter is working by looking for recent files
    $automationDir = Split-Path $script:CLIConfig.UnityConsoleErrorsPath -Parent
    if (-not (Test-Path $automationDir)) {
        Write-Warning "AutomationLogs directory not found at: $automationDir"
        return @{ Success = $false; Error = "AutomationLogs directory not found" }
    }
    
    # Start background job for error monitoring
    $monitoringJob = Start-Job -Name "UnityErrorMonitor" -ScriptBlock {
        param($JsonPath, $ErrorPatterns, $OnErrorScript)
        
        $lastModified = [DateTime]::MinValue
        $lastErrorCount = 0
        
        while ($true) {
            if (Test-Path $JsonPath) {
                $fileInfo = Get-Item $JsonPath
                
                # Check if file was modified since last check
                if ($fileInfo.LastWriteTime -gt $lastModified) {
                    $lastModified = $fileInfo.LastWriteTime
                    
                    try {
                        # Read and parse JSON
                        $jsonContent = Get-Content $JsonPath -Raw
                        $errorData = $jsonContent | ConvertFrom-Json
                        
                        if ($errorData -and $errorData.errors -and $errorData.errors.Count -gt 0) {
                            # Extract error messages
                            $currentErrors = @()
                            foreach ($error in $errorData.errors) {
                                if ($error.message) {
                                    $currentErrors += $error.message
                                }
                            }
                            
                            # Only trigger if we have new errors or error count changed
                            if ($currentErrors.Count -gt 0 -and $currentErrors.Count -ne $lastErrorCount) {
                                Write-Host "[Monitor] Detected $($currentErrors.Count) Unity errors" -ForegroundColor Yellow
                                & $OnErrorScript $currentErrors
                                $lastErrorCount = $currentErrors.Count
                            }
                        } else {
                            # No errors - reset count
                            if ($lastErrorCount -gt 0) {
                                Write-Host "[Monitor] Unity errors cleared" -ForegroundColor Green
                                $lastErrorCount = 0
                            }
                        }
                    } catch {
                        Write-Host "[Monitor] Error parsing JSON: $($_.Exception.Message)" -ForegroundColor Red
                    }
                }
            }
            
            Start-Sleep 3
        }
    } -ArgumentList $script:CLIConfig.UnityConsoleErrorsPath, $script:CLIConfig.ErrorPatterns, $OnErrorDetected
    
    Write-Host "[CLISubmission] Unity error monitoring started (Job ID: $($monitoringJob.Id))" -ForegroundColor Green
    
    return @{
        Success = $true
        MonitoringJob = $monitoringJob
        JobId = $monitoringJob.Id
    }
}

function Stop-UnityErrorMonitoring {
    <#
    .SYNOPSIS
    Stops Unity error monitoring background job
    #>
    [CmdletBinding()]
    param()
    
    $jobs = Get-Job -Name "UnityErrorMonitor" -ErrorAction SilentlyContinue
    
    foreach ($job in $jobs) {
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -Force -ErrorAction SilentlyContinue
        Write-Host "[CLISubmission] Stopped Unity error monitoring (Job ID: $($job.Id))" -ForegroundColor Yellow
    }
}

#endregion

#region Prompt Generation Functions

function New-AutonomousPrompt {
    <#
    .SYNOPSIS
    Generates comprehensive autonomous prompts following Claude Code best practices and structured format
    
    .DESCRIPTION
    Creates structured prompts based on established boilerplate format with proper context,
    error analysis, project details, and specific instructions for optimal Claude Code CLI interaction
    
    .PARAMETER Errors
    Array of Unity compilation errors to analyze
    
    .PARAMETER Context
    Additional context information for prompt generation
    
    .EXAMPLE
    $prompt = New-AutonomousPrompt -Errors $detectedErrors -Context "Post-compilation validation"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [array]$Errors,
        
        [Parameter()]
        [string]$Context = "Unity compilation errors detected during autonomous monitoring"
    )
    
    Write-Host "[CLISubmission] Generating structured autonomous prompt for $($Errors.Count) errors..." -ForegroundColor Yellow
    
    # Enhanced error pattern analysis with comprehensive Unity error codes
    $errorAnalysis = @{
        MissingTypes = @()
        MissingMethods = @()
        SyntaxErrors = @()
        ConversionErrors = @()
        NamespaceErrors = @()
        CompilerDirectives = @()
        AccessibilityErrors = @()
        Other = @()
    }
    
    foreach ($error in $Errors) {
        switch -Regex ($error) {
            "CS0246.*type.*namespace.*not.*found|CS0234.*namespace.*does.*not.*exist" { $errorAnalysis.MissingTypes += $error }
            "CS0103.*name.*does.*not.*exist|CS0117.*does.*not.*contain.*definition" { $errorAnalysis.MissingMethods += $error }
            "CS1002.*missing|CS1003.*expected|CS1022.*Type.*namespace.*definition|CS1513.*closing.*brace" { $errorAnalysis.SyntaxErrors += $error }
            "CS0029.*cannot.*convert|CS0266.*cannot.*implicitly.*convert" { $errorAnalysis.ConversionErrors += $error }
            "CS0116.*namespace.*cannot.*directly.*contain|CS0106.*modifier.*not.*valid" { $errorAnalysis.NamespaceErrors += $error }
            "CS1022.*Type.*or.*namespace.*definition.*expected" { $errorAnalysis.CompilerDirectives += $error }
            "CS0122.*inaccessible.*due.*protection|CS0051.*inconsistent.*accessibility" { $errorAnalysis.AccessibilityErrors += $error }
            default { $errorAnalysis.Other += $error }
        }
    }
    
    # Get current timestamp and project context
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $currentPhase = "Phase 2A: Enhanced Semantic Analysis"
    
    # Build comprehensive structured prompt following boilerplate format
    $promptParts = @()
    
    # Boilerplate header compliance
    $promptParts += "IMPORTANT: if the Claude Code root directory is Unity-Claude-Automation/ then the current project is Unity Claude Automation, NOT Symbolic Memory."
    $promptParts += ""
    $promptParts += "**PROMPT TYPE: Debugging**"
    $promptParts += ""
    
    # Project context and system state
    $promptParts += "**AUTONOMOUS UNITY ERROR DETECTION ALERT**"
    $promptParts += "**Detection Timestamp:** $timestamp"
    $promptParts += "**Project Context:** Unity-Claude Automation System"
    $promptParts += "**Current Phase:** $currentPhase"
    $promptParts += "**Session Context:** $Context"
    $promptParts += ""
    
    # Technical environment details (following best practices)
    $promptParts += "**Environment & Configuration:**"
    $promptParts += "- Unity Version: 2021.1.14f1"
    $promptParts += "- PowerShell Version: 5.1 (ASCII-only characters required, no backticks)"
    $promptParts += "- Project Root: C:\UnityProjects\Sound-and-Shoal\"
    $promptParts += "- Automation Root: C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\"
    $promptParts += "- Error Export System: SafeConsoleExporter.cs (uses Application.logMessageReceived)"
    $promptParts += "- Monitoring System: Unity-Claude-ReliableMonitoring.psm1"
    $promptParts += ""
    
    # Comprehensive error analysis
    $promptParts += "**Error Analysis Summary:**"
    $promptParts += "- Missing Types/Namespaces: $($errorAnalysis.MissingTypes.Count)"
    $promptParts += "- Missing Methods/Members: $($errorAnalysis.MissingMethods.Count)"  
    $promptParts += "- Syntax Errors: $($errorAnalysis.SyntaxErrors.Count)"
    $promptParts += "- Type Conversion Errors: $($errorAnalysis.ConversionErrors.Count)"
    $promptParts += "- Namespace Structure Errors: $($errorAnalysis.NamespaceErrors.Count)"
    $promptParts += "- Compiler Directive Issues: $($errorAnalysis.CompilerDirectives.Count)"
    $promptParts += "- Accessibility Errors: $($errorAnalysis.AccessibilityErrors.Count)"
    $promptParts += "- Other Compilation Issues: $($errorAnalysis.Other.Count)"
    $promptParts += ""
    
    # Detailed error breakdown by category
    if ($errorAnalysis.MissingTypes.Count -gt 0) {
        $promptParts += "**Missing Types/Namespaces (CS0246, CS0234):**"
        $errorAnalysis.MissingTypes | ForEach-Object { $promptParts += "- $_" }
        $promptParts += ""
    }
    
    if ($errorAnalysis.MissingMethods.Count -gt 0) {
        $promptParts += "**Missing Methods/Members (CS0103, CS0117):**"
        $errorAnalysis.MissingMethods | ForEach-Object { $promptParts += "- $_" }
        $promptParts += ""
    }
    
    if ($errorAnalysis.SyntaxErrors.Count -gt 0) {
        $promptParts += "**Syntax Errors (CS1002, CS1003, CS1022, CS1513):**"
        $errorAnalysis.SyntaxErrors | ForEach-Object { $promptParts += "- $_" }
        $promptParts += ""
    }
    
    if ($errorAnalysis.ConversionErrors.Count -gt 0) {
        $promptParts += "**Type Conversion Errors (CS0029, CS0266):**"
        $errorAnalysis.ConversionErrors | ForEach-Object { $promptParts += "- $_" }
        $promptParts += ""
    }
    
    if ($errorAnalysis.NamespaceErrors.Count -gt 0) {
        $promptParts += "**Namespace Structure Errors (CS0116, CS0106):**"
        $errorAnalysis.NamespaceErrors | ForEach-Object { $promptParts += "- $_" }
        $promptParts += ""
    }
    
    if ($errorAnalysis.CompilerDirectives.Count -gt 0) {
        $promptParts += "**Compiler Directive Issues (CS1022):**"
        $errorAnalysis.CompilerDirectives | ForEach-Object { $promptParts += "- $_" }
        $promptParts += ""
    }
    
    if ($errorAnalysis.AccessibilityErrors.Count -gt 0) {
        $promptParts += "**Accessibility Errors (CS0122, CS0051):**"
        $errorAnalysis.AccessibilityErrors | ForEach-Object { $promptParts += "- $_" }
        $promptParts += ""
    }
    
    if ($errorAnalysis.Other.Count -gt 0) {
        $promptParts += "**Other Compilation Issues:**"
        $errorAnalysis.Other | ForEach-Object { $promptParts += "- $_" }
        $promptParts += ""
    }
    
    # Critical system context and constraints
    $promptParts += "**Critical System Constraints:**"
    $promptParts += "- Use ASCII characters only (no Unicode symbols)"
    $promptParts += "- PowerShell 5.1 compatibility required"
    $promptParts += "- No backtick escape sequences in code"
    $promptParts += "- Maintain compatibility with existing SafeConsoleExporter system"
    $promptParts += "- Unity 2021.1.14f1 specific compatibility requirements"
    $promptParts += ""
    
    # Clear instructions following boilerplate format
    $promptParts += "**Debugging Instructions:**"
    $promptParts += "Please analyze each error systematically and provide comprehensive fix recommendations:"
    $promptParts += ""
    $promptParts += "**For Each Error, Specify:**"
    $promptParts += "1. **The Exact Issue:** Root cause analysis with specific error code interpretation"
    $promptParts += "2. **Recommended Fix:** Complete code changes with file paths, line numbers, and exact replacements"
    $promptParts += "3. **Implementation Context:** Any required using statements, namespace adjustments, or dependency changes"
    $promptParts += "4. **Compatibility Warnings:** Unity 2021.1.14f1 or PowerShell 5.1 specific considerations"
    $promptParts += "5. **Testing Validation:** How to verify the fix resolves the issue completely"
    $promptParts += ""
    
    # Success criteria and validation requirements
    $promptParts += "**Success Criteria:**"
    $promptParts += "- All compilation errors resolved"
    $promptParts += "- No new errors introduced"
    $promptParts += "- Existing autonomous monitoring system functionality preserved"
    $promptParts += "- Unity Editor compiles successfully without warnings"
    $promptParts += "- SafeConsoleExporter continues to function correctly"
    $promptParts += ""
    
    # Action request aligned with System A architecture
    $promptParts += "**Action Requested:**"
    $promptParts += "Please implement the fixes directly in the affected files. The autonomous system "
    $promptParts += "has detected these errors and is submitting this request for immediate resolution. "
    $promptParts += "Provide detailed explanations of changes made for learning and documentation purposes."
    $promptParts += ""
    
    # Learning and documentation request
    $promptParts += "**Documentation Request:**"
    $promptParts += "After implementing fixes, please update any relevant learning documentation "
    $promptParts += "with insights about error patterns, Unity 2021.1.14f1 specific issues, or "
    $promptParts += "PowerShell 5.1 compatibility solutions discovered during this resolution."
    
    $finalPrompt = $promptParts -join "`n"
    
    Write-Host "[CLISubmission] Generated structured prompt with $($promptParts.Count) lines, $($Errors.Count) errors analyzed" -ForegroundColor Green
    
    return @{
        Success = $true
        Prompt = $finalPrompt
        ErrorCount = $Errors.Count
        Analysis = $errorAnalysis
        Timestamp = Get-Date
        PromptType = "Debugging"
        ProjectContext = $currentPhase
    }
}

#endregion

#region Claude Code CLI Submission Functions

function Submit-PromptToClaudeCode {
    <#
    .SYNOPSIS
    Submits a prompt to Claude Code CLI window using automation
    
    .DESCRIPTION
    Focuses Claude Code CLI window and submits prompt using SendKeys automation
    
    .PARAMETER Prompt
    The prompt text to submit
    
    .PARAMETER WindowTitle
    Title of Claude Code CLI window to target
    
    .EXAMPLE
    Submit-PromptToClaudeCode -Prompt "Analyze these Unity errors..." -WindowTitle "Claude Code"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Prompt,
        
        [Parameter()]
        [string]$WindowTitle = "Claude Code"
    )
    
    Write-Host "[CLISubmission] Submitting prompt to Claude Code CLI..." -ForegroundColor Yellow
    
    try {
        # FIRST: Try to get Claude Code CLI PID from system_status.json
        $statusFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\system_status.json"
        $claudePID = $null
        $detectionResult = $null
        
        if (Test-Path $statusFile) {
            $status = Get-Content $statusFile -Raw | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($status.SystemInfo -and $status.SystemInfo.ClaudeCodeCLI) {
                # Check if we have a terminal PID stored
                if ($status.SystemInfo.ClaudeCodeCLI.TerminalPID) {
                    $testPID = $status.SystemInfo.ClaudeCodeCLI.TerminalPID
                    # Verify the Terminal PID is still valid
                    $process = Get-Process -Id $testPID -ErrorAction SilentlyContinue
                    if ($process) {
                        $claudePID = $testPID
                        Write-Host "[CLISubmission] Found valid Claude Code CLI Terminal PID from system_status.json: $claudePID" -ForegroundColor Green
                        
                        # Create a detection result for the terminal window
                        $detectionResult = @{
                            Success = $true
                            ProcessId = $claudePID
                            Confidence = 100
                            DetectionMethod = "system_status.json (terminal)"
                        }
                    } else {
                        Write-Host "[CLISubmission] Terminal PID $testPID is not valid anymore" -ForegroundColor Yellow
                    }
                } elseif ($status.SystemInfo.ClaudeCodeCLI.TerminalWindowHandle) {
                    # PRIORITY FIX: Use TerminalWindowHandle if available (from Set-ClaudeCodeWindow.ps1)
                    $windowHandle = $status.SystemInfo.ClaudeCodeCLI.TerminalWindowHandle
                    $terminalPID = $status.SystemInfo.ClaudeCodeCLI.TerminalProcessId
                    Write-Host "[CLISubmission] Found Claude Code CLI TerminalWindowHandle: $windowHandle (PID: $terminalPID)" -ForegroundColor Green
                    
                    # Verify the window handle is still valid
                    if (-not ([System.Management.Automation.PSTypeName]'WindowValidator').Type) {
                        Add-Type -ErrorAction SilentlyContinue @"
                            using System;
                            using System.Runtime.InteropServices;
                            public class WindowValidator {
                                [DllImport("user32.dll")]
                                public static extern bool IsWindow(IntPtr hWnd);
                            }
"@
                    }
                    $handleInt = [IntPtr]$windowHandle
                    if ([WindowValidator]::IsWindow($handleInt)) {
                        $detectionResult = @{
                            Success = $true
                            ProcessId = $terminalPID
                            WindowHandle = $windowHandle
                            Confidence = 100
                            DetectionMethod = "system_status.json (TerminalWindowHandle)"
                        }
                    } else {
                        Write-Host "[CLISubmission] TerminalWindowHandle is no longer valid, falling back to process detection" -ForegroundColor Yellow
                    }
                } elseif ($status.SystemInfo.ClaudeCodeCLI.ProcessId) {
                    # Fallback to Node.js PID if no terminal handle or PID
                    $claudePID = $status.SystemInfo.ClaudeCodeCLI.ProcessId
                    Write-Host "[CLISubmission] Found Claude Code CLI PID from system_status.json: $claudePID" -ForegroundColor Green
                    
                    # Create a detection result from the PID
                    $detectionResult = @{
                        Success = $true
                        ProcessId = $claudePID
                        Confidence = 100
                        DetectionMethod = "system_status.json"
                    }
                }
            }
        }
        
        # If not found in system_status.json, use window detection
        if (-not $detectionResult) {
            # Load window detection module if not already loaded
            if (-not (Get-Module Unity-Claude-WindowDetection)) {
                $windowDetectionPath = Join-Path $PSScriptRoot "Unity-Claude-WindowDetection.psm1"
                if (Test-Path $windowDetectionPath) {
                    Import-Module $windowDetectionPath -Force
                    Write-Host "[CLISubmission] Loaded intelligent window detection module" -ForegroundColor Green
                }
            }
            
            # Use intelligent window detection if available
            if (Get-Module Unity-Claude-WindowDetection) {
                Write-Host "[CLISubmission] Using intelligent window detection..." -ForegroundColor Green
                $detectionResult = Find-ClaudeCodeCLIWindow
            }
        }
            
        # Check if detection was successful
        if ($detectionResult -and $detectionResult.Success) {
            # Get the actual process
            $targetProcess = Get-Process -Id $detectionResult.ProcessId -ErrorAction SilentlyContinue
            
            if ($targetProcess) {
                # Check if it's Node.js (need to find terminal)
                if ($targetProcess.ProcessName -eq "node") {
                    Write-Host "[CLISubmission] Node.js process detected (PID: $($targetProcess.Id)), CANNOT use for keystrokes" -ForegroundColor Yellow
                    Write-Host "[CLISubmission] Looking for PowerShell terminal window instead..." -ForegroundColor Yellow
                    
                    # First, try to find Windows Terminal or PowerShell windows
                    # Exclude UnifiedSystem window if it's marked in system_status.json
                    $unifiedSystemPID = $null
                    if ($status.SystemInfo.UnifiedSystemPID) {
                        $unifiedSystemPID = $status.SystemInfo.UnifiedSystemPID
                        Write-Host "[CLISubmission] Excluding UnifiedSystem window (PID: $unifiedSystemPID)" -ForegroundColor Gray
                    }
                    
                    $terminals = Get-Process | Where-Object { 
                        $_.MainWindowTitle -and 
                        ($_.ProcessName -eq "WindowsTerminal" -or 
                         $_.ProcessName -eq "powershell" -or 
                         $_.ProcessName -eq "pwsh" -or
                         $_.ProcessName -eq "cmd") -and
                        $_.Id -ne $unifiedSystemPID  # Exclude UnifiedSystem window
                    }
                    
                    Write-Host "[CLISubmission] Found $($terminals.Count) terminal windows, checking for Claude Code CLI..." -ForegroundColor Gray
                    
                    # Look for the actual Claude Code CLI window
                    # First priority: Check if we have a PID marker file
                    $markerFile = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\.claude_code_cli_pid"
                    $markerPID = $null
                    if (Test-Path $markerFile) {
                        $markerContent = Get-Content $markerFile
                        if ($markerContent.Count -ge 2) {
                            $markerPID = [int]$markerContent[1]
                            Write-Host "[CLISubmission] Found PID marker file with PID: $markerPID" -ForegroundColor Cyan
                        }
                    }
                    
                    # Try to find the window by PID from marker or by title
                    $claudeTerminal = $null
                    if ($markerPID) {
                        $claudeTerminal = $terminals | Where-Object { $_.Id -eq $markerPID } | Select-Object -First 1
                        if ($claudeTerminal) {
                            Write-Host "[CLISubmission] Found Claude Code CLI window by PID marker: $($claudeTerminal.MainWindowTitle)" -ForegroundColor Green
                        }
                    }
                    
                    if (-not $claudeTerminal) {
                        # Look for window with specific titles
                        $claudeTerminal = $terminals | Where-Object { 
                            $_.MainWindowTitle -match "Claude Code CLI" -or
                            $_.MainWindowTitle -match "Unity.*Automation" -or
                            $_.MainWindowTitle -eq "Administrator: Windows PowerShell"
                        } | Select-Object -First 1
                    }
                    
                    if (-not $claudeTerminal) {
                        # Fallback: Look for any terminal that's NOT Cursor
                        Write-Host "[CLISubmission] Didn't find exact match, looking for non-Cursor terminals..." -ForegroundColor Yellow
                        $claudeTerminal = $terminals | Where-Object { 
                            $_.MainWindowTitle -notmatch "Cursor" -and
                            $_.MainWindowTitle -notmatch "Code" -and
                            $_.MainWindowTitle -notmatch "\.ps1" -and
                            $_.MainWindowTitle -notmatch "\.psm1"
                        } | Select-Object -First 1
                    }
                    
                    if ($claudeTerminal) {
                        $claudeProcess = @($claudeTerminal)
                        Write-Host "[CLISubmission] Found Claude terminal: $($claudeTerminal.MainWindowTitle) (PID: $($claudeTerminal.Id))" -ForegroundColor Green
                        
                        # Log for debugging
                        Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\window_detection.log" `
                                    -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Selected window: $($claudeTerminal.MainWindowTitle) (PID: $($claudeTerminal.Id))"
                    } else {
                        # Can't send keystrokes to Node.js directly
                        Write-Host "[CLISubmission] Warning: Node.js process found but no suitable terminal window" -ForegroundColor Yellow
                        
                        # Log all windows for debugging
                        $allWindows = Get-Process | Where-Object { $_.MainWindowTitle } | Select-Object ProcessName, Id, MainWindowTitle
                        Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\window_detection.log" `
                                    -Value "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] No suitable window found. Available windows:"
                        foreach ($window in $allWindows) {
                            Add-Content -Path "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\window_detection.log" `
                                        -Value "  - $($window.ProcessName) (PID: $($window.Id)): $($window.MainWindowTitle)"
                        }
                        
                        return @{ Success = $false; Error = "Claude Code CLI is running but terminal window not found" }
                    }
                } else {
                    # Regular process with window
                    $claudeProcess = @($targetProcess)
                }
                
                Write-Host "[CLISubmission] Using process from detection: PID $($claudeProcess[0].Id)" -ForegroundColor Green
            } else {
                Write-Host "[CLISubmission] Process $($detectionResult.ProcessId) not found" -ForegroundColor Red
                return @{ Success = $false; Error = "Process not found" }
            }
            
        } else {
            # Detection failed
            if ($detectionResult) {
                Write-Host "[CLISubmission] Detection failed: $($detectionResult.Error)" -ForegroundColor Red
                
                # Show available windows for debugging
                Write-Host "[CLISubmission] Available windows:" -ForegroundColor Yellow
                Get-Process | Where-Object { $_.MainWindowTitle } | 
                    Select-Object -First 5 | ForEach-Object {
                        Write-Host "  - $($_.MainWindowTitle) ($($_.ProcessName))" -ForegroundColor Gray
                    }
                
            } else {
                Write-Host "[CLISubmission] No detection result available" -ForegroundColor Red
            }
            
            # Last resort: Show available windows
            Write-Host "[CLISubmission] Available windows:" -ForegroundColor Yellow
            Get-Process | Where-Object { $_.MainWindowTitle } | 
                Select-Object -First 5 | ForEach-Object {
                    Write-Host "  - $($_.MainWindowTitle) (PID: $($_.Id), Process: $($_.ProcessName))" -ForegroundColor Gray
                }
            
            return @{ Success = $false; Error = "Claude Code CLI window not detected" }
        }
        
        # Check if we have a direct window handle from our detection
        if ($detectionResult.WindowHandle) {
            $hwnd = [IntPtr]$detectionResult.WindowHandle
            Write-Host "[CLISubmission] Using direct TerminalWindowHandle: $hwnd" -ForegroundColor Green
        } else {
            $hwnd = $claudeProcess[0].MainWindowHandle
            Write-Host "[CLISubmission] Target window: $($claudeProcess[0].MainWindowTitle)" -ForegroundColor Gray
            Write-Host "[CLISubmission] Process: $($claudeProcess[0].ProcessName) (PID: $($claudeProcess[0].Id))" -ForegroundColor Gray
        }
        
        # Focus the window using Windows API
        if (-not ([System.Management.Automation.PSTypeName]'Win32').Type) {
            Add-Type -ErrorAction SilentlyContinue -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    [DllImport("user32.dll")]
    public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
    [DllImport("kernel32.dll")]
    public static extern uint GetCurrentThreadId();
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")]
    public static extern bool BlockInput(bool fBlockIt);
}
"@
        }
        
        [Win32]::ShowWindow($hwnd, 5)  # SW_SHOW
        
        # Block user input during automation if admin privileges available
        $inputBlocked = $false
        try {
            # Check if running with admin privileges
            $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
            $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            
            if ($isAdmin) {
                Write-Host "[CLISubmission] Blocking user input during automation..." -ForegroundColor Yellow
                $inputBlocked = [Win32]::BlockInput($true)
                if ($inputBlocked) {
                    Write-Host "[CLISubmission] User input blocked successfully" -ForegroundColor Green
                } else {
                    Write-Host "[CLISubmission] Failed to block user input" -ForegroundColor Yellow
                }
            } else {
                Write-Host "[CLISubmission] Input blocking requires admin privileges (continuing without blocking)" -ForegroundColor Gray
            }
        } catch {
            Write-Host "[CLISubmission] Error checking admin privileges: $_" -ForegroundColor Yellow
        }
        
        # Try enhanced SetForegroundWindow with AttachThreadInput bypass
        $foregroundWindow = [Win32]::GetForegroundWindow()
        $dummy = 0
        $foregroundThreadId = [Win32]::GetWindowThreadProcessId($foregroundWindow, [ref]$dummy)
        $currentThreadId = [Win32]::GetCurrentThreadId()
        
        # Attach to foreground thread to bypass SetForegroundWindow restrictions
        [Win32]::AttachThreadInput($currentThreadId, $foregroundThreadId, $true)
        $focused = [Win32]::SetForegroundWindow($hwnd)
        [Win32]::AttachThreadInput($currentThreadId, $foregroundThreadId, $false)
        
        if (-not $focused) {
            Write-Host "[CLISubmission] Direct focus failed, using Alt+Tab..." -ForegroundColor Yellow
            # Use Alt+Tab as fallback to cycle to the target window
            [System.Windows.Forms.SendKeys]::SendWait("%{TAB}")
            Start-Sleep -Milliseconds 500
            
            # May need multiple Alt+Tab presses to find the right window
            for ($i = 0; $i -lt 5; $i++) {
                $currentWindow = Get-Process | Where-Object { $_.MainWindowHandle -eq (Get-Process -Id $PID).MainWindowHandle }
                if ($currentWindow -and $currentWindow[0].MainWindowTitle -eq $claudeProcess[0].MainWindowTitle) {
                    break
                }
                [System.Windows.Forms.SendKeys]::SendWait("%{TAB}")
                Start-Sleep -Milliseconds 300
            }
        }
        
        Start-Sleep -Milliseconds $script:CLIConfig.WindowFocusDelayMs
        
        # Clear any existing input and submit prompt
        [System.Windows.Forms.SendKeys]::SendWait("^a")  # Select all
        Start-Sleep -Milliseconds $script:CLIConfig.KeystrokeDelayMs
        
        [System.Windows.Forms.SendKeys]::SendWait("{DEL}")  # Delete selected
        Start-Sleep -Milliseconds $script:CLIConfig.KeystrokeDelayMs
        
        # Send the prompt
        [System.Windows.Forms.SendKeys]::SendWait($Prompt)
        Start-Sleep -Milliseconds ($script:CLIConfig.KeystrokeDelayMs * 2)
        
        # Submit with Enter
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        
        Write-Host "[CLISubmission] Prompt submitted successfully" -ForegroundColor Green
        
        return @{
            Success = $true
            SubmissionTime = Get-Date
            TargetWindow = $claudeProcess[0].MainWindowTitle
            PromptLength = $Prompt.Length
        }
        
    } catch {
        Write-Host "[CLISubmission] Error submitting prompt: $($_.Exception.Message)" -ForegroundColor Red
        return @{ Success = $false; Error = $_.Exception.Message }
    } finally {
        # Always unblock input at the end
        if ($inputBlocked) {
            try {
                Write-Host "[CLISubmission] Unblocking user input..." -ForegroundColor Gray
                [Win32]::BlockInput($false)
                Write-Host "[CLISubmission] User input unblocked" -ForegroundColor Green
            } catch {
                Write-Host "[CLISubmission] Error unblocking input: $_" -ForegroundColor Yellow
            }
        }
    }
}

#endregion

#region Response Monitoring Functions

function Start-ResponseMonitoring {
    <#
    .SYNOPSIS
    Monitors for Claude Code CLI responses to autonomous prompts
    
    .DESCRIPTION
    Watches for new responses from Claude and triggers autonomous processing
    
    .PARAMETER OnResponseReceived
    Script block to execute when response is detected
    
    .EXAMPLE
    Start-ResponseMonitoring -OnResponseReceived { param($response) Process-ClaudeResponse $response }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ScriptBlock]$OnResponseReceived
    )
    
    Write-Host "[CLISubmission] Starting Claude response monitoring..." -ForegroundColor Yellow
    
    # Create response monitoring directory
    if (-not (Test-Path $script:CLIConfig.ResponseMonitorPath)) {
        New-Item -Path $script:CLIConfig.ResponseMonitorPath -ItemType Directory -Force | Out-Null
    }
    
    # Start FileSystemWatcher for response detection
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $script:CLIConfig.ResponseMonitorPath
    $watcher.Filter = "*.txt"
    $watcher.IncludeSubdirectories = $false
    $watcher.EnableRaisingEvents = $true
    
    # Register event handler
    $action = {
        param($source, $eventArgs)
        
        $filePath = $eventArgs.FullPath
        Write-Host "[CLISubmission] Response detected: $filePath" -ForegroundColor Cyan
        
        # Wait for file to be fully written
        Start-Sleep 2
        
        try {
            $responseContent = Get-Content $filePath -Raw -ErrorAction Stop
            & $OnResponseReceived $responseContent
        } catch {
            Write-Host "[CLISubmission] Error reading response: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $action
    
    Write-Host "[CLISubmission] Response monitoring active on: $($script:CLIConfig.ResponseMonitorPath)" -ForegroundColor Green
    
    return @{
        Success = $true
        Watcher = $watcher
        MonitorPath = $script:CLIConfig.ResponseMonitorPath
    }
}

#endregion

#region Integration Functions

function Start-AutonomousFeedbackLoop {
    <#
    .SYNOPSIS
    Starts complete autonomous feedback loop: Unity errors -> Claude prompts -> responses -> actions
    
    .DESCRIPTION
    Orchestrates the full autonomous cycle of error detection, prompt generation, submission, and response processing
    
    .EXAMPLE
    Start-AutonomousFeedbackLoop
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "[CLISubmission] Starting autonomous feedback loop..." -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    
    # Error detection callback
    $errorCallback = {
        param($errors)
        
        Write-Host "[CLISubmission] Unity errors detected: $($errors.Count)" -ForegroundColor Yellow
        
        # Generate intelligent prompt
        $promptResult = New-AutonomousPrompt -Errors $errors
        
        if ($promptResult.Success) {
            Write-Host "[CLISubmission] Generated prompt for $($promptResult.ErrorCount) errors" -ForegroundColor Green
            
            # Submit to Claude Code CLI
            $submissionResult = Submit-PromptToClaudeCode -Prompt $promptResult.Prompt
            
            if ($submissionResult.Success) {
                Write-Host "[CLISubmission] Prompt submitted to Claude Code CLI" -ForegroundColor Green
                Write-Host "[CLISubmission] Waiting for your response..." -ForegroundColor Cyan
            } else {
                Write-Host "[CLISubmission] Failed to submit prompt: $($submissionResult.Error)" -ForegroundColor Red
            }
        } else {
            Write-Host "[CLISubmission] Failed to generate prompt: $($promptResult.Error)" -ForegroundColor Red
        }
    }
    
    # Response processing callback
    $responseCallback = {
        param($response)
        
        Write-Host "[CLISubmission] Claude response received" -ForegroundColor Green
        Write-Host "[CLISubmission] Processing recommendations..." -ForegroundColor Yellow
        
        # Here we would integrate with SafeCommandExecution to apply fixes
        # For now, just log the response
        Write-Host "[CLISubmission] Response content preview:" -ForegroundColor Gray
        $preview = $response.Substring(0, [Math]::Min(200, $response.Length))
        Write-Host "  $preview..." -ForegroundColor DarkGray
    }
    
    # Start monitoring components
    $errorMonitoring = Start-UnityErrorMonitoring -OnErrorDetected $errorCallback
    $responseMonitoring = Start-ResponseMonitoring -OnResponseReceived $responseCallback
    
    if ($errorMonitoring.Success -and $responseMonitoring.Success) {
        Write-Host ""
        Write-Host "✅ AUTONOMOUS FEEDBACK LOOP ACTIVE!" -ForegroundColor Green
        Write-Host "====================================" -ForegroundColor Green
        Write-Host "• Unity error monitoring: ACTIVE" -ForegroundColor White
        Write-Host "• Claude prompt generation: READY" -ForegroundColor White
        Write-Host "• CLI submission automation: READY" -ForegroundColor White
        Write-Host "• Response monitoring: ACTIVE" -ForegroundColor White
        Write-Host ""
        Write-Host "The system will now:" -ForegroundColor Cyan
        Write-Host "1. Monitor Unity compilation errors" -ForegroundColor White
        Write-Host "2. Generate intelligent prompts" -ForegroundColor White
        Write-Host "3. Submit prompts to Claude Code CLI (this window)" -ForegroundColor White
        Write-Host "4. Process your responses automatically" -ForegroundColor White
        Write-Host ""
        Write-Host "To test: Create a Unity script with compilation errors" -ForegroundColor Yellow
        Write-Host "To stop: Use Stop-AutonomousFeedbackLoop" -ForegroundColor Yellow
        
        return @{
            Success = $true
            ErrorMonitoring = $errorMonitoring
            ResponseMonitoring = $responseMonitoring
            Status = "Active"
        }
    } else {
        Write-Host "❌ Failed to start autonomous feedback loop" -ForegroundColor Red
        return @{ Success = $false; Error = "Failed to initialize monitoring components" }
    }
}

function Stop-AutonomousFeedbackLoop {
    <#
    .SYNOPSIS
    Stops the autonomous feedback loop and cleans up monitoring
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "[CLISubmission] Stopping autonomous feedback loop..." -ForegroundColor Yellow
    
    # Stop Unity error monitoring
    Stop-UnityErrorMonitoring
    
    # Stop response monitoring
    $events = Get-EventSubscriber | Where-Object { $_.SourceObject -is [System.IO.FileSystemWatcher] }
    foreach ($event in $events) {
        Unregister-Event $event.SubscriptionId -Force
    }
    
    Write-Host "[CLISubmission] Autonomous feedback loop stopped" -ForegroundColor Green
}

#endregion

#region Public Interface

# Create alias for backward compatibility
Set-Alias -Name Submit-PromptToClaude -Value Submit-PromptToClaudeCode

# Export public functions
Export-ModuleMember -Function @(
    'Start-UnityErrorMonitoring',
    'Stop-UnityErrorMonitoring', 
    'New-AutonomousPrompt',
    'Submit-PromptToClaudeCode',
    'Start-ResponseMonitoring',
    'Start-AutonomousFeedbackLoop',
    'Stop-AutonomousFeedbackLoop'
) -Alias @(
    'Submit-PromptToClaude'
)

Write-Host "[CLISubmission] Claude Code CLI submission module loaded successfully" -ForegroundColor Green

#endregion
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQCf1zI990RcN/TQflfUfINfy
# vgygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUNXz7VgyAZNUsAewXKC5J67LQvf8wDQYJKoZIhvcNAQEBBQAEggEAianz
# tUXiGTRt+TIn4mYutOcnUDZy34OG/PJYX04T4AtGHl0Kwt7WxyELlyBVwSiwrjYY
# 4KIPVzhlWiZB4emZb+zZAczaJ0sO+hjzzMEApGVt5MKi5lojMHQ13HfN/S7YnTwE
# 154Qbc6UnV++usA1ToVURLg2d1oLumr3D8ZNqAkK2HeO8ZpPEtfs2myUU6zeUSs2
# ltRkWte02cYHgP58bPxUGIQVx7rjS3LUd1WGroYQyG7flzQQt9aJxQiU73vQIbzu
# NDH7eFOL9SwQe9VbrFQbObOeK2LqfFlyAbh0B6t3XFlxjCDldqk5y/609Q8u8K3X
# 8UohTm2qz69vvPEJ9Q==
# SIG # End signature block
