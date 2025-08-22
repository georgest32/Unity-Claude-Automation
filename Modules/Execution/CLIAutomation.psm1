# CLIAutomation.psm1
# Day 13: CLI Input Automation Module
# Provides SendKeys and file-based input automation for Claude Code CLI
# Date: 2025-08-18

#region Module Configuration

# Import required assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

# Import User32.dll for window management
Add-Type @'
    using System;
    using System.Runtime.InteropServices;
    using System.Text;
    
    public class Win32 {
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        
        [DllImport("user32.dll")]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        
        [DllImport("user32.dll", SetLastError = true)]
        public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint lpdwProcessId);
        
        [DllImport("user32.dll")]
        public static extern bool AttachThreadInput(uint idAttach, uint idAttachTo, bool fAttach);
        
        [DllImport("user32.dll", CharSet = CharSet.Auto)]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
        
        [DllImport("user32.dll")]
        public static extern bool IsWindowVisible(IntPtr hWnd);
        
        public const int SW_RESTORE = 9;
        public const int SW_SHOW = 5;
        public const int SW_MAXIMIZE = 3;
    }
'@ -ErrorAction SilentlyContinue

#endregion

#region Configuration Variables

$script:ModuleName = "CLIAutomation"
$script:LogFile = Join-Path $PSScriptRoot "..\..\unity_claude_automation.log"
$script:ClaudeMessageFile = Join-Path $PSScriptRoot "..\..\claude_code_message.txt"
$script:ClaudeResponseDir = Join-Path $PSScriptRoot "..\..\claude_responses"
$script:InputQueueFile = Join-Path $PSScriptRoot "..\..\input_queue.json"
$script:DefaultTimeout = 30
$script:FocusRetryCount = 3
$script:SendKeysDelay = 100  # milliseconds

#endregion

#region Helper Functions

function Write-CLILog {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [CLIAutomation] $Message"
    
    # Thread-safe logging
    $mutex = New-Object System.Threading.Mutex($false, "Unity_Claude_Log_Mutex")
    try {
        $mutex.WaitOne() | Out-Null
        Add-Content -Path $script:LogFile -Value $logEntry -ErrorAction SilentlyContinue
    }
    finally {
        $mutex.ReleaseMutex()
    }
    
    # Also output to console for debugging
    Write-Host $logEntry -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "WARN") { "Yellow" } else { "Gray" })
}

function Test-ProcessExists {
    param(
        [string]$ProcessName
    )
    
    try {
        $process = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
        return $null -ne $process
    }
    catch {
        return $false
    }
}

function Get-ClaudeWindow {
    <#
    .SYNOPSIS
    Finds the Claude Code CLI window handle
    #>
    
    Write-CLILog "Searching for Claude Code CLI window"
    
    # Try Claude-specific process first
    $claudeProcesses = Get-Process -Name "claude" -ErrorAction SilentlyContinue
    
    foreach ($proc in $claudeProcesses) {
        if ($proc.MainWindowHandle -ne 0) {
            $windowTitle = New-Object System.Text.StringBuilder 256
            [Win32]::GetWindowText($proc.MainWindowHandle, $windowTitle, 256) | Out-Null
            $title = $windowTitle.ToString()
            
            Write-CLILog "Found Claude process window: $title (PID: $($proc.Id))"
            return $proc.MainWindowHandle
        }
    }
    
    # Try other terminal processes but be more selective
    $terminalProcessNames = @("WindowsTerminal", "cmd", "conhost")
    
    foreach ($name in $terminalProcessNames) {
        $processes = Get-Process -Name $name -ErrorAction SilentlyContinue
        
        foreach ($proc in $processes) {
            if ($proc.MainWindowHandle -ne 0) {
                $windowTitle = New-Object System.Text.StringBuilder 256
                [Win32]::GetWindowText($proc.MainWindowHandle, $windowTitle, 256) | Out-Null
                $title = $windowTitle.ToString()
                
                # Only accept windows that explicitly mention Claude
                if ($title -match "claude|Claude") {
                    Write-CLILog "Found Claude window in terminal: $title (PID: $($proc.Id))"
                    return $proc.MainWindowHandle
                }
            }
        }
    }
    
    Write-CLILog "Claude window not found" -Level "WARN"
    return $null
}

