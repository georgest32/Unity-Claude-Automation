# PermissionHandler.psm1
# Handles Claude Code CLI permission prompts for the orchestrator

#region Module Configuration
$script:PermissionConfig = @{
    Enabled = $true
    Mode = "Intelligent"  # Monitor, AutoApprove, Intelligent, Manual
    LogPath = ".\AutomationLogs\orchestrator_permissions.json"
    ResponseDelay = 500  # ms delay before responding
    Patterns = @()
    Statistics = @{
        PromptsDetected = 0
        AutoApproved = 0
        AutoDenied = 0
        ManualRequired = 0
    }
}
#endregion

#region Permission Detection Patterns
$script:PermissionPatterns = @(
    # Standard permission prompts
    @{
        Pattern = "(?i)allow .+ to (read|write|execute|modify|delete) .+\? \((y|yes)/(n|no)\)"
        Type = "ToolPermission"
        Capture = @("action", "target")
    },
    @{
        Pattern = "(?i)do you want to .+\? \[(y|yes)/(n|no)\]"
        Type = "GeneralPermission"
        Capture = @("action")
    },
    @{
        Pattern = "(?i)permission required:.+"
        Type = "ExplicitPermission"
        Capture = @("description")
    },
    # Edit confirmation
    @{
        Pattern = "(?i)apply (edit|changes?) to .+\? \((y|yes)/(n|no)\)"
        Type = "EditConfirmation"
        Capture = @("file")
    },
    @{
        Pattern = "(?i)accept changes to .+\? \[(y|yes)/(n|no)\]"
        Type = "EditConfirmation"
        Capture = @("file")
    },
    # Command execution
    @{
        Pattern = "(?i)execute command: .+\? \((y|yes)/(n|no)\)"
        Type = "CommandExecution"
        Capture = @("command")
    },
    @{
        Pattern = '(?i)run [`""](.+)[`""]?\? \[(y|yes)/(n|no)\]'
        Type = "CommandExecution"
        Capture = @("command")
    },
    # File operations
    @{
        Pattern = "(?i)(create|delete|modify) file .+\? \((y|yes)/(n|no)\)"
        Type = "FileOperation"
        Capture = @("operation", "file")
    },
    # Tool-specific patterns
    @{
        Pattern = "(?i)\[tool: (\w+)\] .+ requires permission"
        Type = "ToolSpecific"
        Capture = @("tool", "action")
    }
)
#endregion

#region Intelligent Decision Rules
$script:DecisionRules = @{
    # Always allow read operations
    ReadOperations = @{
        Pattern = "(?i)\b(read|view|list|get|fetch|check|inspect)\b"
        Decision = "approve"
        Confidence = 0.95
        Reason = "Read operations are safe"
    }
    
    # Allow writes to project directories
    ProjectWrites = @{
        Pattern = "(?i)(Unity-Claude-Automation|AutomationLogs|ClaudeResponses|TestResults)"
        Decision = "approve"
        Confidence = 0.9
        Reason = "Writing to project directories"
    }
    
    # Deny system modifications
    SystemFiles = @{
        Pattern = "(?i)(System32|Windows|Program Files|ProgramData|AppData\\Roaming\\Microsoft)"
        Decision = "deny"
        Confidence = 1.0
        Reason = "System file protection"
    }
    
    # Deny dangerous commands
    DangerousCommands = @{
        Pattern = "(?i)(Remove-Item.*-Recurse|rm -rf|del /f|format|diskpart)"
        Decision = "deny"
        Confidence = 1.0
        Reason = "Dangerous command detected"
    }
    
    # Allow test operations
    TestOperations = @{
        Pattern = "(?i)(test|spec|mock|stub|example|sample|demo)"
        Decision = "approve"
        Confidence = 0.8
        Reason = "Test operation detected"
    }
    
    # Require manual for production
    ProductionOperations = @{
        Pattern = "(?i)(production|prod|live|master|main branch)"
        Decision = "manual"
        Confidence = 1.0
        Reason = "Production operation requires manual approval"
    }
    
    # Allow documentation updates
    DocumentationUpdates = @{
        Pattern = "(?i)\.(md|txt|rst|adoc|html|css)$"
        Decision = "approve"
        Confidence = 0.85
        Reason = "Documentation file update"
    }
    
    # Allow git operations
    GitOperations = @{
        Pattern = "(?i)git (status|diff|log|branch|checkout|pull|fetch)"
        Decision = "approve"
        Confidence = 0.9
        Reason = "Safe git operation"
    }
    
    # Caution with git push
    GitPush = @{
        Pattern = "(?i)git push"
        Decision = "manual"
        Confidence = 0.95
        Reason = "Git push requires review"
    }
}
#endregion

