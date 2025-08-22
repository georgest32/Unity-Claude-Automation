# Start-SimpleServer.ps1
# Very simple synchronous HTTP server for testing

param(
    [int]$Port = 5560  # New port to avoid any conflicts
)

Write-Host "Starting Simple HTTP Server on port $Port" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")

try {
    $listener.Start()
    Write-Host "Server started on http://localhost:$Port/" -ForegroundColor Green
    Write-Host "Test with: curl http://localhost:$Port/api/health" -ForegroundColor Gray
    
    $requestCount = 0
    
    while ($listener.IsListening) {
        # Blocking call - waits for request
        $context = $listener.GetContext()
        
        $request = $context.Request
        $response = $context.Response
        
        $requestCount++
        Write-Host "[$requestCount] $($request.HttpMethod) $($request.Url.AbsolutePath)" -ForegroundColor Cyan
        
        # Simple routing
        $json = switch ($request.Url.AbsolutePath) {
            "/api/health" {
                '{"status":"healthy","port":' + $Port + '}'
            }
            "/api/status" {
                '{"status":"running","port":' + $Port + ',"requests":' + $requestCount + '}'
            }
            "/api/errors" {
                if ($request.HttpMethod -eq "POST") {
                    '{"success":true,"message":"Error received"}'
                } else {
                    '{"queue_length":0,"errors":[]}'
                }
            }
            default {
                $response.StatusCode = 404
                '{"error":"Not found"}'
            }
        }
        
        # Send response
        $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
        $response.ContentType = "application/json"
        
        # HEAD requests should not have a body
        if ($request.HttpMethod -eq "HEAD") {
            $response.ContentLength64 = $buffer.Length
            # Don't write body for HEAD requests
        } else {
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
        }
        
        $response.Close()
        
        Write-Host "  Sent: $json" -ForegroundColor Green
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
} finally {
    $listener.Stop()
    Write-Host "Server stopped" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUUkCrJVKg0/q6BAePRDYs9E3F
# MDygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUgoBKcHgHigVhFGlUggiPwW8RqDYwDQYJKoZIhvcNAQEBBQAEggEAibgB
# bfxUUhsuHuH2qJHVoECRAirKosMAEHTATyjwhq2r9HtmUGBaeeti8FxdPT48Cja7
# DSfe1oDW6wcKC50litGJImIhBMG+edREeBB1lJRm4EErF3MxYr4F6o1yw5uOAn1D
# MHYf1/sc48mj2G5L/h/6aWB+dxKeUn3YVltSh+QoRmqs2DBrZo3B/Mu4N/RNH26D
# 1yznWHc8FQD8q3SCLhWCnDx9s6tL7AcQJ8vuDP4r2fQoYtZPKN3XXSW/R49dLVvq
# PFQ+IbWEnhiUKyIXLHXsVtKXEhMc/URqt4hIxD8axmRaOaZvwyrIoOoWFTURI9o+
# 1y06wOCQ4x+TNYa1tA==
# SIG # End signature block
