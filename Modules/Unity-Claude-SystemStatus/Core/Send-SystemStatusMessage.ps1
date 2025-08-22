
function Send-SystemStatusMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Message,
        
        [switch]$UseNamedPipe = $script:CommunicationState.NamedPipeEnabled,
        
        [int]$RetryAttempts = 3
    )
    
    $startTime = Get-Date
    Write-SystemStatusLog "Sending message type: $($Message.messageType)" -Level 'DEBUG'
    
    try {
        $jsonMessage = $Message | ConvertTo-Json -Depth 10 -Compress
        $success = $false
        
        # Try named pipe first if enabled
        if ($UseNamedPipe -and $script:CommunicationState.NamedPipeEnabled) {
            try {
                if ($script:CommunicationState.NamedPipeServer -and $script:CommunicationState.NamedPipeServer.IsConnected) {
                    $bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonMessage)
                    $script:CommunicationState.NamedPipeServer.Write($bytes, 0, $bytes.Length)
                    $script:CommunicationState.NamedPipeServer.Flush()
                    $success = $true
                    Write-SystemStatusLog "Message sent via named pipe" -Level 'DEBUG'
                }
            } catch {
                Write-SystemStatusLog "Named pipe send failed, falling back to JSON file - $($_.Exception.Message)" -Level 'WARN'
            }
        }
        
        # Fallback to JSON file communication (existing pattern)
        if (-not $success) {
            $messageFile = Join-Path (Split-Path $script:SystemStatusConfig.SystemStatusFile -Parent) "message_queue.json"
            
            # Read existing queue
            $existingMessages = @()
            if (Test-Path $messageFile) {
                try {
                    $existingContent = Get-Content $messageFile -Raw | ConvertFrom-Json
                    $existingMessages = @($existingContent)
                } catch {
                    # Ignore parsing errors for queue file
                }
            }
            
            # Add new message
            $existingMessages += $Message
            
            # Keep only last 100 messages (performance optimization)
            if ($existingMessages.Count -gt 100) {
                $existingMessages = $existingMessages[-100..-1]
            }
            
            # Write queue back
            $existingMessages | ConvertTo-Json -Depth 10 | Out-File -FilePath $messageFile -Encoding UTF8
            $success = $true
            Write-SystemStatusLog "Message sent via JSON file fallback" -Level 'DEBUG'
        }
        
        # Update statistics
        if ($success) {
            $script:CommunicationState.MessageStats.Sent++
            $latency = [math]::Round(((Get-Date) - $startTime).TotalMilliseconds, 2)
            $script:CommunicationState.MessageStats.AverageLatencyMs = [math]::Round(
                ($script:CommunicationState.MessageStats.AverageLatencyMs + $latency) / 2, 2
            )
            $script:SystemStatusData.Communication.PerformanceMetrics.AverageLatencyMs = $script:CommunicationState.MessageStats.AverageLatencyMs
            
            Write-SystemStatusLog "Message sent successfully (Latency: ${latency}ms)" -Level 'DEBUG'
        } else {
            $script:CommunicationState.MessageStats.Errors++
            Write-SystemStatusLog "Failed to send message via all communication methods" -Level 'ERROR'
        }
        
        return $success
        
    } catch {
        $script:CommunicationState.MessageStats.Errors++
        Write-SystemStatusLog "Error sending system status message - $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUVmiV1BC2gW7VkJyGrcIMLjRm
# C0igggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU6UDx6t5elUnsQWWaslXc/IVfAywwDQYJKoZIhvcNAQEBBQAEggEAhwNN
# nKwDGcYp8EPc0mHwlbpWgKJNUZls5rLCL0OVVXBH1brdu2TvLmntfyP4DdwsqRf9
# xsYedIZ45AUQCZlZq6kMJL1ocnZIJbCRuY/owkvPX6gFkY0CRKlBf04bMdX0QwVQ
# w6Sp7DdY/24SM28gSaZm5U8h0M2nSU7XGoIVdfo67P6DqDOijiC+tXCuUWwQ09qz
# xCHpm5AskDAREDZc4PG5VFfToWbVr33qBLxQSLy5Uh2ycGAT6Aj4dXAZlPpvTw+0
# BwPHng17YB3jT2IHk8ec6lJWnTftnlCZsNHz/lx1/+TlxIPgeH2PQ8oY/kjrIaDv
# wSnxnmBatAqHSiy8Yw==
# SIG # End signature block
