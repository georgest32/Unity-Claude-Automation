# MetricsAndHealthCheck.psm1
# Monitoring, metrics, and health check functionality
# Date: 2025-08-21

#region Monitoring Functions

function Get-NotificationMetrics {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Summary', 'Detailed', 'Json')]
        [string]$Format = 'Summary'
    )
    
    Write-Verbose "Getting notification metrics in $Format format"
    Write-Host "[MONITORING MODULE] Getting notification metrics (Format: $Format)..." -ForegroundColor Cyan
    
    # Access parent module state using Get-Module and scriptblock invocation
    $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
    Write-Host "[MONITORING MODULE] Parent module found: $($parentModule.Name)" -ForegroundColor DarkCyan
    
    # Get metrics from parent module
    $metricsBase = & $parentModule { Get-NotificationState -StateType 'Metrics' }
    Write-Host "[MONITORING MODULE] Metrics retrieved with $($metricsBase.Keys.Count) keys" -ForegroundColor DarkCyan
    
    # Clone metrics to avoid modifying original
    $metrics = @{}
    foreach ($key in $metricsBase.Keys) {
        $metrics[$key] = $metricsBase[$key]
        Write-Host "[MONITORING MODULE] Metrics.$key = $($metricsBase[$key])" -ForegroundColor DarkGray
    }
    
    # Get additional state data
    $queue = & $parentModule { Get-NotificationState -StateType 'Queue' }
    $metrics.CurrentQueueSize = $queue.Count
    Write-Host "[MONITORING MODULE] CurrentQueueSize = $($queue.Count)" -ForegroundColor DarkCyan
    
    $failedNotifications = & $parentModule { Get-NotificationState -StateType 'FailedNotifications' }
    $metrics.CurrentFailedSize = $failedNotifications.Count
    Write-Host "[MONITORING MODULE] CurrentFailedSize = $($failedNotifications.Count)" -ForegroundColor DarkCyan
    
    $circuitBreaker = & $parentModule { Get-NotificationState -StateType 'CircuitBreaker' }
    $metrics.CircuitBreakerState = $circuitBreaker.State
    Write-Host "[MONITORING MODULE] CircuitBreakerState = $($circuitBreaker.State)" -ForegroundColor DarkCyan
    
    $metrics.CollectedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    
    # Calculate additional metrics
    if ($metrics.TotalSent -gt 0) {
        $metrics.SuccessRate = [math]::Round((($metrics.TotalSent - $metrics.TotalFailed) / $metrics.TotalSent) * 100, 2)
        $metrics.FailureRate = [math]::Round(($metrics.TotalFailed / $metrics.TotalSent) * 100, 2)
    }
    else {
        $metrics.SuccessRate = 0
        $metrics.FailureRate = 0
    }
    
    switch ($Format) {
        'Summary' {
            return @{
                TotalSent = $metrics.TotalSent
                TotalFailed = $metrics.TotalFailed
                SuccessRate = "$($metrics.SuccessRate)%"
                CurrentQueueSize = $metrics.CurrentQueueSize
                CircuitBreakerState = $metrics.CircuitBreakerState
                LastDeliveryTime = $metrics.LastDeliveryTime
            }
        }
        'Detailed' {
            return $metrics
        }
        'Json' {
            return $metrics | ConvertTo-Json -Depth 3
        }
    }
}

function Get-NotificationHealthCheck {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Performing notification health check"
    
    $health = @{
        OverallStatus = 'Healthy'
        CheckedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        Components = @{}
        Issues = @()
        Recommendations = @()
    }
    
    # Check queue health
    $queueHealth = Test-QueueHealth
    $health.Components.Queue = $queueHealth
    if ($queueHealth.Status -ne 'Healthy') {
        $health.OverallStatus = 'Warning'
        $health.Issues += $queueHealth.Issues
    }
    
    # Check circuit breaker health
    $circuitHealth = Test-CircuitBreakerHealth
    $health.Components.CircuitBreaker = $circuitHealth
    if ($circuitHealth.Status -ne 'Healthy') {
        if ($circuitHealth.Status -eq 'Critical') {
            $health.OverallStatus = 'Critical'
        }
        elseif ($health.OverallStatus -eq 'Healthy') {
            $health.OverallStatus = 'Warning'
        }
        $health.Issues += $circuitHealth.Issues
    }
    
    # Check metrics health
    $metricsHealth = Test-MetricsHealth
    $health.Components.Metrics = $metricsHealth
    if ($metricsHealth.Status -ne 'Healthy') {
        if ($health.OverallStatus -eq 'Healthy') {
            $health.OverallStatus = 'Warning'
        }
        $health.Issues += $metricsHealth.Issues
    }
    
    # Check configuration health
    $configHealth = Test-ConfigurationHealth
    $health.Components.Configuration = $configHealth
    if ($configHealth.Status -ne 'Healthy') {
        if ($health.OverallStatus -eq 'Healthy') {
            $health.OverallStatus = 'Warning'
        }
        $health.Issues += $configHealth.Issues
    }
    
    # Generate recommendations
    if ($health.Components.Queue.QueueUtilization -gt 80) {
        $health.Recommendations += "Consider increasing queue processing frequency or batch size"
    }
    
    if ($health.Components.Metrics.FailureRate -gt 10) {
        $health.Recommendations += "High failure rate detected - review notification channel configurations"
    }
    
    Write-Verbose "Health check completed: $($health.OverallStatus)"
    return $health
}

