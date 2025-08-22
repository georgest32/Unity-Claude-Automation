# Start-SimpleHttpServer.ps1
# Standalone HTTP server for testing

param(
    [int]$Port = 5558
)

Write-Host "Starting Simple HTTP Server on port $Port" -ForegroundColor Cyan

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:$Port/")

try {
    $listener.Start()
    Write-Host "Server started. Press Ctrl+C to stop." -ForegroundColor Green
    Write-Host "Test with: Invoke-WebRequest http://localhost:$Port/api/health" -ForegroundColor Yellow
    
    while ($listener.IsListening) {
        # Use BeginGetContext for async operation with timeout
        $contextAsyncResult = $listener.BeginGetContext($null, $null)
        
        # Wait for request with timeout
        if ($contextAsyncResult.AsyncWaitHandle.WaitOne(1000)) {
            $context = $listener.EndGetContext($contextAsyncResult)
            
            $request = $context.Request
            $response = $context.Response
            
            Write-Host "Request: $($request.HttpMethod) $($request.Url.AbsolutePath)" -ForegroundColor Cyan
            
            # Simple routing
            $result = switch ($request.Url.AbsolutePath) {
                "/api/health" {
                    @{ status = "healthy"; timestamp = Get-Date -Format 'o' }
                }
                "/api/status" {
                    @{ status = "running"; port = $Port }
                }
                default {
                    $response.StatusCode = 404
                    @{ error = "Not found" }
                }
            }
            
            # Send response
            $json = $result | ConvertTo-Json -Compress
            $buffer = [System.Text.Encoding]::UTF8.GetBytes($json)
            
            $response.ContentType = "application/json"
            $response.ContentLength64 = $buffer.Length
            $response.OutputStream.Write($buffer, 0, $buffer.Length)
            $response.Close()
            
            Write-Host "Response sent: $json" -ForegroundColor Green
        }
    }
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
} finally {
    $listener.Stop()
    $listener.Close()
    Write-Host "Server stopped" -ForegroundColor Yellow
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUfTAfmZ3V//NuWrDLB9eN/6Nd
# R2ugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUQWiPh+8G0rquG6+bPlBSeqfsbOowDQYJKoZIhvcNAQEBBQAEggEAdQ8H
# mnew8zr3G4S2bCciHcxqKeZ7PIeMkqgFejE8a/EHlGm5X3ZVdZOgF3sCvnB2B4Gv
# LO3vqPwNZpfjV2nNl16XgUSMWv1jRLqu8js9wuqdypLhO8xt8CdEfScj0Qvw01IM
# YBoK4Kb3wy/6+edOBRYsrvDAHVpZeaonyiyeH4tl3mw6c4STsN/RWV7GexnXdgWF
# 3IY7csjneNAS6nImDWoLxtl1xxWl2RAB1BZzet0VvmINF+lMZiGVc76fneTiTJvy
# QwS/PTCdd1zlVLQz3wgqR8iJs13kOX8T1PfDzu/2dV39lAJa/BmYtYZx/uNDnlyC
# NzA1sqpvbmJmfnCSDQ==
# SIG # End signature block
