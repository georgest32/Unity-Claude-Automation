# Unity-Claude Learning Analytics Engine Module
# Implements advanced analytics for pattern learning and optimization
# PowerShell 5.1 compatible

#region Pattern Success Rate Functions

function Get-PatternSuccessRate {
    <#
    .SYNOPSIS
    Calculates success rates for patterns with time filtering
    
    .DESCRIPTION
    Analyzes pattern application metrics to determine success rates
    over specified time periods with confidence threshold filtering
    
    .PARAMETER PatternID
    Optional pattern ID to analyze specific pattern
    
    .PARAMETER TimeRange
    Time range for analysis: Last24Hours, LastWeek, LastMonth, All
    
    .PARAMETER MinConfidence
    Minimum confidence threshold (default 0.7 for automation)
    #>
    [CmdletBinding()]
    param(
        [string]$PatternID = "",
        
        [ValidateSet("Last24Hours", "LastWeek", "LastMonth", "All")]
        [string]$TimeRange = "All",
        
        [double]$MinConfidence = 0.7
    )
    
    Write-Verbose "Calculating pattern success rates for TimeRange: $TimeRange, MinConfidence: $MinConfidence"
    
    try {
        # Get metrics from storage
        $metrics = Get-LearningMetrics -TimeRange $TimeRange -PatternID $PatternID
        
        if (-not $metrics -or $metrics.TotalApplications -eq 0) {
            Write-Verbose "No metrics found for analysis"
            return @{
                PatternID = $PatternID
                TimeRange = $TimeRange
                TotalApplications = 0
                SuccessRate = 0
                HighConfidenceRate = 0
                AutomationReady = $false
            }
        }
        
        # Get detailed metrics for pattern-specific analysis
        $metricsData = Get-MetricsFromJSON -TimeRange $TimeRange -PatternID $PatternID
        
        # Filter by confidence threshold
        $highConfidenceMetrics = $metricsData | Where-Object { $_.ConfidenceScore -ge $MinConfidence }
        $highConfidenceSuccess = ($highConfidenceMetrics | Where-Object { $_.Success -eq $true }).Count
        
        $result = @{
            PatternID = $PatternID
            TimeRange = $TimeRange
            TotalApplications = $metrics.TotalApplications
            SuccessRate = [math]::Round($metrics.SuccessRate, 4)
            HighConfidenceApplications = $highConfidenceMetrics.Count
            HighConfidenceSuccessRate = if ($highConfidenceMetrics.Count -gt 0) {
                [math]::Round($highConfidenceSuccess / $highConfidenceMetrics.Count, 4)
            } else { 0 }
            AverageConfidence = [math]::Round($metrics.AverageConfidence, 4)
            AverageExecutionTime = [math]::Round($metrics.AverageExecutionTime, 2)
            AutomationReady = ($metrics.SuccessRate -ge 0.85 -and $metrics.AverageConfidence -ge $MinConfidence)
        }
        
        Write-Verbose "Pattern success rate calculated: $($result.SuccessRate * 100)%, Automation ready: $($result.AutomationReady)"
        return $result
        
    } catch {
        Write-Error "Failed to calculate pattern success rate: $_"
        return $null
    }
}

function Get-AllPatternsSuccessRates {
    <#
    .SYNOPSIS
    Gets success rates for all patterns sorted by performance
    #>
    [CmdletBinding()]
    param(
        [ValidateSet("Last24Hours", "LastWeek", "LastMonth", "All")]
        [string]$TimeRange = "All",
        
        [double]$MinConfidence = 0.7
    )
    
    Write-Verbose "Analyzing success rates for all patterns"
    
    try {
        # Get all unique pattern IDs from metrics
        $allMetrics = Get-MetricsFromJSON -TimeRange $TimeRange
        $patternIds = $allMetrics | Select-Object -ExpandProperty PatternID -Unique
        
        $results = @()
        foreach ($pid in $patternIds) {
            $rate = Get-PatternSuccessRate -PatternID $pid -TimeRange $TimeRange -MinConfidence $MinConfidence
            if ($rate) {
                $results += $rate
            }
        }
        
        # Sort by success rate descending
        $sorted = $results | Sort-Object -Property SuccessRate -Descending
        
        Write-Verbose "Analyzed $($sorted.Count) patterns"
        return $sorted
        
    } catch {
        Write-Error "Failed to get all patterns success rates: $_"
        return @()
    }
}

