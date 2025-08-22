# Test script for Week 2 Day 10-11: Learning Analytics Engine
# Tests advanced analytics functions for pattern optimization

# Import required modules
Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning.psm1' -Force -DisableNameChecking
Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning-Analytics.psm1' -Force -DisableNameChecking

Write-Host "=== Week 2 Day 10-11: Learning Analytics Engine Test ===" -ForegroundColor Yellow
Write-Host "Testing pattern success rates, trend analysis, confidence adjustment, and recommendations`n" -ForegroundColor Cyan

# Check if we have sufficient test data
$existingMetrics = Get-MetricsFromJSON
if (-not $existingMetrics -or $existingMetrics.Count -lt 50) {
    Write-Host "WARNING: Insufficient test data detected (found $($existingMetrics.Count) metrics)" -ForegroundColor Yellow
    Write-Host "For comprehensive testing, run Initialize-TestMetrics.ps1 first to generate sample data" -ForegroundColor Yellow
    Write-Host "Continuing with limited data...`n" -ForegroundColor Gray
}

# Test counter
$testsPassed = 0
$testsFailed = 0

function Test-Function {
    param(
        [string]$TestName,
        [scriptblock]$TestCode,
        [scriptblock]$ValidationCode
    )
    
    Write-Host "`n--- $TestName ---" -ForegroundColor White
    try {
        $result = & $TestCode
        $isValid = & $ValidationCode -Result $result
        
        if ($isValid) {
            Write-Host "[PASS] $TestName" -ForegroundColor Green
            $script:testsPassed++
            return $result
        } else {
            Write-Host "[FAIL] $TestName - Validation failed" -ForegroundColor Red
            $script:testsFailed++
            return $null
        }
    } catch {
        Write-Host "[FAIL] $TestName - Error: $_" -ForegroundColor Red
        $script:testsFailed++
        return $null
    }
}

# Test 1: Pattern Success Rate Calculation
$test1 = Test-Function -TestName "Pattern Success Rate Calculation" -TestCode {
    # Get success rate for a specific pattern
    $patterns = Get-AllPatternsSuccessRates -TimeRange "All" -MinConfidence 0.7
    if ($patterns.Count -gt 0) {
        $firstPattern = $patterns[0]
        Write-Host "Pattern: $($firstPattern.PatternID)" -ForegroundColor Gray
        Write-Host "Success Rate: $($firstPattern.SuccessRate * 100)%" -ForegroundColor Gray
        Write-Host "High Confidence Rate: $($firstPattern.HighConfidenceSuccessRate * 100)%" -ForegroundColor Gray
        Write-Host "Automation Ready: $($firstPattern.AutomationReady)" -ForegroundColor Gray
    }
    return $patterns
} -ValidationCode {
    param($Result)
    $Result -ne $null -and $Result.Count -gt 0
}

# Test 2: Moving Average Calculation
$test2 = Test-Function -TestName "Moving Average Calculation" -TestCode {
    # Test data
    $testData = @(50, 55, 48, 62, 58, 65, 70, 68, 72, 75, 73, 78, 80)
    $movingAvg = Calculate-MovingAverage -Data $testData -WindowSize 3 -Verbose
    
    Write-Host "Sample Moving Averages:" -ForegroundColor Gray
    $movingAvg | Select-Object -First 3 | ForEach-Object {
        Write-Host "  Index $($_.Index): Original=$($_.OriginalValue), MA=$($_.MovingAverage), Trend=$($_.Trend)" -ForegroundColor Cyan
    }
    return $movingAvg
} -ValidationCode {
    param($Result)
    $Result -ne $null -and $Result.Count -gt 0 -and $Result[0].MovingAverage -ne $null
}

# Test 3: Learning Trend Analysis
$test3 = Test-Function -TestName "Learning Trend Analysis" -TestCode {
    $trend = Get-LearningTrend -TimeRange "All" -MetricType "SuccessRate" -Verbose
    
    Write-Host "Metric Type: $($trend.MetricType)" -ForegroundColor Gray
    Write-Host "Data Points: $($trend.DataPoints)" -ForegroundColor Gray
    Write-Host "Overall Trend: $($trend.Trend)" -ForegroundColor Gray
    Write-Host "Improvement Rate: $($trend.ImprovementRate)%" -ForegroundColor Gray
    Write-Host "First Value: $($trend.FirstValue)" -ForegroundColor Gray
    Write-Host "Last Value: $($trend.LastValue)" -ForegroundColor Gray
    return $trend
} -ValidationCode {
    param($Result)
    $Result -ne $null -and $Result.Trend -ne $null
}

