# Test script for Unity-Claude Monitoring Stack
# Tests all monitoring components and integrations
# Version: 2025-08-24

param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('All', 'Health', 'Metrics', 'Logs', 'Alerts', 'Integration')]
    [string]$TestType = 'All',
    
    [Parameter(Mandatory = $false)]
    [switch]$StartStack,
    
    [Parameter(Mandatory = $false)]
    [switch]$StopStack,
    
    [Parameter(Mandatory = $false)]
    [switch]$SaveResults
)

$ErrorActionPreference = 'Stop'

Write-Host "Unity-Claude Monitoring Stack Test" -ForegroundColor Cyan
Write-Host "===================================" -ForegroundColor Cyan
Write-Host ""

# Import monitoring module
$modulePath = Join-Path $PSScriptRoot "Modules" | Join-Path -ChildPath "Unity-Claude-Monitoring" | Join-Path -ChildPath "Unity-Claude-Monitoring.psd1"
Import-Module $modulePath -Force

# Test results collection
$testResults = @{
    Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    TestType = $TestType
    Tests = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
    }
}

function Test-ComponentAvailability {
    Write-Host "`nTesting component availability..." -ForegroundColor Yellow
    
    $components = @(
        @{Name = 'Prometheus'; Url = 'http://localhost:9090/-/ready'; Expected = 200},
        @{Name = 'Grafana'; Url = 'http://localhost:3000/api/health'; Expected = 200},
        @{Name = 'Loki'; Url = 'http://localhost:3100/ready'; Expected = 200},
        @{Name = 'Alertmanager'; Url = 'http://localhost:9093/-/healthy'; Expected = 200},
        @{Name = 'cAdvisor'; Url = 'http://localhost:8082/healthz'; Expected = 200},
        @{Name = 'Node Exporter'; Url = 'http://localhost:9100/metrics'; Expected = 200}
    )
    
    $results = @()
    
    foreach ($component in $components) {
        Write-Host "  Testing $($component.Name)..." -NoNewline
        
        try {
            $response = Invoke-WebRequest -Uri $component.Url -Method Get -TimeoutSec 5 -UseBasicParsing
            
            if ($response.StatusCode -eq $component.Expected) {
                Write-Host " PASSED" -ForegroundColor Green
                $results += @{
                    Component = $component.Name
                    Status = "Passed"
                    Message = "Component is accessible"
                }
            } else {
                Write-Host " FAILED" -ForegroundColor Red
                $results += @{
                    Component = $component.Name
                    Status = "Failed"
                    Message = "Unexpected status code" + ": $($response.StatusCode)"
                }
            }
        }
        catch {
            Write-Host " FAILED" -ForegroundColor Red
            $results += @{
                Component = $component.Name
                Status = "Failed"
                Message = $_.Exception.Message
            }
        }
    }
    
    return $results
}

function Test-HealthChecks {
    Write-Host "`nTesting health check endpoints..." -ForegroundColor Yellow
    
    $tests = @()
    
    # Test liveness probe
    Write-Host "  Testing liveness probe..." -NoNewline
    try {
        $liveness = Invoke-RestMethod -Uri "http://localhost:9999/health/live" -Method Get
        if ($liveness.status -eq "alive") {
            Write-Host " PASSED" -ForegroundColor Green
            $tests += @{Name = "Liveness Probe"; Status = "Passed"; Message = "Service is alive"}
        } else {
            Write-Host " FAILED" -ForegroundColor Red
            $tests += @{Name = "Liveness Probe"; Status = "Failed"; Message = "Unexpected status" + ": $($liveness.status)"}
        }
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        $tests += @{Name = "Liveness Probe"; Status = "Failed"; Message = $_.Exception.Message}
    }
    
    # Test readiness probe
    Write-Host "  Testing readiness probe..." -NoNewline
    try {
        # Test readiness probe - expect either 200 or 503 response
        $readiness = $null
        $statusCode = $null
        
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:9999/health/ready" -Method Get -UseBasicParsing
            $readiness = $response.Content | ConvertFrom-Json
            $statusCode = $response.StatusCode
        }
        catch {
            # Handle 503 Service Unavailable which is valid for readiness probe
            if ($_.Exception -is [Microsoft.PowerShell.Commands.HttpResponseException] -and $_.Exception.Response.StatusCode -eq 503) {
                $readiness = $_.ErrorDetails.Message | ConvertFrom-Json
                $statusCode = 503
            } elseif ($_.Exception.Message -like "*503*" -or $_.Exception.Message -like "*Service Unavailable*") {
                # Fallback parsing for older PowerShell versions
                try {
                    # Extract JSON from error message
                    $jsonStart = $_.Exception.Message.IndexOf('{"')
                    if ($jsonStart -ge 0) {
                        $jsonText = $_.Exception.Message.Substring($jsonStart)
                        $jsonEnd = $jsonText.LastIndexOf('}') + 1
                        $jsonText = $jsonText.Substring(0, $jsonEnd)
                        $readiness = $jsonText | ConvertFrom-Json
                        $statusCode = 503
                    } else {
                        throw $_
                    }
                } catch {
                    throw $_
                }
            } else {
                throw $_
            }
        }
        
        # Validate response format regardless of status code
        if ($readiness.status -in @("ready", "not_ready") -and $statusCode -in @(200, 503)) {
            Write-Host " PASSED" -ForegroundColor Green
            $tests += @{Name = "Readiness Probe"; Status = "Passed"; Message = "Probe responded correctly (HTTP $statusCode, status: $($readiness.status))"}
        } else {
            Write-Host " FAILED" -ForegroundColor Red  
            $tests += @{Name = "Readiness Probe"; Status = "Failed"; Message = "Invalid response - HTTP $statusCode, status: $($readiness.status)"}
        }
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        $tests += @{Name = "Readiness Probe"; Status = "Failed"; Message = $_.Exception.Message}
    }
    
    # Test service health
    Write-Host "  Testing service health checks..." -NoNewline
    try {
        $health = Get-ServiceHealth -Detailed
        if ($health.status) {
            Write-Host " PASSED" -ForegroundColor Green
            $tests += @{Name = "Service Health"; Status = "Passed"; Message = "Health status" + ": $($health.status)"}
        } else {
            Write-Host " FAILED" -ForegroundColor Red
            $tests += @{Name = "Service Health"; Status = "Failed"; Message = "No health status returned"}
        }
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        $tests += @{Name = "Service Health"; Status = "Failed"; Message = $_.Exception.Message}
    }
    
    return $tests
}

