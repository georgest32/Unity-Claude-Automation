
function Invoke-CircuitBreakerCheck {
    <#
    .SYNOPSIS
    Implements circuit breaker pattern for subsystem failure detection
    
    .DESCRIPTION
    Enterprise circuit breaker implementation with three states (Closed/Open/Half-Open):
    - State-based failure tracking and threshold management
    - Per-subsystem circuit breaker instances (research-validated pattern)
    - Integrates with existing system status monitoring
    
    .PARAMETER SubsystemName
    Name of the subsystem to check circuit breaker for
    
    .PARAMETER TestResult
    Health test result to process through circuit breaker
    
    .EXAMPLE
    Invoke-CircuitBreakerCheck -SubsystemName "Unity-Claude-Core" -TestResult $healthResult
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SubsystemName,
        
        [Parameter(Mandatory=$true)]
        [object]$TestResult
    )
    
    Write-SystemStatusLog "Processing circuit breaker check for subsystem: $SubsystemName" -Level 'DEBUG'
    
    try {
        # Load configuration for circuit breaker settings
        $config = Get-SystemStatusConfiguration
        $cbConfig = $config.CircuitBreaker
        
        # Check for subsystem-specific configuration overrides
        $subsystemConfig = Get-SubsystemCircuitBreakerConfig -SubsystemName $SubsystemName -BaseConfig $cbConfig
        
        Write-SystemStatusLog "Circuit breaker configuration loaded - Threshold: $($subsystemConfig.FailureThreshold), Timeout: $($subsystemConfig.TimeoutSeconds)s, Source: $($subsystemConfig.ConfigurationSource)" -Level 'TRACE'
        
        # Initialize circuit breaker state storage if not exists
        if (-not $script:CircuitBreakerState) {
            $script:CircuitBreakerState = @{}
        }
        
        # Initialize circuit breaker for this subsystem if not exists
        if (-not $script:CircuitBreakerState.ContainsKey($SubsystemName)) {
            $script:CircuitBreakerState[$SubsystemName] = @{
                State = "Closed"  # Closed, Open, Half-Open
                FailureCount = 0
                LastFailureTime = $null
                LastSuccessTime = Get-Date
                StateChangeTime = Get-Date
                FailureThreshold = $subsystemConfig.FailureThreshold
                TimeoutSeconds = $subsystemConfig.TimeoutSeconds
                TestRequestsInHalfOpen = 0
                MaxTestRequests = $subsystemConfig.MaxTestRequests
                HalfOpenRetryCount = $subsystemConfig.HalfOpenRetryCount
                ConfigurationSource = $subsystemConfig.ConfigurationSource
                SubsystemName = $SubsystemName
                LastConfigurationUpdate = Get-Date
            }
            Write-SystemStatusLog "Initialized circuit breaker for $SubsystemName - Threshold: $($subsystemConfig.FailureThreshold), Timeout: $($subsystemConfig.TimeoutSeconds)s, Source: $($subsystemConfig.ConfigurationSource)" -Level 'DEBUG'
        } else {
            # Update existing circuit breaker with current configuration if enabled
            $existingCB = $script:CircuitBreakerState[$SubsystemName]
            
            # Only update if configuration is different (avoid unnecessary changes during active failures)
            $configurationChanged = $false
            $changes = @()
            
            if ($existingCB.FailureThreshold -ne $subsystemConfig.FailureThreshold) {
                $changes += "FailureThreshold: $($existingCB.FailureThreshold) -> $($subsystemConfig.FailureThreshold)"
                $existingCB.FailureThreshold = $subsystemConfig.FailureThreshold
                $configurationChanged = $true
            }
            
            if ($existingCB.TimeoutSeconds -ne $subsystemConfig.TimeoutSeconds) {
                $changes += "TimeoutSeconds: $($existingCB.TimeoutSeconds) -> $($subsystemConfig.TimeoutSeconds)"
                $existingCB.TimeoutSeconds = $subsystemConfig.TimeoutSeconds
                $configurationChanged = $true
            }
            
            if ($existingCB.MaxTestRequests -ne $subsystemConfig.MaxTestRequests) {
                $changes += "MaxTestRequests: $($existingCB.MaxTestRequests) -> $($subsystemConfig.MaxTestRequests)"
                $existingCB.MaxTestRequests = $subsystemConfig.MaxTestRequests
                $configurationChanged = $true
            }
            
            if ($existingCB.HalfOpenRetryCount -ne $subsystemConfig.HalfOpenRetryCount) {
                $changes += "HalfOpenRetryCount: $($existingCB.HalfOpenRetryCount) -> $($subsystemConfig.HalfOpenRetryCount)"
                $existingCB.HalfOpenRetryCount = $subsystemConfig.HalfOpenRetryCount
                $configurationChanged = $true
            }
            
            if ($existingCB.ConfigurationSource -ne $subsystemConfig.ConfigurationSource) {
                $changes += "ConfigurationSource: $($existingCB.ConfigurationSource) -> $($subsystemConfig.ConfigurationSource)"
                $existingCB.ConfigurationSource = $subsystemConfig.ConfigurationSource
                $configurationChanged = $true
            }
            
            if ($configurationChanged) {
                $existingCB.LastConfigurationUpdate = Get-Date
                Write-SystemStatusLog "Updated circuit breaker configuration for $SubsystemName - Changes: $($changes -join ', ')" -Level 'INFO'
            } else {
                Write-SystemStatusLog "Circuit breaker configuration for $SubsystemName unchanged - Source: $($subsystemConfig.ConfigurationSource)" -Level 'TRACE'
            }
        }
        
        $circuitBreaker = $script:CircuitBreakerState[$SubsystemName]
        $currentTime = Get-Date
        
        # Process test result based on current circuit breaker state
        switch ($circuitBreaker.State) {
            "Closed" {
                if ($TestResult.OverallHealthy -or ($TestResult -is [bool] -and $TestResult)) {
                    # Success - reset failure count
                    $circuitBreaker.FailureCount = 0
                    $circuitBreaker.LastSuccessTime = $currentTime
                    Write-SystemStatusLog "Circuit breaker $SubsystemName - Success in Closed state" -Level 'DEBUG'
                } else {
                    # Failure - increment count
                    $circuitBreaker.FailureCount++
                    $circuitBreaker.LastFailureTime = $currentTime
                    
                    Write-SystemStatusLog "Circuit breaker $SubsystemName - Failure $($circuitBreaker.FailureCount)/$($circuitBreaker.FailureThreshold)" -Level 'WARN'
                    
                    # Check if threshold exceeded
                    if ($circuitBreaker.FailureCount -ge $circuitBreaker.FailureThreshold) {
                        $circuitBreaker.State = "Open"
                        $circuitBreaker.StateChangeTime = $currentTime
                        Write-SystemStatusLog "Circuit breaker $SubsystemName - OPENED due to failure threshold" -Level 'ERROR'
                        
                        # Send alert for circuit breaker opening
                        Send-HealthAlert -AlertLevel "Critical" -SubsystemName $SubsystemName -Message "Circuit breaker opened - $($circuitBreaker.FailureCount) consecutive failures"
                    }
                }
            }
            
            "Open" {
                # Check if timeout period has passed
                $timeInOpen = ($currentTime - $circuitBreaker.StateChangeTime).TotalSeconds
                
                if ($timeInOpen -ge $circuitBreaker.TimeoutSeconds) {
                    # Move to Half-Open state for testing
                    $circuitBreaker.State = "Half-Open"
                    $circuitBreaker.StateChangeTime = $currentTime
                    $circuitBreaker.TestRequestsInHalfOpen = 0
                    Write-SystemStatusLog "Circuit breaker $SubsystemName - Moving to Half-Open for testing" -Level 'INFO'
                } else {
                    Write-SystemStatusLog "Circuit breaker $SubsystemName - Remaining in Open state ($([math]::Round($circuitBreaker.TimeoutSeconds - $timeInOpen, 1))s remaining)" -Level 'DEBUG'
                }
            }
            
            "Half-Open" {
                $circuitBreaker.TestRequestsInHalfOpen++
                
                if ($TestResult.OverallHealthy -or ($TestResult -is [bool] -and $TestResult)) {
                    # Success - return to Closed state
                    $circuitBreaker.State = "Closed"
                    $circuitBreaker.FailureCount = 0
                    $circuitBreaker.LastSuccessTime = $currentTime
                    $circuitBreaker.StateChangeTime = $currentTime
                    Write-SystemStatusLog "Circuit breaker $SubsystemName - CLOSED after successful test" -Level 'INFO'
                    
                    # Send alert for circuit breaker recovery
                    Send-HealthAlert -AlertLevel "Info" -SubsystemName $SubsystemName -Message "Circuit breaker closed - subsystem recovered"
                } else {
                    # Failure - return to Open state
                    $circuitBreaker.State = "Open"
                    $circuitBreaker.FailureCount++
                    $circuitBreaker.LastFailureTime = $currentTime
                    $circuitBreaker.StateChangeTime = $currentTime
                    Write-SystemStatusLog "Circuit breaker $SubsystemName - Returned to Open after test failure" -Level 'ERROR'
                }
            }
        }
        
        # Return circuit breaker status
        $circuitBreakerStatus = @{
            SubsystemName = $SubsystemName
            State = $circuitBreaker.State
            FailureCount = $circuitBreaker.FailureCount
            LastFailureTime = $circuitBreaker.LastFailureTime
            LastSuccessTime = $circuitBreaker.LastSuccessTime
            StateChangeTime = $circuitBreaker.StateChangeTime
            IsHealthy = ($circuitBreaker.State -eq "Closed")
            AllowRequests = ($circuitBreaker.State -ne "Open")
        }
        
        return $circuitBreakerStatus
        
    } catch {
        Write-SystemStatusLog "Error in circuit breaker check for $SubsystemName`: $($_.Exception.Message)" -Level 'ERROR'
        throw
    }
}

