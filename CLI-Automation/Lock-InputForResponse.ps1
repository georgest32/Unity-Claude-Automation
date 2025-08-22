# Lock-InputForResponse.ps1
# Simple input locking for Claude Code CLI responses
# Usage: .\Lock-InputForResponse.ps1 -Lock (to lock)
# Usage: .\Lock-InputForResponse.ps1 -Unlock (to unlock)

param(
    [switch]$Lock,
    [switch]$Unlock,
    [int]$TimeoutSeconds = 180  # 3 minute default timeout
)

#Requires -RunAsAdministrator

# Define BlockInput API
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

public class InputBlocker {
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool BlockInput(bool fBlockIt);
}
'@ -ErrorAction SilentlyContinue

function Lock-Input {
    try {
        $result = [InputBlocker]::BlockInput($true)
        if ($result) {
            Write-Host "===== INPUT LOCKED FOR CLAUDE RESPONSE =====" -ForegroundColor White -BackgroundColor Red
            Write-Host "Do NOT type or click until unlocked!" -ForegroundColor Yellow -BackgroundColor Red
            Write-Host "Emergency: Ctrl+Alt+Del always works" -ForegroundColor White -BackgroundColor Red
            Write-Host "=============================================" -ForegroundColor White -BackgroundColor Red
            
            # Auto-unlock after timeout
            if ($TimeoutSeconds -gt 0) {
                Start-Sleep -Seconds $TimeoutSeconds
                Unlock-Input
                Write-Host "Auto-unlocked after $TimeoutSeconds seconds" -ForegroundColor Yellow
            }
        } else {
            Write-Error "Failed to lock input"
        }
        return $result
    } catch {
        Write-Error "Error locking input: $_"
        return $false
    }
}

function Unlock-Input {
    try {
        $result = [InputBlocker]::BlockInput($false)
        if ($result) {
            Write-Host "===== INPUT UNLOCKED - SAFE TO USE =====" -ForegroundColor Black -BackgroundColor Green
            Write-Host "Keyboard and mouse restored" -ForegroundColor Black -BackgroundColor Green
            Write-Host "=======================================" -ForegroundColor Black -BackgroundColor Green
        } else {
            Write-Warning "Failed to unlock input"
        }
        return $result
    } catch {
        Write-Error "Error unlocking input: $_"
        return $false
    }
}

# Check admin privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Error "Administrator privileges required for input blocking"
    exit 1
}

# Execute requested action
if ($Lock) {
    Lock-Input
} elseif ($Unlock) {
    Unlock-Input
} else {
    Write-Host "Usage:"
    Write-Host "  .\Lock-InputForResponse.ps1 -Lock    # Lock keyboard/mouse"
    Write-Host "  .\Lock-InputForResponse.ps1 -Unlock  # Unlock keyboard/mouse"
    Write-Host ""
    Write-Host "Note: Requires Administrator privileges"
}