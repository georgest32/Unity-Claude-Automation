# Enhanced Documentation System - System Health Test Script
# Phase 3 Day 5: Production Integration & Advanced Features
# Version: 2025-08-25
#
# Comprehensive health check and validation for all system components

[CmdletBinding()]
param(
    [ValidateSet('Quick', 'Full', 'Critical', 'Performance')]
    [string]$TestType = 'Quick',
    
    [string]$OutputPath = '.\health-reports',
    [string]$ConfigPath = '.\config',
    
    [switch]$SaveResults,
    [switch]$Detailed,
    [switch]$IncludeMetrics,
    [switch]$GenerateReport
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

# Test result tracking
$script:TestResults = @{
    StartTime = Get-Date
    TestType = $TestType
    Results = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Warning = 0
        Skipped = 0
    }
}

function Write-TestLog {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [ValidateSet('Info', 'Warning', 'Error', 'Success', 'Test')]
        [string]$Level = 'Info',
        
        [string]$TestName = ''
    )
    
    $timestamp = Get-Date -Format 'HH:mm:ss'
    $prefix = if ($TestName) { "[$TestName] " } else { "" }
    
    $color = switch ($Level) {
        'Info' { 'Cyan' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Success' { 'Green' }
        'Test' { 'Magenta' }
    }
    
    Write-Host "[$timestamp] $prefix$Message" -ForegroundColor $color
}