function New-NotificationReport {
    [CmdletBinding()]
    param(
        [Parameter()]
        [ValidateSet('Summary', 'Detailed', 'Full')]
        [string]$ReportType = 'Summary',
        
        [Parameter()]
        [ValidateSet('Json', 'Html', 'Text')]
        [string]$Format = 'Text',
        
        [Parameter()]
        [string]$OutputPath
    )
    
    Write-Verbose "Generating notification report: $ReportType in $Format format"
    
    $report = @{
        ReportType = $ReportType
        GeneratedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ModuleVersion = $script:ModuleVersion
        Metrics = Get-NotificationMetrics -Format 'Detailed'
        HealthCheck = Get-NotificationHealthCheck
    }
    
    if ($ReportType -in @('Detailed', 'Full')) {
        $report.Configuration = Get-NotificationConfiguration
        $report.QueueStatus = Get-QueueStatus
        $report.FailedNotifications = Get-FailedNotifications -Limit 10
    }
    
    if ($ReportType -eq 'Full') {
        $report.Hooks = Get-NotificationHooks
        $report.FallbackStatus = Get-FallbackStatus
    }
    
    # Format the report
    $formattedReport = switch ($Format) {
        'Json' {
            $report | ConvertTo-Json -Depth 5
        }
        'Html' {
            Format-ReportAsHtml -Report $report
        }
        'Text' {
            Format-ReportAsText -Report $report
        }
    }
    
    if ($OutputPath) {
        $formattedReport | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Verbose "Report saved to: $OutputPath"
    }
    
    return $formattedReport
}

function Export-NotificationAnalytics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        
        [Parameter()]
        [ValidateSet('Json', 'Csv', 'Html')]
        [string]$Format = 'Json'
    )
    
    Write-Verbose "Exporting notification analytics to $OutputPath in $Format format"
    
    $analytics = @{
        ExportedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        ModuleVersion = $script:ModuleVersion
        TotalMetrics = Get-NotificationMetrics -Format 'Detailed'
        HealthStatus = Get-NotificationHealthCheck
        Configuration = Get-NotificationConfiguration
        QueueAnalytics = Get-QueueAnalytics
        PerformanceMetrics = Get-PerformanceMetrics
    }
    
    try {
        switch ($Format) {
            'Json' {
                $analytics | ConvertTo-Json -Depth 5 | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            'Csv' {
                Export-AnalyticsAsCsv -Analytics $analytics -OutputPath $OutputPath
            }
            'Html' {
                Export-AnalyticsAsHtml -Analytics $analytics -OutputPath $OutputPath
            }
        }
        
        Write-Verbose "Analytics exported successfully"
        return $true
    }
    catch {
        Write-Error "Failed to export analytics: $_"
        return $false
    }
}

function Reset-NotificationMetrics {
    [CmdletBinding()]
    param(
        [Parameter()]
        [switch]$ConfirmReset
    )
    
    if (-not $ConfirmReset) {
        Write-Warning "This will reset all notification metrics. Use -ConfirmReset to proceed."
        return $false
    }
    
    Write-Verbose "Resetting notification metrics"
    Write-Host "[MONITORING MODULE] Resetting all notification metrics" -ForegroundColor Red
    
    # Access parent module state
    $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
    Write-Host "[MONITORING MODULE] Parent module found for metrics reset" -ForegroundColor DarkRed
    
    # Reset metrics in parent module
    $metricsReset = @{
        TotalSent = 0
        TotalFailed = 0
        TotalRetries = 0
        AvgDeliveryTime = 0
        LastDeliveryTime = $null
        QueueSize = 0
        FailedQueueSize = 0
    }
    
    & $parentModule { 
        param($metrics)
        Write-Host "[MONITORING MODULE->PARENT] Resetting all metrics to zero" -ForegroundColor DarkRed
        Set-NotificationState -StateType 'Metrics' -Value $metrics 
    } -metrics $metricsReset
    
    Write-Verbose "Metrics reset successfully"
    Write-Host "[MONITORING MODULE] Metrics reset complete" -ForegroundColor Red
    return $true
}

#endregion

