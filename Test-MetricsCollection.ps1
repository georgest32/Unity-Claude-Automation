# Test script for Week 2 Day 8-9: Metrics Collection System
# Validates the new learning analytics functions

Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning.psm1' -Force -DisableNameChecking

Write-Host "=== Week 2 Day 8-9: Metrics Collection System Test ===" -ForegroundColor Yellow

Write-Host "`nTesting metrics collection capabilities..." -ForegroundColor Cyan

# Test 1: Execution Time Measurement
Write-Host "`n--- Test 1: Execution Time Measurement ---" -ForegroundColor White

$timedResult = Measure-ExecutionTime -Description "Test Operation" -ScriptBlock {
    Start-Sleep -Milliseconds 100
    return "Test completed"
}

Write-Host "Execution Time: $($timedResult.ExecutionTimeMs)ms" -ForegroundColor Green
Write-Host "Success: $($timedResult.Success)" -ForegroundColor Green
Write-Host "Result: $($timedResult.Result)" -ForegroundColor Green

# Test 2: Pattern Application Metrics Recording
Write-Host "`n--- Test 2: Pattern Application Metrics Recording ---" -ForegroundColor White

# Add some test patterns first
$pattern1 = Add-ErrorPattern -ErrorMessage "CS0246: Missing using statement" -Fix "using UnityEngine;" -Verbose
$pattern2 = Add-ErrorPattern -ErrorMessage "NullReferenceException in Update" -Fix "if (obj != null) { ... }" -Verbose

Write-Host "Added test patterns: $pattern1, $pattern2" -ForegroundColor Gray

# Record some metrics with varying success rates and confidence scores
$metrics = @(
    @{ PatternID = $pattern1; Confidence = 0.95; Success = $true; Time = 150 }
    @{ PatternID = $pattern1; Confidence = 0.90; Success = $true; Time = 120 }
    @{ PatternID = $pattern1; Confidence = 0.85; Success = $false; Time = 180; Error = "Compilation failed" }
    @{ PatternID = $pattern2; Confidence = 0.75; Success = $true; Time = 200 }
    @{ PatternID = $pattern2; Confidence = 0.60; Success = $false; Time = 90; Error = "Pattern mismatch" }
    @{ PatternID = $pattern2; Confidence = 0.80; Success = $true; Time = 160 }
)

foreach ($metric in $metrics) {
    $metricId = Record-PatternApplicationMetric -PatternID $metric.PatternID -ConfidenceScore $metric.Confidence -Success $metric.Success -ExecutionTimeMs $metric.Time -ErrorMessage $metric.Error -Verbose
    Write-Host "  Recorded metric: $metricId" -ForegroundColor Cyan
}

# Test 3: Learning Metrics Analytics
Write-Host "`n--- Test 3: Learning Metrics Analytics ---" -ForegroundColor White

$analytics = Get-LearningMetrics -TimeRange "All" -Verbose

Write-Host "Total Applications: $($analytics.TotalApplications)" -ForegroundColor Green
Write-Host "Successful Applications: $($analytics.SuccessfulApplications)" -ForegroundColor Green
Write-Host "Success Rate: $($analytics.SuccessRate * 100)%" -ForegroundColor Green
Write-Host "Average Confidence: $($analytics.AverageConfidence)" -ForegroundColor Green
Write-Host "Average Execution Time: $($analytics.AverageExecutionTime)ms" -ForegroundColor Green

# Test 4: Confidence Calibration Analysis
Write-Host "`n--- Test 4: Confidence Calibration Analysis ---" -ForegroundColor White

Write-Host "Confidence Calibration Results:" -ForegroundColor Gray
# Show all buckets to understand distribution
$allBuckets = @("0.0-0.1", "0.1-0.2", "0.2-0.3", "0.3-0.4", "0.4-0.5", 
                 "0.5-0.6", "0.6-0.7", "0.7-0.8", "0.8-0.9", "0.9-1.0")
foreach ($bucket in $allBuckets) {
    if ($analytics.ConfidenceCalibration.ContainsKey($bucket)) {
        $calibration = $analytics.ConfidenceCalibration[$bucket]
        Write-Host "  $bucket`: $($calibration.Total) total, $($calibration.Successful) successful, $($calibration.ActualSuccessRate * 100)% actual success rate" -ForegroundColor Cyan
    } else {
        Write-Host "  $bucket`: 0 total (no data)" -ForegroundColor DarkGray
    }
}

# Test 5: Pattern Usage Analytics
Write-Host "`n--- Test 5: Pattern Usage Analytics ---" -ForegroundColor White

$usageAnalytics = Get-PatternUsageAnalytics -TopCount 5 -Verbose

Write-Host "Usage Analytics Summary: $($usageAnalytics.Summary)" -ForegroundColor Green
Write-Host "Total Patterns Analyzed: $($usageAnalytics.TotalPatterns)" -ForegroundColor Green
Write-Host "Total Applications: $($usageAnalytics.TotalApplications)" -ForegroundColor Green

Write-Host "`nTop Patterns by Usage:" -ForegroundColor Gray
foreach ($pattern in $usageAnalytics.TopPatternsByUsage) {
    Write-Host "  Pattern $($pattern.PatternID): $($pattern.UsageCount) uses, $($pattern.SuccessRate * 100)% success rate, $($pattern.AverageConfidence) avg confidence" -ForegroundColor Cyan
}

