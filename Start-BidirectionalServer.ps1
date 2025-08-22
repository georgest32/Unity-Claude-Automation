# Start-BidirectionalServer.ps1
# Starts the bidirectional communication server for Unity-Claude automation
# Run this in an elevated (admin) PowerShell window


# PowerShell 7 Self-Elevation

param(
    [int]$Port = 5560,
    [string]$PipeName = "Unity-Claude-Bridge"
)

if ($PSVersionTable.PSVersion.Major -lt 7) {
    $pwsh7 = "C:\Program Files\PowerShell\7\pwsh.exe"
    if (Test-Path $pwsh7) {
        Write-Host "Upgrading to PowerShell 7..." -ForegroundColor Yellow
        $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $MyInvocation.MyCommand.Path) + $args
        Start-Process -FilePath $pwsh7 -ArgumentList $arguments -NoNewWindow -Wait
        exit
    } else {
        Write-Warning "PowerShell 7 not found. Running in PowerShell $($PSVersionTable.PSVersion)"
    }
}

[CmdletBinding()]
$ErrorActionPreference = 'Stop'

# Import required modules
$modulePath = Join-Path $PSScriptRoot "Modules"
Import-Module (Join-Path $modulePath "Unity-Claude-IPC-Bidirectional\Unity-Claude-IPC-Bidirectional.psm1") -Force

Write-Host "=== Unity-Claude Bidirectional Communication Server ===" -ForegroundColor Cyan
Write-Host "Starting server on port $Port..." -ForegroundColor Green
Write-Host ""

# Start HTTP server for bidirectional communication
try {
    # Simple HTTP server that handles commands
    $listener = [System.Net.HttpListener]::new()
    $listener.Prefixes.Add("http://localhost:$Port/")
    $listener.Start()
    
    Write-Host "Server started successfully on http://localhost:$Port/" -ForegroundColor Green
    Write-Host "Waiting for commands..." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Available endpoints:" -ForegroundColor Cyan
    Write-Host "  POST /command - Send a command to execute" -ForegroundColor White
    Write-Host "  GET /status   - Check server status" -ForegroundColor White
    Write-Host ""
    Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Gray
    Write-Host ""
    
    while ($listener.IsListening) {
        try {
            $context = $listener.GetContext()
            $request = $context.Request
            $response = $context.Response
            
            $timestamp = Get-Date -Format 'HH:mm:ss'
            Write-Host "[$timestamp] $($request.HttpMethod) $($request.Url.LocalPath)" -ForegroundColor Gray
            
            if ($request.HttpMethod -eq 'POST' -and $request.Url.LocalPath -eq '/command') {
                # Read command from request body
                $reader = [System.IO.StreamReader]::new($request.InputStream)
                $body = $reader.ReadToEnd()
                $reader.Close()
                
                $commandData = $body | ConvertFrom-Json
                $command = $commandData.command
                
                Write-Host "  Received command: $command" -ForegroundColor Yellow
                
                # Handle different commands
                $result = switch ($command) {
                    'trigger-compilation' {
                        Write-Host "  Triggering Unity compilation..." -ForegroundColor Green
                        & "$PSScriptRoot\Invoke-RapidUnityCompile.ps1"
                        @{ status = 'success'; message = 'Compilation triggered' }
                    }
                    'check-errors' {
                        Write-Host "  Checking for errors..." -ForegroundColor Green
                        $errorFile = "C:\UnityProjects\Sound-and-Shoal\Dithering\AutomationLogs\current_errors.json"
                        if (Test-Path $errorFile) {
                            $errors = Get-Content $errorFile -Raw | ConvertFrom-Json
                            @{ status = 'success'; errors = $errors }
                        } else {
                            @{ status = 'success'; errors = @() }
                        }
                    }
                    'switch-window' {
                        Write-Host "  Switching to Unity window..." -ForegroundColor Green
                        & "$PSScriptRoot\Invoke-RapidUnitySwitch-v3.ps1"
                        @{ status = 'success'; message = 'Window switched' }
                    }
                    default {
                        Write-Host "  Unknown command: $command" -ForegroundColor Red
                        @{ status = 'error'; message = "Unknown command: $command" }
                    }
                }
                
                # Send response
                $jsonResponse = $result | ConvertTo-Json -Depth 10
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            elseif ($request.HttpMethod -eq 'GET' -and $request.Url.LocalPath -eq '/status') {
                $status = @{
                    status = 'running'
                    timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                    port = $Port
                }
                $jsonResponse = $status | ConvertTo-Json
                $buffer = [System.Text.Encoding]::UTF8.GetBytes($jsonResponse)
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            else {
                $response.StatusCode = 404
                $buffer = [System.Text.Encoding]::UTF8.GetBytes("Not Found")
                $response.ContentLength64 = $buffer.Length
                $response.OutputStream.Write($buffer, 0, $buffer.Length)
            }
            
            $response.Close()
        }
        catch {
            Write-Host "Error handling request: $_" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "Failed to start server: $_" -ForegroundColor Red
    exit 1
}
finally {
    if ($listener) {
        $listener.Stop()
        $listener.Close()
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU8srsXXce9YNXZsic/trhUrok
# L8OgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU3xWm6JlLcgyZ0pJIzw+UYiuQgqkwDQYJKoZIhvcNAQEBBQAEggEAAq5e
# o9PBnjM10Lwt9PLfhjViIfte4IJm+7CXIya3JSLkHroG1omz5fQyylyMQ7GXVUyr
# VDqvpzYEDA/QbKygJWBaSrvGnkD8PrMER9bZnzqN8PrNE+PP5fBVRSqML/D3lEi+
# n4aA2Plk3uyguJwgF/S6zXNAqR0vJOlDaeZNKBNBjrqsc8YxsebHlkl2yFaNlOwR
# L1ff6vl9RBNH6EqTMd+yEYJjHIyUiZAAK7JwtYJc2APXhq1ET3LZJjM6GwTjt0Cq
# vn30UcYkG4lgIo2hJpBJMxYdac6LEbnflNkfxRhmjxHyTOgo5wpVrlGUGTVGHfRx
# Opm5T1U6iz+t8Urmdw==
# SIG # End signature block


