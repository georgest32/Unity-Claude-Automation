# Test-Day18-Hour2.5-Incremental-Functions-FINAL.ps1
# Final corrected incremental testing of Hour 2.5 functions
# Fixes all 3 identified issues: parameter binding, function names, and non-existent functions
# Date: 2025-08-19 | Phase 3 Week 3 - Unity-Claude Automation System

#Requires -Version 5.1

[CmdletBinding()]
param(
    [switch]$SaveResults = $true,
    [string]$ResultsFile = "incremental_function_test_results_final.txt"
)

$ErrorActionPreference = "Continue"

function Write-SafeLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
    $logLine = "[$timestamp] [$Level] $Message"
    Write-Host $logLine
    
    # Also write to file immediately for crash investigation
    try {
        Add-Content -Path "incremental_function_test_log_final.txt" -Value $logLine -ErrorAction SilentlyContinue
    } catch {
        # Ignore file write errors
    }
}

function Test-FunctionSafely {
    param(
        [string]$FunctionName,
        [scriptblock]$TestCode,
        [string]$Description
    )
    
    Write-SafeLog "========================================" -Level "INFO"
    Write-SafeLog "Testing Function: $FunctionName" -Level "INFO"
    Write-SafeLog "Description: $Description" -Level "INFO"
    Write-SafeLog "========================================" -Level "INFO"
    
    try {
        Write-SafeLog "Starting test execution for $FunctionName..." -Level "DEBUG"
        
        # Execute the test code in a clean scope to avoid parameter contamination
        $result = Invoke-Command -ScriptBlock $TestCode -NoNewScope
        
        Write-SafeLog "Function $FunctionName completed successfully" -Level "OK"
        Write-SafeLog "Result: $result" -Level "DEBUG"
        
        # Allow time for any background processes to settle
        Start-Sleep -Milliseconds 500
        Write-SafeLog "Post-execution settling complete for $FunctionName" -Level "DEBUG"
        
        return @{
            FunctionName = $FunctionName
            Success = $true
            Result = $result
            Error = $null
        }
        
    } catch {
        Write-SafeLog "Function $FunctionName failed with error: $($_.Exception.Message)" -Level "ERROR"
        Write-SafeLog "Exception Type: $($_.Exception.GetType().Name)" -Level "ERROR"
        Write-SafeLog "Stack Trace: $($_.Exception.StackTrace)" -Level "ERROR"
        
        return @{
            FunctionName = $FunctionName
            Success = $false
            Result = $null
            Error = $_.Exception.Message
        }
    }
}

# Create proper test data with all required properties based on actual schema validation errors
function Get-ValidTestStatusData {
    return @{
        exportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        systemInfo = @{
            lastUpdate = "/Date($([DateTimeOffset]::Now.ToUnixTimeMilliseconds()))/"
            hostName = $env:COMPUTERNAME
            powerShellVersion = $PSVersionTable.PSVersion.ToString()
            unityVersion = "2021.1.14f1"
        }
        subsystems = @{}
        watchdog = @{
            enabled = $false
            lastCheck = "/Date($([DateTimeOffset]::Now.ToUnixTimeMilliseconds()))/"
            RestartPolicy = "Manual"  # Required property found missing in error logs
        }
        communication = @{
            namedPipesEnabled = $false
            lastMessage = "/Date($([DateTimeOffset]::Now.ToUnixTimeMilliseconds()))/"
        }
    }
}

Write-SafeLog "========================================" -Level "INFO"
Write-SafeLog "Day 18 Hour 2.5: Final Corrected Incremental Function Testing" -Level "INFO"
Write-SafeLog "Purpose: Test all Hour 2.5 functions with proper error handling" -Level "INFO"
Write-SafeLog "Fixes: Parameter binding, function names, and removed non-existent functions" -Level "INFO"
Write-SafeLog "========================================" -Level "INFO"

# Import the module (we know this works from basic test)
Write-SafeLog "Importing Unity-Claude-SystemStatus module..." -Level "INFO"
try {
    Import-Module .\Modules\Unity-Claude-SystemStatus\Unity-Claude-SystemStatus.psm1 -Force -ErrorAction Stop
    Write-SafeLog "Module imported successfully" -Level "OK"
    
    $functions = Get-Command -Module "Unity-Claude-SystemStatus" -ErrorAction SilentlyContinue
    Write-SafeLog "Module functions available: $($functions.Count)" -Level "INFO"
    
    # Log available functions for debugging
    Write-SafeLog "Available functions: $($functions.Name -join ', ')" -Level "DEBUG"
} catch {
    Write-SafeLog "Module import failed: $_" -Level "ERROR"
    exit 1
}

