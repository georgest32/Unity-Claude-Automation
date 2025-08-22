# Unity-Claude Learning Analytics Dashboard
# Week 2 Day 12-14: PowerShell Universal Dashboard Implementation
# Real-time visualization of learning analytics data

param(
    [int]$Port = 8080,
    [int]$RefreshInterval = 30,  # seconds
    [switch]$OpenBrowser
)

Write-Host "=== Unity-Claude Learning Analytics Dashboard ===" -ForegroundColor Yellow
Write-Host "Loading modules and data..." -ForegroundColor Cyan

# Import required modules
try {
    Import-Module UniversalDashboard.Community -ErrorAction Stop
    Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning.psm1' -Force -DisableNameChecking
    Import-Module './Modules/Unity-Claude-Learning/Unity-Claude-Learning-Analytics.psm1' -Force -DisableNameChecking
    Write-Host "✓ Modules loaded successfully" -ForegroundColor Green
} catch {
    Write-Error "Failed to load required modules: $_"
    Write-Host "Run Install-UniversalDashboard.ps1 first" -ForegroundColor Yellow
    exit 1
}

# Configure storage path
$storagePath = Join-Path (Get-Location) "Storage\JSON"
Write-Host "Storage path: $storagePath" -ForegroundColor Gray

# Load initial data
Write-Host "Loading analytics data..." -ForegroundColor Cyan
$metrics = Get-MetricsFromJSON -StoragePath $storagePath
$patterns = Get-AllPatternsSuccessRates -TimeRange "All"
Write-Host "  Metrics loaded: $($metrics.Count)" -ForegroundColor Gray
Write-Host "  Patterns analyzed: $($patterns.Count)" -ForegroundColor Gray

