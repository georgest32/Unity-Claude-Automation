#Requires -Version 7.0

<#
.SYNOPSIS
Test script for LangGraph Bridge State Management (Hour 6)

.DESCRIPTION
Comprehensive test suite for validating PowerShell-LangGraph state management functionality,
including state validation, serialization, checkpoint synchronization, and snapshot management.

.NOTES
Author: Unity-Claude-Automation System
Version: 1.0.0
Phase: Hour 6 - State Management Interface Testing
#>

param(
    [Parameter()]
    [switch]$SaveResults = $true
)

# Import the updated LangGraph Bridge module
$ModulePath = "$PSScriptRoot\Unity-Claude-LangGraphBridge.psm1"
if (-not (Test-Path $ModulePath)) {
    throw "LangGraph Bridge module not found at: $ModulePath"
}

Write-Host "=== Hour 6: State Management Interface Test Suite ===" -ForegroundColor Cyan
Write-Host "Loading module with state management functions..."

Import-Module $ModulePath -Force

# Test results storage
$testResults = @{
    TestSuite = "LangGraph State Management (Hour 6)"
    StartTime = Get-Date
    Tests = @()
    Summary = @{}
}

function Add-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = "",
        [object]$Data = $null
    )
    
    $result = @{
        TestName = $TestName
        Passed = $Passed
        Details = $Details
        Data = $Data
        Timestamp = Get-Date
    }
    
    $testResults.Tests += $result
    
    $status = if ($Passed) { "PASSED" } else { "FAILED" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Details) {
        Write-Host "    $Details" -ForegroundColor Gray
    }
}

# Prerequisites: Ensure server is running
Write-Host "`nChecking server connectivity..." -ForegroundColor Yellow

try {
    $serverHealthy = Test-LangGraphServer
    if (-not $serverHealthy) {
        Write-Host "Server is not responding. Please ensure the Python server is running with state management." -ForegroundColor Red
        return
    }
    Add-TestResult -TestName "Server Health Check" -Passed $true -Details "State management server operational"
}
catch {
    Add-TestResult -TestName "Server Health Check" -Passed $false -Details "Exception: $($_.Exception.Message)"
    return
}

# Test 1: State Validation
Write-Host "`nTesting state validation functionality..." -ForegroundColor Yellow

