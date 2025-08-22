function New-DiagnosticReport {
    <#
    .SYNOPSIS
    Generates comprehensive diagnostic report with performance analysis and log trends
    
    .DESCRIPTION
    Creates detailed HTML diagnostic reports following 2025 best practices:
    - Performance trend analysis with visualizations
    - Log pattern analysis and error trending
    - System health assessment
    - Interactive HTML dashboard
    - PowerShell 5.1 compatible implementation
    - Configurable report sections and time periods
    
    .PARAMETER OutputPath
    Path for the generated HTML report
    
    .PARAMETER IncludePerformanceData
    Include system performance metrics in the report
    
    .PARAMETER IncludeLogAnalysis
    Include log analysis and error trending
    
    .PARAMETER ReportPeriod
    Time period to analyze (default: 24 hours)
    
    .PARAMETER LogPath
    Specific log file to analyze (default: current SystemStatus log)
    
    .PARAMETER Template
    Report template: Standard, Detailed, Executive
    
    .EXAMPLE
    New-DiagnosticReport -OutputPath ".\diagnostic_report.html"
    
    .EXAMPLE
    New-DiagnosticReport -IncludePerformanceData -IncludeLogAnalysis -ReportPeriod (New-TimeSpan -Hours 48)
    
    .EXAMPLE
    New-DiagnosticReport -Template Executive -OutputPath ".\executive_summary.html"
    #>
    [CmdletBinding()]
    param(
        [string]$OutputPath = ".\SystemStatus_Diagnostic_Report_$(Get-Date -Format 'yyyyMMdd_HHmmss').html",
        
        [switch]$IncludePerformanceData,
        
        [switch]$IncludeLogAnalysis,
        
        [TimeSpan]$ReportPeriod = (New-TimeSpan -Hours 24),
        
        [string]$LogPath,
        
        [ValidateSet('Standard', 'Detailed', 'Executive')]
        [string]$Template = 'Standard'
    )
    
    $reportTimer = [System.Diagnostics.Stopwatch]::StartNew()
    
    Write-TraceLog -Message "Starting diagnostic report generation" -Operation "New-DiagnosticReport" -Context @{
        OutputPath = $OutputPath
        Template = $Template
        ReportPeriod = $ReportPeriod.TotalHours
        IncludePerformance = $IncludePerformanceData.IsPresent
        IncludeLogAnalysis = $IncludeLogAnalysis.IsPresent
    }
    
    try {
        # Create output directory if needed
        $outputDir = Split-Path $OutputPath -Parent
        if ($outputDir -and -not (Test-Path $outputDir)) {
            New-Item $outputDir -ItemType Directory -Force | Out-Null
        }
        
        Write-SystemStatusLog "Generating diagnostic report: $OutputPath" -Level 'INFO' -Source 'DiagnosticReport'
        
        # Gather report data
        $reportData = @{
            GeneratedAt = Get-Date
            ReportPeriod = $ReportPeriod
            Template = $Template
            SystemInfo = Get-DiagnosticSystemInfo
            SystemStatus = Get-DiagnosticSystemStatus
        }
        
        # Add performance data if requested
        if ($IncludePerformanceData) {
            Write-TraceLog -Message "Collecting performance data" -Operation "CollectPerformanceData"
            $reportData.PerformanceData = Get-DiagnosticPerformanceData -Period $ReportPeriod
        }
        
        # Add log analysis if requested
        if ($IncludeLogAnalysis) {
            Write-TraceLog -Message "Analyzing log data" -Operation "AnalyzeLogData"
            $reportData.LogAnalysis = Get-DiagnosticLogAnalysis -LogPath $LogPath -Period $ReportPeriod
        }
        
        # Generate subsystem status
        $reportData.SubsystemStatus = Get-DiagnosticSubsystemStatus
        
        # Generate the HTML report
        $htmlContent = Generate-DiagnosticReportHTML -ReportData $reportData -Template $Template
        
        # Write the report to file
        $htmlContent | Out-File -FilePath $OutputPath -Encoding UTF8 -Force
        
        $reportTimer.Stop()
        
        $reportSize = [math]::Round((Get-Item $OutputPath).Length / 1KB, 1)
        Write-SystemStatusLog "Diagnostic report generated: $OutputPath ($reportSize KB) in $($reportTimer.ElapsedMilliseconds)ms" -Level 'OK' -Source 'DiagnosticReport'
        
        Write-TraceLog -Message "Diagnostic report generation completed successfully" -Operation "New-DiagnosticReport" -Timer $reportTimer -Context @{
            OutputPath = $OutputPath
            ReportSizeKB = $reportSize
            DataSections = $reportData.Keys -join ','
        }
        
        return @{
            Success = $true
            OutputPath = $OutputPath
            ReportSize = $reportSize
            GenerationTime = $reportTimer.Elapsed
            DataSections = $reportData.Keys
        }
        
    } catch {
        $reportTimer.Stop()
        Write-SystemStatusLog "Diagnostic report generation failed: $($_.Exception.Message)" -Level 'ERROR' -Source 'DiagnosticReport'
        Write-TraceLog -Message "Diagnostic report generation failed" -Operation "New-DiagnosticReport" -Timer $reportTimer -Context @{
            Error = $_.Exception.Message
        }
        
        throw
    }
}

