#Requires -Version 5.1
<#
.SYNOPSIS
    Unity performance analysis operations for SafeCommandExecution module.

.DESCRIPTION
    Provides performance metrics extraction, benchmarking, and trend analysis
    for Unity operations from log files.

.NOTES
    Part of SafeCommandExecution refactored architecture
    Originally from SafeCommandExecution.psm1 (lines 1911-2217)
    Refactoring Date: 2025-08-25
#>

# Import required modules
Import-Module "$PSScriptRoot\SafeCommandCore.psm1" -Force

#region Performance Analysis

function Invoke-UnityPerformanceAnalysis {
    <#
    .SYNOPSIS
    Analyzes Unity performance metrics from log files.
    
    .DESCRIPTION
    Extracts timing information for compilation, builds, imports, and tests,
    then provides benchmarks and recommendations.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Starting Unity performance analysis" -Level Info
    
    # Get analysis parameters
    $logPath = $Command.Arguments.LogPath
    $metricTypes = $Command.Arguments.MetricTypes
    if (-not $metricTypes) {
        $metricTypes = @('Compilation', 'Build', 'Test', 'Import')
    }
    
    if (-not $logPath) {
        $logPath = Join-Path $env:LOCALAPPDATA "Unity\Editor\Editor.log"
    }
    
    # Validate log path
    if (-not (Test-Path $logPath)) {
        throw "Unity log file not found: $logPath"
    }
    
    $performanceAnalysis = @{
        LogPath = $logPath
        AnalyzedAt = Get-Date
        MetricTypes = $metricTypes
        Metrics = @{}
        Benchmarks = @{}
        Trends = @{}
        Recommendations = @()
    }
    
    Write-SafeLog "Analyzing performance metrics in Unity log: $logPath" -Level Debug
    
    try {
        # Start timing analysis
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Read log content
        $logContent = Get-Content $logPath -ErrorAction SilentlyContinue
        
        # Define performance patterns to extract
        $performancePatterns = @{
            'CompilationTime' = @{
                StartPattern = 'Compilation started'
                EndPattern = 'Compilation (succeeded|failed)'
                Metrics = @()
            }
            'BuildTime' = @{
                StartPattern = 'Build started|Building Player'
                EndPattern = 'Build (completed|failed)'
                Metrics = @()
            }
            'ImportTime' = @{
                StartPattern = 'Importing'
                EndPattern = 'Import (completed|failed)'
                Metrics = @()
            }
            'TestTime' = @{
                StartPattern = 'Running tests'
                EndPattern = 'Test run (completed|failed)'
                Metrics = @()
            }
        }
        
        # Extract timing information from log
        $currentOperations = @{}
        
        foreach ($line in $logContent) {
            # Look for timing information in Unity logs
            foreach ($patternName in $performancePatterns.Keys) {
                $pattern = $performancePatterns[$patternName]
                
                # Check for start pattern
                if ($line -match $pattern.StartPattern) {
                    $currentOperations[$patternName] = @{
                        StartTime = Get-Date
                        StartLine = $line
                    }
                    Write-SafeLog "Performance tracking started for $patternName" -Level Debug
                }
                
                # Check for end pattern
                if ($line -match $pattern.EndPattern -and $currentOperations.ContainsKey($patternName)) {
                    $operation = $currentOperations[$patternName]
                    $endTime = Get-Date
                    $duration = ($endTime - $operation.StartTime).TotalMilliseconds
                    
                    $pattern.Metrics += @{
                        StartTime = $operation.StartTime
                        EndTime = $endTime
                        Duration = $duration
                        StartLine = $operation.StartLine
                        EndLine = $line
                    }
                    
                    $currentOperations.Remove($patternName)
                    Write-SafeLog "Performance tracking completed for $patternName Duration: ${duration}ms" -Level Debug
                }
            }
        }
        
        # Calculate performance statistics
        foreach ($patternName in $performancePatterns.Keys) {
            $metrics = $performancePatterns[$patternName].Metrics
            
            if ($metrics.Count -gt 0) {
                $durations = $metrics | ForEach-Object { $_.Duration }
                
                $performanceAnalysis.Metrics[$patternName] = @{
                    Count = $metrics.Count
                    AverageDuration = [math]::Round(($durations | Measure-Object -Average).Average, 2)
                    MinDuration = ($durations | Measure-Object -Minimum).Minimum
                    MaxDuration = ($durations | Measure-Object -Maximum).Maximum
                    TotalDuration = [math]::Round(($durations | Measure-Object -Sum).Sum, 2)
                    Metrics = $metrics
                }
                
                Write-SafeLog "Performance metrics for $patternName Count: $($metrics.Count), Avg: $($performanceAnalysis.Metrics[$patternName].AverageDuration)ms" -Level Debug
            }
        }
        
        # Generate performance benchmarks
        $performanceAnalysis.Benchmarks = @{
            FastCompilation = 5000    # Under 5 seconds
            AcceptableBuild = 30000   # Under 30 seconds
            FastImport = 2000         # Under 2 seconds
            QuickTest = 10000         # Under 10 seconds
        }
        
        # Generate recommendations based on performance
        foreach ($metricName in $performanceAnalysis.Metrics.Keys) {
            $metric = $performanceAnalysis.Metrics[$metricName]
            $benchmark = switch ($metricName) {
                'CompilationTime' { $performanceAnalysis.Benchmarks.FastCompilation }
                'BuildTime' { $performanceAnalysis.Benchmarks.AcceptableBuild }
                'ImportTime' { $performanceAnalysis.Benchmarks.FastImport }
                'TestTime' { $performanceAnalysis.Benchmarks.QuickTest }
                default { 10000 }
            }
            
            if ($metric.AverageDuration -gt $benchmark) {
                $performanceAnalysis.Recommendations += @{
                    MetricType = $metricName
                    Issue = "Average $metricName exceeds benchmark"
                    CurrentAverage = $metric.AverageDuration
                    Benchmark = $benchmark
                    Suggestion = "Consider optimizing $metricName process"
                    Priority = if ($metric.AverageDuration -gt ($benchmark * 2)) { 'High' } else { 'Medium' }
                }
            }
        }
        
        $stopwatch.Stop()
        
        Write-SafeLog "Unity performance analysis completed in $($stopwatch.ElapsedMilliseconds)ms" -Level Info
        
        return @{
            Success = $true
            Output = $performanceAnalysis
            Error = $null
            PerformanceAnalysis = $performanceAnalysis
            Duration = $stopwatch.ElapsedMilliseconds
        }
    }
    catch {
        Write-SafeLog "Unity performance analysis failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            PerformanceAnalysis = @{
                Status = 'Failed'
                ErrorMessage = $_.ToString()
            }
        }
    }
}

