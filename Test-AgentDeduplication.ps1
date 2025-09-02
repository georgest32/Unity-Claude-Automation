# Test-AgentDeduplication.ps1
# Test script to verify that only one AutonomousAgent can run at a time
# Date: 2025-08-21

param(
    [switch]$DebugMode
)

$ErrorActionPreference = "Continue"

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "AGENT DEDUPLICATION TEST" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Set working directory
Set-Location "C:\UnityProjects\Sound-and-Shoal\Unity-Claude-Automation"

# Test results tracking
$testResults = @{
    FirstAgentStart = $false
    SecondAgentBlocked = $false
    SystemStatusCheck = $false
    OverallSuccess = $false
}

Write-Host "Test 1: Starting First Agent" -ForegroundColor Yellow
try {
    # Clear any existing system status
    if (Test-Path ".\system_status.json") {
        $backup = Get-Content ".\system_status.json" -Raw
        $backup | Set-Content ".\system_status_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        Remove-Item ".\system_status.json" -Force
        Write-Host "  Cleared existing system status" -ForegroundColor Gray
    }
    
    # Start first agent in background
    $agentArgs = @{
        FilePath = "pwsh.exe"
        ArgumentList = @(
            "-ExecutionPolicy", "Bypass",
            "-File", ".\Start-AutonomousMonitoring-Fixed.ps1",
            "-PollIntervalSeconds", "5"
        )
        WindowStyle = "Hidden"
        PassThru = $true
    }
    
    $firstAgent = Start-Process @agentArgs
    Start-Sleep -Seconds 3  # Give time to initialize
    
    if ($firstAgent -and -not $firstAgent.HasExited) {
        Write-Host "  [PASS] First agent started successfully (PID: $($firstAgent.Id))" -ForegroundColor Green
        $testResults.FirstAgentStart = $true
    } else {
        Write-Host "  [FAIL] First agent failed to start or exited immediately" -ForegroundColor Red
    }
    
} catch {
    Write-Host "  [FAIL] Error starting first agent: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test 2: Checking SystemStatus Registration" -ForegroundColor Yellow
Start-Sleep -Seconds 2  # Give time for registration

try {
    if (Test-Path ".\system_status.json") {
        $systemStatusContent = Get-Content ".\system_status.json" -Raw | ConvertFrom-Json
        if ($systemStatusContent.subsystems -and $systemStatusContent.subsystems.AutonomousAgent) {
            $agentInfo = $systemStatusContent.subsystems.AutonomousAgent
            Write-Host "  [PASS] AutonomousAgent registered in SystemStatus" -ForegroundColor Green
            Write-Host "    Registered PID: $($agentInfo.process_id)" -ForegroundColor Gray
            Write-Host "    Status: $($agentInfo.status)" -ForegroundColor Gray
            $testResults.SystemStatusCheck = $true
        } else {
            Write-Host "  [FAIL] AutonomousAgent not found in SystemStatus" -ForegroundColor Red
        }
    } else {
        Write-Host "  [FAIL] system_status.json not found" -ForegroundColor Red
    }
} catch {
    Write-Host "  [FAIL] Error checking SystemStatus: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "Test 3: Attempting to Start Second Agent (Should Fail)" -ForegroundColor Yellow
try {
    # Try to start second agent - this should abort
    $secondAgentArgs = @{
        FilePath = "pwsh.exe"
        ArgumentList = @(
            "-ExecutionPolicy", "Bypass", 
            "-File", ".\Start-AutonomousMonitoring-Fixed.ps1",
            "-PollIntervalSeconds", "5"
        )
        WindowStyle = "Hidden"
        PassThru = $true
        Wait = $true  # Wait for it to complete (should exit quickly)
    }
    
    $secondAgent = Start-Process @secondAgentArgs
    
    # Check exit code - should be 1 (abort)
    if ($secondAgent.ExitCode -eq 1) {
        Write-Host "  [PASS] Second agent correctly aborted (exit code: 1)" -ForegroundColor Green
        $testResults.SecondAgentBlocked = $true
    } elseif ($secondAgent.ExitCode -eq 0) {
        Write-Host "  [FAIL] Second agent started when it should have aborted" -ForegroundColor Red
    } else {
        Write-Host "  [WARN] Second agent exited with unexpected code: $($secondAgent.ExitCode)" -ForegroundColor Yellow
    }
    
} catch {
    Write-Host "  [FAIL] Error testing second agent: $_" -ForegroundColor Red
}

# Clean up - stop the first agent
Write-Host ""
Write-Host "Cleanup: Stopping test agents..." -ForegroundColor Gray
try {
    if ($firstAgent -and -not $firstAgent.HasExited) {
        $firstAgent.Kill()
        Write-Host "  First agent stopped" -ForegroundColor Gray
    }
    
    # Also kill any other autonomous agents that might be running
    Get-Process | Where-Object { $_.CommandLine -like "*AutonomousMonitoring*" } | ForEach-Object {
        $_.Kill()
        Write-Host "  Stopped agent PID: $($_.Id)" -ForegroundColor Gray
    }
} catch {
    Write-Host "  Warning: Error during cleanup: $_" -ForegroundColor Yellow
}

# Calculate overall result
$testResults.OverallSuccess = $testResults.FirstAgentStart -and $testResults.SystemStatusCheck -and $testResults.SecondAgentBlocked

Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "TEST RESULTS" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan

foreach ($test in $testResults.Keys) {
    if ($test -ne "OverallSuccess") {
        $status = if ($testResults[$test]) { "[PASS]" } else { "[FAIL]" }
        $color = if ($testResults[$test]) { "Green" } else { "Red" }
        Write-Host "$test : $status" -ForegroundColor $color
    }
}

Write-Host ""
if ($testResults.OverallSuccess) {
    Write-Host "OVERALL RESULT: [PASS] Agent deduplication working correctly!" -ForegroundColor Green
    Write-Host "Only one AutonomousAgent can run at a time as expected." -ForegroundColor Green
} else {
    Write-Host "OVERALL RESULT: [FAIL] Agent deduplication not working properly!" -ForegroundColor Red
    Write-Host "Multiple agents may be able to start simultaneously." -ForegroundColor Red
}

Write-Host ""
return $testResults.OverallSuccess
# SIG # Begin signature block
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA5Xcn3pXwOq80u
# zD5C35OUuXYas0y3EqvL3pFf74gDeqCCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEICgf+fzk0L1gLf+G7bCcZmp4
# DtwZ9bxZ/SWrggXOsf8TMA0GCSqGSIb3DQEBAQUABIIBAFeRxLotjUSJL5fEElS2
# eZrRVgB37ZbrhN5a2iA4qgWJ20uJSUaX4nljPLKikKuQN8VGA/dZhMeEft4S1m97
# 8WW08ebZWUBcKq8H+swixyeqUzSKr/N+UWQX6xAQ2Ve7o6L9YcPBfmjBxoTqXTYl
# 3lcDtAjniNMfzkvMWR0ZCFBsW71v3CgRasXR86yCY7HcScSvXizS4MuzTrLUgOwy
# ZwHCnN6gQEetj9fFR2AF+stshv1xLa4jDW3WIALcN1hEDXcgxA09FkfdhHylXUao
# fRHphG29N06V/OPLZORpoycC4i2QTsH49DtqnwVifgOorQnBJ0AXr5umQQy3zCei
# xZA=
# SIG # End signature block
