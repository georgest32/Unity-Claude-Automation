
function Test-ProcessPerformanceHealth {
    <#
    .SYNOPSIS
    Tests process performance health against enterprise thresholds
    
    .DESCRIPTION
    Evaluates process performance against realistic thresholds using research-validated patterns:
    - Uses existing configuration thresholds from system status config
    - Implements multi-tier status: Critical, Warning, Good
    - Integrates with Get-ProcessPerformanceCounters
    
    .PARAMETER ProcessId
    Process ID to test performance health
    
    .EXAMPLE
    Test-ProcessPerformanceHealth -ProcessId 1234
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$ProcessId
    )
    
    Write-SystemStatusLog "Testing performance health for process PID $ProcessId" -Level 'DEBUG'
    
    try {
        # Get performance counters
        $performanceData = Get-ProcessPerformanceCounters -ProcessId $ProcessId
        
        if (-not $performanceData) {
            Write-SystemStatusLog "Unable to get performance data for PID $ProcessId" -Level 'WARN'
            return $false
        }
        
        $isHealthy = $true
        $issues = @()
        
        # Check CPU usage against thresholds (from existing config)
        if ($performanceData.CpuPercent -gt $script:SystemStatusConfig.CriticalCpuPercentage) {
            $isHealthy = $false
            $issues += "Critical CPU usage: $($performanceData.CpuPercent)% > $($script:SystemStatusConfig.CriticalCpuPercentage)%"
            Write-SystemStatusLog "Process $ProcessId critical CPU usage: $($performanceData.CpuPercent)%" -Level 'ERROR'
        } elseif ($performanceData.CpuPercent -gt $script:SystemStatusConfig.WarningCpuPercentage) {
            $issues += "Warning CPU usage: $($performanceData.CpuPercent)% > $($script:SystemStatusConfig.WarningCpuPercentage)%"
            Write-SystemStatusLog "Process $ProcessId warning CPU usage: $($performanceData.CpuPercent)%" -Level 'WARN'
        }
        
        # Check memory usage against thresholds
        if ($performanceData.WorkingSetMB -gt $script:SystemStatusConfig.CriticalMemoryMB) {
            $isHealthy = $false
            $issues += "Critical memory usage: $($performanceData.WorkingSetMB)MB > $($script:SystemStatusConfig.CriticalMemoryMB)MB"
            Write-SystemStatusLog "Process $ProcessId critical memory usage: $($performanceData.WorkingSetMB)MB" -Level 'ERROR'
        } elseif ($performanceData.WorkingSetMB -gt $script:SystemStatusConfig.WarningMemoryMB) {
            $issues += "Warning memory usage: $($performanceData.WorkingSetMB)MB > $($script:SystemStatusConfig.WarningMemoryMB)MB"
            Write-SystemStatusLog "Process $ProcessId warning memory usage: $($performanceData.WorkingSetMB)MB" -Level 'WARN'
        }
        
        # Log performance health result
        if ($isHealthy) {
            Write-SystemStatusLog "Process $ProcessId performance health: HEALTHY" -Level 'DEBUG'
        } else {
            Write-SystemStatusLog "Process $ProcessId performance health: UNHEALTHY - $($issues -join '; ')" -Level 'WARN'
        }
        
        return $isHealthy
        
    } catch {
        Write-SystemStatusLog "Error testing process performance health for PID $ProcessId`: $($_.Exception.Message)" -Level 'ERROR'
        return $false
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUz0yVBQ1m9NVZ5HBKvNN6j6IY
# YvOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUxC4GEe6n2/7h/c5Ra2lN3KbX17MwDQYJKoZIhvcNAQEBBQAEggEAiQR7
# 4j3F1ZNb9SMHliM0ShCOYSoY7Uk60ZNlZzA45fX0ApuhJ34QsrNCkYYCSr7w8EBr
# M4geSFvB+0fuPnI+/aJMb/WWcQ6gMo1pFZA0ZJvt+SKwxvCgHYdlkEziHsSoLsyM
# Dtp6U6pBHuJ7RyJUaIde0fpGZzlRr9WjioSntRiPIFmbf+3Y1dfhb/0wpPoeYldV
# Ozj6Abk95+wpiw1APk8AIjkTex/b4hlAq0MPU1jgoQToJG8euDtYU0AzzpsW6OXS
# 3jJQGlHSmb6kZjOneK8p+6qd4p6hvkqQzDJtI4OyLa8+2fGxB9IWTbvNWjoYJbqq
# mjS5mm7ybJpsYpszAw==
# SIG # End signature block