#endregion

#region Trend Analysis

function Invoke-UnityTrendAnalysis {
    <#
    .SYNOPSIS
    Analyzes trends in Unity errors and performance over time.
    
    .DESCRIPTION
    Examines patterns in error frequency, activity levels, and performance
    to identify trends and provide insights.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Starting Unity trend analysis" -Level Info
    
    # Get analysis parameters
    $logPath = $Command.Arguments.LogPath
    $timeRange = $Command.Arguments.TimeRange
    if (-not $timeRange) {
        $timeRange = 7  # Default to 7 days
    }
    
    if (-not $logPath) {
        $logPath = Join-Path $env:LOCALAPPDATA "Unity\Editor\Editor.log"
    }
    
    $trendAnalysis = @{
        LogPath = $logPath
        AnalyzedAt = Get-Date
        TimeRange = $timeRange
        ErrorTrends = @{}
        PerformanceTrends = @{}
        ActivityTrends = @{}
        Insights = @()
    }
    
    Write-SafeLog "Analyzing trends in Unity log over $timeRange days: $logPath" -Level Debug
    
    try {
        # This is a simplified trend analysis - in a real implementation,
        # you would analyze historical data across multiple log files
        
        # Read current log content
        $logContent = Get-Content $logPath -ErrorAction SilentlyContinue
        
        # Analyze error frequency over time (simulated for current log)
        $errorCounts = @{
            'CS0246' = 0
            'CS0103' = 0
            'CS1061' = 0
            'CS0029' = 0
        }
        
        $warningCounts = @{}
        $activityCounts = @{
            'Compilation' = 0
            'Build' = 0
            'Test' = 0
            'Import' = 0
        }
        
        # Count occurrences in current log (safe enumeration)
        foreach ($line in $logContent) {
            # Count errors (clone keys to avoid enumeration modification)
            foreach ($errorType in @($errorCounts.Keys)) {
                if ($line -match "error $errorType") {
                    $errorCounts[$errorType]++
                }
            }
            
            # Count activities
            if ($line -match 'Compilation') { $activityCounts.Compilation++ }
            if ($line -match 'Build') { $activityCounts.Build++ }
            if ($line -match 'Test') { $activityCounts.Test++ }
            if ($line -match 'Import') { $activityCounts.Import++ }
        }
        
        # Generate trend data (simplified)
        $trendAnalysis.ErrorTrends = @{
            CurrentPeriod = $errorCounts
            TrendDirection = 'Stable'  # Would be calculated from historical data
            ChangePercentage = 0       # Would be calculated from historical data
        }
        
        $trendAnalysis.ActivityTrends = @{
            CurrentPeriod = $activityCounts
            MostActiveType = ($activityCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1).Key
            TotalActivity = ($activityCounts.Values | Measure-Object -Sum).Sum
        }
        
        # Generate insights
        $topError = $errorCounts.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 1
        if ($topError.Value -gt 0) {
            $trendAnalysis.Insights += "Most frequent error: $($topError.Key) ($($topError.Value) occurrences)"
        }
        
        $trendAnalysis.Insights += "Most active development area: $($trendAnalysis.ActivityTrends.MostActiveType)"
        
        if ($trendAnalysis.ActivityTrends.TotalActivity -gt 100) {
            $trendAnalysis.Insights += "High development activity detected"
        } elseif ($trendAnalysis.ActivityTrends.TotalActivity -lt 10) {
            $trendAnalysis.Insights += "Low development activity detected"
        }
        
        Write-SafeLog "Unity trend analysis completed. Total activity: $($trendAnalysis.ActivityTrends.TotalActivity)" -Level Info
        
        return @{
            Success = $true
            Output = $trendAnalysis
            Error = $null
            TrendAnalysis = $trendAnalysis
        }
    }
    catch {
        Write-SafeLog "Unity trend analysis failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            TrendAnalysis = @{
                Status = 'Failed'
                ErrorMessage = $_.ToString()
            }
        }
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Invoke-UnityPerformanceAnalysis',
    'Invoke-UnityTrendAnalysis'
)