#endregion

#region SendKeys Implementation

function Set-WindowFocus {
    <#
    .SYNOPSIS
    Reliably sets focus to a window using multiple techniques
    #>
    param(
        [IntPtr]$WindowHandle,
        [int]$RetryCount = 3
    )
    
    if ($WindowHandle -eq [IntPtr]::Zero) {
        Write-CLILog "Invalid window handle" -Level "ERROR"
        return $false
    }
    
    $success = $false
    $attempt = 0
    
    while (-not $success -and $attempt -lt $RetryCount) {
        $attempt++
        Write-CLILog "Attempting to set window focus (attempt $attempt/$RetryCount)"
        
        try {
            # Get current foreground window
            $currentWindow = [Win32]::GetForegroundWindow()
            
            if ($currentWindow -eq $WindowHandle) {
                Write-CLILog "Window already has focus"
                return $true
            }
            
            # Method 1: Direct SetForegroundWindow
            $result = [Win32]::SetForegroundWindow($WindowHandle)
            Start-Sleep -Milliseconds 100
            
            if (-not $result) {
                # Method 2: ShowWindow then SetForegroundWindow
                [Win32]::ShowWindow($WindowHandle, [Win32]::SW_RESTORE) | Out-Null
                Start-Sleep -Milliseconds 100
                [Win32]::SetForegroundWindow($WindowHandle) | Out-Null
                Start-Sleep -Milliseconds 100
            }
            
            # Method 3: AttachThreadInput if still not focused
            $newForeground = [Win32]::GetForegroundWindow()
            if ($newForeground -ne $WindowHandle) {
                $currentThreadId = [System.Diagnostics.Process]::GetCurrentProcess().Threads[0].Id
                $targetProcessId = 0
                [Win32]::GetWindowThreadProcessId($WindowHandle, [ref]$targetProcessId) | Out-Null
                $targetProcess = Get-Process -Id $targetProcessId -ErrorAction SilentlyContinue
                
                if ($targetProcess) {
                    $targetThreadId = $targetProcess.Threads[0].Id
                    [Win32]::AttachThreadInput($currentThreadId, $targetThreadId, $true) | Out-Null
                    [Win32]::SetForegroundWindow($WindowHandle) | Out-Null
                    [Win32]::AttachThreadInput($currentThreadId, $targetThreadId, $false) | Out-Null
                }
            }
            
            # Verify focus was set
            Start-Sleep -Milliseconds 200
            $finalForeground = [Win32]::GetForegroundWindow()
            $success = ($finalForeground -eq $WindowHandle)
            
            if ($success) {
                Write-CLILog "Successfully set window focus"
            }
            else {
                Write-CLILog "Failed to set window focus (attempt $attempt)" -Level "WARN"
                Start-Sleep -Milliseconds 500
            }
        }
        catch {
            Write-CLILog "Error setting window focus: $_" -Level "ERROR"
            Start-Sleep -Milliseconds 500
        }
    }
    
    return $success
}

function Send-KeysToWindow {
    <#
    .SYNOPSIS
    Sends keystrokes to the focused window using SendKeys
    #>
    param(
        [string]$Text,
        [int]$DelayMs = 100
    )
    
    try {
        Write-CLILog "Sending keys: $(if ($Text.Length -gt 50) { $Text.Substring(0, 50) + '...' } else { $Text })"
        
        # Add delay before sending keys
        Start-Sleep -Milliseconds $DelayMs
        
        # Use SendWait for synchronous sending
        [System.Windows.Forms.SendKeys]::SendWait($Text)
        
        # Add delay after sending keys
        Start-Sleep -Milliseconds $DelayMs
        
        Write-CLILog "Keys sent successfully"
        return $true
    }
    catch {
        Write-CLILog "Error sending keys: $_" -Level "ERROR"
        return $false
    }
}