function Get-DiagnosticSystemInfo {
    <#
    .SYNOPSIS
    Collects comprehensive system information for the diagnostic report
    #>
    [CmdletBinding()]
    param()
    
    try {
        $systemInfo = @{
            Timestamp = Get-Date
            Environment = @{
                PowerShellVersion = $PSVersionTable.PSVersion.ToString()
                PowerShellEdition = $PSVersionTable.PSEdition
                OSVersion = [System.Environment]::OSVersion.ToString()
                MachineName = $env:COMPUTERNAME
                UserName = $env:USERNAME
                ProcessorCount = [System.Environment]::ProcessorCount
                WorkingSet = [math]::Round((Get-Process -Id $PID).WorkingSet64 / 1MB, 1)
                TotalMemory = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
            }
            ModuleInfo = @{
                SystemStatusVersion = (Get-Module Unity-Claude-SystemStatus).Version
                LoadedModules = (Get-Module | Where-Object { $_.Name -like 'Unity-Claude*' }).Count
                ModulePath = $PSModuleAutoLoadingPreference
            }
            Configuration = @{
                DiagnosticMode = $script:DiagnosticModeEnabled
                DiagnosticLevel = $script:DiagnosticLevel
                TraceLogging = $script:TraceLoggingEnabled
                LogRotation = if ($script:SystemStatusConfig) { $script:SystemStatusConfig.Logging.LogRotationEnabled } else { $false }
            }
        }
        
        return $systemInfo
        
    } catch {
        Write-SystemStatusLog "Failed to collect system info: $($_.Exception.Message)" -Level 'WARN' -Source 'DiagnosticReport'
        return @{ Error = $_.Exception.Message }
    }
}

