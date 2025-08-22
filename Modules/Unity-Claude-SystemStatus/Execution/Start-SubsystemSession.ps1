
function Start-SubsystemSession {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SubsystemType,
        
        [Parameter(Mandatory=$true)]
        [scriptblock]$ScriptBlock,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$RunspaceContext
    )
    
    Write-SystemStatusLog "Starting subsystem session: $SubsystemType" -Level 'INFO'
    
    try {
        # PowerShell execution in runspace (Query 9 research finding)
        $powershell = [PowerShell]::Create()
        $powershell.RunspacePool = $RunspaceContext.Pool
        $powershell.AddScript($ScriptBlock.ToString())
        
        # Variable sharing pattern (Query 9 research finding)  
        $powershell.AddArgument($RunspaceContext.SynchronizedResults)
        
        # Add subsystem-specific parameters
        $sessionParameters = @{
            SubsystemType = $SubsystemType
            StartTime = Get-Date
            SessionId = [Guid]::NewGuid().ToString()
        }
        $powershell.AddArgument($sessionParameters)
        
        # Asynchronous execution
        $asyncResult = $powershell.BeginInvoke()
        
        $sessionInfo = @{
            PowerShell = $powershell
            AsyncResult = $asyncResult
            SubsystemType = $SubsystemType
            SessionId = $sessionParameters.SessionId
            StartTime = $sessionParameters.StartTime
            Status = "Running"
        }
        
        # Track active sessions
        if (-not $script:RunspaceManagement.ActiveSessions) {
            $script:RunspaceManagement.ActiveSessions = @{}
        }
        $script:RunspaceManagement.ActiveSessions[$sessionParameters.SessionId] = $sessionInfo
        
        Write-SystemStatusLog "Subsystem session started: $SubsystemType (Session: $($sessionParameters.SessionId))" -Level 'OK'
        return $sessionInfo
        
    }
    catch {
        Write-SystemStatusLog "Failed to start subsystem session ($SubsystemType) - $($_.Exception.Message)" -Level 'ERROR'
        throw
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYFAUTkuewWkli027FtutpmSy
# A/CgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUUdU1eAJqRQv86ibJQNB6W4pd8JYwDQYJKoZIhvcNAQEBBQAEggEAMUCA
# A7OFJ8kK8Z/W147SQRO7u3Yd7fsKW3yT8kasTgz7CvDB6qr6sUQhR1ieXugArP5F
# asNHmcyO6/lh5pbruTQNaG7iBKiT09zBN/vDWaPpggc5mrx4/iktWKfuK0aqjwa6
# pUvHmtVABiJ8gwIp6mj5WVuEvDWi8WWvrCnf9Ml9ikfyZjMHtdpXsQYKlM+7gT/D
# qAKbjI5Lhujob3sm4m2q5BCw2XMJfCJYh5le/rv9se/y/EYcEgx1nY9lRFdhjuFn
# 0IibjXsxq45ZIbIKWCshFGsuqHAQJl8Kda+2+BI9cD667XeRr75AL+7HG+OYX5AE
# DgUBgOqAjuKDq8PyGw==
# SIG # End signature block
