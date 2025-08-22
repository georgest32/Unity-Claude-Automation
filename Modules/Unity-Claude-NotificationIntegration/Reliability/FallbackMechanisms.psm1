# FallbackMechanisms.psm1
# Fallback mechanisms and circuit breaker patterns for notifications
# Date: 2025-08-21

#region Fallback Mechanisms

function New-NotificationFallbackChain {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Channels,
        
        [Parameter()]
        [hashtable]$ChannelConfig = @{},
        
        [Parameter()]
        [int]$TimeoutPerChannel = 10000  # milliseconds
    )
    
    Write-Verbose "Creating notification fallback chain with channels: $($Channels -join ', ')"
    
    $fallbackChain = @{
        Channels = $Channels
        ChannelConfig = $ChannelConfig.Clone()
        TimeoutPerChannel = $TimeoutPerChannel
        CreatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        LastUsed = $null
        SuccessfulChannel = $null
    }
    
    return $fallbackChain
}

function Invoke-NotificationFallback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$FallbackChain,
        
        [Parameter(Mandatory = $true)]
        [hashtable]$Context
    )
    
    Write-Verbose "Invoking notification fallback chain"
    
    $FallbackChain.LastUsed = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    
    foreach ($channel in $FallbackChain.Channels) {
        Write-Verbose "Trying fallback channel: $channel"
        
        try {
            # Check circuit breaker for this channel
            if (Test-CircuitBreaker -Channel $channel) {
                Write-Verbose "Circuit breaker open for $channel, skipping"
                continue
            }
            
            $result = Send-IntegratedNotification -TemplateName 'FallbackNotification' -Severity $Context.Severity -Data $Context.Data -Channels @($channel)
            
            if ($result.Status -eq 'Success' -or $result.Status -eq 'Fallback') {
                $FallbackChain.SuccessfulChannel = $channel
                Write-Verbose "Fallback successful via channel: $channel"
                return @{
                    Success = $true
                    Channel = $channel
                    Result = $result
                    Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
                }
            }
            else {
                Write-Warning "Fallback failed via channel ${channel}: $($result.Error)"
                Update-CircuitBreaker -Channel $channel -Success $false
            }
        }
        catch {
            Write-Warning "Fallback error via channel ${channel}: $_"
            Update-CircuitBreaker -Channel $channel -Success $false
        }
    }
    
    Write-Error "All fallback channels failed"
    return @{
        Success = $false
        Error = 'All fallback channels failed'
        Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    }
}

function Test-NotificationFallback {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$FallbackChain
    )
    
    Write-Verbose "Testing notification fallback chain"
    
    $testContext = @{
        Severity = 'Info'
        Data = @{
            TestMessage = 'Fallback test notification'
            TestTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
    }
    
    return Invoke-NotificationFallback -FallbackChain $FallbackChain -Context $testContext
}

function Get-FallbackStatus {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Getting fallback status"
    
    return @{
        CircuitBreakerState = $script:CircuitBreaker.State
        FailureCount = $script:CircuitBreaker.FailureCount
        LastFailureTime = $script:CircuitBreaker.LastFailureTime
        NextRetryTime = $script:CircuitBreaker.NextRetryTime
        FallbackEnabled = $script:NotificationConfig.EnableFallback
    }
}

function Reset-FallbackState {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Resetting fallback state"
    
    $script:CircuitBreaker.State = 'Closed'
    $script:CircuitBreaker.FailureCount = 0
    $script:CircuitBreaker.LastFailureTime = $null
    $script:CircuitBreaker.NextRetryTime = $null
    
    Write-Verbose "Fallback state reset successfully"
}

#endregion

#region Circuit Breaker Functions

function Test-CircuitBreaker {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Channel = 'Default'
    )
    
    $circuitBreaker = $script:CircuitBreaker
    
    switch ($circuitBreaker.State) {
        'Closed' {
            return $false  # Circuit is closed, allow requests
        }
        'Open' {
            if ($circuitBreaker.NextRetryTime -and (Get-Date) -gt [DateTime]$circuitBreaker.NextRetryTime) {
                # Transition to Half-Open
                $script:CircuitBreaker.State = 'HalfOpen'
                Write-Verbose "Circuit breaker transitioning to Half-Open for $Channel"
                return $false
            }
            else {
                Write-Verbose "Circuit breaker is Open for $Channel"
                return $true  # Circuit is open, block requests
            }
        }
        'HalfOpen' {
            return $false  # Allow one request to test
        }
    }
}

function Update-CircuitBreaker {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Channel = 'Default',
        
        [Parameter(Mandatory = $true)]
        [bool]$Success
    )
    
    $circuitBreaker = $script:CircuitBreaker
    
    if ($Success) {
        # Reset on success
        $script:CircuitBreaker.State = 'Closed'
        $script:CircuitBreaker.FailureCount = 0
        $script:CircuitBreaker.LastFailureTime = $null
        $script:CircuitBreaker.NextRetryTime = $null
        Write-Verbose "Circuit breaker reset to Closed for $Channel"
    }
    else {
        # Increment failure count
        $script:CircuitBreaker.FailureCount++
        $script:CircuitBreaker.LastFailureTime = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        
        if ($circuitBreaker.FailureCount -ge $script:NotificationConfig.CircuitBreakerThreshold) {
            # Open the circuit
            $script:CircuitBreaker.State = 'Open'
            $nextRetry = (Get-Date).AddMilliseconds($script:NotificationConfig.CircuitBreakerTimeout)
            $script:CircuitBreaker.NextRetryTime = $nextRetry.ToString('yyyy-MM-dd HH:mm:ss')
            Write-Warning "Circuit breaker opened for $Channel due to $($circuitBreaker.FailureCount) failures"
        }
    }
}

#endregion

# Export functions
Export-ModuleMember -Function @(
    'New-NotificationFallbackChain',
    'Invoke-NotificationFallback',
    'Test-NotificationFallback',
    'Get-FallbackStatus',
    'Reset-FallbackState'
)

Write-Verbose "FallbackMechanisms module loaded successfully"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUcSd3MKo36Fz/P/DlJZc3yIO6
# uSOgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUunW1LF0ZNFi6v9Oo1JCkTkUd/uEwDQYJKoZIhvcNAQEBBQAEggEAgYkt
# sF7ekCtN6PXaQzLIDpl5CmN03/VfK9cRaJp8Xtb9Km+lBjLQkZdJn8cJWzGKjyxZ
# rNIxl0HymQbWEyExtGVFkOnHDyWFO3N6MkQyTO9rPAdv44FWeRYmAuD9KNDXYZe4
# 7vy9XOeO+bOWgKxW7VqhoP+k/g/Rt9AJRKWriacIao+36JiYv9GtwQfm4lv+12Sz
# cmt2qx1F27VcMGzidg97xoDonB92KrAAFnpMzZdzwHrt22pE135s45p6vxB6fDXx
# SAQrIQzmdbAmYA7oLanxnoYn71ohzOiY4av+Ax171DhsdhcHj7sgZdf0IEoq09zM
# 9tvmC5xso8F5+kKFpA==
# SIG # End signature block
