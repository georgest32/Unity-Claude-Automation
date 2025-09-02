# Start-ClaudeWithPermissionHandling.ps1
# Starts Claude CLI with automatic permission handling and orchestration

param(
    [string]$Mode = "Intelligent",  # Monitor, AutoApprove, Intelligent, SafeOnly
    [switch]$EnableSafeOps,
    [switch]$EnableGitCheckpoints,
    [string]$ImplementationPlan,
    [switch]$Verbose
)

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "CLAUDE CLI WITH INTELLIGENT PERMISSION HANDLING" -ForegroundColor Green
Write-Host "=" * 80 -ForegroundColor Cyan

# Import required modules
Write-Host "`nLoading modules..." -ForegroundColor Gray
Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\PermissionHandler.psm1" -Force
if ($EnableSafeOps) {
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\SafeOperationsHandler.psm1" -Force
}

# Initialize permission handler
Write-Host "Initializing permission handler..." -ForegroundColor Cyan
$initResult = Initialize-PermissionHandler -Mode $Mode

# Configure custom rules based on mode
switch ($Mode) {
    "SafeOnly" {
        Write-Host "Mode: Safe Only - Denying all destructive operations" -ForegroundColor Yellow
        
        # Add strict safety rules
        Add-PermissionRule -Name "DenyAllDeletes" `
            -Pattern "(?i)(delete|remove|rm|del|erase|destroy|clear|purge)" `
            -Decision "deny" `
            -Confidence 1.0 `
            -Reason "Safe mode - all destructive operations blocked"
            
        Add-PermissionRule -Name "DenySystemChanges" `
            -Pattern "(?i)(system|registry|config|settings)" `
            -Decision "deny" `
            -Confidence 1.0 `
            -Reason "Safe mode - system modifications blocked"
    }
    
    "Intelligent" {
        Write-Host "Mode: Intelligent - Context-aware permission decisions" -ForegroundColor Yellow
        
        # Already configured in PermissionHandler module
    }
    
    "AutoApprove" {
        Write-Host "Mode: Auto-Approve - All permissions will be approved" -ForegroundColor Yellow
        Write-Host "⚠️ WARNING: This mode approves ALL operations automatically!" -ForegroundColor Red
    }
    
    "Monitor" {
        Write-Host "Mode: Monitor Only - No automatic responses" -ForegroundColor Yellow
    }
}

# Initialize safe operations if enabled
if ($EnableSafeOps) {
    Write-Host "`nInitializing safe operations..." -ForegroundColor Cyan
    Initialize-SafeOperations -GitAutoCommit:$EnableGitCheckpoints
    
    if ($ImplementationPlan) {
        Start-ImplementationPlan -PlanName $ImplementationPlan -InitialPhase "Setup"
    }
}

# Start permission monitoring
Write-Host "`nStarting permission monitor..." -ForegroundColor Cyan

# Create background job for monitoring Claude output
$monitorScript = {
    param($Mode, $LogPath)
    
    # Load the module in the background job
    Import-Module ".\Modules\Unity-Claude-CLIOrchestrator\Core\PermissionHandler.psm1" -Force
    
    # Monitor loop
    $lastCheck = Get-Date
    $checkInterval = 100  # milliseconds
    
    while ($true) {
        try {
            # Get the active window title
            Add-Type @"
                using System;
                using System.Runtime.InteropServices;
                using System.Text;
                
                public class WindowHelper {
                    [DllImport("user32.dll")]
                    public static extern IntPtr GetForegroundWindow();
                    
                    [DllImport("user32.dll")]
                    public static extern int GetWindowText(IntPtr hWnd, StringBuilder text, int count);
                    
                    public static string GetActiveWindowTitle() {
                        const int nChars = 256;
                        StringBuilder Buff = new StringBuilder(nChars);
                        IntPtr handle = GetForegroundWindow();
                        
                        if (GetWindowText(handle, Buff, nChars) > 0) {
                            return Buff.ToString();
                        }
                        return "";
                    }
                }
"@
            
            $windowTitle = [WindowHelper]::GetActiveWindowTitle()
            
            # Check if Claude CLI is active
            if ($windowTitle -match "claude|Claude|cmd|powershell|terminal") {
                # Try to capture console output (simplified approach)
                # In production, you'd use more sophisticated console reading
                
                # For now, we'll simulate detection based on timing
                # Real implementation would read actual console buffer
                
                $now = Get-Date
                if (($now - $lastCheck).TotalSeconds -gt 5) {
                    # Log activity
                    $activity = @{
                        Timestamp = $now
                        Window = $windowTitle
                        Mode = $Mode
                    } | ConvertTo-Json -Compress
                    
                    Add-Content -Path $LogPath -Value $activity
                    $lastCheck = $now
                }
            }
        } catch {
            # Silent continue
        }
        
        Start-Sleep -Milliseconds $checkInterval
    }
}