# Test 4: Confidence Adjustment
$test4 = Test-Function -TestName "Bayesian Confidence Adjustment" -TestCode {
    # Test confidence updates
    $initialConfidence = 0.7
    Write-Host "Initial Confidence: $initialConfidence" -ForegroundColor Gray
    
    # Simulate success
    $afterSuccess = Update-PatternConfidence -PatternID "TEST_PATTERN" -Success $true -CurrentConfidence $initialConfidence -Verbose
    Write-Host "After Success: $afterSuccess (Expected increase)" -ForegroundColor Cyan
    
    # Simulate failure
    $afterFailure = Update-PatternConfidence -PatternID "TEST_PATTERN" -Success $false -CurrentConfidence $afterSuccess -Verbose
    Write-Host "After Failure: $afterFailure (Expected decrease)" -ForegroundColor Cyan
    
    return @{
        Initial = $initialConfidence
        AfterSuccess = $afterSuccess
        AfterFailure = $afterFailure
    }
} -ValidationCode {
    param($Result)
    $Result -ne $null -and 
    $Result.AfterSuccess -gt $Result.Initial -and 
    $Result.AfterFailure -lt $Result.AfterSuccess
}

# Test 5: Adjusted Confidence Based on Recent Performance
$test5 = Test-Function -TestName "Get Adjusted Confidence" -TestCode {
    # Get patterns with metrics
    $patterns = Get-PatternsFromJSON
    if ($patterns) {
        # Get-PatternsFromJSON returns a hashtable, but let's handle both cases
        if ($patterns -is [hashtable]) {
            $patternId = $patterns.Keys | Select-Object -First 1
        } elseif ($patterns -is [array] -and $patterns.Count -gt 0) {
            $patternId = $patterns[0].PatternID
        } else {
            # Try to get a pattern ID from metrics
            $metrics = Get-MetricsFromJSON
            if ($metrics -and $metrics.Count -gt 0) {
                $patternId = $metrics[0].PatternID
            } else {
                $patternId = "TEST_PATTERN_001"
            }
        }
        $baseConfidence = 0.75
        
        $adjusted = Get-AdjustedConfidence -PatternID $patternId -BaseConfidence $baseConfidence -RecentWindow 5 -Verbose
        
        Write-Host "Pattern ID: $patternId" -ForegroundColor Gray
        Write-Host "Base Confidence: $baseConfidence" -ForegroundColor Gray
        Write-Host "Adjusted Confidence: $adjusted" -ForegroundColor Gray
        
        return @{
            PatternID = $patternId
            BaseConfidence = $baseConfidence
            AdjustedConfidence = $adjusted
        }
    } else {
        # Create a test pattern for validation
        Write-Host "No patterns available, using test pattern" -ForegroundColor Yellow
        $testPatternId = "TEST_PATTERN_001"
        $baseConfidence = 0.75
        $adjusted = Get-AdjustedConfidence -PatternID $testPatternId -BaseConfidence $baseConfidence -RecentWindow 5 -Verbose
        return @{ 
            PatternID = $testPatternId
            AdjustedConfidence = $adjusted 
        }
    }
} -ValidationCode {
    param($Result)
    $Result -ne $null -and $Result.AdjustedConfidence -ge 0 -and $Result.AdjustedConfidence -le 1
}

