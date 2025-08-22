# Unity-Claude-NotificationIntegration-Modular.psm1
# Main module loader for modular notification integration system with centralized state management
# Date: 2025-08-21
# FIXED: Centralized state management to resolve nested module scope isolation

Write-Host "[PARENT MODULE] Loading Unity-Claude-NotificationIntegration modular system..." -ForegroundColor Cyan
Write-Host "[PARENT MODULE] Initializing centralized state management..." -ForegroundColor Yellow

#region Module State Management (Centralized for all nested modules)

# Module metadata
$script:ModuleVersion = '1.1.1'
$script:ModuleName = 'Unity-Claude-NotificationIntegration-Modular'

Write-Host "[PARENT MODULE] Creating shared state variables..." -ForegroundColor Yellow

# Integration state storage (shared across all nested modules)
$script:NotificationHooks = @{}
Write-Host "[PARENT MODULE] Initialized NotificationHooks: Count = $($script:NotificationHooks.Count)" -ForegroundColor Gray

$script:NotificationQueue = @()
Write-Host "[PARENT MODULE] Initialized NotificationQueue: Count = $($script:NotificationQueue.Count)" -ForegroundColor Gray

$script:FailedNotifications = @()
Write-Host "[PARENT MODULE] Initialized FailedNotifications: Count = $($script:FailedNotifications.Count)" -ForegroundColor Gray

$script:NotificationMetrics = @{
    TotalSent = 0
    TotalFailed = 0
    TotalRetries = 0
    AvgDeliveryTime = 0
    LastDeliveryTime = $null
    QueueSize = 0
    FailedQueueSize = 0
}
Write-Host "[PARENT MODULE] Initialized NotificationMetrics with $($script:NotificationMetrics.Keys.Count) keys" -ForegroundColor Gray

# Configuration storage (shared across all nested modules)
$script:NotificationConfig = @{
    Enabled = $true
    AsyncDelivery = $true
    MaxRetries = 3
    RetryBaseDelay = 1000  # milliseconds
    RetryMaxDelay = 30000  # milliseconds
    CircuitBreakerThreshold = 5
    CircuitBreakerTimeout = 60000  # milliseconds
    QueueMaxSize = 1000
    MetricsRetentionDays = 7
    LogLevel = 'Info'
    EnableFallback = $true
    DefaultChannels = @('Email', 'Webhook')
}
Write-Host "[PARENT MODULE] Initialized NotificationConfig with $($script:NotificationConfig.Keys.Count) settings" -ForegroundColor Gray
Write-Host "[PARENT MODULE] QueueMaxSize = $($script:NotificationConfig.QueueMaxSize)" -ForegroundColor Gray

# Circuit breaker state (shared across all nested modules)
$script:CircuitBreaker = @{
    State = 'Closed'  # Closed, Open, HalfOpen
    FailureCount = 0
    LastFailureTime = $null
    NextRetryTime = $null
}
Write-Host "[PARENT MODULE] Initialized CircuitBreaker: State = $($script:CircuitBreaker.State)" -ForegroundColor Gray

#endregion

#region State Accessor Functions (For nested modules to access shared state)

function Get-NotificationState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Config', 'Metrics', 'Hooks', 'Queue', 'FailedNotifications', 'CircuitBreaker')]
        [string]$StateType,
        
        [Parameter()]
        [string]$Property
    )
    
    Write-Host "[STATE ACCESS] Getting $StateType$(if($Property){".$Property"})" -ForegroundColor DarkGray
    
    $result = switch ($StateType) {
        'Config' {
            if ($Property) {
                Write-Host "[STATE ACCESS] Config.$Property = $($script:NotificationConfig[$Property])" -ForegroundColor DarkGray
                $script:NotificationConfig[$Property]
            } else {
                Write-Host "[STATE ACCESS] Returning full Config with $($script:NotificationConfig.Keys.Count) keys" -ForegroundColor DarkGray
                $script:NotificationConfig
            }
        }
        'Metrics' {
            if ($Property) {
                Write-Host "[STATE ACCESS] Metrics.$Property = $($script:NotificationMetrics[$Property])" -ForegroundColor DarkGray
                $script:NotificationMetrics[$Property]
            } else {
                Write-Host "[STATE ACCESS] Returning full Metrics with $($script:NotificationMetrics.Keys.Count) keys" -ForegroundColor DarkGray
                $script:NotificationMetrics
            }
        }
        'Hooks' {
            Write-Host "[STATE ACCESS] Returning Hooks with $($script:NotificationHooks.Count) items" -ForegroundColor DarkGray
            $script:NotificationHooks
        }
        'Queue' {
            Write-Host "[STATE ACCESS] Returning Queue with $($script:NotificationQueue.Count) items" -ForegroundColor DarkGray
            $script:NotificationQueue
        }
        'FailedNotifications' {
            Write-Host "[STATE ACCESS] Returning FailedNotifications with $($script:FailedNotifications.Count) items" -ForegroundColor DarkGray
            $script:FailedNotifications
        }
        'CircuitBreaker' {
            if ($Property) {
                Write-Host "[STATE ACCESS] CircuitBreaker.$Property = $($script:CircuitBreaker[$Property])" -ForegroundColor DarkGray
                $script:CircuitBreaker[$Property]
            } else {
                Write-Host "[STATE ACCESS] Returning full CircuitBreaker state" -ForegroundColor DarkGray
                $script:CircuitBreaker
            }
        }
    }
    
    return $result
}