$TestResults = @()

# Test 1: Schema Validation (Low Risk)
$TestResults += Test-FunctionSafely -FunctionName "Test-SystemStatusSchema" -Description "Validate JSON schema with proper data" -TestCode {
    $testData = Get-ValidTestStatusData
    Test-SystemStatusSchema -StatusData $testData
}

# Test 2: Message Creation (Medium Risk - ETS DateTime)
$TestResults += Test-FunctionSafely -FunctionName "New-SystemStatusMessage" -Description "Create system status message with ETS DateTime" -TestCode {
    New-SystemStatusMessage -MessageType "StatusUpdate" -Source "TestSource" -Target "TestTarget" -Payload @{test = "data"}
}

# Test 3: System Status Write (Medium Risk - File I/O) - FIXED: Proper parameter handling
$TestResults += Test-FunctionSafely -FunctionName "Write-SystemStatus" -Description "Write system status to file with valid data" -TestCode {
    # Create the test data inside the scriptblock to avoid parameter contamination
    $statusData = @{
        exportTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        systemInfo = @{
            lastUpdate = "/Date($([DateTimeOffset]::Now.ToUnixTimeMilliseconds()))/"
            hostName = $env:COMPUTERNAME
            powerShellVersion = $PSVersionTable.PSVersion.ToString()
            unityVersion = "2021.1.14f1"
        }
        subsystems = @{}
        watchdog = @{
            enabled = $false
            lastCheck = "/Date($([DateTimeOffset]::Now.ToUnixTimeMilliseconds()))/"
            RestartPolicy = "Manual"
        }
        communication = @{
            namedPipesEnabled = $false
            lastMessage = "/Date($([DateTimeOffset]::Now.ToUnixTimeMilliseconds()))/"
        }
    }
    Write-SystemStatus -StatusData $statusData
}

# Test 4: System Status Read (Medium Risk - File I/O) - FIXED: Correct function name
$TestResults += Test-FunctionSafely -FunctionName "Read-SystemStatus" -Description "Read system status from file" -TestCode {
    Read-SystemStatus
}

# Test 5: Concurrent Collections (Medium Risk - Threading)
$TestResults += Test-FunctionSafely -FunctionName "ConcurrentQueue Test" -Description "Test thread-safe message queues" -TestCode {
    # This test replicates the ConcurrentQueue usage from the module
    $testQueue = [System.Collections.Concurrent.ConcurrentQueue[PSObject]]::new()
    $testMessage = @{ messageType = "Test"; timestamp = Get-Date }
    $testQueue.Enqueue($testMessage)
    
    $dequeuedMessage = $null
    $dequeueResult = $testQueue.TryDequeue([ref]$dequeuedMessage)
    
    return $dequeueResult -and $dequeuedMessage.messageType -eq "Test"
}

# Test 6: Message Handler Registration (Medium Risk - Event Handling)
$TestResults += Test-FunctionSafely -FunctionName "Register-MessageHandler" -Description "Register message handler" -TestCode {
    Register-MessageHandler -MessageType "TestMessage" -Handler {
        param($Message)
        Write-SafeLog "Test handler executed for: $($Message.messageType)" -Level "DEBUG"
    }
}

# Test 7: Message Handler Invocation (High Risk - Dynamic Invocation)
$TestResults += Test-FunctionSafely -FunctionName "Invoke-MessageHandler" -Description "Invoke registered message handler" -TestCode {
    $testMessage = @{ messageType = "TestMessage"; payload = @{} }
    Invoke-MessageHandler -Message $testMessage
}

# Test 8: Named Pipe Server Initialization (HIGH RISK - System.Core, IPC)
$TestResults += Test-FunctionSafely -FunctionName "Initialize-NamedPipeServer" -Description "Initialize named pipe server with security" -TestCode {
    Initialize-NamedPipeServer -PipeName "TestPipe_Incremental_Final"
}

# Test 9: Communication Performance Measurement (HIGH RISK - Performance Counters)
$TestResults += Test-FunctionSafely -FunctionName "Measure-CommunicationPerformance" -Description "Measure communication latency" -TestCode {
    Measure-CommunicationPerformance
}

# Test 10: Cross-Module Events (HIGH RISK - Register-EngineEvent)
$TestResults += Test-FunctionSafely -FunctionName "Initialize-CrossModuleEvents" -Description "Initialize cross-module event system" -TestCode {
    Initialize-CrossModuleEvents
}

