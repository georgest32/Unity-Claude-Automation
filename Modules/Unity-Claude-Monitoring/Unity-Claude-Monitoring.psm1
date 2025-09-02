# Unity-Claude Monitoring Module
# Provides monitoring and alerting functionality
# Version: 1.0.0
# Date: 2025-08-24

#region Module Variables

$script:MonitoringConfig = @{
    PrometheusUrl = "http://localhost:9090"
    GrafanaUrl = "http://localhost:3000"
    LokiUrl = "http://localhost:3100"
    AlertManagerUrl = "http://localhost:9093"
    HealthCheckUrl = "http://localhost:9999"
    DefaultTimeout = 30
}

$script:AlertThresholds = @{
    CPUWarning = 80
    CPUCritical = 95
    MemoryWarning = 85
    MemoryCritical = 95
    DiskWarning = 80
    DiskCritical = 90
    ResponseTimeWarning = 2000  # ms
    ResponseTimeCritical = 5000  # ms
    ErrorRateWarning = 0.05
    ErrorRateCritical = 0.10
}

#endregion

#region Health Check Functions

function Get-ServiceHealth {
    <#
    .SYNOPSIS
    Gets health status of Unity-Claude services
    
    .DESCRIPTION
    Retrieves comprehensive health information from the health check service
    
    .PARAMETER ServiceName
    Optional service name to check specific service
    
    .PARAMETER Detailed
    Return detailed health information
    
    .EXAMPLE
    Get-ServiceHealth
    
    .EXAMPLE
    Get-ServiceHealth -ServiceName "langgraph-api" -Detailed
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("langgraph-api", "autogen-groupchat", "powershell-modules", "grafana", "prometheus", "loki", "alertmanager")]
        [string]$ServiceName,
        
        [Parameter(Mandatory = $false)]
        [switch]$Detailed
    )
    
    try {
        Write-Verbose "Checking service health..."
        
        $endpoint = if ($Detailed) { "/health/detailed" } else { "/health" }
        $uri = "$($script:MonitoringConfig.HealthCheckUrl)$endpoint"
        
        $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec $script:MonitoringConfig.DefaultTimeout
        
        if ($ServiceName) {
            # Filter for specific service
            $serviceHealth = $response.services | Where-Object { $_.name -eq $ServiceName }
            if ($serviceHealth) {
                return $serviceHealth
            } else {
                Write-Warning "Service '$ServiceName' not found in health check results"
                return $null
            }
        }
        
        return $response
    }
    catch {
        Write-Error "Failed to get service health: $_"
        return @{
            status = "unhealthy"
            error = $_.Exception.Message
            timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
    }
}

function Test-ServiceLiveness {
    <#
    .SYNOPSIS
    Tests if a service is alive (liveness probe)
    
    .DESCRIPTION
    Performs a liveness check to determine if service should be restarted
    
    .PARAMETER ServiceName
    Name of the service to check
    
    .EXAMPLE
    Test-ServiceLiveness -ServiceName "langgraph-api"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName
    )
    
    try {
        $health = Get-ServiceHealth -ServiceName $ServiceName
        return $health.status -eq "healthy"
    }
    catch {
        Write-Error "Liveness check failed for ${ServiceName}: $_"
        return $false
    }
}

function Test-ServiceReadiness {
    <#
    .SYNOPSIS
    Tests if a service is ready to accept traffic (readiness probe)
    
    .DESCRIPTION
    Performs a readiness check to determine if service can handle requests
    
    .PARAMETER ServiceName
    Name of the service to check
    
    .EXAMPLE
    Test-ServiceReadiness -ServiceName "autogen-groupchat"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName
    )
    
    try {
        $uri = "$($script:MonitoringConfig.HealthCheckUrl)/health/ready"
        $response = Invoke-RestMethod -Uri $uri -Method Get -TimeoutSec 10
        
        $service = $response.critical_services | Where-Object { $_.name -eq $ServiceName }
        if ($service) {
            return $service.status -eq "healthy"
        }
        
        # If not a critical service, check general health
        $health = Get-ServiceHealth -ServiceName $ServiceName
        return $health.status -in @("healthy", "degraded")
    }
    catch {
        Write-Error "Readiness check failed for ${ServiceName}: $_"
        return $false
    }
}

#endregion

#region Metrics Functions

