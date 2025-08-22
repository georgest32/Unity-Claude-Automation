function Measure-CommunicationPerformance {
    [CmdletBinding()]
    param(
        [string]$TestMessageId = [System.Guid]::NewGuid().ToString()
    )
    
    $startTime = Get-Date
    Write-SystemStatusLog "Starting communication performance test (ID: $TestMessageId)" -Level 'DEBUG'
    
    try {
        # Create health check message
        $testMessage = New-SystemStatusMessage -MessageType "HealthCheck" -Source "Unity-Claude-SystemStatus" -Target "Unity-Claude-SystemStatus" -CorrelationId $TestMessageId
        $testMessage.payload = @{ 
            requestTimestamp = $startTime.Ticks
            testId = $TestMessageId 
        }
        
        # Send message and measure latency
        $sendResult = Send-SystemStatusMessage -Message $testMessage
        
        if ($sendResult) {
            $endTime = Get-Date
            $latencyMs = ($endTime - $startTime).TotalMilliseconds
            
            Write-SystemStatusLog "Communication performance test completed: $latencyMs ms" -Level 'INFO'
            
            # Validate against performance target (<100ms)
            if ($latencyMs -lt 100) {
                Write-SystemStatusLog "Performance target met: $latencyMs ms < 100ms" -Level 'OK'
            } else {
                Write-SystemStatusLog "Performance target exceeded: $latencyMs ms > 100ms" -Level 'WARN'
            }
            
            # Update average latency
            $script:CommunicationState.MessageStats.AverageLatencyMs = [math]::Round(
                ($script:CommunicationState.MessageStats.AverageLatencyMs + $latencyMs) / 2, 2
            )
            
            return $latencyMs
        } else {
            Write-SystemStatusLog "Performance test failed - message send unsuccessful" -Level 'ERROR'
            return -1
        }
    } catch {
        Write-SystemStatusLog "Performance measurement failed: $_" -Level 'ERROR'
        return -1
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUoVwlNBb3R0e7xIDfWEz8sScE
# p0ygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUo4gwDqz6r+It24rfooolR9l+D7swDQYJKoZIhvcNAQEBBQAEggEAhvQH
# DD0T70rIwxv0Q8b8SPD2tlufueq0HVxRhEjCb+cRDU7aOlAMjeQlyOk0akT5HMjS
# /WIRVh9B+91ecird3UW6BBye/b1Xr1HCOXGLuHHashWu2pXikCpF1L3OeJrlG2yA
# 7NodbXBkR5MhdpQ94FiNChvIka2QuUgFzsAZmVumLb1qc2CwjjsZK48Ro+lffDxj
# enq6ezTa228rVHEOVdNZFzHS+CwpeImWNEJGVe9PMQEmPxa9YgyKYs6UZMoFgbac
# XovX2UAJyjAk2hdTQZRrRyjxQ0N/A7sgodex5Js0JU9dQAZ2Sl8Z+SGYdSw+oUch
# 2bQcZdXXL0IuUwMciw==
# SIG # End signature block