#region Public Functions

function Initialize-PermissionHandler {
    <#
    .SYNOPSIS
        Initializes the permission handler for Claude CLI orchestration
    #>
    [CmdletBinding()]
    param(
        [string]$Mode = "Intelligent",
        [string]$LogPath = $script:PermissionConfig.LogPath
    )
    
    $script:PermissionConfig.Mode = $Mode
    $script:PermissionConfig.LogPath = $LogPath
    $script:PermissionConfig.Enabled = $true
    
    # Ensure log directory exists
    $logDir = Split-Path $LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    Write-Host "[PermissionHandler] Initialized in $Mode mode" -ForegroundColor Green
    
    return @{
        Success = $true
        Mode = $Mode
        LogPath = $LogPath
    }
}

function Test-ClaudePermissionPrompt {
    <#
    .SYNOPSIS
        Tests if the given text contains a Claude permission prompt
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )
    
    foreach ($pattern in $script:PermissionPatterns) {
        if ($Text -match $pattern.Pattern) {
            $matches = [regex]::Match($Text, $pattern.Pattern)
            
            $capturedData = @{}
            if ($pattern.Capture) {
                for ($i = 0; $i -lt $pattern.Capture.Count; $i++) {
                    if ($i + 1 -lt $matches.Groups.Count) {
                        $capturedData[$pattern.Capture[$i]] = $matches.Groups[$i + 1].Value
                    }
                }
            }
            
            return @{
                IsPermissionPrompt = $true
                Type = $pattern.Type
                Pattern = $pattern.Pattern
                CapturedData = $capturedData
                OriginalText = $Text
                Timestamp = Get-Date
            }
        }
    }
    
    return @{
        IsPermissionPrompt = $false
        OriginalText = $Text
    }
}

