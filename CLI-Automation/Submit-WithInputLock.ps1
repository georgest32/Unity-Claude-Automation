# Submit-WithInputLock.ps1
# Enhanced CLI submission with automatic input locking during response
# Integrates with existing Submit-ErrorsToClaude scripts

param(
    [string]$ErrorContent = "",
    [string]$Context = "",
    [switch]$AutoLock = $true,
    [int]$ResponseTimeoutSeconds = 300,  # 5 minutes
    [switch]$Debug
)

# Import required modules
$scriptRoot = Split-Path -Parent $PSScriptRoot
Import-Module "$scriptRoot\Modules\Unity-Claude-CLISubmission.psm1" -Force

function Write-DebugLog {
    param([string]$Message)
    if ($Debug) {
        $timestamp = Get-Date -Format "HH:mm:ss.fff"
        Write-Host "[$timestamp] $Message" -ForegroundColor Cyan
    }
}

function Start-InputLocking {
    Write-DebugLog "Starting input locking process"
    
    # Check if admin privileges available
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if (-not $isAdmin) {
        Write-Warning "Input locking requires Administrator privileges"
        Write-Host "Run PowerShell as Administrator to enable input locking during responses" -ForegroundColor Yellow
        return $false
    }
    
    try {
        # Start input lock script in background
        $lockScript = Join-Path $PSScriptRoot "Lock-InputForResponse.ps1"
        if (Test-Path $lockScript) {
            Write-DebugLog "Starting background input lock"
            $lockJob = Start-Job -ScriptBlock {
                param($ScriptPath, $TimeoutSeconds)
                & $ScriptPath -Lock -TimeoutSeconds $TimeoutSeconds
            } -ArgumentList $lockScript, $ResponseTimeoutSeconds
            
            return $lockJob
        } else {
            Write-Warning "Input lock script not found: $lockScript"
            return $false
        }
    } catch {
        Write-Warning "Failed to start input locking: $_"
        return $false
    }
}

function Stop-InputLocking {
    param($LockJob)
    
    Write-DebugLog "Stopping input locking"
    
    try {
        if ($LockJob) {
            # Stop the lock job
            Stop-Job $LockJob -ErrorAction SilentlyContinue
            Remove-Job $LockJob -ErrorAction SilentlyContinue
        }
        
        # Ensure input is unlocked
        $unlockScript = Join-Path $PSScriptRoot "Lock-InputForResponse.ps1"
        if (Test-Path $unlockScript) {
            & $unlockScript -Unlock
        }
    } catch {
        Write-Warning "Error during input unlock: $_"
    }
}

function Submit-ErrorsWithLocking {
    param(
        [string]$Content,
        [string]$Context
    )
    
    Write-Host "Submitting to Claude Code CLI with input protection..." -ForegroundColor Green
    
    $lockJob = $null
    
    try {
        # Start input locking if enabled
        if ($AutoLock) {
            Write-Host "Enabling input lock to prevent accidental interruption..." -ForegroundColor Yellow
            $lockJob = Start-InputLocking
            
            if ($lockJob) {
                Write-Host "Input lock active - keyboard and mouse disabled during response" -ForegroundColor Magenta
            }
        }
        
        # Submit to Claude using existing CLI submission module
        Write-DebugLog "Submitting content to Claude CLI"
        
        if ($Content) {
            $result = Submit-ToClaudeCodeCLI -ErrorContent $Content -Context $Context
        } else {
            $result = Submit-ToClaudeCodeCLI -Context $Context
        }
        
        Write-DebugLog "Claude submission completed"
        return $result
        
    } finally {
        # Always unlock input
        if ($AutoLock) {
            Write-Host "Restoring keyboard and mouse input..." -ForegroundColor Green
            Stop-InputLocking -LockJob $lockJob
        }
    }
}

# Main execution
try {
    Write-Host "=== Claude Code CLI Submission with Input Lock ===" -ForegroundColor Cyan
    Write-Host "Date: $(Get-Date)" -ForegroundColor Gray
    
    if ($AutoLock) {
        Write-Host "Input locking: ENABLED" -ForegroundColor Green
        Write-Host "This will prevent accidental keyboard/mouse input during Claude response" -ForegroundColor Yellow
    } else {
        Write-Host "Input locking: DISABLED" -ForegroundColor Gray
    }
    
    $result = Submit-ErrorsWithLocking -Content $ErrorContent -Context $Context
    
    if ($result) {
        Write-Host "Submission completed successfully" -ForegroundColor Green
    } else {
        Write-Host "Submission completed with warnings" -ForegroundColor Yellow
    }
    
} catch {
    Write-Error "Submission failed: $_"
    
    # Emergency input unlock
    try {
        $unlockScript = Join-Path $PSScriptRoot "Lock-InputForResponse.ps1"
        if (Test-Path $unlockScript) {
            & $unlockScript -Unlock
        }
    } catch {}
}