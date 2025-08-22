
function Initialize-NamedPipeServer {
    [CmdletBinding()]
    param(
        [string]$PipeName = "UnityClaudeSystemStatus",
        [int]$MaxConnections = 10,
        [int]$TimeoutSeconds = 30
    )
    
    Write-SystemStatusLog "Initializing research-validated named pipe server for cross-subsystem communication..." -Level 'INFO'
    
    try {
        # Load .NET 3.5 System.Core assembly for PowerShell 5.1 compatibility (research requirement)
        Add-Type -AssemblyName System.Core -ErrorAction Stop
        Write-SystemStatusLog "System.Core assembly loaded successfully for PowerShell 5.1" -Level 'DEBUG'
        
        # Research-validated security configuration
        $PipeSecurity = New-Object System.IO.Pipes.PipeSecurity
        $AccessRule = New-Object System.IO.Pipes.PipeAccessRule("Users", "FullControl", "Allow")
        $PipeSecurity.AddAccessRule($AccessRule)
        Write-SystemStatusLog "Named pipe security configured (Users: FullControl)" -Level 'DEBUG'
        
        # Create asynchronous named pipe server with proper security
        $pipeServer = New-Object System.IO.Pipes.NamedPipeServerStream(
            $PipeName,
            [System.IO.Pipes.PipeDirection]::InOut,
            $MaxConnections,
            [System.IO.Pipes.PipeTransmissionMode]::Message,
            [System.IO.Pipes.PipeOptions]::Asynchronous,
            32768,  # InBufferSize
            32768,  # OutBufferSize
            $PipeSecurity
        )
        
        Write-SystemStatusLog "Named pipe server created with async options and security" -Level 'DEBUG'
        
        # Start async connection handling
        $script:CommunicationState.PipeConnectionJob = Start-Job -ScriptBlock {
            param($PipeServer, $TimeoutSeconds)
            
            try {
                $timeout = [timespan]::FromSeconds($TimeoutSeconds)
                $source = [System.Threading.CancellationTokenSource]::new($timeout)
                $connectionTask = $PipeServer.WaitForConnectionAsync($source.token)
                
                $elapsed = 0
                while ($elapsed -lt $TimeoutSeconds -and -not $connectionTask.IsCompleted) {
                    Start-Sleep -Milliseconds 100
                    $elapsed += 0.1
                }
                
                if ($connectionTask.IsCompleted) {
                    return @{ Success = $true; Message = "Pipe connection established" }
                } else {
                    return @{ Success = $false; Message = "Pipe connection timeout after $TimeoutSeconds seconds" }
                }
            } catch {
                return @{ Success = $false; Message = "Pipe connection error: $_" }
            }
        } -ArgumentList $pipeServer, $TimeoutSeconds
        
        if ($pipeServer) {
            $script:CommunicationState.NamedPipeServer = $pipeServer
            $script:CommunicationState.NamedPipeEnabled = $true
            $script:SystemStatusData.Communication.NamedPipesEnabled = $true
            
            Write-SystemStatusLog "Named pipe server initialized successfully: $PipeName (Async: $MaxConnections connections)" -Level 'OK'
            return $true
        }
        
    } catch {
        Write-SystemStatusLog "Named pipes not available, using JSON fallback - $($_.Exception.Message)" -Level 'WARN'
        $script:CommunicationState.NamedPipeEnabled = $false
        $script:SystemStatusData.Communication.NamedPipesEnabled = $false
        return $false
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU9Img5hd8nnER7XVUXNIEVSAD
# oh6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUT12Qqh7w9f32hkAeFZzqjzYQaAUwDQYJKoZIhvcNAQEBBQAEggEAfh1j
# ITe9Ew4aCYVqhookesa/D3S17ZE7CX5ROAqSwVEmC4Vnqmp0LE/buv6/vanxo4vY
# /pq4jXlJUjt3YhYGURGaCDhNTZV6G1PVGkEJnOCPY6C/qK7P+IZCRomLp3onP69U
# +KkZJ0LDtrY1vyZHD5RABwQ9R9Ttw/pddTGhu3S0w0qpDxIdxLKOeDCQguLMXsrO
# cEbCY41SBPykq4MYLegRxrDxaSIoEjrYvxtxrZbCqXu0FyjMbtNgYxu5VuYiRPuV
# R00rhLN/z0v4meZe5rdQTOgtDYhTzaaKJl2u5Kp07qUgdYCb5SE+SFEJCwKs6K9f
# tmfo2d0kfw0AJs92sQ==
# SIG # End signature block
