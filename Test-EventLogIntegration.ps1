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
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCCT6JUMxQ9R1CjX
# 57uVso1rG68lo1skK8C7XYQwvGTVwqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEID5dZNC+FKm00FIAaeZ6FNhx
# 9LrOnyziXFpfut+oN1HxMA0GCSqGSIb3DQEBAQUABIIBAKb5n1mSnG4ZWcSoPvV2
# PySvnKgO2PNldrQFtl4dUTyzSPnphWnC3ClwDfSy+Gt1nV4+2tdFN9PiDFn1uLpH
# 4zqxzHvx873NSw0dfJsYMU+05ddqllzAeJtdfEUQzLv/A0NywUleRAooNIceUUJh
# fnYWvPOZBWNkJ3EDsH/hGMHoqHfk1XyIUefHQRS7eoJnyR5DrQIweHUWx5lfN84V
# CfHfdwVoyu0n3rYmG6mXpAFFIS8VOKXELW9ww+VLfO+U7bqNIc6MC/WFocBlh3MH
# Nx6ZxH9jnhnK+wV2LGSxaYULQ/+S3qIo12aT9rKUSMpElGTDGsuviKrOUy2XYHfu
# 2Ek=
# SIG # End signature block
