
function Stop-SubsystemRunspaces {
    [CmdletBinding()]
    param(
        [switch]$Force
    )
    
    Write-SystemStatusLog "Stopping subsystem runspaces (Force: $Force)" -Level 'INFO'
    
    try {
        if (-not $script:RunspaceManagement -or -not $script:RunspaceManagement.Context) {
            Write-SystemStatusLog "No runspaces to stop" -Level 'DEBUG'
            return $true
        }
        
        $cleanupCount = 0
        
        # Stop active sessions (Resource management - Query 9 research finding)
        if ($script:RunspaceManagement.ActiveSessions) {
            foreach ($sessionId in $script:RunspaceManagement.ActiveSessions.Keys) {
                $session = $script:RunspaceManagement.ActiveSessions[$sessionId]
                try {
                    if ($session.PowerShell) {
                        if ($Force) {
                            $session.PowerShell.Stop()
                        }
                        $session.PowerShell.Dispose()
                        $cleanupCount++
                    }
                }
                catch {
                    Write-SystemStatusLog "Error disposing session $sessionId - $($_.Exception.Message)" -Level 'WARNING'
                }
            }
            $script:RunspaceManagement.ActiveSessions.Clear()
        }
        
        # Dispose runspace pool (Resource management - Query 9 research finding)
        if ($script:RunspaceManagement.Context.Pool) {
            $script:RunspaceManagement.Context.Pool.Close()
            $script:RunspaceManagement.Context.Pool.Dispose()
        }
        
        # Clear runspace management
        $script:RunspaceManagement = $null
        
        Write-SystemStatusLog "Subsystem runspaces stopped successfully (Cleaned up: $cleanupCount sessions)" -Level 'OK'
        return $true
        
    }
    catch {
        Write-SystemStatusLog "Error stopping subsystem runspaces - $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU+ylnLaALi4K0dQiGmo/5GXBw
# /PSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUHPh/unoRgWA6Qrnlh2wRZESx6dYwDQYJKoZIhvcNAQEBBQAEggEAKr6U
# 1DMvAC+hDnjz0rGe8ufp9OZGXpnz2TqD2WHMUKYSDLCtN1GagYRNzeyfydUxM2sk
# 9TCZZaKOokNgTCguvi5bxIJZ+YtcfVN78luz8QH0g/um5ljLyoc9dZ0bf4KoF/t2
# Vm5SUVJZf1XSj+tO7WBYoSdI1mAl6qdKYKgquAdrkn0yfrzZiPjGTcTkb1U49bX9
# VwZdsbFF21P/2C3FCjX1pIlNH6AOq/TDzxDaph6FF3sjdFX/bSI8d5Rt15sS0dgX
# i1BmgPRrteeuQRgi9OgWUPWdB5/QrqrBOJO99pTX78m/kqBXDgU0dY3QHTei6pHp
# f/qI4gSa84n8bilR3Q==
# SIG # End signature block
