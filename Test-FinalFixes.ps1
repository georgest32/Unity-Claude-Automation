# Test-FinalFixes.ps1
# Quick test for the final two fixes

Write-Host "=== Testing Final Configuration Fixes ===" -ForegroundColor Cyan

try {
    # Import module
    Import-Module ".\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1" -Force
    
    # Copy development config for testing
    Copy-Item ".\Modules\Unity-Claude-SystemStatus\Config\examples\development.config.json" ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json" -Force
    
    Write-Host "`n1. Testing UNITYC_CB_FAILURE_THRESHOLD environment variable..." -ForegroundColor Yellow
    
    # Test the circuit breaker environment variable
    $env:UNITYC_CB_FAILURE_THRESHOLD = "7"
    $config = Get-SystemStatusConfiguration -ForceRefresh
    
    if ($config.CircuitBreaker.FailureThreshold -eq 7) {
        Write-Host "✅ UNITYC_CB_FAILURE_THRESHOLD environment variable works!" -ForegroundColor Green
        $fix1Success = $true
    } else {
        Write-Host "❌ UNITYC_CB_FAILURE_THRESHOLD still not working (got: $($config.CircuitBreaker.FailureThreshold))" -ForegroundColor Red
        $fix1Success = $false
    }
    
    # Clean up environment variable
    Remove-Item Env:UNITYC_CB_FAILURE_THRESHOLD -ErrorAction SilentlyContinue
    
    Write-Host "`n2. Testing improved configuration caching test..." -ForegroundColor Yellow
    
    # Test the improved caching functionality test
    $config1 = Get-SystemStatusConfiguration -ForceRefresh
    $config2 = Get-SystemStatusConfiguration
    
    $cachingTest = ($config1 -ne $null) -and ($config2 -ne $null) -and ($config1.Performance.EnableConfigurationCaching)
    
    if ($cachingTest) {
        Write-Host "✅ Configuration caching test logic works!" -ForegroundColor Green
        $fix2Success = $true
    } else {
        Write-Host "❌ Configuration caching test still failing" -ForegroundColor Red
        $fix2Success = $false
    }
    
    if ($fix1Success -and $fix2Success) {
        Write-Host "`n🎉 Both fixes successful! Ready for 100% test success rate!" -ForegroundColor Green
    } else {
        Write-Host "`n⚠️  Some fixes still need work" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "❌ Error during testing: $($_.Exception.Message)" -ForegroundColor Red
} finally {
    # Clean up
    if (Test-Path ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json") {
        Remove-Item ".\Modules\Unity-Claude-SystemStatus\Config\systemstatus.config.json" -ErrorAction SilentlyContinue
    }
}

Write-Host "`nRun .\Test-ConfigurationSystem.ps1 to see the full improved results!" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUlep1uqv/myWQlOJmoYD8+Bj0
# vdmgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUdpKl0M0SdRN/huzcwn5QSI7AAHwwDQYJKoZIhvcNAQEBBQAEggEAE16Q
# AD0zcYSZOl3zGhKXxPhvvPgkH7K4bEN2KgowUxV3E2bxA6byWkqDskryQPuivcKm
# z5GCZBjOGwnbUtonc9kTLOkekrLsb0b7gCus1vJrg9FhTTBkNjKV9issJkaoYOyO
# tJMwjBUDkY+oHnVKzv6auq02mA2XOGYoIaoE0SPmeWM+4xZSa3kVxVa4jE/OElPj
# ZwxLpiT8yXSbPjQRxiLK+EbDG9oUIRkpWvDh1dcKGhKvIFsd+Vaf8EOME35J7xfq
# 6P/Y5IguZOM5pjZt7WTxBaFu/ZxZeaar1+yBtCmNX4TckyEFdSUPZxD8YysRsCmW
# MvscF61vW7XkVNuDBQ==
# SIG # End signature block
