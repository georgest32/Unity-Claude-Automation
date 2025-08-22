
function New-SystemStatusMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet("StatusUpdate", "HeartbeatRequest", "HealthCheck", "Alert", "Command")]
        [string]$MessageType,
        
        [Parameter(Mandatory)]
        [string]$Source,
        
        [Parameter(Mandatory)]
        [string]$Target,
        
        [hashtable]$Payload = @{},
        
        [string]$CorrelationId = [System.Guid]::NewGuid().ToString()
    )
    
    # Follow existing JSON patterns from Enhanced State Tracker
    $message = @{
        messageType = $MessageType
        timestamp = "/Date($([DateTimeOffset]::Now.ToUnixTimeMilliseconds()))/"  # ETS format
        source = $Source
        target = $Target
        correlationId = $CorrelationId
        payload = $Payload
        version = "1.0.0"
    }
    
    Write-SystemStatusLog "Created $MessageType message from $Source to $Target" -Level 'DEBUG'
    return $message
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKdbGCq+uHm6Mz14HsNKCpFtj
# zo+gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUBl0irZ+Z1hBYPB2kr0G9FTaX+g8wDQYJKoZIhvcNAQEBBQAEggEABG/S
# 5num06OQx0aZcrcCCQ9TUTLeOklA2AxLZhtyn6q5d2qCcWE/OBFy34erWTS3Wjuh
# 0EDMHufiWlvAQdVI9NsgzvCI1inRXO00E/kBCqATi61vYzA2fZOtduKRVYEJqsN8
# jjnhQrpWOZDqWMJ8GurFZk3M9gvslanL6E8ZyYBFY2ztAVQOD2u1+1ggvDed6BwA
# oM/zqI8iCsdTm8+3I5ykdzPxv1CUbS1POmZzrUIO4Ns34uAqTml2HdkzaFoLtQy2
# /Y6FXiBm7J39gbRVPPuQqKMXdZTnE19vEEnioOn8KC+p1kbUWmSFQ7VIMDTYcDoF
# itAJtSttVieDdxLbyA==
# SIG # End signature block