function Get-SubsystemCircuitBreakerConfig {
    <#
    .SYNOPSIS
    Gets circuit breaker configuration for a specific subsystem with override support
    
    .DESCRIPTION
    Resolves circuit breaker configuration for a subsystem by checking:
    1. Subsystem manifest CircuitBreaker section
    2. Base configuration from systemstatus.config.json
    3. Returns merged configuration with source tracking
    
    .PARAMETER SubsystemName
    Name of the subsystem to get configuration for
    
    .PARAMETER BaseConfig
    Base circuit breaker configuration from main config
    
    .EXAMPLE
    Get-SubsystemCircuitBreakerConfig -SubsystemName "Unity-Claude-Core" -BaseConfig $cbConfig
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SubsystemName,
        
        [Parameter(Mandatory=$true)]
        [hashtable]$BaseConfig
    )
    
    Write-SystemStatusLog "Resolving circuit breaker configuration for subsystem: $SubsystemName" -Level 'TRACE'
    
    try {
        # Start with base configuration
        $config = $BaseConfig.Clone()
        $config.ConfigurationSource = "SystemStatusConfiguration"
        
        # Check for subsystem manifest with circuit breaker overrides
        $manifest = $null
        if (Get-Command "Get-SubsystemManifest" -ErrorAction SilentlyContinue) {
            $manifest = Get-SubsystemManifest -SubsystemName $SubsystemName -ErrorAction SilentlyContinue
        }
        
        if ($manifest -and $manifest.CircuitBreaker) {
            Write-SystemStatusLog "Found circuit breaker overrides in manifest for $SubsystemName" -Level 'DEBUG'
            
            $manifestCB = $manifest.CircuitBreaker
            $overrides = @()
            
            # Apply manifest overrides
            if ($manifestCB.ContainsKey('FailureThreshold') -and $manifestCB.FailureThreshold -ne $config.FailureThreshold) {
                $config.FailureThreshold = $manifestCB.FailureThreshold
                $overrides += "FailureThreshold=$($manifestCB.FailureThreshold)"
            }
            
            if ($manifestCB.ContainsKey('TimeoutSeconds') -and $manifestCB.TimeoutSeconds -ne $config.TimeoutSeconds) {
                $config.TimeoutSeconds = $manifestCB.TimeoutSeconds
                $overrides += "TimeoutSeconds=$($manifestCB.TimeoutSeconds)"
            }
            
            if ($manifestCB.ContainsKey('MaxTestRequests') -and $manifestCB.MaxTestRequests -ne $config.MaxTestRequests) {
                $config.MaxTestRequests = $manifestCB.MaxTestRequests
                $overrides += "MaxTestRequests=$($manifestCB.MaxTestRequests)"
            }
            
            if ($manifestCB.ContainsKey('HalfOpenRetryCount') -and $manifestCB.HalfOpenRetryCount -ne $config.HalfOpenRetryCount) {
                $config.HalfOpenRetryCount = $manifestCB.HalfOpenRetryCount
                $overrides += "HalfOpenRetryCount=$($manifestCB.HalfOpenRetryCount)"
            }
            
            if ($overrides.Count -gt 0) {
                $config.ConfigurationSource = "SubsystemManifest+SystemStatusConfiguration"
                Write-SystemStatusLog "Applied circuit breaker overrides for $SubsystemName - $($overrides -join ', ')" -Level 'INFO'
            } else {
                Write-SystemStatusLog "No circuit breaker overrides applied for $SubsystemName (manifest values same as base)" -Level 'TRACE'
            }
        } else {
            Write-SystemStatusLog "No circuit breaker manifest found for $SubsystemName, using base configuration" -Level 'TRACE'
        }
        
        # Validate the final configuration
        if ($config.FailureThreshold -lt 1 -or $config.FailureThreshold -gt 10) {
            Write-SystemStatusLog "Invalid FailureThreshold for $SubsystemName`: $($config.FailureThreshold), using default: 3" -Level 'WARN'
            $config.FailureThreshold = 3
        }
        
        if ($config.TimeoutSeconds -lt 10 -or $config.TimeoutSeconds -gt 600) {
            Write-SystemStatusLog "Invalid TimeoutSeconds for $SubsystemName`: $($config.TimeoutSeconds), using default: 60" -Level 'WARN'
            $config.TimeoutSeconds = 60
        }
        
        Write-SystemStatusLog "Resolved circuit breaker config for $SubsystemName - Threshold: $($config.FailureThreshold), Timeout: $($config.TimeoutSeconds)s, Source: $($config.ConfigurationSource)" -Level 'TRACE'
        
        return $config
        
    } catch {
        Write-SystemStatusLog "Error resolving circuit breaker configuration for $SubsystemName`: $($_.Exception.Message)" -Level 'ERROR'
        
        # Return base configuration as fallback
        $config = $BaseConfig.Clone()
        $config.ConfigurationSource = "SystemStatusConfiguration-Fallback"
        return $config
    }
}
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUYDkl3hLK3iyqlcZriUfLIwmj
# +regggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUsHPcGg6D833c41fAHdmrwgTCArswDQYJKoZIhvcNAQEBBQAEggEAIjPr
# 3RtdAq8lG8S+OND99oTGOKVF9U5Dze3HBls8htK7E17oB06b9UJYCGNhoCZw2COI
# BicSPXlrWgpYhGCP1p0tplcO+Rv2e9J2UiSs+/8cK5NUlZRScYW+A5xIsrlMeFso
# NHCCOMFxwkKZgaZQADzDEh2U6+ATs4aPHMs/8QxGRyD5PQL32TKqmYfQdytlnDDT
# G1b9xC1u2Pb7VdJrw/EdLB8ioywZF/Il0+OppWHhxA1PSvWWbswYoSxAZf9QaN1O
# c5E1DIxDfe86uXOKZCvVLV4ZqamhdfeL1HgDL58Tf75k6mCXLzGVDSyKJCSB2pdD
# ihLNXWoX770vwm0MtA==
# SIG # End signature block
