# Fix-ClaudeWindowSubmission.ps1
# Fixes the submission mechanism to work with the current active window
# Date: 2025-08-26

Write-Host "Fixing Claude window submission mechanism..." -ForegroundColor Cyan

# Fix 1: Update the Submit-ToClaudeViaTypeKeys function to target the current active window
$submissionModulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-CLISubmission.psm1"

if (Test-Path $submissionModulePath) {
    Write-Host "  Updating CLISubmission module to use current active window..." -ForegroundColor Yellow
    
    $content = Get-Content $submissionModulePath -Raw
    
    # Check if the function already exists and update it
    if ($content -match 'function Submit-ToClaudeViaTypeKeys') {
        Write-Host "  Found Submit-ToClaudeViaTypeKeys function, updating window detection..." -ForegroundColor Gray
        
        # Create improved version that targets current active window
        $improvedFunction = @'

# Updated Submit-ToClaudeViaTypeKeys function
function Submit-ToClaudeViaTypeKeys {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PromptText,
        [int]$DelayMs = 100,
        [switch]$ForceActiveWindow
    )
    
    Write-Host "[Submit] Preparing to submit prompt to Claude..." -ForegroundColor Cyan
    Write-Host "[Submit] Prompt length: $($PromptText.Length) characters" -ForegroundColor Gray
    
    Add-Type @"
        using System;
        using System.Runtime.InteropServices;
        using System.Windows.Forms;
        
        public class Win32Window {
            [DllImport("user32.dll")]
            public static extern IntPtr GetForegroundWindow();
            
            [DllImport("user32.dll")]
            public static extern bool SetForegroundWindow(IntPtr hWnd);
            
            [DllImport("user32.dll")]
            public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
            
            [DllImport("user32.dll", CharSet = CharSet.Auto)]
            public static extern IntPtr SendMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
            
            [DllImport("user32.dll")]
            public static extern bool PostMessage(IntPtr hWnd, uint Msg, IntPtr wParam, IntPtr lParam);
        }
"@ -ErrorAction SilentlyContinue

    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    
    try {
        # Get the current active window
        $activeWindow = [Win32Window]::GetForegroundWindow()
        Write-Host "[Submit] Current active window handle: $activeWindow" -ForegroundColor Gray
        
        # Clear any existing clipboard content
        [System.Windows.Forms.Clipboard]::Clear()
        
        # Set clipboard with our prompt text
        [System.Windows.Forms.Clipboard]::SetText($PromptText)
        Write-Host "[Submit] Text copied to clipboard" -ForegroundColor Gray
        
        # Small delay to ensure window is ready
        Start-Sleep -Milliseconds 100
        
        # Make sure the window is active
        [Win32Window]::SetForegroundWindow($activeWindow) | Out-Null
        [Win32Window]::ShowWindow($activeWindow, 9) | Out-Null # SW_RESTORE
        Start-Sleep -Milliseconds 100
        
        Write-Host "[Submit] Pasting text into active window..." -ForegroundColor Yellow
        
        # Send Ctrl+V to paste
        [System.Windows.Forms.SendKeys]::SendWait("^v")
        Start-Sleep -Milliseconds 500
        
        Write-Host "[Submit] Text pasted, sending Enter..." -ForegroundColor Yellow
        
        # Send Enter to submit
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        
        Write-Host "[Submit] Submission completed successfully!" -ForegroundColor Green
        
        return @{
            Success = $true
            WindowHandle = $activeWindow
            Message = "Text submitted to active window"
            Timestamp = Get-Date
        }
        
    } catch {
        Write-Host "[Submit] ERROR: Failed to submit - $_" -ForegroundColor Red
        return @{
            Success = $false
            Error = $_.Exception.Message
            Timestamp = Get-Date
        }
    }
}

Export-ModuleMember -Function Submit-ToClaudeViaTypeKeys
'@
        
        # Replace or append the function
        if ($content -match 'function Submit-ToClaudeViaTypeKeys[\s\S]*?(?=function|\z)') {
            Write-Host "  Replacing existing function..." -ForegroundColor Gray
            $content = $content -replace 'function Submit-ToClaudeViaTypeKeys[\s\S]*?(?=function|\z)', $improvedFunction
        } else {
            Write-Host "  Appending new function..." -ForegroundColor Gray
            $content += "`n`n$improvedFunction"
        }
        
        # Save the updated module
        $content | Out-File $submissionModulePath -Encoding UTF8
        Write-Host "  CLISubmission module updated successfully" -ForegroundColor Green
        
    } else {
        Write-Host "  Adding Submit-ToClaudeViaTypeKeys function..." -ForegroundColor Gray
        Add-Content -Path $submissionModulePath -Value $improvedFunction
        Write-Host "  Function added successfully" -ForegroundColor Green
    }
    
} else {
    Write-Host "  WARNING: CLISubmission module not found at $submissionModulePath" -ForegroundColor Yellow
    Write-Host "  Creating new module..." -ForegroundColor Yellow
    
    # Create the module with the submission function
    $moduleContent = @'
# Unity-Claude-CLISubmission.psm1
# Module for submitting prompts to Claude via keyboard simulation
# Date: 2025-08-26

function Submit-ToClaudeViaTypeKeys {
    param(
        [Parameter(Mandatory=$true)]
        [string]$PromptText,
        [int]$DelayMs = 100,
        [switch]$ForceActiveWindow
    )
    
    Write-Host "[Submit] Preparing to submit prompt to Claude..." -ForegroundColor Cyan
    Write-Host "[Submit] Prompt length: $($PromptText.Length) characters" -ForegroundColor Gray
    
    Add-Type @"
        using System;
        using System.Runtime.InteropServices;
        using System.Windows.Forms;
        
        public class Win32Window {
            [DllImport("user32.dll")]
            public static extern IntPtr GetForegroundWindow();
            
            [DllImport("user32.dll")]
            public static extern bool SetForegroundWindow(IntPtr hWnd);
            
            [DllImport("user32.dll")]
            public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
        }
"@ -ErrorAction SilentlyContinue

    Add-Type -AssemblyName System.Windows.Forms -ErrorAction SilentlyContinue
    
    try {
        # Get the current active window
        $activeWindow = [Win32Window]::GetForegroundWindow()
        Write-Host "[Submit] Current active window handle: $activeWindow" -ForegroundColor Gray
        
        # Clear any existing clipboard content
        [System.Windows.Forms.Clipboard]::Clear()
        
        # Set clipboard with our prompt text
        [System.Windows.Forms.Clipboard]::SetText($PromptText)
        Write-Host "[Submit] Text copied to clipboard" -ForegroundColor Gray
        
        # Small delay to ensure window is ready
        Start-Sleep -Milliseconds 100
        
        # Make sure the window is active
        [Win32Window]::SetForegroundWindow($activeWindow) | Out-Null
        [Win32Window]::ShowWindow($activeWindow, 9) | Out-Null # SW_RESTORE
        Start-Sleep -Milliseconds 100
        
        Write-Host "[Submit] Pasting text into active window..." -ForegroundColor Yellow
        
        # Send Ctrl+V to paste
        [System.Windows.Forms.SendKeys]::SendWait("^v")
        Start-Sleep -Milliseconds 500
        
        Write-Host "[Submit] Text pasted, sending Enter..." -ForegroundColor Yellow
        
        # Send Enter to submit
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
        
        Write-Host "[Submit] Submission completed successfully!" -ForegroundColor Green
        
        return @{
            Success = $true
            WindowHandle = $activeWindow
            Message = "Text submitted to active window"
            Timestamp = Get-Date
        }
        
    } catch {
        Write-Host "[Submit] ERROR: Failed to submit - $_" -ForegroundColor Red
        return @{
            Success = $false
            Error = $_.Exception.Message
            Timestamp = Get-Date
        }
    }
}

Export-ModuleMember -Function Submit-ToClaudeViaTypeKeys
'@
    
    $moduleContent | Out-File $submissionModulePath -Encoding UTF8
    Write-Host "  New CLISubmission module created" -ForegroundColor Green
}

Write-Host ""
Write-Host "Fix applied successfully!" -ForegroundColor Green
Write-Host "The submission mechanism will now:" -ForegroundColor Cyan
Write-Host "  1. Target the currently active window (where you're typing)" -ForegroundColor White
Write-Host "  2. Use clipboard paste for reliable text insertion" -ForegroundColor White
Write-Host "  3. Automatically submit with Enter key" -ForegroundColor White
Write-Host ""
Write-Host "Testing the fix..." -ForegroundColor Yellow