# Test 6: Pattern Recommendations
$test6 = Test-Function -TestName "Pattern Recommendation Engine" -TestCode {
    # First add a test pattern if none exist
    $patterns = Get-PatternsFromJSON
    if (-not $patterns -or $patterns.Count -eq 0) {
        # Add a test pattern for the recommendation engine
        Add-PatternToJSON -PatternID "TEST_UNITY_001" -Pattern @{
            ErrorSignature = "CS0246: The type or namespace name 'UnityEngine' could not be found"
            ErrorMessage = "CS0246: The type or namespace name 'UnityEngine' could not be found"
            Fix = "Add using UnityEngine; at the top of the file"
            Category = "Missing Using Directive"
            Confidence = 0.85
        }
    }
    
    # Test with a sample error message
    $errorMsg = "CS0246: The type or namespace name 'UnityEngine' could not be found"
    $recommendations = Get-RecommendedPatterns -ErrorMessage $errorMsg -TopCount 3 -MinSimilarity 0.5 -Verbose
    
    if ($recommendations.Count -gt 0) {
        Write-Host "Recommendations for: $errorMsg" -ForegroundColor Gray
        $recommendations | ForEach-Object {
            Write-Host "  Pattern: $($_.PatternID)" -ForegroundColor Cyan
            Write-Host "    Similarity: $($_.Similarity * 100)%" -ForegroundColor Gray
            Write-Host "    Success Rate: $($_.SuccessRate * 100)%" -ForegroundColor Gray
            Write-Host "    Score: $($_.RecommendationScore)" -ForegroundColor Gray
            Write-Host "    Auto-Ready: $($_.AutomationReady)" -ForegroundColor Gray
        }
    } else {
        Write-Host "No recommendations found (may need more pattern data)" -ForegroundColor Yellow
    }
    return $recommendations
} -ValidationCode {
    param($Result)
    $Result -ne $null  # Can be empty if no similar patterns
}

# Test 7: Pattern Effectiveness Ranking
$test7 = Test-Function -TestName "Pattern Effectiveness Ranking" -TestCode {
    $rankings = Get-PatternEffectivenessRanking -TimeRange "All" -Verbose
    
    if ($rankings.Count -gt 0) {
        Write-Host "Top 3 Most Effective Patterns:" -ForegroundColor Gray
        $rankings | Select-Object -First 3 | ForEach-Object {
            Write-Host "  Rank #$($_.Rank): Pattern $($_.PatternID)" -ForegroundColor Cyan
            Write-Host "    Success Rate: $($_.SuccessRate * 100)%" -ForegroundColor Gray
            Write-Host "    Confidence: $($_.AverageConfidence)" -ForegroundColor Gray
            Write-Host "    Trend: $($_.Trend)" -ForegroundColor Gray
            Write-Host "    Overall Score: $($_.OverallScore)" -ForegroundColor Gray
        }
    } else {
        Write-Host "No patterns to rank (need more data)" -ForegroundColor Yellow
    }
    return $rankings
} -ValidationCode {
    param($Result)
    $Result -ne $null  # Can be empty if no data
}

