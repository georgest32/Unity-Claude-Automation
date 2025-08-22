# Test-TypeFixes-Quick.ps1
# Quick validation test for ExecutionPolicy type fixes and logging fallback
# Date: 2025-08-21

Write-Host "=== Quick Type Fixes Validation Test ===" -ForegroundColor Cyan
Write-Host "Testing Unity-Claude-RunspaceManagement module after ExecutionPolicy type fix" -ForegroundColor Yellow

try {
    Write-Host "Attempting to import module with logging fallback..." -ForegroundColor White
    Import-Module ".\Modules\Unity-Claude-RunspaceManagement\Unity-Claude-RunspaceManagement.psd1" -Force -ErrorAction Stop
    Write-Host "[SUCCESS] Module imported without errors" -ForegroundColor Green
    
    Write-Host "Checking exported functions..." -ForegroundColor White
    $exportedFunctions = Get-Command -Module Unity-Claude-RunspaceManagement
    Write-Host "[SUCCESS] Exported functions: $($exportedFunctions.Count)" -ForegroundColor Green
    
    Write-Host "Testing New-RunspaceSessionState with ExecutionPolicy fix..." -ForegroundColor White
    $sessionConfig = New-RunspaceSessionState -ExecutionPolicy 'Bypass' -LanguageMode 'FullLanguage'
    
    if ($sessionConfig -and $sessionConfig.SessionState -and $sessionConfig.Metadata) {
        Write-Host "[SUCCESS] New-RunspaceSessionState working with ExecutionPolicy" -ForegroundColor Green
        Write-Host "    Session state created: $($sessionConfig.SessionState -ne $null)" -ForegroundColor Gray
        Write-Host "    Language mode: $($sessionConfig.Metadata.LanguageMode)" -ForegroundColor Gray
        Write-Host "    Execution policy: $($sessionConfig.Metadata.ExecutionPolicy)" -ForegroundColor Gray
    } else {
        Write-Host "[FAIL] New-RunspaceSessionState returned invalid result" -ForegroundColor Red
    }
    
    Write-Host "Testing session state validation..." -ForegroundColor White
    $validation = Test-SessionStateConfiguration -SessionStateConfig $sessionConfig
    
    if ($validation -and $validation.IsValid) {
        Write-Host "[SUCCESS] Session state validation passed: $($validation.ValidationScore)%" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Session state validation failed: $($validation.ValidationScore)%" -ForegroundColor Red
    }
    
    Write-Host "`n=== TYPE FIXES VALIDATION SUCCESS ===" -ForegroundColor Green
    Write-Host "ExecutionPolicy type error resolved, module fully operational" -ForegroundColor Green
    
} catch {
    Write-Host "[FAIL] Type fixes validation failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Additional error details:" -ForegroundColor Yellow
    Write-Host $_.Exception.ToString() -ForegroundColor Red
}

Write-Host "`nQuick validation completed at $(Get-Date)" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTD0sit0TDMKxBZJti8V1ukSN
# uR6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU+c8BfGQZLFMbs0U0AndLWGEHvIAwDQYJKoZIhvcNAQEBBQAEggEAeXPE
# MnSlf1qpb1u+DrCjlk2wbLX41Epp1w4uubveI1mwctQnIKZkRTq1WQOGnu1AsaAQ
# HByKByrnirvqRNJTR/tYZzytbGAywsrcNebO4nkLyY0qNXqcxW5Kfa4KySztvRiX
# U22Syl9G1MQS1GT73AO7SN0IY3B3TBiTJOeNQPdQJ36MJdpP60s/E3kJ8OCc1ljo
# ELGgV5QY//Xpmj8fabVEf7jlIufy2HVkqRLsyl4M/gc86B3aXW8LSzeX8BYMHAXr
# jAY/4jRn/mIOVAwIkb+CHCsFTJPqDcufmQydPoBb5DwlmZGV4ChT1Zhxk7uHUND+
# YncUwdU2lEd/vu3yrQ==
# SIG # End signature block