#endregion

#region Trend Analysis Functions

function Calculate-MovingAverage {
    <#
    .SYNOPSIS
    Calculates moving average for trend analysis
    
    .DESCRIPTION
    Implements simple moving average calculation for time series data
    
    .PARAMETER Data
    Array of numeric values
    
    .PARAMETER WindowSize
    Size of the moving average window
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [double[]]$Data,
        
        [Parameter(Mandatory=$true)]
        [int]$WindowSize
    )
    
    Write-Verbose "Calculating moving average with window size: $WindowSize"
    
    $movingAverages = @()
    
    for ($i = $WindowSize - 1; $i -lt $Data.Count; $i++) {
        $startIndex = $i - ($WindowSize - 1)
        $window = $Data[$startIndex..$i]
        $avg = ($window | Measure-Object -Average).Average
        
        $movingAverages += [PSCustomObject]@{
            Index = $i
            OriginalValue = $Data[$i]
            MovingAverage = [math]::Round($avg, 4)
            Trend = if ($movingAverages.Count -gt 0) {
                $previous = $movingAverages[-1].MovingAverage
                if ($avg -gt $previous * 1.05) { "Improving" }
                elseif ($avg -lt $previous * 0.95) { "Declining" }
                else { "Stable" }
            } else { "Initial" }
        }
    }
    
    return $movingAverages
}

function Get-LearningTrend {
    <#
    .SYNOPSIS
    Analyzes learning trend over time
    
    .DESCRIPTION
    Calculates trend indicators showing improvement or decline in performance
    
    .PARAMETER TimeRange
    Time range for trend analysis
    
    .PARAMETER MetricType
    Type of metric to analyze: SuccessRate, Confidence, ExecutionTime
    #>
    [CmdletBinding()]
    param(
        [ValidateSet("Last24Hours", "LastWeek", "LastMonth", "All")]
        [string]$TimeRange = "LastWeek",
        
        [ValidateSet("SuccessRate", "Confidence", "ExecutionTime")]
        [string]$MetricType = "SuccessRate"
    )
    
    Write-Verbose "Analyzing learning trend for $MetricType over $TimeRange"
    
    try {
        # Get time-series metrics data
        $metrics = Get-MetricsFromJSON -TimeRange $TimeRange
        
        if ($metrics.Count -lt 3) {
            Write-Verbose "Insufficient data for trend analysis (need at least 3 data points)"
            return @{
                MetricType = $MetricType
                TimeRange = $TimeRange
                DataPoints = $metrics.Count
                Trend = "InsufficientData"
                ImprovementRate = 0
            }
        }
        
        # Group metrics by time periods (e.g., hourly buckets)
        $grouped = $metrics | Group-Object {
            $timestamp = [DateTime]::Parse($_.Timestamp)
            $timestamp.ToString("yyyy-MM-dd HH:00")
        } | Sort-Object Name
        
        # Calculate metric values for each time bucket
        $timeSeriesData = @()
        foreach ($group in $grouped) {
            $bucketMetrics = $group.Group
            
            $value = switch ($MetricType) {
                "SuccessRate" {
                    $success = ($bucketMetrics | Where-Object { $_.Success }).Count
                    if ($bucketMetrics.Count -gt 0) { $success / $bucketMetrics.Count } else { 0 }
                }
                "Confidence" {
                    ($bucketMetrics | Measure-Object -Property ConfidenceScore -Average).Average
                }
                "ExecutionTime" {
                    ($bucketMetrics | Measure-Object -Property ExecutionTimeMs -Average).Average
                }
            }
            
            $timeSeriesData += $value
        }
        
        # Calculate moving average for trend
        $windowSize = [Math]::Min(3, [Math]::Floor($timeSeriesData.Count / 2))
        $movingAvg = Calculate-MovingAverage -Data $timeSeriesData -WindowSize $windowSize
        
        # Determine overall trend
        $firstAvg = $movingAvg[0].MovingAverage
        $lastAvg = $movingAvg[-1].MovingAverage
        
        $improvementRate = if ($firstAvg -ne 0) {
            [math]::Round((($lastAvg - $firstAvg) / $firstAvg) * 100, 2)
        } else { 0 }
        
        $overallTrend = if ($improvementRate -gt 5) { "Improving" }
                       elseif ($improvementRate -lt -5) { "Declining" }
                       else { "Stable" }
        
        # For execution time, inverse the trend (lower is better)
        if ($MetricType -eq "ExecutionTime") {
            $improvementRate = -$improvementRate
            $overallTrend = if ($improvementRate -gt 5) { "Improving" }
                           elseif ($improvementRate -lt -5) { "Declining" }
                           else { "Stable" }
        }
        
        $result = @{
            MetricType = $MetricType
            TimeRange = $TimeRange
            DataPoints = $timeSeriesData.Count
            Trend = $overallTrend
            ImprovementRate = $improvementRate
            MovingAverages = $movingAvg
            FirstValue = [math]::Round($firstAvg, 4)
            LastValue = [math]::Round($lastAvg, 4)
        }
        
        Write-Verbose "Learning trend: $overallTrend with $improvementRate% change"
        return $result
        
    } catch {
        Write-Error "Failed to analyze learning trend: $_"
        return $null
    }
}

