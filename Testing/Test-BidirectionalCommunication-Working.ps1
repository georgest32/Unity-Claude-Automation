# Test-BidirectionalCommunication-Working.ps1
# Working test suite using simple synchronous server on port 5560

param(
    [switch]$TestNamedPipes,
    [switch]$TestHttpApi,
    [switch]$TestQueues,
    [switch]$TestAll,
    [int]$HttpPort = 5560  # Port for simple server
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
        $result = Start-NamedPipeServer -PipeName "TestPipeWorking" -Async
        $result.Success -eq $true
    }
    
    # Give server time to start
    Start-Sleep -Seconds 1
    
    Test-Function "Send Message to Pipe" {
        $result = Send-PipeMessage -PipeName "TestPipeWorking" -Message "PING:Test"
        $result.Success -eq $true -and $result.Response -like "PONG:*"
    }
    
    Test-Function "Get Pipe Status (Simple Format)" {
        $result = Send-PipeMessage -PipeName "TestPipeWorking" -Message "GET_STATUS:"
        # Accept simple "STATUS:OK" format
        $result.Success -eq $true -and ($result.Response -like "STATUS:*" -or $result.Response -eq "STATUS:OK")
    }
}

#endregion

#region HTTP API Tests

if ($TestHttpApi -or $TestAll) {
    Write-Host "`n=== HTTP API TESTS (Simple Server Port $HttpPort) ===" -ForegroundColor Yellow
    Write-Host "Note: Start-SimpleServer.ps1 should be running on port $HttpPort" -ForegroundColor Yellow
    
    Test-Function "Check HTTP Server" {
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:$HttpPort/api/health" -Method Head -TimeoutSec 2 -UseBasicParsing
            $response.StatusCode -eq 200
        } catch {
            Write-Host "    Start-SimpleServer.ps1 should be running on port $HttpPort" -ForegroundColor Yellow
            $false
        }
    }
    
    Test-Function "HTTP Health Check" {
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:$HttpPort/api/health" -Method Get -TimeoutSec 3
            $response.status -eq "healthy" -and $response.port -eq $HttpPort
        } catch {
            $false
        }
    }
    
    Test-Function "HTTP Status Endpoint" {
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:$HttpPort/api/status" -Method Get -TimeoutSec 3
            $response.status -eq "running" -and $response.port -eq $HttpPort
        } catch {
            $false
        }
    }
    
    Test-Function "Submit Error via API" {
        try {
            $errorData = @{
                Type = "CompilationError"
                Message = "Test error from bidirectional test"
                File = "Test.cs"
                Line = 42
            }
            $response = Invoke-RestMethod -Uri "http://localhost:$HttpPort/api/errors" `
                                         -Method Post `
                                         -Body ($errorData | ConvertTo-Json) `
                                         -ContentType "application/json" `
                                         -TimeoutSec 3
            $response.success -eq $true
        } catch {
            $false
        }
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

# Summary
Write-Host "`n=== TEST SUMMARY ===" -ForegroundColor Yellow
Write-Host "Passed: $($testResults.Passed)" -ForegroundColor Green
Write-Host "Failed: $($testResults.Failed)" -ForegroundColor $(if ($testResults.Failed -gt 0) { "Red" } else { "Green" })

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

Write-Host "`n=== IMPORTANT ===" -ForegroundColor Cyan
Write-Host "This test uses the SIMPLE synchronous server on port $HttpPort" -ForegroundColor Yellow
Write-Host "Run Start-SimpleServer.ps1 in another window first!" -ForegroundColor Yellow
Write-Host "The simple server is more reliable than async versions." -ForegroundColor Green

# Cleanup
Write-Host "`nCleaning up..." -ForegroundColor Cyan
try {
    # Clean up pipe jobs
    Get-Job | Where-Object { $_.State -eq 'Running' } | Stop-Job -ErrorAction SilentlyContinue
    Get-Job | Remove-Job -ErrorAction SilentlyContinue
} catch {
    # Ignore cleanup errors
}

# Exit with appropriate code
$exitCode = if ($testResults.Failed -eq 0) { 0 } else { 1 }
Write-Host "`nTest completed with exit code: $exitCode" -ForegroundColor $(if ($exitCode -eq 0) { "Green" } else { "Red" })
exit $exitCode
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUVPk+y4kxI3mfAoj994Ij2uDB
# NHugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUxkuqSurygysAj46pn2KCeBR9V14wDQYJKoZIhvcNAQEBBQAEggEATsbc
# LedeOXT79T07aSaPm1NQPlarjjm7rEqRHEFJxSw97rx8rRDlpVlgboGDbmaPoRaX
# Md2cCQRDIZpzdjCxpdmoyADTDnMny5YqiP7us28oci1bxcIQMA6SawNHJN7b0T5s
# Y63NuNTJyvUQGSE+uR5wJ02iLUYA8GQjv1iNOeZtrITXw/OAm80vlvhwfJTn9rcq
# 59iXJ06VMg2vuZ9SGpB7Tw4Vd+J2bwT21TkJ49YGkx0pu/Gxyz1Gpq2PBk8d6Xig
# if5xiaU9hi5DpbesqnhKsU6HPgDCQs/NjzkiVX2BKrHiIDTtexXQGoAlcjt4wjZC
# dfMFifhxLyehH9atlw==
# SIG # End signature block
