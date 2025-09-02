# ClaudeWindowMonitor.psm1
# Monitors the Claude Code CLI window for permission prompts and responds automatically

Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    using System.Text;
    
    public class WindowHelper {
        [DllImport("user32.dll")]
        public static extern IntPtr GetForegroundWindow();
        
        [DllImport("user32.dll")]
        public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
        
        [DllImport("user32.dll")]
        public static extern bool SetForegroundWindow(IntPtr hWnd);
        
        [DllImport("user32.dll")]
        public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);
        
        [DllImport("user32.dll")]
        public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
    }
"@ -ErrorAction SilentlyContinue

function Start-ClaudeWindowMonitoring {
    [CmdletBinding()]
    param(
        [int]$CheckInterval = 500,  # milliseconds
        [switch]$AutoApprove
    )
    
    Write-Host "[MONITOR] Starting Claude window monitoring..." -ForegroundColor Cyan
    Write-Host "[MONITOR] Check interval: ${CheckInterval}ms" -ForegroundColor Gray
    
    # Patterns to detect permission prompts
    $permissionPatterns = @(
        'Allow .* to .*\? \(y/n\)',
        'Do you want to .*\? \[y/n\]',
        'Execute .*\? \(y/n\)',
        'Permission required',
        'Approve .*\? \(y/n\)',
        'Continue\? \(y/n\)'
    )
    
    # Safe operations that should be auto-approved
    $safePatterns = @(
        'git status',
        'git diff',
        'Get-ChildItem',
        'Get-Location',
        'pwd',
        'ls',
        'dir',
        'Read file',
        'list files'
    )
    
    $lastPromptTime = Get-Date
    $promptCooldown = 2  # seconds between detecting same prompt
    
    while ($true) {
        try {
            # Find PowerShell windows that might be Claude
            $pwshWindows = Get-Process | Where-Object { 
                $_.ProcessName -eq "pwsh" -and 
                $_.MainWindowTitle -ne "" -and
                ($_.MainWindowTitle -like "*Claude*" -or 
                 $_.MainWindowTitle -eq "Windows PowerShell" -or
                 $_.MainWindowTitle -eq "Administrator: Windows PowerShell")
            }
            
            foreach ($window in $pwshWindows) {
                # Get the window title
                $title = $window.MainWindowTitle
                
                # Check if this is the Claude CLI window
                # The actual Claude window might just be "Windows PowerShell" or "Administrator: Windows PowerShell"
                # We need to check the console buffer content
                
                # Alternative approach: Check if there's a pending input
                $handle = $window.MainWindowHandle
                
                if ($handle -ne 0) {
                    # Try to detect if there's a permission prompt waiting
                    # This is tricky because we can't easily read console buffer from another process
                    # But we can detect if the window is waiting for input
                    
                    $currentTime = Get-Date
                    $timeSinceLastPrompt = ($currentTime - $lastPromptTime).TotalSeconds
                    
                    if ($timeSinceLastPrompt -gt $promptCooldown) {
                        # Check if the window is active (user might be looking at a prompt)
                        $foregroundWindow = [WindowHelper]::GetForegroundWindow()
                        
                        if ($foregroundWindow -eq $handle) {
                            Write-Host "[MONITOR] Claude window is active - checking for prompts..." -ForegroundColor Yellow
                            
                            # Send a test keystroke to see if there's an active prompt
                            # This is a heuristic approach
                            if ($AutoApprove) {
                                Write-Host "[MONITOR] Auto-approving potential permission prompt" -ForegroundColor Green
                                
                                # Activate the window
                                [WindowHelper]::SetForegroundWindow($handle)
                                Start-Sleep -Milliseconds 100
                                
                                # Send approval
                                Add-Type -AssemblyName System.Windows.Forms
                                [System.Windows.Forms.SendKeys]::SendWait("y")
                                Start-Sleep -Milliseconds 50
                                [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
                                
                                Write-Host "[MONITOR] Sent 'y' + Enter to active window" -ForegroundColor Green
                                $lastPromptTime = Get-Date
                            }
                        }
                    }
                }
            }
        }
        catch {
            Write-Warning "[MONITOR] Error in monitoring loop: $_"
        }
        
        Start-Sleep -Milliseconds $CheckInterval
    }
}

function Start-ClaudeOutputCapture {
    [CmdletBinding()]
    param(
        [string]$ProcessName = "pwsh"
    )
    
    Write-Host "[CAPTURE] Attempting to capture Claude CLI output..." -ForegroundColor Cyan
    
    # This is a more advanced approach using UI Automation
    try {
        Add-Type -AssemblyName UIAutomationClient
        Add-Type -AssemblyName UIAutomationTypes
        
        $automation = [System.Windows.Automation.AutomationElement]::RootElement
        $condition = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, "Windows PowerShell")
        $pwshWindow = $automation.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $condition)
        
        if ($pwshWindow) {
            Write-Host "[CAPTURE] Found PowerShell window via UI Automation" -ForegroundColor Green
            
            # Try to get text from the window
            $textPattern = $pwshWindow.GetCurrentPattern([System.Windows.Automation.TextPattern]::Pattern)
            if ($textPattern) {
                $text = $textPattern.DocumentRange.GetText(-1)
                
                # Check for permission prompts in the text
                if ($text -match "Allow .* to .*\? \(y/n\)" -or 
                    $text -match "Do you want to .*\? \[y/n\]" -or
                    $text -match "Continue\? \(y/n\)") {
                    
                    Write-Host "[CAPTURE] ✅ Found permission prompt!" -ForegroundColor Green
                    Write-Host "[CAPTURE] Prompt: $($Matches[0])" -ForegroundColor Yellow
                    return $true
                }
            }
        }
    }
    catch {
        Write-Warning "[CAPTURE] UI Automation not available: $_"
    }
    
    return $false
}

