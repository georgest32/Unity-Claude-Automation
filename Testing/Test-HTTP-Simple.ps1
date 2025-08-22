# Test-HTTP-Simple.ps1
# Simple test for HTTP API functionality

# Add module path
$modulePath = Join-Path (Split-Path $PSScriptRoot) 'Modules'
if ($env:PSModulePath -notlike "*$modulePath*") {
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
}

Write-Host "Simple HTTP API Test" -ForegroundColor Cyan

# Import module
Import-Module Unity-Claude-IPC-Bidirectional -Force -ErrorAction Stop

Write-Host "`n1. Starting HTTP API server..." -ForegroundColor Yellow

$result = Start-HttpApiServer -Port 5557 -LocalOnly

if ($result.Success) {
    Write-Host "  Server started: $($result.Prefix)" -ForegroundColor Green
    
    # Give server time to start
    Start-Sleep -Seconds 2
    
    # Check background jobs
    Write-Host "`n2. Checking background jobs..." -ForegroundColor Yellow
    $jobs = Get-Job
    $jobs | ForEach-Object {
        Write-Host "  Job $($_.Id): $($_.State)" -ForegroundColor Cyan
    }
    
    Write-Host "`n3. Testing with curl (if available)..." -ForegroundColor Yellow
    try {
        $curlTest = & curl.exe "http://localhost:5557/api/health" 2>&1
        Write-Host "  Curl response: $curlTest" -ForegroundColor Green
    } catch {
        Write-Host "  Curl not available" -ForegroundColor Gray
    }
    
    Write-Host "`n4. Testing with .NET WebClient..." -ForegroundColor Yellow
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add("Accept", "application/json")
        $response = $webClient.DownloadString("http://localhost:5557/api/health")
        Write-Host "  WebClient response: $response" -ForegroundColor Green
    } catch {
        Write-Host "  WebClient error: $_" -ForegroundColor Red
    } finally {
        if ($webClient) { $webClient.Dispose() }
    }
    
    Write-Host "`n5. Testing with Invoke-WebRequest (with timeout)..." -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5557/api/health" -TimeoutSec 5 -UseBasicParsing
        Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "  Content: $($response.Content)" -ForegroundColor Green
    } catch {
        Write-Host "  Invoke-WebRequest error: $_" -ForegroundColor Red
    }
    
    # Get job output
    Write-Host "`n6. Checking job output..." -ForegroundColor Yellow
    $jobs | ForEach-Object {
        $output = Receive-Job -Id $_.Id -ErrorAction SilentlyContinue
        if ($output) {
            Write-Host "  Job $($_.Id) output:" -ForegroundColor Cyan
            $output | ForEach-Object { Write-Host "    $_" -ForegroundColor Gray }
        }
    }
    
    # Check if listener is actually listening
    Write-Host "`n7. Checking port 5557..." -ForegroundColor Yellow
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect("localhost", 5557)
        if ($tcpClient.Connected) {
            Write-Host "  Port 5557 is open and accepting connections" -ForegroundColor Green
            $tcpClient.Close()
        }
    } catch {
        Write-Host "  Cannot connect to port 5557: $_" -ForegroundColor Red
    }
    
} else {
    Write-Host "  Failed to start server: $($result.Error)" -ForegroundColor Red
}

Write-Host "`n8. Cleaning up..." -ForegroundColor Yellow
Stop-BidirectionalServers -ErrorAction SilentlyContinue
Get-Job | Stop-Job -ErrorAction SilentlyContinue
Get-Job | Remove-Job -ErrorAction SilentlyContinue

Write-Host "Test complete" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUWas2deE0hYSHc9GuRLePzh/S
# wbigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUvQ3zrzF7+JIW9B9ZhWGWTBaUXCUwDQYJKoZIhvcNAQEBBQAEggEAZe45
# ZsTcTHiJQRNLbA0P49l+IBt4wnVYrYYgi9W4OcFlw63QGEhHoLLdxdCnBToEd26L
# U9Nvc+NdW5IC44tfJ7twwXo6ZO0aSDLqHsX5yJZ3LjKntsoNjPJJOQKoXcG4zBx5
# dq3qo+PP4zjZZWLn1YtDEOEctUfxcWO0dSU1lvw9Ro9mYVmgol/ib53IsW2D0ioW
# VeTFCP80X2fdSyLAt5irp252Ab2EUSASC3rClHpPH2fMvxnMZL4ees2KSAv5QUOj
# 7BnOMe2lvLpL4vO0u0KeMEBWWhwz0oKy0J4ttM3gngya/eY5OxdU4D2LKdB3SzKX
# U9EHhcBfWE5yry2ykA==
# SIG # End signature block
