# Test-Week6-Modular.ps1
# Test modular architecture for Week 6 Integration module
# Date: 2025-08-21

Write-Host "===== Week 6 Modular Architecture Test =====" -ForegroundColor Green
Write-Host ""

$passed = 0
$failed = 0

# Test 1: Import modular module
try {
    Import-Module './Modules/Unity-Claude-NotificationIntegration/Unity-Claude-NotificationIntegration-Modular.psd1' -Force
    Write-Host "[PASS] Modular module imported successfully" -ForegroundColor Green
    $passed++
}
catch {
    Write-Host "[FAIL] Modular module import failed: $_" -ForegroundColor Red
    $failed++
    exit 1
}

# Test 2: Check function count
try {
    $functions = Get-Command -Module Unity-Claude-NotificationIntegration-Modular
    $functionCount = $functions.Count
    if ($functionCount -gt 40) {
        Write-Host "[PASS] Function export count: $functionCount (expected 40+)" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAIL] Function export count too low: $functionCount" -ForegroundColor Red
        $failed++
    }
}
catch {
    Write-Host "[FAIL] Function count check failed: $_" -ForegroundColor Red
    $failed++
}

# Test 3: Core functionality
try {
    $initResult = Initialize-NotificationIntegration
    if ($initResult.QueueInitialized -eq $true) {
        Write-Host "[PASS] Core initialization working" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAIL] Core initialization failed" -ForegroundColor Red
        $failed++
    }
}
catch {
    Write-Host "[FAIL] Core initialization error: $_" -ForegroundColor Red
    $failed++
}

# Test 4: Integration functionality
try {
    $hook = Register-NotificationHook -Name 'ModularTestHook' -TriggerEvent 'Test.Event' -Action { 
        param($Context) 
        return @{ Status = 'Success'; Message = 'Modular test hook executed' }
    } -Severity 'Info'
    
    if ($hook.Name -eq 'ModularTestHook') {
        Write-Host "[PASS] Integration hook registration working" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAIL] Integration hook registration failed" -ForegroundColor Red
        $failed++
    }
}
catch {
    Write-Host "[FAIL] Integration functionality error: $_" -ForegroundColor Red
    $failed++
}

# Test 5: Context management
try {
    $context = New-NotificationContext -EventType 'Test.Event' -Severity 'Info' -Data @{TestKey='TestValue'}
    if ($context.EventType -eq 'Test.Event' -and $context.Data.TestKey -eq 'TestValue') {
        Write-Host "[PASS] Context management working" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAIL] Context management failed" -ForegroundColor Red
        $failed++
    }
}
catch {
    Write-Host "[FAIL] Context management error: $_" -ForegroundColor Red
    $failed++
}

# Test 6: Queue management
try {
    Initialize-NotificationQueue -MaxSize 100
    $queueStatus = Get-QueueStatus
    if ($queueStatus.MaxSize -eq 100 -and $queueStatus.QueueSize -eq 0) {
        Write-Host "[PASS] Queue management working" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAIL] Queue management failed" -ForegroundColor Red
        $failed++
    }
}
catch {
    Write-Host "[FAIL] Queue management error: $_" -ForegroundColor Red
    $failed++
}

# Test 7: Configuration management
try {
    $config = Get-NotificationConfiguration
    if ($config.Enabled -eq $true -and $config.MaxRetries -eq 3) {
        Write-Host "[PASS] Configuration management working" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAIL] Configuration management failed" -ForegroundColor Red
        $failed++
    }
}
catch {
    Write-Host "[FAIL] Configuration management error: $_" -ForegroundColor Red
    $failed++
}

# Test 8: Monitoring functionality
try {
    $metrics = Get-NotificationMetrics
    if ($metrics -and $metrics.ContainsKey('TotalSent')) {
        Write-Host "[PASS] Monitoring functionality working" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAIL] Monitoring functionality failed" -ForegroundColor Red
        $failed++
    }
}
catch {
    Write-Host "[FAIL] Monitoring functionality error: $_" -ForegroundColor Red
    $failed++
}

# Test 9: Module structure validation
try {
    $moduleStructure = @{
        Core = (Get-Command Initialize-NotificationIntegration -ErrorAction Stop)
        Integration = (Get-Command Add-WorkflowNotificationTrigger -ErrorAction Stop)
        Context = (Get-Command New-NotificationContext -ErrorAction Stop)
        Reliability = (Get-Command New-NotificationRetryPolicy -ErrorAction Stop)
        Queue = (Get-Command Initialize-NotificationQueue -ErrorAction Stop)
        Configuration = (Get-Command Get-NotificationConfiguration -ErrorAction Stop)
        Monitoring = (Get-Command Get-NotificationMetrics -ErrorAction Stop)
    }
    
    Write-Host "[PASS] All module components accessible" -ForegroundColor Green
    $passed++
}
catch {
    Write-Host "[FAIL] Module structure validation failed: $_" -ForegroundColor Red
    $failed++
}

Write-Host ""
Write-Host "===== Modular Architecture Test Results =====" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host "Total:  $($passed + $failed)" -ForegroundColor Yellow

if ($failed -eq 0) {
    Write-Host ""
    Write-Host "✅ ALL TESTS PASSED - Modular architecture working perfectly!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📁 Module Structure:" -ForegroundColor Cyan
    Write-Host "├── Core: Foundation and hook management" -ForegroundColor White
    Write-Host "├── Integration: Workflow and context management" -ForegroundColor White 
    Write-Host "├── Reliability: Retry logic and fallback mechanisms" -ForegroundColor White
    Write-Host "├── Queue: Queue management and processing" -ForegroundColor White
    Write-Host "├── Configuration: Settings and validation" -ForegroundColor White
    Write-Host "└── Monitoring: Metrics and health checks" -ForegroundColor White
    exit 0
} else {
    Write-Host ""
    Write-Host "❌ SOME TESTS FAILED - Please review the failures above" -ForegroundColor Red
    exit 1
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUY/8PUW8FkPdtNiEDmoFz1Y7j
# ryegggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUY6p9O1XqWxnIusjOQX1Wg+SFWP4wDQYJKoZIhvcNAQEBBQAEggEAlSAa
# 54I4KJ0Lt5hYeU8ta3f0YnOmvkrDbIK72envPDmrABCXbVsOcFVpZ6hDeYfCDwCv
# PEqELu+rppsF59YhAUB7ZbB7XYp1JRVRUZgaIaI7imgqGSE3fLnb4eST3lc5DnNW
# Rrwt+D8pTgvKNG3Rug+hQvSe3t2RetWdaDYVT8/jBT+DToYCGJrVTiMweQ4vD8cW
# wiklsxpJcj0M6+cw71Du7MfbcmP1L5Eh7duWLPc+imCPWyNh+XkJk+MCfCwRWIOW
# 0nHWtCNkUdZBE8bDB59BCBb9boZCWJrx7CVZ9/NLQKP9Lf0wurUDxA3v6T5TzTwB
# 1HYpM+4yen8CFvUZKA==
# SIG # End signature block