function Send-ApprovalToActiveWindow {
    [CmdletBinding()]
    param(
        [string]$Response = "y",
        [switch]$Force
    )
    
    try {
        Add-Type -AssemblyName System.Windows.Forms
        
        # Small delay to ensure window is ready
        Start-Sleep -Milliseconds 200
        
        # Send the response
        [System.Windows.Forms.SendKeys]::SendWait($Response)
        Write-Host "[APPROVAL] Sent '$Response'" -ForegroundColor Green
        
        # Send Enter
        Start-Sleep -Milliseconds 100
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        Write-Host "[APPROVAL] Sent Enter key" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Error "[APPROVAL] Failed to send keys: $_"
        return $false
    }
}

# More reliable approach: Monitor clipboard for permission prompts
function Start-ClipboardMonitoring {
    [CmdletBinding()]
    param(
        [int]$CheckInterval = 500
    )
    
    Write-Host "[CLIPBOARD] Starting clipboard monitoring for permission prompts..." -ForegroundColor Cyan
    
    $lastClipboard = ""
    
    while ($true) {
        try {
            $currentClipboard = Get-Clipboard -Format Text -ErrorAction SilentlyContinue
            
            if ($currentClipboard -and $currentClipboard -ne $lastClipboard) {
                # Check if clipboard contains a permission prompt
                if ($currentClipboard -match "Allow .* to .*\? \(y/n\)" -or
                    $currentClipboard -match "Do you want to .*\? \[y/n\]") {
                    
                    Write-Host "[CLIPBOARD] Detected permission prompt in clipboard!" -ForegroundColor Green
                    Write-Host "[CLIPBOARD] $currentClipboard" -ForegroundColor Yellow
                    
                    # Auto-approve if it's a safe operation
                    if ($currentClipboard -match "git status" -or 
                        $currentClipboard -match "Get-ChildItem" -or
                        $currentClipboard -match "pwd") {
                        
                        Write-Host "[CLIPBOARD] Safe operation detected - auto-approving" -ForegroundColor Green
                        Send-ApprovalToActiveWindow -Response "y"
                    }
                    
                    $lastClipboard = $currentClipboard
                }
            }
        }
        catch {
            # Ignore clipboard errors
        }
        
        Start-Sleep -Milliseconds $CheckInterval
    }
}

Export-ModuleMember -Function @(
    'Start-ClaudeWindowMonitoring',
    'Start-ClaudeOutputCapture', 
    'Send-ApprovalToActiveWindow',
    'Start-ClipboardMonitoring'
)