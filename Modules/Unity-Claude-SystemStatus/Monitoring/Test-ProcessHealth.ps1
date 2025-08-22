
function Test-ProcessHealth {
    <#
    .SYNOPSIS
    Comprehensive process health validation with dual PID + service responsiveness detection
    
    .DESCRIPTION
    Tests process health using research-validated dual detection approach:
    - PID existence check (basic health)
    - Service responsiveness check (advanced health)
    Integrates with existing health check level system from Enhanced State Tracker
    
    .PARAMETER ProcessId
    Process ID to check for health
    
    .PARAMETER HealthLevel
    Health check level: Minimal, Standard, Comprehensive, Intensive
    
    .PARAMETER ServiceName
    Optional service name for service responsiveness testing
    
    .EXAMPLE
    Test-ProcessHealth -ProcessId 1234 -HealthLevel "Standard"
    
    .EXAMPLE
    Test-ProcessHealth -ProcessId 1234 -HealthLevel "Comprehensive" -ServiceName "MyService"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$ProcessId,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Minimal", "Standard", "Comprehensive", "Intensive")]
        [string]$HealthLevel = "Standard",
        
        [Parameter(Mandatory=$false)]
        [string]$ServiceName = $null
    )
    
    Write-SystemStatusLog "Testing process health for PID $ProcessId with level $HealthLevel" -Level 'DEBUG'
    
    try {
        $healthResult = @{
            ProcessId = $ProcessId
            HealthLevel = $HealthLevel
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
            PidHealthy = $false
            ServiceHealthy = $null
            PerformanceHealthy = $null
            OverallHealthy = $false
            Details = @()
        }
        
        # Basic PID existence check (all health levels)
        Write-SystemStatusLog "Checking PID existence for process $ProcessId" -Level 'DEBUG'
        $pidExists = Get-Process -Id $ProcessId -ErrorAction SilentlyContinue
        $healthResult.PidHealthy = [bool]$pidExists
        
        if ($pidExists) {
            $healthResult.Details += "PID $ProcessId exists and is running"
            Write-SystemStatusLog "PID $ProcessId confirmed running" -Level 'DEBUG'
        } else {
            $healthResult.Details += "PID $ProcessId does not exist or is not running"
            Write-SystemStatusLog "PID $ProcessId not found" -Level 'ERROR'
            $healthResult.OverallHealthy = $false
            return $healthResult
        }
        
        # Service responsiveness check (Standard and above)
        if ($HealthLevel -in @("Standard", "Comprehensive", "Intensive") -and $ServiceName) {
            Write-SystemStatusLog "Testing service responsiveness for $ServiceName" -Level 'DEBUG'
            $serviceHealthy = Test-ServiceResponsiveness -ServiceName $ServiceName -ProcessId $ProcessId
            $healthResult.ServiceHealthy = $serviceHealthy
            
            if ($serviceHealthy) {
                $healthResult.Details += "Service $ServiceName is responsive"
                Write-SystemStatusLog "Service $ServiceName is responsive" -Level 'DEBUG'
            } else {
                $healthResult.Details += "Service $ServiceName is not responsive or hung"
                Write-SystemStatusLog "Service $ServiceName not responsive" -Level 'WARN'
            }
        }
        
        # Performance health check (Comprehensive and above)
        if ($HealthLevel -in @("Comprehensive", "Intensive")) {
            Write-SystemStatusLog "Performing performance health check for PID $ProcessId" -Level 'DEBUG'
            $performanceHealthy = Test-ProcessPerformanceHealth -ProcessId $ProcessId
            $healthResult.PerformanceHealthy = $performanceHealthy
            
            if ($performanceHealthy) {
                $healthResult.Details += "Process performance is within healthy thresholds"
                Write-SystemStatusLog "Process $ProcessId performance healthy" -Level 'DEBUG'
            } else {
                $healthResult.Details += "Process performance exceeds warning thresholds"
                Write-SystemStatusLog "Process $ProcessId performance unhealthy" -Level 'WARN'
            }
        }
        
        # Calculate overall health
        $healthResult.OverallHealthy = $healthResult.PidHealthy
        
        if ($healthResult.ServiceHealthy -ne $null) {
            $healthResult.OverallHealthy = $healthResult.OverallHealthy -and $healthResult.ServiceHealthy
        }
        
        if ($healthResult.PerformanceHealthy -ne $null) {
            $healthResult.OverallHealthy = $healthResult.OverallHealthy -and $healthResult.PerformanceHealthy
        }
        
        Write-SystemStatusLog "Process health check complete: Overall healthy = $($healthResult.OverallHealthy)" -Level 'INFO'
        return $healthResult
        
    } catch {
        Write-SystemStatusLog "Error testing process health for PID $ProcessId`: $($_.Exception.Message)" -Level 'ERROR'
        throw
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUTS7+waUZ/tPeVFf3qhTpT7rL
# 3XigggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUYXAZM4PE64FOWMencuaAaODWxLkwDQYJKoZIhvcNAQEBBQAEggEAQVcl
# caa1i3el4XO75pi/e47amYK4K8y3en4ns6qfy88sJTQzUby4mR1tiiIu7RqObDB7
# FexzQIJqAf9wMNOKLlkT2LxhLWepeVr+NSlYAy0sYFy2trlASpw7BveXdwUZzNa9
# DpgGegrThqZ63HOt96JN5l5Vq7iGi9MmvaIYZaRTNvCElHAQeAH7R4MU97d5Ivru
# HlDqqKm7/IV70nDarcBODhlc5ZCPM/1lG8R0XbKYJOzNhMWiCB049usRG9rYEb0X
# 37lmo2XPpKqmquuiuJXerXI7MYMIqa71h2mLmRjeozcPqohkbeRVjlaYWGiyF5A9
# PJCPi7Vq3Zdks5PW0g==
# SIG # End signature block
