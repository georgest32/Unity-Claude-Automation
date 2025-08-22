# Start-TestServer-Alt.ps1
# Alternative test server on port 5559 to avoid conflicts

param(
    [int]$HttpPort = 5559,  # Different port to avoid conflicts
    [string]$PipeName = "TestPipe"
)

Write-Host @"
=====================================
Unity-Claude Test Server (Alternative)
=====================================
Using port $HttpPort to avoid conflicts
Keep this window open while running tests.
Press Ctrl+C to stop the server.
=====================================
"@ -ForegroundColor Cyan

# Add module path
$modulePath = Join-Path $PSScriptRoot 'Modules'
if ($env:PSModulePath -notlike "*$modulePath*") {
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
}

# Import module
Write-Host "`nLoading module..." -ForegroundColor Yellow
Import-Module Unity-Claude-IPC-Bidirectional -Force -ErrorAction Stop
Write-Host "Module loaded successfully" -ForegroundColor Green

# Start HTTP server
Write-Host "`nStarting HTTP API Server on port $HttpPort..." -ForegroundColor Yellow
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$HttpPort/")

try {
    $listener.Start()
    Write-Host "HTTP Server started on http://localhost:$HttpPort/" -ForegroundColor Green
    Write-Host "`nEndpoints available:" -ForegroundColor Cyan
    Write-Host "  - http://localhost:$HttpPort/api/health" -ForegroundColor White
    Write-Host "  - http://localhost:$HttpPort/api/status" -ForegroundColor White
    Write-Host "  - http://localhost:$HttpPort/api/errors" -ForegroundColor White
    
    Write-Host "`n[Server is running. Press Ctrl+C to stop]" -ForegroundColor Yellow
    
    # Initialize queues
    $queues = Initialize-MessageQueues
    $messageCount = 0
    
    while ($listener.IsListening) {
        $contextAsyncResult = $listener.BeginGetContext($null, $null)
        
        if ($contextAsyncResult.AsyncWaitHandle.WaitOne(1000)) {
            $context = $listener.EndGetContext($contextAsyncResult)
            
            $request = $context.Request
            $response = $context.Response
            
            $messageCount++
            Write-Host "[$messageCount] $($request.HttpMethod) $($request.Url.AbsolutePath)" -ForegroundColor Cyan
            
            # Route request
            $result = switch -Regex ($request.Url.AbsolutePath) {
                '^/api/health$' {
                    @{ 
                        status = "healthy"
                        timestamp = Get-Date -Format 'o'
                        server = "Unity-Claude-Test-Server-Alt"
                        port = $HttpPort
                    }
                }
                
                '^/api/status$' {
                    @{ 
                        status = "running"
                        port = $HttpPort
                        requests = $messageCount
                    }
                }
                
                '^/api/errors$' {
                    if ($request.HttpMethod -eq 'POST') {
                        @{ 
                            success = $true
                            message = "Error queued for analysis"
                        }
                    } else {
                        @{ 
                            queue_length = 0
                            errors = @()
                        }
                    }
                }
                
                default {
                    $response.StatusCode = 404
                    @{ 
                        error = "Not found"
                        path = $request.Url.AbsolutePath
                    }
                }
            }
            
            # Send response
            $json = $result | ConvertTo-Json -Compress
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
            
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            
            Write-Host "  Response sent" -ForegroundColor Green
        }
    }
} catch {
    if ($_.Exception.Message -notlike "*operation was canceled*") {
        Write-Host "Error: $_" -ForegroundColor Red
    }
} finally {
    Write-Host "`nShutting down server..." -ForegroundColor Yellow
    $listener.Stop()
    $listener.Close()
    Write-Host "Server stopped" -ForegroundColor Green
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJUGJhrswaM79QH53J567m4Lc
# hlWgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU8lvBaBTJHu0vvPnQs5QU2dXFLtIwDQYJKoZIhvcNAQEBBQAEggEAWVYv
# 55Z5737wjTowgfUmWWJTY8KyVZaNS3e8lL5+vb8cUGWTauxUXdD0ffh9kMxSfFh2
# 2wgPVtMQDmFN9ZZbEIicM8Fx2BqsFLCBoeYZnzSrnqT9y/a5ZSQOwM3actSjkdKm
# wG8jZ6ntZjPY5w3MHr4xi98ao/6q7AiSXd9v7XXSw5u8kDoIf8RCNqpDtcZBoukz
# yweisykyaD88jYTRDLzXClvol7pEtPN4hEo+aFlDJhhfeYOUVrRMzfrUNuQ/qUVB
# OJYgiftdVMNg6QflL+AusNAy5FOdwDRX3mg2CMRAumY7n5Sx77DG0HtKr/iM6mF3
# qNy3BQZivbk4s5Je9A==
# SIG # End signature block
