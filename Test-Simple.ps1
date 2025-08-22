# Test-Simple.ps1
# Simple test script for autonomous monitoring validation
# Date: 2025-08-21

param(
    [switch]$DebugMode
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "SIMPLE VALIDATION TEST" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan
Write-Host ""

# Test basic PowerShell functionality
Write-Host "Test 1: Basic PowerShell Operations" -ForegroundColor Yellow
$testResult1 = $true

try {
    $testVar = "Hello World"
    $testNum = 42
    $testArray = @(1, 2, 3, 4, 5)
    $testHash = @{ Name = "Test"; Value = 123 }
    
    Write-Host "  String variable: $testVar" -ForegroundColor Green
    Write-Host "  Numeric variable: $testNum" -ForegroundColor Green
    Write-Host "  Array count: $($testArray.Count)" -ForegroundColor Green
    Write-Host "  Hashtable keys: $($testHash.Keys -join ', ')" -ForegroundColor Green
    
    Write-Host "  [PASS] Basic operations successful" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Basic operations failed: $_" -ForegroundColor Red
    $testResult1 = $false
}

Write-Host ""
Write-Host "Test 2: File System Operations" -ForegroundColor Yellow
$testResult2 = $true

try {
    $testFile = ".\test_simple_$(Get-Date -Format 'yyyyMMdd_HHmmss').tmp"
    
    # Create test file
    "Test content $(Get-Date)" | Set-Content -Path $testFile
    
    if (Test-Path $testFile) {
        Write-Host "  [PASS] File creation successful" -ForegroundColor Green
        
        # Read test file
        $content = Get-Content -Path $testFile
        Write-Host "  [PASS] File reading successful: $content" -ForegroundColor Green
        
        # Clean up
        Remove-Item $testFile -Force
        Write-Host "  [PASS] File cleanup successful" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] File creation failed" -ForegroundColor Red
        $testResult2 = $false
    }
} catch {
    Write-Host "  [FAIL] File operations failed: $_" -ForegroundColor Red
    $testResult2 = $false
}

Write-Host ""
Write-Host "Test 3: Process Information" -ForegroundColor Yellow
$testResult3 = $true

try {
    $currentProcess = Get-Process -Id $PID
    Write-Host "  Current process: $($currentProcess.Name) (PID: $($currentProcess.Id))" -ForegroundColor Green
    Write-Host "  Working directory: $(Get-Location)" -ForegroundColor Green
    Write-Host "  PowerShell version: $($PSVersionTable.PSVersion)" -ForegroundColor Green
    Write-Host "  [PASS] Process information retrieved" -ForegroundColor Green
} catch {
    Write-Host "  [FAIL] Process information failed: $_" -ForegroundColor Red
    $testResult3 = $false
}

# Calculate overall result
$overallSuccess = $testResult1 -and $testResult2 -and $testResult3

Write-Host ""
Write-Host "=============================" -ForegroundColor Cyan
Write-Host "TEST RESULTS" -ForegroundColor Cyan
Write-Host "=============================" -ForegroundColor Cyan

Write-Host "Basic Operations: $(if ($testResult1) { '[PASS]' } else { '[FAIL]' })" -ForegroundColor $(if ($testResult1) { 'Green' } else { 'Red' })
Write-Host "File Operations:  $(if ($testResult2) { '[PASS]' } else { '[FAIL]' })" -ForegroundColor $(if ($testResult2) { 'Green' } else { 'Red' })
Write-Host "Process Info:     $(if ($testResult3) { '[PASS]' } else { '[FAIL]' })" -ForegroundColor $(if ($testResult3) { 'Green' } else { 'Red' })

Write-Host ""
if ($overallSuccess) {
    Write-Host "OVERALL RESULT: [PASS] All tests successful!" -ForegroundColor Green
    Write-Host "Simple validation test completed successfully." -ForegroundColor Green
} else {
    Write-Host "OVERALL RESULT: [FAIL] Some tests failed!" -ForegroundColor Red
    Write-Host "Check individual test results above." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Test completed at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray

return $overallSuccess
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU4fIGV/96sfcbTPx4Wv44yXny
# IgugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU84NQH4zn7Zg6ttYuj8roA/M6zhswDQYJKoZIhvcNAQEBBQAEggEADgLt
# a9w/7kB4Ou2ptadcIE69/BObcG+rUwO9wnzb02vq1XUqbVZCbL8aAOHLt3VqwEsJ
# P1TF5JVPkbTRrvZWpisonmdHx6iQptj0F5oCoN8p7ZOdU0FwnGpysmoelpIyHANq
# PWl97JUA1uI77DCM1EznT+o53dquKrCS+82blNoeAFQ09SON3If9zqx6Htw+qJPN
# MkxQvQPQ3Yh18FFZNT2tX+h822IpH8LmAHQyIqAYmyh97KkAVK/REYBP/gGW/Gd8
# L4d/4Lo9Xt6Wvc08LR1DQnZFR8H7GWo9me1SPP6ncYZ2XB7/X7nNfBxQnoA/hRmj
# TqzT7vByqHRpUycwHA==
# SIG # End signature block