#endregion

#region Confidence Adjustment Functions

function Update-PatternConfidence {
    <#
    .SYNOPSIS
    Updates pattern confidence using Bayesian-inspired adjustment
    
    .DESCRIPTION
    Adjusts confidence scores based on recent performance using
    a simplified Bayesian update approach
    
    .PARAMETER PatternID
    Pattern to update confidence for
    
    .PARAMETER Success
    Whether the recent application was successful
    
    .PARAMETER CurrentConfidence
    Current confidence score
    
    .PARAMETER LearningRate
    How much to adjust confidence (0.05 = 5% adjustment)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$PatternID,
        
        [Parameter(Mandatory=$true)]
        [bool]$Success,
        
        [Parameter(Mandatory=$true)]
        [double]$CurrentConfidence,
        
        [double]$LearningRate = 0.05
    )
    
    Write-Verbose "Updating confidence for pattern $PatternID (Current: $CurrentConfidence, Success: $Success)"
    
    try {
        # Bayesian-inspired update
        # Success increases confidence, failure decreases it
        # The adjustment is proportional to how wrong we were
        
        if ($Success) {
            # Success: increase confidence
            # More adjustment if we were less confident
            $adjustment = $LearningRate * (1 - $CurrentConfidence)
            $newConfidence = $CurrentConfidence + $adjustment
        } else {
            # Failure: decrease confidence
            # More adjustment if we were more confident
            $adjustment = $LearningRate * $CurrentConfidence
            $newConfidence = $CurrentConfidence - $adjustment
        }
        
        # Ensure confidence stays in valid range [0.1, 0.99]
        $newConfidence = [Math]::Max(0.1, [Math]::Min(0.99, $newConfidence))
        $newConfidence = [Math]::Round($newConfidence, 4)
        
        # Store confidence update
        $update = @{
            PatternID = $PatternID
            OldConfidence = $CurrentConfidence
            NewConfidence = $newConfidence
            Success = $Success
            Adjustment = [Math]::Round($newConfidence - $CurrentConfidence, 4)
            Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        }
        
        # Save to confidence history (could be extended to persist)
        if (-not $script:ConfidenceHistory) {
            $script:ConfidenceHistory = @{}
        }
        if (-not $script:ConfidenceHistory[$PatternID]) {
            $script:ConfidenceHistory[$PatternID] = @()
        }
        $script:ConfidenceHistory[$PatternID] += $update
        
        Write-Verbose "Confidence updated: $CurrentConfidence -> $newConfidence (Adjustment: $($update.Adjustment))"
        return $newConfidence
        
    } catch {
        Write-Error "Failed to update pattern confidence: $_"
        return $CurrentConfidence
    }
}

