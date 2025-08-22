
function Test-SystemStatusSchema {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$StatusData
    )
    
    Write-SystemStatusLog "Validating system status data against schema..." -Level 'DEBUG'
    
    try {
        # Convert hashtable to JSON for validation
        $jsonData = $StatusData | ConvertTo-Json -Depth 10 -Compress:$false
        
        # PowerShell 5.1 doesn't have Test-Json, so we'll use structural validation
        # Test-Json was introduced in PowerShell 6.1+
        Write-SystemStatusLog "Using PowerShell 5.1 compatible structural validation" -Level 'DEBUG'
        
        # Validate required top-level properties
        $requiredProperties = @('SystemInfo', 'Subsystems', 'Watchdog', 'Communication')
        foreach ($property in $requiredProperties) {
            if (-not $StatusData.ContainsKey($property)) {
                Write-SystemStatusLog "Missing required property: $property" -Level 'ERROR'
                return $false
            }
        }
        
        # Validate SystemInfo structure
        if ($StatusData.SystemInfo) {
            $requiredSystemInfo = @('HostName', 'PowerShellVersion', 'LastUpdate')
            foreach ($prop in $requiredSystemInfo) {
                if (-not $StatusData.SystemInfo.ContainsKey($prop)) {
                    Write-SystemStatusLog "Missing required SystemInfo property: $prop" -Level 'ERROR'
                    return $false
                }
            }
        }
        
        # Validate Subsystems structure
        if ($StatusData.Subsystems -and $StatusData.Subsystems -is [hashtable]) {
            foreach ($subsystemName in $StatusData.Subsystems.Keys) {
                $subsystem = $StatusData.Subsystems[$subsystemName]
                $requiredSubsystemProps = @('Status', 'LastHeartbeat', 'HealthScore')
                foreach ($prop in $requiredSubsystemProps) {
                    if (-not $subsystem.ContainsKey($prop)) {
                        Write-SystemStatusLog "Missing required property '$prop' in subsystem '$subsystemName'" -Level 'ERROR'
                        return $false
                    }
                }
            }
        }
        
        # Validate Watchdog structure
        if ($StatusData.Watchdog) {
            $requiredWatchdog = @('Enabled', 'LastCheck', 'RestartPolicy')
            foreach ($prop in $requiredWatchdog) {
                if (-not $StatusData.Watchdog.ContainsKey($prop)) {
                    Write-SystemStatusLog "Missing required Watchdog property: $prop" -Level 'ERROR'
                    return $false
                }
            }
        }
        
        # Validate Communication structure
        if ($StatusData.Communication) {
            $requiredComm = @('NamedPipesEnabled', 'JsonFallbackEnabled')
            foreach ($prop in $requiredComm) {
                if (-not $StatusData.Communication.ContainsKey($prop)) {
                    Write-SystemStatusLog "Missing required Communication property: $prop" -Level 'ERROR'
                    return $false
                }
            }
        }
        
        # Try to parse JSON to ensure it's valid JSON format
        try {
            $testParse = $jsonData | ConvertFrom-Json
            Write-SystemStatusLog "JSON format validation passed" -Level 'DEBUG'
        } catch {
            Write-SystemStatusLog "Invalid JSON format: $($_.Exception.Message)" -Level 'ERROR'
            return $false
        }
        
        Write-SystemStatusLog "Structural validation passed (PowerShell 5.1 compatible)" -Level 'OK'
        return $true
        
    } catch {
        Write-SystemStatusLog "Schema validation error: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUfyeAx35b4SYKeuXAriRDg0JG
# yKSgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUgoFhXMj/2nyTi7slhx5LSxopePEwDQYJKoZIhvcNAQEBBQAEggEAjG8O
# pBUQGvACSaKj6ib02MAOXjWfPd6UZiFS3Vt/Fr+B59BQvmEchud9+JKpfIEWP044
# kshJjHKIBHDvyZ+f4GuAK/UDIRbW8BbAQDx5J+oST0o86G72ovKKssvTrJHtqLbK
# MWsc/dks1O63ale+Tz6unHzmgLYu3ZoGdCx18SXDV2qj7akfpnUCM+CwmOt5rmIp
# uAdPemi8nl4FBVOZ+A/bHrrxa8F4Mxo9soOKsCAKp+PuWqA3Q84qLLkW3whBjCuQ
# ksvEMcj49IvXvNO8/ZD6QEwo9/ylV8Az7donj9DGjIF4yUkmrEPU3eJOjXdLyAjs
# 4pgrR7ecun5FcHpDqQ==
# SIG # End signature block