function Set-NotificationState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Config', 'Metrics', 'Hooks', 'Queue', 'FailedNotifications', 'CircuitBreaker')]
        [string]$StateType,
        
        [Parameter()]
        [string]$Property,
        
        [Parameter()]
        [object]$Value
    )
    
    Write-Host "[STATE UPDATE] Setting $StateType$(if($Property){".$Property"}) = $Value" -ForegroundColor DarkGray
    
    switch ($StateType) {
        'Config' {
            if ($Property) {
                $script:NotificationConfig[$Property] = $Value
                Write-Host "[STATE UPDATE] Config.$Property updated to: $Value" -ForegroundColor DarkGray
            } else {
                $script:NotificationConfig = $Value
                Write-Host "[STATE UPDATE] Config replaced with $($Value.Keys.Count) keys" -ForegroundColor DarkGray
            }
        }
        'Metrics' {
            if ($Property) {
                $script:NotificationMetrics[$Property] = $Value
                Write-Host "[STATE UPDATE] Metrics.$Property updated to: $Value" -ForegroundColor DarkGray
            } else {
                $script:NotificationMetrics = $Value
                Write-Host "[STATE UPDATE] Metrics replaced with $($Value.Keys.Count) keys" -ForegroundColor DarkGray
            }
        }
        'Hooks' {
            $script:NotificationHooks = $Value
            Write-Host "[STATE UPDATE] Hooks replaced with $($Value.Count) items" -ForegroundColor DarkGray
        }
        'Queue' {
            $script:NotificationQueue = $Value
            Write-Host "[STATE UPDATE] Queue replaced with $(@($Value).Count) items" -ForegroundColor DarkGray
        }
        'FailedNotifications' {
            $script:FailedNotifications = $Value
            Write-Host "[STATE UPDATE] FailedNotifications replaced with $(@($Value).Count) items" -ForegroundColor DarkGray
        }
        'CircuitBreaker' {
            if ($Property) {
                $script:CircuitBreaker[$Property] = $Value
                Write-Host "[STATE UPDATE] CircuitBreaker.$Property updated to: $Value" -ForegroundColor DarkGray
            } else {
                $script:CircuitBreaker = $Value
                Write-Host "[STATE UPDATE] CircuitBreaker state replaced" -ForegroundColor DarkGray
            }
        }
    }
}

function Update-NotificationMetrics {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$MetricName,
        
        [Parameter(Mandatory = $true)]
        [object]$Value,
        
        [Parameter()]
        [ValidateSet('Set', 'Increment', 'Decrement')]
        [string]$Operation = 'Set'
    )
    
    Write-Host "[METRICS UPDATE] $Operation $MetricName with value: $Value" -ForegroundColor DarkGray
    
    switch ($Operation) {
        'Set' {
            $script:NotificationMetrics[$MetricName] = $Value
        }
        'Increment' {
            $script:NotificationMetrics[$MetricName] += $Value
        }
        'Decrement' {
            $script:NotificationMetrics[$MetricName] -= $Value
        }
    }
    
    Write-Host "[METRICS UPDATE] $MetricName is now: $($script:NotificationMetrics[$MetricName])" -ForegroundColor DarkGray
}

#endregion

