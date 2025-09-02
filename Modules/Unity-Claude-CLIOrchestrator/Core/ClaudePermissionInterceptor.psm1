# ClaudePermissionInterceptor.psm1
# Real-time Claude CLI permission detection and automatic response system

#region Configuration
$script:InterceptorConfig = @{
    Enabled = $true
    MonitoringActive = $false
    ResponseDelay = 200  # ms
    CheckInterval = 50   # ms
    LogPath = ".\AutomationLogs\permission_intercepts.json"
    Statistics = @{
        PromptsDetected = 0
        ResponsesSent = 0
        ErrorCount = 0
        StartTime = $null
    }
}

# Enhanced Claude CLI permission patterns
$script:ClaudePermissionPatterns = @(
    @{
        Pattern = "(?i)Allow\s+(.+?)\s+to\s+(read|write|execute|modify|delete)\s+(.+?)\?\s+\(y/n\)"
        Type = "ToolPermission"
        Captures = @("tool", "action", "target")
    },
    @{
        Pattern = "(?i)Do you want to allow\s+(.+?)\s+to\s+(.+?)\?\s+\[(y|yes)/(n|no)\]"
        Type = "GeneralPermission"
        Captures = @("tool", "action")
    },
    @{
        Pattern = "(?i)Execute command:\s+(.+?)\?\s+\(y/n\)"
        Type = "CommandExecution"
        Captures = @("command")
    },
    @{
        Pattern = "(?i)Apply edit to\s+(.+?)\?\s+\(y/n\)"
        Type = "EditConfirmation"
        Captures = @("file")
    },
    @{
        Pattern = "(?i)Create file\s+(.+?)\?\s+\(y/n\)"
        Type = "FileCreation"
        Captures = @("file")
    },
    @{
        Pattern = "(?i)Permission required for\s+(.+)"
        Type = "ExplicitPermission"
        Captures = @("description")
    },
    @{
        Pattern = "(?i)Continue\?\s+\(y/n\)"
        Type = "ContinuePrompt"
        Captures = @()
    }
)
#endregion

#region Windows API for Console Reading
Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;

public class ConsoleInterceptor {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetStdHandle(int nStdHandle);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool GetConsoleScreenBufferInfo(
        IntPtr hConsoleOutput,
        out CONSOLE_SCREEN_BUFFER_INFO lpConsoleScreenBufferInfo);
    
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool ReadConsoleOutputCharacter(
        IntPtr hConsoleOutput,
        StringBuilder lpCharacter,
        uint nLength,
        COORD dwReadCoord,
        out uint lpNumberOfCharsRead);
        
    [DllImport("user32.dll")]
    public static extern IntPtr GetForegroundWindow();
    
    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
    
    [DllImport("user32.dll")]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
    
    [StructLayout(LayoutKind.Sequential)]
    public struct COORD {
        public short X;
        public short Y;
    }
    
    [StructLayout(LayoutKind.Sequential)]
    public struct SMALL_RECT {
        public short Left;
        public short Top;
        public short Right;
        public short Bottom;
    }
    
    [StructLayout(LayoutKind.Sequential)]
    public struct CONSOLE_SCREEN_BUFFER_INFO {
        public COORD dwSize;
        public COORD dwCursorPosition;
        public ushort wAttributes;
        public SMALL_RECT srWindow;
        public COORD dwMaximumWindowSize;
    }
    
    const int STD_OUTPUT_HANDLE = -11;
    
    public static string ReadConsoleLines(int numberOfLines) {
        IntPtr handle = GetStdHandle(STD_OUTPUT_HANDLE);
        CONSOLE_SCREEN_BUFFER_INFO bufferInfo;
        GetConsoleScreenBufferInfo(handle, out bufferInfo);
        
        StringBuilder result = new StringBuilder();
        
        for (int i = numberOfLines; i > 0; i--) {
            COORD coord = new COORD();
            coord.X = 0;
            coord.Y = (short)(bufferInfo.dwCursorPosition.Y - i);
            
            if (coord.Y >= 0) {
                StringBuilder line = new StringBuilder(bufferInfo.dwSize.X);
                uint charsRead;
                ReadConsoleOutputCharacter(handle, line, (uint)bufferInfo.dwSize.X, coord, out charsRead);
                string lineText = line.ToString().TrimEnd();
                if (!string.IsNullOrWhiteSpace(lineText)) {
                    result.AppendLine(lineText);
                }
            }
        }
        
        return result.ToString();
    }
    
