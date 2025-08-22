
function Get-RegisteredSubsystems {
    [CmdletBinding()]
    param(
        [hashtable]$StatusData = $script:SystemStatusData
    )
    
    try {
        $subsystems = @()
        foreach ($subsystemName in $StatusData.Subsystems.Keys) {
            $subsystemInfo = $StatusData.Subsystems[$subsystemName]
            $subsystems += @{
                Name = $subsystemName
                Status = $subsystemInfo.Status
                ProcessId = $subsystemInfo.ProcessId
                HealthScore = $subsystemInfo.HealthScore
                LastHeartbeat = $subsystemInfo.LastHeartbeat
                ModulePath = $subsystemInfo.ModuleInfo.Path
                Dependencies = $StatusData.Dependencies[$subsystemName]
            }
        }
        
        Write-SystemStatusLog "Retrieved information for $($subsystems.Count) registered subsystems" -Level 'DEBUG'
        return $subsystems
        
    } catch {
        Write-SystemStatusLog "Error getting registered subsystems: $($_.Exception.Message)" -Level 'ERROR'
        return @()
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUKgdY83Yp7X2Q/AobkufTm4mt
# UVCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQU96QnwGr2ePPiGyIHKimWVclRwe8wDQYJKoZIhvcNAQEBBQAEggEAh/0R
# H7zYwmSgdGG3lrkodWtNhuV79g43RA38DuJrIqSIohfLCXGFJpsMDSChqY28186V
# nl+8E6I4UTB+vTFJOt5iLMKOYY1BBqCFtea80DrdYX6Msw6Q/GTKOByb9nvflfq4
# 6iHnaXZiAuNv6lXGLY3GxJ8bkv36Ca2poQkjPeYV3BlPtnqnfq120IPxuna+iUbt
# SJG+U4YOMxszUDIG3g5e+7a2OvXhsQ8kcB44IBrDzw91GTQDMMVZ9YdNPZxl6O2D
# b/Jww6fSdG9L3E4Xtlf1pPo+2L82DNi4cnamXYWhK9pd4taiCfMr5jkjtmvdDjFk
# Htgc3Stw1o8I0OzgJA==
# SIG # End signature block
