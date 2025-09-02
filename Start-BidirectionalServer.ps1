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
# MIIFzgYJKoZIhvcNAQcCoIIFvzCCBbsCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCAsO/MCSqeTaQci
# NMqIHCif5pK/m260+aGQRH3p2xkZF6CCAzAwggMsMIICFKADAgECAhB1HRbZIqgr
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
# MAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEILWEtaW3aFP8eqBMQ8vAHG6z
# XvIk+SyxnNe2F5/fEPZbMA0GCSqGSIb3DQEBAQUABIIBAIerT0twyRK1y1JUftK1
# +JJKA1SuLcPQ1D0xGdF00+FZwB5oUVUr+9/76t8+YKf5effdc32xxx+NT0WkiDJv
# bjXkbTLruwUz0H5aCsG7+x4qCNgbOne2v7vBZquTXgqjcOIvO82ivnXNSS7lnPdY
# jmrS7GDHKBlyeWjy9uYfZSNylS7C3tz+XDwPBmoUgX8S7dEVdiLxpFro61MnmHAC
# sdlFi7l56YjMnFF/tx503CAMpe5H5+01uMpGfM3MH/Yj+U3eslpp5WsQQ0Ot9aEG
# EvxN6859Ts2Qag0FLepqdCNRoushZ6FDZ09w09FYsTsqDK4tQGjbbPC7Cg8pcFfL
# mUg=
# SIG # End signature block
