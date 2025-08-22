function Initialize-CrossModuleEvents {
    [CmdletBinding()]
    param()
    
    Write-SystemStatusLog "Initializing cross-module engine events..." -Level 'INFO'
    
    try {
        # Register for system-wide Unity-Claude events
        Register-EngineEvent -SourceIdentifier "Unity.Claude.SystemStatus" -Action {
            try {
                $message = $Event.MessageData
                if ($message) {
                    # Add to incoming message queue for processing
                    $script:CommunicationState.IncomingMessageQueue.Enqueue($message)
                    Write-SystemStatusLog "Cross-module event received: $($message.messageType)" -Level 'DEBUG'
                }
            } catch {
                Write-SystemStatusLog "Cross-module event processing failed: $_" -Level 'ERROR'
            }
        }
        
        # Register for PowerShell session cleanup
        Register-EngineEvent -SourceIdentifier "PowerShell.Exiting" -Action {
            Write-SystemStatusLog "PowerShell session exiting - cleaning up system status resources" -Level 'INFO'
            Stop-SystemStatusMonitoring
        }
        
        Write-SystemStatusLog "Cross-module engine events registered successfully" -Level 'OK'
        return $true
    } catch {
        Write-SystemStatusLog "Failed to register cross-module events: $_" -Level 'ERROR'
        return $false
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUDaOUBxyMuIm7Ch3apvtZPSsI
# WWGgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU2La45b+jBG98HyaYeRxLIH+siJswDQYJKoZIhvcNAQEBBQAEggEAODZd
# cuFhJbrCifEhg7/ca+xCSp3KVyuQifef9eSfmYYjXX7z74zftp5MnjLespXefaN0
# 09jY7oRIa5sti6lBfDbGuKHH0jtylT7c8L/2SPF3xS1hC5WkGCpI1GBT/x51VOtb
# E7UGWimHgRDjlT15sDox1NseN7wVLbQ5zVRU4DKsbkpnXnHhNXBTRwQgLXps+Nl7
# IlzNXE9P5XwhyzF76S4vC5dBEOTOCoSNJWAb533bnkhMMJlhKgVbgd4A0IObNiZj
# 1634nvWKEVw8VbiUtNtlEyPgO2tggx6I7u22SG88D8FWYlAn46rAy6DMUNetEEcl
# jIFg4hS0/fJGY2ZoQQ==
# SIG # End signature block
