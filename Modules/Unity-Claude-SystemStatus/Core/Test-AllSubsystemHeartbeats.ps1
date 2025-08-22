
function Test-AllSubsystemHeartbeats {
    [CmdletBinding()]
    param(
        [hashtable]$StatusData = $script:SystemStatusData
    )
    
    Write-SystemStatusLog "Testing heartbeats for all registered subsystems..." -Level 'DEBUG'
    
    try {
        $results = @{}
        $unhealthyCount = 0
        
        foreach ($subsystemName in $StatusData.Subsystems.Keys) {
            $heartbeatResult = Test-HeartbeatResponse -SubsystemName $subsystemName -StatusData $StatusData
            $results[$subsystemName] = $heartbeatResult
            
            if (-not $heartbeatResult.IsHealthy) {
                $unhealthyCount++
            }
        }
        
        Write-SystemStatusLog "Heartbeat test completed: $($results.Count) subsystems checked, $unhealthyCount unhealthy" -Level 'INFO'
        
        # Run AutonomousAgent watchdog check if the module is available
        try {
            if (Get-Command -Name "Invoke-AutonomousAgentWatchdog" -ErrorAction SilentlyContinue) {
                Write-SystemStatusLog "Running AutonomousAgent watchdog check..." -Level 'DEBUG'
                Invoke-AutonomousAgentWatchdog
            }
        } catch {
            Write-SystemStatusLog "Warning: AutonomousAgent watchdog check failed: $($_.Exception.Message)" -Level 'WARN'
        }
        
        return @{
            Results = $results
            TotalSubsystems = $results.Count
            UnhealthyCount = $unhealthyCount
            HealthyCount = $results.Count - $unhealthyCount
            TestTimestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        }
        
    } catch {
        Write-SystemStatusLog "Error testing all subsystem heartbeats: $($_.Exception.Message)" -Level 'ERROR'
        return @{
            Results = @{}
            TotalSubsystems = 0
            UnhealthyCount = 0
            HealthyCount = 0
            TestTimestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        }
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUvNp1KHjBc7n9Cu/q1HGKjSGt
# ENOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUNfLdttTmfQQzEnlSq4DVE3O7he0wDQYJKoZIhvcNAQEBBQAEggEAHd95
# vE/G7D1Z/iEsLpIHmeusNIuiR6o4tZ+hGLShztYjL7mAOKuoZ99rPLmdRUYkMYQQ
# KE7gH8DpaVvWNyVPZYM/qT06xsiKuWzeZPR8R3JWvuua+AbiTeKK65d6djcHu46c
# IQ2lr1kQmHQNYxzGZuIK7XAGq9oAme+cbADSJ8QFbctOKcOGlC8Wcayg/+OZpvad
# L6ilcjqGIn/5PzAAeughD6h2UUSSTJEEXKjMVdJrRGUPJx8g2T6hUcoBKlXW5woL
# rh5+tBW4KypM7FIPhDXGd3d2WADyAPlBg+ay+yrG+O2KvKHW/WXwWF6GAbvH/qyT
# yN4BnC3oQlS9GMD3VA==
# SIG # End signature block