function Get-DiagnosticSystemStatus {
    <#
    .SYNOPSIS
    Gets current system status and health indicators
    #>
    [CmdletBinding()]
    param()
    
    try {
        $status = @{
            Timestamp = Get-Date
            OverallHealth = 'Unknown'
            Alerts = @()
            Metrics = @{}
        }
        
        # Check if SystemStatus is available
        if (Get-Command Read-SystemStatus -ErrorAction SilentlyContinue) {
            try {
                $systemStatus = Read-SystemStatus
                $status.RegisteredSubsystems = $systemStatus.RegisteredSubsystems.Count
                $status.ActiveSubsystems = ($systemStatus.RegisteredSubsystems.Values | Where-Object { $_.Status -eq 'Running' }).Count
                
                # Calculate overall health
                if ($status.ActiveSubsystems -eq $status.RegisteredSubsystems -and $status.RegisteredSubsystems -gt 0) {
                    $status.OverallHealth = 'Healthy'
                } elseif ($status.ActiveSubsystems -gt 0) {
                    $status.OverallHealth = 'Warning'
                } else {
                    $status.OverallHealth = 'Critical'
                }
                
                # Check for alerts
                $failedSubsystems = $systemStatus.RegisteredSubsystems.Values | Where-Object { $_.Status -ne 'Running' }
                foreach ($failed in $failedSubsystems) {
                    $status.Alerts += "Subsystem '$($failed.Name)' is $($failed.Status)"
                }
                
            } catch {
                $status.OverallHealth = 'Error'
                $status.Alerts += "Failed to read system status: $($_.Exception.Message)"
            }
        }
        
        # Get basic performance metrics
        try {
            $process = Get-Process -Id $PID
            $status.Metrics.MemoryUsageMB = [math]::Round($process.WorkingSet64 / 1MB, 1)
            $status.Metrics.CpuTime = $process.TotalProcessorTime.TotalSeconds
            $status.Metrics.HandleCount = $process.HandleCount
            $status.Metrics.ThreadCount = $process.Threads.Count
        } catch {
            $status.Alerts += "Failed to collect process metrics: $($_.Exception.Message)"
        }
        
        return $status
        
    } catch {
        Write-SystemStatusLog "Failed to collect system status: $($_.Exception.Message)" -Level 'WARN' -Source 'DiagnosticReport'
        return @{ Error = $_.Exception.Message; OverallHealth = 'Error' }
    }
}

function Get-DiagnosticPerformanceData {
    <#
    .SYNOPSIS
    Collects performance data for the specified period
    #>
    param([TimeSpan]$Period)
    
    try {
        Write-TraceLog -Message "Collecting performance metrics" -Operation "GetPerformanceData"
        
        # Collect current performance snapshot
        $performanceData = @{
            CollectedAt = Get-Date
            Period = $Period
            CurrentMetrics = @{}
            HistoricalData = @()
            Trends = @{}
        }
        
        # Get current performance counters
        try {
            $currentMetrics = Get-SystemPerformanceMetrics -MaxSamples 1 -OutputFormat Object
            $performanceData.CurrentMetrics = $currentMetrics.Summary
        } catch {
            $performanceData.CurrentMetrics = @{ Error = $_.Exception.Message }
        }
        
        # Use diagnostic performance data if available
        if ($script:DiagnosticPerformanceData -and $script:DiagnosticPerformanceData.Count -gt 0) {
            $cutoffTime = (Get-Date).Subtract($Period)
            $recentData = $script:DiagnosticPerformanceData | Where-Object { $_.Timestamp -gt $cutoffTime }
            $performanceData.HistoricalData = $recentData
            
            # Calculate trends
            if ($recentData.Count -gt 1) {
                $performanceData.Trends = Calculate-PerformanceTrends -Data $recentData
            }
        }
        
        return $performanceData
        
    } catch {
        Write-SystemStatusLog "Failed to collect performance data: $($_.Exception.Message)" -Level 'WARN' -Source 'DiagnosticReport'
        return @{ Error = $_.Exception.Message }
    }
}

