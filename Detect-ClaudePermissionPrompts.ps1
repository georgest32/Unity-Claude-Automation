# Detect-ClaudePermissionPrompts.ps1
# Detects when Claude Code CLI is asking for permission and can auto-respond

param(
    [string]$Mode = "Monitor",  # Monitor, AutoApprove, Interactive, Custom
    [hashtable]$ApprovalRules = @{},
    [string]$LogPath = ".\AutomationLogs\permission_prompts.log",
    [int]$CheckInterval = 100  # milliseconds
)

# Initialize Windows API for console reading
Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;
    
    public class ConsoleReader {
        [DllImport("kernel32.dll")]
        public static extern IntPtr GetStdHandle(int nStdHandle);
        
        [DllImport("kernel32.dll")]
        public static extern bool ReadConsoleOutputCharacter(
            IntPtr hConsoleOutput,
            StringBuilder lpCharacter,
            uint nLength,
            COORD dwReadCoord,
            out uint lpNumberOfCharsRead);
        
        [DllImport("kernel32.dll")]
        public static extern bool GetConsoleScreenBufferInfo(
            IntPtr hConsoleOutput,
            out CONSOLE_SCREEN_BUFFER_INFO lpConsoleScreenBufferInfo);
        
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
        
        public static string ReadLastLines(int numberOfLines) {
            IntPtr handle = GetStdHandle(STD_OUTPUT_HANDLE);
            CONSOLE_SCREEN_BUFFER_INFO info;
            GetConsoleScreenBufferInfo(handle, out info);
            
            StringBuilder result = new StringBuilder();
            for (int i = numberOfLines; i > 0; i--) {
                COORD coord = new COORD();
                coord.X = 0;
                coord.Y = (short)(info.dwCursorPosition.Y - i);
                
                if (coord.Y >= 0) {
                    StringBuilder line = new StringBuilder(info.dwSize.X);
                    uint charsRead;
                    ReadConsoleOutputCharacter(handle, line, (uint)info.dwSize.X, coord, out charsRead);
                    result.AppendLine(line.ToString().TrimEnd());
                }
            }
            return result.ToString();
        }
    }
"@

