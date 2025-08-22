# NotificationCore.psm1
# Core functionality for Unity-Claude-NotificationIntegration
# Date: 2025-08-21

#region Module State Variables

# NOTE: State is now managed by parent module (Unity-Claude-NotificationIntegration-Modular.psm1)
# This module accesses state through parent module invocation
$script:ModuleVersion = '1.0.0'
$script:ModuleName = 'Unity-Claude-NotificationIntegration'

Write-Host "[CORE MODULE] State management delegated to parent module" -ForegroundColor DarkGreen

#endregion

#region Core Functions

function Initialize-NotificationIntegration {
    [CmdletBinding()]
    param(
        [Parameter()]
        [hashtable]$Configuration = @{}
    )
    
    Write-Verbose "Initializing Unity-Claude Notification Integration"
    Write-Host "[CORE MODULE] Initializing notification integration..." -ForegroundColor Green
    
    # Access parent module state using Get-Module and scriptblock invocation
    $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
    Write-Host "[CORE MODULE] Parent module found: $($parentModule.Name)" -ForegroundColor DarkGreen
    
    # Get current configuration from parent
    $currentConfig = & $parentModule { Get-NotificationState -StateType 'Config' }
    Write-Host "[CORE MODULE] Current config has $($currentConfig.Keys.Count) keys" -ForegroundColor DarkGreen
    
    # Apply custom configuration
    foreach ($key in $Configuration.Keys) {
        if ($currentConfig.ContainsKey($key)) {
            # Extract value to simple variable
            $value = $Configuration[$key]
            Write-Host "[CORE MODULE] Applying config: $key = $value" -ForegroundColor DarkGreen
            & $parentModule { 
                param($configKey, $configValue)
                Write-Host "[CORE MODULE->PARENT] Setting Config.$configKey = $configValue" -ForegroundColor DarkGreen
                Set-NotificationState -StateType 'Config' -Property $configKey -Value $configValue 
            } -configKey $key -configValue $value
            Write-Verbose "Applied configuration: $key = $($Configuration[$key])"
        }
        else {
            Write-Warning "Unknown configuration key: $key"
        }
    }
    
    # Initialize queues via parent module
    & $parentModule { 
        Write-Host "[CORE MODULE->PARENT] Initializing queues" -ForegroundColor DarkGreen
        Set-NotificationState -StateType 'Queue' -Value @() 
        Set-NotificationState -StateType 'FailedNotifications' -Value @()
    }
    
    # Reset metrics via parent module
    $metricsReset = @{
        TotalSent = 0
        TotalFailed = 0
        TotalRetries = 0
        AvgDeliveryTime = 0
        LastDeliveryTime = $null
        QueueSize = 0
        FailedQueueSize = 0
    }
    & $parentModule { 
        param($metrics)
        Write-Host "[CORE MODULE->PARENT] Resetting metrics" -ForegroundColor DarkGreen
        Set-NotificationState -StateType 'Metrics' -Value $metrics
    } -metrics $metricsReset
    
    # Reset circuit breaker via parent module
    $circuitBreakerReset = @{
        State = 'Closed'
        FailureCount = 0
        LastFailureTime = $null
        NextRetryTime = $null
    }
    & $parentModule { 
        param($circuitBreaker)
        Write-Host "[CORE MODULE->PARENT] Resetting circuit breaker" -ForegroundColor DarkGreen
        Set-NotificationState -StateType 'CircuitBreaker' -Value $circuitBreaker
    } -circuitBreaker $circuitBreakerReset
    
    Write-Verbose "Notification integration initialized successfully"
    Write-Host "[CORE MODULE] Initialization complete" -ForegroundColor Green
    
    # Get final state from parent for return value
    $hooks = & $parentModule { Get-NotificationState -StateType 'Hooks' }
    $finalConfig = & $parentModule { Get-NotificationState -StateType 'Config' }
    $circuitBreaker = & $parentModule { Get-NotificationState -StateType 'CircuitBreaker' }
    
    return @{
        ModuleVersion = $script:ModuleVersion
        HooksRegistered = $hooks.Count
        Configuration = $finalConfig
        QueueInitialized = $true
        CircuitBreakerState = $circuitBreaker.State
    }
}

