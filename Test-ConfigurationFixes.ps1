# Test-ConfigurationFixes.ps1
# Quick test for the configuration fixes

Write-Host "=== Testing Configuration System Fixes ===" -ForegroundColor Cyan

try {
    # Test 1: Module import and function availability
    Write-Host "`n1. Testing module import..." -ForegroundColor Yellow
    Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1" -Force
    
    $testConfigFunc = Get-Command "Test-SystemStatusConfiguration" -ErrorAction SilentlyContinue
    if ($testConfigFunc) {
        Write-Host "✅ Test-SystemStatusConfiguration function is now available" -ForegroundColor Green
    } else {
        Write-Host "❌ Test-SystemStatusConfiguration function still missing" -ForegroundColor Red
    }
    
    # Test 2: Load development configuration (should work)
    Write-Host "`n2. Testing development configuration..." -ForegroundColor Yellow
    Copy-Item ".\Modules\Unity-Claude-SystemStatus\Config\examples\development.config.json" ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json" -Force
    
    $config = Get-SystemStatusConfiguration -ForceRefresh
    if ($config.SystemStatus.LogLevel -eq "DEBUG") {
        Write-Host "✅ Development configuration loaded successfully" -ForegroundColor Green
    } else {
        Write-Host "❌ Development configuration failed to load" -ForegroundColor Red
    }
    
    # Test 3: Test validation function
    Write-Host "`n3. Testing configuration validation..." -ForegroundColor Yellow
    $validation = Test-SystemStatusConfiguration -Config $config
    if ($validation.IsValid) {
        Write-Host "✅ Configuration validation passed" -ForegroundColor Green
    } else {
        Write-Host "❌ Configuration validation failed: $($validation.Errors -join ', ')" -ForegroundColor Red
    }
    
    # Test 4: Test circuit breaker configuration
    Write-Host "`n4. Testing circuit breaker configuration..." -ForegroundColor Yellow
    $cbConfig = Get-SubsystemCircuitBreakerConfig -SubsystemName "TestSubsystem" -BaseConfig $config.CircuitBreaker
    if ($cbConfig.ConfigurationSource) {
        Write-Host "✅ Circuit breaker configuration works (Source: $($cbConfig.ConfigurationSource))" -ForegroundColor Green
    } else {
        Write-Host "❌ Circuit breaker configuration failed" -ForegroundColor Red
    }
    
    # Test 5: Environment variable override
    Write-Host "`n5. Testing environment variable override..." -ForegroundColor Yellow
    $env:UNITYC_LOG_LEVEL = "TRACE"
    $configWithEnv = Get-SystemStatusConfiguration -ForceRefresh
    if ($configWithEnv.SystemStatus.LogLevel -eq "TRACE") {
        Write-Host "✅ Environment variable override works" -ForegroundColor Green
    } else {
        Write-Host "❌ Environment variable override failed (got: $($configWithEnv.SystemStatus.LogLevel))" -ForegroundColor Red
    }
    
    # Clean up environment variable
    Remove-Item Env:UNITYC_LOG_LEVEL -ErrorAction SilentlyContinue
    
    Write-Host "`n=== All fixes verified successfully! ===" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error during testing: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Clean up
    if (Test-Path ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json") {
        Remove-Item ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json" -ErrorAction SilentlyContinue
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU6VkXx5W4T0R2bMhPjPVjbpuZ
# b6egggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUW/uz9O4tNJCEyXCvhgCS9qOS1WcwDQYJKoZIhvcNAQEBBQAEggEAfCVO
# K4MPH3uNJXfquEHSfprM8tBsRkDU0BWs39KsO5BtwO0gaHxxG+QE7U/LYhk7MjVj
# PYUIKHXPmFpGhOq/gCWrNsMLnQxjWqgxqmR8AeVEF4oPHowvqV0hd0Yyyw3YLSBC
# S7GTOivLbMAOzXHGjpeYW8pSZ9ugswqknRObGWV2baLvVndXUdJOLVltLqWOC5Vp
# IrxOTlyRgJRi/CR3aO9DuDBiuB0c0GMZIYrdvxGs3IfU9DoYlCyf+8bm1gWaBjgp
# 6uYdLqTxU8ed/6VitEQljJYvTEv9mb2KZzasgwiADJOq4zAJnYwx0SX+Qsa/NZLT
# x+cY/0VeyDfTA5CodA==
# SIG # End signature block
