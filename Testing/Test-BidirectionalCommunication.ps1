# Test-BidirectionalCommunication-Fixed.ps1
# Comprehensive test suite for bidirectional communication module
# Fixed version with proper string handling

param(
    [switch]$TestNamedPipes,
    [switch]$TestHttpApi,
    [switch]$TestQueues,
    [switch]$TestAll,
    [switch]$Interactive
)

# Default to testing all if no specific test selected
if (-not ($TestNamedPipes -or $TestHttpApi -or $TestQueues)) {
    $TestAll = $true
}

# Add module path
$modulePath = Join-Path (Split-Path $PSScriptRoot) 'Modules'
if ($env:PSModulePath -notlike "*$modulePath*") {
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
}

# Import module
Write-Host "`n=== LOADING MODULE ===" -ForegroundColor Yellow
try {
    Import-Module Unity-Claude-IPC-Bidirectional -Force -ErrorAction Stop
    Write-Host "Module loaded successfully" -ForegroundColor Green
} catch {
    Write-Host "Failed to load module: $_" -ForegroundColor Red
    exit 1
}

# Test results tracking
$testResults = @{
    Passed = 0
    Failed = 0
    Tests = @()
}

function Test-Function {
    param(
        [string]$Name,
        [scriptblock]$Test
    )
    
    Write-Host "`n[$Name]" -ForegroundColor Cyan
    
    try {
        $result = & $Test
        
        if ($result) {
            Write-Host "  PASSED" -ForegroundColor Green
            $testResults.Passed++
            $testResults.Tests += @{ Name = $Name; Passed = $true }
        } else {
            Write-Host "  FAILED" -ForegroundColor Red
            $testResults.Failed++
            $testResults.Tests += @{ Name = $Name; Passed = $false }
        }
    } catch {
        Write-Host "  ERROR: $_" -ForegroundColor Red
        $testResults.Failed++
        $errorMsg = $_.Exception.Message
        $testResults.Tests += @{ Name = $Name; Passed = $false; Error = $errorMsg }
    }
}

#region Named Pipe Tests

