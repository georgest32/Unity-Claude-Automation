# ReportingExport.psm1
# Performance reporting and export utilities

# Export performance report in various formats
function Export-PerformanceData {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Report,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [ValidateSet('JSON', 'CSV', 'HTML', 'XML')]
        [string]$Format = 'JSON',
        
        [hashtable]$Configuration
    )
    
    Write-Verbose "[ReportingExport] Exporting performance report as $Format to $OutputPath"
    
    # Ensure directory exists
    $directory = [System.IO.Path]::GetDirectoryName($OutputPath)
    if (-not (Test-Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    
    switch ($Format) {
        'JSON' {
            Export-ToJson -Report $Report -OutputPath $OutputPath -Configuration $Configuration
        }
        'CSV' {
            Export-ToCsv -Report $Report -OutputPath $OutputPath
        }
        'HTML' {
            Export-ToHtml -Report $Report -OutputPath $OutputPath -Configuration $Configuration
        }
        'XML' {
            Export-ToXml -Report $Report -OutputPath $OutputPath
        }
    }
    
    Write-Information "[ReportingExport] Performance report exported to: $OutputPath"
    return $OutputPath
}

# Export to JSON format
function Export-ToJson {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Report,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [hashtable]$Configuration
    )
    
    $fullReport = [PSCustomObject]@{
        GeneratedAt = [datetime]::Now
        ThroughputAnalysis = $Report
        Configuration = $Configuration
        Summary = @{
            MeetingTarget = $Report.MeetingTarget
            Recommendation = if ($Report.MeetingTarget) { 
                "Performance targets are being met" 
            } else { 
                "Consider increasing cache size, batch size, or thread count" 
            }
        }
        SystemInfo = @{
            ProcessorCount = [Environment]::ProcessorCount
            TotalMemoryGB = [Math]::Round((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
            OSVersion = [Environment]::OSVersion.ToString()
        }
    }
    
    $fullReport | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
}

# Export to CSV format
function Export-ToCsv {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Report,
        
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    # Flatten for CSV export
    $csvData = [PSCustomObject]@{
        Timestamp = [datetime]::Now
        CurrentThroughput = $Report.CurrentThroughput
        TargetThroughput = $Report.TargetThroughput
        PerformanceRatio = $Report.PerformanceRatio
        AverageThroughput = $Report.AverageThroughput
        PeakThroughput = $Report.PeakThroughput
        MinimumThroughput = $Report.MinimumThroughput
        TotalFilesProcessed = $Report.TotalFilesProcessed
        CacheHitRate = $Report.CacheHitRate
        ProcessingErrors = $Report.ProcessingErrors
        QueueLength = $Report.QueueLength
        MemoryUsageMB = $Report.MemoryUsageMB
        MeetingTarget = $Report.MeetingTarget
        UpTimeMinutes = [Math]::Round($Report.UpTime.TotalMinutes, 2)
    }
    
    $csvData | Export-Csv -Path $OutputPath -NoTypeInformation
}

# Export to HTML format
function Export-ToHtml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Report,
        
        [Parameter(Mandatory)]
        [string]$OutputPath,
        
        [hashtable]$Configuration
    )
    
    $statusClass = if ($Report.MeetingTarget) { 'success' } else { 'warning' }
    $statusText = if ($Report.MeetingTarget) { 'Meeting Target' } else { 'Below Target' }
    
    $bottlenecksHtml = if ($Report.Bottlenecks -and $Report.Bottlenecks.Count -gt 0) {
        $items = $Report.Bottlenecks.GetEnumerator() | ForEach-Object {
            "<li><strong>$($_.Key):</strong> $($_.Value)</li>"
        }
        "<ul>$($items -join '')</ul>"
    } else {
        "<p>No bottlenecks detected</p>"
    }
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Performance Optimization Report</title>
    <style>
        body { 
            font-family: 'Segoe UI', Arial, sans-serif; 
            margin: 20px; 
            background-color: #f5f5f5;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        h1 { color: #333; border-bottom: 3px solid #007acc; padding-bottom: 10px; }
        h2 { color: #555; margin-top: 30px; }
        .metric { 
            margin: 15px 0; 
            padding: 10px;
            background-color: #f8f9fa;
            border-left: 4px solid #007acc;
        }
        .success { color: #28a745; font-weight: bold; }
        .warning { color: #ffc107; font-weight: bold; }
        .error { color: #dc3545; font-weight: bold; }
        .status-badge {
            display: inline-block;
            padding: 5px 15px;
            border-radius: 20px;
            font-weight: bold;
        }
        .status-badge.success { background-color: #d4edda; color: #155724; }
        .status-badge.warning { background-color: #fff3cd; color: #856404; }
        table {
            width: 100%;
            border-collapse: collapse;
            margin-top: 20px;
        }
        th, td {
            padding: 10px;
            text-align: left;
            border-bottom: 1px solid #ddd;
        }
        th {
            background-color: #f8f9fa;
            font-weight: 600;
        }
        .chart {
            margin: 20px 0;
            padding: 20px;
            background-color: #f8f9fa;
            border-radius: 4px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Performance Optimization Report</h1>
        <p><strong>Generated:</strong> $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</p>
        <p><strong>Status:</strong> <span class="status-badge $statusClass">$statusText</span></p>
        
        <h2>Throughput Analysis</h2>
        <table>
            <tr>
                <th>Metric</th>
                <th>Value</th>
                <th>Target</th>
                <th>Status</th>
            </tr>
            <tr>
                <td>Current Throughput</td>
                <td>$($Report.CurrentThroughput) files/sec</td>
                <td>$($Report.TargetThroughput) files/sec</td>
                <td class="$statusClass">$([Math]::Round($Report.PerformanceRatio, 1))%</td>
            </tr>
            <tr>
                <td>Average Throughput</td>
                <td>$($Report.AverageThroughput) files/sec</td>
                <td>-</td>
                <td>-</td>
            </tr>
            <tr>
                <td>Peak Throughput</td>
                <td>$($Report.PeakThroughput) files/sec</td>
                <td>-</td>
                <td>-</td>
            </tr>
        </table>
        
        <h2>Processing Statistics</h2>
        <div class="metric"><strong>Total Files Processed:</strong> $($Report.TotalFilesProcessed)</div>
        <div class="metric"><strong>Cache Hit Rate:</strong> $($Report.CacheHitRate)%</div>
        <div class="metric"><strong>Queue Length:</strong> $($Report.QueueLength) items</div>
        <div class="metric"><strong>Memory Usage:</strong> $($Report.MemoryUsageMB) MB</div>
        <div class="metric"><strong>Processing Errors:</strong> <span class="$(if($Report.ProcessingErrors -gt 0){'error'}else{'success'})">$($Report.ProcessingErrors)</span></div>
        <div class="metric"><strong>Uptime:</strong> $([Math]::Round($Report.UpTime.TotalHours, 2)) hours</div>
        
        <h2>Bottleneck Analysis</h2>
        $bottlenecksHtml
        
        <h2>Recommendations</h2>
        <div class="chart">
            $(if ($Report.MeetingTarget) {
                "<p class='success'>✓ Performance targets are being met successfully.</p>"
            } else {
                "<p class='warning'>⚠ Performance is below target. Consider:</p>
                <ul>
                    <li>Increasing cache size for better hit rate</li>
                    <li>Adjusting batch size for optimal throughput</li>
                    <li>Adding more worker threads if CPU allows</li>
                    <li>Reviewing and addressing identified bottlenecks</li>
                </ul>"
            })
        </div>
        
        <footer style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #ddd; text-align: center; color: #666;">
            <p>Generated by Unity-Claude-PerformanceOptimizer</p>
        </footer>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $OutputPath -Encoding UTF8
}

# Export to XML format
function Export-ToXml {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject]$Report,
        
        [Parameter(Mandatory)]
        [string]$OutputPath
    )
    
    $Report | Export-Clixml -Path $OutputPath -Depth 10
}

# Generate summary statistics
function Get-PerformanceSummary {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Metrics,
        
        [int]$TargetThroughput
    )
    
    $summary = [PSCustomObject]@{
        Status = if ($Metrics.FilesPerSecond -ge $TargetThroughput) { 'Optimal' } 
                 elseif ($Metrics.FilesPerSecond -ge ($TargetThroughput * 0.8)) { 'Acceptable' } 
                 else { 'Needs Improvement' }
        TotalProcessed = $Metrics.TotalFilesProcessed
        CurrentRate = "$($Metrics.FilesPerSecond) files/sec"
        CacheEfficiency = "$($Metrics.CacheHitRate)%"
        ErrorRate = if ($Metrics.TotalFilesProcessed -gt 0) { 
            [Math]::Round(($Metrics.ProcessingErrors / $Metrics.TotalFilesProcessed) * 100, 2) 
        } else { 0 }
        Timestamp = [datetime]::Now
    }
    
    return $summary
}

Export-ModuleMember -Function @(
    'Export-PerformanceData',
    'Export-ToJson',
    'Export-ToCsv',
    'Export-ToHtml',
    'Export-ToXml',
    'Get-PerformanceSummary'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAUEW0X951eCdNo
# VMLI7eXfL6I0J2lVT0s6OhebUPSMy6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILXLwQMkwu0mUIEmHGLYkfSg
# ai9A1VZ8DdskRBqbyI1sMA0GCSqGSIb3DQEBAQUABIIBAHIl8DXH17MqJ5D+tACa
# 1zHwjlHVqBFlWbBmX2MsL4sh4DNwLqltJ/AbDzeD1kwAU0WKU4lJDoCqxUL1+eHL
# d8d4RyK51lI63IaO3KGdY8mGuuRFZHU6U/QRrAwHcgIbEu8md/8EtHNRHpdEueah
# RrQhjctpsyiYEajG5osWpkxQ8bemP8GP8/jp6I1H0xvgfw+fNLWxnlFnlANj7MnS
# lBz6J4uULIGqpFON+xq59EAPARP3qon0nLu2VrFY4at8rDEPU21tN9Y7K5hiWiua
# B4VRFlAQSeO59Vaek6i1uBeZVaTQMnj94ToSeTS3wh2ly+HkZw9YBOGpUd9XiLBH
# QjE=
# SIG # End signature block