function Submit-ClaudeCLIInput {
    <#
    .SYNOPSIS
    Submits input to Claude Code CLI using SendKeys automation
    #>
    param(
        [string]$Prompt,
        [switch]$PressEnter = $true,
        [int]$TimeoutSeconds = 30
    )
    
    Write-CLILog "Starting SendKeys CLI input submission"
    
    # Find Claude window
    $claudeWindow = Get-ClaudeWindow
    if (-not $claudeWindow) {
        Write-CLILog "Claude window not found. Is Claude Code CLI running?" -Level "ERROR"
        return @{
            Success = $false
            Error = "Claude window not found"
        }
    }
    
    # Set focus to Claude window
    $focusSet = Set-WindowFocus -WindowHandle $claudeWindow -RetryCount $script:FocusRetryCount
    if (-not $focusSet) {
        Write-CLILog "Failed to set focus to Claude window" -Level "ERROR"
        return @{
            Success = $false
            Error = "Failed to set window focus"
        }
    }
    
    # Prepare the text (escape special characters for SendKeys)
    $escapedPrompt = $Prompt -replace '([+^%~(){}])', '{$1}'
    
    # Send the prompt
    $sent = Send-KeysToWindow -Text $escapedPrompt -DelayMs $script:SendKeysDelay
    
    if ($sent -and $PressEnter) {
        # Send Enter key
        Start-Sleep -Milliseconds 200
        Send-KeysToWindow -Text "{ENTER}" -DelayMs 50
        Write-CLILog "Prompt submitted with Enter key"
    }
    
    return @{
        Success = $sent
        Method = "SendKeys"
        Timestamp = Get-Date
    }
}

#endregion

#region File-Based Input Implementation

