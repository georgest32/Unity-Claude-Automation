
function Receive-SystemStatusMessage {
    [CmdletBinding()]
    param(
        [int]$TimeoutMs = 5000
    )
    
    try {
        $messages = @()
        
        # Try named pipe first if enabled
        if ($script:CommunicationState.NamedPipeEnabled -and $script:CommunicationState.NamedPipeServer) {
            # Named pipe message receiving (non-blocking check)
            try {
                if ($script:CommunicationState.NamedPipeServer.IsConnected) {
                    $buffer = New-Object byte[] 4096
                    $bytesRead = $script:CommunicationState.NamedPipeServer.Read($buffer, 0, $buffer.Length)
                    
                    if ($bytesRead -gt 0) {
                        $messageJson = [System.Text.Encoding]::UTF8.GetString($buffer, 0, $bytesRead)
                        $message = $messageJson | ConvertFrom-Json
                        $messages += ConvertTo-HashTable -InputObject $message
                        
                        Write-SystemStatusLog "Received message via named pipe" -Level 'DEBUG'
                    }
                }
            } catch {
                # Ignore named pipe read errors (non-blocking)
            }
        }
        
        # Check JSON file queue (fallback)
        $messageFile = Join-Path (Split-Path $script:SystemStatusConfig.SystemStatusFile -Parent) "message_queue.json"
        if (Test-Path $messageFile) {
            try {
                $queueContent = Get-Content $messageFile -Raw | ConvertFrom-Json
                $queueMessages = @($queueContent)
                
                foreach ($msg in $queueMessages) {
                    $messages += ConvertTo-HashTable -InputObject $msg
                }
                
                # Clear processed messages
                if ($messages.Count -gt 0) {
                    Remove-Item $messageFile -ErrorAction SilentlyContinue
                    Write-SystemStatusLog "Processed $($messages.Count) messages from JSON queue" -Level 'DEBUG'
                }
            } catch {
                # Ignore queue processing errors
            }
        }
        
        # Update statistics
        if ($messages.Count -gt 0) {
            $script:CommunicationState.MessageStats.Received += $messages.Count
        }
        
        return $messages
        
    } catch {
        Write-SystemStatusLog "Error receiving system status messages - $($_.Exception.Message)" -Level 'ERROR'
        return @()
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUJ2pVNKMitggqYzmehsmyfDxP
# EMOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUgiYAOoozzoi2bEOlm3LzWF74C2MwDQYJKoZIhvcNAQEBBQAEggEAemNQ
# QwnvmCqK38DmuJZg8JO4WSE1GlTH3M8kAoc5kD0kvHSleF+IozZOUQrU5vqkRKY4
# Wz7tJCcsNqhaP6sbHT/2bcbfHDS3VNtkk4wAPirVadUE8JCXVa80PuMmS2KBl/Ar
# TqBwbnVLORJujeeUeRsLvsyhEKV39m9BvmORXbZiEpu9iIwQgylSWkOW6wJz0sXf
# oSJQsGTsGQrLaqiNYnvE/awfqWdctZ00rxKloK5oNGeGJA+SFNoMH9qRjf5HiMXz
# TX1bDcGe5OomBsW8j543hi+hxm+aj2/2gcC2sdxXTx+a4VmUEryQ1MPdvqch3mkU
# 3G50qV5fN0yLeL0Y8Q==
# SIG # End signature block