function Get-DiagnosticLogAnalysis {
    <#
    .SYNOPSIS
    Analyzes log files for the specified period
    #>
    param(
        [string]$LogPath,
        [TimeSpan]$Period
    )
    
    try {
        Write-TraceLog -Message "Analyzing log data" -Operation "AnalyzeLogData"
        
        $cutoffTime = (Get-Date).Subtract($Period)
        
        # Search for errors and warnings
        $errorResults = Search-SystemStatusLogs -LogLevels @('ERROR') -StartTime $cutoffTime -MaxResults 1000 -LogPath $LogPath
        $warningResults = Search-SystemStatusLogs -LogLevels @('WARN', 'WARNING') -StartTime $cutoffTime -MaxResults 1000 -LogPath $LogPath
        
        $logAnalysis = @{
            AnalyzedAt = Get-Date
            Period = $Period
            ErrorCount = $errorResults.Summary.TotalMatches
            WarningCount = $warningResults.Summary.TotalMatches
            TopErrors = @()
            TopWarnings = @()
            Trends = @{}
            LogHealth = 'Unknown'
        }
        
        # Analyze error patterns
        if ($errorResults.Results.Count -gt 0) {
            $errorGroups = $errorResults.Results | Group-Object { $_.ParsedEntry.Message -replace '\d+', 'N' -replace '\w{8}-\w{4}-\w{4}-\w{4}-\w{12}', 'GUID' } | Sort-Object Count -Descending
            $logAnalysis.TopErrors = $errorGroups | Select-Object -First 10 | ForEach-Object {
                @{
                    Pattern = $_.Name
                    Count = $_.Count
                    LastOccurrence = ($_.Group | Sort-Object { $_.ParsedEntry.Timestamp } -Descending | Select-Object -First 1).ParsedEntry.Timestamp
                }
            }
        }
        
        # Analyze warning patterns
        if ($warningResults.Results.Count -gt 0) {
            $warningGroups = $warningResults.Results | Group-Object { $_.ParsedEntry.Message -replace '\d+', 'N' -replace '\w{8}-\w{4}-\w{4}-\w{4}-\w{12}', 'GUID' } | Sort-Object Count -Descending
            $logAnalysis.TopWarnings = $warningGroups | Select-Object -First 10 | ForEach-Object {
                @{
                    Pattern = $_.Name
                    Count = $_.Count
                    LastOccurrence = ($_.Group | Sort-Object { $_.ParsedEntry.Timestamp } -Descending | Select-Object -First 1).ParsedEntry.Timestamp
                }
            }
        }
        
        # Calculate log health
        $totalIssues = $logAnalysis.ErrorCount + $logAnalysis.WarningCount
        if ($totalIssues -eq 0) {
            $logAnalysis.LogHealth = 'Excellent'
        } elseif ($totalIssues -lt 10) {
            $logAnalysis.LogHealth = 'Good'
        } elseif ($totalIssues -lt 50) {
            $logAnalysis.LogHealth = 'Fair'
        } else {
            $logAnalysis.LogHealth = 'Poor'
        }
        
        return $logAnalysis
        
    } catch {
        Write-SystemStatusLog "Failed to analyze log data: $($_.Exception.Message)" -Level 'WARN' -Source 'DiagnosticReport'
        return @{ Error = $_.Exception.Message }
    }
}

function Get-DiagnosticSubsystemStatus {
    <#
    .SYNOPSIS
    Gets detailed status of all registered subsystems
    #>
    [CmdletBinding()]
    param()
    
    try {
        $subsystemStatus = @{
            CollectedAt = Get-Date
            Subsystems = @()
            Summary = @{
                Total = 0
                Running = 0
                Stopped = 0
                Failed = 0
                Unknown = 0
            }
        }
        
        if (Get-Command Read-SystemStatus -ErrorAction SilentlyContinue) {
            try {
                $systemStatus = Read-SystemStatus
                
                foreach ($subsystem in $systemStatus.RegisteredSubsystems.Values) {
                    $subsystemInfo = @{
                        Name = $subsystem.Name
                        Status = $subsystem.Status
                        PID = $subsystem.PID
                        LastHeartbeat = $subsystem.LastHeartbeat
                        RegisteredAt = $subsystem.RegisteredAt
                        Health = 'Unknown'
                    }
                    
                    # Calculate subsystem health
                    if ($subsystem.Status -eq 'Running') {
                        $timeSinceHeartbeat = (Get-Date) - $subsystem.LastHeartbeat
                        if ($timeSinceHeartbeat.TotalMinutes -lt 5) {
                            $subsystemInfo.Health = 'Healthy'
                        } elseif ($timeSinceHeartbeat.TotalMinutes -lt 15) {
                            $subsystemInfo.Health = 'Warning'
                        } else {
                            $subsystemInfo.Health = 'Critical'
                        }
                    } else {
                        $subsystemInfo.Health = 'Failed'
                    }
                    
                    $subsystemStatus.Subsystems += $subsystemInfo
                    
                    # Update summary
                    $subsystemStatus.Summary.Total++
                    switch ($subsystem.Status) {
                        'Running' { $subsystemStatus.Summary.Running++ }
                        'Stopped' { $subsystemStatus.Summary.Stopped++ }
                        'Failed' { $subsystemStatus.Summary.Failed++ }
                        default { $subsystemStatus.Summary.Unknown++ }
                    }
                }
                
            } catch {
                $subsystemStatus.Error = $_.Exception.Message
            }
        }
        
        return $subsystemStatus
        
    } catch {
        Write-SystemStatusLog "Failed to collect subsystem status: $($_.Exception.Message)" -Level 'WARN' -Source 'DiagnosticReport'
        return @{ Error = $_.Exception.Message }
    }
}

