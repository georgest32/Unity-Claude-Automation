
function Send-HeartbeatRequest {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TargetSubsystem
    )
    
    Write-SystemStatusLog "Sending heartbeat request to: $TargetSubsystem" -Level 'DEBUG'
    
    try {
        $message = New-SystemStatusMessage -MessageType "HeartbeatRequest" -Source "Unity-Claude-SystemStatus" -Target $TargetSubsystem
        $message.payload = @{
            requestedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
            timeout = $script:SystemStatusConfig.CommunicationTimeoutMs
        }
        
        $result = Send-SystemStatusMessage -Message $message
        if ($result) {
            Write-SystemStatusLog "Heartbeat request sent to $TargetSubsystem" -Level 'DEBUG'
        }
        
        return $result
        
    } catch {
        Write-SystemStatusLog "Error sending heartbeat request to $TargetSubsystem - $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQULWYgOrGYFneQlXcESbO+jFBG
# Z36gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUiDsi8cITTfzxjghG5k650f+GAj0wDQYJKoZIhvcNAQEBBQAEggEAqet/
# T4XEF2eb6SfgCeurUL4WekgvSyuV+Q6Y6K5Fct+4MYSMmq+D7Rp3Yci37o/8QddZ
# pWD0t4nvlCIXbZogW2XCzDhxMMUCYc6xvCkYUDzBFWARLg/rmQcvNSWTbTJgPfgh
# 0Wv2ccMucCEMv+F9aSSKDiJTffAVPfSXry02MM3RVp9samDxU6Y4WebzljtmYdF4
# v5P6sJyJVKW+20aI2q/uAU8f1Dl+FKFhYYmT53PxePBUbbhEFiu5SPFhIo3OS5Vb
# Smc5ZuhaEv0usdr5F/jbcfQUa9Dn1QNSV9HF/5xaheBKvRWxFpsEB2HAvh69RlVo
# slu7/P2Qb4fe7p5PdA==
# SIG # End signature block
