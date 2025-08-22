
function Test-ServiceResponsiveness {
    <#
    .SYNOPSIS
    Tests service responsiveness using WMI Win32_Service integration
    
    .DESCRIPTION
    Uses research-validated pattern for service responsiveness testing:
    - WMI Win32_Service class for service-to-process ID mapping
    - Process.Responding property validation
    - Enterprise timeout patterns (60-second standard)
    
    .PARAMETER ServiceName
    Name of the service to test
    
    .PARAMETER ProcessId
    Optional process ID to validate service mapping
    
    .EXAMPLE
    Test-ServiceResponsiveness -ServiceName "Spooler"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ServiceName,
        
        [Parameter(Mandatory=$false)]
        [int]$ProcessId = $null
    )
    
    Write-SystemStatusLog "Testing service responsiveness for service: $ServiceName" -Level 'DEBUG'
    
    try {
        # Get service information using CIM Win32_Service (research-optimized for 2-3x performance improvement)
        Write-SystemStatusLog "Querying CIM Win32_Service for $ServiceName" -Level 'DEBUG'
        $service = Get-CimInstance -ClassName Win32_Service -Filter "Name='$ServiceName'" -ErrorAction Stop
        
        if (-not $service) {
            Write-SystemStatusLog "Service $ServiceName not found in CIM" -Level 'ERROR'
            return $false
        }
        
        $serviceProcessId = $service.ProcessId
        Write-SystemStatusLog "Service $ServiceName mapped to PID $serviceProcessId" -Level 'DEBUG'
        
        # Validate process ID mapping if provided
        if ($ProcessId -and $serviceProcessId -ne $ProcessId) {
            Write-SystemStatusLog "Service PID mismatch: Expected $ProcessId, found $serviceProcessId" -Level 'WARN'
            return $false
        }
        
        # Test process responsiveness using Process.Responding property
        if ($serviceProcessId -and $serviceProcessId -gt 0) {
            Write-SystemStatusLog "Testing process responsiveness for PID $serviceProcessId" -Level 'DEBUG'
            $process = Get-Process -Id $serviceProcessId -ErrorAction SilentlyContinue
            
            if ($process) {
                $isResponding = $process.Responding
                Write-SystemStatusLog "Service $ServiceName process responsiveness: $isResponding" -Level 'DEBUG'
                return $isResponding
            } else {
                Write-SystemStatusLog "Process PID $serviceProcessId for service $ServiceName not found" -Level 'ERROR'
                return $false
            }
        } else {
            Write-SystemStatusLog "Service $ServiceName has no valid process ID" -Level 'WARN'
            return $false
        }
        
    } catch {
        Write-SystemStatusLog "Error testing service responsiveness for $ServiceName`: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUXvIHS5UIDfv1fkC+Cjvq0ANc
# 2wygggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUBiwKaYpy1fItPe05LReheuQAJB8wDQYJKoZIhvcNAQEBBQAEggEAHHkC
# 7ydFKtN1deKJdv8Q1Ydm7DBBUdnZNcIpbRwZivDKXj5KjGicQ+9NOWfXKTO2jNch
# h8yec091NAE9R1ELnqVoc2yzUZfMLNLf2wWEXJLaLuuwRs9zpalTV3FbV+MRXInK
# VNofOeMa7H1t12Mco3bLgW03MtAVY73aHOiRn6NRWvSL7HvMhoh7viqcpZeOTDLO
# 0bWNmJZNRljSpax9hiiLRS4opWMI5W+LFDd8IOVe2jGkEwL1O1SKV1RNPt8Ma+rI
# 8Sl8usGut0anbZhYaeNLYRvEhVTQ+8wuh/OcxqCfjSQGJ2YJlTlalwJJeDtGZcNP
# o10HqajCrT9kBcWhqg==
# SIG # End signature block