#region Helper Functions

function Test-QueueHealth {
    Write-Host "[MONITORING MODULE] Testing queue health" -ForegroundColor DarkCyan
    
    # Access parent module state
    $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
    
    $queue = & $parentModule { Get-NotificationState -StateType 'Queue' }
    $config = & $parentModule { Get-NotificationState -StateType 'Config' }
    
    $queueSize = $queue.Count
    $maxSize = $config.QueueMaxSize
    $utilization = if ($maxSize -gt 0) { [math]::Round(($queueSize / $maxSize) * 100, 2) } else { 0 }
    
    Write-Host "[MONITORING MODULE] Queue health: Size=$queueSize, Max=$maxSize, Utilization=$utilization%" -ForegroundColor DarkCyan
    
    $status = 'Healthy'
    $issues = @()
    
    if ($utilization -gt 90) {
        $status = 'Critical'
        $issues += "Queue is $utilization% full (critical threshold)"
    }
    elseif ($utilization -gt 75) {
        $status = 'Warning'
        $issues += "Queue is $utilization% full (warning threshold)"
    }
    
    return @{
        Status = $status
        QueueSize = $queueSize
        MaxSize = $maxSize
        QueueUtilization = $utilization
        Issues = $issues
    }
}

function Test-CircuitBreakerHealth {
    Write-Host "[MONITORING MODULE] Testing circuit breaker health" -ForegroundColor DarkCyan
    
    # Access parent module state
    $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
    $circuitBreaker = & $parentModule { Get-NotificationState -StateType 'CircuitBreaker' }
    
    Write-Host "[MONITORING MODULE] Circuit breaker state: $($circuitBreaker.State)" -ForegroundColor DarkCyan
    
    $status = switch ($circuitBreaker.State) {
        'Closed' { 'Healthy' }
        'HalfOpen' { 'Warning' }
        'Open' { 'Critical' }
    }
    
    $issues = @()
    if ($circuitBreaker.State -eq 'Open') {
        $issues += "Circuit breaker is open due to failures"
    }
    elseif ($circuitBreaker.State -eq 'HalfOpen') {
        $issues += "Circuit breaker is in half-open state (testing)"
    }
    
    return @{
        Status = $status
        State = $circuitBreaker.State
        FailureCount = $circuitBreaker.FailureCount
        Issues = $issues
    }
}

function Test-MetricsHealth {
    Write-Host "[MONITORING MODULE] Testing metrics health" -ForegroundColor DarkCyan
    
    # Access parent module state
    $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
    $metrics = & $parentModule { Get-NotificationState -StateType 'Metrics' }
    
    Write-Host "[MONITORING MODULE] Metrics: Sent=$($metrics.TotalSent), Failed=$($metrics.TotalFailed)" -ForegroundColor DarkCyan
    $failureRate = if ($metrics.TotalSent -gt 0) { ($metrics.TotalFailed / $metrics.TotalSent) * 100 } else { 0 }
    
    $status = 'Healthy'
    $issues = @()
    
    if ($failureRate -gt 25) {
        $status = 'Critical'
        $issues += "Very high failure rate: $([math]::Round($failureRate, 2))%"
    }
    elseif ($failureRate -gt 10) {
        $status = 'Warning'
        $issues += "High failure rate: $([math]::Round($failureRate, 2))%"
    }
    
    return @{
        Status = $status
        FailureRate = [math]::Round($failureRate, 2)
        TotalSent = $metrics.TotalSent
        TotalFailed = $metrics.TotalFailed
        Issues = $issues
    }
}

function Test-ConfigurationHealth {
    Write-Host "[MONITORING MODULE] Testing configuration health" -ForegroundColor DarkCyan
    
    # Access parent module state
    $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
    $config = & $parentModule { Get-NotificationState -StateType 'Config' }
    
    Write-Host "[MONITORING MODULE] Configuration keys: $($config.Keys -join ', ')" -ForegroundColor DarkCyan
    $validation = Test-NotificationConfiguration -Configuration $config
    
    $status = if ($validation.IsValid) { 'Healthy' } else { 'Warning' }
    
    return @{
        Status = $status
        IsValid = $validation.IsValid
        Issues = $validation.Errors + $validation.Warnings
    }
}

function Get-QueueAnalytics {
    Write-Host "[MONITORING MODULE] Getting queue analytics" -ForegroundColor DarkCyan
    
    # Access parent module state
    $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
    $queue = & $parentModule { Get-NotificationState -StateType 'Queue' }
    $config = & $parentModule { Get-NotificationState -StateType 'Config' }
    $failed = & $parentModule { Get-NotificationState -StateType 'FailedNotifications' }
    
    $currentSize = $queue.Count
    $maxSize = $config.QueueMaxSize
    $failedSize = $failed.Count
    
    Write-Host "[MONITORING MODULE] Queue analytics: Current=$currentSize, Max=$maxSize, Failed=$failedSize" -ForegroundColor DarkCyan
    
    return @{
        CurrentSize = $currentSize
        MaxSize = $maxSize
        FailedSize = $failedSize
        Utilization = if ($maxSize -gt 0) { 
            [math]::Round(($currentSize / $maxSize) * 100, 2) 
        } else { 0 }
    }
}