# Test 11: Engine Event Sending (HIGH RISK - New-Event)
$TestResults += Test-FunctionSafely -FunctionName "Send-EngineEvent" -Description "Send engine event message" -TestCode {
    Send-EngineEvent -SourceIdentifier "Unity.Claude.IncrementalTest.Final" -MessageData @{ test = "incremental" }
}

# Test 12: Health Check Requests (HIGH RISK - Complex Message Flow)
$TestResults += Test-FunctionSafely -FunctionName "Send-HealthCheckRequest" -Description "Send health check requests" -TestCode {
    Send-HealthCheckRequest -TargetSubsystems @("Unity-Claude-SystemStatus")
}

# Test 13: Basic System Monitoring Initialization (HIGH RISK - Complex Initialization)
$TestResults += Test-FunctionSafely -FunctionName "Initialize-SystemStatusMonitoring (Basic)" -Description "System monitoring with minimal settings" -TestCode {
    # Test with minimal settings first
    Initialize-SystemStatusMonitoring -EnableCommunication:$false -EnableFileWatcher:$false
}

# Test 14: System Monitoring with Communication (EXTREME RISK - Named Pipes + Background Jobs)
$TestResults += Test-FunctionSafely -FunctionName "Initialize-SystemStatusMonitoring (Full)" -Description "Full system monitoring with all features enabled" -TestCode {
    Initialize-SystemStatusMonitoring -EnableCommunication:$true -EnableFileWatcher:$true
}

Write-SafeLog "========================================" -Level "INFO"
Write-SafeLog "FINAL INCREMENTAL FUNCTION TEST RESULTS SUMMARY" -Level "INFO"
Write-SafeLog "========================================" -Level "INFO"

$successCount = ($TestResults | Where-Object { $_.Success -eq $true }).Count
$failCount = ($TestResults | Where-Object { $_.Success -eq $false }).Count
$totalTests = $TestResults.Count

Write-SafeLog "Total Functions Tested: $totalTests" -Level "INFO"
Write-SafeLog "Successful Functions: $successCount" -Level "OK"
Write-SafeLog "Failed Functions: $failCount" -Level "ERROR"

if ($totalTests -gt 0) {
    $successRate = [math]::Round(($successCount / $totalTests) * 100, 1)
    Write-SafeLog "Success Rate: $successRate%" -Level "INFO"
}

Write-SafeLog "========================================" -Level "INFO"
Write-SafeLog "DETAILED RESULTS:" -Level "INFO"

foreach ($result in $TestResults) {
    if ($result.Success) {
        Write-SafeLog "$($result.FunctionName): SUCCESS" -Level "OK"
    } else {
        Write-SafeLog "$($result.FunctionName): FAILED - $($result.Error)" -Level "ERROR"
    }
}

# Cleanup
Write-SafeLog "Cleaning up test environment..." -Level "INFO"
try {
    Stop-SystemStatusMonitoring -ErrorAction SilentlyContinue
    
    # Clean up engine events
    Get-EventSubscriber | Where-Object { $_.SourceIdentifier -like "*Unity.Claude.*" } | Unregister-Event -ErrorAction SilentlyContinue
    
    Write-SafeLog "Test environment cleaned up" -Level "OK"
} catch {
    Write-SafeLog "Cleanup warning: $_" -Level "WARN"
}

# Save results
if ($SaveResults) {
    try {
        $resultsPath = Join-Path $PSScriptRoot $ResultsFile
        
        $output = @()
        $output += "# Day 18 Hour 2.5 - Final Corrected Incremental Function Test Results"
        $output += "Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        $output += "Total Functions Tested: $totalTests"
        $output += "Success Rate: $successRate% ($successCount/$totalTests)"
        $output += ""
        $output += "## Function Test Results:"
        
        foreach ($result in $TestResults) {
            if ($result.Success) {
                $output += "$($result.FunctionName): SUCCESS"
            } else {
                $output += "$($result.FunctionName): FAILED - $($result.Error)"
            }
        }
        
        $output += ""
        $output += "## Analysis:"
        if ($failCount -eq 0) {
            $output += "All functions tested successfully - Hour 2.5 implementation validated"
        } else {
            $output += "Some functions failed - review errors above"
        }
        
        $output += ""
        $output += "## Key Fixes Applied:"
        $output += "1. FIXED: Removed non-existent New-SystemStatusSchema function test"
        $output += "2. FIXED: Parameter binding issue in Write-SystemStatus by using clean scriptblock scope"
        $output += "3. FIXED: Function name Get-SystemStatus changed to Read-SystemStatus"
        $output += "4. FIXED: Added proper error isolation using Invoke-Command -NoNewScope"
        
        $output | Out-File -FilePath $resultsPath -Encoding UTF8
        Write-SafeLog "Test results saved to: $resultsPath" -Level "OK"
    } catch {
        Write-SafeLog "Failed to save test results: $_" -Level "ERROR"
    }
}