function Get-PrometheusMetrics {
    <#
    .SYNOPSIS
    Queries Prometheus for metrics
    
    .DESCRIPTION
    Executes PromQL queries against Prometheus
    
    .PARAMETER Query
    PromQL query to execute
    
    .PARAMETER TimeRange
    Time range for the query (e.g., "5m", "1h", "1d")
    
    .EXAMPLE
    Get-PrometheusMetrics -Query 'up{job="langgraph-api"}' -TimeRange "5m"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [Parameter(Mandatory = $false)]
        [string]$TimeRange = "5m"
    )
    
    try {
        $uri = "$($script:MonitoringConfig.PrometheusUrl)/api/v1/query"
        $body = @{
            query = $Query
            time = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        }
        
        if ($TimeRange) {
            $uri = "$($script:MonitoringConfig.PrometheusUrl)/api/v1/query_range"
            $endTime = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
            $duration = ParseTimeRange -TimeRange $TimeRange
            $startTime = $endTime - $duration
            
            $body = @{
                query = $Query
                start = $startTime
                end = $endTime
                step = [Math]::Max(15, $duration / 100)  # Adaptive step size
            }
        }
        
        $response = Invoke-RestMethod -Uri $uri -Method Get -Body $body
        
        if ($response.status -eq "success") {
            return $response.data
        } else {
            Write-Warning "Prometheus query returned status: $($response.status)"
            return $null
        }
    }
    catch {
        Write-Error "Failed to query Prometheus: $_"
        return $null
    }
}

function Get-ContainerMetrics {
    <#
    .SYNOPSIS
    Gets container resource metrics
    
    .DESCRIPTION
    Retrieves CPU, memory, and network metrics for containers
    
    .PARAMETER ContainerName
    Optional container name filter
    
    .EXAMPLE
    Get-ContainerMetrics
    
    .EXAMPLE
    Get-ContainerMetrics -ContainerName "unity-claude-langgraph"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$ContainerName
    )
    
    try {
        $metrics = @{}
        
        # CPU usage
        $cpuQuery = if ($ContainerName) {
            "rate(container_cpu_usage_seconds_total{name=`"$ContainerName`"}[5m]) * 100"
        } else {
            "rate(container_cpu_usage_seconds_total[5m]) * 100"
        }
        $metrics.CPU = Get-PrometheusMetrics -Query $cpuQuery
        
        # Memory usage
        $memQuery = if ($ContainerName) {
            "container_memory_usage_bytes{name=`"$ContainerName`"}"
        } else {
            "container_memory_usage_bytes"
        }
        $metrics.Memory = Get-PrometheusMetrics -Query $memQuery
        
        # Network I/O
        $netRxQuery = if ($ContainerName) {
            "rate(container_network_receive_bytes_total{name=`"$ContainerName`"}[5m])"
        } else {
            "rate(container_network_receive_bytes_total[5m])"
        }
        $metrics.NetworkRx = Get-PrometheusMetrics -Query $netRxQuery
        
        $netTxQuery = if ($ContainerName) {
            "rate(container_network_transmit_bytes_total{name=`"$ContainerName`"}[5m])"
        } else {
            "rate(container_network_transmit_bytes_total[5m])"
        }
        $metrics.NetworkTx = Get-PrometheusMetrics -Query $netTxQuery
        
        return $metrics
    }
    catch {
        Write-Error "Failed to get container metrics: $_"
        return $null
    }
}

#endregion

#region Log Functions