function Get-AdjustedConfidence {
    <#
    .SYNOPSIS
    Gets adjusted confidence based on recent performance
    
    .DESCRIPTION
    Calculates confidence adjustment based on recent success rate
    
    .PARAMETER PatternID
    Pattern to get adjusted confidence for
    
    .PARAMETER BaseConfidence
    Base confidence score
    
    .PARAMETER RecentWindow
    Number of recent applications to consider
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$PatternID,
        
        [Parameter(Mandatory=$true)]
        [double]$BaseConfidence,
        
        [int]$RecentWindow = 10
    )
    
    Write-Verbose "Getting adjusted confidence for pattern $PatternID"
    
    try {
        # Get recent metrics for this pattern
        $allMetrics = Get-MetricsFromJSON -PatternID $PatternID
        
        # Take the most recent N applications
        $recentMetrics = $allMetrics | 
            Sort-Object { [DateTime]::Parse($_.Timestamp) } -Descending |
            Select-Object -First $RecentWindow
        
        if ($recentMetrics.Count -eq 0) {
            Write-Verbose "No recent metrics, using base confidence"
            return $BaseConfidence
        }
        
        # Calculate recent success rate
        $recentSuccess = ($recentMetrics | Where-Object { $_.Success }).Count
        $recentSuccessRate = $recentSuccess / $recentMetrics.Count
        
        # Adjust confidence based on recent performance
        # If recent success rate differs from base confidence, adjust accordingly
        $performanceRatio = $recentSuccessRate / $BaseConfidence
        
        # Apply bounded adjustment
        $adjustmentFactor = 0.2  # Maximum 20% adjustment
        $adjustment = ($performanceRatio - 1) * $adjustmentFactor
        
        $adjustedConfidence = $BaseConfidence * (1 + $adjustment)
        $adjustedConfidence = [Math]::Max(0.1, [Math]::Min(0.99, $adjustedConfidence))
        $adjustedConfidence = [Math]::Round($adjustedConfidence, 4)
        
        Write-Verbose "Adjusted confidence: $BaseConfidence -> $adjustedConfidence (Recent success rate: $recentSuccessRate)"
        return $adjustedConfidence
        
    } catch {
        Write-Error "Failed to get adjusted confidence: $_"
        return $BaseConfidence
    }
}

#endregion

#region Pattern Recommendation Functions