function Get-PerformanceMetrics {
    Write-Host "[MONITORING MODULE] Getting performance metrics" -ForegroundColor DarkCyan
    
    # Access parent module state
    $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
    $metrics = & $parentModule { Get-NotificationState -StateType 'Metrics' }
    
    Write-Host "[MONITORING MODULE] Performance: AvgDelivery=$($metrics.AvgDeliveryTime)ms, Retries=$($metrics.TotalRetries)" -ForegroundColor DarkCyan
    
    return @{
        AverageDeliveryTime = $metrics.AvgDeliveryTime
        TotalRetries = $metrics.TotalRetries
        RetryRate = if ($metrics.TotalSent -gt 0) { 
            [math]::Round(($metrics.TotalRetries / $metrics.TotalSent) * 100, 2)
        } else { 0 }
    }
}

function Format-ReportAsText {
    param($Report)
    
    $text = @()
    $text += "Unity-Claude Notification Integration Report"
    $text += "===========================================" 
    $text += "Generated: $($Report.GeneratedAt)"
    $text += "Module Version: $($Report.ModuleVersion)"
    $text += ""
    $text += "Overall Health: $($Report.HealthCheck.OverallStatus)"
    $text += "Total Sent: $($Report.Metrics.TotalSent)"
    $text += "Total Failed: $($Report.Metrics.TotalFailed)"
    $text += "Success Rate: $($Report.Metrics.SuccessRate)%"
    $text += "Queue Size: $($Report.Metrics.CurrentQueueSize)"
    $text += ""
    
    if ($Report.HealthCheck.Issues.Count -gt 0) {
        $text += "Issues:"
        foreach ($issue in $Report.HealthCheck.Issues) {
            $text += "- $issue"
        }
        $text += ""
    }
    
    return $text -join "`n"
}

function Format-ReportAsHtml {
    param($Report)
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Unity-Claude Notification Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { background-color: #f0f0f0; padding: 10px; border-radius: 5px; }
        .metric { display: inline-block; margin: 10px; padding: 10px; border: 1px solid #ccc; border-radius: 5px; }
        .healthy { background-color: #d4edda; }
        .warning { background-color: #fff3cd; }
        .critical { background-color: #f8d7da; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Unity-Claude Notification Integration Report</h1>
        <p>Generated: $($Report.GeneratedAt) | Version: $($Report.ModuleVersion)</p>
    </div>
    
    <div class="metrics">
        <div class="metric $($Report.HealthCheck.OverallStatus.ToLower())">
            <h3>Overall Health</h3>
            <p>$($Report.HealthCheck.OverallStatus)</p>
        </div>
        <div class="metric">
            <h3>Total Sent</h3>
            <p>$($Report.Metrics.TotalSent)</p>
        </div>
        <div class="metric">
            <h3>Success Rate</h3>
            <p>$($Report.Metrics.SuccessRate)%</p>
        </div>
    </div>
</body>
</html>
"@
    
    return $html
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'Get-NotificationMetrics',
    'Get-NotificationHealthCheck',
    'New-NotificationReport',
    'Export-NotificationAnalytics',
    'Reset-NotificationMetrics'
)

Write-Verbose "MetricsAndHealthCheck module loaded successfully"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUDm5egeUcbpUhKvt5oiK+QOdX
# y3agggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUaCwGTkvQhIO/0KjYA6UXBNPWf/AwDQYJKoZIhvcNAQEBBQAEggEApm8P
# omQrcdIVDvxOw5BGsUjtO865P7cMpMA9LFKO3pkQp8gRo2XGHXi98k2Rrt8YYsCk
# dG2QXhlNm/mLX3vG3aWpiFbmvLA5Zl5+XKop4Hw9IF5zXDgpKG9MwgO4t4Fp8ylY
# 7T6SwUfV2MiJ1gXMwKY0DlmyB+zpRw3sD0WYomyx32qgDGNnBMLjXyFIc9psUX/3
# D6F/yZE6ajYoWTau2/GLQ+FvNGR2IaQXI2TWek0mamM5qwII93I4V6CXaCcW1gpq
# KsSmSLP/yLTYHTGkewTOz676tKgcbYtfhDQdaDGD4Rw2MRwIITfwpWjTnqTT25i7
# 639kTowMKM6LoYgi+A==
# SIG # End signature block
