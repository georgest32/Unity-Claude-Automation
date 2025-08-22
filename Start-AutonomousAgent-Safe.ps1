# Start-AutonomousAgent-Safe.ps1
# Safe AutonomousAgent loading that avoids ConversationStateManager/ContextOptimization conflicts
# ASCII only. No backticks used. Balanced try/catch and braces.
# Date: 2025-08-19

[CmdletBinding()]
param(
    [switch]$SkipConversationModules = $true
)

function Write-Stamp {
    param([string]$Message, [string]$Color = 'Gray')
    $ts = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')
    Write-Host "$Message [$ts]" -ForegroundColor $Color
}

Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "Unity-Claude AutonomousAgent - Safe Startup" -ForegroundColor Cyan
Write-Host "Starting at: $(Get-Date)" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Verify/Load SystemStatus (non-fatal if unavailable)
Write-Host "Step 1: Checking SystemStatus..." -ForegroundColor Yellow
try {
    $systemStatusModule = Get-Module -Name "Unity-Claude-SystemStatus" -ErrorAction SilentlyContinue
    if (-not $systemStatusModule) {
        Write-Host "SystemStatus module not loaded. Loading module..." -ForegroundColor DarkYellow
        $modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psd1"
        if (Test-Path $modulePath) {
            Write-Host "Loading SystemStatus module from: $modulePath" -ForegroundColor Gray
            Import-Module $modulePath -Force -Global
            Write-Host "SystemStatus module loaded." -ForegroundColor Green
            
            # Initialize the monitoring system if loaded
            try {
                Initialize-SystemStatusMonitoring -Verbose:$false
                Write-Host "SystemStatus monitoring initialized." -ForegroundColor Green
            } catch {
                Write-Host "Warning: Could not initialize monitoring: $($_.Exception.Message)" -ForegroundColor Yellow
            }
        } else {
            Write-Host "SystemStatus module not found at: $modulePath (continuing)" -ForegroundColor DarkGray
        }
    } else {
        Write-Host "SystemStatus module is already loaded." -ForegroundColor Green
    }
} catch {
    Write-Host "Warning: Could not verify or load SystemStatus: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 2: Register AutonomousAgent subsystem (best-effort; do not fail hard)
Write-Host ""
Write-Host "Step 2: Registering AutonomousAgent subsystem (best-effort)..." -ForegroundColor Yellow
try {
    if (Get-Command Register-Subsystem -ErrorAction SilentlyContinue) {
        $modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-AutonomousAgent"
        Register-Subsystem -SubsystemName "Unity-Claude-AutonomousAgent" -ModulePath $modulePath -HealthCheckLevel "Standard"
        Write-Host "Subsystem registration invoked." -ForegroundColor Green
    } else {
        Write-Host "Register-Subsystem command not available; skipping." -ForegroundColor DarkGray
    }
} catch {
    Write-Host "Non-fatal: Subsystem registration failed: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 3: (Optional) Load conversation modules unless skipped
Write-Host ""
if (-not $SkipConversationModules) {
    Write-Host "Step 3: Loading conversation modules (ConversationStateManager, ContextOptimization)..." -ForegroundColor Yellow
    try {
        $convModulePath = Join-Path $PSScriptRoot "Modules\Conversation"
        if (Test-Path $convModulePath) {
            $psm1Files = Get-ChildItem -Path $convModulePath -Filter *.psm1 -Recurse -ErrorAction SilentlyContinue
            foreach ($m in $psm1Files) {
                Import-Module $m.FullName -Force -ErrorAction Stop
            }
            Write-Host "Conversation modules loaded." -ForegroundColor Green
        } else {
            Write-Host "Conversation modules path not found: $convModulePath (skipping)" -ForegroundColor DarkGray
        }
    } catch {
        Write-Host "ERROR: Failed to load conversation modules: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "This may cause the system to crash. Monitor carefully." -ForegroundColor Yellow
    }
} else {
    Write-Host "Step 3: Skipping conversation modules (ConversationStateManager, ContextOptimization) for stability." -ForegroundColor Gray
    Write-Host "AUTONOMOUS-AGENT: Conversation modules skipped for stability" -ForegroundColor DarkGray
}

# Step 4: Load AutonomousAgent module
Write-Host ""
Write-Host "Step 4: Loading AutonomousAgent module..." -ForegroundColor Yellow
try {
    $modulePath = Join-Path $PSScriptRoot "Modules\Unity-Claude-AutonomousAgent\Unity-Claude-AutonomousAgent.psd1"
    if (Test-Path $modulePath) {
        Import-Module $modulePath -Force -DisableNameChecking
        Write-Host "AutonomousAgent module imported successfully." -ForegroundColor Green
    } else {
        Write-Host "AutonomousAgent module not found at: $modulePath" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ERROR: Failed to import AutonomousAgent module: $($_.Exception.Message)" -ForegroundColor Red
}

# Step 5: Test basic AutonomousAgent functionality
Write-Host ""
Write-Host "Step 5: Testing AutonomousAgent functionality..." -ForegroundColor Yellow
Write-Host "AUTONOMOUS-AGENT: Testing basic module functionality..." -ForegroundColor DarkGray

try {
    $agentFunctions = @(
        'Initialize-AgentLogging',
        'Start-ClaudeResponseMonitoring',
        'Stop-ClaudeResponseMonitoring'
    )

    $found = New-Object System.Collections.Generic.List[string]
    $missing = New-Object System.Collections.Generic.List[string]

    foreach ($func in $agentFunctions) {
        if (Get-Command -Name $func -ErrorAction SilentlyContinue) {
            $null = $found.Add($func)
        } else {
            $null = $missing.Add($func)
        }
    }

    if ($found.Count -gt 0) {
        Write-Host ("Found functions: " + ($found -join ", ")) -ForegroundColor Green
    } else {
        Write-Host "No core agent functions were found in the current session." -ForegroundColor Yellow
    }

    if ($missing.Count -gt 0) {
        Write-Host ("Missing functions: " + ($missing -join ", ")) -ForegroundColor Yellow
    }

    if ($found.Contains('Initialize-AgentLogging')) {
        try {
            Initialize-AgentLogging -ErrorAction Stop
            Write-Host "Initialize-AgentLogging executed successfully" -ForegroundColor Green
        } catch {
            Write-Host ("Initialize-AgentLogging call failed: " + $_.Exception.Message) -ForegroundColor Yellow
        }
    }
} catch {
    Write-Host "ERROR during Step 5: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
$systemStatusModule = Get-Module -Name "Unity-Claude-SystemStatus" -ErrorAction SilentlyContinue
if ($systemStatusModule) {
    Write-Host "SystemStatus: Loaded and available" -ForegroundColor Green
} else {
    Write-Host "SystemStatus: Not available" -ForegroundColor Yellow
}

if ($SkipConversationModules) {
    Write-Host "Conversation modules: Skipped for stability" -ForegroundColor Yellow
} else {
    Write-Host "Conversation modules: Loaded (monitor for crashes)" -ForegroundColor Green
}

Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Monitor SystemStatus for AutonomousAgent health" -ForegroundColor Gray
Write-Host "2. Test basic AutonomousAgent functionality" -ForegroundColor Gray
Write-Host "3. If stable, consider loading conversation modules with:" -ForegroundColor Gray
Write-Host "   .\Start-AutonomousAgent-Safe.ps1 -SkipConversationModules:$false" -ForegroundColor Gray
Write-Host ""

Write-Stamp -Message "AUTONOMOUS-AGENT: Safe startup completed at" -Color 'DarkGray'

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUNZM1YbhMJDrJxfn1mq7S6qNP
# 29+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUbLLnXfNY6QQ+Ajx4kbrUoD3vOIEwDQYJKoZIhvcNAQEBBQAEggEAEnC+
# E6o/wlJ9iFPe8lz3wDHmm4UGyuqHTeoj161q4QkokKDVho644CxsOnlAUgBDGhNG
# R3P4v3f40PFffZniRkZPzmlh8S6JK0Hom/MxE8KEXelwWVfCXUL06pi2ZnnTLQFd
# ArQOTD2xWkk6LdEzKExLQ9ggeCrpaD2nG0eva7FDqnSIypJUhJOto0N/3dkN8mqI
# u9HAYQgaJRl9VxIz6WJXhnbmQR5z7mkyp0hhxiRbI6mz7b6YJ/3KGJTTz+LCe107
# SDWjCOx74LUZW+gqFEgXU7x2zlLUiteIpSOL+QdbgUPlIR5lzrYh1IbVHNhn5EsC
# M/NVx1AQMWiKrC4FFA==
# SIG # End signature block