    public static string GetActiveWindowTitle() {
        const int nChars = 256;
        StringBuilder buff = new StringBuilder(nChars);
        IntPtr handle = GetForegroundWindow();
        
        if (GetWindowText(handle, buff, nChars) > 0) {
            return buff.ToString();
        }
        return "";
    }
    
    public static bool FindAndFocusClaudeWindow() {
        // Try to find Claude CLI window
        string[] possibleTitles = {
            "claude", "Claude", "Claude Code", "cmd", "powershell", "terminal", "Windows Terminal"
        };
        
        foreach (string title in possibleTitles) {
            IntPtr window = FindWindow(null, title);
            if (window != IntPtr.Zero) {
                SetForegroundWindow(window);
                return true;
            }
        }
        
        return false;
    }
}
"@ -ErrorAction SilentlyContinue
#endregion

#region Core Functions

function Start-ClaudePermissionInterceptor {
    <#
    .SYNOPSIS
        Starts real-time monitoring of Claude CLI for permission prompts
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PermissionHandler,
        
        [int]$CheckInterval = 50,
        [int]$MaxHistory = 10
    )
    
    if ($script:InterceptorConfig.MonitoringActive) {
        Write-Warning "Permission interceptor is already running"
        return
    }
    
    $script:InterceptorConfig.MonitoringActive = $true
    $script:InterceptorConfig.Statistics.StartTime = Get-Date
    $script:InterceptorConfig.CheckInterval = $CheckInterval
    
    Write-Host "[Interceptor] Starting Claude permission monitoring..." -ForegroundColor Green
    Write-Host "[Interceptor] Check interval: ${CheckInterval}ms" -ForegroundColor Gray
    
    # Background monitoring script
    $monitorScript = {
        param($Config, $Patterns, $PermissionHandlerConfig)
        
        $lastConsoleContent = ""
        $consecutiveEmpty = 0
        
        while ($Config.MonitoringActive) {
            try {
                # Read recent console content
                $consoleContent = [ConsoleInterceptor]::ReadConsoleLines(5)
                
                # Check if content changed
                if ($consoleContent -ne $lastConsoleContent -and -not [string]::IsNullOrWhiteSpace($consoleContent)) {
                    $lastConsoleContent = $consoleContent
                    $consecutiveEmpty = 0
                    
                    # Check for permission patterns
                    foreach ($pattern in $Patterns) {
                        if ($consoleContent -match $pattern.Pattern) {
                            $match = [regex]::Match($consoleContent, $pattern.Pattern)
                            
                            # Extract captured data
                            $capturedData = @{}
                            for ($i = 0; $i -lt $pattern.Captures.Count; $i++) {
                                if ($i + 1 -lt $match.Groups.Count) {
                                    $capturedData[$pattern.Captures[$i]] = $match.Groups[$i + 1].Value
                                }
                            }
                            
                            # Create prompt info
                            $promptInfo = @{
                                Type = $pattern.Type
                                OriginalText = $consoleContent.Trim()
                                CapturedData = $capturedData
                                Timestamp = Get-Date
                                Pattern = $pattern.Pattern
                            }
                            
                            # Signal detection
                            $detection = @{
                                Detected = $true
                                PromptInfo = $promptInfo
                                Timestamp = Get-Date
                            }
                            
                            # Write to named pipe or file for main process to pick up
                            $detectionJson = $detection | ConvertTo-Json -Depth 10 -Compress
                            $detectionFile = ".\AutomationLogs\permission_detected_$(Get-Date -Format 'yyyyMMddHHmmssffff').json"
                            $detectionJson | Out-File -FilePath $detectionFile -Encoding UTF8
                            
                            break
                        }
                    }
                } else {
                    $consecutiveEmpty++
                    if ($consecutiveEmpty -gt 100) {
                        # Reduce CPU usage when no activity
                        Start-Sleep -Milliseconds 500
                        $consecutiveEmpty = 0
                    }
                }
            } catch {
                # Continue silently on errors
            }
            
            Start-Sleep -Milliseconds $Config.CheckInterval
        }
    }
    
    # Start monitoring job
    $monitorJob = Start-Job -ScriptBlock $monitorScript -ArgumentList $script:InterceptorConfig, $script:ClaudePermissionPatterns, $PermissionHandler
    
    # Start detection processor
    Start-DetectionProcessor -PermissionHandler $PermissionHandler
    
    return @{
        Success = $true
        JobId = $monitorJob.Id
        StartTime = $script:InterceptorConfig.Statistics.StartTime
    }
}