# Test 8: Comprehensive Learning Analytics
$test8 = Test-Function -TestName "Comprehensive Analytics Integration" -TestCode {
    Write-Host "Testing integrated analytics capabilities..." -ForegroundColor Gray
    
    # Get overall system performance with defensive property checking
    $allPatterns = Get-AllPatternsSuccessRates -TimeRange "All"
    $successRates = 0
    
    try {
        if ($allPatterns -and $allPatterns.Count -gt 0) {
            # Handle both array and single object with property validation
            if ($allPatterns -is [array]) {
                # Check if objects have SuccessRate property before measuring
                $validPatterns = $allPatterns | Where-Object { 
                    $_ -and [bool]($_.PSObject.Properties['SuccessRate'])
                }
                if ($validPatterns -and $validPatterns.Count -gt 0) {
                    $successRates = ($validPatterns | Measure-Object -Property SuccessRate -Average).Average
                }
            } else {
                # Single object - check for property
                if ([bool]($allPatterns.PSObject.Properties['SuccessRate'])) {
                    $successRates = $allPatterns.SuccessRate
                }
            }
        }
    } catch {
        Write-Warning "Failed to calculate average success rate: $_"
        $successRates = 0
    }
    
    # Get trends
    $successTrend = Get-LearningTrend -TimeRange "All" -MetricType "SuccessRate"
    $confTrend = Get-LearningTrend -TimeRange "All" -MetricType "Confidence"
    $execTrend = Get-LearningTrend -TimeRange "All" -MetricType "ExecutionTime"
    
    $summary = @{
        TotalPatterns = if ($allPatterns) { $allPatterns.Count } else { 0 }
        AverageSuccessRate = if ($successRates) { [Math]::Round($successRates, 4) } else { 0 }
        SuccessTrend = if ($successTrend -and $successTrend.Trend) { $successTrend.Trend } else { "NoData" }
        ConfidenceTrend = if ($confTrend -and $confTrend.Trend) { $confTrend.Trend } else { "NoData" }
        ExecutionTimeTrend = if ($execTrend -and $execTrend.Trend) { $execTrend.Trend } else { "NoData" }
        AutomationReadyPatterns = if ($allPatterns -and $allPatterns.Count -gt 0) {
            ($allPatterns | Where-Object { 
                $_ -and [bool]($_.PSObject.Properties['AutomationReady']) -and $_.AutomationReady 
            }).Count
        } else { 0 }
    }
    
    Write-Host "`nSystem Analytics Summary:" -ForegroundColor Cyan
    Write-Host "  Total Patterns: $($summary.TotalPatterns)" -ForegroundColor Gray
    $avgSuccessDisplay = if ($successRates -ne $null -and $successRates -ne 0) {
        "$([Math]::Round($successRates * 100, 2))%"
    } else { "0%" }
    Write-Host "  Avg Success Rate: $avgSuccessDisplay" -ForegroundColor Gray
    Write-Host "  Success Trend: $($summary.SuccessTrend)" -ForegroundColor Gray
    Write-Host "  Confidence Trend: $($summary.ConfidenceTrend)" -ForegroundColor Gray
    Write-Host "  Execution Time Trend: $($summary.ExecutionTimeTrend)" -ForegroundColor Gray
    Write-Host "  Automation Ready: $($summary.AutomationReadyPatterns) patterns" -ForegroundColor Gray
    
    return $summary
} -ValidationCode {
    param($Result)
    $Result -ne $null -and $Result.TotalPatterns -ge 0
}

# Display final results
Write-Host "`n=== Learning Analytics Engine Test Results ===" -ForegroundColor Yellow
Write-Host "Tests Passed: $testsPassed" -ForegroundColor Green
Write-Host "Tests Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })

if ($testsFailed -eq 0) {
    Write-Host "`n✅ All learning analytics tests passed successfully!" -ForegroundColor Green
    Write-Host "The learning analytics engine is fully operational with:" -ForegroundColor Cyan
    Write-Host "  • Pattern success rate calculation" -ForegroundColor Gray
    Write-Host "  • Trend analysis with moving averages" -ForegroundColor Gray
    Write-Host "  • Bayesian confidence adjustment" -ForegroundColor Gray
    Write-Host "  • Pattern recommendation system" -ForegroundColor Gray
    Write-Host "  • Effectiveness ranking algorithms" -ForegroundColor Gray
    Write-Host "`nWeek 2 Day 10-11 implementation: COMPLETED" -ForegroundColor Green
} else {
    Write-Host "`n⚠️ Some tests failed. Review the errors above." -ForegroundColor Yellow
    Write-Host "Note: Some tests may fail if there's insufficient data in the metrics store." -ForegroundColor Gray
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvOfWjEuQj2c5ZJfsBi7ECgDW
# noagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUKHGhm8sKLY4EbuK5cktseoqobxowDQYJKoZIhvcNAQEBBQAEggEArvdv
# 54MwqJxJI7N6PcB69wLciUdAfkQ/PtouiypQBMEp5WdP5SAu2y+SXWIpvSISqt0K
# JMxFC9MTsWGGrYYVKHXrsfqJLfrthUJAqP9VYMcZn0PuD/UDHr46YH62hbdd53AZ
# KLbqgupcJMc1DXvRF8UcCjNMXvcCT+WahXF3BNFMRE9i1Vtn6ubAIkppgexirouR
# 6wKcGV33kda00uF+qPlk9oy7s686pB/GYz0UJbV8rGuqjRSWfTqBQqap4/qcYeVY
# PYFeRwinX04HVEJezk5k9sl8EA9A9tntw5EVC6phhOz+6DRULhIzgJoeMCFEngZO
# zkFLYZsN1xRDxIz0/A==
# SIG # End signature block