function Get-RecommendedPatterns {
    <#
    .SYNOPSIS
    Recommends best patterns for an error
    
    .DESCRIPTION
    Uses similarity matching and performance metrics to recommend patterns
    
    .PARAMETER ErrorMessage
    Error message to find patterns for
    
    .PARAMETER TopCount
    Number of top patterns to recommend
    
    .PARAMETER MinSimilarity
    Minimum similarity threshold (0-1)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ErrorMessage,
        
        [int]$TopCount = 3,
        
        [double]$MinSimilarity = 0.6
    )
    
    Write-Verbose "Getting pattern recommendations for: $ErrorMessage"
    
    try {
        # Import Unity-Claude-Learning module to access Find-SimilarPatterns
        if (-not (Get-Command Find-SimilarPatterns -ErrorAction SilentlyContinue)) {
            Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'Unity-Claude-Learning/Unity-Claude-Learning.psm1') -Force -DisableNameChecking
        }
        
        # Find similar patterns using existing similarity function
        $similarPatterns = Find-SimilarPatterns -ErrorSignature $ErrorMessage -SimilarityThreshold $MinSimilarity
        
        if ($similarPatterns.Count -eq 0) {
            Write-Verbose "No similar patterns found"
            return @()
        }
        
        # Get performance metrics for each similar pattern
        $recommendations = @()
        foreach ($pattern in $similarPatterns) {
            # Handle different possible property names from Find-SimilarPatterns
            $patternId = if ($pattern.PatternID) { $pattern.PatternID } 
                        elseif ($pattern.PatternId) { $pattern.PatternId }
                        elseif ($pattern.ID) { $pattern.ID }
                        else { "UNKNOWN" }
                        
            $errorMsg = if ($pattern.ErrorMessage) { $pattern.ErrorMessage }
                       elseif ($pattern.ErrorSignature) { $pattern.ErrorSignature }
                       elseif ($pattern.Error) { $pattern.Error }
                       else { "Unknown error" }
                       
            $fix = if ($pattern.Fix) { $pattern.Fix }
                  elseif ($pattern.Solution) { $pattern.Solution }
                  else { "No fix available" }
                  
            $similarity = if ($pattern.Similarity -ne $null) { $pattern.Similarity }
                         elseif ($pattern.Score -ne $null) { $pattern.Score }
                         else { $MinSimilarity }
            
            $successRate = Get-PatternSuccessRate -PatternID $patternId -TimeRange "LastMonth"
            
            # Calculate recommendation score
            # Combines similarity, success rate, and confidence
            $similarityScore = $similarity
            $performanceScore = if ($successRate) { $successRate.SuccessRate } else { 0 }
            $confidenceScore = if ($successRate) { $successRate.AverageConfidence } else { 0.5 }
            
            # Weighted combination (similarity is most important for relevance)
            $recommendationScore = ($similarityScore * 0.5) + 
                                 ($performanceScore * 0.3) + 
                                 ($confidenceScore * 0.2)
            
            $recommendations += [PSCustomObject]@{
                PatternID = $patternId
                ErrorPattern = $errorMsg
                Fix = $fix
                Similarity = [Math]::Round($similarityScore, 4)
                SuccessRate = [Math]::Round($performanceScore, 4)
                Confidence = [Math]::Round($confidenceScore, 4)
                RecommendationScore = [Math]::Round($recommendationScore, 4)
                AutomationReady = ($performanceScore -ge 0.85 -and $confidenceScore -ge 0.7)
            }
        }
        
        # Sort by recommendation score and take top N
        $topRecommendations = $recommendations | 
            Sort-Object -Property RecommendationScore -Descending |
            Select-Object -First $TopCount
        
        Write-Verbose "Found $($topRecommendations.Count) pattern recommendations"
        return $topRecommendations
        
    } catch {
        Write-Error "Failed to get pattern recommendations: $_"
        return @()
    }
}

