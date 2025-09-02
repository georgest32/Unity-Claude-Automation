# Test-FileMonitor.ps1
# Comprehensive test script for Unity-Claude-FileMonitor module

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$SaveResults
)

# Test results structure
$script:TestResults = @{
    StartTime = Get-Date
    Tests = @()
    Summary = @{
        Total = 0
        Passed = 0
        Failed = 0
        Duration = 0
    }
}

function Write-TestLog {
    param([string]$Message, [string]$Level = 'Info')
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        'Error' { Write-Host $logMessage -ForegroundColor Red }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
        'Debug' { Write-Verbose $logMessage }
        default { Write-Host $logMessage }
    }
}

function Test-ModuleFunction {
    param(
        [string]$TestName,
        [scriptblock]$TestScript,
        [string]$Description = ''
    )
    
    Write-TestLog "Running test: $TestName" 'Info'
    
    $testResult = @{
        Name = $TestName
        Description = $Description
        Status = 'Failed'
        Error = $null
        Duration = 0
        Timestamp = Get-Date
    }
    
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    
    try {
        $result = & $TestScript
        if ($result -eq $true -or $result.Success -eq $true) {
            $testResult.Status = 'Passed'
            Write-TestLog "  [PASSED] $TestName" 'Success'
        }
        else {
            $testResult.Status = 'Failed'
            $testResult.Error = "Test returned false or unsuccessful result"
            Write-TestLog "  [FAILED] $TestName" 'Error'
        }
    }
    catch {
        $testResult.Status = 'Failed'
        $testResult.Error = $_.Exception.Message
        Write-TestLog "  [FAILED] $TestName - Error: $_" 'Error'
    }
    finally {
        $stopwatch.Stop()
        $testResult.Duration = $stopwatch.ElapsedMilliseconds
    }
    
    $script:TestResults.Tests += $testResult
    $script:TestResults.Summary.Total++
    
    if ($testResult.Status -eq 'Passed') {
        $script:TestResults.Summary.Passed++
    }
    else {
        $script:TestResults.Summary.Failed++
    }
    
    return $testResult
}

# Main test execution
Write-TestLog "=" * 60 'Info'
Write-TestLog "Unity-Claude-FileMonitor Test Suite" 'Info'
Write-TestLog "=" * 60 'Info'
Write-TestLog "Starting at: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" 'Info'
Write-TestLog "" 'Info'

# Import the module
Write-TestLog "Importing Unity-Claude-FileMonitor module..." 'Info'
try {
    Import-Module "$PSScriptRoot\Modules\Unity-Claude-FileMonitor\Unity-Claude-FileMonitor.psd1" -Force
    Write-TestLog "Module imported successfully" 'Success'
}
catch {
    Write-TestLog "Failed to import module: $_" 'Error'
    exit 1
}

# Create test directory
$testDir = Join-Path $env:TEMP "FileMonitorTest_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
Write-TestLog "Created test directory: $testDir" 'Info'