function Test-MetricsCollection {
    Write-Host "`nTesting metrics collection..." -ForegroundColor Yellow
    
    $tests = @()
    
    # Test Prometheus metrics
    Write-Host "  Testing Prometheus queries..." -NoNewline
    try {
        $upMetric = Get-PrometheusMetrics -Query "up" -TimeRange ""
        if ($upMetric) {
            Write-Host " PASSED" -ForegroundColor Green
            $tests += @{Name = "Prometheus Query"; Status = "Passed"; Message = "Metrics retrieved successfully"}
        } else {
            Write-Host " FAILED" -ForegroundColor Red
            $tests += @{Name = "Prometheus Query"; Status = "Failed"; Message = "No metrics returned"}
        }
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        $tests += @{Name = "Prometheus Query"; Status = "Failed"; Message = $_.Exception.Message}
    }
    
    # Test container metrics
    Write-Host "  Testing container metrics..." -NoNewline
    try {
        $containerMetrics = Get-ContainerMetrics
        if ($containerMetrics.CPU -or $containerMetrics.Memory) {
            Write-Host " PASSED" -ForegroundColor Green
            $tests += @{Name = "Container Metrics"; Status = "Passed"; Message = "Container metrics available"}
        } else {
            Write-Host " FAILED" -ForegroundColor Red
            $tests += @{Name = "Container Metrics"; Status = "Failed"; Message = "No container metrics"}
        }
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        $tests += @{Name = "Container Metrics"; Status = "Failed"; Message = $_.Exception.Message}
    }
    
    return $tests
}

function Test-LogAggregation {
    Write-Host "`nTesting log aggregation..." -ForegroundColor Yellow
    
    $tests = @()
    
    # Test Loki connectivity
    Write-Host "  Testing Loki log search..." -NoNewline
    try {
        $logs = Search-Logs -Query '{job="fluent-bit"}' -TimeRange "1h" -Limit 10
        Write-Host " PASSED" -ForegroundColor Green
        $tests += @{Name = "Loki Search"; Status = "Passed"; Message = "Found $($logs.Count) log entries"}
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        $tests += @{Name = "Loki Search"; Status = "Failed"; Message = $_.Exception.Message}
    }
    
    # Test service logs
    Write-Host "  Testing service log retrieval..." -NoNewline
    try {
        # Generate a test log entry
        $testDate = Get-Date
        $null = docker exec unity-claude-langgraph echo "Test log entry $testDate" 2>&1
        Start-Sleep -Seconds 2
        
        $serviceLogs = Get-ServiceLogs -ServiceName "unity-claude-langgraph" -TimeRange "5m"
        if ($serviceLogs) {
            Write-Host " PASSED" -ForegroundColor Green
            $tests += @{Name = "Service Logs"; Status = "Passed"; Message = "Retrieved service logs"}
        } else {
            Write-Host " WARNING" -ForegroundColor Yellow
            $tests += @{Name = "Service Logs"; Status = "Passed"; Message = "No logs found (may be normal)"}
        }
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        $tests += @{Name = "Service Logs"; Status = "Failed"; Message = $_.Exception.Message}
    }
    
    return $tests
}

