
function Test-HeartbeatResponse {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SubsystemName,
        
        [hashtable]$StatusData = $script:SystemStatusData,
        
        [int]$TimeoutSeconds = 60  # SCOM 2025 standard
    )
    
    Write-SystemStatusLog "Testing heartbeat response for subsystem: $SubsystemName" -Level 'DEBUG'
    
    try {
        if (-not $StatusData.Subsystems.ContainsKey($SubsystemName)) {
            Write-SystemStatusLog "Cannot test heartbeat for unregistered subsystem: $SubsystemName" -Level 'WARN'
            return @{
                IsHealthy = $false
                TimeSinceLastHeartbeat = -1
                Status = "Unknown"
                MissedHeartbeats = -1
            }
        }
        
        $subsystemInfo = $StatusData.Subsystems[$SubsystemName]
        $lastHeartbeatStr = $subsystemInfo.LastHeartbeat
        
        # Parse timestamp (PowerShell 5.1 compatible)
        try {
            $lastHeartbeat = [DateTime]::ParseExact($lastHeartbeatStr, 'yyyy-MM-dd HH:mm:ss.fff', $null)
        } catch {
            Write-SystemStatusLog "Could not parse heartbeat timestamp for $SubsystemName - $lastHeartbeatStr" -Level 'WARN'
            return @{
                IsHealthy = $false
                TimeSinceLastHeartbeat = -1
                Status = "Unknown" 
                MissedHeartbeats = -1
            }
        }
        
        $timeSinceLastHeartbeat = (Get-Date) - $lastHeartbeat
        $timeSinceLastHeartbeatSeconds = [math]::Round($timeSinceLastHeartbeat.TotalSeconds, 0)
        
        # Calculate missed heartbeats based on enterprise standard (60-second intervals)
        $expectedInterval = $script:SystemStatusConfig.HeartbeatIntervalSeconds
        $missedHeartbeats = [math]::Floor($timeSinceLastHeartbeatSeconds / $expectedInterval)
        
        # Determine if healthy based on failure threshold (4 missed heartbeats - SCOM 2025 standard)
        $failureThreshold = $script:SystemStatusConfig.HeartbeatFailureThreshold
        $isHealthy = $missedHeartbeats -lt $failureThreshold
        
        $result = @{
            IsHealthy = $isHealthy
            TimeSinceLastHeartbeat = $timeSinceLastHeartbeatSeconds
            Status = $subsystemInfo.Status
            MissedHeartbeats = $missedHeartbeats
            FailureThreshold = $failureThreshold
            HealthScore = $subsystemInfo.HealthScore
        }
        
        if (-not $isHealthy) {
            Write-SystemStatusLog "Heartbeat failure detected for $SubsystemName (Missed: $missedHeartbeats, Threshold: $failureThreshold)" -Level 'WARN'
        }
        
        return $result
        
    } catch {
        Write-SystemStatusLog "Error testing heartbeat for $SubsystemName - $($_.Exception.Message)" -Level 'ERROR'
        return @{
            IsHealthy = $false
            TimeSinceLastHeartbeat = -1
            Status = "Error"
            MissedHeartbeats = -1
        }
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUdRUHAdKPsgyAmgP/fWLR7q4w
# VxKgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU6/+x86uJ+Dawl0hOBi3IN8A5+2swDQYJKoZIhvcNAQEBBQAEggEAoYxu
# WPtyj53eDUo3QSN9hpBuvoMqxlF8zgpcTJFkIpVOmnBgPZHrcCQxuVdY7xq6F/eU
# rk7l7NhtEq+AXXg+uNO+V3vrWZO+/CXQ+FEDnLASa0lFm8rKW12mRBPanVpMSSvm
# iBAoJ70P1E026+dLfJ05jQzj9yUEVRdP1jg9RV9loF9yuFVUWWjjOaldbpibTHf7
# q+69/foRODcGo2qtXtkmBWso8S/zcobN+YBmP7BSvkGx4ZtpIz9pr0F9C+GA+tEx
# woGv3DSRUINfx8RYGbden9/jtB/MFXhUzR3bXNMbDZNvSFOVex7lmSU6+ZxC+ots
# wpB6YtDwgi5cZQ6otw==
# SIG # End signature block