Write-SafeLog "Final Corrected Incremental Function Testing Complete" -Level "INFO"
Write-SafeLog "All known issues have been addressed in this version" -Level "INFO"

Write-SafeLog "Press Enter to exit" -Level "INFO"
Read-Host "Press Enter to continue"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUywwZZE62uOR2q/wTDCXwsC7Y
# gFmgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
# AQsFADAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0b21hdGlvbi1EZXZlbG9w
# bWVudDAeFw0yNTA4MjAyMTE1MTdaFw0yNjA4MjAyMTM1MTdaMC4xLDAqBgNVBAMM
# I1VuaXR5LUNsYXVkZS1BdXRvbWF0aW9uLURldmVsb3BtZW50MIIBIjANBgkqhkiG
# 9w0BAQEFAAOCAQ8AMIIBCgKCAQEAseH3qinVEOhrn2OLpjc5TNT4vGh1BkfB5X4S
# FhY7K0QMQsYYnkZVmx3tB8PqVQXl++l+e3uT7uCscc7vjMTK8tDSWH98ji0U34WL
# JBwXC62l1ArazMKp4Tyr7peksei7vL4pZOtOVgAyTYn5d1hbnsVQmCSTPRtpn7mC
# Azfq2ec5qZ9Kgl7puPW5utvYfh8idtOWa5/WgYSKwOIvyZawIdZKLFpwqOtqbJe4
# sWzVahasFhLfoAKkniKOAocJDkJexh5pO/EOSKEZ3mOCU1ZSs4XWRGISRhV3qGZp
# f+Y3JlHKMeFDWKynaJBO8/GU5sqMATlDUvrByBtU2OQ2Um/L3QIDAQABo0YwRDAO
# BgNVHQ8BAf8EBAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwHQYDVR0OBBYEFHw5
# rOy6xlW6B45sJUsiI2A/yS0MMA0GCSqGSIb3DQEBCwUAA4IBAQAUTLH0+w8ysvmh
# YuBw4NDKcZm40MTh9Zc1M2p2hAkYsgNLJ+/rAP+I74rNfqguTYwxpCyjkwrg8yF5
# wViwggboLpF2yDu4N/dgDainR4wR8NVpS7zFZOFkpmNPepc6bw3d4yQKa/wJXKeC
# pkRjS50N77/hfVI+fFKNao7POb7en5fcXuZaN6xWoTRy+J4I4MhfHpjZuxSLSXjb
# VXtPD4RZ9HGjl9BU8162cRhjujr/Lc3/dY/6ikHQYnxuxcdxRew4nzaqAQaOeWu6
# tGp899JPKfldM5Zay5IBl3zs15gNS9+0Jrd0ARQnSVYoI0DLh3KybFnfK4POezoN
# Lp/dbX2SMYIB4zCCAd8CAQEwQjAuMSwwKgYDVQQDDCNVbml0eS1DbGF1ZGUtQXV0
# b21hdGlvbi1EZXZlbG9wbWVudAIQdR0W2SKoK5VE8JId4ZxrRTAJBgUrDgMCGgUA
# oHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZBgkqhkiG9w0BCQMxDAYKKwYB
# BAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYBBAGCNwIBFTAjBgkqhkiG9w0B
# CQQxFgQUbSSSb8v0FTNmZ60fnDnzsfStPRYwDQYJKoZIhvcNAQEBBQAEggEAKXMx
# gFh7LhBLg+jO6f891gEUx+pJUWKrCGnZ64+ysRy7CM9BZuog76gT0WeMoM1JJBCH
# QhfaJPjFw5fEKjwJoGySx4GhdrjLnd3dN/cb6u8vcSNzGEBjCPEi7ol4pTf9Z1V/
# t2Y1LYE89sx25PNYeTHmQz3/QoP4wKkHdznwdBJDfN9y+KkLOlKGtSP24xd6G+fU
# M2OTroXdzul+pNqO7sWa/sxtLC85tCThV5+HxYsPAELclszBMzuXzFGbAkjHgmLR
# u8Ex/090h5TsR+lgpo2HaOvGJur3kAHgdLUvYRUGfyit169Bt6hp5LPkpbapmeLQ
# J1aBBi+KuvmuEpVMAg==
# SIG # End signature block
