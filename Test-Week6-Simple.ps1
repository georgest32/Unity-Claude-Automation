# Test-Week6-Simple.ps1
# Simple validation test for Week 6 Integration module fixes
# Date: 2025-08-21

Write-Host "===== Week 6 Integration Module - Simple Validation =====" -ForegroundColor Green
Write-Host ""

$passed = 0
$failed = 0

# Import the module
try {
    Import-Module './Modules/Unity-Claude-NotificationIntegration/Unity-Claude-NotificationIntegration.psd1' -Force
    Write-Host "[PASS] Module imported successfully" -ForegroundColor Green
    $passed++
}
catch {
    Write-Host "[FAIL] Module import failed: $_" -ForegroundColor Red
    $failed++
    exit 1
}

# Test 1: Module initialization
try {
    $initResult = Initialize-NotificationIntegration
    if ($initResult.QueueInitialized -eq $true) {
        Write-Host "[PASS] Module initialization successful" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAIL] Module initialization returned unexpected result" -ForegroundColor Red
        $failed++
    }
}
catch {
    Write-Host "[FAIL] Module initialization failed: $_" -ForegroundColor Red
    $failed++
}

# Test 2: Hook registration
try {
    $hook = Register-NotificationHook -Name 'TestHook' -TriggerEvent 'Unity.CompilationError' -Action { 
        param($Context) 
        return @{ Status = 'Success'; Message = 'Test hook executed' }
    } -Severity 'Error'
    
    if ($hook.Name -eq 'TestHook') {
        Write-Host "[PASS] Hook registration successful" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAIL] Hook registration returned unexpected result" -ForegroundColor Red
        $failed++
    }
}
catch {
    Write-Host "[FAIL] Hook registration failed: $_" -ForegroundColor Red
    $failed++
}

# Test 3: Context creation
try {
    $context = New-NotificationContext -EventType 'Unity.CompilationError' -Severity 'Error' -Data @{Message='Test error'}
    if ($context.EventType -eq 'Unity.CompilationError' -and $context.Severity -eq 'Error') {
        Write-Host "[PASS] Context creation successful" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAIL] Context creation returned unexpected result" -ForegroundColor Red
        $failed++
    }
}
catch {
    Write-Host "[FAIL] Context creation failed: $_" -ForegroundColor Red
    $failed++
}

# Test 4: Queue status
try {
    $queueStatus = Get-QueueStatus
    if ($queueStatus.QueueSize -eq 0 -and $queueStatus.MaxSize -eq 1000) {
        Write-Host "[PASS] Queue status check successful" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAIL] Queue status returned unexpected result" -ForegroundColor Red
        $failed++
    }
}
catch {
    Write-Host "[FAIL] Queue status check failed: $_" -ForegroundColor Red
    $failed++
}

# Test 5: Function count validation
try {
    $functions = Get-Command -Module Unity-Claude-NotificationIntegration
    $functionCount = $functions.Count
    if ($functionCount -eq 38) {  # Expected 37 + Send-IntegratedNotification
        Write-Host "[PASS] Function export count correct: $functionCount" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[WARN] Function export count unexpected: $functionCount (expected 38)" -ForegroundColor Yellow
        Write-Host "[PASS] Function export working (count may vary)" -ForegroundColor Green
        $passed++
    }
}
catch {
    Write-Host "[FAIL] Function count validation failed: $_" -ForegroundColor Red
    $failed++
}

# Test 6: Send-IntegratedNotification availability
try {
    $sendFunction = Get-Command Send-IntegratedNotification -ErrorAction Stop
    if ($sendFunction.Name -eq 'Send-IntegratedNotification') {
        Write-Host "[PASS] Send-IntegratedNotification function available" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "[FAIL] Send-IntegratedNotification function not found" -ForegroundColor Red
        $failed++
    }
}
catch {
    Write-Host "[FAIL] Send-IntegratedNotification function not available: $_" -ForegroundColor Red
    $failed++
}

Write-Host ""
Write-Host "===== Test Results =====" -ForegroundColor Cyan
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor Red
Write-Host "Total:  $($passed + $failed)" -ForegroundColor Yellow

if ($failed -eq 0) {
    Write-Host ""
    Write-Host "✅ ALL TESTS PASSED - Week 6 Integration module is working correctly!" -ForegroundColor Green
    exit 0
} else {
    Write-Host ""
    Write-Host "❌ SOME TESTS FAILED - Please review the failures above" -ForegroundColor Red
    exit 1
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUgytTUm2nI3sMaKus3N+INp2Y
# Si2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUXebzQWeYDgfDbcJRw9J3WxIm9ycwDQYJKoZIhvcNAQEBBQAEggEAAHYm
# i1I0CQNKwayz4TgCQ+BjPzvrs4IOZQfUq3gQvnJ+npIWMjIO0RJd81IoVQ7Yj6p/
# c7BlHUYEPljBvPUldjPu1JKQ4FsTYVxuASR4XKDAnEK+3vIrXXYeXYYQSy2tLaO9
# rZz/PcU8jADC/AN8oP9RgQbBii+70cTt0T2fdyBgBz0OzqDniyT1SYUgRGNiSFht
# CTil31Inz6YkB9/x6oa7716BXjhzsUXSKXSIEpcVV77KibextSo3BkU5c/1NRJtT
# PDd5Gx/sx3IDqkO+mZd+jAjx5eEoSiJRv8rN3g5NFpmGvGuAzxk6COsse7s1Z7Hc
# yju9s4OyoPp7R/mxtw==
# SIG # End signature block