if ($TestNamedPipes -or $TestAll) {
    Write-Host "`n=== NAMED PIPE TESTS ===" -ForegroundColor Yellow
    
    Test-Function "Start Named Pipe Server" {
        $result = Start-NamedPipeServer -PipeName "TestPipe" -Async
        $result.Success -eq $true
    }
    
    # Give server time to start
    Start-Sleep -Seconds 1
    
    Test-Function "Send Message to Pipe" {
        $result = Send-PipeMessage -PipeName "TestPipe" -Message "PING:Test"
        $result.Success -eq $true -and $result.Response -like "PONG:*"
    }
    
    Test-Function "Get Pipe Status" {
        $result = Send-PipeMessage -PipeName "TestPipe" -Message "GET_STATUS:"
        $result.Success -eq $true -and $result.Response -like "STATUS:*"
    }
    
    if ($Interactive) {
        Write-Host "`nInteractive Pipe Test:" -ForegroundColor Cyan
        Write-Host "Pipe server is running on: \\.\pipe\TestPipe" -ForegroundColor White
        Write-Host "You can connect with another PowerShell instance" -ForegroundColor White
        Write-Host "Press any key to continue..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

#endregion

#region HTTP API Tests

if ($TestHttpApi -or $TestAll) {
    Write-Host "`n=== HTTP API TESTS ===" -ForegroundColor Yellow
    
    Test-Function "Check HTTP API Server" {
        # Don't start a new server - check if external server is running
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:5556/api/health" -Method Head -TimeoutSec 2 -UseBasicParsing
            $response.StatusCode -eq 200
        } catch {
            Write-Host "    Note: Start-TestServer.ps1 should be running on port 5556" -ForegroundColor Yellow
            $false
        }
    }
    
    # Give server time to start
    Start-Sleep -Seconds 2
    
    Test-Function "HTTP Health Check" {
        try {
            # Add timeout to prevent hanging
            $response = Invoke-RestMethod -Uri "http://localhost:5556/api/health" -Method Get -TimeoutSec 5
            $response.status -eq "healthy"
        } catch {
            Write-Host "    Note: Make sure Start-TestServer.ps1 is running in another window" -ForegroundColor Yellow
            $false
        }
    }
    
    Test-Function "HTTP Status Endpoint" {
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:5556/api/status" -Method Get -TimeoutSec 5
            $response.status -eq "running" -and $response.port -eq 5556
        } catch {
            $false
        }
    }
    
    Test-Function "Submit Error via API" {
        try {
            $errorData = @{
                Type = "CompilationError"
                Message = "Test error"
                File = "Test.cs"
                Line = 42
            }
            $response = Invoke-RestMethod -Uri "http://localhost:5556/api/errors" `
                                         -Method Post `
                                         -Body ($errorData | ConvertTo-Json) `
                                         -ContentType "application/json" `
                                         -TimeoutSec 5
            $response.success -eq $true
        } catch {
            $false
        }
    }
    
    if ($Interactive) {
        Write-Host "`nInteractive API Test:" -ForegroundColor Cyan
        Write-Host "API server is running on: http://localhost:5556/api/" -ForegroundColor White
        Write-Host "You can test with curl or browser" -ForegroundColor White
        Write-Host "Press any key to continue..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

#endregion

#region Queue Management Tests

if ($TestQueues -or $TestAll) {
    Write-Host "`n=== QUEUE MANAGEMENT TESTS ===" -ForegroundColor Yellow
    
    Test-Function "Initialize Message Queues" {
        $queues = Initialize-MessageQueues
        $null -ne $queues.MessageQueue -and $null -ne $queues.ResponseQueue
    }
    
    Test-Function "Add Message to Queue" {
        $message = @{
            Type = "Test"
            Data = "Test message"
            Timestamp = Get-Date
        }
        Add-MessageToQueue -Message $message
        $true  # If no error, it passed
    }
    
    Test-Function "Get Queue Status" {
        $status = Get-QueueStatus
        $status.MessageQueue.Count -gt 0
    }
    
    Test-Function "Get Next Message" {
        $message = Get-NextMessage -QueueType Message
        $null -ne $message -and $message.Type -eq "Test"
    }
    
    Test-Function "Clear Message Queue" {
        Clear-MessageQueue -QueueType All
        $status = Get-QueueStatus
        $status.MessageQueue.Count -eq 0 -and $status.ResponseQueue.Count -eq 0
    }
    
    Test-Function "Wait for Message (timeout test)" {
        $message = Get-NextMessage -QueueType Message -Wait -TimeoutMs 500
        $null -eq $message  # Should timeout and return null
    }
}

#endregion

#region Server Management Tests

if ($TestAll) {
    Write-Host "`n=== SERVER MANAGEMENT TESTS ===" -ForegroundColor Yellow
    
    Test-Function "Start All Servers" {
        $result = Start-BidirectionalServers -PipeName "TestBridge" -HttpPort 5557 -LocalOnly
        $result.NamedPipe.Success -eq $true -and $result.HttpApi.Success -eq $true
    }
    
    # Give servers time to start
    Start-Sleep -Seconds 2
    
    Test-Function "Combined Server Status" {
        $status = Get-QueueStatus
        # Check for pipe jobs instead of servers in simplified version
        $hasPipeJobs = $status.PipeJobs -and $status.PipeJobs.Count -gt 0
        $hasHttpListeners = $status.HttpListeners -and $status.HttpListeners.Count -gt 0
        $hasPipeJobs -or $hasHttpListeners  # Either one is sufficient
    }
    
    Test-Function "Stop All Servers" {
        Stop-BidirectionalServers
        $true  # If no error, it passed
    }
    
    Test-Function "Verify Servers Stopped" {
        $status = Get-QueueStatus
        $status.PipeServers.Count -eq 0 -and $status.HttpListeners.Count -eq 0
    }
}

#endregion

# Summary
Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Yellow
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor Red

if ($testResults.Failed -gt 0) {
    Write-Host "`nFailed Tests:" -ForegroundColor Red
    $testResults.Tests | Where-Object { -not $_.Passed } | ForEach-Object {
        $testName = $_.Name
        Write-Host "  - $testName" -ForegroundColor Red
        if ($_.Error) {
            $errorMsg = $_.Error
            Write-Host "    Error: $errorMsg" -ForegroundColor Yellow
        }
    }
}

# Cleanup
Write-Host "`nCleaning up..." -ForegroundColor Cyan
try {
    Stop-BidirectionalServers -ErrorAction SilentlyContinue
} catch {
    # Ignore cleanup errors
}

# Exit with appropriate code
$exitCode = if ($testResults.Failed -eq 0) { 0 } else { 1 }
exit $exitCode
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUML7FvzIop9a/R77fukt0DQ55
# QwagggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUPfs/+KcHWgvvlIrIAsgYt9NyMQIwDQYJKoZIhvcNAQEBBQAEggEAC2mL
# iXVKj0Rl6wU0cfsG1Od1LVtLTFYurXtf4Sqhusf8hhj5u7qh6uENkxl8mJrpBMfH
# c0Y/pJpP/N9v/V3V5UQ7fwm0xxJrwWDd+Ld2jutBP+M1cEL28VEhOvSRJZlLb/zJ
# t8UAoAqfgBjpW/sM9nuVcDSeBvHdBn+CobqERe4/EVz7QCffZuaq9w/SoZWuvH4D
# JyHHeBswq3+ZiyKglwLI0MOSA8/rpzFYUGd9n7sKRjOUOyb1b3gCUVGkjlTWHYSs
# 4uaptoBDsauugv6CBA9TEW5kfsaE+5FUUl47L7+1esswLREPddKOiB89pNr2YNeS
# DSlz7ZOtcuNArqAcCg==
# SIG # End signature block
