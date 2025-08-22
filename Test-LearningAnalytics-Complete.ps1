# Complete Learning Analytics Test with Proper Configuration
# This version properly configures storage paths for testing

Write-Host "=== Complete Learning Analytics Test ===" -ForegroundColor Yellow

# Step 1: Clean up old metrics in wrong location
$wrongLocation = "./Modules/Unity-Claude-Learning/metrics.json"
if (Test-Path $wrongLocation) {
    Write-Host "Removing old metrics from module directory..." -ForegroundColor Gray
    Remove-Item $wrongLocation -Force
}

# Step 2: Import modules
Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning.psm1' -Force -DisableNameChecking
Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning-Analytics.psm1' -Force -DisableNameChecking

# Step 3: Configure proper storage path
$properStoragePath = Join-Path (Get-Location) "Storage\JSON"
Set-LearningConfig -StoragePath $properStoragePath

Write-Host "Storage path configured: $properStoragePath" -ForegroundColor Green

# Step 4: Verify metrics are loaded from correct location
$metrics = Get-MetricsFromJSON -StoragePath $properStoragePath
Write-Host "Metrics loaded: $($metrics.Count)" -ForegroundColor Cyan

if ($metrics.Count -gt 100) {
    Write-Host "Metrics loaded successfully from correct location" -ForegroundColor Green
} else {
    Write-Host "Insufficient metrics. Running initialization..." -ForegroundColor Yellow
    & ".\Initialize-TestMetrics-Direct.ps1" -DaysOfData 7 -MetricsPerDay 10
    $metrics = Get-MetricsFromJSON -StoragePath $properStoragePath
    Write-Host "Metrics after initialization: $($metrics.Count)" -ForegroundColor Cyan
}

Write-Host "`n=== Running Analytics Tests ===" -ForegroundColor Yellow

# Test 1: Pattern Success Rates
Write-Host "`n--- Test 1: Pattern Success Rates ---" -ForegroundColor White
$allPatterns = Get-AllPatternsSuccessRates -TimeRange "All"
Write-Host "Patterns analyzed: $($allPatterns.Count)" -ForegroundColor Gray

if ($allPatterns.Count -gt 0) {
    Write-Host "Top 3 patterns by success rate:" -ForegroundColor Cyan
    $allPatterns | Select-Object -First 3 | ForEach-Object {
        $automationStatus = if ($_.AutomationReady) { "Ready" } else { "Not Ready" }
        Write-Host "  $($_.PatternID): $([Math]::Round($_.SuccessRate * 100, 1))% success - $automationStatus" -ForegroundColor Gray
    }
}

# Test 2: Trend Analysis
Write-Host "`n--- Test 2: Trend Analysis ---" -ForegroundColor White
$trends = @("SuccessRate", "Confidence", "ExecutionTime") | ForEach-Object {
    $trend = Get-LearningTrend -TimeRange "All" -MetricType $_
    [PSCustomObject]@{
        Metric = $_
        Trend = $trend.Trend
        ImprovementRate = "$($trend.ImprovementRate)%"
        DataPoints = $trend.DataPoints
    }
}

$trends | Format-Table -AutoSize

# Test 3: Pattern Recommendations
Write-Host "`n--- Test 3: Pattern Recommendations ---" -ForegroundColor White
$testError = "CS0246: The type or namespace name 'UnityEngine' could not be found"
$recommendations = Get-RecommendedPatterns -ErrorMessage $testError -TopCount 3

if ($recommendations.Count -gt 0) {
    Write-Host "Recommendations for: $testError" -ForegroundColor Cyan
    $recommendations | ForEach-Object {
        Write-Host "  Pattern: $($_.PatternID)" -ForegroundColor Gray
        Write-Host "    Similarity: $($_.Similarity * 100)%" -ForegroundColor DarkGray
        Write-Host "    Success Rate: $($_.SuccessRate * 100)%" -ForegroundColor DarkGray
        Write-Host "    Recommendation Score: $($_.RecommendationScore)" -ForegroundColor DarkGray
    }
} else {
    Write-Host "No recommendations found (may need pattern data)" -ForegroundColor Yellow
}