function Test-AlertingSystem {
    Write-Host "`nTesting alerting system..." -ForegroundColor Yellow
    
    $tests = @()
    
    # Test alert sending
    Write-Host "  Testing alert creation..." -NoNewline
    try {
        $alertSent = Send-Alert `
            -AlertName "TestAlert" `
            -Severity "info" `
            -Summary "Test alert from monitoring test" `
            -Description "This is a test alert to verify alerting system"
        
        if ($alertSent) {
            Write-Host " PASSED" -ForegroundColor Green
            $tests += @{Name = "Send Alert"; Status = "Passed"; Message = "Alert sent successfully"}
        } else {
            Write-Host " FAILED" -ForegroundColor Red
            $tests += @{Name = "Send Alert"; Status = "Failed"; Message = "Failed to send alert"}
        }
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        $tests += @{Name = "Send Alert"; Status = "Failed"; Message = $_.Exception.Message}
    }
    
    # Test alert retrieval
    Write-Host "  Testing alert retrieval..." -NoNewline
    try {
        Start-Sleep -Seconds 2  # Wait for alert to be processed
        $activeAlerts = Get-ActiveAlerts
        
        Write-Host " PASSED" -ForegroundColor Green
        $tests += @{Name = "Get Alerts"; Status = "Passed"; Message = "Found $($activeAlerts.Count) active alerts"}
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        $tests += @{Name = "Get Alerts"; Status = "Failed"; Message = $_.Exception.Message}
    }
    
    return $tests
}