function Register-NotificationHook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,
        
        [Parameter(Mandatory = $true)]
        [string]$TriggerEvent,
        
        [Parameter(Mandatory = $true)]
        [scriptblock]$Action,
        
        [Parameter()]
        [ValidateSet('Critical', 'Error', 'Warning', 'Info')]
        [string]$Severity = 'Info',
        
        [Parameter()]
        [string[]]$Channels,
        
        [Parameter()]
        [hashtable]$Conditions = @{},
        
        [Parameter()]
        [int]$Priority = 0,
        
        [Parameter()]
        [switch]$Enabled
    )
    
    Write-Verbose "Registering notification hook: $Name for event: $TriggerEvent"
    Write-Host "[CORE MODULE] Registering hook: $Name" -ForegroundColor Green
    
    # Access parent module state
    $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
    Write-Host "[CORE MODULE] Parent module found for hook registration" -ForegroundColor DarkGreen
    
    # Get current hooks from parent
    $hooks = & $parentModule { Get-NotificationState -StateType 'Hooks' }
    Write-Host "[CORE MODULE] Current hooks count: $($hooks.Count)" -ForegroundColor DarkGreen
    
    # Get default channels if not provided
    if (-not $Channels) {
        $config = & $parentModule { Get-NotificationState -StateType 'Config' }
        $Channels = $config.DefaultChannels
        Write-Host "[CORE MODULE] Using default channels: $($Channels -join ', ')" -ForegroundColor DarkGreen
    }
    
    if ($hooks.ContainsKey($Name)) {
        Write-Warning "Hook '$Name' already exists. Overwriting."
    }
    
    $hook = @{
        Name = $Name
        TriggerEvent = $TriggerEvent
        Action = $Action
        Severity = $Severity
        Channels = $Channels
        Conditions = $Conditions
        Priority = $Priority
        Enabled = $Enabled.IsPresent -or $true
        CreatedAt = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        TriggerCount = 0
        LastTriggered = $null
    }
    
    # Update hooks in parent module
    $hooks[$Name] = $hook
    & $parentModule { 
        param($hookName, $hooksData)
        Write-Host "[CORE MODULE->PARENT] Updating hooks with new hook: $hookName" -ForegroundColor DarkGreen
        Set-NotificationState -StateType 'Hooks' -Value $hooksData 
    } -hookName $Name -hooksData $hooks
    
    Write-Verbose "Hook '$Name' registered successfully"
    Write-Host "[CORE MODULE] Hook registered successfully" -ForegroundColor Green
    return $hook
}

function Unregister-NotificationHook {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )
    
    Write-Verbose "Unregistering notification hook: $Name"
    Write-Host "[CORE MODULE] Unregistering hook: $Name" -ForegroundColor Yellow
    
    # Access parent module state
    $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
    Write-Host "[CORE MODULE] Parent module found for hook unregistration" -ForegroundColor DarkYellow
    
    # Get current hooks from parent
    $hooks = & $parentModule { Get-NotificationState -StateType 'Hooks' }
    Write-Host "[CORE MODULE] Current hooks count: $($hooks.Count)" -ForegroundColor DarkYellow
    
    if ($hooks.ContainsKey($Name)) {
        $hooks.Remove($Name)
        # Update hooks in parent module
        & $parentModule { 
            param($hookName, $hooksData)
            Write-Host "[CORE MODULE->PARENT] Removing hook: $hookName" -ForegroundColor DarkYellow
            Set-NotificationState -StateType 'Hooks' -Value $hooksData 
        } -hookName $Name -hooksData $hooks
        Write-Verbose "Hook '$Name' unregistered successfully"
        Write-Host "[CORE MODULE] Hook unregistered successfully" -ForegroundColor Yellow
        return $true
    }
    else {
        Write-Warning "Hook '$Name' not found"
        Write-Host "[CORE MODULE] Hook not found: $Name" -ForegroundColor Red
        return $false
    }
}

function Get-NotificationHooks {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Name,
        
        [Parameter()]
        [string]$TriggerEvent,
        
        [Parameter()]
        [switch]$EnabledOnly
    )
    
    Write-Host "[CORE MODULE] Getting notification hooks (Name: $Name, Event: $TriggerEvent, EnabledOnly: $EnabledOnly)" -ForegroundColor Cyan
    
    # Access parent module state
    $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
    Write-Host "[CORE MODULE] Parent module found for getting hooks" -ForegroundColor DarkCyan
    
    # Get hooks from parent
    $hooksHash = & $parentModule { Get-NotificationState -StateType 'Hooks' }
    Write-Host "[CORE MODULE] Retrieved $($hooksHash.Count) hooks from parent" -ForegroundColor DarkCyan
    
    $hooks = $hooksHash.Values
    
    if ($Name) {
        $hooks = $hooks | Where-Object { $_.Name -eq $Name }
        Write-Host "[CORE MODULE] Filtered by name: $($hooks.Count) hooks" -ForegroundColor DarkCyan
    }
    
    if ($TriggerEvent) {
        $hooks = $hooks | Where-Object { $_.TriggerEvent -eq $TriggerEvent }
        Write-Host "[CORE MODULE] Filtered by trigger event: $($hooks.Count) hooks" -ForegroundColor DarkCyan
    }
    
    if ($EnabledOnly) {
        $hooks = $hooks | Where-Object { $_.Enabled }
        Write-Host "[CORE MODULE] Filtered by enabled: $($hooks.Count) hooks" -ForegroundColor DarkCyan
    }
    
    Write-Host "[CORE MODULE] Returning $($hooks.Count) hooks" -ForegroundColor Cyan
    return $hooks
}