# Create dashboard pages
$Pages = @(
    # Overview Page
    New-UDPage -Name "Overview" -Icon home -Content {
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Unity-Claude Learning Analytics Dashboard" -Content {
                    New-UDParagraph -Text "Real-time visualization of pattern learning and error resolution analytics"
                    New-UDParagraph -Text "Last Update: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
                }
            }
        }
        
        # Summary Cards
        New-UDRow {
            New-UDColumn -Size 3 {
                New-UDCard -Title "Total Metrics" -Content {
                    $metricsCount = (Get-MetricsFromJSON -StoragePath $storagePath).Count
                    New-UDHeading -Size 1 -Text $metricsCount.ToString()
                } -FontColor "white" -BackgroundColor "#2196F3"
            }
            
            New-UDColumn -Size 3 {
                New-UDCard -Title "Active Patterns" -Content {
                    $patternCount = (Get-AllPatternsSuccessRates -TimeRange "All").Count
                    New-UDHeading -Size 1 -Text $patternCount.ToString()
                } -FontColor "white" -BackgroundColor "#4CAF50"
            }
            
            New-UDColumn -Size 3 {
                New-UDCard -Title "Avg Success Rate" -Content {
                    $avgSuccess = if ($patterns.Count -gt 0) {
                        [Math]::Round(($patterns | Measure-Object -Property SuccessRate -Average).Average * 100, 1)
                    } else { 0 }
                    New-UDHeading -Size 1 -Text "$avgSuccess%"
                } -FontColor "white" -BackgroundColor "#FF9800"
            }
            
            New-UDColumn -Size 3 {
                New-UDCard -Title "Automation Ready" -Content {
                    $autoReady = ($patterns | Where-Object { $_.AutomationReady }).Count
                    New-UDHeading -Size 1 -Text $autoReady.ToString()
                } -FontColor "white" -BackgroundColor "#9C27B0"
            }
        }
        
        # Recent Activity Chart
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDChart -Title "Recent Pattern Applications (Last 7 Days)" -Type Line -RefreshInterval $RefreshInterval -Endpoint {
                    $recentMetrics = Get-MetricsFromJSON -StoragePath $storagePath -TimeRange "LastWeek"
                    
                    # Group by day
                    $grouped = $recentMetrics | Group-Object {
                        [DateTime]::Parse($_.Timestamp).ToString("yyyy-MM-dd")
                    } | Sort-Object Name
                    
                    $grouped | ForEach-Object {
                        [PSCustomObject]@{
                            Date = $_.Name
                            Applications = $_.Count
                            SuccessCount = ($_.Group | Where-Object { $_.Success }).Count
                        }
                    } | Out-UDChartData -DataProperty "Applications", "SuccessCount" -LabelProperty "Date" -BackgroundColor @("#2196F3", "#4CAF50") -BorderColor @("#1976D2", "#388E3C")
                }
            }
        }
    }
    
    # Success Rates Page
    New-UDPage -Name "Success Rates" -Icon chart_line -Content {
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Pattern Success Rates" -Content {
                    New-UDParagraph -Text "Success rates for all tracked patterns with automation readiness indicators"
                }
            }
        }
        
        # Success Rate Bar Chart
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDChart -Title "Pattern Success Rates" -Type Bar -RefreshInterval $RefreshInterval -Endpoint {
                    $patterns = Get-AllPatternsSuccessRates -TimeRange "All"
                    
                    $patterns | Select-Object -First 10 | ForEach-Object {
                        $patternName = if ($_.PatternID) { $_.PatternID } else { "Unknown" }
                        [PSCustomObject]@{
                            Pattern = $patternName.Substring([Math]::Max(0, $patternName.Length - 15))
                            SuccessRate = [Math]::Round($_.SuccessRate * 100, 1)
                            Threshold = 85  # Automation threshold
                        }
                    } | Out-UDChartData -DataProperty "SuccessRate", "Threshold" -LabelProperty "Pattern" -BackgroundColor @("#4CAF50", "#FF5722") -BorderColor @("#388E3C", "#D32F2F")
                }
            }
        }
        
        # Pattern Details Grid
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDGrid -Title "Pattern Details" -Headers @("Pattern", "Success Rate", "Applications", "Confidence", "Ready") -Properties @("PatternID", "SuccessRate", "TotalApplications", "AverageConfidence", "AutomationReady") -RefreshInterval $RefreshInterval -Endpoint {
                    $patterns = Get-AllPatternsSuccessRates -TimeRange "All"
                    
                    $patterns | ForEach-Object {
                        [PSCustomObject]@{
                            PatternID = if ($_.PatternID) { $_.PatternID.Substring([Math]::Max(0, $_.PatternID.Length - 20)) } else { "N/A" }
                            SuccessRate = "$([Math]::Round($_.SuccessRate * 100, 1))%"
                            TotalApplications = $_.TotalApplications
                            AverageConfidence = [Math]::Round($_.AverageConfidence, 3)
                            AutomationReady = if ($_.AutomationReady) { "Yes" } else { "No" }
                        }
                    } | Out-UDGridData
                }
            }
        }
    }
    
    # Trend Analysis Page
    New-UDPage -Name "Trend Analysis" -Icon trending_up -Content {
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Learning Trend Analysis" -Content {
                    New-UDParagraph -Text "System performance trends over time"
                }
            }
        }
        
        # Trend Charts
        New-UDRow {
            New-UDColumn -Size 6 {
                New-UDChart -Title "Success Rate Trend" -Type Line -RefreshInterval $RefreshInterval -Endpoint {
                    $trend = Get-LearningTrend -TimeRange "All" -MetricType "SuccessRate"
                    
                    if ($trend.MovingAverages) {
                        $trend.MovingAverages | ForEach-Object {
                            [PSCustomObject]@{
                                Index = $_.Index
                                Value = [Math]::Round($_.MovingAverage * 100, 1)
                            }
                        }
                    } else {
                        [PSCustomObject]@{
                            Index = 0
                            Value = 0
                        }
                    } | Out-UDChartData -DataProperty "Value" -LabelProperty "Index" -BackgroundColor "#4CAF50" -BorderColor "#388E3C"
                }
            }
            
            New-UDColumn -Size 6 {
                New-UDChart -Title "Confidence Trend" -Type Line -RefreshInterval $RefreshInterval -Endpoint {
                    $trend = Get-LearningTrend -TimeRange "All" -MetricType "Confidence"
                    
                    if ($trend.MovingAverages) {
                        $trend.MovingAverages | ForEach-Object {
                            [PSCustomObject]@{
                                Index = $_.Index
                                Value = [Math]::Round($_.MovingAverage * 100, 1)
                            }
                        }
                    } else {
                        [PSCustomObject]@{
                            Index = 0
                            Value = 0
                        }
                    } | Out-UDChartData -DataProperty "Value" -LabelProperty "Index" -BackgroundColor "#2196F3" -BorderColor "#1976D2"
                }
            }
        }
        
        # Execution Time Trend
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDChart -Title "Execution Time Trend (ms)" -Type Line -RefreshInterval $RefreshInterval -Endpoint {
                    $trend = Get-LearningTrend -TimeRange "All" -MetricType "ExecutionTime"
                    
                    if ($trend.MovingAverages) {
                        $trend.MovingAverages | ForEach-Object {
                            [PSCustomObject]@{
                                Index = $_.Index
                                Time = [Math]::Round($_.MovingAverage, 0)
                            }
                        }
                    } else {
                        [PSCustomObject]@{
                            Index = 0
                            Time = 0
                        }
                    } | Out-UDChartData -DataProperty "Time" -LabelProperty "Index" -BackgroundColor "#FF9800" -BorderColor "#F57C00"
                }
            }
        }
    }
    
    # Pattern Effectiveness Page
    New-UDPage -Name "Effectiveness" -Icon star -Content {
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Pattern Effectiveness Rankings" -Content {
                    New-UDParagraph -Text "Patterns ranked by overall effectiveness score"
                }
            }
        }
        
        # Effectiveness Chart
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDChart -Title "Top 10 Most Effective Patterns" -Type HorizontalBar -RefreshInterval $RefreshInterval -Endpoint {
                    $rankings = Get-PatternEffectivenessRanking -TimeRange "All"
                    
                    $rankings | Select-Object -First 10 | ForEach-Object {
                        $patternName = if ($_.PatternID) { $_.PatternID } else { "Unknown" }
                        [PSCustomObject]@{
                            Pattern = $patternName.Substring([Math]::Max(0, $patternName.Length - 15))
                            Score = [Math]::Round($_.OverallScore * 100, 1)
                        }
                    } | Out-UDChartData -DataProperty "Score" -LabelProperty "Pattern" -BackgroundColor "#9C27B0" -BorderColor "#7B1FA2"
                }
            }
        }
        
        # Effectiveness Details
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDGrid -Title "Effectiveness Details" -Headers @("Rank", "Pattern", "Success", "Confidence", "Trend", "Score") -Properties @("Rank", "PatternID", "SuccessRate", "AverageConfidence", "Trend", "OverallScore") -RefreshInterval $RefreshInterval -Endpoint {
                    $rankings = Get-PatternEffectivenessRanking -TimeRange "All"
                    
                    $rankings | Select-Object -First 15 | ForEach-Object {
                        [PSCustomObject]@{
                            Rank = $_.Rank
                            PatternID = if ($_.PatternID) { $_.PatternID.Substring([Math]::Max(0, $_.PatternID.Length - 20)) } else { "N/A" }
                            SuccessRate = "$([Math]::Round($_.SuccessRate * 100, 1))%"
                            AverageConfidence = [Math]::Round($_.AverageConfidence, 3)
                            Trend = $_.Trend
                            OverallScore = [Math]::Round($_.OverallScore, 3)
                        }
                    } | Out-UDGridData
                }
            }
        }
    }
    
    # Confidence Calibration Page
    New-UDPage -Name "Confidence" -Icon assessment -Content {
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDCard -Title "Confidence Calibration Analysis" -Content {
                    New-UDParagraph -Text "Distribution of confidence scores and calibration accuracy"
                }
            }
        }
        
        # Confidence Distribution
        New-UDRow {
            New-UDColumn -Size 12 {
                New-UDChart -Title "Confidence Score Distribution" -Type Doughnut -RefreshInterval $RefreshInterval -Endpoint {
                    $analytics = Get-PatternUsageAnalytics -TopCount 100
                    
                    if ($analytics -and $analytics.ConfidenceCalibration) {
                        $buckets = @("0.0-0.5", "0.5-0.6", "0.6-0.7", "0.7-0.8", "0.8-0.9", "0.9-1.0")
                        
                        $buckets | ForEach-Object {
                            $bucket = $_
                            $count = 0
                            
                            # Aggregate smaller buckets into larger ones
                            if ($bucket -eq "0.0-0.5") {
                                $count = 0
                                @("0.0-0.1", "0.1-0.2", "0.2-0.3", "0.3-0.4", "0.4-0.5") | ForEach-Object {
                                    if ($analytics.ConfidenceCalibration.ContainsKey($_)) {
                                        $count += $analytics.ConfidenceCalibration[$_].Total
                                    }
                                }
                            } else {
                                if ($analytics.ConfidenceCalibration.ContainsKey($bucket)) {
                                    $count = $analytics.ConfidenceCalibration[$bucket].Total
                                }
                            }
                            
                            [PSCustomObject]@{
                                Range = $bucket
                                Count = $count
                            }
                        }
                    } else {
                        [PSCustomObject]@{
                            Range = "No Data"
                            Count = 1
                        }
                    } | Out-UDChartData -DataProperty "Count" -LabelProperty "Range" -BackgroundColor @("#FF5722", "#FF9800", "#FFC107", "#8BC34A", "#4CAF50", "#2196F3")
                }
            }
        }
    }
)