try {
    # Test 1: Module Loading
    Test-ModuleFunction -TestName "Module Loading" -Description "Verify module loads correctly" -TestScript {
        $module = Get-Module -Name 'Unity-Claude-FileMonitor'
        return ($null -ne $module)
    }
    
    # Test 2: Create File Monitor
    Test-ModuleFunction -TestName "Create File Monitor" -Description "Create a new file monitor" -TestScript {
        $monitorId = New-FileMonitor -Path $testDir -Filter '*.*' -DebounceMs 100
        return (-not [string]::IsNullOrEmpty($monitorId))
    }
    
    # Test 3: Start File Monitor
    Test-ModuleFunction -TestName "Start File Monitor" -Description "Start monitoring file changes" -TestScript {
        $monitorId = New-FileMonitor -Path $testDir -Filter '*.*' -DebounceMs 100
        Start-FileMonitor -Identifier $monitorId
        $status = Get-FileMonitorStatus -Identifier $monitorId
        return ($status.IsActive -eq $true)
    }
    
    # Test 4: File Change Detection
    Test-ModuleFunction -TestName "File Change Detection" -Description "Detect file creation and changes" -TestScript {
        $monitorId = New-FileMonitor -Path $testDir -Filter '*.*' -DebounceMs 100
        
        # Register a handler to capture changes
        $script:detectedChanges = @()
        Register-FileChangeHandler -Handler {
            param($AggregatedChanges)
            $script:detectedChanges = $AggregatedChanges
        }
        
        Start-FileMonitor -Identifier $monitorId
        
        # Create test files
        $testFile1 = Join-Path $testDir "test1.ps1"
        $testFile2 = Join-Path $testDir "test2.json"
        
        "# Test PowerShell file" | Out-File $testFile1
        '{"test": "data"}' | Out-File $testFile2
        
        # Wait for debounce
        Start-Sleep -Milliseconds 200
        
        # Modify files
        "# Modified content" | Add-Content $testFile1
        
        # Wait for debounce to complete
        Start-Sleep -Milliseconds 200
        
        Stop-FileMonitor -Identifier $monitorId
        
        return ($script:detectedChanges.Count -gt 0)
    }
    
    # Test 5: File Classification
    Test-ModuleFunction -TestName "File Classification" -Description "Test file type classification" -TestScript {
        $testCases = @(
            @{ Path = "test.ps1"; ExpectedType = "Test" }  # Fixed: test.ps1 should be Test type
            @{ Path = "main.ps1"; ExpectedType = "Code" }  # Added: regular .ps1 file for Code type
            @{ Path = "config.json"; ExpectedType = "Config" }
            @{ Path = "README.md"; ExpectedType = "Documentation" }
            @{ Path = "Test-Module.ps1"; ExpectedType = "Test" }
            @{ Path = "project.csproj"; ExpectedType = "Build" }
        )
        
        $allCorrect = $true
        foreach ($testCase in $testCases) {
            $result = Test-FileChangeClassification -FilePath $testCase.Path
            if ($result.FileType -ne $testCase.ExpectedType) {
                Write-TestLog "    Classification mismatch for $($testCase.Path): Expected $($testCase.ExpectedType), got $($result.FileType)" 'Warning'
                $allCorrect = $false
            }
        }
        
        return $allCorrect
    }
    
    # Test 6: Debouncing
    Test-ModuleFunction -TestName "Debouncing" -Description "Test debounce aggregation of rapid changes" -TestScript {
        $monitorId = New-FileMonitor -Path $testDir -Filter '*.*' -DebounceMs 200
        
        # Track aggregated events
        $script:aggregatedEvents = @()
        Register-FileChangeHandler -Handler {
            param($AggregatedChanges)
            $script:aggregatedEvents += @{
                Timestamp = Get-Date
                Changes = $AggregatedChanges
            }
        }
        
        Start-FileMonitor -Identifier $monitorId
        
        # Create rapid file changes
        $testFile = Join-Path $testDir "rapid.txt"
        
        # Multiple rapid writes
        1..5 | ForEach-Object {
            "Line $_" | Out-File $testFile -Append
            Start-Sleep -Milliseconds 50
        }
        
        # Wait for debounce to complete
        Start-Sleep -Milliseconds 300
        
        Stop-FileMonitor -Identifier $monitorId
        
        # Should have aggregated into fewer events due to debouncing
        Write-TestLog "    Aggregated event count: $($script:aggregatedEvents.Count)" 'Debug'
        return ($script:aggregatedEvents.Count -le 2)  # Should be 1-2 aggregated events, not 5
    }
    
    # Test 7: Multiple Monitors
    Test-ModuleFunction -TestName "Multiple Monitors" -Description "Test multiple concurrent monitors" -TestScript {
        $subDir1 = Join-Path $testDir "SubDir1"
        $subDir2 = Join-Path $testDir "SubDir2"
        New-Item -Path $subDir1 -ItemType Directory -Force | Out-Null
        New-Item -Path $subDir2 -ItemType Directory -Force | Out-Null
        
        $monitor1 = Add-MonitorPath -Path $subDir1 -Filter '*.txt'
        $monitor2 = Add-MonitorPath -Path $subDir2 -Filter '*.log'
        
        $monitors = Get-FileMonitorStatus
        $activeCount = ($monitors | Where-Object { $_.IsActive }).Count
        
        Remove-MonitorPath -Path $subDir1
        Remove-MonitorPath -Path $subDir2
        
        return ($activeCount -ge 2)
    }
    
    # Test 8: Priority Classification
    Test-ModuleFunction -TestName "Priority Classification" -Description "Test change priority classification" -TestScript {
        $testCases = @(
            @{ Path = "build.gradle"; ExpectedPriority = 1 }  # Critical
            @{ Path = "main.cs"; ExpectedPriority = 2 }       # High
            @{ Path = "app.config"; ExpectedPriority = 3 }    # Medium
            @{ Path = "readme.md"; ExpectedPriority = 4 }     # Low
            @{ Path = "test_utils.py"; ExpectedPriority = 5 } # Minimal
        )
        
        $allCorrect = $true
        foreach ($testCase in $testCases) {
            $result = Test-FileChangeClassification -FilePath $testCase.Path
            if ($result.Priority -ne $testCase.ExpectedPriority) {
                Write-TestLog "    Priority mismatch for $($testCase.Path): Expected $($testCase.ExpectedPriority), got $($result.Priority)" 'Warning'
                $allCorrect = $false
            }
        }
        
        return $allCorrect
    }
    
    # Test 9: Queue Management
    Test-ModuleFunction -TestName "Queue Management" -Description "Test change queue operations" -TestScript {
        $monitorId = New-FileMonitor -Path $testDir -Filter '*.*' -DebounceMs 500
        Write-TestLog "      Created monitor for queue test: $monitorId" 'Debug'
        
        Start-FileMonitor -Identifier $monitorId
        Write-TestLog "      Started monitor" 'Debug'
        
        # Create changes but don't wait for debounce
        $testFile = Join-Path $testDir "queue_test.txt"
        Write-TestLog "      Creating test file: $testFile" 'Debug'
        "Test content" | Out-File $testFile
        
        # Check pending changes before debounce completes
        Write-TestLog "      Waiting 100ms then checking pending changes" 'Debug'
        Start-Sleep -Milliseconds 100
        $pending = Get-PendingChanges
        $hasPending = ($pending.Count -gt 0)
        Write-TestLog "      Pending changes: $($pending.Count), hasPending: $hasPending" 'Debug'
        
        # Clear queue
        Write-TestLog "      Clearing change queue" 'Debug'
        $cleared = Clear-ChangeQueue
        $pendingAfterClear = Get-PendingChanges
        Write-TestLog "      Cleared: $cleared, Pending after clear: $($pendingAfterClear.Count)" 'Debug'
        
        Stop-FileMonitor -Identifier $monitorId
        
        $result = ($hasPending -and $pendingAfterClear.Count -eq 0)
        Write-TestLog "      Final result: $result (hasPending: $hasPending, clearWorked: $($pendingAfterClear.Count -eq 0))" 'Debug'
        
        return $result
    }
    
    # Test 10: Resource Cleanup
    Test-ModuleFunction -TestName "Resource Cleanup" -Description "Test proper resource disposal" -TestScript {
        $monitorId = New-FileMonitor -Path $testDir -Filter '*.*'
        Write-TestLog "      Created monitor: $monitorId" 'Debug'
        
        Start-FileMonitor -Identifier $monitorId
        Write-TestLog "      Started monitor" 'Debug'
        
        # Get initial status - store IsActive value before it can be modified
        $initialStatus = Get-FileMonitorStatus -Identifier $monitorId
        $initialIsActive = $initialStatus.IsActive  # Store the value before Stop-FileMonitor changes it
        Write-TestLog "      Initial status - IsActive: $initialIsActive" 'Debug'
        
        # Stop monitor
        Write-TestLog "      Stopping monitor" 'Debug'
        Stop-FileMonitor -Identifier $monitorId
        
        # Verify cleanup
        $finalStatus = Get-FileMonitorStatus -Identifier $monitorId
        Write-TestLog "      Final status: $($finalStatus -eq $null ? 'null' : 'not null')" 'Debug'
        
        $initialValid = $initialStatus -ne $null -and $initialIsActive -eq $true
        $finalValid = $finalStatus -eq $null
        
        Write-TestLog "      Initial valid: $initialValid, Final valid: $finalValid" 'Debug'
        
        return ($initialValid -and $finalValid)
    }
}
finally {
    # Cleanup
    Write-TestLog "" 'Info'
    Write-TestLog "Cleaning up test directory..." 'Info'
    
    # Stop any remaining monitors
    $monitors = Get-FileMonitorStatus
    foreach ($monitor in $monitors) {
        try {
            Stop-FileMonitor -Identifier $monitor.Identifier -ErrorAction SilentlyContinue
        }
        catch {
            # Ignore cleanup errors
        }
    }
    
    # Remove test directory
    if (Test-Path $testDir) {
        Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    
    # Calculate summary
    $script:TestResults.Summary.Duration = ((Get-Date) - $script:TestResults.StartTime).TotalSeconds
    
    # Display summary
    Write-TestLog "" 'Info'
    Write-TestLog "=" * 60 'Info'
    Write-TestLog "Test Summary" 'Info'
    Write-TestLog "=" * 60 'Info'
    Write-TestLog "Total Tests: $($script:TestResults.Summary.Total)" 'Info'
    Write-TestLog "Passed: $($script:TestResults.Summary.Passed)" 'Success'
    Write-TestLog "Failed: $($script:TestResults.Summary.Failed)" $(if ($script:TestResults.Summary.Failed -gt 0) { 'Error' } else { 'Info' })
    Write-TestLog "Duration: $([Math]::Round($script:TestResults.Summary.Duration, 2)) seconds" 'Info'
    Write-TestLog "" 'Info'
    
    # Display failed tests
    if ($script:TestResults.Summary.Failed -gt 0) {
        Write-TestLog "Failed Tests:" 'Error'
        $script:TestResults.Tests | Where-Object { $_.Status -eq 'Failed' } | ForEach-Object {
            Write-TestLog "  - $($_.Name): $($_.Error)" 'Error'
        }
        Write-TestLog "" 'Info'
    }
    
    # Save results if requested
    if ($SaveResults) {
        $resultsFile = Join-Path $PSScriptRoot "FileMonitor-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        $script:TestResults | ConvertTo-Json -Depth 10 | Out-File $resultsFile
        Write-TestLog "Test results saved to: $resultsFile" 'Info'
    }
    
    # Remove module
    Remove-Module -Name 'Unity-Claude-FileMonitor' -Force -ErrorAction SilentlyContinue
    
    # Exit with appropriate code
    if ($script:TestResults.Summary.Failed -gt 0) {
        exit 1
    }
    else {
        Write-TestLog "All tests passed successfully!" 'Success'
        exit 0
    }
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA5n6+3iBikhM5Q
# tcBIGLi53I3sCtW71XmLi6qKViKMmKCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIBs85PnBbSr5xiYSVQMW++pp
# iQ2EIXUd0N3TFDt8sogqMA0GCSqGSIb3DQEBAQUABIIBAEfnWckKVt4fgcUlPuRm
# gEyqdtVqw9rWJEU/RQxZX1guHY5H8r+KDZMOIP9VIqTGbUTMSt+YCfwIK1Sp2OuF
# CWWzB0RUt+f5Ni8R6PmFx5rBZ4l5DhqN+CEVABRlraSqMfFNgC9g8NR2Vo/xiINA
# WK4ZF11oRsgYbU2GTiA9HCRyxxgZwXcBYrDzZX15pV0DxJTV2CAwObL4qrkhi4AW
# UFRn7pf8W0L5eBVX5fuOTgtqXWyWjXm+Q5cJhZV2V3rMEH1LVy0eQXr8Mv/47gqQ
# 5DYY6ez4vXhIbGy0zu1lBvRMD1Ut0ytwgvdZsSnq9sfToOTA4QH9BAEWzUsZCP5U
# 5PQ=
# SIG # End signature block