function Start-DetectionProcessor {
    <#
    .SYNOPSIS
        Processes detected permission prompts and sends appropriate responses
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PermissionHandler
    )
    
    $processorScript = {
        param($Config, $HandlerConfig)
        
        $detectionPattern = ".\AutomationLogs\permission_detected_*.json"
        
        while ($Config.MonitoringActive) {
            try {
                # Check for detection files
                $detectionFiles = Get-ChildItem -Path $detectionPattern -ErrorAction SilentlyContinue
                
                foreach ($file in $detectionFiles) {
                    try {
                        # Read detection data
                        $detectionData = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                        
                        if ($detectionData.Detected) {
                            $Config.Statistics.PromptsDetected++
                            
                            Write-Host "[Interceptor] Permission prompt detected: $($detectionData.PromptInfo.Type)" -ForegroundColor Yellow
                            
                            # Make decision using permission handler
                            $decision = @{
                                Action = "approve"  # Default for demonstration
                                Confidence = 0.8
                                Reason = "Auto-approved by interceptor"
                            }
                            
                            # Apply intelligent decision logic based on handler config
                            if ($HandlerConfig.Mode -eq "SafeOnly") {
                                if ($detectionData.PromptInfo.Type -match "Delete|Remove|Clear") {
                                    $decision.Action = "deny"
                                    $decision.Reason = "Safe mode - destructive operation blocked"
                                }
                            }
                            
                            # Send response if decision is to approve or deny
                            if ($decision.Action -in @("approve", "deny")) {
                                $response = if ($decision.Action -eq "approve") { "y" } else { "n" }
                                
                                # Focus Claude window and send response
                                if ([ConsoleInterceptor]::FindAndFocusClaudeWindow()) {
                                    Start-Sleep -Milliseconds $Config.ResponseDelay
                                    
                                    # Send keystrokes
                                    Add-Type -AssemblyName System.Windows.Forms
                                    [System.Windows.Forms.SendKeys]::SendWait($response)
                                    [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
                                    
                                    $Config.Statistics.ResponsesSent++
                                    
                                    Write-Host "[Interceptor] Response sent: $response ($($decision.Reason))" -ForegroundColor Green
                                }
                            }
                            
                            # Log the interaction
                            $logEntry = @{
                                Timestamp = Get-Date
                                PromptInfo = $detectionData.PromptInfo
                                Decision = $decision
                                Response = if ($decision.Action -in @("approve", "deny")) { if ($decision.Action -eq "approve") { "y" } else { "n" } } else { "none" }
                            }
                            
                            $logJson = $logEntry | ConvertTo-Json -Depth 10 -Compress
                            Add-Content -Path $Config.LogPath -Value $logJson
                        }
                        
                        # Clean up detection file
                        Remove-Item -Path $file.FullName -Force -ErrorAction SilentlyContinue
                        
                    } catch {
                        Write-Warning "[Interceptor] Error processing detection file: $_"
                        $Config.Statistics.ErrorCount++
                    }
                }
            } catch {
                # Continue on errors
            }
            
            Start-Sleep -Milliseconds 100
        }
    }
    
    # Start processor job
    $processorJob = Start-Job -ScriptBlock $processorScript -ArgumentList $script:InterceptorConfig, $PermissionHandler
    
    return $processorJob
}

