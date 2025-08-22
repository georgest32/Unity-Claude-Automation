
function Unregister-Subsystem {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SubsystemName,
        
        [hashtable]$StatusData = $script:SystemStatusData
    )
    
    Write-SystemStatusLog "Unregistering subsystem: $SubsystemName" -Level 'INFO'
    
    try {
        # ENHANCED: Release mutex if this subsystem holds one
        if ($script:SubsystemMutexes -and $script:SubsystemMutexes.ContainsKey($SubsystemName)) {
            Write-SystemStatusLog "Releasing mutex for subsystem: $SubsystemName" -Level 'DEBUG'
            $mutex = $script:SubsystemMutexes[$SubsystemName]
            
            if ($mutex) {
                try {
                    # Use the Remove-SubsystemMutex function if available
                    if (Get-Command Remove-SubsystemMutex -ErrorAction SilentlyContinue) {
                        Remove-SubsystemMutex -MutexObject $mutex -SubsystemName $SubsystemName
                    } else {
                        # Fallback to direct release
                        $mutex.ReleaseMutex()
                        $mutex.Dispose()
                        Write-SystemStatusLog "Released and disposed mutex for $SubsystemName" -Level 'OK'
                    }
                } catch {
                    Write-SystemStatusLog "Error releasing mutex for ${SubsystemName}: $_" -Level 'ERROR'
                }
            }
            
            # Remove from mutex tracking
            $script:SubsystemMutexes.Remove($SubsystemName)
            Write-SystemStatusLog "Removed mutex reference for $SubsystemName" -Level 'TRACE'
        }
        
        # Remove from status data
        if ($StatusData.Subsystems.ContainsKey($SubsystemName)) {
            $StatusData.Subsystems.Remove($SubsystemName)
        }
        
        if ($StatusData.Dependencies.ContainsKey($SubsystemName)) {
            $StatusData.Dependencies.Remove($SubsystemName)
        }
        
        # Remove from critical subsystems registry
        if ($script:CriticalSubsystems.ContainsKey($SubsystemName)) {
            $script:CriticalSubsystems.Remove($SubsystemName)
        }
        
        Write-SystemStatusLog "Successfully unregistered subsystem: $SubsystemName" -Level 'OK'
        return $true
        
    } catch {
        Write-SystemStatusLog "Error unregistering subsystem $SubsystemName - $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUVpNoAYKeT/P6skDWlRoZsftq
# plugggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUaoK+MlyUMnVtOaWhNRC0T2zC1MswDQYJKoZIhvcNAQEBBQAEggEAZ/zQ
# 99Ql6aEATlsj3CPZPxqUDXiiT85pETZfrnc4O8pT976QgdbF8ayuXuwXqhd0gY6U
# PczH4lyArwMYU8m382MzByoU495BFjcqSx1Y6bCVylZtGkwKpN8cyk640E9cdh0c
# kbTYMO08Sudkdv1Dt+mCQ8gi1wbNoKfLowjFch/19VxsroANK7IwlW6UFQUv+L3Z
# /FPa5Cb+FWzsar1iwcIqEh0i3sKnuihgtrWuO4Q8XF4kZgtcZZ0gibdSSMa5SHz4
# 5gQLVKV0LaT2+4x8qI0kONVCDccsKiXEFrtpDu+6g0qFHlqEpf/YQO+Fwh6mFHg1
# hGdzMexxwxErN1PN1w==
# SIG # End signature block