# Create the dashboard
$Dashboard = New-UDDashboard -Title "Unity-Claude Learning Analytics" -Pages $Pages -Theme "Default"

# Start the dashboard
try {
    Write-Host "`nStarting dashboard on port $Port..." -ForegroundColor Cyan
    
    # Stop any existing dashboard on this port
    Get-UDDashboard | Where-Object { $_.Port -eq $Port } | Stop-UDDashboard
    
    # Start new dashboard
    Start-UDDashboard -Dashboard $Dashboard -Port $Port -AutoReload
    
    Write-Host "✓ Dashboard started successfully!" -ForegroundColor Green
    Write-Host "`nAccess the dashboard at: http://localhost:$Port" -ForegroundColor Yellow
    
    if ($OpenBrowser) {
        Start-Process "http://localhost:$Port"
    }
    
    Write-Host "`nPress Ctrl+C to stop the dashboard" -ForegroundColor Gray
    Write-Host "Dashboard is auto-refreshing every $RefreshInterval seconds" -ForegroundColor Gray
    
    # Keep the script running
    while ($true) {
        Start-Sleep -Seconds 10
    }
    
} catch {
    Write-Error "Failed to start dashboard: $_"
    Write-Host "`nTroubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Check if port $Port is already in use" -ForegroundColor Gray
    Write-Host "2. Try a different port: .\Start-LearningDashboard.ps1 -Port 8081" -ForegroundColor Gray
    Write-Host "3. Run as Administrator if needed" -ForegroundColor Gray
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU1HaTeelS8zf22aIFuHQhU43d
# sNSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUB0n71gE1lqWGRcPuFqJ7ujNF27UwDQYJKoZIhvcNAQEBBQAEggEALpQD
# yv/BSigXNp/w2kylcwoKmqoHRiuRgZowI8vztqKcmKbbS0OBT3ribno7ob5dhHKM
# mymaZXouX0OrsTMOZ4MiAkfyAljH5qPXBPzOhvqXU+i1LPO898ThrOqYKUH5rrw/
# za4m1GBkReZdH8KVPKB/PEtD9sCijwAmYCvMy3rm3HnzWU2qXFnmRXv6tLJe5yub
# 5GkuR6VzIe8TzhGz8B+lt8s8omoonvEls6jmP+4P8QO/uc2+2G+rlLAuB08WXjWY
# Uo8c9N3tvZE9WEST8z5A2l9x1Fo/Jb5y1P7+jPDVC6cr4KzqlOdcaLJ812Q9m0/4
# q4RmAAwWVQ5LS/aKVQ==
# SIG # End signature block