# Export state accessor functions AND all functions from nested modules
# The nested modules will be loaded by the manifest, and we need to re-export their functions
Export-ModuleMember -Function @(
    # State accessor functions
    'Get-NotificationState',
    'Set-NotificationState',
    'Update-NotificationMetrics',
    
    # Core Functions (from Core\NotificationCore.psm1)
    'Initialize-NotificationIntegration',
    'Register-NotificationHook',
    'Unregister-NotificationHook', 
    'Get-NotificationHooks',
    'Clear-NotificationHooks',
    'Send-IntegratedNotification',
    'Test-IntegratedNotification',
    'Validate-CrossModuleMessage',
    
    # Workflow Integration Functions (from Integration\WorkflowIntegration.psm1)
    'Invoke-NotificationHook',
    'Add-WorkflowNotificationTrigger',
    'Remove-WorkflowNotificationTrigger',
    'Enable-WorkflowNotifications',
    'Disable-WorkflowNotifications',
    'Get-WorkflowNotificationStatus',
    
    # Context Management Functions (from Integration\ContextManagement.psm1)
    'New-NotificationContext',
    'Add-NotificationContextData',
    'Get-NotificationContext',
    'Clear-NotificationContext',
    'Format-NotificationContext',
    
    # Reliability Functions (from Reliability\RetryLogic.psm1)
    'New-NotificationRetryPolicy',
    'Invoke-NotificationWithRetry',
    'Test-NotificationDelivery',
    'Get-NotificationDeliveryStatus',
    'Reset-NotificationRetryState',
    
    # Fallback Functions (from Reliability\FallbackMechanisms.psm1)
    'New-NotificationFallbackChain',
    'Invoke-NotificationFallback',
    'Test-NotificationFallback',
    'Get-FallbackStatus',
    'Reset-FallbackState',
    
    # Queue Management Functions (from Queue\QueueManagement.psm1)
    'Initialize-NotificationQueue',
    'Add-NotificationToQueue',
    'Process-NotificationQueue',
    'Get-QueueStatus',
    'Clear-NotificationQueue',
    'Get-FailedNotifications',
    
    # Configuration Functions (from Configuration\ConfigurationManagement.psm1)
    'New-NotificationConfiguration',
    'Import-NotificationConfiguration',
    'Export-NotificationConfiguration',
    'Test-NotificationConfiguration',
    'Get-NotificationConfiguration',
    'Set-NotificationConfiguration',
    
    # Monitoring Functions (from Monitoring\MetricsAndHealthCheck.psm1)
    'Get-NotificationMetrics',
    'Get-NotificationHealthCheck',
    'New-NotificationReport',
    'Export-NotificationAnalytics',
    'Reset-NotificationMetrics'
)

Write-Host "[PARENT MODULE] All functions exported (state accessors + nested module functions)" -ForegroundColor Green
Write-Host "[PARENT MODULE] Unity-Claude-NotificationIntegration modular system loaded successfully" -ForegroundColor Green
Write-Host "[PARENT MODULE] Module version: $script:ModuleVersion" -ForegroundColor Green
Write-Host "[PARENT MODULE] Available submodules: Core, Integration, Reliability, Queue, Configuration, Monitoring" -ForegroundColor Green
Write-Host "" # Blank line for readability
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUrTZFl3edPF7jgir4/knqjgM4
# eSqgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUQ7NWl1plUe/9b/ghE/wmPt8NDl4wDQYJKoZIhvcNAQEBBQAEggEAF6Ml
# Ufa0/itirOeiZ3thU0U56/uOA7ei6XY7vF0l/qlsYfquj0zhdAzNe7z63azz7Mq3
# u8IfpJ2tiW/svBcRRMVAi/f10T8Jmt84V+ONUAdUMo41yxOJ6wkMSF7O9qCMmQ1D
# L1ezLP0eLHzR6yVbeoZB8GuRxlnTnnibQWiYitSUWkgyKpUatGpX86yIwpiVp7SU
# +UVYrnrVvbpeUYmYlJOAImkAmlbDpHQld89yN9kTtS9T+6h/Y4vSPtQIgBC5cXAm
# squLzoSiClSLd5oeMhAG4qLD3a2qpcrAMPHvFBPiTAO9pRQfPMsfsKLhwRU4evxF
# eZ9KlKIFhLQsfem0rQ==
# SIG # End signature block
