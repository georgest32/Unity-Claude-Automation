# Start-AutonomousMonitoring-Fixed.ps1
# Stable autonomous monitoring launcher that imports core functionality as module
# Date: 2025-08-21


# PowerShell 7 Self-Elevation

param(
    [int]$PollIntervalSeconds = 5,
    [switch]$DebugMode
)

if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh7 = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $pwsh7) {
        Write-Host "Upgrading to PowerShell 7..." -ForegroundColor Yellow
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $MyInvocation.MyCommand.Path) + $args
        Start-Process -FilePath $pwsh7 -ArgumentList $arguments -NoNewWindow -Wait
        exit
    } else {
        Write-Warning "PowerShell 7 not found. Running in PowerShell $($PSVersionTable.PSVersion)"
    }
}

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "AUTONOMOUS MONITORING LAUNCHER" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Get process ID for tracking
# When launched with powershell -NoExit -File, the script runs in the PowerShell host process
# So $PID is the actual process ID that will be running
$agentPID = $PID
Write-Host "AutonomousAgent Process ID: $agentPID" -ForegroundColor Yellow

# IMPORTANT: When this script is started via Start-Process with -NoExit, 
# the $PID here IS the actual PowerShell process that will keep running
# This is the correct PID to register

# Set working directory
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

# Load required assemblies first
Write-Host "Loading assemblies..." -ForegroundColor Gray
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Import required modules first for deduplication check
Write-Host "Loading modules..." -ForegroundColor Gray
try {
    Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1" -Force
    Write-Host "  SystemStatus module loaded" -ForegroundColor Green
} catch {
    Write-Host "  Warning: Could not load SystemStatus module: $_" -ForegroundColor Yellow
}

# NOTE: Duplicate agent prevention is now handled by SystemStatus module during registration
# The Register-Subsystem function will automatically kill any existing AutonomousAgent process
Write-Host "Duplicate prevention handled by SystemStatus module" -ForegroundColor Gray

try {
    Import-Module ".\Modules\Unity-Claude-CLISubmission.psm1" -Force
    Write-Host "  CLISubmission module loaded" -ForegroundColor Green
} catch {
    Write-Host "  Warning: Could not load CLISubmission module: $_" -ForegroundColor Yellow
}

# Import the autonomous monitoring module
Write-Host "Loading autonomous monitoring module..." -ForegroundColor Yellow
try {
    Import-Module ".\Modules\Unity-Claude-AutonomousMonitoring\Unity-Claude-AutonomousMonitoring.psd1" -Force
    Write-Host "  Autonomous monitoring module loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "  ERROR: Could not load autonomous monitoring module: $_" -ForegroundColor Red
    Write-Host "  This is critical - cannot continue without core monitoring functionality" -ForegroundColor Red
    throw "Failed to load Unity-Claude-AutonomousMonitoring module: $_"
}

# Register with SystemStatus (if available)
try {
    Register-Subsystem -SubsystemName "AutonomousAgent" -ModulePath ".\Modules\Unity-Claude-AutonomousAgent" -HealthCheckLevel "Standard" -ProcessId $agentPID
    Write-Host "Registered AutonomousAgent subsystem with PID $agentPID" -ForegroundColor Green
} catch {
    Write-Host "Warning: Could not register with SystemStatus: $_" -ForegroundColor Yellow
}

# Start the autonomous monitoring
Write-Host ""
Write-Host "Starting autonomous monitoring..." -ForegroundColor Cyan

try {
    # Call the main monitoring function from the module
    Start-AutonomousMonitoring -PollIntervalSeconds $PollIntervalSeconds -DebugMode:$DebugMode
} catch {
    Write-Host "CRITICAL ERROR: Autonomous monitoring failed: $_" -ForegroundColor Red
    Write-Host "Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Red
    
    # Log the error
    $errorLog = @{
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        Error = $_.Exception.Message
        StackTrace = $_.ScriptStackTrace
        ProcessId = $PID
    }
    $errorLog | ConvertTo-Json | Add-Content -Path ".\autonomous_monitoring_errors.log"
    
    throw $_
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUQn1gFVOCUJxHgcZLWUmYQ7n1
# 3GygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU5AguNjtOSilMlQq3lwHe0a8Uyc8wDQYJKoZIhvcNAQEBBQAEggEAYcQX
# Ht83kGO6E/ENZbA0tNTlICZGNKOB4QXWibiUPMKJPPorrSlryvZzmpWGqLQpqNz9
# lY9rybKQJFib7naiiJ7+7fMp7WChcqMamAv+6IxAPq3dTJgqMIZs42RVhnIlcbAX
# LMeSGQlDHS1eOyHZ0FvSPwY5KjKVK1ucWHpWr0koTZQ2F1ISDpAwUgf8tfNAbjCa
# g/aojdZjEOCxcWLOGA4hRgwxXURYvX+YsVKHuP/LR0r+HjcCh1/qtH2VXe4fmhHa
# bsznLZAWpgZdHIpiEKw5StfCbdtoRh4SPi+lHPq+NUHiQ5aKO4CMbndBfnIUskJI
# NwZ5T1ZWvGeYA6PoIA==
# SIG # End signature block