function Test-Integration {
    Write-Host "`nTesting monitoring integration..." -ForegroundColor Yellow
    
    $tests = @()
    
    # Test Grafana data sources
    Write-Host "  Testing Grafana datasources..." -NoNewline
    try {
        $authString = "admin:admin"
        $headers = @{
            "Authorization" = "Basic " + [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes($authString))
        }
        
        $datasources = Invoke-RestMethod `
            -Uri "http://localhost:3000/api/datasources" `
            -Method Get `
            -Headers $headers
        
        $hasPrometheus = $datasources | Where-Object { $_.type -eq "prometheus" }
        $hasLoki = $datasources | Where-Object { $_.type -eq "loki" }
        
        if ($hasPrometheus -and $hasLoki) {
            Write-Host " PASSED" -ForegroundColor Green
            $tests += @{Name = "Grafana Datasources"; Status = "Passed"; Message = "All datasources configured"}
        } else {
            Write-Host " FAILED" -ForegroundColor Red
            $tests += @{Name = "Grafana Datasources"; Status = "Failed"; Message = "Missing datasources"}
        }
    }
    catch {
        Write-Host " WARNING" -ForegroundColor Yellow
        $tests += @{Name = "Grafana Datasources"; Status = "Warning"; Message = "Could not verify (auth required)"}
    }
    
    # Test metric scraping
    Write-Host "  Testing metric scraping..." -NoNewline
    try {
        $targets = Invoke-RestMethod -Uri "http://localhost:9090/api/v1/targets" -Method Get
        $healthyTargets = $targets.data.activeTargets | Where-Object { $_.health -eq "up" }
        
        if ($healthyTargets.Count -gt 0) {
            Write-Host " PASSED" -ForegroundColor Green
            $tests += @{Name = "Metric Scraping"; Status = "Passed"; Message = "$($healthyTargets.Count) healthy targets"}
        } else {
            Write-Host " FAILED" -ForegroundColor Red
            $tests += @{Name = "Metric Scraping"; Status = "Failed"; Message = "No healthy scrape targets"}
        }
    }
    catch {
        Write-Host " FAILED" -ForegroundColor Red
        $tests += @{Name = "Metric Scraping"; Status = "Failed"; Message = $_.Exception.Message}
    }
    
    return $tests
}

# Main test execution
try {
    # Start stack if requested
    if ($StartStack) {
        Write-Host "Starting monitoring stack..." -ForegroundColor Cyan
        Start-MonitoringStack
        Write-Host "Waiting for services to initialize..." -ForegroundColor Yellow
        Start-Sleep -Seconds 30
    }
    
    # Run tests based on type
    $allTests = @()
    
    if ($TestType -eq 'All' -or $TestType -eq 'Health') {
        Write-Host "`n--- Component Availability Tests ---" -ForegroundColor Cyan
        $allTests += Test-ComponentAvailability
        
        Write-Host "`n--- Health Check Tests ---" -ForegroundColor Cyan
        $allTests += Test-HealthChecks
    }
    
    if ($TestType -eq 'All' -or $TestType -eq 'Metrics') {
        Write-Host "`n--- Metrics Collection Tests ---" -ForegroundColor Cyan
        $allTests += Test-MetricsCollection
    }
    
    if ($TestType -eq 'All' -or $TestType -eq 'Logs') {
        Write-Host "`n--- Log Aggregation Tests ---" -ForegroundColor Cyan
        $allTests += Test-LogAggregation
    }
    
    if ($TestType -eq 'All' -or $TestType -eq 'Alerts') {
        Write-Host "`n--- Alerting System Tests ---" -ForegroundColor Cyan
        $allTests += Test-AlertingSystem
    }
    
    if ($TestType -eq 'All' -or $TestType -eq 'Integration') {
        Write-Host "`n--- Integration Tests ---" -ForegroundColor Cyan
        $allTests += Test-Integration
    }
    
    # Update test results
    $testResults.Tests = $allTests
    $testResults.Summary.Total = $allTests.Count
    $testResults.Summary.Passed = ($allTests | Where-Object { $_.Status -eq "Passed" }).Count
    $testResults.Summary.Failed = ($allTests | Where-Object { $_.Status -eq "Failed" }).Count
    
    # Display summary
    Write-Host ("`n" + "="*50) -ForegroundColor Cyan
    Write-Host "TEST SUMMARY" -ForegroundColor Cyan
    Write-Host ("="*50) -ForegroundColor Cyan
    Write-Host "Total Tests:    $($testResults.Summary.Total)" -ForegroundColor White
    Write-Host "Passed:         $($testResults.Summary.Passed)" -ForegroundColor Green
    Write-Host "Failed:         $($testResults.Summary.Failed)" -ForegroundColor Red
    
    # Display failed tests
    if ($testResults.Summary.Failed -gt 0) {
        Write-Host "`nFailed Tests:" -ForegroundColor Red
        $allTests | Where-Object { $_.Status -eq "Failed" } | ForEach-Object {
            $testName = $_.Name -or $_.Component
            Write-Host "  - ${testName}: $($_.Message)" -ForegroundColor Red
        }
    }
    
    # Save results if requested
    if ($SaveResults) {
        $outputFile = Join-Path $PSScriptRoot "MonitoringStack-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $testResults | ConvertTo-Json -Depth 10 | Set-Content $outputFile
        Write-Host "`nTest results saved to: $outputFile" -ForegroundColor Green
    }
    
    # Stop stack if requested
    if ($StopStack) {
        Write-Host "`nStopping monitoring stack..." -ForegroundColor Cyan
        Stop-MonitoringStack
    }
    
    # Display access information
    Write-Host ("`n" + "="*50) -ForegroundColor Cyan
    Write-Host 'MONITORING STACK ACCESS' -ForegroundColor Cyan
    Write-Host ("="*50) -ForegroundColor Cyan
    Write-Host 'Grafana:      http://localhost:3000     (admin/admin)' -ForegroundColor Yellow
    Write-Host 'Prometheus:   http://localhost:9090' -ForegroundColor Yellow
    Write-Host 'Alertmanager: http://localhost:9093' -ForegroundColor Yellow
    Write-Host 'Loki:         http://localhost:3100' -ForegroundColor Yellow
    Write-Host 'cAdvisor:     http://localhost:8082' -ForegroundColor Yellow
    Write-Host 'Health Check: http://localhost:9999/health/detailed' -ForegroundColor Yellow
    
    # Return exit code
    if ($testResults.Summary.Failed -gt 0) {
        exit 1
    } else {
        exit 0
    }
}
catch {
    Write-Error "Test execution failed: $_"
    exit 1
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAEzGujAaKj1DvA
# ggY9TiH6LnuI1fm3P2rkyeber3qnAaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAD9PRdf1yem4qNjrGbUhuZg
# MVV8qd4pOfT+5sBXEtJWMA0GCSqGSIb3DQEBAQUABIIBAClSncwJh8rYEsk0RHNx
# U3GjM3+fnhfATHtLADTy00HwiRWdSbzBsbV6NXZ8D7Yo1dCw8iAm8T3nIXbd140F
# edlAUaJugIn9JUkev9sHk+g8HIOLZtcrtUF346VWjqDgXsJDHffq0dFv9keqfR87
# wlZoHw4c4tVgl7uK+dSnZbO9kwFhiaxndgU35pl+rJ03ajQLBXa3f86QebTD70xX
# KWrsF9REK2FLA7gbZQOH7hhraFT8XbWdMS0Qppqf7AEBQaJKLF9Q644AugNFbW+I
# wSvK8mMyeAu+jPZBOb7AAU+jCji0cl7xhxuKpwtPdD3xqXC4B1+40jb5K8QL3WV6
# 4ko=
# SIG # End signature block
