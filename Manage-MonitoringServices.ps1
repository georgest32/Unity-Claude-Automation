# Monitoring Services Management Script
# Unity-Claude Automation - Service Management
# Version: 2025-08-24

param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('start', 'stop', 'restart', 'status', 'logs', 'test', 'reset')]
    [string]$Action,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet('all', 'prometheus', 'grafana', 'loki', 'alertmanager', 'cadvisor', 'node-exporter', 'health-check', 'fluent-bit', 'alloy')]
    [string]$Service = 'all',
    
    [Parameter(Mandatory = $false)]
    [switch]$DetailedOutput
)

$ComposeFile = "docker-compose.monitoring.yml"
$ErrorActionPreference = 'Continue'

function Write-ServiceLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO" { "Cyan" }
        "SUCCESS" { "Green" }  
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Get-ServiceStatus {
    param([string]$ServiceFilter = "unity-claude")
    
    Write-ServiceLog "Checking service status..." "INFO"
    $containers = docker ps -a --filter name=$ServiceFilter --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>&1
    
    if ($containers) {
        Write-ServiceLog "Service Status:" "INFO"
        $containers | ForEach-Object { Write-Host $_ }
    } else {
        Write-ServiceLog "No services found with filter: $ServiceFilter" "WARNING"
    }
}

function Get-ServiceLogs {
    param([string]$ServiceName)
    
    if ($ServiceName -eq 'all') {
        $services = @('prometheus', 'grafana', 'loki', 'alertmanager', 'cadvisor', 'node-exporter', 'health-check', 'fluent-bit', 'alloy')
        foreach ($svc in $services) {
            Write-ServiceLog "=== LOGS for unity-claude-$svc ===" "INFO"
            docker logs "unity-claude-$svc" --tail 5 2>&1 | ForEach-Object { Write-Host $_ }
            Write-Host ""
        }
    } else {
        Write-ServiceLog "=== LOGS for unity-claude-$ServiceName ===" "INFO"
        docker logs "unity-claude-$ServiceName" --tail 20 2>&1 | ForEach-Object { Write-Host $_ }
    }
}

function Test-ServiceConnectivity {
    Write-ServiceLog "Testing service connectivity..." "INFO"
    
    $endpoints = @(
        @{Name = "Prometheus"; Url = "http://localhost:9090/-/ready"; Expected = 200},
        @{Name = "Grafana"; Url = "http://localhost:3000/api/health"; Expected = 200},
        @{Name = "Loki"; Url = "http://localhost:3100/ready"; Expected = 200},
        @{Name = "Alertmanager"; Url = "http://localhost:9093/-/healthy"; Expected = 200},
        @{Name = "cAdvisor"; Url = "http://localhost:8082/healthz"; Expected = 200},
        @{Name = "Node Exporter"; Url = "http://localhost:9100/metrics"; Expected = 200},
        @{Name = "Health Check"; Url = "http://localhost:9999/health/live"; Expected = 200}
    )
    
    foreach ($endpoint in $endpoints) {
        try {
            Write-Host "  Testing $($endpoint.Name)..." -NoNewline
            $response = Invoke-WebRequest -Uri $endpoint.Url -Method Get -TimeoutSec 5 -UseBasicParsing
            
            if ($response.StatusCode -eq $endpoint.Expected) {
                Write-Host " ✓ PASS" -ForegroundColor Green
            } else {
                Write-Host " ✗ FAIL (Status: $($response.StatusCode))" -ForegroundColor Red
            }
        }
        catch {
            Write-Host " ✗ FAIL ($($_.Exception.Message.Split('.')[0]))" -ForegroundColor Red
        }
    }
}

function Reset-MonitoringStack {
    Write-ServiceLog "Resetting monitoring stack..." "WARNING"
    
    Write-ServiceLog "1. Stopping all services..." "INFO"
    docker compose -f $ComposeFile down --remove-orphans 2>&1 | Out-Null
    
    Write-ServiceLog "2. Cleaning up containers and volumes..." "INFO"
    docker container prune -f 2>&1 | Out-Null
    
    Write-ServiceLog "3. Starting services..." "INFO"
    docker compose -f $ComposeFile up -d --build
    
    Write-ServiceLog "4. Waiting for initialization..." "INFO"
    Start-Sleep 45
    
    Write-ServiceLog "5. Testing connectivity..." "INFO"
    Test-ServiceConnectivity
}

# Main execution
Write-ServiceLog "Unity-Claude Monitoring Service Manager" "INFO"
Write-ServiceLog "Action: $Action, Service: $Service" "INFO"

switch ($Action) {
    'start' {
        if ($Service -eq 'all') {
            Write-ServiceLog "Starting all monitoring services..." "INFO"
            docker compose -f $ComposeFile up -d
        } else {
            Write-ServiceLog "Starting service: $Service" "INFO"
            docker compose -f $ComposeFile up -d $Service
        }
        Start-Sleep 10
        Get-ServiceStatus
    }
    
    'stop' {
        if ($Service -eq 'all') {
            Write-ServiceLog "Stopping all monitoring services..." "INFO"
            docker compose -f $ComposeFile down
        } else {
            Write-ServiceLog "Stopping service: $Service" "INFO"
            docker compose -f $ComposeFile stop $Service
        }
        Get-ServiceStatus
    }
    
    'restart' {
        if ($Service -eq 'all') {
            Write-ServiceLog "Restarting all monitoring services..." "INFO"
            docker compose -f $ComposeFile restart
        } else {
            Write-ServiceLog "Restarting service: $Service" "INFO"
            docker compose -f $ComposeFile restart $Service
        }
        Start-Sleep 15
        Get-ServiceStatus
    }
    
    'status' {
        Get-ServiceStatus
    }
    
    'logs' {
        Get-ServiceLogs -ServiceName $Service
    }
    
    'test' {
        Get-ServiceStatus
        Write-Host ""
        Test-ServiceConnectivity
    }
    
    'reset' {
        Reset-MonitoringStack
    }
}

Write-ServiceLog "Service management complete" "SUCCESS"
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBuI2bOMU1fxBKI
# qnmQA8ZFTOCybOOJNeyq9WNKgJXY2KCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKXF1tW+3aCa70TXX7HAgJd3
# ZdtGEvJiTgRmdHFARdUDMA0GCSqGSIb3DQEBAQUABIIBAFyQ213syF4XujY+RBXx
# enC91ZkS3RN24A6ImUoia/LcwBGANPZCARZEGd3ziIEisKTK/dTDJtny24TO0Zi0
# ROLgjnSxqvPfykC3PTfbCOgoB3s9ECKsgjzz+IUVjpSVV6yRGw90TvPD5gl9Udgh
# rV4t1l4scqj8SmDHUNCWUo058eMdKicj5njcuiNNXGIGT2jNNI8NsTx622GqQEYw
# yHRShDtPw0+grXlmMW9fdfGJoPco3jSoTxagUv33B1Ky83s3uT/Mx8d1Ks5PAjIe
# eOZ3BeD7X7Q8UroXX++e5XqIHQms/sC8bLo9OgKfb8UYf4elE+Dd0s7rzNajOgsP
# E7g=
# SIG # End signature block
