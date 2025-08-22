# Block-InputDuringClaudeResponse.ps1
# Blocks keyboard and mouse input during Claude Code CLI response typing
# Prevents accidental interruption of autonomous response generation
# Based on Invoke-RapidUnityCompile.ps1 input blocking implementation

param(
    [int]$ResponseTimeoutSeconds = 300,  # 5 minutes max response time
    [switch]$Debug,                     # Enable debug output
    [string]$ClaudeWindowTitle = "Claude Code CLI*"  # Window title pattern to monitor
)

#Requires -RunAsAdministrator

# Initialize logging
$logFile = Join-Path $PSScriptRoot "unity_claude_automation.log"
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"

function Write-DebugLog {
    param([string]$Message)
    $logEntry = "$timestamp [CLAUDE_INPUT_BLOCK] $Message"
    Add-Content -Path $logFile -Value $logEntry -Encoding UTF8
    if ($Debug) {
        Write-Host $logEntry -ForegroundColor Magenta
    }
}

Write-DebugLog "=== Claude Code CLI Input Blocking Started ==="

# Check administrator privileges
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
if (-not $isAdmin) {
    Write-Error "Input blocking requires administrator privileges. Please run PowerShell as Administrator."
    exit 1
}

Write-DebugLog "Administrator privileges confirmed"

# Define P/Invoke for BlockInput API
$signature = @'
[DllImport("user32.dll", SetLastError = true)]
public static extern bool BlockInput(bool fBlockIt);

[DllImport("user32.dll", SetLastError = true)]
public static extern IntPtr GetForegroundWindow();

[DllImport("user32.dll", SetLastError = true)]
public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

[DllImport("user32.dll", SetLastError = true)]
public static extern int GetWindowTextLength(IntPtr hWnd);
'@

try {
    $type = Add-Type -MemberDefinition $signature -Name ClaudeInputBlock -Namespace ClaudeAutomation -PassThru -UsingNamespace System.Text -ErrorAction SilentlyContinue
    Write-DebugLog "P/Invoke structures defined successfully"
} catch {
    Write-DebugLog "P/Invoke structures already defined: $_"
}

function Get-CurrentWindowTitle {
    $window = [ClaudeAutomation.ClaudeInputBlock]::GetForegroundWindow()
    $length = [ClaudeAutomation.ClaudeInputBlock]::GetWindowTextLength($window)
    
    if ($length -gt 0) {
        $titleBuilder = New-Object System.Text.StringBuilder ($length + 1)
        [ClaudeAutomation.ClaudeInputBlock]::GetWindowText($window, $titleBuilder, $titleBuilder.Capacity) | Out-Null
        return $titleBuilder.ToString()
    }
    return ""
}

function Block-UserInput {
    param([bool]$Block)
    
    try {
        $result = [ClaudeAutomation.ClaudeInputBlock]::BlockInput($Block)
        if ($Block) {
            Write-DebugLog "User input blocked: $result"
            Write-Host "`n===== CLAUDE RESPONSE IN PROGRESS =====" -ForegroundColor White -BackgroundColor Blue
            Write-Host "KEYBOARD AND MOUSE LOCKED" -ForegroundColor Yellow -BackgroundColor Red
            Write-Host "Do NOT type or click until response completes!" -ForegroundColor Yellow -BackgroundColor Red
            Write-Host "Emergency unlock: Ctrl+Alt+Del" -ForegroundColor White -BackgroundColor Blue
            Write-Host "========================================" -ForegroundColor White -BackgroundColor Blue
        } else {
            Write-DebugLog "User input unblocked: $result"
            Write-Host "`n===== CLAUDE RESPONSE COMPLETED =======" -ForegroundColor White -BackgroundColor Green
            Write-Host "KEYBOARD AND MOUSE UNLOCKED" -ForegroundColor Black -BackgroundColor Green
            Write-Host "Safe to use keyboard and mouse again" -ForegroundColor Black -BackgroundColor Green
            Write-Host "=======================================" -ForegroundColor White -BackgroundColor Green
        }
        return $result
    } catch {
        Write-DebugLog "Failed to block/unblock input: $_"
        return $false
    }
}