#endregion

# REFACTORING MARKER: This module was refactored from SafeCommandExecution.psm1 on 2025-08-25
# Original file size: 2860 lines
# This component: Unity performance and trend analysis (lines 1911-2217, ~308 lines)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCks1IQqvoDA6TY
# gGuSuyzYYSYWEq5ZYXRtO6qW2hgnQKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCSqGSIb3DQEBCwUAMC4xLDAqBgNVBAMMI1VuaXR5LUNsYXVk
# ZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MB4XDTI1MDgyMDIxMTUxN1oXDTI2MDgy
# MDIxMzUxN1owLjEsMCoGA1UEAwwjVW5pdHktQ2xhdWRlLUF1dG9tYXRpb24tRGV2
# ZWxvcG1lbnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCx4feqKdUQ
# 6GufY4umNzlM1Pi8aHUGR8HlfhIWFjsrRAxCxhieRlWbHe0Hw+pVBeX76X57e5Pu
# 4Kxxzu+MxMry0NJYf3yOLRTfhYskHBcLraXUCtrMwqnhPKvul6Sx6Lu8vilk605W
# ADJNifl3WFuexVCYJJM9G2mfuYIDN+rZ5zmpn0qCXum49bm629h+HyJ205Zrn9aB
# hIrA4i/JlrAh1kosWnCo62psl7ixbNVqFqwWEt+gAqSeIo4ChwkOQl7GHmk78Q5I
# oRneY4JTVlKzhdZEYhJGFXeoZml/5jcmUcox4UNYrKdokE7z8ZTmyowBOUNS+sHI
# G1TY5DZSb8vdAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUEDDAKBggr
# BgEFBQcDAzAdBgNVHQ4EFgQUfDms7LrGVboHjmwlSyIjYD/JLQwwDQYJKoZIhvcN
# AQELBQADggEBABRMsfT7DzKy+aFi4HDg0MpxmbjQxOH1lzUzanaECRiyA0sn7+sA
# /4jvis1+qC5NjDGkLKOTCuDzIXnBWLCCBugukXbIO7g392ANqKdHjBHw1WlLvMVk
# 4WSmY096lzpvDd3jJApr/Alcp4KmRGNLnQ3vv+F9Uj58Uo1qjs85vt6fl9xe5lo3
# rFahNHL4ngjgyF8emNm7FItJeNtVe08PhFn0caOX0FTzXrZxGGO6Ov8tzf91j/qK
# QdBifG7Fx3FF7DifNqoBBo55a7q0anz30k8p+V0zllrLkgGXfOzXmA1L37Qmt3QB
# FCdJVigjQMuHcrJsWd8rg857Og0un91tfZIxggH0MIIB8AIBATBCMC4xLDAqBgNV
# BAMMI1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50AhB1HRbZIqgr
# lUTwkh3hnGtFMA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKA
# AKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEO
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMh4I848F1DRtqygw9ol8j4t
# NWRPk3qNKjZCtIVOyL3WMA0GCSqGSIb3DQEBAQUABIIBAGRolQW8wgUauU+bHIVc
# lbLm5KjL3fzSScM2DZtTSxNagZiDs6djiCQMpwAgUE5wtoUHSLxv9f0UBS8pDARp
# jzef+5UDJMH3gt4JC5OWfmJK0R4DTaP8nuFQ7IzJ0vjLiGl3YqVDogRs/2bVl3De
# yVj7XP+rv8IbvqBelmAzum7Y9CabH8mmQKTpGWTgmFLcJaprD6mGwH/spBT/ZmpX
# jc9qtatBttt1UhOjpE8GR5tFR6d4ODJkeZHC9DD1Lsci2QEYNR5zE43Qp2g+CVSi
# IjyutD96ddRzTGP0eRsQmkgGjyKG2XjO9QXJ+ZnawJ57STT39Y2ODdGzsvyxBoxV
# zfU=
# SIG # End signature block