function Write-ClaudeMessageFile {
    <#
    .SYNOPSIS
    Writes a prompt to the Claude message file for file-based input
    #>
    param(
        [string]$Prompt,
        [string]$FilePath = $script:ClaudeMessageFile
    )
    
    try {
        Write-CLILog "Writing prompt to message file: $FilePath"
        
        # Create directory if it doesn't exist
        $dir = Split-Path -Parent $FilePath
        if ($dir -and -not (Test-Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force | Out-Null
        }
        
        # Write prompt to file
        Set-Content -Path $FilePath -Value $Prompt -Encoding UTF8 -Force
        
        Write-CLILog "Message file written successfully"
        return $true
    }
    catch {
        Write-CLILog "Error writing message file: $_" -Level "ERROR"
        return $false
    }
}

function Submit-ClaudeFileInput {
    <#
    .SYNOPSIS
    Submits input to Claude Code CLI using file-based messaging
    #>
    param(
        [string]$Prompt,
        [string]$ResponseDirectory = $script:ClaudeResponseDir,
        [int]$TimeoutSeconds = 30
    )
    
    Write-CLILog "Starting file-based CLI input submission"
    
    # Ensure response directory exists
    if (-not (Test-Path $ResponseDirectory)) {
        New-Item -ItemType Directory -Path $ResponseDirectory -Force | Out-Null
    }
    
    # Generate unique response file name
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $responseFile = Join-Path $ResponseDirectory "response_$timestamp.json"
    
    # Write prompt to message file
    $written = Write-ClaudeMessageFile -Prompt $Prompt
    if (-not $written) {
        return @{
            Success = $false
            Error = "Failed to write message file"
        }
    }
    
    # Execute Claude CLI with file input and output redirection
    try {
        Write-CLILog "Executing Claude CLI with file input"
        
        $claudeArgs = @(
            "-p", "`"$Prompt`"",
            "--output-format", "json"
        )
        
        $processInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processInfo.FileName = "claude"
        $processInfo.Arguments = $claudeArgs -join " "
        $processInfo.RedirectStandardOutput = $true
        $processInfo.RedirectStandardError = $true
        $processInfo.UseShellExecute = $false
        $processInfo.CreateNoWindow = $true
        
        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processInfo
        
        Write-CLILog "Starting Claude process with arguments: $($processInfo.Arguments)"
        $process.Start() | Out-Null
        
        # Wait for process with timeout
        $completed = $process.WaitForExit($TimeoutSeconds * 1000)
        
        if ($completed) {
            $output = $process.StandardOutput.ReadToEnd()
            $error = $process.StandardError.ReadToEnd()
            
            if ($process.ExitCode -eq 0) {
                # Save output to response file
                Set-Content -Path $responseFile -Value $output -Encoding UTF8
                Write-CLILog "Claude response saved to: $responseFile"
                
                return @{
                    Success = $true
                    Method = "FileInput"
                    ResponseFile = $responseFile
                    Timestamp = Get-Date
                }
            }
            else {
                Write-CLILog "Claude CLI returned error: $error" -Level "ERROR"
                return @{
                    Success = $false
                    Error = "Claude CLI error: $error"
                }
            }
        }
        else {
            Write-CLILog "Claude CLI process timed out" -Level "ERROR"
            $process.Kill()
            return @{
                Success = $false
                Error = "Process timed out after $TimeoutSeconds seconds"
            }
        }
    }
    catch {
        Write-CLILog "Error executing Claude CLI: $_" -Level "ERROR"
        return @{
            Success = $false
            Error = "Execution error: $_"
        }
    }
}

#endregion

#region Input Queue Management

function Initialize-InputQueue {
    <#
    .SYNOPSIS
    Initializes the input queue for managing multiple prompts
    #>
    
    if (-not (Test-Path $script:InputQueueFile)) {
        $emptyQueue = @{
            Queue = @()
            Processing = $false
            LastProcessed = $null
        }
        $emptyQueue | ConvertTo-Json -Depth 10 | Set-Content -Path $script:InputQueueFile -Encoding UTF8
        Write-CLILog "Input queue initialized"
    }
}

function Add-InputToQueue {
    <#
    .SYNOPSIS
    Adds a prompt to the input queue
    #>
    param(
        [string]$Prompt,
        [string]$Type = "General",
        [int]$Priority = 5
    )
    
    Initialize-InputQueue
    
    try {
        $queue = Get-Content $script:InputQueueFile -Raw | ConvertFrom-Json
        
        $queueItem = @{
            Id = [Guid]::NewGuid().ToString()
            Prompt = $Prompt
            Type = $Type
            Priority = $Priority
            Added = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            Status = "Pending"
        }
        
        # Add to queue (higher priority first)
        # Cast Queue to proper array to avoid PSObject array issues
        $queueArray = @($queue.Queue)
        $queueArray += $queueItem
        
        # Debug logging for queue sorting
        $beforePriorities = ($queueArray | ForEach-Object { $_.Priority }) -join ', '
        Write-CLILog "Before sorting: $beforePriorities"
        
        # Fix for PowerShell 5.1 string vs numeric sorting issue
        # Cast Priority to int for proper numeric sorting
        $queue.Queue = $queueArray | Sort-Object -Property { [int]$_.Priority } -Descending
        
        $afterPriorities = ($queue.Queue | ForEach-Object { $_.Priority }) -join ', '
        Write-CLILog "After sorting: $afterPriorities"
        
        $queue | ConvertTo-Json -Depth 10 | Set-Content -Path $script:InputQueueFile -Encoding UTF8
        
        Write-CLILog "Added prompt to queue (Priority: $Priority, Type: $Type)"
        return $queueItem.Id
    }
    catch {
        Write-CLILog "Error adding to input queue: $_" -Level "ERROR"
        return $null
    }
}

function Process-InputQueue {
    <#
    .SYNOPSIS
    Processes the next item in the input queue
    #>
    param(
        [switch]$UseSendKeys,
        [switch]$UseFileInput
    )
    
    Initialize-InputQueue
    
    try {
        $queue = Get-Content $script:InputQueueFile -Raw | ConvertFrom-Json
        
        if ($queue.Processing) {
            Write-CLILog "Queue is already being processed" -Level "WARN"
            return $null
        }
        
        $pendingItems = $queue.Queue | Where-Object { $_.Status -eq "Pending" }
        if ($pendingItems.Count -eq 0) {
            Write-CLILog "No pending items in queue"
            return $null
        }
        
        # Get next item (already sorted by priority)
        $nextItem = $pendingItems[0]
        
        # Mark as processing
        $queue.Processing = $true
        $nextItem.Status = "Processing"
        $queue | ConvertTo-Json -Depth 10 | Set-Content -Path $script:InputQueueFile -Encoding UTF8
        
        Write-CLILog "Processing queue item: $($nextItem.Id) (Type: $($nextItem.Type))"
        
        # Submit the prompt
        $result = $null
        if ($UseSendKeys) {
            $result = Submit-ClaudeCLIInput -Prompt $nextItem.Prompt
        }
        elseif ($UseFileInput) {
            $result = Submit-ClaudeFileInput -Prompt $nextItem.Prompt
        }
        else {
            # Try file input first, fallback to SendKeys
            $result = Submit-ClaudeFileInput -Prompt $nextItem.Prompt
            if (-not $result.Success) {
                Write-CLILog "File input failed, trying SendKeys" -Level "WARN"
                $result = Submit-ClaudeCLIInput -Prompt $nextItem.Prompt
            }
        }
        
        # Update queue status
        $queue = Get-Content $script:InputQueueFile -Raw | ConvertFrom-Json
        $queueItem = $queue.Queue | Where-Object { $_.Id -eq $nextItem.Id }
        
        if ($result.Success) {
            $queueItem.Status = "Completed"
            # Use Add-Member to add new properties to PSObject from JSON
            $queueItem | Add-Member -MemberType NoteProperty -Name "Completed" -Value (Get-Date -Format "yyyy-MM-dd HH:mm:ss") -Force
            $queue.LastProcessed = $queueItem.Id
            Write-CLILog "Queue item processed successfully"
        }
        else {
            $queueItem.Status = "Failed"
            # Use Add-Member to add Error property to PSObject from JSON
            $queueItem | Add-Member -MemberType NoteProperty -Name "Error" -Value $result.Error -Force
            Write-CLILog "Queue item processing failed: $($result.Error)" -Level "ERROR"
        }
        
        $queue.Processing = $false
        $queue | ConvertTo-Json -Depth 10 | Set-Content -Path $script:InputQueueFile -Encoding UTF8
        
        return $result
    }
    catch {
        Write-CLILog "Error processing input queue: $_" -Level "ERROR"
        
        # Reset processing flag on error
        try {
            $queue = Get-Content $script:InputQueueFile -Raw | ConvertFrom-Json
            $queue.Processing = $false
            $queue | ConvertTo-Json -Depth 10 | Set-Content -Path $script:InputQueueFile -Encoding UTF8
        }
        catch {}
        
        return $null
    }
}

function Get-InputQueueStatus {
    <#
    .SYNOPSIS
    Gets the current status of the input queue
    #>
    
    Initialize-InputQueue
    
    try {
        $queue = Get-Content $script:InputQueueFile -Raw | ConvertFrom-Json
        
        $status = @{
            TotalItems = $queue.Queue.Count
            Pending = ($queue.Queue | Where-Object { $_.Status -eq "Pending" }).Count
            Processing = ($queue.Queue | Where-Object { $_.Status -eq "Processing" }).Count
            Completed = ($queue.Queue | Where-Object { $_.Status -eq "Completed" }).Count
            Failed = ($queue.Queue | Where-Object { $_.Status -eq "Failed" }).Count
            IsProcessing = $queue.Processing
            LastProcessed = $queue.LastProcessed
        }
        
        return $status
    }
    catch {
        Write-CLILog "Error getting queue status: $_" -Level "ERROR"
        return $null
    }
}

#endregion

#region Input Validation and Formatting

function Format-ClaudePrompt {
    <#
    .SYNOPSIS
    Formats a prompt for Claude consumption with proper escaping
    #>
    param(
        [string]$Prompt,
        [string]$Context = "",
        [int]$MaxLength = 8000
    )
    
    # Combine context and prompt if context provided
    if ($Context) {
        $fullPrompt = "$Context`n`n$Prompt"
    }
    else {
        $fullPrompt = $Prompt
    }
    
    # Truncate if too long
    if ($fullPrompt.Length -gt $MaxLength) {
        Write-CLILog "Truncating prompt from $($fullPrompt.Length) to $MaxLength characters" -Level "WARN"
        $fullPrompt = $fullPrompt.Substring(0, $MaxLength - 100) + "`n`n[Truncated for length]"
    }
    
    # Escape problematic characters for JSON
    $escaped = $fullPrompt -replace '\\', '\\\\' `
                          -replace '"', '\"' `
                          -replace "`r`n", '\n' `
                          -replace "`n", '\n' `
                          -replace "`t", '\t'
    
    return $escaped
}

function Test-InputDelivery {
    <#
    .SYNOPSIS
    Tests if input was successfully delivered to Claude
    #>
    param(
        [string]$ResponseFile,
        [int]$TimeoutSeconds = 10
    )
    
    if (-not $ResponseFile) {
        return $false
    }
    
    $startTime = Get-Date
    $timeout = New-TimeSpan -Seconds $TimeoutSeconds
    
    while ((Get-Date) - $startTime -lt $timeout) {
        if (Test-Path $ResponseFile) {
            $fileInfo = Get-Item $ResponseFile
            if ($fileInfo.Length -gt 0) {
                Write-CLILog "Response file detected: $ResponseFile"
                return $true
            }
        }
        Start-Sleep -Milliseconds 500
    }
    
    Write-CLILog "No response detected within timeout" -Level "WARN"
    return $false
}

#endregion

#region Fallback Mechanisms

function Submit-ClaudeInputWithFallback {
    <#
    .SYNOPSIS
    Submits input to Claude with automatic fallback mechanisms
    #>
    param(
        [string]$Prompt,
        [string[]]$Methods = @("FileInput", "SendKeys"),
        [int]$RetryCount = 2
    )
    
    Write-CLILog "Starting input submission with fallback (Methods: $($Methods -join ', '))"
    
    $formattedPrompt = Format-ClaudePrompt -Prompt $Prompt
    $attempt = 0
    $lastError = ""
    
    foreach ($method in $Methods) {
        for ($i = 0; $i -lt $RetryCount; $i++) {
            $attempt++
            Write-CLILog "Attempt ${attempt}: Using method '$method'"
            
            $result = $null
            switch ($method) {
                "FileInput" {
                    $result = Submit-ClaudeFileInput -Prompt $formattedPrompt
                }
                "SendKeys" {
                    $result = Submit-ClaudeCLIInput -Prompt $formattedPrompt
                }
                default {
                    Write-CLILog "Unknown method: $method" -Level "WARN"
                    continue
                }
            }
            
            if ($result -and $result.Success) {
                Write-CLILog "Input submitted successfully using $method"
                return $result
            }
            
            $lastError = if ($result) { $result.Error } else { "Unknown error" }
            Write-CLILog "Method '$method' failed: $lastError" -Level "WARN"
            
            if ($i -lt $RetryCount - 1) {
                Start-Sleep -Seconds 2
            }
        }
    }
    
    Write-CLILog "All methods failed after $attempt attempts" -Level "ERROR"
    return @{
        Success = $false
        Error = "All methods failed. Last error: $lastError"
        Attempts = $attempt
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    # SendKeys Functions
    'Submit-ClaudeCLIInput',
    'Get-ClaudeWindow',
    'Set-WindowFocus',
    'Send-KeysToWindow',
    
    # File-Based Functions
    'Submit-ClaudeFileInput',
    'Write-ClaudeMessageFile',
    
    # Queue Management
    'Add-InputToQueue',
    'Process-InputQueue',
    'Get-InputQueueStatus',
    
    # Utilities
    'Format-ClaudePrompt',
    'Test-InputDelivery',
    'Submit-ClaudeInputWithFallback'
)

Write-CLILog "CLIAutomation module loaded successfully"

#endregion
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUN7CcGqd2lcGAGPLFuCd8OVm0
# GdqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQURfiRF0K375fxMfMgyjPvbh82ekQwDQYJKoZIhvcNAQEBBQAEggEAQ6Rg
# aDNKKq6B7z4HYW33mqHno/RlT24nbaIprUIcf/W9wrrY393QxkGpeql4AZS+hrPn
# tiI0p5GMRfPg+UkWrxc5dfdDrLtdxfQdm6SWfD7geoUniMdzuwPYhCHoedljnxrF
# Bt1yHM6oFEXLNu2Ri53YP9rkd38uGH0KhZR0JFHe/UPtuhvNCV564MpvaqScebk0
# QThbrxry76sWLRejqIrbaOxwMQWskfrdWE9wTDpeaLgf3QFL2WaGqwmzoFy7Bo0m
# nS5dO/WHwiGNJOL2QkRBlYYUTDZyA48lEVY2jE0q4E2pw5azEEgC5/LYSgb8hvJJ
# fnKWfp5YDyqLRA3KqA==
# SIG # End signature block
