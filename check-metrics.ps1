Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning.psm1' -Force -DisableNameChecking

Write-Host "Checking metrics storage..." -ForegroundColor Yellow

# Load metrics using the module function
$metrics = Get-MetricsFromJSON
Write-Host "Total metrics loaded via Get-MetricsFromJSON: $($metrics.Count)" -ForegroundColor Cyan

# Check direct file access
$metricsFile = "./Storage/JSON/metrics.json"
if (Test-Path $metricsFile) {
    $directMetrics = Get-Content $metricsFile -Raw | ConvertFrom-Json
    if ($directMetrics -is [array]) {
        Write-Host "Total metrics in JSON file: $($directMetrics.Count)" -ForegroundColor Green
    } else {
        Write-Host "Metrics file exists but format unexpected" -ForegroundColor Yellow
    }
    
    # Check date ranges
    $dates = $directMetrics | ForEach-Object { [DateTime]::Parse($_.Timestamp) }
    $minDate = ($dates | Measure-Object -Minimum).Minimum
    $maxDate = ($dates | Measure-Object -Maximum).Maximum
    
    Write-Host "Date range: $($minDate.ToString('yyyy-MM-dd')) to $($maxDate.ToString('yyyy-MM-dd'))" -ForegroundColor Gray
    
    # Check pattern distribution
    $patternGroups = $directMetrics | Group-Object PatternID
    Write-Host "`nPattern distribution:" -ForegroundColor Yellow
    $patternGroups | ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count) metrics" -ForegroundColor Gray
    }
} else {
    Write-Host "Metrics file not found at: $metricsFile" -ForegroundColor Red
}

# Import analytics module too
Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning-Analytics.psm1' -Force -DisableNameChecking

# Test the analytics functions with the new data
Write-Host "`nTesting analytics functions with new data..." -ForegroundColor Yellow
$allPatterns = Get-AllPatternsSuccessRates -TimeRange "All"
Write-Host "Patterns with success rates: $($allPatterns.Count)" -ForegroundColor Cyan

if ($allPatterns.Count -gt 0) {
    Write-Host "Top 3 patterns by success rate:" -ForegroundColor Gray
    $allPatterns | Select-Object -First 3 | ForEach-Object {
        Write-Host "  $($_.PatternID): $([Math]::Round($_.SuccessRate * 100, 1))% success" -ForegroundColor Cyan
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUzQjAKK4gTYPcbEMLWUe2NXIr
# 9fugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUSXm7/6ZyxuLS2VqSDPfRVgjLzyowDQYJKoZIhvcNAQEBBQAEggEAMwj5
# m/eDnjd6dQNx7fVxqsYhBTJfQPudmtzCtMz5DH8x8pggVtYHDBTbvtUR4/F4odP5
# XwCIPbrgIt0h4XjF3DGjCXjFevXuJg/iQtz7Zc0LOBrzTWSjSg0KO6KG9XkS+Yx1
# 6FUbMkw87RgXVv6sL1uA7An17RxgfO/6o4OB4a15ru5tVXXo6cv/o8mavGA9oMnL
# JvCBbKmJB0YlpIw7aA9qFOVmRhZWJb42uIm7jmtxngPhIeMFJ63stbgEqbB6MO+s
# kt36GkSWFJOat7jC64szTrs/qChx6+fMY895nsCyki0luNM2d0+JV33+wiax0tYg
# n+hCu/bo41xkbaIUGg==
# SIG # End signature block