function Search-Logs {
    <#
    .SYNOPSIS
    Searches logs in Loki
    
    .DESCRIPTION
    Queries Loki for log entries matching criteria
    
    .PARAMETER Query
    LogQL query string
    
    .PARAMETER TimeRange
    Time range to search (e.g., "1h", "24h")
    
    .PARAMETER Limit
    Maximum number of results
    
    .EXAMPLE
    Search-Logs -Query '{job="fluent-bit"} |= "error"' -TimeRange "1h" -Limit 100
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Query,
        
        [Parameter(Mandatory = $false)]
        [string]$TimeRange = "1h",
        
        [Parameter(Mandatory = $false)]
        [int]$Limit = 100
    )
    
    try {
        Write-Verbose "Starting Loki log search with Query: $Query, TimeRange: $TimeRange"
        
        # Calculate timestamps in nanoseconds for Loki API
        $endTimeMs = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
        $endTime = [int64]($endTimeMs * 1000000)  # Convert to nanoseconds
        
        $duration = ParseTimeRange -TimeRange $TimeRange
        $durationNs = [int64]($duration * 1000000000)  # Convert seconds to nanoseconds
        $startTime = $endTime - $durationNs
        
        Write-Verbose "Time calculation - EndTime: $endTime ns, StartTime: $startTime ns, Duration: $duration seconds"
        
        # Validate time range
        if ($startTime -ge $endTime) {
            throw "Invalid time range: startTime ($startTime) >= endTime ($endTime). Duration: $duration seconds"
        }
        
        $uri = "$($script:MonitoringConfig.LokiUrl)/loki/api/v1/query_range"
        $body = @{
            query = $Query
            start = $startTime
            end = $endTime
            limit = $Limit
            direction = "backward"
        }
        
        $response = Invoke-RestMethod -Uri $uri -Method Get -Body $body
        
        if ($response.status -eq "success") {
            $logs = @()
            foreach ($stream in $response.data.result) {
                foreach ($entry in $stream.values) {
                    $logs += @{
                        Timestamp = [DateTimeOffset]::FromUnixTimeNanoseconds([long]$entry[0]).DateTime
                        Message = $entry[1]
                        Labels = $stream.stream
                    }
                }
            }
            return $logs | Sort-Object Timestamp -Descending
        } else {
            Write-Warning "Loki query returned status: $($response.status)"
            return @()
        }
    }
    catch {
        Write-Error "Failed to search logs: $_"
        return @()
    }
}

function Get-ServiceLogs {
    <#
    .SYNOPSIS
    Gets logs for a specific service
    
    .DESCRIPTION
    Retrieves recent log entries for a Unity-Claude service
    
    .PARAMETER ServiceName
    Name of the service
    
    .PARAMETER Level
    Log level filter (error, warn, info, debug)
    
    .PARAMETER TimeRange
    Time range to search
    
    .EXAMPLE
    Get-ServiceLogs -ServiceName "langgraph-api" -Level "error" -TimeRange "30m"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$ServiceName,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet("error", "warn", "info", "debug", "all")]
        [string]$Level = "all",
        
        [Parameter(Mandatory = $false)]
        [string]$TimeRange = "1h"
    )
    
    try {
        $query = "{container_name=`"$ServiceName`"}"
        
        if ($Level -ne "all") {
            $query += " |~ `"(?i)$Level`""
        }
        
        return Search-Logs -Query $query -TimeRange $TimeRange
    }
    catch {
        Write-Error "Failed to get service logs: $_"
        return @()
    }
}

#endregion

#region Alert Functions

function Send-Alert {
    <#
    .SYNOPSIS
    Sends an alert to Alertmanager
    
    .DESCRIPTION
    Creates and sends a custom alert through Alertmanager
    
    .PARAMETER AlertName
    Name of the alert
    
    .PARAMETER Severity
    Alert severity (critical, warning, info)
    
    .PARAMETER Summary
    Brief summary of the alert
    
    .PARAMETER Description
    Detailed description
    
    .PARAMETER Labels
    Additional labels for routing
    
    .EXAMPLE
    Send-Alert -AlertName "CustomAlert" -Severity "warning" -Summary "High CPU usage" -Description "CPU usage above 80%"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AlertName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet("critical", "warning", "info")]
        [string]$Severity,
        
        [Parameter(Mandatory = $true)]
        [string]$Summary,
        
        [Parameter(Mandatory = $false)]
        [string]$Description = "",
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Labels = @{}
    )
    
    try {
        $alert = @{
            labels = @{
                alertname = $AlertName
                severity = $Severity
            } + $Labels
            annotations = @{
                summary = $Summary
                description = $Description
            }
            generatorURL = "http://unity-claude-monitoring/alerts"
            startsAt = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ")
        }
        
        # Ensure array format for Alertmanager v2 API PostableAlerts
        $alertArray = @($alert)
        $body = ConvertTo-Json -InputObject $alertArray -Depth 10
        $uri = "$($script:MonitoringConfig.AlertManagerUrl)/api/v2/alerts"
        
        $response = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType "application/json"
        
        Write-Verbose "Alert sent successfully: $AlertName"
        return $true
    }
    catch {
        Write-Error "Failed to send alert: $_"
        return $false
    }
}

