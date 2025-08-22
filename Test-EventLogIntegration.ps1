# Test-EventLogIntegration.ps1
# Comprehensive test for Unity-Claude Event Log integration
# Tests both PowerShell 5.1 and PowerShell 7 compatibility

param(
    [switch]$InstallEventSource,
    [switch]$SkipSourceCheck
)

$ErrorActionPreference = 'Stop'
$testResults = @()
$testStartTime = Get-Date

# Test result tracking
function Add-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details,
        [double]$Duration = 0
    )
    
    $script:testResults += [PSCustomObject]@{
        TestName = $TestName
        Passed = $Passed
        Details = $Details
        Duration = $Duration
        Timestamp = Get-Date
    }
    
    $status = if ($Passed) { "PASS" } else { "FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Details) {
        Write-Host "  Details: $Details" -ForegroundColor Gray
    }
}

Write-Host "Unity-Claude Event Log Integration Test" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host "PowerShell Version: $($PSVersionTable.PSVersion)" -ForegroundColor Gray
Write-Host "PowerShell Edition: $($PSVersionTable.PSEdition)" -ForegroundColor Gray
Write-Host ""

# Test 1: Module Import
Write-Host "Test 1: Module Import" -ForegroundColor Yellow
try {
    $moduleStart = Get-Date
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-EventLog" -Force -ErrorAction Stop
    $moduleTime = ((Get-Date) - $moduleStart).TotalMilliseconds
    Add-TestResult -TestName "Module Import" -Passed $true -Details "Module loaded in $moduleTime ms" -Duration $moduleTime
}
catch {
    Add-TestResult -TestName "Module Import" -Passed $false -Details $_.Exception.Message
    Write-Host "Cannot continue without module" -ForegroundColor Red
    exit 1
}

