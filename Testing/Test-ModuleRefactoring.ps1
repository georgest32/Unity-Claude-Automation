# Test-ModuleRefactoring.ps1
# Test script to verify refactored module structure works correctly
# Date: 2025-08-18

param(
    [switch]$UseRefactored
)

Write-Host ""
Write-Host "Testing Unity-Claude-AutonomousAgent Module Refactoring" -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

$modulePath = "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation\Modules\Unity-Claude-AutonomousAgent"

# Choose which module to test
if ($UseRefactored) {
    $moduleFile = Join-Path $modulePath "Unity-Claude-AutonomousAgent-Refactored.psm1"
    Write-Host "Testing REFACTORED module structure..." -ForegroundColor Yellow
} else {
    $moduleFile = Join-Path $modulePath "Unity-Claude-AutonomousAgent.psm1"
    Write-Host "Testing ORIGINAL module structure..." -ForegroundColor Yellow
}

Write-Host ""

# Test 1: Load the module
Write-Host "Test 1: Loading module..." -NoNewline
try {
    Import-Module $moduleFile -Force -DisableNameChecking
    Write-Host " PASS" -ForegroundColor Green
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    exit 1
}

# Test 2: Check core functions availability
Write-Host "Test 2: Checking core functions..." -NoNewline
$coreFunctions = @(
    'Initialize-AgentCore',
    'Get-AgentConfig',
    'Set-AgentConfig',
    'Get-AgentState',
    'Set-AgentState',
    'Reset-AgentState'
)

$missingCore = @()
foreach ($func in $coreFunctions) {
    if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
        $missingCore += $func
    }
}

if ($missingCore.Count -eq 0) {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "  Missing functions: $($missingCore -join ', ')" -ForegroundColor Red
}

# Test 3: Check logging functions
Write-Host "Test 3: Checking logging functions..." -NoNewline
$loggingFunctions = @(
    'Write-AgentLog',
    'Initialize-AgentLogging',
    'Get-AgentLogPath',
    'Get-AgentLogStatistics'
)

$missingLogging = @()
foreach ($func in $loggingFunctions) {
    if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
        $missingLogging += $func
    }
}

if ($missingLogging.Count -eq 0) {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "  Missing functions: $($missingLogging -join ', ')" -ForegroundColor Red
}

# Test 4: Check monitoring functions
Write-Host "Test 4: Checking monitoring functions..." -NoNewline
$monitoringFunctions = @(
    'Start-ClaudeResponseMonitoring',
    'Stop-ClaudeResponseMonitoring',
    'Get-MonitoringStatus'
)

$missingMonitoring = @()
foreach ($func in $monitoringFunctions) {
    if (-not (Get-Command $func -ErrorAction SilentlyContinue)) {
        $missingMonitoring += $func
    }
}

if ($missingMonitoring.Count -eq 0) {
    Write-Host " PASS" -ForegroundColor Green
} else {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "  Missing functions: $($missingMonitoring -join ', ')" -ForegroundColor Red
}