function Add-TestResult {
    param(
        [Parameter(Mandatory)]
        [string]$TestName,
        
        [Parameter(Mandatory)]
        [ValidateSet('Pass', 'Fail', 'Warning', 'Skip')]
        [string]$Status,
        
        [string]$Details = '',
        [hashtable]$Metrics = @{},
        [int]$Duration = 0
    )
    
    $result = @{
        TestName = $TestName
        Status = $Status
        Details = $Details
        Metrics = $Metrics
        Duration = $Duration
        Timestamp = (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    }
    
    $script:TestResults.Results += $result
    $script:TestResults.Summary.Total++
    
    switch ($Status) {
        'Pass' { 
            $script:TestResults.Summary.Passed++
            Write-TestLog "✅ PASS" -Level Success -TestName $TestName
        }
        'Fail' { 
            $script:TestResults.Summary.Failed++
            Write-TestLog "❌ FAIL - $Details" -Level Error -TestName $TestName
        }
        'Warning' { 
            $script:TestResults.Summary.Warning++
            Write-TestLog "⚠️  WARNING - $Details" -Level Warning -TestName $TestName
        }
        'Skip' { 
            $script:TestResults.Summary.Skipped++
            Write-TestLog "⏭️  SKIPPED - $Details" -Level Info -TestName $TestName
        }
    }
}

function Test-ServiceHealth {
    param(
        [Parameter(Mandatory)]
        [string]$ServiceName,
        
        [Parameter(Mandatory)]
        [string]$URL,
        
        [int]$TimeoutSeconds = 30,
        [string]$ExpectedContent = '',
        [hashtable]$Headers = @{}
    )
    
    $testName = "Service Health: $ServiceName"
    $startTime = Get-Date
    
    try {
        Write-TestLog "Testing $ServiceName at $URL" -TestName $testName -Level Test
        
        $params = @{
            Uri = $URL
            TimeoutSec = $TimeoutSeconds
            UseBasicParsing = $true
            ErrorAction = 'Stop'
        }
        
        if ($Headers.Count -gt 0) {
            $params.Headers = $Headers
        }
        
        $response = Invoke-WebRequest @params
        $duration = [int]((Get-Date) - $startTime).TotalMilliseconds
        
        $metrics = @{
            StatusCode = $response.StatusCode
            ResponseTime = $duration
            ContentLength = $response.Content.Length
        }
        
        if ($response.StatusCode -eq 200) {
            if ($ExpectedContent -and $response.Content -notlike "*$ExpectedContent*") {
                Add-TestResult -TestName $testName -Status 'Warning' -Details "Response doesn't contain expected content" -Metrics $metrics -Duration $duration
            } else {
                Add-TestResult -TestName $testName -Status 'Pass' -Details "HTTP 200, ${duration}ms response time" -Metrics $metrics -Duration $duration
            }
        } else {
            Add-TestResult -TestName $testName -Status 'Warning' -Details "HTTP $($response.StatusCode)" -Metrics $metrics -Duration $duration
        }
        
    } catch {
        $duration = [int]((Get-Date) - $startTime).TotalMilliseconds
        Add-TestResult -TestName $testName -Status 'Fail' -Details $_.Exception.Message -Duration $duration
    }
}

function Test-DockerServices {
    Write-TestLog "Testing Docker services..." -Level Info
    
    # Check Docker daemon
    try {
        $dockerInfo = docker info --format "{{.ServerVersion}}" 2>$null
        if ($dockerInfo) {
            Add-TestResult -TestName "Docker Daemon" -Status 'Pass' -Details "Docker version: $dockerInfo"
        } else {
            Add-TestResult -TestName "Docker Daemon" -Status 'Fail' -Details "Docker daemon not running"
            return
        }
    } catch {
        Add-TestResult -TestName "Docker Daemon" -Status 'Fail' -Details "Docker not accessible"
        return
    }
    
    # Check running containers
    try {
        $containers = docker ps --format "{{.Names}};{{.Status}}" 2>$null
        
        if ($containers) {
            $runningCount = ($containers | Measure-Object).Count
            $healthyCount = ($containers | Where-Object { $_ -like "*Up*" } | Measure-Object).Count
            
            Add-TestResult -TestName "Docker Containers" -Status 'Pass' -Details "$healthyCount/$runningCount containers running" -Metrics @{
                Total = $runningCount
                Healthy = $healthyCount
            }
            
            # Test individual container health
            foreach ($container in $containers) {
                $parts = $container -split ';'
                $name = $parts[0]
                $status = $parts[1]
                
                if ($status -like "*Up*") {
                    Add-TestResult -TestName "Container: $name" -Status 'Pass' -Details $status
                } else {
                    Add-TestResult -TestName "Container: $name" -Status 'Fail' -Details $status
                }
            }
        } else {
            Add-TestResult -TestName "Docker Containers" -Status 'Warning' -Details "No containers running"
        }
    } catch {
        Add-TestResult -TestName "Docker Containers" -Status 'Fail' -Details "Cannot check container status"
    }
}

function Test-ServiceEndpoints {
    Write-TestLog "Testing service endpoints..." -Level Info
    
    # Core services
    $services = @(
        @{ Name = "Documentation Web"; URL = "http://localhost:8080/health"; Timeout = 30; Content = "healthy" },
        @{ Name = "Documentation API"; URL = "http://localhost:8091/health"; Timeout = 30; Content = "healthy" },
        @{ Name = "PowerShell Modules"; URL = "http://localhost:5985"; Timeout = 15; Content = "" },
        @{ Name = "LangGraph API"; URL = "http://localhost:8000/health"; Timeout = 30; Content = "healthy" },
        @{ Name = "AutoGen Service"; URL = "http://localhost:8001/health"; Timeout = 30; Content = "healthy" }
    )
    
    # Monitoring services (optional)
    if ($TestType -in @('Full', 'Performance')) {
        $services += @(
            @{ Name = "Prometheus"; URL = "http://localhost:9090/-/ready"; Timeout = 15; Content = "" },
            @{ Name = "Grafana"; URL = "http://localhost:3000/api/health"; Timeout = 15; Content = "" },
            @{ Name = "Loki"; URL = "http://localhost:3100/ready"; Timeout = 15; Content = "" }
        )
    }
    
    foreach ($service in $services) {
        Test-ServiceHealth -ServiceName $service.Name -URL $service.URL -TimeoutSeconds $service.Timeout -ExpectedContent $service.Content
    }
}

function Test-PowerShellModules {
    Write-TestLog "Testing PowerShell modules..." -Level Info
    
    $modules = @(
        'Unity-Claude-CPG',
        'Unity-Claude-SemanticAnalysis',
        'Unity-Claude-LLM',
        'Unity-Claude-APIDocumentation',
        'Unity-Claude-CodeQL'
    )
    
    foreach ($moduleName in $modules) {
        $testName = "PowerShell Module: $moduleName"
        
        try {
            $modulePath = ".\Modules\$moduleName\$moduleName.psd1"
            
            if (Test-Path $modulePath) {
                # Test manifest
                $manifest = Test-ModuleManifest -Path $modulePath -ErrorAction Stop
                
                # Try importing
                Import-Module $modulePath -Force -ErrorAction Stop
                
                # Get exported functions
                $exportedFunctions = (Get-Command -Module $moduleName).Count
                
                Add-TestResult -TestName $testName -Status 'Pass' -Details "$exportedFunctions functions exported" -Metrics @{
                    Version = $manifest.Version
                    Functions = $exportedFunctions
                }
                
                # Remove module to clean up
                Remove-Module $moduleName -Force -ErrorAction SilentlyContinue
            } else {
                Add-TestResult -TestName $testName -Status 'Warning' -Details "Module manifest not found"
            }
            
        } catch {
            Add-TestResult -TestName $testName -Status 'Fail' -Details $_.Exception.Message
        }
    }
}

function Test-FileSystemHealth {
    Write-TestLog "Testing file system health..." -Level Info
    
    # Check critical directories
    $directories = @(
        @{ Path = '.\Modules'; Critical = $true; Name = "Modules Directory" },
        @{ Path = '.\docs'; Critical = $false; Name = "Documentation Directory" },
        @{ Path = '.\scripts'; Critical = $false; Name = "Scripts Directory" },
        @{ Path = '.\agents'; Critical = $false; Name = "Agents Directory" },
        @{ Path = '.\docker'; Critical = $true; Name = "Docker Directory" },
        @{ Path = '.\logs'; Critical = $false; Name = "Logs Directory" }
    )
    
    foreach ($dir in $directories) {
        $testName = "Directory: $($dir.Name)"
        
        if (Test-Path $dir.Path) {
            $itemCount = (Get-ChildItem $dir.Path -Recurse | Measure-Object).Count
            Add-TestResult -TestName $testName -Status 'Pass' -Details "$itemCount items" -Metrics @{ ItemCount = $itemCount }
        } else {
            $status = if ($dir.Critical) { 'Fail' } else { 'Warning' }
            Add-TestResult -TestName $testName -Status $status -Details "Directory not found"
        }
    }
    
    # Check disk space
    $diskSpace = Get-WmiObject -Class Win32_LogicalDisk | Where-Object { $_.DeviceID -eq "C:" }
    $freeSpaceGB = [math]::Round($diskSpace.FreeSpace / 1GB, 2)
    $totalSpaceGB = [math]::Round($diskSpace.Size / 1GB, 2)
    $usedPercentage = [math]::Round((($totalSpaceGB - $freeSpaceGB) / $totalSpaceGB) * 100, 1)
    
    if ($freeSpaceGB -lt 5) {
        Add-TestResult -TestName "Disk Space" -Status 'Fail' -Details "Only ${freeSpaceGB}GB free (${usedPercentage}% used)"
    } elseif ($freeSpaceGB -lt 10) {
        Add-TestResult -TestName "Disk Space" -Status 'Warning' -Details "${freeSpaceGB}GB free (${usedPercentage}% used)"
    } else {
        Add-TestResult -TestName "Disk Space" -Status 'Pass' -Details "${freeSpaceGB}GB free (${usedPercentage}% used)"
    }
}

function Test-PerformanceMetrics {
    if ($TestType -ne 'Performance') {
        return
    }
    
    Write-TestLog "Testing performance metrics..." -Level Info
    
    # Memory usage
    $memory = Get-WmiObject -Class Win32_ComputerSystem
    $memoryUsage = Get-WmiObject -Class Win32_OperatingSystem
    $totalMemoryGB = [math]::Round($memory.TotalPhysicalMemory / 1GB, 2)
    $availableMemoryGB = [math]::Round($memoryUsage.FreePhysicalMemory / 1MB, 2)
    $usedMemoryPercentage = [math]::Round((($totalMemoryGB - $availableMemoryGB) / $totalMemoryGB) * 100, 1)
    
    if ($usedMemoryPercentage -gt 90) {
        Add-TestResult -TestName "Memory Usage" -Status 'Fail' -Details "${usedMemoryPercentage}% used"
    } elseif ($usedMemoryPercentage -gt 80) {
        Add-TestResult -TestName "Memory Usage" -Status 'Warning' -Details "${usedMemoryPercentage}% used"
    } else {
        Add-TestResult -TestName "Memory Usage" -Status 'Pass' -Details "${usedMemoryPercentage}% used"
    }
    
    # CPU usage (average over 5 seconds)
    $cpuUsage = (Get-Counter "\Processor(_Total)\% Processor Time" -SampleInterval 1 -MaxSamples 5 | 
                 Select-Object -ExpandProperty CounterSamples | 
                 Measure-Object -Property CookedValue -Average).Average
    $cpuUsage = [math]::Round($cpuUsage, 1)
    
    if ($cpuUsage -gt 90) {
        Add-TestResult -TestName "CPU Usage" -Status 'Warning' -Details "${cpuUsage}% average"
    } else {
        Add-TestResult -TestName "CPU Usage" -Status 'Pass' -Details "${cpuUsage}% average"
    }
}

function Test-APIFunctionality {
    if ($TestType -eq 'Quick') {
        return
    }
    
    Write-TestLog "Testing API functionality..." -Level Info
    
    # Test Documentation API endpoints
    $apiTests = @(
        @{ Endpoint = "/api/modules"; Name = "Modules List" },
        @{ Endpoint = "/api/functions"; Name = "Functions List" },
        @{ Endpoint = "/api/search-data"; Name = "Search Data" }
    )
    
    foreach ($test in $apiTests) {
        $testName = "API: $($test.Name)"
        $url = "http://localhost:8091$($test.Endpoint)"
        
        try {
            $response = Invoke-RestMethod -Uri $url -TimeoutSec 15 -ErrorAction Stop
            
            if ($response) {
                $responseType = $response.GetType().Name
                $itemCount = if ($response -is [array]) { $response.Count } else { 1 }
                Add-TestResult -TestName $testName -Status 'Pass' -Details "$itemCount items returned" -Metrics @{
                    ResponseType = $responseType
                    ItemCount = $itemCount
                }
            } else {
                Add-TestResult -TestName $testName -Status 'Warning' -Details "Empty response"
            }
            
        } catch {
            Add-TestResult -TestName $testName -Status 'Fail' -Details $_.Exception.Message
        }
    }
}

function Save-TestResults {
    if (-not $SaveResults) {
        return
    }
    
    # Ensure output directory exists
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Finalize test results
    $script:TestResults.EndTime = Get-Date
    $script:TestResults.Duration = ($script:TestResults.EndTime - $script:TestResults.StartTime).ToString('hh\:mm\:ss')
    
    # Generate filename
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $filename = "SystemHealth-$TestType-$timestamp"
    
    # Save JSON results
    $jsonPath = Join-Path $OutputPath "$filename.json"
    $script:TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
    Write-TestLog "Test results saved to: $jsonPath" -Level Info
    
    # Generate HTML report if requested
    if ($GenerateReport) {
        $htmlPath = Join-Path $OutputPath "$filename.html"
        Generate-HTMLReport -OutputPath $htmlPath
    }
}

function Generate-HTMLReport {
    param([string]$OutputPath)
    
    $passRate = [math]::Round(($script:TestResults.Summary.Passed / $script:TestResults.Summary.Total) * 100, 1)
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Enhanced Documentation System - Health Report</title>
    <style>
        body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; margin: 20px; }
        .header { background: #0078d4; color: white; padding: 20px; border-radius: 5px; }
        .summary { display: flex; gap: 20px; margin: 20px 0; }
        .metric { background: #f8f9fa; padding: 15px; border-radius: 5px; text-align: center; flex: 1; }
        .pass { color: #28a745; } .fail { color: #dc3545; } .warning { color: #ffc107; }
        .results { margin: 20px 0; }
        table { width: 100%; border-collapse: collapse; }
        th, td { border: 1px solid #dee2e6; padding: 8px; text-align: left; }
        th { background: #e9ecef; }
        .status-pass { background: #d4edda; } .status-fail { background: #f8d7da; } .status-warning { background: #fff3cd; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Enhanced Documentation System - Health Report</h1>
        <p>Test Type: $TestType | Generated: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))</p>
    </div>
    
    <div class="summary">
        <div class="metric">
            <h3>Pass Rate</h3>
            <div class="$(if($passRate -gt 80){'pass'}elseif($passRate -gt 60){'warning'}else{'fail'})">$passRate%</div>
        </div>
        <div class="metric">
            <h3>Total Tests</h3>
            <div>$($script:TestResults.Summary.Total)</div>
        </div>
        <div class="metric">
            <h3>Duration</h3>
            <div>$($script:TestResults.Duration)</div>
        </div>
    </div>
    
    <div class="results">
        <h2>Test Results</h2>
        <table>
            <thead>
                <tr><th>Test Name</th><th>Status</th><th>Details</th><th>Duration (ms)</th></tr>
            </thead>
            <tbody>
"@
    
    foreach ($result in $script:TestResults.Results) {
        $statusClass = "status-$($result.Status.ToLower())"
        $html += "<tr class='$statusClass'><td>$($result.TestName)</td><td>$($result.Status)</td><td>$($result.Details)</td><td>$($result.Duration)</td></tr>"
    }
    
    $html += @"
            </tbody>
        </table>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-TestLog "HTML report generated: $OutputPath" -Level Success
}

function Show-TestSummary {
    Write-TestLog "Test Summary" -Level Info
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "Enhanced Documentation System Health Check" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "Test Type: $TestType" -ForegroundColor White
    Write-Host "Duration: $($script:TestResults.Duration)" -ForegroundColor White
    Write-Host ""
    
    $passRate = [math]::Round(($script:TestResults.Summary.Passed / $script:TestResults.Summary.Total) * 100, 1)
    $color = if ($passRate -gt 80) { 'Green' } elseif ($passRate -gt 60) { 'Yellow' } else { 'Red' }
    
    Write-Host "Overall Pass Rate: $passRate%" -ForegroundColor $color
    Write-Host "✅ Passed:  $($script:TestResults.Summary.Passed)" -ForegroundColor Green
    Write-Host "❌ Failed:  $($script:TestResults.Summary.Failed)" -ForegroundColor Red
    Write-Host "⚠️  Warning: $($script:TestResults.Summary.Warning)" -ForegroundColor Yellow
    Write-Host "⏭️  Skipped: $($script:TestResults.Summary.Skipped)" -ForegroundColor Gray
    Write-Host ""
    
    if ($script:TestResults.Summary.Failed -gt 0) {
        Write-Host "❌ SYSTEM HEALTH: CRITICAL ISSUES DETECTED" -ForegroundColor Red
        exit 2
    } elseif ($script:TestResults.Summary.Warning -gt 0) {
        Write-Host "⚠️  SYSTEM HEALTH: WARNINGS DETECTED" -ForegroundColor Yellow
        exit 1
    } else {
        Write-Host "✅ SYSTEM HEALTH: ALL SYSTEMS OPERATIONAL" -ForegroundColor Green
        exit 0
    }
}

# Main execution
function Start-HealthCheck {
    Write-TestLog "Enhanced Documentation System Health Check" -Level Info
    Write-TestLog "Test Type: $TestType" -Level Info
    Write-TestLog "Starting health assessment..." -Level Info
    
    # Core tests (always run)
    Test-DockerServices
    Test-ServiceEndpoints
    
    # Extended tests based on type
    if ($TestType -in @('Full', 'Critical')) {
        Test-PowerShellModules
        Test-FileSystemHealth
    }
    
    if ($TestType -in @('Full', 'Performance')) {
        Test-PerformanceMetrics
        Test-APIFunctionality
    }
    
    # Save and report results
    Save-TestResults
    Show-TestSummary
}

# Execute health check
Start-HealthCheck
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCTAamC8v0OoLgn
# YPtYnvfGVvMqiCNaeiTa8CCBd/mprKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIGw2saA4ENA8c8YdFvUB7nAh
# bSpnLWxOOdWFQGcXX8oxMA0GCSqGSIb3DQEBAQUABIIBAHj2GlhQuWyA6afClSCl
# U8JOEx7edOEpkaNWdZIbDoQcR766XcpKkozyQAguXBFF77Xyh1kxiep52c0EKrrw
# cJZjixUaoP7EDNjJGqUwVZlcsUJop4+BXps7MF3gqaicLB0IuQ75MicAOsI9MJsA
# Urvk81IVRoAopV5y+365lYRGoTRp6LXJy1gwMgBWr5I9X2aIXwlWe+9IaMbV5Rl8
# 3MAVDLIwlo+wEbliHTCtdTYTM4QK6iE5S8ZQiNaBtiLxLTGhUIQmtTGAIn2C/mFY
# W1DdxM1V1Y0N+hgomT+NTPGrM/27MYKZjCF35mPKABHZj4BcotGgP6jEOCz0/j2R
# brk=
# SIG # End signature block