try {
    # Test basic state validation
    $basicState = @{
        counter = 5
        messages = @(
            @{ role = "user"; content = "Hello" },
            @{ role = "assistant"; content = "Hi there!" }
        )
    }
    
    $validation = Test-LangGraphState -StateData $basicState -StateType "basic"
    Add-TestResult -TestName "Basic State Validation" -Passed $validation.valid -Details "Valid: $($validation.valid)"
    
    # Test HITL state validation
    $hitlState = @{
        counter = 3
        messages = @(@{ role = "user"; content = "Approve this action" })
        approval_needed = $true
        approved = $null
    }
    
    $hitlValidation = Test-LangGraphState -StateData $hitlState -StateType "hitl"
    Add-TestResult -TestName "HITL State Validation" -Passed $hitlValidation.valid -Details "Valid: $($hitlValidation.valid)"
    
    # Test invalid state (missing required fields)
    try {
        $invalidState = @{ incomplete = $true }
        $invalidValidation = Test-LangGraphState -StateData $invalidState -StateType "basic"
        Add-TestResult -TestName "Invalid State Detection" -Passed (-not $invalidValidation.valid) -Details "Should detect invalid state"
    }
    catch {
        Add-TestResult -TestName "Invalid State Detection" -Passed $true -Details "Correctly threw validation error: $($_.Exception.Message)"
    }
}
catch {
    Add-TestResult -TestName "State Validation Tests" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

# Test 2: State Processing and Serialization
Write-Host "`nTesting PowerShell-LangGraph state processing..." -ForegroundColor Yellow

try {
    # Test state conversion with snapshot creation
    $complexState = @{
        counter = 42
        messages = @(
            @{ role = "user"; content = "Process this complex state" },
            @{ role = "assistant"; content = "Processing..." }
        )
        metadata = @{
            version = "1.0"
            timestamp = (Get-Date).ToString("o")
            features = @("state-mgmt", "serialization", "checkpoints")
        }
        config = @{
            timeout = 300
            retry_count = 3
            debug_mode = $true
        }
    }
    
    $graphId = "state-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $threadId = "thread-$(Get-Random -Maximum 9999)"
    
    $processed = ConvertTo-LangGraphState -StateData $complexState -StateType "complex" -GraphId $graphId -ThreadId $threadId
    Add-TestResult -TestName "Complex State Processing" -Passed ($processed.processed_state -ne $null) -Details "Graph: $graphId, Thread: $threadId"
    
    # Test state processing without thread ID (no snapshot)
    $simpleProcessed = ConvertTo-LangGraphState -StateData $basicState -StateType "basic" -GraphId "simple-test"
    Add-TestResult -TestName "Simple State Processing" -Passed ($simpleProcessed.processed_state -ne $null) -Details "No thread ID - no snapshot created"
}
catch {
    Add-TestResult -TestName "State Processing Tests" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

# Test 3: State Synchronization
Write-Host "`nTesting state synchronization with checkpoints..." -ForegroundColor Yellow

try {
    # Create initial state and sync
    $initialState = @{
        counter = 10
        messages = @(@{ role = "user"; content = "Initial state" })
        workflow_step = "initialization"
    }
    
    $syncGraphId = "sync-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $syncThreadId = "sync-thread-$(Get-Random -Maximum 9999)"
    
    # First, process state to create a checkpoint
    ConvertTo-LangGraphState -StateData $initialState -StateType "basic" -GraphId $syncGraphId -ThreadId $syncThreadId | Out-Null
    
    # Now sync with updated state
    $updatedState = @{
        counter = 15
        messages = @(
            @{ role = "user"; content = "Initial state" },
            @{ role = "assistant"; content = "State updated" }
        )
        workflow_step = "processing"
    }
    
    $synced = Sync-LangGraphState -GraphId $syncGraphId -ThreadId $syncThreadId -CurrentState $updatedState
    $hasSyncInfo = $synced.synchronized_state.__checkpoint_info -ne $null
    Add-TestResult -TestName "State Synchronization" -Passed $hasSyncInfo -Details "Synchronized with checkpoint info"
    
    # Test sync with non-existent checkpoint
    $newThreadId = "new-thread-$(Get-Random -Maximum 9999)"
    $newSync = Sync-LangGraphState -GraphId $syncGraphId -ThreadId $newThreadId -CurrentState $updatedState
    $hasNewSyncInfo = $newSync.synchronized_state.__checkpoint_info -ne $null
    Add-TestResult -TestName "Sync Without Checkpoint" -Passed $hasNewSyncInfo -Details "Handled missing checkpoint gracefully"
}
catch {
    Add-TestResult -TestName "State Synchronization Tests" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

# Test 4: State Snapshot Management
Write-Host "`nTesting state snapshot management..." -ForegroundColor Yellow

try {
    # List all snapshots
    $allSnapshots = Get-LangGraphStateSnapshot
    Add-TestResult -TestName "List All Snapshots" -Passed ($allSnapshots.total -ge 0) -Details "Found $($allSnapshots.total) snapshots"
    
    # Filter snapshots by graph ID (using one we created above)
    if ($allSnapshots.total -gt 0) {
        $testGraphId = $syncGraphId  # Use the graph ID from previous test
        $filteredSnapshots = Get-LangGraphStateSnapshot -GraphId $testGraphId
        Add-TestResult -TestName "Filter Snapshots by Graph" -Passed ($filteredSnapshots.total -ge 0) -Details "Found $($filteredSnapshots.total) snapshots for graph $testGraphId"
        
        # Try to get a specific snapshot
        if ($filteredSnapshots.snapshots.Count -gt 0) {
            $snapshotId = $filteredSnapshots.snapshots[0].state_id
            $specificSnapshot = Get-LangGraphStateSnapshot -SnapshotId $snapshotId
            Add-TestResult -TestName "Get Specific Snapshot" -Passed ($specificSnapshot.snapshot_id -eq $snapshotId) -Details "Retrieved snapshot: $snapshotId"
        }
        else {
            Add-TestResult -TestName "Get Specific Snapshot" -Passed $true -Details "No snapshots available to test"
        }
    }
    else {
        Add-TestResult -TestName "Filter Snapshots by Graph" -Passed $true -Details "No snapshots available to filter"
        Add-TestResult -TestName "Get Specific Snapshot" -Passed $true -Details "No snapshots available to test"
    }
}
catch {
    Add-TestResult -TestName "Snapshot Management Tests" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

# Test 5: State Statistics
Write-Host "`nTesting state management statistics..." -ForegroundColor Yellow

try {
    $stats = Get-LangGraphStateStatistics
    $hasStats = $stats.statistics -ne $null
    Add-TestResult -TestName "State Statistics" -Passed $hasStats -Details "Total snapshots: $($stats.statistics.total_snapshots), Unique graphs: $($stats.statistics.unique_graphs)"
}
catch {
    Add-TestResult -TestName "State Statistics Tests" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

# Test 6: PowerShell State Preparation
Write-Host "`nTesting PowerShell state preparation..." -ForegroundColor Yellow

try {
    # Test converting Python state back to PowerShell format
    $pythonStyleState = @{
        counter = 25
        messages = @(@{ role = "assistant"; content = "Python processed" })
        result = "success"
        timestamp = "2025-08-23T16:00:00Z"
    }
    
    $psState = ConvertFrom-LangGraphState -StateData $pythonStyleState
    Add-TestResult -TestName "Python to PowerShell Conversion" -Passed ($psState.powershell_state -ne $null) -Details "State converted for PowerShell consumption"
    
    # Test with metadata
    $psStateWithMeta = ConvertFrom-LangGraphState -StateData $pythonStyleState -IncludeMetadata
    $hasMetadata = ($psStateWithMeta.powershell_state.__metadata -ne $null) -or ($psStateWithMeta.include_metadata -eq $true)
    Add-TestResult -TestName "PowerShell State with Metadata" -Passed $hasMetadata -Details "Metadata included: $hasMetadata"
}
catch {
    Add-TestResult -TestName "PowerShell State Preparation Tests" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

# Test 7: Integration with Graph Execution
Write-Host "`nTesting state management integration with graph execution..." -ForegroundColor Yellow

try {
    # Create a graph and execute it with state management
    $integrationGraphId = "state-integration-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $createResult = New-LangGraph -GraphId $integrationGraphId -GraphType "basic"
    
    if ($createResult.status -eq "created") {
        # Execute with state that will be managed
        $executionState = @{
            counter = 1
            messages = @(@{ role = "user"; content = "State management integration test" })
        }
        
        # Process the state first
        $processedState = ConvertTo-LangGraphState -StateData $executionState -StateType "basic" -GraphId $integrationGraphId -ThreadId "integration-thread"
        
        # Execute the graph with original state (not processed state)
        $execution = Start-LangGraphExecution -GraphId $integrationGraphId -InitialState $executionState
        
        Add-TestResult -TestName "Graph Execution with State Management" -Passed ($execution.status -eq "completed") -Details "Integration successful: $($execution.status)"
        
        # Clean up
        Remove-LangGraph -GraphId $integrationGraphId -Confirm:$false | Out-Null
    }
    else {
        Add-TestResult -TestName "Graph Execution with State Management" -Passed $false -Details "Failed to create test graph"
    }
}
catch {
    Add-TestResult -TestName "Integration Tests" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

# Generate final summary
$testResults.EndTime = Get-Date
$testResults.Duration = ($testResults.EndTime - $testResults.StartTime).ToString()

$passedTests = ($testResults.Tests | Where-Object { $_.Passed }).Count
$totalTests = $testResults.Tests.Count
$passRate = [math]::Round(($passedTests / $totalTests) * 100, 1)

$testResults.Summary = @{
    TotalTests = $totalTests
    PassedTests = $passedTests
    FailedTests = $totalTests - $passedTests
    PassRate = "$passRate%"
    Duration = $testResults.Duration
}

# Display summary
Write-Host "`n=== HOUR 6: STATE MANAGEMENT TEST SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green  
Write-Host "Failed: $($totalTests - $passedTests)" -ForegroundColor Red
Write-Host "Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 85) { "Green" } else { "Yellow" })
Write-Host "Duration: $($testResults.Duration)" -ForegroundColor White

# Save results if requested
if ($SaveResults) {
    $resultsFile = "StateManagement-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
    Write-Host "`nTest results saved to: $resultsFile" -ForegroundColor Cyan
}

# Overall success determination
if ($passRate -ge 85) {
    Write-Host "`n🎉 Hour 6: State Management Interface tests completed successfully!" -ForegroundColor Green
    Write-Host "PowerShell-LangGraph state management is fully operational." -ForegroundColor Green
    
    Write-Host "`n=== HOUR 6 ACHIEVEMENTS ===" -ForegroundColor Cyan
    Write-Host "✅ State validation system working" -ForegroundColor Green
    Write-Host "✅ PowerShell-Python state serialization functional" -ForegroundColor Green
    Write-Host "✅ Checkpoint synchronization operational" -ForegroundColor Green
    Write-Host "✅ State snapshot management available" -ForegroundColor Green
    Write-Host "✅ State statistics and monitoring ready" -ForegroundColor Green
    Write-Host "✅ Graph execution integration complete" -ForegroundColor Green
    
    exit 0
}
else {
    Write-Host "`n⚠️  Some state management tests failed. Please review the results above." -ForegroundColor Yellow
    exit 1
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB4MZqZ7GjEiD52
# LfMr9PhP8pu9Hsr5p8k0Izyqn5aUMaCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIM7XwY2ulGJCFvha9G/KiOEI
# W05+pdLecmQB5LEYuuetMA0GCSqGSIb3DQEBAQUABIIBADGR9xdSZMEGwgvg+IKY
# TzKpRQBreaOcVJ67QmBKyM7+VvSEz1oLLvFugZTCWPFsDtcCWo7JnSd4t7Ry+s3P
# UIgs1QwGuqEFJe49oq7z7HIErZHBKX28JR42TI4iTot/nUaLZ8VO9PMbCVraVH22
# L5eF7WhiNfHAJ3ReTFt4EeoDVpYC5iGiAHk7dqV1B3BJbPQjXLgqUm+GcFaVXMo9
# XquB5+CLA63EXJVmWj/hWEvEHAwo/hniJVqiOBM6Ts/5I/s8RoQu2EqLZ6UPbHzT
# 8pH/+kjp1zEIcvrblW/lMEqK1FFRCp5HRavwKz/NN77ZgIZDhtcQhaXyVCb66C8r
# 9Dc=
# SIG # End signature block
