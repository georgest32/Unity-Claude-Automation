# Test-Integration-Simple.ps1
# Simplified integration test for Phase 3
# Date: 2025-08-17

Write-Host "`n=== PHASE 3 INTEGRATION TEST ===" -ForegroundColor Cyan

# Setup module path
$modulePath = Join-Path $PSScriptRoot 'Modules'
$env:PSModulePath = "$modulePath;$env:PSModulePath"

# Load module
Write-Host "Loading Unity-Claude-Learning-Simple..." -ForegroundColor Gray
Import-Module Unity-Claude-Learning-Simple -Force
Write-Host "  Module loaded successfully" -ForegroundColor Green

# Initialize
Initialize-LearningStorage | Out-Null
Write-Host "  Storage initialized" -ForegroundColor Green

# Check patterns
$config = Get-LearningConfig
$patternCount = 0
if (Test-Path $config.PatternsFile) {
    $jsonContent = Get-Content $config.PatternsFile -Raw | ConvertFrom-Json
    $patternCount = ($jsonContent | Get-Member -MemberType NoteProperty).Count
}
Write-Host "  Patterns available: $patternCount" -ForegroundColor Gray

Write-Host "`n=== RUNNING TESTS ===" -ForegroundColor Cyan
$passCount = 0
$totalTests = 3

# Test 1: Known pattern
Write-Host "`nTest 1: Known Unity error" -ForegroundColor Yellow
$fixes = Get-SuggestedFixes -ErrorMessage "CS0246: GameObject not found" -MinSimilarity 65
if ($fixes) {
    Write-Host "  PASS - Found fix: $($fixes[0].Fix)" -ForegroundColor Green
    $passCount++
}
else {
    Write-Host "  FAIL - No fix found" -ForegroundColor Red
}

# Test 2: Performance
Write-Host "`nTest 2: Performance check" -ForegroundColor Yellow
$start = Get-Date
for ($i = 1; $i -le 5; $i++) {
    $null = Get-SuggestedFixes -ErrorMessage "CS0246: Test error" -MinSimilarity 65
}
$duration = ((Get-Date) - $start).TotalMilliseconds
$avg = $duration / 5
Write-Host "  Average time: $([Math]::Round($avg, 2))ms" -ForegroundColor Gray
if ($avg -lt 500) {
    Write-Host "  PASS - Performance acceptable" -ForegroundColor Green
    $passCount++
}
else {
    Write-Host "  FAIL - Too slow" -ForegroundColor Red
}

# Test 3: Unknown error
Write-Host "`nTest 3: Unknown error handling" -ForegroundColor Yellow
$fixes = Get-SuggestedFixes -ErrorMessage "CS9999: Unknown error" -MinSimilarity 65
if (-not $fixes) {
    Write-Host "  PASS - Correctly returns no fix" -ForegroundColor Green
    $passCount++
}
else {
    Write-Host "  FAIL - Incorrectly found fix" -ForegroundColor Red
}

# Summary
Write-Host "`n=== SUMMARY ===" -ForegroundColor Cyan
Write-Host "Results: $passCount / $totalTests tests passed" -ForegroundColor $(if ($passCount -eq $totalTests) { "Green" } else { "Yellow" })

if ($passCount -eq $totalTests) {
    Write-Host "`nALL TESTS PASSED - Integration ready!" -ForegroundColor Green
}
else {
    Write-Host "`nSome tests failed - review above" -ForegroundColor Yellow
}

Write-Host ""
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUK95LzskFVValy1JU8P7KbzFp
# DH6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUfUkuNaN3lQZQ2SjwjvQQ4r+vBCcwDQYJKoZIhvcNAQEBBQAEggEAmKyc
# 3SowZ4BePod8AVqXpLM8fwdcjMm4B73Ckd34STpyVggKmOkSjxuoR30ibbizX8hI
# zoWaDni1yMLkZMoJR9BIi4y6xAoW6RyttppVFcylLABp/BUyN/5PIAkyQS2mBjHB
# zjmh01lQT74GvZbKb5Qt/74neh0HFrM9KND9avcwQZkhQS1/0UPxlSX6DpEEy8BM
# gCzRi36TuaohRMG/V8iNXutlBxAhW0GUhYLklepaFjvEaTrR6PF6mFq5ypIIvDU+
# U/94aPvpPJaO1NRKTKMuzG6jHPIVpE0P1CCpZrQuNoE0W6pCczMfLz1ISTnvZBhN
# zMKVYzz6uIE0I7vYAw==
# SIG # End signature block