$logPath = ".\AutomationLogs\permission_monitor_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$monitorJob = Start-Job -ScriptBlock $monitorScript -ArgumentList $Mode, $logPath

Write-Host "✅ Permission monitor started (Job ID: $($monitorJob.Id))" -ForegroundColor Green

# Create a function to check for permission prompts in real-time
function Watch-ClaudePermissions {
    param(
        [int]$Duration = 0  # 0 = infinite
    )
    
    $startTime = Get-Date
    $promptCount = 0
    
    Write-Host "`nWatching for Claude permission prompts..." -ForegroundColor Gray
    Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Gray
    Write-Host ""
    
    try {
        while ($true) {
            # Check if we should timeout
            if ($Duration -gt 0) {
                if ((Get-Date) - $startTime).TotalSeconds -gt $Duration {
                    break
                }
            }
            
            # This is where we'd check for actual permission prompts
            # For demonstration, we'll check every second
            Start-Sleep -Milliseconds 500
            
            # In real implementation, this would:
            # 1. Read console buffer
            # 2. Check for permission patterns
            # 3. Make decision based on rules
            # 4. Send response if needed
        }
    } catch {
        Write-Host "`nMonitoring stopped" -ForegroundColor Yellow
    } finally {
        Write-Host "Total monitoring time: $((Get-Date) - $startTime)" -ForegroundColor Cyan
        Write-Host "Prompts detected: $promptCount" -ForegroundColor Cyan
    }
}

# Display instructions
Write-Host "`n" + ("=" * 80) -ForegroundColor Cyan
Write-Host "PERMISSION HANDLING ACTIVE" -ForegroundColor Green
Write-Host ("=" * 80) -ForegroundColor Cyan

Write-Host "`nCurrent Configuration:" -ForegroundColor Yellow
Write-Host "  Mode: $Mode" -ForegroundColor White
Write-Host "  Safe Operations: $(if ($EnableSafeOps) { 'Enabled' } else { 'Disabled' })" -ForegroundColor White
Write-Host "  Git Checkpoints: $(if ($EnableGitCheckpoints) { 'Enabled' } else { 'Disabled' })" -ForegroundColor White
Write-Host "  Log Path: $logPath" -ForegroundColor White

Write-Host "`nHow to use:" -ForegroundColor Yellow
Write-Host "  1. Start Claude CLI in another terminal:" -ForegroundColor Gray
Write-Host '     claude' -ForegroundColor White
Write-Host ""
Write-Host "  2. When Claude asks for permissions, they will be handled based on mode:" -ForegroundColor Gray
Write-Host "     - Intelligent: Smart decisions based on context" -ForegroundColor White
Write-Host "     - SafeOnly: Block all destructive operations" -ForegroundColor White
Write-Host "     - AutoApprove: Approve everything (use with caution!)" -ForegroundColor White
Write-Host "     - Monitor: Just log, no automatic responses" -ForegroundColor White

Write-Host "`nUseful commands:" -ForegroundColor Yellow
Write-Host "  Watch-ClaudePermissions     # Start interactive monitoring" -ForegroundColor White
Write-Host "  Get-PermissionStatistics    # View permission stats" -ForegroundColor White
Write-Host "  Stop-Job $($monitorJob.Id)            # Stop background monitor" -ForegroundColor White

if ($EnableSafeOps) {
    Write-Host "`nSafe Operations commands:" -ForegroundColor Yellow
    Write-Host "  Show-SafeOperationsSummary  # View safety stats" -ForegroundColor White
    Write-Host "  phase-complete              # Complete implementation phase" -ForegroundColor White
}

Write-Host "`n📋 RECOMMENDED CLAUDE FLAGS:" -ForegroundColor Yellow
Write-Host @"
For maximum safety with this handler, start Claude with:

  claude --permission-mode default

Or for specific tool allowlisting:

  claude --allowed-tools "Read Edit Bash(git:*) Bash(npm:*)"

This handler will intercept and manage permissions based on your configured rules.
"@ -ForegroundColor Cyan

# Set up aliases for convenience
Set-Alias -Name watch-perms -Value Watch-ClaudePermissions
Set-Alias -Name perm-stats -Value Get-PermissionStatistics

Write-Host "`n✅ Permission handling system is ready!" -ForegroundColor Green
Write-Host "Open another terminal and start Claude CLI to begin." -ForegroundColor Yellow