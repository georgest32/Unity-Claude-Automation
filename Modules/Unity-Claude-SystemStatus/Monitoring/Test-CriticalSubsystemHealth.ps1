
function Test-CriticalSubsystemHealth {
    <#
    .SYNOPSIS
    Tests health of all critical subsystems
    
    .DESCRIPTION
    Performs comprehensive health checks on all critical subsystems using research-validated patterns:
    - Integrates with Test-ProcessHealth for comprehensive validation
    - Implements priority-based health checking
    - Returns detailed health status for each subsystem
    
    .PARAMETER HealthLevel
    Health check level to use for all subsystems
    
    .EXAMPLE
    Test-CriticalSubsystemHealth -HealthLevel "Standard"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false)]
        [ValidateSet("Minimal", "Standard", "Comprehensive", "Intensive")]
        [string]$HealthLevel = "Standard"
    )
    
    Write-SystemStatusLog "Testing critical subsystem health with level: $HealthLevel" -Level 'INFO'
    
    try {
        $criticalSubsystems = Get-CriticalSubsystems
        $healthResults = @{
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
            HealthLevel = $HealthLevel
            TotalSubsystems = $criticalSubsystems.Count
            HealthySubsystems = 0
            UnhealthySubsystems = 0
            OverallHealthy = $true
            SubsystemResults = @()
        }
        
        foreach ($subsystem in $criticalSubsystems) {
            Write-SystemStatusLog "Testing health for critical subsystem: $($subsystem.Name)" -Level 'DEBUG'
            
            $subsystemHealth = @{
                Name = $subsystem.Name
                Description = $subsystem.Description
                Priority = $subsystem.Priority
                IsHealthy = $false
                ProcessIds = @()
                Details = @()
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss.fff'
            }
            
            try {
                # Find processes matching the subsystem pattern
                $matchingProcesses = Get-Process | Where-Object { $_.Name -like $subsystem.ProcessPattern }
                
                if ($matchingProcesses) {
                    $subsystemHealth.ProcessIds = $matchingProcesses.Id
                    $allProcessesHealthy = $true
                    
                    foreach ($process in $matchingProcesses) {
                        Write-SystemStatusLog "Testing process health for $($subsystem.Name) PID $($process.Id)" -Level 'DEBUG'
                        
                        $processHealth = Test-ProcessHealth -ProcessId $process.Id -HealthLevel $HealthLevel -ServiceName $subsystem.ServiceName
                        
                        if (-not $processHealth.OverallHealthy) {
                            $allProcessesHealthy = $false
                            $subsystemHealth.Details += "Process $($process.Id) unhealthy: $($processHealth.Details -join '; ')"
                        } else {
                            $subsystemHealth.Details += "Process $($process.Id) healthy"
                        }
                    }
                    
                    $subsystemHealth.IsHealthy = $allProcessesHealthy
                } else {
                    $subsystemHealth.IsHealthy = $false
                    $subsystemHealth.Details += "No processes found matching pattern: $($subsystem.ProcessPattern)"
                    Write-SystemStatusLog "No processes found for $($subsystem.Name)" -Level 'WARN'
                }
                
            } catch {
                $subsystemHealth.IsHealthy = $false
                $subsystemHealth.Details += "Error testing subsystem: $($_.Exception.Message)"
                Write-SystemStatusLog "Error testing $($subsystem.Name)`: $($_.Exception.Message)" -Level 'ERROR'
            }
            
            # Update overall health counts
            if ($subsystemHealth.IsHealthy) {
                $healthResults.HealthySubsystems++
                Write-SystemStatusLog "Critical subsystem $($subsystem.Name): HEALTHY" -Level 'DEBUG'
            } else {
                $healthResults.UnhealthySubsystems++
                $healthResults.OverallHealthy = $false
                Write-SystemStatusLog "Critical subsystem $($subsystem.Name): UNHEALTHY" -Level 'WARN'
            }
            
            $healthResults.SubsystemResults += $subsystemHealth
        }
        
        Write-SystemStatusLog "Critical subsystem health check complete: $($healthResults.HealthySubsystems)/$($healthResults.TotalSubsystems) healthy" -Level 'INFO'
        return $healthResults
        
    } catch {
        Write-SystemStatusLog "Error testing critical subsystem health: $($_.Exception.Message)" -Level 'ERROR'
        throw
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUNBjMPg3SWsqNZgGlAgn+vXyK
# M/WgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUNzVCuVsAqLav8vQ7B47gYdP+irMwDQYJKoZIhvcNAQEBBQAEggEAiN+L
# 4ShHR6mYhy3p3/p2igKyt7Z9MGprAEU9ISvm4hrlK8mMlGUDxb9qCgaBz7a+voX7
# P4XmyJ0qnpFYZOaS8Q8fFsMG6LrDAijlgevmMp2sEAJHbwW6mh8H2Dtyt18gCBLA
# PD9TK23UnMhXfI5HFtuKvUKr4RsfVMe7O3PN7Z5Ej9qg/7Ms/MUxeRv8KIDXvC7R
# 19rQFpM6d1m6mxVQNzAznW0x+BBA3fZeLEhHtB7XjhDe3f8pX1bGduFHkBxqTHkr
# P601lRJSJc0yjP4ieLsCN8wlaVP59H10WIkzyybeueiROera1Vb9LlOWaLEVeWkP
# xqUuUsTSqaxBFfhv1w==
# SIG # End signature block
