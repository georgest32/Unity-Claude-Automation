# PermissionApprovalHandler.psm1
# Handles actual approval of permissions in Claude Code CLI window

function Send-ClaudeApproval {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Response,  # "y" or "n"
        
        [Parameter()]
        [string]$Reason = "Auto-approved by orchestrator"
    )
    
    try {
        # Method 1: Try to find and activate Claude window
        $claudeWindow = Get-Process | Where-Object { 
            $_.MainWindowTitle -like "*Claude*" -or 
            $_.ProcessName -like "*claude*" -or
            $_.MainWindowTitle -like "*pwsh*Claude*"
        } | Select-Object -First 1
        
        if ($claudeWindow -and $claudeWindow.MainWindowHandle -ne 0) {
            Write-Host "[APPROVAL] Found Claude window: $($claudeWindow.MainWindowTitle)" -ForegroundColor Cyan
            
            # Use Windows Forms to send keystrokes
            Add-Type -AssemblyName System.Windows.Forms
            Add-Type @"
                using System;
                using System.Runtime.InteropServices;
                public class Win32 {
                    [DllImport("user32.dll")]
                    public static extern bool SetForegroundWindow(IntPtr hWnd);
                    [DllImport("user32.dll")]
                    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);
                }
"@ -ErrorAction SilentlyContinue
            
            # Activate the Claude window
            [Win32]::ShowWindow($claudeWindow.MainWindowHandle, 9) # SW_RESTORE
            [Win32]::SetForegroundWindow($claudeWindow.MainWindowHandle)
            Start-Sleep -Milliseconds 200
            
            # Send the response
            [System.Windows.Forms.SendKeys]::SendWait($Response)
            Start-Sleep -Milliseconds 100
            [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
            
            Write-Host "[APPROVAL] ✅ Sent '$Response' response to Claude" -ForegroundColor Green
            Write-Host "[APPROVAL] Reason: $Reason" -ForegroundColor Gray
            
            return @{
                Success = $true
                Method = "DirectKeystroke"
                Response = $Response
                Timestamp = Get-Date
            }
        }
        
        # Method 2: Write approval file for Claude to detect
        Write-Host "[APPROVAL] Claude window not found, using file-based approval" -ForegroundColor Yellow
        
        $approvalFile = Join-Path ".\ClaudeResponses\Autonomous" "approval_response_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
        $Response | Out-File $approvalFile -Force
        
        Write-Host "[APPROVAL] Created approval file: $approvalFile" -ForegroundColor Yellow
        
        return @{
            Success = $true
            Method = "FileBasedApproval"
            Response = $Response
            ApprovalFile = $approvalFile
            Timestamp = Get-Date
        }
        
    } catch {
        Write-Error "[APPROVAL] Failed to send approval: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
            Timestamp = Get-Date
        }
    }
}

function Test-ClaudeWindowAvailable {
    [CmdletBinding()]
    param()
    
    $claudeProcesses = @(
        Get-Process -ErrorAction SilentlyContinue | Where-Object { 
            $_.MainWindowTitle -like "*Claude*" -or 
            $_.ProcessName -like "*claude*" -or
            $_.MainWindowTitle -like "*pwsh*Claude*" -or
            $_.MainWindowTitle -eq "Administrator: Windows PowerShell"
        }
    )
    
    if ($claudeProcesses.Count -gt 0) {
        Write-Host "[WINDOW] Found $($claudeProcesses.Count) potential Claude window(s):" -ForegroundColor Cyan
        $claudeProcesses | ForEach-Object {
            Write-Host "  - $($_.ProcessName): $($_.MainWindowTitle)" -ForegroundColor Gray
        }
        return $true
    }
    
    return $false
}

function Approve-ClaudePermission {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$PermissionRequest,
        
        [Parameter()]
        [bool]$AutoApprove = $false,
        
        [Parameter()]
        [string]$ApprovalReason = ""
    )
    
    try {
        Write-Host "`n[APPROVAL HANDLER] Processing permission request" -ForegroundColor Magenta
        
        # Determine approval
        $shouldApprove = $false
        $response = "n"  # Default to deny
        
        if ($AutoApprove) {
            $shouldApprove = $true
            $response = "y"
            Write-Host "[APPROVAL] Auto-approving: $ApprovalReason" -ForegroundColor Green
        } else {
            # Check for safe operations
            $safeCommands = @('git status', 'git diff', 'ls', 'pwd', 'dir', 'Get-ChildItem', 'Get-Location')
            
            foreach ($cmd in $safeCommands) {
                if ($PermissionRequest.Command -like "*$cmd*") {
                    $shouldApprove = $true
                    $response = "y"
                    $ApprovalReason = "Safe command detected: $cmd"
                    Write-Host "[APPROVAL] Auto-approving safe command: $cmd" -ForegroundColor Green
                    break
                }
            }
            
            if (-not $shouldApprove) {
                Write-Host "[APPROVAL] ⚠️ Manual approval required - unsafe operation" -ForegroundColor Yellow
                Write-Host "[APPROVAL] Command: $($PermissionRequest.Command)" -ForegroundColor White
                
                # For now, deny unsafe operations automatically
                $response = "n"
                $ApprovalReason = "Unsafe operation - auto-denied for safety"
            }
        }
        
        # Send the approval
        $result = Send-ClaudeApproval -Response $response -Reason $ApprovalReason
        
        # Log the decision
        $logEntry = @{
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            RequestId = $PermissionRequest.RequestId
            Tool = $PermissionRequest.Tool
            Command = $PermissionRequest.Command
            Decision = if ($response -eq "y") { "APPROVED" } else { "DENIED" }
            Reason = $ApprovalReason
            Method = $result.Method
        }
        
        $logFile = Join-Path ".\AutomationLogs" "permission_decisions_$(Get-Date -Format 'yyyyMMdd').log"
        $logEntry | ConvertTo-Json -Compress | Add-Content $logFile
        
        return $result
        
    } catch {
        Write-Error "[APPROVAL] Error processing approval: $_"
        return @{
            Success = $false
            Error = $_.Exception.Message
        }
    }
}

# Export functions
Export-ModuleMember -Function @(
    'Send-ClaudeApproval',
    'Test-ClaudeWindowAvailable',
    'Approve-ClaudePermission'
)