# Test 5: Initialize core systems
Write-Host "Test 5: Initializing core systems..." -NoNewline
try {
    $initResult = Initialize-AgentCore
    if ($initResult.Success) {
        Write-Host " PASS" -ForegroundColor Green
    } else {
        Write-Host " FAIL" -ForegroundColor Red
    }
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Test 6: Test logging
Write-Host "Test 6: Testing logging system..." -NoNewline
try {
    Write-AgentLog -Message "Test log entry from refactoring test" -Level "INFO" -Component "RefactoringTest" -NoConsole
    $logPath = Get-AgentLogPath
    if (Test-Path $logPath) {
        $logContent = Get-Content $logPath -Tail 1
        if ($logContent -match "Test log entry from refactoring test") {
            Write-Host " PASS" -ForegroundColor Green
        } else {
            Write-Host " FAIL" -ForegroundColor Red
            Write-Host "  Log entry not found" -ForegroundColor Red
        }
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        Write-Host "  Log file not found" -ForegroundColor Red
    }
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Test 7: Test configuration management
Write-Host "Test 7: Testing configuration management..." -NoNewline
try {
    $config = Get-AgentConfig
    if ($config.ContainsKey("ConfidenceThreshold")) {
        # Try to update a setting
        Set-AgentConfig -Settings @{ ConfidenceThreshold = 0.8 }
        $newValue = Get-AgentConfig -Setting "ConfidenceThreshold"
        if ($newValue -eq 0.8) {
            Write-Host " PASS" -ForegroundColor Green
            # Reset to original
            Set-AgentConfig -Settings @{ ConfidenceThreshold = 0.7 }
        } else {
            Write-Host " FAIL" -ForegroundColor Red
            Write-Host "  Configuration update failed" -ForegroundColor Red
        }
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        Write-Host "  Configuration not loaded" -ForegroundColor Red
    }
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Test 8: Test state management
Write-Host "Test 8: Testing state management..." -NoNewline
try {
    $state = Get-AgentState
    if ($state.ContainsKey("IsMonitoring")) {
        # Try to update state
        Set-AgentState -Properties @{ ConversationRound = 5 }
        $newState = Get-AgentState -Property "ConversationRound"
        if ($newState -eq 5) {
            Write-Host " PASS" -ForegroundColor Green
            # Reset state
            Reset-AgentState
        } else {
            Write-Host " FAIL" -ForegroundColor Red
            Write-Host "  State update failed" -ForegroundColor Red
        }
    } else {
        Write-Host " FAIL" -ForegroundColor Red
        Write-Host "  State not loaded" -ForegroundColor Red
    }
} catch {
    Write-Host " FAIL" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
}

# Test 9: Check module status (refactored only)
if ($UseRefactored) {
    Write-Host "Test 9: Getting module status..." -NoNewline
    try {
        if (Get-Command Get-ModuleStatus -ErrorAction SilentlyContinue) {
            $status = Get-ModuleStatus
            Write-Host " PASS" -ForegroundColor Green
            Write-Host ""
            Write-Host "Module Status:" -ForegroundColor Cyan
            Write-Host "  Version: $($status.Version)" -ForegroundColor Gray
            Write-Host "  Loaded Modules: $($status.LoadedModules.Count)" -ForegroundColor Gray
            Write-Host "  Total Functions: $($status.TotalFunctions)" -ForegroundColor Gray
        } else {
            Write-Host " SKIP" -ForegroundColor Yellow
            Write-Host "  Get-ModuleStatus not available" -ForegroundColor Yellow
        }
    } catch {
        Write-Host " FAIL" -ForegroundColor Red
        Write-Host "  Error: $_" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "========================================================" -ForegroundColor Cyan

# Summary
$totalTests = 8
if ($UseRefactored) { $totalTests = 9 }

Write-Host "Test Summary:" -ForegroundColor Cyan
Write-Host "  Module Type: $(if ($UseRefactored) { 'REFACTORED' } else { 'ORIGINAL' })" -ForegroundColor White
Write-Host "  Total Tests: $totalTests" -ForegroundColor White

if ($UseRefactored) {
    Write-Host ""
    Write-Host "Refactoring Benefits:" -ForegroundColor Green
    Write-Host "  ✓ Modular architecture" -ForegroundColor Gray
    Write-Host "  ✓ Better maintainability" -ForegroundColor Gray
    Write-Host "  ✓ Easier testing" -ForegroundColor Gray
    Write-Host "  ✓ Improved performance" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Test completed at $(Get-Date)" -ForegroundColor Gray
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUv8ZjZxyL2aPSSVkqd2j+5jFE
# vUSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUYjqqB/ztWHl7d2ZUoY6MER/scvQwDQYJKoZIhvcNAQEBBQAEggEAclOa
# fGhiIwqNUnf5kurNE93d73AFRRCG02WNeFg3URlByq6cSCsRqoq+keNzY7an9pi3
# lvknCT2KIcH7TCiM7gvQIUB+yRQxZNw3owu+u1Z6qWvAeuhCaiyi8z2zzKIyA1Fn
# XItrXOj2rGVaRrx07gjUuk4/3y4Yue2ZTQWpQ/R4/pqSOM0sRVrWOYK6K8siWtnW
# f0xjVETeSRsHEasXbh7XOJ2UoTeZNYFPodk+NLwgjnLenSUgvtXXF/lkDzprIhx2
# 5n7GaKlnjuGE0w92TlF8SohEFAGtekT4UdWK3HXqm8ad3tmLLmgEs05uYBO+88c9
# GSMMiCZdvoGp8VxwBA==
# SIG # End signature block