# Permission prompt patterns that Claude Code CLI uses
$script:PermissionPatterns = @(
    # Tool permission prompts
    @{
        Pattern = "Allow .+ to (read|write|execute|modify|delete) .+\? \(y/n\)"
        Type = "ToolPermission"
        DefaultResponse = "y"
    },
    @{
        Pattern = "Do you want to allow .+ to .+\? \[y/N\]"
        Type = "ToolPermission"
        DefaultResponse = "y"
    },
    @{
        Pattern = "Permission required: .+ wants to .+"
        Type = "ToolPermission"
        DefaultResponse = "y"
    },
    # Edit confirmations
    @{
        Pattern = "Apply edit to .+\? \(y/n\)"
        Type = "EditConfirmation"
        DefaultResponse = "y"
    },
    @{
        Pattern = "Accept changes to .+\? \[Y/n\]"
        Type = "EditConfirmation"
        DefaultResponse = "y"
    },
    # Command execution
    @{
        Pattern = "Execute command: .+\? \(y/n\)"
        Type = "CommandExecution"
        DefaultResponse = "y"
    },
    @{
        Pattern = "Run `".+`"\? \[y/N\]"
        Type = "CommandExecution"
        DefaultResponse = "n"  # Default to no for commands
    },
    # File operations
    @{
        Pattern = "Create file .+\? \(y/n\)"
        Type = "FileOperation"
        DefaultResponse = "y"
    },
    @{
        Pattern = "Delete .+\? \[y/N\]"
        Type = "FileOperation"
        DefaultResponse = "n"  # Default to no for deletions
    }
)

# Custom approval rules for specific scenarios
$script:DefaultApprovalRules = @{
    # Auto-approve read operations
    "read" = @{
        Pattern = ".*\bread\b.*"
        AutoApprove = $true
        Response = "y"
    }
    # Auto-approve specific directories
    "project_dir" = @{
        Pattern = ".*Unity-Claude-Automation.*"
        AutoApprove = $true
        Response = "y"
    }
    # Deny dangerous operations
    "system_files" = @{
        Pattern = ".*(System32|Windows|Program Files).*"
        AutoApprove = $true
        Response = "n"
    }
    # Require manual approval for deletions
    "delete_ops" = @{
        Pattern = ".*\b(delete|remove|rm)\b.*"
        AutoApprove = $false
        Response = "manual"
    }
}

# Merge default rules with user-provided rules
if ($ApprovalRules.Count -eq 0) {
    $ApprovalRules = $script:DefaultApprovalRules
} else {
    foreach ($key in $script:DefaultApprovalRules.Keys) {
        if (-not $ApprovalRules.ContainsKey($key)) {
            $ApprovalRules[$key] = $script:DefaultApprovalRules[$key]
        }
    }
}

function Test-PermissionPrompt {
    param([string]$Text)
    
    foreach ($pattern in $script:PermissionPatterns) {
        if ($Text -match $pattern.Pattern) {
            return @{
                IsPermissionPrompt = $true
                Type = $pattern.Type
                Pattern = $pattern.Pattern
                DefaultResponse = $pattern.DefaultResponse
                PromptText = $Text
            }
        }
    }
    
    return @{ IsPermissionPrompt = $false }
}

function Get-ApprovalResponse {
    param(
        [hashtable]$PromptInfo,
        [hashtable]$Rules,
        [string]$Mode
    )
    
    $response = $null
    $reason = ""
    
    # Check custom rules first
    foreach ($rule in $Rules.Values) {
        if ($PromptInfo.PromptText -match $rule.Pattern) {
            if ($rule.AutoApprove) {
                $response = $rule.Response
                $reason = "Matched rule: $($rule.Pattern)"
                break
            } elseif ($rule.Response -eq "manual") {
                $response = $null
                $reason = "Manual approval required by rule"
                break
            }
        }
    }
    
    # If no rule matched, use mode-based logic
    if ($null -eq $response) {
        switch ($Mode) {
            "AutoApprove" {
                $response = $PromptInfo.DefaultResponse
                $reason = "Auto-approve mode"
            }
            "Interactive" {
                $response = $null
                $reason = "Interactive mode - user input required"
            }
            "Custom" {
                # Already handled by rules above
                if (-not $reason) {
                    $response = $PromptInfo.DefaultResponse
                    $reason = "No matching rule, using default"
                }
            }
            default {
                # Monitor mode - don't respond
                $response = $null
                $reason = "Monitor mode - no response"
            }
        }
    }
    
    return @{
        Response = $response
        Reason = $reason
    }
}

function Send-Response {
    param([string]$Response)
    
    if ($Response) {
        # Send keystrokes to the console
        Add-Type -AssemblyName System.Windows.Forms
        [System.Windows.Forms.SendKeys]::SendWait($Response)
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        return $true
    }
    return $false
}

function Write-PermissionLog {
    param(
        [hashtable]$PromptInfo,
        [string]$Response,
        [string]$Reason
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = @{
        Timestamp = $timestamp
        Type = $PromptInfo.Type
        Prompt = $PromptInfo.PromptText
        Response = $Response
        Reason = $Reason
    } | ConvertTo-Json -Compress
    
    # Ensure log directory exists
    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    # Append to log file
    Add-Content -Path $LogPath -Value $logEntry
}

# Main monitoring loop
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "CLAUDE PERMISSION PROMPT DETECTOR" -ForegroundColor Green
Write-Host "Mode: $Mode" -ForegroundColor Yellow
Write-Host "Log: $LogPath" -ForegroundColor Yellow
Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host ""

Write-Host "Monitoring for permission prompts..." -ForegroundColor Gray
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""

$lastPrompt = ""
$promptCount = 0

try {
    while ($true) {
        # Read last few lines from console
        try {
            $consoleText = [ConsoleReader]::ReadLastLines(5)
            
            # Check if it's a permission prompt
            $promptInfo = Test-PermissionPrompt -Text $consoleText
            
            if ($promptInfo.IsPermissionPrompt -and $consoleText -ne $lastPrompt) {
                $lastPrompt = $consoleText
                $promptCount++
                
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Permission prompt detected (#$promptCount)" -ForegroundColor Yellow
                Write-Host "Type: $($promptInfo.Type)" -ForegroundColor Cyan
                Write-Host "Prompt: $($promptInfo.PromptText.Trim())" -ForegroundColor White
                
                # Get response based on mode and rules
                $approval = Get-ApprovalResponse -PromptInfo $promptInfo -Rules $ApprovalRules -Mode $Mode
                
                if ($approval.Response) {
                    Write-Host "Response: $($approval.Response) ($($approval.Reason))" -ForegroundColor Green
                    
                    # Send the response
                    if (Send-Response -Response $approval.Response) {
                        Write-Host "Response sent successfully" -ForegroundColor Green
                    }
                } else {
                    Write-Host "Action: $($approval.Reason)" -ForegroundColor Magenta
                    
                    if ($Mode -eq "Interactive") {
                        Write-Host "Manual input required - please respond in the Claude window" -ForegroundColor Yellow
                    }
                }
                
                # Log the interaction
                Write-PermissionLog -PromptInfo $promptInfo -Response $approval.Response -Reason $approval.Reason
                
                Write-Host "-" * 40 -ForegroundColor Gray
            }
        } catch {
            # Silently continue on read errors
        }
        
        Start-Sleep -Milliseconds $CheckInterval
    }
} catch {
    if ($_.Exception.Message -notlike "*The operation was canceled*") {
        Write-Host "Error: $_" -ForegroundColor Red
    }
} finally {
    Write-Host "`nMonitoring stopped" -ForegroundColor Yellow
    Write-Host "Total prompts detected: $promptCount" -ForegroundColor Cyan
    if (Test-Path $LogPath) {
        Write-Host "Log saved to: $LogPath" -ForegroundColor Green
    }
}