function Monitor-ClaudeResponse {
    Write-DebugLog "Starting Claude response monitoring"
    Write-Host "Monitoring for Claude Code CLI response activity..." -ForegroundColor Cyan
    
    # Check if we're in a Claude window
    $currentTitle = Get-CurrentWindowTitle
    Write-DebugLog "Current window: $currentTitle"
    
    if ($currentTitle -like $ClaudeWindowTitle) {
        Write-Host "Claude Code CLI window detected: $currentTitle" -ForegroundColor Green
        
        # User confirmation
        Write-Host "`nWARNING: This will block keyboard and mouse input during Claude response typing." -ForegroundColor Yellow
        Write-Host "This prevents accidental interruption of autonomous responses." -ForegroundColor Yellow
        $response = Read-Host "Continue with input blocking? (Y/N)"
        
        if ($response -ne 'Y') {
            Write-Host "Operation cancelled" -ForegroundColor Yellow
            return
        }
        
        # Block input
        Write-DebugLog "Blocking input for Claude response"
        $blocked = Block-UserInput -Block $true
        
        if (-not $blocked) {
            Write-Error "Failed to block input"
            return
        }
        
        try {
            # Monitor for response completion
            # We'll wait for timeout or manual intervention
            Write-DebugLog "Monitoring response for up to $ResponseTimeoutSeconds seconds"
            
            $startTime = Get-Date
            $endTime = $startTime.AddSeconds($ResponseTimeoutSeconds)
            
            while ((Get-Date) -lt $endTime) {
                Start-Sleep -Seconds 1
                
                # Check if Claude window is still active
                $currentTitle = Get-CurrentWindowTitle
                if ($currentTitle -notlike $ClaudeWindowTitle) {
                    Write-DebugLog "Claude window no longer active: $currentTitle"
                    break
                }
                
                # Check for emergency file (user can create this to unlock)
                $emergencyFile = Join-Path $PSScriptRoot "unlock_claude_input.txt"
                if (Test-Path $emergencyFile) {
                    Write-DebugLog "Emergency unlock file detected"
                    Remove-Item $emergencyFile -Force
                    break
                }
            }
            
            if ((Get-Date) -ge $endTime) {
                Write-DebugLog "Response timeout reached"
                Write-Host "`nResponse timeout reached ($ResponseTimeoutSeconds seconds)" -ForegroundColor Yellow
            }
            
        } finally {
            # Always unblock input
            Write-DebugLog "Unblocking input"
            Block-UserInput -Block $false
        }
        
    } else {
        Write-Host "Not in Claude Code CLI window. Current: $currentTitle" -ForegroundColor Yellow
        Write-Host "Expected pattern: $ClaudeWindowTitle" -ForegroundColor Gray
    }
}

# Main execution
try {
    Monitor-ClaudeResponse
    Write-DebugLog "=== Claude input blocking completed ==="
    
} catch {
    Write-DebugLog "ERROR: $($_.Exception.Message)"
    Write-Error $_
    
    # Emergency unblock
    try {
        [ClaudeAutomation.ClaudeInputBlock]::BlockInput($false)
        Write-Host "Emergency input unblock executed" -ForegroundColor Yellow
    } catch {}
    
    throw
} finally {
    Write-DebugLog "=== Script execution ended ==="
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUddtYBorCg+QRwXUkSCPCSgem
# +HygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUQNHgTouFzh46Imin8Ur85gw2v9owDQYJKoZIhvcNAQEBBQAEggEAa1aL
# tH/uiFhS2CJBOLlxLTeeOr5Gl9eg+D8mFFw6bcwmBzWbHNz/jHD7f9uzP+ATtLFV
# Y4fDTydqcXudEm9JIb5u+EFkRGa0ZlfDDLRRRC1h8+C7rjoWKnpUBDuKfPV2isuZ
# 9j9wFaAnRumGQUmwOQj0QOQpvmHYTgzodLiXyBUJ++fCN4C9S/LDCRa9f1IldNhC
# 7lmBJXz9vTpOVIJ36jK239HGdmoRZx2OdLa6P5cqgbHn3Vw4heH4agb9NhprP1oE
# 33YOHYh9HkKmwsA1af3vHewDfcjU1XgQJrFtwvrhhHeRdOB1F00dFnnE2OkX8X/0
# y4KtGZdaMJ7EJRu+fA==
# SIG # End signature block
