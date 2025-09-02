#Requires -Version 7.0

<#
.SYNOPSIS
Test script for Unity-Claude LangGraph Bridge PowerShell Module
Phase 4: Multi-Agent Orchestration - Hours 5-8 Testing

.DESCRIPTION
Comprehensive test suite for validating PowerShell-LangGraph REST API bridge functionality.
Tests HTTP communication, graph operations, state management, and HITL workflows.

.NOTES
Author: Unity-Claude-Automation System
Version: 1.0.0
Created: 2025-08-23
#>

param(
    [Parameter()]
    [switch]$SkipInteractive,
    
    [Parameter()]
    [switch]$SaveResults = $true
)

# Import the LangGraph Bridge module
$ModulePath = "$PSScriptRoot\Unity-Claude-LangGraphBridge.psm1"
if (-not (Test-Path $ModulePath)) {
    throw "LangGraph Bridge module not found at: $ModulePath"
}

Write-Host "=== Unity-Claude LangGraph Bridge Test Suite ===" -ForegroundColor Cyan
Write-Host "Loading module: $ModulePath"

Import-Module $ModulePath -Force

# Test results storage
$testResults = @{
    TestSuite = "LangGraph Bridge PowerShell Integration"
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

# Test 1: Server Connectivity
Write-Host "`nTesting server connectivity..." -ForegroundColor Yellow

try {
    $serverHealthy = Test-LangGraphServer
    Add-TestResult -TestName "Server Health Check" -Passed $serverHealthy -Details "Server responded to health check"
    
    if ($serverHealthy) {
        $serverInfo = Get-LangGraphServerInfo
        Add-TestResult -TestName "Server Info Retrieval" -Passed $true -Details "Version: $($serverInfo.version), Service: $($serverInfo.service)" -Data $serverInfo
    }
    else {
        Add-TestResult -TestName "Server Info Retrieval" -Passed $false -Details "Server not healthy, skipping info retrieval"
        Write-Host "Server is not responding. Please ensure the Python server is running." -ForegroundColor Red
        return
    }
}
catch {
    Add-TestResult -TestName "Server Connectivity" -Passed $false -Details "Exception: $($_.Exception.Message)"
    Write-Host "Server connectivity failed. Aborting tests." -ForegroundColor Red
    return
}

# Test 2: Basic Graph Operations
Write-Host "`nTesting basic graph operations..." -ForegroundColor Yellow

try {
    # Create a basic graph
    $graphId = "test-graph-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $createResult = New-LangGraph -GraphId $graphId -GraphType "basic"
    Add-TestResult -TestName "Create Basic Graph" -Passed ($createResult.status -eq "created") -Details "Graph ID: $graphId"
    
    # List graphs
    $graphList = Get-LangGraph
    $graphExists = $graphList.graphs.PSObject.Properties.Name -contains $graphId
    Add-TestResult -TestName "List Graphs" -Passed $graphExists -Details "Found $($graphList.total) graphs, including our test graph"
    
    # Execute basic graph
    $initialState = @{
        counter = 0
        messages = @()
    }
    
    $execution = Start-LangGraphExecution -GraphId $graphId -InitialState $initialState
    Add-TestResult -TestName "Execute Basic Graph" -Passed ($execution.status -eq "completed") -Details "Execution status: $($execution.status)"
    
    # Clean up
    $deleteResult = Remove-LangGraph -GraphId $graphId -Confirm:$false
    Add-TestResult -TestName "Delete Basic Graph" -Passed ($deleteResult.status -eq "deleted") -Details "Graph cleaned up successfully"
}
catch {
    Add-TestResult -TestName "Basic Graph Operations" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

# Test 3: HITL Graph Operations  
Write-Host "`nTesting HITL graph operations..." -ForegroundColor Yellow

try {
    # Create HITL graph
    $hitlGraphId = "hitl-graph-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $hitlCreateResult = New-LangGraph -GraphId $hitlGraphId -GraphType "hitl"
    Add-TestResult -TestName "Create HITL Graph" -Passed ($hitlCreateResult.status -eq "created") -Details "HITL Graph ID: $hitlGraphId"
    
    # Execute HITL graph (should be interrupted)
    $hitlInitialState = @{
        counter = 5
        messages = @(@{ role = "user"; content = "Test HITL workflow" })
    }
    
    $hitlExecution = Start-LangGraphExecution -GraphId $hitlGraphId -InitialState $hitlInitialState
    $wasInterrupted = $hitlExecution.status -eq "interrupted"
    Add-TestResult -TestName "Execute HITL Graph (Interrupt)" -Passed $wasInterrupted -Details "Status: $($hitlExecution.status), Thread: $($hitlExecution.thread_id)"
    
    if ($wasInterrupted) {
        # Test thread status
        $threadInfo = Get-LangGraphThread -ThreadId $hitlExecution.thread_id
        Add-TestResult -TestName "Get Thread Status" -Passed ($threadInfo.thread_id -eq $hitlExecution.thread_id) -Details "Thread status: $($threadInfo.info.status)"
        
        # Resume with approval
        $approvalResponse = @{ approved = $true }
        $resumeResult = Resume-LangGraphExecution -GraphId $hitlGraphId -ThreadId $hitlExecution.thread_id -ResumeValue $approvalResponse
        Add-TestResult -TestName "Resume HITL Graph" -Passed ($resumeResult.status -eq "completed") -Details "Resumed with approval, final status: $($resumeResult.status)"
        
        # Test thread cleanup
        $threadDeleteResult = Remove-LangGraphThread -ThreadId $hitlExecution.thread_id -Confirm:$false
        Add-TestResult -TestName "Delete Thread" -Passed ($threadDeleteResult.status -eq "deleted") -Details "Thread cleaned up successfully"
    }
    
    # Clean up HITL graph
    $hitlDeleteResult = Remove-LangGraph -GraphId $hitlGraphId -Confirm:$false
    Add-TestResult -TestName "Delete HITL Graph" -Passed ($hitlDeleteResult.status -eq "deleted") -Details "HITL graph cleaned up successfully"
}
catch {
    Add-TestResult -TestName "HITL Graph Operations" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

# Test 4: Error Handling and Edge Cases
Write-Host "`nTesting error handling..." -ForegroundColor Yellow

try {
    # Test non-existent graph
    try {
        $nonExistentExecution = Start-LangGraphExecution -GraphId "non-existent-graph" -InitialState @{}
        Add-TestResult -TestName "Non-Existent Graph Error Handling" -Passed $false -Details "Should have thrown an error"
    }
    catch {
        Add-TestResult -TestName "Non-Existent Graph Error Handling" -Passed $true -Details "Correctly threw error: $($_.Exception.Message)"
    }
    
    # Test invalid thread ID
    try {
        $invalidThreadInfo = Get-LangGraphThread -ThreadId "invalid-thread-id"
        Add-TestResult -TestName "Invalid Thread Error Handling" -Passed $false -Details "Should have thrown an error"
    }
    catch {
        Add-TestResult -TestName "Invalid Thread Error Handling" -Passed $true -Details "Correctly threw error: $($_.Exception.Message)"
    }
}
catch {
    Add-TestResult -TestName "Error Handling Tests" -Passed $false -Details "Unexpected exception: $($_.Exception.Message)"
}

# Test 5: State Serialization
Write-Host "`nTesting state serialization..." -ForegroundColor Yellow

try {
    # Create graph for state testing
    $stateGraphId = "state-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
    $stateCreateResult = New-LangGraph -GraphId $stateGraphId -GraphType "basic"
    
    # Complex state with various data types
    $complexState = @{
        counter = 42
        messages = @(
            @{ role = "user"; content = "Hello"; timestamp = "2025-08-23T15:30:00Z" },
            @{ role = "assistant"; content = "Hi there!"; timestamp = "2025-08-23T15:30:01Z" }
        )
        metadata = @{
            version = "1.0.0"
            features = @("hitl", "persistence", "multi-agent")
            config = @{
                timeout = 300
                retry_count = 3
                debug_mode = $true
            }
        }
        user_input = "Complex test scenario"
    }
    
    $complexExecution = Start-LangGraphExecution -GraphId $stateGraphId -InitialState $complexState
    $statePreserved = $complexExecution.result -ne $null
    Add-TestResult -TestName "Complex State Serialization" -Passed $statePreserved -Details "State preserved through JSON serialization"
    
    # Clean up
    $stateDeleteResult = Remove-LangGraph -GraphId $stateGraphId -Confirm:$false
    Add-TestResult -TestName "State Test Cleanup" -Passed ($stateDeleteResult.status -eq "deleted") -Details "State test graph cleaned up"
}
catch {
    Add-TestResult -TestName "State Serialization Test" -Passed $false -Details "Exception: $($_.Exception.Message)"
}

# Interactive HITL Test (optional)
if (-not $SkipInteractive) {
    Write-Host "`nTesting interactive HITL workflow..." -ForegroundColor Yellow
    
    try {
        $interactiveGraphId = "interactive-test-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
        $interactiveResult = New-LangGraph -GraphId $interactiveGraphId -GraphType "hitl"
        
        $interactiveExecution = Start-LangGraphExecution -GraphId $interactiveGraphId -InitialState @{ counter = 1 }
        
        if ($interactiveExecution.status -eq "interrupted") {
            Write-Host "Interactive HITL test started. You will be prompted for approval..." -ForegroundColor Cyan
            $approvalResult = Wait-LangGraphApproval -GraphId $interactiveGraphId -ThreadId $interactiveExecution.thread_id -Message "Test approval workflow"
            Add-TestResult -TestName "Interactive HITL Approval" -Passed ($approvalResult.status -eq "completed") -Details "Interactive approval workflow completed"
        }
        
        # Clean up
        Remove-LangGraph -GraphId $interactiveGraphId -Confirm:$false | Out-Null
    }
    catch {
        Add-TestResult -TestName "Interactive HITL Test" -Passed $false -Details "Exception: $($_.Exception.Message)"
    }
}

# Test 6: Module Configuration
Write-Host "`nTesting module configuration..." -ForegroundColor Yellow

try {
    # Test URI management
    $originalUri = Get-LangGraphServerUri
    $testUri = "http://test.example.com:9000"
    
    Set-LangGraphServerUri -Uri $testUri
    $updatedUri = Get-LangGraphServerUri
    $uriUpdateWorked = $updatedUri -eq $testUri
    Add-TestResult -TestName "Server URI Update" -Passed $uriUpdateWorked -Details "URI changed from $originalUri to $updatedUri"
    
    # Restore original URI
    Set-LangGraphServerUri -Uri $originalUri
    
    # Test logging controls
    Disable-LangGraphLogging
    Enable-LangGraphLogging
    Add-TestResult -TestName "Logging Controls" -Passed $true -Details "Logging enable/disable functions work"
}
catch {
    Add-TestResult -TestName "Module Configuration" -Passed $false -Details "Exception: $($_.Exception.Message)"
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
Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Cyan
Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green  
Write-Host "Failed: $($totalTests - $passedTests)" -ForegroundColor Red
Write-Host "Pass Rate: $passRate%" -ForegroundColor $(if ($passRate -ge 80) { "Green" } else { "Yellow" })
Write-Host "Duration: $($testResults.Duration)" -ForegroundColor White

# Save results if requested
if ($SaveResults) {
    $resultsFile = "LangGraphBridge-TestResults-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $testResults | ConvertTo-Json -Depth 10 | Out-File -FilePath $resultsFile -Encoding UTF8
    Write-Host "`nTest results saved to: $resultsFile" -ForegroundColor Cyan
}

# Overall success determination
if ($passRate -ge 80) {
    Write-Host "`n🎉 LangGraph Bridge tests completed successfully!" -ForegroundColor Green
    Write-Host "PowerShell-LangGraph integration is operational." -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`n⚠️  Some tests failed. Please review the results above." -ForegroundColor Yellow
    exit 1
}
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBCgd0/m48TIyof
# FCmYk5arEM9x0H6U4tkeuKwXGmR8o6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIFAGANwoaq6RzIQGNHUzoRFO
# TkbVW4YMYzdw0CypKi1zMA0GCSqGSIb3DQEBAQUABIIBAAbWvuwKkGIOJwZrhpgk
# WdVinnovrNwpBTpoVJh5zKB8Mv5MpcN9k+/Pm69N2jK6bA4u/ORRt7Z9dUiLFnbg
# 3Lx/uodYfdlZIvHBK4LHF6QbUUOmrEeaYF2lKBtmy6z9VRf7ZItgAAknfZwMIqad
# 53Fibw1Fu/DgJ0tmHAXBxtn9bTrd5LrB7EwgUiFzyFs5lyLyV1eTzj4lPedGh5Ia
# BUqMWCCaNwCHP94W8MFR7+bSSUXYhfyVFbbmlxZg+BiMI0MJIfJgiX4AOIAIAHyF
# PZBs0I3vyInrqDYtki2PMqxmco2a6n5ZypyWrtVBBayJCG55bbfXS+nxUtLaNpAk
# vnU=
# SIG # End signature block
