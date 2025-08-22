function Start-MessageProcessor {
    [CmdletBinding()]
    param(
        [int]$ProcessingIntervalMs = 100
    )
    
    Write-SystemStatusLog "Starting background message processor..." -Level 'INFO'
    
    try {
        $script:CommunicationState.MessageProcessor = Start-Job -ScriptBlock {
            param($IncomingQueue, $OutgoingQueue, $PendingResponses, $IntervalMs, $LogFunction)
            
            while ($true) {
                try {
                    # Process outgoing messages
                    $outgoingMessage = $null
                    if ($OutgoingQueue.TryDequeue([ref]$outgoingMessage)) {
                        try {
                            # Send message (will be handled by main thread)
                            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [DEBUG] [MessageProcessor] Processing outgoing message: $($outgoingMessage.messageType)"
                        } catch {
                            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [ERROR] [MessageProcessor] Outgoing message processing failed: $_"
                        }
                    }
                    
                    # Process incoming messages
                    $incomingMessage = $null
                    if ($IncomingQueue.TryDequeue([ref]$incomingMessage)) {
                        try {
                            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [DEBUG] [MessageProcessor] Processing incoming message: $($incomingMessage.messageType)"
                            # Message will be handled by main thread via handler registry
                        } catch {
                            Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [ERROR] [MessageProcessor] Incoming message processing failed: $_"
                        }
                    }
                    
                    Start-Sleep -Milliseconds $IntervalMs
                } catch {
                    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff')] [ERROR] [MessageProcessor] Background processing error: $_"
                    Start-Sleep -Milliseconds 1000  # Longer sleep on error
                }
            }
        } -ArgumentList $script:CommunicationState.IncomingMessageQueue, $script:CommunicationState.OutgoingMessageQueue, $script:CommunicationState.PendingResponses, $ProcessingIntervalMs, 'Write-SystemStatusLog'
        
        Write-SystemStatusLog "Background message processor started (Interval: $ProcessingIntervalMs ms)" -Level 'OK'
        return $true
    } catch {
        Write-SystemStatusLog "Failed to start message processor: $_" -Level 'ERROR'
        return $false
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdWA5iPRumNObGgQ38qrbZeV6
# lv6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUL21+ctdexloSwaXVHSZo9DwSPIswDQYJKoZIhvcNAQEBBQAEggEAQTO0
# vrrWWGUmH97Y7QdPp/XR07VTzLLo7SLTHpnebJ6hhBeqo+dhahZP8lcWuDr02Ed1
# ee2QRgkBs4STwBD0OLvd4gwKSCsbNGacv1eGKWO1KNF17B/zXHo3HqLFGSOJ9Vdi
# Ifid+1YzUc8tHF4u4VHs8VmW3swq+2hyDzGTFNrqRZtqdw15Md6fzbONnjHfX9d4
# k7fdq9Xo2RYnna8drKVUmTKOI1AhbjyBwo+v3Ntg0vq7GYbvQYMhCry4xXdqiv/5
# qSK28y0jihJYij87MeMMtar3fLEL4SUZ/+0J9gXVywXaIs1ZtQB92O23hFSq1+1N
# RU2fLsR1fO0OS8RGAA==
# SIG # End signature block