function Get-PermissionDecision {
    <#
    .SYNOPSIS
        Makes an intelligent decision about a permission request
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PromptInfo
    )
    
    $decision = @{
        Action = "manual"
        Confidence = 0.0
        Reason = "No matching rule"
        Rules = @()
    }
    
    if ($script:PermissionConfig.Mode -eq "Monitor") {
        $decision.Action = "monitor"
        $decision.Reason = "Monitor mode - no action taken"
        return $decision
    }
    
    if ($script:PermissionConfig.Mode -eq "AutoApprove") {
        $decision.Action = "approve"
        $decision.Confidence = 1.0
        $decision.Reason = "Auto-approve mode"
        return $decision
    }
    
    if ($script:PermissionConfig.Mode -eq "Manual") {
        $decision.Action = "manual"
        $decision.Reason = "Manual mode - user input required"
        return $decision
    }
    
    # Intelligent mode - analyze the request
    $matchedRules = @()
    $totalConfidence = 0
    $approveVotes = 0
    $denyVotes = 0
    
    foreach ($ruleName in $script:DecisionRules.Keys) {
        $rule = $script:DecisionRules[$ruleName]
        
        if ($PromptInfo.OriginalText -match $rule.Pattern) {
            $matchedRules += @{
                Name = $ruleName
                Decision = $rule.Decision
                Confidence = $rule.Confidence
                Reason = $rule.Reason
            }
            
            switch ($rule.Decision) {
                "approve" {
                    $approveVotes += $rule.Confidence
                }
                "deny" {
                    $denyVotes += $rule.Confidence
                }
                "manual" {
                    # Manual override
                    $decision.Action = "manual"
                    $decision.Confidence = $rule.Confidence
                    $decision.Reason = $rule.Reason
                    $decision.Rules = @($ruleName)
                    return $decision
                }
            }
            
            $totalConfidence += $rule.Confidence
        }
    }
    
    if ($matchedRules.Count -gt 0) {
        # Determine final decision based on votes
        if ($denyVotes -gt 0) {
            # Any deny vote overrides approvals
            $decision.Action = "deny"
            $decision.Confidence = $denyVotes / $matchedRules.Count
            $decision.Reason = ($matchedRules | Where-Object { $_.Decision -eq "deny" } | Select-Object -First 1).Reason
        } elseif ($approveVotes -gt 0) {
            $decision.Action = "approve"
            $decision.Confidence = $approveVotes / $matchedRules.Count
            $decision.Reason = ($matchedRules | Where-Object { $_.Decision -eq "approve" } | Select-Object -First 1).Reason
        }
        
        $decision.Rules = $matchedRules | ForEach-Object { $_.Name }
    } else {
        # No rules matched - check prompt type defaults
        switch ($PromptInfo.Type) {
            "EditConfirmation" {
                $decision.Action = "approve"
                $decision.Confidence = 0.7
                $decision.Reason = "Default: approve edits"
            }
            "CommandExecution" {
                $decision.Action = "manual"
                $decision.Confidence = 0.5
                $decision.Reason = "Default: manual review for commands"
            }
            "FileOperation" {
                if ($PromptInfo.CapturedData.operation -eq "delete") {
                    $decision.Action = "manual"
                    $decision.Confidence = 0.8
                    $decision.Reason = "Default: manual review for deletions"
                } else {
                    $decision.Action = "approve"
                    $decision.Confidence = 0.6
                    $decision.Reason = "Default: approve file operations"
                }
            }
            default {
                $decision.Action = "manual"
                $decision.Confidence = 0.0
                $decision.Reason = "Unknown prompt type"
            }
        }
    }
    
    return $decision
}

function Submit-PermissionResponse {
    <#
    .SYNOPSIS
        Submits a response to a Claude permission prompt
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("approve", "deny", "y", "n", "yes", "no")]
        [string]$Response
    )
    
    # Normalize response
    $normalizedResponse = switch ($Response) {
        "approve" { "y" }
        "deny" { "n" }
        "yes" { "y" }
        "no" { "n" }
        default { $Response }
    }
    
    try {
        # Add delay to ensure prompt is ready
        Start-Sleep -Milliseconds $script:PermissionConfig.ResponseDelay
        
        # Send keystroke
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
        [System.Windows.Forms.SendKeys]::SendWait($normalizedResponse)
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        
        return @{
            Success = $true
            Response = $normalizedResponse
            Timestamp = Get-Date
        }
    } catch {
        return @{
            Success = $false
            ErrorMessage = $_.Exception.Message
            Response = $normalizedResponse
            Timestamp = Get-Date
        }
    }
}

function Write-PermissionLog {
    <#
    .SYNOPSIS
        Logs a permission interaction
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$PromptInfo,
        
        [Parameter(Mandatory)]
        [hashtable]$Decision,
        
        [string]$Response,
        [bool]$Success = $true
    )
    
    $logEntry = @{
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        PromptType = $PromptInfo.Type
        PromptText = $PromptInfo.OriginalText
        CapturedData = $PromptInfo.CapturedData
        Decision = $Decision.Action
        Confidence = $Decision.Confidence
        Reason = $Decision.Reason
        Rules = $Decision.Rules
        Response = $Response
        Success = $Success
        Mode = $script:PermissionConfig.Mode
    }
    
    # Update statistics
    $script:PermissionConfig.Statistics.PromptsDetected++
    
    switch ($Decision.Action) {
        "approve" { $script:PermissionConfig.Statistics.AutoApproved++ }
        "deny" { $script:PermissionConfig.Statistics.AutoDenied++ }
        "manual" { $script:PermissionConfig.Statistics.ManualRequired++ }
    }
    
    # Write to log file
    try {
        $json = $logEntry | ConvertTo-Json -Depth 10 -Compress
        Add-Content -Path $script:PermissionConfig.LogPath -Value $json
    } catch {
        Write-Warning "Failed to write permission log: $_"
    }
    
    return $logEntry
}