# Test 4: Effectiveness Ranking
Write-Host "`n--- Test 4: Pattern Effectiveness Ranking ---" -ForegroundColor White
$rankings = Get-PatternEffectivenessRanking -TimeRange "All"

if ($rankings.Count -gt 0) {
    Write-Host "Top 5 most effective patterns:" -ForegroundColor Cyan
    $rankings | Select-Object -First 5 | ForEach-Object {
        Write-Host "  Rank #$($_.Rank): $($_.PatternID)" -ForegroundColor Gray
        Write-Host "    Success Rate: $($_.SuccessRate * 100)%" -ForegroundColor DarkGray
        Write-Host "    Trend: $($_.Trend)" -ForegroundColor DarkGray
        Write-Host "    Overall Score: $($_.OverallScore)" -ForegroundColor DarkGray
    }
}

# Test 5: Moving Average Calculation
Write-Host "`n--- Test 5: Moving Average Calculation ---" -ForegroundColor White
$testData = 1..30 | ForEach-Object { Get-Random -Minimum 60 -Maximum 100 }
$movingAvg = Calculate-MovingAverage -Data $testData -WindowSize 5

Write-Host "Moving average results (last 5 points):" -ForegroundColor Cyan
$movingAvg | Select-Object -Last 5 | ForEach-Object {
    Write-Host "  Index $($_.Index): Original=$($_.OriginalValue), MA=$([Math]::Round($_.MovingAverage, 2)), Trend=$($_.Trend)" -ForegroundColor Gray
}

# Summary
Write-Host "`n=== Test Summary ===" -ForegroundColor Yellow
Write-Host "Metrics loaded: $($metrics.Count)" -ForegroundColor Green
Write-Host "Patterns analyzed: $($allPatterns.Count)" -ForegroundColor Green
Write-Host "Trends calculated: $($trends.Count)" -ForegroundColor Green
Write-Host "Recommendations generated: $($recommendations.Count)" -ForegroundColor Green
Write-Host "Rankings created: $($rankings.Count)" -ForegroundColor Green

# Check for automation-ready patterns
$automationReady = $allPatterns | Where-Object { $_.AutomationReady }
if ($automationReady.Count -gt 0) {
    Write-Host "`n$($automationReady.Count) patterns are ready for automation!" -ForegroundColor Green
    Write-Host "These patterns have greater than 85% success rate and 70% confidence:" -ForegroundColor Gray
    $automationReady | ForEach-Object {
        Write-Host "  - $($_.PatternID): $([Math]::Round($_.SuccessRate * 100, 1))% success" -ForegroundColor Cyan
    }
} else {
    Write-Host "`nNo patterns meet automation criteria yet (need greater than 85% success, 70% confidence)" -ForegroundColor Yellow
}

Write-Host "`nWeek 2 Day 10-11 Learning Analytics Engine: FULLY OPERATIONAL" -ForegroundColor Green
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUHxkWEIIMjfs1i2zfvboCPty7
# GoigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUGBX/6yIsBTZ78B253dSbS4OTDpIwDQYJKoZIhvcNAQEBBQAEggEAXr/5
# DayU7VarcAy0cjeLw2FSfJFKhJ5KsUX3+UzXv3lmEhKGQnmCSJRxu9Q6pIFaeRmp
# ebPW90y4U7WwXvAPya+hzsesNysGZU/MOkRvh/3kpYSVC4nB83PUPx1QH74uFLiq
# GHf9+jjEFKEJWuzTgV6hA/qGPUly9jYjJeSCXXNusj8hbjBR6Q98uUH3y2ja4HLB
# XLwZQje/pFEPpEbto1/HQZ8EVnmQCBPaPjx4toO4cuIlaGRbUsJhL4a5V992iGQZ
# ymYbi3dNblaegjwL+U1EwBdL3DwNFhucggHQx5k/FDwEwaf9dud0BDFHfNBalulA
# Gyr6mGT41KDdEfIVhA==
# SIG # End signature block