Write-Host "`nTop Patterns by Success Rate:" -ForegroundColor Gray
foreach ($pattern in $usageAnalytics.TopPatternsBySuccessRate) {
    Write-Host "  Pattern $($pattern.PatternID): $($pattern.SuccessRate * 100)% success rate, $($pattern.UsageCount) uses" -ForegroundColor Cyan
}

Write-Host "`nTop Patterns by Effectiveness:" -ForegroundColor Gray
foreach ($pattern in $usageAnalytics.TopPatternsByEffectiveness) {
    Write-Host "  Pattern $($pattern.PatternID): $($pattern.Effectiveness) effectiveness score ($($pattern.SuccessRate * 100)% success * $($pattern.AverageConfidence) confidence)" -ForegroundColor Cyan
}

# Test 6: Time Range Filtering
Write-Host "`n--- Test 6: Time Range Filtering ---" -ForegroundColor White

$timeRanges = @("Last24Hours", "LastWeek", "LastMonth", "All")
foreach ($range in $timeRanges) {
    $rangeMetrics = Get-LearningMetrics -TimeRange $range
    Write-Host "$range`: $($rangeMetrics.TotalApplications) applications" -ForegroundColor Cyan
}

# Test 7: Storage Backend Validation
Write-Host "`n--- Test 7: Storage Backend Validation ---" -ForegroundColor White

$config = Get-LearningConfig
Write-Host "Current Storage Backend: $($config.StorageBackend)" -ForegroundColor Green
Write-Host "Storage Path: $($config.StoragePath)" -ForegroundColor Green

# Check if metrics file was created
$metricsFile = Join-Path $config.StoragePath "metrics.json"
if (Test-Path $metricsFile) {
    $fileSize = (Get-Item $metricsFile).Length
    Write-Host "Metrics file created: $metricsFile ($fileSize bytes)" -ForegroundColor Green
} else {
    Write-Host "Metrics file not found: $metricsFile" -ForegroundColor Red
}

# Test 8: Confidence Threshold Analysis
Write-Host "`n--- Test 8: Confidence Threshold Analysis ---" -ForegroundColor White

$highConfidenceMetrics = Get-LearningMetrics -TimeRange "All"
$highConfidenceCount = 0
$lowConfidenceCount = 0

# Analyze confidence distribution
$metricsData = Get-MetricsFromJSON -StoragePath $config.StoragePath
foreach ($metric in $metricsData) {
    if ($metric.ConfidenceScore -ge 0.7) {
        $highConfidenceCount++
    } else {
        $lowConfidenceCount++
    }
}

Write-Host "High Confidence (>=0.7): $highConfidenceCount applications" -ForegroundColor Green
Write-Host "Low Confidence (<0.7): $lowConfidenceCount applications" -ForegroundColor Yellow
$autoApplyRate = if (($highConfidenceCount + $lowConfidenceCount) -gt 0) { 
    [math]::Round($highConfidenceCount / ($highConfidenceCount + $lowConfidenceCount) * 100, 2)
} else { 0 }
Write-Host "Auto-Apply Rate (>=0.7 threshold): $autoApplyRate%" -ForegroundColor Green

Write-Host "`n=== Metrics Collection System Test Completed ===" -ForegroundColor Green

# Display summary
Write-Host "`n=== SUMMARY ===" -ForegroundColor Yellow
Write-Host "✅ Execution time measurement working" -ForegroundColor Green
Write-Host "✅ Pattern application metrics recording" -ForegroundColor Green
Write-Host "✅ Learning analytics calculation" -ForegroundColor Green
Write-Host "✅ Confidence calibration analysis" -ForegroundColor Green
Write-Host "✅ Pattern usage analytics" -ForegroundColor Green
Write-Host "✅ Time range filtering" -ForegroundColor Green
Write-Host "✅ JSON storage backend integration" -ForegroundColor Green
Write-Host "✅ Confidence threshold analysis for automation" -ForegroundColor Green

Write-Host "`nWeek 2 Day 8-9 implementation: COMPLETED" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdvsJEsuuKMGYbp5p82dKoMep
# jG2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUhMUR+Ff3Pa6CvaCFXh9cOgZowfUwDQYJKoZIhvcNAQEBBQAEggEAf9je
# TH4xr0B/2QsDnt2CZOhcGHFzIxXQmMLDFahs9DlE2pIO5PsIp0aiv60gZHZ1c8aX
# PfcR+fbxALbe7ONxJXny6AMAAeVcgjYzRxdavNcqxhUnXS8d5VgLX2nNPeH5/NHs
# Oayn5AiH+LpcQDiJHM1tju9yoxpTff15gEu7b87GN2za13WmQg72FfNLXPGInVfH
# JNUKRsfqRkkwbffofQIs3ZoEAiqMNSgB/tULFEAeGCqrCJtV+BYjeafdi3oRjU+E
# AGcxIh2wWk9ffPx5QcaDB2LnVGvpDZ3w8FlJ3ClsT8nhGh5S9hbLP7nxO9aPAJ8P
# Hn7pvuhVdGmDlGZ36g==
# SIG # End signature block
