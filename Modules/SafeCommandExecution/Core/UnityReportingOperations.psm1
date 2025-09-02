#Requires -Version 5.1
<#
.SYNOPSIS
    Unity reporting and metrics operations for SafeCommandExecution module.

.DESCRIPTION
    Provides report generation, data export, and analytics metrics extraction
    functionality for Unity analysis results.

.NOTES
    Part of SafeCommandExecution refactored architecture
    Originally from SafeCommandExecution.psm1 (lines 2220-2714)
    Refactoring Date: 2025-08-25
#>

# Import required modules
Import-Module "$PSScriptRoot\SafeCommandCore.psm1" -Force

#region Report Generation

function Invoke-UnityReportGeneration {
    <#
    .SYNOPSIS
    Generates formatted reports from Unity analysis data.
    
    .DESCRIPTION
    Creates HTML, JSON, or CSV reports from Unity analysis results
    with customizable formatting and output options.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Starting Unity report generation" -Level Info
    
    # Get report parameters
    $analysisData = $Command.Arguments.AnalysisData
    $outputFormat = $Command.Arguments.OutputFormat
    $outputPath = $Command.Arguments.OutputPath
    $reportTitle = $Command.Arguments.ReportTitle
    
    if (-not $outputFormat) {
        $outputFormat = 'Html'
    }
    
    if (-not $reportTitle) {
        $reportTitle = "Unity Analysis Report - $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    }
    
    if (-not $outputPath) {
        $outputPath = Join-Path $env:TEMP "UnityAnalysisReport_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    }
    
    $reportGeneration = @{
        Title = $reportTitle
        GeneratedAt = Get-Date
        OutputFormat = $outputFormat
        OutputPath = $outputPath
        Sections = @()
        Success = $false
    }
    
    Write-SafeLog "Generating Unity report in $outputFormat format: $outputPath" -Level Debug
    
    try {
        # Prepare report data structure
        $reportData = @{
            Title = $reportTitle
            GeneratedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            Summary = @{
                TotalErrors = 0
                TotalWarnings = 0
                AnalysisType = 'Comprehensive'
                Duration = '0ms'
            }
            Sections = @()
        }
        
        # Add analysis data to report if provided
        if ($analysisData) {
            if ($analysisData.AnalysisResult) {
                $result = $analysisData.AnalysisResult
                $reportData.Summary.TotalErrors = if ($result.Summary) { $result.Summary.ErrorCount } else { 0 }
                $reportData.Summary.TotalWarnings = if ($result.Summary) { $result.Summary.WarningCount } else { 0 }
            }
            
            # Add sections based on analysis data
            $reportData.Sections += @{
                Title = 'Analysis Summary'
                Content = $analysisData
                Type = 'Data'
            }
        }
        
        # Generate report based on format
        switch ($outputFormat.ToLower()) {
            'html' {
                $htmlContent = @"
<!DOCTYPE html>
<html>
<head>
    <title>$($reportData.Title)</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 15px; border-radius: 5px; }
        .summary { background-color: #e8f4fd; padding: 10px; margin: 10px 0; border-radius: 5px; }
        .error { color: #d32f2f; }
        .warning { color: #f57c00; }
        .success { color: #388e3c; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .section { margin: 20px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>$($reportData.Title)</h1>
        <p>Generated: $($reportData.GeneratedAt)</p>
    </div>
    
    <div class="summary">
        <h2>Summary</h2>
        <p><span class="error">Errors: $($reportData.Summary.TotalErrors)</span> | 
           <span class="warning">Warnings: $($reportData.Summary.TotalWarnings)</span></p>
        <p>Analysis Type: $($reportData.Summary.AnalysisType)</p>
    </div>
    
    <div class="section">
        <h2>Analysis Details</h2>
        <p>Unity analysis completed successfully. Detailed analysis data available in JSON format.</p>
    </div>
</body>
</html>
"@
                
                Set-Content -Path "$outputPath.html" -Value $htmlContent -Encoding UTF8
                $reportGeneration.OutputPath = "$outputPath.html"
                Write-SafeLog "HTML report generated: $outputPath.html" -Level Debug
            }
            
            'json' {
                $jsonContent = $reportData | ConvertTo-Json -Depth 10
                Set-Content -Path "$outputPath.json" -Value $jsonContent -Encoding UTF8
                $reportGeneration.OutputPath = "$outputPath.json"
                Write-SafeLog "JSON report generated: $outputPath.json" -Level Debug
            }
            
            'csv' {
                # Convert analysis data to CSV format
                $csvData = @()
                if ($analysisData -and $analysisData.AnalysisResult -and $analysisData.AnalysisResult.Errors) {
                    foreach ($error in $analysisData.AnalysisResult.Errors) {
                        $csvData += [PSCustomObject]@{
                            Type = 'Error'
                            Category = $error.Category
                            Content = $error.Content
                            FilePath = $error.FilePath
                            ErrorCode = $error.ErrorCode
                        }
                    }
                }
                
                if ($csvData.Count -gt 0) {
                    $csvData | Export-Csv -Path "$outputPath.csv" -NoTypeInformation -Encoding UTF8
                } else {
                    # Create empty CSV with headers
                    "Type,Category,Content,FilePath,ErrorCode" | Set-Content -Path "$outputPath.csv" -Encoding UTF8
                }
                
                $reportGeneration.OutputPath = "$outputPath.csv"
                Write-SafeLog "CSV report generated: $outputPath.csv" -Level Debug
            }
            
            default {
                throw "Unsupported output format: $outputFormat"
            }
        }
        
        $reportGeneration.Success = $true
        
        Write-SafeLog "Unity report generation completed: $($reportGeneration.OutputPath)" -Level Info
        
        return @{
            Success = $true
            Output = $reportGeneration
            Error = $null
            ReportGeneration = $reportGeneration
        }
    }
    catch {
        Write-SafeLog "Unity report generation failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            ReportGeneration = @{
                Status = 'Failed'
                ErrorMessage = $_.ToString()
            }
        }
    }
}

#endregion

#region Data Export

function Export-UnityAnalysisData {
    <#
    .SYNOPSIS
    Exports Unity analysis data to various formats.
    
    .DESCRIPTION
    Exports analysis results to JSON, XML, or CSV formats
    for external processing or archival.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Starting Unity analysis data export" -Level Info
    
    # Get export parameters
    $analysisData = $Command.Arguments.AnalysisData
    $exportFormat = $Command.Arguments.ExportFormat
    $outputPath = $Command.Arguments.OutputPath
    
    if (-not $exportFormat) {
        $exportFormat = 'Json'
    }
    
    if (-not $outputPath) {
        $outputPath = Join-Path $env:TEMP "UnityAnalysisExport_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    }
    
    if (-not $analysisData) {
        throw "Analysis data is required for export operation"
    }
    
    $exportResult = @{
        ExportedAt = Get-Date
        SourceData = $analysisData
        ExportFormat = $exportFormat
        OutputPath = $outputPath
        Success = $false
        Statistics = @{
            RecordsExported = 0
            FileSizeBytes = 0
        }
    }
    
    Write-SafeLog "Exporting Unity analysis data in $exportFormat format: $outputPath" -Level Debug
    
    try {
        switch ($exportFormat.ToLower()) {
            'json' {
                $jsonContent = $analysisData | ConvertTo-Json -Depth 10 -Compress
                Set-Content -Path "$outputPath.json" -Value $jsonContent -Encoding UTF8
                $exportResult.OutputPath = "$outputPath.json"
                $exportResult.Statistics.FileSizeBytes = (Get-Item "$outputPath.json").Length
            }
            
            'xml' {
                # Convert to XML format
                $xmlContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<UnityAnalysis>
    <ExportedAt>$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</ExportedAt>
    <Data>$($analysisData | ConvertTo-Json -Depth 5)</Data>
</UnityAnalysis>
"@
                Set-Content -Path "$outputPath.xml" -Value $xmlContent -Encoding UTF8
                $exportResult.OutputPath = "$outputPath.xml"
                $exportResult.Statistics.FileSizeBytes = (Get-Item "$outputPath.xml").Length
            }
            
            'csv' {
                # Flatten data for CSV export
                $csvData = @()
                
                # Export error data if available
                if ($analysisData.AnalysisResult -and $analysisData.AnalysisResult.Errors) {
                    foreach ($error in $analysisData.AnalysisResult.Errors) {
                        $csvData += [PSCustomObject]@{
                            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                            Type = 'Error'
                            Category = $error.Category
                            Severity = $error.Severity
                            Content = $error.Content
                            FilePath = $error.FilePath
                            LineNumber = $error.LineNumber
                            ErrorCode = $error.ErrorCode
                        }
                    }
                }
                
                # Export warning data if available
                if ($analysisData.AnalysisResult -and $analysisData.AnalysisResult.Warnings) {
                    foreach ($warning in $analysisData.AnalysisResult.Warnings) {
                        $csvData += [PSCustomObject]@{
                            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                            Type = 'Warning'
                            Category = $warning.Category
                            Severity = $warning.Severity
                            Content = $warning.Content
                            FilePath = $warning.FilePath
                            LineNumber = $warning.LineNumber
                            ErrorCode = $warning.ErrorCode
                        }
                    }
                }
                
                if ($csvData.Count -gt 0) {
                    $csvData | Export-Csv -Path "$outputPath.csv" -NoTypeInformation -Encoding UTF8
                    $exportResult.Statistics.RecordsExported = $csvData.Count
                } else {
                    # Create empty CSV with headers
                    "Timestamp,Type,Category,Severity,Content,FilePath,LineNumber,ErrorCode" | Set-Content -Path "$outputPath.csv" -Encoding UTF8
                }
                
                $exportResult.OutputPath = "$outputPath.csv"
                $exportResult.Statistics.FileSizeBytes = (Get-Item "$outputPath.csv").Length
            }
            
            default {
                throw "Unsupported export format: $exportFormat"
            }
        }
        
        $exportResult.Success = $true
        
        Write-SafeLog "Unity analysis data export completed: $($exportResult.OutputPath), Size: $($exportResult.Statistics.FileSizeBytes) bytes" -Level Info
        
        return @{
            Success = $true
            Output = $exportResult
            Error = $null
            ExportResult = $exportResult
        }
    }
    catch {
        Write-SafeLog "Unity analysis data export failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            ExportResult = @{
                Status = 'Failed'
                ErrorMessage = $_.ToString()
            }
        }
    }
}

#endregion

#region Analytics Metrics

function Get-UnityAnalyticsMetrics {
    <#
    .SYNOPSIS
    Extracts analytics metrics from Unity logs.
    
    .DESCRIPTION
    Calculates KPIs, quality scores, and dashboard metrics
    from Unity log analysis results.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [hashtable]$Command,
        
        [Parameter()]
        [int]$TimeoutSeconds = 180
    )
    
    Write-SafeLog "Starting Unity analytics metrics extraction" -Level Info
    
    # Get metrics parameters
    $logPath = $Command.Arguments.LogPath
    $metricTypes = $Command.Arguments.MetricTypes
    
    if (-not $logPath) {
        $logPath = Join-Path $env:LOCALAPPDATA "Unity\Editor\Editor.log"
    }
    
    if (-not $metricTypes) {
        $metricTypes = @('ErrorRate', 'Performance', 'Activity', 'Quality')
    }
    
    $metricsResult = @{
        LogPath = $logPath
        ExtractedAt = Get-Date
        MetricTypes = $metricTypes
        Metrics = @{}
        Dashboard = @{}
        KPIs = @{}
    }
    
    Write-SafeLog "Extracting Unity analytics metrics from: $logPath" -Level Debug
    
    try {
        # Validate log path
        if (-not (Test-Path $logPath)) {
            throw "Unity log file not found: $logPath"
        }
        
        # Read log content
        $logContent = Get-Content $logPath -ErrorAction SilentlyContinue
        $totalLines = $logContent.Count
        
        # Initialize counters
        $errorCount = 0
        $warningCount = 0
        $compilationCount = 0
        $buildCount = 0
        $testCount = 0
        
        # Count various metrics
        foreach ($line in $logContent) {
            if ($line -match 'error CS\d+:') { $errorCount++ }
            if ($line -match 'warning CS\d+:') { $warningCount++ }
            if ($line -match 'Compilation') { $compilationCount++ }
            if ($line -match 'Build') { $buildCount++ }
            if ($line -match 'Test') { $testCount++ }
        }
        
        # Calculate metrics
        $metricsResult.Metrics = @{
            'ErrorRate' = @{
                Value = if ($totalLines -gt 0) { [math]::Round(($errorCount / $totalLines) * 100, 2) } else { 0 }
                Unit = 'Percentage'
                Description = 'Error rate per log lines'
                RawCount = $errorCount
                TotalLines = $totalLines
            }
            'WarningRate' = @{
                Value = if ($totalLines -gt 0) { [math]::Round(($warningCount / $totalLines) * 100, 2) } else { 0 }
                Unit = 'Percentage'
                Description = 'Warning rate per log lines'
                RawCount = $warningCount
            }
            'ActivityLevel' = @{
                Value = $compilationCount + $buildCount + $testCount
                Unit = 'Count'
                Description = 'Total development activity events'
                Breakdown = @{
                    Compilation = $compilationCount
                    Build = $buildCount
                    Test = $testCount
                }
            }
            'QualityScore' = @{
                Value = if (($errorCount + $warningCount) -eq 0) { 100 } else { 
                    [math]::Max(0, [math]::Round(100 - (($errorCount * 10 + $warningCount * 5) / [math]::Max(1, $totalLines) * 100), 2))
                }
                Unit = 'Score'
                Description = 'Code quality score based on error/warning ratio'
                Factors = @{
                    Errors = $errorCount
                    Warnings = $warningCount
                    Impact = 'Errors weighted 2x warnings'
                }
            }
        }
        
        # Generate KPIs for dashboard
        $metricsResult.KPIs = @{
            'OverallHealth' = @{
                Status = if ($metricsResult.Metrics.QualityScore.Value -ge 80) { 'Good' } 
                        elseif ($metricsResult.Metrics.QualityScore.Value -ge 60) { 'Fair' } 
                        else { 'Poor' }
                Score = $metricsResult.Metrics.QualityScore.Value
                Trend = 'Stable'  # Would be calculated from historical data
            }
            'ErrorTrend' = @{
                Current = $errorCount
                Previous = $errorCount  # Would be from historical data
                Change = 0
                Direction = 'Stable'
            }
            'ActivityIndex' = @{
                Level = if ($metricsResult.Metrics.ActivityLevel.Value -ge 50) { 'High' }
                       elseif ($metricsResult.Metrics.ActivityLevel.Value -ge 20) { 'Medium' }
                       else { 'Low' }
                Count = $metricsResult.Metrics.ActivityLevel.Value
            }
        }
        
        # Generate dashboard data
        $metricsResult.Dashboard = @{
            'Summary' = @{
                TotalErrors = $errorCount
                TotalWarnings = $warningCount
                QualityScore = $metricsResult.Metrics.QualityScore.Value
                ActivityLevel = $metricsResult.KPIs.ActivityIndex.Level
                OverallHealth = $metricsResult.KPIs.OverallHealth.Status
            }
            'Charts' = @{
                'ErrorBreakdown' = @{
                    Type = 'Pie'
                    Data = @{
                        Errors = $errorCount
                        Warnings = $warningCount
                        Clean = [math]::Max(0, $totalLines - $errorCount - $warningCount)
                    }
                }
                'ActivityBreakdown' = @{
                    Type = 'Bar'
                    Data = $metricsResult.Metrics.ActivityLevel.Breakdown
                }
            }
        }
        
        Write-SafeLog "Unity analytics metrics extraction completed. Quality Score: $($metricsResult.Metrics.QualityScore.Value), Activity: $($metricsResult.KPIs.ActivityIndex.Level)" -Level Info
        
        return @{
            Success = $true
            Output = $metricsResult
            Error = $null
            MetricsResult = $metricsResult
        }
    }
    catch {
        Write-SafeLog "Unity analytics metrics extraction failed: $($_.Exception.Message)" -Level Error
        return @{
            Success = $false
            Output = $null
            Error = $_.ToString()
            MetricsResult = @{
                Status = 'Failed'
                ErrorMessage = $_.ToString()
            }
        }
    }
}

#endregion

#region Module Exports

Export-ModuleMember -Function @(
    'Invoke-UnityReportGeneration',
    'Export-UnityAnalysisData',
    'Get-UnityAnalyticsMetrics'
)

#endregion

# REFACTORING MARKER: This module was refactored from SafeCommandExecution.psm1 on 2025-08-25
# Original file size: 2860 lines
# This component: Unity reporting and metrics operations (lines 2220-2714, ~497 lines)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB4EGI4TVVtE1aG
# /nP13Zjzn4gSMXAYbbbZv0D4JPNhnqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOQqS452en7aiRfWR7s0gMRH
# CWj7/i6LzguDtmxaVTstMA0GCSqGSIb3DQEBAQUABIIBAHqzgz1j2Bf5zNOyFfVT
# X4lwC4xI3KbY0WsKjw84hyi7gYzvlL80bN1mh+sdX7B38wbW1BZCDNl+50v/qzw3
# uQNSUd4uYbgGsEZKdBduyDb3WWAv6sJdVFcYsPBI/HoHYYy4MSxOxl7XsU+ym0hw
# YtgZJSrjrKbLD1N035Ug3HWbI5Aat+0tIutaxVYdMPT+8vEch3O32e8FnYOhV+eS
# SV/THtrKCxk4/Mh/pTuZjPouYu+PZWW6KTEhQs4ssJB+d/erHTjV16bhSUeGYJxr
# lBjaeEGPvozXHSpiiTkPwo9xKYDwYR2mVtdn/Saoag+EAYhwijd7zCFLqWgtEopD
# 9RU=
# SIG # End signature block