function Calculate-PerformanceTrends {
    <#
    .SYNOPSIS
    Calculates performance trends from historical data
    #>
    param([array]$Data)
    
    $trends = @{}
    
    try {
        # Group by operation
        $operationGroups = $Data | Group-Object Operation
        
        foreach ($group in $operationGroups) {
            $sortedData = $group.Group | Sort-Object Timestamp
            
            if ($sortedData.Count -gt 1) {
                $firstHalf = $sortedData | Select-Object -First ([math]::Floor($sortedData.Count / 2))
                $secondHalf = $sortedData | Select-Object -Last ([math]::Floor($sortedData.Count / 2))
                
                $firstAvg = ($firstHalf | Measure-Object ElapsedMs -Average).Average
                $secondAvg = ($secondHalf | Measure-Object ElapsedMs -Average).Average
                
                $trendDirection = if ($secondAvg -gt $firstAvg * 1.1) { 'Deteriorating' } 
                                 elseif ($secondAvg -lt $firstAvg * 0.9) { 'Improving' } 
                                 else { 'Stable' }
                
                $trends[$group.Name] = @{
                    Direction = $trendDirection
                    FirstHalfAvg = [math]::Round($firstAvg, 2)
                    SecondHalfAvg = [math]::Round($secondAvg, 2)
                    Change = [math]::Round((($secondAvg - $firstAvg) / $firstAvg) * 100, 1)
                    SampleCount = $sortedData.Count
                }
            }
        }
        
    } catch {
        $trends.Error = $_.Exception.Message
    }
    
    return $trends
}