function Get-ActiveAlerts {
    <#
    .SYNOPSIS
    Gets currently active alerts
    
    .DESCRIPTION
    Retrieves list of active alerts from Alertmanager
    
    .PARAMETER Filter
    Optional filter for alert names or labels
    
    .EXAMPLE
    Get-ActiveAlerts
    
    .EXAMPLE
    Get-ActiveAlerts -Filter "severity=critical"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Filter
    )
    
    try {
        $uri = "$($script:MonitoringConfig.AlertManagerUrl)/api/v2/alerts"
        
        if ($Filter) {
            $uri += "?filter=$Filter"
        }
        
        $response = Invoke-RestMethod -Uri $uri -Method Get
        
        return $response.data | ForEach-Object {
            @{
                Name = $_.labels.alertname
                Severity = $_.labels.severity
                Status = $_.status.state
                Summary = $_.annotations.summary
                StartsAt = $_.startsAt
                EndsAt = $_.endsAt
                Labels = $_.labels
            }
        }
    }
    catch {
        Write-Error "Failed to get active alerts: $_"
        return @()
    }
}

#endregion

#region Helper Functions

function ParseTimeRange {
    param([string]$TimeRange)
    
    if ($TimeRange -match '^(\d+)([smhd])$') {
        $value = [int]$Matches[1]
        $unit = $Matches[2]
        
        switch ($unit) {
            's' { return $value }
            'm' { return $value * 60 }
            'h' { return $value * 3600 }
            'd' { return $value * 86400 }
        }
    }
    
    # Default to 1 hour if parsing fails
    return 3600
}

function Start-MonitoringStack {
    <#
    .SYNOPSIS
    Starts the monitoring stack
    
    .DESCRIPTION
    Starts all monitoring services using Docker Compose
    
    .EXAMPLE
    Start-MonitoringStack
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "Starting monitoring stack..." -ForegroundColor Cyan
        
        $composeFile = Join-Path $PSScriptRoot "..\..\docker-compose.monitoring.yml"
        
        if (-not (Test-Path $composeFile)) {
            throw "Monitoring compose file not found: $composeFile"
        }
        
        docker-compose -f $composeFile up -d
        
        Write-Host "Monitoring stack started successfully" -ForegroundColor Green
        Write-Host "Grafana: http://localhost:3000" -ForegroundColor Yellow
        Write-Host "Prometheus: http://localhost:9090" -ForegroundColor Yellow
        Write-Host "Alertmanager: http://localhost:9093" -ForegroundColor Yellow
        
        return $true
    }
    catch {
        Write-Error "Failed to start monitoring stack: $_"
        return $false
    }
}

function Stop-MonitoringStack {
    <#
    .SYNOPSIS
    Stops the monitoring stack
    
    .DESCRIPTION
    Stops all monitoring services
    
    .EXAMPLE
    Stop-MonitoringStack
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Host "Stopping monitoring stack..." -ForegroundColor Cyan
        
        $composeFile = Join-Path $PSScriptRoot "..\..\docker-compose.monitoring.yml"
        
        docker-compose -f $composeFile down
        
        Write-Host "Monitoring stack stopped successfully" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "Failed to stop monitoring stack: $_"
        return $false
    }
}

#endregion

# Export module members
Export-ModuleMember -Function @(
    'Get-ServiceHealth',
    'Test-ServiceLiveness',
    'Test-ServiceReadiness',
    'Get-PrometheusMetrics',
    'Get-ContainerMetrics',
    'Search-Logs',
    'Get-ServiceLogs',
    'Send-Alert',
    'Get-ActiveAlerts',
    'Start-MonitoringStack',
    'Stop-MonitoringStack'
)
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAXl1hxFbjk+A4c
# xutwUFSk73YG5RClp9c/HohjnhvB2KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIOD3xR4dUZwnb9QSOpFVfp7P
# eSl/o0cHX/LWJ6FjG8joMA0GCSqGSIb3DQEBAQUABIIBAC0YCg7U6owpfL44C9wf
# aSYtyE8ikO+5rzCchTwBhFts5q9MDcmnr/I7T0Jt+QYk1GvtMntcrs3jAJV0OhU1
# N8Of5Y/m5C7dm5Fwx1iiHj/iS+EknVdjkvkTxSWTrWu9xYKrZYZT5lKGD7EvtqIn
# k6Y7DMhGCc/WZ6a+ZeBAmfAoPZoQRavAQFWPdwrloZ9Z5Ovdk/4D2riH4+l1QWvX
# tXYE8H0qt1stgs1ffs81kc9DmaYuVwJIjrUqr1gIfd1bugeq0/NyyC/PgATplHi7
# yygAlycLcX4amaKfNXSfhuOJZBP4riOdiZvURUEK/KrqYVddAesmWpeycIX5qo5x
# s5M=
# SIG # End signature block
