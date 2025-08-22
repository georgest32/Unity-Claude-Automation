
function Send-HealthCheckRequest {
    [CmdletBinding()]
    param(
        [string[]]$TargetSubsystems = @()
    )
    
    Write-SystemStatusLog "Sending health check request to subsystems..." -Level 'DEBUG'
    
    try {
        if ($TargetSubsystems.Count -eq 0) {
            $TargetSubsystems = $script:SystemStatusData.Subsystems.Keys
        }
        
        $results = @{}
        foreach ($subsystem in $TargetSubsystems) {
            $message = New-SystemStatusMessage -MessageType "HealthCheck" -Source "Unity-Claude-SystemStatus" -Target $subsystem
            $message.payload = @{
                checkType = "Comprehensive"
                requestedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
                includePerformanceData = $true
            }
            
            $result = Send-SystemStatusMessage -Message $message
            $results[$subsystem] = $result
        }
        
        $successCount = ($results.Values | Where-Object { $_ -eq $true }).Count
        Write-SystemStatusLog "Health check requests sent: $successCount/$($TargetSubsystems.Count) successful" -Level 'INFO'
        
        return $results
        
    } catch {
        Write-SystemStatusLog "Error sending health check requests - $($_.Exception.Message)" -Level 'ERROR'
        return @{}
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUje1yGmKRYHdDvomCQ5hIko1D
# tIygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUUrPU8KEpQ2Ci73LFqHFAXOH1A/cwDQYJKoZIhvcNAQEBBQAEggEANxx5
# Z+i+YPsbTsKwkg0HSqZCjP1zVrI72IQ6mTsbCE28/Ebqq24MHLpVyxvb+1kvGHRc
# JMOA9xxYA1UWiY8EvxwI3bSclGsm6I4ph3Uhe0JdCF46U0j9A/DH14ZvkVwn2sE7
# WjRtDcDAyyQ/Gi55aYe5h5FY2DdtWfwqjm6J5UIkoy6hrSqwAvC1dlmeo40mnc6C
# 5208ubBPVjhIuQEKG2qlWQWMDOJSVmLWmvRE3bYTc4QRdzcY0d/bunhrWY0NsOYB
# Ygyb+U0I9t50t6TnTfxhwUfqfhjQrg+yKyiU7PsNmDaUqwSGTp1ZQAM4EjcVwSAi
# 1R5cllcxu0DHpWGDXQ==
# SIG # End signature block
