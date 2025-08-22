function Test-SubsystemStatus {
    <#
    .SYNOPSIS
    Generic health checking function for any subsystem type
    
    .DESCRIPTION
    Implements flexible health checking patterns for heterogeneous subsystems:
    - Custom health check function support (manifest-defined)
    - Fallback to PID-based process checking
    - Performance counter monitoring (Memory, CPU)
    - Circuit breaker integration
    - Standardized health object output
    
    .PARAMETER SubsystemName
    Name of the subsystem to check health for
    
    .PARAMETER Manifest
    Subsystem manifest containing health check configuration
    
    .PARAMETER IncludePerformanceData
    Include CPU and memory performance metrics
    
    .EXAMPLE
    Test-SubsystemStatus -SubsystemName "AutonomousAgent" -Manifest $manifest
    
    .EXAMPLE
    Test-SubsystemStatus -SubsystemName "CLISubmission" -Manifest $manifest -IncludePerformanceData
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SubsystemName,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$Manifest,
        
        [switch]$IncludePerformanceData
    )
    
    Write-SystemStatusLog "Testing health for subsystem: $SubsystemName" -Level 'DEBUG'
    
    try {
        # Initialize health result object
        $healthResult = @{
            SubsystemName = $SubsystemName
            Timestamp = Get-Date
            OverallHealthy = $false
            ProcessRunning = $false
            ProcessId = $null
            CustomHealthCheck = $null
            PerformanceData = $null
            ErrorDetails = @()
            HealthCheckSource = "Unknown"
        }
        
        # Read current system status for PID information
        $systemStatus = Read-SystemStatus
        $subsystemInfo = $null
        if ($systemStatus.Subsystems.ContainsKey($SubsystemName)) {
            $subsystemInfo = $systemStatus.Subsystems[$SubsystemName]
            $healthResult.ProcessId = $subsystemInfo.ProcessId
        }
        
        # Step 1: Check if custom health check function exists
        $customHealthFunction = $Manifest.HealthCheckFunction
        if ($customHealthFunction -and (Get-Command $customHealthFunction -ErrorAction SilentlyContinue)) {
            Write-SystemStatusLog "Using custom health check function: $customHealthFunction" -Level 'DEBUG'
            
            try {
                $customResult = & $customHealthFunction
                $healthResult.CustomHealthCheck = $customResult
                $healthResult.HealthCheckSource = "CustomFunction"
                
                # Handle different return types from custom functions
                if ($customResult -is [bool]) {
                    $healthResult.OverallHealthy = $customResult
                } elseif ($customResult -is [hashtable] -and $customResult.ContainsKey('OverallHealthy')) {
                    $healthResult.OverallHealthy = $customResult.OverallHealthy
                    if ($customResult.ContainsKey('ProcessRunning')) {
                        $healthResult.ProcessRunning = $customResult.ProcessRunning
                    }
                } else {
                    # Assume success if function completes without error
                    $healthResult.OverallHealthy = $true
                }
                
                Write-SystemStatusLog "Custom health check completed: $($healthResult.OverallHealthy)" -Level 'DEBUG'
                
            } catch {
                Write-SystemStatusLog "Custom health check failed: $($_.Exception.Message)" -Level 'WARN'
                $healthResult.ErrorDetails += "Custom health check error: $($_.Exception.Message)"
                $healthResult.OverallHealthy = $false
            }
        }
        
        # Step 2: Fallback to PID-based checking if no custom function or if custom check failed
        if (-not $healthResult.OverallHealthy -or -not $customHealthFunction) {
            Write-SystemStatusLog "Performing PID-based health check" -Level 'DEBUG'
            $healthResult.HealthCheckSource = "PidCheck"
            
            if ($subsystemInfo -and $subsystemInfo.ProcessId) {
                try {
                    $process = Get-Process -Id $subsystemInfo.ProcessId -ErrorAction SilentlyContinue
                    if ($process) {
                        $healthResult.ProcessRunning = $true
                        $healthResult.OverallHealthy = $true
                        Write-SystemStatusLog "Process $($subsystemInfo.ProcessId) is running" -Level 'DEBUG'
                    } else {
                        $healthResult.ProcessRunning = $false
                        $healthResult.OverallHealthy = $false
                        $healthResult.ErrorDetails += "Process ID $($subsystemInfo.ProcessId) not found"
                        Write-SystemStatusLog "Process $($subsystemInfo.ProcessId) not found" -Level 'WARN'
                    }
                } catch {
                    $healthResult.ProcessRunning = $false
                    $healthResult.OverallHealthy = $false
                    $healthResult.ErrorDetails += "Error checking process: $($_.Exception.Message)"
                    Write-SystemStatusLog "Error checking process $($subsystemInfo.ProcessId): $($_.Exception.Message)" -Level 'ERROR'
                }
            } else {
                $healthResult.ProcessRunning = $false
                $healthResult.OverallHealthy = $false
                $healthResult.ErrorDetails += "No process ID registered for subsystem"
                Write-SystemStatusLog "No process ID found for subsystem $SubsystemName" -Level 'WARN'
            }
        }
        
        # Step 3: Performance data collection if requested and process is running
        if ($IncludePerformanceData -and $healthResult.ProcessRunning -and $healthResult.ProcessId) {
            Write-SystemStatusLog "Collecting performance data for process $($healthResult.ProcessId)" -Level 'DEBUG'
            
            try {
                $performanceData = @{
                    CpuPercent = $null
                    MemoryMB = $null
                    CollectionTime = Get-Date
                    Counters = @{}
                }
                
                # Get process object for performance data
                $process = Get-Process -Id $healthResult.ProcessId -ErrorAction SilentlyContinue
                if ($process) {
                    # Memory usage in MB
                    $performanceData.MemoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
                    
                    # CPU percentage using performance counters (PowerShell 5.1 compatible)
                    try {
                        $cpuCounter = Get-Counter "\Process($($process.ProcessName))\% Processor Time" -SampleInterval 1 -MaxSamples 2 -ErrorAction SilentlyContinue
                        if ($cpuCounter -and $cpuCounter.CounterSamples.Count -ge 2) {
                            $performanceData.CpuPercent = [math]::Round($cpuCounter.CounterSamples[-1].CookedValue, 2)
                        }
                    } catch {
                        Write-SystemStatusLog "Could not collect CPU performance data: $($_.Exception.Message)" -Level 'DEBUG'
                    }
                    
                    # Additional counters if manifest specifies them
                    if ($Manifest.ContainsKey('PerformanceCounters') -and $Manifest.PerformanceCounters) {
                        foreach ($counterPath in $Manifest.PerformanceCounters) {
                            try {
                                $counter = Get-Counter $counterPath -MaxSamples 1 -ErrorAction SilentlyContinue
                                if ($counter) {
                                    $performanceData.Counters[$counterPath] = $counter.CounterSamples[0].CookedValue
                                }
                            } catch {
                                Write-SystemStatusLog "Could not collect counter $counterPath`: $($_.Exception.Message)" -Level 'DEBUG'
                            }
                        }
                    }
                }
                
                $healthResult.PerformanceData = $performanceData
                Write-SystemStatusLog "Performance data collected: Memory=$($performanceData.MemoryMB)MB, CPU=$($performanceData.CpuPercent)%" -Level 'DEBUG'
                
            } catch {
                Write-SystemStatusLog "Error collecting performance data: $($_.Exception.Message)" -Level 'WARN'
                $healthResult.ErrorDetails += "Performance data collection error: $($_.Exception.Message)"
            }
        }
        
        # Step 4: Apply resource limits from manifest if specified
        if ($healthResult.PerformanceData -and $Manifest.ContainsKey('MaxMemoryMB') -and $Manifest.MaxMemoryMB) {
            if ($healthResult.PerformanceData.MemoryMB -gt $Manifest.MaxMemoryMB) {
                $healthResult.OverallHealthy = $false
                $healthResult.ErrorDetails += "Memory usage ($($healthResult.PerformanceData.MemoryMB)MB) exceeds limit ($($Manifest.MaxMemoryMB)MB)"
                Write-SystemStatusLog "Memory limit exceeded: $($healthResult.PerformanceData.MemoryMB)MB > $($Manifest.MaxMemoryMB)MB" -Level 'WARN'
            }
        }
        
        if ($healthResult.PerformanceData -and $Manifest.ContainsKey('MaxCpuPercent') -and $Manifest.MaxCpuPercent) {
            if ($healthResult.PerformanceData.CpuPercent -gt $Manifest.MaxCpuPercent) {
                $healthResult.OverallHealthy = $false
                $healthResult.ErrorDetails += "CPU usage ($($healthResult.PerformanceData.CpuPercent)%) exceeds limit ($($Manifest.MaxCpuPercent)%)"
                Write-SystemStatusLog "CPU limit exceeded: $($healthResult.PerformanceData.CpuPercent)% > $($Manifest.MaxCpuPercent)%" -Level 'WARN'
            }
        }
        
        # Return standardized health object
        Write-SystemStatusLog "Health check completed for $SubsystemName`: Overall=$($healthResult.OverallHealthy), Source=$($healthResult.HealthCheckSource)" -Level 'INFO'
        return $healthResult
        
    } catch {
        Write-SystemStatusLog "Critical error in health check for $SubsystemName`: $($_.Exception.Message)" -Level 'ERROR'
        
        # Return error result
        return @{
            SubsystemName = $SubsystemName
            Timestamp = Get-Date
            OverallHealthy = $false
            ProcessRunning = $false
            ProcessId = $null
            CustomHealthCheck = $null
            PerformanceData = $null
            ErrorDetails = @("Critical health check error: $($_.Exception.Message)")
            HealthCheckSource = "Error"
        }
    }
}

# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUd14ErObU8BNRzeeq2TqMR4UF
# 8B2gggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUDf2EV5K7zs7Ze8/FyRO+lyzEcjkwDQYJKoZIhvcNAQEBBQAEggEALdrI
# 8EixCD9gjZ+Gl6hVwZaZw73ujXbD3wI3SeS81RcGaA/proQ17pQ8KVgP5J6XxeIa
# rSnyzSK5VObD8D8hnjMQTpuKtrc8rYCDMJj1nroanDvB4MmXrhPuHFx4SOcWbid4
# 9QFJ31GrtdfBIugGRf8mcsjZn5tKk/lGfyh1eKrKfgZy2Iia8+ausWFA6uah2qFs
# /wxn1DaqQk4BI6kVmuo3D1M095hSLH/r9v5xwUJctgo9Z++9mvVcqFP9Jz+yWdnj
# HW8LjMTX8PIG/a9U41fwEjwef7V8Hot2mw9VMqtxSdp40Jy0KIUXUPDbuz4/KP8N
# dDUoW6WxLEOv5qJt+A==
# SIG # End signature block
