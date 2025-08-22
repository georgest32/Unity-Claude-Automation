
function Stop-SystemStatusMonitoring {
    [CmdletBinding()]
    param()
    
    Write-SystemStatusLog "Stopping system status monitoring and cleaning up resources..." -Level 'INFO'
    
    try {
        # Stop file watcher
        Stop-SystemStatusFileWatcher
        
        # Stop background message processor
        Stop-MessageProcessor
        
        # Stop named pipe server
        Stop-NamedPipeServer
        
        # Stop pipe connection job
        if ($script:CommunicationState.PipeConnectionJob) {
            Stop-Job $script:CommunicationState.PipeConnectionJob -Force
            Remove-Job $script:CommunicationState.PipeConnectionJob -Force
            $script:CommunicationState.PipeConnectionJob = $null
        }
        
        # Unregister engine events
        try {
            Get-EventSubscriber | Where-Object { $_.SourceIdentifier -like "*Unity.Claude*" } | Unregister-Event
            Write-SystemStatusLog "Engine events unregistered" -Level 'DEBUG'
        } catch {
            # Ignore cleanup errors
        }
        
        # Clear communication state
        $script:CommunicationState.IncomingMessageQueue = [System.Collections.Concurrent.ConcurrentQueue[PSObject]]::new()
        $script:CommunicationState.OutgoingMessageQueue = [System.Collections.Concurrent.ConcurrentQueue[PSObject]]::new()
        $script:CommunicationState.MessageHandlers = @{}
        $script:CommunicationState.LastMessageTime = $null
        
        Write-SystemStatusLog "System status monitoring stopped successfully" -Level 'OK'
        return $true
        
    } catch {
        Write-SystemStatusLog "Error stopping system status monitoring - $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUlu/lqxIqqjbwbl/6eTavOr30
# Iu6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUTNylfYbqhaHmxsx1NpnICYOP+4swDQYJKoZIhvcNAQEBBQAEggEAsGub
# GBaTFSy6boMqyuISOqglBEOt67tlK0iW2CxNQwIEf1tBjjERAgjebWnewyLLXjIr
# y5qHp4TSr8wYJM+XyzZCYdBIriQb46NShajhl5YCKIXA4xWMHifDM5KwfetnffGm
# xOBBwKWzcDO6vTtKA8OuTWg0ZVBVh1CpNu5NDpXnmq/vZzO5o04ssLu/TQcpC3rC
# 4OnD+aSnvgY1Bd+fuV6fc9j0VG498qgSpyhAKcvD83DaTTGAIaQaCSJ0P8zTY+71
# G/y4THUf5hhf3/P1npdnVQZX6PIO3YcPqz7JnK53MUgUNXvUg4m+ujvNZN8f2hyz
# DAitHAHO3GhsoN/0dQ==
# SIG # End signature block