function Stop-ClaudePermissionInterceptor {
    <#
    .SYNOPSIS
        Stops the permission interceptor
    #>
    [CmdletBinding()]
    param()
    
    if (-not $script:InterceptorConfig.MonitoringActive) {
        Write-Warning "Permission interceptor is not running"
        return
    }
    
    $script:InterceptorConfig.MonitoringActive = $false
    
    # Stop background jobs
    Get-Job | Where-Object { $_.Name -match "Job" -and $_.State -eq "Running" } | Stop-Job -PassThru | Remove-Job
    
    # Clean up detection files
    Get-ChildItem -Path ".\AutomationLogs\permission_detected_*.json" -ErrorAction SilentlyContinue | Remove-Item -Force
    
    Write-Host "[Interceptor] Permission monitoring stopped" -ForegroundColor Yellow
    
    # Show statistics
    $stats = $script:InterceptorConfig.Statistics
    $duration = if ($stats.StartTime) { (Get-Date) - $stats.StartTime } else { [TimeSpan]::Zero }
    
    Write-Host "`nInterceptor Statistics:" -ForegroundColor Cyan
    Write-Host "  Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor White
    Write-Host "  Prompts Detected: $($stats.PromptsDetected)" -ForegroundColor White
    Write-Host "  Responses Sent: $($stats.ResponsesSent)" -ForegroundColor White
    Write-Host "  Errors: $($stats.ErrorCount)" -ForegroundColor White
    
    return @{
        Success = $true
        Statistics = $stats
        Duration = $duration
    }
}

function Test-ClaudePermissionDetection {
    <#
    .SYNOPSIS
        Tests permission detection with sample patterns
    #>
    [CmdletBinding()]
    param()
    
    Write-Host "Testing Claude permission pattern detection..." -ForegroundColor Cyan
    
    $testPrompts = @(
        "Allow Bash to execute command 'git status'? (y/n)",
        "Do you want to allow Edit to modify main.py? [y/n]",
        "Execute command: npm install? (y/n)",
        "Apply edit to config.json? (y/n)",
        "Create file output.txt? (y/n)",
        "Permission required for file system access",
        "Continue? (y/n)"
    )
    
    $detectedCount = 0
    
    foreach ($prompt in $testPrompts) {
        Write-Host "`nTesting: $prompt" -ForegroundColor Gray
        
        $detected = $false
        foreach ($pattern in $script:ClaudePermissionPatterns) {
            if ($prompt -match $pattern.Pattern) {
                $match = [regex]::Match($prompt, $pattern.Pattern)
                
                Write-Host "  ✅ Detected as: $($pattern.Type)" -ForegroundColor Green
                
                # Show captured data
                for ($i = 0; $i -lt $pattern.Captures.Count; $i++) {
                    if ($i + 1 -lt $match.Groups.Count) {
                        Write-Host "    $($pattern.Captures[$i]): $($match.Groups[$i + 1].Value)" -ForegroundColor Yellow
                    }
                }
                
                $detected = $true
                $detectedCount++
                break
            }
        }
        
        if (-not $detected) {
            Write-Host "  ❌ Not detected" -ForegroundColor Red
        }
    }
    
    Write-Host "`nDetection Summary:" -ForegroundColor Cyan
    Write-Host "  Total Tests: $($testPrompts.Count)" -ForegroundColor White
    Write-Host "  Detected: $detectedCount" -ForegroundColor White
    Write-Host "  Success Rate: $([math]::Round(($detectedCount / $testPrompts.Count) * 100, 2))%" -ForegroundColor White
    
    return @{
        TotalTests = $testPrompts.Count
        Detected = $detectedCount
        SuccessRate = ($detectedCount / $testPrompts.Count) * 100
    }
}

function Get-InterceptorStatistics {
    <#
    .SYNOPSIS
        Gets current interceptor statistics
    #>
    [CmdletBinding()]
    param()
    
    $stats = $script:InterceptorConfig.Statistics.Clone()
    $stats.IsActive = $script:InterceptorConfig.MonitoringActive
    $stats.ConfiguredPatterns = $script:ClaudePermissionPatterns.Count
    
    if ($stats.StartTime) {
        $stats.Duration = (Get-Date) - $stats.StartTime
    }
    
    return $stats
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Start-ClaudePermissionInterceptor',
    'Stop-ClaudePermissionInterceptor',
    'Test-ClaudePermissionDetection',
    'Test-ClaudePermissionPrompt',
    'Get-InterceptorStatistics'
)