function New-AnalysisTrendReport {
    <#
    .SYNOPSIS
    Generates trend analysis reports from historical static analysis data
    
    .DESCRIPTION
    Analyzes historical SARIF results to identify trends in code quality,
    tracks improvements or regressions, and generates comprehensive reports
    
    .PARAMETER HistoryPath
    Path to directory containing historical SARIF files
    
    .PARAMETER CurrentResults
    Current SARIF analysis results to compare
    
    .PARAMETER TimeRange
    Time range for trend analysis (days)
    
    .PARAMETER OutputFormat
    Output format: HTML, Markdown, JSON, or Console
    
    .PARAMETER IncludeCharts
    Generate visual charts for trends (requires HTML format)
    
    .EXAMPLE
    $current = Invoke-StaticAnalysis -Path "."
    New-AnalysisTrendReport -CurrentResults $current -TimeRange 30 -OutputFormat HTML
    
    .EXAMPLE
    New-AnalysisTrendReport -HistoryPath ".ai/analysis-history" -TimeRange 7 -OutputFormat Markdown
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$HistoryPath = ".ai/analysis-history",
        
        [Parameter()]
        [PSCustomObject]$CurrentResults,
        
        [Parameter()]
        [int]$TimeRange = 30,
        
        [Parameter()]
        [ValidateSet('HTML', 'Markdown', 'JSON', 'Console')]
        [string]$OutputFormat = 'Console',
        
        [Parameter()]
        [switch]$IncludeCharts,
        
        [Parameter()]
        [string]$OutputPath
    )
    
    begin {
        Write-Verbose "Starting trend analysis for past $TimeRange days"
        
        # Ensure history directory exists
        if (-not (Test-Path $HistoryPath)) {
            New-Item -Path $HistoryPath -ItemType Directory -Force | Out-Null
            Write-Verbose "Created history directory: $HistoryPath"
        }
        
        # Initialize trend data structure
        $trendData = @{
            TimeRange = $TimeRange
            StartDate = (Get-Date).AddDays(-$TimeRange)
            EndDate = Get-Date
            DataPoints = @()
            Summary = @{}
            Trends = @{}
        }
    }
    
    process {
        # Save current results if provided
        if ($CurrentResults) {
            $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
            $currentFile = Join-Path $HistoryPath "analysis-$timestamp.sarif"
            $CurrentResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $currentFile -Encoding UTF8
            Write-Verbose "Saved current results to: $currentFile"
        }
        
        # Load historical data
        $historicalFiles = Get-ChildItem -Path $HistoryPath -Filter "*.sarif" | 
            Where-Object { $_.CreationTime -ge $trendData.StartDate } |
            Sort-Object CreationTime
        
        Write-Verbose "Found $($historicalFiles.Count) historical analysis files"
        
        foreach ($file in $historicalFiles) {
            try {
                $sarifData = Get-Content $file.FullName -Raw | ConvertFrom-Json
                
                # Extract metrics from SARIF
                $metrics = @{
                    Timestamp = $file.CreationTime
                    FileName = $file.Name
                    TotalIssues = 0
                    ErrorCount = 0
                    WarningCount = 0
                    NoteCount = 0
                    ByRule = @{}
                    ByFile = @{}
                    ByTool = @{}
                }
                
                foreach ($run in $sarifData.runs) {
                    $toolName = $run.tool.driver.name
                    if (-not $metrics.ByTool.ContainsKey($toolName)) {
                        $metrics.ByTool[$toolName] = @{
                            Total = 0
                            Errors = 0
                            Warnings = 0
                            Notes = 0
                        }
                    }
                    
                    foreach ($result in $run.results) {
                        $metrics.TotalIssues++
                        $metrics.ByTool[$toolName].Total++
                        
                        # Count by severity
                        switch ($result.level) {
                            'error' { 
                                $metrics.ErrorCount++
                                $metrics.ByTool[$toolName].Errors++
                            }
                            'warning' { 
                                $metrics.WarningCount++
                                $metrics.ByTool[$toolName].Warnings++
                            }
                            'note' { 
                                $metrics.NoteCount++
                                $metrics.ByTool[$toolName].Notes++
                            }
                        }
                        
                        # Count by rule
                        $ruleId = $result.ruleId
                        if (-not $metrics.ByRule.ContainsKey($ruleId)) {
                            $metrics.ByRule[$ruleId] = 0
                        }
                        $metrics.ByRule[$ruleId]++
                        
                        # Count by file
                        if ($result.locations -and $result.locations[0].physicalLocation) {
                            $filePath = $result.locations[0].physicalLocation.artifactLocation.uri
                            if (-not $metrics.ByFile.ContainsKey($filePath)) {
                                $metrics.ByFile[$filePath] = 0
                            }
                            $metrics.ByFile[$filePath]++
                        }
                    }
                }
                
                $trendData.DataPoints += $metrics
                
            } catch {
                Write-Warning "Failed to process $($file.Name): $_"
            }
        }
        
        # Calculate trends if we have enough data points
        if ($trendData.DataPoints.Count -ge 2) {
            $first = $trendData.DataPoints[0]
            $last = $trendData.DataPoints[-1]
            
            # Overall trend
            $trendData.Trends.Overall = @{
                TotalChange = $last.TotalIssues - $first.TotalIssues
                ErrorChange = $last.ErrorCount - $first.ErrorCount
                WarningChange = $last.WarningCount - $first.WarningCount
                NoteChange = $last.NoteCount - $first.NoteCount
                PercentageChange = if ($first.TotalIssues -gt 0) {
                    [Math]::Round((($last.TotalIssues - $first.TotalIssues) / $first.TotalIssues) * 100, 2)
                } else { 0 }
            }
            
            # Calculate moving average
            $windowSize = [Math]::Min(5, $trendData.DataPoints.Count)
            $movingAverages = @()
            
            for ($i = $windowSize - 1; $i -lt $trendData.DataPoints.Count; $i++) {
                $window = $trendData.DataPoints[($i - $windowSize + 1)..$i]
                $avg = ($window | Measure-Object -Property TotalIssues -Average).Average
                $movingAverages += [Math]::Round($avg, 2)
            }
            
            $trendData.Trends.MovingAverage = $movingAverages
            
            # Identify top growing issues
            $ruleGrowth = @{}
            foreach ($point in $trendData.DataPoints[-[Math]::Min(5, $trendData.DataPoints.Count)..-1]) {
                foreach ($rule in $point.ByRule.Keys) {
                    if (-not $ruleGrowth.ContainsKey($rule)) {
                        $ruleGrowth[$rule] = 0
                    }
                    $ruleGrowth[$rule] += $point.ByRule[$rule]
                }
            }
            
            $trendData.Trends.TopGrowingRules = $ruleGrowth.GetEnumerator() | 
                Sort-Object Value -Descending | 
                Select-Object -First 10
        }
        
        # Generate summary statistics
        $trendData.Summary = @{
            TotalDataPoints = $trendData.DataPoints.Count
            AverageIssues = if ($trendData.DataPoints.Count -gt 0) {
                [Math]::Round(($trendData.DataPoints | Measure-Object -Property TotalIssues -Average).Average, 2)
            } else { 0 }
            MaxIssues = if ($trendData.DataPoints.Count -gt 0) {
                ($trendData.DataPoints | Measure-Object -Property TotalIssues -Maximum).Maximum
            } else { 0 }
            MinIssues = if ($trendData.DataPoints.Count -gt 0) {
                ($trendData.DataPoints | Measure-Object -Property TotalIssues -Minimum).Minimum
            } else { 0 }
            LatestIssues = if ($trendData.DataPoints.Count -gt 0) {
                $trendData.DataPoints[-1].TotalIssues
            } else { 0 }
        }
    }
    
    end {
        # Generate output based on format
        switch ($OutputFormat) {
            'Console' {
                Write-Host "`n" ("=" * 60) -ForegroundColor Cyan
                Write-Host "Static Analysis Trend Report" -ForegroundColor Cyan
                Write-Host ("=" * 60) -ForegroundColor Cyan
                
                Write-Host "`nTime Range: $($trendData.StartDate.ToString('yyyy-MM-dd')) to $($trendData.EndDate.ToString('yyyy-MM-dd'))" -ForegroundColor Gray
                Write-Host "Data Points: $($trendData.Summary.TotalDataPoints)" -ForegroundColor Gray
                
                if ($trendData.Summary.TotalDataPoints -gt 0) {
                    Write-Host "`nSummary Statistics:" -ForegroundColor Yellow
                    Write-Host "  Current Issues: $($trendData.Summary.LatestIssues)" -ForegroundColor White
                    Write-Host "  Average Issues: $($trendData.Summary.AverageIssues)" -ForegroundColor White
                    Write-Host "  Max Issues: $($trendData.Summary.MaxIssues)" -ForegroundColor White
                    Write-Host "  Min Issues: $($trendData.Summary.MinIssues)" -ForegroundColor White
                }
                
                if ($trendData.Trends.Overall) {
                    Write-Host "`nTrend Analysis:" -ForegroundColor Yellow
                    $trend = $trendData.Trends.Overall
                    
                    $changeColor = if ($trend.TotalChange -lt 0) { 'Green' } 
                                  elseif ($trend.TotalChange -gt 0) { 'Red' } 
                                  else { 'Gray' }
                    
                    Write-Host "  Total Change: $($trend.TotalChange) ($($trend.PercentageChange)%)" -ForegroundColor $changeColor
                    Write-Host "  Error Change: $($trend.ErrorChange)" -ForegroundColor $(if ($trend.ErrorChange -le 0) { 'Green' } else { 'Red' })
                    Write-Host "  Warning Change: $($trend.WarningChange)" -ForegroundColor $(if ($trend.WarningChange -le 0) { 'Green' } else { 'Yellow' })
                    Write-Host "  Note Change: $($trend.NoteChange)" -ForegroundColor Gray
                    
                    if ($trendData.Trends.TopGrowingRules) {
                        Write-Host "`nTop Issues (Recent):" -ForegroundColor Yellow
                        foreach ($rule in $trendData.Trends.TopGrowingRules | Select-Object -First 5) {
                            Write-Host "  $($rule.Name): $($rule.Value) occurrences" -ForegroundColor White
                        }
                    }
                }
                
                # Simple ASCII chart for console
                if ($trendData.DataPoints.Count -gt 1) {
                    Write-Host "`nTrend Chart (Issues over time):" -ForegroundColor Yellow
                    $maxValue = $trendData.Summary.MaxIssues
                    $scale = if ($maxValue -gt 0) { 20 / $maxValue } else { 1 }
                    
                    foreach ($point in $trendData.DataPoints) {
                        $barLength = [Math]::Round($point.TotalIssues * $scale)
                        $bar = "#" * $barLength
                        Write-Host ("  {0:MM/dd} [{1,4}] {2}" -f $point.Timestamp, $point.TotalIssues, $bar) -ForegroundColor Cyan
                    }
                }
            }
            
            'Markdown' {
                $markdown = @"
# Static Analysis Trend Report

**Generated**: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')  
**Time Range**: $($trendData.StartDate.ToString('yyyy-MM-dd')) to $($trendData.EndDate.ToString('yyyy-MM-dd'))  
**Data Points**: $($trendData.Summary.TotalDataPoints)

## Summary Statistics

| Metric | Value |
|--------|-------|
| Current Issues | $($trendData.Summary.LatestIssues) |
| Average Issues | $($trendData.Summary.AverageIssues) |
| Maximum Issues | $($trendData.Summary.MaxIssues) |
| Minimum Issues | $($trendData.Summary.MinIssues) |

"@
                
                if ($trendData.Trends.Overall) {
                    $trend = $trendData.Trends.Overall
                    $trendIcon = if ($trend.TotalChange -lt 0) { "📉" } 
                                elseif ($trend.TotalChange -gt 0) { "📈" } 
                                else { "➡️" }
                    
                    $markdown += @"
## Trend Analysis

| Metric | Change | Percentage |
|--------|--------|------------|
| Total Issues | $($trend.TotalChange) $trendIcon | $($trend.PercentageChange)% |
| Errors | $($trend.ErrorChange) | - |
| Warnings | $($trend.WarningChange) | - |
| Notes | $($trend.NoteChange) | - |

"@
                    
                    if ($trendData.Trends.TopGrowingRules) {
                        $markdown += "`n## Top Issues (Recent)`n`n"
                        $markdown += "| Rule | Occurrences |`n"
                        $markdown += "|------|-------------|`n"
                        foreach ($rule in $trendData.Trends.TopGrowingRules | Select-Object -First 10) {
                            $markdown += "| $($rule.Name) | $($rule.Value) |`n"
                        }
                    }
                }
                
                # Add data table
                if ($trendData.DataPoints.Count -gt 0) {
                    $markdown += "`n## Historical Data`n`n"
                    $markdown += "| Date | Total | Errors | Warnings | Notes |`n"
                    $markdown += "|------|-------|--------|----------|-------|`n"
                    foreach ($point in $trendData.DataPoints) {
                        $markdown += "| $($point.Timestamp.ToString('MM/dd')) | $($point.TotalIssues) | $($point.ErrorCount) | $($point.WarningCount) | $($point.NoteCount) |`n"
                    }
                }
                
                if ($OutputPath) {
                    $markdown | Out-File -FilePath $OutputPath -Encoding UTF8
                    Write-Host "Markdown report saved to: $OutputPath" -ForegroundColor Green
                } else {
                    Write-Output $markdown
                }
            }
            
            'HTML' {
                $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Static Analysis Trend Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        h1 { color: #333; border-bottom: 2px solid #0078d4; padding-bottom: 10px; }
        h2 { color: #0078d4; margin-top: 30px; }
        table { width: 100%; border-collapse: collapse; margin: 20px 0; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background: #0078d4; color: white; }
        tr:hover { background: #f5f5f5; }
        .metric-card { display: inline-block; padding: 15px; margin: 10px; background: #f0f0f0; border-radius: 5px; min-width: 150px; }
        .metric-value { font-size: 24px; font-weight: bold; color: #0078d4; }
        .metric-label { color: #666; font-size: 12px; }
        .trend-up { color: #d73027; }
        .trend-down { color: #1a9850; }
        .trend-neutral { color: #666; }
        #chart { width: 100%; height: 400px; margin: 20px 0; }
    </style>
"@
                
                if ($IncludeCharts) {
                    $html += @"
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
"@
                }
                
                $html += @"
</head>
<body>
    <div class="container">
        <h1>Static Analysis Trend Report</h1>
        <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p><strong>Time Range:</strong> $($trendData.StartDate.ToString('yyyy-MM-dd')) to $($trendData.EndDate.ToString('yyyy-MM-dd'))</p>
        
        <h2>Summary Metrics</h2>
        <div>
            <div class="metric-card">
                <div class="metric-value">$($trendData.Summary.LatestIssues)</div>
                <div class="metric-label">Current Issues</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$($trendData.Summary.AverageIssues)</div>
                <div class="metric-label">Average Issues</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$($trendData.Summary.MaxIssues)</div>
                <div class="metric-label">Max Issues</div>
            </div>
            <div class="metric-card">
                <div class="metric-value">$($trendData.Summary.MinIssues)</div>
                <div class="metric-label">Min Issues</div>
            </div>
        </div>
"@
                
                if ($IncludeCharts -and $trendData.DataPoints.Count -gt 1) {
                    $labels = ($trendData.DataPoints | ForEach-Object { "'$($_.Timestamp.ToString('MM/dd'))'" }) -join ','
                    $totalData = ($trendData.DataPoints | ForEach-Object { $_.TotalIssues }) -join ','
                    $errorData = ($trendData.DataPoints | ForEach-Object { $_.ErrorCount }) -join ','
                    $warningData = ($trendData.DataPoints | ForEach-Object { $_.WarningCount }) -join ','
                    
                    $html += @"
        <h2>Trend Chart</h2>
        <canvas id="trendChart"></canvas>
        <script>
            const ctx = document.getElementById('trendChart').getContext('2d');
            new Chart(ctx, {
                type: 'line',
                data: {
                    labels: [$labels],
                    datasets: [{
                        label: 'Total Issues',
                        data: [$totalData],
                        borderColor: '#0078d4',
                        backgroundColor: 'rgba(0, 120, 212, 0.1)',
                        tension: 0.1
                    }, {
                        label: 'Errors',
                        data: [$errorData],
                        borderColor: '#d73027',
                        backgroundColor: 'rgba(215, 48, 39, 0.1)',
                        tension: 0.1
                    }, {
                        label: 'Warnings',
                        data: [$warningData],
                        borderColor: '#fee08b',
                        backgroundColor: 'rgba(254, 224, 139, 0.1)',
                        tension: 0.1
                    }]
                },
                options: {
                    responsive: true,
                    plugins: {
                        title: {
                            display: true,
                            text: 'Code Quality Trends'
                        }
                    },
                    scales: {
                        y: {
                            beginAtZero: true
                        }
                    }
                }
            });
        </script>
"@
                }
                
                # Add historical data table
                if ($trendData.DataPoints.Count -gt 0) {
                    $html += @"
        <h2>Historical Data</h2>
        <table>
            <thead>
                <tr>
                    <th>Date</th>
                    <th>Total Issues</th>
                    <th>Errors</th>
                    <th>Warnings</th>
                    <th>Notes</th>
                </tr>
            </thead>
            <tbody>
"@
                    foreach ($point in $trendData.DataPoints) {
                        $html += @"
                <tr>
                    <td>$($point.Timestamp.ToString('yyyy-MM-dd HH:mm'))</td>
                    <td>$($point.TotalIssues)</td>
                    <td>$($point.ErrorCount)</td>
                    <td>$($point.WarningCount)</td>
                    <td>$($point.NoteCount)</td>
                </tr>
"@
                    }
                    $html += @"
            </tbody>
        </table>
"@
                }
                
                $html += @"
    </div>
</body>
</html>
"@
                
                if ($OutputPath) {
                    $html | Out-File -FilePath $OutputPath -Encoding UTF8
                    Write-Host "HTML report saved to: $OutputPath" -ForegroundColor Green
                } else {
                    Write-Output $html
                }
            }
            
            'JSON' {
                $jsonOutput = $trendData | ConvertTo-Json -Depth 10
                if ($OutputPath) {
                    $jsonOutput | Out-File -FilePath $OutputPath -Encoding UTF8
                    Write-Host "JSON report saved to: $OutputPath" -ForegroundColor Green
                } else {
                    Write-Output $jsonOutput
                }
            }
        }
        
        # Return trend data object
        return $trendData
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAG6XtRuKlfIYu8
# JXXhwBo7ySLp5qWYqm+khK90Jw5R2aCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIMJczuDm02TpisOYAWMhCsP5
# aZHvNeioY7TGn3p7R5zFMA0GCSqGSIb3DQEBAQUABIIBAIF1vpkVzUn5QezkEDPJ
# Hb6r4Nc1bnPlqR/uvM+fOzB0wmWIV68BKyD+nefbYc43miHtVuvClUheZa29qlRO
# QuA2J3AqEy9NLYXE2LU8SzSvBk+eHpq1TJT2iKWdabyc6irlwd/pC814GaV3wBZv
# Z8YzQCsGo9peHtG+BS18zDouPzSsDw3skzKhUGEkjhtnmHJkyyL+7KXOnnB5yKir
# RfUcOlfsIJPsZlP3m0b0E7tivrKt7IqsTwT1rp2wn0E5Oib1JNPfwbBokQRv3xAu
# jq6bIC0S44XDvd9fnZV16sTbJgiQMVk9CO5pNobyRanSrtVcnYallMz59+T5Wmzt
# KKw=
# SIG # End signature block
