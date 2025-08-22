# Initialize Test Metrics with Direct JSON Manipulation
# Generates sample metrics data for realistic testing of analytics functions
# This version directly manipulates the metrics.json file to include historical timestamps

param(
    [int]$DaysOfData = 30,
    [double]$BaseSuccessRate = 0.75,
    [int]$MetricsPerDay = 5
)

# Import required module
Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning.psm1' -Force -DisableNameChecking

Write-Host "=== Initializing Test Metrics Data (Direct Method) ===" -ForegroundColor Yellow
Write-Host "Generating $DaysOfData days of metrics with $MetricsPerDay metrics per day" -ForegroundColor Cyan

function Generate-RandomBoolean {
    param([double]$Probability = 50)
    return (Get-Random -Maximum 100) -lt $Probability
}

try {
    # Ensure storage directory exists
    $storagePath = "./Storage/JSON"
    if (-not (Test-Path $storagePath)) {
        New-Item -ItemType Directory -Path $storagePath -Force | Out-Null
    }
    
    $metricsFile = Join-Path $storagePath "metrics.json"
    
    # Load existing metrics or create new
    $existingMetrics = @()
    if (Test-Path $metricsFile) {
        $content = Get-Content $metricsFile -Raw
        if ($content) {
            $existingMetrics = $content | ConvertFrom-Json
            if ($existingMetrics -isnot [array]) {
                $existingMetrics = @($existingMetrics)
            }
        }
    }
    
    Write-Host "Found $($existingMetrics.Count) existing metrics" -ForegroundColor Gray
    
    # Create test patterns
    $testPatterns = @(
        @{
            ID = "CS0246_UNITY"
            Name = "Missing UnityEngine namespace"
            BaseSuccess = 0.90
            BaseConfidence = 0.85
        },
        @{
            ID = "CS0103_VAR"
            Name = "Undeclared variable"
            BaseSuccess = 0.75
            BaseConfidence = 0.80
        },
        @{
            ID = "CS1061_METHOD"
            Name = "Missing method definition"
            BaseSuccess = 0.70
            BaseConfidence = 0.75
        },
        @{
            ID = "CS0029_CONVERT"
            Name = "Type conversion error"
            BaseSuccess = 0.65
            BaseConfidence = 0.70
        },
        @{
            ID = "NULL_REF"
            Name = "Null reference exception"
            BaseSuccess = 0.80
            BaseConfidence = 0.82
        }
    )
    
    Write-Host "`nGenerating historical metrics..." -ForegroundColor Cyan
    
    $newMetrics = @()
    $startDate = (Get-Date).AddDays(-$DaysOfData)
    
    foreach ($pattern in $testPatterns) {
        Write-Host "  Processing pattern: $($pattern.ID) - $($pattern.Name)" -ForegroundColor Gray
        
        for ($day = 0; $day -lt $DaysOfData; $day++) {
            $dayProgress = $day / $DaysOfData
            $currentDate = $startDate.AddDays($day)
            
            # Add learning effect - improvement over time
            $learningBonus = $dayProgress * 0.1
            
            for ($metric = 0; $metric -lt $MetricsPerDay; $metric++) {
                # Randomize time within the day
                $timestamp = $currentDate.AddHours((Get-Random -Maximum 24)).AddMinutes((Get-Random -Maximum 60))
                
                # Calculate success with variance and learning
                $successProbability = [Math]::Min(100, ($pattern.BaseSuccess + $learningBonus + ((Get-Random -Maximum 20) - 10) / 100.0) * 100)
                $success = Generate-RandomBoolean -Probability $successProbability
                
                # Confidence tends to be higher for successful applications
                $confidenceAdjustment = if ($success) { 0.05 } else { -0.05 }
                $confidence = [Math]::Max(0.1, [Math]::Min(0.99, 
                    $pattern.BaseConfidence + $confidenceAdjustment + ((Get-Random -Maximum 20) - 10) / 100.0
                ))
                
                # Execution time
                $baseTime = if ($success) { 500 } else { 800 }
                $executionTime = $baseTime + (Get-Random -Minimum -200 -Maximum 400)
                
                # Create metric object
                $metricId = "METRIC_" + [System.Guid]::NewGuid().ToString("N").Substring(0, 8).ToUpper()
                
                $newMetric = [PSCustomObject]@{
                    MetricID = $metricId
                    PatternID = $pattern.ID
                    ConfidenceScore = [Math]::Round($confidence, 4)
                    Success = $success
                    ExecutionTimeMs = [Math]::Max(100, $executionTime)
                    ErrorMessage = if (-not $success) { "Simulated error for testing" } else { "" }
                    Context = "TestData"
                    Timestamp = $timestamp.ToString("yyyy-MM-dd HH:mm:ss")
                }
                
                $newMetrics += $newMetric
            }
        }
    }
    
    Write-Host "  Generated $($newMetrics.Count) new metrics" -ForegroundColor Green
    
    # Combine with existing metrics and sort by timestamp
    $allMetrics = $existingMetrics + $newMetrics
    $allMetrics = $allMetrics | Sort-Object { [DateTime]::Parse($_.Timestamp) }
    
    # Save to JSON file
    $allMetrics | ConvertTo-Json -Depth 10 | Set-Content $metricsFile -Encoding UTF8
    
    Write-Host "`nMetrics generation complete!" -ForegroundColor Green
    Write-Host "  Total metrics in storage: $($allMetrics.Count)" -ForegroundColor Gray
    Write-Host "  Date range: $($startDate.ToString('yyyy-MM-dd')) to $(Get-Date -Format 'yyyy-MM-dd')" -ForegroundColor Gray
    
    # Display summary statistics
    Write-Host "`nVerifying generated data..." -ForegroundColor Cyan
    
    # Group by pattern and calculate stats
    $patternStats = $newMetrics | Group-Object PatternID | ForEach-Object {
        $patternMetrics = $_.Group
        $successCount = ($patternMetrics | Where-Object { $_.Success }).Count
        $avgConfidence = ($patternMetrics | Measure-Object -Property ConfidenceScore -Average).Average
        
        [PSCustomObject]@{
            PatternID = $_.Name
            Count = $patternMetrics.Count
            SuccessRate = [Math]::Round($successCount / $patternMetrics.Count * 100, 1)
            AvgConfidence = [Math]::Round($avgConfidence, 3)
        }
    }
    
    Write-Host "  Pattern statistics:" -ForegroundColor Gray
    $patternStats | ForEach-Object {
        Write-Host "    $($_.PatternID): $($_.Count) metrics, $($_.SuccessRate)% success, $($_.AvgConfidence) avg confidence" -ForegroundColor Cyan
    }
    
    Write-Host "`nTest metrics initialized successfully!" -ForegroundColor Green
    Write-Host "You can now run Test-LearningAnalytics.ps1 for comprehensive testing" -ForegroundColor Yellow
    
} catch {
    Write-Error "Failed to initialize test metrics: $_"
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    # Clean up temporary files
    if (Test-Path ".\check-patterns.ps1") {
        Remove-Item ".\check-patterns.ps1" -Force -ErrorAction SilentlyContinue
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUh/ZpsMg0k2tnv7ZvPrg5az7q
# VyigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUjQo+08WFw2OXfAgofr9jfWQE+3kwDQYJKoZIhvcNAQEBBQAEggEAabKq
# l3iUHXhb4/XeImOBxSEAD/ggKK6w/1GuaLKb6Wv94YwtG+RVkEyTDAeM9Ad1sCZI
# 6+E3Z6AvF1p0UBZUyB8ND3wuZC7dd0qyfJMQZlsE6qT8hbpUBZzrfAcnCyp+qL8b
# NeN3utFe0S8dBM3wWp1eWbQFuoOg6SMM6kmfHT+mH9O1j1dAbHw/OePqC7WIlBhT
# TuRqGouvkJeJSuwUeZTWMddoLJibDXKH/ruWGFY+pzwICT9PJZcQ9OtIIhGMwZrJ
# /ROdX0uAPEXBH++hVpoXUjVBacOpZYXyc/zKlk0b/ie+OFchf8CilD8d5rKjqlNk
# OchmWJepGSlIbfva6g==
# SIG # End signature block
