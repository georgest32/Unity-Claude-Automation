# Test-NamedPipe-Simple.ps1
# Simple test for named pipe functionality

# Add module path
$modulePath = Join-Path (Split-Path $PSScriptRoot) 'Modules'
if ($env:PSModulePath -notlike "*$modulePath*") {
    $env:PSModulePath = "$modulePath;$env:PSModulePath"
}

Write-Host "Simple Named Pipe Test" -ForegroundColor Cyan

# Import module
Import-Module Unity-Claude-IPC-Bidirectional -Force -ErrorAction Stop

Write-Host "`n1. Testing synchronous pipe server..." -ForegroundColor Yellow

# Create a simple synchronous pipe server
$pipeName = "TestPipeSimple"

try {
    Write-Host "Creating pipe server..." -ForegroundColor Cyan
    
    # Create pipe directly without async
    $pipeServer = New-Object System.IO.Pipes.NamedPipeServerStream(
        $pipeName,
        [System.IO.Pipes.PipeDirection]::InOut,
        1,
        [System.IO.Pipes.PipeTransmissionMode]::Message,
        [System.IO.Pipes.PipeOptions]::None
    )
    
    Write-Host "Pipe server created. Starting client in background..." -ForegroundColor Green
    
    # Start a client in background
    $clientJob = Start-Job -ScriptBlock {
        param($pipeName)
        
        Start-Sleep -Seconds 1  # Give server time to start listening
        
        $pipeClient = New-Object System.IO.Pipes.NamedPipeClientStream(
            ".",
            $pipeName,
            [System.IO.Pipes.PipeDirection]::InOut
        )
        
        try {
            Write-Output "Client: Connecting to pipe..."
            $pipeClient.Connect(5000)
            
            $writer = New-Object System.IO.StreamWriter($pipeClient)
            $reader = New-Object System.IO.StreamReader($pipeClient)
            $writer.AutoFlush = $true
            
            # Send message
            Write-Output "Client: Sending PING"
            $writer.WriteLine("PING")
            
            # Read response
            $response = $reader.ReadLine()
            Write-Output "Client: Received response: $response"
            
            return $response
        } finally {
            if ($writer) { $writer.Dispose() }
            if ($reader) { $reader.Dispose() }
            if ($pipeClient) { $pipeClient.Dispose() }
        }
    } -ArgumentList $pipeName
    
    Write-Host "Waiting for client connection..." -ForegroundColor Cyan
    $pipeServer.WaitForConnection()
    
    Write-Host "Client connected! Setting up communication..." -ForegroundColor Green
    $reader = New-Object System.IO.StreamReader($pipeServer)
    $writer = New-Object System.IO.StreamWriter($pipeServer)
    $writer.AutoFlush = $true
    
    # Read message
    $message = $reader.ReadLine()
    Write-Host "Server: Received message: $message" -ForegroundColor White
    
    # Send response
    $response = "PONG"
    $writer.WriteLine($response)
    Write-Host "Server: Sent response: $response" -ForegroundColor White
    
    # Get client results
    Wait-Job $clientJob | Out-Null
    $clientOutput = Receive-Job $clientJob
    Remove-Job $clientJob
    
    Write-Host "`nClient output:" -ForegroundColor Yellow
    $clientOutput | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    
    Write-Host "`nSimple pipe test PASSED!" -ForegroundColor Green
    
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
} finally {
    if ($reader) { $reader.Dispose() }
    if ($writer) { $writer.Dispose() }
    if ($pipeServer) { $pipeServer.Dispose() }
}

Write-Host "`n2. Testing module's Send-PipeMessage function..." -ForegroundColor Yellow

# Now test the module's implementation
try {
    # Start server using module function (non-async for simplicity)
    Write-Host "Starting pipe server using module..." -ForegroundColor Cyan
    $result = Start-NamedPipeServer -PipeName "ModuleTestPipe" -MaxConnections 1
    
    if ($result.Success) {
        Write-Host "Module pipe server started successfully" -ForegroundColor Green
        
        # The server is waiting for connection, we need to connect from another process
        Write-Host "Note: The module's async implementation needs fixing" -ForegroundColor Yellow
        Write-Host "The server is waiting for a connection but async handling is broken" -ForegroundColor Yellow
    } else {
        Write-Host "Failed to start module pipe server: $($result.Error)" -ForegroundColor Red
    }
} catch {
    Write-Host "Module test error: $_" -ForegroundColor Red
}

Write-Host "`nTest complete!" -ForegroundColor Cyan
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU0sqlY76jd5t3t0mw0PA6pAvZ
# t/GgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU+YpZtFaZwhdIg4Ak5ZBWgtE112EwDQYJKoZIhvcNAQEBBQAEggEAiWnG
# qfKBXytc0rtSDOAR/asqTLYKRqhCENXw/oje1efFKQQIMZqx/oVVGN8YzD8rwo2d
# 8XmaDo4hK3fTTe6w0Lsqc038nv8iYC4weBvDbNbYH4XZ/NyhyKdj6lweFBcCXuhO
# HfQlDz7d6lKLGOOpOazyzjb38CbNBxTFh5YCenbp/OUJ6llYYVQ7FszsBVkM5Zqx
# V5ISlETj7CcsD7vfcNzsOvdjpHQHfGuXLDfc0+iLZU31GsNn0teIEMtxr8d78TVy
# pxM2WxlqaK5FD3l3U0mGFrRkV6qPQT/OsGzXUBjr+jGeFb+Cn9DXDBhmQTxG5HNH
# EgP7cQurj+UHyrlYlw==
# SIG # End signature block