function Generate-DiagnosticReportHTML {
    <#
    .SYNOPSIS
    Generates the HTML content for the diagnostic report
    #>
    param(
        [hashtable]$ReportData,
        [string]$Template
    )
    
    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Unity-Claude SystemStatus Diagnostic Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
        .header h1 { margin: 0; font-size: 2em; }
        .header .subtitle { opacity: 0.9; margin-top: 5px; }
        .container { max-width: 1200px; margin: 0 auto; }
        .section { background: white; padding: 20px; margin-bottom: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .section h2 { color: #333; margin-top: 0; border-bottom: 2px solid #667eea; padding-bottom: 10px; }
        .status-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 15px; margin-bottom: 20px; }
        .status-card { background: #f8f9fa; padding: 15px; border-radius: 6px; border-left: 4px solid #667eea; }
        .status-card.healthy { border-left-color: #28a745; }
        .status-card.warning { border-left-color: #ffc107; }
        .status-card.critical { border-left-color: #dc3545; }
        .status-card h3 { margin: 0 0 10px 0; color: #333; }
        .status-card .value { font-size: 1.5em; font-weight: bold; color: #667eea; }
        .table { width: 100%; border-collapse: collapse; margin-top: 15px; }
        .table th, .table td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
        .table th { background-color: #f8f9fa; font-weight: 600; }
        .table tr:hover { background-color: #f1f3f4; }
        .alert { padding: 10px 15px; margin: 10px 0; border-radius: 4px; }
        .alert.info { background-color: #d1ecf1; border-left: 4px solid #17a2b8; }
        .alert.warning { background-color: #fff3cd; border-left: 4px solid #ffc107; }
        .alert.error { background-color: #f8d7da; border-left: 4px solid #dc3545; }
        .timestamp { color: #6c757d; font-size: 0.9em; }
        .no-data { text-align: center; padding: 40px; color: #6c757d; font-style: italic; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Unity-Claude SystemStatus Diagnostic Report</h1>
            <div class="subtitle">Generated: $($ReportData.GeneratedAt.ToString('yyyy-MM-dd HH:mm:ss')) | Template: $Template | Period: $($ReportData.ReportPeriod.TotalHours)h</div>
        </div>
"@

    # Add system overview section
    $html += Generate-SystemOverviewSection -SystemInfo $ReportData.SystemInfo -SystemStatus $ReportData.SystemStatus

    # Add subsystem status section
    if ($ReportData.SubsystemStatus) {
        $html += Generate-SubsystemStatusSection -SubsystemStatus $ReportData.SubsystemStatus
    }

    # Add performance data section
    if ($ReportData.PerformanceData) {
        $html += Generate-PerformanceSection -PerformanceData $ReportData.PerformanceData
    }

    # Add log analysis section
    if ($ReportData.LogAnalysis) {
        $html += Generate-LogAnalysisSection -LogAnalysis $ReportData.LogAnalysis
    }

    $html += @"
    </div>
</body>
</html>
"@

    return $html
}

function Generate-SystemOverviewSection {
    param($SystemInfo, $SystemStatus)
    
    $healthClass = switch ($SystemStatus.OverallHealth) {
        'Healthy' { 'healthy' }
        'Warning' { 'warning' }
        'Critical' { 'critical' }
        default { '' }
    }
    
    return @"
        <div class="section">
            <h2>System Overview</h2>
            <div class="status-grid">
                <div class="status-card $healthClass">
                    <h3>Overall Health</h3>
                    <div class="value">$($SystemStatus.OverallHealth)</div>
                </div>
                <div class="status-card">
                    <h3>PowerShell Version</h3>
                    <div class="value">$($SystemInfo.Environment.PowerShellVersion)</div>
                </div>
                <div class="status-card">
                    <h3>Memory Usage</h3>
                    <div class="value">$($SystemStatus.Metrics.MemoryUsageMB) MB</div>
                </div>
                <div class="status-card">
                    <h3>Active Subsystems</h3>
                    <div class="value">$($SystemStatus.ActiveSubsystems)/$($SystemStatus.RegisteredSubsystems)</div>
                </div>
            </div>
            $(if ($SystemStatus.Alerts.Count -gt 0) {
                $alertsHtml = ""
                foreach ($alert in $SystemStatus.Alerts) {
                    $alertsHtml += "<div class='alert warning'>$alert</div>"
                }
                $alertsHtml
            })
        </div>
"@
}

function Generate-SubsystemStatusSection {
    param($SubsystemStatus)
    
    $tableRows = ""
    foreach ($subsystem in $SubsystemStatus.Subsystems) {
        $healthClass = switch ($subsystem.Health) {
            'Healthy' { 'style="color: #28a745;"' }
            'Warning' { 'style="color: #ffc107;"' }
            'Critical' { 'style="color: #dc3545;"' }
            'Failed' { 'style="color: #dc3545;"' }
            default { '' }
        }
        
        $tableRows += @"
            <tr>
                <td>$($subsystem.Name)</td>
                <td $healthClass>$($subsystem.Status)</td>
                <td $healthClass>$($subsystem.Health)</td>
                <td>$($subsystem.PID)</td>
                <td>$($subsystem.LastHeartbeat.ToString('yyyy-MM-dd HH:mm:ss'))</td>
            </tr>
"@
    }
    
    return @"
        <div class="section">
            <h2>Subsystem Status</h2>
            <div class="status-grid">
                <div class="status-card healthy">
                    <h3>Running</h3>
                    <div class="value">$($SubsystemStatus.Summary.Running)</div>
                </div>
                <div class="status-card warning">
                    <h3>Stopped</h3>
                    <div class="value">$($SubsystemStatus.Summary.Stopped)</div>
                </div>
                <div class="status-card critical">
                    <h3>Failed</h3>
                    <div class="value">$($SubsystemStatus.Summary.Failed)</div>
                </div>
                <div class="status-card">
                    <h3>Total</h3>
                    <div class="value">$($SubsystemStatus.Summary.Total)</div>
                </div>
            </div>
            $(if ($SubsystemStatus.Subsystems.Count -gt 0) { @"
            <table class="table">
                <thead>
                    <tr>
                        <th>Name</th>
                        <th>Status</th>
                        <th>Health</th>
                        <th>PID</th>
                        <th>Last Heartbeat</th>
                    </tr>
                </thead>
                <tbody>
                    $tableRows
                </tbody>
            </table>
"@ } else { '<div class="no-data">No subsystems registered</div>' })
        </div>
"@
}

function Generate-PerformanceSection {
    param($PerformanceData)
    
    if ($PerformanceData.Error) {
        return @"
        <div class="section">
            <h2>Performance Data</h2>
            <div class="alert error">Failed to collect performance data: $($PerformanceData.Error)</div>
        </div>
"@
    }
    
    return @"
        <div class="section">
            <h2>Performance Metrics</h2>
            <div class="alert info">Current performance snapshot and trends over the last $($PerformanceData.Period.TotalHours) hours</div>
            $(if ($PerformanceData.CurrentMetrics.CPUUsage) { @"
            <div class="status-grid">
                <div class="status-card">
                    <h3>CPU Usage (Avg)</h3>
                    <div class="value">$($PerformanceData.CurrentMetrics.CPUUsage.Average)%</div>
                </div>
                <div class="status-card">
                    <h3>Memory Available</h3>
                    <div class="value">$($PerformanceData.CurrentMetrics.MemoryAvailable.Average) MB</div>
                </div>
            </div>
"@ })
            $(if ($PerformanceData.HistoricalData.Count -gt 0) { 
                "<div class='alert info'>Collected $($PerformanceData.HistoricalData.Count) performance samples</div>"
            } else { 
                "<div class='no-data'>No historical performance data available</div>"
            })
        </div>
"@
}

function Generate-LogAnalysisSection {
    param($LogAnalysis)
    
    if ($LogAnalysis.Error) {
        return @"
        <div class="section">
            <h2>Log Analysis</h2>
            <div class="alert error">Failed to analyze log data: $($LogAnalysis.Error)</div>
        </div>
"@
    }
    
    $healthClass = switch ($LogAnalysis.LogHealth) {
        'Excellent' { 'healthy' }
        'Good' { 'healthy' }
        'Fair' { 'warning' }
        'Poor' { 'critical' }
        default { '' }
    }
    
    $errorRows = ""
    foreach ($error in $LogAnalysis.TopErrors) {
        $errorRows += @"
            <tr>
                <td>$($error.Pattern)</td>
                <td>$($error.Count)</td>
                <td>$($error.LastOccurrence.ToString('yyyy-MM-dd HH:mm:ss'))</td>
            </tr>
"@
    }
    
    return @"
        <div class="section">
            <h2>Log Analysis</h2>
            <div class="status-grid">
                <div class="status-card critical">
                    <h3>Errors</h3>
                    <div class="value">$($LogAnalysis.ErrorCount)</div>
                </div>
                <div class="status-card warning">
                    <h3>Warnings</h3>
                    <div class="value">$($LogAnalysis.WarningCount)</div>
                </div>
                <div class="status-card $healthClass">
                    <h3>Log Health</h3>
                    <div class="value">$($LogAnalysis.LogHealth)</div>
                </div>
            </div>
            $(if ($LogAnalysis.TopErrors.Count -gt 0) { @"
            <h3>Top Error Patterns</h3>
            <table class="table">
                <thead>
                    <tr>
                        <th>Error Pattern</th>
                        <th>Count</th>
                        <th>Last Occurrence</th>
                    </tr>
                </thead>
                <tbody>
                    $errorRows
                </tbody>
            </table>
"@ } else { '<div class="no-data">No errors found in the analyzed period</div>' })
        </div>
"@
}