
function Update-SubsystemProcessInfo {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$SubsystemName,
        
        [hashtable]$StatusData = $script:SystemStatusData
    )
    
    Write-SystemStatusLog "Updating process information for subsystem: $SubsystemName" -Level 'DEBUG'
    
    try {
        if (-not $StatusData.Subsystems.ContainsKey($SubsystemName)) {
            Write-SystemStatusLog "Subsystem $SubsystemName not found in status data" -Level 'WARN'
            return $false
        }
        
        # Get current process ID
        $processId = Get-SubsystemProcessId -SubsystemName $SubsystemName
        $StatusData.Subsystems[$SubsystemName].ProcessId = $processId
        
        if ($processId) {
            # Get performance information using existing patterns
            try {
                $process = Get-Process -Id $processId -ErrorAction SilentlyContinue
                if ($process) {
                    $StatusData.Subsystems[$SubsystemName].Performance.CpuPercent = [math]::Round($process.CPU, 2)
                    $StatusData.Subsystems[$SubsystemName].Performance.MemoryMB = [math]::Round($process.WorkingSet / 1MB, 2)
                    
                    Write-SystemStatusLog "Updated performance data for $SubsystemName (PID: $processId)" -Level 'DEBUG'
                }
            } catch {
                Write-SystemStatusLog "Could not get performance data for $SubsystemName - $($_.Exception.Message)" -Level 'WARN'
            }
        }
        
        return $true
        
    } catch {
        Write-SystemStatusLog "Error updating process info for $SubsystemName - $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUHWOXI4XIY6wpAMZR4olFw4VR
# tm6gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUGlLOhUfsFH++y/UXilJvTFJqgUgwDQYJKoZIhvcNAQEBBQAEggEANe0E
# WFdSM6ws6UDQRPGLS219eX2TStVeGUFsYmgErbEvuxbhQ/vIFBHkR36kPIbYhCrV
# 1b1j1l6Mi7Gy+geV0vHpI7pQc2fkszUL7I5AdaKFZuKmdz2x+rMqkU8cDCyGkBaf
# 1e2SCvuEkHAbI9jQ2CHj7TJqj8jAKBj1GGVvFCWXU6tvMfprvM8s1ckGz5Ku3wJI
# IFJGESfm4fZEw9hl8BRNMzQFV5B4ZRdigsFLx74MwDONeE3eO7+9o6tY/3toD5Cg
# 3aMjDEkkcO9CwOyKkJNU9jnXj6OnmmngalM/O0KkkcZ/Zv8LYeRmklo7L9aySVPP
# kCzxg7K5DwAhxKBlQQ==
# SIG # End signature block