function Clear-NotificationHooks {
    [CmdletBinding()]
    param()
    
    Write-Verbose "Clearing all notification hooks"
    Write-Host "[CORE MODULE] Clearing all notification hooks" -ForegroundColor Red
    
    # Access parent module state
    $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
    Write-Host "[CORE MODULE] Parent module found for clearing hooks" -ForegroundColor DarkRed
    
    # Clear hooks in parent module
    & $parentModule { 
        Write-Host "[CORE MODULE->PARENT] Clearing all hooks" -ForegroundColor DarkRed
        Set-NotificationState -StateType 'Hooks' -Value @{} 
    }
    
    Write-Verbose "All hooks cleared"
    Write-Host "[CORE MODULE] All hooks cleared successfully" -ForegroundColor Red
}

function Send-IntegratedNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TemplateName,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('Critical', 'Error', 'Warning', 'Info')]
        [string]$Severity,
        
        [Parameter()]
        [hashtable]$Data = @{},
        
        [Parameter()]
        [string[]]$Channels = @()
    )
    
    Write-Verbose "Sending integrated notification using template: $TemplateName"
    
    try {
        # Check if notification modules are available
        $contentEngineAvailable = Get-Module -Name 'Unity-Claude-NotificationContentEngine' -ErrorAction SilentlyContinue
        
        if ($contentEngineAvailable) {
            # Use the content engine for unified notifications
            $result = Send-UnifiedNotification -TemplateName $TemplateName -Severity $Severity -Data $Data
            
            # Update metrics via parent module
            Write-Host "[CORE MODULE] Updating metrics for successful notification" -ForegroundColor DarkGreen
            $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
            $lastDelivery = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            & $parentModule { 
                param($deliveryTime)
                Write-Host "[CORE MODULE->PARENT] Updating TotalSent metric" -ForegroundColor DarkGreen
                Update-NotificationMetrics -MetricName 'TotalSent' -Increment $true
                Set-NotificationState -StateType 'Metrics' -Property 'LastDeliveryTime' -Value $deliveryTime
            } -deliveryTime $lastDelivery
            
            return $result
        }
        else {
            # Fallback to direct module calls
            Write-Warning "Content engine not available, using fallback notification"
            
            # Simple fallback notification
            $message = "Unity-Claude Notification - $TemplateName - Severity: $Severity"
            if ($Data.Count -gt 0) {
                $message += " - Data: $($Data | ConvertTo-Json -Compress)"
            }
            
            Write-Host $message -ForegroundColor $(
                switch ($Severity) {
                    'Critical' { 'Red' }
                    'Error' { 'Red' }
                    'Warning' { 'Yellow' }
                    'Info' { 'Green' }
                }
            )
            
            return @{
                Status = 'Fallback'
                Message = $message
                Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
            }
        }
    }
    catch {
        Write-Error "Failed to send integrated notification: $_"
        Write-Host "[CORE MODULE] Notification failed, updating metrics" -ForegroundColor Red
        
        # Update failed metric via parent module
        $parentModule = Get-Module 'Unity-Claude-NotificationIntegration-Modular'
        & $parentModule { 
            Write-Host "[CORE MODULE->PARENT] Updating TotalFailed metric" -ForegroundColor DarkRed
            Update-NotificationMetrics -MetricName 'TotalFailed' -Increment $true
        }
        
        return @{
            Status = 'Failed'
            Error = $_.Exception.Message
            Timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        }
    }
}

#endregion

# Export functions only (no variables - state is managed by parent module)
Export-ModuleMember -Function @(
    'Initialize-NotificationIntegration',
    'Register-NotificationHook',
    'Unregister-NotificationHook', 
    'Get-NotificationHooks',
    'Clear-NotificationHooks',
    'Send-IntegratedNotification'
)

Write-Verbose "NotificationCore module loaded successfully"
# SIG # Begin signature block
# MIIFqQYJKoZIhvcNAQcCoIIFmjCCBZYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUnFRrUuI1iJKiESg8xDQm7mF3
# NeCgggMwMIIDLDCCAhSgAwIBAgIQdR0W2SKoK5VE8JId4ZxrRTANBgkqhkiG9w0B
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
# CQQxFgQUxTgEUtQqCBqCC6VKbTVJpycTthMwDQYJKoZIhvcNAQEBBQAEggEAbY1U
# Rbp6IGMwMNPfWykxaRr47pvIrrjICuEHHNwMTxie2JyzyTHDgDsgjjzQ63OhTd5I
# RgshE4ffyxFX46P3SRppAoYpuK483rbe++FQk5DUOITsrM0tpPn8faEbXo55ZMGt
# r0HrAYWVn+86drZ1rs4qTiqmQXH7Xw8R0lgBvWKoZu5sfwXawz1XV9T8mJM+xJZ6
# 7wIih/c1xCVMNswLB9CrRR++phg7Jc6nipWr+PwJWz9eWHnWW9CV5Lrcrj/jWz47
# bwJxKmCEh8YgrKjZiz2UobtHY6pkU3n361/Zf//LjZDqWFLwHfFtFFSwFfsUgxuf
# SfF7M4ZUQwN5M+l5Aw==
# SIG # End signature block