function Get-PermissionStatistics {
    <#
    .SYNOPSIS
        Gets current permission handling statistics
    #>
    [CmdletBinding()]
    param()
    
    return $script:PermissionConfig.Statistics
}

function Add-PermissionRule {
    <#
    .SYNOPSIS
        Adds a custom permission rule
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        
        [Parameter(Mandatory)]
        [string]$Pattern,
        
        [Parameter(Mandatory)]
        [ValidateSet("approve", "deny", "manual")]
        [string]$Decision,
        
        [double]$Confidence = 0.8,
        [string]$Reason = "Custom rule"
    )
    
    $script:DecisionRules[$Name] = @{
        Pattern = $Pattern
        Decision = $Decision
        Confidence = $Confidence
        Reason = $Reason
    }
    
    return @{
        Success = $true
        Rule = $Name
        Action = "Added"
    }
}

#endregion

#region Integration Functions

function Start-PermissionMonitor {
    <#
    .SYNOPSIS
        Starts monitoring for Claude permission prompts (for orchestrator integration)
    #>
    [CmdletBinding()]
    param(
        [scriptblock]$OnPermissionDetected,
        [int]$CheckInterval = 100
    )
    
    if (-not $script:PermissionConfig.Enabled) {
        Write-Warning "Permission handler is disabled"
        return
    }
    
    $monitorJob = Start-Job -ScriptBlock {
        param($CheckInterval, $Patterns)
        
        Add-Type @"
            using System;
            using System.Runtime.InteropServices;
            using System.Text;
            
            public class ConsoleMonitor {
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
                
                public static string GetLastLine() {
                    IntPtr handle = GetStdHandle(STD_OUTPUT_HANDLE);
                    CONSOLE_SCREEN_BUFFER_INFO info;
                    GetConsoleScreenBufferInfo(handle, out info);
                    
                    COORD coord = new COORD();
                    coord.X = 0;
                    coord.Y = (short)(info.dwCursorPosition.Y - 1);
                    
                    StringBuilder line = new StringBuilder(info.dwSize.X);
                    uint charsRead;
                    ReadConsoleOutputCharacter(handle, line, (uint)info.dwSize.X, coord, out charsRead);
                    return line.ToString().TrimEnd();
                }
            }
"@
        
        $lastLine = ""
        while ($true) {
            try {
                $currentLine = [ConsoleMonitor]::GetLastLine()
                if ($currentLine -ne $lastLine) {
                    $lastLine = $currentLine
                    
                    # Check if it matches any pattern
                    foreach ($pattern in $Patterns) {
                        if ($currentLine -match $pattern.Pattern) {
                            # Return the detected prompt
                            @{
                                Detected = $true
                                Text = $currentLine
                                Pattern = $pattern.Pattern
                                Type = $pattern.Type
                                Timestamp = Get-Date
                            }
                            break
                        }
                    }
                }
            } catch {
                # Continue on error
            }
            
            Start-Sleep -Milliseconds $CheckInterval
        }
    } -ArgumentList $CheckInterval, $script:PermissionPatterns
    
    return $monitorJob
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Initialize-PermissionHandler',
    'Test-ClaudePermissionPrompt',
    'Get-PermissionDecision',
    'Submit-PermissionResponse',
    'Write-PermissionLog',
    'Get-PermissionStatistics',
    'Add-PermissionRule',
    'Start-PermissionMonitor'
)