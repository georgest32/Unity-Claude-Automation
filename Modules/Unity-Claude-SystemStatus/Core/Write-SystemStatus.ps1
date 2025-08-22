
function Write-SystemStatus {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$StatusData
    )
    
    Write-SystemStatusLog "Writing system status to file..." -Level 'DEBUG'
    
    try {
        # Update last update timestamp
        $StatusData.SystemInfo.LastUpdate = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
        
        # Validate data before writing
        if (-not (Test-SystemStatusSchema -StatusData $StatusData)) {
            Write-SystemStatusLog "System status data failed validation, writing anyway with warning" -Level 'WARN'
        }
        
        # Convert to JSON and write (following existing JSON file patterns)
        $jsonContent = $StatusData | ConvertTo-Json -Depth 10
        # Write without BOM using .NET methods for PowerShell 5.1 compatibility
        [System.IO.File]::WriteAllText($script:SystemStatusConfig.SystemStatusFile, $jsonContent, [System.Text.UTF8Encoding]::new($false))
        
        Write-SystemStatusLog "Successfully wrote system status file" -Level 'OK'
        return $true
    } catch {
        Write-SystemStatusLog "Error writing system status: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQULWbJDI8q2iZ0VLEPjvXyDMWV
# ytqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUGoD54dzi4wa8jIJynGqix36HvdkwDQYJKoZIhvcNAQEBBQAEggEAohOq
# 47tI68aHn5zGPFBh3g2HQ11oTguZp2s95Wo1jMrl4OX6kHPW8w51063pPYD6EQWr
# hwcYF8/S5iLbQmoQ6YKAlwekwF6y5Qgdju4rSyfjk3ddbdQ/oHNrV8qUN5LiXMrD
# gYk8zDMISmXzPwi6M43b8mtWpjghv2n2aqrQUweflEUybo6ibiD4ptxBMQnWcz7H
# QE8Bi6zNpTVT7dBETp/VvVynY6d8aTEq4vO6qwPYX5wnFphEqKpuKtvq2ww/wVtM
# nZlkwYKQPUvRSttPHvdm82ZAinWV75msvk7gKQ4/dasLJ5DVb6Na7L08zbf6FQmN
# AZT4YZ9LGVNIgP/voQ==
# SIG # End signature block