# Test 2: Check Administrator Privileges
Write-Host ""
Write-Host "Test 2: Administrator Check" -ForegroundColor Yellow
$isAdmin = [bool]([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')
Add-TestResult -TestName "Administrator Check" -Passed $true -Details "Running as Admin: $isAdmin"

# Test 3: Event Source Check
Write-Host ""
Write-Host "Test 3: Event Source Verification" -ForegroundColor Yellow
if (-not $SkipSourceCheck) {
    try {
        $sourceTest = Test-UCEventSource -Detailed
        
        if ($sourceTest.Exists) {
            Add-TestResult -TestName "Event Source Exists" -Passed $true -Details "Source: $($sourceTest.SourceName), Log: $($sourceTest.LogName)"
            
            # Check if correctly associated
            if ($sourceTest.IsCorrectLog) {
                Add-TestResult -TestName "Event Source Association" -Passed $true -Details "Correctly associated with log"
            }
            else {
                Add-TestResult -TestName "Event Source Association" -Passed $false -Details "Associated with wrong log: $($sourceTest.LogName)"
            }
        }
        else {
            Add-TestResult -TestName "Event Source Exists" -Passed $false -Details "Source does not exist"
            
            if ($InstallEventSource -and $isAdmin) {
                Write-Host "  Attempting to create event source..." -ForegroundColor Yellow
                $initResult = Initialize-UCEventSource
                if ($initResult.Success) {
                    Add-TestResult -TestName "Event Source Creation" -Passed $true -Details $initResult.Message
                }
                else {
                    Add-TestResult -TestName "Event Source Creation" -Passed $false -Details $initResult.Message
                }
            }
            elseif ($InstallEventSource -and -not $isAdmin) {
                Add-TestResult -TestName "Event Source Creation" -Passed $false -Details "Administrator privileges required"
            }
        }
    }
    catch {
        Add-TestResult -TestName "Event Source Verification" -Passed $false -Details $_.Exception.Message
    }
}

# Test 4: Write Event Log Entry
Write-Host ""
Write-Host "Test 4: Write Event Log Entry" -ForegroundColor Yellow
try {
    $writeStart = Get-Date
    $correlationId = [guid]::NewGuid()
    
    $writeResult = Write-UCEventLog -Message "Test event from integration test" `
        -EntryType Information `
        -Component Agent `
        -Action "TestExecution" `
        -Details @{
            TestScript = "Test-EventLogIntegration.ps1"
            PSVersion = $PSVersionTable.PSVersion.ToString()
            TestTime = (Get-Date).ToString()
        } `
        -CorrelationId $correlationId
    
    $writeTime = ((Get-Date) - $writeStart).TotalMilliseconds
    
    if ($writeResult.Success) {
        Add-TestResult -TestName "Write Event Log" -Passed $true -Details "Event ID: $($writeResult.EventId), Duration: $writeTime ms" -Duration $writeTime
    }
    else {
        $fallbackMsg = if ($writeResult.FallbackUsed) { " (used file fallback)" } else { "" }
        Add-TestResult -TestName "Write Event Log" -Passed $false -Details "Failed to write$fallbackMsg"
    }
    
    # Test different event types
    $eventTypes = @('Warning', 'Error', 'Information')
    foreach ($type in $eventTypes) {
        try {
            $result = Write-UCEventLog -Message "Test $type event" -EntryType $type -Component Unity -NoFallback
            Add-TestResult -TestName "Write $type Event" -Passed $result.Success -Details "Event ID: $($result.EventId)"
        }
        catch {
            Add-TestResult -TestName "Write $type Event" -Passed $false -Details $_.Exception.Message
        }
    }
}
catch {
    Add-TestResult -TestName "Write Event Log" -Passed $false -Details $_.Exception.Message
}

# Test 5: Read Event Log Entries
Write-Host ""
Write-Host "Test 5: Read Event Log Entries" -ForegroundColor Yellow
try {
    $readStart = Get-Date
    $events = Get-UCEventLog -MaxEvents 10 -EntryType All
    $readTime = ((Get-Date) - $readStart).TotalMilliseconds
    
    if ($events) {
        Add-TestResult -TestName "Read Event Log" -Passed $true -Details "Retrieved $($events.Count) events in $readTime ms" -Duration $readTime
        
        # Test filtering by component
        $unityEvents = Get-UCEventLog -Component Unity -MaxEvents 5
        Add-TestResult -TestName "Filter by Component" -Passed $true -Details "Found $($unityEvents.Count) Unity events"
        
        # Test time-based filtering
        $recentEvents = Get-UCEventLog -StartTime (Get-Date).AddMinutes(-5)
        Add-TestResult -TestName "Filter by Time" -Passed $true -Details "Found $($recentEvents.Count) events in last 5 minutes"
    }
    else {
        Add-TestResult -TestName "Read Event Log" -Passed $true -Details "No events found (may be empty log)"
    }
}
catch {
    if ($_.Exception.Message -like "*does not exist*") {
        Add-TestResult -TestName "Read Event Log" -Passed $false -Details "Event log does not exist"
    }
    else {
        Add-TestResult -TestName "Read Event Log" -Passed $false -Details $_.Exception.Message
    }
}

# Test 6: Performance Benchmark
Write-Host ""
Write-Host "Test 6: Performance Benchmark" -ForegroundColor Yellow
if ((Test-UCEventSource) -eq $true) {
    try {
        $iterations = 10
        $times = @()
        
        for ($i = 1; $i -le $iterations; $i++) {
            $perfStart = Get-Date
            $result = Write-UCEventLog -Message "Performance test $i" -EntryType Information -Component Monitor -NoFallback
            $perfTime = ((Get-Date) - $perfStart).TotalMilliseconds
            $times += $perfTime
        }
        
        $avgTime = ($times | Measure-Object -Average).Average
        $maxTime = ($times | Measure-Object -Maximum).Maximum
        $minTime = ($times | Measure-Object -Minimum).Minimum
        
        $perfDetails = "Avg: $([math]::Round($avgTime, 2))ms, Min: $([math]::Round($minTime, 2))ms, Max: $([math]::Round($maxTime, 2))ms"
        $perfPassed = $avgTime -lt 100  # Target: <100ms average
        
        Add-TestResult -TestName "Performance Benchmark" -Passed $perfPassed -Details $perfDetails -Duration $avgTime
    }
    catch {
        Add-TestResult -TestName "Performance Benchmark" -Passed $false -Details $_.Exception.Message
    }
}
else {
    Add-TestResult -TestName "Performance Benchmark" -Passed $false -Details "Skipped - Event source not available"
}

# Test 7: Cross-Version Compatibility
Write-Host ""
Write-Host "Test 7: Cross-Version Compatibility" -ForegroundColor Yellow
try {
    $isPSCore = $PSVersionTable.PSEdition -eq 'Core'
    $versionInfo = "PS $($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))"
    
    # Test System.Diagnostics.EventLog availability
    $typeExists = $null -ne ([System.Management.Automation.PSTypeName]'System.Diagnostics.EventLog').Type
    
    if ($typeExists) {
        Add-TestResult -TestName "EventLog Class Available" -Passed $true -Details $versionInfo
        
        # Test static methods
        try {
            $canCheckSource = $null -ne [System.Diagnostics.EventLog]::SourceExists
            Add-TestResult -TestName "Static Methods Available" -Passed $true -Details "SourceExists method available"
        }
        catch {
            Add-TestResult -TestName "Static Methods Available" -Passed $false -Details $_.Exception.Message
        }
    }
    else {
        Add-TestResult -TestName "EventLog Class Available" -Passed $false -Details "System.Diagnostics.EventLog not found"
    }
}
catch {
    Add-TestResult -TestName "Cross-Version Compatibility" -Passed $false -Details $_.Exception.Message
}

# Generate Test Report
Write-Host ""
Write-Host "Test Summary" -ForegroundColor Cyan
Write-Host "============" -ForegroundColor Cyan

$totalTests = $testResults.Count
$passedTests = ($testResults | Where-Object { $_.Passed }).Count
$failedTests = $totalTests - $passedTests
$passRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 2) } else { 0 }

Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Green" })
Write-Host "Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 80) { "Green" } elseif ($passRate -ge 60) { "Yellow" } else { "Red" })
Write-Host "Total Duration: $([math]::Round(((Get-Date) - $testStartTime).TotalSeconds, 2)) seconds" -ForegroundColor Gray

# Save test results
$resultsFile = "$PSScriptRoot\Test-EventLogIntegration-Results_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"
$testResults | Format-Table -AutoSize | Out-String | Set-Content $resultsFile

Write-Host ""
Write-Host "Results saved to: $resultsFile" -ForegroundColor Gray

# Recommendations
if ($failedTests -gt 0) {
    Write-Host ""
    Write-Host "Recommendations:" -ForegroundColor Yellow
    
    if (-not $isAdmin -and ($testResults | Where-Object { $_.TestName -like "*Event Source*" -and -not $_.Passed })) {
        Write-Host "  - Run as Administrator to create event source" -ForegroundColor White
        Write-Host "  - Or run: .\Modules\Unity-Claude-EventLog\Setup\Install-UCEventSource.ps1" -ForegroundColor White
    }
    
    if ($testResults | Where-Object { $_.TestName -eq "Module Import" -and -not $_.Passed }) {
        Write-Host "  - Check module path and file integrity" -ForegroundColor White
    }
}
else {
    Write-Host ""
    Write-Host "All tests passed successfully!" -ForegroundColor Green
}

# Return exit code
exit $(if ($failedTests -eq 0) { 0 } else { 1 })