function Get-PatternEffectivenessRanking {
    <#
    .SYNOPSIS
    Ranks all patterns by effectiveness
    
    .DESCRIPTION
    Combines multiple metrics to rank patterns by overall effectiveness
    #>
    [CmdletBinding()]
    param(
        [ValidateSet("Last24Hours", "LastWeek", "LastMonth", "All")]
        [string]$TimeRange = "LastMonth"
    )
    
    Write-Verbose "Ranking patterns by effectiveness for TimeRange: $TimeRange"
    
    try {
        # Get usage analytics
        $usageAnalytics = Get-PatternUsageAnalytics -TopCount 100
        
        if (-not $usageAnalytics -or $usageAnalytics.TopPatternsByEffectiveness.Count -eq 0) {
            Write-Verbose "No pattern data available for ranking"
            return @()
        }
        
        # Get trend data for each pattern
        $rankings = @()
        foreach ($pattern in $usageAnalytics.TopPatternsByEffectiveness) {
            # Get recent trend
            $recentMetrics = Get-MetricsFromJSON -PatternID $pattern.PatternID -TimeRange $TimeRange
            
            # Calculate trend (simple: compare first half vs second half)
            if ($recentMetrics.Count -ge 4) {
                $midPoint = [Math]::Floor($recentMetrics.Count / 2)
                $firstHalf = $recentMetrics[0..($midPoint-1)]
                $secondHalf = $recentMetrics[$midPoint..($recentMetrics.Count-1)]
                
                $firstSuccess = ($firstHalf | Where-Object { $_.Success }).Count / $firstHalf.Count
                $secondSuccess = ($secondHalf | Where-Object { $_.Success }).Count / $secondHalf.Count
                
                $trend = if ($secondSuccess -gt $firstSuccess * 1.1) { "Improving" }
                        elseif ($secondSuccess -lt $firstSuccess * 0.9) { "Declining" }
                        else { "Stable" }
                
                $trendScore = switch ($trend) {
                    "Improving" { 1.2 }
                    "Stable" { 1.0 }
                    "Declining" { 0.8 }
                }
            } else {
                $trend = "InsufficientData"
                $trendScore = 1.0
            }
            
            # Calculate overall effectiveness with trend adjustment
            $overallScore = $pattern.Effectiveness * $trendScore
            
            $rankings += [PSCustomObject]@{
                Rank = 0  # Will be set after sorting
                PatternID = $pattern.PatternID
                UsageCount = $pattern.UsageCount
                SuccessRate = $pattern.SuccessRate
                AverageConfidence = $pattern.AverageConfidence
                BaseEffectiveness = $pattern.Effectiveness
                Trend = $trend
                TrendMultiplier = $trendScore
                OverallScore = [Math]::Round($overallScore, 4)
            }
        }
        
        # Sort by overall score and assign ranks
        $sorted = $rankings | Sort-Object -Property OverallScore -Descending
        for ($i = 0; $i -lt $sorted.Count; $i++) {
            $sorted[$i].Rank = $i + 1
        }
        
        Write-Verbose "Ranked $($sorted.Count) patterns by effectiveness"
        return $sorted
        
    } catch {
        Write-Error "Failed to rank pattern effectiveness: $_"
        return @()
    }
}

#endregion

#region Export Functions

# Export all public functions
Export-ModuleMember -Function @(
    'Get-PatternSuccessRate',
    'Get-AllPatternsSuccessRates',
    'Calculate-MovingAverage',
    'Get-LearningTrend',
    'Update-PatternConfidence',
    'Get-AdjustedConfidence',
    'Get-RecommendedPatterns',
    'Get-PatternEffectivenessRanking'
)

#endregion
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUQD9IoBConkB9dijPkC7Ag9i
# hA6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU4+JOD7IxV3gXR2TDWfQhvzJqobgwDQYJKoZIhvcNAQEBBQAEggEAl92+
# x9HOf3xvVjOWcR1hkkYndH4PF6L147yPb7EHDLxdyuiw5SepXicD0PRmvSeYGxod
# LuQKLCLfrtNM1IYesWGc2HC40juhk8YfdX04N/lPROxkeg0HcFMjNSYLmbQmsuxy
# sKQSTt/Tso2At/qNYKgZ51QpoI/Apx6qUgFBWChZknM4p4NQisnlyXRL4T7c6/JM
# h0cLXseW8Ki7fASJ5UkN7BDYKdl+YSt8PGHLYhEJw3lJCeqvafoq6Mr2QnyIlt8U
# Q3azycGA+ZCXB1uX3qPdi/g/O7Rsmf3BRTY4+NJigoOZXbcSU9jdYzxLfnDOiQhi
# cMoxquuE5LFSPgQkUg==
# SIG # End signature block
