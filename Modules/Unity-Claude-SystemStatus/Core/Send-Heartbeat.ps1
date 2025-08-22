
function Send-Heartbeat {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SubsystemName,
        
        [hashtable]$StatusData = $script:SystemStatusData,
        
        [double]$HealthScore = 1.0,
        
        [hashtable]$AdditionalData = @{}
    )
    
    Write-SystemStatusLog "Sending heartbeat for subsystem: $SubsystemName" -Level 'DEBUG'
    
    try {
        if (-not $StatusData.Subsystems.ContainsKey($SubsystemName)) {
            Write-SystemStatusLog "Cannot send heartbeat for unregistered subsystem: $SubsystemName" -Level 'WARN'
            return $false
        }
        
        # Update heartbeat timestamp and health score
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        $StatusData.Subsystems[$SubsystemName].LastHeartbeat = $timestamp
        $StatusData.Subsystems[$SubsystemName].HealthScore = $HealthScore
        
        # Determine status based on health score (enterprise standard thresholds)
        if ($HealthScore -ge 0.8) {
            $status = "Healthy"
        } elseif ($HealthScore -ge 0.5) {
            $status = "Warning"  
        } else {
            $status = "Critical"
        }
        
        $StatusData.Subsystems[$SubsystemName].Status = $status
        
        # Update process information
        Update-SubsystemProcessInfo -SubsystemName $SubsystemName -StatusData $StatusData | Out-Null
        
        # Add any additional performance data
        foreach ($key in $AdditionalData.Keys) {
            if ($StatusData.Subsystems[$SubsystemName].Performance.ContainsKey($key)) {
                $StatusData.Subsystems[$SubsystemName].Performance[$key] = $AdditionalData[$key]
            }
        }
        
        Write-SystemStatusLog "Heartbeat sent for $SubsystemName (Status: $status, Score: $HealthScore)" -Level 'DEBUG'
        return $true
        
    } catch {
        Write-SystemStatusLog "Error sending heartbeat for $SubsystemName - $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUY6gP/9Aa5PMMuDRf6rFjokOW
# rMCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUAyruxDalYBuTR0Iq+hNToyozWQIwDQYJKoZIhvcNAQEBBQAEggEADQuI
# snbBrWHisgVSxOdu/F5EHeIK7X0L+J5IaBxXy1zsaf3vCXXdaq5DICAnQuchmdRZ
# l+iQ3QpNp8UbKpNJGoa7Qi0YVh1smClW04v9tEjZ0QvUd4k7wy+8BHV4yYeAm9Rq
# J2svyF6C46l4up4lsnUNlDnvrCHxuigsOwWkK6/UAbExvHQsNYZnVxvbSQcgvTdf
# w4PISONoORCwSAoBGJpzl19wW7baub9xxDoquFvNunAB+BU7w0TE6Mn/3Owekv3O
# 6J4WDl2sOFUa6vyfR6YB/3pKWYjIOCu9EK7w7l5uYr+yfGsaTQIOCmk3wa9ziQXB
# /gN8vMpVtqFlxXPL1g==
# SIG # End signature block
