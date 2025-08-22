# Force reload modules and test
Remove-Module Unity-Claude-Learning -Force -ErrorAction SilentlyContinue
Remove-Module Unity-Claude-Learning-Analytics -Force -ErrorAction SilentlyContinue

Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning.psm1' -Force -DisableNameChecking
Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning-Analytics.psm1' -Force -DisableNameChecking

Write-Host "Modules reloaded" -ForegroundColor Green

$metrics = Get-MetricsFromJSON
Write-Host "Metrics loaded via Get-MetricsFromJSON: $($metrics.Count)" -ForegroundColor Yellow

# Check file directly
$metricsFile = "./Storage/JSON/metrics.json"
if (Test-Path $metricsFile) {
    $content = Get-Content $metricsFile -Raw
    $directMetrics = $content | ConvertFrom-Json
    
    if ($directMetrics -is [array]) {
        Write-Host "Direct file load (array): $($directMetrics.Count) metrics" -ForegroundColor Cyan
    } else {
        Write-Host "Direct file load (object): $($directMetrics.PSObject.Properties.Count) properties" -ForegroundColor Cyan
    }
    
    # Save first 5 lines to see format
    Write-Host "`nFirst few lines of metrics.json:" -ForegroundColor Gray
    $content.Substring(0, [Math]::Min(500, $content.Length))
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUSNRAEcy0UVa5CF3VCMZKcMFR
# TzKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUBcBh3fM6fzfYmCct8PoSWhiXSQQwDQYJKoZIhvcNAQEBBQAEggEAlSvj
# Qz3QdnwrpQ6cEEQR2W+Pzx30AcCYKX5vVptefijAVS4ltDx9ZG8tNtchmrHVPwG0
# x623Prpy7P/LE2GiR/1gcsdaDTQuyrA4re76iOO42XAmAjLSWFb+P5WHoqMgZSU7
# VJ7ZDg8zQDLT3ybc6Iz9+lyjBp9hHZr0mxVBQEhe3+wSFbZDid8wE9Jv9PwqtJHT
# Hsokqh/bSY24bIf9vSyvdqVu2Nm7d5G6spBMZ5hQ8pS2aKsbKmRf5hUAh5FUdjz1
# edvtUGm3KWFEkVGSe8fCiLPhzbJRMa48zKfnvfpjQ0Ne9anl0gRJHoxrdHAKlJgp
# xkHNXamF50qRy4HMzw==
# SIG # End signature block
