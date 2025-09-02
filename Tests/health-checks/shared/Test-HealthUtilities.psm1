# Unity-Claude-Automation Health Check Utilities
# Shared functions for all health check components
# Version: 2025-08-25

# Global test results tracking
$script:TestResults = @{
    StartTime = Get-Date
    TestType = 'Unknown'
    Results = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Warning = 0
        Skipped = 0
    }
}

function Initialize-HealthCheck {
    <#
    .SYNOPSIS
    Initialize a health check session
    
    .PARAMETER TestType
    The type of health check being performed
    #>
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Quick', 'Full', 'Critical', 'Performance')]
        [string]$TestType
    )
    
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
    
    Write-TestLog "Initialized health check session: $TestType" -Level Info
}

function Write-TestLog {
    <#
    .SYNOPSIS
    Write a formatted test log message
    
    .PARAMETER Message
    The message to log
    
    .PARAMETER Level
    The log level
    
    .PARAMETER TestName
    Optional test name for context
    #>
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
    <#
    .SYNOPSIS
    Add a test result to the global results collection
    
    .PARAMETER TestName
    Name of the test
    
    .PARAMETER Status
    Test status
    
    .PARAMETER Details
    Additional details about the test result
    
    .PARAMETER Metrics
    Optional metrics hashtable
    
    .PARAMETER Duration
    Test duration in milliseconds
    #>
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
    <#
    .SYNOPSIS
    Test health of a web service endpoint
    
    .PARAMETER ServiceName
    Name of the service being tested
    
    .PARAMETER URL
    Service URL to test
    
    .PARAMETER TimeoutSeconds
    Request timeout in seconds
    
    .PARAMETER ExpectedContent
    Optional content to verify in response
    
    .PARAMETER Headers
    Optional headers for the request
    #>
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

function Get-TestResults {
    <#
    .SYNOPSIS
    Get the current test results
    #>
    return $script:TestResults
}

function Save-TestResults {
    <#
    .SYNOPSIS
    Save test results to file
    
    .PARAMETER OutputPath
    Directory to save results
    
    .PARAMETER GenerateReport
    Whether to generate HTML report
    #>
    param(
        [string]$OutputPath = '.\health-reports',
        [switch]$GenerateReport
    )
    
    # Ensure output directory exists
    if (-not (Test-Path $OutputPath)) {
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }
    
    # Finalize test results
    $script:TestResults.EndTime = Get-Date
    $script:TestResults.Duration = ($script:TestResults.EndTime - $script:TestResults.StartTime).ToString('hh\:mm\:ss')
    
    # Generate filename
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $filename = "SystemHealth-$($script:TestResults.TestType)-$timestamp"
    
    # Save JSON results
    $jsonPath = Join-Path $OutputPath "$filename.json"
    $script:TestResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $jsonPath -Encoding UTF8
    Write-TestLog "Test results saved to: $jsonPath" -Level Info
    
    # Generate HTML report if requested
    if ($GenerateReport) {
        $htmlPath = Join-Path $OutputPath "$filename.html"
        Generate-HTMLReport -OutputPath $htmlPath
    }
    
    return $jsonPath
}

function Generate-HTMLReport {
    <#
    .SYNOPSIS
    Generate HTML report from test results
    
    .PARAMETER OutputPath
    Path for the HTML report
    #>
    param([string]$OutputPath)
    
    $passRate = if ($script:TestResults.Summary.Total -gt 0) {
        [math]::Round(($script:TestResults.Summary.Passed / $script:TestResults.Summary.Total) * 100, 1)
    } else { 0 }
    
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>Unity-Claude-Automation - Health Report</title>
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
        <h1>Unity-Claude-Automation - Health Report</h1>
        <p>Test Type: $($script:TestResults.TestType) | Generated: $((Get-Date).ToString('yyyy-MM-dd HH:mm:ss'))</p>
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
    <#
    .SYNOPSIS
    Display test summary and set exit code
    #>
    Write-TestLog "Test Summary" -Level Info
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "Unity-Claude-Automation Health Check" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "Test Type: $($script:TestResults.TestType)" -ForegroundColor White
    Write-Host "Duration: $($script:TestResults.Duration)" -ForegroundColor White
    Write-Host ""
    
    $passRate = if ($script:TestResults.Summary.Total -gt 0) {
        [math]::Round(($script:TestResults.Summary.Passed / $script:TestResults.Summary.Total) * 100, 1)
    } else { 0 }
    
    $color = if ($passRate -gt 80) { 'Green' } elseif ($passRate -gt 60) { 'Yellow' } else { 'Red' }
    
    Write-Host "Overall Pass Rate: $passRate%" -ForegroundColor $color
    Write-Host "✅ Passed:  $($script:TestResults.Summary.Passed)" -ForegroundColor Green
    Write-Host "❌ Failed:  $($script:TestResults.Summary.Failed)" -ForegroundColor Red
    Write-Host "⚠️  Warning: $($script:TestResults.Summary.Warning)" -ForegroundColor Yellow
    Write-Host "⏭️  Skipped: $($script:TestResults.Summary.Skipped)" -ForegroundColor Gray
    Write-Host ""
    
    $exitCode = 0
    if ($script:TestResults.Summary.Failed -gt 0) {
        Write-Host "❌ SYSTEM HEALTH: CRITICAL ISSUES DETECTED" -ForegroundColor Red
        $exitCode = 2
    } elseif ($script:TestResults.Summary.Warning -gt 0) {
        Write-Host "⚠️  SYSTEM HEALTH: WARNINGS DETECTED" -ForegroundColor Yellow
        $exitCode = 1
    } else {
        Write-Host "✅ SYSTEM HEALTH: ALL SYSTEMS OPERATIONAL" -ForegroundColor Green
        $exitCode = 0
    }
    
    return $exitCode
}

# Export functions
Export-ModuleMember -Function @(
    'Initialize-HealthCheck',
    'Write-TestLog',
    'Add-TestResult',
    'Test-ServiceHealth',
    'Get-TestResults',
    'Save-TestResults',
    'Generate-HTMLReport',
    'Show-TestSummary'
)